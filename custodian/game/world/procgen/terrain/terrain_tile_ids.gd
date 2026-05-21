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


static func industrial(key: String, fallback: String = "existing_floor") -> String:
	return String(INDUSTRIAL.get(key, fallback))


static func mountain(key: String, fallback: String = "existing_wall") -> String:
	return String(MOUNTAIN.get(key, fallback))
