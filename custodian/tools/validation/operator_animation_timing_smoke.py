#!/usr/bin/env python3
"""Focused regression for authored Operator animation-clock timing."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = PROJECT_ROOT.parent
PIPELINES = PROJECT_ROOT / "tools/pipelines"
sys.path.insert(0, str(PIPELINES))

import sync_operator_runtime_assets as syncer  # noqa: E402


EXPECTED = [0.6, 0.7, 1.0] * 4
EXPECTED_MS = [60.0, 70.0, 100.0] * 4
PROFILES = ("unarmed", "melee_1h")


def _load_workbench_model():
    import importlib.util

    path = PROJECT_ROOT / "tools/operator/animation_workbench_model.py"
    spec = importlib.util.spec_from_file_location("operator_timing_workbench", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def main() -> int:
    manifest = json.loads(syncer.RUNTIME_MANIFEST_PATH.read_text())
    catalog = json.loads(syncer.ANIMATION_CATALOG_PATH.read_text())
    for profile in PROFILES:
        source_png = next((
            PROJECT_ROOT / f"content/sprites/operator/source/animations/{profile}/locomotion/run_01"
        ).glob(f"operator__lower_body__{profile}__locomotion__run_01__s__12f__96.png"))
        source_timing = syncer.read_timing(source_png)
        assert source_timing is not None
        assert source_timing["frames"] == 12
        assert source_timing["fps"] == 10.0
        assert source_timing["loop"] is True
        assert source_timing["durations"] == EXPECTED
        milliseconds = [round(duration / source_timing["fps"] * 1000.0, 6) for duration in EXPECTED]
        assert milliseconds == EXPECTED_MS
        assert round(sum(milliseconds), 6) == 920.0

        runtime_png = PROJECT_ROOT / syncer.canonical_runtime_path(syncer.parse_filename(source_png))
        assert syncer.read_timing(runtime_png) == source_timing
        identity = f"{profile}/locomotion/run_01/s"
        expected_clock = {"clock_layer": "lower_body", "fps": 10.0,
                          "loop": True, "durations": EXPECTED}
        assert manifest["animations"][identity]["timing"] == expected_clock
        assert catalog["animations"][identity]["timing"] == expected_clock

    workbench = _load_workbench_model()
    for profile in PROFILES:
        timeline = workbench.build_plan(profile, "run_01", "s", group="locomotion")["timeline"]
        assert timeline["timing_authority"] is True
        assert timeline["clock_owner"] == "lower_body"
        assert timeline["fps"] == 10.0 and timeline["loop"] is True
        assert timeline["durations"] == EXPECTED
        assert [round(value, 6) for value in timeline["frame_durations_ms"]] == EXPECTED_MS

    print("operator_animation_timing_smoke: PASS source/runtime timing metadata, 60/70/100ms cadence, 920ms loops")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
