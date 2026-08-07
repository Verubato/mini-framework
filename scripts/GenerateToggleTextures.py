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


def segment_distance(x, y, x1, y1, x2, y2):
    dx, dy = x2 - x1, y2 - y1
    t = max(0.0, min(1.0, ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)))
    return math.hypot(x - (x1 + t * dx), y - (y1 + t * dy))


def chevron_distance(x, y):
    # Downward chevron: rows run bottom-up in the TGA, so the apex sits at the low y.
    stroke = 2.0
    left = segment_distance(x, y, 8.0, 19.0, 16.0, 11.0)
    right = segment_distance(x, y, 16.0, 11.0, 24.0, 19.0)
    return min(left, right) - stroke


def rounded_rect_distance(x, y):
    # Signed distance to a rounded rect spanning the texture minus its margin, radius 8.
    radius = 8.0
    qx = abs(x - 32.0) - (31.0 - radius)
    qy = abs(y - 16.0) - (15.0 - radius)
    ox = max(qx, 0.0)
    oy = max(qy, 0.0)
    return math.hypot(ox, oy) + min(max(qx, qy), 0.0) - radius


def rounded_ring_distance(x, y):
    # A 1.5-texel line hugging the inside of the rounded rect's edge, so the ring's outer
    # silhouette matches the fill's exactly and nothing pokes into the texture margin.
    return abs(rounded_rect_distance(x, y) + 0.75) - 0.75


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

    # 32x32 downward chevron for the dropdown face.
    write_tga(os.path.join(media, "Chevron.tga"), 32, 32, chevron_distance)

    # 64x32 soft-cornered field: a filled rounded rect and its matching border ring, kept
    # separate so fill and border tint independently.
    write_tga(os.path.join(media, "RoundedField.tga"), 64, 32, rounded_rect_distance)
    write_tga(os.path.join(media, "RoundedBorder.tga"), 64, 32, rounded_ring_distance)


if __name__ == "__main__":
    main()
