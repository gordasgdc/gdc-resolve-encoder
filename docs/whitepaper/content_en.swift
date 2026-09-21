import Foundation

// English edition, part 1 (chapters 1–9). Customer-facing: no internal names, no code details.

func recipeEN(_ title: String, _ rows: [[String]]) -> [Block] {
    [.h3(title), .table(headers: ["Setting", "Value"], rows: rows, widths: [0.26, 0.74])]
}

func whitepaperBlocksEN() -> [Block] {
    var b: [Block] = []
    b += en1(); b += en2(); b += en3(); b += en4(); b += en5(); b += en6()
    b += en7a(); b += en7b(); b += en8(); b += en9()
    b += en10a(); b += en10b(); b += en10c(); b += en10d()
    b += en11(); b += en12(); b += en13(); b += en14(); b += enAnnex()
    return b
}

private func en1() -> [Block] { [
    .h1("1. Executive summary"),
    .p("**GDC Resolve Encoder** is an export plugin for **DaVinci Resolve Studio** that adds software **H.264 (x264)** and **H.265 (x265)** encoders to the codec list, with fine quality control, **10-bit** export, **4:2:2** chroma, **HDR10 metadata** (mastering display, MaxCLL, MaxFALL) and three **own formats** (GDC QuickTime, GDC MP4, GDC Matroska) that write the HDR information straight into the file, not only into the video stream."),
    .p("The plugin does not replace Resolve's native codecs (ProRes, DNxHR, XDCAM, DCP, EXR). It complements them where you need **controlled H.264/H.265**: deliveries for YouTube, social networks, TVs, streaming platforms, light masters and review copies. Color is not reinterpreted: the plugin receives the finished, graded image from Resolve and encodes it, tagging it correctly (Rec.709, Rec.2020, P3-D65, P3-DCI, PQ, HLG)."),
    .h2("At a glance"),
    .table(headers: ["Aspect", "What it offers"], rows: [
        ["Type", "Export plugin (IO Encode Plugin) for DaVinci Resolve Studio 21.x"],
        ["Encoders", "x264 and x265 (software); Apple VideoToolbox (Mac); NVIDIA NVENC (Windows with an NVIDIA GPU)"],
        ["Bit depth", "8-bit and 10-bit"],
        ["Chroma", "4:2:0 (8 and 10-bit) and 4:2:2 (10-bit)"],
        ["Color", "Rec.709, Rec.2020, P3-D65, P3-DCI; SDR, PQ (HDR10) and HLG transfer"],
        ["HDR", "Static HDR10: mastering display, MaxCLL, MaxFALL (in the stream and, in the GDC formats, in the container)"],
        ["Controls", "Preset, Profile, Level, Tune, CRF / bitrate / constant QP, keyframe interval, expert x264/x265 parameters"],
        ["Formats", "Resolve's QuickTime, MP4 and MKV + GDC QuickTime, GDC MP4, GDC Matroska"],
        ["Platforms", "macOS on Apple Silicon (arm64); Windows 64-bit"],
        ["Dependencies", "Nothing to install: FFmpeg and the required libraries ship inside the package"],
    ], widths: [0.24, 0.76]),
    .note(.info, "This document describes what the plugin does, how it works and how to configure it for concrete destinations. Chapter 14 states explicitly what has been verified in DaVinci Resolve and what has not been tested yet."),
] }

