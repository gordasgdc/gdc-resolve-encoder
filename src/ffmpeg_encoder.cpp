#include <algorithm>
#include "ffmpeg_encoder.h"
#include "pixconv.h"
#include "gdc_container.h"
#include "bitstream.h"

#include <cstring>
#include <cmath>
#include <vector>
#include <string>
#include <thread>
#include <chrono>
#include <atomic>
#include <mutex>
#include <cstdarg>

extern "C" {
#include <libavutil/opt.h>
#include <libavutil/imgutils.h>
#include <libavutil/pixdesc.h>
}

using namespace gdc_bs;

#ifndef GDC_ENCODER_VERSION
#define GDC_ENCODER_VERSION "dev"
#endif

// Encoder-side failure counter, read by the GDC containers so that a render
// whose ENCODER failed never leaves a partial file that looks like an export.
std::atomic<int> g_GdcEncoderFailureCount{ 0 };

// libav* diagnostics -> Resolve's log (davinci_resolve.log). Warnings and
// errors only; installed once. Without this, a muxer/encoder refusal showed
// up as a bare numeric code with no reason.
static void GdcAvLogCallback(void* p_pAvcl, int p_Level, const char* p_pFmt, va_list p_Args)
{
    if (p_Level > AV_LOG_WARNING) return;
    char line[512];
    int printPrefix = 1;
    va_list copy;
    va_copy(copy, p_Args);
    av_log_format_line2(p_pAvcl, p_Level, p_pFmt, copy, line, sizeof(line), &printPrefix);
    va_end(copy);
    size_t n = strlen(line);
    while (n > 0 && (line[n - 1] == '\n' || line[n - 1] == '\r')) line[--n] = 0;
    if (n == 0) return;
    g_Log(p_Level <= AV_LOG_ERROR ? logLevelError : logLevelWarn, "GDC Encoder :: libav: %s", line);
}

void GdcInstallAvLog()
{
    static std::once_flag once;
    std::call_once(once, []() { av_log_set_callback(GdcAvLogCallback); });
}

// The ISO/IEC 14496-15 avcC / hvcC builders and the Annex-B helpers live in
// src/bitstream.h (shared with the GDC containers and the regression tests).

// ─── HDR10 static metadata (mastering display + content light level) ───
// Resolve 21.1 does NOT hand the hdrPrimaries/hdrWhite/hdrMasterLum/hdrMaxCLL/
// hdrMaxFALL props to the encoder at any stage (verified: 0 of 5 present in
// DoInit, DoOpen and on the first frame, with hdrMasteringOn=1 in the
// project), so the values come from this plugin's own settings panel.
// Units follow x264/x265: chromaticity in 0.00002, luminance in 0.0001 cd/m2.
static std::string BuildMasterDisplay(int p_PrimariesIdx, int p_MaxLumNits)
{
    char buf[200];
    if (p_PrimariesIdx == 1) // Rec.2020, D65
    {
        snprintf(buf, sizeof(buf), "G(8500,39850)B(6550,2300)R(35400,14600)WP(15635,16450)L(%d,50)", p_MaxLumNits * 10000);
    }
    else // P3-D65 (default: the usual HDR10 grading display)
    {
        snprintf(buf, sizeof(buf), "G(13250,34500)B(7500,3000)R(34000,16000)WP(15635,16450)L(%d,50)", p_MaxLumNits * 10000);
    }
    return buf;
}

// ─────────────────────────────────────────────────────────────────────────

FFmpegEncoder::FFmpegEncoder(const EncoderVariant* p_pVariant)
    : m_pVariant(p_pVariant)
    , m_pCtx(nullptr)
    , m_pFrame(nullptr)
    , m_pPacket(nullptr)
    , m_pSwsCtx(nullptr)
    , m_QualityMode(0)
    , m_CRF(23)
    , m_BitRateKbps(8000)
    , m_Preset(5) // "medium" — see s_GetEncoderSettings preset list
    , m_Profile(2) // "high"
    , m_Tune(0)    // "none"
    , m_QP(23)
    , m_KeyframeIntervalSec(2)
    , m_Level(0) // "Auto"
    , m_AdvancedParams("")
    , m_Hdr10Mode(0)
    , m_HdrPrimaries(0)
    , m_HdrMaxLum(1000)
    , m_HdrMaxCLL(0)
    , m_HdrMaxFALL(0)
    , m_HwQuality(65)
    , m_HwDtsDelay(0)
    , m_FrameCount(0)
    , m_PacketCount(0)
    , m_TotalBytesSent(0)
    , m_HeaderSent(false)
    , m_EofSentToEncoder(false)
    , m_Error(errNone)
{
    g_Log(logLevelInfo, "GDC Encoder :: FFmpegEncoder() constructed (variant='%s')", p_pVariant ? p_pVariant->displayName : "NULL");
}

FFmpegEncoder::~FFmpegEncoder()
{
    if (m_pSwsCtx) sws_freeContext(m_pSwsCtx);
    if (m_pFrame) av_frame_free(&m_pFrame);
    if (m_pPacket) av_packet_free(&m_pPacket);
    if (m_pCtx) avcodec_free_context(&m_pCtx);
}

const EncoderVariant* FFmpegEncoder::s_FindVariant(const unsigned char* p_pUUID)
{
    for (int i = 0; i < g_NumEncoderVariants; ++i)
    {
        if (memcmp(p_pUUID, g_EncoderVariants[i].uuid, 16) == 0)
        {
            return &g_EncoderVariants[i];
        }
    }
    return nullptr;
}

bool FFmpegEncoder::s_IsVariantAvailable(const EncoderVariant* p_pVariant)
{
    return avcodec_find_encoder_by_name(p_pVariant->avCodecName) != nullptr;
}

