#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path
from statistics import median
from typing import Dict, List, Tuple

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ASCENT_TILES = [
    {
        "id": "terrain_landing_industrial_32",
        "file": "terrain_landing_industrial_32.png",
        "role": "landing",
        "style": "industrial",
        "walkable": True,
        "terrain_role": "elevation_landing",
    },
    {
        "id": "terrain_landing_stone_32",
        "file": "terrain_landing_stone_32.png",
        "role": "landing",
        "style": "stone",
        "walkable": True,
        "terrain_role": "elevation_landing",
    },
    {
        "id": "ramp_north_wide_32",
        "file": "ramp_north_wide_32.png",
        "role": "ramp",
        "direction": "north",
        "walkable": True,
        "traversal": "ramp",
    },
    {
        "id": "ramp_south_wide_32",
        "file": "ramp_south_wide_32.png",
        "role": "ramp",
        "direction": "south",
        "walkable": True,
        "traversal": "ramp",
    },
    {
        "id": "ramp_east_wide_32",
        "file": "ramp_east_wide_32.png",
        "role": "ramp",
        "direction": "east",
        "walkable": True,
        "traversal": "ramp",
    },
    {
        "id": "ramp_west_wide_32",
        "file": "ramp_west_wide_32.png",
        "role": "ramp",
        "direction": "west",
        "walkable": True,
        "traversal": "ramp",
    },
    {
        "id": "ramp_north_broken_32",
        "file": "ramp_north_broken_32.png",
        "role": "broken_ramp",
        "direction": "north",
        "walkable": True,
        "traversal": "ramp",
        "variant": "broken",
    },
    {
        "id": "ramp_south_broken_32",
        "file": "ramp_south_broken_32.png",
        "role": "broken_ramp",
        "direction": "south",
        "walkable": True,
        "traversal": "ramp",
        "variant": "broken",
    },
    {
        "id": "ramp_east_broken_32",
        "file": "ramp_east_broken_32.png",
        "role": "broken_ramp",
        "direction": "east",
        "walkable": True,
        "traversal": "ramp",
        "variant": "broken",
    },
    {
        "id": "ramp_west_broken_32",
        "file": "ramp_west_broken_32.png",
        "role": "broken_ramp",
        "direction": "west",
        "walkable": True,
        "traversal": "ramp",
        "variant": "broken",
    },
    {
        "id": "stair_north_stone_32",
        "file": "stair_north_stone_32.png",
        "role": "stair",
        "direction": "north",
        "style": "stone",
        "walkable": True,
        "traversal": "stair",
    },
    {
        "id": "stair_south_stone_32",
        "file": "stair_south_stone_32.png",
        "role": "stair",
        "direction": "south",
        "style": "stone",
        "walkable": True,
        "traversal": "stair",
    },
    {
        "id": "stair_east_stone_32",
        "file": "stair_east_stone_32.png",
        "role": "stair",
        "direction": "east",
        "style": "stone",
        "walkable": True,
        "traversal": "stair",
    },
    {
        "id": "stair_west_stone_32",
        "file": "stair_west_stone_32.png",
        "role": "stair",
        "direction": "west",
        "style": "stone",
        "walkable": True,
        "traversal": "stair",
    },
    {
        "id": "stair_north_metal_32",
        "file": "stair_north_metal_32.png",
        "role": "stair",
        "direction": "north",
        "style": "metal",
        "walkable": True,
        "traversal": "stair",
    },
    {
        "id": "stair_south_metal_32",
        "file": "stair_south_metal_32.png",
        "role": "stair",
        "direction": "south",
        "style": "metal",
        "walkable": True,
        "traversal": "stair",
    },
    {
        "id": "stair_east_metal_32",
        "file": "stair_east_metal_32.png",
        "role": "stair",
        "direction": "east",
        "style": "metal",
        "walkable": True,
        "traversal": "stair",
    },
    {
        "id": "stair_west_metal_32",
        "file": "stair_west_metal_32.png",
        "role": "stair",
        "direction": "west",
        "style": "metal",
        "walkable": True,
        "traversal": "stair",
    },
    {
        "id": "ascent_threshold_32",
        "file": "ascent_threshold_32.png",
        "role": "ascent_threshold",
        "walkable": True,
        "terrain_role": "objective_transition",
    },
    {
        "id": "ascent_lip_connector_32",
        "file": "ascent_lip_connector_32.png",
        "role": "elevated_lip_connector",
        "walkable": True,
        "terrain_role": "elevation_lip",
    },
]


