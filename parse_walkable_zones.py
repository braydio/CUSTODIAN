#!/usr/bin/env python3
"""
parse_walkable_zones.py

Parse green walkable zones from a masked Sundered Keep / causeway image.

Input:
  A PNG where walkable areas are painted green, either:
    - exact flat #00ff00 mask, or
    - preview/composited green overlay over the background art.

Output:
  JSON containing:
    - walkable_tiles
    - walkable_rects_tiles
    - walkable_rects_px

Also optionally writes:
  - debug pixel mask
  - debug preview with detected tile rects/grid

Recommended first run for a composited preview:
  python3 parse_walkable_zones.py INPUT.png \
    --green-mode threshold \
    --coverage-threshold 0.15 \
    --pad-to-grid \
    --out-json causeway_walkable_zones.json \
    --debug-mask causeway_walkable_mask.png \
    --debug-preview causeway_walkable_preview.png
"""

from __future__ import annotations

import argparse
import json
import math
from collections import deque
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw


SCHEMA = "custodian.sundered_keep.causeway_walkable_mask.v1"

DEBUG_GREEN = (0, 255, 0, 255)
DEBUG_BLACK = (0, 0, 0, 255)
DEBUG_GRID_MINOR = (255, 255, 255, 42)
DEBUG_GRID_MAJOR = (255, 255, 255, 95)
DEBUG_RECT_OUTLINE = (0, 255, 0, 230)
DEBUG_RECT_FILL = (0, 255, 0, 82)


def parse_hex_color(value: str) -> tuple[int, int, int]:
    value = value.strip().lower()
    if value.startswith("#"):
        value = value[1:]
    if len(value) != 6:
        raise argparse.ArgumentTypeError(f"Expected 6-digit hex color, got: {value!r}")
    try:
        return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"Invalid hex color: {value!r}") from exc


def ceil_to_multiple(value: int, multiple: int) -> int:
    return int(math.ceil(float(value) / float(multiple)) * multiple)


def normalize_to_grid(image: Image.Image, tile_size: int, pad_to_grid: bool) -> Image.Image:
    image = image.convert("RGBA")
    if not pad_to_grid:
        return image

    width, height = image.size
    out_width = ceil_to_multiple(width, tile_size)
    out_height = ceil_to_multiple(height, tile_size)

    if (out_width, out_height) == (width, height):
        return image

    canvas = Image.new("RGBA", (out_width, out_height), DEBUG_BLACK)
    canvas.alpha_composite(image, (0, 0))
    return canvas


def is_green_exact(
    r: int,
    g: int,
    b: int,
    a: int,
    exact_color: tuple[int, int, int],
    tolerance: int,
    alpha_min: int,
) -> bool:
    if a < alpha_min:
        return False

    er, eg, eb = exact_color
    return (
        abs(r - er) <= tolerance
        and abs(g - eg) <= tolerance
        and abs(b - eb) <= tolerance
    )


def is_green_threshold(
    r: int,
    g: int,
    b: int,
    a: int,
    min_green: int,
    green_margin: int,
    alpha_min: int,
) -> bool:
    """
    Detect green overlay in a composited screenshot.

    This works when your walkable area is green-tinted over dark art, not only
    pure #00ff00.
    """
    if a < alpha_min:
        return False

    if g < min_green:
        return False

    if g < r + green_margin:
        return False

    if g < b + green_margin:
        return False

    return True


def build_pixel_mask(
    image: Image.Image,
    green_mode: str,
    exact_color: tuple[int, int, int],
    exact_tolerance: int,
    min_green: int,
    green_margin: int,
    alpha_min: int,
) -> list[list[bool]]:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size

    mask: list[list[bool]] = []

    for y in range(height):
        row: list[bool] = []
        for x in range(width):
            r, g, b, a = pixels[x, y]

            if green_mode == "exact":
                row.append(is_green_exact(r, g, b, a, exact_color, exact_tolerance, alpha_min))
            elif green_mode == "threshold":
                row.append(is_green_threshold(r, g, b, a, min_green, green_margin, alpha_min))
            else:
                raise ValueError(f"Unsupported green mode: {green_mode}")

        mask.append(row)

    return mask