StatusCode FFmpegEncoder::s_RegisterCodecs(HostListRef* p_pList)
{
    g_Log(logLevelInfo, "GDC Encoder :: s_RegisterCodecs called (%d variants defined)", g_NumEncoderVariants);

    for (int i = 0; i < g_NumEncoderVariants; ++i)
    {
        const EncoderVariant& v = g_EncoderVariants[i];
        if (!s_IsVariantAvailable(&v))
        {
            g_Log(logLevelInfo, "GDC Encoder :: '%s' unavailable, skipping", v.avCodecName);
            // e.g. h264_videotoolbox on non-Mac builds, or *_nvenc without
            // an NVIDIA GPU/driver — silently skip, don't fail the plugin.
            continue;
        }

        HostPropertyCollectionRef codecInfo;
        if (!codecInfo.IsValid())
        {
            g_Log(logLevelError, "GDC Encoder :: codecInfo.IsValid() FAILED for '%s'", v.avCodecName);
            return errAlloc;
        }

        codecInfo.SetProperty(pIOPropUUID, propTypeUInt8, v.uuid, 16);
        codecInfo.SetProperty(pIOPropName, propTypeString, v.displayName, strlen(v.displayName));
        codecInfo.SetProperty(pIOPropGroup, propTypeString, v.group, strlen(v.group));

        uint32_t fourCC = v.fourCC;
        codecInfo.SetProperty(pIOPropFourCC, propTypeUInt32, &fourCC, 1);

        uint32_t mediaTypeVal = mediaVideo;
        codecInfo.SetProperty(pIOPropMediaType, propTypeUInt32, &mediaTypeVal, 1);

        uint32_t dirVal = dirEncode;
        codecInfo.SetProperty(pIOPropCodecDirection, propTypeUInt32, &dirVal, 1);

        uint32_t colorModelVal = clrYUVp;
        codecInfo.SetProperty(pIOPropColorModel, propTypeUInt32, &colorModelVal, 1);

        // Missing in earlier versions of this plugin — Resolve appears to
        // need this to construct a video track at all; without it, render
        // fails immediately with "Failed to add video track" before any of
        // this plugin's own code (DoInit/DoOpen) ever runs.
        std::vector<uint8_t> dataRangeVec = { 0, 1 }; // 0=video range (default), 1=full range also offered
        codecInfo.SetProperty(pIOPropDataRange, propTypeUInt8, dataRangeVec.data(), static_cast<int>(dataRangeVec.size()));

        // 10-bit 4:2:0: Resolve 21.2 does NOT deliver planar data for clrYUVp
        // 4:2:0 at 16 bits per sample (host buffer is 3-way interleaved noise
        // from the plane point of view; PSNR 14 dB vs the source, bitrate 5x).
        // 8-bit 4:2:0 and 16-bit 4:2:2 are planar and verified, so 10-bit
        // variants always request 4:2:2 planes and FillFrameFromBuffer halves
        // the chroma height for the 4:2:0 encoders.
        uint8_t hSampling = 2, vSampling = (v.is422 || v.bitDepth > 8) ? 1 : 2;
        codecInfo.SetProperty(pIOPropHSubsampling, propTypeUInt8, &hSampling, 1);
        codecInfo.SetProperty(pIOPropVSubsampling, propTypeUInt8, &vSampling, 1);

        uint32_t bitDepthVal = static_cast<uint32_t>(v.bitDepth);
        codecInfo.SetProperty(pIOPropBitDepth, propTypeUInt32, &bitDepthVal, 1);
        // clrYUVp 4:2:0 only allows 8 or 16 bit SAMPLES (see IOPluginProps.h);
        // declaring sampleBits=10 made Resolve reject every 10-bit variant
        // ("Pixel Format was not defined"). 10-bit = 16-bit container, 10
        // meaningful bits (bitDepth). Sample alignment inside the container
        // is verified at runtime, see FillFrameFromBuffer.
        uint32_t sampleBitsVal = (v.bitDepth > 8) ? 16u : 8u;
        codecInfo.SetProperty(pIOPropBitsPerSample, propTypeUInt32, &sampleBitsVal, 1);

        // 0 here at registration time (the static capability declaration);
        // DoOpen() sets this to 2 later, on the per-instance buffer, once a
        // track is actually being encoded. Matches the SDK's own reference
        // x264 example, which uses the same two different values.
        const uint32_t temporalReorder = 0;
        codecInfo.SetProperty(pIOPropTemporalReordering, propTypeUInt32, &temporalReorder, 1);

        // Advertise support for progressive AND interlaced (top/bottom
        // field first) — a narrower declaration here risks Resolve
        // rejecting track creation for any timeline it doesn't consider an
        // exact match.
        const uint8_t fieldSupport = (fieldProgressive | fieldTop | fieldBottom);
        codecInfo.SetProperty(pIOPropFieldOrder, propTypeUInt8, &fieldSupport, 1);

        // Declared as 1 (thread-safe) in an earlier version, copied from
        // the reference without verifying this implementation actually
        // supports it. It doesn't: one shared AVCodecContext/AVFrame/
        // AVPacket per instance, no locking. If Resolve trusts the false
        // "thread safe" declaration and dispatches DoProcess concurrently
        // from its multiple worker threads onto the same encoder instance,
        // that's a data race — and matches the observed symptom exactly
        // (render succeeds sometimes, fails "Cannot add video track"
        // other times, same file, same settings, on retry).
        const uint8_t threadSafe = 0;
        codecInfo.SetProperty(pIOPropThreadSafe, propTypeUInt8, &threadSafe, 1);

        const uint8_t hwAcc = v.isHardware ? 1 : 0;
        codecInfo.SetProperty(pIOPropHWAcc, propTypeUInt8, &hwAcc, 1);

        std::vector<std::string> containerVec = { "mov", "mp4", "mkv" };
        for (int c = 0; c < g_NumContainerFormats; ++c)
        {
            containerVec.push_back(GdcContainer::s_UUIDHex(g_ContainerFormats[c]));
        }
        std::string valStrings;
        for (size_t c = 0; c < containerVec.size(); ++c)
        {
            valStrings.append(containerVec[c]);
            if (c < containerVec.size() - 1) valStrings.append(1, '\0');
        }
        codecInfo.SetProperty(pIOPropContainerList, propTypeString, valStrings.c_str(), valStrings.size());

        if (!p_pList->Append(&codecInfo))
        {
            g_Log(logLevelError, "GDC Encoder :: list->Append() FAILED for '%s'", v.displayName);
            return errFail;
        }
        g_Log(logLevelInfo, "GDC Encoder :: Registered '%s'", v.displayName);
    }

    g_Log(logLevelInfo, "GDC Encoder :: s_RegisterCodecs finished successfully");
    return errNone;
}

