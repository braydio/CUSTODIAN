#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sys
import tempfile
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]


def _load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def _write_strip(path: Path, frames: int = 5, size: int = 96) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGBA", (frames * size, size), (255, 255, 255, 255)).save(path)


def main() -> int:
    manifests = _load_module(
        "generate_inbox_manifests",
        PROJECT_ROOT / "tools/pipelines/generate_inbox_manifests.py",
    )
    spriteframes = _load_module(
        "build_actor_spriteframes",
        PROJECT_ROOT / "tools/pipelines/build_actor_spriteframes.py",
    )

    with tempfile.TemporaryDirectory(prefix="non-operator-actor-pipeline-") as temp:
        root = Path(temp)
        enemy = root / "enemy_savage__body__locomotion__walk_01__e__8f__96.png"
        ally = root / "allied_infantry_droid__fx__ranged__muzzle_flash__w__5f__96.png"
        _write_strip(enemy, frames=8)
        _write_strip(ally)

        enemy_manifest = manifests._build_manifest(enemy)
        enemy_paths = [output["path"] for output in enemy_manifest["outputs"]]
        assert enemy_paths[0] == (
            "enemy_savage/runtime/body/locomotion/"
            "enemy_savage__body__locomotion__walk_01__e__8f__96.png"
        )
        assert "enemies/enemy_savage/runtime/body/" + enemy.name in enemy_paths
        assert "enemies/enemy_savage/" + enemy.name in enemy_paths
        assert enemy_manifest["post_process"] == ["enemy_runtime_import"]

        ally_manifest = manifests._build_manifest(ally)
        ally_paths = [output["path"] for output in ally_manifest["outputs"]]
        assert ally_paths[0] == (
            "allied_infantry_droid/runtime/fx/ranged/"
            "allied_infantry_droid__fx__ranged__muzzle_flash__w__5f__96.png"
        )
        assert "allies/allied_infantry_droid/runtime/fx/" + ally.name in ally_paths
        assert ally_manifest["post_process"] == [
            "actor_spriteframes:allies:allied_infantry_droid"
        ]

        canonical_runtime = root / "enemy_savage" / "runtime"
        legacy_runtime = root / "enemies" / "enemy_savage" / "runtime"
        canonical_walk = canonical_runtime / "body" / "locomotion" / enemy.name
        legacy_walk = legacy_runtime / "body" / enemy.name
        legacy_idle = legacy_runtime / "body" / (
            "enemy_savage__body__locomotion__idle_01__e__5f__96.png"
        )
        _write_strip(canonical_walk, frames=8)
        _write_strip(legacy_walk, frames=8)
        _write_strip(legacy_idle)

        sheets = spriteframes._collect_sheets(
            [canonical_runtime, legacy_runtime],
            "enemy_savage",
            "body",
            0,
        )
        assert [sheet.animation_name for sheet in sheets] == ["idle_01_e", "walk_01_e"]
        walk_sheet = next(sheet for sheet in sheets if sheet.animation_name == "walk_01_e")
        assert walk_sheet.path == canonical_walk

    print("non-Operator actor pipeline smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
