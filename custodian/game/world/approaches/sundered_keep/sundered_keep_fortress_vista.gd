extends Node
class_name SunderedKeepFortressVista

const COMPONENT_ROOT := (
	"res://content/backgrounds/sundered_keep/"
	+ "grand_vista/fortress_components/"
)

const FAR_SECONDARY := Color(0.48, 0.56, 0.66, 0.62)
const FAR_HERO := Color(0.48, 0.56, 0.66, 0.62)
const MID_HERO := Color(0.68, 0.74, 0.82, 0.88)
const MID_SECONDARY := Color(0.68, 0.74, 0.82, 0.88)
const NEAR_COLOR := Color(0.78, 0.82, 0.88, 0.78)

# The source directory is a composition kit. All components stay instantiated
# for hitch-free review, but the primary hero shot intentionally uses 17.
const HERO_VISIBLE_COMPONENTS := {
	"distant_fortress_outer_wall_01": true,
	"distant_fortress_broken_spire_01": true,
	"distant_fortress_central_citadel_01": true,
	"distant_fortress_descending_ward_01": true,
	"rear_watchtower_round_01": true,
	"curtain_wall_plain_01": true,
	"cliff_foundation_broad_01": true,
	"round_citadel_tower_01": true,
	"rear_watchtower_octagonal_broken_01": true,
	"curtain_wall_gate_01": true,
	"cliff_foundation_hollow_01": true,
	"square_gate_tower_01": true,
	"cliff_foundation_split_01": true,
	"round_citadel_tower_02": true,
	"curtain_wall_banner_01": true,
	"square_gate_tower_02": true,
	"broken_arch_heavy_01": true,
}

