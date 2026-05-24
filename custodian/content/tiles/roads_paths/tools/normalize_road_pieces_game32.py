#!/usr/bin/env python3
"""
normalize_road_pieces_game32.py

Post-processes road pieces exported by the Aseprite road slicer.

What it does:
- Reads road_piece_manifest.json
- Opens every PNG listed in manifest["pieces"]
- Pads each image to clean 32px multiples
- Optionally forces cross/tee/corner pieces to square canvases
- Writes a new manifest with game-grid metadata
- Does NOT rescale art by default, so details stay crisp

Example:
python normalize_road_pieces_game32.py \
  --manifest custodian/content/tiles/roads_paths/source/road_piece_exports/road_piece_manifest.json \
  --pathways-json custodian/content/tiles/roads_paths/source/Pathways.json \
  --output-root custodian/content/tiles/roads_paths/runtime/paths \
  --surface paths
"""

from __future__ import annotations

import argparse
import json
import math
import shutil
from pathlib import Path
from typing import Any, Dict, Tuple

from PIL import Image

DEFAULT_TILE_SIZE = 32


def ceil_to_multiple(value: int, multiple: int) -> int:
    return int(math.ceil(value / multiple) * multiple)


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def pathish_piece(piece: Dict[str, Any]) -> bool:
    tags = set(piece.get("tags", []))
    name = str(piece.get("name", piece.get("id", ""))).lower()
    kind = str(piece.get("kind", "")).lower()
    width_class = str(piece.get("width_class", "")).lower()

    return (
        kind == "transition"
        or width_class in {"tiny", "short"}
        or "rubble" in tags
        or "damaged" in tags
        or "rounded" in tags
        or "path" in tags
        or "rubble" in name
        or "path" in name
    )


def road_piece(piece: Dict[str, Any]) -> bool:
    return not pathish_piece(piece)


def filter_pieces_for_surface(
    pieces: list[Dict[str, Any]],
    surface: str,
) -> list[Dict[str, Any]]:
    if surface == "all":
        return pieces
    if surface == "paths":
        return [piece for piece in pieces if pathish_piece(piece)]
    return [piece for piece in pieces if road_piece(piece)]


def manifest_name_for_surface(surface: str) -> str:
    if surface == "paths":
        return "path_piece_manifest.game32.json"
    return "road_piece_manifest.game32.json"


