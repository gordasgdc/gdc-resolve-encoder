#include "ffmpeg_encoder.h"
#include "license_check.h"

#include <cstring>
#include <cmath>
#include <vector>
#include <string>
#include <thread>
#include <chrono>

extern "C" {
#include <libavutil/opt.h>
#include <libavutil/imgutils.h>
}

static int NalTypeH264(const std::vector<uint8_t>& p_Nal) { return p_Nal.empty() ? -1 : (p_Nal[0] & 0x1F); }
static int NalTypeH265(const std::vector<uint8_t>& p_Nal) { return p_Nal.empty() ? -1 : ((p_Nal[0] >> 1) & 0x3F); }

// ─────────────────────────────────────────────────────────────────────────
// Licentiere — INLOCUIESTE cu cheia TA publica, generata de keygen.py
// (gdc-license-system). Valoarea de mai jos e doar un exemplu si NU va
// valida niciun cod real generat cu cheia ta privata.
static const std::string kLicensePublicKeyB64 = "I1h23MNMRbOhc0ObKJrfa3oFHKA9w+SzbNrroAIy8hs=";
static const std::string kLicenseProductID = "gdc-resolve-encoder";

// ─────────────────────────────────────────────────────────────────────────
// Proper ISO/IEC 14496-15 hvcC construction for H.265 only.
//
// H.264 uses the reference-matched Annex-B cookie (proven working). But the
// official reference has no HEVC variant at all, so that approach was never
// actually validated for H.265 — and "only audio, no video" after a
// confirmed-complete, error-free encode strongly suggests Resolve's writer
// needs a properly structured hvcC box for HEVC specifically, not a raw
// NAL concatenation. This exact bit-parsing logic was verified earlier by
// encoding real test clips with libx265, extracting the true field values
// via FFmpeg's own `trace_headers` bitstream filter as ground truth, and
// confirming exact matches field-for-field before ever using it here.
// ─────────────────────────────────────────────────────────────────────────
class RbspBitReader
{
public:
    explicit RbspBitReader(const std::vector<uint8_t>& p_Data)
    {
        int zeroCount = 0;
        for (size_t i = 0; i < p_Data.size(); ++i)
        {
            uint8_t b = p_Data[i];
            if (zeroCount >= 2 && b == 3) { zeroCount = 0; continue; }
            zeroCount = (b == 0) ? (zeroCount + 1) : 0;
            m_Data.push_back(b);
        }
    }

    int ReadBit()
    {
        size_t byteIdx = m_BitPos / 8;
        if (byteIdx >= m_Data.size()) return 0;
        int bitIdx = 7 - static_cast<int>(m_BitPos % 8);
        int bit = (m_Data[byteIdx] >> bitIdx) & 1;
        ++m_BitPos;
        return bit;
    }

    uint64_t ReadBits(int p_N)
    {
        uint64_t v = 0;
        for (int i = 0; i < p_N; ++i) v = (v << 1) | static_cast<uint64_t>(ReadBit());
        return v;
    }

    uint32_t ReadUE()
    {
        int zeros = 0;
        while (ReadBit() == 0)
        {
            ++zeros;
            if (zeros > 32) return 0;
        }
        if (zeros == 0) return 0;
        return static_cast<uint32_t>((1u << zeros) - 1 + ReadBits(zeros));
    }

private:
    std::vector<uint8_t> m_Data;
    size_t m_BitPos = 0;
};

struct H265SpsInfo
{
    uint8_t profileSpace = 0, tierFlag = 0, profileIdc = 0, levelIdc = 0;
    uint32_t profileCompatFlags = 0;
    uint64_t constraintFlags = 0;
    uint32_t chromaFormatIdc = 1, bitDepthLumaMinus8 = 0, bitDepthChromaMinus8 = 0;
};

