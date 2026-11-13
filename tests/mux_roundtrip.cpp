// Regression harness for the GDC containers, independent of DaVinci Resolve.
//
// Encodes synthetic frames with the SAME encoder setup, parameter-set
// "cookie" and packet framing the plugin uses (src/bitstream.h), feeds them
// through the SAME muxing core the plugin uses (src/gdc_mux.cpp), then
// re-opens the file and decodes every frame.
//
//   mux_roundtrip <encoder> <mov|mp4|matroska> <out-file> [--legacy] [--frames N]
//                 [--pixfmt yuv420p|yuv420p10le|yuv422p10le|nv12|p010le] [--fps num/den]
//                 [--no-audio] [--abort]
//
// --legacy reproduces v1.7.0 (H.264 Annex-B cookie handed to libavformat
// untouched): the expected result there is FAIL.
// Exit code 0 = file decodes to exactly N frames (+ audio duration matches).

#include "../src/bitstream.h"
#include "../src/gdc_mux.h"

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libavutil/opt.h>
#include <libavutil/pixdesc.h>
}

static void FillFrame(AVFrame* f, int n)
{
    const AVPixFmtDescriptor* d = av_pix_fmt_desc_get(static_cast<AVPixelFormat>(f->format));
    const int depth = d->comp[0].depth;
    const bool wide = depth > 8;
    const int maxv = (1 << depth) - 1;
    const bool semi = (f->format == AV_PIX_FMT_NV12 || f->format == AV_PIX_FMT_P010LE);
    const int shift = (f->format == AV_PIX_FMT_P010LE) ? 6 : 0;
    for (int y = 0; y < f->height; ++y)
        for (int x = 0; x < f->width; ++x)
        {
            const int v = ((x + y + n * 4) * maxv / (f->width + f->height)) % (maxv + 1);
            if (wide) reinterpret_cast<uint16_t*>(f->data[0] + y * f->linesize[0])[x] = static_cast<uint16_t>(v << shift);
            else f->data[0][y * f->linesize[0] + x] = static_cast<uint8_t>(v);
        }
    const int cw = AV_CEIL_RSHIFT(f->width, d->log2_chroma_w), ch = AV_CEIL_RSHIFT(f->height, d->log2_chroma_h);
    for (int y = 0; y < ch; ++y)
        for (int x = 0; x < cw; ++x)
        {
            const int u = (maxv / 2 + (x * 40 * (maxv / 255 + 0)) / cw + n) % (maxv + 1);
            const int v = (maxv / 2 + (y * 40) / ch) % (maxv + 1);
            if (semi)
            {
                if (wide)
                {
                    uint16_t* p = reinterpret_cast<uint16_t*>(f->data[1] + y * f->linesize[1]);
                    p[2 * x] = static_cast<uint16_t>(u << shift);
                    p[2 * x + 1] = static_cast<uint16_t>(v << shift);
                }
                else
                {
                    f->data[1][y * f->linesize[1] + 2 * x] = static_cast<uint8_t>(u);
                    f->data[1][y * f->linesize[1] + 2 * x + 1] = static_cast<uint8_t>(v);
                }
            }
            else if (wide)
            {
                reinterpret_cast<uint16_t*>(f->data[1] + y * f->linesize[1])[x] = static_cast<uint16_t>(u);
                reinterpret_cast<uint16_t*>(f->data[2] + y * f->linesize[2])[x] = static_cast<uint16_t>(v);
            }
            else
            {
                f->data[1][y * f->linesize[1] + x] = static_cast<uint8_t>(u);
                f->data[2][y * f->linesize[2] + x] = static_cast<uint8_t>(v);
            }
        }
}