def build_tile_mask(
    pixel_mask: list[list[bool]],
    image_width: int,
    image_height: int,
    tile_size: int,
    coverage_threshold: float,
) -> list[list[bool]]:
    grid_width = image_width // tile_size
    grid_height = image_height // tile_size

    tile_mask: list[list[bool]] = []

    for tile_y in range(grid_height):
        row: list[bool] = []

        y0 = tile_y * tile_size
        y1 = min(y0 + tile_size, image_height)

        for tile_x in range(grid_width):
            x0 = tile_x * tile_size
            x1 = min(x0 + tile_size, image_width)

            green_count = 0
            total_count = max(1, (x1 - x0) * (y1 - y0))

            for py in range(y0, y1):
                for px in range(x0, x1):
                    if pixel_mask[py][px]:
                        green_count += 1

            coverage = float(green_count) / float(total_count)
            row.append(coverage >= coverage_threshold)

        tile_mask.append(row)

    return tile_mask


def tile_mask_to_tiles(tile_mask: list[list[bool]]) -> list[list[int]]:
    tiles: list[list[int]] = []

    for y, row in enumerate(tile_mask):
        for x, value in enumerate(row):
            if value:
                tiles.append([x, y])

    return tiles


def spans_from_tile_mask(tile_mask: list[list[bool]]) -> list[tuple[int, int, int]]:
    """
    Convert tile mask to horizontal spans:
      (x, y, width)
    """
    spans: list[tuple[int, int, int]] = []

    for y, row in enumerate(tile_mask):
        x = 0
        while x < len(row):
            if not row[x]:
                x += 1
                continue

            start_x = x
            while x < len(row) and row[x]:
                x += 1

            spans.append((start_x, y, x - start_x))

    return spans


def rects_from_spans(spans: list[tuple[int, int, int]]) -> list[list[int]]:
    """
    Merge horizontal spans vertically when x and width match.

    Output rects:
      [x, y, width, height]
    """
    active: dict[tuple[int, int], list[int]] = {}
    finished: list[list[int]] = []

    spans_by_y: dict[int, list[tuple[int, int, int]]] = {}
    for x, y, width in spans:
        spans_by_y.setdefault(y, []).append((x, y, width))

    for y in sorted(spans_by_y.keys()):
        current_keys: set[tuple[int, int]] = set()

        for x, _span_y, width in spans_by_y[y]:
            key = (x, width)
            current_keys.add(key)

            if key in active:
                rect = active[key]
                expected_next_y = rect[1] + rect[3]
                if expected_next_y == y:
                    rect[3] += 1
                else:
                    finished.append(rect)
                    active[key] = [x, y, width, 1]
            else:
                active[key] = [x, y, width, 1]

        stale_keys: list[tuple[int, int]] = []
        for key, rect in active.items():
            last_y_covered = rect[1] + rect[3] - 1
            if key not in current_keys and last_y_covered < y:
                finished.append(rect)
                stale_keys.append(key)

        for key in stale_keys:
            del active[key]

    finished.extend(active.values())
    finished.sort(key=lambda r: (r[1], r[0], r[3], r[2]))

    return finished


def tile_rects_to_px_rects(rects: list[list[int]], tile_size: int) -> list[list[int]]:
    return [
        [x * tile_size, y * tile_size, width * tile_size, height * tile_size]
        for x, y, width, height in rects
    ]


def connected_components(tile_mask: list[list[bool]]) -> list[list[list[int]]]:
    """
    Return connected components of walkable tiles using 4-way adjacency.

    Each component is:
      [[x, y], [x, y], ...]
    """
    height = len(tile_mask)
    width = len(tile_mask[0]) if height else 0

    seen = [[False for _ in range(width)] for _ in range(height)]
    components: list[list[list[int]]] = []

    for y in range(height):
        for x in range(width):
            if seen[y][x] or not tile_mask[y][x]:
                continue

            queue: deque[tuple[int, int]] = deque([(x, y)])
            seen[y][x] = True
            component: list[list[int]] = []

            while queue:
                cx, cy = queue.popleft()
                component.append([cx, cy])

                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    if seen[ny][nx] or not tile_mask[ny][nx]:
                        continue

                    seen[ny][nx] = True
                    queue.append((nx, ny))

            components.append(component)

    components.sort(key=len, reverse=True)
    return components


def component_bounds(component: list[list[int]]) -> list[int]:
    xs = [tile[0] for tile in component]
    ys = [tile[1] for tile in component]

    min_x = min(xs)
    min_y = min(ys)
    max_x = max(xs)
    max_y = max(ys)

    return [min_x, min_y, max_x - min_x + 1, max_y - min_y + 1]


def draw_debug_pixel_mask(pixel_mask: list[list[bool]]) -> Image.Image:
    height = len(pixel_mask)
    width = len(pixel_mask[0]) if height else 0

    out = Image.new("RGBA", (width, height), DEBUG_BLACK)
    px = out.load()

    for y in range(height):
        for x in range(width):
            if pixel_mask[y][x]:
                px[x, y] = DEBUG_GREEN

    return out