static H265SpsInfo ParseH265Sps(const std::vector<uint8_t>& p_SpsNal)
{
    H265SpsInfo info;
    if (p_SpsNal.size() < 4) return info;
    std::vector<uint8_t> rest(p_SpsNal.begin() + 2, p_SpsNal.end()); // skip 2-byte NAL header
    RbspBitReader br(rest);

    br.ReadBits(4);
    uint64_t maxSubLayersMinus1 = br.ReadBits(3);
    br.ReadBits(1);

    info.profileSpace = static_cast<uint8_t>(br.ReadBits(2));
    info.tierFlag = static_cast<uint8_t>(br.ReadBits(1));
    info.profileIdc = static_cast<uint8_t>(br.ReadBits(5));
    info.profileCompatFlags = static_cast<uint32_t>(br.ReadBits(32));
    info.constraintFlags = br.ReadBits(48);
    info.levelIdc = static_cast<uint8_t>(br.ReadBits(8));

    std::vector<int> subProfilePresent, subLevelPresent;
    for (uint64_t i = 0; i < maxSubLayersMinus1; ++i)
    {
        subProfilePresent.push_back(br.ReadBit());
        subLevelPresent.push_back(br.ReadBit());
    }
    if (maxSubLayersMinus1 > 0)
    {
        for (uint64_t i = maxSubLayersMinus1; i < 8; ++i) br.ReadBits(2);
    }
    for (uint64_t i = 0; i < maxSubLayersMinus1; ++i)
    {
        if (subProfilePresent[i]) br.ReadBits(88);
        if (subLevelPresent[i]) br.ReadBits(8);
    }

    br.ReadUE();
    info.chromaFormatIdc = br.ReadUE();
    if (info.chromaFormatIdc == 3) br.ReadBit();
    br.ReadUE(); br.ReadUE();
    if (br.ReadBit()) { br.ReadUE(); br.ReadUE(); br.ReadUE(); br.ReadUE(); }
    info.bitDepthLumaMinus8 = br.ReadUE();
    info.bitDepthChromaMinus8 = br.ReadUE();
    return info;
}

static std::vector<uint8_t> BuildHevcConfigRecord(const std::vector<std::vector<uint8_t>>& p_Nals)
{
    const std::vector<uint8_t>* pVps = nullptr;
    const std::vector<uint8_t>* pSps = nullptr;
    const std::vector<uint8_t>* pPps = nullptr;
    for (auto& n : p_Nals)
    {
        int t = NalTypeH265(n);
        if (t == 32 && !pVps) pVps = &n;
        else if (t == 33 && !pSps) pSps = &n;
        else if (t == 34 && !pPps) pPps = &n;
    }
    if (!pSps) return {};

    H265SpsInfo s = ParseH265Sps(*pSps);

    std::vector<uint8_t> out;
    out.push_back(1);
    out.push_back(static_cast<uint8_t>((s.profileSpace << 6) | (s.tierFlag << 5) | (s.profileIdc & 0x1F)));
    for (int i = 3; i >= 0; --i) out.push_back(static_cast<uint8_t>((s.profileCompatFlags >> (i * 8)) & 0xFF));
    for (int i = 5; i >= 0; --i) out.push_back(static_cast<uint8_t>((s.constraintFlags >> (i * 8)) & 0xFF));
    out.push_back(s.levelIdc);
    out.push_back(0xF0); out.push_back(0x00);
    out.push_back(0xFC);
    out.push_back(static_cast<uint8_t>(0xFC | (s.chromaFormatIdc & 0x03)));
    out.push_back(static_cast<uint8_t>(0xF8 | (s.bitDepthLumaMinus8 & 0x07)));
    out.push_back(static_cast<uint8_t>(0xF8 | (s.bitDepthChromaMinus8 & 0x07)));
    out.push_back(0x00); out.push_back(0x00);
    out.push_back(static_cast<uint8_t>((0 << 6) | (1 << 3) | (0 << 2) | 3));

    struct ArrEntry { const std::vector<uint8_t>* nal; int type; };
    std::vector<ArrEntry> arrays;
    if (pVps) arrays.push_back({ pVps, 32 });
    arrays.push_back({ pSps, 33 });
    if (pPps) arrays.push_back({ pPps, 34 });

    out.push_back(static_cast<uint8_t>(arrays.size()));
    for (auto& a : arrays)
    {
        out.push_back(static_cast<uint8_t>((1 << 7) | (a.type & 0x3F)));
        out.push_back(0x00); out.push_back(0x01);
        out.push_back(static_cast<uint8_t>((a.nal->size() >> 8) & 0xFF));
        out.push_back(static_cast<uint8_t>(a.nal->size() & 0xFF));
        out.insert(out.end(), a.nal->begin(), a.nal->end());
    }
    return out;
}

