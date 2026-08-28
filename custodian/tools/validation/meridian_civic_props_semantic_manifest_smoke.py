#!/usr/bin/env python3
"""Validate the Meridian civic native-prop semantic/runtime contract."""

from __future__ import annotations

import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
MANIFEST = ROOT / "custodian/content/metadata/assets/meridian_civic_props_native.semantic.json"
SOURCE = ROOT / "custodian/asset_drop/source_work/meridian_civic_props/native_extract/sprites"
RUNTIME = ROOT / "custodian/content/sprites/environment/props/meridian_civic/native"
MASTER = ROOT / "custodian/asset_drop/source_work/lower_quarter_region/meridian_civic_props_atlas__master.png"
PRESENTER = ROOT / "custodian/game/world/levels/authored/ash_bell/common/meridian_civic_art_presenter.gd"
EXPECTED_FAMILIES = {
    "meridian_civic_basin": 11,
    "meridian_civic_bench": 4,
    "meridian_civic_container": 5,
    "meridian_civic_crate": 8,
    "meridian_civic_debris": 35,
    "meridian_civic_floor_hardware": 39,
    "meridian_civic_industrial_module": 23,
    "meridian_civic_lighting": 16,
    "meridian_civic_planter": 11,
    "meridian_civic_security": 4,
    "meridian_civic_signage": 13,
    "meridian_civic_structure": 16,
    "meridian_civic_terminal": 3,
    "meridian_civic_traffic_control": 17,
    "meridian_civic_utility": 12,
    "meridian_civic_waste": 3,
    "meridian_civic_worksite": 4,
}


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        assert handle.read(8) == b"\x89PNG\r\n\x1a\n", f"not a PNG: {path}"
        length = struct.unpack(">I", handle.read(4))[0]
        assert handle.read(4) == b"IHDR" and length == 13, f"invalid IHDR: {path}"
        return struct.unpack(">II", handle.read(8))


def main() -> None:
    assert MANIFEST.is_file() and MASTER.is_file()
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    entries = payload["entries"]
    assert payload["schema"] == "custodian.semantic_prop_manifest.v1"
    assert len(entries) == 224
    assert sorted(entry["id"] for entry in entries) == list(range(1, 225))
    assert len({(entry["runtime_family"], entry["variant_key"]) for entry in entries}) == 224
    assert set(payload["runtime_families"]) == set(EXPECTED_FAMILIES)

    counts: dict[str, int] = {}
    review_ids: set[int] = set()
    representatives = {
        "lantern_standard_a", "lantern_standard_amber", "bench_wood_short",
        "cabinet_tall_closed", "octagonal_jet_fountain", "planter_rect_small_a",
        "rect_grate_large", "concrete_barrier_striped", "cargo_crate_long",
        "rubble_pile_a",
    }
    seen_representatives: set[str] = set()
    for entry in entries:
        family = entry["runtime_family"]
        counts[family] = counts.get(family, 0) + 1
        source_path = SOURCE / entry["source_file"]
        runtime_path = RUNTIME / family / entry["source_file"]
        assert source_path.is_file(), source_path
        assert runtime_path.is_file(), runtime_path
        assert png_size(source_path) == tuple(entry["crop_size"])
        assert png_size(runtime_path) == tuple(entry["crop_size"])
        assert entry["native_scale"] == 1.0
        assert entry["collision_is_authoritative"] is False
        assert entry["anchor_mode"] in {"floor_contact", "floor_center", "wall_mount"}
        if entry["role"] == "floor_overlay":
            assert entry["collision_profile"] == "none" or entry["collision_profile"].startswith(("authored_", "optional_"))
        if entry["runtime_strategy"] == "detail_only":
            assert entry["collision_profile"] == "none"
        if entry["review_required"]:
            review_ids.add(entry["id"])
        if entry["variant_key"] in representatives:
            seen_representatives.add(entry["variant_key"])

    assert counts == EXPECTED_FAMILIES
    assert review_ids == {177, 201, 212}
    assert seen_representatives == representatives
    assert len(list(RUNTIME.glob("*/*.png"))) == 224

    presenter_source = PRESENTER.read_text(encoding="utf-8")
    assert "meridian_civic_props_atlas_512.png" not in presenter_source
    assert "draw_texture_rect_region(PROPS" not in presenter_source
    print("meridian_civic_props_semantic_manifest_smoke: PASS entries=224 families=17")


if __name__ == "__main__":
    main()
