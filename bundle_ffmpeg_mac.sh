#!/usr/bin/env bash
# Bundleaza FFmpeg + TOATE dependintele lor tranzitive (x264, x265, aom,
# dav1d, zlib etc.) DIRECT in bundle-ul .dvcp, ca plugin-ul sa nu se mai
# lege la FFmpeg-ul Homebrew de PE MASINA UTILIZATORULUI la runtime.
#
# Fix pentru bug-ul structural real documentat in CLAUDE.md (2026-09-04):
# plugin-ul construit pe o masina (CI sau alt Mac) cerea SONAME-uri exacte
# (ex. libavcodec.62.dylib) care nu mai corespundeau FFmpeg-ului instalat
# via Homebrew pe masina lui Cristi (.63) — incarcare esuata SILENTIOS in
# Resolve, fara nicio eroare vizibila. De acum, bundle-ul e self-contained:
# FFmpeg-ul folosit e CEL DE PE MASINA DE BUILD, copiat in bundle o data,
# indiferent ce versiune are Homebrew-ul userului final.
#
# Apelat identic din build_installer.sh (local, .pkg semnat+notarizat) SI
# din .github/workflows/build.yml (CI, zip) — o singura sursa de adevar,
# nu doua implementari care pot diverge (Regula 30, zero cod impur).
#
# Usage: ./bundle_ffmpeg_mac.sh <bundle_dir> <binary_name>
#   bundle_dir  - radacina bundle-ului (contine deja Contents/MacOS/<binary_name>)
#   binary_name - numele binarului plugin, ex. gdc_resolve_encoder.dvcp
#
# Semnare: daca APPLE_SIGN_IDENTITY_APP e setat in mediu, dylib-urile
# bundle-uite sunt semnate cu identitatea reala Developer ID (obligatoriu
# pentru ca pachetul final sa treaca notarizarea Apple). Altfel, semnare
# ad-hoc (fluxul CI/zip, nesemnat/nenotarizat, cu eliminare manuala de
# quarantine de catre user prin install.sh — neschimbat).
#
# IMPORTANT: dylibbundler rescrie load commands atat in binar cat si in
# dylib-urile copiate, ceea ce invalideaza orice semnatura anterioara —
# ruleaza acest script INAINTE de orice semnare finala a binarului
# principal, niciodata dupa.

set -euo pipefail

BUNDLE_DIR="${1:?Usage: $0 <bundle_dir> <binary_name>}"
BINARY_NAME="${2:?Usage: $0 <bundle_dir> <binary_name>}"

BINARY_PATH="$BUNDLE_DIR/Contents/MacOS/$BINARY_NAME"
FRAMEWORKS_DIR="$BUNDLE_DIR/Contents/Frameworks"

if [[ ! -f "$BINARY_PATH" ]]; then
    echo "EROARE: nu gasesc binarul la $BINARY_PATH" >&2
    exit 1
fi

if ! command -v dylibbundler &>/dev/null; then
    echo "EROARE: dylibbundler nu e instalat. Ruleaza: brew install dylibbundler" >&2
    exit 1
fi

echo "==> Bundle FFmpeg + dependinte tranzitive in $FRAMEWORKS_DIR ..."
rm -rf "$FRAMEWORKS_DIR"
dylibbundler -ns -cd -b \
    -x "$BINARY_PATH" \
    -d "$FRAMEWORKS_DIR" \
    -p "@loader_path/../Frameworks/"

echo "==> Semnez dylib-urile bundle-uite..."
for dylib in "$FRAMEWORKS_DIR"/*.dylib; do
    [[ -e "$dylib" ]] || continue
    if [[ -n "${APPLE_SIGN_IDENTITY_APP:-}" ]]; then
        codesign --force --timestamp --options runtime --sign "$APPLE_SIGN_IDENTITY_APP" "$dylib"
    else
        codesign --force --sign - "$dylib"
    fi
done

echo "==> Verific: nicio referinta Homebrew ramasa (cale absoluta)..."
FAIL=0
if otool -L "$BINARY_PATH" | tail -n +2 | grep -q "/opt/homebrew\|/usr/local/opt"; then
    echo "EROARE: binarul inca refera FFmpeg din Homebrew dupa bundling!" >&2
    otool -L "$BINARY_PATH" >&2
    FAIL=1
fi
for dylib in "$FRAMEWORKS_DIR"/*.dylib; do
    [[ -e "$dylib" ]] || continue
    if otool -L "$dylib" | tail -n +2 | grep -q "/opt/homebrew\|/usr/local/opt"; then
        echo "EROARE: $dylib inca refera o cale Homebrew absoluta!" >&2
        otool -L "$dylib" >&2
        FAIL=1
    fi
done
if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi

COUNT=$(find "$FRAMEWORKS_DIR" -maxdepth 1 -name "*.dylib" | wc -l | xargs)
echo "==> OK: bundle self-contained (Contents/Frameworks contine $COUNT biblioteci)."