StatusCode FFmpegEncoder::s_GetEncoderSettings(unsigned char* p_pUUID, HostPropertyCollectionRef* p_pValues, HostListRef* p_pSettingsList)
{
    const EncoderVariant* pVariant = s_FindVariant(p_pUUID);
    if (!pVariant)
    {
        return errNoCodec;
    }

    int32_t qualityMode = 0;
    int32_t crf = 23;
    int32_t bitRateKbps = 8000;
    int32_t preset = 5;
    int32_t profile = 2;   // index into the H.264 profile list below, default "high"
    int32_t tune = 0;      // index into the tune list below, default "none"
    int32_t qp = 23;
    int32_t keyframeIntervalSec = 2; // ~48-60 frames at 24-30fps — professional-delivery default, was hardcoded to a flat 12-frame GOP before
    int32_t level = 0;      // 0 = "Auto" (don't force a Level)
    std::string advancedParams; // raw x264-params/x265-params passthrough

    p_pValues->GetINT32("gdc_quality_mode", qualityMode);
    p_pValues->GetINT32("gdc_crf", crf);
    p_pValues->GetINT32("gdc_bitrate", bitRateKbps);
    p_pValues->GetINT32("gdc_preset", preset);
    p_pValues->GetINT32("gdc_profile", profile);
    p_pValues->GetINT32("gdc_tune", tune);
    p_pValues->GetINT32("gdc_qp", qp);
    p_pValues->GetINT32("gdc_keyframe_interval", keyframeIntervalSec);
    p_pValues->GetINT32("gdc_level", level);
    p_pValues->GetString("gdc_advanced_params", advancedParams);
    int32_t hwQuality = 65; // hardware constant-quality target (1-100)
    p_pValues->GetINT32("gdc_hw_quality", hwQuality);
    int32_t hdr10Mode = 0;
    int32_t hdrPrimaries = 0;
    int32_t hdrMaxLum = 1000;
    int32_t hdrMaxCLL = 0;
    int32_t hdrMaxFALL = 0;
    p_pValues->GetINT32("gdc_hdr10_mode", hdr10Mode);
    p_pValues->GetINT32("gdc_hdr_primaries", hdrPrimaries);
    p_pValues->GetINT32("gdc_hdr_maxlum", hdrMaxLum);
    p_pValues->GetINT32("gdc_hdr_maxcll", hdrMaxCLL);
    p_pValues->GetINT32("gdc_hdr_maxfall", hdrMaxFALL);

    {
        HostUIConfigEntryRef brandItem("gdc_brand_label");
        brandItem.MakeLabel("GDC Resolve Encoder " GDC_ENCODER_VERSION " — Dumitru Cristinel Gordas (GDC)");
        if (!brandItem.IsSuccess() || !p_pSettingsList->Append(&brandItem))
        {
            return errFail;
        }
    }
    {
        HostUIConfigEntryRef sepItem("gdc_brand_sep");
        sepItem.MakeSeparator();
        if (!sepItem.IsSuccess() || !p_pSettingsList->Append(&sepItem))
        {
            return errFail;
        }
    }

    if (!pVariant->isHardware)
    {
        HostUIConfigEntryRef presetItem("gdc_preset");
        std::vector<std::string> texts = { "ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow" };
        std::vector<int32_t> values = { 0, 1, 2, 3, 4, 5, 6, 7, 8 };
        presetItem.MakeComboBox("Preset", texts, values, preset);
        if (!presetItem.IsSuccess() || !p_pSettingsList->Append(&presetItem))
        {
            return errFail;
        }
    }

    // Profile forcing: only meaningful for H.264 8-bit — the 10-bit
    // variant is already implicitly High10, and HEVC profile forcing
    // isn't offered here since it's not been validated against any
    // reference the way the H.264 list was (RMT's own panel only forces
    // H.264 profiles too).
    if (!pVariant->isHardware && !pVariant->isHEVC && pVariant->bitDepth == 8)
    {
        HostUIConfigEntryRef profileItem("gdc_profile");
        // "high422" REMOVED — no registered EncoderVariant ever uses a 4:2:2
        // pixel format (all are 4:2:0/NV12), so offering it here asked x264
        // to flag a High 4:2:2 bitstream for 4:2:0 data: misleading at best,
        // and a plausible real cause of intermittent avcodec_open2 failures
        // (see CLAUDE.md journal). A real 4:2:2 variant is a separate,
        // larger addition (needs its own EncoderVariant + AV_PIX_FMT_YUV422P
        // buffer handling), not done here.
        std::vector<std::string> texts = { "baseline", "main", "high" };
        std::vector<int32_t> values = { 0, 1, 2 };
        profileItem.MakeComboBox("Profile", texts, values, profile);
        if (!profileItem.IsSuccess() || !p_pSettingsList->Append(&profileItem))
        {
            return errFail;
        }
    }

    if (!pVariant->isHardware)
    {
        HostUIConfigEntryRef levelItem("gdc_level");
        std::vector<std::string> texts = { "Auto", "3.0", "3.1", "3.2", "4.0", "4.1", "4.2", "5.0", "5.1", "5.2" };
        std::vector<int32_t> values = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
        levelItem.MakeComboBox("Level", texts, values, level);
        if (!levelItem.IsSuccess() || !p_pSettingsList->Append(&levelItem))
        {
            return errFail;
        }
    }

    if (!pVariant->isHardware)
    {
        HostUIConfigEntryRef tuneItem("gdc_tune");
        std::vector<std::string> texts;
        std::vector<int32_t> values;
        if (pVariant->isHEVC)
        {
            // libx265 rejects "film" and "stillimage" — verified directly
            // against the actual encoder rather than assumed from x264's list.
            texts = { "none", "animation", "grain", "psnr", "ssim", "fastdecode", "zerolatency" };
        }
        else
        {
            texts = { "none", "film", "animation", "grain", "stillimage", "psnr", "ssim", "fastdecode", "zerolatency" };
        }
        for (int32_t i = 0; i < static_cast<int32_t>(texts.size()); ++i) values.push_back(i);
        tuneItem.MakeComboBox("Tune", texts, values, tune);
        if (!tuneItem.IsSuccess() || !p_pSettingsList->Append(&tuneItem))
        {
            return errFail;
        }
    }

    if (pVariant->isHardware)
    {
        // Hardware (VideoToolbox / NVENC) has no CRF or constant-QP mode:
        // offering those (as v1.7.0 did) silently encoded at a fixed
        // 12 Mbps whatever the slider said. Two honest modes instead.
        if (qualityMode != 0 && qualityMode != 1) qualityMode = 0;
        {
            HostUIConfigEntryRef modeItem("gdc_quality_mode");
            std::vector<std::string> texts = { "Constant Quality", "Target Bitrate" };
            std::vector<int32_t> values = { 0, 1 };
            modeItem.MakeRadioBox("Rate Control", texts, values, qualityMode);
            modeItem.SetTriggersUpdate(true);
            if (!modeItem.IsSuccess() || !p_pSettingsList->Append(&modeItem))
            {
                return errFail;
            }
        }
        if (qualityMode == 0)
        {
            HostUIConfigEntryRef qItem("gdc_hw_quality");
            qItem.MakeSlider("Quality (1-100)", "higher = better", hwQuality, 1, 100, 65);
            if (!qItem.IsSuccess() || !p_pSettingsList->Append(&qItem))
            {
                return errFail;
            }
        }
        else
        {
            HostUIConfigEntryRef brItem("gdc_bitrate");
            brItem.MakeSlider("Bit Rate", "kbps", bitRateKbps, 500, 100000, 8000, 100);
            if (!brItem.IsSuccess() || !p_pSettingsList->Append(&brItem))
            {
                return errFail;
            }
        }
    }
    else
    {
        {
            HostUIConfigEntryRef modeItem("gdc_quality_mode");
            std::vector<std::string> texts = { "Constant Quality (CRF)", "Target Bitrate", "Constant QP" };
            std::vector<int32_t> values = { 0, 1, 2 };
            modeItem.MakeRadioBox("Rate Control", texts, values, qualityMode);
            modeItem.SetTriggersUpdate(true);
            if (!modeItem.IsSuccess() || !p_pSettingsList->Append(&modeItem))
            {
                return errFail;
            }
        }

        if (qualityMode == 0)
        {
            HostUIConfigEntryRef crfItem("gdc_crf");
            crfItem.MakeSlider("Quality (CRF)", "lower = better", crf, 0, 51, 23);
            if (!crfItem.IsSuccess() || !p_pSettingsList->Append(&crfItem))
            {
                return errFail;
            }
        }
        else if (qualityMode == 1)
        {
            HostUIConfigEntryRef brItem("gdc_bitrate");
            brItem.MakeSlider("Bit Rate", "kbps", bitRateKbps, 500, 100000, 8000, 100);
            if (!brItem.IsSuccess() || !p_pSettingsList->Append(&brItem))
            {
                return errFail;
            }
        }
        else
        {
            HostUIConfigEntryRef qpItem("gdc_qp");
            qpItem.MakeSlider("Constant QP", "lower = better", qp, 0, 51, 23);
            if (!qpItem.IsSuccess() || !p_pSettingsList->Append(&qpItem))
            {
                return errFail;
            }
        }
    }

    {
        // Was a hardcoded 12-frame GOP (~0.5s at 24-30fps) regardless of
        // this setting existing — see OpenCodec, where it's now converted
        // to frames using the REAL source frame rate. 2s is the common
        // professional-delivery default (MainConcept and most NLEs default
        // in this range), not an arbitrary round number.
        HostUIConfigEntryRef gopItem("gdc_keyframe_interval");
        gopItem.MakeSlider("Keyframe Interval (sec)", "GOP length", keyframeIntervalSec, 1, 10, 2);
        if (!gopItem.IsSuccess() || !p_pSettingsList->Append(&gopItem))
        {
            return errFail;
        }
    }

    if (!pVariant->isHardware)
    {
        // MainConcept-style "expert" escape hatch: raw x264-params/
        // x265-params passthrough (psy-rd, aq-mode, ref, deblock, etc.)
        // without hand-wiring a dedicated slider for every single knob
        // those encoders expose.
        HostUIConfigEntryRef advItem("gdc_advanced_params");
        advItem.MakeTextBox("Advanced Params (x264/x265)", advancedParams, "e.g. aq-mode=3:psy-rd=1.0,0.15");
        if (!advItem.IsSuccess() || !p_pSettingsList->Append(&advItem))
        {
            return errFail;
        }
    }

    if (!pVariant->isHardware)
    {
        // HDR10 static metadata (SEI). The host does not supply it (see
        // BuildMasterDisplay), so it is set here. Only written when the
        // export is PQ; off by default so existing deliveries are unchanged.
        {
            HostUIConfigEntryRef modeItem("gdc_hdr10_mode");
            std::vector<std::string> texts = { "Off", "On (PQ exports only)" };
            std::vector<int32_t> values = { 0, 1 };
            modeItem.MakeComboBox("HDR10 Metadata", texts, values, hdr10Mode);
            modeItem.SetTriggersUpdate(true);
            if (!modeItem.IsSuccess() || !p_pSettingsList->Append(&modeItem))
            {
                return errFail;
            }
        }

        if (hdr10Mode > 0)
        {
            {
                HostUIConfigEntryRef primItem("gdc_hdr_primaries");
                std::vector<std::string> texts = { "P3-D65", "Rec.2020" };
                std::vector<int32_t> values = { 0, 1 };
                primItem.MakeComboBox("Mastering Primaries", texts, values, hdrPrimaries);
                if (!primItem.IsSuccess() || !p_pSettingsList->Append(&primItem))
                {
                    return errFail;
                }
            }
            {
                HostUIConfigEntryRef lumItem("gdc_hdr_maxlum");
                lumItem.MakeSlider("Mastering Peak", "nits", hdrMaxLum, 100, 10000, 1000, 50);
                if (!lumItem.IsSuccess() || !p_pSettingsList->Append(&lumItem))
                {
                    return errFail;
                }
            }
            {
                HostUIConfigEntryRef cllItem("gdc_hdr_maxcll");
                cllItem.MakeSlider("MaxCLL", "nits, 0 = not signalled", hdrMaxCLL, 0, 10000, 0, 10);
                if (!cllItem.IsSuccess() || !p_pSettingsList->Append(&cllItem))
                {
                    return errFail;
                }
            }
            {
                HostUIConfigEntryRef fallItem("gdc_hdr_maxfall");
                fallItem.MakeSlider("MaxFALL", "nits, 0 = not signalled", hdrMaxFALL, 0, 4000, 0, 10);
                if (!fallItem.IsSuccess() || !p_pSettingsList->Append(&fallItem))
                {
                    return errFail;
                }
            }
        }
    }

    return errNone;
}

