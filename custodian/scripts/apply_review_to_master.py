#!/usr/bin/env python3
"""
Apply review-batch decisions to the gothic master sheet manifest.

What it does:
  1. Reads a completed aggregate review JSON (which may include extended
     game32 fields: collision, procgen, placement).
  2. For each entry whose action is "keep" or "move":
     - Matches the entry to its counterpart in the master sheet manifest
       (gothic_master_sheet.game32.json) by file path.
     - Writes the enriched classification, collision, procgen, and placement
       data into the master manifest entry.
     - Sets review_status from "needs_game32_enrichment" to "reviewed".
  3. Writes the updated master manifest back (or a new copy).
  4. Reports which entries were updated, skipped, or unmatched.

Typical workflow:
  cd /home/braydenchaffee/Projects/CUSTODIAN

  # 1. The existing review batcher generates a batch file:
  #    python scripts/review_game32_png_batches.py --batch-size 24

  # 2. Human edits the batch JSON (fills in classification + game32 fields).

  # 3. This script applies those edits to the master manifest:
  #    python custodian/scripts/apply_review_to_master.py
  #      --review-batch content/tiles/gothic/.review_batches/game32_asset_review/batch_0000_aggregate.game32.review.json
  #      --master content/tiles/gothic/gothic_master_sheet.game32.json

  # Or to extend a batch with stub game32 fields before review:
  #    python custodian/scripts/apply_review_to_master.py
  #      --review-batch .../batch_0000_aggregate.game32.review.json
  #      --master .../gothic_master_sheet.game32.json
  #      --extend-only

Extending the review format:

  The review format already has review.new_asset_type, new_semantic_role,
  new_placement_layer, new_tags. This script EXTENDS each entry's `review`
  object with three additional optional blocks:

    "review": {
      ... existing fields ...

      "new_collision": {
        "blocks_movement": true|false,
        "blocks_sight":    true|false,
        "cover_value":     0|1|2|3
      },
      "new_procgen": {
        "uses":              ["gothic", "dungeon", ...],
        "weight":            5,
        "can_spawn_indoor":  true|false,
        "can_spawn_outdoor": true|false
      },
      "new_placement": {
        "tile_size":     32,
        "footprint_tiles": {"w": 1, "h": 1},
        "origin_mode":   "bottom_center"|"center"|"top_left",
        "snap":          "tile"|"pixel"|"half_tile",
        "allow_mirror_x": true|false,
        "allow_rotation": false,
        "y_sort":        true|false
      }
    }

  These are OPTIONAL — if absent, the script only applies classification.
  The --extend-only flag populates these blocks with sensible defaults from
  the current master manifest entry so the human can tweak them.
"""

from __future__ import annotations

import argparse
import json
import sys
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


# ── helpers ──────────────────────────────────────────────────────────────


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def eprint(*args: Any) -> None:
    print(*args, file=sys.stderr)


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        eprint(f"ERROR loading {path}: {exc}")
        return {}


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=False) + "\n", encoding="utf-8"
    )


def res_to_relative(res_path: str) -> str:
    """Normalise a res://content/... path to a relative posix path."""
    return res_path.replace("res://", "")


def path_matches_review(
    master_file_path: str, review_png: str, project_root: str
) -> bool:
    """
    Return True if a master manifest file path corresponds to a review entry.

    master_file_path is a res:// URI like res://content/tiles/...
    review_png is a relative path like custodian/content/tiles/...

    The master manifest paths are relative to the Godot project root (the
    custodian/ directory), so res://content/ == custodian/content/ at the
    repo level.

    We normalise both to the same frame of reference for comparison.
    """
    # Normalise master path: res://content/... → content/...
    master_rel = res_to_relative(master_file_path)
    master_rel = Path(master_rel).as_posix()

    # Normalise review path: it's relative to the repo root.
    # It may be:
    #   custodian/content/tiles/...     (relative, Godot subdir prefix)
    #   /abs/path/custodian/content/... (absolute)
    review_rel = review_png

    # Remove absolute project_root prefix if present
    if project_root and review_rel.startswith(project_root):
        review_rel = review_rel[len(project_root) :].lstrip("/")

    # Strip the leading custodian/ prefix — master uses content/ not custodian/content/
    if review_rel.startswith("custodian/"):
        review_rel = review_rel[len("custodian/"):]

    review_rel = Path(review_rel).as_posix()

    return master_rel == review_rel


