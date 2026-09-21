#!/usr/bin/env bash
# Generează whitepaper-ul PDF (Regula 38: doar prin script local; verificarea o face scriptul, fără a randa PDF-ul).
set -euo pipefail
cd "$(dirname "$0")"
OUT="${1:-GDC_Resolve_Encoder_Whitepaper_RO.pdf}"
swiftc -O main.swift content.swift content2.swift -o /tmp/gdc-whitepaper-gen
/tmp/gdc-whitepaper-gen "$OUT"
