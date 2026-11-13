#!/usr/bin/env bash
# Attaches the verified macOS package and the corresponding-source archive to the
# DRAFT release created by the tag workflow, then publishes it. Run only after the
# tag exists and the package has been tested. Nothing is uploaded without --yes.
#
# Usage: scripts/publish_release.sh <version> <pkg> <pkg-sha256> <source.tar.gz> [--yes]
set -euo pipefail
VER="${1:?version, e.g. 1.8.0}"; PKG="${2:?pkg}"; PKGSHA="${3:?expected pkg sha256}"; SRC="${4:?source tarball}"; GO="${5:-}"
TAG="v$VER"; REPO="gordasgdc/gdc-resolve-encoder"
[ "$(basename "$PKG")" = "GDCResolveEncoder-$VER.pkg" ] || { echo "pkg must be named GDCResolveEncoder-$VER.pkg"; exit 1; }
[ "$(basename "$SRC")" = "gdc-resolve-encoder-$VER-corresponding-source.tar.gz" ] || { echo "unexpected source archive name"; exit 1; }
[ "$(shasum -a 256 "$PKG" | cut -d' ' -f1)" = "$PKGSHA" ] || { echo "pkg sha256 mismatch"; exit 1; }
[ -f "$SRC.sha256" ] && [ "$(shasum -a 256 "$SRC" | cut -d' ' -f1)" = "$(cut -d' ' -f1 "$SRC.sha256")" ] || { echo "source archive checksum mismatch"; exit 1; }
spctl -a -vv -t install "$PKG" 2>&1 | grep -q "Notarized Developer ID" || { echo "pkg is not notarized"; exit 1; }
xcrun stapler validate "$PKG" >/dev/null
gh release view "$TAG" --repo "$REPO" --json isDraft --jq '.isDraft' | grep -q true || { echo "no draft release $TAG (tag workflow must finish first)"; exit 1; }
echo "Ready: $PKG ($PKGSHA) + $SRC -> draft $TAG of $REPO"
[ "$GO" = "--yes" ] || { echo "dry run; add --yes to upload and publish"; exit 0; }
gh release upload "$TAG" "$PKG" "$SRC" --repo "$REPO" --clobber
gh release edit "$TAG" --repo "$REPO" --draft=false --latest
# The stable link used by the page must now download the package.
curl -fsSIL -o /dev/null -w "latest download: %{http_code} %{size_download}\n" "https://github.com/$REPO/releases/latest/download/GDCResolveEncoder-$VER.pkg"
