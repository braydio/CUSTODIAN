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

    print("operator_compatibility_resources_smoke: PASS 5f->6f paths, aliases, AtlasTexture frames, stale-path gate")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