def draw_grid(draw: ImageDraw.ImageDraw, width: int, height: int, tile_size: int) -> None:
    for x in range(0, width + 1, tile_size):
        color = DEBUG_GRID_MAJOR if x % (tile_size * 4) == 0 else DEBUG_GRID_MINOR
        draw.line((x, 0, x, height), fill=color, width=1)

    for y in range(0, height + 1, tile_size):
        color = DEBUG_GRID_MAJOR if y % (tile_size * 4) == 0 else DEBUG_GRID_MINOR
        draw.line((0, y, width, y), fill=color, width=1)


def draw_debug_preview(
    source: Image.Image,
    tile_mask: list[list[bool]],
    rects_px: list[list[int]],
    tile_size: int,
    show_grid: bool,
) -> Image.Image:
    preview = source.convert("RGBA")
    overlay = Image.new("RGBA", preview.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")

    grid_height = len(tile_mask)
    grid_width = len(tile_mask[0]) if grid_height else 0

    # Fill detected walkable tiles.
    for tile_y in range(grid_height):
        for tile_x in range(grid_width):
            if not tile_mask[tile_y][tile_x]:
                continue

            x0 = tile_x * tile_size
            y0 = tile_y * tile_size
            x1 = x0 + tile_size
            y1 = y0 + tile_size
            draw.rectangle((x0, y0, x1, y1), fill=DEBUG_RECT_FILL)

    # Draw merged rect outlines.
    for x, y, width, height in rects_px:
        draw.rectangle(
            (x, y, x + width, y + height),
            outline=DEBUG_RECT_OUTLINE,
            width=2,
        )

    preview = Image.alpha_composite(preview, overlay)

    if show_grid:
        draw = ImageDraw.Draw(preview, "RGBA")
        draw_grid(draw, preview.width, preview.height, tile_size)

    return preview


def write_json(
    out_path: Path,
    source_path: Path,
    original_size: tuple[int, int],
    padded_size: tuple[int, int],
    tile_size: int,
    green_mode: str,
    exact_color: tuple[int, int, int],
    exact_tolerance: int,
    min_green: int,
    green_margin: int,
    alpha_min: int,
    coverage_threshold: float,
    walkable_tiles: list[list[int]],
    rects_tiles: list[list[int]],
    rects_px: list[list[int]],
    components: list[list[list[int]]],
) -> None:
    component_payload: list[dict[str, Any]] = []
    for index, component in enumerate(components):
        component_payload.append(
            {
                "id": index,
                "tile_count": len(component),
                "bounds_tiles": component_bounds(component),
            }
        )

    payload: dict[str, Any] = {
        "schema": SCHEMA,
        "source_image_path": str(source_path),
        "source_image_size_px": list(original_size),
        "padded_image_size_px": list(padded_size),
        "tile_size": tile_size,
        "grid_size_tiles": [padded_size[0] // tile_size, padded_size[1] // tile_size],
        "detection": {
            "green_mode": green_mode,
            "exact_color": "#%02x%02x%02x" % exact_color,
            "exact_tolerance": exact_tolerance,
            "min_green": min_green,
            "green_margin": green_margin,
            "alpha_min": alpha_min,
            "coverage_threshold": coverage_threshold,
        },
        "stats": {
            "walkable_tile_count": len(walkable_tiles),
            "walkable_rect_count": len(rects_tiles),
            "component_count": len(components),
        },
        "walkable_tiles": walkable_tiles,
        "walkable_rects_tiles": rects_tiles,
        "walkable_rects_px": rects_px,
        "components": component_payload,
    }

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Parse green walkable areas from a masked image into tile rect JSON."
    )

    parser.add_argument(
        "image",
        type=Path,
        help="Input PNG with green walkable mask/overlay.",
    )

    parser.add_argument(
        "--out-json",
        type=Path,
        default=Path("causeway_walkable_zones.json"),
        help="Output JSON path.",
    )

    parser.add_argument(
        "--debug-mask",
        type=Path,
        default=None,
        help="Optional debug pixel mask PNG path.",
    )

    parser.add_argument(
        "--debug-preview",
        type=Path,
        default=None,
        help="Optional debug preview PNG path.",
    )

    parser.add_argument(
        "--tile-size",
        type=int,
        default=32,
        help="Tile size in pixels.",
    )

    parser.add_argument(
        "--coverage-threshold",
        type=float,
        default=0.15,
        help="Fraction of a tile that must be green to count as walkable.",
    )

    parser.add_argument(
        "--green-mode",
        choices=("threshold", "exact"),
        default="threshold",
        help="Use threshold for composited preview overlays; exact for clean flat masks.",
    )

    parser.add_argument(
        "--exact-color",
        type=parse_hex_color,
        default=(0, 255, 0),
        help="Exact mask color for --green-mode exact. Default: #00ff00.",
    )

    parser.add_argument(
        "--exact-tolerance",
        type=int,
        default=0,
        help="RGB tolerance for --green-mode exact.",
    )

    parser.add_argument(
        "--min-green",
        type=int,
        default=70,
        help="Minimum green channel for --green-mode threshold.",
    )

    parser.add_argument(
        "--green-margin",
        type=int,
        default=30,
        help="Green must exceed red/blue by this margin in threshold mode.",
    )

    parser.add_argument(
        "--alpha-min",
        type=int,
        default=16,
        help="Minimum alpha channel to consider a pixel.",
    )

    parser.add_argument(
        "--pad-to-grid",
        action="store_true",
        help="Pad image dimensions up to a multiple of tile size.",
    )

    parser.add_argument(
        "--no-grid-preview",
        action="store_true",
        help="Do not draw a tile grid on the debug preview.",
    )

    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if args.tile_size <= 0:
        raise SystemExit("--tile-size must be positive")

    if not (0.0 < args.coverage_threshold <= 1.0):
        raise SystemExit("--coverage-threshold must be between 0 and 1")

    if not args.image.exists():
        raise SystemExit(f"missing input image: {args.image}")

    raw = Image.open(args.image).convert("RGBA")
    original_size = raw.size

    image = normalize_to_grid(raw, args.tile_size, args.pad_to_grid)
    padded_size = image.size

    if padded_size[0] % args.tile_size != 0 or padded_size[1] % args.tile_size != 0:
        raise SystemExit(
            "image dimensions are not divisible by tile size. "
            "Use --pad-to-grid or provide a grid-aligned image. "
            f"image={padded_size}, tile_size={args.tile_size}"
        )

    pixel_mask = build_pixel_mask(
        image=image,
        green_mode=args.green_mode,
        exact_color=args.exact_color,
        exact_tolerance=args.exact_tolerance,
        min_green=args.min_green,
        green_margin=args.green_margin,
        alpha_min=args.alpha_min,
    )

    tile_mask = build_tile_mask(
        pixel_mask=pixel_mask,
        image_width=image.width,
        image_height=image.height,
        tile_size=args.tile_size,
        coverage_threshold=args.coverage_threshold,
    )

    walkable_tiles = tile_mask_to_tiles(tile_mask)
    spans = spans_from_tile_mask(tile_mask)
    rects_tiles = rects_from_spans(spans)
    rects_px = tile_rects_to_px_rects(rects_tiles, args.tile_size)
    components = connected_components(tile_mask)

    write_json(
        out_path=args.out_json,
        source_path=args.image,
        original_size=original_size,
        padded_size=padded_size,
        tile_size=args.tile_size,
        green_mode=args.green_mode,
        exact_color=args.exact_color,
        exact_tolerance=args.exact_tolerance,
        min_green=args.min_green,
        green_margin=args.green_margin,
        alpha_min=args.alpha_min,
        coverage_threshold=args.coverage_threshold,
        walkable_tiles=walkable_tiles,
        rects_tiles=rects_tiles,
        rects_px=rects_px,
        components=components,
    )

    if args.debug_mask is not None:
        args.debug_mask.parent.mkdir(parents=True, exist_ok=True)
        draw_debug_pixel_mask(pixel_mask).save(args.debug_mask)

    if args.debug_preview is not None:
        args.debug_preview.parent.mkdir(parents=True, exist_ok=True)
        preview = draw_debug_preview(
            source=image,
            tile_mask=tile_mask,
            rects_px=rects_px,
            tile_size=args.tile_size,
            show_grid=not args.no_grid_preview,
        )
        preview.save(args.debug_preview)

    print("walkable mask parsed")
    print(f"input:                 {args.image}")
    print(f"original_size_px:      {original_size}")
    print(f"processed_size_px:     {padded_size}")
    print(f"tile_size:             {args.tile_size}")
    print(f"grid_size_tiles:       {padded_size[0] // args.tile_size} x {padded_size[1] // args.tile_size}")
    print(f"green_mode:            {args.green_mode}")
    print(f"coverage_threshold:    {args.coverage_threshold}")
    print(f"walkable_tile_count:   {len(walkable_tiles)}")
    print(f"walkable_rect_count:   {len(rects_tiles)}")
    print(f"component_count:       {len(components)}")
    print(f"out_json:              {args.out_json}")

    if args.debug_mask is not None:
        print(f"debug_mask:            {args.debug_mask}")

    if args.debug_preview is not None:
        print(f"debug_preview:         {args.debug_preview}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
