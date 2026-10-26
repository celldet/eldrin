"""Builds store graphics from raw device screenshots into store/graphics/.

1. Capture raw screenshots (see integration_test/store_screenshots_test.dart):
     SHOT_DIR=store/screenshots/raw/ios     flutter drive ... -d <ios simulator>
     SHOT_DIR=store/screenshots/raw/android flutter drive ... -d <android emulator>
2. python3 tool/make_store_assets.py      (requires Pillow)

Outputs
  store/graphics/ios/icon-1024.png
  store/graphics/ios/screenshots-6.9in/*.png          1320 x 2868
  store/graphics/android/icon-512.png
  store/graphics/android/feature-graphic-1024x500.png
  store/graphics/android/phone-screenshots/*.png      1080 x 1920
"""
import os
import shutil

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "tool", "fonts", "Cinzel[wght].ttf")
NAVY_TOP, NAVY_BOT = (26, 36, 52), (9, 12, 18)
PARCHMENT, AMBER = (243, 233, 210), (240, 169, 59)

SCENES = [
    ("01_shore", ["WAKE IN THE", "HOLLOWMERE"]),
    ("02_wick", ["MEET THE", "STRANGE FOLK"]),
    ("03_beacon", ["SOLVE PUZZLES,", "LIGHT THE WAY"]),
    ("04_gate", ["ANSWER THE", "ANCIENT RIDDLES"]),
    ("05_cistern", ["EXPLORE THE DARK,", "MIND YOUR LAMP"]),
]


def font(size, weight="Bold"):
    f = ImageFont.truetype(FONT, size)
    f.set_variation_by_name(weight)
    return f


def gradient(w, h):
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(NAVY_TOP[i] * (1 - t) + NAVY_BOT[i] * t) for i in range(3)))
    return img


def tracked(draw, cx, cy, text, fnt, fill, tracking):
    widths = [draw.textlength(c, font=fnt) for c in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x = cx - total / 2
    asc, desc = fnt.getmetrics()
    y = cy - (asc + desc) / 2
    for c, w in zip(text, widths):
        draw.text((x, y), c, font=fnt, fill=fill)
        x += w + tracking


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *img.size], radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def frame(raw_path, size, caption, crop_top, shot_width, caption_cy, shot_top, font_px, radius):
    w, h = size
    canvas = gradient(w, h).convert("RGBA")
    # warm glow behind the phone
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([w * 0.1, h * 0.35, w * 0.9, h * 1.0], fill=AMBER + (50,))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(w * 0.12)))

    raw = Image.open(raw_path).convert("RGB")
    raw = raw.crop((0, crop_top, raw.width, raw.height))
    scale = shot_width / raw.width
    shot = raw.resize((shot_width, int(raw.height * scale)), Image.LANCZOS)
    border = max(4, w // 220)
    framed = Image.new("RGBA", (shot.width + 2 * border, shot.height + 2 * border), AMBER + (255,))
    framed = rounded(framed, radius + border)
    framed.alpha_composite(rounded(shot, radius), (border, border))
    canvas.alpha_composite(framed, ((w - framed.width) // 2, shot_top))

    d = ImageDraw.Draw(canvas)
    # Shrink the caption until its widest line fits in 88% of the canvas.
    while True:
        f = font(font_px)
        widest = max(sum(d.textlength(c, font=f) for c in line) + font_px * 0.08 * (len(line) - 1) for line in caption)
        if widest <= w * 0.88:
            break
        font_px -= 2
    line_h = font_px * 1.25
    y0 = caption_cy - line_h * (len(caption) - 1) / 2
    for i, line in enumerate(caption):
        tracked(d, w / 2, y0 + i * line_h, line, f, PARCHMENT + (255,), font_px * 0.08)
    return canvas.convert("RGB")


def ios_alt(img, size):
    """Centre-crop to the target aspect ratio, then scale (differences are <0.5%)."""
    w, h = img.size
    tw, th = size
    if w * th > h * tw:
        nw = round(h * tw / th)
        img = img.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = round(w * th / tw)
        img = img.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    return img.resize(size, Image.LANCZOS)


def main():
    gfx = os.path.join(ROOT, "store", "graphics")
    for sub in ("ios/screenshots-6.9in", "ios/screenshots-6.7in", "ios/screenshots-6.5in", "android/phone-screenshots"):
        shutil.rmtree(os.path.join(gfx, sub), ignore_errors=True)
        os.makedirs(os.path.join(gfx, sub))

    # Icons
    icon = Image.open(os.path.join(ROOT, "assets/icon/icon.png")).convert("RGB")
    icon.resize((1024, 1024), Image.LANCZOS).save(os.path.join(gfx, "ios/icon-1024.png"))
    icon.resize((512, 512), Image.LANCZOS).save(os.path.join(gfx, "android/icon-512.png"))

    raw = os.path.join(ROOT, "store", "screenshots", "raw")
    for name, caption in SCENES:
        ios = frame(f"{raw}/ios/{name}.png", (1320, 2868), caption, crop_top=120, shot_width=1120,
                    caption_cy=330, shot_top=540, font_px=104, radius=70)
        ios.save(os.path.join(gfx, f"ios/screenshots-6.9in/{name}.png"))
        # Other accepted iPhone sizes, cut from the same artwork.
        for sub, size in (("6.7in", (1290, 2796)), ("6.5in", (1284, 2778))):
            ios_alt(ios, size).save(os.path.join(gfx, f"ios/screenshots-{sub}/{name}.png"))
        android = frame(f"{raw}/android/{name}.png", (1080, 1920), caption, crop_top=60, shot_width=840,
                        caption_cy=250, shot_top=420, font_px=88, radius=56)
        android.save(os.path.join(gfx, f"android/phone-screenshots/{name}.png"))

    # Feature graphic 1024 x 500
    w, h = 1024, 500
    fg = gradient(w, h).convert("RGBA")
    lantern = Image.open(os.path.join(ROOT, "assets/icon/icon_foreground.png")).convert("RGBA")
    lantern = lantern.resize((460, 460), Image.LANCZOS)
    fg.alpha_composite(lantern, (50, 20))
    d = ImageDraw.Draw(fg)
    tracked(d, 715, 215, "ELDRIN", font(100), PARCHMENT + (255,), 12)
    tracked(d, 715, 310, "THE LANTERNS OF THE DEEP", font(25, "Regular"), AMBER + (255,), 3)
    tracked(d, 715, 370, "A TEXT ADVENTURE", font(22, "Regular"), PARCHMENT + (200,), 3)
    fg.convert("RGB").save(os.path.join(gfx, "android/feature-graphic-1024x500.png"))
    print("wrote", gfx)


if __name__ == "__main__":
    main()