// ─────────────────────────────────────────────────────────────────────────
// Annex-B -> length-prefixed NAL conversion
//
// libx264/libx265 (and most FFmpeg H.264/H.265 encoders) emit Annex-B
// bytestream packets: each NAL unit is preceded by a start code (00 00 01
// or 00 00 00 01). MP4/MOV containers instead expect each NAL prefixed by
// its own big-endian 4-byte length, with no start codes ("AVCC"/"HVCC"
// format) — this is what Resolve's container writer expects from the
// buffer this plugin hands it. Converting explicitly here (rather than
// relying on a specific FFmpeg flag combination behaving a certain way)
// keeps this correct regardless of encoder/version quirks.
// ─────────────────────────────────────────────────────────────────────────
static void ConvertAnnexBToLengthPrefixed(const uint8_t* p_pData, int p_Size, std::vector<uint8_t>& p_Out)
{
    p_Out.clear();
    int i = 0;
    while (i < p_Size - 3)
    {
        int startCodeLen = 0;
        if (p_pData[i] == 0 && p_pData[i + 1] == 0 && p_pData[i + 2] == 1)
        {
            startCodeLen = 3;
        }
        else if ((i < p_Size - 4) && p_pData[i] == 0 && p_pData[i + 1] == 0 && p_pData[i + 2] == 0 && p_pData[i + 3] == 1)
        {
            startCodeLen = 4;
        }
        else
        {
            ++i;
            continue;
        }

        int nalStart = i + startCodeLen;
        int nalEnd = p_Size;
        for (int j = nalStart; j < p_Size - 3; ++j)
        {
            if ((p_pData[j] == 0 && p_pData[j + 1] == 0 && p_pData[j + 2] == 1) ||
                (j < p_Size - 4 && p_pData[j] == 0 && p_pData[j + 1] == 0 && p_pData[j + 2] == 0 && p_pData[j + 3] == 1))
            {
                nalEnd = j;
                break;
            }
        }

        int nalLen = nalEnd - nalStart;
        if (nalLen > 0)
        {
            uint8_t lenBytes[4] = {
                static_cast<uint8_t>((nalLen >> 24) & 0xFF),
                static_cast<uint8_t>((nalLen >> 16) & 0xFF),
                static_cast<uint8_t>((nalLen >> 8) & 0xFF),
                static_cast<uint8_t>(nalLen & 0xFF),
            };
            p_Out.insert(p_Out.end(), lenBytes, lenBytes + 4);
            p_Out.insert(p_Out.end(), p_pData + nalStart, p_pData + nalEnd);
        }

        i = nalEnd;
    }
}

