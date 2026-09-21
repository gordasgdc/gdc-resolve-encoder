#include "gdc_container.h"
#include "encoder_variants.h"

#include <cassert>
#include <cstdio>
#include <cstring>

extern "C" {
#include <libavutil/mastering_display_metadata.h>
#include <libavutil/channel_layout.h>
#include <libavutil/mem.h>
}

// Container UUIDs: ...80 (QuickTime), ...81 (MP4), ...82 (Matroska). Distinct
// from the codec variants (...01-...0a) and from the plugin UUID.
const ContainerFormat g_ContainerFormats[] = {
    { { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x80 }, "GDC QuickTime", "mov", "mov" },
    { { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x81 }, "GDC MP4", "mp4", "mp4" },
    { { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x82 }, "GDC Matroska", "mkv", "matroska" },
};
const int g_NumContainerFormats = sizeof(g_ContainerFormats) / sizeof(g_ContainerFormats[0]);

// ───────────────────────────── track writer ─────────────────────────────

class GdcTrackWriter : public IPluginTrackBase, public IPluginTrackWriter
{
public:
    GdcTrackWriter(GdcContainer* p_pContainer, uint32_t p_StreamIdx, bool p_IsVideo)
        : IPluginTrackBase(p_pContainer)
        , m_StreamIdx(p_StreamIdx)
        , m_IsVideo(p_IsVideo)
    {
    }
    virtual ~GdcTrackWriter() = default;

    virtual StatusCode DoWrite(HostBufferRef* p_pBuf) override
    {
        GdcContainer* pContainer = dynamic_cast<GdcContainer*>(m_pContainer);
        assert(pContainer != nullptr);
        return m_IsVideo ? pContainer->WriteVideo(m_StreamIdx, p_pBuf) : pContainer->WriteAudio(m_StreamIdx, p_pBuf);
    }

private:
    uint32_t m_StreamIdx;
    bool m_IsVideo;
};

// ───────────────────────────── registration ─────────────────────────────

const ContainerFormat* GdcContainer::s_FindFormat(const unsigned char* p_pUUID)
{
    for (int i = 0; i < g_NumContainerFormats; ++i)
    {
        if (memcmp(p_pUUID, g_ContainerFormats[i].uuid, 16) == 0) return &g_ContainerFormats[i];
    }
    return nullptr;
}

std::string GdcContainer::s_UUIDHex(const ContainerFormat& p_Format)
{
    static const char* hex = "0123456789abcdef";
    std::string s;
    for (int i = 0; i < 16; ++i)
    {
        s.push_back(hex[(p_Format.uuid[i] >> 4) & 0xF]);
        s.push_back(hex[p_Format.uuid[i] & 0xF]);
    }
    return s;
}

StatusCode GdcContainer::s_Register(HostListRef* p_pList)
{
    for (int i = 0; i < g_NumContainerFormats; ++i)
    {
        const ContainerFormat& f = g_ContainerFormats[i];
        HostPropertyCollectionRef info;
        if (!info.IsValid())
        {
            return errAlloc;
        }
        info.SetProperty(pIOPropUUID, propTypeUInt8, f.uuid, 16);
        info.SetProperty(pIOPropName, propTypeString, f.displayName, strlen(f.displayName));
        const uint32_t mediaType = (mediaAudio | mediaVideo);
        info.SetProperty(pIOPropMediaType, propTypeUInt32, &mediaType, 1);
        info.SetProperty(pIOPropContainerExt, propTypeString, f.ext, strlen(f.ext));
        if (!p_pList->Append(&info))
        {
            return errFail;
        }
        g_Log(logLevelInfo, "GDC Container :: Registered '%s' (.%s via libavformat '%s')", f.displayName, f.ext, f.avFormat);
    }
    return errNone;
}

// ───────────────────────────── container ─────────────────────────────

GdcContainer::GdcContainer(const ContainerFormat* p_pFormat)
    : m_pFormat(p_pFormat)
    , m_pFmtCtx(nullptr)
    , m_HeaderWritten(false)
    , m_HeaderFailed(false)
{
}

