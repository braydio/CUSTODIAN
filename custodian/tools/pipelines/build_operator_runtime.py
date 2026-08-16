#!/usr/bin/env python3
"""Build canonical Operator V2 runtime strips and semantic animation catalog."""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from operator_asset_schema import (
    OperatorAssetKey, canonical_runtime_path, parse_filename, semantic_identity,
)


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = PROJECT_ROOT / "content/sprites/operator/source/animations"
WEAPON_ROOT = PROJECT_ROOT / "content/sprites/weapons"
RUNTIME_ROOT = PROJECT_ROOT / "content/sprites/operator/runtime/animations"
CATALOG_PATH = PROJECT_ROOT / "content/data/operator/generated/operator_animation_catalog.generated.json"


@dataclass(frozen=True)
class RuntimeModuleIdentity:
    layer: str
    loadout: str
    action: str
    direction: str
    frames: int
    frame_width: int
    frame_height: int
    family: str

    @property
    def semantic_id(self) -> str:
        return "|".join((self.layer, self.loadout, self.action, self.direction))


@dataclass(frozen=True)
class RuntimeSourceResolution:
    runtime_path: Path
    identity: RuntimeModuleIdentity
    selected_source: Path | None
    candidates: tuple[Path, ...]
    builder_family: str


def identify_runtime_module(runtime_path: Path, module_root: Path = RUNTIME_ROOT) -> RuntimeModuleIdentity:
    key = parse_filename(runtime_path)
    if key.owner != "operator" or key.layer not in {"lower_body", "upper_body"}:
        raise ValueError(f"alignment repair supports Operator lower/upper layers: {runtime_path}")
    return RuntimeModuleIdentity(key.layer, key.animation_profile, key.action, key.direction,
                                 key.frames, key.frame_width, key.frame_height, key.action_group)


def resolve_source_for_runtime_module(
    runtime_path: Path, source_root: Path = SOURCE_ROOT, module_root: Path = RUNTIME_ROOT,
) -> RuntimeSourceResolution:
    key = parse_filename(runtime_path)
    identity = identify_runtime_module(runtime_path, module_root)
    selected = source_root / key.animation_profile / key.action_group / key.action / runtime_path.name
    candidates = tuple(sorted(selected.parent.glob(
        "__".join(runtime_path.stem.split("__")[:-2]) + "__*f__*.png"
    ))) if selected.parent.exists() else ()
    return RuntimeSourceResolution(runtime_path, identity, selected if selected.exists() else None, candidates, key.action_group)


def build_runtime_module_from_source(source: Path, runtime_path: Path, identity: RuntimeModuleIdentity) -> None:
    with Image.open(source) as image:
        expected = (identity.frames * identity.frame_width, identity.frame_height)
        if image.size != expected:
            raise ValueError(f"source contract changed: expected {expected}, got {image.size}")
    runtime_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, runtime_path)


def validate_dimensions(path: Path, key: OperatorAssetKey) -> None:
    with Image.open(path) as image:
        expected = (key.frames * key.frame_width, key.frame_height)
        if image.size != expected:
            raise ValueError(f"{path}: declared {expected[0]}x{expected[1]}, actual {image.width}x{image.height}")


def scan_sources(source_root: Path = SOURCE_ROOT, weapon_root: Path = WEAPON_ROOT, profile: str = "") -> list[tuple[Path, OperatorAssetKey]]:
    found: list[tuple[Path, OperatorAssetKey]] = []
    roots = [source_root]
    if weapon_root.exists():
        roots.append(weapon_root)
    for root in roots:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.png")):
            try:
                key = parse_filename(path)
            except ValueError:
                if root == source_root:
                    raise
                continue
            if profile and key.animation_profile != profile:
                continue
            validate_dimensions(path, key)
            found.append((path, key))
    return found


