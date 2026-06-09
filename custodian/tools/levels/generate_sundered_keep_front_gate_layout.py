#!/usr/bin/env python3
"""Deterministically migrate the existing Sundered Keep V1 front-gate layout."""

from __future__ import annotations

import copy
import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
LEVEL_PATH = ROOT / "custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json"
PRESERVATION_PATH = ROOT / "custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.before_cheatsheet_relayout.json"
ASSET_SCRIPT_PATH = ROOT / "custodian/content/runtime/sundered_keep/sundered_keep_game32_assets.gd"

LAYOUT_KEYS = {
    "layout_revision",
    "layout_generator",
    "layout_zones",
    "layout_routes",
    "layout_limitations",
    "blocker_visual_coverage",
    "elevation_regions",
    "underpass_regions",
    "shore_walk_regions",
    "interior_occlusion_regions",
    "ops",
}


def rect(x: int, y: int, width: int, height: int) -> list[int]:
    return [x, y, width, height]


def region(
    region_id: str,
    bounds: list[int],
    height: int,
    traversal_type: str = "walkable",
    direction: str | None = None,
) -> dict[str, Any]:
    value: dict[str, Any] = {
        "id": region_id,
        "rect": bounds,
        "height": height,
        "traversal_type": traversal_type,
    }
    if direction is not None:
        value["direction"] = direction
    return value


def generated_op(op_type: str, **values: Any) -> dict[str, Any]:
    return {"type": op_type, "generated_by": "cheatsheet_relayout_v1", **values}


def remap_asset_id(asset_id: str) -> str:
    remap = {
        "gothic_castle_wall_damaged_s": "great_hall_wall_broken_exterior_s",
        "gothic_castle_wall_breach_s": "great_hall_wall_broken_exterior_s",
        "gothic_castle_wall_breach_n": "great_hall_wall_broken_exterior_n",
        "gothic_castle_wall_damaged_n": "great_hall_wall_broken_exterior_n",
    }
    return remap.get(asset_id, asset_id)


def remap_base_ops(base_ops: list[dict[str, Any]]) -> list[dict[str, Any]]:
    remapped: list[dict[str, Any]] = []
    for op in base_ops:
        updated = copy.deepcopy(op)
        asset_id = updated.get("asset_id")
        if asset_id:
            updated["asset_id"] = remap_asset_id(str(asset_id))
        assets = updated.get("assets")
        if isinstance(assets, list):
            for entry in assets:
                if isinstance(entry, dict) and entry.get("asset_id"):
                    entry["asset_id"] = remap_asset_id(str(entry["asset_id"]))
        remapped.append(updated)
    return remapped


def build_layout_zones() -> list[dict[str, Any]]:
    return [
        {"id": "approach_bridge_h1", "rect": rect(52, 49, 9, 21), "height": 1, "role": "main_route"},
        {"id": "lower_shore_h0", "rect": rect(38, 55, 41, 25), "height": 0, "role": "lower_route"},
        {"id": "west_underbridge_lane_h0", "rect": rect(49, 62, 3, 8), "height": 0, "role": "underpass"},
        {"id": "east_underbridge_lane_h0", "rect": rect(61, 62, 3, 8), "height": 0, "role": "underpass"},
        {"id": "return_mooring", "rect": rect(39, 56, 8, 8), "height": 0, "role": "return_travel"},
        {"id": "gatehouse_core", "rect": rect(38, 44, 37, 15), "height": 1, "role": "gate_progression"},
        {"id": "main_gate_threshold", "rect": rect(54, 49, 4, 3), "height": 1, "role": "locked_threshold"},
        {"id": "courtyard", "rect": rect(35, 32, 43, 15), "height": 0, "role": "combat_arena"},
        {"id": "west_service_yard", "rect": rect(22, 35, 16, 26), "height": 0, "role": "utility_route"},
        {"id": "east_rampart", "rect": rect(73, 35, 15, 19), "height": 1, "role": "high_ground_route"},
        {"id": "great_hall_exterior_roof", "rect": rect(38, 9, 38, 21), "height": 0, "role": "roof_occluder"},
        {"id": "great_hall_interior", "rect": rect(39, 12, 36, 17), "height": 0, "role": "interior"},
        {"id": "great_hall_right_turn_hallway", "rect": rect(56, 26, 18, 3), "height": 0, "role": "marine_ambush_route"},
    ]