GdcContainer::~GdcContainer()
{
    if (m_pFmtCtx)
    {
        if (m_pFmtCtx->pb) avio_closep(&m_pFmtCtx->pb);
        avformat_free_context(m_pFmtCtx);
        m_pFmtCtx = nullptr;
    }
}

// The host's call order (Init / Open / AddTrack) is not documented and the
// path may only be known at Open, so the muxer context is created on first
// need, and the path is only required when the header is written.
StatusCode GdcContainer::EnsureContext()
{
    if (m_pFmtCtx) return errNone;
    const int ret = avformat_alloc_output_context2(&m_pFmtCtx, nullptr, m_pFormat->avFormat, nullptr);
    if (ret < 0 || !m_pFmtCtx)
    {
        g_Log(logLevelError, "GDC Container :: avformat_alloc_output_context2('%s') FAILED (%d)", m_pFormat->avFormat, ret);
        m_pFmtCtx = nullptr;
        return errFail;
    }
    return errNone;
}

StatusCode GdcContainer::DoInit(HostPropertyCollectionRef* p_pProps)
{
    std::lock_guard<std::mutex> lock(m_Mutex);
    std::string path;
    if (p_pProps->GetString(pIOPropPath, path) && !path.empty()) m_Path = path;
    g_Log(logLevelInfo, "GDC Container :: DoInit '%s' path='%s'", m_pFormat->displayName, m_Path.c_str());
    return EnsureContext();
}

StatusCode GdcContainer::DoOpen(HostPropertyCollectionRef* p_pProps)
{
    std::lock_guard<std::mutex> lock(m_Mutex);
    std::string path;
    if (p_pProps->GetString(pIOPropPath, path) && !path.empty()) m_Path = path;
    g_Log(logLevelInfo, "GDC Container :: DoOpen '%s' path='%s'", m_pFormat->displayName, m_Path.c_str());
    return EnsureContext();
}

static void ParseMdcv(const std::string& p_Str, AVMasteringDisplayMetadata* p_pMd)
{
    // "G(gx,gy)B(bx,by)R(rx,ry)WP(wx,wy)L(max,min)" — x264/x265 units:
    // chromaticity 0.00002, luminance 0.0001 cd/m2.
    int gx, gy, bx, by, rx, ry, wx, wy, lmax, lmin;
    if (sscanf(p_Str.c_str(), "G(%d,%d)B(%d,%d)R(%d,%d)WP(%d,%d)L(%d,%d)", &gx, &gy, &bx, &by, &rx, &ry, &wx, &wy, &lmax, &lmin) != 10)
    {
        return;
    }
    p_pMd->display_primaries[0][0] = av_make_q(rx, 50000);
    p_pMd->display_primaries[0][1] = av_make_q(ry, 50000);
    p_pMd->display_primaries[1][0] = av_make_q(gx, 50000);
    p_pMd->display_primaries[1][1] = av_make_q(gy, 50000);
    p_pMd->display_primaries[2][0] = av_make_q(bx, 50000);
    p_pMd->display_primaries[2][1] = av_make_q(by, 50000);
    p_pMd->white_point[0] = av_make_q(wx, 50000);
    p_pMd->white_point[1] = av_make_q(wy, 50000);
    p_pMd->max_luminance = av_make_q(lmax, 10000);
    p_pMd->min_luminance = av_make_q(lmin, 10000);
    p_pMd->has_primaries = 1;
    p_pMd->has_luminance = 1;
}

