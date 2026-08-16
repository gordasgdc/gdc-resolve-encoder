#pragma once

#include <cstdint>

extern "C" {
#include <libavutil/pixfmt.h>
}

// Explicit, compiler-portable FourCC construction — a bare 'avc1' style
// multi-character constant is technically compiler-defined behavior and
// MSVC can evaluate it differently than GCC/Clang, which would silently
// produce the wrong FourCC on Windows.
// FIXED: byte order was backwards. Apple/QuickTime FourCharCode convention
// (what a C multichar literal like 'avc1' actually evaluates to on
// GCC/Clang, which is what the official reference plugin relies on) packs
// the FIRST character into the HIGHEST byte, not the lowest. Verified by
// computing both 'avc1' as a multichar literal and this macro side-by-side
// and confirming exact match. The previous byte order meant every codec
// this plugin registered had a FourCC value Resolve's mov/mp4 writer would
// never actually recognize as real "avc1"/"hvc1" — a very plausible cause
// for track creation silently failing on every single codec variant.
#define GDC_FOURCC(a, b, c, d) \
    ((static_cast<unsigned int>(static_cast<unsigned char>(a)) << 24) | \
     (static_cast<unsigned int>(static_cast<unsigned char>(b)) << 16) | \
     (static_cast<unsigned int>(static_cast<unsigned char>(c)) << 8) | \
     (static_cast<unsigned int>(static_cast<unsigned char>(d))))

// One entry per codec variant this plugin registers with Resolve. Each
// variant maps to a specific FFmpeg (libavcodec) encoder name — the same
// generic FFmpegEncoder class drives all of them, whether it's a CPU
// encoder (libx264/libx265) or a platform hardware encoder
// (h264_videotoolbox on Mac, h264_nvenc on Windows/Linux with an NVIDIA
// GPU). Availability of hardware variants is checked at plugin startup —
// if FFmpeg can't find the encoder on this machine, it's simply not
// registered, so the same binary adapts per-platform automatically.
// (No AV1 variant yet — libsvtav1 could be added the same way later.)

struct EncoderVariant
{
    const unsigned char uuid[16];
    const char* avCodecName;   // name passed to avcodec_find_encoder_by_name()
    const char* displayName;   // shown in Resolve's codec list
    const char* group;         // shown as the codec group/category
    unsigned int fourCC;       // GDC_FOURCC('a','v','c','1') (H.264) or GDC_FOURCC('h','v','c','1') (H.265)
    bool isHEVC;
    bool isHardware;
    AVPixelFormat preferredPixFmt; // set explicitly rather than queried from
                                    // AVCodec::pix_fmts, which newer FFmpeg
                                    // versions have removed from the struct
    int bitDepth;               // 8 or 10 — drives pIOPropBitDepth and which
                                 // 8-bit vs 10-bit source buffer layout
                                 // FillFrameFromBuffer expects from Resolve
};

// NOTE: these UUIDs are unique to GDC Resolve Encoder. If you fork this
// project for your own distribution, generate fresh UUIDs to avoid
// clashing with this plugin if a user has both installed.
static const EncoderVariant g_EncoderVariants[] = {
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x01 },
        "libx264", "GDC H.264 (Software x264)", "GDC Encoder", GDC_FOURCC('a','v','c','1'), false, false, AV_PIX_FMT_YUV420P, 8,
    },
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x02 },
        "libx265", "GDC H.265 (Software x265)", "GDC Encoder", GDC_FOURCC('h','v','c','1'), true, false, AV_PIX_FMT_YUV420P, 8,
    },
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x03 },
        "h264_videotoolbox", "GDC H.264 (Apple VideoToolbox)", "GDC Encoder", GDC_FOURCC('a','v','c','1'), false, true, AV_PIX_FMT_NV12, 8,
    },
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x04 },
        "hevc_videotoolbox", "GDC H.265 (Apple VideoToolbox)", "GDC Encoder", GDC_FOURCC('h','v','c','1'), true, true, AV_PIX_FMT_NV12, 8,
    },
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x05 },
        "h264_nvenc", "GDC H.264 (NVIDIA NVENC)", "GDC Encoder", GDC_FOURCC('a','v','c','1'), false, true, AV_PIX_FMT_YUV420P, 8,
    },
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x06 },
        "hevc_nvenc", "GDC H.265 (NVIDIA NVENC)", "GDC Encoder", GDC_FOURCC('h','v','c','1'), true, true, AV_PIX_FMT_YUV420P, 8,
    },
    // 10-bit variants. Software only for now (libx264 High10 / libx265
    // Main10) — hardware 10-bit support (VideoToolbox/NVENC) varies too
    // much by GPU/driver to register unconditionally; can be added later
    // once tested against real hardware.
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x07 },
        "libx264", "GDC H.264 10-bit (Software x264 High10)", "GDC Encoder", GDC_FOURCC('a','v','c','1'), false, false, AV_PIX_FMT_YUV420P10LE, 10,
    },
    {
        { 0x9a, 0x1c, 0x3e, 0x02, 0x6b, 0x77, 0x4f, 0x10, 0x8e, 0x21, 0x0c, 0x4f, 0x2a, 0x91, 0x7d, 0x08 },
        "libx265", "GDC H.265 10-bit (Software x265 Main10)", "GDC Encoder", GDC_FOURCC('h','v','c','1'), true, false, AV_PIX_FMT_YUV420P10LE, 10,
    },
};

static const int g_NumEncoderVariants = sizeof(g_EncoderVariants) / sizeof(g_EncoderVariants[0]);
