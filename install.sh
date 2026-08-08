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

# --- verify FFmpeg is installed --------------------------------------------
# Plugin-ul foloseste bibliotecile FFmpeg din sistem (nu sunt incluse in
# bundle — vezi README pentru motiv). Fara ele, plugin-ul nu se incarca deloc
# in Resolve, fara niciun mesaj de eroare vizibil in interfata.
log "Verific daca FFmpeg este instalat..."
if command -v ffmpeg &> /dev/null; then
    ok "FFmpeg este deja instalat ($(ffmpeg -version | head -n1 | cut -d' ' -f3))."
else
    echo ""
    echo "FFmpeg nu a fost gasit. Plugin-ul are nevoie de el ca sa functioneze."
    if ! command -v brew &> /dev/null; then
        err "Homebrew nu e instalat, deci nu pot instala FFmpeg automat."
        echo ""
        echo "Instaleaza Homebrew mai intai, cu:"
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo ""
        echo "Apoi ruleaza din nou acest script. Sau instaleaza FFmpeg manual (vezi README)."
        exit 1
    fi
    read -r -p "Instalez FFmpeg acum prin Homebrew? [Y/n] " reply
    if [[ "$reply" =~ ^[Nn]$ ]]; then
        err "Instalare anulata — plugin-ul nu va functiona fara FFmpeg."
        exit 1
    fi
    log "Instalez FFmpeg (poate dura cateva minute)..."
    brew install ffmpeg
    ok "FFmpeg instalat."
fi

# --- locate the bundle -------------------------------------------------
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
