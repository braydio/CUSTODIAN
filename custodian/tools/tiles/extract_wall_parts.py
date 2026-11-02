#!/usr/bin/env python3
"""Extract wall modules from an RGBA source sheet and pack a simple atlas."""

from __future__ import annotations

import argparse
import json
import math
from collections import deque
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image


DEFAULT_TILE_SIZE = 32
DEFAULT_PADDING = 2
DEFAULT_ALPHA_THRESHOLD = 1
DEFAULT_MIN_AREA = 64
DEFAULT_ATLAS_WIDTH = 1024


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Source RGBA wall sheet.")
    parser.add_argument("--out-dir", required=True, type=Path, help="Directory for individual part PNGs.")
    parser.add_argument("--atlas-out", required=True, type=Path, help="Output atlas PNG path.")
    parser.add_argument("--json-out", required=True, type=Path, help="Output metadata JSON path.")
    parser.add_argument("--rects", type=Path, help="Optional manual rectangle JSON override.")
    parser.add_argument("--tile-size", type=int, default=DEFAULT_TILE_SIZE, help="Tile size for metadata guesses.")
    parser.add_argument("--padding", type=int, default=DEFAULT_PADDING, help="Transparent padding around each part.")
    parser.add_argument("--alpha-threshold", type=int, default=DEFAULT_ALPHA_THRESHOLD, help="Minimum alpha to keep.")
    parser.add_argument("--min-area", type=int, default=DEFAULT_MIN_AREA, help="Minimum component pixel area.")
    parser.add_argument("--atlas-width", type=int, default=DEFAULT_ATLAS_WIDTH, help="Packed atlas max row width.")
    return parser.parse_args()


def find_components(img: Image.Image, alpha_threshold: int, min_area: int) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    alpha = img.getchannel("A")
    width, height = img.size
    pix = alpha.load()
    seen = bytearray(width * height)
    components: list[dict[str, Any]] = []
    skipped: list[dict[str, Any]] = []

    for y in range(height):
        row_offset = y * width
        for x in range(width):
            idx = row_offset + x
            if seen[idx] or pix[x, y] < alpha_threshold:
                continue

            q: deque[tuple[int, int]] = deque([(x, y)])
            seen[idx] = 1
            min_x = max_x = x
            min_y = max_y = y
            area = 0

            while q:
                cx, cy = q.popleft()
                area += 1
                if cx < min_x:
                    min_x = cx
                if cx > max_x:
                    max_x = cx
                if cy < min_y:
                    min_y = cy
                if cy > max_y:
                    max_y = cy

                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    nidx = ny * width + nx
                    if seen[nidx] or pix[nx, ny] < alpha_threshold:
                        continue
                    seen[nidx] = 1
                    q.append((nx, ny))

            rect = [min_x, min_y, max_x - min_x + 1, max_y - min_y + 1]
            target = components if area >= min_area else skipped
            target.append({"source_rect": rect, "area": area})

    components.sort(key=lambda item: (item["source_rect"][1], item["source_rect"][0]))
    skipped.sort(key=lambda item: item["area"], reverse=True)
    return components, skipped


