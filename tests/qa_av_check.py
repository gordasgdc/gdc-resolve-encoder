#!/usr/bin/env python3
"""Frame- and sample-accurate QC of one export against its source clip(s).

Usage: tests/qa_av_check.py <export> <source1> [<source2> ...]
The sources are the clips placed back to back on the timeline (in order, each
from its first frame). The script reports, per segment:
  * PSNR of the first / middle / last frame against the source (video content
    and frame alignment: a one-frame slip shows as a PSNR collapse),
  * audio: exact-match fraction of the PCM samples, or the cross-correlation
    lag in samples/ms when the audio is not identical (A/V sync).
and for the whole file: stream start times, durations and audio sample count.
Requires ffmpeg/ffprobe and numpy. Never writes next to the sources.
"""
import json
import subprocess
import warnings
import sys

import numpy as np

warnings.filterwarnings("ignore")
W_SETPARAMS = "setparams=colorspace=bt709:color_primaries=bt709:color_trc=bt709:range=tv"


def probe(path, entries, stream):
    out = subprocess.run(["ffprobe", "-v", "error", "-select_streams", stream, "-show_entries",
                          "stream=" + entries, "-of", "json", path], capture_output=True, text=True).stdout
    s = json.loads(out or "{}").get("streams", [])
    return s[0] if s else None


def frames(path, idx, pix, w, h, fix_tags):
    sel = "+".join("eq(n\\,%d)" % i for i in idx)
    vf = ("%s," % W_SETPARAMS if fix_tags else "") + "select='%s',format=%s" % (sel, pix)
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-map", "0:v:0", "-vf", vf, "-fps_mode", "passthrough",
                          "-f", "rawvideo", "-"], capture_output=True).stdout
    per = len(raw) // len(idx)
    return [np.frombuffer(raw[i * per:(i + 1) * per], dtype="<u2").astype(np.float64) for i in range(len(idx))]


def psnr(a, b):
    mse = np.mean((a - b) ** 2)
    return 99.0 if mse == 0 else 10 * np.log10(1023.0 ** 2 / mse)


def audio(path):
    p = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-map", "0:a:0", "-f", "s32le", "-ac", "2", "-ar", "48000", "-"],
                       capture_output=True)
    if p.returncode != 0 or not p.stdout:
        return None
    return np.frombuffer(p.stdout, dtype="<i4").reshape(-1, 2).astype(np.int64)


def lag(a, b, maxlag=4800):
    n = min(len(a), len(b), 48000)
    x = a[:n, 0].astype(np.float64)
    y = b[:n, 0].astype(np.float64)
    if not x.any() or not y.any():
        return None
    N = 1 << int(np.ceil(np.log2(2 * n)))
    c = np.fft.irfft(np.fft.rfft(x, N) * np.conj(np.fft.rfft(y, N)), N)
    c = np.concatenate([c[-maxlag:], c[:maxlag + 1]])
    return int(np.argmax(c)) - maxlag


def main():
    exp, srcs = sys.argv[1], sys.argv[2:]
    ev = probe(exp, "pix_fmt,nb_frames,start_time,duration,width,height", "v:0")
    ea = probe(exp, "start_time,duration,channels,codec_name", "a:0")
    pix = "yuv422p10le" if "422" in ev["pix_fmt"] else "yuv420p10le"
    w, h = int(ev["width"]), int(ev["height"])
    print("EXPORT %s | %s %dx%d v_start=%s v_dur=%s | a: %s" % (
        exp.split("/")[-1], ev["pix_fmt"], w, h, ev.get("start_time"), ev.get("duration"),
        ("%s ch%s start=%s dur=%s" % (ea["codec_name"], ea["channels"], ea.get("start_time"), ea.get("duration"))) if ea else "none"))
    ex_audio = audio(exp)
    f0 = 0
    worst_psnr = 99.0
    for s in srcs:
        sv = probe(s, "nb_frames", "v:0")
        n = int(sv["nb_frames"])
        local = sorted({0, n // 2, n - 1})
        pe = frames(exp, [f0 + i for i in local], pix, w, h, False)
        ps = frames(s, local, pix, w, h, True)
        vals = [psnr(a, b) for a, b in zip(pe, ps)]
        worst_psnr = min(worst_psnr, min(vals))
        line = "  seg@%-5d %s n=%d PSNR[first,mid,last]=%s" % (f0, s.split("/")[-1][:9], n, [round(float(v), 1) for v in vals])
        sa = audio(s)
        if ex_audio is not None:
            seg = ex_audio[f0 * 1600:(f0 + n) * 1600]
            if sa is None:
                line += " audio: source has none, export peak=%d (silence if 0)" % (np.abs(seg).max() if len(seg) else -1)
            else:
                ref = sa[:len(seg)]
                m = min(len(ref), len(seg))
                same = float(np.mean((seg[:m] == ref[:m]).all(axis=1)))
                if same == 1.0:
                    line += " audio: bit-exact (%d samples)" % m
                else:
                    d = np.nonzero((seg[:m] != ref[:m]).any(axis=1))[0]
                    # Resolve applies a ~1.5 ms fade at every clip edge: differences
                    # confined to the first/last EDGE samples of the segment are expected.
                    EDGE = 96
                    inner = d[(d >= EDGE) & (d < m - EDGE)]
                    line += " audio: %d/%d samples differ, %d outside the %d-sample clip-edge fades, lag=%s" % (
                        len(d), m, len(inner), EDGE, lag(seg, ref))
        print(line)
        f0 += n
    tot = len(ex_audio) if ex_audio is not None else 0
    print("  TOTAL frames_expected=%d export_frames=%s audio_samples=%d expected=%d (diff %d)" % (
        f0, ev.get("nb_frames"), tot, f0 * 1600, tot - f0 * 1600))
    print("  VERDICT %s" % ("OK" if worst_psnr > 30 else "VIDEO_MISMATCH(min %.1f dB)" % worst_psnr))


if __name__ == "__main__":
    main()
