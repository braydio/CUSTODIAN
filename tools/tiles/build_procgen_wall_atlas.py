#!/usr/bin/env python3
"""Build a fixed-grid procgen wall atlas from extracted variable-size wall parts."""

from __future__ import annotations

import argparse
import json
import math
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image


DEFAULT_TILE_SIZE = 32
DEFAULT_COLUMNS = 16

BUCKETS = [
    "reference_horizontal_wall_coords",
    "reference_horizontal_hole_bottom_coords",
    "reference_open_left_wall_coords",
    "reference_open_right_wall_coords",
    "reference_left_terminal_coords",
    "reference_right_terminal_coords",
    "reference_vertical_wall_coords",
    "reference_top_terminal_coords",
    "reference_bottom_terminal_coords",
    "reference_northwest_corner_coords",
    "reference_northeast_corner_coords",
    "reference_southwest_corner_coords",
    "reference_southeast_corner_coords",
    "reference_cross_fallback_coords",
    "reference_damaged_wall_coords",
    "reference_moss_wall_coords",
    "reference_rubble_wall_coords",
    # Exact names used by the current ProcGenTilemap exported arrays.
    "reference_north_west_corner_coords",
    "reference_north_east_corner_coords",
    "reference_open_left_corner_coords",
    "reference_open_left_t_coords",
    "reference_open_left_hole_coords",
    "reference_open_right_corner_coords",
    "reference_open_right_t_coords",
    "reference_open_right_hole_coords",
    "reference_cross_wall_coords",
    "reference_cross_hole_coords",
    "reference_passage_wall_coords",
]

HORIZONTAL_ROLES = {"long_horizontal", "medium_horizontal", "short_horizontal", "horizontal"}
PASSAGE_ROLES = {"passage_horizontal", "passage"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--parts-json", required=True, type=Path, help="Generated wall_parts.json.")
    parser.add_argument("--atlas", required=True, type=Path, help="Generated packed wall_atlas.png.")
    parser.add_argument("--semantics", type=Path, help="Optional curated semantic role JSON.")
    parser.add_argument(
        "--passage-dir",
        type=Path,
        help="Optional directory of 32px-tall passage wall strips to slice directly into passage/hole buckets.",
    )
    parser.add_argument("--out-image", required=True, type=Path, help="Output fixed-grid runtime atlas PNG.")
    parser.add_argument("--out-json", required=True, type=Path, help="Output semantic mapping JSON.")
    parser.add_argument("--tile-size", type=int, default=DEFAULT_TILE_SIZE, help="Square runtime tile size.")
    parser.add_argument("--columns", type=int, default=DEFAULT_COLUMNS, help="Atlas columns.")
    parser.add_argument(
        "--vertical-window",
        choices=["bottom", "top", "center"],
        default="bottom",
        help="How to crop source modules taller than one runtime tile.",
    )
    return parser.parse_args()


def load_metadata(path: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, list):
        return {"schema": "legacy-list"}, data
    return data, list(data.get("parts", []))


def load_semantics(path: Path | None) -> dict[str, Any]:
    if path is None or not path.exists():
        return {"parts": {}}
    return json.loads(path.read_text(encoding="utf-8"))


def crop_part(atlas: Image.Image, part: dict[str, Any]) -> Image.Image:
    x, y, width, height = part["atlas_rect"]
    cropped = atlas.crop((x, y, x + width, y + height))
    bbox = cropped.getchannel("A").getbbox()
    if bbox:
        return cropped.crop(bbox)
    return cropped


def infer_role(part: dict[str, Any], override: dict[str, Any]) -> tuple[str, list[str], bool]:
    if override.get("role"):
        return str(override["role"]), list(override.get("tags", part.get("tags", []))), False

    kind = str(part.get("kind", "unclassified"))
    tags = list(part.get("tags", []))
    source_width = int(part.get("source_rect", [0, 0, 0, 0])[2])
    source_height = int(part.get("source_rect", [0, 0, 0, 0])[3])
    aspect = source_width / max(1, source_height)

    if "long" in kind:
        return "long_horizontal", tags, False
    if "medium" in kind:
        return "medium_horizontal", tags, False
    if "short" in kind and aspect >= 1.0:
        return "short_horizontal", tags, False
    if "vertical" in kind:
        return "vertical", tags, True
    if "corner" in kind:
        return "cross_fallback", tags, True
    return "horizontal" if aspect >= 1.5 else "cross_fallback", tags, True


def vertical_crop_offset(height: int, tile_size: int, mode: str) -> int:
    if height <= tile_size:
        return 0
    if mode == "top":
        return 0
    if mode == "center":
        return int((height - tile_size) / 2)
    return height - tile_size


def slice_part_into_cells(image: Image.Image, tile_size: int, vertical_window: str) -> list[Image.Image]:
    width, height = image.size
    cols = max(1, math.ceil(width / tile_size))
    y0 = vertical_crop_offset(height, tile_size, vertical_window)
    y1 = min(height, y0 + tile_size)
    cells: list[Image.Image] = []

    for col in range(cols):
        x0 = col * tile_size
        crop = image.crop((x0, y0, min(x0 + tile_size, width), y1))
        cell = Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 0))
        paste_x = int((tile_size - crop.size[0]) / 2) if crop.size[0] < tile_size else 0
        paste_y = tile_size - crop.size[1]
        cell.alpha_composite(crop, (paste_x, paste_y))
        cells.append(cell)
    return cells


