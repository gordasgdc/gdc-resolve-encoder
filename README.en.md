# GDC Resolve Encoder

Native, open-source encoder for DaVinci Resolve Studio — H.264 and H.265 via FFmpeg, with automatic hardware acceleration (Apple VideoToolbox on Mac, NVIDIA NVENC on Windows), plus 8-bit and 10-bit variants.

**Presentation page**: https://gordasgdc.github.io/gdc-resolve-encoder/
**Română**: [README.md](README.md) · **Español**: [README.es.md](README.es.md)

> Requires **DaVinci Resolve Studio** — the free edition doesn't support IOPlugins.

## Full guide, in 3 languages

Every archive in [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest) includes a complete PDF guide (installation, every setting explained with examples, practical recipes, troubleshooting, licensing), in Romanian, English, and Spanish. Also available directly in [`docs/guides/`](docs/guides/).

## What the plugin registers

| Codec | Backend | Type | Depth | Platforms |
|---|---|---|---|---|
| GDC H.264 | `libx264` | Software | 8-bit | Mac · Windows |
| GDC H.265 | `libx265` | Software | 8-bit | Mac · Windows |
| GDC H.264 | Apple VideoToolbox | Hardware | 8-bit | Mac (Apple Silicon) |
| GDC H.265 | Apple VideoToolbox | Hardware | 8-bit | Mac (Apple Silicon) |
| GDC H.264 | NVIDIA NVENC | Hardware | 8-bit | Windows (NVIDIA GPU) |
| GDC H.265 | NVIDIA NVENC | Hardware | 8-bit | Windows (NVIDIA GPU) |
| GDC H.264 10-bit | `libx264` (High10) | Software | 10-bit | Mac · Windows |
| GDC H.265 10-bit | `libx265` (Main10) | Software | 10-bit | Mac · Windows |

Hardware variants only show up in Resolve's codec list if your machine can actually run them — FFmpeg is checked at plugin startup, not assumed. 10-bit is currently software-only.

## Settings available in the plugin panel

- **Preset** — speed vs compression efficiency (ultrafast → veryslow)
- **Rate Control** — Constant Quality (CRF), Target Bitrate, or Constant QP
- **Profile** — baseline/main/high (H.264 8-bit software only)
- **Level** — 3.0-5.2 or Auto (H.264/H.265 software)
- **Keyframe Interval** — distance between keyframes, in seconds
- **Advanced Params** — direct x264/x265 expert parameters, e.g. `aq-mode=3:psy-rd=1.0,0.15`
- **Tune** — film, animation, grain, stillimage, psnr, ssim, fastdecode, zerolatency (the list differs slightly between H.264 and H.265, verified directly against each encoder)

Every setting, with concrete examples of when and how to use it, is explained in detail in the PDF guide.

## Installation

Download the archive for your platform from [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest).

> **About FFmpeg**: the required FFmpeg libraries already ship in the archive, on both **Mac** and **Windows** — nothing extra to install.

### macOS (Apple Silicon)

Simplest way: in the unzipped folder, run:
```bash
./install.sh
```
The script removes the macOS quarantine flag and copies the plugin to the correct location (FFmpeg is already bundled inside). Asks for your password once.

Manual install, if you prefer:
```bash
xattr -rd com.apple.quarantine gdc_resolve_encoder.dvcp.bundle
mv gdc_resolve_encoder.dvcp.bundle "/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins/"
```

### Windows

No separate FFmpeg needed — the required DLLs already ship in the archive.

Easiest way: in the unzipped folder, run `install.bat` (double-click) — it places the bundle in the right folder for you, requesting Administrator rights automatically if needed.

Manual, if you prefer: move the whole `gdc_resolve_encoder.dvcp.bundle` folder (the folder itself, not just the file inside) to:
```
%ProgramData%\Blackmagic Design\DaVinci Resolve\Support\IOPlugins\
```


## How to use it

1. **Deliver** page, like any normal export
2. Choose **MP4** or **QuickTime** format
3. **GDC** codecs appear in the codec list, alongside the native ones
4. Settings appear directly in the export panel (Plugin Settings)

## Requirements

- **DaVinci Resolve Studio** (the free edition doesn't support IOPlugins)
- **macOS Apple Silicon** or Windows 64-bit — Intel Macs aren't supported
- For NVENC: an **NVIDIA** GPU with an up-to-date driver

## Correct bundle structure

```
gdc_resolve_encoder.dvcp.bundle/
└── Contents/
    ├── MacOS/              (Mac only)
    │   └── gdc_resolve_encoder.dvcp
    └── Win64/               (Windows only)
        └── gdc_resolve_encoder.dvcp
```

Every archive on [Releases](https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest) contains the full bundle, already correctly structured, for that platform — no manual assembly needed.

## Building from source

See [`.github/workflows/build.yml`](.github/workflows/build.yml) for the exact steps used for each release; summary:

```bash
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
- 2-Pass Encoding available only for software variants (x264/x265), Target Bitrate mode only — not on hardware (VideoToolbox/NVENC)
- CRF on hardware encoders (VideoToolbox/NVENC) automatically falls back to a fixed bitrate, not true constant quality — hardware doesn't expose CRF the same way x264/x265 do

## License

MIT for the plugin's own code — see [LICENSE](LICENSE). Built on the DaVinci Resolve IO Encode Plugin SDK (Blackmagic Design), redistributed per the SDK's requirements (`include/`, `wrapper/`). Not affiliated with Blackmagic Design.

The plugin links against **GPL**-licensed libraries (FFmpeg, libx264, libx265) — the compiled binary is, as a distribution, subject to GPL terms. Full details, with implications, in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

## Author

**Cristi Gordas (GDC)** — [GitHub](https://github.com/gordasgdc) · [Facebook](https://web.facebook.com/cristiGDC) · [YouTube](https://www.youtube.com/@cristigordas)