def build(
    *, source_root: Path = SOURCE_ROOT, weapon_root: Path = WEAPON_ROOT,
    project_root: Path = PROJECT_ROOT, catalog_path: Path = CATALOG_PATH,
    dry_run: bool = False, remove_superseded: bool = False, strict: bool = False,
    profile: str = "",
) -> dict:
    sources = scan_sources(source_root, weapon_root, profile)
    groups: dict[tuple, list[tuple[Path, OperatorAssetKey]]] = defaultdict(list)
    for item in sources:
        groups[semantic_identity(item[1])].append(item)
    errors: list[str] = []
    selected: list[tuple[Path, OperatorAssetKey]] = []
    for identity, candidates in sorted(groups.items()):
        if len(candidates) > 1:
            errors.append(f"superseded semantic siblings: {identity}: {[str(item[0]) for item in candidates]}")
        selected.append(sorted(candidates, key=lambda item: item[0].as_posix())[-1])

    synchronized: dict[tuple[str, str, str, str], dict[str, OperatorAssetKey]] = defaultdict(dict)
    for _path, key in selected:
        if key.owner == "operator":
            synchronized[(key.animation_profile, key.action_group, key.action, key.direction)][key.layer] = key
    for identity, layers in sorted(synchronized.items()):
        if "lower_body" in layers and "upper_body" in layers:
            if layers["lower_body"].frames != layers["upper_body"].frames:
                errors.append(f"synchronized frame mismatch {identity}: lower={layers['lower_body'].frames} upper={layers['upper_body'].frames}")
    if strict and errors:
        raise RuntimeError("\n".join(errors))

    emitted: list[Path] = []
    animations: dict[str, dict] = {}
    weapons: dict[str, dict] = {}
    for source, key in selected:
        if key.owner == "operator":
            relative = canonical_runtime_path(key)
            output = project_root / relative
            emitted.append(output)
            if not dry_run:
                output.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, output)
            entry_id = "/".join((key.animation_profile, key.action_group, key.action, key.direction))
            entry = animations.setdefault(entry_id, {
                "profile": key.animation_profile, "group": key.action_group,
                "action": key.action, "direction": key.direction, "layers": {},
            })
            entry["layers"][key.layer] = {
                "path": "res://" + relative.as_posix(), "frames": key.frames,
                "frame_size": [key.frame_width, key.frame_height],
            }
        else:
            default_mode = "authored_overlay" if key.owner in {"vigil_pattern_dagger", "sword_cleaver"} else "hybrid"
            weapon = weapons.setdefault(key.owner, {
                "animation_profile": key.animation_profile, "presentation_mode": default_mode,
                "held": {}, "overrides": {},
            })
            rel = source.relative_to(project_root)
            layer = {"path": "res://" + rel.as_posix(), "frames": key.frames,
                     "frame_size": [key.frame_width, key.frame_height]}
            if key.action_group == "presentation" and key.action == "held_01":
                weapon["held"][key.direction] = layer
            else:
                weapon["overrides"]["/".join((key.action_group, key.action, key.direction))] = layer

    runtime_scan_root = project_root / Path("content/sprites/operator/runtime/animations")
    if remove_superseded and runtime_scan_root.exists():
        keep = {path.resolve() for path in emitted}
        for path in sorted(runtime_scan_root.rglob("*.png")):
            if path.resolve() not in keep and (not profile or f"/{profile}/" in path.as_posix()):
                if dry_run:
                    print(f"[dry-run] remove {path}")
                else:
                    path.unlink()
                    path.with_suffix(path.suffix + ".import").unlink(missing_ok=True)
    catalog = {
        "schema": "custodian.operator_animation_catalog.v2",
        "animations": {key: animations[key] for key in sorted(animations)},
        "weapons": {key: weapons[key] for key in sorted(weapons)},
        "errors": errors,
    }
    if not dry_run:
        catalog_path.parent.mkdir(parents=True, exist_ok=True)
        catalog_path.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    return {"source_assets": len(sources), "emitted": len(emitted), "errors": errors, "catalog": catalog}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=SOURCE_ROOT)
    parser.add_argument("--weapon-root", type=Path, default=WEAPON_ROOT)
    parser.add_argument("--project-root", type=Path, default=PROJECT_ROOT)
    parser.add_argument("--catalog-path", type=Path, default=CATALOG_PATH)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--remove-superseded", action="store_true")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--profile", default="")
    parser.add_argument("--report-json", type=Path)
    args = parser.parse_args(argv)
    try:
        report = build(
            source_root=args.source_root, weapon_root=args.weapon_root,
            project_root=args.project_root, catalog_path=args.catalog_path,
            dry_run=args.dry_run, remove_superseded=args.remove_superseded,
            strict=args.strict, profile=args.profile,
        )
    except (ValueError, RuntimeError) as exc:
        print(exc, file=sys.stderr)
        return 1
    if args.report_json:
        args.report_json.parent.mkdir(parents=True, exist_ok=True)
        args.report_json.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"built {report['emitted']} Operator V2 runtime sheets ({len(report['errors'])} warnings)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
