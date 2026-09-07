#!/usr/bin/env python3
"""Synchronize authored Operator art into runtime authority, then describe runtime.

Authoring authority is ``source/``; execution authority is ``runtime/``. This tool
validates source, copies it into runtime, removes superseded runtime files, and only
then scans runtime to generate the runtime manifest. The manifest therefore describes
what gameplay will actually load, never a projection of source.
"""

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
    OperatorAssetKey, canonical_runtime_path, is_legacy_action, parse_filename,
    semantic_identity,
)


PROJECT_ROOT = Path(__file__).resolve().parents[2]

OPERATOR_SOURCE_ROOT = PROJECT_ROOT / "content/sprites/operator/source/animations"
OPERATOR_RUNTIME_ROOT = PROJECT_ROOT / "content/sprites/operator/runtime/animations"
RUNTIME_PACKAGE_ROOT = PROJECT_ROOT / "content/sprites/operator/runtime"
RUNTIME_MANIFEST_PATH = RUNTIME_PACKAGE_ROOT / "operator_runtime_manifest.generated.json"
ANIMATION_CATALOG_PATH = PROJECT_ROOT / "content/data/operator/generated/operator_animation_catalog.generated.json"

WEAPONS_ROOT = PROJECT_ROOT / "content/sprites/weapons"
WEAPON_SOURCE_GLOB = "*/source/operator"
WEAPON_RUNTIME_SEGMENT = "runtime/operator"

MANIFEST_SCHEMA = "custodian.operator_runtime_manifest.v1"
CATALOG_SCHEMA = "custodian.operator_animation_catalog.v2"
TIMING_SCHEMA = "custodian.operator_animation_timing.v1"
AUTHORED_OVERLAY_WEAPONS = {"vigil_pattern_dagger", "sword_cleaver"}


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


def identify_runtime_module(
    runtime_path: Path, module_root: Path = OPERATOR_RUNTIME_ROOT
) -> RuntimeModuleIdentity:
    key = parse_filename(runtime_path)
    if key.owner != "operator" or key.layer not in {"lower_body", "upper_body"}:
        raise ValueError(f"alignment repair supports Operator lower/upper layers: {runtime_path}")
    return RuntimeModuleIdentity(key.layer, key.animation_profile, key.action, key.direction,
                                 key.frames, key.frame_width, key.frame_height, key.action_group)


