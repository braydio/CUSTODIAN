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

import build_operator_runtime as builder  # noqa: E402
import generate_inbox_manifests as manifests  # noqa: E402
from operator_asset_schema import parse_filename  # noqa: E402


def _write_strip(path: Path, frames: int, width: int, height: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGBA", (frames * width, height), (255, 255, 255, 255)).save(path)


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="operator-v2-pipeline-") as temp:
        root = Path(temp)
        source = root / "source"
        runtime = root / "content/sprites/operator/runtime/animations"
        catalog = root / "catalog.json"

        lower = source / "melee_1h/posture/draw_01/operator__lower_body__melee_1h__posture__draw_01__e__4f__128x96.png"
        upper = source / "melee_1h/posture/draw_01/operator__upper_body__melee_1h__posture__draw_01__e__4f__128x96.png"
        fx = source / "melee_1h/attack/fast_01/operator__fx__melee_1h__attack__fast_01__e__10f__156x96.png"
        for path in (lower, upper):
            _write_strip(path, 4, 128, 96)
        _write_strip(fx, 10, 156, 96)

        key = parse_filename(lower)
        assert key.frame_width == 128 and key.frame_height == 96
        manifest = manifests._build_manifest(lower)
        assert manifest["frame_size"] == [128, 96]
        assert manifest["post_process"] == ["operator_runtime_build"]

        report = builder.build(
            source_root=source,
            project_root=root,
            catalog_path=catalog,
            weapon_root=root / "weapons",
            strict=True,
            remove_superseded=True,
        )
        assert report["emitted"] == 3
        assert (runtime / "melee_1h/posture/draw_01" / lower.name).exists()
        assert (runtime / "melee_1h/posture/draw_01" / upper.name).exists()
        assert (runtime / "melee_1h/attack/fast_01" / fx.name).exists()
        with Image.open(runtime / "melee_1h/attack/fast_01" / fx.name) as image:
            assert image.size == (1560, 96), "wide canvas must survive unchanged"

        payload = json.loads(catalog.read_text(encoding="utf-8"))
        entry = payload["animations"]["melee_1h/posture/draw_01/e"]
        assert entry["layers"]["lower_body"]["frame_size"] == [128, 96]
        assert entry["layers"]["upper_body"]["frames"] == 4

        stale = runtime / "melee_1h/posture/draw_01/operator__lower_body__melee_1h__posture__draw_01__e__3f__128x96.png"
        _write_strip(stale, 3, 128, 96)
        builder.build(
            source_root=source,
            project_root=root,
            catalog_path=catalog,
            weapon_root=root / "weapons",
            strict=True,
            remove_superseded=True,
        )
        assert not stale.exists(), "superseded semantic siblings must be removed"

    print("operator V2 pipeline smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
