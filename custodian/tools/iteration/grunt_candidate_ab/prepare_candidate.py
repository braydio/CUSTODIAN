#!/usr/bin/env python3
"""Build DEV ONLY 96x96 source-comparison frames; never publishes Asset V2 outputs.

Usage from repo root:
python3 custodian/tools/iteration/grunt_candidate_ab/prepare_candidate.py \
  --source custodian/asset_drop/source_work/enemies/grunt_cutout_candidate_v1/raider_humanoid_cutout_turnaround_parts_v1_source.png
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image

# Source regions confirmed by 8-connected alpha inventory of the supplied 1448x1086 RGBA sheet.
# These are full-body reference crops, NOT a valid articulated-part assignment.
VIEWS = {
    "s": {"source": "front", "bbox": (100, 57, 323, 448)},
    "n": {"source": "back", "bbox": (459, 57, 674, 444)},
    "e": {"source": "profile_right", "bbox": (845, 55, 950, 443)},
    "w": {"source": "profile_left", "bbox": (1196, 54, 1300, 443)},
}
TARGET_HEIGHTS = (64, 72, 80)
BASELINE_Y = 80
CELL = 96


def build(source: Path, out: Path) -> None:
    raw = source.read_bytes()
    image = Image.open(source).convert("RGBA")
    if image.size != (1448, 1086):
        raise ValueError(f"Expected the supplied 1448x1086 source, got {image.size}")
    out.mkdir(parents=True, exist_ok=True)
    result = {
        "schema": "custodian.dev_grunt_ab_preview.v1",
        "status": "DEV_ONLY_NOT_ASSET_V2_RUNTIME",
        "source_file": source.name,
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "source_dimensions": [1448, 1086],
        "cell_dimensions": [CELL, CELL],
        "sampling": "PIL_NEAREST_only_no_repaint",
        "baseline_frame_y": BASELINE_Y,
        "height_presets": list(TARGET_HEIGHTS),
        "views": {},
        "notes": "Candidate is a static per-facing silhouette reference, not rigged, animated or an authentic CUSTODIAN Grunt skin. Compare actual Grunt scene locally.",
    }
    for direction, view in VIEWS.items():
        bbox = view["bbox"]
        crop = image.crop(bbox)
        real_bbox = crop.getchannel("A").getbbox()
        if real_bbox is None:
            raise ValueError(f"Empty {direction} crop")
        crop = crop.crop(real_bbox)
        result["views"][direction] = {
            "label": view["source"], "source_bbox": list(bbox),
            "tight_dimensions": list(crop.size), "files": {}
        }
        for h in TARGET_HEIGHTS:
            w = max(1, round(crop.width * h / crop.height))
            if w > CELL or h > CELL:
                raise ValueError(f"Oversize normalized reference {direction}, h{h}")
            thumb = crop.resize((w, h), Image.Resampling.NEAREST)
            sheet = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
            sheet.alpha_composite(thumb, (round((CELL - w) / 2), BASELINE_Y - h))
            name = f"candidate_{direction}_{h}px.png"
            sheet.save(out / name)
            result["views"][direction]["files"][str(h)] = name
    (out / "preview_manifest.json").write_text(json.dumps(result, indent=2) + "\n")
    print(f"Generated {len(VIEWS) * len(TARGET_HEIGHTS)} DEV preview frames in {out}")
    print("Source SHA-256", result["source_sha256"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--out", type=Path, default=Path("custodian/tools/iteration/grunt_candidate_ab/generated"))
    args = parser.parse_args()
    build(args.source, args.out)
