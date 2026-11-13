#include "gdc_mux.h"
#include "bitstream.h"

#include <cstdarg>
#include <cstdio>
#include <cstring>

extern "C" {
#include <libavutil/mastering_display_metadata.h>
#include <libavutil/channel_layout.h>
#include <libavutil/mem.h>
}

GdcMux::GdcMux(const char* p_pAvFormat, LogFn p_Log)
    : m_AvFormat(p_pAvFormat ? p_pAvFormat : "")
    , m_Log(std::move(p_Log))
{
}

GdcMux::~GdcMux()
{
    if (m_pFmtCtx)
    {
        // Destroyed without Close(): never leave a half-written file that
        // looks like an export.
        Close(true);
    }
}

void GdcMux::Log(LogLevel p_Level, const char* p_pFmt, ...) const
{
    if (!m_Log) return;
    char buf[1024];
    va_list ap;
    va_start(ap, p_pFmt);
    vsnprintf(buf, sizeof(buf), p_pFmt, ap);
    va_end(ap);
    m_Log(p_Level, buf);
}

void GdcMux::Fail(const char* p_pWhat, int p_AvErr)
{
    char eb[128] = "";
    av_strerror(p_AvErr, eb, sizeof(eb));
    Log(kError, "GDC Container :: %s FAILED: %s (%d)", p_pWhat, eb, p_AvErr);
    m_Failed = true;
}

