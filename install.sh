#!/usr/bin/env bash
# GDC Resolve Encoder — macOS installer
# Removes the Gatekeeper quarantine flag and copies the plugin bundle into
# DaVinci Resolve's IOPlugins folder. Run this from the folder where you
# unzipped the release archive (where gdc_resolve_encoder.dvcp.bundle sits).

set -euo pipefail

PLUGIN_NAME="gdc_resolve_encoder"
BUNDLE_NAME="${PLUGIN_NAME}.dvcp.bundle"
STANDALONE_DEST="/Library/Application Support/Blackmagic Design/DaVinci Resolve/IOPlugins"
APPSTORE_DEST="$HOME/Library/Containers/com.blackmagic-design.DaVinciResolveAppStore/Data/Library/Application Support/IOPlugins"

log()  { printf '\033[1;33m==>\033[0m %s\n' "$1"; }
err()  { printf '\033[1;31mEROARE:\033[0m %s\n' "$1" >&2; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$1"; }

if [[ "$(uname)" != "Darwin" ]]; then
    err "Acest script e doar pentru macOS. Pe Windows/Linux, vezi README pentru pasii de instalare."
    exit 1
fi

# --- locate the bundle -------------------------------------------------
# NOTA: pana la v1.4.1, aici se verifica daca FFmpeg e instalat pe sistem
# (prin Homebrew) — plugin-ul se lega dinamic la el. De la fix-ul SONAME
# mismatch (2026-09-05), FFmpeg + toate dependintele lui vin deja incluse
# in bundle (Contents/Frameworks/), deci userul nu mai are nevoie de nimic
# instalat separat pe Mac.
BUNDLE_PATH=""
if [[ -n "${1:-}" ]]; then
    BUNDLE_PATH="$1"
elif [[ -d "./${BUNDLE_NAME}" ]]; then
    BUNDLE_PATH="./${BUNDLE_NAME}"
else
    FOUND=$(find . -maxdepth 2 -type d -name "*.dvcp.bundle" 2>/dev/null | head -n1 || true)
    if [[ -n "$FOUND" ]]; then
        BUNDLE_PATH="$FOUND"
    fi
fi

if [[ -z "$BUNDLE_PATH" || ! -d "$BUNDLE_PATH" ]]; then
    err "Nu gasesc niciun folder *.dvcp.bundle in directorul curent."
    err "Ruleaza scriptul din folderul unde ai dezarhivat release-ul, sau da calea explicit:"
    err "  ./install.sh /cale/catre/${BUNDLE_NAME}"
    exit 1
fi
ok "Bundle gasit: ${BUNDLE_PATH}"

# --- verify structure ----------------------------------------------------
BINARY_PATH="${BUNDLE_PATH}/Contents/MacOS/${PLUGIN_NAME}.dvcp"
if [[ ! -f "$BINARY_PATH" ]]; then
    err "Structura bundle-ului nu e cea asteptata."
    err "Astept: ${BUNDLE_NAME}/Contents/MacOS/${PLUGIN_NAME}.dvcp"
    err "Daca ai doar fisierul .dvcp (nu bundle-ul complet), descarca din nou arhiva de pe:"
    err "  https://github.com/gordasgdc/gdc-resolve-encoder/releases/latest"
    exit 1
fi
ok "Structura bundle validata (${BINARY_PATH})"

# --- remove quarantine -----------------------------------------------------
log "Elimin flag-ul de carantina (binarul nu e notarizat de Apple)..."
xattr -rd com.apple.quarantine "$BUNDLE_PATH" 2>/dev/null || true
ok "Carantina eliminata"

# --- pick destination ----------------------------------------------------
DEST="$STANDALONE_DEST"
if [[ -d "$HOME/Library/Containers/com.blackmagic-design.DaVinciResolveAppStore" ]]; then
    echo ""
    echo "Am detectat DaVinci Resolve instalat din Mac App Store SI/SAU standalone."
    echo "Unde vrei sa instalezi plugin-ul?"
    select choice in "Standalone (${STANDALONE_DEST})" "Mac App Store (${APPSTORE_DEST})"; do
        case $choice in
            "Standalone"*) DEST="$STANDALONE_DEST"; break ;;
            "Mac App Store"*) DEST="$APPSTORE_DEST"; break ;;
        esac
    done
fi

# --- copy ------------------------------------------------------------------
log "Instalez in: ${DEST}"

USE_SUDO=""
if [[ "$DEST" == "$STANDALONE_DEST" ]]; then
    USE_SUDO="sudo"
    log "Destinatia e un folder de sistem — s-ar putea sa-ti ceara parola."
fi

$USE_SUDO mkdir -p "$DEST"

if [[ -d "${DEST}/${BUNDLE_NAME}" ]]; then
    log "O versiune existenta a fost gasita — o inlocuiesc."
    $USE_SUDO rm -rf "${DEST:?}/${BUNDLE_NAME}"
fi

$USE_SUDO cp -R "$BUNDLE_PATH" "$DEST/"
ok "Plugin instalat cu succes."

echo ""
echo "Urmatorul pas: reporneste DaVinci Resolve. Codecurile GDC ar trebui sa"
echo "apara in lista de format-uri MP4/QuickTime, pe pagina Deliver."
