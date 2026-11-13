# Corresponding source / Codul sursă corespunzător (Windows 1.7.1)

The Windows package of GDC Resolve Encoder includes the FFmpeg DLLs of the unmodified build
**ffmpeg-9.0.2-full_build-shared** by www.gyan.dev (GPL v3; it contains libx264, libx265 and other libraries).
In accordance with GPL-3.0 §6:

1. **The plugin**: https://github.com/gordasgdc/gdc-resolve-encoder — the tag `v1.7.1` (branch `maintenance/windows-1.7.1`)
   contains the exact source, `CMakeLists.txt` and `.github/workflows/build.yml` (which downloads the pinned build below).
2. **FFmpeg and its libraries**: the package contains the unmodified DLLs from
   https://github.com/GyanD/codexffmpeg/releases/download/9.0.2/ffmpeg-9.0.2-full_build-shared.7z
   (SHA-256 `4d2060a8b34a940aa47d785142055bb92a63053781e55f2ace4546edd519a8f5`). The build's own `README.txt`
   (copied into the package folder `licenses/`) lists the exact configuration, versions of every library and the
   source commit (FFmpeg commit `946fcce07b`: https://github.com/FFmpeg/FFmpeg/commit/946fcce07b). Gyan publishes
   the corresponding sources at https://www.gyan.dev/ffmpeg/builds/ .
3. **On request**: every item above is also offered on request for at least three years after the release
   (open an issue at https://github.com/gordasgdc/gdc-resolve-encoder/issues).

The plugin's own code is MIT-licensed (`legal/texts/gdc-resolve-encoder-LICENSE-MIT.txt`); the binary package as a
whole is distributed under GPL v3 (`legal/texts/ffmpeg-COPYING.GPLv3.txt`). The package is not endorsed by
Blackmagic Design; it is built on the DaVinci Resolve IO Encode Plugin SDK.
