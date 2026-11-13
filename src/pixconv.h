// Host-frame pixel conversion helpers (header-only, no FFmpeg/Resolve
// dependency so tests/pixconv_test.cpp can exercise them directly).
//
// DaVinci Resolve hands 10-bit planar YUV to the plugin as 16-bit
// little-endian samples. These helpers turn such planes into the 10-bit
// samples libx264/libx265 expect (AV_PIX_FMT_YUV4xxP10LE).
#pragma once

#include <cstddef>
#include <cstdint>

namespace gdc
{

// Size in bytes of a tightly packed planar host frame.
inline size_t HostPlanarFrameBytes(int w, int h, bool chroma422, int bytesPerSample)
{
    const size_t cw = static_cast<size_t>(w) / 2;
    const size_t ch = chroma422 ? static_cast<size_t>(h) : static_cast<size_t>(h) / 2;
    return (static_cast<size_t>(w) * h + 2 * cw * ch) * static_cast<size_t>(bytesPerSample);
}

// 16-bit container -> 10 bit with rounding, clamped to 1023.
inline uint16_t Sample16To10(uint32_t v)
{
    v = (v + 32u) >> 6;
    return static_cast<uint16_t>(v > 1023u ? 1023u : v);
}

// Same-size plane copy, 16 -> 10 bit. Strides are in samples.
inline void Plane16To10(const uint16_t* s, size_t sStride, uint16_t* d, size_t dStride, int w, int h)
{
    for (int y = 0; y < h; ++y)
    {
        const uint16_t* ps = s + static_cast<size_t>(y) * sStride;
        uint16_t* pd = d + static_cast<size_t>(y) * dStride;
        for (int x = 0; x < w; ++x)
            pd[x] = Sample16To10(ps[x]);
    }
}

// Full-height (4:2:2) chroma plane of w x h samples -> half-height (4:2:0)
// plane of w x (h/2): each output row is the rounded mean of two source rows
// (vertical chroma siting between the rows, i.e. MPEG-2/H.264 "left"
// location), 16 -> 10 bit. Strides are in samples.
inline void Chroma422To420_16To10(const uint16_t* s, size_t sStride, uint16_t* d, size_t dStride, int w, int h)
{
    for (int y = 0; y < h / 2; ++y)
    {
        const uint16_t* a = s + static_cast<size_t>(2 * y) * sStride;
        const uint16_t* b = a + sStride;
        uint16_t* pd = d + static_cast<size_t>(y) * dStride;
        for (int x = 0; x < w; ++x)
        {
            const uint32_t v = (static_cast<uint32_t>(a[x]) + static_cast<uint32_t>(b[x]) + 64u) >> 7;
            pd[x] = static_cast<uint16_t>(v > 1023u ? 1023u : v);
        }
    }
}

} // namespace gdc
