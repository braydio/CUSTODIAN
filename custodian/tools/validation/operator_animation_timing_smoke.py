#!/usr/bin/env python3
"""Focused regression for authored Operator animation-clock timing."""
from __future__ import annotations

import importlib.util
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


def _load_compatibility_module():
    path = PIPELINES / "update_operator_compatibility_resources.py"
    spec = importlib.util.spec_from_file_location("operator_timing_compatibility", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _load_workbench_model():
    path = PROJECT_ROOT / "tools/operator/animation_workbench_model.py"
    spec = importlib.util.spec_from_file_location("operator_timing_workbench", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _animation_block(module, path: Path, name: str) -> str:
    _start, _end, blocks = module._animation_blocks(path.read_text())
    return next(block for block in blocks if f'"name": &"{name}"' in block)


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

    module = _load_compatibility_module()
    compatibility = PROJECT_ROOT / "game/actors/operator/operator_modular_lower_body_frames.tres"
    block = _animation_block(module, compatibility, "unarmed_run_down")
    assert '"speed": 10.0' in block
    assert '"loop": true' in block
    assert [float(value) for value in re.findall(r'"duration": ([0-9.]+)', block)] == EXPECTED

    catalog_resource = PROJECT_ROOT / "game/actors/operator/operator_animation_catalog_frames.tres"
    melee = _animation_block(module, catalog_resource, "melee_1h/locomotion/run_01/s/lower_body")
    assert '"speed": 10.0' in melee
    assert [float(value) for value in re.findall(r'"duration": ([0-9.]+)', melee)] == EXPECTED

    print("operator_animation_timing_smoke: PASS 12f clocks, 60/70/100ms cadence, 920ms loops")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