// Splits Annex-B extradata (SPS/PPS with start codes, as libx264/libx265
// with AV_CODEC_FLAG_GLOBAL_HEADER produce) into a list of raw NALs, for
// building an avcC/hvcC-style magic cookie.
static void SplitAnnexBNALs(const uint8_t* p_pData, int p_Size, std::vector<std::vector<uint8_t>>& p_OutNals)
{
    std::vector<uint8_t> combined;
    ConvertAnnexBToLengthPrefixed(p_pData, p_Size, combined);

    size_t pos = 0;
    while (pos + 4 <= combined.size())
    {
        int len = (combined[pos] << 24) | (combined[pos + 1] << 16) | (combined[pos + 2] << 8) | combined[pos + 3];
        pos += 4;
        if (pos + len > combined.size() || len <= 0)
        {
            break;
        }
        p_OutNals.emplace_back(combined.begin() + pos, combined.begin() + pos + len);
        pos += len;
    }
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

        uint8_t hSampling = 2, vSampling = 2; // 4:2:0, confirmed proven working
        codecInfo.SetProperty(pIOPropHSubsampling, propTypeUInt8, &hSampling, 1);
        codecInfo.SetProperty(pIOPropVSubsampling, propTypeUInt8, &vSampling, 1);

        uint32_t bitDepthVal = static_cast<uint32_t>(v.bitDepth);
        codecInfo.SetProperty(pIOPropBitDepth, propTypeUInt32, &bitDepthVal, 1);
        codecInfo.SetProperty(pIOPropBitsPerSample, propTypeUInt32, &bitDepthVal, 1);

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

    {
        HostUIConfigEntryRef brandItem("gdc_brand_label");
        brandItem.MakeLabel("GDC Resolve Encoder — by Cristi Gordas");
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

    {
        gdc_license::CheckResult activated = gdc_license::check_activated_license(kLicenseProductID, kLicensePublicKeyB64);
        if (activated.valid)
        {
            HostUIConfigEntryRef licenseItem("gdc_license_status");
            licenseItem.MakeLabel("Licenta: activa");
            if (!licenseItem.IsSuccess() || !p_pSettingsList->Append(&licenseItem))
            {
                return errFail;
            }
        }
        else
        {
            {
                HostUIConfigEntryRef machineIdItem("gdc_machine_id");
                std::string machineIdLabel = "ID masina (trimite-mi asta): " + gdc_license::get_machine_id_display();
                machineIdItem.MakeLabel(machineIdLabel);
                if (!machineIdItem.IsSuccess() || !p_pSettingsList->Append(&machineIdItem))
                {
                    return errFail;
                }
            }
            std::string licenseCode;
            p_pValues->GetString("gdc_license", licenseCode);
            HostUIConfigEntryRef licenseItem("gdc_license");
            licenseItem.MakeTextBox("Cod licenta", licenseCode, "");
            if (!licenseItem.IsSuccess() || !p_pSettingsList->Append(&licenseItem))
            {
                return errFail;
            }
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

    gdc_license::CheckResult licenseResult = gdc_license::check_activated_license(kLicenseProductID, kLicensePublicKeyB64);
    if (!licenseResult.valid)
    {
        // nicio licenta activata local inca - verificam ce a introdus
        // utilizatorul in campul de text si, daca e valid, o salvam
        // local pentru viitor (dupa asta, campul dispare din panou —
        // vezi s_GetEncoderSettings — si codul brut nu mai e vizibil)
        std::string licenseCode;
        p_pBuff->GetString("gdc_license", licenseCode);
        licenseResult = gdc_license::check_serial(licenseCode, kLicensePublicKeyB64, kLicenseProductID);
        if (licenseResult.valid)
        {
            // Randarea curenta merge oricum (licenseResult.valid e deja
            // true din check_serial de mai sus), dar daca scrierea pe
            // disc esueaza (permisiuni, disc plin), utilizatorului i se
            // va cere codul din nou la fiecare pornire a Resolve, fara
            // niciun indiciu de ce — logam explicit ca sa fie clar ce
            // s-a intamplat, in loc sa pretindem mereu succes.
            if (gdc_license::save_activated_license(kLicenseProductID, licenseCode))
            {
                g_Log(logLevelInfo, "GDC Encoder :: Licenta noua, activata si salvata local.");
            }
            else
            {
                g_Log(logLevelWarn, "GDC Encoder :: Licenta valida pentru aceasta randare, dar salvarea locala a esuat (%s) — codul va fi cerut din nou la urmatoarea pornire.",
                      gdc_license::activation_file_path(kLicenseProductID).c_str());
            }
        }
    }
    if (!licenseResult.valid)
    {
        g_Log(logLevelError, "GDC Encoder :: Licenta invalida sau lipsa: %s", licenseResult.error.c_str());
        return errFail;
    }
    g_Log(logLevelInfo, "GDC Encoder :: Licenta valida.");

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

    return OpenCodec(p_pBuff);
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

    // Color space signalling — color_range was already set above, but
    // color_primaries/color_trc/colorspace were never set at all, so a
    // delivered file carried no signal of which color space it was
    // actually encoded in. Some playback pipelines then guess wrong,
    // which reads as "colors look off"/quality complaints unrelated to
    // bit-rate. Prefer the real signal from Resolve (clrPrimaries) when
    // present — its numbering is assumed to follow the same ISO/IEC
    // 23001-8 (CICP) convention AVColorPrimaries/AVColorTransferCharacteristic/
    // AVColorSpace already use, which is the standard convention for this
    // exact kind of property in the broadcast/codec world, but this exact
    // mapping has NOT been confirmed against a real Resolve export — fall
    // back to an explicit default otherwise (BT.709 for 8-bit, BT.2020 for
    // 10-bit — a reasonable heuristic, not a guarantee of the true source).
    {
        // `clrPrimaries` is a single "which primaries" hint — NOT three
        // separate primaries/transfer/matrix values, so color_trc/colorspace
        // are derived from WHICH primaries we got (small explicit mapping),
        // never a blind reuse of the same raw number across three different
        // enumerations (those don't share a numbering scheme beyond a few
        // coincidental low values).
        int16_t rawPrimaries = 0;
        bool haveBt2020 = p_pBuff->GetINT16("clrPrimaries", rawPrimaries) && (rawPrimaries == AVCOL_PRI_BT2020);
        bool wantWideGamut = haveBt2020 || (m_pVariant->bitDepth >= 10);

        if (wantWideGamut)
        {
            m_pCtx->color_primaries = AVCOL_PRI_BT2020;
            m_pCtx->color_trc = AVCOL_TRC_BT2020_10;
            m_pCtx->colorspace = AVCOL_SPC_BT2020_NCL;
        }
        else
        {
            m_pCtx->color_primaries = AVCOL_PRI_BT709;
            m_pCtx->color_trc = AVCOL_TRC_BT709;
            m_pCtx->colorspace = AVCOL_SPC_BT709;
        }
    }

    if (m_QualityMode == 1)
    {
        m_pCtx->bit_rate = static_cast<int64_t>(m_BitRateKbps) * 1000;
        m_pCtx->rc_max_rate = m_pCtx->bit_rate;
        m_pCtx->rc_buffer_size = static_cast<int>(m_pCtx->bit_rate);
    }

    AVDictionary* pOpts = nullptr;
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
        if (!m_AdvancedParams.empty())
        {
            const char* paramKey = m_pVariant->isHEVC ? "x265-params" : "x264-params";
            av_dict_set(&pOpts, paramKey, m_AdvancedParams.c_str(), 0);
        }
    }
    else
    {
        // Hardware encoders (VideoToolbox/NVENC): CRF isn't universally
        // supported the same way — fall back to a quality-oriented bitrate
        // if the person picked CRF mode, since a 0 bit_rate would leave
        // the hardware encoder without any rate target.
        if (m_QualityMode == 0 && m_pCtx->bit_rate == 0)
        {
            m_pCtx->bit_rate = 12000000; // 12 Mbps sensible default
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

    // Resolve delivers planar YUV 4:2:0 (Y plane, then U plane, then V
    // plane, tightly packed) matching pIOPropColorModel=clrYUVp + 2/2
    // subsampling declared in s_RegisterCodecs. For 10-bit variants, each
    // sample is a 16-bit little-endian container (10 meaningful bits) —
    // same plane layout, just double the bytes per sample, matching
    // AV_PIX_FMT_YUV420P10LE. When the target encoder wants exactly this
    // source layout, no conversion is needed at all; otherwise (hardware
    // encoders wanting NV12, etc.) go through swscale.
    const bool is10Bit = (m_pVariant->bitDepth == 10);
    const AVPixelFormat srcFmt = is10Bit ? AV_PIX_FMT_YUV420P10LE : AV_PIX_FMT_YUV420P;
    const int bytesPerSample = is10Bit ? 2 : 1;

    const uint8_t* pSrcData[4] = {};
    int srcLinesize[4] = {};
    pSrcData[0] = reinterpret_cast<const uint8_t*>(pBuf);
    srcLinesize[0] = static_cast<int>(width) * bytesPerSample;
    pSrcData[1] = pSrcData[0] + (static_cast<size_t>(width) * height * bytesPerSample);
    srcLinesize[1] = (static_cast<int>(width) / 2) * bytesPerSample;
    pSrcData[2] = pSrcData[1] + ((static_cast<size_t>(width) / 2) * (height / 2) * bytesPerSample);
    srcLinesize[2] = (static_cast<int>(width) / 2) * bytesPerSample;

    if (static_cast<AVPixelFormat>(p_pFrame->format) == srcFmt)
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
            p_pBuff->UnlockBuffer();
            return errFail;
        }
        sws_scale(m_pSwsCtx, pSrcData, srcLinesize, 0, height, p_pFrame->data, p_pFrame->linesize);
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
        return sts;
    }

    return EncodeFrame(m_pFrame);
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
    std::vector<uint8_t> lengthPrefixed;
    ConvertAnnexBToLengthPrefixed(p_pPkt->data, p_pPkt->size, lengthPrefixed);
    if (lengthPrefixed.empty())
    {
        // Some hardware encoders may already emit length-prefixed NALs
        // directly rather than Annex-B — fall back to the raw packet as-is.
        lengthPrefixed.assign(p_pPkt->data, p_pPkt->data + p_pPkt->size);
    }

    HostBufferRef outBuf(false);
    if (!outBuf.IsValid() || !outBuf.Resize(lengthPrefixed.size()))
    {
        return errAlloc;
    }

    char* pOutBuf = nullptr;
    size_t outBufSize = 0;
    if (!outBuf.LockBuffer(&pOutBuf, &outBufSize))
    {
        return errAlloc;
    }
    memcpy(pOutBuf, lengthPrefixed.data(), lengthPrefixed.size());
    outBuf.UnlockBuffer();

    int64_t pts = p_pPkt->pts;
    outBuf.SetProperty(pIOPropPTS, propTypeInt64, &pts, 1);
    int64_t dts = p_pPkt->dts;
    outBuf.SetProperty(pIOPropDTS, propTypeInt64, &dts, 1);

    uint8_t isKeyFrame = (p_pPkt->flags & AV_PKT_FLAG_KEY) ? 1 : 0;
    outBuf.SetProperty(pIOPropIsKeyFrame, propTypeUInt8, &isKeyFrame, 1);

    if (!m_pCallback)
    {
        return errInvalidOperation;
    }
    return m_pCallback->SendOutput(&outBuf);
}
