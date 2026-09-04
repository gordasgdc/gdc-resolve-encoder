#!/usr/bin/env bash
# Construieste plugin-ul, il semneaza, si il impacheteaza intr-un .pkg
# instalabil prin dublu-clic (fara Terminal) — payload-ul merge DIRECT in
# folderul IOPlugins al DaVinci Resolve, cu pas de acceptare a licentei.
#
# NOTE: produce un .pkg SEMNAT + NOTARIZAT automat daca certificatele
# Developer ID Application/Installer sunt configurate (vezi
# codesigning/README.md). Altfel cade pe un pachet NESEMNAT.
#
# IMPORTANT: plugin-ul se leaga DINAMIC la FFmpeg-ul din Homebrew de pe
# MASINA PE CARE SE COMPILEAZA — .pkg-ul produs va cere exact acele
# SONAME-uri (libavcodec.NN.dylib etc.) la runtime. Daca FFmpeg-ul de pe
# Homebrew se schimba de versiune intre build si instalare pe alta masina,
# plugin-ul nu se va incarca (esec silentios in Resolve, fara eroare
# vizibila) — problema reala, structurala, gasita 2026-09-04, inca
# nerezolvata definitiv (ar necesita bundling static sau al dylib-urilor
# FFmpeg in pachet, ca pe Windows — vezi CLAUDE.md).

set -euo pipefail
cd "$(dirname "$0")"

VERSION="${1:?Usage: ./build_installer.sh <versiune, ex 1.4.1>}"
PLUGIN_NAME="gdc_resolve_encoder"
BUNDLE_NAME="${PLUGIN_NAME}.dvcp.bundle"
PKG_ID="com.gordasgdc.resolveencoder.installer"
DIST_DIR="dist"
PAYLOAD_ROOT="$DIST_DIR/payload"
COMPONENT_PKG="$DIST_DIR/${PLUGIN_NAME}-component.pkg"
FINAL_PKG="$DIST_DIR/GDCResolveEncoder-$VERSION.pkg"
INSTALL_DEST="Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins"

echo "==> Compilez plugin-ul (local, pe FFmpeg-ul instalat pe ACEASTA masina)..."
rm -rf build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j

echo "==> Pregatesc bundle-ul..."
rm -rf "$DIST_DIR"
BUNDLE_DIR="$DIST_DIR/${BUNDLE_NAME}"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
cp "build/${PLUGIN_NAME}.dvcp" "$BUNDLE_DIR/Contents/MacOS/"

if [ -n "${APPLE_SIGN_IDENTITY_APP:-}" ]; then
    echo "==> Semnez binarul plugin-ului..."
    codesign --force --timestamp --options runtime \
        --entitlements "codesigning/entitlements.plist" \
        --sign "$APPLE_SIGN_IDENTITY_APP" "$BUNDLE_DIR/Contents/MacOS/${PLUGIN_NAME}.dvcp"
    codesign --verify --strict --verbose=2 "$BUNDLE_DIR/Contents/MacOS/${PLUGIN_NAME}.dvcp"
else
    echo "AVERTISMENT: APPLE_SIGN_IDENTITY_APP nesetat — semnez ad-hoc (pachetul final va ramane nesemnat)."
    codesign --force --sign - "$BUNDLE_DIR/Contents/MacOS/${PLUGIN_NAME}.dvcp"
fi

echo "==> Construiesc payload-ul (destinatie: /$INSTALL_DEST/)..."
mkdir -p "$PAYLOAD_ROOT/$INSTALL_DEST"
cp -R "$BUNDLE_DIR" "$PAYLOAD_ROOT/$INSTALL_DEST/"

echo "==> Construiesc component package..."
pkgbuild \
    --root "$PAYLOAD_ROOT" \
    --identifier "$PKG_ID" \
    --version "$VERSION" \
    --install-location "/" \
    --scripts "installer/scripts" \
    "$COMPONENT_PKG"

echo "==> Scriu Distribution.xml (pas de licenta obligatoriu — Agree/Disagree)..."
cat > "$DIST_DIR/Distribution.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>GDC Resolve Encoder $VERSION</title>
    <license file="License.txt" mime-type="text/plain"/>
    <options customize="never" require-scripts="false" rootVolumeOnly="true"/>
    <domains enable_localSystem="true"/>
    <choices-outline>
        <line choice="default">
            <line choice="$PKG_ID"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$PKG_ID" visible="false">
        <pkg-ref id="$PKG_ID"/>
    </choice>
    <pkg-ref id="$PKG_ID" version="$VERSION" onConclusion="none">${PLUGIN_NAME}-component.pkg</pkg-ref>
</installer-gui-script>
EOF

cp installer/License.txt "$DIST_DIR/License.txt"

echo "==> Construiesc pachetul final..."
productbuild \
    --distribution "$DIST_DIR/Distribution.xml" \
    --package-path "$DIST_DIR" \
    --resources "$DIST_DIR" \
    "$FINAL_PKG"

rm -rf "$PAYLOAD_ROOT" "$COMPONENT_PKG"

echo "==> Semnez + notarizez pachetul final..."
./codesigning/sign-and-notarize.sh pkg "$FINAL_PKG"

cp "$FINAL_PKG" "$DIST_DIR/GDCResolveEncoder.pkg"

echo ""
echo "==> Gata: $FINAL_PKG"
echo "==> Nume stabil: $DIST_DIR/GDCResolveEncoder.pkg"
