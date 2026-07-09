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
    builder = _load_module(
        "build_operator_modular_runtime",
        PROJECT_ROOT / "tools/pipelines/build_operator_modular_runtime.py",
    )

    with tempfile.TemporaryDirectory(prefix="operator-modular-pipeline-") as temp:
        root = Path(temp)
        canonical = root / "operator__modular_lower_body__unarmed__block_loop_01__e__5f__96.png"
        legacy_collision = root / "operator__modular_lower_body__block_loop_01__e__4f__96.png"
        legacy = root / "operator__modular_lower_body__blocking_hitreact_01__e__5f__96.png"
        cape = root / "operator__modular_wardrobe_cape__unarmed__block_loop_01__e__5f__96.png"
        ranged = root / "operator__modular_upper_body__stance__ranged_2h__e__5f__96.png"
        for path in (canonical, legacy, cape, ranged):
            _write_strip(path)
        _write_strip(legacy_collision, frames=4)
        rectangular = root / "operator__body__melee_1h__e__8f__156x96.png"
        Image.new("RGBA", (8 * 156, 96), (255, 255, 255, 255)).save(rectangular)

        canonical_info = manifests._inspect_sheet(canonical)
        legacy_info = manifests._inspect_sheet(legacy)
        cape_info = manifests._inspect_sheet(cape)
        assert manifests._canonical_runtime_path(canonical_info).startswith(
            "operator/new_operator/modular/block/"
        )
        assert manifests._canonical_runtime_path(legacy_info).startswith(
            "operator/new_operator/modular/block/"
        )
        assert manifests._canonical_runtime_path(cape_info).startswith(
            "operator/new_operator/modular/block/"
        )
        assert manifests._build_post_process(cape_info) == ["operator_modular_runtime"]
        rectangular_manifest = manifests._build_manifest(rectangular)
        assert rectangular_manifest["frame_size"] == [156, 96]
        assert rectangular_manifest["outputs"][0]["select"]["count"] == 8

        module_root = root / "runtime"
        generated = builder._build_generic_action_modules(root, module_root, dry_run=True)
        relative = {path.relative_to(module_root).as_posix() for path in generated}
        assert (
            "lower_body/actions/unarmed/block_loop_01/"
            "operator__modular_lower_body__unarmed__block_loop_01__e__5f__96.png"
        ) in relative
        assert not any("block_loop_01__e__4f__96.png" in path for path in relative)
        assert (
            "lower_body/actions/unarmed/blocking_hitreact_01/"
            "operator__modular_lower_body__unarmed__blocking_hitreact_01__e__5f__96.png"
        ) in relative
        assert (
            "wardrobe_cape/actions/unarmed/block_loop_01/"
            "operator__modular_wardrobe_cape__unarmed__block_loop_01__e__5f__96.png"
        ) in relative
        assert not any("ranged_2h/stance_01" in path for path in relative)

        generated_new = module_root / (
            "lower_body/actions/unarmed/block_loop_01/"
            "operator__modular_lower_body__unarmed__block_loop_01__e__5f__96.png"
        )
        generated_old = generated_new.with_name(
            "operator__modular_lower_body__unarmed__block_loop_01__e__4f__96.png"
        )
        _write_strip(generated_new)
        _write_strip(generated_old, frames=4)
        generated_old.with_suffix(".png.import").write_text("smoke\n", encoding="utf-8")
        builder._remove_superseded_generated([generated_new], dry_run=True)
        assert generated_old.exists()
        builder._remove_superseded_generated([generated_new], dry_run=False)
        assert not generated_old.exists()
        assert not generated_old.with_suffix(".png.import").exists()

    print("operator modular pipeline smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