# ── default / stub generators ───────────────────────────────────────────


def default_classification() -> dict[str, Any]:
    return {
        "asset_type": "tiles",
        "semantic_role": "uncategorized_environment_asset",
        "placement_layer": "prop",
        "tags": ["needs_review"],
        "review_status": "needs_game32_enrichment",
    }


def default_placement() -> dict[str, Any]:
    return {
        "tile_size": 32,
        "footprint_tiles": {"w": 1, "h": 1},
        "origin_mode": "bottom_center",
        "snap": "tile",
        "allow_mirror_x": True,
        "allow_rotation": False,
        "y_sort": True,
    }


def default_collision() -> dict[str, Any]:
    return {
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "review_status": "needs_game32_enrichment",
    }


def default_procgen() -> dict[str, Any]:
    return {
        "uses": ["needs_review"],
        "weight": 5,
        "can_spawn_indoor": True,
        "can_spawn_outdoor": True,
        "review_status": "needs_game32_enrichment",
    }


# ── extend review entries with game32 stubs ─────────────────────────────


def extend_review_entry(
    entry: dict[str, Any],
    master_entry: dict[str, Any] | None,
    project_root: str,
) -> dict[str, Any]:
    """
    Add new_collision, new_procgen, new_placement stubs to a review entry.

    If a matching master manifest entry exists, seed the stubs from its
    current values (so the reviewer sees what's already there to tweak).
    Otherwise use game32 defaults.
    """
    review = entry.get("review", {})

    # Collision
    if "new_collision" not in review:
        col = default_collision()
        if master_entry:
            mc = master_entry.get("collision", {})
            col["blocks_movement"] = mc.get("blocks_movement", False)
            col["blocks_sight"] = mc.get("blocks_sight", False)
            col["cover_value"] = mc.get("cover_value", 0)
            col["review_status"] = mc.get("review_status", "needs_game32_enrichment")
        # Strip review_status from new_collision — it's a metadata field,
        # not a data field the reviewer should set.
        col.pop("review_status", None)
        review["new_collision"] = col

    # Procgen
    if "new_procgen" not in review:
        pg = default_procgen()
        if master_entry:
            mp = master_entry.get("procgen", {})
            pg["uses"] = mp.get("uses", ["needs_review"])
            pg["weight"] = mp.get("weight", 5)
            pg["can_spawn_indoor"] = mp.get("can_spawn_indoor", True)
            pg["can_spawn_outdoor"] = mp.get("can_spawn_outdoor", True)
        pg.pop("review_status", None)
        review["new_procgen"] = pg

    # Placement
    if "new_placement" not in review:
        pl = default_placement()
        if master_entry:
            mp = master_entry.get("placement", {})
            pl["tile_size"] = mp.get("tile_size", 32)
            pl["footprint_tiles"] = mp.get("footprint_tiles", {"w": 1, "h": 1})
            pl["origin_mode"] = mp.get("origin_mode", "bottom_center")
            pl["snap"] = mp.get("snap", "tile")
            pl["allow_mirror_x"] = mp.get("allow_mirror_x", True)
            pl["allow_rotation"] = mp.get("allow_rotation", False)
            pl["y_sort"] = mp.get("y_sort", True)
        review["new_placement"] = pl

    # Ensure classification stubs
    if not review.get("new_semantic_role"):
        if master_entry:
            mc = master_entry.get("classification", {})
            review["new_semantic_role"] = mc.get("semantic_role")
    if not review.get("new_asset_type"):
        if master_entry:
            mc = master_entry.get("classification", {})
            review["new_asset_type"] = mc.get("asset_type")
    if not review.get("new_placement_layer"):
        if master_entry:
            mc = master_entry.get("classification", {})
            review["new_placement_layer"] = mc.get("placement_layer")
    if not review.get("new_tags") or review.get("new_tags") == []:
        if master_entry:
            mc = master_entry.get("classification", {})
            existing_tags = mc.get("tags", [])
            # Filter out meta-tags
            review["new_tags"] = [t for t in existing_tags if t != "needs_review"]

    entry["review"] = review
    return entry