def load_manual_rects(path: Path, fallback_tile_size: int) -> tuple[int, list[dict[str, Any]]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    tile_size = int(data.get("tile_size", fallback_tile_size))
    parts = []
    for index, raw in enumerate(data.get("parts", [])):
        rect = raw.get("rect")
        if not isinstance(rect, list) or len(rect) != 4:
            raise ValueError(f"Manual part {index} must include rect [x, y, w, h].")
        parts.append(
            {
                "id": raw.get("id", f"wall_part_{index:03d}"),
                "source_rect": [int(value) for value in rect],
                "kind": raw.get("kind"),
                "tags": list(raw.get("tags", [])),
                "anchor": raw.get("anchor", "bottom_left"),
                "area": int(rect[2]) * int(rect[3]),
            }
        )
    return tile_size, parts


def classify(width_px: int, height_px: int, tile_size: int) -> tuple[str, list[int]]:
    width_tiles = max(1, math.ceil(width_px / tile_size))
    height_tiles = max(1, math.ceil(height_px / tile_size))
    aspect_ratio = width_px / max(1, height_px)
    aspect_delta = abs(width_px - height_px) / max(width_px, height_px)

    if width_tiles >= 5 and (height_tiles <= 3 or aspect_ratio >= 1.7):
        kind = "long_straight"
    elif 3 <= width_tiles < 5:
        kind = "medium_straight"
    elif width_tiles <= 2 and height_tiles <= 3:
        kind = "short_straight"
    elif height_tiles > width_tiles and width_tiles <= 2:
        kind = "vertical_end_or_pillar"
    elif aspect_delta <= 0.25 and width_tiles >= 3 and height_tiles >= 3:
        kind = "corner_or_block"
    else:
        kind = "unclassified"

    return kind, [width_tiles, height_tiles]


def crop_with_padding(img: Image.Image, rect: list[int], padding: int) -> Image.Image:
    x, y, width, height = rect
    crop = img.crop((x, y, x + width, y + height))
    if padding <= 0:
        return crop
    padded = Image.new("RGBA", (width + padding * 2, height + padding * 2), (0, 0, 0, 0))
    padded.alpha_composite(crop, (padding, padding))
    return padded


def pack_parts(parts: list[dict[str, Any]], atlas_width: int, spacing: int) -> tuple[Image.Image, list[dict[str, Any]]]:
    x = 0
    y = 0
    row_height = 0
    packed: list[dict[str, Any]] = []

    for part in parts:
        image: Image.Image = part["image"]
        width, height = image.size
        if x > 0 and x + width > atlas_width:
            x = 0
            y += row_height + spacing
            row_height = 0
        part["atlas_rect"] = [x, y, width, height]
        packed.append(part)
        x += width + spacing
        row_height = max(row_height, height)

    atlas_height = max(1, y + row_height)
    atlas = Image.new("RGBA", (atlas_width, atlas_height), (0, 0, 0, 0))
    for part in packed:
        atlas.alpha_composite(part["image"], tuple(part["atlas_rect"][:2]))
    return atlas, packed


def has_useful_transparency(img: Image.Image) -> bool:
    alpha = img.getchannel("A")
    return alpha.getextrema()[0] < 255


def write_outputs(args: argparse.Namespace) -> None:
    src = Image.open(args.input).convert("RGBA")
    tile_size = args.tile_size

    if args.rects:
        tile_size, component_records = load_manual_rects(args.rects, args.tile_size)
        skipped_components: list[dict[str, Any]] = []
        extraction_mode = "manual_rects"
    else:
        if not has_useful_transparency(src):
            raise SystemExit(
                "Source has no transparent pixels. Provide --rects with manual crop rectangles for this sheet."
            )
        component_records, skipped_components = find_components(src, args.alpha_threshold, args.min_area)
        extraction_mode = "alpha_components"

    args.out_dir.mkdir(parents=True, exist_ok=True)
    args.atlas_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.parent.mkdir(parents=True, exist_ok=True)

    parts: list[dict[str, Any]] = []
    for index, component in enumerate(component_records):
        rect = component["source_rect"]
        part_id = component.get("id", f"wall_part_{index:03d}")
        image = crop_with_padding(src, rect, args.padding)
        output_name = f"{part_id}.png"
        output_path = args.out_dir / output_name
        image.save(output_path)

        guessed_kind, size_tiles_guess = classify(rect[2], rect[3], tile_size)
        kind = component.get("kind") or guessed_kind
        part = {
            "id": part_id,
            "kind": kind,
            "source_rect": rect,
            "atlas_rect": [0, 0, image.size[0], image.size[1]],
            "size_px": [image.size[0], image.size[1]],
            "size_tiles_guess": size_tiles_guess,
            "tags": component.get("tags", []),
            "anchor": component.get("anchor", "bottom_left"),
            "file": str(output_path.as_posix()),
            "area": component.get("area", rect[2] * rect[3]),
            "image": image,
        }
        parts.append(part)

    atlas, packed_parts = pack_parts(parts, args.atlas_width, args.padding)
    atlas.save(args.atlas_out)

    serializable_parts = []
    for part in packed_parts:
        clean = dict(part)
        clean.pop("image")
        serializable_parts.append(clean)

    metadata = {
        "schema": "custodian.wall_parts.v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source": str(args.input.as_posix()),
        "extraction_mode": extraction_mode,
        "tile_size": tile_size,
        "padding": args.padding,
        "alpha_threshold": args.alpha_threshold,
        "min_area": args.min_area,
        "atlas": str(args.atlas_out.as_posix()),
        "parts_dir": str(args.out_dir.as_posix()),
        "parts": serializable_parts,
        "skipped_components": skipped_components,
    }
    args.json_out.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")

    print(f"Extracted {len(serializable_parts)} parts")
    print(f"Skipped {len(skipped_components)} tiny components")
    print(f"Wrote {args.atlas_out}")
    print(f"Wrote {args.json_out}")


def main() -> None:
    args = parse_args()
    write_outputs(args)


if __name__ == "__main__":
    main()
