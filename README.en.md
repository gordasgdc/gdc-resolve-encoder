# GDC Resolve Encoder

Free, open-source encoder for DaVinci Resolve Studio — H.264 and H.265 via FFmpeg, with automatic hardware acceleration (Apple VideoToolbox on Mac, NVIDIA NVENC on Windows/Linux), plus 8-bit and 10-bit variants.

**Presentation page**: https://gordasgdc.github.io/gdc-resolve-encoder/
**Română**: [README.md](README.md) · **Español**: [README.es.md](README.es.md)

> Requires **DaVinci Resolve Studio** — the free edition doesn't support IOPlugins.

## Full guide, in 3 languages

Every archive in [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest) includes a complete PDF guide (installation, every setting explained with examples, practical recipes, troubleshooting, licensing), in Romanian, English, and Spanish. Also available directly in [`docs/guides/`](docs/guides/).

## What the plugin registers

| Codec | Backend | Type | Depth | Platforms |
|---|---|---|---|---|
| GDC H.264 | `libx264` | Software | 8-bit | Mac · Windows · Linux |
| GDC H.265 | `libx265` | Software | 8-bit | Mac · Windows · Linux |
| GDC H.264 | Apple VideoToolbox | Hardware | 8-bit | Mac (Apple Silicon) |
| GDC H.265 | Apple VideoToolbox | Hardware | 8-bit | Mac (Apple Silicon) |
| GDC H.264 | NVIDIA NVENC | Hardware | 8-bit | Windows · Linux (NVIDIA GPU) |
| GDC H.265 | NVIDIA NVENC | Hardware | 8-bit | Windows · Linux (NVIDIA GPU) |
| GDC H.264 10-bit | `libx264` (High10) | Software | 10-bit | Mac · Windows · Linux |
| GDC H.265 10-bit | `libx265` (Main10) | Software | 10-bit | Mac · Windows · Linux |

Hardware variants only show up in Resolve's codec list if your machine can actually run them — FFmpeg is checked at plugin startup, not assumed. 10-bit is currently software-only.

## Settings available in the plugin panel

- **Preset** — speed vs compression efficiency (ultrafast → veryslow)
- **Rate Control** — Constant Quality (CRF), Target Bitrate, or Constant QP
- **Profile** — baseline/main/high/high422 (H.264 8-bit software only)
- **Tune** — film, animation, grain, stillimage, psnr, ssim, fastdecode, zerolatency (the list differs slightly between H.264 and H.265, verified directly against each encoder)

Every setting, with concrete examples of when and how to use it, is explained in detail in the PDF guide.

## Installation

Download the archive for your platform from [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest).

> **About FFmpeg**: the plugin doesn't bundle FFmpeg (large size, GPL/LGPL licensing complications). On **Mac and Linux**, you need FFmpeg installed separately on the system. On **Windows**, the required libraries already ship in the archive — nothing extra to install.

### macOS (Apple Silicon)

**Prerequisite**: [Homebrew](https://brew.sh) — if you don't have it yet, run:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Simplest way: in the unzipped folder, run:
```bash
./install.sh
```
The script checks Homebrew and FFmpeg (installs FFmpeg if missing), removes the macOS quarantine flag, and copies the plugin to the correct location. Asks for your password once.

Manual install, if you prefer:
```bash
xattr -rd com.apple.quarantine gdc_resolve_encoder.dvcp.bundle
mv gdc_resolve_encoder.dvcp.bundle "/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins/"
```

### Windows

No separate FFmpeg needed — the required DLLs already ship in the archive.

Move the whole `gdc_resolve_encoder.dvcp.bundle` folder (the folder itself, not just the file inside) to:
```
%ProgramData%\Blackmagic Design\DaVinci Resolve\Support\IOPlugins\
```

### Linux

Install FFmpeg via your distribution's package manager, e.g.:
```bash
sudo apt install ffmpeg        # Debian/Ubuntu
sudo dnf install ffmpeg        # Fedora
sudo pacman -S ffmpeg          # Arch
```

Then move the bundle to:
```
/opt/resolve/IOPlugins/
```

Restart Resolve after installing.

## How to use it

1. **Deliver** page, like any normal export
2. Choose **MP4** or **QuickTime** format
3. **GDC** codecs appear in the codec list, alongside the native ones
4. Settings appear directly in the export panel (Plugin Settings)

## Requirements

- **DaVinci Resolve Studio** (the free edition doesn't support IOPlugins)
- **macOS Apple Silicon**, Windows 64-bit, or Linux — Intel Macs aren't supported
- **FFmpeg installed on the system** — Mac/Linux (Windows has the DLLs included in the archive)
- For NVENC: an **NVIDIA** GPU with an up-to-date driver

## Correct bundle structure

```
gdc_resolve_encoder.dvcp.bundle/
└── Contents/
    ├── MacOS/              (Mac only)
    │   └── gdc_resolve_encoder.dvcp
    ├── Win64/               (Windows only)
    │   └── gdc_resolve_encoder.dvcp
    └── Linux-x86-64/        (Linux only)
        └── gdc_resolve_encoder.dvcp
```

Every archive on [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest) contains the full bundle, already correctly structured, for that platform — no manual assembly needed.

## Building from source

See [`.github/workflows/build.yml`](.github/workflows/build.yml) for the exact steps used for each release; summary:

```bash
# Linux
sudo apt-get install cmake pkg-config libavcodec-dev libavutil-dev libswscale-dev
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j

# macOS (arm64 only)
brew install cmake pkg-config ffmpeg
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build -j

# Windows (needs an FFmpeg shared dev build, e.g. gyan.dev)
cmake -B build -DCMAKE_BUILD_TYPE=Release -DFFMPEG_ROOT="C:\path\to\ffmpeg"
cmake --build build --config Release
```

## Known limitations

- No HDR support (PQ/HLG metadata) yet — planned for a future version
- 10-bit is software-only (x264/x265) for now, not hardware
- No multi-pass rendering — single-pass only currently
- CRF on hardware encoders (VideoToolbox/NVENC) automatically falls back to a fixed bitrate, not true constant quality — hardware doesn't expose CRF the same way x264/x265 do

## License

MIT for the plugin's own code — see [LICENSE](LICENSE). Built on the DaVinci Resolve IO Encode Plugin SDK (Blackmagic Design), redistributed per the SDK's requirements (`include/`, `wrapper/`). Not affiliated with Blackmagic Design.

The plugin links against **GPL**-licensed libraries (FFmpeg, libx264, libx265) — the compiled binary is, as a distribution, subject to GPL terms. Full details, with implications, in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

## Author

**Cristi Gordas (GDC)** — [GitHub](https://github.com/gordasgdc) · [Facebook](https://web.facebook.com/cristiGDC) · [YouTube](https://www.youtube.com/@cristigordas)