def resolve_source_for_runtime_module(
    runtime_path: Path,
    source_root: Path = OPERATOR_SOURCE_ROOT,
    module_root: Path = OPERATOR_RUNTIME_ROOT,
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


def timing_sidecar_path(png_path: Path) -> Path:
    return png_path.with_suffix("").with_suffix(".animation.json")


def _animation_identity(key: OperatorAssetKey) -> str:
    return "/".join((key.animation_profile, key.action_group, key.action, key.direction))


def read_timing(png_path: Path, key: OperatorAssetKey | None = None) -> dict | None:
    """Timing sidecars preserve authored FPS/loop/frame durations through the pipeline."""
    sidecar = timing_sidecar_path(png_path)
    if not sidecar.exists():
        return None
    key = key or parse_filename(png_path)
    identity = _animation_identity(key)
    prefix = f"{sidecar} [{identity}]"
    try:
        payload = json.loads(sidecar.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"{prefix}: invalid timing sidecar: {exc}") from exc
    if payload.get("schema") != TIMING_SCHEMA:
        raise ValueError(f"{prefix}: unexpected timing schema {payload.get('schema')!r}")
    frames = payload.get("frames")
    fps = payload.get("fps")
    loop = payload.get("loop")
    durations = payload.get("durations")
    if isinstance(frames, bool) or not isinstance(frames, int) or frames != key.frames:
        raise ValueError(f"{prefix}: frames must equal PNG declaration {key.frames}, got {frames!r}")
    if isinstance(fps, bool) or not isinstance(fps, (int, float)) or fps <= 0:
        raise ValueError(f"{prefix}: fps must be a positive number, got {fps!r}")
    if not isinstance(loop, bool):
        raise ValueError(f"{prefix}: loop must be bool, got {loop!r}")
    if not isinstance(durations, list) or len(durations) != frames:
        actual = len(durations) if isinstance(durations, list) else type(durations).__name__
        raise ValueError(f"{prefix}: durations must contain {frames} entries, got {actual}")
    if any(isinstance(value, bool) or not isinstance(value, (int, float)) or value <= 0 for value in durations):
        raise ValueError(f"{prefix}: all durations must be positive numbers, got {durations!r}")
    return {
        "schema": TIMING_SCHEMA,
        "frames": frames,
        "fps": float(fps),
        "loop": loop,
        "durations": [float(value) for value in durations],
    }


def weapon_source_roots(weapons_root: Path = WEAPONS_ROOT) -> list[Path]:
    """Only ``weapons/*/source/operator`` is authored Operator art; never the whole tree."""
    if not weapons_root.exists():
        return []
    return sorted(path for path in weapons_root.glob(WEAPON_SOURCE_GLOB) if path.is_dir())


def scan_sources(
    source_root: Path = OPERATOR_SOURCE_ROOT,
    weapons_root: Path = WEAPONS_ROOT,
    profile: str = "",
    legacy_skipped: list[Path] | None = None,
) -> list[tuple[Path, OperatorAssetKey]]:
    """Authoring may still hold legacy art; it is never synchronized into runtime."""
    found: list[tuple[Path, OperatorAssetKey]] = []
    for root in [source_root, *weapon_source_roots(weapons_root)]:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.png")):
            try:
                key = parse_filename(path, allow_legacy_action=True)
            except ValueError:
                if root == source_root:
                    raise
                continue
            if profile and key.animation_profile != profile:
                continue
            if is_legacy_action(key.action):
                if legacy_skipped is not None:
                    legacy_skipped.append(path)
                continue
            validate_dimensions(path, key)
            read_timing(path, key)
            found.append((path, key))
    return found


def scan_operator_runtime(
    runtime_root: Path = OPERATOR_RUNTIME_ROOT,
    profile: str = "",
    legacy_residue: list[Path] | None = None,
) -> list[tuple[Path, OperatorAssetKey]]:
    return _scan_runtime_tree(runtime_root, profile, strict=True, legacy_residue=legacy_residue)


def scan_weapon_runtime(
    weapons_root: Path = WEAPONS_ROOT,
    profile: str = "",
    legacy_residue: list[Path] | None = None,
) -> list[tuple[Path, OperatorAssetKey]]:
    found: list[tuple[Path, OperatorAssetKey]] = []
    if not weapons_root.exists():
        return found
    for weapon in sorted(path for path in weapons_root.iterdir() if path.is_dir()):
        root = weapon / WEAPON_RUNTIME_SEGMENT
        if root.is_dir():
            found.extend(_scan_runtime_tree(root, profile, strict=False, legacy_residue=legacy_residue))
    return found


def _scan_runtime_tree(
    root: Path, profile: str, *, strict: bool, legacy_residue: list[Path] | None
) -> list[tuple[Path, OperatorAssetKey]]:
    found: list[tuple[Path, OperatorAssetKey]] = []
    if not root.exists():
        return found
    for path in sorted(root.rglob("*.png")):
        try:
            key = parse_filename(path, allow_legacy_action=True)
        except ValueError:
            if strict:
                raise
            continue
        if profile and key.animation_profile != profile:
            continue
        # Legacy runtime files are migration residue: excluded from the manifest,
        # and deleted only by the explicit --remove-legacy-runtime cleanup.
        if is_legacy_action(key.action):
            if legacy_residue is not None:
                legacy_residue.append(path)
            continue
        found.append((path, key))
    return found


def _layer_entry(path: Path, key: OperatorAssetKey, project_root: Path) -> dict:
    relative = path.relative_to(project_root).as_posix()
    # Hard invariant: gameplay may only ever be pointed at runtime authority.
    if "/runtime/" not in f"/{relative}":
        raise RuntimeError(f"non-runtime animation entered runtime manifest: {relative}")
    if is_legacy_action(key.action):
        raise RuntimeError(f"legacy identity entered runtime: {key.action}")
    entry = {
        "path": "res://" + relative,
        "frames": key.frames,
        "frame_size": [key.frame_width, key.frame_height],
    }
    timing = read_timing(path, key)
    if timing is not None:
        entry["fps"] = timing["fps"]
        entry["loop"] = timing["loop"]
        entry["durations"] = timing["durations"]
    return entry


def build_runtime_manifest(
    runtime_assets: list[tuple[Path, OperatorAssetKey]],
    weapon_runtime_assets: list[tuple[Path, OperatorAssetKey]],
    *,
    project_root: Path = PROJECT_ROOT,
    errors: list[str] | None = None,
) -> dict:
    animations: dict[str, dict] = {}
    for path, key in sorted(runtime_assets, key=lambda item: item[0].as_posix()):
        entry_id = "/".join((key.animation_profile, key.action_group, key.action, key.direction))
        entry = animations.setdefault(entry_id, {
            "profile": key.animation_profile, "group": key.action_group,
            "action": key.action, "direction": key.direction, "layers": {},
        })
        entry["layers"][key.layer] = _layer_entry(path, key, project_root)

    for entry in animations.values():
        layers = entry["layers"]
        clock_layer = next((name for name in ("lower_body", "full_body", "upper_body") if name in layers), None)
        if clock_layer is None:
            continue
        clock = layers[clock_layer]
        if all(field in clock for field in ("fps", "loop", "durations")):
            entry["timing"] = {
                "clock_layer": clock_layer,
                "fps": clock["fps"],
                "loop": clock["loop"],
                "durations": clock["durations"],
            }

    weapons: dict[str, dict] = {}
    for path, key in sorted(weapon_runtime_assets, key=lambda item: item[0].as_posix()):
        default_mode = "authored_overlay" if key.owner in AUTHORED_OVERLAY_WEAPONS else "hybrid"
        weapon = weapons.setdefault(key.owner, {
            "animation_profile": key.animation_profile, "presentation_mode": default_mode,
            "held": {}, "overrides": {},
        })
        layer = _layer_entry(path, key, project_root)
        if key.action_group == "presentation" and key.action == "held_01":
            weapon["held"][key.direction] = layer
        else:
            slot = "/".join((key.action_group, key.action, key.direction))
            weapon["overrides"].setdefault(slot, {})[key.layer] = layer
    return {
        "schema": MANIFEST_SCHEMA,
        "animations": {key: animations[key] for key in sorted(animations)},
        "weapons": {key: weapons[key] for key in sorted(weapons)},
        "errors": list(errors or []),
    }


def build_animation_catalog(manifest: dict, catalog_path: Path) -> dict:
    """Merge runtime clock data into the broader generated presentation catalog."""
    if catalog_path.exists():
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        if catalog.get("schema") != CATALOG_SCHEMA:
            raise ValueError(f"{catalog_path}: unexpected catalog schema {catalog.get('schema')!r}")
    else:
        catalog = {"schema": CATALOG_SCHEMA, "animations": {}, "weapons": {}, "errors": []}
    catalog_animations = catalog.setdefault("animations", {})
    for identity, runtime_entry in manifest["animations"].items():
        entry = catalog_animations.setdefault(identity, runtime_entry)
        if "timing" in runtime_entry:
            entry["timing"] = runtime_entry["timing"]
        else:
            continue
        for layer, runtime_layer in runtime_entry["layers"].items():
            catalog_layer = entry.setdefault("layers", {}).get(layer)
            if catalog_layer is None:
                entry["layers"][layer] = runtime_layer
                continue
            for field in ("fps", "loop", "durations"):
                if field in runtime_layer:
                    catalog_layer[field] = runtime_layer[field]
    if not catalog.get("weapons"):
        catalog["weapons"] = manifest["weapons"]
    catalog["errors"] = manifest["errors"]
    return catalog


def validate_sources(
    sources: list[tuple[Path, OperatorAssetKey]]
) -> tuple[list[tuple[Path, OperatorAssetKey]], list[str]]:
    groups: dict[tuple, list[tuple[Path, OperatorAssetKey]]] = defaultdict(list)
    for item in sources:
        groups[semantic_identity(item[1])].append(item)
    errors: list[str] = []
    selected: list[tuple[Path, OperatorAssetKey]] = []
    for identity, candidates in sorted(groups.items()):
        if len(candidates) > 1:
            errors.append(f"superseded semantic siblings: {identity}: {[str(item[0]) for item in candidates]}")
        selected.append(sorted(candidates, key=lambda item: item[0].as_posix())[-1])

    synchronized: dict[tuple[str, str, str, str], dict[str, tuple[Path, OperatorAssetKey]]] = defaultdict(dict)
    for path, key in selected:
        if key.owner == "operator":
            synchronized[(key.animation_profile, key.action_group, key.action, key.direction)][key.layer] = (path, key)
    for identity, layers in sorted(synchronized.items()):
        if "lower_body" in layers and "upper_body" in layers:
            lower_key = layers["lower_body"][1]
            upper_key = layers["upper_body"][1]
            if lower_key.frames != upper_key.frames:
                errors.append(f"synchronized frame mismatch {identity}: lower={lower_key.frames} upper={upper_key.frames}")
        clock_layer = next((name for name in ("lower_body", "full_body", "upper_body") if name in layers), None)
        if clock_layer is None:
            continue
        clock_path, clock_key = layers[clock_layer]
        clock_timing = read_timing(clock_path, clock_key)
        for layer, (path, key) in sorted(layers.items()):
            if layer == clock_layer:
                continue
            sibling_timing = read_timing(path, key)
            if sibling_timing is not None and sibling_timing != clock_timing:
                errors.append(
                    f"synchronized timing mismatch {identity}: clock {clock_layer} "
                    f"({timing_sidecar_path(clock_path)}) != {layer} ({timing_sidecar_path(path)})"
                )
    return selected, errors


def synchronize_runtime(
    selected: list[tuple[Path, OperatorAssetKey]],
    *,
    project_root: Path = PROJECT_ROOT,
    dry_run: bool = False,
) -> list[Path]:
    """Copy authored art (and its timing sidecar) to canonical runtime locations."""
    emitted: list[Path] = []
    for source, key in selected:
        output = project_root / canonical_runtime_path(key)
        emitted.append(output)
        if dry_run:
            continue
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, output)
        sidecar = timing_sidecar_path(source)
        if sidecar.exists():
            shutil.copy2(sidecar, timing_sidecar_path(output))
    return emitted


