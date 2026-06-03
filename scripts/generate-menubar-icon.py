#!/usr/bin/env python3
"""Generate a bold monochrome menubar icon for WhispyAI.

Creates a simple, bold 'W' shape that is clearly visible at 16-22pt
in the macOS menu bar. The icon is black-on-transparent (template image).

Output: Sources/WhispyAI/Resources/menubar-icon.png
"""
import struct
import zlib
import os

OUTPUT_PATH = "Sources/WhispyAI/Resources/menubar-icon.png"

# 16x16 grid — bold W silhouette
# 0 = transparent, 1 = black (template image)
GRID = [
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
    [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
    [0,0,0,0,1,1,1,0,0,1,1,1,0,0,0,0],
    [0,1,1,0,1,1,1,0,0,1,1,1,0,1,1,0],
    [0,1,1,0,1,1,1,0,0,1,1,1,0,1,1,0],
    [0,1,1,1,1,1,1,0,0,1,1,1,1,1,1,0],
    [0,0,1,1,1,1,1,0,0,1,1,1,1,1,0,0],
    [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
    [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
    [0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0],
    [0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
]

# Template image: black opaque pixels on transparent background
COLORS = {
    0: (0, 0, 0, 0),       # transparent
    1: (0, 0, 0, 255),     # black (template)
}


def create_png(pixels, width, height):
    """Create a minimal PNG from RGBA pixel data."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        return (
            struct.pack('>I', len(data))
            + c
            + struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)
        )

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))

    raw = b''
    for y in range(height):
        raw += b'\x00'  # filter: none
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            raw += struct.pack('BBBB', r, g, b, a)

    idat = chunk(b'IDAT', zlib.compress(raw))
    iend = chunk(b'IEND', b'')
    return header + ihdr + idat + iend


def generate():
    """Generate 16x16 menubar icon."""
    size = 16
    pixels = []
    for y in range(size):
        for x in range(size):
            color_idx = GRID[y][x]
            pixels.append(COLORS[color_idx])

    png_data = create_png(pixels, size, size)

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, 'wb') as f:
        f.write(png_data)
    print(f"Generated {OUTPUT_PATH} ({size}x{size})")


if __name__ == "__main__":
    generate()