def load_passage_images(path: Path | None) -> list[tuple[str, Image.Image]]:
    if path is None or not path.exists():
        return []
    images: list[tuple[str, Image.Image]] = []
    for image_path in sorted(path.iterdir()):
        if image_path.suffix.lower() not in {".png", ".webp"}:
            continue
        images.append((image_path.stem, Image.open(image_path).convert("RGBA")))
    return images


def add_unique(bucket_map: dict[str, list[list[int]]], bucket: str, coord: list[int]) -> None:
    if coord not in bucket_map[bucket]:
        bucket_map[bucket].append(coord)


def assign_buckets(
    bucket_map: dict[str, list[list[int]]],
    role: str,
    tags: list[str],
    coord: list[int],
    index: int,
    count: int,
) -> None:
    tag_text = " ".join(tags).lower()
    is_first = index == 0
    is_last = index == count - 1
    is_middle = not is_first and not is_last

    if role in HORIZONTAL_ROLES:
        if count == 1:
            add_unique(bucket_map, "reference_horizontal_wall_coords", coord)
            add_unique(bucket_map, "reference_horizontal_hole_bottom_coords", coord)
            add_unique(bucket_map, "reference_open_left_wall_coords", coord)
            add_unique(bucket_map, "reference_open_right_wall_coords", coord)
        else:
            if is_first:
                add_unique(bucket_map, "reference_left_terminal_coords", coord)
                add_unique(bucket_map, "reference_open_left_wall_coords", coord)
                add_unique(bucket_map, "reference_open_left_corner_coords", coord)
                add_unique(bucket_map, "reference_open_left_t_coords", coord)
            elif is_last:
                add_unique(bucket_map, "reference_right_terminal_coords", coord)
                add_unique(bucket_map, "reference_open_right_wall_coords", coord)
                add_unique(bucket_map, "reference_open_right_corner_coords", coord)
                add_unique(bucket_map, "reference_open_right_t_coords", coord)
            elif is_middle:
                add_unique(bucket_map, "reference_horizontal_wall_coords", coord)
                add_unique(bucket_map, "reference_horizontal_hole_bottom_coords", coord)
        if "damage" in tag_text or "damaged" in tag_text:
            add_unique(bucket_map, "reference_damaged_wall_coords", coord)
        if "moss" in tag_text:
            add_unique(bucket_map, "reference_moss_wall_coords", coord)
        if "rubble" in tag_text:
            add_unique(bucket_map, "reference_rubble_wall_coords", coord)
        return

    if role in PASSAGE_ROLES:
        add_unique(bucket_map, "reference_passage_wall_coords", coord)
        add_unique(bucket_map, "reference_horizontal_hole_bottom_coords", coord)
        add_unique(bucket_map, "reference_open_left_hole_coords", coord)
        add_unique(bucket_map, "reference_open_right_hole_coords", coord)
        add_unique(bucket_map, "reference_cross_hole_coords", coord)
        if is_first:
            add_unique(bucket_map, "reference_left_terminal_coords", coord)
            add_unique(bucket_map, "reference_open_left_wall_coords", coord)
        elif is_last:
            add_unique(bucket_map, "reference_right_terminal_coords", coord)
            add_unique(bucket_map, "reference_open_right_wall_coords", coord)
        else:
            add_unique(bucket_map, "reference_horizontal_wall_coords", coord)
        return

    if role == "left_terminal":
        add_unique(bucket_map, "reference_left_terminal_coords", coord)
        add_unique(bucket_map, "reference_open_left_wall_coords", coord)
        return
    if role == "right_terminal":
        add_unique(bucket_map, "reference_right_terminal_coords", coord)
        add_unique(bucket_map, "reference_open_right_wall_coords", coord)
        return
    if role == "open_left":
        add_unique(bucket_map, "reference_open_left_wall_coords", coord)
        return
    if role == "open_right":
        add_unique(bucket_map, "reference_open_right_wall_coords", coord)
        return
    if role == "vertical":
        add_unique(bucket_map, "reference_vertical_wall_coords", coord)
        add_unique(bucket_map, "reference_top_terminal_coords", coord)
        add_unique(bucket_map, "reference_bottom_terminal_coords", coord)
        return
    if role == "northwest_corner":
        add_unique(bucket_map, "reference_northwest_corner_coords", coord)
        add_unique(bucket_map, "reference_north_west_corner_coords", coord)
        return
    if role == "northeast_corner":
        add_unique(bucket_map, "reference_northeast_corner_coords", coord)
        add_unique(bucket_map, "reference_north_east_corner_coords", coord)
        return
    if role == "southwest_corner":
        add_unique(bucket_map, "reference_southwest_corner_coords", coord)
        return
    if role == "southeast_corner":
        add_unique(bucket_map, "reference_southeast_corner_coords", coord)
        return
    if role in {"cross_fallback", "damaged", "moss", "rubble"}:
        add_unique(bucket_map, "reference_cross_fallback_coords", coord)
        add_unique(bucket_map, "reference_cross_wall_coords", coord)
        if role == "damaged":
            add_unique(bucket_map, "reference_damaged_wall_coords", coord)
        if role == "moss":
            add_unique(bucket_map, "reference_moss_wall_coords", coord)
        if role == "rubble":
            add_unique(bucket_map, "reference_rubble_wall_coords", coord)


