#!/usr/bin/env python3
"""Fixture-isolated apply/rollback coverage for Workbench mirror promotion."""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "operator"))
import animation_workbench as workbench
import animation_workbench_model as model


FRAMES = 3
FRAME_SIZE = (4, 2)
LAYERS = ("lower_body", "upper_body")
TIMING = {
    "schema": model.BUILDER.TIMING_SCHEMA,
    "frames": FRAMES,
    "fps": 8.0,
    "loop": True,
    "durations": [1.0, 1.5, 0.5],
}


def make_strip(path: Path, seed: int) -> None:
    image = Image.new("RGBA", (FRAMES * FRAME_SIZE[0], FRAME_SIZE[1]))
    for frame in range(FRAMES):
        left = frame * FRAME_SIZE[0]
        image.putpixel((left, 0), (seed + frame, 10, 20, 255))
        image.putpixel((left + 3, 1), (30, seed + frame, 40, 128 + frame))
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def framewise_mirror_bytes(path: Path) -> tuple[bytes, ...]:
    with Image.open(path) as image:
        return tuple(
            image.crop((frame * 4, 0, (frame + 1) * 4, 2))
            .transpose(Image.Transpose.FLIP_LEFT_RIGHT).convert("RGBA").tobytes()
            for frame in range(FRAMES)
        )


def frame_bytes(path: Path) -> tuple[bytes, ...]:
    with Image.open(path) as image:
        return tuple(image.crop((frame * 4, 0, (frame + 1) * 4, 2)).convert("RGBA").tobytes() for frame in range(FRAMES))


def fixture(root: Path, seed: int) -> tuple[Path, dict[str, Path], dict[str, Path]]:
    custodian = root / "custodian"
    workspace = root / ".ai/workbench/unarmed/defense/block_hold_01/e"
    workspace.mkdir(parents=True)
    document = workspace / "workbench.aseprite"
    document.write_bytes(b"saved fixture workbench")
    east: dict[str, Path] = {}
    west: dict[str, Path] = {}
    layers = []
    for offset, layer in enumerate(LAYERS):
        east_key = model.SCHEMA.OperatorAssetKey("operator", layer, "unarmed", "defense", "block_hold_01", "e", FRAMES, *FRAME_SIZE)
        west_key = model.SCHEMA.OperatorAssetKey("operator", layer, "unarmed", "defense", "block_hold_01", "w", FRAMES, *FRAME_SIZE)
        east[layer] = custodian / model.SCHEMA.canonical_source_path(east_key)
        west[layer] = custodian / model.SCHEMA.canonical_source_path(west_key)
        make_strip(east[layer], 10 + offset * 20)
        make_strip(west[layer], 90 + offset * 20)
        layers.append({
            "binding_id": layer, "aseprite_layer_name": layer, "role": "editable", "editable": True,
            "owner": "operator", "layer": layer, "profile": "unarmed", "group": "defense",
            "action": "block_hold_01", "direction": "e", "frames": FRAMES,
            "frame_size": list(FRAME_SIZE), "placement": [0, 0],
            "source_path": str(east[layer].relative_to(root)),
            "source_contract": {"path": str(east[layer].relative_to(root)), "frames": FRAMES,
                                "frame_size": list(FRAME_SIZE), "file_sha256": model.file_sha256(east[layer]),
                                "pixel_sha256": model.pixel_sha256(east[layer])},
            "workspace_contract": {"frames": FRAMES, "frame_size": list(FRAME_SIZE),
                                   "placement": [0, 0], "timeline_slots": [1, 2, 3]},
            "publish_contract": {"path": str(east[layer].relative_to(root)), "frames": FRAMES,
                                 "frame_size": list(FRAME_SIZE)},
        })
    timing_path = model.BUILDER.timing_sidecar_path(east["lower_body"])
    timing_path.write_text(json.dumps(TIMING, indent=2) + "\n")
    west_timing = model.BUILDER.timing_sidecar_path(west["lower_body"])
    west_timing.write_text(json.dumps({**TIMING, "fps": 3.0}, indent=2) + "\n")
    manifest = {
        "schema": model.SCHEMA_NAME,
        "identity": {"profile": "unarmed", "group": "defense", "action": "block_hold_01", "direction": "e"},
        "context": {}, "canvas": {"width": 4, "height": 2}, "layers": layers, "references": [],
        "timeline": {"frames": FRAMES, "source_clock_frames": FRAMES, "workspace_clock_frames": FRAMES,
                     "document_frames": FRAMES, "fps": 8.0, "loop": True,
                     "durations": [1.0, 1.5, 0.5], "timing_authority": True, "clock_owner": "lower_body"},
        "aseprite": {"path": str(document), "last_synced_sha256": model.file_sha256(document)},
        "pending_migration": None,
    }
    manifest_path = workspace / "workbench.json"
    workbench.save(manifest_path, manifest)
    return manifest_path, east, west


