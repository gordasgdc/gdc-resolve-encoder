#pragma once

#include <string>

#include "wrapper/plugin_api.h"
#include "encoder_variants.h"

extern "C" {
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
}

using namespace IOPlugin;

// Generic encoder: wraps a single FFmpeg (libavcodec) encoder. Which actual
// codec it drives (libx264, libx265, h264_videotoolbox, h264_nvenc, ...) is
// decided entirely by the EncoderVariant it's constructed with — this one
// class implements every codec variant this plugin registers, rather than
// one bespoke class per codec.
class FFmpegEncoder : public IPluginCodecRef
{
public:
    explicit FFmpegEncoder(const EncoderVariant* p_pVariant);
    ~FFmpegEncoder();

    static StatusCode s_RegisterCodecs(HostListRef* p_pList);
    static StatusCode s_GetEncoderSettings(unsigned char* p_pUUID, HostPropertyCollectionRef* p_pValues, HostListRef* p_pSettingsList);
    static const EncoderVariant* s_FindVariant(const unsigned char* p_pUUID);

    // Returns true if FFmpeg can actually find/use this encoder on the
    // current machine (relevant for hardware encoders: VideoToolbox only
    // exists on Mac, NVENC only exists with an NVIDIA GPU + driver).
    static bool s_IsVariantAvailable(const EncoderVariant* p_pVariant);

public:
    // 2-pass (multi-pass) ABR: host calls this after DoFlush() completes a
    // pass, to ask whether another pass is needed. true after pass 1 of a
    // 2-pass job (analysis-only, output discarded — see m_SuppressOutput),
    // false otherwise (single-pass, or pass 2/final already done).
    virtual bool IsNeedNextPass() override;

protected:
    virtual void DoFlush() override;
    virtual StatusCode DoInit(HostPropertyCollectionRef* p_pProps) override;
    virtual StatusCode DoOpen(HostBufferRef* p_pBuff) override;
    virtual StatusCode DoProcess(HostBufferRef* p_pBuff) override;

private:
    StatusCode OpenCodec(HostBufferRef* p_pBuff);
    StatusCode EncodeFrame(AVFrame* p_pFrame);
    StatusCode DrainPackets();
    StatusCode FlushOneStep();
    StatusCode SendPacketToHost(AVPacket* p_pPkt);
    StatusCode FillFrameFromBuffer(HostBufferRef* p_pBuff, AVFrame* p_pFrame);
    // A fresh, unique path in the system temp dir for this job's 2-pass
    // stats log (x264/x265 write/read this file themselves via the
    // "passlogfile"/"x265-stats" AVOption — see OpenCodec).
    std::string MakeStatsFilePath() const;
    // Releases m_pCtx/m_pFrame/m_pPacket/m_pSwsCtx, if allocated. Needed in
    // the destructor AND at the start of every OpenCodec() call now that
    // OpenCodec can run twice per instance (2-pass: pass 1 then pass 2) —
    // without this, pass 2 would leak pass 1's entire AVCodecContext.
    void FreeCodecResources();

private:
    const EncoderVariant* m_pVariant;

    AVCodecContext* m_pCtx;
    AVFrame* m_pFrame;
    AVPacket* m_pPacket;
    SwsContext* m_pSwsCtx;

    HostCodecConfigCommon m_CommonProps;

    // UI-configurable settings
    int32_t m_QualityMode; // 0 = CRF/CQ, 1 = ABR bitrate, 2 = constant QP
    int32_t m_CRF;
    int32_t m_BitRateKbps;
    int32_t m_Preset; // maps to a libx264/libx265 preset string, ignored by hardware encoders
    int32_t m_Profile; // H.264 8-bit software only: index into baseline/main/high
    int32_t m_Tune;     // index into the codec-appropriate tune list, 0 = none
    int32_t m_QP;
    int32_t m_KeyframeIntervalSec; // GOP length, in seconds — converted to frames from the real source frame rate in OpenCodec
    int32_t m_Level; // index into s_LevelNames, 0 = "Auto" (don't set explicitly)
    std::string m_AdvancedParams; // raw x264-params/x265-params passthrough, MainConcept-style "expert" field
    bool m_MultiPassEnabled; // gdc_multipass checkbox — only offered for software encoders in ABR (bitrate) mode

    // 2-pass ABR state. m_PassNumber starts at 1 (also the value for an
    // ordinary single-pass job); OpenCodec() advances it to 2 when
    // IsNeedNextPass() told the host to call DoOpen() again. m_StatsFilePath
    // is a temp file x264/x265 themselves write to during pass 1 and read
    // back during pass 2, via the "passlogfile"/"x265-stats" AVOption (NOT
    // the generic AVCodecContext.stats_in/stats_out fields — verified
    // directly with a standalone libavcodec test that those come back
    // empty for both encoders; x264/x265 use their own private
    // file-based option instead, same as `ffmpeg -pass 1/2 -passlogfile`
    // does on the command line). m_SuppressOutput is true only during pass
    // 1: encoded bytes are deliberately never sent to the host (this pass
    // exists purely to produce the stats file — sending its output too
    // would double/corrupt whatever container track pass 2 also writes
    // into).
    int32_t m_PassNumber;
    std::string m_StatsFilePath;
    bool m_SuppressOutput;

    int64_t m_FrameCount;
    int64_t m_PacketCount;
    int64_t m_TotalBytesSent;
    bool m_HeaderSent;
    bool m_EofSentToEncoder;
    StatusCode m_Error;
};
