#!/usr/bin/env python3
"""
make_clean_causeway_mask.py

Creates a clean first-pass gameplay logic mask for the Sundered Keep
causeway approach image.

This intentionally DOES NOT auto-detect water/cliffs from the finished art.
The output is a starting mask you review/edit by hand.

Mask colors:
  #00ff00 = walkable
  #ff0000 = blocker / hard boundary
  #0000ff = transition trigger
  #ffff00 = hazard / fall / water edge
  #ff00ff = interactable marker
  #000000 = ignored
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw

IGNORED = (0, 0, 0, 255)
WALKABLE = (0, 255, 0, 255)
BLOCKER = (255, 0, 0, 255)
TRANSITION = (0, 0, 255, 255)
HAZARD = (255, 255, 0, 255)
INTERACTABLE = (255, 0, 255, 255)


def ceil_to_multiple(value: int, multiple: int) -> int:
    return int(math.ceil(value / multiple) * multiple)


def normalize_to_grid(image: Image.Image, tile_size: int) -> Image.Image:
    image = image.convert("RGBA")
    w, h = image.size
    out_w = ceil_to_multiple(w, tile_size)
    out_h = ceil_to_multiple(h, tile_size)

    canvas = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 255))
    canvas.alpha_composite(image, (0, 0))
    return canvas


def draw_causeway_mask(draw: ImageDraw.ImageDraw) -> None:
    """
    Coordinates are tuned for the uploaded Sundered Keep approach image:
    approximately 2048 wide, padded to 2048x1440.
    """

    # Main central bridge/causeway deck.
    draw.polygon(
        [
            (930, 1418),
            (1138, 1418),
            (1138, 635),
            (1112, 585),
            (1088, 515),
            (994, 515),
            (970, 585),
            (930, 635),
        ],
        fill=WALKABLE,
    )

    # Upper landing in front of gate.
    draw.polygon(
        [
            (890, 445),
            (1185, 445),
            (1185, 625),
            (1138, 650),
            (930, 650),
            (890, 605),
        ],
        fill=WALKABLE,
    )

    # Gate transition area.
    draw.rectangle((985, 400, 1085, 470), fill=TRANSITION)

    # Left causeway side platform.
    draw.polygon(
        [
            (820, 810),
            (920, 765),
            (920, 940),
            (805, 940),
            (765, 875),
        ],
        fill=WALKABLE,
    )

    # Right causeway side platform.
    draw.polygon(
        [
            (1142, 760),
            (1265, 805),
            (1290, 910),
            (1190, 955),
            (1142, 925),
        ],
        fill=WALKABLE,
    )

    # Right cliff stairs / switchback route.
    # This is intentionally a thick ribbon; tune in Aseprite after preview.
    stairs = [
        (1490, 382),
        (1440, 470),
        (1515, 545),
        (1410, 640),
        (1490, 725),
        (1375, 830),
        (1450, 910),
    ]
    try:
        draw.line(stairs, fill=WALKABLE, width=54, joint="curve")
    except TypeError:
        draw.line(stairs, fill=WALKABLE, width=54)

    # Lower-right shore playable area.
    draw.polygon(
        [
            (1400, 560),
            (1710, 560),
            (1865, 650),
            (1900, 780),
            (1810, 940),
            (1615, 1005),
            (1410, 950),
            (1315, 820),
            (1315, 665),
        ],
        fill=WALKABLE,
    )

    # Hoist / interactable marker.
    draw.ellipse((1518, 860, 1578, 920), fill=INTERACTABLE)

    # Optional hazard edge around visible waterline near shore.
    # Keep this conservative. Do not fill the whole ocean.
    draw.line(
        [
            (1760, 620),
            (1890, 710),
            (1870, 860),
            (1740, 980),
            (1570, 1030),
        ],
        fill=HAZARD,
        width=36,
    )

    # Outer blocker rails around the main bridge so the player cannot walk off.
    # These are not the whole wall mass, just hard boundaries near playable route.
    draw.line([(905, 1418), (905, 650), (865, 610), (865, 455)], fill=BLOCKER, width=24)
    draw.line(
        [(1165, 1418), (1165, 650), (1210, 610), (1210, 455)], fill=BLOCKER, width=24
    )

    # Front gate / fortress hard top boundary, leaving blue transition open.
    draw.rectangle((860, 360, 980, 440), fill=BLOCKER)
    draw.rectangle((1090, 360, 1220, 440), fill=BLOCKER)


def draw_grid(preview: Image.Image, tile_size: int) -> None:
    draw = ImageDraw.Draw(preview, "RGBA")
    w, h = preview.size

    for x in range(0, w + 1, tile_size):
        alpha = 85 if x % (tile_size * 4) == 0 else 35
        draw.line((x, 0, x, h), fill=(255, 255, 255, alpha), width=1)

    for y in range(0, h + 1, tile_size):
        alpha = 85 if y % (tile_size * 4) == 0 else 35
        draw.line((0, y, w, y), fill=(255, 255, 255, alpha), width=1)


def make_preview(
    src: Image.Image, mask: Image.Image, tile_size: int, show_grid: bool
) -> Image.Image:
    preview = src.convert("RGBA")
    overlay = Image.new("RGBA", src.size, (0, 0, 0, 0))

    mask_px = mask.load()
    overlay_px = overlay.load()

    alpha_by_color = {
        WALKABLE: 130,
        BLOCKER: 120,
        TRANSITION: 165,
        HAZARD: 120,
        INTERACTABLE: 190,
    }

    for y in range(src.height):
        for x in range(src.width):
            color = mask_px[x, y]
            if color == IGNORED:
                continue
            alpha = alpha_by_color.get(color, 120)
            overlay_px[x, y] = (color[0], color[1], color[2], alpha)

    preview = Image.alpha_composite(preview, overlay)

    if show_grid:
        draw_grid(preview, tile_size)

    return preview


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("image", type=Path)
    parser.add_argument(
        "--out", type=Path, default=Path("causeway_approach_logic_mask.png")
    )
    parser.add_argument(
        "--preview", type=Path, default=Path("causeway_approach_logic_mask_preview.png")
    )
    parser.add_argument(
        "--normalized-bg", type=Path, default=Path("causeway_approach_background.png")
    )
    parser.add_argument("--tile-size", type=int, default=32)
    parser.add_argument("--no-grid-preview", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not args.image.exists():
        raise SystemExit(f"missing image: {args.image}")

    src_raw = Image.open(args.image).convert("RGBA")
    src = normalize_to_grid(src_raw, args.tile_size)

    if src.size != src_raw.size:
        print(f"padded source from {src_raw.size} to {src.size}")

    mask = Image.new("RGBA", src.size, IGNORED)
    draw = ImageDraw.Draw(mask, "RGBA")

    draw_causeway_mask(draw)

    preview = make_preview(
        src, mask, args.tile_size, show_grid=not args.no_grid_preview
    )

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.preview.parent.mkdir(parents=True, exist_ok=True)
    args.normalized_bg.parent.mkdir(parents=True, exist_ok=True)

    mask.save(args.out)
    preview.save(args.preview)
    src.save(args.normalized_bg)

    print("wrote:")
    print(f"  mask:       {args.out} {mask.size}")
    print(f"  preview:    {args.preview} {preview.size}")
    print(f"  background: {args.normalized_bg} {src.size}")
    print(
        f"grid: {src.size[0] // args.tile_size} x {src.size[1] // args.tile_size} tiles"
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