def build_elevation_regions() -> list[dict[str, Any]]:
    # Regions are broad enough to keep every authored elevation pocket connected.
    # Later entries intentionally override broad regions with transitions/blockers.
    return [
        region("lower_shore_and_mooring", rect(38, 55, 41, 25), 0),
        region("west_service_yard_ground", rect(22, 35, 16, 26), 0),
        region("courtyard_ground", rect(35, 31, 43, 24), 0),
        region("great_hall_ground", rect(39, 9, 36, 23), 0),
        region("raised_gatehouse_bridge", rect(52, 49, 9, 21), 1),
        region("gatehouse_core_deck", rect(50, 44, 13, 8), 1),
        region("east_rampart_high_ground", rect(78, 35, 10, 19), 1),
        region("south_bridge_ramp", rect(54, 69, 5, 1), 1, "ramp", "south"),
        region("west_bridge_side_stairs", rect(52, 63, 1, 3), 1, "stair", "west"),
        region("east_bridge_side_stairs", rect(60, 63, 1, 3), 1, "stair", "east"),
        region("gatehouse_courtyard_stairs", rect(54, 47, 5, 2), 1, "stair", "north"),
        region("east_rampart_stairs", rect(76, 42, 2, 4), 1, "stair", "east"),
        region("west_bridge_parapet_north", rect(51, 50, 1, 12), 1, "blocked"),
        region("west_bridge_parapet_south", rect(51, 66, 1, 4), 1, "blocked"),
        region("east_bridge_parapet_north", rect(61, 50, 1, 12), 1, "blocked"),
        region("east_bridge_parapet_south", rect(61, 66, 1, 4), 1, "blocked"),
    ]


def build_generated_ops() -> list[dict[str, Any]]:
    return [
        # Gatehouse descent and east-rampart ascent make every visual height change explicit.
        generated_op("fill_rect", layer="FloorDetail", rect=rect(54, 47, 5, 2), asset_id="cobblestone_stairs_vertical_01"),
        generated_op("fill_rect", layer="FloorDetail", rect=rect(76, 42, 2, 4), asset_id="cobblestone_stairs_vertical_01"),
        # West service-yard boundary and broken utility-yard choke points.
        generated_op("fill_rect", layer="WallsHigh", rect=rect(28, 38, 1, 10), asset_id="PLACEHOLDER_sundered_keep_labyrinth_wall_straight_s"),
        generated_op("fill_rect", layer="WallsHigh", rect=rect(29, 34, 9, 1), asset_id="PLACEHOLDER_sundered_keep_labyrinth_wall_straight_s"),
        generated_op("paint_cells", layer="WallsHigh", asset_id="PLACEHOLDER_sundered_keep_labyrinth_wall_corner", cells=[[28, 38], [29, 34], [37, 34]]),
        generated_op("blocker_rect", name="WestServiceYardOuterWallBlocker", rect=rect(28, 38, 1, 10)),
        generated_op("blocker_rect", name="WestServiceYardNorthWallBlocker", rect=rect(29, 34, 9, 1)),
        # Great Hall central aisle, archive/throne focus, and readable right-turn route.
        generated_op("fill_rect", layer="FloorDetail", rect=rect(55, 12, 2, 15), asset_id="great_hall_carpet_runner_vertical_01"),
        generated_op("stamp_prop", layer="PropsStatic", asset_id="prop_gate_winch_01", tile=[65, 13]),
        generated_op("stamp_prop", layer="PropsBlocking", asset_id="prop_banquet_table_broken_01", tile=[62, 23]),
        # Explicit collapsed sea-cut guard/readability art beside the Great Hall.
        generated_op("fill_rect", layer="WallsLow", rect=rect(81, 20, 1, 7), asset_id="PLACEHOLDER_sundered_keep_labyrinth_void_edge"),
    ]


def build_blocker_visual_coverage(base_ops: list[dict[str, Any]], generated_ops: list[dict[str, Any]]) -> list[dict[str, Any]]:
    visible_rects: list[dict[str, Any]] = []
    for op in [*base_ops, *generated_ops]:
        if op.get("type") not in {"fill_rect", "stamp_wall"}:
            continue
        if not str(op.get("layer", "WallsHigh")).startswith(("Wall", "TerrainEdge")):
            continue
        visible_rects.append({"rect": op["rect"], "asset_id": op.get("asset_id", ""), "layer": op.get("layer", "WallsHigh")})

    coverage: list[dict[str, Any]] = []
    for op in [*base_ops, *generated_ops]:
        if op.get("type") != "blocker_rect":
            continue
        visible_coverage = [
            entry for entry in visible_rects if rectangles_overlap(op["rect"], entry["rect"])
        ]
        blocker_name = str(op.get("name", "LevelBlocker"))
        if not visible_coverage and "Ocean" in blocker_name:
            visible_coverage = [{"layer": "StormOceanBackdrop", "asset_id": "storm_ocean_backdrop", "rect": op["rect"]}]
        if not visible_coverage and blocker_name == "SubmergedCausewayBlocker":
            visible_coverage = [{"layer": "TerrainBase", "asset_id": "entrance_causeway_broken_gap_01", "rect": op["rect"]}]
        coverage.append(
            {
                "blocker_name": blocker_name,
                "rect": op["rect"],
                "visible_coverage": visible_coverage,
                "intent": "ocean_boundary" if "Ocean" in blocker_name else "fortress_wall_or_edge",
            }
        )
    return coverage


