#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ASSET_EXTS = {".png"}
IMPORT_SUFFIX = ".png.import"

SKIP_DIR_NAMES = {
    "_extraction_review",
    "_manifest_archive",
    "_organize_backup",
    "_duplicates",
    ".godot",
}

SKIP_FILE_PATTERNS = [
    re.compile(r".*_detected_bboxes\.png$", re.I),
    re.compile(r".*contact_sheet.*\.png$", re.I),
]

FLOOR_THEME_BY_NAME = {
    "main_courtyard_flagstone_01": "courtyard",
    "main_courtyard_flagstone_02": "courtyard",
    "main_courtyard_flagstone_cracked_01": "courtyard",
    "main_courtyard_flagstone_wet_01": "courtyard",
    "main_courtyard_flagstone_mossy_01": "courtyard",
    "main_gate_threshold_stone_01": "gatehouse",
    "great_hall_marble_floor_01": "great_hall",
    "great_hall_marble_floor_cracked_01": "great_hall",
    "great_hall_carpet_runner_vertical_01": "great_hall",
    "great_hall_carpet_runner_horizontal_01": "great_hall",
    "rampart_walkway_floor_01": "ramparts",
    "rampart_walkway_broken_01": "ramparts",
    "cliff_rock_floor_01": "cliffs",
    "cliff_rock_floor_cracked_01": "cliffs",
    "roof_slate_dark_01": "roofs",
    "dungeon_stone_floor_01": "dungeon",
    "undercroft_wet_stone_floor_01": "undercroft",
    "ocean_void_01": "ocean",
}

PROP_THEME_PREFIXES = [
    ("prop_banquet_table", "tables"),
    ("prop_bookshelf", "furniture"),
    ("prop_chapel_pew", "furniture"),
    ("prop_throne", "throne"),
    ("prop_sarcophagus", "tombs"),
    ("prop_barrel", "storage"),
    ("prop_crate", "storage"),
    ("prop_banner", "hanging"),
    ("prop_portcullis_chain", "hanging"),
    ("prop_brazier", "lights"),
    ("prop_torch", "lights"),
    ("prop_gate_winch", "mechanical"),
    ("prop_broken_cart", "debris"),
    ("prop_fallen", "debris"),
    ("prop_gargoyle", "statues"),
    ("prop_gothic_statue", "statues"),
    ("prop_broken_spire", "rubble"),
    ("prop_fallen_masonry", "rubble"),
    ("prop_low_garden_wall", "low_walls"),
    ("prop_rope_bridge_anchor", "anchors"),
    ("prop_gate_barricade", "barriers"),
    ("prop_great_hall_column", "columns"),
    ("prop_courtyard_fountain", "large"),
    ("prop_telescope", "observatory"),
    ("prop_sea_spray_rock", "rocks"),
    ("prop_lightning_rod", "rooftop"),
]

def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()

def die(msg: str) -> None:
    raise SystemExit(f"ERROR: {msg}")

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def read_json(path: Path) -> Any | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None

def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=False) + "\n", encoding="utf-8")

def res_path(custodian_root: Path, path: Path) -> str:
    return "res://" + path.resolve().relative_to(custodian_root.resolve()).as_posix()

def repo_root_from_custodian(custodian_root: Path) -> Path:
    return custodian_root.parent if custodian_root.name == "custodian" else custodian_root

def should_skip_path(path: Path) -> bool:
    for part in path.parts:
        if part in SKIP_DIR_NAMES or part.startswith("_organize_backup_"):
            return True
    return any(p.match(path.name) for p in SKIP_FILE_PATTERNS)

