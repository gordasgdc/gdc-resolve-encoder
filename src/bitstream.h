#pragma once
// Bitstream helpers shared by the encoder, the GDC container and the
// standalone regression tests (tests/mux_roundtrip.cpp). Header-only, no
// host (Resolve) dependency.

#include <cstdint>
#include <cstring>
#include <vector>

namespace gdc_bs {

inline int NalTypeH264(const std::vector<uint8_t>& p_Nal) { return p_Nal.empty() ? -1 : (p_Nal[0] & 0x1F); }
inline int NalTypeH265(const std::vector<uint8_t>& p_Nal) { return p_Nal.empty() ? -1 : ((p_Nal[0] >> 1) & 0x3F); }

inline bool StartsWithStartCode(const uint8_t* p_pData, int p_Size)
{
    if (p_Size >= 3 && p_pData[0] == 0 && p_pData[1] == 0 && p_pData[2] == 1) return true;
    return p_Size >= 4 && p_pData[0] == 0 && p_pData[1] == 0 && p_pData[2] == 0 && p_pData[3] == 1;
}

// ─────────────────────────────────────────────────────────────────────────
// Annex-B -> length-prefixed NAL conversion
//
// libx264/libx265 (and most FFmpeg H.264/H.265 encoders) emit Annex-B
// bytestream packets: each NAL unit is preceded by a start code (00 00 01
// or 00 00 00 01). MP4/MOV containers instead expect each NAL prefixed by
// its own big-endian 4-byte length, with no start codes ("AVCC"/"HVCC"
// format) — this is what Resolve's container writer expects from the
// buffer this plugin hands it. Converting explicitly here (rather than
// relying on a specific FFmpeg flag combination behaving a certain way)
// keeps this correct regardless of encoder/version quirks.
// ─────────────────────────────────────────────────────────────────────────
inline size_t ConvertAnnexBToLengthPrefixedRaw(const uint8_t* p_pData, int p_Size, uint8_t* p_pOut)
{
    size_t outPos = 0;
    int i = 0;
    while (i < p_Size - 3)
    {
        int startCodeLen = 0;
        if (p_pData[i] == 0 && p_pData[i + 1] == 0 && p_pData[i + 2] == 1)
        {
            startCodeLen = 3;
        }
        else if ((i < p_Size - 4) && p_pData[i] == 0 && p_pData[i + 1] == 0 && p_pData[i + 2] == 0 && p_pData[i + 3] == 1)
        {
            startCodeLen = 4;
        }
        else
        {
            ++i;
            continue;
        }

        int nalStart = i + startCodeLen;
        int nalEnd = p_Size;
        for (int j = nalStart; j < p_Size - 3; ++j)
        {
            if ((p_pData[j] == 0 && p_pData[j + 1] == 0 && p_pData[j + 2] == 1) ||
                (j < p_Size - 4 && p_pData[j] == 0 && p_pData[j + 1] == 0 && p_pData[j + 2] == 0 && p_pData[j + 3] == 1))
            {
                nalEnd = j;
                break;
            }
        }

        int nalLen = nalEnd - nalStart;
        if (nalLen > 0)
        {
            uint8_t lenBytes[4] = {
                static_cast<uint8_t>((nalLen >> 24) & 0xFF),
                static_cast<uint8_t>((nalLen >> 16) & 0xFF),
                static_cast<uint8_t>((nalLen >> 8) & 0xFF),
                static_cast<uint8_t>(nalLen & 0xFF),
            };
            if (p_pOut)
            {
                memcpy(p_pOut + outPos, lenBytes, 4);
                memcpy(p_pOut + outPos + 4, p_pData + nalStart, static_cast<size_t>(nalLen));
            }
            outPos += 4 + static_cast<size_t>(nalLen);
        }

        i = nalEnd;
    }
    return outPos;
}

inline void ConvertAnnexBToLengthPrefixed(const uint8_t* p_pData, int p_Size, std::vector<uint8_t>& p_Out)
{
    p_Out.resize(ConvertAnnexBToLengthPrefixedRaw(p_pData, p_Size, nullptr));
    if (!p_Out.empty())
    {
        ConvertAnnexBToLengthPrefixedRaw(p_pData, p_Size, p_Out.data());
    }
}

// Splits Annex-B extradata (SPS/PPS with start codes, as libx264/libx265
// with AV_CODEC_FLAG_GLOBAL_HEADER produce) into a list of raw NALs, for
// building an avcC/hvcC-style magic cookie.
inline void SplitAnnexBNALs(const uint8_t* p_pData, int p_Size, std::vector<std::vector<uint8_t>>& p_OutNals)
{
    std::vector<uint8_t> combined;
    ConvertAnnexBToLengthPrefixed(p_pData, p_Size, combined);

    size_t pos = 0;
    while (pos + 4 <= combined.size())
    {
        int len = (combined[pos] << 24) | (combined[pos + 1] << 16) | (combined[pos + 2] << 8) | combined[pos + 3];
        pos += 4;
        if (pos + len > combined.size() || len <= 0)
        {
            break;
        }
        p_OutNals.emplace_back(combined.begin() + pos, combined.begin() + pos + len);
        pos += len;
    }
}

// ISO/IEC 14496-15 AVCDecoderConfigurationRecord ("avcC") from raw SPS/PPS
// NALs. Needed by the GDC containers: libavformat decides whether packets
// are Annex-B or length-prefixed by looking at the extradata, and this
// plugin always hands it length-prefixed packets. Returns empty if there
// is no SPS or no PPS.
inline std::vector<uint8_t> BuildAvcConfigRecord(const std::vector<std::vector<uint8_t>>& p_Nals)
{
    std::vector<const std::vector<uint8_t>*> sps, pps;
    for (auto& n : p_Nals)
    {
        const int t = NalTypeH264(n);
        if (t == 7) sps.push_back(&n);
        else if (t == 8) pps.push_back(&n);
    }
    if (sps.empty() || pps.empty() || sps[0]->size() < 4) return {};
    if (sps.size() > 31 || pps.size() > 255) return {};

    const std::vector<uint8_t>& s = *sps[0];
    std::vector<uint8_t> out;
    out.push_back(1);    // configurationVersion
    out.push_back(s[1]); // AVCProfileIndication
    out.push_back(s[2]); // profile_compatibility
    out.push_back(s[3]); // AVCLevelIndication
    out.push_back(0xFF); // reserved + lengthSizeMinusOne = 3 (4-byte lengths)
    out.push_back(static_cast<uint8_t>(0xE0 | sps.size()));
    for (auto* n : sps)
    {
        out.push_back(static_cast<uint8_t>((n->size() >> 8) & 0xFF));
        out.push_back(static_cast<uint8_t>(n->size() & 0xFF));
        out.insert(out.end(), n->begin(), n->end());
    }
    out.push_back(static_cast<uint8_t>(pps.size()));
    for (auto* n : pps)
    {
        out.push_back(static_cast<uint8_t>((n->size() >> 8) & 0xFF));
        out.push_back(static_cast<uint8_t>(n->size() & 0xFF));
        out.insert(out.end(), n->begin(), n->end());
    }
    // High-profile extension (chroma format / bit depths), required for
    // profile_idc 100/110/122/244/44: parse just enough of the SPS.
    const uint8_t profileIdc = s[1];
    if (profileIdc == 100 || profileIdc == 110 || profileIdc == 122 || profileIdc == 244 || profileIdc == 44)
    {
        // RBSP after nal header(1) + profile(1) + constraints(1) + level(1)
        std::vector<uint8_t> rbsp;
        int zeros = 0;
        for (size_t i = 4; i < s.size(); ++i)
        {
            if (zeros >= 2 && s[i] == 3) { zeros = 0; continue; }
            zeros = (s[i] == 0) ? zeros + 1 : 0;
            rbsp.push_back(s[i]);
        }
        size_t bitPos = 0;
        auto bit = [&]() -> uint32_t {
            const size_t byteIdx = bitPos / 8;
            if (byteIdx >= rbsp.size()) return 0;
            const uint32_t v = (rbsp[byteIdx] >> (7 - (bitPos % 8))) & 1u;
            ++bitPos;
            return v;
        };
        auto ue = [&]() -> uint32_t {
            int z = 0;
            while (bit() == 0 && z < 32) ++z;
            uint32_t v = 0;
            for (int i = 0; i < z; ++i) v = (v << 1) | bit();
            return (z == 0) ? 0 : ((1u << z) - 1 + v);
        };
        ue(); // seq_parameter_set_id
        const uint32_t chromaFormatIdc = ue();
        if (chromaFormatIdc == 3) bit(); // separate_colour_plane_flag
        const uint32_t bitDepthLumaMinus8 = ue();
        const uint32_t bitDepthChromaMinus8 = ue();
        out.push_back(static_cast<uint8_t>(0xFC | (chromaFormatIdc & 0x03)));
        out.push_back(static_cast<uint8_t>(0xF8 | (bitDepthLumaMinus8 & 0x07)));
        out.push_back(static_cast<uint8_t>(0xF8 | (bitDepthChromaMinus8 & 0x07)));
        out.push_back(0); // numOfSequenceParameterSetExt
    }
    return out;
}

// ─── ISO/IEC 14496-15 hvcC construction (moved verbatim from ffmpeg_encoder.cpp) ───
class RbspBitReader
{
public:
    explicit RbspBitReader(const std::vector<uint8_t>& p_Data)
    {
        int zeroCount = 0;
        for (size_t i = 0; i < p_Data.size(); ++i)
        {
            uint8_t b = p_Data[i];
            if (zeroCount >= 2 && b == 3) { zeroCount = 0; continue; }
            zeroCount = (b == 0) ? (zeroCount + 1) : 0;
            m_Data.push_back(b);
        }
    }