private func en2() -> [Block] { [
    .h1("2. What GDC Resolve Encoder is"),
    .h2("2.1 The problem it solves"),
    .p("A colorist or editor eventually faces the same question: which settings should I export with so the file looks good, has a reasonable size and is recognized correctly by the destination platform? H.264 and H.265 have dozens of parameters, and the difference between a good and a poor setting shows up as banding, lost detail, file size and, for HDR, whether the TV or platform recognizes the image as HDR at all."),
    .p("The plugin brings the widely used x264 and x265 encoders into Resolve, with their parameters exposed in the export panel, plus 10-bit and 4:2:2 export and correct HDR10 metadata."),
    .h2("2.2 What it adds"),
    .bullets([
        "**Fine quality control**: CRF (constant quality), target bitrate or constant QP, with preset, level and tune.",
        "**10-bit** for HDR and for SDR without banding, plus **4:2:2** for masters and deliveries with full vertical chroma.",
        "**Correct color tags** in the file, read from the project settings: Rec.709, Rec.2020, P3-D65, P3-DCI, PQ, HLG.",
        "**Static HDR10**: mastering display and MaxCLL/MaxFALL, written into the video stream and, through the GDC formats, into the container.",
        "**Own formats** (GDC QuickTime, GDC MP4, GDC Matroska) selectable directly in Deliver's Format list.",
        "**Expert parameters**: a field to pass x264/x265 options directly for special cases.",
    ]),
    .h2("2.3 Who it is for"),
    .bullets([
        "Colorists and editors delivering to **YouTube, Instagram, Facebook, TikTok, Vimeo** who want control over quality.",
        "Anyone producing **HDR10 or HLG content** who needs the metadata to reach the file.",
        "Anyone delivering **files for TV playback** (USB, streamer, Apple TV) who wants maximum compatibility.",
        "Studios that want light **H.264/H.265 4:2:2 10-bit masters** or consistent review copies.",
    ]),
    .h2("2.4 Requirements and compatibility"),
    .table(headers: ["Requirement", "Details"], rows: [
        ["DaVinci Resolve", "**Studio** version (the export plugin SDK works in Studio). Verified on Studio 21.1."],
        ["Mac", "macOS on **Apple Silicon** (M1/M2/M3/M4...). Intel Macs are not a target of this version."],
        ["Windows", "Windows 10/11, 64-bit. NVENC hardware encoding requires an NVIDIA GPU and a current driver."],
        ["Linux", "Not offered."],
        ["Mac installation", "Signed and Apple-notarized `.pkg`, installed by double-click into Resolve's IOPlugins folder."],
        ["Windows installation", "Archive with an install script; copies the plugin into Resolve's IOPlugins folder."],
        ["Dependencies", "FFmpeg and the required libraries are included in the package; nothing else to install."],
        ["License", "Activation code bound to the Machine ID (see chapter 3.6)."],
    ], widths: [0.24, 0.76]),
] }

private func en3() -> [Block] { [
    .h1("3. How it works"),
    .h2("3.1 The flow of an export"),
    .p("When you pick a GDC codec in Deliver and start rendering, Resolve processes the timeline (grading, effects, scaling) and hands each finished frame to the plugin. The plugin encodes it and sends the video packets to the container, which writes them to the file together with the audio."),
    .code("Resolve timeline  →  finished YUV frames\n      ↓\n  GDC plugin: conversion (16 → 10-bit when needed) + color tags\n      ↓\n  Encoder: x264 / x265 (software)  or  VideoToolbox / NVENC (hardware)\n      ↓\n  H.264 / H.265 packets\n      ↓\n  Container: QuickTime / MP4 / MKV (Resolve)  or  GDC QuickTime / GDC MP4 / GDC Matroska\n      ↓\n  Final file"),
    .h2("3.2 What the plugin receives from Resolve"),
    .p("Resolve sends the image as **YUV planes**. At 8-bit each sample takes one byte. At 10-bit, Resolve delivers each sample in a **16-bit** container, with the value shifted by 6 bits (that is, on the full 16-bit scale). The plugin converts to 10-bit with **rounding** and clamping to 1023, so it introduces no loss beyond what the codec itself introduces."),
    .note(.info, "You do not need to do anything about this: the conversion is automatic. It is only useful to know if you analyze files with external tools and wonder why the input values are 16-bit."),
    .h2("3.3 The encoders"),
    .table(headers: ["Encoder", "Type", "Strengths", "Weaknesses"], rows: [
        ["x264 (H.264)", "Software", "Excellent quality at low bitrate, very fine control, maximum compatibility", "Slower than hardware; 10-bit/4:2:2 H.264 is not played by many TVs"],
        ["x265 (H.265/HEVC)", "Software", "Smaller files at the same quality, 10-bit and HDR, 4K", "Slowest; some older platforms/devices do not play it"],
        ["Apple VideoToolbox", "Hardware (Mac)", "Very fast, suited to previews", "Lower quality at the same bitrate than x264/x265; 8-bit 4:2:0 only"],
        ["NVIDIA NVENC", "Hardware (Windows)", "Very fast on NVIDIA GPUs", "Same as above; only with an NVIDIA GPU"],
    ], widths: [0.19, 0.14, 0.34, 0.33]),
    .h2("3.4 Color tagging"),
    .p("Every file carries, besides the image, **tags** that tell the player which color space it was encoded in (primaries, transfer function, matrix). The plugin reads them from the Resolve project settings (Output Color Space) and writes them into the file. If Resolve sends no value or an unknown one, **Rec.709** is used: the plugin does not guess the color space from the bit depth."),
    .table(headers: ["Output Color Space in Resolve", "Primaries", "Transfer", "Matrix"], rows: [
        ["Rec.709 (Scene)", "Rec.709 (1)", "Rec.709 (1)", "Rec.709 (1)"],
        ["Rec.2100 ST2084 (PQ)", "Rec.2020 (9)", "SMPTE ST 2084 / PQ (16)", "Rec.2020 nc (9)"],
        ["Rec.2100 HLG", "Rec.2020 (9)", "ARIB STD-B67 / HLG (18)", "Rec.2020 nc (9)"],
        ["P3-D65", "SMPTE EG 432 / P3-D65 (12)", "SMPTE ST 428 (17)", "Rec.709 (1)"],
        ["P3-DCI", "SMPTE RP 431 / P3-DCI (11)", "SMPTE ST 428 (17)", "Rec.709 (1)"],
    ], widths: [0.32, 0.24, 0.26, 0.18]),
    .note(.info, "The table reflects what Resolve 21.1 sends and what the plugin writes (the values in brackets are the standard CICP codes). For HLG the transfer tag is written, but there is no static HDR10-style metadata."),
    .h2("3.5 The containers"),
    .p("There are two families of formats in Deliver's Format list:"),
    .bullets([
        "**Resolve's formats** (QuickTime, MP4, MKV): Resolve packages the file and handles all the audio (PCM, AAC, etc.). The GDC codecs appear here as a codec choice. Resolve's container **does not write** HDR10 metadata into the container; it stays in the video stream.",
        "**The GDC formats** (GDC QuickTime, GDC MP4, GDC Matroska): the plugin packages the file. It writes the color tags, **mastering display** and **MaxCLL/MaxFALL** straight into the container, and the audio is uncompressed **PCM**.",
    ]),
    .h2("3.6 Licensing"),
    .p("The plugin requires an **activation code** bound to the computer's **Machine ID** (shown in the plugin panel). The code is entered once; after activation the field disappears from the panel. Verification is local, with no internet connection. Activation is obtained by supporting the project through a donation. Without an active license, the export does not start."),
] }