def run_case(*, mirror: bool, fail_downstream: bool) -> None:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        manifest_path, east, west = fixture(root, 20)
        originals = {path: path.read_bytes() for path in (*east.values(), *west.values())}
        timing_paths = tuple(model.BUILDER.timing_sidecar_path(paths["lower_body"]) for paths in (east, west))
        original_timing = {path: path.read_bytes() for path in timing_paths}
        exported = {layer: root / f"edited_{layer}.png" for layer in LAYERS}
        for offset, layer in enumerate(LAYERS): make_strip(exported[layer], 50 + offset * 20)

        saved = {
            "repo": model.REPO_ROOT, "custodian": model.CUSTODIAN_ROOT, "pipelines": model.PIPELINES,
            "rel": model.rel, "source_index": model.source_index,
            "resources": workbench.GENERATED_OPERATOR_RESOURCES, "aseprite": workbench.aseprite_run,
            "resolve": workbench.resolve_aseprite, "commands": workbench._validation_commands,
            "compat_update": workbench._compatibility_update, "compat_check": workbench._compatibility_check,
            "import": workbench._godot_import, "catalog": workbench._catalog_build,
            "consistency": workbench._operator_scene_consistency, "subprocess": workbench.subprocess.run,
        }
        calls = 0
        def source_index(*_args, **_kwargs):
            result = {}
            for layer, path in west.items(): result[("operator", layer, "unarmed", "defense", "block_hold_01", "w")] = (path, None)
            return result
        def aseprite_run(_binary, path, _mode):
            data = json.loads(path.read_text()); raw = path.parent / "exports" / data["export_stamp"] / "raw"
            raw.mkdir(parents=True, exist_ok=True)
            for layer in LAYERS: shutil.copy2(exported[layer], raw / f"{layer}.png")
        def downstream(*_args, **_kwargs):
            nonlocal calls
            calls += 1
            if fail_downstream and calls == 1: raise subprocess.CalledProcessError(91, "injected-runtime-build")
            return subprocess.CompletedProcess([], 0)
        try:
            model.REPO_ROOT=root; model.CUSTODIAN_ROOT=root/"custodian"; model.PIPELINES=root/"custodian/tools/pipelines"
            model.rel=lambda path,repo_root=root:str(Path(path).relative_to(repo_root))
            model.source_index=source_index; workbench.GENERATED_OPERATOR_RESOURCES=[]
            workbench.aseprite_run=aseprite_run; workbench.resolve_aseprite=lambda *_args,**_kwargs:Path("/bin/true")
            workbench._validation_commands=lambda *_args,**_kwargs:[]
            workbench._compatibility_update=lambda:None; workbench._compatibility_check=lambda:None
            workbench._godot_import=lambda:None; workbench._catalog_build=lambda:None; workbench._operator_scene_consistency=lambda:None
            workbench.subprocess.run=downstream
            if fail_downstream:
                try: workbench.publish(manifest_path, mirror_counterpart=mirror)
                except subprocess.CalledProcessError: pass
                else: raise AssertionError("injected downstream failure did not escape publish")
                assert all(path.read_bytes() == content for path, content in originals.items())
                assert all(path.read_bytes() == content for path, content in original_timing.items())
                journal = json.loads(sorted((manifest_path.parent / "transactions").glob("*/transaction.json"))[-1].read_text())
                assert journal["state"] == "ROLLED_BACK" and journal["mirror_promotion"]["enabled"] is mirror
            else:
                workbench.publish(manifest_path, mirror_counterpart=mirror)
                for layer in LAYERS: assert east[layer].read_bytes() == exported[layer].read_bytes()
                if mirror:
                    for layer in LAYERS: assert frame_bytes(west[layer]) == framewise_mirror_bytes(east[layer])
                    assert timing_paths[0].read_bytes() == timing_paths[1].read_bytes()
                else:
                    assert all(path.read_bytes() == originals[path] for path in west.values())
                    assert timing_paths[1].read_bytes() == original_timing[timing_paths[1]]
        finally:
            model.REPO_ROOT=saved["repo"]; model.CUSTODIAN_ROOT=saved["custodian"]; model.PIPELINES=saved["pipelines"]
            model.rel=saved["rel"]; model.source_index=saved["source_index"]
            workbench.GENERATED_OPERATOR_RESOURCES=saved["resources"]; workbench.aseprite_run=saved["aseprite"]
            workbench.resolve_aseprite=saved["resolve"]; workbench._validation_commands=saved["commands"]
            workbench._compatibility_update=saved["compat_update"]; workbench._compatibility_check=saved["compat_check"]
            workbench._godot_import=saved["import"]; workbench._catalog_build=saved["catalog"]
            workbench._operator_scene_consistency=saved["consistency"]; workbench.subprocess.run=saved["subprocess"]


def main() -> None:
    run_case(mirror=False, fail_downstream=False)
    run_case(mirror=True, fail_downstream=False)
    run_case(mirror=True, fail_downstream=True)
    print("PASS operator_workbench_mirror_publish_smoke: opt-out, framewise apply/timing, atomic byte rollback")


if __name__ == "__main__": main()
