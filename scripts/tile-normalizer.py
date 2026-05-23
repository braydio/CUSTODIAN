#!/usr/bin/env python3
"""
normalize_road_pieces_32.py

Reads road_piece_manifest.json and creates a game-aligned road module export.

Default behavior:
- keeps original road art at 1:1 scale
- pads each PNG to the next 32 px multiple
- centers the original art on the new transparent canvas
- writes a new manifest with:
  - original_size_px
  - size_px
  - grid_size_tiles
  - art_offset_px
  - anchor
  - socket_points_px
  - normalized file paths

This is better than resampling because roads stay crisp and procgen math becomes clean.

Example:
    python normalize_road_pieces_32.py \
      --manifest /home/braydenchaffee/Projects/CUSTODIAN/custodian/content/tiles/roads_paths/road_piece_exports/road_piece_manifest.json

Output:
    road_piece_exports_game32/
      pieces/
      road_piece_manifest.game32.json
"""

from __future__ import annotations

import argparse
import json
import math
import shutil
from pathlib import Path
from typing import Any, Dict, List, Tuple

from PIL import Image

DEFAULT_TILE_SIZE = 32


def ceil_to_multiple(value: int, multiple: int) -> int:
    return int(math.ceil(value / multiple) * multiple)


def even_center_offset(canvas_size: int, art_size: int) -> int:
    return (canvas_size - art_size) // 2


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def write_json(path: Path, data: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def resolve_piece_path(
    manifest_path: Path,
    manifest: Dict[str, Any],
    piece_file: str,
) -> Path:
    """
    Resolve paths like:
      pieces/foo.png

    Uses manifest export_root first, then falls back to manifest directory.
    """
    file_path = Path(piece_file)

    if file_path.is_absolute():
        return file_path

    export_root_raw = manifest.get("export_root")
    if export_root_raw:
        export_root = Path(export_root_raw)
        candidate = export_root / file_path
        if candidate.exists():
            return candidate

    candidate = manifest_path.parent / file_path
    if candidate.exists():
        return candidate

    # Last fallback: manifest dir / pieces / filename
    candidate = manifest_path.parent / "pieces" / file_path.name
    return candidate


def get_target_size(
    w: int,
    h: int,
    tile_size: int,
    min_tiles_w: int,
    min_tiles_h: int,
) -> Tuple[int, int, int, int]:
    """
    Pad to nearest tile-size multiple.
    Enforce optional minimum tile dimensions.
    """
    target_w = max(ceil_to_multiple(w, tile_size), min_tiles_w * tile_size)
    target_h = max(ceil_to_multiple(h, tile_size), min_tiles_h * tile_size)

    tiles_w = target_w // tile_size
    tiles_h = target_h // tile_size

    return target_w, target_h, tiles_w, tiles_h


def socket_points_px(target_w: int, target_h: int) -> Dict[str, Dict[str, int]]:
    return {
        "n": {"x": target_w // 2, "y": 0},
        "e": {"x": target_w, "y": target_h // 2},
        "s": {"x": target_w // 2, "y": target_h},
        "w": {"x": 0, "y": target_h // 2},
    }


def normalize_piece(
    source_path: Path,
    output_path: Path,
    tile_size: int,
    min_tiles_w: int,
    min_tiles_h: int,
    force_square_intersections: bool,
    kind: str,
) -> Dict[str, Any]:
    if not source_path.exists():
        raise FileNotFoundError(f"Missing piece image: {source_path}")

    img = Image.open(source_path).convert("RGBA")
    original_w, original_h = img.size

    target_w, target_h, tiles_w, tiles_h = get_target_size(
        original_w,
        original_h,
        tile_size,
        min_tiles_w,
        min_tiles_h,
    )

    if force_square_intersections and kind in {"cross", "tee", "corner"}:
        side = max(target_w, target_h)
        side = ceil_to_multiple(side, tile_size)
        target_w = side
        target_h = side
        tiles_w = side // tile_size
        tiles_h = side // tile_size

    offset_x = even_center_offset(target_w, original_w)
    offset_y = even_center_offset(target_h, original_h)

    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    canvas.alpha_composite(img, (offset_x, offset_y))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path)

    return {
        "original_size_px": {"w": original_w, "h": original_h},
        "size_px": {"w": target_w, "h": target_h},
        "grid_size_tiles": {"w": tiles_w, "h": tiles_h},
        "art_offset_px": {"x": offset_x, "y": offset_y},
        "anchor": {
            "mode": "center",
            "x": target_w // 2,
            "y": target_h // 2,
        },
        "socket_points_px": socket_points_px(target_w, target_h),
    }


def normalize_manifest(
    manifest_path: Path,
    output_root: Path | None,
    tile_size: int,
    min_tiles_w: int,
    min_tiles_h: int,
    force_square_intersections: bool,
    overwrite: bool,
) -> Path:
    manifest = load_json(manifest_path)

    if output_root is None:
        original_export_root = manifest.get("export_root")
        if original_export_root:
            output_root = (
                Path(str(original_export_root)).parent / "road_piece_exports_game32"
            )
        else:
            output_root = manifest_path.parent.parent / "road_piece_exports_game32"

    pieces_out_dir = output_root / "pieces"
    new_manifest_path = output_root / "road_piece_manifest.game32.json"

    if output_root.exists() and overwrite:
        shutil.rmtree(output_root)

    output_root.mkdir(parents=True, exist_ok=True)
    pieces_out_dir.mkdir(parents=True, exist_ok=True)

    new_manifest = dict(manifest)
    new_manifest["asset_pack"] = (
        str(manifest.get("asset_pack", "road_pieces")) + "_game32"
    )
    new_manifest["export_root"] = str(output_root)
    new_manifest["tile_size_px"] = tile_size
    new_manifest["normalization"] = {
        "mode": "pad_to_tile_grid",
        "art_scale": 1.0,
        "resampled": False,
        "tile_size_px": tile_size,
        "force_square_intersections": force_square_intersections,
        "note": "Artwork is not rescaled; transparent canvas is padded to grid multiples.",
    }

    normalized_pieces: List[Dict[str, Any]] = []

    for piece in manifest.get("pieces", []):
        piece_id = piece["id"]
        kind = piece.get("kind", "unknown")
        src_file = piece["file"]

        source_path = resolve_piece_path(manifest_path, manifest, src_file)
        output_file = f"{piece_id}.png"
        output_path = pieces_out_dir / output_file

        result = normalize_piece(
            source_path=source_path,
            output_path=output_path,
            tile_size=tile_size,
            min_tiles_w=min_tiles_w,
            min_tiles_h=min_tiles_h,
            force_square_intersections=force_square_intersections,
            kind=kind,
        )

        new_piece = dict(piece)
        new_piece["file"] = f"pieces/{output_file}"
        new_piece["original_file"] = src_file
        new_piece["original_size_px"] = result["original_size_px"]
        new_piece["size_px"] = result["size_px"]
        new_piece["grid_size_tiles"] = result["grid_size_tiles"]
        new_piece["art_offset_px"] = result["art_offset_px"]
        new_piece["anchor"] = result["anchor"]
        new_piece["socket_points_px"] = result["socket_points_px"]

        # Keep normalized socket points too for generic procgen use.
        new_piece["socket_points_normalized"] = {
            "n": {"x": 0.5, "y": 0.0},
            "e": {"x": 1.0, "y": 0.5},
            "s": {"x": 0.5, "y": 1.0},
            "w": {"x": 0.0, "y": 0.5},
        }

        normalized_pieces.append(new_piece)

    new_manifest["pieces"] = normalized_pieces
    new_manifest["piece_count"] = len(normalized_pieces)

    write_json(new_manifest_path, new_manifest)

    return new_manifest_path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Normalize CUSTODIAN road pieces to a 32px game grid."
    )

    parser.add_argument(
        "--manifest",
        required=True,
        help="Path to road_piece_manifest.json",
    )

    parser.add_argument(
        "--output-root",
        default=None,
        help="Output folder. Default: sibling road_piece_exports_game32 folder.",
    )

    parser.add_argument(
        "--tile-size",
        type=int,
        default=DEFAULT_TILE_SIZE,
        help="Grid tile size in pixels. Default: 32.",
    )

    parser.add_argument(
        "--min-tiles-w",
        type=int,
        default=1,
        help="Minimum output width in tiles. Default: 1.",
    )

    parser.add_argument(
        "--min-tiles-h",
        type=int,
        default=1,
        help="Minimum output height in tiles. Default: 1.",
    )

    parser.add_argument(
        "--no-square-intersections",
        action="store_true",
        help="Do not force cross/tee/corner modules to square canvases.",
    )

    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Delete existing output folder before writing.",
    )

    args = parser.parse_args()

    manifest_path = Path(args.manifest).expanduser().resolve()
    output_root = (
        Path(args.output_root).expanduser().resolve() if args.output_root else None
    )

    new_manifest_path = normalize_manifest(
        manifest_path=manifest_path,
        output_root=output_root,
        tile_size=args.tile_size,
        min_tiles_w=args.min_tiles_w,
        min_tiles_h=args.min_tiles_h,
        force_square_intersections=not args.no_square_intersections,
        overwrite=args.overwrite,
    )

    print("Normalized road pieces complete.")
    print(f"New manifest: {new_manifest_path}")


if __name__ == "__main__":
    main()