private func en4() -> [Block] { [
    .h1("4. What it does and does not do"),
    .h2("4.1 What it does"),
    .table(headers: ["Capability", "Details"], rows: [
        ["H.264 and H.265 encoding", "x264 and x265 at 8 and 10-bit; 4:2:0 (8/10-bit) and 4:2:2 (10-bit)"],
        ["Quality control", "CRF, target bitrate, constant QP; preset, level, tune, keyframe interval"],
        ["Expert parameters", "Free-form string of x264/x265 options (for example aq-mode, psy-rd, vbv-maxrate)"],
        ["Color tags", "Rec.709, Rec.2020, P3-D65, P3-DCI; SDR, PQ, HLG; Video or Full range"],
        ["Static HDR10", "Mastering display (P3-D65 or Rec.2020, peak luminance), MaxCLL, MaxFALL"],
        ["Own formats", "GDC QuickTime, GDC MP4, GDC Matroska, with HDR in the container"],
        ["Audio", "In the GDC formats: 16/24/32-bit PCM, written unchanged (tested with a 1 kHz tone)"],
        ["Hardware", "VideoToolbox (Mac) and NVENC (Windows, NVIDIA GPU) for fast previews"],
        ["Compatibility", "The codecs stay available in Resolve's own QuickTime, MP4 and MKV as well"],
    ], widths: [0.26, 0.74]),
    .h2("4.2 What it does not do"),
    .table(headers: ["Does not do", "What to do instead"], rows: [
        ["ProRes, DNxHR/DNxHD, XDCAM, DCP, EXR, DPX", "Use Resolve's native codecs"],
        ["4:4:4; 4:2:2 at 8-bit", "4:2:2 exists only at 10-bit; for 4:4:4 use ProRes 4444 or another native codec"],
        ["Two-pass encoding", "Use CRF or target bitrate with VBV (see chapter 11)"],
        ["HDR10+ and Dolby Vision", "The plugin writes static HDR10 only; HLG is only tagged"],
        ["AAC / AC-3 in the GDC formats", "In the GDC formats audio is PCM; for AAC use Resolve's MP4 or QuickTime with a GDC codec"],
        ["Start timecode and markers in the GDC formats", "Not written yet; in Resolve's formats Resolve's own apply"],
        ["AV1 and VP9", "Not included"],
        ["Color space conversion", "Color management is done by Resolve; the plugin only tags"],
        ["Strict CBR from the panel", "Approximate it with vbv-maxrate/vbv-bufsize in advanced parameters"],
        ["Linux and Intel Mac", "Not targets of this version"],
    ], widths: [0.42, 0.58]),
] }