BBox = Tuple[int, int, int, int]


def alpha_mask(
    img: Image.Image, alpha_threshold: int, merge_radius: int
) -> Image.Image:
    alpha = img.getchannel("A")
    mask = alpha.point(lambda a: 255 if a > alpha_threshold else 0)
    if merge_radius > 0:
        size = merge_radius * 2 + 1
        mask = mask.filter(ImageFilter.MaxFilter(size=size))
    return mask.convert("L")


def connected_components(mask: Image.Image, min_area: int) -> List[Dict]:
    w, h = mask.size
    data = mask.tobytes()
    visited = bytearray(w * h)
    components: List[Dict] = []

    def is_on(idx: int) -> bool:
        return data[idx] > 0

    for idx in range(w * h):
        if visited[idx] or not is_on(idx):
            continue

        q = deque([idx])
        visited[idx] = 1

        area = 0
        min_x = w
        min_y = h
        max_x = -1
        max_y = -1

        while q:
            cur = q.popleft()
            x = cur % w
            y = cur // w

            area += 1
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)

            neighbors = []
            if x > 0:
                neighbors.append(cur - 1)
            if x < w - 1:
                neighbors.append(cur + 1)
            if y > 0:
                neighbors.append(cur - w)
            if y < h - 1:
                neighbors.append(cur + w)

            for n in neighbors:
                if visited[n] or not is_on(n):
                    continue
                visited[n] = 1
                q.append(n)

        if area >= min_area:
            bbox = (min_x, min_y, max_x + 1, max_y + 1)
            components.append(
                {
                    "bbox": bbox,
                    "area": area,
                    "center": ((bbox[0] + bbox[2]) / 2.0, (bbox[1] + bbox[3]) / 2.0),
                    "size": (bbox[2] - bbox[0], bbox[3] - bbox[1]),
                }
            )

    return components


def sort_top_down_left_right(
    components: List[Dict], row_tolerance: int | None = None
) -> List[Dict]:
    if not components:
        return []

    heights = [c["size"][1] for c in components]
    if row_tolerance is None:
        row_tolerance = max(48, int(median(heights) * 0.45))

    rows: List[Dict] = []

    for comp in sorted(components, key=lambda c: (c["center"][1], c["center"][0])):
        cy = comp["center"][1]
        placed = False
        for row in rows:
            if abs(cy - row["cy"]) <= row_tolerance:
                row["items"].append(comp)
                row["cy"] = sum(item["center"][1] for item in row["items"]) / len(
                    row["items"]
                )
                placed = True
                break
        if not placed:
            rows.append({"cy": cy, "items": [comp]})

    rows.sort(key=lambda r: r["cy"])

    ordered: List[Dict] = []
    for row_index, row in enumerate(rows):
        row["items"].sort(key=lambda c: c["center"][0])
        for col_index, comp in enumerate(row["items"]):
            comp["row"] = row_index
            comp["col"] = col_index
            ordered.append(comp)

    return ordered


def expand_bbox(bbox: BBox, img_size: Tuple[int, int], padding_px: int) -> BBox:
    w, h = img_size
    l, t, r, b = bbox
    return (
        max(0, l - padding_px),
        max(0, t - padding_px),
        min(w, r + padding_px),
        min(h, b + padding_px),
    )


def square_crop_from_bbox(
    img: Image.Image, bbox: BBox, padding_ratio: float
) -> Image.Image:
    l, t, r, b = bbox
    content_w = r - l
    content_h = b - t
    side = max(content_w, content_h)
    padding = int(round(side * padding_ratio))
    side += padding * 2

    cx = (l + r) / 2.0
    cy = (t + b) / 2.0

    crop_l = int(round(cx - side / 2.0))
    crop_t = int(round(cy - side / 2.0))
    crop_r = crop_l + side
    crop_b = crop_t + side

    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))

    src_l = max(0, crop_l)
    src_t = max(0, crop_t)
    src_r = min(img.size[0], crop_r)
    src_b = min(img.size[1], crop_b)

    crop = img.crop((src_l, src_t, src_r, src_b))
    canvas.alpha_composite(crop, (src_l - crop_l, src_t - crop_t))
    return canvas


