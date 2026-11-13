// Unit test for src/pixconv.h (no Resolve, no FFmpeg).
// Regression for the 10-bit 4:2:0 defect found on Resolve 21.2: the 16-bit
// 4:2:0 host layout was not planar, so 10-bit 4:2:0 variants now request
// 4:2:2 planes from the host and halve the chroma height here.
#include "src/pixconv.h"

#include <cstdio>
#include <vector>

static int g_fail = 0;
#define CHECK(cond, msg) do { if (!(cond)) { std::printf("FAIL: %s\n", msg); ++g_fail; } } while (0)

int main()
{
    // Rounding / clamping of the 16 -> 10 bit conversion.
    CHECK(gdc::Sample16To10(0) == 0, "0 -> 0");
    CHECK(gdc::Sample16To10(4096) == 64, "legal black 4096 -> 64");
    CHECK(gdc::Sample16To10(60160) == 940, "legal white 60160 -> 940");
    CHECK(gdc::Sample16To10(31) == 0 && gdc::Sample16To10(32) == 1, "round half up at 32");
    CHECK(gdc::Sample16To10(65535) == 1023, "clamp at 1023");

    // Frame size accounting used to validate the host buffer.
    CHECK(gdc::HostPlanarFrameBytes(1920, 1080, false, 2) == 6220800, "4:2:0 16-bit 1080p = 6220800 B");
    CHECK(gdc::HostPlanarFrameBytes(1920, 1080, true, 2) == 8294400, "4:2:2 16-bit 1080p = 8294400 B");
    CHECK(gdc::HostPlanarFrameBytes(1920, 1080, false, 1) == 3110400, "4:2:0 8-bit 1080p = 3110400 B");

    // 4:2:2 -> 4:2:0 chroma: a vertical ramp must come out as the mean of row pairs.
    const int w = 8, h = 6;
    std::vector<uint16_t> src(w * h), dst(w * (h / 2));
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x)
            src[y * w + x] = static_cast<uint16_t>((100 + 64 * y) * 64 + x * 64); // 10-bit value (100+64y)+x, in 16 bits
    gdc::Chroma422To420_16To10(src.data(), w, dst.data(), w, w, h);
    for (int y = 0; y < h / 2; ++y)
        for (int x = 0; x < w; ++x)
        {
            const int want = ((100 + 64 * (2 * y) + x) + (100 + 64 * (2 * y + 1) + x) + 1) / 2;
            if (dst[y * w + x] != want)
            {
                std::printf("FAIL: chroma row %d col %d got %u want %d\n", y, x, dst[y * w + x], want);
                ++g_fail;
            }
        }

    // Constant plane stays constant; clamp holds at full scale.
    std::vector<uint16_t> full(w * h, 65535), out(w * (h / 2));
    gdc::Chroma422To420_16To10(full.data(), w, out.data(), w, w, h);
    CHECK(out[0] == 1023 && out[out.size() - 1] == 1023, "full-scale chroma clamps to 1023");

    std::printf("result: %s\n", g_fail ? "FAILED" : "ok");
    return g_fail ? 1 : 0;
}
