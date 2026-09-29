#!/usr/bin/env python3
"""Build the compact ROI evidence sheet for the five late Awakening seams.

Structural registration/alpha/order/order facts for all five late seams
(05-06, 06-07, 07-08, 08-10, 08-09) already run for free via the generic
Moment Forge probes/assertions in
`custodian/tools/iteration/scenarios/traversal/awakening_late_seams_v1.json`
under `--capture-mode none`. This script is the optional, explicitly-invoked
escalation: it turns that scenario's one `--capture-mode evidence` run into a
single small ROI contact sheet plus a void/matte sanity check, instead of
routine full-frame inspection of five 1280x720 screenshots. See the Visual
Validation Economy section of `custodian/AGENTS.md`.

Usage:
    python3 custodian/tools/iteration/run_moment.py \\
        traversal/awakening_late_seams_v1 --capture-mode evidence
    python3 custodian/tools/validation/awakening_late_seams_evidence.py \\
        <the run directory printed above>
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ITERATION_DIR = Path(__file__).resolve().parents[1] / "iteration"
sys.path.insert(0, str(ITERATION_DIR))

from build_moment_report import build_roi_contact_sheet  # noqa: E402
from presentation_image_metrics import analyze  # noqa: E402

# (seam id, contact_sheet tick that frames it) - see the scenario's setup/timeline.
SEAMS = [
    ("05_06", 30),
    ("06_07", 95),
    ("07_08", 160),
    ("08_10", 225),
    ("08_09", 290),
]
# Centered band around the framed seam boundary (screen center is 640, 360 at
# 1280x720); tight enough to be compact, wide enough to show the join.
SEAM_ROI = [440, 260, 400, 200]


def build(run_dir: Path, output_dir: Path) -> dict[str, Path]:
    keyframes = run_dir / "keyframes"
    cells = []
    images: dict[str, str] = {}
    rois: dict[str, dict] = {}
    checks: list[dict] = []
    for seam_id, tick in SEAMS:
        frame = keyframes / f"tick_{tick:06d}.png"
        if not frame.is_file():
            raise FileNotFoundError(f"missing seam keyframe: {frame}")
        cells.append({"label": f"seam {seam_id}", "image": frame, "rect": SEAM_ROI})
        images[seam_id] = str(frame.resolve())
        rois[seam_id] = {"image": seam_id, "rect": SEAM_ROI}
        checks.append({"type": "matte_void", "roi": seam_id, "max_void_ratio": 0.98})
    output_dir.mkdir(parents=True, exist_ok=True)
    sheet_path = build_roi_contact_sheet(cells, output_dir / "awakening_late_seams_roi_sheet.png")
    metrics = analyze({"images": images, "rois": rois, "checks": checks}, Path("/"))
    metrics_path = output_dir / "awakening_late_seams_roi_metrics.json"
    metrics_path.write_text(json.dumps(metrics, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return {"sheet": sheet_path, "metrics": metrics_path}


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "run_dir",
        type=Path,
        help="a --capture-mode evidence run directory for traversal/awakening_late_seams_v1",
    )
    parser.add_argument("--output-dir", type=Path, default=None, help="defaults to run_dir")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    output_dir = args.output_dir or args.run_dir
    try:
        result = build(args.run_dir, output_dir)
    except (FileNotFoundError, ValueError) as exc:
        print(f"awakening_late_seams_evidence error: {exc}", file=sys.stderr)
        return 2
    print(f"ROI sheet: {result['sheet']}")
    print(f"Metrics:   {result['metrics']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
