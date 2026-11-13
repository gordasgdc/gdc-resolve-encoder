#pragma once

#include <cstdint>
#include <mutex>
#include <string>
#include <vector>

#include <memory>

#include "wrapper/plugin_api.h"
#include "gdc_mux.h"

using namespace IOPlugin;

// One entry per container this plugin registers as its OWN top-level Format
// in Resolve's Deliver page (instead of hiding under QuickTime/MP4/MKV).
// The muxing itself is libavformat's, so HDR static metadata (mdcv/clli),
// colr/nclx and the codec's parameter sets are written by us, not by
// Resolve's built-in writers (which leave HDR10 out of the container).
struct ContainerFormat
{
    const unsigned char uuid[16];
    const char* displayName; // shown in Resolve's Format list
    const char* ext;         // file extension
    const char* avFormat;    // libavformat muxer name
};

extern const ContainerFormat g_ContainerFormats[];
extern const int g_NumContainerFormats;

class GdcTrackWriter;

class GdcContainer : public IPluginContainerRef
{
public:
    explicit GdcContainer(const ContainerFormat* p_pFormat);

    static StatusCode s_Register(HostListRef* p_pList);
    static const ContainerFormat* s_FindFormat(const unsigned char* p_pUUID);
    // Lower-case hex UUIDs, for the codec's pIOPropContainerList.
    static std::string s_UUIDHex(const ContainerFormat& p_Format);

    StatusCode WriteVideo(uint32_t p_StreamIdx, HostBufferRef* p_pBuf);
    StatusCode WriteAudio(uint32_t p_StreamIdx, HostBufferRef* p_pBuf);

protected:
    virtual StatusCode DoInit(HostPropertyCollectionRef* p_pProps) override;
    virtual StatusCode DoOpen(HostPropertyCollectionRef* p_pProps) override;
    virtual StatusCode DoAddTrack(HostPropertyCollectionRef* p_pProps, HostPropertyCollectionRef* p_pCodecProps, IPluginTrackBase** p_pTrack) override;
    virtual StatusCode DoClose() override;

protected:
    virtual ~GdcContainer();

private:
    void EnsureMux();

private:
    const ContainerFormat* m_pFormat;
    std::unique_ptr<GdcMux> m_pMux;
    std::string m_Path;
    int m_EncoderFailuresAtStart;
    std::mutex m_Mutex;
    std::vector<GdcTrackWriter*> m_Tracks;
};
