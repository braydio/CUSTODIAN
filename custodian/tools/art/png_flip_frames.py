#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
from PIL import Image, ImageOps


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Flip each frame in a spritesheet while preserving frame layout."
    )
    p.add_argument("input", help="Input spritesheet PNG")
    p.add_argument("output", help="Output spritesheet PNG")

    p.add_argument("--h", "--horizontal", action="store_true", dest="hflip",
                   help="Flip each frame horizontally")
    p.add_argument("--v", "--vertical", action="store_true", dest="vflip",
                   help="Flip each frame vertically")

    p.add_argument("--frames", type=int, default=None,
                   help="Number of frames to process. Defaults to rows * cols.")
    p.add_argument("--rows", type=int, required=True,
                   help="Number of frame rows in the sheet")
    p.add_argument("--cols", type=int, required=True,
                   help="Number of frame columns in the sheet")

    p.add_argument("--strict", action="store_true",
                   help="Fail if --frames does not equal rows * cols")

    return p.parse_args()


def main() -> None:
    args = parse_args()

    if not args.hflip and not args.vflip:
        raise SystemExit("Nothing to do: pass --h and/or --v")

    src_path = Path(args.input)
    out_path = Path(args.output)

    img = Image.open(src_path).convert("RGBA")
    w, h = img.size

    if w % args.cols != 0:
        raise SystemExit(f"Image width {w} is not divisible by cols {args.cols}")
    if h % args.rows != 0:
        raise SystemExit(f"Image height {h} is not divisible by rows {args.rows}")

    frame_w = w // args.cols
    frame_h = h // args.rows

    max_frames = args.rows * args.cols
    frame_count = args.frames if args.frames is not None else max_frames

    if frame_count > max_frames:
        raise SystemExit(
            f"--frames {frame_count} exceeds grid capacity rows*cols={max_frames}"
        )

    if args.strict and frame_count != max_frames:
        raise SystemExit(
            f"--strict enabled: --frames {frame_count} != rows*cols {max_frames}"
        )

    out = img.copy()

    for i in range(frame_count):
        row = i // args.cols
        col = i % args.cols

        x0 = col * frame_w
        y0 = row * frame_h
        x1 = x0 + frame_w
        y1 = y0 + frame_h

        frame = img.crop((x0, y0, x1, y1))

        if args.hflip:
            frame = ImageOps.mirror(frame)
        if args.vflip:
            frame = ImageOps.flip(frame)

        out.paste(frame, (x0, y0))

    out.save(out_path)
    print(f"wrote {out_path}")
    print(f"sheet={w}x{h} frame={frame_w}x{frame_h} rows={args.rows} cols={args.cols} processed_frames={frame_count}")
    print(f"hflip={args.hflip} vflip={args.vflip}")


if __name__ == "__main__":
    main()
