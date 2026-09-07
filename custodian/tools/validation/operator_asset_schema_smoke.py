#!/usr/bin/env python3
from __future__ import annotations

import sys
import tempfile
from pathlib import Path

from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT_ROOT / "tools/pipelines"))
from operator_asset_schema import (
    DIRECTIONS, OperatorAssetKey, canonical_filename, canonical_runtime_path,
    canonical_source_path, is_legacy_action, parse_filename, semantic_identity,
)
from migrations.operator_legacy_asset_migration import normalize_legacy_filename
import sync_operator_runtime_assets


def main() -> int:
    for direction in DIRECTIONS:
        key = parse_filename(f"operator__upper_body__unarmed__locomotion__idle_01__{direction}__5f__96.png")
        assert key.direction == direction and key.frame_width == key.frame_height == 96
    rectangular = parse_filename("operator__fx__melee_1h__attack__fast_01__e__10f__156x96.png")
    assert (rectangular.frame_width, rectangular.frame_height) == (156, 96)
    assert semantic_identity(rectangular) == semantic_identity(OperatorAssetKey(
        "operator", "fx", "melee_1h", "attack", "fast_01", "e", 4, 96, 96
    ))
    weapon = parse_filename("carbine_mk1__weapon__ranged_2h__presentation__held_01__e__1f__96.png")
    assert "weapons/carbine_mk1" in canonical_source_path(weapon).as_posix()
    assert parse_filename("operator__full_body__shared__transition__arrival_01__s__13f__156x156.png").layer == "full_body"
    assert "weapons/carbine_mk1/runtime/operator" in canonical_runtime_path(weapon).as_posix()
    legacy = normalize_legacy_filename("operator__modular_lower_body__unarmed__chain_01__e__10f__156x96.png")
    assert legacy.action == "fast_01" and legacy.layer == "lower_body"
    try:
        parse_filename("operator__bad__name.png")
        raise AssertionError("invalid filename accepted")
    except ValueError:
        pass

    # Legacy identity is migration-only vocabulary; the canonical schema must reject it.
    assert is_legacy_action("legacy_fast_attack") and is_legacy_action("fast_01_legacy_7f7c22c3")
    assert not is_legacy_action("fast_01")
    for name in (
        "operator__full_body__melee_1h__attack__legacy_operator_body_melee_fast_01__omni__1f__1092x96.png",
        "operator__fx__melee_1h__attack__fast_01_legacy_7f7c22c3__e__10f__96.png",
    ):
        try:
            parse_filename(name)
            raise AssertionError(f"legacy action accepted as canonical: {name}")
        except ValueError:
            pass
        assert normalize_legacy_filename(name).action  # migration tooling still reads it

    with tempfile.TemporaryDirectory(prefix="operator-v2-builder-") as temp:
        root = Path(temp)
        source = root / "content/sprites/operator/source/animations"
        path = source / "unarmed/locomotion/idle_01/operator__lower_body__unarmed__locomotion__idle_01__s__2f__96.png"
        path.parent.mkdir(parents=True)
        Image.new("RGBA", (192, 96)).save(path)
        report = sync_operator_runtime_assets.sync(
            source_root=source, weapons_root=root / "weapons", project_root=root,
            manifest_path=root / "manifest.json", strict=True,
        )
        output = root / canonical_runtime_path(parse_filename(path))
        assert output.exists() and Image.open(output).size == (192, 96)
        assert report["emitted"] == 1
    print("operator asset schema smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
