#!/usr/bin/env python3
"""Conservative, contract-driven normalization for Awakening art."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "asset_drop/source_work/awakening"
READY = SOURCE / "_normalized_ready"

APPROVED = {
    "awakening_late_service_environment": {
        "underlay": ("late_service/late_service_underlay.png", (704, 768), "pair"),
        "foreground": ("late_service/late_service_foreground.png", (704, 768), "pair"),
    },
}

def family_contract(family: str) -> dict:
    return json.loads((ROOT / f"content/metadata/assets/families/{family}.asset.json").read_text())

def normalize_pair(source: Path, target: tuple[int, int]) -> Image.Image:
    with Image.open(source) as image:
        rgba = image.convert("RGBA")
    return rgba.resize(target, Image.Resampling.LANCZOS)

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--family", default="awakening_late_service_environment")
    args = parser.parse_args()
    if args.family not in APPROVED:
        raise SystemExit(f"no approved mapping for {args.family}")
    contract = family_contract(args.family)
    report = {"family": args.family, "items": [], "warnings": []}
    for state, (relative, target, mode) in APPROVED[args.family].items():
        source = SOURCE / relative
        if not source.exists():
            report["items"].append({"state": state, "status": "missing", "source": str(source)})
            continue
        expected = tuple(contract["states"][state][key] for key in ("frame_width", "frame_height"))
        if expected != target:
            raise SystemExit(f"{args.family}/{state}: mapping {target} disagrees with contract {expected}")
        output = READY / args.family / f"{state}.png"
        output.parent.mkdir(parents=True, exist_ok=True)
        image = normalize_pair(source, target)
        image.save(output)
        report["items"].append({"family": args.family, "state": state, "source": str(source), "normalized": str(output), "target": list(target), "final": list(image.size), "mode": mode, "status": "ok"})
    (READY / "awakening_normalization_report.json").write_text(json.dumps(report, indent=2) + "\n")
    (READY / "awakening_normalization_report.txt").write_text("\n".join(f"{i['state']}: {i['status']} {i.get('final', '')}" for i in report["items"]) + "\n")
    return 0 if all(i["status"] == "ok" for i in report["items"]) else 1

if __name__ == "__main__":
    raise SystemExit(main())
