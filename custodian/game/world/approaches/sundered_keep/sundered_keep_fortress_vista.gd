extends Node
class_name SunderedKeepFortressVista

const COMPONENT_ROOT := (
	"res://content/backgrounds/sundered_keep/"
	+ "grand_vista/fortress_components/"
)

const FAR_SECONDARY := Color(0.40, 0.48, 0.58, 1.0)
const FAR_HERO := Color(0.44, 0.51, 0.61, 1.0)
const MID_HERO := Color(0.86, 0.89, 0.94, 1.0)
const MID_SECONDARY := Color(0.74, 0.79, 0.86, 0.96)
const NEAR_COLOR := Color(0.68, 0.74, 0.82, 1.0)

# The source directory is a composition kit. All components stay instantiated
# for hitch-free review, but the primary hero shot intentionally uses 17
# overlapping pieces arranged into western, central, eastern, and remote wards.
const HERO_VISIBLE_COMPONENTS := {
	"distant_fortress_outer_wall_01": true,
	"distant_fortress_central_citadel_01": true,
	"distant_fortress_descending_ward_01": true,
	"curtain_wall_plain_01": true,
	"cliff_foundation_broad_01": true,
	"round_citadel_tower_01": true,
	"rear_watchtower_octagonal_broken_01": true,
	"curtain_wall_gate_01": true,
	"cliff_foundation_hollow_01": true,
	"square_gate_tower_01": true,
	"cliff_foundation_split_01": true,
	"curtain_wall_banner_01": true,
	"rear_watchtower_square_buttressed_01": true,
	"square_gate_tower_02": true,
	"broken_arch_heavy_01": true,
	"raised_causeway_01": true,
	"stone_bridge_single_arch_01": true,
}

