#!/usr/bin/env bash
# Generează whitepaper-ul PDF în RO, EN și ES (Regula 38: doar prin script local; verificarea o face scriptul, fără a randa PDF-ul).
# Utilizare: ./build-whitepaper.sh [ro|en|es|all]   (implicit: all)
set -euo pipefail
cd "$(dirname "$0")"
swiftc -O main.swift lang.swift content.swift content2.swift content_en.swift content2_en.swift content_es.swift content2_es.swift -o /tmp/gdc-whitepaper-gen
LANGS="${1:-all}"
[ "$LANGS" = "all" ] && LANGS="ro en es"
for l in $LANGS; do /tmp/gdc-whitepaper-gen "$l"; done