private func en5() -> [Block] { [
    .h1("5. Advantages and disadvantages"),
    .h2("5.1 Advantages"),
    .bullets([
        "**Better quality/size ratio than hardware encoders**: x264 and x265 produce smaller files at the same visual quality.",
        "**10-bit and 4:2:2**: less banding in gradients, cleaner chroma on graphics and colored text.",
        "**Complete HDR10**: tags + mastering display + MaxCLL/MaxFALL, including in the container (GDC formats).",
        "**Granular control** without leaving Resolve: preset, level, tune, VBV, expert parameters.",
        "**No extra installs**: FFmpeg and the libraries ship in the package.",
        "**Compatible** with your existing workflow: the codecs also work in Resolve's native formats.",
        "**Reproducible**: the same settings give the same result, useful for repeated deliveries.",
    ]),
    .h2("5.2 Disadvantages and limits"),
    .bullets([
        "**Speed**: x265 and slow presets (slower, veryslow) take a long time; hardware is fast but weaker on quality.",
        "**Audio**: PCM only in the GDC formats; PCM in MP4 has weak support in some players.",
        "**Playback compatibility**: 10-bit and 4:2:2 H.264 are not played by many TVs and phones; H.265 is not accepted everywhere.",
        "**No timecode or markers** in the GDC formats.",
        "**Requires Resolve Studio** and an activated license.",
        "**Does not cover** deliveries that require ProRes, DNxHR, XDCAM or DCP; those stay with the native codecs.",
    ]),
    .h2("5.3 When NOT to use the plugin"),
    .bullets([
        "When the destination requires a specific broadcast or cinema codec (ProRes, DNxHR, XDCAM, DCP, DPX/EXR).",
        "When you need the start timecode and markers in the exported file but want the GDC format: use a Resolve format instead.",
        "When the destination requires AAC and you also want HDR metadata in the container: right now you cannot have both in a single file.",
        "When you need Dolby Vision or HDR10+.",
    ]),
] }

private func en6() -> [Block] { [
    .h1("6. The codec variants"),
    .p("In Deliver, under Codec you pick **GDC Encoder**, then under **Type** one of the variants below (in the plugin's own GDC formats the same variants appear directly as the codec). Hardware variants appear only if the machine has the respective encoder."),
    .table(headers: ["Variant (Type)", "Bits", "Chroma", "Profile", "Recommended for"], rows: [
        ["GDC H.264 (Software x264)", "8", "4:2:0", "Baseline / Main / High (High default)", "Web, social, TVs, maximum compatibility"],
        ["GDC H.265 (Software x265)", "8", "4:2:0", "Main", "SDR 4K, small files"],
        ["GDC H.264 (Apple VideoToolbox)", "8", "4:2:0", "—", "Fast previews on Mac"],
        ["GDC H.265 (Apple VideoToolbox)", "8", "4:2:0", "—", "Fast previews on Mac"],
        ["GDC H.264 (NVIDIA NVENC)", "8", "4:2:0", "—", "Fast previews on Windows with NVIDIA"],
        ["GDC H.265 (NVIDIA NVENC)", "8", "4:2:0", "—", "Fast previews on Windows with NVIDIA"],
        ["GDC H.264 10-bit (Software x264 High10)", "10", "4:2:0", "High 10", "Banding-free 10-bit SDR; limited TV/phone playback"],
        ["GDC H.265 10-bit (Software x265 Main10)", "10", "4:2:0", "Main 10", "HDR10, HLG, 4K, modern deliveries"],
        ["GDC H.264 4:2:2 10-bit (Software x264 High 4:2:2)", "10", "4:2:2", "High 4:2:2", "Light masters, post-production deliveries"],
        ["GDC H.265 4:2:2 10-bit (Software x265 Main 4:2:2 10)", "10", "4:2:2", "Main 4:2:2 10 (Rext)", "HDR 4:2:2 masters, graphics with colored text"],
    ], widths: [0.34, 0.06, 0.08, 0.22, 0.30]),
    .note(.warn, "The 10-bit and 4:2:2 variants are intended for post-production and modern platforms. Many TVs, phones and hardware players do not decode 10-bit or 4:2:2 H.264. For TV playback use 8-bit 4:2:0 (SDR) or H.265 Main10 4:2:0 (HDR)."),
] }

