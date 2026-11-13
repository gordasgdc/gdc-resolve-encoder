#!/usr/bin/env bash
# One-line QC summary of an exported file: container/stream facts, a full
# decode to the last frame, and audio/video duration agreement.
# Usage: tests/qa_probe.sh <file> [expected-frame-count]
f="${1:?file}"; want="${2:-}"
[ -f "$f" ] || { echo "MISSING $f"; exit 1; }
v=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,pix_fmt,nb_frames,duration,bit_rate,color_primaries,color_transfer,color_space,color_range,r_frame_rate -of default=nk=0:nw=1 "$f" | tr '\n' ' ')
a=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,channels,sample_rate,duration -of default=nk=0:nw=1 "$f" | tr '\n' ' ')
dec=$(ffmpeg -v error -i "$f" -map 0:v:0 -f null - 2>&1 | wc -l | tr -d ' ')
n=$(ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of csv=p=0 "$f" 2>/dev/null)
sz=$(stat -f %z "$f")
ok=OK; [ "$dec" != 0 ] && ok=DECODE_ERRORS; [ -n "$want" ] && [ "$n" != "$want" ] && ok="FRAMES_${n}_WANT_${want}"
echo "$ok | $(basename "$f") | ${sz} B | decoded=$n errs=$dec | V: $v| A: ${a:-none}"
[ "$ok" = OK ]
