#include "gdc_container.h"
#include "encoder_variants.h"

#include <cassert>
#include <cstdio>
#include <cstring>

#include <atomic>

extern std::atomic<int> g_GdcEncoderFailureCount; // src/ffmpeg_encoder.cpp
void GdcInstallAvLog();                            // src/ffmpeg_encoder.cpp

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
// Thin adapter: Resolve's IOPlugin container calls -> GdcMux (src/gdc_mux.cpp),
// which holds all the libavformat logic and is covered by tests/mux_roundtrip.

GdcContainer::GdcContainer(const ContainerFormat* p_pFormat)
    : m_pFormat(p_pFormat)
    , m_EncoderFailuresAtStart(g_GdcEncoderFailureCount.load())
{
}

GdcContainer::~GdcContainer()
{
    // GdcMux's destructor aborts (and removes the partial file) if the host
    // never called DoClose.
}

void GdcContainer::EnsureMux()
{
    if (m_pMux) return;
    GdcInstallAvLog();
    m_pMux.reset(new GdcMux(m_pFormat->avFormat, [](GdcMux::LogLevel p_Level, const std::string& p_Msg) {
        g_Log(p_Level == GdcMux::kError ? logLevelError : (p_Level == GdcMux::kWarn ? logLevelWarn : logLevelInfo), "%s", p_Msg.c_str());
    }));
    m_pMux->SetPath(m_Path);
}

// The host's call order is DoInit (no path) -> DoAddTrack x N -> DoOpen
// (path) -> writes -> DoClose, so the path is only required when the header
// is written (first packet).
StatusCode GdcContainer::DoInit(HostPropertyCollectionRef* p_pProps)
{
    std::lock_guard<std::mutex> lock(m_Mutex);
    std::string path;
    if (p_pProps->GetString(pIOPropPath, path) && !path.empty()) m_Path = path;
    if (m_pMux) m_pMux->SetPath(m_Path);
    return errNone;
}

StatusCode GdcContainer::DoOpen(HostPropertyCollectionRef* p_pProps)
{
    std::lock_guard<std::mutex> lock(m_Mutex);
    std::string path;
    if (p_pProps->GetString(pIOPropPath, path) && !path.empty()) m_Path = path;
    EnsureMux();
    m_pMux->SetPath(m_Path);
    g_Log(logLevelInfo, "GDC Container :: DoOpen '%s' path='%s'", m_pFormat->displayName, m_Path.c_str());
    return m_pMux->EnsureContext() ? errNone : errFail;
}

StatusCode GdcContainer::DoAddTrack(HostPropertyCollectionRef* p_pProps, HostPropertyCollectionRef* p_pCodecProps, IPluginTrackBase** p_pTrack)
{
    std::lock_guard<std::mutex> lock(m_Mutex);
    EnsureMux();
    uint32_t mediaType = 0;
    if (!p_pProps->GetUINT32(pIOPropMediaType, mediaType) || ((mediaType != mediaVideo) && (mediaType != mediaAudio)))
    {
        return errInvalidParam;
    }
    const bool isVideo = (mediaType == mediaVideo);

    int streamIdx = -1;
    if (isVideo)
    {
        HostCodecConfigCommon cfg;
        cfg.Load(p_pProps);

        GdcMux::VideoParams vp;
        uint32_t fourCC = 0;
        p_pCodecProps->GetUINT32(pIOPropFourCC, fourCC);
        if (fourCC == GDC_FOURCC('a', 'v', 'c', '1')) vp.codecId = AV_CODEC_ID_H264;
        else if (fourCC == GDC_FOURCC('h', 'v', 'c', '1')) vp.codecId = AV_CODEC_ID_HEVC;
        else
        {
            g_Log(logLevelError, "GDC Container :: unsupported video fourCC 0x%08x (only H.264/H.265 from GDC Encoder)", fourCC);
            return errNoCodec;
        }
        vp.width = static_cast<int>(cfg.GetWidth());
        vp.height = static_cast<int>(cfg.GetHeight());
        vp.fpsNum = static_cast<int>(cfg.GetFrameRateNum());
        vp.fpsDen = static_cast<int>(cfg.GetFrameRateDen());

        PropertyType type = propTypeNull;
        const void* pVal = nullptr;
        int n = 0;
        if (p_pCodecProps->GetProperty(pIOPropMagicCookie, &type, &pVal, &n) == errNone && type == propTypeUInt8 && n > 0 && pVal)
        {
            const uint8_t* p = static_cast<const uint8_t*>(pVal);
            vp.extradata.assign(p, p + n);
        }

        // Color tags + HDR static metadata, passed from the encoder as custom
        // props on its codec buffer (see FFmpegEncoder::OpenCodec).
        int32_t pri = 0, trc = 0, mtx = 0, range = 0;
        p_pCodecProps->GetINT32("gdc_pri", pri);
        p_pCodecProps->GetINT32("gdc_trc", trc);
        p_pCodecProps->GetINT32("gdc_mtx", mtx);
        p_pCodecProps->GetINT32("gdc_range", range);
        vp.colorPrimaries = pri;
        vp.colorTrc = trc;
        vp.colorMatrix = mtx;
        vp.fullRange = (range != 0);
        p_pCodecProps->GetString("gdc_mdcv", vp.mdcv);
        p_pCodecProps->GetString("gdc_cll", vp.cll);
        streamIdx = m_pMux->AddVideo(vp);
    }
    else
    {
        uint32_t samplingRate = 0, numChannels = 0, bitDepth = 0;
        uint8_t isFloat = 0;
        p_pProps->GetUINT32(pIOPropSamplingRate, samplingRate);
        p_pProps->GetUINT32(pIOPropNumChannels, numChannels);
        p_pProps->GetUINT32(pIOPropBitDepth, bitDepth); // storage depth
        p_pProps->GetUINT8(pIOPropIsFloat, isFloat);
        GdcMux::AudioParams ap;
        ap.sampleRate = static_cast<int>(samplingRate);
        ap.channels = static_cast<int>(numChannels);
        ap.bitDepth = static_cast<int>(bitDepth);
        ap.isFloat = (isFloat != 0);
        streamIdx = m_pMux->AddAudio(ap);
    }
    if (streamIdx < 0)
    {
        g_Log(logLevelError, "GDC Container :: %s track REJECTED", isVideo ? "video" : "audio");
        return errNoCodec;
    }

    GdcTrackWriter* pTrack = new GdcTrackWriter(this, static_cast<uint32_t>(streamIdx), isVideo);
    pTrack->Retain();
    *p_pTrack = pTrack;
    m_Tracks.push_back(pTrack);
    return errNone;
}