def extend_review_batch(
    review_path: Path,
    master_data: dict[str, Any],
    project_root: str,
) -> dict[str, Any]:
    """Extend all entries in a review batch with game32 stubs."""
    data = load_json(review_path)
    if not data:
        eprint(f"ERROR: could not load {review_path}")
        return {}

    # Build a lookup from master manifest by file path
    master_by_path: dict[str, dict[str, Any]] = {}
    for a in master_data.get("assets", []):
        fp = a.get("file", {}).get("path", "")
        if fp:
            master_by_path[res_to_relative(fp)] = a

    for entry in data.get("entries", []):
        current = entry.get("current", {})
        review_png = current.get("png", "")
        master_entry = None

        # Try to find the matching master entry
        for mfp, ma in master_by_path.items():
            if path_matches_review(ma.get("file", {}).get("path", ""), review_png, project_root):
                master_entry = ma
                break

        extend_review_entry(entry, master_entry, project_root)

    return data


# ── apply review to master manifest ─────────────────────────────────────


def match_review_to_master(
    review_png: str,
    master_assets: list[dict[str, Any]],
    project_root: str,
) -> dict[str, Any] | None:
    """Find the master manifest entry whose file.path matches review_png."""
    for ma in master_assets:
        fp = ma.get("file", {}).get("path", "")
        if fp and path_matches_review(fp, review_png, project_root):
            return ma
    return None


def apply_classification(
    master_entry: dict[str, Any], review: dict[str, Any]
) -> None:
    """Write classification fields from review into the master entry."""
    classification = master_entry.get("classification")
    if not isinstance(classification, dict):
        classification = default_classification()

    mapping = [
        ("new_asset_type", "asset_type"),
        ("new_semantic_role", "semantic_role"),
        ("new_placement_layer", "placement_layer"),
        ("new_category", "category"),
    ]
    for review_key, manifest_key in mapping:
        val = review.get(review_key)
        if val is not None and val != "":
            classification[manifest_key] = val

    tags = review.get("new_tags")
    if isinstance(tags, list) and tags:
        classification["tags"] = tags

    classification["review_status"] = "reviewed"
    master_entry["classification"] = classification


def apply_collision(
    master_entry: dict[str, Any], review: dict[str, Any]
) -> None:
    """Write collision fields from review into the master entry."""
    new_col = review.get("new_collision")
    if not isinstance(new_col, dict):
        return

    collision = master_entry.get("collision")
    if not isinstance(collision, dict):
        collision = default_collision()

    for key in ("blocks_movement", "blocks_sight", "cover_value"):
        if key in new_col:
            collision[key] = new_col[key]

    collision["review_status"] = "reviewed"
    master_entry["collision"] = collision


def apply_procgen(
    master_entry: dict[str, Any], review: dict[str, Any]
) -> None:
    """Write procgen fields from review into the master entry."""
    new_pg = review.get("new_procgen")
    if not isinstance(new_pg, dict):
        return

    procgen = master_entry.get("procgen")
    if not isinstance(procgen, dict):
        procgen = default_procgen()

    for key in ("uses", "weight", "can_spawn_indoor", "can_spawn_outdoor"):
        if key in new_pg:
            procgen[key] = new_pg[key]

    procgen["review_status"] = "reviewed"
    master_entry["procgen"] = procgen


def apply_placement(
    master_entry: dict[str, Any], review: dict[str, Any]
) -> None:
    """Write placement fields from review into the master entry."""
    new_pl = review.get("new_placement")
    if not isinstance(new_pl, dict):
        return

    placement = master_entry.get("placement")
    if not isinstance(placement, dict):
        placement = default_placement()

    for key in ("tile_size", "footprint_tiles", "origin_mode", "snap",
                "allow_mirror_x", "allow_rotation", "y_sort"):
        if key in new_pl:
            placement[key] = new_pl[key]

    master_entry["placement"] = placement


GAME32_ASSET_KEYS = frozenset({
    "schema", "id", "display_name", "source", "file",
    "classification", "placement", "collision", "procgen",
    "master_index",
})

REVIEWED_STATUS = "reviewed"