def remove_superseded_runtime(
    emitted: list[Path],
    runtime_roots: list[Path],
    *,
    profile: str = "",
    dry_run: bool = False,
    remove_legacy: bool = False,
) -> list[Path]:
    keep = {path.resolve() for path in emitted}
    removed: list[Path] = []
    for root in runtime_roots:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.png")):
            if path.resolve() in keep:
                continue
            if profile and f"/{profile}/" not in path.as_posix():
                continue
            # Legacy runtime art still has live consumers until the actor cutover lands.
            if not remove_legacy:
                try:
                    if is_legacy_action(parse_filename(path, allow_legacy_action=True).action):
                        continue
                except ValueError:
                    pass
            removed.append(path)
            if dry_run:
                print(f"[dry-run] remove {path}")
                continue
            path.unlink()
            path.with_suffix(path.suffix + ".import").unlink(missing_ok=True)
            timing_sidecar_path(path).unlink(missing_ok=True)
    return removed


def sync(
    *, source_root: Path = OPERATOR_SOURCE_ROOT, weapons_root: Path = WEAPONS_ROOT,
    project_root: Path = PROJECT_ROOT, manifest_path: Path = RUNTIME_MANIFEST_PATH,
    catalog_path: Path | None = None,
    dry_run: bool = False, remove_superseded: bool = False, strict: bool = False,
    profile: str = "", remove_legacy_runtime: bool = False,
) -> dict:
    legacy_source: list[Path] = []
    sources = scan_sources(source_root, weapons_root, profile, legacy_skipped=legacy_source)
    selected, errors = validate_sources(sources)
    if strict and errors:
        raise RuntimeError("\n".join(errors))

    emitted = synchronize_runtime(selected, project_root=project_root, dry_run=dry_run)

    operator_runtime_root = project_root / "content/sprites/operator/runtime/animations"
    weapon_runtime_roots = [
        weapon / WEAPON_RUNTIME_SEGMENT
        for weapon in sorted(p for p in (project_root / "content/sprites/weapons").glob("*") if p.is_dir())
    ] if (project_root / "content/sprites/weapons").exists() else []
    if remove_superseded:
        remove_superseded_runtime(
            emitted, [operator_runtime_root, *weapon_runtime_roots],
            profile=profile, dry_run=dry_run, remove_legacy=remove_legacy_runtime,
        )

    # Scan runtime only after synchronizing, so the manifest describes execution authority.
    legacy_runtime: list[Path] = []
    if dry_run:
        runtime_assets = [(project_root / canonical_runtime_path(key), key)
                          for _s, key in selected if key.owner == "operator"]
        weapon_runtime_assets = [(project_root / canonical_runtime_path(key), key)
                                 for _s, key in selected if key.owner != "operator"]
    else:
        runtime_assets = scan_operator_runtime(operator_runtime_root, profile, legacy_runtime)
        weapon_runtime_assets = scan_weapon_runtime(
            project_root / "content/sprites/weapons", profile, legacy_runtime
        )

    manifest = build_runtime_manifest(
        runtime_assets, weapon_runtime_assets, project_root=project_root, errors=errors,
    )
    if not dry_run:
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        resolved_catalog_path = catalog_path or (
            project_root / "content/data/operator/generated/operator_animation_catalog.generated.json"
        )
        catalog = build_animation_catalog(manifest, resolved_catalog_path)
        resolved_catalog_path.parent.mkdir(parents=True, exist_ok=True)
        resolved_catalog_path.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    return {
        "source_assets": len(sources), "emitted": len(emitted),
        "runtime_assets": len(runtime_assets) + len(weapon_runtime_assets),
        "legacy_source_skipped": len(legacy_source),
        "legacy_runtime_residue": len(legacy_runtime),
        "errors": errors, "manifest": manifest,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=OPERATOR_SOURCE_ROOT)
    parser.add_argument("--weapons-root", type=Path, default=WEAPONS_ROOT)
    parser.add_argument("--project-root", type=Path, default=PROJECT_ROOT)
    parser.add_argument("--manifest-path", type=Path, default=RUNTIME_MANIFEST_PATH)
    parser.add_argument("--catalog-path", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--remove-superseded", action="store_true")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--profile", default="")
    parser.add_argument(
        "--remove-legacy-runtime", action="store_true",
        help="also delete legacy-named runtime art; only safe after the actor cutover",
    )
    parser.add_argument("--report-json", type=Path)
    args = parser.parse_args(argv)
    try:
        report = sync(
            source_root=args.source_root, weapons_root=args.weapons_root,
            project_root=args.project_root, manifest_path=args.manifest_path,
            catalog_path=args.catalog_path,
            dry_run=args.dry_run, remove_superseded=args.remove_superseded,
            strict=args.strict, profile=args.profile,
            remove_legacy_runtime=args.remove_legacy_runtime,
        )
    except (ValueError, RuntimeError) as exc:
        print(exc, file=sys.stderr)
        return 1
    if args.report_json:
        args.report_json.parent.mkdir(parents=True, exist_ok=True)
        args.report_json.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(
        f"synchronized {report['emitted']} Operator runtime sheets; "
        f"manifest describes {report['runtime_assets']} runtime assets "
        f"({len(report['errors'])} warnings)"
    )
    print(
        f"legacy migration debt: {report['legacy_source_skipped']} source, "
        f"{report['legacy_runtime_residue']} runtime residue"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
