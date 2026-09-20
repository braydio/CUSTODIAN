#!/usr/bin/env python3
"""Non-destructive regression for Operator compatibility SpriteFrames migration."""
from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
PIPELINE = REPO_ROOT / "custodian/tools/pipelines/update_operator_compatibility_resources.py"


def load_module():
    spec = importlib.util.spec_from_file_location("operator_compatibility_resources_smoke_module", PIPELINE)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def resource_text(path: str, ext_id: str, animation: str, frames: int, layer: str, *, speed: float = 12.0, loop: bool = True) -> str:
    lines = [
        f'[gd_resource type="SpriteFrames" load_steps={frames + 2} format=3]',
        "",
        f'[ext_resource type="Texture2D" uid="uid://retired" path="{path}" id="{ext_id}"]',
        "",
    ]
    ids = []
    for index in range(frames):
        sub_id = f"AtlasTexture_{layer}_{index}"
        ids.append(sub_id)
        lines.extend([
            f'[sub_resource type="AtlasTexture" id="{sub_id}"]',
            f'atlas = ExtResource("{ext_id}")',
            f"region = Rect2({index * 96}, 0, 96, 96)",
            "",
        ])
    entries = ", ".join(
        '{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sub_id for sub_id in ids
    )
    lines.extend([
        "[resource]",
        f'animations = [{{\n"frames": [{entries}],\n"loop": {str(loop).lower()},\n"name": &"{animation}",\n"speed": {speed}\n}}]',
        "",
    ])
    return "\n".join(lines)


def multi_resource_text(entries: list[dict]) -> str:
    """A SpriteFrames resource holding several full-strip animations."""

    lines = [f'[gd_resource type="SpriteFrames" load_steps=99 format=3]', ""]
    seen_ext: dict[str, str] = {}
    for entry in entries:
        if entry["ext_id"] in seen_ext:
            continue
        seen_ext[entry["ext_id"]] = entry["path"]
        lines.append(
            f'[ext_resource type="Texture2D" uid="uid://{entry["ext_id"]}" '
            f'path="{entry["path"]}" id="{entry["ext_id"]}"]'
        )
    lines.append("")
    emitted: set[str] = set()
    for entry in entries:
        for index in range(entry["frames"]):
            sub_id = f'AtlasTexture_{entry["ext_id"]}_{index}'
            if sub_id in emitted:
                continue
            emitted.add(sub_id)
            lines.extend([
                f'[sub_resource type="AtlasTexture" id="{sub_id}"]',
                f'atlas = ExtResource("{entry["ext_id"]}")',
                f"region = Rect2({index * 96}, 0, 96, 96)",
                "",
            ])
    blocks = []
    for entry in entries:
        frame_entries = ", ".join(
            '{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%s_%d")\n}'
            % (entry["ext_id"], index)
            for index in range(entry["frames"])
        )
        blocks.append(
            '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}'
            % (frame_entries, str(entry["loop"]).lower(), entry["name"], entry["speed"])
        )
    lines.extend(["[resource]", "animations = [" + ", ".join(blocks) + "]", ""])
    return "\n".join(lines)


