#!/usr/bin/env python3
"""
Finalize gothic review batch_0000 aggregate JSON after visual review.

This assumes the semantic roles are already filled, as shown in the contact
sheet:

  floor_detail_001..020:
    reviewed non-blocking gothic floor detail overlays

  ritual_floor_decal_001..004:
    reviewed non-blocking ritual floor overlays

This script cleans final metadata:
  - source.review_source -> human_reviewed_contact_sheet_batch_0000
  - source.review_status -> reviewed
  - review.notes -> explicit human review note
  - classification.placement_layer -> floor_overlay
  - procgen.uses keeps the existing semantic uses

It edits only the aggregate review JSON. Your batch review script will then
write each asset sidecar when you press Enter to apply.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


DEFAULT_JSON = Path(
    "/home/braydenchaffee/Projects/CUSTODIAN/"
    "custodian/content/tiles/gothic/.review_batches/game32_asset_review/"
    "batch_0000_aggregate.game32.review.json"
)


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def is_batch_0000_decal(filename: str) -> bool:
    return (
        filename.startswith("floor_detail_")
        or filename.startswith("ritual_floor_decal_")
    ) and filename.endswith(".png")


def patch_entry(entry: dict[str, Any], *, use_floor_overlay_layer: bool) -> bool:
    current = entry.get("current", {})
    filename = current.get("filename", "")

    if not is_batch_0000_decal(filename):
        return False

    review = entry.setdefault("review", {})
    asset = entry.setdefault("asset", {})
    source = asset.setdefault("source", {})
    classification = asset.setdefault("classification", {})
    placement = asset.setdefault("placement", {})
    collision = asset.setdefault("collision", {})
    procgen = asset.setdefault("procgen", {})

    is_ritual = filename.startswith("ritual_floor_decal_")

    review["action"] = "keep"
    review["delete_import"] = True
    review["notes"] = (
        "Finalized from batch_0000 contact sheet visual review. "
        "Asset is a non-blocking floor overlay/decal, not a base floor tile."
    )

    source["review_source"] = "human_reviewed_contact_sheet_batch_0000"
    source["review_status"] = "reviewed"
    source["section"] = "tiles"
    source["subtype"] = "decals"

    classification["asset_type"] = "tiles"
    if use_floor_overlay_layer:
        classification["placement_layer"] = "floor_overlay"
    else:
        classification["placement_layer"] = "ground_detail"
    classification["review_status"] = "reviewed"

    tags = classification.get("tags", [])
    for tag in ["floor", "decal", "overlay", "walkable", "no_collision"]:
        if tag not in tags:
            tags.append(tag)
    if is_ritual and "ritual" not in tags:
        tags.append("ritual")
    classification["tags"] = tags

    placement["tile_size"] = 32
    placement["origin_mode"] = "top_left"
    placement["snap"] = "tile"
    placement["allow_mirror_x"] = False
    placement["allow_rotation"] = False
    placement["y_sort"] = False
    placement["pivot_px"] = {"x": 0, "y": 0}
    placement["review_status"] = "reviewed"

    collision["blocks_movement"] = False
    collision["blocks_sight"] = False
    collision["cover_value"] = 0
    collision["collision_shape"] = "none"
    collision["review_status"] = "reviewed"

    procgen["can_spawn_indoor"] = True
    if is_ritual:
        procgen["can_spawn_outdoor"] = False
    procgen["supports_gothic_compound"] = True
    procgen["review_status"] = "reviewed"

    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", type=Path, default=DEFAULT_JSON)
    parser.add_argument(
        "--keep-ground-detail",
        action="store_true",
        help="Keep classification.placement_layer as ground_detail instead of normalizing to floor_overlay.",
    )
    args = parser.parse_args()

    path = args.json.expanduser().resolve()
    data = read_json(path)

    changed = 0
    for entry in data.get("entries", []):
        if patch_entry(entry, use_floor_overlay_layer=not args.keep_ground_detail):
            changed += 1

    write_json(path, data)
    print(f"Finalized {changed} entries in {path}")

    if changed != 24:
        print(f"WARNING: expected 24 entries, changed {changed}")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