def ensure_runtime_fallbacks(bucket_map: dict[str, list[list[int]]]) -> None:
    horizontal = bucket_map["reference_horizontal_wall_coords"]
    left = bucket_map["reference_left_terminal_coords"] or horizontal
    right = bucket_map["reference_right_terminal_coords"] or horizontal
    vertical = bucket_map["reference_vertical_wall_coords"] or left or horizontal
    cross = bucket_map["reference_cross_wall_coords"] or horizontal or left

    fallback_sets = {
        "reference_horizontal_hole_bottom_coords": horizontal,
        "reference_open_left_wall_coords": left,
        "reference_open_left_corner_coords": left,
        "reference_open_left_t_coords": left,
        "reference_open_left_hole_coords": left,
        "reference_open_right_wall_coords": right,
        "reference_open_right_corner_coords": right,
        "reference_open_right_t_coords": right,
        "reference_open_right_hole_coords": right,
        "reference_vertical_wall_coords": vertical,
        "reference_top_terminal_coords": vertical,
        "reference_bottom_terminal_coords": vertical,
        "reference_northwest_corner_coords": cross,
        "reference_northeast_corner_coords": cross,
        "reference_southwest_corner_coords": cross,
        "reference_southeast_corner_coords": cross,
        "reference_north_west_corner_coords": cross,
        "reference_north_east_corner_coords": cross,
        "reference_cross_fallback_coords": cross,
        "reference_cross_wall_coords": cross,
        "reference_cross_hole_coords": cross,
    }
    for bucket, fallback in fallback_sets.items():
        if not bucket_map[bucket]:
            for coord in fallback[:4]:
                add_unique(bucket_map, bucket, coord)


