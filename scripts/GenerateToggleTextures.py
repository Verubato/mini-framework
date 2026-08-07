"""Generates the toggle switch textures: a white pill track and a white circle knob.

Both are 32-bit uncompressed TGAs with an antialiased alpha channel, drawn white so the
widget tints them with vertex colors. Shapes are inset one texel from every edge and the
widget crops that margin with SetTexCoord, so bilinear sampling never bleeds across the
texture border. Run from anywhere; writes into src/MiniFramework/Media.
"""

import math
import os
import struct

SUPERSAMPLE = 4


def capsule_distance(x, y, x1, x2, cy, radius):
    # Distance to the horizontal segment (x1,cy)-(x2,cy), minus the radius.
    px = min(max(x, x1), x2)
    return math.hypot(x - px, y - cy) - radius


def coverage(distance_fn, px, py):
    hits = 0

    for sy in range(SUPERSAMPLE):
        for sx in range(SUPERSAMPLE):
            x = px + (sx + 0.5) / SUPERSAMPLE
            y = py + (sy + 0.5) / SUPERSAMPLE

            if distance_fn(x, y) <= 0:
                hits += 1

    return hits / (SUPERSAMPLE * SUPERSAMPLE)


def write_tga(path, width, height, distance_fn):
    header = struct.pack(
        "<BBBHHBHHHHBB",
        0,  # id length
        0,  # no color map
        2,  # uncompressed truecolor
        0, 0, 0,  # color map spec
        0, 0,  # origin
        width, height,
        32,  # bits per pixel
        8,  # 8 alpha bits, bottom-left origin
    )

    pixels = bytearray()

    for py in range(height):
        for px in range(width):
            alpha = round(coverage(distance_fn, px, py) * 255)
            pixels += bytes((255, 255, 255, alpha))  # BGRA, white

    with open(path, "wb") as f:
        f.write(header + pixels)

    print(f"wrote {path} ({width}x{height})")


def main():
    media = os.path.join(os.path.dirname(__file__), "..", "src", "MiniFramework", "Media")
    os.makedirs(media, exist_ok=True)

    # 64x32 pill: capsule radius 15 spanning x 1..63, one-texel margin all round.
    write_tga(
        os.path.join(media, "TogglePill.tga"),
        64, 32,
        lambda x, y: capsule_distance(x, y, 16.0, 48.0, 16.0, 15.0),
    )

    # 32x32 circle: radius 15 centered, one-texel margin all round.
    write_tga(
        os.path.join(media, "ToggleKnob.tga"),
        32, 32,
        lambda x, y: math.hypot(x - 16.0, y - 16.0) - 15.0,
    )


if __name__ == "__main__":
    main()