bool GdcMux::EnsureContext()
{
    if (m_pFmtCtx) return true;
    const int ret = avformat_alloc_output_context2(&m_pFmtCtx, nullptr, m_AvFormat.c_str(), nullptr);
    if (ret < 0 || !m_pFmtCtx)
    {
        m_pFmtCtx = nullptr;
        Fail("avformat_alloc_output_context2", ret);
        return false;
    }
    return true;
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

int GdcMux::AddVideo(const VideoParams& p_Params)
{
    if (!EnsureContext()) return -1;
    if (p_Params.codecId != AV_CODEC_ID_H264 && p_Params.codecId != AV_CODEC_ID_HEVC)
    {
        Log(kError, "GDC Container :: unsupported video codec (only H.264/H.265 from GDC Encoder)");
        return -1;
    }

    AVStream* pSt = avformat_new_stream(m_pFmtCtx, nullptr);
    if (!pSt) return -1;

    AVCodecParameters* pPar = pSt->codecpar;
    pPar->codec_type = AVMEDIA_TYPE_VIDEO;
    pPar->codec_id = p_Params.codecId;
    pPar->width = p_Params.width;
    pPar->height = p_Params.height;
    if (p_Params.codecId == AV_CODEC_ID_HEVC) pPar->codec_tag = MKTAG('h', 'v', 'c', '1'); // Apple wants hvc1, not hev1

    const int fpsNum = p_Params.fpsNum > 0 ? p_Params.fpsNum : 25;
    const int fpsDen = p_Params.fpsDen > 0 ? p_Params.fpsDen : 1;
    pSt->time_base = av_make_q(fpsDen, fpsNum);
    pSt->avg_frame_rate = av_make_q(fpsNum, fpsDen);
    pSt->r_frame_rate = pSt->avg_frame_rate;

    // Parameter sets. This plugin ALWAYS writes length-prefixed packets
    // (see FFmpegEncoder::SendPacketToHost), and libavformat decides the
    // packet framing from the extradata: Annex-B extradata makes the mov /
    // matroska muxers re-parse every packet as Annex-B, which turns each
    // length-prefixed H.264 frame into a 1-byte sample (v1.7.0 defect:
    // "export complete", file undecodable). So the H.264 Annex-B cookie
    // (kept for Resolve's own writers) is converted to an avcC record here.
    std::vector<uint8_t> extradata = p_Params.extradata;
    const char* extradataKind = "as provided";
    if (!p_Params.legacyRawExtradata && p_Params.codecId == AV_CODEC_ID_H264 && !extradata.empty() &&
        gdc_bs::StartsWithStartCode(extradata.data(), static_cast<int>(extradata.size())))
    {
        std::vector<std::vector<uint8_t>> nals;
        gdc_bs::SplitAnnexBNALs(extradata.data(), static_cast<int>(extradata.size()), nals);
        std::vector<uint8_t> avcc = gdc_bs::BuildAvcConfigRecord(nals);
        if (avcc.empty())
        {
            Log(kError, "GDC Container :: cannot build avcC from the H.264 parameter sets (%d bytes, %d NALs)",
                static_cast<int>(extradata.size()), static_cast<int>(nals.size()));
            m_Failed = true;
            return -1;
        }
        extradata.swap(avcc);
        extradataKind = "avcC (converted from Annex-B)";
    }
    if (!extradata.empty())
    {
        pPar->extradata = static_cast<uint8_t*>(av_mallocz(extradata.size() + AV_INPUT_BUFFER_PADDING_SIZE));
        if (!pPar->extradata) return -1;
        memcpy(pPar->extradata, extradata.data(), extradata.size());
        pPar->extradata_size = static_cast<int>(extradata.size());
    }
    else
    {
        Log(kError, "GDC Container :: no parameter sets (magic cookie) on the video codec — refusing to write an undecodable file");
        m_Failed = true;
        return -1;
    }

    if (p_Params.colorPrimaries > 0) pPar->color_primaries = static_cast<AVColorPrimaries>(p_Params.colorPrimaries);
    if (p_Params.colorTrc > 0) pPar->color_trc = static_cast<AVColorTransferCharacteristic>(p_Params.colorTrc);
    if (p_Params.colorMatrix > 0) pPar->color_space = static_cast<AVColorSpace>(p_Params.colorMatrix);
    pPar->color_range = p_Params.fullRange ? AVCOL_RANGE_JPEG : AVCOL_RANGE_MPEG;

    if (!p_Params.mdcv.empty())
    {
        size_t sz = 0;
        AVMasteringDisplayMetadata* pMd = av_mastering_display_metadata_alloc_size(&sz);
        if (pMd)
        {
            ParseMdcv(p_Params.mdcv, pMd);
            if (!av_packet_side_data_add(&pPar->coded_side_data, &pPar->nb_coded_side_data, AV_PKT_DATA_MASTERING_DISPLAY_METADATA, pMd, sz, 0))
            {
                av_free(pMd);
            }
        }
    }
    if (!p_Params.cll.empty())
    {
        unsigned maxCll = 0, maxFall = 0;
        if (sscanf(p_Params.cll.c_str(), "%u,%u", &maxCll, &maxFall) == 2)
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

    Log(kInfo, "GDC Container :: video track: %dx%d %d/%d fps, codec=%s, parameter sets=%d bytes %s, color pri=%d trc=%d mtx=%d range=%d, mdcv=%s, cll=%s",
        pPar->width, pPar->height, fpsNum, fpsDen, p_Params.codecId == AV_CODEC_ID_HEVC ? "hevc" : "h264",
        pPar->extradata_size, extradataKind, p_Params.colorPrimaries, p_Params.colorTrc, p_Params.colorMatrix, p_Params.fullRange ? 1 : 0,
        p_Params.mdcv.empty() ? "none" : p_Params.mdcv.c_str(), p_Params.cll.empty() ? "none" : p_Params.cll.c_str());
    return pSt->index;
}

int GdcMux::AddAudio(const AudioParams& p_Params)
{
    if (!EnsureContext()) return -1;

    AVCodecID codecId = AV_CODEC_ID_NONE;
    if (p_Params.isFloat && p_Params.bitDepth == 32) codecId = AV_CODEC_ID_PCM_F32LE;
    else if (p_Params.bitDepth == 16) codecId = AV_CODEC_ID_PCM_S16LE;
    else if (p_Params.bitDepth == 24) codecId = AV_CODEC_ID_PCM_S24LE;
    else if (p_Params.bitDepth == 32) codecId = AV_CODEC_ID_PCM_S32LE;
    if (codecId == AV_CODEC_ID_NONE || p_Params.sampleRate <= 0 || p_Params.channels <= 0)
    {
        Log(kError, "GDC Container :: unsupported audio track: rate=%d ch=%d depth=%d float=%d",
            p_Params.sampleRate, p_Params.channels, p_Params.bitDepth, p_Params.isFloat ? 1 : 0);
        return -1;
    }

    AVStream* pSt = avformat_new_stream(m_pFmtCtx, nullptr);
    if (!pSt) return -1;
    AVCodecParameters* pPar = pSt->codecpar;
    pPar->codec_type = AVMEDIA_TYPE_AUDIO;
    pPar->codec_id = codecId;
    pPar->sample_rate = p_Params.sampleRate;
    av_channel_layout_default(&pPar->ch_layout, p_Params.channels);
    pPar->bits_per_coded_sample = p_Params.bitDepth;
    pPar->bits_per_raw_sample = p_Params.bitDepth;
    pPar->block_align = p_Params.channels * p_Params.bitDepth / 8;
    pSt->time_base = av_make_q(1, p_Params.sampleRate);

    StreamInfo si;
    si.isVideo = false;
    si.bytesPerSample = p_Params.bitDepth / 8;
    si.channels = p_Params.channels;
    if (m_Streams.size() <= static_cast<size_t>(pSt->index)) m_Streams.resize(pSt->index + 1);
    m_Streams[pSt->index] = si;

    Log(kInfo, "GDC Container :: audio track: %d Hz, %d ch, %d-bit%s (PCM, little-endian)",
        p_Params.sampleRate, p_Params.channels, p_Params.bitDepth, p_Params.isFloat ? " float" : "");
    return pSt->index;
}

bool GdcMux::EnsureHeader()
{
    if (m_HeaderWritten) return true;
    if (m_Failed || !m_pFmtCtx) return false;
    if (m_Path.empty())
    {
        Log(kError, "GDC Container :: no output path known when the header must be written");
        m_Failed = true;
        return false;
    }

    if (!(m_pFmtCtx->oformat->flags & AVFMT_NOFILE))
    {
        const int r = avio_open(&m_pFmtCtx->pb, m_Path.c_str(), AVIO_FLAG_WRITE);
        if (r < 0)
        {
            Fail("avio_open", r);
            return false;
        }
        m_FileOpened = true;
    }
    const int r = avformat_write_header(m_pFmtCtx, nullptr);
    if (r < 0)
    {
        Fail("avformat_write_header", r);
        return false;
    }
    m_HeaderWritten = true;
    Log(kInfo, "GDC Container :: header written (%d streams)", m_pFmtCtx->nb_streams);
    return true;
}

bool GdcMux::WriteVideo(int p_StreamIdx, const uint8_t* p_pData, size_t p_Size, int64_t p_Pts, int64_t p_Dts, bool p_IsKey)
{
    if (m_Failed) return false;
    if (!EnsureHeader()) return false;
    if (p_StreamIdx < 0 || p_StreamIdx >= static_cast<int>(m_pFmtCtx->nb_streams)) return false;

    AVPacket* pPkt = av_packet_alloc();
    if (!pPkt || av_new_packet(pPkt, static_cast<int>(p_Size)) < 0)
    {
        av_packet_free(&pPkt);
        Fail("video packet alloc", AVERROR(ENOMEM));
        return false;
    }
    memcpy(pPkt->data, p_pData, p_Size);

    AVStream* pSt = m_pFmtCtx->streams[p_StreamIdx];
    const AVRational srcTb = av_inv_q(pSt->avg_frame_rate);
    pPkt->stream_index = p_StreamIdx;
    pPkt->pts = p_Pts;
    pPkt->dts = p_Dts;
    pPkt->duration = 1;
    if (p_IsKey) pPkt->flags |= AV_PKT_FLAG_KEY;
    av_packet_rescale_ts(pPkt, srcTb, pSt->time_base);

    const int r = av_interleaved_write_frame(m_pFmtCtx, pPkt);
    av_packet_free(&pPkt);
    if (r < 0)
    {
        Log(kError, "GDC Container :: video packet #%lld (pts=%lld dts=%lld, %zu bytes) rejected by the muxer",
            static_cast<long long>(m_VideoPackets), static_cast<long long>(p_Pts), static_cast<long long>(p_Dts), p_Size);
        Fail("video write", r);
        return false;
    }
    ++m_VideoPackets;
    m_VideoBytes += static_cast<int64_t>(p_Size);
    return true;
}

bool GdcMux::WriteAudio(int p_StreamIdx, const uint8_t* p_pData, size_t p_Size)
{
    if (m_Failed) return false;
    if (!EnsureHeader()) return false;
    if (p_StreamIdx < 0 || p_StreamIdx >= static_cast<int>(m_Streams.size())) return false;

    StreamInfo& si = m_Streams[p_StreamIdx];
    const int frameBytes = si.bytesPerSample * si.channels;
    if (frameBytes <= 0 || p_Size < static_cast<size_t>(frameBytes))
    {
        return true; // nothing usable in this buffer
    }
    const size_t usable = p_Size - (p_Size % static_cast<size_t>(frameBytes));

    AVPacket* pPkt = av_packet_alloc();
    if (!pPkt || av_new_packet(pPkt, static_cast<int>(usable)) < 0)
    {
        av_packet_free(&pPkt);
        Fail("audio packet alloc", AVERROR(ENOMEM));
        return false;
    }
    memcpy(pPkt->data, p_pData, usable);

    AVStream* pSt = m_pFmtCtx->streams[p_StreamIdx];
    const int64_t nbSamples = static_cast<int64_t>(usable / static_cast<size_t>(frameBytes));
    pPkt->stream_index = p_StreamIdx;
    pPkt->pts = pPkt->dts = si.audioSamplesWritten;
    pPkt->duration = nbSamples;
    pPkt->flags |= AV_PKT_FLAG_KEY;
    si.audioSamplesWritten += nbSamples;
    av_packet_rescale_ts(pPkt, av_make_q(1, pSt->codecpar->sample_rate), pSt->time_base);

    const int r = av_interleaved_write_frame(m_pFmtCtx, pPkt);
    av_packet_free(&pPkt);
    if (r < 0)
    {
        Fail("audio write", r);
        return false;
    }
    return true;
}

int64_t GdcMux::AudioSamples(int p_StreamIdx) const
{
    if (p_StreamIdx < 0 || p_StreamIdx >= static_cast<int>(m_Streams.size())) return 0;
    return m_Streams[p_StreamIdx].audioSamplesWritten;
}

bool GdcMux::Close(bool p_Abort)
{
    if (!m_pFmtCtx) return !m_Failed;

    bool ok = !m_Failed && !p_Abort;
    if (ok && !m_HeaderWritten && m_pFmtCtx->nb_streams > 0)
    {
        ok = EnsureHeader();
    }
    if (m_HeaderWritten)
    {
        // The trailer is written even on abort so libavformat releases its
        // interleaving queue cleanly; the file is removed right after.
        const int r = av_write_trailer(m_pFmtCtx);
        if (r < 0)
        {
            Fail("trailer write", r);
            ok = false;
        }
    }
    if (m_pFmtCtx->pb)
    {
        const int ioErr = m_pFmtCtx->pb->error;
        const int r = avio_closep(&m_pFmtCtx->pb);
        if (ioErr < 0 || r < 0)
        {
            Fail("file write/close (disk full or volume gone?)", ioErr < 0 ? ioErr : r);
            ok = false;
        }
    }
    avformat_free_context(m_pFmtCtx);
    m_pFmtCtx = nullptr;

    if (ok && m_VideoPackets == 0 && !m_Streams.empty() && m_Streams[0].isVideo)
    {
        Log(kError, "GDC Container :: no video packet reached the file");
        ok = false;
    }

    if (ok)
    {
        Log(kInfo, "GDC Container :: file '%s' finalised: %lld video packets, %lld video bytes",
            m_Path.c_str(), static_cast<long long>(m_VideoPackets), static_cast<long long>(m_VideoBytes));
    }
    else if (m_FileOpened && !m_Path.empty())
    {
        // A failed or cancelled export must not leave something that looks
        // like a finished deliverable.
        const int rr = remove(m_Path.c_str());
        Log(kWarn, "GDC Container :: export %s — partial file '%s' %s",
            p_Abort ? "aborted" : "FAILED", m_Path.c_str(), rr == 0 ? "removed" : "could NOT be removed");
    }
    return ok;
}
