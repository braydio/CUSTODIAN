#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "custodian/tools/iteration"))
from build_moment_report import build_report
from run_moment import load_scenarios


def write(path: Path, value: object) -> None:
    path.write_text(json.dumps(value), encoding="utf-8")


def main() -> int:
    scenario = load_scenarios()["combat/light_hit_grunt"]
    with tempfile.TemporaryDirectory(dir=ROOT / "reports") as raw:
        run = Path(raw)
        write(run / "run_result.json", {
            "passed": True, "capture_mode": "none", "assertions": [],
            "runtime": {}, "scenario_path": "fixture",
        })
        write(run / "metrics.json", {"completed": True})
        write(run / "timeline.json", [])
        write(run / "probes.json", {"records": [], "failures": []})
        write(run / "assertions.json", [])
        write(run / "telemetry.json", {"events": [], "warnings": []})
        manifest = build_report(run, scenario, ROOT, build_video=False)
        assert manifest["stable_assertions_passed"]
        assert (run / "index.html").is_file()
        assert manifest["artifacts"]["contact_sheet"] is None
    print("Moment Forge report smoke: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