private func en7a() -> [Block] { [
    .h1("7. Complete settings reference"),
    .p("The plugin's settings (\"Plugin Settings\") appear under the codec selection. Those marked \"software only\" do not appear for the hardware variants."),
    .h2("7.1 Preset (software only)"),
    .p("The preset chooses **how much effort** the encoder spends compressing efficiently. A slower preset produces, at the same CRF, a smaller file or better quality, but takes longer. It does not change \"what kind\" of image you get, only how well it is compressed."),
    .table(headers: ["Preset", "Speed", "Efficiency", "When"], rows: [
        ["ultrafast", "Maximum", "Very poor (large files)", "Tests, emergency previews"],
        ["superfast", "Very high", "Poor", "Quick review"],
        ["veryfast", "High", "Medium-poor", "Dailies, working copies"],
        ["faster", "Good", "Medium", "Working copies with acceptable quality"],
        ["fast", "Good", "Medium-good", "Quick deliveries"],
        ["**medium** (default)", "Balanced", "Good", "General use"],
        ["slow", "Slower", "Very good", "**Recommended for final delivery**"],
        ["slower", "Slow", "Excellent", "Final delivery, when you have time"],
        ["veryslow", "Very slow", "Maximum", "Small gain over \"slower\"; rarely justified"],
    ], widths: [0.20, 0.16, 0.26, 0.38]),
    .note(.tip, "Rule of thumb: pick **slow** for final delivery and **veryfast** for review. The difference between slower and veryslow is usually small compared to the extra time."),
    .h2("7.2 Profile (software only, 8-bit H.264)"),
    .table(headers: ["Profile", "What it means", "When"], rows: [
        ["baseline", "Restricted toolset, no B-frames; lower quality at equal bitrate", "Only very old devices"],
        ["main", "Wide compatibility, fewer tools than High", "Older players that do not accept High"],
        ["**high** (default)", "The full 8-bit toolset; best efficiency", "Almost any modern destination"],
    ], widths: [0.20, 0.50, 0.30]),
    .p("For H.265, at 10-bit and at 4:2:2 the profile is chosen automatically by the encoder (Main, Main 10, Main 4:2:2 10, High 10, High 4:2:2)."),
    .h2("7.3 Level (software only)"),
    .p("The level limits resolution, frame rate and maximum bitrate so the file can be played by certain devices. **Auto** (default) lets the encoder choose according to resolution; it suits most cases. Set it manually only when a specific device requires a maximum level."),
    .table(headers: ["Level", "H.264: suited for", "H.265: suited for"], rows: [
        ["3.0 / 3.1", "SD and 720p", "720p"],
        ["4.0 / 4.1", "1080p up to 30 fps", "1080p up to 30 fps (4.0), 1080p60 (4.1)"],
        ["4.2", "1080p60", "1080p60 and above"],
        ["5.0", "Large resolutions, low frame rates", "**4K up to 30 fps**"],
        ["5.1", "**4K up to 30 fps**", "**4K up to 60 fps**"],
        ["5.2", "**4K up to 60 fps**", "4K up to 120 fps"],
    ], widths: [0.14, 0.43, 0.43]),
    .note(.info, "A level too low for the chosen resolution makes the encoder refuse the combination or limit the bitrate. A level that is too high does no harm, but may make the file undecodable on devices that stop at a lower level."),
    .h2("7.4 Tune (software only)"),
    .p("Tune optimizes the encoder for a certain kind of content. \"none\" (default) is good in most cases."),
    .table(headers: ["Tune", "What it does", "When", "Available"], rows: [
        ["none", "No special optimization", "General use", "H.264, H.265"],
        ["film", "Preserves fine detail on filmed content, high bitrate", "Films, finely textured content", "H.264 only"],
        ["animation", "Optimized for flat areas, clean edges", "Animation, graphics, drawings", "H.264, H.265"],
        ["grain", "Preserves grain structure, keeps it uniform", "Film-grain material", "H.264, H.265"],
        ["stillimage", "Optimized for nearly static images", "Presentations, slideshows", "H.264 only"],
        ["psnr / ssim", "Optimizes objective metrics, not appearance", "Technical comparisons, not delivery", "H.264, H.265"],
        ["fastdecode", "Simplifies the stream so it decodes easily", "Weak devices; lowers compression efficiency", "H.264, H.265"],
        ["zerolatency", "No encoding delay (no B-frames/lookahead)", "Live streaming; not for delivery files", "H.264, H.265"],
    ], widths: [0.14, 0.34, 0.34, 0.18]),
    .note(.warn, "fastdecode and zerolatency reduce compression efficiency: the same quality needs a larger file. Do not use them for ordinary deliveries."),
] }

