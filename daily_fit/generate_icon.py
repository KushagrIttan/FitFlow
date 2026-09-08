#!/usr/bin/env python3
"""Generate Daily Fit launcher icon assets with PIL.

- assets/icon/icon.png             : full 1024x1024 icon (black rounded tile + yellow folded-tee glyph)
- assets/icon/icon_foreground.png  : adaptive foreground (transparent bg, glyph in safe zone)
"""
from PIL import Image, ImageDraw

YELLOW = (255, 214, 10, 255)
BLACK = (10, 10, 10, 255)
SIZE = 1024


def draw_folded_tee(d, cx, top, hem, width, sleeve_wing, shoulder_drop):
    """Folded t-shirt glyph (front view): dropped sleeves, collar, center fold.

    width        : half-width of the body at the hem
    sleeve_wing  : how far the sleeve tips poke out horizontally
    shoulder_drop: vertical distance of sleeve tips below the shoulders
    """
    shoulder = cx - width + 16
    sleeve_tip_x = cx - width - sleeve_wing
    sleeve_hem_outer = cx - width - 18
    sleeve_hem_inner = cx - width + 44

    # Body + sleeves as a single filled path.
    torso = [
        (shoulder, top + 6),                 # left shoulder
        (sleeve_tip_x, top + 6 + shoulder_drop),   # left sleeve tip
        (sleeve_hem_outer, top + 6 + shoulder_drop + 26),  # left sleeve hem outer
        (sleeve_hem_inner, top + 6 + shoulder_drop + 12),  # left sleeve hem inner
        (cx - width, hem),                   # body left
        (cx + width, hem),                   # body right
        (cx + width - 44, top + 6 + shoulder_drop + 12),   # right sleeve hem inner
        (cx + width + 18, top + 6 + shoulder_drop + 26),   # right sleeve hem outer
        (cx + width + sleeve_wing, top + 6 + shoulder_drop),  # right sleeve tip
        (cx - shoulder, top + 6),            # right shoulder
    ]
    d.polygon(torso, fill=YELLOW)

    # Collar (open neck) — cut out in black.
    collar_w = 172
    collar_h = 58
    d.ellipse(
        [cx - collar_w, top, cx + collar_w, top + collar_h],
        fill=BLACK,
        width=0,
    )
    # Sleeve seam lines.
    d.line([(sleeve_hem_inner, top + 6 + shoulder_drop + 2), (cx - width + 22, top + 6 + shoulder_drop + 26)],
           fill=BLACK, width=16)
    d.line([(cx + width - 44, top + 6 + shoulder_drop + 2), (cx + width - 22, top + 6 + shoulder_drop + 26)],
           fill=BLACK, width=16)
    # Center fold line.
    d.line([(cx, top + 46), (cx, hem - 6)], fill=BLACK, width=20)


def rounded_square(draw, size, radius, fill):
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=fill)


# ---- Full icon ----
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
rounded_square(d, SIZE, 224, BLACK)
draw_folded_tee(d, cx=512, top=330, hem=664, width=152, sleeve_wing=64, shoulder_drop=104)
img.save("assets/icon/icon.png")

# ---- Adaptive foreground (glyph inside central safe zone, transparent bg) ----
fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d2 = ImageDraw.Draw(fg)
draw_folded_tee(d2, cx=512, top=392, hem=656, width=120, sleeve_wing=52, shoulder_drop=84)
fg.save("assets/icon/icon_foreground.png")

print("wrote assets/icon/icon.png and assets/icon/icon_foreground.png")