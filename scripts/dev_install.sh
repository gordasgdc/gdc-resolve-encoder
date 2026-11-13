#!/usr/bin/env bash
# Developer helper: bundle + sign a freshly built plugin and copy it over the
# installed one. Resolve must be closed. The installed bundle must be
# writable by the current user (a .pkg install makes it root-owned again).
# Usage: scripts/dev_install.sh <cmake-build-dir> <staging-dir>
set -euo pipefail
cd "$(dirname "$0")/.."
BUILD="${1:?cmake build dir}"; STAGE="${2:?staging dir}"
DEST="/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins/gdc_resolve_encoder.dvcp.bundle"
pgrep -x Resolve >/dev/null && { echo "DaVinci Resolve is running — close it first." >&2; exit 1; }
[ -w "$DEST" ] || { echo "Installed bundle is not writable by $(id -un)." >&2; exit 1; }
B="$STAGE/gdc_resolve_encoder.dvcp.bundle"
rm -rf "$B"; mkdir -p "$B/Contents/MacOS"
cp "$BUILD/gdc_resolve_encoder.dvcp" "$B/Contents/MacOS/"
./bundle_ffmpeg_mac.sh "$B" gdc_resolve_encoder.dvcp >/dev/null
mkdir -p "$B/Contents/Resources/Licenses"; cp legal/texts/* legal/SOURCES.md THIRD_PARTY_LICENSES.md "$B/Contents/Resources/Licenses/"
codesign --force ${APPLE_SIGN_IDENTITY_APP:+--timestamp --options runtime --entitlements codesigning/entitlements.plist} \
    --sign "${APPLE_SIGN_IDENTITY_APP:--}" "$B/Contents/MacOS/gdc_resolve_encoder.dvcp" 2>/dev/null
python3 tests/check_load.py "$B/Contents/MacOS/gdc_resolve_encoder.dvcp"
rsync -a --delete "$B/" "$DEST/"
echo "installed: $(shasum -a 256 "$DEST/Contents/MacOS/gdc_resolve_encoder.dvcp" | cut -c1-16)"
