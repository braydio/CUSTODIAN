#!/usr/bin/env python3
"""Stage only contract-valid normalized Awakening outputs."""
from __future__ import annotations
import argparse, json, shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
READY = ROOT / "asset_drop/source_work/awakening/_normalized_ready"
INBOX = ROOT / "asset_drop/inbox"

def main() -> int:
    parser = argparse.ArgumentParser(); parser.add_argument("--family", required=True); args = parser.parse_args()
    contract = json.loads((ROOT / f"content/metadata/assets/families/{args.family}.asset.json").read_text())
    family_ready = READY / args.family
    manifest = {"schema": "custodian.awakening_staging.v1", "family": args.family, "items": []}
    if not family_ready.exists(): raise SystemExit(f"normalized directory missing: {family_ready}")
    for state, spec in contract["states"].items():
        source = family_ready / f"{state}.png"
        if not source.exists(): continue
        target = (int(spec["frame_width"]), int(spec["frame_height"]))
        frames = int(spec.get("frames", spec.get("frame_count", 1)))
        expected = (target[0] * frames, target[1]) if spec.get("layout") == "horizontal_strip" else target
        with Image.open(source) as image:
            actual = image.size
            if actual != expected: raise SystemExit(f"{source}: {actual} != {expected}")
            if image.mode != "RGBA": raise SystemExit(f"{source}: expected RGBA")
        destination = INBOX / args.family / f"{state}.png"; destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        manifest["items"].append({"family": args.family, "state": state, "normalized": str(source), "destination": str(destination), "size": list(actual), "status": "staged"})
    (INBOX / "awakening_ingest_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return 0

if __name__ == "__main__": raise SystemExit(main())
