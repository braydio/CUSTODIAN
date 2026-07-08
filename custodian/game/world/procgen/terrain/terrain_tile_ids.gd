extends RefCounted
class_name TerrainTileIds

const INDUSTRIAL := {
	"ground": "ground_flat_32",
	"elevated_floor": "elevated_floor_32",
	"edge_north": "elevation_edge_north_32",
	"edge_south": "elevation_edge_south_32",
	"edge_east": "elevation_edge_east_32",
	"edge_west": "elevation_edge_west_32",
	"ramp_north": "ramp_north_32",
	"ramp_south": "ramp_south_32",
	"ramp_east": "ramp_east_32",
	"ramp_west": "ramp_west_32",
	"drop_shadow": "cliff_shadow_32",
	"stair": "stair_metal_32",
}

const MOUNTAIN := {
	"ground": "rock_ground_flat_32",
	"plateau": "rock_plateau_raised_32",
	"edge_north": "cliff_edge_north_32",
	"edge_south": "cliff_edge_south_32",
	"edge_east": "cliff_edge_east_32",
	"edge_west": "cliff_edge_west_32",
	"outer_nw": "cliff_outer_nw_32",
	"outer_ne": "cliff_outer_ne_32",
	"outer_sw": "cliff_outer_sw_32",
	"outer_se": "cliff_outer_se_32",
	"inner_nw": "cliff_inner_nw_32",
	"inner_ne": "cliff_inner_ne_32",
	"inner_sw": "cliff_inner_sw_32",
	"inner_se": "cliff_inner_se_32",
	"chasm": "cliff_chasm_drop_32",
	"wall": "mountain_wall_impassable_32",
}

const PLACEHOLDER := {
	"ground": "existing_floor",
	"blocked": "existing_wall",
}

const CONNECTOR := {
	"ground": "terrain_connector_ground_32",
	"cracked": "terrain_connector_cracked_32",
	"gravel": "terrain_connector_gravel_32",
	"dust": "terrain_connector_dust_32",
	"edge_north": "terrain_connector_edge_n_32",
	"edge_south": "terrain_connector_edge_s_32",
	"edge_east": "terrain_connector_edge_e_32",
	"edge_west": "terrain_connector_edge_w_32",
	"outer_corner_ne": "terrain_connector_outer_corner_ne_32",
	"outer_corner_nw": "terrain_connector_outer_corner_nw_32",
	"outer_corner_se": "terrain_connector_outer_corner_se_32",
	"outer_corner_sw": "terrain_connector_outer_corner_sw_32",
	"inner_corner_ne": "terrain_connector_inner_corner_ne_32",
	"inner_corner_nw": "terrain_connector_inner_corner_nw_32",
	"inner_corner_se": "terrain_connector_inner_corner_se_32",
	"inner_corner_sw": "terrain_connector_inner_corner_sw_32",
	"centerline": "terrain_connector_centerline_32",
	"broken_patch": "terrain_connector_broken_patch_32",
}

const ASCENT := {
	"landing_industrial": "terrain_landing_industrial_32",
	"landing_stone": "terrain_landing_stone_32",
	"ramp_north": "ramp_north_wide_32",
	"ramp_south": "ramp_south_wide_32",
	"ramp_east": "ramp_east_wide_32",
	"ramp_west": "ramp_west_wide_32",
	"ramp_north_broken": "ramp_north_broken_32",
	"ramp_south_broken": "ramp_south_broken_32",
	"ramp_east_broken": "ramp_east_broken_32",
	"ramp_west_broken": "ramp_west_broken_32",
	"stair_north_stone": "stair_north_stone_32",
	"stair_south_stone": "stair_south_stone_32",
	"stair_east_stone": "stair_east_stone_32",
	"stair_west_stone": "stair_west_stone_32",
	"stair_north_metal": "stair_north_metal_32",
	"stair_south_metal": "stair_south_metal_32",
	"stair_east_metal": "stair_east_metal_32",
	"stair_west_metal": "stair_west_metal_32",
	"threshold": "ascent_threshold_32",
	"lip_connector": "ascent_lip_connector_32",
}

const CHASM := {
	"void": "chasm_void_32",
	"edge_north": "chasm_edge_n_32",
	"edge_south": "chasm_edge_s_32",
	"edge_east": "chasm_edge_e_32",
	"edge_west": "chasm_edge_w_32",
	"outer_corner_ne": "chasm_outer_corner_ne_32",
	"outer_corner_nw": "chasm_outer_corner_nw_32",
	"outer_corner_se": "chasm_outer_corner_se_32",
	"outer_corner_sw": "chasm_outer_corner_sw_32",
	"inner_corner_ne": "chasm_inner_corner_ne_32",
	"inner_corner_nw": "chasm_inner_corner_nw_32",
	"inner_corner_se": "chasm_inner_corner_se_32",
	"inner_corner_sw": "chasm_inner_corner_sw_32",
	"collapsed_gap": "collapsed_gap_32",
	"broken_gap_edge": "broken_gap_edge_32",
}

const BRIDGE := {
	"stone_mid_horizontal": "bridge_stone_mid_horizontal_32",
	"stone_mid_vertical": "bridge_stone_mid_vertical_32",
	"start_north": "bridge_stone_start_n_32",
	"start_south": "bridge_stone_start_s_32",
	"start_east": "bridge_stone_start_e_32",
	"start_west": "bridge_stone_start_w_32",
	"metal_mid_horizontal": "bridge_metal_mid_horizontal_32",
	"metal_mid_vertical": "bridge_metal_mid_vertical_32",
	"broken_segment": "bridge_broken_segment_32",
}


static func industrial(key: String, fallback: String = "existing_floor") -> String:
	return String(INDUSTRIAL.get(key, fallback))


static func mountain(key: String, fallback: String = "existing_wall") -> String:
	return String(MOUNTAIN.get(key, fallback))


static func connector(key: String, fallback: String = "existing_floor") -> String:
	return String(CONNECTOR.get(key, fallback))


static func ascent(key: String, fallback: String = "existing_floor") -> String:
	return String(ASCENT.get(key, fallback))


static func chasm(key: String, fallback: String = "existing_wall") -> String:
	return String(CHASM.get(key, fallback))


static func bridge(key: String, fallback: String = "existing_floor") -> String:
	return String(BRIDGE.get(key, fallback))