void FFmpegEncoder::DoFlush()
{
    g_Log(logLevelInfo, "GDC Encoder :: DoFlush called (m_Error=%d, m_pCtx=%s)",
          static_cast<int>(m_Error), m_pCtx ? "valid" : "NULL");

    if (m_Error != errNone || !m_pCtx) return;

    // Matches the reference's exact draining architecture: loop calling a
    // single-step flush until nothing more comes out, rather than assuming
    // one avcodec_send_frame(null) + drain-to-EAGAIN pass captures
    // everything up front. Found by direct comparison with X264Encoder::
    // DoFlush, which loops DoProcess(NULL) the same way — this plugin's
    // previous single-shot approach may have been leaving encoder-internal
    // buffered frames (B-frame reorder lookahead) never extracted if
    // Resolve's actual EOF-signaling path is repeated DoProcess(NULL)
    // calls rather than (or in addition to) msgCodecFlush.
    StatusCode sts = FlushOneStep();
    while (sts == errNone)
    {
        sts = FlushOneStep();
    }

    g_Log(logLevelInfo, "GDC Encoder :: DoFlush complete — %d frames sent, %d packets, %lld total bytes sent to host",
          static_cast<int>(m_FrameCount), static_cast<int>(m_PacketCount), static_cast<long long>(m_TotalBytesSent));
}

StatusCode FFmpegEncoder::FlushOneStep()
{
    if (!m_EofSentToEncoder)
    {
        avcodec_send_frame(m_pCtx, nullptr);
        m_EofSentToEncoder = true;
    }

    int ret = avcodec_receive_packet(m_pCtx, m_pPacket);
    if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
    {
        return errMoreData; // truly nothing left to drain
    }
    else if (ret < 0)
    {
        char errBuf[128];
        av_strerror(ret, errBuf, sizeof(errBuf));
        g_Log(logLevelError, "GDC Encoder :: avcodec_receive_packet FAILED during flush: %s (%d)", errBuf, ret);
        return errFail;
    }

    ++m_PacketCount;
    m_TotalBytesSent += m_pPacket->size;
    g_Log(logLevelInfo, "GDC Encoder :: Flushed buffered packet #%d, %d bytes", static_cast<int>(m_PacketCount), m_pPacket->size);

    StatusCode sts = SendPacketToHost(m_pPacket);
    av_packet_unref(m_pPacket);
    if (sts != errNone)
    {
        g_Log(logLevelError, "GDC Encoder :: SendPacketToHost FAILED during flush (err=%d)", static_cast<int>(sts));
        ++g_GdcEncoderFailureCount;
        m_Error = sts;
        return sts;
    }

    return errNone; // there may be more buffered — caller should call again
}

StatusCode FFmpegEncoder::DoInit(HostPropertyCollectionRef* p_pProps)
{
    g_Log(logLevelInfo, "GDC Encoder :: DoInit called (variant='%s')", m_pVariant ? m_pVariant->displayName : "NULL");
    // The proven-working ffmpeg_encoder_plugin reference does nothing here
    // — it relies entirely on the colorModel/hSubsampling/vSubsampling
    // already declared in s_RegisterCodecs, rather than re-declaring them
    // per-instance. Setting them again here (as earlier versions of this
    // plugin did) likely conflicted with that negotiation and is the actual
    // cause of "Failed to add video track" happening before any of this
    // plugin's own encoding code ever ran.
    (void)p_pProps;
    return errNone;
}

StatusCode FFmpegEncoder::DoOpen(HostBufferRef* p_pBuff)
{
    g_Log(logLevelInfo, "GDC Encoder :: DoOpen called (variant='%s')", m_pVariant ? m_pVariant->displayName : "NULL");
    m_CommonProps.Load(p_pBuff);

    GdcInstallAvLog();
    g_Log(logLevelInfo, "GDC Encoder :: version " GDC_ENCODER_VERSION ", libavcodec %s", av_version_info());

    p_pBuff->GetINT32("gdc_quality_mode", m_QualityMode);
    p_pBuff->GetINT32("gdc_crf", m_CRF);
    p_pBuff->GetINT32("gdc_bitrate", m_BitRateKbps);
    p_pBuff->GetINT32("gdc_preset", m_Preset);
    p_pBuff->GetINT32("gdc_profile", m_Profile);
    p_pBuff->GetINT32("gdc_tune", m_Tune);
    p_pBuff->GetINT32("gdc_qp", m_QP);
    p_pBuff->GetINT32("gdc_keyframe_interval", m_KeyframeIntervalSec);
    p_pBuff->GetINT32("gdc_level", m_Level);
    p_pBuff->GetString("gdc_advanced_params", m_AdvancedParams);
    p_pBuff->GetINT32("gdc_hdr10_mode", m_Hdr10Mode);
    p_pBuff->GetINT32("gdc_hdr_primaries", m_HdrPrimaries);
    p_pBuff->GetINT32("gdc_hdr_maxlum", m_HdrMaxLum);
    p_pBuff->GetINT32("gdc_hdr_maxcll", m_HdrMaxCLL);
    p_pBuff->GetINT32("gdc_hdr_maxfall", m_HdrMaxFALL);
    p_pBuff->GetINT32("gdc_hw_quality", m_HwQuality);

    const StatusCode openSts = OpenCodec(p_pBuff);
    if (openSts != errNone) ++g_GdcEncoderFailureCount;
    return openSts;
}

