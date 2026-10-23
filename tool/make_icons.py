"""Generates Eldrin's icon and splash art into assets/icon/.

Run from the project root:  python3 tool/make_icons.py
Requires Pillow. Then:      dart run flutter_launcher_icons && dart run flutter_native_splash:create
"""
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 4          # supersampling factor
N = 1024       # output size
W = N * S

AMBER = (240, 169, 59)
FLAME = (255, 226, 150)
IRON = (230, 216, 181)
NAVY_TOP = (26, 36, 52)
NAVY_BOT = (9, 12, 18)


def background():
    img = Image.new("RGB", (W, W))
    px = ImageDraw.Draw(img)
    for y in range(W):
        t = y / W
        c = tuple(int(NAVY_TOP[i] * (1 - t) + NAVY_BOT[i] * t) for i in range(3))
        px.line([(0, y), (W, y)], fill=c)
    return img


def glow(radius_frac, strength, cx=0.5, cy=0.5):
    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    r = int(W * radius_frac)
    d.ellipse([W * cx - r, W * cy - r, W * cx + r, W * cy + r], fill=AMBER + (int(255 * strength),))
    return layer.filter(ImageFilter.GaussianBlur(W * 0.07))


def lantern(scale=1.0):
    """Lantern drawn on a transparent layer, centred, fitting ~scale of the canvas."""
    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    def P(x, y):  # normalised (0..1) lantern space -> pixels, scaled about the centre
        return (W * (0.5 + (x - 0.5) * scale), W * (0.5 + (y - 0.5) * scale))

    lw = int(W * 0.028 * scale)

    # bail (handle)
    d.arc([*P(0.39, 0.10), *P(0.61, 0.30)], 180, 360, fill=IRON, width=lw)
    # cap
    d.polygon([P(0.34, 0.30), P(0.66, 0.30), P(0.60, 0.22), P(0.40, 0.22)], fill=IRON)
    # glass body (slightly flared)
    body = [P(0.36, 0.30), P(0.64, 0.30), P(0.69, 0.70), P(0.31, 0.70)]
    d.polygon(body, fill=(60, 40, 14, 255))
    # inner light
    inner = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(inner).polygon(body, fill=AMBER + (255,))
    layer.alpha_composite(inner)
    # flame
    f = ImageDraw.Draw(layer)
    f.ellipse([*P(0.455, 0.40), *P(0.545, 0.62)], fill=FLAME + (255,))
    f.polygon([P(0.455, 0.52), P(0.5, 0.35), P(0.545, 0.52)], fill=FLAME + (255,))
    # frame bars
    for x0, x1 in ((0.36, 0.31), (0.64, 0.69)):
        f.line([P(x0, 0.30), P(x1, 0.70)], fill=IRON, width=lw)
    # base
    f.rounded_rectangle([*P(0.29, 0.70), *P(0.71, 0.76)], radius=int(W * 0.012), fill=IRON)
    f.rounded_rectangle([*P(0.33, 0.76), *P(0.67, 0.79)], radius=int(W * 0.010), fill=IRON)
    return layer


def save(img, name, size=N):
    img.resize((size, size), Image.LANCZOS).save(f"assets/icon/{name}")


# Full icon (iOS + legacy Android): opaque background with halo and lantern.
icon = background().convert("RGBA")
icon.alpha_composite(glow(0.30, 0.55))
icon.alpha_composite(lantern(1.0))
save(icon.convert("RGB"), "icon.png")

# Android adaptive foreground: transparent. flutter_launcher_icons already insets
# it 16% for the safe zone, so the lantern fills the canvas here.
fg = Image.new("RGBA", (W, W), (0, 0, 0, 0))
fg.alpha_composite(glow(0.30, 0.50))
fg.alpha_composite(lantern(1.0))
save(fg, "icon_foreground.png")

# Splash: title on top, lantern in the middle, subtitle underneath (transparent PNG).
# Type is Cinzel (SIL Open Font License, see tool/fonts/OFL-Cinzel.txt).
FONT = os.path.join(os.path.dirname(__file__), "fonts", "Cinzel[wght].ttf")
PARCHMENT = (243, 233, 210)


def font(size, weight):
    f = ImageFont.truetype(FONT, size)
    f.set_variation_by_name(weight)
    return f


def tracked(draw, cy, text, fnt, fill, tracking, width):
    """Draw [text] horizontally centred in [width] with letter-spacing, centred on y=cy."""
    widths = [draw.textlength(ch, font=fnt) for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x = (width - total) / 2
    asc, desc = fnt.getmetrics()
    y = cy - (asc + desc) / 2
    for ch, w in zip(text, widths):
        draw.text((x, y), ch, font=fnt, fill=fill)
        x += w + tracking


def splash_art(out_w=1152, out_h=1728):
    k = 2  # draw at 2x, then downsample
    cw, ch = out_w * k, out_h * k
    canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    mark = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    mark.alpha_composite(glow(0.27, 0.50))
    mark.alpha_composite(lantern(0.92))
    size = int(cw * 0.78)
    mark = mark.resize((size, size), Image.LANCZOS)
    canvas.alpha_composite(mark, ((cw - size) // 2, int(ch * 0.50 - size / 2)))
    d = ImageDraw.Draw(canvas)
    tracked(d, ch * 0.195, "ELDRIN", font(int(cw * 0.15), "Bold"), PARCHMENT + (255,), cw * 0.035, cw)
    tracked(d, ch * 0.795, "The Lanterns of the Deep", font(int(cw * 0.043), "Regular"), AMBER + (255,), cw * 0.008, cw)
    return canvas.resize((out_w, out_h), Image.LANCZOS)


splash_art().save("assets/icon/splash_logo.png")

# Android 12 clips the splash icon to a circle (~2/3 of the canvas), so keep the
# lantern and its halo well inside it.
a12 = Image.new("RGBA", (W, W), (0, 0, 0, 0))
a12.alpha_composite(glow(0.14, 0.45))
a12.alpha_composite(lantern(0.56))
save(a12, "splash_logo_a12.png", 768)
print("wrote assets/icon/")
