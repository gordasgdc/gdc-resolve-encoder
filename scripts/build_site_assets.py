#!/usr/bin/env python3
"""Builds the page images from raw Deliver-panel captures.

Usage: scripts/build_site_assets.py <raw-dir> <assets-dir>
<raw-dir> holds the private raw captures (panel_*_raw.jpg: zooms of the
Render Settings panel, never the viewer or the render queue). Only the panel
is cropped; the file name and location rows are never included.
Writes deliver-hero.jpg, deliver-{format,codec,settings,render}.jpg and
social-preview.png (1280x640, for the GitHub repository card).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

BG = (16, 18, 20)
ACCENT = (29, 116, 128)
CROP = (0, 0, 660, 1088)  # panel only (no viewer), from the Video/Audio/File tabs down


def panel(raw, name):
    return Image.open(os.path.join(raw, name)).convert("RGB").crop(CROP)


def font(size, bold=False):
    for p in ("/System/Library/Fonts/HelveticaNeue.ttc", "/System/Library/Fonts/Helvetica.ttc"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size, index=1 if bold else 0)
    return ImageFont.load_default()


def fit(img, h):
    return img.resize((round(img.width * h / img.height), h), Image.LANCZOS)


def main():
    raw, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    fmt, typ, closed = panel(raw, "panel_format_list_raw.jpg"), panel(raw, "panel_type_list_raw.jpg"), panel(raw, "panel_closed_raw.jpg")

    # Hero: three panels in a row (Format / Codec+Type / Settings).
    W, H, ph = 1600, 900, 760
    hero = Image.new("RGB", (W, H), BG)
    ps = [fit(p, ph) for p in (fmt, typ, closed)]
    gap = 56
    x0 = (W - (sum(p.width for p in ps) + 2 * gap)) // 2
    pos = []
    x = x0
    for p in ps:
        hero.paste(p, (x, 70))
        pos.append((x, 70))
        x += p.width + gap
    hero.save(os.path.join(out, "deliver-hero.jpg"), quality=90)
    # Pin anchors (percent of the hero) at the Format combo, the Type combo and Rate Control.
    sc = ps[0].width / CROP[2]
    anchors = [(pos[0][0] + 300 * sc, pos[0][1] + 158 * sc), (pos[1][0] + 300 * sc, pos[1][1] + 237 * sc), (pos[2][0] + 300 * sc, pos[2][1] + 758 * sc)]
    print("hero pins:", ["%d%%,%d%%" % (round(100 * a / W), round(100 * b / H)) for a, b in anchors])

    # Tour: one panel on the dark stage per step.
    bottom = Image.open(os.path.join(raw, "panel_bottom_raw.jpg")).convert("RGB").crop((0, 0, 898, 378))
    bottom = bottom.resize((CROP[2], round(378 * CROP[2] / 898)), Image.LANCZOS)
    lower = closed.crop((0, 560, CROP[2], CROP[3]))
    render = Image.new("RGB", (CROP[2], lower.height + bottom.height), BG)
    render.paste(lower, (0, 0))
    render.paste(bottom, (0, lower.height))
    for name, img in (("format", fmt), ("codec", typ), ("settings", closed), ("render", render)):
        tw, th = 1400, 780
        c = Image.new("RGB", (tw, th), BG)
        p = fit(img, min(th - 60, round(img.height * (th - 60) / img.height)))
        c.paste(p, ((tw - p.width) // 2, (th - p.height) // 2))
        c.save(os.path.join(out, "deliver-%s.jpg" % name), quality=90)

    # Guide figures: native-resolution panel crops (legible on A4).
    for name, img, box in (("format", fmt, (0, 90, 660, 520)), ("codec", typ, (0, 90, 660, 560)), ("settings", closed, (0, 590, 660, 1088))):
        img.crop(box).save(os.path.join(out, "guide-%s.jpg" % name), quality=92)

    # Social preview 1280x640.
    sp = Image.new("RGB", (1280, 640), BG)
    d = ImageDraw.Draw(sp)
    d.rectangle((0, 0, 8, 640), fill=ACCENT)
    d.text((72, 120), "GDC Resolve Encoder", font=font(64, True), fill=(255, 255, 255))
    d.text((72, 214), "H.264 and H.265 export plugin", font=font(34), fill=(190, 200, 203))
    d.text((72, 262), "for DaVinci Resolve Studio on Mac", font=font(34), fill=(190, 200, 203))
    d.text((72, 420), "Free  ·  Open source  ·  10-bit  ·  4:2:2  ·  HDR10", font=font(26), fill=(111, 192, 201))
    d.text((72, 540), "Dumitru Cristinel Gordas (GDC)", font=font(22), fill=(130, 140, 143))
    pp = fit(typ, 560)
    sp.paste(pp, (1280 - pp.width - 70, 40))
    sp.save(os.path.join(out, "social-preview.png"))
    print("ok")


if __name__ == "__main__":
    main()