StatusCode GdcContainer::AddVideoTrack(HostPropertyCollectionRef* p_pProps, HostPropertyCollectionRef* p_pCodecProps, uint32_t* p_pStreamIdx)
{
    HostCodecConfigCommon cfg;
    cfg.Load(p_pProps);

    uint32_t fourCC = 0;
    p_pCodecProps->GetUINT32(pIOPropFourCC, fourCC);
    AVCodecID codecId = AV_CODEC_ID_NONE;
    if (fourCC == GDC_FOURCC('a', 'v', 'c', '1')) codecId = AV_CODEC_ID_H264;
    else if (fourCC == GDC_FOURCC('h', 'v', 'c', '1')) codecId = AV_CODEC_ID_HEVC;
    if (codecId == AV_CODEC_ID_NONE)
    {
        g_Log(logLevelError, "GDC Container :: unsupported video fourCC 0x%08x (only H.264/H.265 from GDC Encoder)", fourCC);
        return errNoCodec;
    }

    AVStream* pSt = avformat_new_stream(m_pFmtCtx, nullptr);
    if (!pSt)
    {
        return errAlloc;
    }

    AVCodecParameters* pPar = pSt->codecpar;
    pPar->codec_type = AVMEDIA_TYPE_VIDEO;
    pPar->codec_id = codecId;
    pPar->width = static_cast<int>(cfg.GetWidth());
    pPar->height = static_cast<int>(cfg.GetHeight());
    if (codecId == AV_CODEC_ID_HEVC) pPar->codec_tag = MKTAG('h', 'v', 'c', '1'); // Apple wants hvc1, not hev1

    const int fpsNum = static_cast<int>(cfg.GetFrameRateNum());
    const int fpsDen = static_cast<int>(cfg.GetFrameRateDen());
    pSt->time_base = av_make_q(fpsDen > 0 ? fpsDen : 1, fpsNum > 0 ? fpsNum : 25);
    pSt->avg_frame_rate = av_make_q(fpsNum > 0 ? fpsNum : 25, fpsDen > 0 ? fpsDen : 1);

    // Parameter sets (magic cookie set by the encoder in DoOpen): avcC-able
    // Annex-B for H.264, hvcC record for HEVC — libavformat accepts both.
    {
        PropertyType type = propTypeNull;
        const void* pVal = nullptr;
        int n = 0;
        if (p_pCodecProps->GetProperty(pIOPropMagicCookie, &type, &pVal, &n) == errNone && type == propTypeUInt8 && n > 0 && pVal)
        {
            pPar->extradata = static_cast<uint8_t*>(av_mallocz(static_cast<size_t>(n) + AV_INPUT_BUFFER_PADDING_SIZE));
            if (pPar->extradata)
            {
                memcpy(pPar->extradata, pVal, static_cast<size_t>(n));
                pPar->extradata_size = n;
            }
        }
        else
        {
            g_Log(logLevelWarn, "GDC Container :: no magic cookie on the video codec props");
        }
    }

    // Color tags + HDR static metadata, passed from the encoder as custom
    // props on its codec buffer (see FFmpegEncoder::OpenCodec).
    int32_t pri = 0, trc = 0, mtx = 0, range = 0;
    p_pCodecProps->GetINT32("gdc_pri", pri);
    p_pCodecProps->GetINT32("gdc_trc", trc);
    p_pCodecProps->GetINT32("gdc_mtx", mtx);
    p_pCodecProps->GetINT32("gdc_range", range);
    if (pri > 0) pPar->color_primaries = static_cast<AVColorPrimaries>(pri);
    if (trc > 0) pPar->color_trc = static_cast<AVColorTransferCharacteristic>(trc);
    if (mtx > 0) pPar->color_space = static_cast<AVColorSpace>(mtx);
    pPar->color_range = range ? AVCOL_RANGE_JPEG : AVCOL_RANGE_MPEG;

    std::string mdcv, cll;
    p_pCodecProps->GetString("gdc_mdcv", mdcv);
    p_pCodecProps->GetString("gdc_cll", cll);
    if (!mdcv.empty())
    {
        size_t sz = 0;
        AVMasteringDisplayMetadata* pMd = av_mastering_display_metadata_alloc_size(&sz);
        if (pMd)
        {
            ParseMdcv(mdcv, pMd);
            if (!av_packet_side_data_add(&pPar->coded_side_data, &pPar->nb_coded_side_data, AV_PKT_DATA_MASTERING_DISPLAY_METADATA, pMd, sz, 0))
            {
                av_free(pMd);
            }
        }
    }
    if (!cll.empty())
    {
        unsigned maxCll = 0, maxFall = 0;
        if (sscanf(cll.c_str(), "%u,%u", &maxCll, &maxFall) == 2)
        {
            size_t sz = 0;
            AVContentLightMetadata* pCl = av_content_light_metadata_alloc(&sz);
            if (pCl)
            {
                pCl->MaxCLL = maxCll;
                pCl->MaxFALL = maxFall;
                if (!av_packet_side_data_add(&pPar->coded_side_data, &pPar->nb_coded_side_data, AV_PKT_DATA_CONTENT_LIGHT_LEVEL, pCl, sz, 0))
                {
                    av_free(pCl);
                }
            }
        }
    }

    StreamInfo si;
    si.isVideo = true;
    if (m_Streams.size() <= static_cast<size_t>(pSt->index)) m_Streams.resize(pSt->index + 1);
    m_Streams[pSt->index] = si;
    *p_pStreamIdx = static_cast<uint32_t>(pSt->index);

    g_Log(logLevelInfo, "GDC Container :: video track: %dx%d %d/%d fps, codec=%s, cookie=%d bytes, color pri=%d trc=%d mtx=%d range=%d, mdcv=%s, cll=%s",
          pPar->width, pPar->height, fpsNum, fpsDen, codecId == AV_CODEC_ID_HEVC ? "hevc" : "h264", pPar->extradata_size,
          pri, trc, mtx, range, mdcv.empty() ? "none" : mdcv.c_str(), cll.empty() ? "none" : cll.c_str());
    return errNone;
}