def rectangles_overlap(a: list[int], b: list[int]) -> bool:
    return a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]


def collect_asset_ids(ops: list[dict[str, Any]]) -> set[str]:
    asset_ids: set[str] = set()
    for op in ops:
        asset_id = op.get("asset_id")
        if asset_id:
            asset_ids.add(str(asset_id))
        for entry in op.get("assets", []):
            if entry.get("asset_id"):
                asset_ids.add(str(entry["asset_id"]))
    return asset_ids


def collect_registered_asset_ids() -> set[str]:
    registered = {path.stem for path in (ROOT / "custodian/content").rglob("*.png")}
    script_text = ASSET_SCRIPT_PATH.read_text(encoding="utf-8")
    registered.update(re.findall(r'^\\s*"([^"]+)":\\s*\\{', script_text, re.MULTILINE))
    return registered


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    if not PRESERVATION_PATH.exists():
        raise SystemExit(f"Missing required preservation copy: {PRESERVATION_PATH}")

    current = load_json(LEVEL_PATH) if LEVEL_PATH.exists() else load_json(PRESERVATION_PATH)
    preserved_v1 = load_json(PRESERVATION_PATH)
    migrated = copy.deepcopy(current)

    base_ops = remap_base_ops(copy.deepcopy(preserved_v1.get("ops", [])))
    generated_ops = build_generated_ops()
    migrated.update(
        {
            "layout_revision": "cheatsheet_relayout_v1",
            "layout_generator": "custodian/tools/levels/generate_sundered_keep_front_gate_layout.py",
            "layout_zones": build_layout_zones(),
            "layout_routes": [
                {"id": "main_route", "zones": ["approach_bridge_h1", "gatehouse_core", "main_gate_threshold", "courtyard", "great_hall_interior"]},
                {"id": "lower_route", "zones": ["lower_shore_h0", "west_underbridge_lane_h0", "east_underbridge_lane_h0", "return_mooring"]},
                {"id": "east_high_ground_route", "zones": ["courtyard", "east_rampart"]},
                {"id": "west_utility_route", "zones": ["return_mooring", "west_service_yard", "courtyard"]},
            ],
            "layout_limitations": [
                "V1 does not support true same-coordinate stacked traversal.",
                "Under-bridge traversal uses adjacent height-0 shore lanes plus visual shadow/occlusion overlays.",
            ],
            "elevation_regions": build_elevation_regions(),
            "underpass_regions": copy.deepcopy(preserved_v1.get("underpass_regions", [])),
            "shore_walk_regions": copy.deepcopy(preserved_v1.get("shore_walk_regions", [])),
            "interior_occlusion_regions": copy.deepcopy(preserved_v1.get("interior_occlusion_regions", [])),
            "ops": [*base_ops, *generated_ops],
        }
    )
    migrated["blocker_visual_coverage"] = build_blocker_visual_coverage(base_ops, generated_ops)

    LEVEL_PATH.write_text(json.dumps(migrated, indent=2, ensure_ascii=True) + "\n", encoding="utf-8")

    before_keys = set(current)
    after_keys = set(migrated)
    changed = sorted(key for key in before_keys & after_keys if current[key] != migrated[key])
    unresolved = sorted(collect_asset_ids(migrated["ops"]) - collect_registered_asset_ids())
    blocker_regions = migrated["blocker_visual_coverage"]
    covered_blockers = sum(bool(item["visible_coverage"]) for item in blocker_regions)
    print("Sundered Keep front-gate cheat-sheet relayout generated")
    print(f"top-level JSON keys preserved: {sorted((before_keys & after_keys) - set(changed))}")
    print(f"top-level JSON keys changed: {changed}")
    print(f"top-level JSON keys added: {sorted(after_keys - before_keys)}")
    print(f"top-level JSON keys removed: {sorted(before_keys - after_keys)}")
    print(f"unresolved asset IDs: {unresolved}")
    print("placeholder assets created: []")
    print(f"blocker regions with visible wall/edge coverage: {covered_blockers}/{len(blocker_regions)}")
    print(f"elevation regions generated: {len(migrated['elevation_regions'])}")


if __name__ == "__main__":
    main()
