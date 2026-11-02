#!/usr/bin/env python3
"""Prove sparse Moment Forge evidence capture completes with all keyframes."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RUNNER = ROOT / "custodian/tools/iteration/run_moment.py"
SCENARIO_ID = "validation/evidence_capture"
CAPTURE_TICKS = (1, 4, 7, 10, 13, 16)


def main() -> int:
    run_id = f"evidence-capture-smoke-{os.getpid()}"
    run_dir = ROOT / "reports/moment_forge" / SCENARIO_ID / run_id
    completed = subprocess.run(
        [
            sys.executable,
            str(RUNNER),
            SCENARIO_ID,
            "--capture-mode",
            "evidence",
            "--run-id",
            run_id,
        ],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
        timeout=30,
    )
    if completed.returncode != 0:
        print(completed.stdout, file=sys.stderr)
        print(completed.stderr, file=sys.stderr)
        raise AssertionError(f"evidence capture exited {completed.returncode}")

    result = json.loads((run_dir / "run_result.json").read_text())
    assert result["completed"] is True
    assert result["passed"] is True
    assert len(result["keyframes"]) == len(CAPTURE_TICKS)
    assert [item["tick"] for item in result["keyframes"]] == list(CAPTURE_TICKS)
    for tick in CAPTURE_TICKS:
        keyframe = run_dir / "keyframes" / f"tick_{tick:06d}.png"
        assert keyframe.is_file() and keyframe.stat().st_size > 0, keyframe
    shutil.rmtree(run_dir)

    print("Moment Forge evidence capture smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
