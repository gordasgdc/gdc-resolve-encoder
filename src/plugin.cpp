#include "wrapper/plugin_api.h"
#include "ffmpeg_encoder.h"
#include "encoder_variants.h"

#include <cstring>
#include <cstdio>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavutil/log.h>
}

// NOTE: generate a fresh UUID if you fork this project for your own
// distribution, to avoid clashing with this plugin if a user has both
// installed at once.
static const uint8_t s_MyPluginUUID[] = { 0x4c, 0x2a, 0x91, 0x7d, 0x8f, 0x33, 0x4a, 0xe6, 0xb1, 0x02, 0x5f, 0x7c, 0x9d, 0x11, 0x6e, 0x40 };

using namespace IOPlugin;

static const char* s_UUIDToHex(const unsigned char* p_pUUID, char* p_pOut)
{
    static const char* hexChars = "0123456789ABCDEF";
    for (int i = 0; i < 16; ++i)
    {
        p_pOut[i * 2] = hexChars[(p_pUUID[i] >> 4) & 0xF];
        p_pOut[i * 2 + 1] = hexChars[p_pUUID[i] & 0xF];
    }
    p_pOut[32] = '\0';
    return p_pOut;
}

StatusCode g_HandleGetInfo(HostPropertyCollectionRef* p_pProps)
{
    StatusCode err = p_pProps->SetProperty(pIOPropUUID, propTypeUInt8, s_MyPluginUUID, 16);
    if (err == errNone)
    {
        const char* pName = "GDC Resolve Encoder";
        err = p_pProps->SetProperty(pIOPropName, propTypeString, pName, strlen(pName));
    }
    g_Log(logLevelInfo, "GDC Encoder :: g_HandleGetInfo called, returning err=%d", static_cast<int>(err));
    return err;
}

StatusCode g_HandleCreateObj(unsigned char* p_pUUID, ObjectRef* p_ppObj)
{
    char hexBuf[33];
    g_Log(logLevelInfo, "GDC Encoder :: g_HandleCreateObj called for UUID=%s", s_UUIDToHex(p_pUUID, hexBuf));

    const EncoderVariant* pVariant = FFmpegEncoder::s_FindVariant(p_pUUID);
    if (pVariant)
    {
        g_Log(logLevelInfo, "GDC Encoder :: UUID matched variant '%s', creating object", pVariant->displayName);
        *p_ppObj = new FFmpegEncoder(pVariant);
        return errNone;
    }
    g_Log(logLevelInfo, "GDC Encoder :: UUID did not match any of our %d variants (not for us)", g_NumEncoderVariants);
    return errUnsupported;
}

StatusCode g_HandlePluginStart()
{
    // Quiet down libav*'s own stderr logging — Resolve captures our g_Log
    // calls instead, and unfiltered FFmpeg logs are noisy in Resolve's log.
    av_log_set_level(AV_LOG_ERROR);
    g_Log(logLevelInfo, "GDC Encoder :: g_HandlePluginStart called");
    return errNone;
}

StatusCode g_HandlePluginTerminate()
{
    return errNone;
}

StatusCode g_ListCodecs(HostListRef* p_pList)
{
    g_Log(logLevelInfo, "GDC Encoder :: g_ListCodecs called");
    StatusCode err = FFmpegEncoder::s_RegisterCodecs(p_pList);
    g_Log(logLevelInfo, "GDC Encoder :: g_ListCodecs returning err=%d", static_cast<int>(err));
    return err;
}

StatusCode g_ListContainers(HostListRef* p_pList)
{
    // This plugin only supplies codecs, not container writers — Resolve's
    // own mp4/mov writer handles muxing using the codecs registered above.
    return errNone;
}

StatusCode g_GetEncoderSettings(unsigned char* p_pUUID, HostPropertyCollectionRef* p_pValues, HostListRef* p_pSettingsList)
{
    char hexBuf[33];
    g_Log(logLevelInfo, "GDC Encoder :: g_GetEncoderSettings called for UUID=%s", s_UUIDToHex(p_pUUID, hexBuf));
    return FFmpegEncoder::s_GetEncoderSettings(p_pUUID, p_pValues, p_pSettingsList);
}
