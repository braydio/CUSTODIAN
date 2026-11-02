#!/usr/bin/env python3
"""Prepare complete painted procgen underlay compositions for V2 intake."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageEnhance

SIZE = (1536, 1024)
MAPPING = {
    "far_depth_a_master_1536x1024.png": "far_depth_a.png",
    "far_depth_b_master_1536x1024.png": "far_depth_b.png",
    "drowned_basilica_ruin_field_a_1536x1024.png": "ruin_field_a.png",
    "drowned_basilica_ruin_field_b_1536x1024.png": "ruin_field_b.png",
    "drowned_basilica_near_wall_a_1536x1024.png": "near_wall_a.png",
    "drowned_basilica_near_wall_b_1536x1024.png": "near_wall_b.png",
}


def cover_fit(image: Image.Image) -> Image.Image:
    scale = max(SIZE[0] / image.width, SIZE[1] / image.height)
    scaled = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = (scaled.width - SIZE[0]) // 2
    top = (scaled.height - SIZE[1]) // 2
    return scaled.crop((left, top, left + SIZE[0], top + SIZE[1]))


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--report-json", type=Path)
    args = parser.parse_args()
    report = {"source": str(args.source), "destination": str(args.destination), "target_size": SIZE, "files": []}
    for source_name, output_name in MAPPING.items():
        source = args.source / source_name
        if not source.is_file():
            raise SystemExit(f"missing source: {source}")
        with Image.open(source) as image:
            original_size = image.size
            converted = image.convert("RGBA") if image.mode not in ("RGB", "RGBA") else image.copy()
            output = cover_fit(converted)
            item = {"source": source_name, "output": output_name, "original_size": original_size, "output_size": output.size, "source_sha256": sha(source), "resample": "cover_fit_center_crop"}
            report["files"].append(item)
            if not args.dry_run:
                args.destination.mkdir(parents=True, exist_ok=True)
                output.save(args.destination / output_name, "PNG", optimize=False, compress_level=6)
            print(f"{source_name}: {original_size} -> {output.size}; cover-fit center crop")
    if args.report_json:
        args.report_json.parent.mkdir(parents=True, exist_ok=True)
        args.report_json.write_text(json.dumps(report, indent=2) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