StatusCode GdcContainer::AddAudioTrack(HostPropertyCollectionRef* p_pProps, uint32_t* p_pStreamIdx)
{
    uint32_t samplingRate = 0, numChannels = 0, bitDepth = 0;
    uint8_t isFloat = 0;
    p_pProps->GetUINT32(pIOPropSamplingRate, samplingRate);
    p_pProps->GetUINT32(pIOPropNumChannels, numChannels);
    p_pProps->GetUINT32(pIOPropBitDepth, bitDepth); // storage depth
    p_pProps->GetUINT8(pIOPropIsFloat, isFloat);

    AVCodecID codecId = AV_CODEC_ID_NONE;
    if (isFloat && bitDepth == 32) codecId = AV_CODEC_ID_PCM_F32LE;
    else if (bitDepth == 16) codecId = AV_CODEC_ID_PCM_S16LE;
    else if (bitDepth == 24) codecId = AV_CODEC_ID_PCM_S24LE;
    else if (bitDepth == 32) codecId = AV_CODEC_ID_PCM_S32LE;
    if (codecId == AV_CODEC_ID_NONE || samplingRate == 0 || numChannels == 0)
    {
        g_Log(logLevelError, "GDC Container :: unsupported audio track: rate=%u ch=%u depth=%u float=%d", samplingRate, numChannels, bitDepth, isFloat);
        return errNoCodec;
    }

    AVStream* pSt = avformat_new_stream(m_pFmtCtx, nullptr);
    if (!pSt)
    {
        return errAlloc;
    }
    AVCodecParameters* pPar = pSt->codecpar;
    pPar->codec_type = AVMEDIA_TYPE_AUDIO;
    pPar->codec_id = codecId;
    pPar->sample_rate = static_cast<int>(samplingRate);
    av_channel_layout_default(&pPar->ch_layout, static_cast<int>(numChannels));
    pPar->bits_per_coded_sample = static_cast<int>(bitDepth);
    pPar->bits_per_raw_sample = static_cast<int>(bitDepth);
    pPar->block_align = static_cast<int>(numChannels * bitDepth / 8);
    pSt->time_base = av_make_q(1, static_cast<int>(samplingRate));

    StreamInfo si;
    si.isVideo = false;
    si.bytesPerSample = static_cast<int>(bitDepth / 8);
    si.channels = static_cast<int>(numChannels);
    if (m_Streams.size() <= static_cast<size_t>(pSt->index)) m_Streams.resize(pSt->index + 1);
    m_Streams[pSt->index] = si;
    *p_pStreamIdx = static_cast<uint32_t>(pSt->index);

    g_Log(logLevelInfo, "GDC Container :: audio track: %u Hz, %u ch, %u-bit%s (PCM, little-endian assumed)", samplingRate, numChannels, bitDepth, isFloat ? " float" : "");
    return errNone;
}

