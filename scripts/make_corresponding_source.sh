#!/usr/bin/env bash
# Builds gdc-resolve-encoder-<version>-corresponding-source.tar.gz: the plugin
# source at a given git ref plus the exact upstream archives of every library
# bundled in the macOS package (see legal/SOURCES.md), with checksums and the
# Homebrew formula metadata of the build.
#
# Usage: scripts/make_corresponding_source.sh <version> <git-ref> <output-dir>
# Needs network access to the upstream hosts listed below and Homebrew.
set -euo pipefail
cd "$(dirname "$0")/.."
VER="${1:?version, e.g. 1.8.0}"; REF="${2:?git ref}"; OUT="${3:?output dir}"
NAME="gdc-resolve-encoder-$VER-corresponding-source"
W="$OUT/$NAME"
rm -rf "$W"; mkdir -p "$W/plugin" "$W/upstream" "$W/formulae"

echo "==> Plugin source @ $(git rev-parse --short "$REF")"
git archive --format=tar "$REF" | tar -x -C "$W/plugin"
git rev-parse "$REF" > "$W/plugin/GIT_COMMIT"

# name | version | url | homebrew formula (checksum source, '-' = none)
LIBS='ffmpeg|9.0.2|https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz|ffmpeg
x264|r3222-b35605a|https://code.videolan.org/videolan/x264/-/archive/b35605ace3ddf7c1a5d67a2eb553f034aef41d55/x264-b35605ace3ddf7c1a5d67a2eb553f034aef41d55.tar.bz2|-
x265|4.3|https://github.com/Multicorewareinc/x265/releases/download/4.3/x265_4.3.tar.gz|x265
libvpx|1.17.0|https://github.com/webmproject/libvpx/archive/refs/tags/v1.17.0.tar.gz|libvpx
dav1d|1.5.4|https://code.videolan.org/videolan/dav1d/-/archive/1.5.4/dav1d-1.5.4.tar.bz2|dav1d
svt-av1|4.2.0|https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v4.2.0/SVT-AV1-v4.2.0.tar.bz2|svt-av1
opus|1.6.1|https://ftp.osuosl.org/pub/xiph/releases/opus/opus-1.6.1.tar.gz|opus
lame|4.0|https://downloads.sourceforge.net/project/lame/lame/4.0/lame-4.0.tar.gz|lame
mpg123|1.33.7|https://www.mpg123.de/download/mpg123-1.33.7.tar.bz2|mpg123
xz|5.8.4|https://github.com/tukaani-project/xz/releases/download/v5.8.4/xz-5.8.4.tar.gz|xz
openssl|3.6.4|https://github.com/openssl/openssl/releases/download/openssl-3.6.4/openssl-3.6.4.tar.gz|openssl@3'

: > "$W/CHECKSUM_VERIFICATION.txt"
while IFS='|' read -r name ver url formula; do
    f="$W/upstream/$(basename "$url")"
    echo "==> $name $ver"
    curl -fsSL --retry 3 -o "$f" "$url"
    sum=$(shasum -a 256 "$f" | cut -d' ' -f1)
    if [ "$formula" != "-" ]; then
        brew info --json=v2 "$formula" > "$W/formulae/$formula.json"
        for r in "$(brew --cellar)/$formula"/*/INSTALL_RECEIPT.json; do [ -f "$r" ] && cp "$r" "$W/formulae/$formula.install-receipt.json"; done
        want=$(brew info --json=v2 "$formula" | python3 -c 'import json,sys; d=json.load(sys.stdin)["formulae"][0]; print(d["urls"]["stable"].get("checksum",""), d["versions"]["stable"])')
        wsum="${want%% *}"; wver="${want##* }"
        inst=$(ls "$(brew --cellar)/$formula" | tr '\n' ' ')
        if [ "$wsum" = "$sum" ]; then st="matches Homebrew formula $formula ($wver); installed: $inst"; else st="current Homebrew formula is $wver (differs from the build); the build used the installed version(s): $inst - archive is the upstream release of $ver"; fi
    else
        st="no Homebrew checksum (git revision archive)"
        for r in "$(brew --cellar)/x264"/*/INSTALL_RECEIPT.json; do [ -f "$r" ] && cp "$r" "$W/formulae/x264.install-receipt.json"; done
    fi
    printf '%s  %s  %s %s  [%s]\n' "$sum" "$(basename "$url")" "$name" "$ver" "$st" | tee -a "$W/CHECKSUM_VERIFICATION.txt"
done <<< "$LIBS"

cat > "$W/README-SOURCE.txt" <<EOF
GDC Resolve Encoder $VER - corresponding source (macOS package)
Author: Dumitru Cristinel Gordas (GDC)

plugin/     the exact source of the plugin at git commit $(git rev-parse "$REF")
            (MIT; build scripts: CMakeLists.txt, build_installer.sh, bundle_ffmpeg_mac.sh)
upstream/   the unmodified upstream source archives of the libraries bundled in the package
formulae/   Homebrew formula metadata (source URL, checksum, dependencies) and install receipts of the build machine
CHECKSUM_VERIFICATION.txt   SHA-256 of every archive and how it was verified

The libraries in the package are the unmodified Homebrew builds of these archives (see plugin/legal/SOURCES.md).
FFmpeg configuration of the package:
  --enable-shared --enable-pthreads --enable-version3 --enable-gpl --enable-libsvtav1 --enable-libopus
  --enable-libx264 --enable-libmp3lame --enable-libdav1d --enable-libvpx --enable-libx265 --enable-openssl
  --enable-videotoolbox --enable-audiotoolbox --enable-neon
Licenses: GPLv3 (FFmpeg, x264, x265 in this build), LGPL/BSD/MIT/Apache-style for the others; texts in plugin/legal/texts/.

Rebuild the package:
  1. brew install cmake pkg-config ffmpeg dylibbundler   (or build the upstream archives above with the formula metadata in formulae/)
  2. cd plugin && ./build_installer.sh $VER              (macOS 26+ SDK; sets the minimum macOS to 26.0)
The package's own build only needs plugin/ plus the libraries; the upstream archives are provided so the
source does not depend on third-party hosting.
EOF

( cd "$OUT" && tar -czf "$NAME.tar.gz" "$NAME" )
shasum -a 256 "$OUT/$NAME.tar.gz" | tee "$OUT/$NAME.tar.gz.sha256"
ls -l "$OUT/$NAME.tar.gz" | awk '{print $5, "bytes"}'
