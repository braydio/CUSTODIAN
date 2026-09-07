#!/usr/bin/env python3
"""Regression smoke for the canonical Operator V2 ingest/build pipeline."""
from __future__ import annotations

import json
import sys
import tempfile
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
