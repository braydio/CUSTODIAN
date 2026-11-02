#!/usr/bin/env python3
"""Remap the live Sundered Keep ocean runtime to the cosmic ocean art pack.

This keeps the existing Sundered Keep runtime ids stable:
`ocean_dark_water_01`, `ocean_foam_edge_n/e/s/w`.

The only directional gap in the cosmic source pack is the east shoreline edge,
so the script synthesizes `ocean_foam_edge_e` as a mirrored derivative of the
west foam edge.
"""
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path
from typing import Dict, Any

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE_DIR = ROOT / "custodian" / "content" / "tiles" / "terrain" / "cosmic_ocean" / "game32"
RUNTIME_DIR = ROOT / "custodian" / "content" / "runtime" / "sundered_keep" / "terrain" / "ocean"


MAPPING = {
    "ocean_dark_water_01": {
        "source_png": "cosmic_ocean_void_fill_deep_space_01.png",
        "transform": "copy",
        "source_asset_id": "cosmic_ocean_void_fill_deep_space_01",
    },
    "ocean_foam_edge_n": {
        "source_png": "cosmic_ocean_shore_n_foam_01.png",
        "transform": "copy",
        "source_asset_id": "cosmic_ocean_shore_n_foam_01",
    },
    "ocean_foam_edge_s": {
        "source_png": "cosmic_ocean_shore_s_foam_01.png",
        "transform": "copy",
        "source_asset_id": "cosmic_ocean_shore_s_foam_01",
    },
    "ocean_foam_edge_w": {
        "source_png": "cosmic_ocean_shore_w_foam_01.png",
        "transform": "copy",
        "source_asset_id": "cosmic_ocean_shore_w_foam_01",
    },
    "ocean_foam_edge_e": {
        "source_png": "cosmic_ocean_shore_w_foam_01.png",
        "transform": "mirror_x",
        "source_asset_id": "cosmic_ocean_shore_w_foam_01",
    },
}


def load_json(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: Dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def remap_asset(asset_name: str, dry_run: bool) -> Dict[str, Any]:
    spec = MAPPING[asset_name]
    source_png = SOURCE_DIR / spec["source_png"]
    runtime_png = RUNTIME_DIR / f"{asset_name}.png"
    runtime_json = RUNTIME_DIR / f"{asset_name}.game32.json"

    if not source_png.exists():
        raise FileNotFoundError(source_png)
    if not runtime_json.exists():
        raise FileNotFoundError(runtime_json)

    if not dry_run:
        runtime_png.parent.mkdir(parents=True, exist_ok=True)
        img = Image.open(source_png).convert("RGBA")
        if spec["transform"] == "mirror_x":
            img = img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        img.save(runtime_png)

        meta = load_json(runtime_json)
        meta.setdefault("editor", {})
        meta["editor"]["notes"] = (
            "Live Sundered Keep ocean runtime remapped from the cosmic ocean pack. "
            f"Source asset: {spec['source_asset_id']} ({spec['transform']})."
        )
        meta["source_remap"] = {
            "source_dir": str(SOURCE_DIR.relative_to(ROOT)),
            "source_png": spec["source_png"],
            "source_asset_id": spec["source_asset_id"],
            "transform": spec["transform"],
        }
        write_json(runtime_json, meta)

    return {
        "asset": asset_name,
        "source_png": str(source_png.relative_to(ROOT)),
        "runtime_png": str(runtime_png.relative_to(ROOT)),
        "transform": spec["transform"],
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Print the planned remap without writing files.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    results = [remap_asset(name, args.dry_run) for name in MAPPING]
    print(json.dumps({"dry_run": args.dry_run, "results": results}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
