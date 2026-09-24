#!/usr/bin/env python3
"""Translate the supplied Meridian hardstand profile JSON into .tres resources."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AUTHORING = ROOT / "asset_drop/source_work/procgen_surface_meridian_hardstand/authoring/profile_recommendations"
OUT = ROOT / "content/procgen/presentation/surface/meridian_hardstand"

MATERIALS = {
    "meridian_hardstand_plaza_irregular_01": ["hardened_civic", "hardened_industrial"],
    "meridian_hardstand_service_plaza_01": ["hardened_industrial"],
    "meridian_hardstand_corner_01": ["hardened_civic", "hardened_industrial"],
    "meridian_hardstand_service_strip_01": ["hardened_industrial"],
    "meridian_hardstand_maintenance_hatch_01": ["hardened_industrial"],
    "meridian_hardstand_landing_pad_square_01": ["hardened_industrial"],
    "meridian_hardstand_landing_pad_octagonal_01": ["hardened_industrial"],
    "meridian_hardstand_grate_service_01": ["hardened_industrial"],
    "meridian_hardstand_ruined_transition_01": [
        "hardened_civic", "hardened_industrial", "ruined_road",
        "natural_soft", "natural_rock", "wet_ground",
    ],
    "meridian_ruined_roadway_01": ["ruined_road"],
}


def vec2(value: list[int], kind: str) -> str:
    return f"{kind}({value[0]}, {value[1]})"


def vec_array(values: list[list[int]]) -> str:
    return "Array[Vector2i]([" + ", ".join(vec2(v, "Vector2i") for v in values) + "])"


def packed_strings(values: list[str]) -> str:
    return "PackedStringArray(" + ", ".join(json.dumps(v) for v in values) + ")"


def render(data: dict) -> str:
    stamp = data["stamp_id"]
    canvas = data["canvas_px"]
    footprint = data["footprint_size_cells"]
    lines = [
        "[gd_resource type=\"Resource\" script_class=\"TerrainStampProfile\" load_steps=3 format=3]",
        "",
        "[ext_resource type=\"Script\" path=\"res://game/world/procgen/presentation/terrain_stamp_profile.gd\" id=\"1\"]",
        f"[ext_resource type=\"Texture2D\" path=\"res://content/tiles/procgen_macro/runtime/meridian_hardstand/{stamp}.png\" id=\"2\"]",
        "",
        "[resource]",
        'script = ExtResource("1")',
        f'stamp_id = &"{stamp}"',
        'family_id = &"procgen_surface_meridian_hardstand"',
        'texture = ExtResource("2")',
        f"canvas_px = {vec2(canvas, 'Vector2i')}",
        f"pivot_px = {vec2(data['pivot_px'], 'Vector2')}",
        f"footprint_size_cells = {vec2(footprint, 'Vector2i')}",
        "placement_domain = 0",
        "solid_mask_cells = Array[Vector2i]([])",
        f"walkable_overlay_cells = {vec_array(data['walkable_overlay_cells'])}",
        f"reveal_probe_cells = {vec_array(data['reveal_probe_cells'])}",
        f"allowed_region_kinds = {packed_strings(data['allowed_region_kinds'])}",
        'required_biome = &""',
        f"min_region_cells = {int(data['min_region_cells'])}",
        "depth_band = 1",
        f"weight = {int(data['weight'])}",
        f"claims_dressing_clearance = {'true' if data['claims_dressing_clearance'] else 'false'}",
        "allow_flip_h = false",
        f"allowed_surface_materials = {packed_strings(MATERIALS[stamp])}",
        f"max_instances_per_map = {int(data['max_instances_per_map'])}",
        "",
    ]
    return "\n".join(lines)


def main() -> None:
    files = sorted(AUTHORING.glob("*.profile.json"))
    if len(files) != 10:
        raise SystemExit(f"expected 10 profile JSONs, found {len(files)}")
    OUT.mkdir(parents=True, exist_ok=True)
    for path in files:
        data = json.loads(path.read_text())
        if data["stamp_id"] not in MATERIALS:
            raise SystemExit(f"unexpected stamp id: {data['stamp_id']}")
        (OUT / f"{data['stamp_id']}.tres").write_text(render(data))
    print(f"generated {len(files)} Meridian hardstand profiles in {OUT}")


if __name__ == "__main__":
    main()