StatusCode GdcContainer::DoAddTrack(HostPropertyCollectionRef* p_pProps, HostPropertyCollectionRef* p_pCodecProps, IPluginTrackBase** p_pTrack)
{
    std::lock_guard<std::mutex> lock(m_Mutex);
    g_Log(logLevelInfo, "GDC Container :: DoAddTrack (ctx=%s, path='%s')", m_pFmtCtx ? "ready" : "null", m_Path.c_str());
    if (EnsureContext() != errNone)
    {
        return errFail;
    }
    uint32_t mediaType = 0;
    if (!p_pProps->GetUINT32(pIOPropMediaType, mediaType) || ((mediaType != mediaVideo) && (mediaType != mediaAudio)))
    {
        return errInvalidParam;
    }
    const bool isVideo = (mediaType == mediaVideo);

    uint32_t streamIdx = 0;
    const StatusCode sts = isVideo ? AddVideoTrack(p_pProps, p_pCodecProps, &streamIdx) : AddAudioTrack(p_pProps, &streamIdx);
    if (sts != errNone)
    {
        g_Log(logLevelError, "GDC Container :: %s track REJECTED (status %d)", isVideo ? "video" : "audio", static_cast<int>(sts));
        return sts;
    }

    GdcTrackWriter* pTrack = new GdcTrackWriter(this, streamIdx, isVideo);
    pTrack->Retain();
    *p_pTrack = pTrack;
    m_Tracks.push_back(pTrack);
    return errNone;
}

StatusCode GdcContainer::EnsureHeader()
{
    if (m_HeaderWritten) return errNone;
    if (m_HeaderFailed || !m_pFmtCtx) return errFail;
    if (m_Path.empty())
    {
        g_Log(logLevelError, "GDC Container :: no output path known when the header must be written");
        m_HeaderFailed = true;
        return errFail;
    }

    if (!(m_pFmtCtx->oformat->flags & AVFMT_NOFILE))
    {
        const int r = avio_open(&m_pFmtCtx->pb, m_Path.c_str(), AVIO_FLAG_WRITE);
        if (r < 0)
        {
            g_Log(logLevelError, "GDC Container :: avio_open FAILED for '%s' (%d)", m_Path.c_str(), r);
            m_HeaderFailed = true;
            return errFail;
        }
    }
    const int r = avformat_write_header(m_pFmtCtx, nullptr);
    if (r < 0)
    {
        char eb[128];
        av_strerror(r, eb, sizeof(eb));
        g_Log(logLevelError, "GDC Container :: avformat_write_header FAILED: %s (%d)", eb, r);
        m_HeaderFailed = true;
        return errFail;
    }
    m_HeaderWritten = true;
    g_Log(logLevelInfo, "GDC Container :: header written (%d streams)", m_pFmtCtx->nb_streams);
    return errNone;
}

StatusCode GdcContainer::WriteVideo(uint32_t p_StreamIdx, HostBufferRef* p_pBuf)
{
    if (p_pBuf == nullptr)
    {
        return errNone; // flush
    }
    std::lock_guard<std::mutex> lock(m_Mutex);
    StatusCode sts = EnsureHeader();
    if (sts != errNone) return sts;

    int64_t pts = 0, dts = 0;
    p_pBuf->GetINT64(pIOPropPTS, pts);
    if (!p_pBuf->GetINT64(pIOPropDTS, dts)) dts = pts;
    uint8_t isKey = 0;
    p_pBuf->GetUINT8(pIOPropIsKeyFrame, isKey);

    char* pData = nullptr;
    size_t size = 0;
    if (!p_pBuf->LockBuffer(&pData, &size)) return errFail;

    AVPacket* pPkt = av_packet_alloc();
    if (!pPkt || av_new_packet(pPkt, static_cast<int>(size)) < 0)
    {
        p_pBuf->UnlockBuffer();
        av_packet_free(&pPkt);
        return errAlloc;
    }
    memcpy(pPkt->data, pData, size);
    p_pBuf->UnlockBuffer();

    // Timestamps arrive in frame units of the video track (1 unit = 1 frame
    // interval); rescale into whatever time base the muxer settled on.
    AVStream* pSt = m_pFmtCtx->streams[p_StreamIdx];
    const AVRational srcTb = av_inv_q(pSt->avg_frame_rate);
    pPkt->stream_index = static_cast<int>(p_StreamIdx);
    pPkt->pts = pts;
    pPkt->dts = dts;
    pPkt->duration = 1;
    if (isKey) pPkt->flags |= AV_PKT_FLAG_KEY;
    av_packet_rescale_ts(pPkt, srcTb, pSt->time_base);

    const int r = av_interleaved_write_frame(m_pFmtCtx, pPkt);
    av_packet_free(&pPkt);
    if (r < 0)
    {
        char eb[128];
        av_strerror(r, eb, sizeof(eb));
        g_Log(logLevelError, "GDC Container :: video write FAILED: %s (%d)", eb, r);
        return errFail;
    }
    return errNone;
}