def main() -> None:
    args = parse_args()
    metadata, parts = load_metadata(args.parts_json)
    semantics = load_semantics(args.semantics)
    overrides = semantics.get("parts", {})
    source_atlas = Image.open(args.atlas).convert("RGBA")

    cells: list[Image.Image] = []
    cell_records: list[dict[str, Any]] = []
    bucket_map: dict[str, list[list[int]]] = defaultdict(list)
    needs_review: list[dict[str, Any]] = []
    tall_source_count = 0
    passage_sources = load_passage_images(args.passage_dir)

    for part in parts:
        part_id = str(part.get("id", f"part_{len(cell_records):03d}"))
        override = overrides.get(part_id, {})
        role, tags, review = infer_role(part, override)
        part_image = crop_part(source_atlas, part)
        if part_image.size[1] > args.tile_size:
            tall_source_count += 1
        part_cells = slice_part_into_cells(part_image, args.tile_size, args.vertical_window)

        for idx, cell in enumerate(part_cells):
            cell_index = len(cells)
            coord = [cell_index % args.columns, int(cell_index / args.columns)]
            cells.append(cell)
            assign_buckets(bucket_map, role, tags, coord, idx, len(part_cells))
            cell_records.append(
                {
                    "coord": coord,
                    "source_part": part_id,
                    "source_kind": part.get("kind", "unclassified"),
                    "role": role,
                    "tags": tags,
                    "slice_index": idx,
                    "slice_count": len(part_cells),
                    "needs_review": review,
                }
            )

        if review:
            needs_review.append({"id": part_id, "role": role, "kind": part.get("kind", "unclassified")})

    for passage_id, passage_image in passage_sources:
        part_cells = slice_part_into_cells(passage_image, args.tile_size, "bottom")
        for idx, cell in enumerate(part_cells):
            cell_index = len(cells)
            coord = [cell_index % args.columns, int(cell_index / args.columns)]
            cells.append(cell)
            assign_buckets(bucket_map, "passage_horizontal", ["passage"], coord, idx, len(part_cells))
            cell_records.append(
                {
                    "coord": coord,
                    "source_part": passage_id,
                    "source_kind": "passage_strip",
                    "role": "passage_horizontal",
                    "tags": ["passage"],
                    "slice_index": idx,
                    "slice_count": len(part_cells),
                    "needs_review": False,
                }
            )

    ensure_runtime_fallbacks(bucket_map)

    rows = max(1, math.ceil(len(cells) / args.columns))
    output = Image.new("RGBA", (args.columns * args.tile_size, rows * args.tile_size), (0, 0, 0, 0))
    for index, cell in enumerate(cells):
        x = (index % args.columns) * args.tile_size
        y = int(index / args.columns) * args.tile_size
        output.alpha_composite(cell, (x, y))

    args.out_image.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    output.save(args.out_image)

    buckets = {bucket: bucket_map[bucket] for bucket in BUCKETS}
    missing = [bucket for bucket in BUCKETS if not buckets[bucket]]
    mapping = {
        "schema": "custodian.procgen_wall_tiles.v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "tile_size": args.tile_size,
        "columns": args.columns,
        "source_parts_json": str(args.parts_json.as_posix()),
        "source_atlas": str(args.atlas.as_posix()),
        "passage_dir": str(args.passage_dir.as_posix()) if args.passage_dir else "",
        "source_image": str(args.out_image.as_posix()),
        "source_parts_schema": metadata.get("schema", "unknown"),
        "vertical_window": args.vertical_window,
        "buckets": buckets,
        "cells": cell_records,
        "needs_review": needs_review,
        "warnings": {
            "tall_source_parts_cropped_to_tile": tall_source_count,
            "passage_sources_loaded": len(passage_sources),
            "missing_semantic_buckets": missing,
        },
    }
    args.out_json.write_text(json.dumps(mapping, indent=2) + "\n", encoding="utf-8")

    print(f"Loaded {len(parts)} source parts")
    print(f"Emitted {len(cells)} runtime cells")
    print(f"Tall source parts cropped to {args.vertical_window} {args.tile_size}px window: {tall_source_count}")
    print(f"Passage strips loaded: {len(passage_sources)}")
    print(f"Needs review: {len(needs_review)}")
    print(f"Missing semantic buckets: {', '.join(missing) if missing else 'none'}")
    print(f"Wrote {args.out_image}")
    print(f"Wrote {args.out_json}")


if __name__ == "__main__":
    main()
