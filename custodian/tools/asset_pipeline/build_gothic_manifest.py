#!/usr/bin/env python3
"""
build_gothic_manifest.py

Scans all gothic assets across content/ and writes a unified master manifest at:
  custodian/content/gothic_manifest.game32.json
"""

from __future__ import annotations

import json
import os
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image

CONTENT_ROOT = Path(__file__).resolve().parent.parent / "content"
OUTPUT_PATH = CONTENT_ROOT / "gothic_manifest.game32.json"

# Define sections: (label, glob_base, path_prefix_in_manifest)
SECTIONS = [
    ("tiles", "tiles/gothic"),
    ("tiles_interiors", "tiles/interiors/gothic"),
    ("props", "props/gothic"),
    ("structures", "structures/gothic"),
    ("doors", "doors/gothic"),
    ("walls", "walls/gothic"),
    ("roads", "tiles/roads_paths/runtime/roads/gothic"),
    ("road_compound", "tiles/roads_paths/runtime/gothic_compound"),
    ("animations", "animations/gothic"),
    ("rooms", "procgen/special_rooms/gothic_compound"),
]


def find_sub_manifest(base_dir: Path) -> str | None:
    """Check for a game32 manifest in base_dir."""
    for f in base_dir.glob("*.game32.json"):
        return f"res://content/{f.relative_to(CONTENT_ROOT)}"
    for f in base_dir.glob("manifest.json"):
        return f"res://content/{f.relative_to(CONTENT_ROOT)}"
    return None


def collect_pngs(base_dir: Path) -> list[dict]:
    """Recursively collect all PNGs under base_dir with metadata."""
    assets = []
    if not base_dir.exists():
        return assets

    for fpath in sorted(base_dir.rglob("*.png")):
        if ".import" in str(fpath):
            continue
        rel = str(fpath.relative_to(CONTENT_ROOT))
        name = fpath.stem
        try:
            img = Image.open(fpath)
            w, h = img.size
        except Exception:
            w, h = 0, 0

        # Derive subtype from directory structure
        parents = fpath.relative_to(CONTENT_ROOT).parts
        subtype = "unknown"
        if len(parents) >= 3:
            subtype = parents[2]
        if len(parents) >= 4:
            subtype = "/".join(parents[2:4])

        assets.append({
            "id": name,
            "path": rel,
            "subtype": subtype,
            "pixel_size": {"w": w, "h": h},
        })
    return assets


def main() -> int:
    sections = {}
    total = 0

    for label, glob_base in SECTIONS:
        base = CONTENT_ROOT / glob_base
        assets = collect_pngs(base)
        sub_manifest = find_sub_manifest(base)
        if assets:
            entry = {
                "base_path": f"res://content/{glob_base}",
                "count": len(assets),
            }
            if sub_manifest:
                entry["manifest"] = sub_manifest
            entry["assets"] = assets
            sections[label] = entry
            total += len(assets)
            ref = f"  manifest: {sub_manifest}" if sub_manifest else ""
            print(f"  {label:20s}  {len(assets):4d} assets  @ {glob_base}{ref}")
        else:
            print(f"  {label:20s}  {'(empty)'}")

    manifest = {
        "schema": "game32.gothic_master_manifest.v1",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "total_asset_count": total,
        "section_count": len(sections),
        "sections": sections,
    }

    OUTPUT_PATH.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"\nWrote {total} assets across {len(sections)} sections → {OUTPUT_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
