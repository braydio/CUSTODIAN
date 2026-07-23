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
        cape_alias = root / "operator__cape__unarmed__dodge_fast_attack_01__w__11f__96.png"
        head = root / "operator__modular_head__hooded__idle_01__s__5f__96.png"
        walk = root / "operator__modular_lower_body__unarmed__walk_01__s__5f__96.png"
        ranged = root / "operator__modular_upper_body__stance__ranged_2h__e__5f__96.png"
        ranged_weapon = root / "operator__modular_ranged_weapon__ranged_2h__relaxed_carbine_mk1_01__e__5f__96.png"
        for path in (canonical, legacy, cape, head, walk, ranged, ranged_weapon):
            _write_strip(path)
        _write_strip(cape_alias, frames=11)
        _write_strip(legacy_collision, frames=4)
        rectangular = root / "operator__body__melee_1h__e__8f__156x96.png"
        Image.new("RGBA", (8 * 156, 96), (255, 255, 255, 255)).save(rectangular)
        dodge_charge = root / "operator__body__full__dodge_charge_windup_01__s__5f__96.png"
        dodge_chain = root / "operator__body__full__dodge_chain_link_01__s__4f__96.png"
        _write_strip(dodge_charge, frames=5)
        _write_strip(dodge_chain, frames=4)

        generic_run_nw = (
            root / "run/operator__modular_lower_body__run_01__nw__5f__96.png"
        )
        explicit_run_nw = (
            root
            / "run/operator__modular_lower_body__unarmed__run_01__nw__6f__96.png"
        )
        _write_strip(generic_run_nw, frames=5)
        _write_strip(explicit_run_nw, frames=6)
        resolved_run_nw = builder._resolve_lower_source(
            root,
            "run_01",
            "nw",
            ("action_01",),
        )
        assert resolved_run_nw is not None
        assert resolved_run_nw.path == explicit_run_nw
        assert resolved_run_nw.frames == 6

        canonical_info = manifests._inspect_sheet(canonical)
        legacy_info = manifests._inspect_sheet(legacy)
        cape_info = manifests._inspect_sheet(cape)
        cape_alias_info = manifests._inspect_sheet(cape_alias)
        head_info = manifests._inspect_sheet(head)
        ranged_weapon_info = manifests._inspect_sheet(ranged_weapon)
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
        assert manifests._canonical_runtime_path(cape_alias_info).startswith(
            "operator/new_operator/modular/dodge/"
        )
        assert manifests._build_post_process(cape_alias_info) == ["operator_modular_runtime"]
        assert manifests._canonical_runtime_path(head_info).startswith(
            "operator/new_operator/modular/idle/"
        )
        assert manifests._build_post_process(head_info) == ["operator_modular_runtime"]
        parsed_head = builder._parse_generic_modular_source(head)
        assert parsed_head is not None
        assert parsed_head[0:3] == ("head", "hooded", "idle_01")
        walk_info = manifests._inspect_sheet(walk)
        assert manifests._operator_modular_loadout_action(walk_info) == ("unarmed", "walk_01")
        assert manifests._canonical_runtime_path(walk_info).startswith(
            "operator/new_operator/modular/walk/"
        )
        parsed_walk = builder._parse_generic_modular_source(walk)
        assert parsed_walk is not None
        assert parsed_walk[0:3] == ("lower_body", "unarmed", "walk_01")
        assert manifests._canonical_runtime_path(ranged_weapon_info).startswith(
            "operator/new_operator/modular/ranged/"
        )
        assert manifests._build_post_process(ranged_weapon_info) == ["operator_modular_runtime"]
        parsed_ranged_weapon = builder._parse_generic_modular_source(ranged_weapon)
        assert parsed_ranged_weapon is not None
        assert parsed_ranged_weapon[1:3] == ("ranged_2h", "relaxed_01")
        assert parsed_ranged_weapon[4] == 3
        rectangular_manifest = manifests._build_manifest(rectangular)
        assert rectangular_manifest["frame_size"] == [156, 96]
        assert rectangular_manifest["outputs"][0]["select"]["count"] == 8
        assert manifests._canonical_runtime_path(
            manifests._inspect_sheet(dodge_charge)
        ).startswith("operator/runtime/actions/dodge_charge/body/")
        assert manifests._canonical_runtime_path(
            manifests._inspect_sheet(dodge_chain)
        ).startswith("operator/runtime/actions/dodge_chain/body/")

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
        assert (
            "wardrobe_cape/actions/unarmed/dodge_fast_attack_01/"
            "operator__modular_wardrobe_cape__unarmed__dodge_fast_attack_01__w__11f__96.png"
        ) in relative
        assert (
            "ranged_weapon/actions/ranged_2h/relaxed_01/"
            "operator__modular_ranged_weapon__ranged_2h__relaxed_01__e__5f__96.png"
        ) in relative
        assert (
            "head/actions/hooded/idle_01/"
            "operator__modular_head__hooded__idle_01__s__5f__96.png"
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

        referenced_root = root / "referenced-project"
        referenced_runtime = referenced_root / "content/runtime"
        referenced_new = referenced_runtime / (
            "operator__modular_lower_body__unarmed__walk_01__s__5f__96.png"
        )
        referenced_old = referenced_runtime / (
            "operator__modular_lower_body__unarmed__walk_01__s__6f__96.png"
        )
        _write_strip(referenced_new, frames=5)
        _write_strip(referenced_old, frames=6)
        referenced_old.with_suffix(".png.import").write_text("smoke\n", encoding="utf-8")
        consumer = referenced_root / "game/operator_walk_frames.tres"
        consumer.parent.mkdir(parents=True, exist_ok=True)
        old_resource_path = "res://content/runtime/" + referenced_old.name
        new_resource_path = "res://content/runtime/" + referenced_new.name
        consumer.write_text(old_resource_path + "\n", encoding="utf-8")

        builder._remove_superseded_generated(
            [referenced_new],
            dry_run=False,
            reference_root=referenced_root,
        )
        assert referenced_old.exists(), "referenced generated sheets must survive pre-update cleanup"

        consumer.write_text(new_resource_path + "\n", encoding="utf-8")
        builder._remove_superseded_generated(
            [referenced_new],
            dry_run=False,
            reference_root=referenced_root,
        )
        assert not referenced_old.exists(), "superseded sheets should be removed after consumers update"
        assert not referenced_old.with_suffix(".png.import").exists()

    print("operator modular pipeline smoke passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
