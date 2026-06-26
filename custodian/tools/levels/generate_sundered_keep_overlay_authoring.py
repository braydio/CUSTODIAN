#!/usr/bin/env python3
"""
Generate deterministic tile-space authoring guides from the Sundered Keep overlay image.

This is an authoring/review pipeline. It does not change runtime traversal or collision
authority by itself; it produces JSON guidance that can be reviewed against the live map.
"""

from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path
from typing import Any

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_TEXTURE_PATH = ROOT / "custodian/content/masters/sundered_keep/sundered_keep_main_overlay.png"
DEFAULT_OUTPUT_PATH = ROOT / "custodian/content/levels/sundered_keep/sundered_keep_overlay_authoring.json"
DEFAULT_TEXTURE_RESOURCE_PATH = "res://content/masters/sundered_keep/sundered_keep_main_overlay.png"
DEFAULT_RECT_TILES = (0, 0, 112, 80)
SCHEMA = "custodian.sundered_keep.overlay_authoring_mask.v1"
GENERATOR = "custodian/tools/levels/generate_sundered_keep_overlay_authoring.py"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate tile-space authoring guides from the Sundered Keep overlay image."
    )
    parser.add_argument(
        "--texture",
        type=Path,
        default=DEFAULT_TEXTURE_PATH,
        help="Overlay PNG to analyze.",
    )
    parser.add_argument(
        "--texture-resource-path",
        type=str,
        default=DEFAULT_TEXTURE_RESOURCE_PATH,
        help="res:// path recorded in the generated JSON.",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help="Output JSON path.",
    )
    parser.add_argument(
        "--rect-tiles",
        type=int,
        nargs=4,
        metavar=("X", "Y", "W", "H"),
        default=DEFAULT_RECT_TILES,
        help="Tile rect the overlay occupies in the authored level.",
    )
    parser.add_argument(
        "--alpha-threshold",
        type=int,
        default=16,
        help="Alpha threshold used when deciding whether a source pixel counts as solid.",
    )
    parser.add_argument(
        "--coverage-threshold",
        type=float,
        default=0.10,
        help="Fraction of solid pixels required for a tile to count as part of the keep footprint.",
    )
    parser.add_argument(
        "--min-solid-component-tiles",
        type=int,
        default=8,
        help="Discard solid components smaller than this many tiles as noise.",
    )
    parser.add_argument(
        "--min-void-component-tiles",
        type=int,
        default=4,
        help="Discard enclosed-void components smaller than this many tiles as noise.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    texture_path = args.texture.expanduser().resolve()
    out_path = args.out.expanduser().resolve()
    rect_tiles = tuple(args.rect_tiles)

    if not texture_path.exists():
        print(f"ERROR: missing overlay texture: {texture_path}")
        return 2

    image = Image.open(texture_path).convert("RGBA")
    solid_mask = build_solid_mask(
        image=image,
        grid_width=rect_tiles[2],
        grid_height=rect_tiles[3],
        alpha_threshold=args.alpha_threshold,
        coverage_threshold=args.coverage_threshold,
    )
    solid_components = connected_components(solid_mask)
    solid_mask = filter_mask_by_component_size(solid_mask, solid_components, args.min_solid_component_tiles)

    void_mask = invert_mask(solid_mask)
    void_components = connected_components(void_mask)
    border_void_mask, enclosed_void_mask = classify_void_components(
        void_mask,
        void_components,
        min_component_tiles=args.min_void_component_tiles,
    )

    solid_components = connected_components(solid_mask)
    border_void_components = connected_components(border_void_mask)
    enclosed_void_components = connected_components(enclosed_void_mask)

    solid_spans = mask_to_spans(solid_mask, rect_tiles[0], rect_tiles[1])
    border_void_spans = mask_to_spans(border_void_mask, rect_tiles[0], rect_tiles[1])
    enclosed_void_spans = mask_to_spans(enclosed_void_mask, rect_tiles[0], rect_tiles[1])

    solid_rects = spans_to_rects(solid_spans)
    border_void_rects = spans_to_rects(border_void_spans)
    enclosed_void_rects = spans_to_rects(enclosed_void_spans)

    solid_tiles = count_mask_tiles(solid_mask)
    border_void_tiles = count_mask_tiles(border_void_mask)
    enclosed_void_tiles = count_mask_tiles(enclosed_void_mask)

    largest_solid = largest_component(solid_components)
    centroid = component_centroid(largest_solid, rect_tiles[0], rect_tiles[1])

    payload: dict[str, Any] = {
        "schema": SCHEMA,
        "generator": GENERATOR,
        "source_texture_path": args.texture_resource_path,
        "source_image_size_px": [image.width, image.height],
        "tile_rect": list(rect_tiles),
        "grid_size_tiles": [rect_tiles[2], rect_tiles[3]],
        "thresholds": {
            "alpha_threshold": args.alpha_threshold,
            "coverage_threshold": args.coverage_threshold,
            "min_solid_component_tiles": args.min_solid_component_tiles,
            "min_void_component_tiles": args.min_void_component_tiles,
        },
        "stats": {
            "solid_tiles": solid_tiles,
            "border_void_tiles": border_void_tiles,
            "enclosed_void_tiles": enclosed_void_tiles,
            "solid_components": len(solid_components),
            "border_void_components": len(border_void_components),
            "enclosed_void_components": len(enclosed_void_components),
            "solid_rects": len(solid_rects),
            "border_void_rects": len(border_void_rects),
            "enclosed_void_rects": len(enclosed_void_rects),
        },
        "anchors": {
            "largest_solid_component_centroid_tile": centroid,
        },
        "suggested_floor_spans": solid_spans,
        "suggested_floor_rects": solid_rects,
        "suggested_border_void_spans": border_void_spans,
        "suggested_border_void_rects": border_void_rects,
        "suggested_enclosed_void_spans": enclosed_void_spans,
        "suggested_enclosed_void_rects": enclosed_void_rects,
    }

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")

    print("Sundered Keep overlay authoring generated")
    print(f"texture={texture_path}")
    print(f"out={out_path}")
    print(
        "solid_tiles=%d border_void_tiles=%d enclosed_void_tiles=%d solid_rects=%d"
        % (solid_tiles, border_void_tiles, enclosed_void_tiles, len(solid_rects))
    )
    return 0


def build_solid_mask(
    image: Image.Image,
    grid_width: int,
    grid_height: int,
    alpha_threshold: int,
    coverage_threshold: float,
) -> list[list[bool]]:
    alpha = image.getchannel("A")
    mask: list[list[bool]] = []
    for tile_y in range(grid_height):
        row: list[bool] = []
        top = int(tile_y * image.height / grid_height)
        bottom = int((tile_y + 1) * image.height / grid_height)
        for tile_x in range(grid_width):
            left = int(tile_x * image.width / grid_width)
            right = int((tile_x + 1) * image.width / grid_width)
            crop = alpha.crop((left, top, max(left + 1, right), max(top + 1, bottom)))
            histogram = crop.histogram()
            solid_pixels = sum(histogram[alpha_threshold:])
            coverage = float(solid_pixels) / float(crop.width * crop.height)
            row.append(coverage >= coverage_threshold)
        mask.append(row)
    return mask


def connected_components(mask: list[list[bool]]) -> list[list[tuple[int, int]]]:
    height = len(mask)
    width = len(mask[0]) if height else 0
    seen = [[False for _ in range(width)] for _ in range(height)]
    components: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            if seen[y][x] or not mask[y][x]:
                continue
            queue: deque[tuple[int, int]] = deque([(x, y)])
            seen[y][x] = True
            component: list[tuple[int, int]] = []
            while queue:
                cx, cy = queue.popleft()
                component.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    if seen[ny][nx] or not mask[ny][nx]:
                        continue
                    seen[ny][nx] = True
                    queue.append((nx, ny))
            components.append(component)
    return components


def filter_mask_by_component_size(
    mask: list[list[bool]],
    components: list[list[tuple[int, int]]],
    min_component_tiles: int,
) -> list[list[bool]]:
    filtered = [[False for _ in row] for row in mask]
    for component in components:
        if len(component) < min_component_tiles:
            continue
        for x, y in component:
            filtered[y][x] = True
    return filtered


def invert_mask(mask: list[list[bool]]) -> list[list[bool]]:
    return [[not value for value in row] for row in mask]


def classify_void_components(
    void_mask: list[list[bool]],
    components: list[list[tuple[int, int]]],
    min_component_tiles: int,
) -> tuple[list[list[bool]], list[list[bool]]]:
    height = len(void_mask)
    width = len(void_mask[0]) if height else 0
    border_void = [[False for _ in range(width)] for _ in range(height)]
    enclosed_void = [[False for _ in range(width)] for _ in range(height)]
    for component in components:
        touches_border = False
        for x, y in component:
            if x == 0 or y == 0 or x == width - 1 or y == height - 1:
                touches_border = True
                break
        if len(component) < min_component_tiles and not touches_border:
            continue
        target = border_void if touches_border else enclosed_void
        for x, y in component:
            target[y][x] = True
    return border_void, enclosed_void


def mask_to_spans(mask: list[list[bool]], offset_x: int, offset_y: int) -> list[list[int]]:
    spans: list[list[int]] = []
    for y, row in enumerate(mask):
        x = 0
        while x < len(row):
            if not row[x]:
                x += 1
                continue
            start = x
            while x < len(row) and row[x]:
                x += 1
            spans.append([offset_x + start, offset_y + y, x - start, 1])
    return spans


def spans_to_rects(spans: list[list[int]]) -> list[list[int]]:
    active: dict[tuple[int, int, int], list[int]] = {}
    rects: list[list[int]] = []
    for span in spans:
        x, y, width, _height = span
        key = (x, width, y)
        if (x, width, y - 1) in active:
            rect = active.pop((x, width, y - 1))
            rect[3] += 1
            active[(x, width, y)] = rect
        else:
            active[(x, width, y)] = [x, y, width, 1]
    rects.extend(active.values())
    rects.sort(key=lambda value: (value[1], value[0], value[2], value[3]))
    return rects


def count_mask_tiles(mask: list[list[bool]]) -> int:
    total = 0
    for row in mask:
        for value in row:
            if value:
                total += 1
    return total


def largest_component(components: list[list[tuple[int, int]]]) -> list[tuple[int, int]]:
    if not components:
        return []
    return max(components, key=len)


def component_centroid(component: list[tuple[int, int]], offset_x: int, offset_y: int) -> list[float]:
    if not component:
        return [0.0, 0.0]
    total_x = 0.0
    total_y = 0.0
    for x, y in component:
        total_x += float(offset_x + x) + 0.5
        total_y += float(offset_y + y) + 0.5
    size = float(len(component))
    return [round(total_x / size, 2), round(total_y / size, 2)]


if __name__ == "__main__":
    raise SystemExit(main())
