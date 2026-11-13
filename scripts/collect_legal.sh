#!/usr/bin/env bash
# Copies the licence texts of every library bundled into the macOS plugin
# (FFmpeg + transitive dylibs from Homebrew) into legal/texts/. The texts come
# from the Homebrew prefix that the build actually links against, so they match
# the binaries. Run before building the installer; output is committed.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=legal/texts; mkdir -p "$OUT"; rm -f "$OUT"/*
cp_() { # <formula> <file-in-prefix> <dest-name>
    local p; p="$(brew --prefix "$1")"
    [ -f "$p/$2" ] || { echo "missing $p/$2" >&2; exit 1; }
    cp "$p/$2" "$OUT/$3"
}
cp_ ffmpeg    COPYING.GPLv3   ffmpeg-COPYING.GPLv3.txt
cp_ ffmpeg    COPYING.LGPLv3  ffmpeg-COPYING.LGPLv3.txt
cp_ ffmpeg    LICENSE.md      ffmpeg-LICENSE.md
cp_ x264      COPYING         x264-COPYING.txt
cp_ x265      COPYING         x265-COPYING.txt
cp_ libvpx    LICENSE         libvpx-LICENSE.txt
cp_ dav1d     COPYING         dav1d-COPYING.txt
cp_ svt-av1   LICENSE.md      svt-av1-LICENSE.md
cp_ svt-av1   LICENSE-BSD2.md svt-av1-LICENSE-BSD2.md
cp_ opus      COPYING         opus-COPYING.txt
cp_ lame      COPYING         lame-COPYING.txt
cp_ mpg123    COPYING         mpg123-COPYING.txt
cp_ xz        COPYING         xz-COPYING.txt
cp_ xz        COPYING.0BSD    xz-COPYING.0BSD.txt
cp_ openssl@3 LICENSE.txt     openssl-LICENSE.txt
cp LICENSE "$OUT/gdc-resolve-encoder-LICENSE-MIT.txt"
ls "$OUT" | wc -l | sed 's/^/licence texts: /'
