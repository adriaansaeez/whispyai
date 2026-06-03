#!/usr/bin/env python3
"""Generate macOS AppIcon PNGs from the WhispyAI logo pixel data."""
import struct
import zlib
import os

OUTPUT_DIR = "Sources/WhispyAI/Resources/AppIcon.appiconset"
SIZES = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}

# Pixel data for the 16x16 logo grid
# 0 = transparent, 1 = blue (#33b5f5), 2 = white (eyes)
GRID = [
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0],
    [0,0,0,0,0,1,2,1,0,0,2,1,1,0,0,0],
    [0,0,0,0,0,1,1,1,0,0,1,1,1,1,0,0],
    [0,1,1,0,0,1,1,1,0,0,1,1,1,1,0,0],
    [0,1,1,1,1,1,1,1,0,0,1,1,1,1,1,0],
    [0,0,0,0,0,1,1,1,0,0,1,1,1,1,1,1],
    [0,0,0,0,0,1,1,1,0,0,1,1,1,1,1,1],
    [0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1],
    [0,0,0,0,0,0,1,1,1,0,0,1,1,1,0,0],
    [0,0,0,0,0,0,1,1,1,0,0,1,1,1,0,0],
    [0,0,0,0,0,0,1,1,0,0,0,0,1,1,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
]

COLORS = {
    0: (0, 0, 0, 0),       # transparent
    1: (51, 181, 245, 255), # #33b5f5
    2: (255, 255, 255, 255),# white
}

def create_png(pixels, width, height):
    """Create a minimal PNG from RGBA pixel data."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))

    raw = b''
    for y in range(height):
        raw += b'\x00'  # filter none
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            raw += struct.pack('BBBB', r, g, b, a)

    idat = chunk(b'IDAT', zlib.compress(raw))
    iend = chunk(b'IEND', b'')
    return header + ihdr + idat + iend

def generate_icon(target_size):
    """Scale the 16x16 grid to target_size using nearest-neighbor."""
    scale = target_size / 16
    pixels = []
    for y in range(target_size):
        for x in range(target_size):
            src_x = int(x / scale)
            src_y = int(y / scale)
            src_x = min(src_x, 15)
            src_y = min(src_y, 15)
            color_idx = GRID[src_y][src_x]
            pixels.append(COLORS[color_idx])
    return pixels

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for filename, size in SIZES.items():
        pixels = generate_icon(size)
        png_data = create_png(pixels, size, size)
        filepath = os.path.join(OUTPUT_DIR, filename)
        with open(filepath, 'wb') as f:
            f.write(png_data)
        print(f"  {filename} ({size}x{size})")

    # Write Contents.json
    contents = {
        "images": [
            {"filename": "icon_16x16.png", "idiom": "mac", "scale": "1x", "size": "16x16"},
            {"filename": "icon_16x16@2x.png", "idiom": "mac", "scale": "2x", "size": "16x16"},
            {"filename": "icon_32x32.png", "idiom": "mac", "scale": "1x", "size": "32x32"},
            {"filename": "icon_32x32@2x.png", "idiom": "mac", "scale": "2x", "size": "32x32"},
            {"filename": "icon_128x128.png", "idiom": "mac", "scale": "1x", "size": "128x128"},
            {"filename": "icon_128x128@2x.png", "idiom": "mac", "scale": "2x", "size": "128x128"},
            {"filename": "icon_256x256.png", "idiom": "mac", "scale": "1x", "size": "256x256"},
            {"filename": "icon_256x256@2x.png", "idiom": "mac", "scale": "2x", "size": "256x256"},
            {"filename": "icon_512x512.png", "idiom": "mac", "scale": "1x", "size": "512x512"},
            {"filename": "icon_512x512@2x.png", "idiom": "mac", "scale": "2x", "size": "512x512"},
        ],
        "info": {"author": "xcode", "version": 1}
    }
    import json
    with open(os.path.join(OUTPUT_DIR, "Contents.json"), 'w') as f:
        json.dump(contents, f, indent=2)
    print("  Contents.json")

if __name__ == "__main__":
    main()