def check_frozen_timing_authority(module, schema) -> None:
    """The frozen compatibility record outranks the catalog for clips it knows.

    Three historical clips are cross-action: the strip behind
    `unarmed_walk_up_right` is authored as `unarmed/locomotion/idle_01/ne`, so
    refreshing from the catalog entry for those pixels retimes the clip to the
    idle clock. That happened on four consecutive Operator ingests, each time
    needing manual repair, which is exactly the kind of silent drift a migration
    must not carry. A clip the frozen record does not name still refreshes from
    the catalog, so ordinary art updates keep working.
    """

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        # The res:// identity of the resource is what the frozen record is keyed
        # by, so the fixture has to sit at the real project-relative location.
        (root / "custodian").mkdir()
        (root / "custodian/tools").symlink_to(REPO_ROOT / "custodian/tools")
        resource_root = root / "custodian/game/actors/operator"
        resource_root.mkdir(parents=True)

        def runtime_path(group: str, action: str, direction: str, frames: int) -> tuple[object, str]:
            key = schema.OperatorAssetKey(
                "operator", "lower_body", "unarmed", group, action, direction, frames, 96, 96
            )
            return key, "res://" + schema.canonical_runtime_path(key).as_posix()

        idle_key, idle_res = runtime_path("locomotion", "idle_01", "ne", 6)
        recovery_key, recovery_res = runtime_path("attack", "fast_recovery_01", "n", 3)
        walk_key, walk_res = runtime_path("locomotion", "walk_01", "e", 4)
        posture_key, posture_res = runtime_path("posture", "idle_ready_01", "e", 5)

        entries = [
            # Frozen: 6f @10 looping. Catalog for these pixels says 8 FPS.
            {"name": "unarmed_walk_up_right", "path": idle_res, "ext_id": "idle_ne",
             "frames": 6, "speed": 10.0, "loop": True},
            # Frozen: 6f @12 looping. Same pixels, different clip, different clock.
            {"name": "unarmed_run_up_right", "path": idle_res, "ext_id": "idle_ne",
             "frames": 6, "speed": 12.0, "loop": True},
            # Frozen: 3f @12 non-looping.
            {"name": "unarmed_fast_windup_lower_up", "path": recovery_res, "ext_id": "recovery_n",
             "frames": 3, "speed": 12.0, "loop": False},
            # Frozen at 5f, but the art has since been re-authored to 4f. The
            # historical per-frame durations cannot describe frames that no
            # longer exist, so they come from the catalog -- but the clock the
            # consumer plays this clip at is still the frozen one.
            {"name": "unarmed_walk_right", "path": walk_res, "ext_id": "walk_e",
             "frames": 4, "speed": 99.0, "loop": False},
            # Named by no frozen record, as a clip added after the baseline was
            # captured would be. Ordinary catalog-driven refresh still applies.
            {"name": "unarmed_posture_idle_ready_lower", "path": posture_res, "ext_id": "posture_e",
             "frames": 5, "speed": 99.0, "loop": False},
        ]
        resource = resource_root / "operator_modular_lower_body_frames.tres"
        resource.write_text(multi_resource_text(entries))

        index = {
            schema.semantic_identity(idle_key): module.CatalogSpec(
                idle_res, 6, 96, 96, 8.0, True, tuple(1.0 for _ in range(6))),
            schema.semantic_identity(recovery_key): module.CatalogSpec(
                recovery_res, 3, 96, 96, 8.0, True, tuple(1.0 for _ in range(3))),
            schema.semantic_identity(walk_key): module.CatalogSpec(
                walk_res, 4, 96, 96, 8.0, True, tuple(1.0 for _ in range(4))),
            schema.semantic_identity(posture_key): module.CatalogSpec(
                posture_res, 5, 96, 96, 8.0, True, tuple(1.0 for _ in range(5))),
        }

        result = module.update_resource(resource, index, root)
        _start, _end, blocks = module._animation_blocks(result.text)
        by_name = {}
        for block in blocks:
            match = module.NAME_RE.search(block)
            if match:
                by_name[match.group(1)] = block

        preserved = {
            "unarmed_walk_up_right": (10.0, "true"),
            "unarmed_run_up_right": (12.0, "true"),
            "unarmed_fast_windup_lower_up": (12.0, "false"),
        }
        for name, (fps, loop) in preserved.items():
            block = by_name[name]
            speed = float(module.SPEED_RE.search(block).group(2))
            assert speed == fps, f"{name} should keep {fps} FPS, refresh wrote {speed}"
            assert module.LOOP_RE.search(block).group(2) == loop, f"{name} loop drifted"
            assert name in result.preserved_timing, f"{name} should report frozen timing authority"

        # Re-authored frame count: clock preserved, geometry and durations follow
        # the new art.
        rewritten = by_name["unarmed_walk_right"]
        rewritten_speed = float(module.SPEED_RE.search(rewritten).group(2))
        assert rewritten_speed == 10.0, f"re-authored clip should keep 10 FPS, got {rewritten_speed}"
        assert len(module.SUB_REF_RE.findall(rewritten)) == 4, "re-authored clip should take the new frame count"
        assert "unarmed_walk_right" in result.preserved_timing

        control = by_name["unarmed_posture_idle_ready_lower"]
        control_speed = float(module.SPEED_RE.search(control).group(2))
        assert control_speed == 8.0, f"unknown clip should refresh from the catalog, got {control_speed}"
        assert module.LOOP_RE.search(control).group(2) == "true", "unknown clip should take catalog loop"
        assert "unarmed_posture_idle_ready_lower" not in result.preserved_timing

        # A second refresh of the result must be a no-op: an ingest followed by a
        # compatibility refresh has to leave the repository clean.
        resource.write_text(result.text)
        again = module.update_resource(resource, index, root)
        assert again.text == result.text, "compatibility refresh is not idempotent"


