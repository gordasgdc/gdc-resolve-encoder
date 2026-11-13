#!/usr/bin/env bash
# Regression matrix for the GDC containers (no DaVinci Resolve needed).
# Usage: tests/run_mux_tests.sh <path-to-mux_roundtrip> <scratch-dir>
# Exit 0 only if every available encoder/container combination round-trips
# (every frame decodes, audio length matches) AND the v1.7.0 behaviour
# (--legacy) is still detected as broken, so the test cannot pass vacuously.
set -uo pipefail
BIN="${1:?usage: $0 <mux_roundtrip> <scratch-dir>}"
OUT="${2:?usage: $0 <mux_roundtrip> <scratch-dir>}"
mkdir -p "$OUT"
pass=0; fail=0; skip=0
run() { # <expect: pass|fail> <label> <args...>
    local expect="$1" label="$2"; shift 2
    local log; log="$("$BIN" "$@" 2>&1)"; local rc=$?
    if [ $rc -eq 77 ]; then skip=$((skip+1)); printf 'SKIP  %s\n' "$label"; return; fi
    if { [ "$expect" = pass ] && [ $rc -eq 0 ]; } || { [ "$expect" = fail ] && [ $rc -ne 0 ]; }; then
        pass=$((pass+1)); printf 'OK    %-58s %s\n' "$label" "$(printf '%s\n' "$log" | grep -E '^result:' | cut -c9-60)"
    else
        fail=$((fail+1)); printf 'FAIL  %s (rc=%d, expected %s)\n' "$label" $rc "$expect"; printf '%s\n' "$log" | tail -4 | sed 's/^/        /'
    fi
}
for fmt in mov mp4 matroska; do
    ext=$fmt; [ "$fmt" = matroska ] && ext=mkv
    for enc in libx264 libx265 h264_videotoolbox hevc_videotoolbox; do
        run pass "$enc -> $fmt" "$enc" "$fmt" "$OUT/${enc}.$ext"
    done
    run pass "libx264 High10 4:2:0 -> $fmt" libx264 "$fmt" "$OUT/x264_10.$ext" --pixfmt yuv420p10le
    run pass "libx265 Main10 4:2:0 -> $fmt" libx265 "$fmt" "$OUT/x265_10.$ext" --pixfmt yuv420p10le
    run pass "libx264 High 4:2:2 10 -> $fmt" libx264 "$fmt" "$OUT/x264_422.$ext" --pixfmt yuv422p10le
    run pass "libx265 Main 4:2:2 10 -> $fmt" libx265 "$fmt" "$OUT/x265_422.$ext" --pixfmt yuv422p10le
done
run pass "libx264 23.976 fps -> mov"            libx264 mov "$OUT/x264_23976.mov" --fps 24000/1001 --frames 120
run pass "h264_videotoolbox 29.97 fps -> mp4"   h264_videotoolbox mp4 "$OUT/vt_2997.mp4" --fps 30000/1001 --frames 120
run pass "libx265 no audio -> mov"              libx265 mov "$OUT/x265_noaudio.mov" --no-audio
run pass "aborted export leaves no file"        libx264 mov "$OUT/aborted.mov" --abort
run fail "v1.7.0 behaviour: libx264 -> mov must be detected as broken"           libx264 mov "$OUT/legacy_x264.mov" --legacy
run fail "v1.7.0 behaviour: h264_videotoolbox -> mov must be detected as broken" h264_videotoolbox mov "$OUT/legacy_vt.mov" --legacy
echo "---- $pass ok, $fail failed, $skip skipped"
[ $fail -eq 0 ]