StatusCode FFmpegEncoder::OpenCodec(HostBufferRef* p_pBuff)
{
    const AVCodec* pCodec = avcodec_find_encoder_by_name(m_pVariant->avCodecName);
    if (!pCodec)
    {
        g_Log(logLevelError, "GDC Encoder :: Encoder '%s' not available on this system", m_pVariant->avCodecName);
        return errNoCodec;
    }

    m_pCtx = avcodec_alloc_context3(pCodec);
    if (!m_pCtx)
    {
        return errAlloc;
    }

    m_pCtx->width = m_CommonProps.GetWidth();
    m_pCtx->height = m_CommonProps.GetHeight();
    m_pCtx->time_base = AVRational{ static_cast<int>(m_CommonProps.GetFrameRateDen()), static_cast<int>(m_CommonProps.GetFrameRateNum()) };
    m_pCtx->framerate = AVRational{ static_cast<int>(m_CommonProps.GetFrameRateNum()), static_cast<int>(m_CommonProps.GetFrameRateDen()) };
    g_Log(logLevelInfo, "GDC Encoder :: width=%d height=%d frDen=%d frNum=%d",
          m_pCtx->width, m_pCtx->height, static_cast<int>(m_CommonProps.GetFrameRateDen()), static_cast<int>(m_CommonProps.GetFrameRateNum()));
    // GOP length: was a hardcoded 12 frames (~0.5s at 24-30fps) regardless
    // of source frame rate — far below the professional-delivery norm of
    // ~2s, wasting bit-rate on unnecessarily frequent I-frames instead of
    // spending it on quality. Now derived from the REAL source frame rate
    // (m_KeyframeIntervalSec is user-configurable, see s_GetEncoderSettings).
    {
        double fps = 24.0;
        if (m_CommonProps.GetFrameRateDen() > 0)
        {
            fps = static_cast<double>(m_CommonProps.GetFrameRateNum()) / static_cast<double>(m_CommonProps.GetFrameRateDen());
        }
        int gopFrames = static_cast<int>(std::lround(static_cast<double>(m_KeyframeIntervalSec) * fps));
        m_pCtx->gop_size = (gopFrames > 0) ? gopFrames : 1;
    }
    m_pCtx->max_b_frames = 2;
    m_pCtx->pix_fmt = m_pVariant->preferredPixFmt;
    m_pCtx->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
    m_pCtx->color_range = m_CommonProps.IsFullRange() ? AVCOL_RANGE_JPEG : AVCOL_RANGE_MPEG;

    // Explicit multi-threading — was left on FFmpeg's implicit default,
    // fine functionally but unpredictable in how it scales across
    // machines with many cores. Capped well above any real workstation's
    // core count purely as a sanity bound, not a meaningful limit.
    {
        unsigned int hwThreads = std::thread::hardware_concurrency();
        m_pCtx->thread_count = static_cast<int>((hwThreads > 0 && hwThreads <= 32) ? hwThreads : (hwThreads > 32 ? 32 : 8));
    }

    // Color tags from the host's CICP-style clrPrimaries/clrTransfer/clrMtx
    // (ISO/IEC 23001-8 numbering assumed, NOT yet confirmed against a real
    // Resolve export). Only whitelisted values are forwarded; anything
    // absent/unknown falls back to Rec.709 — never inferred from bit depth.
    {
        int16_t rawPri = 0, rawTrc = 0, rawMtx = 0;
        const bool havePri = p_pBuff->GetINT16(pIOPropColorPrimaries, rawPri);
        const bool haveTrc = p_pBuff->GetINT16(pIOTransferCharacteristics, rawTrc);
        const bool haveMtx = p_pBuff->GetINT16(pIOColorMatrix, rawMtx);

        AVColorPrimaries pri = AVCOL_PRI_BT709;
        AVColorTransferCharacteristic trc = AVCOL_TRC_BT709;
        AVColorSpace mtx = AVCOL_SPC_BT709;

        if (havePri && (rawPri == AVCOL_PRI_BT709 || rawPri == AVCOL_PRI_BT2020 ||
                        rawPri == AVCOL_PRI_SMPTE431 || rawPri == AVCOL_PRI_SMPTE432))
            pri = static_cast<AVColorPrimaries>(rawPri); // Rec.709 / Rec.2020 / P3-DCI (11) / P3-D65 (12); host numbering CICP, verified in Resolve 21.1
        if (haveTrc && (rawTrc == AVCOL_TRC_BT709 || rawTrc == AVCOL_TRC_SMPTE2084 ||
                        rawTrc == AVCOL_TRC_ARIB_STD_B67 || rawTrc == AVCOL_TRC_BT2020_10 ||
                        rawTrc == AVCOL_TRC_SMPTE428))
            trc = static_cast<AVColorTransferCharacteristic>(rawTrc); // 709 / PQ / HLG / SMPTE428 (DCI 2.6, host sends 17 for P3 outputs)
        else if (pri == AVCOL_PRI_BT2020)
            trc = AVCOL_TRC_BT2020_10; // wide gamut, no transfer signalled

        if (haveMtx && (rawMtx == AVCOL_SPC_BT709 || rawMtx == AVCOL_SPC_BT2020_NCL))
            mtx = static_cast<AVColorSpace>(rawMtx);
        else if (pri == AVCOL_PRI_BT2020)
            mtx = AVCOL_SPC_BT2020_NCL;
        // P3-D65 has no dedicated NCL matrix here: BT.709 matrix is the
        // common convention for P3-D65 YUV (Apple/DCI-P3 deliverables).

        m_pCtx->color_primaries = pri;
        m_pCtx->color_trc = trc;
        m_pCtx->colorspace = mtx;
        g_Log(logLevelInfo, "GDC Encoder :: color tags host(pri=%d/%d trc=%d/%d mtx=%d/%d) -> applied pri=%d trc=%d mtx=%d",
              static_cast<int>(rawPri), havePri, static_cast<int>(rawTrc), haveTrc, static_cast<int>(rawMtx), haveMtx,
              static_cast<int>(pri), static_cast<int>(trc), static_cast<int>(mtx));
    }

    if (m_QualityMode == 1)
    {
        m_pCtx->bit_rate = static_cast<int64_t>(m_BitRateKbps) * 1000;
        m_pCtx->rc_max_rate = m_pCtx->bit_rate;
        m_pCtx->rc_buffer_size = static_cast<int>(m_pCtx->bit_rate);
    }

    AVDictionary* pOpts = nullptr;
    std::string hdrMdcv, hdrCll; // handed to the GDC container (mdcv/clli boxes)
    if (!m_pVariant->isHardware)
    {
        static const char* s_PresetNames[] = { "ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow" };
        int presetIdx = (m_Preset >= 0 && m_Preset < 9) ? m_Preset : 5;
        av_dict_set(&pOpts, "preset", s_PresetNames[presetIdx], 0);

        if (m_QualityMode == 0)
        {
            char crfStr[8];
            snprintf(crfStr, sizeof(crfStr), "%d", m_CRF);
            av_dict_set(&pOpts, "crf", crfStr, 0);
        }
        else if (m_QualityMode == 2)
        {
            // Constant QP — same-numbered scale as CRF (0-51, lower =
            // better) but disables adaptive rate control entirely, giving
            // every frame the exact same quantizer. Matches RMT's own "QP"
            // rate-control mode.
            char qpStr[8];
            snprintf(qpStr, sizeof(qpStr), "%d", m_QP);
            av_dict_set(&pOpts, "qp", qpStr, 0);
        }

        // Profile forcing — H.264 8-bit software only (see
        // s_GetEncoderSettings for why HEVC/10-bit/hardware are excluded).
        // "high422" removed — see s_GetEncoderSettings for why.
        if (!m_pVariant->isHEVC && m_pVariant->bitDepth == 8)
        {
            static const char* s_ProfileNames[] = { "baseline", "main", "high" };
            int profileIdx = (m_Profile >= 0 && m_Profile < 3) ? m_Profile : 2;
            av_dict_set(&pOpts, "profile", s_ProfileNames[profileIdx], 0);
        }

        // Level — real gap vs. any professional encoder: affects
        // decoder/device compatibility (e.g. some hardware players cap out
        // at Level 4.1). Index 0 is "Auto" — leave unset, let x264/x265
        // infer one from resolution/bitrate, same as before this change.
        if (m_Level > 0)
        {
            static const char* s_LevelNames[] = { "3.0", "3.1", "3.2", "4.0", "4.1", "4.2", "5.0", "5.1", "5.2" };
            int levelIdx = m_Level - 1;
            if (levelIdx >= 0 && levelIdx < static_cast<int>(sizeof(s_LevelNames) / sizeof(s_LevelNames[0])))
            {
                av_dict_set(&pOpts, "level", s_LevelNames[levelIdx], 0);
            }
        }

        // Tune — codec-appropriate list (libx265 rejects "film" and
        // "stillimage", verified directly against the encoder). Index 0 is
        // always "none" — skip setting the option entirely in that case,
        // since x264/x265 don't accept an explicit "none" tune string.
        if (m_Tune > 0)
        {
            static const char* s_TuneNamesAvc[] = { "none", "film", "animation", "grain", "stillimage", "psnr", "ssim", "fastdecode", "zerolatency" };
            static const char* s_TuneNamesHevc[] = { "none", "animation", "grain", "psnr", "ssim", "fastdecode", "zerolatency" };
            const char** pTuneNames = m_pVariant->isHEVC ? s_TuneNamesHevc : s_TuneNamesAvc;
            int tuneCount = m_pVariant->isHEVC ? 7 : 9;
            if (m_Tune > 0 && m_Tune < tuneCount)
            {
                av_dict_set(&pOpts, "tune", pTuneNames[m_Tune], 0);
            }
        }

        // MainConcept-style "expert" escape hatch — raw x264-params/
        // x265-params passthrough (aq-mode, psy-rd, ref, deblock, etc.)
        // without hand-wiring a dedicated UI slider for every knob those
        // encoders expose. libavcodec forwards this string as-is to
        // x264_param_parse/x265_param_parse; a malformed string is
        // rejected by that parser (avcodec_open2 fails cleanly with an
        // error already logged below), it doesn't crash the plugin.
        // HDR10 static metadata — only when enabled in the panel AND the
        // export is PQ. User-supplied advanced params are appended AFTER, so
        // an explicit master-display/max-cll there still wins.
        std::string codecParams;
        if (m_Hdr10Mode > 0)
        {
            if (m_pCtx->color_trc == AVCOL_TRC_SMPTE2084)
            {
                const char* mdKey = m_pVariant->isHEVC ? "master-display" : "mastering-display";
                const char* cllKey = m_pVariant->isHEVC ? "max-cll" : "cll";
                hdrMdcv = BuildMasterDisplay(m_HdrPrimaries, m_HdrMaxLum);
                codecParams = std::string(mdKey) + "=" + hdrMdcv;
                if (m_HdrMaxCLL > 0 || m_HdrMaxFALL > 0)
                {
                    hdrCll = std::to_string(m_HdrMaxCLL) + "," + std::to_string(m_HdrMaxFALL);
                    codecParams += std::string(":") + cllKey + "=" + std::to_string(m_HdrMaxCLL) + "," + std::to_string(m_HdrMaxFALL);
                }
                g_Log(logLevelInfo, "GDC Encoder :: HDR10 params applied: %s", codecParams.c_str());
            }
            else
            {
                g_Log(logLevelInfo, "GDC Encoder :: HDR10 metadata requested but the export is not PQ - skipped");
            }
        }
        if (!m_AdvancedParams.empty())
        {
            if (!codecParams.empty()) codecParams += ":";
            codecParams += m_AdvancedParams;
        }
        if (!codecParams.empty())
        {
            const char* paramKey = m_pVariant->isHEVC ? "x265-params" : "x264-params";
            av_dict_set(&pOpts, paramKey, codecParams.c_str(), 0);
        }
    }
    else
    {
        // Hardware encoders. "Constant Quality" maps to the encoder's own
        // quality scale: VideoToolbox takes global_quality 1-100 with the
        // QSCALE flag (kVTCompressionPropertyKey_Quality, Apple Silicon);
        // NVENC has no such scale here, so it keeps a bitrate target.
        const bool isVT = (strstr(m_pVariant->avCodecName, "videotoolbox") != nullptr);
        if (m_QualityMode != 1)
        {
            int q = m_HwQuality;
            if (q < 1) q = 1;
            if (q > 100) q = 100;
            if (isVT)
            {
                m_pCtx->flags |= AV_CODEC_FLAG_QSCALE;
                m_pCtx->global_quality = q * FF_QP2LAMBDA;
                m_pCtx->bit_rate = 0;
                g_Log(logLevelInfo, "GDC Encoder :: hardware rate control: constant quality %d/100", q);
            }
            else
            {
                m_pCtx->bit_rate = 12000000;
                g_Log(logLevelWarn, "GDC Encoder :: hardware rate control: constant quality not available for '%s', using 12 Mbps", m_pVariant->avCodecName);
            }
        }
        else
        {
            g_Log(logLevelInfo, "GDC Encoder :: hardware rate control: target bitrate %d kbps", static_cast<int>(m_BitRateKbps));
        }
        if (isVT)
        {
            // Never fall back silently to Apple's software encoder: a
            // "hardware" variant that quietly ran in software would be a
            // different product than the one selected in Deliver.
            av_dict_set(&pOpts, "allow_sw", "0", 0);
            av_dict_set(&pOpts, "realtime", "0", 0);
        }
    }

    // Hardware encoders (NVENC especially) can fail to open transiently —
    // confirmed on real hardware (RTX 4070 Ti SUPER): the exact same
    // resolution/settings failed with avcodec_open2 returning ENOSYS
    // once, then succeeded twice in a row immediately after with zero
    // code changes. Most likely the NVENC session was briefly held by
    // something else (possibly Resolve's own NVDEC/NVENC use). Software
    // encoders (x264/x265) don't exhibit this — a genuine parameter
    // problem there fails every time, so no retry for those.
    const int maxAttempts = m_pVariant->isHardware ? 3 : 1;
    int openResult = -1;
    for (int attempt = 1; attempt <= maxAttempts; ++attempt)
    {
        openResult = avcodec_open2(m_pCtx, pCodec, &pOpts);
        if (openResult >= 0)
        {
            if (attempt > 1)
            {
                g_Log(logLevelInfo, "GDC Encoder :: avcodec_open2 succeeded for '%s' on attempt %d/%d",
                      m_pVariant->avCodecName, attempt, maxAttempts);
            }
            break;
        }
        g_Log(logLevelWarn, "GDC Encoder :: avcodec_open2 failed for '%s' on attempt %d/%d (%d)",
              m_pVariant->avCodecName, attempt, maxAttempts, openResult);
        if (attempt < maxAttempts)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(300));
        }
    }
    av_dict_free(&pOpts);
    if (openResult < 0)
    {
        g_Log(logLevelError, "GDC Encoder :: avcodec_open2 failed for '%s' after %d attempt(s) (%d)",
              m_pVariant->avCodecName, maxAttempts, openResult);
        return errFail;
    }

    // H.264 uses the reference-matched Annex-B cookie exactly (proven
    // working — see comment history). H.265 uses a properly structured
    // ISO/IEC 14496-15 hvcC box instead: the official reference has no
    // HEVC variant at all, so the Annex-B approach was never actually
    // validated for it, and "encode completes with zero errors but no
    // video ends up in the file" is consistent with Resolve's writer
    // needing real hvcC structure it can't get from a raw concatenation.
    if (strstr(m_pVariant->avCodecName, "videotoolbox") != nullptr && m_pCtx->max_b_frames > 0 && m_pCtx->has_b_frames > 0)
    {
        m_HwDtsDelay = std::max(m_pCtx->has_b_frames, m_pCtx->max_b_frames);
    }
    g_Log(logLevelInfo, "GDC Encoder :: encoder '%s' opened: pix_fmt=%s threads=%d gop=%d b-frames=%d reorder delay=%d (synthesised dts delay=%d)",
          m_pVariant->avCodecName, av_get_pix_fmt_name(m_pCtx->pix_fmt), m_pCtx->thread_count, m_pCtx->gop_size,
          m_pCtx->max_b_frames, m_pCtx->has_b_frames, m_HwDtsDelay);
    g_Log(logLevelInfo, "GDC Encoder :: rate control: mode=%d (0=CRF 1=bitrate 2=QP) crf=%d qp=%d bitrate=%dkbps hwQuality=%d preset=%d tune=%d level=%d",
          m_QualityMode, m_CRF, m_QP, m_BitRateKbps, m_HwQuality, m_Preset, m_Tune, m_Level);

    if (m_pCtx->extradata && m_pCtx->extradata_size > 0)
    {
        std::vector<std::vector<uint8_t>> nals;
        SplitAnnexBNALs(m_pCtx->extradata, m_pCtx->extradata_size, nals);

        std::vector<uint8_t> cookie;
        uint32_t cookieType = 0;

        if (m_pVariant->isHEVC)
        {
            cookie = BuildHevcConfigRecord(nals);
            cookieType = GDC_FOURCC('h', 'v', 'c', 'C');
        }
        else
        {
            for (auto& nal : nals)
            {
                int nalType = NalTypeH264(nal);
                if (nalType == 6) continue; // skip SEI, matching the reference

                static const uint8_t s_StartCode[4] = { 0, 0, 0, 1 };
                cookie.insert(cookie.end(), s_StartCode, s_StartCode + 4);
                cookie.insert(cookie.end(), nal.begin(), nal.end());
            }
            cookieType = 0; // matches the official SDK reference exactly
        }

        if (!cookie.empty())
        {
            p_pBuff->SetProperty(pIOPropMagicCookie, propTypeUInt8, cookie.data(), static_cast<int>(cookie.size()));
            p_pBuff->SetProperty(pIOPropMagicCookieType, propTypeUInt32, &cookieType, 1);
            g_Log(logLevelInfo, "GDC Encoder :: Built %s cookie, %d bytes",
                  m_pVariant->isHEVC ? "hvcC" : "Annex-B (reference-matched)", static_cast<int>(cookie.size()));
        }
        else
        {
            g_Log(logLevelError, "GDC Encoder :: Cookie build produced EMPTY result (isHEVC=%d)", m_pVariant->isHEVC ? 1 : 0);
        }
    }

    // Color tags + HDR static metadata for the GDC container (custom props
    // on this codec buffer, read back in GdcContainer::AddVideoTrack). Resolve's
    // own writers ignore them; harmless there.
    {
        int32_t v = static_cast<int32_t>(m_pCtx->color_primaries);
        p_pBuff->SetProperty("gdc_pri", propTypeInt32, &v, 1);
        v = static_cast<int32_t>(m_pCtx->color_trc);
        p_pBuff->SetProperty("gdc_trc", propTypeInt32, &v, 1);
        v = static_cast<int32_t>(m_pCtx->colorspace);
        p_pBuff->SetProperty("gdc_mtx", propTypeInt32, &v, 1);
        v = m_CommonProps.IsFullRange() ? 1 : 0;
        p_pBuff->SetProperty("gdc_range", propTypeInt32, &v, 1);
        if (!hdrMdcv.empty()) p_pBuff->SetProperty("gdc_mdcv", propTypeString, hdrMdcv.c_str(), hdrMdcv.size());
        if (!hdrCll.empty()) p_pBuff->SetProperty("gdc_cll", propTypeString, hdrCll.c_str(), hdrCll.size());
    }

    m_pFrame = av_frame_alloc();
    m_pFrame->format = m_pCtx->pix_fmt;
    m_pFrame->width = m_pCtx->width;
    m_pFrame->height = m_pCtx->height;
    if (av_frame_get_buffer(m_pFrame, 32) < 0)
    {
        g_Log(logLevelError, "GDC Encoder :: av_frame_get_buffer FAILED (width=%d height=%d)", m_pCtx->width, m_pCtx->height);
        return errAlloc;
    }

    m_pPacket = av_packet_alloc();

    // Found by direct line-by-line comparison against the official
    // reference's DoOpen — it always sets this explicitly (0 for single
    // pass), even though the property doc says "absent" should also mean
    // single-pass. Matching the reference exactly since I've been wrong
    // about "should be equivalent" assumptions before in this exact spot.
    uint8_t isMultiPass = 0;
    p_pBuff->SetProperty(pIOPropMultiPass, propTypeUInt8, &isMultiPass, 1);

    uint32_t temporalVal = 2;
    p_pBuff->SetProperty(pIOPropTemporalReordering, propTypeUInt32, &temporalVal, 1);

    g_Log(logLevelInfo, "GDC Encoder :: OpenCodec finished successfully, returning errNone");
    return errNone;
}