const PLACEMENTS: Array[Dictionary] = [
	{"id": "distant_fortress_outer_wall_01", "file": "distant_fortress_outer_wall_01.png", "plane": "far", "x": 1280.0, "y": 390.0, "scale": 0.28, "z": 0, "modulate": FAR_SECONDARY, "precinct": "remote_inner_keep"},
	{"id": "distant_fortress_broken_spire_01", "file": "distant_fortress_broken_spire_01.png", "plane": "far", "x": 1040.0, "y": 230.0, "scale": 0.25, "z": 1, "modulate": FAR_SECONDARY, "precinct": "remote_inner_keep"},
	{"id": "distant_fortress_central_citadel_01", "file": "distant_fortress_central_citadel_01.png", "plane": "far", "x": 1580.0, "y": 190.0, "scale": 0.25, "z": 2, "modulate": FAR_HERO, "precinct": "remote_inner_keep"},
	{"id": "distant_fortress_descending_ward_01", "file": "distant_fortress_descending_ward_01.png", "plane": "far", "x": 1730.0, "y": 440.0, "scale": 0.26, "z": 3, "modulate": FAR_SECONDARY, "precinct": "remote_inner_keep"},

	{"id": "broken_wall_collapsed_01", "file": "broken_wall_collapsed_01.png", "plane": "mid", "x": 40.0, "y": 650.0, "scale": 0.66, "z": 10, "modulate": MID_SECONDARY, "precinct": "western_collapsed_ward"},
	{"id": "rear_watchtower_round_01", "file": "rear_watchtower_round_01.png", "plane": "mid", "x": 20.0, "y": 390.0, "scale": 0.52, "z": 11, "modulate": MID_SECONDARY, "precinct": "western_collapsed_ward"},
	{"id": "curtain_wall_plain_01", "file": "curtain_wall_plain_01.png", "plane": "mid", "x": 120.0, "y": 570.0, "scale": 0.70, "z": 12, "modulate": MID_SECONDARY, "precinct": "western_collapsed_ward"},
	{"id": "cliff_foundation_broad_01", "file": "cliff_foundation_broad_01.png", "plane": "mid", "x": 250.0, "y": 470.0, "scale": 0.58, "z": 13, "modulate": MID_SECONDARY, "precinct": "western_collapsed_ward"},
	{"id": "raised_causeway_01", "file": "raised_causeway_01.png", "plane": "mid", "x": 480.0, "y": 515.0, "scale": 0.70, "z": 14, "modulate": MID_SECONDARY, "precinct": "central_citadel", "route_hint": "middle"},
	{"id": "stone_bridge_single_arch_01", "file": "stone_bridge_single_arch_01.png", "plane": "mid", "x": 1040.0, "y": 470.0, "scale": 0.62, "z": 15, "modulate": MID_SECONDARY, "precinct": "eastern_gate_ward", "route_hint": "upper"},
	{"id": "cliff_foundation_hollow_01", "file": "cliff_foundation_hollow_01.png", "plane": "mid", "x": 650.0, "y": 450.0, "scale": 0.55, "z": 16, "modulate": MID_SECONDARY, "precinct": "central_citadel"},
	{"id": "round_citadel_tower_01", "file": "round_citadel_tower_01.png", "plane": "mid", "x": 620.0, "y": 130.0, "scale": 0.74, "z": 17, "modulate": MID_HERO, "precinct": "central_citadel"},
	{"id": "rear_watchtower_octagonal_broken_01", "file": "rear_watchtower_octagonal_broken_01.png", "plane": "mid", "x": 160.0, "y": 260.0, "scale": 0.62, "z": 18, "modulate": MID_SECONDARY, "precinct": "western_collapsed_ward"},
	{"id": "square_gate_tower_01", "file": "square_gate_tower_01.png", "plane": "mid", "x": 820.0, "y": 310.0, "scale": 0.62, "z": 19, "modulate": MID_HERO, "precinct": "central_citadel"},
	{"id": "curtain_wall_gate_01", "file": "curtain_wall_gate_01.png", "plane": "mid", "x": 700.0, "y": 575.0, "scale": 0.68, "z": 20, "modulate": MID_SECONDARY, "precinct": "central_citadel", "route_hint": "middle"},
	{"id": "cliff_foundation_split_01", "file": "cliff_foundation_split_01.png", "plane": "mid", "x": 1190.0, "y": 500.0, "scale": 0.55, "z": 21, "modulate": MID_SECONDARY, "precinct": "eastern_gate_ward"},
	{"id": "round_citadel_tower_02", "file": "round_citadel_tower_02.png", "plane": "mid", "x": 1080.0, "y": 180.0, "scale": 0.64, "z": 22, "modulate": MID_SECONDARY, "precinct": "eastern_gate_ward"},
	{"id": "curtain_wall_banner_01", "file": "curtain_wall_banner_01.png", "plane": "mid", "x": 960.0, "y": 570.0, "scale": 0.68, "z": 23, "modulate": MID_SECONDARY, "precinct": "eastern_gate_ward"},
	{"id": "rear_watchtower_square_buttressed_01", "file": "rear_watchtower_square_buttressed_01.png", "plane": "mid", "x": 1480.0, "y": 360.0, "scale": 0.50, "z": 24, "modulate": MID_SECONDARY, "precinct": "eastern_gate_ward"},
	{"id": "cliff_foundation_shelved_01", "file": "cliff_foundation_shelved_01.png", "plane": "mid", "x": 1450.0, "y": 510.0, "scale": 0.50, "z": 25, "modulate": MID_SECONDARY, "precinct": "eastern_gate_ward"},
	{"id": "square_gate_tower_02", "file": "square_gate_tower_02.png", "plane": "mid", "x": 1200.0, "y": 300.0, "scale": 0.66, "z": 26, "modulate": MID_HERO, "precinct": "eastern_gate_ward"},
	{"id": "broken_wall_window_01", "file": "broken_wall_window_01.png", "plane": "mid", "x": 1670.0, "y": 600.0, "scale": 0.62, "z": 27, "modulate": MID_SECONDARY, "precinct": "remote_inner_keep"},

	{"id": "battlement_crown_round_01", "file": "battlement_crown_round_01.png", "plane": "near", "x": 80.0, "y": 870.0, "scale": 0.72, "z": 30, "modulate": NEAR_COLOR},
	{"id": "broken_arch_heavy_01", "file": "broken_arch_heavy_01.png", "plane": "near", "x": 10.0, "y": 650.0, "scale": 0.62, "z": 31, "modulate": NEAR_COLOR, "precinct": "western_collapsed_ward", "route_hint": "lower"},
	{"id": "battlement_crown_round_02", "file": "battlement_crown_round_02.png", "plane": "near", "x": 530.0, "y": 920.0, "scale": 0.70, "z": 32, "modulate": NEAR_COLOR},
	{"id": "raised_causeway_02", "file": "raised_causeway_02.png", "plane": "near", "x": 1370.0, "y": 650.0, "scale": 0.58, "z": 33, "modulate": NEAR_COLOR, "precinct": "eastern_gate_ward", "route_hint": "upper"},
	{"id": "stone_bridge_double_arch_01", "file": "stone_bridge_double_arch_01.png", "plane": "near", "x": 1530.0, "y": 700.0, "scale": 0.56, "z": 34, "modulate": NEAR_COLOR, "precinct": "remote_inner_keep"},
	{"id": "battlement_crown_round_broken_01", "file": "battlement_crown_round_broken_01.png", "plane": "near", "x": 980.0, "y": 920.0, "scale": 0.70, "z": 35, "modulate": NEAR_COLOR},
	{"id": "battlement_crown_round_turreted_01", "file": "battlement_crown_round_turreted_01.png", "plane": "near", "x": 1560.0, "y": 900.0, "scale": 0.70, "z": 38, "modulate": NEAR_COLOR},
	{"id": "broken_arch_walkway_01", "file": "broken_arch_walkway_01.png", "plane": "near", "x": 1650.0, "y": 690.0, "scale": 0.54, "z": 39, "modulate": NEAR_COLOR, "precinct": "remote_inner_keep", "route_hint": "lower"},
]