StatusCode GdcContainer::WriteVideo(uint32_t p_StreamIdx, HostBufferRef* p_pBuf)
{
    if (p_pBuf == nullptr)
    {
        return errNone; // flush
    }
    std::lock_guard<std::mutex> lock(m_Mutex);
    if (!m_pMux) return errFail;

    int64_t pts = 0, dts = 0;
    p_pBuf->GetINT64(pIOPropPTS, pts);
    if (!p_pBuf->GetINT64(pIOPropDTS, dts)) dts = pts;
    uint8_t isKey = 0;
    p_pBuf->GetUINT8(pIOPropIsKeyFrame, isKey);

    char* pData = nullptr;
    size_t size = 0;
    if (!p_pBuf->LockBuffer(&pData, &size)) return errFail;
    const bool ok = m_pMux->WriteVideo(static_cast<int>(p_StreamIdx), reinterpret_cast<const uint8_t*>(pData), size, pts, dts, isKey != 0);
    p_pBuf->UnlockBuffer();
    return ok ? errNone : errFail;
}

StatusCode GdcContainer::WriteAudio(uint32_t p_StreamIdx, HostBufferRef* p_pBuf)
{
    if (p_pBuf == nullptr)
    {
        return errNone; // flush
    }
    std::lock_guard<std::mutex> lock(m_Mutex);
    if (!m_pMux) return errFail;

    char* pData = nullptr;
    size_t size = 0;
    if (!p_pBuf->LockBuffer(&pData, &size)) return errFail;
    const bool ok = m_pMux->WriteAudio(static_cast<int>(p_StreamIdx), reinterpret_cast<const uint8_t*>(pData), size);
    p_pBuf->UnlockBuffer();
    return ok ? errNone : errFail;
}

StatusCode GdcContainer::DoClose()
{
    StatusCode sts = errNone;
    {
        std::lock_guard<std::mutex> lock(m_Mutex);
        if (m_pMux)
        {
            // If the encoder failed during this export, the file is
            // incomplete whatever the muxer thinks: abort and remove it.
            const bool encoderFailed = (g_GdcEncoderFailureCount.load() != m_EncoderFailuresAtStart);
            if (encoderFailed)
            {
                g_Log(logLevelError, "GDC Container :: the encoder reported a failure during this export — not finalising '%s'", m_Path.c_str());
            }
            if (!m_pMux->Close(encoderFailed)) sts = errFail;
            m_pMux.reset();
        }
    }
    for (GdcTrackWriter* pTrack : m_Tracks)
    {
        pTrack->Release();
    }
    m_Tracks.clear();
    return sts;
}
