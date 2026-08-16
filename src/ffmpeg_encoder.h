#pragma once

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
    int32_t m_Profile; // H.264 8-bit software only: index into baseline/main/high/high422
    int32_t m_Tune;     // index into the codec-appropriate tune list, 0 = none
    int32_t m_QP;

    int64_t m_FrameCount;
    int64_t m_PacketCount;
    int64_t m_TotalBytesSent;
    bool m_HeaderSent;
    bool m_EofSentToEncoder;
    StatusCode m_Error;
};
