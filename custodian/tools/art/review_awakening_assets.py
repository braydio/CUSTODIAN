#!/usr/bin/env python3
"""Inventory Awakening source art without guessing strips from aspect ratio."""
from __future__ import annotations
import argparse, hashlib, json, re
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "asset_drop/source_work/awakening"

def main() -> int:
    parser = argparse.ArgumentParser(); parser.add_argument("--output", default=str(SOURCE / "_asset_review_inventory.json")); args = parser.parse_args()
    rows = []
    for path in sorted(SOURCE.rglob("*.png")):
        if any(part.startswith("_") for part in path.relative_to(SOURCE).parts): continue
        with Image.open(path) as image:
            image.load(); alpha = image.getchannel("A").getextrema() if "A" in image.getbands() else None
            explicit_frames = re.search(r"(?:^|[_-])(\d+)f(?:[_-]|\.)", path.name, re.I)
            rows.append({"path": str(path), "size": list(image.size), "mode": image.mode, "alpha": alpha, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "inferred_frames": int(explicit_frames.group(1)) if explicit_frames else None})
    Path(args.output).write_text(json.dumps({"schema": "custodian.awakening_review.v1", "assets": rows}, indent=2) + "\n")
    print(f"reviewed {len(rows)} PNGs; strips require explicit Nf naming or resolved animation contract")
    return 0

if __name__ == "__main__": raise SystemExit(main())