def normalize_theme_name(s: str) -> str:
    s = s.strip().lower()
    s = re.sub(r"^prop_", "", s)
    s = re.sub(r"[^a-z0-9_]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s or "misc"

def infer_prop_theme(stem: str, source_path: Path) -> str:
    for prefix, theme in PROP_THEME_PREFIXES:
        if stem.startswith(prefix):
            return theme

    # Preserve existing runtime prop subdomain, but remove redundant prop_ prefix.
    parts = list(source_path.parts)
    if "props" in parts:
        i = parts.index("props")
        if len(parts) > i + 1:
            return normalize_theme_name(parts[i + 1])

    pieces = stem.split("_")
    if len(pieces) >= 2 and pieces[0] == "prop":
        return normalize_theme_name(pieces[1])

    return "misc"

def classify_asset(path: Path) -> tuple[str, str] | None:
    stem = path.stem

    if should_skip_path(path):
        return None

    if stem in FLOOR_THEME_BY_NAME:
        return ("tiles/floors", FLOOR_THEME_BY_NAME[stem])

    if stem.startswith("main_courtyard_flagstone"):
        return ("tiles/floors", "courtyard")
    if stem.startswith("great_hall_") and ("floor" in stem or "carpet" in stem):
        return ("tiles/floors", "great_hall")
    if stem.startswith("rampart_walkway"):
        return ("tiles/floors", "ramparts")
    if stem.startswith("cliff_rock_floor"):
        return ("tiles/floors", "cliffs")
    if stem.startswith("roof_slate"):
        return ("tiles/floors", "roofs")
    if stem.startswith("dungeon_"):
        return ("tiles/floors", "dungeon")
    if stem.startswith("undercroft_"):
        return ("tiles/floors", "undercroft")
    if stem.startswith("ocean_void"):
        return ("tiles/floors", "ocean")

    if stem.startswith("gothic_castle_wall_"):
        return ("walls", "gothic_castle")
    if stem.startswith("great_hall_wall_"):
        return ("walls", "great_hall")
    if stem.startswith("rampart_parapet") or stem.startswith("rampart_crenellation") or stem.startswith("rampart_broken_gap"):
        return ("walls", "ramparts")

    if stem.startswith("cliff_"):
        return ("terrain", "cliffs")
    if stem.startswith("ocean_"):
        return ("terrain", "ocean")

    if stem.startswith("main_gate_portcullis"):
        return ("doors_traversal", "gates")
    if stem.startswith("gothic_double_door"):
        return ("doors_traversal", "doors")
    if stem.startswith("stone_stairs_"):
        return ("doors_traversal", "stairs")
    if stem.startswith("floor_hatch_"):
        return ("doors_traversal", "hatches")

    if stem.startswith("prop_"):
        return ("props", infer_prop_theme(stem, path))

    # Preserve already-organized runtime domains when possible.
    parts = list(path.parts)
    for domain in ("doors_traversal", "terrain", "walls", "tiles", "props"):
        if domain in parts:
            i = parts.index(domain)
            theme = parts[i + 1] if len(parts) > i + 1 else "misc"
            return (domain, normalize_theme_name(theme))

    return None

def stable_asset_id(domain: str, theme: str, stem: str) -> str:
    return f"sundered_keep/{domain}/{theme}/{stem}"

def same_file_content(a: Path, b: Path) -> bool:
    return a.exists() and b.exists() and a.stat().st_size == b.stat().st_size and sha256(a) == sha256(b)

def unique_dest(dest: Path, src: Path) -> Path:
    if not dest.exists():
        return dest

    try:
        if dest.resolve() == src.resolve():
            return dest
    except Exception:
        pass

    if same_file_content(dest, src):
        return dest

    short = sha256(src)[:8]
    return dest.with_name(f"{dest.stem}__dup_{short}{dest.suffix}")

def collect_source_roots(custodian_root: Path) -> list[Path]:
    roots = [
        custodian_root / "content" / "runtime" / "sundered_keep",
        custodian_root / "content" / "tiles" / "sundered_keep",
        custodian_root / "content" / "tiles" / "sundered",
    ]
    return [r for r in roots if r.exists()]

def collect_pngs(roots: list[Path]) -> list[Path]:
    found: list[Path] = []
    for root in roots:
        for p in root.rglob("*.png"):
            if p.name.endswith(".png") and not should_skip_path(p):
                found.append(p)
    return sorted(set(found), key=lambda p: p.as_posix())

def associated_import(path: Path) -> Path:
    return path.with_name(path.name + ".import")

def associated_game32(path: Path) -> Path:
    return path.with_suffix(".game32.json")

def update_import_text(import_path: Path, custodian_root: Path, png_path: Path) -> None:
    if not import_path.exists():
        return
    try:
        text = import_path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return
    new_res = res_path(custodian_root, png_path)
    text = re.sub(r'source_file="res://[^"]+\.png"', f'source_file="{new_res}"', text)
    import_path.write_text(text, encoding="utf-8")

def backup_file(path: Path, backup_root: Path, repo_root: Path, apply: bool) -> None:
    if not apply or not path.exists():
        return
    rel = path.resolve().relative_to(repo_root.resolve())
    dest = backup_root / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, dest)

