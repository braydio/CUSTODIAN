#!/usr/bin/env python3
"""Refresh generated Operator compatibility SpriteFrames from the V2 catalog.

This is deliberately a text/resource-path phase. It runs after runtime PNG
generation and before Godot import, so stale Texture2D references never need to
be loaded in order to repair themselves. Only full, sequential horizontal-strip
aliases are resized; manually sliced or multi-texture animations are preserved.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
CUSTODIAN_ROOT = REPO_ROOT / "custodian"
CATALOG_PATH = CUSTODIAN_ROOT / "content/data/operator/generated/operator_animation_catalog.generated.json"
OPERATOR_RESOURCE_ROOT = CUSTODIAN_ROOT / "game/actors/operator"

COMPATIBILITY_RESOURCE_NAMES = (
    "operator_runtime_frames.tres",
    "operator_weapon_frames.tres",
    "operator_melee_overlay_frames.tres",
    "operator_ranged_fx_frames.tres",
    "operator_modular_lower_body_frames.tres",
    "operator_modular_upper_body_frames.tres",
    "operator_modular_sidearm_frames.tres",
    "operator_modular_upper_fx_frames.tres",
    "operator_modular_cape_frames.tres",
    "operator_modular_head_frames.tres",
)
CATALOG_RESOURCE_NAME = "operator_animation_catalog_frames.tres"
GENERATED_RESOURCE_NAMES = COMPATIBILITY_RESOURCE_NAMES + (CATALOG_RESOURCE_NAME,)

EXT_RE = re.compile(
    r'^\[ext_resource type="Texture2D"(?: uid="[^"]+")? path="([^"]+)" id="([^"]+)"\]$',
    re.MULTILINE,
)
ATLAS_RE = re.compile(
    r'^\[sub_resource type="AtlasTexture" id="([^"]+)"\]\n(.*?)(?=^\[|\Z)',
    re.MULTILINE | re.DOTALL,
)
REGION_RE = re.compile(r"^region = Rect2\(([-0-9.]+), ([-0-9.]+), ([-0-9.]+), ([-0-9.]+)\)$", re.MULTILINE)
ATLAS_EXT_RE = re.compile(r'^atlas = ExtResource\("([^"]+)"\)$', re.MULTILINE)
SUB_REF_RE = re.compile(r'SubResource\("([^"]+)"\)')
NAME_RE = re.compile(r'^"name": &"([^"]+)"', re.MULTILINE)
FRAMES_RE = re.compile(r'("frames": \[)(.*?)(\],\n"loop":)', re.DOTALL)


def _load_schema(repo_root: Path):
    path = repo_root / "custodian/tools/pipelines/operator_asset_schema.py"
    spec = importlib.util.spec_from_file_location("operator_compatibility_schema", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load Operator schema: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


@dataclass(frozen=True)
class CatalogSpec:
    path: str
    frames: int
    frame_width: int
    frame_height: int


@dataclass
class ResourceUpdate:
    path: Path
    changed_paths: list[tuple[str, str]]
    resized_animations: list[tuple[str, int, int]]
    text: str

    @property
    def changed(self) -> bool:
        return bool(self.changed_paths or self.resized_animations)


def catalog_index(catalog_path: Path, repo_root: Path = REPO_ROOT) -> dict[tuple, CatalogSpec]:
    schema = _load_schema(repo_root)
    catalog = json.loads(catalog_path.read_text())
    if catalog.get("schema") != "custodian.operator_animation_catalog.v2":
        raise ValueError(f"invalid Operator catalog: {catalog_path}")
    result: dict[tuple, CatalogSpec] = {}
    for animation in catalog.get("animations", {}).values():
        for raw in animation.get("layers", {}).values():
            path = str(raw.get("path", ""))
            size = raw.get("frame_size", [])
            key = schema.parse_filename(Path(path).name)
            if key is None or len(size) != 2:
                raise ValueError(f"catalog contains invalid Operator layer: {path}")
            identity = schema.semantic_identity(key)
            spec = CatalogSpec(path, int(raw["frames"]), int(size[0]), int(size[1]))
            if identity in result and result[identity] != spec:
                raise ValueError(f"ambiguous catalog semantic identity: {identity}")
            result[identity] = spec
    return result


def _atlas_records(text: str) -> dict[str, tuple[str, tuple[int, int, int, int]]]:
    records: dict[str, tuple[str, tuple[int, int, int, int]]] = {}
    for match in ATLAS_RE.finditer(text):
        ext = ATLAS_EXT_RE.search(match.group(2))
        region = REGION_RE.search(match.group(2))
        if ext is None or region is None:
            continue
        records[match.group(1)] = (
            ext.group(1),
            tuple(int(float(region.group(i))) for i in range(1, 5)),
        )
    return records


def _animation_blocks(text: str) -> tuple[int, int, list[str]]:
    marker = "animations = ["
    start = text.find(marker)
    if start < 0:
        raise ValueError("SpriteFrames resource has no animations array")
    array_start = start + len("animations = ")
    depth = 0
    in_string = False
    escaped = False
    end = -1
    for index in range(array_start, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "[":
            depth += 1
        elif char == "]":
            depth -= 1
            if depth == 0:
                end = index + 1
                break
    if end < 0:
        raise ValueError("unterminated SpriteFrames animations array")
    raw = text[array_start:end]
    blocks: list[str] = []
    depth = 0
    block_start = -1
    in_string = False
    escaped = False
    for index, char in enumerate(raw):
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            if depth == 0:
                block_start = index
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0 and block_start >= 0:
                blocks.append(raw[block_start:index + 1])
    return array_start, end, blocks


def _full_strip_ext(block: str, atlases: dict[str, tuple[str, tuple[int, int, int, int]]], old_key) -> str | None:
    ids = SUB_REF_RE.findall(block)
    if not ids or any(item not in atlases for item in ids):
        return None
    ext_ids = {atlases[item][0] for item in ids}
    if len(ext_ids) != 1 or len(ids) != old_key.frames:
        return None
    expected = [(i * old_key.frame_width, 0, old_key.frame_width, old_key.frame_height) for i in range(old_key.frames)]
    if [atlases[item][1] for item in ids] != expected:
        return None
    return next(iter(ext_ids))


def _atlas_id(resource_path: Path, ext_id: str, frame_index: int) -> str:
    digest = hashlib.sha256(f"{resource_path.as_posix()}:{ext_id}:{frame_index}".encode()).hexdigest()[:12]
    return f"AtlasTexture_compat_{digest}"


def update_resource(path: Path, index: dict[tuple, CatalogSpec], repo_root: Path = REPO_ROOT) -> ResourceUpdate:
    schema = _load_schema(repo_root)
    original = path.read_text()
    text = original
    changed_paths: list[tuple[str, str]] = []
    managed: dict[str, tuple[object, CatalogSpec]] = {}
    ext_matches = list(EXT_RE.finditer(original))
    for match in ext_matches:
        old_path, ext_id = match.groups()
        if not old_path.startswith("res://content/sprites/operator/runtime/animations/"):
            continue
        old_key = schema.parse_filename(Path(old_path).name)
        if old_key is None:
            continue
        target = index.get(schema.semantic_identity(old_key))
        if target is None:
            continue
        managed[ext_id] = (old_key, target)
        if old_path != target.path:
            replacement = f'[ext_resource type="Texture2D" path="{target.path}" id="{ext_id}"]'
            text = text.replace(match.group(0), replacement, 1)
            changed_paths.append((old_path, target.path))

    if not managed:
        return ResourceUpdate(path, [], [], original)

    atlases = _atlas_records(original)
    array_start, array_end, blocks = _animation_blocks(text)
    additions: list[str] = []
    resized: list[tuple[str, int, int]] = []
    updated_blocks: list[str] = []
    target_ids: dict[str, list[str]] = {}
    for ext_id, (_old_key, target) in managed.items():
        by_region = {region: sub_id for sub_id, (atlas_ext, region) in atlases.items() if atlas_ext == ext_id}
        ids: list[str] = []
        for frame_index in range(target.frames):
            region = (frame_index * target.frame_width, 0, target.frame_width, target.frame_height)
            sub_id = by_region.get(region)
            if sub_id is None:
                sub_id = _atlas_id(path, ext_id, frame_index)
                if sub_id not in atlases:
                    additions.append(
                        f'[sub_resource type="AtlasTexture" id="{sub_id}"]\n'
                        f'atlas = ExtResource("{ext_id}")\n'
                        f'region = Rect2({region[0]}, 0, {region[2]}, {region[3]})\n'
                    )
            ids.append(sub_id)
        target_ids[ext_id] = ids

    for block in blocks:
        replacement = block
        for ext_id, (old_key, target) in managed.items():
            if _full_strip_ext(block, atlases, old_key) != ext_id:
                continue
            name_match = NAME_RE.search(block)
            name = name_match.group(1) if name_match else "<unnamed>"
            frame_match = FRAMES_RE.search(block)
            if frame_match is None:
                continue
            frame_entries = ", ".join(
                '{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sub_id
                for sub_id in target_ids[ext_id]
            )
            replacement = block[:frame_match.start(2)] + frame_entries + block[frame_match.end(2):]
            if old_key.frames != target.frames:
                resized.append((name, old_key.frames, target.frames))
            break
        updated_blocks.append(replacement)

    if updated_blocks != blocks:
        rebuilt = "[{" + "}, {".join(block[1:-1] for block in updated_blocks) + "}]"
        text = text[:array_start] + rebuilt + text[array_end:]
    if additions:
        resource_marker = text.find("[resource]")
        if resource_marker < 0:
            raise ValueError(f"missing [resource] block: {path}")
        text = text[:resource_marker] + "\n".join(additions) + "\n" + text[resource_marker:]
        ext_count = len(EXT_RE.findall(text))
        sub_count = len(ATLAS_RE.findall(text))
        text = re.sub(r"load_steps=\d+", f"load_steps={ext_count + sub_count + 1}", text, count=1)
    return ResourceUpdate(path, changed_paths, resized, text)


def stale_runtime_references(resource_root: Path, repo_root: Path = REPO_ROOT) -> list[dict[str, str]]:
    missing: list[dict[str, str]] = []
    project_root = repo_root / "custodian"
    for resource in sorted(resource_root.glob("*.tres")):
        text = resource.read_text(errors="replace")
        for animation_path, ext_id in EXT_RE.findall(text):
            if not animation_path.startswith("res://content/sprites/operator/runtime/"):
                continue
            disk_path = project_root / animation_path.removeprefix("res://")
            if not disk_path.exists():
                missing.append({
                    "resource": str(resource.relative_to(repo_root)),
                    "ext_resource": ext_id,
                    "missing_png": animation_path,
                })
    return missing


def inventory(repo_root: Path = REPO_ROOT) -> dict[str, list[str] | str]:
    root = repo_root / "custodian/game/actors/operator"
    compatibility = [str((root / name).relative_to(repo_root)) for name in COMPATIBILITY_RESOURCE_NAMES]
    catalog = str((root / CATALOG_RESOURCE_NAME).relative_to(repo_root))
    known = set(COMPATIBILITY_RESOURCE_NAMES) | {CATALOG_RESOURCE_NAME}
    weapon_owned = [str(path.relative_to(repo_root)) for path in sorted(root.glob("*_frames.tres")) if path.name not in known]
    return {
        "generated_compatibility": compatibility,
        "generated_catalog": catalog,
        "weapon_or_manually_authored": weapon_owned,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT)
    parser.add_argument("--catalog", type=Path)
    parser.add_argument("--resource", type=Path, action="append")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--inventory", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
    resource_root = repo_root / "custodian/game/actors/operator"
    if args.inventory:
        print(json.dumps(inventory(repo_root), indent=2))
        return 0
    if args.check:
        missing = stale_runtime_references(resource_root, repo_root)
        if missing:
            print("STALE OPERATOR SPRITEFRAMES RESOURCE", file=sys.stderr)
            for item in missing:
                print(
                    f"  {item['resource']} [{item['ext_resource']}] -> {item['missing_png']}",
                    file=sys.stderr,
                )
            return 1
        print("Operator SpriteFrames runtime paths: OK")
        return 0
    catalog_path = (args.catalog or repo_root / CATALOG_PATH.relative_to(REPO_ROOT)).resolve()
    index = catalog_index(catalog_path, repo_root)
    resources = args.resource or [resource_root / name for name in GENERATED_RESOURCE_NAMES]
    report = []
    for resource in resources:
        path = resource if resource.is_absolute() else repo_root / resource
        result = update_resource(path, index, repo_root)
        if result.changed and not args.dry_run:
            temp = path.with_suffix(path.suffix + ".compat.tmp")
            temp.write_text(result.text)
            temp.replace(path)
        report.append({
            "resource": str(path.relative_to(repo_root)),
            "changed": result.changed,
            "path_updates": result.changed_paths,
            "resized_animations": result.resized_animations,
        })
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        for item in report:
            if item["changed"]:
                print(f"updated {item['resource']}: {len(item['path_updates'])} paths, {len(item['resized_animations'])} animations")
        if not any(item["changed"] for item in report):
            print("Operator compatibility SpriteFrames already current")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
