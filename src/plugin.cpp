#include "wrapper/plugin_api.h"
#include "ffmpeg_encoder.h"
#include "encoder_variants.h"

#include <cstring>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavutil/log.h>
}

// NOTE: generate a fresh UUID if you fork this project for your own
// distribution, to avoid clashing with this plugin if a user has both
// installed at once.
static const uint8_t s_MyPluginUUID[] = { 0x4c, 0x2a, 0x91, 0x7d, 0x8f, 0x33, 0x4a, 0xe6, 0xb1, 0x02, 0x5f, 0x7c, 0x9d, 0x11, 0x6e, 0x40 };

using namespace IOPlugin;

StatusCode g_HandleGetInfo(HostPropertyCollectionRef* p_pProps)
{
    StatusCode err = p_pProps->SetProperty(pIOPropUUID, propTypeUInt8, s_MyPluginUUID, 16);
    if (err == errNone)
    {
        const char* pName = "GDC Resolve Encoder";
        err = p_pProps->SetProperty(pIOPropName, propTypeString, pName, strlen(pName));
    }
    return err;
}

StatusCode g_HandleCreateObj(unsigned char* p_pUUID, ObjectRef* p_ppObj)
{
    const EncoderVariant* pVariant = FFmpegEncoder::s_FindVariant(p_pUUID);
    if (pVariant)
    {
        *p_ppObj = new FFmpegEncoder(pVariant);
        return errNone;
    }
    return errUnsupported;
}

StatusCode g_HandlePluginStart()
{
    // Quiet down libav*'s own stderr logging — Resolve captures our g_Log
    // calls instead, and unfiltered FFmpeg logs are noisy in Resolve's log.
    av_log_set_level(AV_LOG_ERROR);
    return errNone;
}

StatusCode g_HandlePluginTerminate()
{
    return errNone;
}

StatusCode g_ListCodecs(HostListRef* p_pList)
{
    return FFmpegEncoder::s_RegisterCodecs(p_pList);
}

StatusCode g_ListContainers(HostListRef* p_pList)
{
    // This plugin only supplies codecs, not container writers — Resolve's
    // own mp4/mov writer handles muxing using the codecs registered above.
    return errNone;
}

StatusCode g_GetEncoderSettings(unsigned char* p_pUUID, HostPropertyCollectionRef* p_pValues, HostListRef* p_pSettingsList)
{
    return FFmpegEncoder::s_GetEncoderSettings(p_pUUID, p_pValues, p_pSettingsList);
}