def move_or_delete_duplicate(src: Path, dest: Path, backup_root: Path, repo_root: Path, apply: bool, actions: list[str]) -> None:
    if src.resolve() == dest.resolve():
        actions.append(f"KEEP {src}")
        return

    if dest.exists() and same_file_content(src, dest):
        actions.append(f"DEDUP {src} -> already exists at {dest}")
        if apply:
            backup_file(src, backup_root, repo_root, apply)
            src.unlink()
        return

    actions.append(f"MOVE {src} -> {dest}")
    if apply:
        backup_file(src, backup_root, repo_root, apply)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dest))

def archive_file(src: Path, archive_root: Path, backup_root: Path, repo_root: Path, apply: bool, actions: list[str]) -> None:
    if not src.exists():
        return
    try:
        rel = src.resolve().relative_to(repo_root.resolve())
    except ValueError:
        rel = Path(src.name)
    dest = archive_root / rel
    actions.append(f"ARCHIVE {src} -> {dest}")
    if apply:
        backup_file(src, backup_root, repo_root, apply)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dest))

def remove_empty_dirs(root: Path, stop_at: Path, actions: list[str], apply: bool) -> None:
    if not root.exists():
        return
    dirs = sorted([p for p in root.rglob("*") if p.is_dir()], key=lambda p: len(p.parts), reverse=True)
    for d in dirs:
        if d == stop_at or should_skip_path(d):
            continue
        try:
            next(d.iterdir())
        except StopIteration:
            actions.append(f"RMDIR {d}")
            if apply:
                d.rmdir()

