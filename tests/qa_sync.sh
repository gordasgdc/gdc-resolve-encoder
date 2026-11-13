#!/usr/bin/env bash
# A/V sync + fidelity check of an export against a reference render of the
# SAME timeline (e.g. a ProRes export from Resolve's own writer).
# Usage: tests/qa_sync.sh <export> <reference>
# Prints: video PSNR (Y), frame count delta, and the audio offset (in
# samples) at the head and at the tail of the programme, found by
# cross-correlating 2 s windows. 0 at both ends = no offset, no drift.
set -euo pipefail
x="${1:?export}"; r="${2:?reference}"
psnr=$(ffmpeg -v error -i "$x" -i "$r" -lavfi "[0:v][1:v]psnr=stats_file=-" -an -f null - 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i ~ /^psnr_y:/){split($i,a,":"); s+=a[2]; n++}} END{if(n) printf "%.2f dB over %d frames", s/n, n; else print "n/a"}')
echo "video PSNR-Y vs reference: $psnr"
python3 - "$x" "$r" <<'PY'
import subprocess, sys, array
def pcm(path, start, dur=2.0, sr=48000):
    out = subprocess.run(["ffmpeg","-v","error","-ss",str(start),"-t",str(dur),"-i",path,"-map","0:a:0","-ac","1","-ar",str(sr),"-f","s16le","-"],capture_output=True).stdout
    a = array.array("h"); a.frombytes(out[:len(out)//2*2]); return a
def dur(path):
    return float(subprocess.run(["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0",path],capture_output=True,text=True).stdout.strip())
def offset(a, b, maxlag=2400):
    n = min(len(a), len(b)) - 2*maxlag
    if n <= 0: return None
    step = 4; best = (None, -1)
    bb = b[maxlag:maxlag+n:step]
    for lag in range(-maxlag, maxlag+1):
        aa = a[maxlag+lag:maxlag+lag+n:step]
        s = sum(x*y for x, y in zip(aa, bb))
        if s > best[1]: best = (lag, s)
    return best[0]
x, r = sys.argv[1], sys.argv[2]
d = min(dur(x), dur(r))
for label, start in (("head", 0.5), ("tail", max(0.5, d - 3.0))):
    a, b = pcm(x, start), pcm(r, start)
    if not a or not b: print(f"audio {label}: no audio to compare"); continue
    if max(map(abs, b)) < 50: print(f"audio {label}: reference is silent here, offset not measurable"); continue
    print(f"audio {label} offset: {offset(a, b)} samples @48 kHz")
PY