const PLACEMENTS: Array[Dictionary] = [
	{"id": "distant_fortress_outer_wall_01", "file": "distant_fortress_outer_wall_01.png", "plane": "far", "x": 80.0, "y": 360.0, "scale": 0.46, "z": 0, "modulate": FAR_SECONDARY},
	{"id": "distant_fortress_broken_spire_01", "file": "distant_fortress_broken_spire_01.png", "plane": "far", "x": 420.0, "y": 70.0, "scale": 0.40, "z": 1, "modulate": FAR_SECONDARY},
	{"id": "distant_fortress_central_citadel_01", "file": "distant_fortress_central_citadel_01.png", "plane": "far", "x": 820.0, "y": 10.0, "scale": 0.50, "z": 2, "modulate": FAR_HERO},
	{"id": "distant_fortress_descending_ward_01", "file": "distant_fortress_descending_ward_01.png", "plane": "far", "x": 1170.0, "y": 350.0, "scale": 0.50, "z": 3, "modulate": FAR_SECONDARY},

	{"id": "broken_wall_collapsed_01", "file": "broken_wall_collapsed_01.png", "plane": "mid", "x": 50.0, "y": 650.0, "scale": 0.86, "z": 10, "modulate": MID_SECONDARY},
	{"id": "rear_watchtower_round_01", "file": "rear_watchtower_round_01.png", "plane": "mid", "x": 290.0, "y": 300.0, "scale": 0.68, "z": 11, "modulate": MID_SECONDARY},
	{"id": "curtain_wall_plain_01", "file": "curtain_wall_plain_01.png", "plane": "mid", "x": 260.0, "y": 560.0, "scale": 0.82, "z": 12, "modulate": MID_SECONDARY},
	{"id": "cliff_foundation_broad_01", "file": "cliff_foundation_broad_01.png", "plane": "mid", "x": 420.0, "y": 470.0, "scale": 0.68, "z": 13, "modulate": MID_SECONDARY},
	{"id": "round_citadel_tower_01", "file": "round_citadel_tower_01.png", "plane": "mid", "x": 470.0, "y": 120.0, "scale": 0.80, "z": 14, "modulate": MID_HERO},
	{"id": "rear_watchtower_octagonal_broken_01", "file": "rear_watchtower_octagonal_broken_01.png", "plane": "mid", "x": 720.0, "y": 330.0, "scale": 0.70, "z": 15, "modulate": MID_SECONDARY},
	{"id": "curtain_wall_gate_01", "file": "curtain_wall_gate_01.png", "plane": "mid", "x": 640.0, "y": 590.0, "scale": 0.84, "z": 16, "modulate": MID_SECONDARY},
	{"id": "cliff_foundation_hollow_01", "file": "cliff_foundation_hollow_01.png", "plane": "mid", "x": 760.0, "y": 500.0, "scale": 0.62, "z": 17, "modulate": MID_SECONDARY},
	{"id": "square_gate_tower_01", "file": "square_gate_tower_01.png", "plane": "mid", "x": 810.0, "y": 240.0, "scale": 0.78, "z": 18, "modulate": MID_HERO},
	{"id": "cliff_foundation_split_01", "file": "cliff_foundation_split_01.png", "plane": "mid", "x": 1080.0, "y": 500.0, "scale": 0.66, "z": 19, "modulate": MID_SECONDARY},
	{"id": "round_citadel_tower_02", "file": "round_citadel_tower_02.png", "plane": "mid", "x": 1130.0, "y": 100.0, "scale": 0.82, "z": 20, "modulate": MID_HERO},
	{"id": "curtain_wall_banner_01", "file": "curtain_wall_banner_01.png", "plane": "mid", "x": 1280.0, "y": 590.0, "scale": 0.84, "z": 21, "modulate": MID_SECONDARY},
	{"id": "rear_watchtower_square_buttressed_01", "file": "rear_watchtower_square_buttressed_01.png", "plane": "mid", "x": 1360.0, "y": 345.0, "scale": 0.68, "z": 22, "modulate": MID_SECONDARY},
	{"id": "cliff_foundation_shelved_01", "file": "cliff_foundation_shelved_01.png", "plane": "mid", "x": 1430.0, "y": 520.0, "scale": 0.62, "z": 23, "modulate": MID_SECONDARY},
	{"id": "square_gate_tower_02", "file": "square_gate_tower_02.png", "plane": "mid", "x": 1480.0, "y": 255.0, "scale": 0.74, "z": 24, "modulate": MID_HERO},
	{"id": "broken_wall_window_01", "file": "broken_wall_window_01.png", "plane": "mid", "x": 1720.0, "y": 610.0, "scale": 0.78, "z": 25, "modulate": MID_SECONDARY},

	{"id": "battlement_crown_round_01", "file": "battlement_crown_round_01.png", "plane": "near", "x": 80.0, "y": 870.0, "scale": 0.72, "z": 30, "modulate": NEAR_COLOR},
	{"id": "broken_arch_heavy_01", "file": "broken_arch_heavy_01.png", "plane": "near", "x": 230.0, "y": 680.0, "scale": 0.72, "z": 31, "modulate": NEAR_COLOR},
	{"id": "battlement_crown_round_02", "file": "battlement_crown_round_02.png", "plane": "near", "x": 530.0, "y": 920.0, "scale": 0.70, "z": 32, "modulate": NEAR_COLOR},
	{"id": "raised_causeway_01", "file": "raised_causeway_01.png", "plane": "near", "x": 580.0, "y": 750.0, "scale": 0.95, "z": 33, "modulate": NEAR_COLOR},
	{"id": "stone_bridge_single_arch_01", "file": "stone_bridge_single_arch_01.png", "plane": "near", "x": 900.0, "y": 780.0, "scale": 0.92, "z": 34, "modulate": NEAR_COLOR},
	{"id": "battlement_crown_round_broken_01", "file": "battlement_crown_round_broken_01.png", "plane": "near", "x": 980.0, "y": 920.0, "scale": 0.70, "z": 35, "modulate": NEAR_COLOR},
	{"id": "raised_causeway_02", "file": "raised_causeway_02.png", "plane": "near", "x": 1260.0, "y": 760.0, "scale": 0.90, "z": 36, "modulate": NEAR_COLOR},
	{"id": "stone_bridge_double_arch_01", "file": "stone_bridge_double_arch_01.png", "plane": "near", "x": 1580.0, "y": 790.0, "scale": 0.88, "z": 37, "modulate": NEAR_COLOR},
	{"id": "battlement_crown_round_turreted_01", "file": "battlement_crown_round_turreted_01.png", "plane": "near", "x": 1560.0, "y": 900.0, "scale": 0.70, "z": 38, "modulate": NEAR_COLOR},
	{"id": "broken_arch_walkway_01", "file": "broken_arch_walkway_01.png", "plane": "near", "x": 1770.0, "y": 670.0, "scale": 0.70, "z": 39, "modulate": NEAR_COLOR},
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
			"disabled_for_primary_composition",
			not sprite.visible
		)
		parent.add_child(sprite)
		built += 1
	return built