def apply_asset_block(
    master_entry: dict[str, Any],
    asset: dict[str, Any],
) -> list[str]:
    """Bulk-apply a complete game32.asset.v2 block into a master entry.

    The asset block comes from fill_gothic_batch_0000_decals.py and has the
    exact game32.asset.v2 schema. We copy the enrichment fields and leave
    the master's source_rect (coordinates on the master sheet) intact.

    Returns a list of field names that were applied.
    """
    applied: list[str] = []

    # Fields to copy (these are the enrichment fields)
    copy_fields = [
        "classification",
        "placement",
        "collision",
        "procgen",
        "display_name",
    ]

    for field in copy_fields:
        if field in asset:
            val = asset[field]
            if isinstance(val, dict):
                # Ensure review_status is set to reviewed
                val = dict(val)
                if "review_status" not in val:
                    val["review_status"] = REVIEWED_STATUS
                master_entry[field] = val
            else:
                master_entry[field] = val
            applied.append(field)

    # Copy id if present and different from current
    new_id = asset.get("id")
    if new_id and new_id != master_entry.get("id"):
        master_entry["id"] = new_id
        applied.append("id")

    return applied


def apply_review_entry(
    master_entry: dict[str, Any],
    entry: dict[str, Any],
    review_png: str,
) -> dict[str, str]:
    """Apply a single review entry's decisions to a master manifest entry.

    Supports two formats:
      1. **Asset-block format** (from fill_gothic_batch_0000_decals.py):
         entry["asset"] contains a complete game32.asset.v2 block.
      2. **Field-level format**: entry["review"] has new_collision,
         new_procgen, new_placement, new_id, etc.

    Returns a dict with keys: status, details.
    """
    result: dict[str, str] = {}
    review = entry.get("review", {})
    asset = entry.get("asset", {})

    action = str(review.get("action", "keep")).strip().lower()
    if action in ("skip", "delete"):
        result["status"] = action
        result["details"] = f"Skipped by action '{action}'"
        return result

    if action not in ("keep", "move"):
        result["status"] = "ignored"
        result["details"] = f"Unknown action '{action}'"
        return result

    # ── Format 1: Asset block present ────────────────────────────────
    if isinstance(asset, dict) and any(k in asset for k in GAME32_ASSET_KEYS):
        applied = apply_asset_block(master_entry, asset)
        result["status"] = "updated"
        result["details"] = f"Asset block applied: {', '.join(applied)}"

        # Handle move if needed
        if action == "move":
            new_relative_dir = review.get("new_relative_dir")
            new_filename = review.get("new_filename")
            if new_relative_dir and new_filename:
                new_path = f"res://{Path(new_relative_dir) / new_filename}"
                new_path = new_path.replace("res://res://", "res://")
                master_entry.setdefault("file", {})["path"] = new_path
                result["details"] += " + moved"

        return result

    # ── Format 2: Field-level review ─────────────────────────────────
    # Apply classification
    apply_classification(master_entry, review)

    # Apply collision (if review has it)
    apply_collision(master_entry, review)

    # Apply procgen (if review has it)
    apply_procgen(master_entry, review)

    # Apply placement (if review has it)
    apply_placement(master_entry, review)

    # Update the display_name from new_id if provided
    new_id = review.get("new_id")
    if new_id:
        master_entry["id"] = new_id
        display = new_id.replace("_", " ").title()
        master_entry["display_name"] = display

    # Update the file path if moved
    if action == "move":
        new_relative_dir = review.get("new_relative_dir")
        new_filename = review.get("new_filename")
        if new_relative_dir and new_filename:
            new_path = f"res://{Path(new_relative_dir) / new_filename}"
            new_path = new_path.replace("res://res://", "res://")
            master_entry.setdefault("file", {})["path"] = new_path

    result["status"] = "updated"
    result["details"] = "Classification applied"
    if "new_collision" in review:
        result["details"] += " + collision"
    if "new_procgen" in review:
        result["details"] += " + procgen"
    if "new_placement" in review:
        result["details"] += " + placement"

    return result


def find_sidecar_manifest(png_path: Path) -> Path | None:
    """Find a `.game32.json` sidecar adjacent to a PNG.

    Supports both naming conventions:
      asset_name.game32.json         (preferred)
      asset_name.png.game32.json     (legacy fallback)
    """
    stem = png_path.with_suffix("")
    candidates = [
        png_path.with_name(stem.name + ".game32.json"),
        Path(str(png_path) + ".game32.json"),
    ]
    for c in candidates:
        if c.is_file():
            return c
    return None