private func en7b() -> [Block] { [
    .h2("7.5 Rate Control: how you choose quality"),
    .p("You have three modes. The choice determines whether you control **quality** or **size**."),
    .table(headers: ["Mode", "What you control", "Advantage", "Disadvantage", "When"], rows: [
        ["**Constant Quality (CRF)** (default)", "Quality: number 0–51, lower = better", "Constant quality across the film; most efficient", "Final size not known beforehand", "Almost always"],
        ["**Target Bitrate**", "Size: kbps (500–100000)", "Predictable size", "Variable quality: heavy scenes may come out weak", "When the platform requires a bitrate; hardware"],
        ["**Constant QP**", "Each frame's quantization", "Predictable behavior, no adaptation", "Inefficient; large files", "Tests, analysis, special cases"],
    ], widths: [0.19, 0.20, 0.22, 0.21, 0.18]),
    .note(.tip, "The rule: if you have no bitrate requirement, use **CRF**. If the platform imposes a ceiling, use CRF **plus** a VBV cap (see chapter 11)."),
    .note(.info, "The hardware variants (VideoToolbox, NVENC) have no native CRF: if you pick CRF, the plugin uses a default bitrate of about 12 Mbps. For hardware pick **Target Bitrate**."),
    .h2("7.6 Quality (CRF): recommended values"),
    .p("The values below are **starting points** for ordinary filmed content; very detailed or grainy content needs a lower CRF. x265 uses a slightly different scale: for the same visual quality, x265's CRF is usually **3–5 units higher** than x264's (rule of thumb)."),
    .table(headers: ["Purpose", "x264 (H.264)", "x265 (H.265)", "Notes"], rows: [
        ["Master / light archive", "14–16", "16–18", "Large files; 10-bit recommended"],
        ["High-quality delivery", "17–19", "19–22", "Demanding client, festivals"],
        ["Standard delivery (YouTube, Vimeo)", "18–21", "21–24", "Platform recompresses; keep headroom"],
        ["Social (Instagram, TikTok, Facebook)", "20–23", "23–26", "Platform recompresses heavily"],
        ["Review / proxy", "24–28", "27–30", "Small size, sufficient quality"],
        ["Very small file", "26–30", "28–32", "Visible loss on detail"],
    ], widths: [0.30, 0.16, 0.16, 0.38]),
    .h2("7.7 Bit Rate (Target Bitrate)"),
    .p("A slider from **500 to 100000 kbps**, in steps of 100. The values below are indicative for SDR H.264; for H.265 you can use about **60–70%** of these values at comparable quality (rule of thumb)."),
    .table(headers: ["Resolution / frame rate", "H.264 SDR", "H.265 / HDR (indicative)"], rows: [
        ["720p 24–30", "5–7.5 Mbps", "4–6 Mbps"],
        ["1080p 24–30", "8–12 Mbps", "6–9 Mbps"],
        ["1080p 48–60", "12–18 Mbps", "9–13 Mbps"],
        ["1440p 24–30", "16 Mbps", "12 Mbps"],
        ["4K 24–30", "35–45 Mbps", "25–35 Mbps (HDR: 44–56 Mbps recommended by some platforms)"],
        ["4K 48–60", "53–68 Mbps", "40–50 Mbps (HDR: 66–85 Mbps recommended by some platforms)"],
    ], widths: [0.34, 0.24, 0.42]),
    .h2("7.8 Keyframe Interval (sec)"),
    .p("The distance between two keyframes (complete images), between **1 and 10 seconds**, default **2 seconds**. The plugin converts it into frames using the project's real frame rate. A short interval means fast scrubbing and good error recovery, but a slightly larger file; a long one means a slightly smaller file but slower scrubbing."),
    .table(headers: ["Purpose", "Value"], rows: [
        ["Streaming / web (default)", "2 seconds"],
        ["Social, platforms that recompress", "1–2 seconds"],
        ["Post-production deliveries, later editing", "1 second"],
        ["Small file for a viewing archive", "4–5 seconds"],
    ], widths: [0.62, 0.38]),
    .p("The number of B-frames is fixed at **2**; it cannot be changed from the panel."),
    .h2("7.9 Advanced Params (x264/x265)"),
    .p("A text field where you write raw encoder options in the form `key=value:key=value` (for example `aq-mode=3:psy-rd=1.0,0.15`). They are passed directly to x264 or x265, depending on the chosen variant. Details and examples in chapter 11."),
    .note(.warn, "An invalid string makes the encoder refuse to start the export. If the export does not start after you fill in the field, clear it and try again. Options you write here take priority over those in the panel (including HDR10)."),
    .h2("7.10 HDR10 Metadata (software only)"),
    .p("The group of settings that writes static HDR10 metadata. It is **off** by default. It applies only when the export is **PQ** (Output Color Space: Rec.2100 ST2084)."),
    .table(headers: ["Setting", "Values", "What it means"], rows: [
        ["HDR10 Metadata", "Off / On (PQ exports only)", "Off: nothing is written. On: the data below is written, only if the export is PQ."],
        ["Mastering Primaries", "P3-D65 / Rec.2020", "The gamut of the **monitor you graded on** (not the image's color space). P3-D65 is the usual case."],
        ["Mastering Peak", "100–10000 nits (default 1000)", "The maximum luminance of the mastering monitor."],
        ["MaxCLL", "0–10000 nits (0 = not signalled)", "The brightest pixel in the whole film."],
        ["MaxFALL", "0–4000 nits (0 = not signalled)", "The highest frame-average luminance of any frame in the whole film."],
    ], widths: [0.20, 0.30, 0.50]),
    .p("The mastering display's minimum luminance is fixed at 0.005 nits. More about HDR in chapter 8."),
    .h2("7.11 Resolve settings that affect the export"),
    .table(headers: ["Resolve setting", "Recommendation", "Why"], rows: [
        ["Output Color Space (Color Management)", "Rec.709 for SDR; Rec.2100 ST2084 for HDR10; Rec.2100 HLG for HLG", "The color tags written into the file come from here"],
        ["Data Levels (Advanced Settings)", "**Video** for almost any delivery", "Full range makes some players show the image washed out or too contrasty"],
        ["Color Space Tag / Gamma Tag", "Same as project", "Lets the tagging follow the project"],
        ["Retain sub-black and super-white data", "Unchecked for delivery", "Only for intermediate streams"],
        ["Resolution", "**Even** width and height", "Odd dimensions are refused by the plugin"],
        ["Frame rate", "The timeline's", "Changing the rate at export causes stutter"],
        ["Export Audio", "Checked, or unchecked if you work separately", "The GDC formats write PCM"],
    ], widths: [0.31, 0.37, 0.32]),
    .h2("7.12 Fixed behaviors"),
    .bullets([
        "B-frames: 2. The encoder automatically uses the number of threads suited to the processor (up to 32).",
        "Encoding does not hold the whole file in memory: frames are encoded one at a time, so memory use stays stable even on long exports.",
        "NVENC hardware variants retry up to 3 times to start, because the GPU session may be temporarily busy.",
    ]),
] }