def write_json(path: Path, data: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def resolve_piece_path(
    manifest_path: Path, manifest: Dict[str, Any], piece_file: str
) -> Path:
    piece_path = Path(piece_file)

    if piece_path.is_absolute():
        return piece_path

    export_root = manifest.get("export_root")
    if export_root:
        candidate = Path(export_root) / piece_path
        if candidate.exists():
            return candidate

    candidate = manifest_path.parent / piece_path
    if candidate.exists():
        return candidate

    return manifest_path.parent / "pieces" / piece_path.name


def output_root_from_manifest(manifest_path: Path, manifest: Dict[str, Any]) -> Path:
    export_root = manifest.get("export_root")

    if export_root:
        root = Path(export_root)
        return root.parent / f"{root.name}_game32"

    return manifest_path.parent.parent / "road_piece_exports_game32"


def target_size_for_piece(
    original_w: int,
    original_h: int,
    tile_size: int,
    kind: str,
    force_square_intersections: bool,
    min_tiles_w: int,
    min_tiles_h: int,
) -> Tuple[int, int]:
    target_w = max(ceil_to_multiple(original_w, tile_size), min_tiles_w * tile_size)
    target_h = max(ceil_to_multiple(original_h, tile_size), min_tiles_h * tile_size)

    if force_square_intersections and kind in {
        "cross",
        "tee",
        "corner",
        "corner_small",
    }:
        side = max(target_w, target_h)
        side = ceil_to_multiple(side, tile_size)
        target_w = side
        target_h = side

    return target_w, target_h


def socket_points_px(w: int, h: int) -> Dict[str, Dict[str, int]]:
    return {
        "n": {"x": w // 2, "y": 0},
        "e": {"x": w, "y": h // 2},
        "s": {"x": w // 2, "y": h},
        "w": {"x": 0, "y": h // 2},
    }


def normalize_one_image(
    source_path: Path,
    output_path: Path,
    target_w: int,
    target_h: int,
    scale_art: float,
) -> Dict[str, Any]:
    img = Image.open(source_path).convert("RGBA")
    original_w, original_h = img.size

    if scale_art != 1.0:
        scaled_w = max(1, round(original_w * scale_art))
        scaled_h = max(1, round(original_h * scale_art))
        img = img.resize((scaled_w, scaled_h), Image.Resampling.NEAREST)
    else:
        scaled_w, scaled_h = original_w, original_h

    if scaled_w > target_w or scaled_h > target_h:
        raise ValueError(
            f"Scaled art is larger than target canvas for {source_path.name}: "
            f"scaled={scaled_w}x{scaled_h}, target={target_w}x{target_h}"
        )

    offset_x = (target_w - scaled_w) // 2
    offset_y = (target_h - scaled_h) // 2

    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    canvas.alpha_composite(img, (offset_x, offset_y))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path)

    return {
        "original_size_px": {"w": original_w, "h": original_h},
        "scaled_art_size_px": {"w": scaled_w, "h": scaled_h},
        "art_offset_px": {"x": offset_x, "y": offset_y},
    }


def normalize_manifest(
    manifest_path: Path,
    pathways_json_path: Path | None,
    output_root: Path | None,
    tile_size: int,
    surface: str,
    force_square_intersections: bool,
    min_tiles_w: int,
    min_tiles_h: int,
    scale_art: float,
    overwrite: bool,
) -> Path:
    manifest = load_json(manifest_path)

    if output_root is None:
        output_root = output_root_from_manifest(manifest_path, manifest)

    pieces_dir = output_root / "pieces"
    output_manifest_path = output_root / manifest_name_for_surface(surface)

    if output_root.exists() and overwrite:
        shutil.rmtree(output_root)

    pieces_dir.mkdir(parents=True, exist_ok=True)

    new_manifest = dict(manifest)
    new_manifest["asset_pack"] = f"{manifest.get('asset_pack', 'road_pieces')}_{surface}_game32"
    new_manifest["export_root"] = str(output_root)
    new_manifest["tile_size_px"] = tile_size
    new_manifest["surface"] = surface
    new_manifest["pathways_json"] = str(pathways_json_path) if pathways_json_path else ""
    new_manifest["normalization"] = {
        "mode": "pad_to_32px_game_grid",
        "tile_size_px": tile_size,
        "scale_art": scale_art,
        "resampled": scale_art != 1.0,
        "resample_filter": "nearest",
        "force_square_intersections": force_square_intersections,
        "note": "Default behavior pads transparent canvas; it does not resize the art.",
    }

    if pathways_json_path is not None and pathways_json_path.exists():
        pathways = load_json(pathways_json_path)
        new_manifest["pathways_tileset"] = pathways.get("tileset", {})

    normalized_pieces = []

    source_pieces = filter_pieces_for_surface(manifest.get("pieces", []), surface)

    for piece in source_pieces:
        piece_id = piece["id"]
        kind = piece.get("kind", "unknown")
        src_file = piece["file"]

        source_path = resolve_piece_path(manifest_path, manifest, src_file)
        if not source_path.exists():
            raise FileNotFoundError(
                f"Missing source image for {piece_id}: {source_path}"
            )

        with Image.open(source_path) as probe:
            original_w, original_h = probe.size

        scaled_w = max(1, round(original_w * scale_art))
        scaled_h = max(1, round(original_h * scale_art))

        target_w, target_h = target_size_for_piece(
            original_w=scaled_w,
            original_h=scaled_h,
            tile_size=tile_size,
            kind=kind,
            force_square_intersections=force_square_intersections,
            min_tiles_w=min_tiles_w,
            min_tiles_h=min_tiles_h,
        )

        output_file = f"{piece_id}.png"
        output_path = pieces_dir / output_file

        image_meta = normalize_one_image(
            source_path=source_path,
            output_path=output_path,
            target_w=target_w,
            target_h=target_h,
            scale_art=scale_art,
        )

        new_piece = dict(piece)
        new_piece["file"] = f"pieces/{output_file}"
        new_piece["original_file"] = src_file
        new_piece["original_size_px"] = image_meta["original_size_px"]
        new_piece["scaled_art_size_px"] = image_meta["scaled_art_size_px"]
        new_piece["art_offset_px"] = image_meta["art_offset_px"]

        new_piece["size_px"] = {"w": target_w, "h": target_h}
        new_piece["grid_size_tiles"] = {
            "w": target_w // tile_size,
            "h": target_h // tile_size,
        }

        new_piece["anchor"] = {
            "mode": "center",
            "x": target_w // 2,
            "y": target_h // 2,
        }

        new_piece["socket_points_px"] = socket_points_px(target_w, target_h)

        new_piece["socket_points_normalized"] = {
            "n": {"x": 0.5, "y": 0.0},
            "e": {"x": 1.0, "y": 0.5},
            "s": {"x": 0.5, "y": 1.0},
            "w": {"x": 0.0, "y": 0.5},
        }

        normalized_pieces.append(new_piece)

    new_manifest["pieces"] = normalized_pieces
    new_manifest["pieces"] = normalized_pieces
    new_manifest["piece_count"] = len(normalized_pieces)
    new_manifest["source_piece_count"] = len(manifest.get("pieces", []))

    write_json(output_manifest_path, new_manifest)
    return output_manifest_path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Normalize extracted CUSTODIAN road pieces to 32px grid-aligned game modules."
    )

    parser.add_argument(
        "--manifest",
        required=True,
        help="Path to road_piece_manifest.json from the Aseprite export.",
    )

    parser.add_argument(
        "--pathways-json",
        default=None,
        help="Optional Pathways.json role map to embed in the generated manifest.",
    )

    parser.add_argument(
        "--output-root",
        default=None,
        help="Optional output folder. Default: sibling *_game32 folder.",
    )

    parser.add_argument(
        "--tile-size",
        type=int,
        default=DEFAULT_TILE_SIZE,
        help="Game tile size in pixels. Default: 32.",
    )

    parser.add_argument(
        "--surface",
        choices=["roads", "paths", "all"],
        default="roads",
        help="Which surface family to emit. Default: roads.",
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
        "--scale-art",
        type=float,
        default=1.0,
        help="Optional art scale before padding. Default: 1.0. Usually leave this alone.",
    )

    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Delete existing output folder before writing.",
    )

    args = parser.parse_args()

    manifest_path = Path(args.manifest).expanduser().resolve()
    pathways_json_path = (
        Path(args.pathways_json).expanduser().resolve() if args.pathways_json else None
    )
    output_root = (
        Path(args.output_root).expanduser().resolve() if args.output_root else None
    )

    output_manifest = normalize_manifest(
        manifest_path=manifest_path,
        pathways_json_path=pathways_json_path,
        output_root=output_root,
        tile_size=args.tile_size,
        surface=args.surface,
        force_square_intersections=not args.no_square_intersections,
        min_tiles_w=args.min_tiles_w,
        min_tiles_h=args.min_tiles_h,
        scale_art=args.scale_art,
        overwrite=args.overwrite,
    )

    print(f"{args.surface.capitalize()} piece normalization complete.")
    print(f"New manifest: {output_manifest}")


if __name__ == "__main__":
    main()
