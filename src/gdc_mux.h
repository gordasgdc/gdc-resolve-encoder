#pragma once
// Host-independent muxing core of the GDC containers (libavformat mov / mp4 /
// matroska). GdcContainer (src/gdc_container.cpp) adapts Resolve's IOPlugin
// calls onto this class; tests/mux_roundtrip.cpp drives it directly, so the
// exact code that writes the user's file is what the regression tests run.

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

extern "C" {
#include <libavformat/avformat.h>
}

class GdcMux
{
public:
    enum LogLevel { kInfo = 0, kWarn = 1, kError = 2 };
    using LogFn = std::function<void(LogLevel, const std::string&)>;

    struct VideoParams
    {
        AVCodecID codecId = AV_CODEC_ID_NONE; // H264 or HEVC
        int width = 0, height = 0;
        int fpsNum = 0, fpsDen = 0;
        // Parameter sets as the encoder published them: Annex-B (H.264
        // cookie for Resolve's own writers) or an avcC/hvcC record.
        std::vector<uint8_t> extradata;
        int colorPrimaries = 0, colorTrc = 0, colorMatrix = 0;
        bool fullRange = false;
        std::string mdcv; // "G(..)B(..)R(..)WP(..)L(..)" or empty
        std::string cll;  // "maxCLL,maxFALL" or empty
        // Test hook only: hand the extradata to libavformat untouched
        // (reproduces the v1.7.0 H.264 defect).
        bool legacyRawExtradata = false;
    };

    struct AudioParams
    {
        int sampleRate = 0, channels = 0, bitDepth = 0;
        bool isFloat = false;
    };

    GdcMux(const char* p_pAvFormat, LogFn p_Log);
    ~GdcMux();

    void SetPath(const std::string& p_Path) { if (!p_Path.empty()) m_Path = p_Path; }
    const std::string& Path() const { return m_Path; }

    bool EnsureContext();
    // Return the stream index, or -1.
    int AddVideo(const VideoParams& p_Params);
    int AddAudio(const AudioParams& p_Params);

    // p_Pts/p_Dts in frame units (1 = one frame interval).
    bool WriteVideo(int p_StreamIdx, const uint8_t* p_pData, size_t p_Size, int64_t p_Pts, int64_t p_Dts, bool p_IsKey);
    // Interleaved little-endian PCM; timing derives from the sample count.
    bool WriteAudio(int p_StreamIdx, const uint8_t* p_pData, size_t p_Size);

    // Finalises the file. Returns true only if every packet and the trailer
    // were written without error. p_Abort=true (cancelled / failed render)
    // skips the trailer and removes the partial file.
    bool Close(bool p_Abort);

    bool Failed() const { return m_Failed; }
    int64_t VideoPackets() const { return m_VideoPackets; }
    int64_t AudioSamples(int p_StreamIdx) const;

private:
    struct StreamInfo
    {
        bool isVideo = false;
        int bytesPerSample = 0;
        int channels = 0;
        int64_t audioSamplesWritten = 0;
    };

    bool EnsureHeader();
    void Log(LogLevel p_Level, const char* p_pFmt, ...) const;
    void Fail(const char* p_pWhat, int p_AvErr);

    std::string m_AvFormat;
    LogFn m_Log;
    AVFormatContext* m_pFmtCtx = nullptr;
    std::string m_Path;
    bool m_HeaderWritten = false;
    bool m_Failed = false;
    bool m_FileOpened = false;
    int64_t m_VideoPackets = 0;
    int64_t m_VideoBytes = 0;
    std::vector<StreamInfo> m_Streams;
};
