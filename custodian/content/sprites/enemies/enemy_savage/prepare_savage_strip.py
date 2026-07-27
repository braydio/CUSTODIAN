#!/usr/bin/env python3
"""Convert a horizontally distributed AI concept sheet into an aligned draft sprite strip.

This is a PREP step only. The output still requires manual pixel cleanup and animation review in Aseprite.
"""
from __future__ import annotations

import argparse
from pathlib import Path
from PIL import Image


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("input", type=Path)
    p.add_argument("output", type=Path)
    p.add_argument("--frames", type=int, default=8)
    p.add_argument("--frame-size", type=int, default=96)
    p.add_argument("--baseline", type=int, default=88,
                   help="Y coordinate where the lowest opaque pixel is anchored")
    p.add_argument("--max-width", type=int, default=88)
    p.add_argument("--max-height", type=int, default=84)
    p.add_argument("--alpha-threshold", type=int, default=48)
    p.add_argument("--preview", type=Path, default=None)
    return p.parse_args()


def clean_alpha(im: Image.Image, threshold: int) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < threshold:
                px[x, y] = (0, 0, 0, 0)
            else:
                # Make surviving pixels fully opaque for a hard-edged draft.
                px[x, y] = (r, g, b, 255)
    return im


def main() -> None:
    args = parse_args()
    src = Image.open(args.input).convert("RGBA")
    if src.width % args.frames != 0:
        raise SystemExit(
            f"Input width {src.width} is not divisible by {args.frames} frames"
        )

    band_w = src.width // args.frames
    out = Image.new("RGBA", (args.frames * args.frame_size, args.frame_size), (0, 0, 0, 0))

    for i in range(args.frames):
        band = src.crop((i * band_w, 0, (i + 1) * band_w, src.height))
        band = clean_alpha(band, args.alpha_threshold)
        bbox = band.getbbox()
        if bbox is None:
            raise SystemExit(f"No visible pixels found in frame band {i + 1}")
        sprite = band.crop(bbox)

        scale = min(args.max_width / sprite.width, args.max_height / sprite.height)
        new_size = (
            max(1, round(sprite.width * scale)),
            max(1, round(sprite.height * scale)),
        )
        sprite = sprite.resize(new_size, Image.Resampling.NEAREST)

        cell_x = i * args.frame_size
        paste_x = cell_x + (args.frame_size - sprite.width) // 2
        paste_y = args.baseline - sprite.height
        if paste_y < 0:
            raise SystemExit(
                f"Frame {i + 1} exceeds the cell height after scaling: {sprite.size}"
            )
        out.alpha_composite(sprite, (paste_x, paste_y))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    out.save(args.output)

    if args.preview:
        args.preview.parent.mkdir(parents=True, exist_ok=True)
        out.resize(
            (out.width * 4, out.height * 4), Image.Resampling.NEAREST
        ).save(args.preview)

    print(f"Wrote {args.output} ({out.width}x{out.height})")


if __name__ == "__main__":
    main()
