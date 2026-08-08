# GDC Resolve Encoder

A free, open-source IOPlugin encoder for DaVinci Resolve Studio — H.264 and H.265 via FFmpeg, with automatic hardware acceleration (Apple VideoToolbox on Mac, NVIDIA NVENC on Windows/Linux).

**Website**: https://gordasgdc.github.io/gdc-resolve-encoder/
**Română**: [README.md](README.md) · **Español**: [README.es.md](README.es.md)

> Requires **DaVinci Resolve Studio** — the free edition does not support IOPlugins.

## What the plugin registers

| Codec | Backend | Type | Platforms |
|---|---|---|---|
| GDC H.264 | `libx264` | Software | Mac · Windows · Linux |
| GDC H.265 | `libx265` | Software | Mac · Windows · Linux |
| GDC H.264 | Apple VideoToolbox | Hardware | Mac (Apple Silicon) |
| GDC H.265 | Apple VideoToolbox | Hardware | Mac (Apple Silicon) |
| GDC H.264 | NVIDIA NVENC | Hardware | Windows · Linux (with an NVIDIA GPU) |
| GDC H.265 | NVIDIA NVENC | Hardware | Windows · Linux (with an NVIDIA GPU) |

Hardware variants only appear in Resolve's codec list if your machine can actually run them — FFmpeg is checked at plugin startup, never assumed.

## Installation

Download the archive for your platform from [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest).

> **About FFmpeg**: the plugin doesn't bundle FFmpeg (large size, GPL/LGPL licensing complications). On **Mac and Linux**, you need FFmpeg installed separately on your system. On **Windows**, the required libraries already ship in the archive — nothing extra to install.

### macOS (Apple Silicon)

**Prerequisite**: [Homebrew](https://brew.sh) — if you don't already have it, run:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Install FFmpeg, if you don't already have it:
```bash
brew install ffmpeg
```

Then:
```bash
xattr -rd com.apple.quarantine gdc_resolve_encoder.dvcp.bundle
mv gdc_resolve_encoder.dvcp.bundle "/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins/"
```

Or use [`install.sh`](install.sh), which does all of this automatically — checks for Homebrew and FFmpeg, installs FFmpeg via Homebrew if it's missing, removes the quarantine flag, and copies the plugin to the right place. If Homebrew itself isn't installed, the script shows you the install link above and stops, rather than trying something that can't succeed.

### Windows

No separate FFmpeg install needed — the required DLLs already ship in the archive.

Move the whole `gdc_resolve_encoder.dvcp.bundle` folder (not just the file inside it) to:
```
%ProgramData%\Blackmagic Design\DaVinci Resolve\Support\IOPlugins\
```

### Linux

Install FFmpeg from your distribution's package manager, e.g.:
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

## Usage

1. The **Deliver** page, same as any normal export
2. Choose **MP4** or **QuickTime** format
3. The **GDC** codecs appear in the codec list, alongside the native ones
4. Quality settings (CRF or target bitrate) show up directly in the export panel

## Requirements

- **DaVinci Resolve Studio** (the free edition doesn't support IOPlugins)
- **macOS Apple Silicon**, Windows 64-bit, or Linux — Intel Macs aren't supported
- **FFmpeg installed on your system** — on Mac/Linux (Windows ships the DLLs in the archive)
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

Every archive on [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest) already contains the fully-structured bundle for that platform — nothing to assemble by hand.

## Building from source

See [`.github/workflows/build.yml`](.github/workflows/build.yml) for the exact steps used on every release; summary:

```bash
# Linux
sudo apt-get install cmake pkg-config libavcodec-dev libavutil-dev libswscale-dev
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j

# macOS (arm64 only)
brew install cmake pkg-config ffmpeg
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build -j

# Windows (needs a shared FFmpeg dev build, e.g. gyan.dev)
cmake -B build -DCMAKE_BUILD_TYPE=Release -DFFMPEG_ROOT="C:\path\to\ffmpeg"
cmake --build build --config Release
```

## Known limitations

- CRF on hardware encoders (VideoToolbox/NVENC) falls back to a fixed bitrate rather than a true constant-quality mode — hardware doesn't expose CRF the way x264/x265 do
- The magic cookie (SPS/PPS) used for muxing is a plain NAL concatenation, not a formal avcC/hvcC box — this has worked in testing but hasn't been validated against every muxing edge case

## License

MIT — see [LICENSE](LICENSE). Built on Blackmagic Design's DaVinci Resolve IO Encode Plugin SDK, redistributed as required by the SDK (`include/`, `wrapper/`). Not affiliated with Blackmagic Design.

## Author

**Cristi Gordas (GDC)** — [GitHub](https://github.com/gordasgdc) · [Facebook](https://web.facebook.com/cristiGDC) · [YouTube](https://www.youtube.com/@cristigordas)
