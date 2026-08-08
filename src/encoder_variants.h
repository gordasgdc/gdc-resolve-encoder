#pragma once

#include <cstdint>

// Explicit, compiler-portable FourCC construction — a bare 'avc1' style
// multi-character constant is technically compiler-defined behavior and
// MSVC can evaluate it differently than GCC/Clang, which would silently
// produce the wrong FourCC on Windows.
#define GDC_FOURCC(a, b, c, d) \
    (static_cast<unsigned int>(static_cast<unsigned char>(a)) | \
     (static_cast<unsigned int>(static_cast<unsigned char>(b)) << 8) | \
     (static_cast<unsigned int>(static_cast<unsigned char>(c)) << 16) | \
     (static_cast<unsigned int>(static_cast<unsigned char>(d)) << 24))

// One entry per codec variant this plugin registers with Resolve. Each
// variant maps to a specific FFmpeg (libavcodec) encoder name — the same
// generic FFmpegEncoder class drives all of them, whether it's a CPU
// encoder (libx264/libx265/libsvtav1) or a platform hardware encoder
// (h264_videotoolbox on Mac, h264_nvenc on Windows/Linux with an NVIDIA
// GPU). Availability of hardware variants is checked at plugin startup —
// if FFmpeg can't find the encoder on this machine, it's simply not
// registered, so the same binary adapts per-platform automatically.

struct EncoderVariant
{
    const unsigned char uuid[16];
    const char* avCodecName;   // name passed to avcodec_find_encoder_by_name()
    const char* displayName;   // shown in Resolve's codec list
    const char* group;         // shown as the codec group/category
    unsigned int fourCC;       // GDC_FOURCC('a','v','c','1') (H.264) or GDC_FOURCC('h','v','c','1') (H.265)
    bool isHEVC;
    bool isHardware;
};

// NOTE: these UUIDs are unique to GDC Resolve Encoder. If you fork this
// project for your own distribution, generate fresh UUIDs to avoid
// clashing with this plugin if a user has both installed.
static const EncoderVariant g_EncoderVariants[] = {
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x01 },
        "libx264", "GDC H.264 (Software x264)", "GDC Encoder", GDC_FOURCC('a','v','c','1'), false, false,
    },
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x02 },
        "libx265", "GDC H.265 (Software x265)", "GDC Encoder", GDC_FOURCC('h','v','c','1'), true, false,
    },
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x03 },
        "h264_videotoolbox", "GDC H.264 (Apple VideoToolbox)", "GDC Encoder", GDC_FOURCC('a','v','c','1'), false, true,
    },
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x04 },
        "hevc_videotoolbox", "GDC H.265 (Apple VideoToolbox)", "GDC Encoder", GDC_FOURCC('h','v','c','1'), true, true,
    },
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x05 },
        "h264_nvenc", "GDC H.264 (NVIDIA NVENC)", "GDC Encoder", GDC_FOURCC('a','v','c','1'), false, true,
    },
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x06 },
        "hevc_nvenc", "GDC H.265 (NVIDIA NVENC)", "GDC Encoder", GDC_FOURCC('h','v','c','1'), true, true,
    },
};

static const int g_NumEncoderVariants = sizeof(g_EncoderVariants) / sizeof(g_EncoderVariants[0]);