StatusCode GdcContainer::WriteAudio(uint32_t p_StreamIdx, HostBufferRef* p_pBuf)
{
    if (p_pBuf == nullptr)
    {
        return errNone; // flush
    }
    std::lock_guard<std::mutex> lock(m_Mutex);
    StatusCode sts = EnsureHeader();
    if (sts != errNone) return sts;

    StreamInfo& si = m_Streams[p_StreamIdx];
    char* pData = nullptr;
    size_t size = 0;
    if (!p_pBuf->LockBuffer(&pData, &size)) return errFail;
    const int frameBytes = si.bytesPerSample * si.channels;
    if (frameBytes <= 0 || size < static_cast<size_t>(frameBytes))
    {
        p_pBuf->UnlockBuffer();
        return errNone;
    }

    AVPacket* pPkt = av_packet_alloc();
    const size_t usable = size - (size % static_cast<size_t>(frameBytes));
    if (!pPkt || av_new_packet(pPkt, static_cast<int>(usable)) < 0)
    {
        p_pBuf->UnlockBuffer();
        av_packet_free(&pPkt);
        return errAlloc;
    }
    memcpy(pPkt->data, pData, usable);
    p_pBuf->UnlockBuffer();

    // Audio timing is derived from the running sample count, not from the
    // host's pts (whose unit is not documented for audio).
    AVStream* pSt = m_pFmtCtx->streams[p_StreamIdx];
    const int64_t nbSamples = static_cast<int64_t>(usable / static_cast<size_t>(frameBytes));
    pPkt->stream_index = static_cast<int>(p_StreamIdx);
    pPkt->pts = pPkt->dts = si.audioSamplesWritten;
    pPkt->duration = nbSamples;
    pPkt->flags |= AV_PKT_FLAG_KEY;
    si.audioSamplesWritten += nbSamples;
    av_packet_rescale_ts(pPkt, av_make_q(1, pSt->codecpar->sample_rate), pSt->time_base);

    const int r = av_interleaved_write_frame(m_pFmtCtx, pPkt);
    av_packet_free(&pPkt);
    if (r < 0)
    {
        char eb[128];
        av_strerror(r, eb, sizeof(eb));
        g_Log(logLevelError, "GDC Container :: audio write FAILED: %s (%d)", eb, r);
        return errFail;
    }
    return errNone;
}

StatusCode GdcContainer::DoClose()
{
    {
        std::lock_guard<std::mutex> lock(m_Mutex);
        if (m_pFmtCtx)
        {
            if (!m_HeaderWritten && !m_HeaderFailed && m_pFmtCtx->nb_streams > 0)
            {
                EnsureHeader();
            }
            if (m_HeaderWritten)
            {
                const int r = av_write_trailer(m_pFmtCtx);
                g_Log(logLevelInfo, "GDC Container :: trailer written (%d), file '%s' closed", r, m_Path.c_str());
            }
            if (m_pFmtCtx->pb) avio_closep(&m_pFmtCtx->pb);
            avformat_free_context(m_pFmtCtx);
            m_pFmtCtx = nullptr;
        }
    }
    for (GdcTrackWriter* pTrack : m_Tracks)
    {
        pTrack->Release();
    }
    m_Tracks.clear();
    return errNone;
}