private func en8() -> [Block] { [
    .h1("8. Color and HDR in detail"),
    .h2("8.1 SDR: Rec.709, gamma 2.4"),
    .p("The standard delivery for web and SDR television: Rec.709 primaries, Rec.709/BT.1886 transfer (gamma 2.4 on a calibrated monitor), **Video** level range (16–235 at 8-bit). In Resolve, Output Color Space: Rec.709. The plugin writes tags 1/1/1 and adds no HDR metadata."),
    .h2("8.2 HDR10 (PQ)"),
    .p("HDR10 uses the **PQ (SMPTE ST 2084)** transfer function and **Rec.2020** primaries, at **10-bit**, with static metadata (mastering display, MaxCLL, MaxFALL). It is the HDR format accepted by most TVs and platforms."),
    .bullets([
        "Output Color Space: **Rec.2100 ST2084**.",
        "Codec: an H.265 **10-bit** variant (Main10) or 4:2:2 10-bit.",
        "HDR10 Metadata: **On**, with the real mastering monitor.",
        "Format: **GDC MP4**, **GDC QuickTime** or **GDC Matroska**, so the metadata also reaches the container.",
    ]),
    .h2("8.3 HLG"),
    .p("HLG (Hybrid Log-Gamma) is used mostly in television because it looks reasonable on SDR screens too. It is exported with Output Color Space **Rec.2100 HLG**; the plugin writes the HLG transfer tag. HLG **does not use** static HDR10 metadata, so set **HDR10 Metadata: Off**."),
    .h2("8.4 P3-D65 and P3-DCI"),
    .p("If you work in P3-D65 (for example for Apple deliveries or P3 screens) or in P3-DCI (digital cinema), the matching Output Color Space makes the plugin write P3 primaries into the stream and the container. Check that the destination platform interprets P3 correctly; many web platforms expect Rec.709 or Rec.2020."),
    .h2("8.5 Mastering display vs the image's color space"),
    .p("These are two different things, often confused:"),
    .table(headers: ["", "The image's color space", "Mastering display"], rows: [
        ["What it describes", "How the pixels are coded (e.g. Rec.2020 + PQ)", "The monitor you graded on"],
        ["Where it comes from", "From Output Color Space in Resolve", "From the plugin panel (Mastering Primaries, Mastering Peak)"],
        ["Who uses it", "The player, when decoding and displaying", "The TV, for tone mapping"],
        ["Does it change the pixels?", "Yes (it defines their interpretation)", "No; it only informs the TV"],
    ], widths: [0.20, 0.40, 0.40]),
    .p("A common example: the image is in a Rec.2020/PQ container, while the mastering display is **P3-D65** with a **1000-nit** peak, because you graded on a P3 monitor that reaches 1000 nits. Choose **Rec.2020** under Mastering Primaries only if your monitor covers almost the whole Rec.2020 gamut (rare)."),
    .h2("8.6 MaxCLL and MaxFALL"),
    .bullets([
        "**MaxCLL** (Maximum Content Light Level): the luminance of the brightest pixel in the whole film, in nits.",
        "**MaxFALL** (Maximum Frame-Average Light Level): the highest average luminance of any frame in the whole film, in nits.",
    ]),
    .p("The correct values must be **measured** on the final content. If you have not measured them, leave **0** (not signalled), which is more correct than an invented value: a MaxCLL that is too low or too high can make the TV's tone mapping behave badly."),
    .note(.warn, "The values in this document's examples (1000 and 400) are illustrative only. Do not copy them into real deliveries without measuring."),
    .h2("8.7 Example: grading on a laptop screen with an HDR profile"),
    .p("If you grade on the internal screen of an Apple laptop with the HDR profile active, the screen works in P3 with PQ. Prudent settings: **Mastering Primaries: P3-D65**, **Mastering Peak: 1000**, MaxCLL/MaxFALL measured or 0. A laptop screen is not an HDR reference monitor: for deliveries with strict requirements, also check on an HDR TV. An external SDR monitor calibrated to Rec.709 cannot evaluate HDR; the SDR version is checked separately."),
    .h2("8.8 What HDR metadata is not supported"),
    .bullets([
        "**HDR10+** (dynamic metadata) and **Dolby Vision**: not written by the plugin.",
        "**HLG** is tagged, but has no additional static metadata.",
    ]),
] }

