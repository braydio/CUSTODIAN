#!/usr/bin/env python3
"""Inventory and migrate historical Operator runtime art into Pipeline V2."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image

from operator_asset_schema import (
    OperatorAssetKey, canonical_filename, canonical_runtime_path,
    infer_action_group, normalize_legacy_filename, semantic_identity,
)


PROJECT_ROOT = Path(__file__).resolve().parents[2]
OPERATOR_ROOT = PROJECT_ROOT / "content/sprites/operator"
RUNTIME_ROOT = OPERATOR_ROOT / "runtime"
SOURCE_LEGACY = OPERATOR_ROOT / "source/legacy"
REPORT_PATH = PROJECT_ROOT.parent / "reports/operator/operator_asset_migration_v2.json"
LEGACY_RUNTIME_ROOTS = (
    "animation_base", "curated", "modules", "actions", "body", "fx", "overlay",
    "overlays", "full_body", "weapon", "live_review", "idle", "modular_fx",
    "modular_ranged_weapon", "modular_weapon", "parry_fx", "weapons",
)
RUNTIME_CONSUMER_EXTENSIONS = {".gd", ".tscn", ".tres", ".py", ".json"}


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def _slug(value: str) -> str:
    value = re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")
    return value or "legacy_asset"


def _profile_from_path(path: Path) -> str:
    text = path.as_posix()
    if "vigil" in text:
        return "melee_1h_dagger"
    if "cleaver" in text or "melee_2h" in text or "heavy_2h" in text:
        return "melee_1h_heavy"
    if "melee_1h" in text or "/melee/" in text:
        return "melee_1h"
    if "ranged" in text or "carbine" in text:
        return "ranged_2h"
    if "sidearm" in text or "pistol" in text:
        return "sidearm"
    return "unarmed"


def _layer_from_path(path: Path) -> str:
    text = path.as_posix()
    name = path.name
    if any(token in text for token in ("/fx/", "/overlay/", "/overlays/", "modular_fx", "parry_fx")) or "_fx" in name or "effects" in name:
        return "fx"
    if "/head/" in text:
        return "head"
    if "cape" in text:
        return "cape"
    if any(token in text for token in ("/weapon/", "/weapons/", "ranged_weapon", "modular_weapon")) or "_weapon" in name:
        return "weapon"
    return "full_body"


def fallback_key(path: Path) -> OperatorAssetKey:
    with Image.open(path) as image:
        width, height = image.size
    profile = _profile_from_path(path)
    layer = _layer_from_path(path)
    action = "legacy_" + _slug(path.stem)
    return OperatorAssetKey("operator", layer, profile, infer_action_group(action), action, "omni", 1, width, height)


def weapon_owner(path: Path) -> str | None:
    parts = path.parts
    for marker in ("weapon", "weapons"):
        if marker in parts:
            index = parts.index(marker)
            if index + 2 < len(parts) and parts[index + 1] == "melee_1h":
                return parts[index + 2]
            if index + 1 < len(parts):
                candidate = parts[index + 1]
                if candidate not in {"melee_1h", "ranged_2h", "unarmed", "curated"}:
                    return candidate
    return None


def classify_runtime(path: Path) -> tuple[OperatorAssetKey, str]:
    try:
        key = normalize_legacy_filename(path)
        classification = "migratable"
    except ValueError:
        key = fallback_key(path)
        classification = "referenced_legacy" if is_referenced(path) else "unreferenced_legacy"
    owner = weapon_owner(path)
    if owner and key.layer == "weapon":
        key = OperatorAssetKey(owner, "weapon", key.animation_profile, key.action_group, key.action,
                               key.direction, key.frames, key.frame_width, key.frame_height)
    return key, classification


def is_referenced(path: Path) -> bool:
    needle = "res://" + path.relative_to(PROJECT_ROOT).as_posix()
    for root in (PROJECT_ROOT / "game", PROJECT_ROOT / "tools"):
        for candidate in root.rglob("*"):
            if candidate.suffix not in RUNTIME_CONSUMER_EXTENSIONS or not candidate.is_file():
                continue
            try:
                if needle in candidate.read_text(encoding="utf-8"):
                    return True
            except UnicodeDecodeError:
                pass
    return False


def destination_for(path: Path, key: OperatorAssetKey) -> Path:
    if key.owner != "operator":
        base = PROJECT_ROOT / "content/sprites/weapons" / key.owner / "operator" / key.animation_profile
        tail = Path("held") if key.action_group == "presentation" else Path("overrides") / key.action_group / key.action
        return base / tail / canonical_filename(key)
    return PROJECT_ROOT / canonical_runtime_path(key)


def build_plan() -> dict:
    records = []
    claimed: dict[Path, str] = {}
    hashes: dict[str, Path] = {}
    for path in sorted(RUNTIME_ROOT.rglob("*.png")):
        if "/animations/" in path.as_posix():
            continue
        if "/live_review/" in path.as_posix():
            file_hash = digest(path)
            destination = PROJECT_ROOT / "animation_review/operator" / path.relative_to(RUNTIME_ROOT / "live_review")
            records.append({
                "old": path.relative_to(PROJECT_ROOT).as_posix(),
                "new": destination.relative_to(PROJECT_ROOT).as_posix(),
                "classification": "unreferenced_legacy", "sha256": file_hash,
                "duplicate_of": None, "semantic_id": [], "diagnostic": "review output",
            })
            continue
        try:
            with Image.open(path) as image:
                image.verify()
        except Exception:
            file_hash = digest(path)
            destination = SOURCE_LEGACY / "unclassified" / path.name
            records.append({
                "old": path.relative_to(PROJECT_ROOT).as_posix(),
                "new": destination.relative_to(PROJECT_ROOT).as_posix(),
                "classification": "unreferenced_legacy", "sha256": file_hash,
                "duplicate_of": None, "semantic_id": [], "diagnostic": "unreadable PNG",
            })
            continue
        key, classification = classify_runtime(path)
        file_hash = digest(path)
        destination = destination_for(path, key)
        if destination in claimed and claimed[destination] != file_hash:
            key = OperatorAssetKey(
                key.owner, key.layer, key.animation_profile, key.action_group,
                f"{key.action}_legacy_{file_hash[:8]}", key.direction, key.frames,
                key.frame_width, key.frame_height,
            )
            destination = destination_for(path, key)
        duplicate_of = hashes.get(file_hash)
        if duplicate_of is not None:
            classification = "duplicate"
        else:
            hashes[file_hash] = destination
        claimed[destination] = file_hash
        records.append({
            "old": path.relative_to(PROJECT_ROOT).as_posix(),
            "new": destination.relative_to(PROJECT_ROOT).as_posix(),
            "classification": classification, "sha256": file_hash,
            "duplicate_of": duplicate_of.relative_to(PROJECT_ROOT).as_posix() if duplicate_of else None,
            "semantic_id": list(semantic_identity(key)),
            "source_new": (
                (Path("content/sprites/operator/source/animations") / key.animation_profile /
                 key.action_group / key.action / canonical_filename(key)).as_posix()
                if key.owner == "operator" else destination.relative_to(PROJECT_ROOT).as_posix()
            ),
        })
    return {
        "schema": "custodian.operator_asset_migration.v2",
        "records": records,
        "summary": dict(Counter(record["classification"] for record in records)),
    }


def rewrite_references(mapping: dict[str, str]) -> int:
    changed = 0
    for root in (PROJECT_ROOT / "game", PROJECT_ROOT / "tools"):
        for path in sorted(root.rglob("*")):
            if path.suffix not in RUNTIME_CONSUMER_EXTENSIONS or not path.is_file():
                continue
            try:
                original = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            updated = original
            for old, new in mapping.items():
                updated = updated.replace("res://" + old, "res://" + new)
            if updated != original:
                path.write_text(updated, encoding="utf-8")
                changed += 1
    return changed


def apply_plan(plan: dict, cleanup_legacy: bool) -> dict:
    mapping: dict[str, str] = {}
    copied = 0
    removed = 0
    first_by_hash: dict[str, Path] = {}
    for record in plan["records"]:
        source = PROJECT_ROOT / record["old"]
        destination = PROJECT_ROOT / record["new"]
        if record["sha256"] in first_by_hash:
            actual = first_by_hash[record["sha256"]]
            mapping[record["old"]] = actual.relative_to(PROJECT_ROOT).as_posix()
        else:
            destination.parent.mkdir(parents=True, exist_ok=True)
            if not destination.exists() or digest(destination) != record["sha256"]:
                shutil.copy2(source, destination)
                copied += 1
            first_by_hash[record["sha256"]] = destination
            mapping[record["old"]] = record["new"]
        source_new = record.get("source_new")
        if source_new:
            canonical_source = PROJECT_ROOT / source_new
            canonical_source.parent.mkdir(parents=True, exist_ok=True)
            if not canonical_source.exists() or digest(canonical_source) != record["sha256"]:
                shutil.copy2(source, canonical_source)
    rewritten = rewrite_references(mapping)
    if cleanup_legacy:
        for record in plan["records"]:
            source = PROJECT_ROOT / record["old"]
            source.unlink(missing_ok=True)
            source.with_suffix(source.suffix + ".import").unlink(missing_ok=True)
            removed += 1
        for root_name in LEGACY_RUNTIME_ROOTS:
            root = RUNTIME_ROOT / root_name
            if root.exists():
                leftovers = SOURCE_LEGACY / "unclassified/runtime_leftovers" / root_name
                for leftover in sorted(p for p in root.rglob("*") if p.is_file()):
                    relative = leftover.relative_to(root)
                    target = leftovers / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    if not target.exists():
                        shutil.move(leftover, target)
                    else:
                        leftover.unlink()
                shutil.rmtree(root)
        old_new_operator = OPERATOR_ROOT / "new_operator"
        if old_new_operator.exists():
            archive = SOURCE_LEGACY / "masters/new_operator"
            shutil.copytree(old_new_operator, archive, dirs_exist_ok=True)
            shutil.rmtree(old_new_operator)
        old_source = OPERATOR_ROOT / "source"
        for child in list(old_source.iterdir()) if old_source.exists() else []:
            if child.name in {"animations", "legacy"}:
                continue
            target = SOURCE_LEGACY / "masters/source_original" / child.name
            target.parent.mkdir(parents=True, exist_ok=True)
            if child.is_dir():
                shutil.copytree(child, target, dirs_exist_ok=True)
                shutil.rmtree(child)
            else:
                shutil.copy2(child, target)
                child.unlink()
    dimension_repairs = repair_canonical_dimensions()
    semantic_repairs = disambiguate_canonical_semantics()
    archived_reference_repairs = rewrite_archived_source_references()
    prior_manifest_repairs = rewrite_from_prior_manifest()
    return {"copied": copied, "removed": removed, "rewritten_consumers": rewritten,
            "dimension_repairs": dimension_repairs, "semantic_repairs": semantic_repairs,
            "archived_reference_repairs": archived_reference_repairs,
            "prior_manifest_repairs": prior_manifest_repairs}


def repair_canonical_dimensions() -> int:
    """Rename migrated strips when historical filename metadata contradicted live pixels."""
    source_root = OPERATOR_ROOT / "source/animations"
    mapping: dict[str, str] = {}
    repairs = 0
    for source in sorted(source_root.rglob("*.png")) if source_root.exists() else []:
        try:
            key = normalize_legacy_filename(source)
            with Image.open(source) as image:
                actual_width, actual_height = image.size
        except Exception:
            continue
        frame_width = actual_width // key.frames if actual_width % key.frames == 0 else actual_width
        frames = key.frames if actual_width % key.frames == 0 else 1
        if (frames, frame_width, actual_height) == (key.frames, key.frame_width, key.frame_height):
            continue
        corrected = OperatorAssetKey(key.owner, key.layer, key.animation_profile, key.action_group,
                                     key.action, key.direction, frames, frame_width, actual_height)
        corrected_source = source.with_name(canonical_filename(corrected))
        if corrected_source.exists() and digest(corrected_source) != digest(source):
            corrected = OperatorAssetKey(
                corrected.owner, corrected.layer, corrected.animation_profile, corrected.action_group,
                f"{corrected.action}_legacy_{digest(source)[:8]}", corrected.direction,
                corrected.frames, corrected.frame_width, corrected.frame_height,
            )
            corrected_source = source.parent.parent / corrected.action / canonical_filename(corrected)
        corrected_source.parent.mkdir(parents=True, exist_ok=True)
        source.rename(corrected_source)
        old_runtime = PROJECT_ROOT / canonical_runtime_path(key)
        new_runtime = PROJECT_ROOT / canonical_runtime_path(corrected)
        if old_runtime.exists():
            new_runtime.parent.mkdir(parents=True, exist_ok=True)
            old_runtime.rename(new_runtime)
            mapping[old_runtime.relative_to(PROJECT_ROOT).as_posix()] = new_runtime.relative_to(PROJECT_ROOT).as_posix()
        repairs += 1
    if mapping:
        rewrite_references(mapping)
    return repairs


def disambiguate_canonical_semantics() -> int:
    source_root = OPERATOR_ROOT / "source/animations"
    groups: dict[tuple, list[tuple[Path, OperatorAssetKey]]] = defaultdict(list)
    for source in sorted(source_root.rglob("*.png")) if source_root.exists() else []:
        try:
            key = normalize_legacy_filename(source)
        except ValueError:
            continue
        groups[semantic_identity(key)].append((source, key))
    rename_items: list[tuple[Path, OperatorAssetKey]] = []
    for candidates in groups.values():
        if len(candidates) > 1:
            # Stable newest-contract preference: retain the largest canvas/frame
            # candidate as the unsuffixed semantic action and preserve every other
            # pixel-distinct historical strip under an explicit legacy action.
            ordered = sorted(candidates, key=lambda item: (
                item[1].frame_width * item[1].frame_height, item[1].frames, item[0].as_posix()
            ), reverse=True)
            rename_items.extend(ordered[1:])
    # A synchronized lower/upper semantic may only share a clock when frame counts match.
    sync: dict[tuple, dict[str, tuple[Path, OperatorAssetKey]]] = defaultdict(dict)
    for candidates in groups.values():
        for source, key in candidates:
            if key.layer in {"lower_body", "upper_body"}:
                sync[(key.animation_profile, key.action_group, key.action, key.direction)][key.layer] = (source, key)
    for layers in sync.values():
        if set(layers) == {"lower_body", "upper_body"} and layers["lower_body"][1].frames != layers["upper_body"][1].frames:
            rename_items.append(layers["upper_body"])
    mapping: dict[str, str] = {}
    repairs = 0
    seen: set[Path] = set()
    for source, key in rename_items:
        if source in seen or not source.exists():
            continue
        seen.add(source)
        renamed = OperatorAssetKey(
            key.owner, key.layer, key.animation_profile, key.action_group,
            f"{key.action}_legacy_{digest(source)[:8]}", key.direction,
            key.frames, key.frame_width, key.frame_height,
        )
        new_source = source.parent.parent / renamed.action / canonical_filename(renamed)
        new_source.parent.mkdir(parents=True, exist_ok=True)
        source.rename(new_source)
        old_runtime = PROJECT_ROOT / canonical_runtime_path(key)
        new_runtime = PROJECT_ROOT / canonical_runtime_path(renamed)
        if old_runtime.exists() and digest(old_runtime) == digest(new_source):
            new_runtime.parent.mkdir(parents=True, exist_ok=True)
            old_runtime.rename(new_runtime)
            mapping[old_runtime.relative_to(PROJECT_ROOT).as_posix()] = new_runtime.relative_to(PROJECT_ROOT).as_posix()
        repairs += 1
    if mapping:
        rewrite_references(mapping)
    return repairs


def rewrite_archived_source_references() -> int:
    archive = SOURCE_LEGACY / "masters/new_operator"
    if not archive.exists():
        return 0
    runtime_by_hash: dict[str, Path] = {}
    for runtime in sorted((RUNTIME_ROOT / "animations").rglob("*.png")):
        runtime_by_hash.setdefault(digest(runtime), runtime)
    mapping: dict[str, str] = {}
    referenced_text = "\n".join(
        path.read_text(encoding="utf-8", errors="ignore")
        for root in (PROJECT_ROOT / "game", PROJECT_ROOT / "tools")
        for path in root.rglob("*") if path.is_file() and path.suffix in RUNTIME_CONSUMER_EXTENSIONS
    )
    for archived in sorted(archive.rglob("*.png")):
        old = Path("content/sprites/operator/new_operator") / archived.relative_to(archive)
        runtime = runtime_by_hash.get(digest(archived))
        if runtime is not None:
            mapping[old.as_posix()] = runtime.relative_to(PROJECT_ROOT).as_posix()
        elif ("res://" + old.as_posix()) in referenced_text:
            try:
                key = normalize_legacy_filename(archived)
            except ValueError:
                key = fallback_key(archived)
            with Image.open(archived) as image:
                width, height = image.size
            frames = key.frames if width % key.frames == 0 else 1
            key = OperatorAssetKey(key.owner, key.layer, key.animation_profile, key.action_group,
                                   key.action, key.direction, frames, width // frames, height)
            source = OPERATOR_ROOT / "source/animations" / key.animation_profile / key.action_group / key.action / canonical_filename(key)
            runtime = PROJECT_ROOT / canonical_runtime_path(key)
            source.parent.mkdir(parents=True, exist_ok=True)
            runtime.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(archived, source)
            shutil.copy2(archived, runtime)
            mapping[old.as_posix()] = runtime.relative_to(PROJECT_ROOT).as_posix()
    return rewrite_references(mapping)


def rewrite_from_prior_manifest() -> int:
    manifest = PROJECT_ROOT.parent / "reports/operator/operator_asset_migration_v2.json"
    if not manifest.exists():
        return 0
    records = json.loads(manifest.read_text(encoding="utf-8")).get("records", [])
    runtime_by_hash = {digest(path): path for path in (RUNTIME_ROOT / "animations").rglob("*.png")}
    mapping = {
        record["old"]: runtime_by_hash[record["sha256"]].relative_to(PROJECT_ROOT).as_posix()
        for record in records if record.get("sha256") in runtime_by_hash
    }
    return rewrite_references(mapping)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--cleanup-legacy", action="store_true")
    parser.add_argument("--report-json", type=Path, default=REPORT_PATH)
    args = parser.parse_args()
    plan = build_plan()
    result = apply_plan(plan, args.cleanup_legacy) if args.apply else {"dry_run": True}
    payload = {**plan, "result": result}
    args.report_json.parent.mkdir(parents=True, exist_ok=True)
    args.report_json.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"summary": plan["summary"], "result": result}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