StatusCode FFmpegEncoder::FillFrameFromBuffer(HostBufferRef* p_pBuff, AVFrame* p_pFrame)
{
    char* pBuf = nullptr;
    size_t bufSize = 0;
    if (!p_pBuff->LockBuffer(&pBuf, &bufSize))
    {
        return errFail;
    }

    uint32_t width = m_pCtx->width;
    uint32_t height = m_pCtx->height;

    if (m_FrameCount == 0)
    {
        g_Log(logLevelInfo, "GDC Encoder :: first host frame buffer: %zu bytes for %ux%u (variant %d-bit%s)",
              bufSize, width, height, m_pVariant->bitDepth, m_pVariant->is422 ? " 4:2:2" : " 4:2:0");
#ifdef GDC_DEBUG_DUMP_DIR
        {
            std::string dumpPath = std::string(GDC_DEBUG_DUMP_DIR) + "/host_frame0_" + std::to_string(m_pVariant->bitDepth) + (m_pVariant->is422 ? "_422" : "_420") + ".raw";
            if (FILE* fp = fopen(dumpPath.c_str(), "wb")) { fwrite(pBuf, 1, bufSize, fp); fclose(fp); }
        }
#endif
    }

    // 4:2:0 chroma planes are (w/2)x(h/2) below: odd dimensions would read
    // past the tightly packed source layout. Refuse instead of corrupting.
    if ((width & 1u) || (!m_pVariant->is422 && (height & 1u)))
    {
        g_Log(logLevelError, "GDC Encoder :: odd frame size %ux%u not supported for subsampled planar input", width, height);
        p_pBuff->UnlockBuffer();
        return errFail;
    }

    // Encoder may still hold a reference to the previous frame's buffers
    // (x264/x265 lookahead, hardware encoders): make sure we own them.
    if (av_frame_make_writable(p_pFrame) < 0)
    {
        g_Log(logLevelError, "GDC Encoder :: av_frame_make_writable FAILED at frame %d", static_cast<int>(m_FrameCount));
        p_pBuff->UnlockBuffer();
        return errAlloc;
    }

    // 8-bit: planar YUV 4:2:0 (Y, U, V tightly packed), matching
    // pIOPropColorModel=clrYUVp + 2/2 subsampling. 10-bit: the host sends
    // planar 4:2:2 with 16-bit little-endian samples (10 meaningful bits),
    // see s_RegisterCodecs for why 4:2:0 is not requested at 16 bits.
    const bool is10Bit = (m_pVariant->bitDepth == 10);
    const bool is422 = m_pVariant->is422;            // what the ENCODER wants
    const bool hostIs422 = is422 || is10Bit;         // what the HOST delivers
    const AVPixelFormat srcFmt = is10Bit ? AV_PIX_FMT_YUV422P16LE
                                         : (is422 ? AV_PIX_FMT_YUV422P : AV_PIX_FMT_YUV420P);
    const size_t chromaH = hostIs422 ? height : (height / 2);
    const int bytesPerSample = is10Bit ? 2 : 1;

    const size_t wantBytes = gdc::HostPlanarFrameBytes(static_cast<int>(width), static_cast<int>(height), hostIs422, bytesPerSample);
    if (bufSize < wantBytes)
    {
        g_Log(logLevelError, "GDC Encoder :: host frame buffer too small: %zu bytes, expected %zu for %ux%u %d-bit %s planar",
              bufSize, wantBytes, width, height, m_pVariant->bitDepth, hostIs422 ? "4:2:2" : "4:2:0");
        p_pBuff->UnlockBuffer();
        return errFail;
    }

    const uint8_t* pSrcData[4] = {};
    int srcLinesize[4] = {};
    pSrcData[0] = reinterpret_cast<const uint8_t*>(pBuf);
    srcLinesize[0] = static_cast<int>(width) * bytesPerSample;
    pSrcData[1] = pSrcData[0] + (static_cast<size_t>(width) * height * bytesPerSample);
    srcLinesize[1] = (static_cast<int>(width) / 2) * bytesPerSample;
    pSrcData[2] = pSrcData[1] + ((static_cast<size_t>(width) / 2) * chromaH * bytesPerSample);
    srcLinesize[2] = (static_cast<int>(width) / 2) * bytesPerSample;

    if (is10Bit && (static_cast<AVPixelFormat>(p_pFrame->format) == AV_PIX_FMT_YUV422P10LE ||
                    static_cast<AVPixelFormat>(p_pFrame->format) == AV_PIX_FMT_YUV420P10LE))
    {
        // 16 -> 10 bit with rounding, clamped (host samples are value << 6).
        const int cw = static_cast<int>(width) / 2;
        const auto* sY = reinterpret_cast<const uint16_t*>(pSrcData[0]);
        gdc::Plane16To10(sY, width, reinterpret_cast<uint16_t*>(p_pFrame->data[0]),
                         static_cast<size_t>(p_pFrame->linesize[0]) / 2, static_cast<int>(width), static_cast<int>(height));
        for (int plane = 1; plane < 3; ++plane)
        {
            const auto* sC = reinterpret_cast<const uint16_t*>(pSrcData[plane]);
            auto* dC = reinterpret_cast<uint16_t*>(p_pFrame->data[plane]);
            const size_t dStride = static_cast<size_t>(p_pFrame->linesize[plane]) / 2;
            if (is422)
                gdc::Plane16To10(sC, static_cast<size_t>(cw), dC, dStride, cw, static_cast<int>(height));
            else
                gdc::Chroma422To420_16To10(sC, static_cast<size_t>(cw), dC, dStride, cw, static_cast<int>(height));
        }
    }
    else if (static_cast<AVPixelFormat>(p_pFrame->format) == srcFmt)
    {
        av_image_copy(p_pFrame->data, p_pFrame->linesize, pSrcData, srcLinesize, srcFmt,
                       static_cast<int>(width), static_cast<int>(height));
    }
    else
    {
        if (!m_pSwsCtx)
        {
            m_pSwsCtx = sws_getContext(width, height, srcFmt,
                                        width, height, static_cast<AVPixelFormat>(p_pFrame->format),
                                        SWS_BILINEAR, nullptr, nullptr, nullptr);
        }
        if (!m_pSwsCtx)
        {
            g_Log(logLevelError, "GDC Encoder :: sws_getContext FAILED (%ux%u)", width, height);
            p_pBuff->UnlockBuffer();
            return errFail;
        }
        sws_scale(m_pSwsCtx, pSrcData, srcLinesize, 0, height, p_pFrame->data, p_pFrame->linesize);
    }

    if (is10Bit && m_FrameCount == 0)
    {
        // One-off diagnostic: raw range of the host's 16-bit container
        // (10-bit content arrives as value<<6, so max ~ 60160 for legal white).
        const uint16_t* pY = reinterpret_cast<const uint16_t*>(pSrcData[0]);
        const size_t n = static_cast<size_t>(width) * height;
        uint16_t maxV = 0, minV = 0xFFFF;
        uint16_t orAll = 0;
        for (size_t i = 0; i < n; i += 7)
        {
            maxV = std::max(maxV, pY[i]);
            minV = std::min(minV, pY[i]);
            orAll |= pY[i];
        }
        g_Log(logLevelInfo, "GDC Encoder :: 10-bit%s first frame Y: min=%u max=%u lowBitsSet=%d",
              is422 ? " 4:2:2" : "", static_cast<unsigned>(minV), static_cast<unsigned>(maxV), (orAll & 0x3F) ? 1 : 0);
    }

    p_pBuff->UnlockBuffer();

    int64_t pts = 0;
    p_pBuff->GetINT64(pIOPropPTS, pts);
    p_pFrame->pts = pts;

    return errNone;
}