def resize_square(img: Image.Image, size: int, sharpen: bool) -> Image.Image:
    out = img.resize((size, size), Image.Resampling.LANCZOS)
    if sharpen:
        out = out.filter(ImageFilter.UnsharpMask(radius=0.65, percent=115, threshold=2))
    return out


def has_bad_runtime_alpha(img: Image.Image) -> bool:
    return img.mode != "RGBA" or img.getchannel("A").getextrema()[1] == 0


def write_labeled_debug_sheet(
    img: Image.Image, ordered: List[Dict], out_path: Path
) -> None:
    debug = img.copy().convert("RGBA")
    draw = ImageDraw.Draw(debug)
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 24)
    except Exception:
        font = ImageFont.load_default()

    for index, comp in enumerate(ordered, start=1):
        l, t, r, b = comp["bbox"]
        draw.rectangle((l, t, r, b), outline=(255, 80, 0, 255), width=3)
        label = str(index)
        draw.rectangle((l, t, l + 42, t + 32), fill=(0, 0, 0, 210))
        draw.text((l + 7, t + 2), label, fill=(255, 230, 90, 255), font=font)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    debug.save(out_path)


def write_manifest(manifest_path: Path, tiles: List[Dict]) -> None:
    manifest = {
        "id": "terrain_ascent_pack",
        "version": 1,
        "source_type": "ai_generated_source_sheet_component_sliced",
        "source_sheet": "res://content/tiles/terrain/source/generated/ascent/ascent_pack_ai_source.png",
        "normalized_source_dir": "res://content/tiles/terrain/source/generated/ascent/normalized_1024/",
        "preview_dir": "res://content/tiles/terrain/source/generated/ascent/previews_256/",
        "runtime_dir": "res://content/tiles/terrain/runtime/ascent/",
        "tile_size": 32,
        "background_policy": "alpha_component_detection_preserve_black_void_pixels",
        "role": "terrain_elevation_transition",
        "tiles": tiles,
    }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Slice and normalize the ascent pack source sheet into runtime 32x32 tiles."
    )
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument(
        "--sheet",
        type=Path,
        default=None,
        help="Path to ascent_pack_ai_source.png. Defaults to repo terrain source path.",
    )
    parser.add_argument("--alpha-threshold", type=int, default=8)
    parser.add_argument("--merge-radius", type=int, default=8)
    parser.add_argument("--min-area", type=int, default=1000)
    parser.add_argument("--padding-ratio", type=float, default=0.08)
    parser.add_argument("--normalized-size", type=int, default=1024)
    parser.add_argument("--preview-size", type=int, default=256)
    parser.add_argument("--runtime-size", type=int, default=32)
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    custodian_root = repo_root / "custodian"

    sheet_path = args.sheet
    if sheet_path is None:
        sheet_path = (
            custodian_root
            / "content/tiles/terrain/source/generated/ascent/ascent_pack_ai_source.png"
        )
    sheet_path = sheet_path.resolve()

    if not sheet_path.exists():
        print(f"ERROR: sheet not found: {sheet_path}")
        return 2

    normalized_dir = (
        custodian_root
        / "content/tiles/terrain/source/generated/ascent/normalized_1024"
    )
    preview_dir = (
        custodian_root
        / "content/tiles/terrain/source/generated/ascent/previews_256"
    )
    runtime_dir = custodian_root / "content/tiles/terrain/runtime/ascent"
    manifest_path = (
        custodian_root / "content/tiles/terrain/manifests/ascent_pack.game32.json"
    )

    report_dir = repo_root / "reports/terrain_pack_ingest"
    report_path = report_dir / "ascent_pack_normalize_report.md"
    debug_sheet_path = report_dir / "ascent_pack_detected_components.png"

    for d in [normalized_dir, preview_dir, runtime_dir, report_dir]:
        d.mkdir(parents=True, exist_ok=True)

    img = Image.open(sheet_path).convert("RGBA")
    mask = alpha_mask(img, args.alpha_threshold, args.merge_radius)
    components = connected_components(mask, args.min_area)
    ordered = sort_top_down_left_right(components)

    write_labeled_debug_sheet(img, ordered, debug_sheet_path)

    expected = len(ASCENT_TILES)
    if len(ordered) != expected:
        print(f"ERROR: expected {expected} components, detected {len(ordered)}")
        print(f"Debug sheet written: {debug_sheet_path}")
        for i, comp in enumerate(ordered, start=1):
            print(
                f"{i:02d}: bbox={comp['bbox']} area={comp['area']} row={comp.get('row')} col={comp.get('col')}"
            )
        return 3

    report_lines = [
        "# Ascent Pack Normalize Report",
        "",
        f"- source_sheet: `{sheet_path}`",
        f"- detected_components: `{len(ordered)}`",
        f"- debug_sheet: `{debug_sheet_path}`",
        f"- alpha_threshold: `{args.alpha_threshold}`",
        f"- merge_radius: `{args.merge_radius}`",
        f"- min_area: `{args.min_area}`",
        "",
        "| index | row | col | tile_id | bbox | source_size | runtime | warnings |",
        "|---:|---:|---:|---|---|---|---|---|",
    ]

    manifest_tiles: List[Dict] = []
    failures: List[str] = []

    for index, (comp, tile_def) in enumerate(zip(ordered, ASCENT_TILES), start=1):
        tile_id = tile_def["id"]
        bbox = comp["bbox"]

        try:
            square = square_crop_from_bbox(img, bbox, args.padding_ratio)
            normalized = resize_square(square, args.normalized_size, sharpen=False)
            preview = resize_square(square, args.preview_size, sharpen=True)
            runtime = resize_square(square, args.runtime_size, sharpen=True)

            normalized_path = normalized_dir / tile_def["file"].replace(
                "_32.png", "_1024.png"
            )
            preview_path = preview_dir / tile_def["file"].replace("_32.png", "_256.png")
            runtime_path = runtime_dir / tile_def["file"]

            normalized.save(normalized_path)
            preview.save(preview_path)
            runtime.save(runtime_path)

            warnings: List[str] = []
            if runtime.size != (args.runtime_size, args.runtime_size):
                warnings.append(f"bad runtime size {runtime.size}")
                failures.append(f"{tile_id}: bad runtime size {runtime.size}")
            if has_bad_runtime_alpha(runtime):
                warnings.append("bad or empty alpha")
                failures.append(f"{tile_id}: bad or empty alpha")

            manifest_entry = dict(tile_def)
            manifest_entry["source_index"] = index
            manifest_entry["source_bbox"] = list(bbox)
            manifest_entry["source_row"] = comp.get("row", -1)
            manifest_entry["source_col"] = comp.get("col", -1)
            manifest_entry["normalized_source_file"] = normalized_path.name
            manifest_entry["preview_file"] = preview_path.name
            manifest_tiles.append(manifest_entry)

            report_lines.append(
                f"| {index} | {comp.get('row')} | {comp.get('col')} | `{tile_id}` | `{bbox}` | "
                f"`{comp['size']}` | `{runtime_path.relative_to(repo_root)}` | "
                f"{'; '.join(warnings) if warnings else ''} |"
            )
            print(f"[ok] {index:02d} -> {tile_id}")

        except Exception as exc:
            failures.append(f"{tile_id}: {exc}")
            report_lines.append(
                f"| {index} | {comp.get('row')} | {comp.get('col')} | `{tile_id}` | `{bbox}` | "
                f"`{comp['size']}` | n/a | ERROR: {exc} |"
            )
            print(f"[error] {index:02d} {tile_id}: {exc}")

    write_manifest(manifest_path, manifest_tiles)
    report_path.write_text("\n".join(report_lines) + "\n", encoding="utf-8")

    print()
    print(f"Wrote manifest:   {manifest_path}")
    print(f"Wrote report:     {report_path}")
    print(f"Wrote debug sheet:{debug_sheet_path}")

    if failures:
        print()
        print("FAILURES:")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print()
    print("ascent pack normalization complete")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