def main() -> int:
    module = load_module()
    schema = module._load_schema(REPO_ROOT)
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        resource_root = root / "custodian/game/actors/operator"
        resource_root.mkdir(parents=True)
        old_paths = {}
        new_paths = {}
        layers = {
            "operator_runtime_frames.tres": ("lower_body", "unarmed_run_right"),
            "operator_modular_lower_body_frames.tres": ("lower_body", "unarmed_run_right"),
            "operator_modular_upper_body_frames.tres": ("upper_body", "unarmed_run_right"),
        }
        catalog_layers = {}
        for resource_name, (layer, animation) in layers.items():
            old_key = schema.OperatorAssetKey("operator", layer, "unarmed", "locomotion", "run_01", "e", 5, 96, 96)
            new_key = schema.OperatorAssetKey("operator", layer, "unarmed", "locomotion", "run_01", "e", 6, 96, 96)
            old_res = "res://" + schema.canonical_runtime_path(old_key).as_posix()
            new_res = "res://" + schema.canonical_runtime_path(new_key).as_posix()
            old_paths[resource_name] = old_res
            new_paths[resource_name] = new_res
            target = root / "custodian" / new_res.removeprefix("res://")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(b"synthetic six-frame runtime")
            ext_id = "13_body" if layer == "lower_body" else "13_upper"
            (resource_root / resource_name).write_text(resource_text(old_res, ext_id, animation, 5, layer))
            catalog_layers[layer] = {"path": new_res, "frames": 6, "frame_size": [96, 96]}
        catalog = {
            "schema": "custodian.operator_animation_catalog.v2",
            "animations": {
                "unarmed/locomotion/run_01/e": {
                    "profile": "unarmed",
                    "group": "locomotion",
                    "action": "run_01",
                    "direction": "e",
                    "timing": {"clock_layer": "lower_body", "fps": 10.0, "loop": True,
                               "durations": [0.6, 0.7, 1.0, 0.6, 0.7, 1.0]},
                    "layers": catalog_layers,
                }
            },
        }
        catalog_path = root / "catalog.json"
        catalog_path.write_text(json.dumps(catalog))
        index = module.catalog_index(catalog_path, REPO_ROOT)

        before = module.stale_runtime_references(resource_root, root)
        assert len(before) == 3, before
        for resource_name in layers:
            path = resource_root / resource_name
            result = module.update_resource(path, index, REPO_ROOT)
            assert result.changed_paths == [(old_paths[resource_name], new_paths[resource_name])]
            assert result.resized_animations == [("unarmed_run_right", 5, 6)]
            path.write_text(result.text)
            text = path.read_text()
            assert old_paths[resource_name] not in text
            assert new_paths[resource_name] in text
            _start, _end, blocks = module._animation_blocks(text)
            run = next(block for block in blocks if '"name": &"unarmed_run_right"' in block)
            assert len(module.SUB_REF_RE.findall(run)) == 6
            assert '"speed": 10' in run
            assert '"loop": true' in run
            assert [float(value) for value in __import__("re").findall(r'"duration": ([0-9.]+)', run)] == [0.6, 0.7, 1.0, 0.6, 0.7, 1.0]
            assert "region = Rect2(480, 0, 96, 96)" in text

        legacy_path = resource_root / "legacy_uniform.tres"
        legacy_key = schema.OperatorAssetKey("operator", "fx", "unarmed", "attack", "fast_01", "s", 2, 96, 96)
        legacy_res = "res://" + schema.canonical_runtime_path(legacy_key).as_posix()
        legacy_runtime = root / "custodian" / legacy_res.removeprefix("res://")
        legacy_runtime.parent.mkdir(parents=True, exist_ok=True)
        legacy_runtime.write_bytes(b"synthetic legacy runtime")
        legacy_path.write_text(resource_text(legacy_res, "legacy_fx", "legacy_uniform", 2, "fx", speed=7.5, loop=False))
        legacy_index = {schema.semantic_identity(legacy_key): module.CatalogSpec(legacy_res, 2, 96, 96)}
        legacy = module.update_resource(legacy_path, legacy_index, REPO_ROOT)
        assert not legacy.changed
        assert '"speed": 7.5' in legacy.text and '"loop": false' in legacy.text

        assert module.stale_runtime_references(resource_root, root) == []
        for old_res in old_paths.values():
            assert not (root / "custodian" / old_res.removeprefix("res://")).exists()
        for new_res in new_paths.values():
            assert (root / "custodian" / new_res.removeprefix("res://")).exists()

    check_frozen_timing_authority(module, schema)

    print(
        "operator_compatibility_resources_smoke: PASS 5f->6f paths, aliases, "
        "AtlasTexture frames, stale-path gate, frozen timing authority"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
