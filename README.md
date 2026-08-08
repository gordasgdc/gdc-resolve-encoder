# GDC Resolve Encoder

A free, open-source IOPlugin encoder for DaVinci Resolve Studio, built on
FFmpeg's `libavcodec`. One generic encoder class drives every codec variant
this plugin registers — CPU encoders (`libx264`, `libx265`) and hardware
encoders (Apple **VideoToolbox** on Mac, **NVENC** on Windows/Linux with an
NVIDIA GPU) — rather than one bespoke implementation per codec.

Built against Blackmagic Design's official **DaVinci Resolve IO Encode
Plugin SDK**, using its `x264_encoder_plugin` example as the reference for
the required plugin interface.

> Requires **DaVinci Resolve Studio** — the free edition does not support
> IOPlugins.

## What it registers

| Codec | Backend | Platforms |
|---|---|---|
| GDC H.264 (Software x264) | `libx264` | Mac, Windows, Linux |
| GDC H.265 (Software x265) | `libx265` | Mac, Windows, Linux |
| GDC H.264 (Apple VideoToolbox) | hardware | Mac only |
| GDC H.265 (Apple VideoToolbox) | hardware | Mac only |
| GDC H.264 (NVIDIA NVENC) | hardware | Windows/Linux with an NVIDIA GPU |
| GDC H.265 (NVIDIA NVENC) | hardware | Windows/Linux with an NVIDIA GPU |

Hardware variants only appear in Resolve's codec list if FFmpeg can
actually find that encoder on the machine the plugin is running on — the
same binary adapts automatically, no separate hardware/software builds.

## Installation

Download the zip for your platform from
[Releases](../../releases/latest), unzip it, and copy the
`gdc_resolve_encoder.dvcp.bundle` folder to:

| Platform | Path |
|---|---|
| Mac (standalone) | `/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins/` |
| Mac (App Store) | `~/Library/Containers/com.blackmagic-design.DaVinciResolveAppStore/Data/Library/Application Support/IOPlugins/` |
| Windows | `%ProgramData%\Blackmagic Design\DaVinci Resolve\Support\IOPlugins\` |
| Linux | `/opt/resolve/IOPlugins/` |

**On Mac**, since this build isn't notarized by Apple, run this once before
moving the bundle into place, or macOS will refuse to load it and say it's
damaged:

```bash
xattr -rd com.apple.quarantine gdc_resolve_encoder.dvcp.bundle
```

Restart Resolve, open the Deliver page, and the GDC codecs should appear
under **MP4**/**QuickTime** format in the codec list.

## Building from source

Each platform is built and packaged separately (three independent
downloads), even though the source is shared — see
`.github/workflows/build.yml` for the exact CI steps this project uses on
every release; the summary below matches it.

### Linux

```bash
sudo apt-get install cmake pkg-config libavcodec-dev libavutil-dev libswscale-dev
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

Output: `build/gdc_resolve_encoder.dvcp`

### macOS (Apple Silicon only — Intel is not a build target)

```bash
brew install cmake pkg-config ffmpeg
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build -j
```

### Windows

Download a **shared** FFmpeg dev build (e.g.
[gyan.dev's `ffmpeg-release-full-shared`](https://www.gyan.dev/ffmpeg/builds/)),
extract it, then:

```powershell
cmake -B build -DCMAKE_BUILD_TYPE=Release -DFFMPEG_ROOT="C:\path\to\ffmpeg"
cmake --build build --config Release
```

Copy `avcodec-*.dll`, `avutil-*.dll`, `swscale-*.dll`, and `swresample-*.dll`
from `ffmpeg\bin` alongside the built `.dvcp` file — Windows needs these
DLLs next to the plugin binary, unlike Mac/Linux where the shared libraries
are found via the system library path.

### Packaging

Whichever platform you built on, place the resulting `.dvcp` file at:

```
gdc_resolve_encoder.dvcp.bundle/Contents/<ARCH>/gdc_resolve_encoder.dvcp
```

where `<ARCH>` is `MacOS` (Mac), `Win64` (Windows), or `Linux-x86-64`
(Linux) — see [`docs/SDK-README.txt`](docs/SDK-README.txt) for the full
packaging spec from Blackmagic's SDK.

## Project structure

```
include/            Blackmagic's official IOPlugin headers (unmodified)
wrapper/             Blackmagic's official C++ wrapper around the raw
                      message-passing plugin API (unmodified)
src/
  encoder_variants.h  Table of registered codecs (name, UUID, FFmpeg
                       encoder string, hardware flag) — add a new codec
                       here without touching the encoder logic itself
  ffmpeg_encoder.h/.cpp
                      The generic encoder: opens whichever libavcodec
                      encoder its variant names, converts Resolve's YUV
                      4:2:0 planar frames to whatever pixel format that
                      encoder wants, and repackages Annex-B NAL output
                      into the length-prefixed format Resolve's mp4/mov
                      writer expects
  plugin.cpp          Entry point Resolve loads; dispatches to the above
CMakeLists.txt
.github/workflows/build.yml
                      Builds and releases all three platforms separately
```

## Known limitations

- **CPU-only per the SDK, hardware via FFmpeg**: Blackmagic's plugin SDK
  itself only documents CPU-side plugins; VideoToolbox/NVENC hardware
  acceleration works here because FFmpeg exposes them as ordinary
  `libavcodec` encoders — the plugin itself doesn't talk to the GPU
  directly.
- **Magic cookie format**: the SPS/PPS cookie handed to Resolve is a raw
  concatenation of the NAL units from the encoder's extradata (cookie type
  `0`, plugin-defined) rather than a formal avcC/hvcC box. This has worked
  in testing but hasn't been validated against every NLE/muxer edge case —
  if you hit a muxing issue, this is the first place to look.
- **CRF on hardware encoders**: VideoToolbox/NVENC don't expose CRF the
  same way `libx264`/`libx265` do. Picking "Constant Quality" on a
  hardware variant falls back to a fixed bitrate target rather than a true
  per-frame quality mode.

## License

MIT — see [LICENSE](LICENSE). Built against Blackmagic Design's IO Encode
Plugin SDK (`include/`, `wrapper/`), redistributed here as required to use
the SDK; those files remain Blackmagic's.

Not affiliated with or endorsed by Blackmagic Design. "DaVinci Resolve" is
a trademark of Blackmagic Design Pty. Ltd.