int main(int argc, char** argv)
{
    if (argc < 4)
    {
        fprintf(stderr, "usage: %s <encoder> <mov|mp4|matroska> <out> [--legacy] [--frames N] [--pixfmt F] [--fps n/d] [--no-audio] [--abort]\n", argv[0]);
        return 2;
    }
    const char* encName = argv[1];
    const char* fmtName = argv[2];
    const std::string outPath = argv[3];
    bool legacy = false, withAudio = true, doAbort = false;
    int nFrames = 90, fpsNum = 30, fpsDen = 1;
    AVPixelFormat pixFmt = AV_PIX_FMT_NONE;
    for (int i = 4; i < argc; ++i)
    {
        if (!strcmp(argv[i], "--legacy")) legacy = true;
        else if (!strcmp(argv[i], "--no-audio")) withAudio = false;
        else if (!strcmp(argv[i], "--abort")) doAbort = true;
        else if (!strcmp(argv[i], "--frames") && i + 1 < argc) nFrames = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--pixfmt") && i + 1 < argc) pixFmt = av_get_pix_fmt(argv[++i]);
        else if (!strcmp(argv[i], "--fps") && i + 1 < argc) sscanf(argv[++i], "%d/%d", &fpsNum, &fpsDen);
    }

    const AVCodec* pCodec = avcodec_find_encoder_by_name(encName);
    if (!pCodec) { fprintf(stderr, "SKIP: encoder %s not available\n", encName); return 77; }
    const bool isHevc = pCodec->id == AV_CODEC_ID_HEVC;
    const bool isHw = strstr(encName, "videotoolbox") != nullptr;
    if (pixFmt == AV_PIX_FMT_NONE) pixFmt = isHw ? AV_PIX_FMT_NV12 : AV_PIX_FMT_YUV420P;

    AVCodecContext* c = avcodec_alloc_context3(pCodec);
    c->width = 640; c->height = 360;
    c->time_base = AVRational{ fpsDen, fpsNum };
    c->framerate = AVRational{ fpsNum, fpsDen };
    c->gop_size = static_cast<int>(lround(2.0 * fpsNum / fpsDen));
    c->max_b_frames = 2;
    c->pix_fmt = pixFmt;
    c->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
    c->color_range = AVCOL_RANGE_MPEG;
    c->color_primaries = AVCOL_PRI_BT709; c->color_trc = AVCOL_TRC_BT709; c->colorspace = AVCOL_SPC_BT709;
    AVDictionary* opts = nullptr;
    if (isHw) c->bit_rate = 4000000;
    else { av_dict_set(&opts, "preset", "veryfast", 0); av_dict_set(&opts, "crf", "23", 0); }
    if (avcodec_open2(c, pCodec, &opts) < 0) { fprintf(stderr, "FAIL: avcodec_open2(%s)\n", encName); return 1; }
    av_dict_free(&opts);

    // Cookie exactly as FFmpegEncoder::OpenCodec builds it.
    std::vector<std::vector<uint8_t>> nals;
    if (c->extradata && c->extradata_size > 0)
    {
        if (gdc_bs::StartsWithStartCode(c->extradata, c->extradata_size)) gdc_bs::SplitAnnexBNALs(c->extradata, c->extradata_size, nals);
    }
    std::vector<uint8_t> cookie;
    if (nals.empty() && c->extradata_size > 0)
    {
        cookie.assign(c->extradata, c->extradata + c->extradata_size); // already avcC/hvcC
    }
    else if (isHevc) cookie = gdc_bs::BuildHevcConfigRecord(nals);
    else
        for (auto& nal : nals)
        {
            if (gdc_bs::NalTypeH264(nal) == 6) continue;
            static const uint8_t sc[4] = { 0, 0, 0, 1 };
            cookie.insert(cookie.end(), sc, sc + 4);
            cookie.insert(cookie.end(), nal.begin(), nal.end());
        }
    printf("encoder=%s extradata=%d bytes (%s) cookie=%zu bytes\n", encName, c->extradata_size,
           (c->extradata_size > 0 && gdc_bs::StartsWithStartCode(c->extradata, c->extradata_size)) ? "annexb" : "record", cookie.size());

    GdcMux mux(fmtName, [](GdcMux::LogLevel l, const std::string& m) { printf("  [%s] %s\n", l == GdcMux::kError ? "ERR" : (l == GdcMux::kWarn ? "WRN" : "inf"), m.c_str()); });
    mux.SetPath(outPath);
    GdcMux::VideoParams vp;
    vp.codecId = pCodec->id; vp.width = c->width; vp.height = c->height; vp.fpsNum = fpsNum; vp.fpsDen = fpsDen;
    vp.extradata = cookie; vp.colorPrimaries = 1; vp.colorTrc = 1; vp.colorMatrix = 1; vp.legacyRawExtradata = legacy;
    const int vIdx = mux.AddVideo(vp);
    int aIdx = -1;
    if (withAudio)
    {
        GdcMux::AudioParams ap; ap.sampleRate = 48000; ap.channels = 2; ap.bitDepth = 24;
        aIdx = mux.AddAudio(ap);
    }
    if (vIdx < 0 || (withAudio && aIdx < 0)) { printf("FAIL: track setup\n"); return 1; }

    AVFrame* f = av_frame_alloc();
    f->format = pixFmt; f->width = c->width; f->height = c->height;
    av_frame_get_buffer(f, 32);
    AVPacket* pkt = av_packet_alloc();
    bool muxOk = true;
    int64_t pktIndex = 0;
    const int hwDtsDelay = (!legacy && isHw && c->max_b_frames > 0 && c->has_b_frames > 0) ? (c->has_b_frames > c->max_b_frames ? c->has_b_frames : c->max_b_frames) : 0;
    std::vector<uint8_t> conv;
    auto drain = [&]() {
        while (avcodec_receive_packet(c, pkt) >= 0)
        {
            const size_t convSize = gdc_bs::ConvertAnnexBToLengthPrefixedRaw(pkt->data, pkt->size, nullptr);
            const uint8_t* pData = pkt->data; size_t size = static_cast<size_t>(pkt->size);
            if (convSize > 0 && gdc_bs::StartsWithStartCode(pkt->data, pkt->size)) // same rule as FFmpegEncoder::SendPacketToHost
            {
                conv.resize(convSize);
                gdc_bs::ConvertAnnexBToLengthPrefixedRaw(pkt->data, pkt->size, conv.data());
                pData = conv.data(); size = convSize;
            }
            if (getenv("GDC_TS")) printf("  ts pts=%lld dts=%lld key=%d size=%d\n", (long long)pkt->pts, (long long)pkt->dts, (pkt->flags & AV_PKT_FLAG_KEY) ? 1 : 0, pkt->size);
            // Same DTS rule as FFmpegEncoder::SendPacketToHost (VideoToolbox only, not in --legacy).
            int64_t dts = pkt->dts;
            if (hwDtsDelay > 0) dts = pktIndex - hwDtsDelay;
            ++pktIndex;
            if (!mux.WriteVideo(vIdx, pData, size, pkt->pts, dts, (pkt->flags & AV_PKT_FLAG_KEY) != 0)) muxOk = false;
            av_packet_unref(pkt);
        }
    };
    // 24-bit stereo 1 kHz tone, one video frame's worth per frame (as Resolve delivers audio alongside video).
    int64_t audioPos = 0;
    for (int n = 0; n < nFrames && muxOk; ++n)
    {
        if (withAudio)
        {
            const int64_t end = static_cast<int64_t>(n + 1) * 48000 * fpsDen / fpsNum;
            std::vector<uint8_t> pcm;
            for (; audioPos < end; ++audioPos)
            {
                const int32_t s = static_cast<int32_t>(lround(sin(2.0 * M_PI * 1000.0 * audioPos / 48000.0) * 0.1 * 8388607.0));
                for (int ch = 0; ch < 2; ++ch) { pcm.push_back(s & 0xFF); pcm.push_back((s >> 8) & 0xFF); pcm.push_back((s >> 16) & 0xFF); }
            }
            if (!mux.WriteAudio(aIdx, pcm.data(), pcm.size())) muxOk = false;
        }
        av_frame_make_writable(f);
        FillFrame(f, n);
        f->pts = n;
        if (avcodec_send_frame(c, f) < 0) { printf("FAIL: send_frame %d\n", n); return 1; }
        drain();
    }
    avcodec_send_frame(c, nullptr);
    drain();
    const bool closeOk = mux.Close(doAbort || !muxOk);
    avcodec_free_context(&c); av_frame_free(&f); av_packet_free(&pkt);

    if (doAbort)
    {
        FILE* fp = fopen(outPath.c_str(), "rb");
        if (fp) { fclose(fp); printf("FAIL: aborted export left a file behind\n"); return 1; }
        printf("PASS: aborted export left no file\n");
        return 0;
    }
    if (!muxOk || !closeOk) { printf("FAIL: muxer reported an error (muxOk=%d closeOk=%d)\n", muxOk, closeOk); return 1; }

    // ── verification: reopen, decode everything ──
    AVFormatContext* in = nullptr;
    if (avformat_open_input(&in, outPath.c_str(), nullptr, nullptr) < 0 || avformat_find_stream_info(in, nullptr) < 0) { printf("FAIL: cannot reopen output\n"); return 1; }
    int vs = av_find_best_stream(in, AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
    int as = av_find_best_stream(in, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
    if (vs < 0) { printf("FAIL: no video stream\n"); return 1; }
    const AVCodec* dec = avcodec_find_decoder(in->streams[vs]->codecpar->codec_id);
    AVCodecContext* dc = avcodec_alloc_context3(dec);
    avcodec_parameters_to_context(dc, in->streams[vs]->codecpar);
    av_log_set_level(AV_LOG_QUIET);
    avcodec_open2(dc, dec, nullptr);
    AVPacket* rp = av_packet_alloc(); AVFrame* rf = av_frame_alloc();
    int decoded = 0; int64_t audioBytes = 0, videoBytes = 0; int minPacket = 1 << 30;
    while (av_read_frame(in, rp) >= 0)
    {
        if (rp->stream_index == vs)
        {
            videoBytes += rp->size; if (rp->size < minPacket) minPacket = rp->size;
            if (avcodec_send_packet(dc, rp) >= 0) while (avcodec_receive_frame(dc, rf) >= 0) ++decoded;
        }
        else if (rp->stream_index == as) audioBytes += rp->size;
        av_packet_unref(rp);
    }
    avcodec_send_packet(dc, nullptr);
    while (avcodec_receive_frame(dc, rf) >= 0) ++decoded;
    const int64_t expectAudio = withAudio ? static_cast<int64_t>(nFrames) * 48000 * fpsDen / fpsNum * 6 : 0;
    const double vDur = in->streams[vs]->duration * av_q2d(in->streams[vs]->time_base);
    printf("result: decoded=%d/%d videoBytes=%lld minVideoPacket=%d audioBytes=%lld/%lld videoDur=%.4fs (expect %.4fs)\n",
           decoded, nFrames, static_cast<long long>(videoBytes), minPacket, static_cast<long long>(audioBytes), static_cast<long long>(expectAudio),
           vDur, static_cast<double>(nFrames) * fpsDen / fpsNum);
    bool pass = decoded == nFrames && audioBytes == expectAudio && (withAudio ? as >= 0 : true);
    if (in->streams[vs]->duration != AV_NOPTS_VALUE && fabs(vDur - static_cast<double>(nFrames) * fpsDen / fpsNum) > 0.5 * fpsDen / fpsNum) pass = false;
    avformat_close_input(&in);
    printf("%s\n", pass ? "PASS" : "FAIL");
    return pass ? 0 : 1;
}
