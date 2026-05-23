extends RefCounted
class_name GothicCompoundAssetDefs

const ROOT := "res://content/procgen/special_rooms/gothic_compound/"

const KIND_TILE := "tile"
const KIND_PROP := "prop"
const KIND_DECAL := "decal"
const KIND_MARKER := "marker"
const KIND_WALL := "wall"
const KIND_ROAD := "road"

const ANCHOR_TOP_LEFT := "top_left"
const Z_FLOOR := -100
const Z_ROAD := -90
const Z_DECAL := -80
const Z_WALL_STATIC := 10
const Z_PROP_STATIC := 12
const Z_OCCLUDER_FRONT := 1
const Z_OCCLUDER_BEHIND := 40

const ASSETS := {
	"terrain_ash_a": {"path": ROOT + "01_terrain_ash_base_dark_a.png", "kind": KIND_TILE, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_FLOOR},
	"terrain_ash_b": {"path": ROOT + "02_terrain_ash_base_dark_b.png", "kind": KIND_TILE, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_FLOOR},
	"terrain_ash_roots": {"path": ROOT + "03_terrain_ash_roots_cracked_a.png", "kind": KIND_TILE, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_FLOOR},
	"terrain_rocky_ash": {"path": ROOT + "05_terrain_rocky_ash_base_a.png", "kind": KIND_TILE, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_FLOOR},
	"terrain_cracked_rock_a": {"path": ROOT + "06_terrain_cracked_rock_base_a.png", "kind": KIND_TILE, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_FLOOR},
	"terrain_cracked_rock_b": {"path": ROOT + "07_terrain_cracked_rock_base_b.png", "kind": KIND_TILE, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_FLOOR},
	"terrain_stone_a": {"path": ROOT + "12_terrain_stone_cracked_base_a.png", "kind": KIND_TILE, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_FLOOR},
	"terrain_stone_b": {"path": ROOT + "13_terrain_stone_cracked_base_b.png", "kind": KIND_TILE, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_FLOOR},
	"terrain_stone_c": {"path": ROOT + "14_terrain_stone_cracked_base_c.png", "kind": KIND_TILE, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_FLOOR},
	"road_ns_a": {"path": ROOT + "16_road_straight_ns_a.png", "kind": KIND_ROAD, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_ROAD},
	"road_ns_b": {"path": ROOT + "17_road_straight_ns_b.png", "kind": KIND_ROAD, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_ROAD},
	"road_ns_cracked": {"path": ROOT + "21_road_straight_ns_cracked.png", "kind": KIND_ROAD, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_ROAD},
	"road_cross": {"path": ROOT + "29_road_cross_intersection.png", "kind": KIND_ROAD, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_ROAD},
	"road_ew_long": {"path": ROOT + "15_road_straight_ew_long.png", "kind": KIND_PROP, "footprint": Vector2i(4, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_ROAD},
	"gate_threshold_open": {"path": ROOT + "15_gate_threshold_open_walkable.png", "kind": KIND_ROAD, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_ROAD},
	"wall_h": {"path": ROOT + "01_wall_straight_w_pillar_conn_e.png", "kind": KIND_WALL, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_WALL_STATIC},
	"wall_h_b": {"path": ROOT + "25_wall_straight_conn_e_w_left_pillar.png", "kind": KIND_WALL, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_WALL_STATIC},
	"wall_h_damaged": {"path": ROOT + "06_wall_straight_damaged_conn_w_e.png", "kind": KIND_WALL, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_WALL_STATIC},
	"wall_h_broken": {"path": ROOT + "26_wall_broken_rubble_conn_w_e_left_pillar.png", "kind": KIND_WALL, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_WALL_STATIC},
	"wall_v": {"path": ROOT + "21_wall_straight_vertical_conn_n_s_large.png", "kind": KIND_WALL, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_WALL_STATIC},
	"wall_pillar": {"path": ROOT + "02_wall_pillar_spire_single.png", "kind": KIND_WALL, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_WALL_STATIC},
	"wall_corner_se": {"path": ROOT + "03_wall_corner_l_conn_s_e.png", "kind": KIND_WALL, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_WALL_STATIC},
	"wall_corner_sw": {"path": ROOT + "04_wall_corner_l_conn_s_w.png", "kind": KIND_WALL, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_WALL_STATIC},
	"wall_corner_spire": {"path": ROOT + "08_wall_corner_spire_conn_s_w.png", "kind": KIND_WALL, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_WALL_STATIC},
	"gatehouse_open": {"path": ROOT + "36_gatehouse_main_open_large.png", "kind": KIND_PROP, "footprint": Vector2i(7, 5), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_OCCLUDER_BEHIND, "depth_sort": true, "front_z": Z_OCCLUDER_FRONT, "behind_z": Z_OCCLUDER_BEHIND, "horizon_ratio": 0.82},
	"gate_lamp": {"path": ROOT + "13_lamp_post_amber.png", "kind": KIND_PROP, "footprint": Vector2i(1, 2), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_PROP_STATIC},
	"command_keep": {"path": ROOT + "01_structure_command_keep_gothic_large.png", "kind": KIND_PROP, "footprint": Vector2i(11, 10), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_OCCLUDER_BEHIND, "depth_sort": true, "front_z": Z_OCCLUDER_FRONT, "behind_z": Z_OCCLUDER_BEHIND, "horizon_ratio": 0.78},
	"utility_fan": {"path": ROOT + "02_structure_utility_fan_roof_block.png", "kind": KIND_PROP, "footprint": Vector2i(7, 8), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_OCCLUDER_BEHIND, "depth_sort": true, "front_z": Z_OCCLUDER_FRONT, "behind_z": Z_OCCLUDER_BEHIND, "horizon_ratio": 0.78},
	"machine_house": {"path": ROOT + "03_structure_machine_house_gothic_industrial.png", "kind": KIND_PROP, "footprint": Vector2i(7, 8), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_OCCLUDER_BEHIND, "depth_sort": true, "front_z": Z_OCCLUDER_FRONT, "behind_z": Z_OCCLUDER_BEHIND, "horizon_ratio": 0.78},
	"fountain": {"path": ROOT + "08_structure_dry_fountain_basin_octagonal.png", "kind": KIND_PROP, "footprint": Vector2i(4, 4), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_PROP_STATIC},
	"bell_frame": {"path": ROOT + "09_bell_frame_gothic_small.png", "kind": KIND_PROP, "footprint": Vector2i(4, 6), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_OCCLUDER_BEHIND, "depth_sort": true, "front_z": Z_OCCLUDER_FRONT, "behind_z": Z_OCCLUDER_BEHIND, "horizon_ratio": 0.75},
	"terminal": {"path": ROOT + "13_terminal_compound_control_console.png", "kind": KIND_PROP, "footprint": Vector2i(4, 4), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_PROP_STATIC},
	"sandbag_h": {"path": ROOT + "01_cover_sandbag_straight_h.png", "kind": KIND_PROP, "footprint": Vector2i(4, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_PROP_STATIC},
	"stone_cover_h": {"path": ROOT + "03_cover_stone_low_wall_h.png", "kind": KIND_PROP, "footprint": Vector2i(3, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_PROP_STATIC},
	"fence_long_h": {"path": ROOT + "04_fence_wrought_iron_long_h.png", "kind": KIND_PROP, "footprint": Vector2i(6, 2), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_PROP_STATIC},
	"spike_h": {"path": ROOT + "06_spike_barricade_h.png", "kind": KIND_PROP, "footprint": Vector2i(3, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_PROP_STATIC},
	"banner": {"path": ROOT + "16_banner_black_torn.png", "kind": KIND_PROP, "footprint": Vector2i(2, 5), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_OCCLUDER_BEHIND, "depth_sort": true, "front_z": Z_OCCLUDER_FRONT, "behind_z": Z_OCCLUDER_BEHIND, "horizon_ratio": 0.74},
	"rubble_s": {"path": ROOT + "19_rubble_pile_small.png", "kind": KIND_PROP, "footprint": Vector2i(2, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_PROP_STATIC},
	"rubble_m": {"path": ROOT + "20_rubble_pile_medium.png", "kind": KIND_PROP, "footprint": Vector2i(3, 3), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_PROP_STATIC},
	"dead_shrub": {"path": ROOT + "23_dead_shrub_small.png", "kind": KIND_PROP, "footprint": Vector2i(2, 2), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_PROP_STATIC},
	"dead_tree": {"path": ROOT + "25_dead_tree_large.png", "kind": KIND_PROP, "footprint": Vector2i(5, 6), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_OCCLUDER_BEHIND, "depth_sort": true, "front_z": Z_OCCLUDER_FRONT, "behind_z": Z_OCCLUDER_BEHIND, "horizon_ratio": 0.74},
	"collapsed_spire": {"path": ROOT + "42_collapsed_spire_ruin_large.png", "kind": KIND_PROP, "footprint": Vector2i(6, 7), "anchor": ANCHOR_TOP_LEFT, "blocks": true, "z": Z_OCCLUDER_BEHIND, "depth_sort": true, "front_z": Z_OCCLUDER_FRONT, "behind_z": Z_OCCLUDER_BEHIND, "horizon_ratio": 0.74},
	"resource_ruin_scrap": {"path": ROOT + "32_resource_node_ruin_scrap_gothic.png", "kind": KIND_PROP, "footprint": Vector2i(5, 4), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_PROP_STATIC},
	"resource_blackwood": {"path": ROOT + "33_resource_node_blackwood_deadfall_gothic.png", "kind": KIND_PROP, "footprint": Vector2i(7, 4), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_PROP_STATIC},
	"marker_spawn_plain": {"path": ROOT + "34_marker_hidden_spawn_x_plain.png", "kind": KIND_MARKER, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": 40},
	"marker_spawn_amber": {"path": ROOT + "35_marker_hidden_spawn_x_amber.png", "kind": KIND_MARKER, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": 40},
	"marker_spawn_stone": {"path": ROOT + "38_marker_hidden_spawn_stone_ring.png", "kind": KIND_MARKER, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": 40},
	"marker_spawn_ember": {"path": ROOT + "39_marker_hidden_spawn_ember_star.png", "kind": KIND_MARKER, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": 40},
	"grate_square": {"path": ROOT + "50_grate_square_metal.png", "kind": KIND_DECAL, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_DECAL},
	"grate_round": {"path": ROOT + "51_grate_round_metal.png", "kind": KIND_DECAL, "footprint": Vector2i(1, 1), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_DECAL},
	"floor_sigil": {"path": ROOT + "52_floor_sigil_stone_square.png", "kind": KIND_DECAL, "footprint": Vector2i(2, 2), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_DECAL},
	"light_pool": {"path": ROOT + "53_decal_light_pool_amber.png", "kind": KIND_DECAL, "footprint": Vector2i(3, 3), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_DECAL},
	"shadow_smoke": {"path": ROOT + "54_decal_shadow_smoke_dark.png", "kind": KIND_DECAL, "footprint": Vector2i(3, 3), "anchor": ANCHOR_TOP_LEFT, "blocks": false, "z": Z_DECAL},
}

static func get_asset(asset_id: String) -> Dictionary:
	var def: Dictionary = ASSETS.get(asset_id, {})
	if def.is_empty():
		push_warning("Unknown gothic compound asset id: %s" % asset_id)
	return def.duplicate(true)
