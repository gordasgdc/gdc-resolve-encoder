#include "ffmpeg_encoder.h"

#include <cstring>
#include <vector>
#include <string>

extern "C" {
#include <libavutil/opt.h>
#include <libavutil/imgutils.h>
}

static int NalTypeH264(const std::vector<uint8_t>& p_Nal) { return p_Nal.empty() ? -1 : (p_Nal[0] & 0x1F); }
static int NalTypeH265(const std::vector<uint8_t>& p_Nal) { return p_Nal.empty() ? -1 : ((p_Nal[0] >> 1) & 0x3F); }

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
    , m_FrameCount(0)
    , m_HeaderSent(false)
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

        uint32_t bitDepthVal = 8;
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

    p_pValues->GetINT32("gdc_quality_mode", qualityMode);
    p_pValues->GetINT32("gdc_crf", crf);
    p_pValues->GetINT32("gdc_bitrate", bitRateKbps);
    p_pValues->GetINT32("gdc_preset", preset);

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

    {
        HostUIConfigEntryRef modeItem("gdc_quality_mode");
        std::vector<std::string> texts = { "Constant Quality (CRF)", "Target Bitrate" };
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
        HostUIConfigEntryRef crfItem("gdc_crf");
        crfItem.MakeSlider("Quality (CRF)", "lower = better", crf, 0, 51, 23);
        if (!crfItem.IsSuccess() || !p_pSettingsList->Append(&crfItem))
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

    return errNone;
}

void FFmpegEncoder::DoFlush()
{
    if (m_Error != errNone || !m_pCtx) return;

    avcodec_send_frame(m_pCtx, nullptr); // signal EOF to the encoder
    DrainPackets();
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

    p_pBuff->GetINT32("gdc_quality_mode", m_QualityMode);
    p_pBuff->GetINT32("gdc_crf", m_CRF);
    p_pBuff->GetINT32("gdc_bitrate", m_BitRateKbps);
    p_pBuff->GetINT32("gdc_preset", m_Preset);

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
    m_pCtx->gop_size = 12;
    m_pCtx->max_b_frames = 2;
    m_pCtx->pix_fmt = m_pVariant->preferredPixFmt;
    m_pCtx->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
    m_pCtx->color_range = m_CommonProps.IsFullRange() ? AVCOL_RANGE_JPEG : AVCOL_RANGE_MPEG;

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

    int openResult = avcodec_open2(m_pCtx, pCodec, &pOpts);
    av_dict_free(&pOpts);
    if (openResult < 0)
    {
        g_Log(logLevelError, "GDC Encoder :: avcodec_open2 failed for '%s' (%d)", m_pVariant->avCodecName, openResult);
        return errFail;
    }

    // The official Blackmagic SDK reference (x264_encoder_plugin's
    // DoOpen) does NOT build a structured ISO avcC/hvcC box at all — it
    // re-inserts Annex-B start codes (00 00 00 01) before each non-SEI NAL
    // from the encoder's headers and sets magicCookieType=0. Verified by
    // reading that reference's actual DoOpen code directly. An earlier
    // version of this plugin built a spec-correct avcC/hvcC box instead,
    // which seemed more "correct" by the ISO spec but does not match what
    // Resolve's own writer actually expects from this SDK — matching the
    // reference exactly here, byte-for-byte in approach.
    if (m_pCtx->extradata && m_pCtx->extradata_size > 0)
    {
        std::vector<std::vector<uint8_t>> nals;
        SplitAnnexBNALs(m_pCtx->extradata, m_pCtx->extradata_size, nals);

        std::vector<uint8_t> cookie;
        for (auto& nal : nals)
        {
            int nalType = m_pVariant->isHEVC ? NalTypeH265(nal) : NalTypeH264(nal);
            bool isSei = m_pVariant->isHEVC ? (nalType == 39 || nalType == 40) : (nalType == 6);
            if (isSei) continue;

            static const uint8_t s_StartCode[4] = { 0, 0, 0, 1 };
            cookie.insert(cookie.end(), s_StartCode, s_StartCode + 4);
            cookie.insert(cookie.end(), nal.begin(), nal.end());
        }

        if (!cookie.empty())
        {
            p_pBuff->SetProperty(pIOPropMagicCookie, propTypeUInt8, cookie.data(), static_cast<int>(cookie.size()));
            uint32_t cookieType = 0; // matches the official SDK reference exactly
            p_pBuff->SetProperty(pIOPropMagicCookieType, propTypeUInt32, &cookieType, 1);
            g_Log(logLevelInfo, "GDC Encoder :: Built Annex-B cookie (reference-matched), %d bytes",
                  static_cast<int>(cookie.size()));
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
    // subsampling declared in s_RegisterCodecs. When the target encoder
    // wants exactly this layout (AV_PIX_FMT_YUV420P — true for libx264),
    // no conversion is needed at all. Only hardware encoders that want a
    // different layout (e.g. NV12) go through swscale.
    const uint8_t* pSrcData[4] = {};
    int srcLinesize[4] = {};
    pSrcData[0] = reinterpret_cast<const uint8_t*>(pBuf);
    srcLinesize[0] = static_cast<int>(width);
    pSrcData[1] = pSrcData[0] + (width * height);
    srcLinesize[1] = static_cast<int>(width) / 2;
    pSrcData[2] = pSrcData[1] + ((width / 2) * (height / 2));
    srcLinesize[2] = static_cast<int>(width) / 2;

    if (static_cast<AVPixelFormat>(p_pFrame->format) == AV_PIX_FMT_YUV420P)
    {
        av_image_copy(p_pFrame->data, p_pFrame->linesize, pSrcData, srcLinesize, AV_PIX_FMT_YUV420P,
                       static_cast<int>(width), static_cast<int>(height));
    }
    else
    {
        if (!m_pSwsCtx)
        {
            m_pSwsCtx = sws_getContext(width, height, AV_PIX_FMT_YUV420P,
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
        return errMoreData; // no more input; DoFlush() drives EOF explicitly
    }

    StatusCode sts = FillFrameFromBuffer(p_pBuff, m_pFrame);
    if (sts != errNone) return sts;

    return EncodeFrame(m_pFrame);
}

StatusCode FFmpegEncoder::EncodeFrame(AVFrame* p_pFrame)
{
    int ret = avcodec_send_frame(m_pCtx, p_pFrame);
    if (ret < 0)
    {
        g_Log(logLevelError, "GDC Encoder :: avcodec_send_frame failed (%d)", ret);
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
            return errFail;
        }

        StatusCode sts = SendPacketToHost(m_pPacket);
        av_packet_unref(m_pPacket);
        if (sts != errNone)
        {
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
