# Corresponding source / Codul sursă corespunzător

The macOS package of GDC Resolve Encoder includes GPL-licensed binaries (FFmpeg, x264, x265). In accordance with
GPL-3.0 §6, the Corresponding Source is available as follows. Every item is also offered on request for at least
three years after the release (open an issue at https://github.com/gordasgdc/gdc-resolve-encoder/issues).

## 1. The plugin itself
https://github.com/gordasgdc/gdc-resolve-encoder — the git tag of the release you installed (for example `v1.8.0`)
contains the exact source, build scripts (`CMakeLists.txt`, `build_installer.sh`, `bundle_ffmpeg_mac.sh`) and the
tests. Build recipe: `brew install cmake pkg-config ffmpeg dylibbundler`, then `./build_installer.sh <version>`.

## 2. Bundled libraries (as built by Homebrew)
The libraries were copied unchanged from Homebrew (`/opt/homebrew`) at the versions below. Homebrew's formulae
record the exact upstream archive and build options: https://github.com/Homebrew/homebrew-core/tree/master/Formula
(file names `ffmpeg.rb`, `x264.rb`, `x265.rb`, ...). The FFmpeg build configuration of the package was:

    --enable-shared --enable-pthreads --enable-version3 --enable-gpl --enable-libsvtav1 --enable-libopus
    --enable-libx264 --enable-libmp3lame --enable-libdav1d --enable-libvpx --enable-libx265 --enable-openssl
    --enable-videotoolbox --enable-audiotoolbox --enable-neon

| Library | Version | Upstream source archive |
|---|---|---|
| FFmpeg | 9.0.2 | https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz |
| x264 | r3222 | https://code.videolan.org/videolan/x264.git at revision b35605ace3ddf7c1a5d67a2eb553f034aef41d55 |
| x265 | 4.3 | https://github.com/Multicorewareinc/x265/releases/download/4.3/x265_4.3.tar.gz |
| libvpx | 1.17.0 | https://github.com/webmproject/libvpx/archive/refs/tags/v1.17.0.tar.gz |
| dav1d | 1.5.4 | https://code.videolan.org/videolan/dav1d/-/archive/1.5.4/dav1d-1.5.4.tar.bz2 |
| SVT-AV1 | 4.2.0 | https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v4.2.0/SVT-AV1-v4.2.0.tar.bz2 |
| Opus | 1.6.1 | https://ftp.osuosl.org/pub/xiph/releases/opus/opus-1.6.1.tar.gz |
| LAME | 4.0 | https://downloads.sourceforge.net/project/lame/lame/4.0/lame-4.0.tar.gz |
| mpg123 | 1.33.7 | https://www.mpg123.de/download/mpg123-1.33.7.tar.bz2 |
| xz / liblzma | 5.8.4 | https://github.com/tukaani-project/xz/releases/download/v5.8.4/xz-5.8.4.tar.gz |
| OpenSSL | 3.6.4 | https://github.com/openssl/openssl/releases/download/openssl-3.6.4/openssl-3.6.4.tar.gz |

Each GitHub release of the plugin also attaches a `gdc-resolve-encoder-<version>-corresponding-source.tar.gz`
with these archives (see the release notes) so the source does not depend on third-party hosting.