StatusCode FFmpegEncoder::DoProcess(HostBufferRef* p_pBuff)
{
    if (m_Error != errNone) return m_Error;

    if ((p_pBuff == nullptr) || !p_pBuff->IsValid())
    {
        StatusCode sts = FlushOneStep();
        g_Log(logLevelInfo, "GDC Encoder :: DoProcess(null) — flush step returned %d (%d frames sent, %d packets so far)",
              static_cast<int>(sts), static_cast<int>(m_FrameCount), static_cast<int>(m_PacketCount));
        return sts;
    }

    if (m_FrameCount == 0)
    {
        g_Log(logLevelInfo, "GDC Encoder :: DoProcess called for the first time");
    }

    StatusCode sts = FillFrameFromBuffer(p_pBuff, m_pFrame);
    if (sts != errNone)
    {
        g_Log(logLevelError, "GDC Encoder :: FillFrameFromBuffer FAILED (err=%d) at frame %d", static_cast<int>(sts), static_cast<int>(m_FrameCount));
        ++g_GdcEncoderFailureCount;
        m_Error = sts;
        return sts;
    }

    sts = EncodeFrame(m_pFrame);
    if (sts != errNone)
    {
        // Latch the error: every later call fails too, and the GDC
        // container removes the partial file instead of finalising it.
        ++g_GdcEncoderFailureCount;
        m_Error = sts;
    }
    return sts;
}

