#!/usr/bin/env python3
"""Validate Meridian catastrophe extraction, semantics, and placement authority."""

from __future__ import annotations

import json
import struct
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PROJECT = ROOT / "custodian"
RAW = PROJECT / "asset_drop/source_work/meridian_civic_ruins_props/native_extract/manifest.json"
ANNOTATIONS = PROJECT / "content/metadata/assets/meridian_civic_ruins_native.semantic_annotations.json"
MANIFEST = PROJECT / "content/metadata/assets/meridian_civic_ruins_native.semantic.json"
PLACEMENTS = PROJECT / "game/world/levels/authored/ash_bell/common/ash_bell_catastrophe_prop_placements.json"
LAYER = PROJECT / "game/world/levels/authored/ash_bell/common/ash_bell_catastrophe_prop_layer_2d.gd"
EXPECTED_ZONES = {
    "arrival": 12,
    "direct_collapse": 22,
    "evacuation_arcade": 18,
    "lower_market": 22,
    "civic_basin": 8,
    "wrong_street": 4,
    "answers_court": 6,
    "station_approach": 10,
}
BLOCKED_CELLS = {
    (64, 87), (14, 43), (80, 65),
    (64, 91), (6, 43), (74, 65),
    (39, 58), (22, 42), (89, 21),
}
WALKABLE = (
    (52, 82, 24, 12), (58, 70, 12, 14), (38, 74, 22, 8),
    (32, 48, 14, 32), (16, 34, 46, 20), (56, 36, 24, 14),
    (74, 30, 34, 24), (84, 18, 12, 14), (55, 8, 34, 22),
    (84, 16, 24, 10), (98, 22, 10, 44), (72, 58, 30, 10),
    (4, 39, 14, 8),
)


def _png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as stream:
        assert stream.read(8) == b"\x89PNG\r\n\x1a\n", path
        length = struct.unpack(">I", stream.read(4))[0]
        assert stream.read(4) == b"IHDR" and length == 13, path
        return struct.unpack(">II", stream.read(8))


def _walkable(cell: tuple[int, int]) -> bool:
    return any(x <= cell[0] < x + width and y <= cell[1] < y + height for x, y, width, height in WALKABLE)


def main() -> None:
    raw = json.loads(RAW.read_text(encoding="utf-8"))
    annotations = json.loads(ANNOTATIONS.read_text(encoding="utf-8"))
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    placement_document = json.loads(PLACEMENTS.read_text(encoding="utf-8"))
    raw_by_id = {int(entry["id"]): entry for entry in raw["sprites"]}
    annotation_by_id = {int(entry["source_id"]): entry for entry in annotations["entries"]}
    manifest_by_id = {int(entry["source_id"]): entry for entry in manifest["entries"]}
    expected_ids = set(range(1, 162))
    assert set(raw_by_id) == set(annotation_by_id) == set(manifest_by_id) == expected_ids
    assert len(manifest["entries"]) == 161
    assert len(manifest["runtime_families"]) == 12
    assert sum(bool(entry["review_required"]) for entry in manifest["entries"]) == 20

    addresses: set[tuple[str, str]] = set()
    for source_id in sorted(expected_ids):
        raw_entry = raw_by_id[source_id]
        semantic = annotation_by_id[source_id]
        merged = manifest_by_id[source_id]
        for key in (
            "filename", "native_content_size", "crop_size", "detected_bbox",
            "crop_bbox", "suggested_anchor_px", "anchor_semantics", "resized",
        ):
            assert merged[key] == raw_entry[key], (source_id, key)
        for key in (
            "semantic_name", "semantic_family", "runtime_family", "anchor_mode",
            "collision_hint", "era_layer", "districts", "review_required", "usage_policy",
        ):
            assert merged[key] == semantic[key], (source_id, key)
        address = (merged["runtime_family"], merged["variant_key"])
        assert address not in addresses
        addresses.add(address)
        texture = PROJECT / merged["texture_path"].removeprefix("res://")
        assert texture.is_file(), texture
        assert _png_size(texture) == tuple(raw_entry["crop_size"])
        assert merged["native_scale"] == 1.0
        assert merged["collision_is_authoritative"] is False

    placements = placement_document["placements"]
    assert len(placements) == placement_document["placement_count"] == 102
    assert placement_document["zone_counts"] == EXPECTED_ZONES
    assert Counter(entry["zone"] for entry in placements) == Counter(EXPECTED_ZONES)
    assert len({entry["placement_id"] for entry in placements}) == 102
    assert len({tuple(entry["cell"]) for entry in placements}) == 102
    used_review_required = set()
    for placement in placements:
        source_id = int(placement["source_id"])
        assert source_id in manifest_by_id
        assert placement["semantic_name"] == manifest_by_id[source_id]["semantic_name"]
        assert placement["scale"] == [1.0, 1.0]
        assert placement["collision_enabled"] is False
        cell = tuple(placement["cell"])
        assert cell not in BLOCKED_CELLS, placement["placement_id"]
        assert _walkable(cell), placement["placement_id"]
        if manifest_by_id[source_id]["review_required"]:
            assert manifest_by_id[source_id]["usage_policy"] == "explicit_authored_only"
            used_review_required.add(source_id)
    assert used_review_required == {143, 144}

    layer_source = LAYER.read_text(encoding="utf-8")
    for forbidden in ("randf", "randi", "RandomNumberGenerator", "shuffle", "pick_random"):
        assert forbidden not in layer_source
    print(
        "meridian_civic_ruins_semantic_manifest_smoke: PASS "
        "entries=161 placements=102 explicit_compounds=2"
    )


if __name__ == "__main__":
    main()