def infer_game32_record(domain: str, theme: str, path: Path) -> dict[str, Any]:
    stem = path.stem
    is_floor = domain == "tiles/floors"
    is_void = stem in {"ocean_void_01", "ocean_dark_water_01"}
    is_wall = domain == "walls"
    is_doorish = domain == "doors_traversal"

    return {
        "tile_size_px": 32,
        "domain": domain,
        "theme": theme,
        "logical_footprint_cells": [1, 1],
        "placement_rule": "snap_to_grid32" if is_floor else "snap_bottom_to_grid32",
        "anchor": "top_left" if is_floor else "bottom_center",
        "walkable": bool(is_floor and not is_void) or ("open" in stem) or ("arch" in stem) or ("breach" in stem) or ("stairs" in stem) or ("hatch_open" in stem),
        "blocks_movement": bool(is_void or (is_wall and not any(x in stem for x in ["arch", "breach", "broken_gap"])) or ("closed" in stem and is_doorish)),
        "blocks_projectiles": bool(is_wall and not any(x in stem for x in ["arch", "breach", "broken_gap"])),
        "blocks_vision": bool(is_wall and not any(x in stem for x in ["arch", "breach", "broken_gap"])),
        "render": {
            "z_layer": "ground" if is_floor else ("architecture" if domain in {"walls", "doors_traversal"} else "props"),
            "y_sort": not is_floor,
            "import_filter": "nearest_or_disabled_in_godot",
            "mipmaps": False,
        },
        "tags": sorted(set(["sundered_keep", domain.replace("/", "_"), theme] + stem.split("_"))),
    }

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--custodian-root", default="custodian")
    ap.add_argument("--apply", action="store_true", help="Actually move/archive/write files. Omit for dry-run.")
    ap.add_argument("--keep-old-manifests", action="store_true", help="Do not archive old per-asset/domain manifests.")
    args = ap.parse_args()

    custodian_root = Path(args.custodian_root).resolve()
    if not (custodian_root / "content").exists():
        die(f"Bad custodian root: {custodian_root}")

    repo_root = repo_root_from_custodian(custodian_root).resolve()
    canonical_root = custodian_root / "content" / "runtime" / "sundered_keep"
    manifest_dir = canonical_root / "_manifests"
    metadata_dir = custodian_root / "content" / "metadata" / "game32"

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_root = canonical_root / f"_organize_backup_{stamp}"
    archive_root = canonical_root / "_manifest_archive" / stamp

    roots = collect_source_roots(custodian_root)
    if not roots:
        die("No Sundered Keep runtime/source roots found.")

    actions: list[str] = []
    pngs = collect_pngs(roots)

    # Read all existing manifests before moving anything.
    existing_json_by_stem: dict[str, list[dict[str, Any]]] = defaultdict(list)
    manifest_files: list[Path] = []

    for root in roots + [metadata_dir]:
        if not root.exists():
            continue
        for j in root.rglob("*.json"):
            if should_skip_path(j):
                continue
            if "sundered_keep" not in j.as_posix() and not any(root == r or root.is_relative_to(r) for r in roots if hasattr(root, "is_relative_to")):
                # Conservative guard for metadata dir.
                pass
            data = read_json(j)
            manifest_files.append(j)
            if data is not None:
                existing_json_by_stem[j.name.replace(".game32.json", "").replace(".json", "")].append({
                    "path": j.as_posix(),
                    "data": data,
                })

    planned_assets: list[dict[str, Any]] = []
    moved_png_dest_by_source: dict[Path, Path] = {}

    for src in pngs:
        cls = classify_asset(src)
        if cls is None:
            actions.append(f"SKIP {src}")
            continue

        domain, theme = cls
        dest_dir = canonical_root / domain / theme
        dest = unique_dest(dest_dir / src.name, src)

        import_src = associated_import(src)
        import_dest = dest.with_name(dest.name + ".import")

        old_res = res_path(custodian_root, src)
        new_res = res_path(custodian_root, dest)

        move_or_delete_duplicate(src, dest, backup_root, repo_root, args.apply, actions)
        moved_png_dest_by_source[src] = dest

        if import_src.exists():
            # Keep import paired with the png name, then patch source_file.
            move_or_delete_duplicate(import_src, import_dest, backup_root, repo_root, args.apply, actions)
            if args.apply:
                update_import_text(import_dest, custodian_root, dest)

        legacy_records = []
        legacy_records.extend(existing_json_by_stem.get(src.stem, []))

        image_sha = sha256(dest if dest.exists() else src) if (dest.exists() or src.exists()) else None

        asset = {
            "id": stable_asset_id(domain, theme, dest.stem),
            "name": dest.stem,
            "domain": domain,
            "theme": theme,
            "filename": dest.name,
            "runtime_path": new_res,
            "import_path": new_res + ".import",
            "old_runtime_path": old_res,
            "sha256": image_sha,
            "source_metadata": legacy_records,
            "game32": infer_game32_record(domain, theme, dest),
        }
        planned_assets.append(asset)

    # Archive old manifests after reading them.
    if not args.keep_old_manifests:
        for j in sorted(set(manifest_files), key=lambda p: p.as_posix()):
            # Do not archive the new canonical manifest names if rerunning.
            if j.parent == manifest_dir:
                continue
            if j.name in {"game32_manifest.json", "sundered_keep.game32.json", "sundered_keep_floor_tiles.game32.json"} or j.name.endswith(".game32.json"):
                archive_file(j, archive_root, backup_root, repo_root, args.apply, actions)

    assets_by_domain: dict[str, list[dict[str, Any]]] = defaultdict(list)
    assets_by_theme: dict[str, list[dict[str, Any]]] = defaultdict(list)

    for asset in sorted(planned_assets, key=lambda a: (a["domain"], a["theme"], a["name"])):
        assets_by_domain[asset["domain"]].append(asset)
        assets_by_theme[f'{asset["domain"]}/{asset["theme"]}'].append(asset)

    consolidated = {
        "schema": "custodian.game32.sundered_keep.consolidated_manifest.v1",
        "generated_at_utc": utc_now(),
        "canonical_root": res_path(custodian_root, canonical_root),
        "source_roots_scanned": [res_path(custodian_root, r) for r in roots],
        "asset_count": len(planned_assets),
        "domains": {
            domain: {
                "count": len(items),
                "themes": sorted({a["theme"] for a in items}),
            }
            for domain, items in sorted(assets_by_domain.items())
        },
        "assets": sorted(planned_assets, key=lambda a: a["id"]),
        "legacy_manifest_policy": "archived_to_runtime_sundered_keep_manifest_archive" if not args.keep_old_manifests else "left_in_place",
    }

    domain_manifests = {}
    for domain, items in sorted(assets_by_domain.items()):
        safe_domain = domain.replace("/", "__")
        domain_manifests[safe_domain] = {
            "schema": "custodian.game32.sundered_keep.domain_manifest.v1",
            "generated_at_utc": utc_now(),
            "domain": domain,
            "count": len(items),
            "themes": {
                key.split("/", 1)[1] if "/" in key else key: sorted(vals, key=lambda a: a["name"])
                for key, vals in sorted(assets_by_theme.items())
                if key.startswith(domain + "/")
            },
        }

    index_lines = [
        "# Sundered Keep Runtime Asset Index",
        "",
        f"Generated: `{utc_now()}`",
        "",
        "Canonical runtime root:",
        "",
        f"- `{res_path(custodian_root, canonical_root)}`",
        "",
        "## Domains",
        "",
    ]

    for domain, items in sorted(assets_by_domain.items()):
        index_lines.append(f"### `{domain}` — {len(items)} assets")
        index_lines.append("")
        by_theme = defaultdict(list)
        for a in items:
            by_theme[a["theme"]].append(a)
        for theme, vals in sorted(by_theme.items()):
            index_lines.append(f"- `{theme}`: {len(vals)}")
        index_lines.append("")

    doc_drift = {
        "checked_at_utc": utc_now(),
        "checks": [
            {"path": str(repo_root / "AGENTS.md"), "exists": (repo_root / "AGENTS.md").exists()},
            {"path": str(custodian_root / "docs"), "exists": (custodian_root / "docs").exists()},
            {"path": str(custodian_root / "docs" / "ai_context"), "exists": (custodian_root / "docs" / "ai_context").exists()},
            {"path": str(custodian_root / "docs" / "ai_context" / "CURRENT_STATE.md"), "exists": (custodian_root / "docs" / "ai_context" / "CURRENT_STATE.md").exists()},
            {"path": str(canonical_root), "exists": canonical_root.exists()},
        ],
        "recommendation": "After applying, update custodian/docs/ai_context/CURRENT_STATE.md to mention the canonical Sundered Keep runtime root and consolidated manifest.",
    }

    if args.apply:
        manifest_dir.mkdir(parents=True, exist_ok=True)
        write_json(canonical_root / "game32_manifest.json", consolidated)
        write_json(metadata_dir / "sundered_keep.game32.json", consolidated)

        for safe_domain, data in domain_manifests.items():
            write_json(manifest_dir / f"{safe_domain}.game32.json", data)

        (canonical_root / "ASSET_INDEX.md").write_text("\n".join(index_lines) + "\n", encoding="utf-8")
        write_json(canonical_root / "_doc_drift_review.json", doc_drift)
        (canonical_root / "_doc_drift_review.md").write_text(
            "# Sundered Keep Asset Organization Doc Drift Review\n\n"
            + f"Generated: `{utc_now()}`\n\n"
            + "\n".join(
                f"- {'OK' if c['exists'] else 'MISSING'} `{c['path']}`"
                for c in doc_drift["checks"]
            )
            + "\n\n"
            + doc_drift["recommendation"]
            + "\n",
            encoding="utf-8",
        )

        for root in roots:
            remove_empty_dirs(root, root, actions, args.apply)

    print("\n".join(actions))
    print()
    print("SUMMARY")
    print(f"  mode: {'APPLY' if args.apply else 'DRY RUN'}")
    print(f"  assets planned: {len(planned_assets)}")
    print(f"  canonical root: {canonical_root}")
    print(f"  root manifest: {canonical_root / 'game32_manifest.json'}")
    print(f"  mirrored metadata manifest: {metadata_dir / 'sundered_keep.game32.json'}")
    print(f"  domain manifests: {manifest_dir}")
    print(f"  backup root: {backup_root if args.apply else '(created only with --apply)'}")
    print()
    if not args.apply:
        print("Dry run only. Re-run with --apply to actually move/archive/write files.")

if __name__ == "__main__":
    main()
