#!/usr/bin/env python3
"""Regression smoke for the canonical Operator V2 ingest/build pipeline."""
from __future__ import annotations

import json
import sys
import tempfile
import types
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PIPELINES = PROJECT_ROOT / "tools" / "pipelines"
sys.path.insert(0, str(PIPELINES))

import sync_operator_runtime_assets as builder  # noqa: E402
import generate_inbox_manifests as manifests  # noqa: E402
from operator_asset_schema import parse_filename  # noqa: E402


def _write_strip(path: Path, frames: int, width: int, height: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGBA", (frames * width, height), (255, 255, 255, 255)).save(path)


def _write_timing(path: Path, frames: int, durations: list[float]) -> None:
    builder.timing_sidecar_path(path).write_text(json.dumps({
        "schema": builder.TIMING_SCHEMA,
        "frames": frames,
        "fps": 10.0,
        "loop": True,
        "durations": durations,
    }))


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="operator-v2-pipeline-") as temp:
        root = Path(temp)

        # Targeted manifest generation must carry the same selection into the
        # downstream Godot ingest; otherwise a second unrelated inbox manifest
        # is silently processed as well.
        targeted_inbox = root / "content/sprites/_pipeline/inbox"
        targeted_inbox.mkdir(parents=True)
        first = targeted_inbox / "operator__upper_body__unarmed__locomotion__walk_01__e__2f__96.png"
        second = targeted_inbox / "operator__upper_body__unarmed__locomotion__run_01__e__2f__96.png"
        _write_strip(first, 2, 96, 96)
        _write_strip(second, 2, 96, 96)
        captured: list[list[str]] = []
        original_inbox, original_project, original_ingest, original_argv, original_run = (
            manifests.INBOX_DIR, manifests.PROJECT_DIR, manifests.INGEST_SCRIPT, sys.argv[:], manifests.subprocess.run
        )
        try:
            manifests.INBOX_DIR = targeted_inbox
            manifests.PROJECT_DIR = root
            manifests.INGEST_SCRIPT = root / "ingest.py"
            manifests.subprocess.run = lambda command, **_kwargs: (
                captured.append(command) or types.SimpleNamespace(returncode=0)
            )
            sys.argv = ["generate_inbox_manifests.py", "--manifest", first.name]
            assert manifests.main() == 0
        finally:
            manifests.INBOX_DIR, manifests.PROJECT_DIR, manifests.INGEST_SCRIPT = (
                original_inbox, original_project, original_ingest
            )
            manifests.subprocess.run = original_run
            sys.argv = original_argv
        assert captured and captured[0].count("--manifest") == 1
        assert first.with_suffix(".json").as_posix() in captured[0]
        assert second.with_suffix(".json").as_posix() not in captured[0]
        assert first.with_suffix(".json").exists()
        assert not second.with_suffix(".json").exists()

        source = root / "source"
        runtime = root / "content/sprites/operator/runtime/animations"
        manifest_path = root / "content/sprites/operator/runtime/operator_runtime_manifest.generated.json"

        lower = source / "melee_1h/posture/draw_01/operator__lower_body__melee_1h__posture__draw_01__e__4f__128x96.png"
        upper = source / "melee_1h/posture/draw_01/operator__upper_body__melee_1h__posture__draw_01__e__4f__128x96.png"
        fx = source / "melee_1h/attack/fast_01/operator__fx__melee_1h__attack__fast_01__e__10f__156x96.png"
        for path in (lower, upper):
            _write_strip(path, 4, 128, 96)
        durations = [0.6, 0.7, 1.0, 0.6]
        _write_timing(lower, 4, durations)
        _write_strip(fx, 10, 156, 96)

        key = parse_filename(lower)
        assert key.frame_width == 128 and key.frame_height == 96
        manifest = manifests._build_manifest(lower)
        assert manifest["frame_size"] == [128, 96]
        assert manifest["post_process"] == ["operator_runtime_build"]
        weapon_drop = (
            source
            / "vigil_pattern_dagger__weapon__melee_1h_dagger__defense__block_loop_01__e__5f__96.png"
        )
        _write_strip(weapon_drop, 5, 96, 96)
        weapon_manifest = manifests._build_manifest(weapon_drop)
        assert weapon_manifest["outputs"][0]["path"] == (
            "weapons/vigil_pattern_dagger/source/operator/melee_1h_dagger/"
            "overrides/defense/block_loop_01/"
            "vigil_pattern_dagger__weapon__melee_1h_dagger__defense__block_loop_01__e__5f__96.png"
        )
        weapon_drop.unlink()

        report = builder.sync(
            source_root=source,
            project_root=root,
            manifest_path=manifest_path,
            weapons_root=root / "weapons",
            strict=True,
            remove_superseded=True,
        )
        assert report["emitted"] == 3
        assert (runtime / "melee_1h/posture/draw_01" / lower.name).exists()
        assert (runtime / "melee_1h/posture/draw_01" / upper.name).exists()
        assert (runtime / "melee_1h/attack/fast_01" / fx.name).exists()
        with Image.open(runtime / "melee_1h/attack/fast_01" / fx.name) as image:
            assert image.size == (1560, 96), "wide canvas must survive unchanged"

        payload = json.loads(manifest_path.read_text(encoding="utf-8"))
        entry = payload["animations"]["melee_1h/posture/draw_01/e"]
        assert entry["layers"]["lower_body"]["frame_size"] == [128, 96]
        assert entry["layers"]["upper_body"]["frames"] == 4
        assert entry["timing"] == {
            "clock_layer": "lower_body", "fps": 10.0, "loop": True, "durations": durations,
        }
        runtime_sidecar = builder.timing_sidecar_path(runtime / "melee_1h/posture/draw_01" / lower.name)
        assert json.loads(runtime_sidecar.read_text())["durations"] == durations
        catalog_path = root / "content/data/operator/generated/operator_animation_catalog.generated.json"
        catalog = json.loads(catalog_path.read_text())
        assert catalog["schema"] == builder.CATALOG_SCHEMA
        assert catalog["animations"]["melee_1h/posture/draw_01/e"]["timing"]["durations"] == durations
        assert "timing" not in payload["animations"]["melee_1h/attack/fast_01/e"], "missing sidecar must preserve legacy timing"

        # Canvas-contract migrations must replace stale generated catalog sizes.
        catalog["animations"]["melee_1h/posture/draw_01/e"]["layers"]["lower_body"]["frame_size"] = [96, 96]
        catalog_path.write_text(json.dumps(catalog))
        runtime_size = json.loads(json.dumps(payload))
        runtime_size["animations"]["melee_1h/posture/draw_01/e"]["layers"]["lower_body"]["frame_size"] = [128, 96]
        merged = builder.build_animation_catalog(runtime_size, catalog_path)
        assert merged["animations"]["melee_1h/posture/draw_01/e"]["layers"]["lower_body"]["frame_size"] == [128, 96]
        catalog_path.write_text(json.dumps(merged))

        catalog["animations"]["melee_1h/posture/draw_01/e"]["layers"]["fx"] = {
            "path": "res://deleted_fx.png", "frames": 4, "frame_size": [128, 96]
        }
        catalog_path.write_text(json.dumps(catalog))
        builder.sync(source_root=source, project_root=root, manifest_path=manifest_path,
                     weapons_root=root / "weapons", strict=True)
        catalog = json.loads(catalog_path.read_text())
        assert "fx" not in catalog["animations"]["melee_1h/posture/draw_01/e"]["layers"], \
            "catalog must prune layers retired from a live semantic identity"

        _write_timing(upper, 4, [1.0, 1.0, 1.0, 1.0])
        try:
            builder.sync(source_root=source, project_root=root, manifest_path=manifest_path,
                         weapons_root=root / "weapons", strict=True)
        except RuntimeError as exc:
            assert "synchronized timing mismatch" in str(exc)
        else:
            raise AssertionError("mismatched synchronized timing must fail strict validation")
        builder.timing_sidecar_path(upper).unlink()

        stale = runtime / "melee_1h/posture/draw_01/operator__lower_body__melee_1h__posture__draw_01__e__3f__128x96.png"
        _write_strip(stale, 3, 128, 96)
        builder.sync(
            source_root=source,
            project_root=root,
            manifest_path=manifest_path,
            weapons_root=root / "weapons",
            strict=True,
            remove_superseded=True,
        )
        assert not stale.exists(), "superseded semantic siblings must be removed"

    print("operator V2 pipeline smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
