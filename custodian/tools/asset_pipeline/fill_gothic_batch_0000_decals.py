#!/usr/bin/env python3
"""
Fill full game32.asset.v2 fields for gothic asset review batch_0000.

Reviewed contact sheet:
  #00-#19 floor_detail_001..020:
    Non-blocking floor overlay/decal/details.

  #20-#23 ritual_floor_decal_001..004:
    Non-blocking ritual/sigil/blood floor overlay decals.

This edits the aggregate review JSON in place. It does not move PNGs.
After running this, return to the review batch script and press Enter to apply.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


DEFAULT_PROJECT_ROOT = Path("/home/braydenchaffee/Projects/CUSTODIAN")
DEFAULT_AGGREGATE_JSON = (
    DEFAULT_PROJECT_ROOT
    / "custodian/content/tiles/gothic/.review_batches/game32_asset_review/batch_0000_aggregate.game32.review.json"
)


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def title_from_stem(stem: str) -> str:
    return stem.replace("_", " ").replace("-", " ").title()


def unique(values: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for value in values:
        value = str(value).strip()
        if not value or value in seen:
            continue
        seen.add(value)
        out.append(value)
    return out


def common_decal_placement(asset: dict[str, Any]) -> dict[str, Any]:
    existing = asset.get("placement", {})
    footprint = existing.get("footprint_tiles", {"w": 2, "h": 2})

    return {
        "tile_size": 32,
        "footprint_tiles": footprint,
        "origin_mode": "top_left",
        "snap": "tile",
        "allow_mirror_x": False,
        "allow_rotation": False,
        "y_sort": False,
        "pivot_px": {
            "x": 0,
            "y": 0,
        },
    }


def common_no_collision() -> dict[str, Any]:
    return {
        "blocks_movement": False,
        "blocks_sight": False,
        "cover_value": 0,
        "review_status": "reviewed",
        "collision_shape": "none",
    }


def make_procgen(
    *,
    uses: list[str],
    weight: int,
    indoor: bool = True,
    outdoor: bool = True,
) -> dict[str, Any]:
    return {
        "uses": uses,
        "weight": weight,
        "can_spawn_indoor": indoor,
        "can_spawn_outdoor": outdoor,
        "review_status": "reviewed",
        "supports_gothic_compound": True,
    }


FLOOR_DETAIL_OVERRIDES: dict[str, dict[str, Any]] = {
    "floor_detail_001.png": {
        "display_name": "Blood Floor Detail 001",
        "semantic_role": "blood_floor_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "blood", "gore", "distress", "walkable", "no_collision"],
        "uses": ["floor_detail", "blood_detail", "combat_aftermath", "environmental_storytelling"],
        "weight": 8,
    },
    "floor_detail_002.png": {
        "display_name": "Damaged Metal Floor Plate 002",
        "semantic_role": "damaged_metal_floor_plate_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal_plate", "damaged", "cracked", "walkable", "no_collision"],
        "uses": ["floor_detail", "industrial_gothic_insert", "damaged_floor"],
        "weight": 18,
    },
    "floor_detail_003.png": {
        "display_name": "Damaged Metal Floor Plate 003",
        "semantic_role": "damaged_metal_floor_plate_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal_plate", "damaged", "cracked", "walkable", "no_collision"],
        "uses": ["floor_detail", "industrial_gothic_insert", "damaged_floor"],
        "weight": 18,
    },
    "floor_detail_004.png": {
        "display_name": "Industrial Grate Floor Detail 004",
        "semantic_role": "industrial_floor_grate_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal", "grate", "industrial", "walkable", "no_collision"],
        "uses": ["floor_detail", "industrial_gothic_insert", "grate_detail"],
        "weight": 14,
    },
    "floor_detail_005.png": {
        "display_name": "Partial Circular Inlay Floor Detail 005",
        "semantic_role": "partial_circular_metal_floor_inlay_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal", "circular_inlay", "arc", "ornate", "walkable", "no_collision"],
        "uses": ["floor_detail", "ornate_floor_inlay", "industrial_gothic_insert"],
        "weight": 12,
    },
    "floor_detail_006.png": {
        "display_name": "Partial Circular Inlay Floor Detail 006",
        "semantic_role": "partial_circular_metal_floor_inlay_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal", "circular_inlay", "arc", "ornate", "walkable", "no_collision"],
        "uses": ["floor_detail", "ornate_floor_inlay", "industrial_gothic_insert"],
        "weight": 12,
    },
    "floor_detail_007.png": {
        "display_name": "Blood Floor Detail 007",
        "semantic_role": "blood_floor_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "blood", "gore", "distress", "walkable", "no_collision"],
        "uses": ["floor_detail", "blood_detail", "combat_aftermath", "environmental_storytelling"],
        "weight": 8,
    },
    "floor_detail_008.png": {
        "display_name": "Circular Drain Floor Detail 008",
        "semantic_role": "circular_drain_floor_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal", "drain", "circular_inlay", "walkable", "no_collision"],
        "uses": ["floor_detail", "drain_detail", "industrial_gothic_insert"],
        "weight": 12,
    },
    "floor_detail_009.png": {
        "display_name": "Ornate Metal Inlay Floor Detail 009",
        "semantic_role": "ornate_metal_floor_inlay_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal", "ornate", "inlay", "gold_accent", "walkable", "no_collision"],
        "uses": ["floor_detail", "ornate_floor_inlay", "vault_or_chapel_floor_detail"],
        "weight": 10,
    },
    "floor_detail_010.png": {
        "display_name": "Ornate Metal Inlay Floor Detail 010",
        "semantic_role": "ornate_metal_floor_inlay_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal", "ornate", "inlay", "gold_accent", "walkable", "no_collision"],
        "uses": ["floor_detail", "ornate_floor_inlay", "vault_or_chapel_floor_detail"],
        "weight": 10,
    },
    "floor_detail_011.png": {
        "display_name": "Square Metal Panel Floor Detail 011",
        "semantic_role": "square_metal_panel_floor_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal_panel", "ornate", "industrial", "walkable", "no_collision"],
        "uses": ["floor_detail", "industrial_gothic_insert", "vault_floor_detail"],
        "weight": 14,
    },
    "floor_detail_012.png": {
        "display_name": "Dark Scuffed Floor Detail 012",
        "semantic_role": "dark_scuffed_floor_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "scuffed", "dark", "worn", "walkable", "no_collision"],
        "uses": ["floor_detail", "dirty_floor_variation", "environmental_storytelling"],
        "weight": 18,
    },
    "floor_detail_013.png": {
        "display_name": "Damaged Metal Floor Plate 013",
        "semantic_role": "damaged_metal_floor_plate_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal_plate", "damaged", "cracked", "walkable", "no_collision"],
        "uses": ["floor_detail", "industrial_gothic_insert", "damaged_floor"],
        "weight": 18,
    },
    "floor_detail_014.png": {
        "display_name": "Damaged Metal Floor Plate 014",
        "semantic_role": "damaged_metal_floor_plate_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal_plate", "damaged", "cracked", "walkable", "no_collision"],
        "uses": ["floor_detail", "industrial_gothic_insert", "damaged_floor"],
        "weight": 18,
    },
    "floor_detail_015.png": {
        "display_name": "Broken Stone Floor Plate 015",
        "semantic_role": "broken_stone_floor_plate_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "stone_plate", "broken", "rubble", "walkable", "no_collision"],
        "uses": ["floor_detail", "broken_floor_detail", "damaged_floor"],
        "weight": 16,
    },
    "floor_detail_016.png": {
        "display_name": "Broken Stone Floor Plate 016",
        "semantic_role": "broken_stone_floor_plate_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "stone_plate", "broken", "rubble", "walkable", "no_collision"],
        "uses": ["floor_detail", "broken_floor_detail", "damaged_floor"],
        "weight": 16,
    },
    "floor_detail_017.png": {
        "display_name": "Damaged Floor Plate With Debris 017",
        "semantic_role": "damaged_floor_plate_debris_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal_plate", "damaged", "debris", "wood_fragment", "walkable", "no_collision"],
        "uses": ["floor_detail", "industrial_gothic_insert", "damaged_floor", "debris_detail"],
        "weight": 14,
    },
    "floor_detail_018.png": {
        "display_name": "Broken Stone Floor Plate 018",
        "semantic_role": "broken_stone_floor_plate_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "stone_plate", "broken", "rubble", "walkable", "no_collision"],
        "uses": ["floor_detail", "broken_floor_detail", "damaged_floor"],
        "weight": 16,
    },
    "floor_detail_019.png": {
        "display_name": "Ornate Square Panel Floor Detail 019",
        "semantic_role": "ornate_square_panel_floor_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal_panel", "ornate", "gold_accent", "walkable", "no_collision"],
        "uses": ["floor_detail", "ornate_floor_inlay", "vault_floor_detail"],
        "weight": 10,
    },
    "floor_detail_020.png": {
        "display_name": "Circular Center Plate Floor Detail 020",
        "semantic_role": "circular_center_plate_floor_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "metal_panel", "circular_inlay", "center_plate", "walkable", "no_collision"],
        "uses": ["floor_detail", "industrial_gothic_insert", "vault_floor_detail"],
        "weight": 12,
    },
}


RITUAL_OVERRIDES: dict[str, dict[str, Any]] = {
    "ritual_floor_decal_001.png": {
        "display_name": "Blood Ritual Sigil Floor Decal 001",
        "semantic_role": "blood_ritual_sigil_floor_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "ritual", "sigil", "blood", "occult", "walkable", "no_collision"],
        "uses": ["ritual_room_floor_detail", "blood_ritual_detail", "environmental_storytelling", "rare_floor_decal"],
        "weight": 3,
    },
    "ritual_floor_decal_002.png": {
        "display_name": "Clean Ritual Sigil Floor Decal 002",
        "semantic_role": "ritual_sigil_floor_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "ritual", "sigil", "occult", "chalk", "walkable", "no_collision"],
        "uses": ["ritual_room_floor_detail", "occult_floor_detail", "rare_floor_decal"],
        "weight": 4,
    },
    "ritual_floor_decal_003.png": {
        "display_name": "Small Blood Ritual Floor Decal 003",
        "semantic_role": "small_blood_ritual_floor_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "ritual", "blood", "splatter", "occult", "walkable", "no_collision"],
        "uses": ["ritual_room_floor_detail", "blood_ritual_detail", "environmental_storytelling"],
        "weight": 5,
    },
    "ritual_floor_decal_004.png": {
        "display_name": "Clean Ritual Scatter Floor Decal 004",
        "semantic_role": "ritual_scatter_floor_decal",
        "tags": ["gothic", "floor", "decal", "overlay", "ritual", "sigil", "chalk", "occult", "walkable", "no_collision"],
        "uses": ["ritual_room_floor_detail", "occult_floor_detail", "rare_floor_decal"],
        "weight": 4,
    },
}


def classify_entry(filename: str) -> dict[str, Any] | None:
    if filename in FLOOR_DETAIL_OVERRIDES:
        return FLOOR_DETAIL_OVERRIDES[filename]
    if filename in RITUAL_OVERRIDES:
        return RITUAL_OVERRIDES[filename]
    return None


def patch_entry(entry: dict[str, Any]) -> bool:
    current = entry.get("current", {})
    review = entry.setdefault("review", {})
    asset = entry.setdefault("asset", {})

    filename = current.get("filename") or Path(str(review.get("target_png", ""))).name
    if not filename:
        return False

    override = classify_entry(filename)
    if not override:
        return False

    is_ritual = filename.startswith("ritual_floor_decal_")

    # Keep paths stable. These folders are already correct for this sheet.
    png_path = current.get("png") or review.get("target_png")
    canonical_manifest = current.get("canonical_manifest") or review.get("target_manifest")

    review["action"] = "keep"
    review["target_png"] = png_path
    review["target_manifest"] = canonical_manifest
    review["delete_import"] = True
    review["notes"] = (
        "Human-reviewed from batch_0000 contact sheet. "
        "Classified as non-blocking floor overlay/decal; full game32.asset.v2 fields filled."
    )

    asset["schema"] = "game32.asset.v2"
    asset["id"] = asset.get("id") or Path(filename).stem
    asset["display_name"] = override["display_name"]

    source = asset.setdefault("source", {})
    source["section"] = "tiles"
    source["subtype"] = "decals"
    source["review_source"] = "human_reviewed_contact_sheet_batch_0000"
    source["review_status"] = "reviewed"

    file_block = asset.setdefault("file", {})
    if png_path:
        file_block["path"] = "res://" + str(png_path).split("custodian/", 1)[-1] if str(png_path).startswith("custodian/") else file_block.get("path")

    asset["classification"] = {
        "asset_type": "tiles",
        "semantic_role": override["semantic_role"],
        "placement_layer": "ground_detail",
        "tags": unique(override["tags"]),
        "review_status": "reviewed",
    }

    asset["placement"] = common_decal_placement(asset)
    asset["collision"] = common_no_collision()
    asset["procgen"] = make_procgen(
        uses=override["uses"],
        weight=int(override["weight"]),
        indoor=True,
        outdoor=not is_ritual,
    )

    # Preserve master_index from the generated reference manifest. If missing,
    # use batch_index + 1 because this batch starts at master_index 1.
    if "master_index" not in asset:
        asset["master_index"] = int(entry.get("batch_index", 0)) + 1

    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Fill full game32 fields for gothic batch_0000 decals.")
    parser.add_argument(
        "--json",
        type=Path,
        default=DEFAULT_AGGREGATE_JSON,
        help="Path to batch_0000_aggregate.game32.review.json",
    )
    args = parser.parse_args()

    aggregate_json = args.json.expanduser().resolve()
    if not aggregate_json.exists():
        raise FileNotFoundError(f"Aggregate review JSON not found: {aggregate_json}")

    data = read_json(aggregate_json)
    changed = 0

    for entry in data.get("entries", []):
        if patch_entry(entry):
            changed += 1

    write_json(aggregate_json, data)
    print(f"Updated {changed} entries in {aggregate_json}")

    if changed != 24:
        print(f"WARNING: expected to update 24 entries, updated {changed}. Check filenames/batch.")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
