#!/usr/bin/env python3
"""
Split a generated 3x3 CUSTODIAN vault tilesheet into individual PNG files
and append entries to the master gothic manifest.

Default expected tile order:

row 1:
  vault_floor_stone_01.png
  vault_floor_stone_02.png
  vault_floor_metal_inlay_01.png

row 2:
  vault_floor_threshold_01.png
  vault_wall_back_01.png
  vault_wall_side_01.png

row 3:
  vault_wall_corner_01.png
  vault_wall_cap_01.png
  vault_wall_broken_01.png

Output is routed per asset type:

  Category        | Target directory
  ----------------|--------------------------------------------------
  floor/threshold | interiors/gothic/floors/
  wall/side       | gothic/wall_vertical_slice/
  corner          | gothic/wall_corner_or_end/
  cap             | gothic/wall_horizontal_or_cap/
  broken          | gothic/wall_vertical_slice/

Each tile is written to its type-specific directory and a game32.asset.v2
entry is appended to content/tiles/gothic/gothic_master_sheet.game32.json.

Typical use:

  python custodian/tools/asset_pipeline/split_vault_tiles.py \\
    --input /path/to/generated_vault_tilesheet.png \\
    --project-root /home/braydenchaffee/Projects/CUSTODIAN

This script supports two extraction modes:

1. auto:
   Detects the 9 visible tile islands by thresholding out transparency/checkerboard.
   Best for generated images with spacing around each tile.

2. grid:
   Splits the image into a regular 3x3 grid.
   Best for manually cleaned master sheets.

By default it uses auto first and falls back to grid if detection fails.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from collections import deque
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image


MASTER_MANIFEST_PATH = Path("custodian/content/tiles/gothic/gothic_master_sheet.game32.json")
SOURCE_COPY_DIR_DEFAULT = Path("custodian/content/tiles/source/gothic/vault")

# Route each tile to its type-specific directory under content/tiles/.
# Keyed by (category, semantic_role) for unambiguous matching.
OUTPUT_DIR_MAP: dict[tuple[str, str], Path] = {
    ("floor", "vault_floor"):              Path("interiors/gothic/floors"),
    ("floor", "vault_floor_variant"):      Path("interiors/gothic/floors"),
    ("floor", "vault_floor_decorative_inlay"): Path("interiors/gothic/floors"),
    ("threshold", "vault_threshold_floor"): Path("interiors/gothic/floors"),
    ("wall", "vault_back_wall"):           Path("gothic/wall_vertical_slice"),
    ("wall", "vault_side_wall"):           Path("gothic/wall_vertical_slice"),
    ("wall", "vault_wall_corner"):         Path("gothic/wall_corner_or_end"),
    ("wall_cap", "vault_wall_cap"):        Path("gothic/wall_horizontal_or_cap"),
    ("wall_broken", "vault_broken_wall"):  Path("gothic/wall_vertical_slice"),
}

# Map category to section/subtype used in the master manifest.
SECTION_MAP: dict[str, str] = {
    "floor": "tiles_interiors",
    "threshold": "tiles_interiors",
    "wall": "walls",
    "wall_cap": "walls",
    "wall_broken": "walls",
}

SUBTYPE_MAP: dict[str, str] = {
    "floor": "floors",
    "threshold": "floors",
    "wall": "wall_vertical_slice",
    "wall_cap": "wall_horizontal_or_cap",
    "wall_broken": "wall_vertical_slice",
}

TILE_ORDER = [
    {
        "filename": "vault_floor_stone_01.png",
        "id": "gothic_vault_tiles_vault_floor_stone_01",
        "asset_type": "tiles",
        "semantic_role": "vault_floor",
        "placement_layer": "floor",
        "category": "floor",
        "description": "Dark gothic vault stone floor variant with large worn slabs, cracks, and low-contrast grime.",
        "tile_semantics": ["floor", "walkable", "vault", "stone", "interior"],
        "tags": ["vault", "floor", "stone", "gothic", "walkable", "tile"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
    },
    {
        "filename": "vault_floor_stone_02.png",
        "id": "gothic_vault_tiles_vault_floor_stone_02",
        "asset_type": "tiles",
        "semantic_role": "vault_floor_variant",
        "placement_layer": "floor",
        "category": "floor",
        "description": "Alternate dark gothic vault stone floor with smaller irregular slabs and cracked seams.",
        "tile_semantics": ["floor", "walkable", "vault", "stone", "interior", "variant"],
        "tags": ["vault", "floor", "stone", "gothic", "walkable", "variant", "tile"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
    },
    {
        "filename": "vault_floor_metal_inlay_01.png",
        "id": "gothic_vault_tiles_vault_floor_metal_inlay_01",
        "asset_type": "tiles",
        "semantic_role": "vault_floor_decorative_inlay",
        "placement_layer": "floor",
        "category": "floor",
        "description": "Decorative vault floor tile with metal framing, central compass-like inlay, rivets, and reinforced stone.",
        "tile_semantics": ["floor", "walkable", "vault", "stone", "metal_inlay", "decorative"],
        "tags": ["vault", "floor", "metal", "inlay", "gothic", "walkable", "decorative", "tile"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
    },
    {
        "filename": "vault_floor_threshold_01.png",
        "id": "gothic_vault_tiles_vault_floor_threshold_01",
        "asset_type": "tiles",
        "semantic_role": "vault_threshold_floor",
        "placement_layer": "floor_transition",
        "category": "threshold",
        "description": "Reinforced metal-and-stone threshold tile for vault doors, gates, and room transitions.",
        "tile_semantics": ["floor", "walkable", "vault", "threshold", "doorway", "metal", "transition"],
        "tags": ["vault", "floor", "threshold", "doorway", "metal", "gothic", "walkable", "tile"],
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
    },
    {
        "filename": "vault_wall_back_01.png",
        "id": "gothic_vault_walls_vault_wall_back_01",
        "asset_type": "walls",
        "semantic_role": "vault_back_wall",
        "placement_layer": "wall",
        "category": "wall",
        "description": "Back-facing gothic vault wall segment with carved stone, columns, arched recesses, and heavy masonry.",
        "tile_semantics": ["wall", "vault", "stone", "back_wall", "blocks_movement", "blocks_sight"],
        "tags": ["vault", "wall", "back", "stone", "gothic", "blocking", "tile"],
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
    },
    {
        "filename": "vault_wall_side_01.png",
        "id": "gothic_vault_walls_vault_wall_side_01",
        "asset_type": "walls",
        "semantic_role": "vault_side_wall",
        "placement_layer": "wall",
        "category": "wall",
        "description": "Side-facing gothic vault wall segment with column edge, arched inset, base molding, and dark stone blocks.",
        "tile_semantics": ["wall", "vault", "stone", "side_wall", "blocks_movement", "blocks_sight"],
        "tags": ["vault", "wall", "side", "stone", "gothic", "blocking", "tile"],
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
    },
    {
        "filename": "vault_wall_corner_01.png",
        "id": "gothic_vault_walls_vault_wall_corner_01",
        "asset_type": "walls",
        "semantic_role": "vault_wall_corner",
        "placement_layer": "wall",
        "category": "wall",
        "description": "L-shaped gothic vault wall corner with perpendicular stone faces, pillar mass, and base trim.",
        "tile_semantics": ["wall", "vault", "stone", "corner", "blocks_movement", "blocks_sight"],
        "tags": ["vault", "wall", "corner", "stone", "gothic", "blocking", "tile"],
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
    },
    {
        "filename": "vault_wall_cap_01.png",
        "id": "gothic_vault_walls_vault_wall_cap_01",
        "asset_type": "walls",
        "semantic_role": "vault_wall_cap",
        "placement_layer": "wall_cap",
        "category": "wall_cap",
        "description": "Horizontal top cap/coping tile for vault walls, with gothic trim, shield-like emblem, and heavy stone slab.",
        "tile_semantics": ["wall_cap", "vault", "stone", "top_edge", "blocks_movement"],
        "tags": ["vault", "wall", "cap", "top", "stone", "gothic", "tile"],
        "blocks_movement": True,
        "blocks_sight": False,
        "cover_value": 1,
    },
    {
        "filename": "vault_wall_broken_01.png",
        "id": "gothic_vault_walls_vault_wall_broken_01",
        "asset_type": "walls",
        "semantic_role": "vault_broken_wall",
        "placement_layer": "wall",
        "category": "wall_broken",
        "description": "Broken gothic vault wall segment with collapsed masonry, jagged stone break, rubble mass, and damaged trim.",
        "tile_semantics": ["wall", "vault", "stone", "broken", "rubble", "blocks_movement", "partial_sight_block"],
        "tags": ["vault", "wall", "broken", "rubble", "stone", "gothic", "blocking", "tile"],
        "blocks_movement": True,
        "blocks_sight": True,
        "cover_value": 2,
    },
]


def get_output_dir(spec: dict[str, Any], project_root: Path, fallback: Path | None) -> Path:
    """Resolve the per-type output directory from a tile spec."""
    key = (spec["category"], spec["semantic_role"])
    rel = OUTPUT_DIR_MAP.get(key)
    if rel is None and fallback is not None:
        rel = fallback
    if rel is None:
        raise ValueError(
            f"No output dir mapped for ({spec['category']!r}, {spec['semantic_role']!r}) "
            f"and no --out-dir fallback provided"
        )
    if rel.is_absolute():
        return rel
    return (project_root / "custodian/content/tiles" / rel).resolve()


@dataclass(frozen=True)
class BBox:
    left: int
    top: int
    right: int
    bottom: int

    @property
    def width(self) -> int:
        return self.right - self.left

    @property
    def height(self) -> int:
        return self.bottom - self.top

    @property
    def area(self) -> int:
        return self.width * self.height

    @property
    def center(self) -> tuple[float, float]:
        return ((self.left + self.right) / 2.0, (self.top + self.bottom) / 2.0)

    def padded(self, pad: int, max_w: int, max_h: int) -> "BBox":
        return BBox(
            max(0, self.left - pad),
            max(0, self.top - pad),
            min(max_w, self.right + pad),
            min(max_h, self.bottom + pad),
        )


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def is_probably_checkerboard_pixel(r: int, g: int, b: int, tolerance: int) -> bool:
    """
    Generated transparent previews often become actual light checkerboard pixels.
    Treat very light neutral gray/white pixels as background.
    """
    near_neutral = max(abs(r - g), abs(g - b), abs(r - b)) <= tolerance
    very_light = min(r, g, b) >= 210
    return near_neutral and very_light


def make_foreground_mask(img: Image.Image, checker_tolerance: int) -> list[list[bool]]:
    rgba = img.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    mask: list[list[bool]] = [[False for _ in range(w)] for _ in range(h)]

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 10:
                continue
            if is_probably_checkerboard_pixel(r, g, b, checker_tolerance):
                continue
            mask[y][x] = True

    return mask


def connected_components(mask: list[list[bool]], min_area: int) -> list[BBox]:
    h = len(mask)
    w = len(mask[0]) if h else 0
    seen = [[False for _ in range(w)] for _ in range(h)]
    boxes: list[BBox] = []

    for y in range(h):
        for x in range(w):
            if seen[y][x] or not mask[y][x]:
                continue

            q: deque[tuple[int, int]] = deque([(x, y)])
            seen[y][x] = True
            left = right = x
            top = bottom = y
            count = 0

            while q:
                cx, cy = q.popleft()
                count += 1
                left = min(left, cx)
                right = max(right, cx)
                top = min(top, cy)
                bottom = max(bottom, cy)

                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    if seen[ny][nx] or not mask[ny][nx]:
                        continue
                    seen[ny][nx] = True
                    q.append((nx, ny))

            if count >= min_area:
                boxes.append(BBox(left, top, right + 1, bottom + 1))

    return boxes


def sort_boxes_grid(boxes: list[BBox]) -> list[BBox]:
    """Sort 9 boxes into row-major order using center positions."""
    if len(boxes) != 9:
        raise ValueError(f"Expected 9 boxes, got {len(boxes)}")

    by_y = sorted(boxes, key=lambda b: b.center[1])
    rows = [by_y[0:3], by_y[3:6], by_y[6:9]]
    sorted_rows = [sorted(row, key=lambda b: b.center[0]) for row in rows]
    return [b for row in sorted_rows for b in row]


def detect_auto_boxes(img: Image.Image, pad: int, min_component_area: int, checker_tolerance: int) -> list[BBox]:
    mask = make_foreground_mask(img, checker_tolerance)
    boxes = connected_components(mask, min_component_area)

    # Keep largest 9 visible islands. This ignores stray speckles.
    boxes = sorted(boxes, key=lambda b: b.area, reverse=True)[:9]
    boxes = sort_boxes_grid(boxes)
    w, h = img.size
    return [b.padded(pad, w, h) for b in boxes]


def grid_boxes(img: Image.Image, margin: int = 0) -> list[BBox]:
    w, h = img.size
    cell_w = w // 3
    cell_h = h // 3
    boxes = []

    for row in range(3):
        for col in range(3):
            left = col * cell_w + margin
            top = row * cell_h + margin
            right = (col + 1) * cell_w - margin if col < 2 else w - margin
            bottom = (row + 1) * cell_h - margin if row < 2 else h - margin
            boxes.append(BBox(left, top, right, bottom))

    return boxes


def alpha_out_checkerboard(img: Image.Image, checker_tolerance: int) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 10:
                px[x, y] = (0, 0, 0, 0)
                continue
            if is_probably_checkerboard_pixel(r, g, b, checker_tolerance):
                px[x, y] = (0, 0, 0, 0)

    return rgba


def trim_transparent(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    bbox = rgba.getbbox()
    if not bbox:
        return rgba
    return rgba.crop(bbox)


def fit_to_square_canvas(img: Image.Image, size: int) -> Image.Image:
    """Resize proportionally into a size x size transparent canvas (lossy, nearest-neighbor)."""
    rgba = img.convert("RGBA")
    bbox = rgba.getbbox()
    if bbox:
        rgba = rgba.crop(bbox)

    w, h = rgba.size
    if w == 0 or h == 0:
        return Image.new("RGBA", (size, size), (0, 0, 0, 0))

    scale = min(size / w, size / h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    resized = rgba.resize((new_w, new_h), Image.Resampling.NEAREST)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - new_w) // 2
    y = (size - new_h) // 2
    canvas.alpha_composite(resized, (x, y))
    return canvas


def make_master_manifest_entry(
    *,
    spec: dict[str, Any],
    project_root: Path,
    output_png: Path,
    source_sheet_copy: Path,
    crop_box: BBox,
    exported_size: tuple[int, int],
    tile_size: int,
    master_index: int,
    res_path: str,
) -> dict[str, Any]:
    """Build a game32.asset.v2 entry matching the gothic master manifest format."""
    rel_output = output_png.relative_to(project_root).as_posix()
    rel_source_copy = source_sheet_copy.relative_to(project_root).as_posix()

    is_floor = spec["category"] in {"floor", "threshold"}
    is_wall = spec["category"].startswith("wall")
    category = spec["category"]
    section = SECTION_MAP.get(category, "tiles")
    subtype = SUBTYPE_MAP.get(category, "tiles")

    tile_w = max(1, round(exported_size[0] / tile_size))
    tile_h = max(1, round(exported_size[1] / tile_size))

    return {
        "schema": "game32.asset.v2",
        "id": spec["id"],
        "display_name": Path(spec["filename"]).stem.replace("_", " ").title(),
        "source": {
            "master_sheet": rel_source_copy,
            "original_path": res_path,
            "section": section,
            "subtype": subtype,
            "source_rect_px": {
                "x": crop_box.left,
                "y": crop_box.top,
                "w": crop_box.width,
                "h": crop_box.height,
            },
        },
        "file": {
            "path": res_path,
            "pixel_size": {
                "w": exported_size[0],
                "h": exported_size[1],
            },
        },
        "classification": {
            "asset_type": spec["asset_type"],
            "semantic_role": spec["semantic_role"],
            "placement_layer": spec["placement_layer"],
            "tags": spec["tags"],
            "review_status": "needs_game32_enrichment",
        },
        "placement": {
            "tile_size": tile_size,
            "footprint_tiles": {
                "w": tile_w,
                "h": tile_h,
            },
            "origin_mode": "top_left" if is_floor else "bottom_center",
            "snap": "tile",
            "allow_mirror_x": bool(is_wall),
            "allow_rotation": False,
            "y_sort": bool(is_wall),
        },
        "collision": {
            "blocks_movement": spec["blocks_movement"],
            "blocks_sight": spec["blocks_sight"],
            "cover_value": spec["cover_value"],
            "review_status": "needs_game32_enrichment",
        },
        "procgen": {
            "uses": [
                "vault_interior",
                "gothic_interior",
                "compound_interior",
            ],
            "weight": 1,
            "can_spawn_indoor": True,
            "can_spawn_outdoor": False,
            "review_status": "needs_game32_enrichment",
        },
        "master_index": master_index,
    }


def load_master_manifest(path: Path) -> dict[str, Any]:
    """Load the gothic master manifest JSON."""
    if not path.exists():
        print(f"ERROR: master manifest not found: {path}", file=sys.stderr)
        print("Run the manifest generator first, or create an empty one.", file=sys.stderr)
        sys.exit(7)
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_master_manifest(path: Path, manifest: dict[str, Any]) -> None:
    """Write the gothic master manifest JSON."""
    path.write_text(json.dumps(manifest, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def existing_ids(manifest: dict[str, Any]) -> set[str]:
    """Return the set of all asset IDs already in the master manifest."""
    return {entry["id"] for entry in manifest.get("assets", [])}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Split vault tilesheet into type-routed PNGs + append to master gothic manifest."
    )
    parser.add_argument("--input", required=True, type=Path, help="Path to generated 3x3 vault tilesheet PNG.")
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path.cwd(),
        help="Repo root. Default: current working directory.",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=None,
        help="Fallback output directory when no type-specific mapping exists. "
             "Default: computed from OUTPUT_DIR_MAP per tile type.",
    )
    parser.add_argument(
        "--source-copy-dir",
        type=Path,
        default=SOURCE_COPY_DIR_DEFAULT,
        help=f"Where to copy the generated master sheet for source provenance. Default: {SOURCE_COPY_DIR_DEFAULT}",
    )
    parser.add_argument(
        "--master-manifest",
        type=Path,
        default=MASTER_MANIFEST_PATH,
        help=f"Path to the master gothic manifest to append to. Default: {MASTER_MANIFEST_PATH}",
    )
    parser.add_argument(
        "--mode",
        choices=["auto", "grid", "auto_then_grid"],
        default="auto_then_grid",
        help="Extraction mode.",
    )
    parser.add_argument("--tile-size", type=int, default=32, help="Game tile size metadata, usually 32.")
    parser.add_argument("--pad", type=int, default=6, help="Padding around auto-detected crop boxes.")
    parser.add_argument(
        "--min-component-area",
        type=int,
        default=5000,
        help="Minimum connected component area for auto detection.",
    )
    parser.add_argument(
        "--checker-tolerance",
        type=int,
        default=8,
        help="Tolerance for treating light neutral checkerboard pixels as background.",
    )
    parser.add_argument(
        "--grid-margin",
        type=int,
        default=20,
        help="Margin trimmed from each regular 3x3 grid cell in grid mode.",
    )
    parser.add_argument(
        "--trim",
        action="store_true",
        help="Trim transparent area around each extracted tile after background removal.",
    )
    parser.add_argument(
        "--normalize-size",
        type=int,
        default=0,
        help="Optional lossy export size, e.g. 32, 64, 128. 0 keeps cropped source size.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing PNG outputs and re-append to master manifest.",
    )

    args = parser.parse_args()

    project_root = args.project_root.expanduser().resolve()
    input_path = args.input.expanduser().resolve()

    if not input_path.exists():
        print(f"ERROR: input file does not exist: {input_path}", file=sys.stderr)
        return 2

    # Source copy
    source_copy_dir = args.source_copy_dir
    if not source_copy_dir.is_absolute():
        source_copy_dir = project_root / source_copy_dir
    source_copy_dir.mkdir(parents=True, exist_ok=True)

    source_copy = source_copy_dir / input_path.name
    if source_copy.exists() and not args.overwrite:
        print(f"Source copy exists, keeping: {source_copy}")
    else:
        shutil.copy2(input_path, source_copy)
        print(f"Copied source sheet: {source_copy}")

    # Load master manifest
    master_path = args.master_manifest
    if not master_path.is_absolute():
        master_path = project_root / master_path
    master = load_master_manifest(master_path)
    known_ids = existing_ids(master)
    next_index = master.get("total_asset_count", len(known_ids))

    # Compute fallback out_dir
    fallback_out = None
    if args.out_dir is not None:
        fallback_out = args.out_dir
        if not fallback_out.is_absolute():
            fallback_out = project_root / fallback_out

    # Extraction
    img = Image.open(input_path).convert("RGBA")
    original_sheet_size = img.size

    extraction_mode_used = args.mode
    try:
        if args.mode == "auto":
            boxes = detect_auto_boxes(img, args.pad, args.min_component_area, args.checker_tolerance)
        elif args.mode == "grid":
            boxes = grid_boxes(img, args.grid_margin)
        else:
            try:
                boxes = detect_auto_boxes(img, args.pad, args.min_component_area, args.checker_tolerance)
                extraction_mode_used = "auto"
            except Exception as exc:
                print(f"Auto detection failed: {exc}", file=sys.stderr)
                print("Falling back to regular 3x3 grid extraction.", file=sys.stderr)
                boxes = grid_boxes(img, args.grid_margin)
                extraction_mode_used = "grid"
    except Exception as exc:
        print(f"ERROR: failed to compute crop boxes: {exc}", file=sys.stderr)
        return 3

    if len(boxes) != 9:
        print(f"ERROR: expected 9 crop boxes, got {len(boxes)}", file=sys.stderr)
        return 4

    new_entries: list[dict[str, Any]] = []
    section_updates: dict[str, int] = {}

    for idx, (spec, box) in enumerate(zip(TILE_ORDER, boxes)):
        tile_id = spec["id"]

        if tile_id in known_ids and not args.overwrite:
            print(f"ERROR: tile ID already in master manifest, use --overwrite: {tile_id}", file=sys.stderr)
            return 5

        # Resolve output directory for this tile type
        out_dir = get_output_dir(spec, project_root, fallback_out)
        out_dir.mkdir(parents=True, exist_ok=True)

        output_png = out_dir / spec["filename"]
        if output_png.exists() and not args.overwrite:
            print(f"ERROR: output exists, use --overwrite: {output_png}", file=sys.stderr)
            return 5

        # Crop and process
        tile_img = img.crop((box.left, box.top, box.right, box.bottom))
        tile_img = alpha_out_checkerboard(tile_img, args.checker_tolerance)

        if args.trim:
            tile_img = trim_transparent(tile_img)

        if args.normalize_size and args.normalize_size > 0:
            tile_img = fit_to_square_canvas(tile_img, args.normalize_size)

        tile_img.save(output_png)

        # Res path for manifest
        rel_png = output_png.relative_to(project_root).as_posix()
        res_path = f"res://{rel_png}"

        entry = make_master_manifest_entry(
            spec=spec,
            project_root=project_root,
            output_png=output_png,
            source_sheet_copy=source_copy,
            crop_box=box,
            exported_size=tile_img.size,
            tile_size=args.tile_size,
            master_index=next_index,
            res_path=res_path,
        )
        new_entries.append(entry)

        # Track section counts
        section = entry["source"]["section"]
        section_updates[section] = section_updates.get(section, 0) + 1

        next_index += 1
        print(f"Wrote {output_png}")

    # Append to master manifest
    master.setdefault("assets", []).extend(new_entries)
    master["total_asset_count"] = master.get("total_asset_count", 0) + len(new_entries)
    master["generated_at_utc"] = iso_now()

    # Update section counts
    sections = master.setdefault("sections", {})
    for sec, count in section_updates.items():
        sections[sec] = sections.get(sec, 0) + count

    save_master_manifest(master_path, master)
    print(f"Appended {len(new_entries)} entries to {master_path}")

    print("\nDone.")
    print(f"Generated {len(new_entries)} tile PNGs into type-specific directories under content/tiles/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
