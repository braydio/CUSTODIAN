#!/usr/bin/env python3
"""
slice_128_directional_tiles.py

Cuts cardinal + diagonal 32x32 directional tiles from a 128x128 source tile.

Assumes the source image is a 4x4 grid of 32px cells:

  NW   N1   N2   NE
  W1   C1   C2   E1
  W2   C3   C4   E2
  SW   S1   S2   SE

Default output chooses the most useful directional cells:
  nw = (0,0)
  n  = (1,0)
  ne = (3,0)
  w  = (0,1)
  e  = (3,1)
  sw = (0,3)
  s  = (1,3)
  se = (3,3)

Use --include-cardinal-variants to also output n_02/e_02/s_02/w_02.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from PIL import Image

TILE_SIZE = 32
EXPECTED_SIZE = (128, 128)

PRIMARY_CROPS = {
    "nw": (0, 0),
    "n": (1, 0),
    "ne": (3, 0),
    "w": (0, 1),
    "e": (3, 1),
    "sw": (0, 3),
    "s": (1, 3),
    "se": (3, 3),
}

CARDINAL_VARIANTS = {
    "n_02": (2, 0),
    "e_02": (3, 2),
    "s_02": (2, 3),
    "w_02": (0, 2),
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def crop_cell(img: Image.Image, grid_x: int, grid_y: int) -> Image.Image:
    x0 = grid_x * TILE_SIZE
    y0 = grid_y * TILE_SIZE
    return img.crop((x0, y0, x0 + TILE_SIZE, y0 + TILE_SIZE))


def write_game32_sidecar(
    json_path: Path,
    asset_id: str,
    png_path: Path,
    source_path: Path,
    direction: str,
    grid_cell: tuple[int, int],
    domain: str,
) -> None:
    sidecar = {
        "schema": "custodian.game32.asset.v1",
        "id": asset_id,
        "name": asset_id,
        "asset_class": "directional_tile",
        "domain": domain,
        "generated_at_utc": utc_now(),
        "generator": "custodian/tools/art/slice_128_directional_tiles.py",
        "source": {
            "source_path": str(source_path),
            "source_size_px": [128, 128],
            "grid_cell": list(grid_cell),
            "crop_box_px": [
                grid_cell[0] * TILE_SIZE,
                grid_cell[1] * TILE_SIZE,
                grid_cell[0] * TILE_SIZE + TILE_SIZE,
                grid_cell[1] * TILE_SIZE + TILE_SIZE,
            ],
        },
        "runtime_path": str(png_path),
        "size_px": [32, 32],
        "tile_size_px": 32,
        "game32": {
            "logical_footprint_cells": [1, 1],
            "anchor": "top_left",
            "pivot": "top_left",
            "placement_rule": "snap_to_grid32",
            "orientation": direction,
            "z_layer": "ground",
            "z_index": 0,
            "y_sort": False,
            "walkable": True,
            "blocks_movement": False,
            "blocks_projectiles": False,
            "blocks_vision": False,
            "collision": {
                "enabled": False,
                "profile": "none",
                "shape": "none",
            },
            "navigation": {
                "can_pathfind": True,
                "cost": 1.0,
            },
            "render": {
                "import_filter": "nearest_or_disabled_in_godot",
                "mipmaps": False,
            },
        },
    }

    json_path.write_text(json.dumps(sidecar, indent=2) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="128x128 source image.")
    parser.add_argument("--out-dir", required=True, help="Output directory.")
    parser.add_argument(
        "--prefix",
        default="directional_tile",
        help="Output filename prefix, e.g. entrance_causeway_edge.",
    )
    parser.add_argument(
        "--domain",
        default="directional_edges",
        help="game32 domain name.",
    )
    parser.add_argument(
        "--include-cardinal-variants",
        action="store_true",
        help="Also output n_02/e_02/s_02/w_02 from the second cardinal cells.",
    )
    parser.add_argument(
        "--game32",
        action="store_true",
        help="Also write .game32.json sidecars.",
    )

    args = parser.parse_args()

    source_path = Path(args.input).expanduser().resolve()
    out_dir = Path(args.out_dir).expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    img = Image.open(source_path).convert("RGBA")

    if img.size != EXPECTED_SIZE:
        raise SystemExit(f"Expected 128x128 image, got {img.size}: {source_path}")

    crops = dict(PRIMARY_CROPS)
    if args.include_cardinal_variants:
        crops.update(CARDINAL_VARIANTS)

    written = []

    for direction, grid_cell in crops.items():
        tile = crop_cell(img, *grid_cell)

        asset_id = f"{args.prefix}_{direction}"
        png_path = out_dir / f"{asset_id}.png"
        tile.save(png_path)

        if args.game32:
            json_path = out_dir / f"{asset_id}.game32.json"
            write_game32_sidecar(
                json_path=json_path,
                asset_id=asset_id,
                png_path=png_path,
                source_path=source_path,
                direction=direction,
                grid_cell=grid_cell,
                domain=args.domain,
            )

        written.append(png_path)

    manifest = {
        "schema": "custodian.directional_tile_slice_manifest.v1",
        "source": str(source_path),
        "generated_at_utc": utc_now(),
        "tile_size_px": 32,
        "source_size_px": [128, 128],
        "prefix": args.prefix,
        "domain": args.domain,
        "include_cardinal_variants": args.include_cardinal_variants,
        "count": len(written),
        "outputs": [str(p) for p in written],
    }

    (out_dir / f"{args.prefix}_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n"
    )

    print(f"Wrote {len(written)} tiles to {out_dir}")
    for p in written:
        print(p)


if __name__ == "__main__":
    main()
