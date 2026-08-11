#!/usr/bin/env python3
"""Generate Daily Fit launcher icon assets with PIL.

- assets/icon/icon.png             : full 1024x1024 icon (rounded black square + yellow hanger)
- assets/icon/icon_foreground.png  : adaptive foreground (transparent bg, glyph in safe zone)
"""
from PIL import Image, ImageDraw

YELLOW = (255, 214, 10, 255)
BLACK = (10, 10, 10, 255)
SIZE = 1024


def draw_hanger(draw, cx, apex_y, base_y, width, hook_r, stem_dx):
    """Hanger glyph: dome hook + two stems + triangle body (base = crossbar)."""
    # Triangle body (apex at top, wide base at bottom).
    draw.polygon(
        [(cx, apex_y), (cx - width, base_y), (cx + width, base_y)],
        outline=YELLOW,
        width=42,
    )
    # Hook: upper semicircle.
    draw.arc(
        [cx - hook_r, apex_y - 2 * hook_r, cx + hook_r, apex_y],
        start=180,
        end=360,
        fill=YELLOW,
        width=42,
    )
    # Stems connecting hook ends to the apex.
    draw.line([(cx - hook_r, apex_y - hook_r), (cx - stem_dx, apex_y)], fill=YELLOW, width=42)
    draw.line([(cx + hook_r, apex_y - hook_r), (cx + stem_dx, apex_y)], fill=YELLOW, width=42)


def rounded_square(draw, size, radius, fill):
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=fill)


# ---- Full icon ----
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
rounded_square(d, SIZE, 224, BLACK)
draw_hanger(d, cx=512, apex_y=352, base_y=640, width=168, hook_r=46, stem_dx=26)
img.save("assets/icon/icon.png")

# ---- Adaptive foreground (glyph inside central safe zone, transparent bg) ----
fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d2 = ImageDraw.Draw(fg)
draw_hanger(d2, cx=512, apex_y=430, base_y=650, width=132, hook_r=34, stem_dx=20)
fg.save("assets/icon/icon_foreground.png")

print("wrote assets/icon/icon.png and assets/icon/icon_foreground.png")