StatusCode FFmpegEncoder::EncodeFrame(AVFrame* p_pFrame)
{
    int ret = avcodec_send_frame(m_pCtx, p_pFrame);
    if (ret < 0)
    {
        char errBuf[128];
        av_strerror(ret, errBuf, sizeof(errBuf));
        g_Log(logLevelError, "GDC Encoder :: avcodec_send_frame failed at frame %d: %s (%d)", static_cast<int>(m_FrameCount), errBuf, ret);
        return errFail;
    }
    ++m_FrameCount;
    return DrainPackets();
}

StatusCode FFmpegEncoder::DrainPackets()
{
    while (true)
    {
        int ret = avcodec_receive_packet(m_pCtx, m_pPacket);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
        {
            break;
        }
        else if (ret < 0)
        {
            char errBuf[128];
            av_strerror(ret, errBuf, sizeof(errBuf));
            g_Log(logLevelError, "GDC Encoder :: avcodec_receive_packet FAILED at frame %d: %s (%d)", static_cast<int>(m_FrameCount), errBuf, ret);
            return errFail;
        }

        ++m_PacketCount;
        m_TotalBytesSent += m_pPacket->size;
        if (m_PacketCount == 1)
        {
            g_Log(logLevelInfo, "GDC Encoder :: First packet received from encoder, %d bytes", m_pPacket->size);
        }
        if (m_PacketCount % 25 == 0)
        {
            g_Log(logLevelInfo, "GDC Encoder :: packet #%d, %d bytes this packet, %lld total bytes sent so far",
                  static_cast<int>(m_PacketCount), m_pPacket->size, static_cast<long long>(m_TotalBytesSent));
        }

        StatusCode sts = SendPacketToHost(m_pPacket);
        av_packet_unref(m_pPacket);
        if (sts != errNone)
        {
            g_Log(logLevelError, "GDC Encoder :: SendPacketToHost FAILED (err=%d) at packet %d", static_cast<int>(sts), static_cast<int>(m_PacketCount));
            return sts;
        }
    }
    return errNone;
}

StatusCode FFmpegEncoder::SendPacketToHost(AVPacket* p_pPkt)
{
    // Two-pass, no intermediate heap buffer: measure, then write straight
    // into the host buffer. Empty result = packet already length-prefixed
    // (some hardware encoders) -> copy it as-is.
    const size_t convSize = ConvertAnnexBToLengthPrefixedRaw(p_pPkt->data, p_pPkt->size, nullptr);
    const bool passthrough = (convSize == 0);
    const size_t outSize = passthrough ? static_cast<size_t>(p_pPkt->size) : convSize;

    HostBufferRef outBuf(false);
    if (!outBuf.IsValid() || !outBuf.Resize(outSize))
    {
        return errAlloc;
    }

    char* pOutBuf = nullptr;
    size_t outBufSize = 0;
    if (!outBuf.LockBuffer(&pOutBuf, &outBufSize) || outBufSize < outSize)
    {
        return errAlloc;
    }
    if (passthrough)
    {
        memcpy(pOutBuf, p_pPkt->data, outSize);
    }
    else
    {
        ConvertAnnexBToLengthPrefixedRaw(p_pPkt->data, p_pPkt->size, reinterpret_cast<uint8_t*>(pOutBuf));
    }
    outBuf.UnlockBuffer();

    int64_t pts = p_pPkt->pts;
    outBuf.SetProperty(pIOPropPTS, propTypeInt64, &pts, 1);
    int64_t dts = p_pPkt->dts;
    if (m_HwDtsDelay > 0)
    {
        // h264_videotoolbox shifts DTS by one frame while its B-pyramid
        // needs two (measured: pts=1 dts=2 on the 4th packet), which every
        // ISO-BMFF/Matroska muxer rejects (dts > pts). Packets leave the
        // encoder in decode order, so DTS = decode index - delay.
        dts = (m_PacketCount - 1) - m_HwDtsDelay;
    }
    if (dts > pts)
    {
        g_Log(logLevelError, "GDC Encoder :: packet #%d has dts %lld > pts %lld — refusing to hand an invalid timestamp to the container",
              static_cast<int>(m_PacketCount), static_cast<long long>(dts), static_cast<long long>(pts));
        return errFail;
    }
    outBuf.SetProperty(pIOPropDTS, propTypeInt64, &dts, 1);

    uint8_t isKeyFrame = (p_pPkt->flags & AV_PKT_FLAG_KEY) ? 1 : 0;
    outBuf.SetProperty(pIOPropIsKeyFrame, propTypeUInt8, &isKeyFrame, 1);

    if (!m_pCallback)
    {
        return errInvalidOperation;
    }
    return m_pCallback->SendOutput(&outBuf);
}