def cleanup_original_manifests(
    report: dict[str, Any],
    review_data: dict[str, Any],
    project_root: str,
    dry_run: bool,
) -> int:
    """Delete per-PNG .game32.json sidecar files after applying to master.

    These individual sidecar manifests are now redundant — the master
    manifest is the source of truth. Removing them prevents confusion.

    Returns the number of files deleted.
    """
    deleted = 0
    skipped = 0
    missing = 0

    for entry in review_data.get("entries", []):
        current = entry.get("current", {})
        review = entry.get("review", {})
        batch_index = entry.get("batch_index")
        review_png = current.get("png", "")

        action = str(review.get("action", "keep")).strip().lower()
        if action in ("skip", "delete"):
            continue

        # Resolve the PNG path from the review entry
        png_rel = review_png
        if project_root and png_rel.startswith(project_root):
            png_rel = png_rel[len(project_root) + 1 :]

        png_abs = Path(project_root) / png_rel
        if not png_abs.is_file():
            # Try without custodian/ prefix if present
            if png_rel.startswith("custodian/"):
                png_rel = png_rel[len("custodian/"):]
                png_abs = Path(project_root) / png_rel
            if not png_abs.is_file():
                missing += 1
                continue

        sidecar = find_sidecar_manifest(png_abs)
        if sidecar is None:
            missing += 1
            continue

        if dry_run:
            skipped += 1
            continue

        sidecar.unlink()
        deleted += 1

    report["cleanup"] = {
        "deleted": deleted,
        "skipped_dry_run": skipped,
        "missing_sidecar": missing,
    }
    return deleted


def apply_review_batch_to_master(
    review_data: dict[str, Any],
    master_data: dict[str, Any],
    project_root: str,
    *,
    cleanup: bool = False,
    dry_run: bool = False,
) -> dict[str, Any]:
    """Apply all entries in a review batch to the master manifest.

    When cleanup=True, deletes per-PNG .game32.json sidecar files after
    successful application, since the master manifest becomes the source
    of truth.

    Returns a report dict with per-entry results.
    """
    report: dict[str, Any] = {
        "applied_utc": iso_now(),
        "review_id": review_data.get("id", "unknown"),
        "master_schema": master_data.get("schema", "unknown"),
        "total_review_entries": len(review_data.get("entries", [])),
        "results": [],
        "summary": {},
    }

    master_assets = master_data.get("assets", [])

    for entry in review_data.get("entries", []):
        current = entry.get("current", {})
        review = entry.get("review", {})
        batch_index = entry.get("batch_index")
        review_png = current.get("png", "")

        action = str(review.get("action", "keep")).strip().lower()

        result: dict[str, Any] = {
            "batch_index": batch_index,
            "png": review_png,
            "action": action,
            "status": "unmatched",
            "details": "No matching master manifest entry found",
            "has_asset_block": "asset" in entry and bool(entry["asset"]),
        }

        master_entry = match_review_to_master(
            review_png, master_assets, project_root
        )

        if master_entry is not None:
            apply_result = apply_review_entry(master_entry, entry, review_png)
            result["status"] = apply_result["status"]
            result["details"] = apply_result["details"]
            result["master_index"] = master_entry.get("master_index", -1)

        report["results"].append(result)

    # Clean up per-PNG sidecar manifests (now redundant)
    if cleanup:
        cleanup_original_manifests(report, review_data, project_root, dry_run)

    # Build summary
    summary: dict[str, int] = {}
    for r in report["results"]:
        summary[r["status"]] = summary.get(r["status"], 0) + 1
    report["summary"] = summary

    return report