    int ReadBit()
    {
        size_t byteIdx = m_BitPos / 8;
        if (byteIdx >= m_Data.size()) return 0;
        int bitIdx = 7 - static_cast<int>(m_BitPos % 8);
        int bit = (m_Data[byteIdx] >> bitIdx) & 1;
        ++m_BitPos;
        return bit;
    }

    uint64_t ReadBits(int p_N)
    {
        uint64_t v = 0;
        for (int i = 0; i < p_N; ++i) v = (v << 1) | static_cast<uint64_t>(ReadBit());
        return v;
    }

    uint32_t ReadUE()
    {
        int zeros = 0;
        while (ReadBit() == 0)
        {
            ++zeros;
            if (zeros > 32) return 0;
        }
        if (zeros == 0) return 0;
        return static_cast<uint32_t>((1u << zeros) - 1 + ReadBits(zeros));
    }

private:
    std::vector<uint8_t> m_Data;
    size_t m_BitPos = 0;
};

struct H265SpsInfo
{
    uint8_t profileSpace = 0, tierFlag = 0, profileIdc = 0, levelIdc = 0;
    uint32_t profileCompatFlags = 0;
    uint64_t constraintFlags = 0;
    uint32_t chromaFormatIdc = 1, bitDepthLumaMinus8 = 0, bitDepthChromaMinus8 = 0;
};

inline H265SpsInfo ParseH265Sps(const std::vector<uint8_t>& p_SpsNal)
{
    H265SpsInfo info;
    if (p_SpsNal.size() < 4) return info;
    std::vector<uint8_t> rest(p_SpsNal.begin() + 2, p_SpsNal.end()); // skip 2-byte NAL header
    RbspBitReader br(rest);

    br.ReadBits(4);
    uint64_t maxSubLayersMinus1 = br.ReadBits(3);
    br.ReadBits(1);

    info.profileSpace = static_cast<uint8_t>(br.ReadBits(2));
    info.tierFlag = static_cast<uint8_t>(br.ReadBits(1));
    info.profileIdc = static_cast<uint8_t>(br.ReadBits(5));
    info.profileCompatFlags = static_cast<uint32_t>(br.ReadBits(32));
    info.constraintFlags = br.ReadBits(48);
    info.levelIdc = static_cast<uint8_t>(br.ReadBits(8));

    std::vector<int> subProfilePresent, subLevelPresent;
    for (uint64_t i = 0; i < maxSubLayersMinus1; ++i)
    {
        subProfilePresent.push_back(br.ReadBit());
        subLevelPresent.push_back(br.ReadBit());
    }
    if (maxSubLayersMinus1 > 0)
    {
        for (uint64_t i = maxSubLayersMinus1; i < 8; ++i) br.ReadBits(2);
    }
    for (uint64_t i = 0; i < maxSubLayersMinus1; ++i)
    {
        if (subProfilePresent[i]) br.ReadBits(88);
        if (subLevelPresent[i]) br.ReadBits(8);
    }

    br.ReadUE();
    info.chromaFormatIdc = br.ReadUE();
    if (info.chromaFormatIdc == 3) br.ReadBit();
    br.ReadUE(); br.ReadUE();
    if (br.ReadBit()) { br.ReadUE(); br.ReadUE(); br.ReadUE(); br.ReadUE(); }
    info.bitDepthLumaMinus8 = br.ReadUE();
    info.bitDepthChromaMinus8 = br.ReadUE();
    return info;
}

inline std::vector<uint8_t> BuildHevcConfigRecord(const std::vector<std::vector<uint8_t>>& p_Nals)
{
    const std::vector<uint8_t>* pVps = nullptr;
    const std::vector<uint8_t>* pSps = nullptr;
    const std::vector<uint8_t>* pPps = nullptr;
    for (auto& n : p_Nals)
    {
        int t = NalTypeH265(n);
        if (t == 32 && !pVps) pVps = &n;
        else if (t == 33 && !pSps) pSps = &n;
        else if (t == 34 && !pPps) pPps = &n;
    }
    if (!pSps) return {};

    H265SpsInfo s = ParseH265Sps(*pSps);

    std::vector<uint8_t> out;
    out.push_back(1);
    out.push_back(static_cast<uint8_t>((s.profileSpace << 6) | (s.tierFlag << 5) | (s.profileIdc & 0x1F)));
    for (int i = 3; i >= 0; --i) out.push_back(static_cast<uint8_t>((s.profileCompatFlags >> (i * 8)) & 0xFF));
    for (int i = 5; i >= 0; --i) out.push_back(static_cast<uint8_t>((s.constraintFlags >> (i * 8)) & 0xFF));
    out.push_back(s.levelIdc);
    out.push_back(0xF0); out.push_back(0x00);
    out.push_back(0xFC);
    out.push_back(static_cast<uint8_t>(0xFC | (s.chromaFormatIdc & 0x03)));
    out.push_back(static_cast<uint8_t>(0xF8 | (s.bitDepthLumaMinus8 & 0x07)));
    out.push_back(static_cast<uint8_t>(0xF8 | (s.bitDepthChromaMinus8 & 0x07)));
    out.push_back(0x00); out.push_back(0x00);
    out.push_back(static_cast<uint8_t>((0 << 6) | (1 << 3) | (0 << 2) | 3));

    struct ArrEntry { const std::vector<uint8_t>* nal; int type; };
    std::vector<ArrEntry> arrays;
    if (pVps) arrays.push_back({ pVps, 32 });
    arrays.push_back({ pSps, 33 });
    if (pPps) arrays.push_back({ pPps, 34 });

    out.push_back(static_cast<uint8_t>(arrays.size()));
    for (auto& a : arrays)
    {
        out.push_back(static_cast<uint8_t>((1 << 7) | (a.type & 0x3F)));
        out.push_back(0x00); out.push_back(0x01);
        out.push_back(static_cast<uint8_t>((a.nal->size() >> 8) & 0xFF));
        out.push_back(static_cast<uint8_t>(a.nal->size() & 0xFF));
        out.insert(out.end(), a.nal->begin(), a.nal->end());
    }
    return out;
}

} // namespace gdc_bs