private func en9() -> [Block] { [
    .h1("9. Containers and audio"),
    .h2("9.1 Resolve's formats vs the GDC formats"),
    .table(headers: ["", "Resolve's formats (QuickTime / MP4 / MKV)", "The GDC formats (GDC QuickTime / MP4 / Matroska)"], rows: [
        ["Who packages", "Resolve", "The plugin (through FFmpeg)"],
        ["Audio", "Any codec Resolve offers (PCM, AAC, etc.)", "16/24/32-bit PCM, written unchanged"],
        ["HDR10 metadata in the container", "No", "Yes: mastering display and MaxCLL/MaxFALL"],
        ["Color tags in the container", "Yes, written by Resolve", "Yes, written by the plugin"],
        ["Start timecode / markers", "Yes", "No (yet)"],
        ["How it appears in Deliver", "Format = QuickTime/MP4/MKV, then Codec = GDC Encoder, then Type", "Format = GDC ..., then Type (directly)"],
    ], widths: [0.24, 0.38, 0.38]),
    .p("The GDC formats appear in the **Format** list after Resolve's native formats, alongside other plugin formats; their position in the list cannot be changed."),
    .h2("9.2 Audio"),
    .p("In the GDC formats, Resolve sends uncompressed audio (PCM) and the plugin writes it unchanged. That is the professional choice for masters and post-production deliveries. For destinations that require AAC, use Resolve's MP4 or QuickTime format with a GDC video codec."),
    .table(headers: ["Container", "PCM audio", "Note"], rows: [
        ["GDC QuickTime (.mov)", "Good", "Standard in post-production"],
        ["GDC Matroska (.mkv)", "Very good", "Wide support for PCM"],
        ["GDC MP4 (.mp4)", "Limited", "PCM in MP4 (ipcm) is played poorly by some players (e.g. QuickTime/Safari)"],
    ], widths: [0.28, 0.20, 0.52]),
    .note(.info, "If you do not need audio in the file, uncheck \"Export Audio\" in Deliver; the container will then receive no audio track."),
    .h2("9.3 Which combination to choose"),
    .table(headers: ["Purpose", "Format", "Why"], rows: [
        ["HDR10 with metadata in the file + PCM audio", "GDC QuickTime or GDC Matroska", "Metadata in the container; PCM well supported"],
        ["HDR10 for players that require MP4", "GDC MP4", "Metadata in the container; check audio playback"],
        ["SDR with AAC for web/social", "Resolve's MP4 + GDC codec", "AAC is compatible everywhere"],
        ["Delivery that requires timecode/markers", "A Resolve format + GDC codec", "Resolve writes them"],
    ], widths: [0.38, 0.30, 0.32]),
] }