# ── CLI ─────────────────────────────────────────────────────────────────


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Apply review-batch decisions to the gothic master sheet manifest."
    )
    parser.add_argument(
        "--review-batch", "-r",
        type=Path,
        required=True,
        help="Path to the aggregate review JSON (batch_NNNN_aggregate.game32.review.json).",
    )
    parser.add_argument(
        "--master", "-m",
        type=Path,
        default=Path("custodian/content/tiles/gothic/gothic_master_sheet.game32.json"),
        help="Path to the master sheet manifest JSON.",
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        default=None,
        help="Write updated master to a different path (default: overwrite --master).",
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path.cwd(),
        help="Repo root. Default: current working directory.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Do not write any files; only report what would happen.",
    )
    parser.add_argument(
        "--extend-only",
        action="store_true",
        help="Instead of applying, extend the review batch with game32 stub "
             "fields (new_collision, new_procgen, new_placement) for human review.",
    )
    parser.add_argument(
        "--report", "-p",
        type=Path,
        default=None,
        help="Write the apply report to a separate JSON file.",
    )
    parser.add_argument(
        "--cleanup",
        action="store_true",
        help="Delete per-PNG .game32.json sidecar manifests after applying, "
             "since the master manifest becomes the source of truth.",
    )

    args = parser.parse_args()

    # Resolve paths
    project_root = args.project_root.expanduser().resolve()
    review_path = args.review_batch.expanduser()
    if not review_path.is_absolute():
        review_path = project_root / review_path

    master_path = args.master.expanduser()
    if not master_path.is_absolute():
        master_path = project_root / master_path

    output_path = args.output.expanduser() if args.output else master_path
    if not output_path.is_absolute():
        output_path = project_root / output_path

    pr_str = project_root.as_posix()

    # Validate inputs
    if not review_path.exists():
        eprint(f"ERROR: review batch not found: {review_path}")
        return 2
    if not master_path.exists():
        eprint(f"ERROR: master manifest not found: {master_path}")
        return 2

    # Load
    master_data = load_json(master_path)
    if not master_data:
        eprint("ERROR: failed to load master manifest.")
        return 2

    # --extend-only mode: add game32 stubs to the review batch
    if args.extend_only:
        print(f"Extending review batch with game32 stubs...")
        extended = extend_review_batch(review_path, master_data, pr_str)
        if not extended:
            return 2

        # Write extended review back
        write_json(review_path, extended)
        print(f"Extended review batch written: {review_path}")
        print(f"  → Each entry now has new_collision, new_procgen, new_placement stubs.")
        print(f"  → Edit these fields in the review JSON, then run this script")
        print(f"    WITHOUT --extend-only to apply them to the master manifest.")
        return 0

    # Normal mode: apply review to master
    review_data = load_json(review_path)
    if not review_data:
        eprint(f"ERROR: could not load {review_path}")
        return 2

    report = apply_review_batch_to_master(
        review_data, master_data, pr_str,
        cleanup=args.cleanup,
        dry_run=args.dry_run,
    )

    # Print report
    print(f"\nApply report for review: {report['review_id']}")
    print(f"  Total entries: {report['total_review_entries']}")
    print(f"  Dry run: {args.dry_run}")
    print("  Summary:")
    for status, count in sorted(report["summary"].items()):
        print(f"    {status}: {count}")

    # Show cleanup results
    cleanup_info = report.get("cleanup")
    if cleanup_info:
        print(f"  Cleanup:")
        print(f"    Sidecar manifests deleted:  {cleanup_info['deleted']}")
        print(f"    Skipped (dry-run):          {cleanup_info['skipped_dry_run']}")
        print(f"    No sidecar found:           {cleanup_info['missing_sidecar']}")

    # Show unmatched entries (these need attention)
    unmatched = [r for r in report["results"] if r["status"] == "unmatched"]
    if unmatched:
        print(f"\n  ⚠  {len(unmatched)} unmatched entries (no master manifest match):")
        for r in unmatched[:10]:
            print(f"      [{r['batch_index']}] {r['png']}")
        if len(unmatched) > 10:
            print(f"      ... and {len(unmatched) - 10} more")

    # Write the report
    if args.report:
        report_path = args.report.expanduser()
        if not report_path.is_absolute():
            report_path = project_root / report_path
        write_json(report_path, report)
        print(f"\n  Report written: {report_path}")

    # Write updated master
    if not args.dry_run:
        write_json(output_path, master_data)
        print(f"\n  Updated master manifest: {output_path}")
        print(f"  Total assets: {len(master_data.get('assets', []))}")
    else:
        print(f"\n  (dry-run — no files written)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