func build(
	far_parent: Node2D,
	mid_parent: Node2D,
	near_parent: Node2D
) -> int:
	var parents := {
		"far": far_parent,
		"mid": mid_parent,
		"near": near_parent,
	}
	var built := 0
	for data: Dictionary in PLACEMENTS:
		var plane := str(data["plane"])
		var parent := parents.get(plane) as Node2D
		if parent == null:
			push_error("[FortressVista] Invalid plane: %s" % plane)
			continue
		var path := COMPONENT_ROOT + str(data["file"])
		var texture := load(path) as Texture2D
		if texture == null:
			push_error("[FortressVista] Missing texture: %s" % path)
			continue
		var sprite := Sprite2D.new()
		sprite.name = str(data["id"]).to_pascal_case()
		sprite.texture = texture
		sprite.centered = false
		sprite.position = Vector2(
			float(data["x"]),
			float(data["y"])
		)
		var authored_scale := float(data["scale"])
		sprite.scale = Vector2.ONE * authored_scale
		sprite.z_as_relative = true
		sprite.z_index = int(data["z"])
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
		sprite.modulate = data.get(
			"modulate",
			Color.WHITE
		) as Color
		sprite.visible = HERO_VISIBLE_COMPONENTS.has(
			str(data["id"])
		)
		sprite.set_meta("presentation_only", true)
		sprite.set_meta("fortress_component", str(data["id"]))
		sprite.set_meta(
			"fortress_precinct",
			str(data.get("precinct", "support"))
		)
		sprite.set_meta(
			"labyrinth_route_hint",
			str(data.get("route_hint", ""))
		)
		sprite.set_meta(
			"disabled_for_primary_composition",
			not sprite.visible
		)
		parent.add_child(sprite)
		built += 1
	return built
