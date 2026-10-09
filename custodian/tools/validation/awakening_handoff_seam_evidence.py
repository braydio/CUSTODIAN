#!/usr/bin/env python3
"""Emit five compact Awakening handoff seam ROIs and technical pixel metrics.

Input is one evidence run of traversal/awakening_late_seams_v1. The metrics are
technical measurements for review; this tool does not approve visual composition.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from PIL import Image

ITERATION_DIR = Path(__file__).resolve().parents[1] / "iteration"
sys.path.insert(0, str(ITERATION_DIR))

from build_moment_report import build_roi_contact_sheet  # noqa: E402
from presentation_image_metrics import analyze  # noqa: E402

SEAMS = [
    ("01_dust_lung_undergate", 330, "horizontal", 100),
    ("02_undergate_gate", 390, "horizontal", 100),
    ("03_gate_approach", 450, "horizontal", 100),
    ("04_approach_road", 510, "horizontal", 100),
    ("05_approach_late_service", 570, "vertical", 200),
]
ROI = [440, 260, 400, 200]


def build(run_dir: Path, output_dir: Path) -> dict[str, Any]:
    keyframes = run_dir / "keyframes"
    images: dict[str, str] = {}
    rois: dict[str, dict[str, Any]] = {}
    cells = []
    checks = []
    capture_entries = []
    crop_dir = output_dir / "seam_rois"
    crop_dir.mkdir(parents=True, exist_ok=True)
    for seam_id, tick, axis, boundary in SEAMS:
        source = keyframes / f"tick_{tick:06d}.png"
        if not source.is_file():
            raise FileNotFoundError(f"missing {seam_id} keyframe: {source}")
        with Image.open(source) as frame:
            x, y, width, height = ROI
            if x + width > frame.width or y + height > frame.height:
                raise ValueError(f"ROI exceeds {source} bounds {frame.size}")
            crop_path = crop_dir / f"{seam_id}.png"
            frame.crop((x, y, x + width, y + height)).save(crop_path)
        images[seam_id] = str(source.resolve())
        rois[seam_id] = {"image": seam_id, "rect": ROI}
        cells.append({"label": seam_id.replace("_", " "), "image": crop_path})
        capture_entries.append({
            "order": len(capture_entries) + 1,
            "seam": seam_id,
            "tick": tick,
            "source_keyframe": str(source.resolve()),
            "roi": ROI,
            "capture": str(crop_path.resolve()),
        })
        checks.extend([
            {"type": "matte_void", "roi": seam_id},
            {"type": "seam_discontinuity", "roi": seam_id, "axis": axis,
             "boundary": boundary, "band": 2},
        ])
    sheet = build_roi_contact_sheet(cells, output_dir / "awakening_handoff_seam_contact_sheet.png")
    metrics = analyze({"images": images, "rois": rois, "checks": checks}, Path("/"))
    metrics_path = output_dir / "awakening_handoff_seam_metrics.json"
    metrics_path.write_text(json.dumps(metrics, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    manifest_path = output_dir / "awakening_handoff_seam_capture_manifest.json"
    manifest_path.write_text(json.dumps({
        "schema": "custodian.awakening_handoff_seam_capture_manifest.v1",
        "scenario": "traversal/awakening_late_seams_v1",
        "capture_mode": "evidence",
        "captures": capture_entries,
        "metrics": str(metrics_path.resolve()),
        "contact_sheet": str(sheet.resolve()),
        "human_approval_required": True,
        "agent_visual_adjudication": False,
    }, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return {
        "roi_dir": crop_dir.resolve(), "sheet": sheet,
        "metrics": metrics_path.resolve(), "manifest": manifest_path.resolve(),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_dir", type=Path)
    parser.add_argument("--output-dir", type=Path, default=None)
    args = parser.parse_args(argv)
    output_dir = args.output_dir or args.run_dir
    try:
        result = build(args.run_dir, output_dir)
    except (FileNotFoundError, ValueError) as error:
        print(f"awakening_handoff_seam_evidence error: {error}", file=sys.stderr)
        return 2
    print(f"ROI captures: {result['roi_dir']}")
    print(f"Contact sheet: {result['sheet']}")
    print(f"Metrics: {result['metrics']}")
    print(f"Capture manifest: {result['manifest']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
