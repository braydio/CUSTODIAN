#!/usr/bin/env python3
"""
make_sundered_keep_causeway_mask.py

Creates a first-pass flat-color gameplay logic mask for the Sundered Keep
causeway approach background.

Mask color contract:
  #00ff00 = walkable
  #ff0000 = blocker / wall / parapet / hard boundary
  #0000ff = transition trigger
  #ffff00 = hazard / water / fall edge
  #ff00ff = interactable marker
  #000000 = ignored

This is an AUTHORING STARTING POINT. Review/tune the output in Aseprite/Krita.
Do not use the pretty background PNG directly as runtime collision authority.
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path
from typing import Iterable

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
    """Pad image to a tile-aligned RGBA canvas."""
    image = image.convert("RGBA")
    w, h = image.size
    out_w = ceil_to_multiple(w, tile_size)
    out_h = ceil_to_multiple(h, tile_size)

    if (out_w, out_h) == (w, h):
        return image

    canvas = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 255))
    canvas.alpha_composite(image, (0, 0))
    return canvas


def is_waterish_pixel(r: int, g: int, b: int, a: int) -> bool:
    """
    Rough water detector for this specific dark ocean/keep image.

    This is intentionally conservative. The authored green walkable shapes
    are painted afterward and override this.
    """
    if a < 16:
        return False

    # Ignore pure/near black empty canvas.
    if r < 8 and g < 8 and b < 8:
        return False

    brightness = (r + g + b) / 3.0

    # Dark blue-green ocean/void range.
    blue_green_bias = b >= r + 8 and g >= r - 2
    dark_enough = brightness <= 95
    enough_color = b >= 24 and g >= 18

    return blue_green_bias and dark_enough and enough_color


def paint_auto_water_hazards(src: Image.Image, mask: Image.Image) -> None:
    """Paint ocean-ish pixels as yellow hazard."""
    src_px = src.load()
    mask_px = mask.load()
    w, h = src.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = src_px[x, y]
            if is_waterish_pixel(r, g, b, a):
                mask_px[x, y] = HAZARD


def draw_polygons(
    draw: ImageDraw.ImageDraw,
    polygons: Iterable[list[tuple[int, int]]],
    color: tuple[int, int, int, int],
) -> None:
    for poly in polygons:
        draw.polygon(poly, fill=color)


def draw_walkable_route(draw: ImageDraw.ImageDraw) -> None:
    """
    Hand-authored first-pass playable space for the uploaded 2048px-wide image.

    Tune these coordinates after reviewing the preview.
    """

    # Main central causeway / bridge deck.
    draw.polygon(
        [
            (920, 1418),
            (1142, 1418),
            (1144, 610),
            (1116, 565),
            (1088, 510),
            (992, 510),
            (960, 565),
            (918, 610),
        ],
        fill=WALKABLE,
    )

    # Upper landing in front of gate.
    draw.polygon(
        [
            (875, 455),
            (1194, 455),
            (1190, 625),
            (1126, 642),
            (930, 642),
            (875, 600),
        ],
        fill=WALKABLE,
    )

    # Keep gate threshold / interior transition area.
    draw.rectangle((962, 388, 1112, 500), fill=TRANSITION)

    # Left/right causeway side towers/landings that are potentially walkable.
    draw.polygon(
        [
            (818, 805),
            (918, 760),
            (918, 930),
            (810, 930),
            (760, 875),
        ],
        fill=WALKABLE,
    )
    draw.polygon(
        [
            (1144, 750),
            (1262, 800),
            (1292, 905),
            (1192, 952),
            (1144, 925),
        ],
        fill=WALKABLE,
    )

    # Right-side cliff stair / switchback access to the shoreline.
    # Thick lines make a rough walkable ribbon over the visible stair route.
    stair_points = [
        (1502, 382),
        (1445, 462),
        (1518, 535),
        (1414, 625),
        (1492, 713),
        (1375, 822),
        (1450, 900),
    ]
    try:
        draw.line(stair_points, fill=WALKABLE, width=58, joint="curve")
    except TypeError:
        draw.line(stair_points, fill=WALKABLE, width=58)

    # Lower right shore / gravel approach.
    draw.polygon(
        [
            (1410, 570),
            (1695, 560),
            (1850, 650),
            (1888, 775),
            (1800, 930),
            (1608, 1000),
            (1412, 945),
            (1312, 820),
            (1315, 665),
        ],
        fill=WALKABLE,
    )

    # Shoreline hoist / interactable marker candidate.
    draw.ellipse((1510, 860, 1570, 920), fill=INTERACTABLE)

    # Exit / front-gate transition strip at the upper gate.
    draw.rectangle((986, 398, 1084, 455), fill=TRANSITION)


def draw_blockers(draw: ImageDraw.ImageDraw) -> None:
    """
    Rough blockers for castle mass, parapets, and hard scenery.

    These are broad first-pass regions. Green walkable and blue transitions
    are painted after blockers, so they override this where needed.
    """

    blocker_polys = [
        # Big upper keep/wall mass.
        [
            (300, 95),
            (640, 165),
            (650, 350),
            (825, 350),
            (835, 168),
            (1380, 25),
            (1400, 310),
            (1845, 110),
            (1928, 445),
            (1210, 455),
            (1180, 625),
            (850, 625),
            (850, 430),
            (300, 430),
        ],
        # Left fortress wall block.
        [
            (270, 80),
            (650, 160),
            (650, 520),
            (300, 520),
            (300, 380),
            (250, 350),
        ],
        # Right fortress wall block.
        [
            (1210, 95),
            (1935, 115),
            (1935, 470),
            (1350, 470),
            (1320, 340),
            (1210, 330),
        ],
        # Central gate/wall mass above the walkable landing.
        [
            (825, 110),
            (1400, 35),
            (1398, 450),
            (1120, 450),
            (1100, 390),
            (970, 390),
            (945, 455),
            (825, 455),
        ],
        # Left cliff hard edge under walls.
        [
            (350, 440),
            (800, 440),
            (850, 620),
            (760, 820),
            (590, 1045),
            (470, 1010),
            (370, 740),
        ],
        # Right cliff mass around stairs.
        [
            (1280, 410),
            (1510, 360),
            (1555, 570),
            (1420, 705),
            (1510, 885),
            (1340, 980),
            (1195, 900),
            (1225, 620),
        ],
    ]

    draw_polygons(draw, blocker_polys, BLOCKER)


def draw_grid_preview(preview: Image.Image, tile_size: int) -> None:
    draw = ImageDraw.Draw(preview, "RGBA")
    w, h = preview.size

    for x in range(0, w + 1, tile_size):
        alpha = 95 if x % (tile_size * 4) == 0 else 45
        draw.line((x, 0, x, h), fill=(255, 255, 255, alpha), width=1)

    for y in range(0, h + 1, tile_size):
        alpha = 95 if y % (tile_size * 4) == 0 else 45
        draw.line((0, y, w, y), fill=(255, 255, 255, alpha), width=1)


def make_preview(
    src: Image.Image, mask: Image.Image, tile_size: int, show_grid: bool
) -> Image.Image:
    preview = src.convert("RGBA")
    overlay = Image.new("RGBA", src.size, (0, 0, 0, 0))

    mask_px = mask.load()
    overlay_px = overlay.load()
    w, h = src.size

    alpha_by_color = {
        WALKABLE: 120,
        BLOCKER: 95,
        TRANSITION: 150,
        HAZARD: 90,
        INTERACTABLE: 180,
    }

    for y in range(h):
        for x in range(w):
            color = mask_px[x, y]
            if color == IGNORED:
                continue
            a = alpha_by_color.get(color, 110)
            overlay_px[x, y] = (color[0], color[1], color[2], a)

    preview = Image.alpha_composite(preview, overlay)

    if show_grid:
        draw_grid_preview(preview, tile_size)

    return preview


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "image",
        type=Path,
        help="Source causeway approach background PNG.",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("causeway_approach_logic_mask.png"),
        help="Output flat-color logic mask PNG.",
    )
    parser.add_argument(
        "--preview",
        type=Path,
        default=Path("causeway_approach_logic_mask_preview.png"),
        help="Output preview PNG with mask over source.",
    )
    parser.add_argument(
        "--normalized-bg",
        type=Path,
        default=Path("causeway_approach_background_grid.png"),
        help="Output padded grid-aligned background PNG.",
    )
    parser.add_argument(
        "--tile-size",
        type=int,
        default=32,
        help="Tile size in pixels.",
    )
    parser.add_argument(
        "--no-auto-water",
        action="store_true",
        help="Disable automatic yellow water/hazard pass.",
    )
    parser.add_argument(
        "--no-grid-preview",
        action="store_true",
        help="Do not draw 32px grid on preview.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not args.image.exists():
        raise SystemExit(f"missing image: {args.image}")

    src_raw = Image.open(args.image).convert("RGBA")
    src = normalize_to_grid(src_raw, args.tile_size)

    if src.size != src_raw.size:
        print(
            f"padded source from {src_raw.size} to {src.size} for {args.tile_size}px grid alignment"
        )

    mask = Image.new("RGBA", src.size, IGNORED)

    if not args.no_auto_water:
        paint_auto_water_hazards(src, mask)

    draw = ImageDraw.Draw(mask, "RGBA")

    # Draw order matters:
    # hazard auto-pass first, blockers second, authored playable/markers last.
    draw_blockers(draw)
    draw_walkable_route(draw)

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
    print(f"  mask:        {args.out} {mask.size}")
    print(f"  preview:     {args.preview} {preview.size}")
    print(f"  background:  {args.normalized_bg} {src.size}")
    print(
        f"grid: {src.size[0] // args.tile_size} x {src.size[1] // args.tile_size} tiles"
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
