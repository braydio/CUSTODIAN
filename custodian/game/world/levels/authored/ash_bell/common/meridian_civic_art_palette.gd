class_name MeridianCivicArtPalette
extends RefCounted

const BASE_CIVIC := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(10, 0), Vector2i(8, 1), Vector2i(11, 1), Vector2i(12, 1),
	Vector2i(0, 2), Vector2i(10, 2),
]
# The live source atlas gives two members of the semantic base family a large
# structural cutout. Retain them in BASE_CIVIC for authored infrastructure,
# but keep continuous generic fields on the eight visually quiet slabs.
const BASE_CIVIC_FIELD := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(10, 0), Vector2i(11, 1), Vector2i(12, 1), Vector2i(0, 2),
]
const BASE_CIVIC_STRUCTURAL := [Vector2i(8, 1), Vector2i(10, 2)]
const WORN_CIVIC := [
	Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
]
const MARKET_GROUND := [
	Vector2i(0, 8), Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8),
	Vector2i(4, 8), Vector2i(5, 8), Vector2i(6, 8), Vector2i(7, 8),
	Vector2i(8, 8), Vector2i(9, 8), Vector2i(10, 8), Vector2i(11, 8),
	Vector2i(12, 8), Vector2i(13, 8), Vector2i(14, 8), Vector2i(15, 8),
	Vector2i(0, 9), Vector2i(1, 9), Vector2i(2, 9), Vector2i(3, 9),
	Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9), Vector2i(7, 9),
	Vector2i(8, 9), Vector2i(9, 9), Vector2i(10, 9), Vector2i(11, 9),
	Vector2i(12, 9), Vector2i(13, 9), Vector2i(15, 9),
]
const ROAD_BASE := [
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5),
	Vector2i(11, 5), Vector2i(12, 5),
]
const TRANSIT_MARKINGS := [
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4),
	Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4),
	Vector2i(8, 4), Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4),
	Vector2i(12, 4), Vector2i(13, 4), Vector2i(14, 4), Vector2i(15, 4),
	Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5),
	Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 5), Vector2i(13, 5),
	Vector2i(14, 5), Vector2i(15, 5),
]
const CIVIC_ACCENTS := [
	Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7),
	Vector2i(4, 7), Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7),
	Vector2i(8, 7), Vector2i(9, 7), Vector2i(10, 7), Vector2i(11, 7),
	Vector2i(12, 7),
]

# Detail cells are overlays only. They are intentionally absent from every
# full-field ground pool.
const SERVICE_DETAILS := [Vector2i(9, 2), Vector2i(9, 6), Vector2i(14, 10)]
const TECHNICAL_DETAILS := [
	Vector2i(1, 12), Vector2i(4, 12), Vector2i(7, 12),
	Vector2i(2, 13), Vector2i(6, 13), Vector2i(10, 13),
]

const FLOOR := {
	"base_civic": BASE_CIVIC,
	"worn_civic": WORN_CIVIC,
	"market_ground": MARKET_GROUND,
	"road_base": ROAD_BASE,
	"transit_markings": TRANSIT_MARKINGS,
	"civic_accents": CIVIC_ACCENTS,
	"service_details": SERVICE_DETAILS,
	"technical_details": TECHNICAL_DETAILS,
}

# Reviewed 16x16 wall-atlas semantics. These cells are transparent facade and
# perimeter modules, not solid 32px building voxels.
const WALL_TOP_STRAIGHT := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(4, 0), Vector2i(13, 0), Vector2i(14, 0), Vector2i(15, 0)]
const WALL_TOP_CORNERS := [Vector2i(2, 0), Vector2i(3, 0), Vector2i(7, 0)]
const WALL_TOP_JUNCTIONS := [Vector2i(6, 0), Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0)]
const WALL_TOP_PILLARS := [Vector2i(12, 0)]
const WALL_ARCH_FACADES := [
	Vector2i(0, 1), Vector2i(2, 1), Vector2i(4, 1), Vector2i(12, 1), Vector2i(13, 1),
	Vector2i(0, 9), Vector2i(1, 9), Vector2i(2, 9), Vector2i(3, 9), Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9), Vector2i(7, 9),
	Vector2i(8, 9), Vector2i(9, 9), Vector2i(10, 9), Vector2i(11, 9), Vector2i(12, 9), Vector2i(13, 9), Vector2i(14, 9), Vector2i(15, 9),
]
const WALL_SERVICE_FACADES := [
	Vector2i(1, 1), Vector2i(3, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1), Vector2i(11, 1), Vector2i(14, 1), Vector2i(15, 1),
	Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7), Vector2i(9, 7), Vector2i(10, 7), Vector2i(11, 7), Vector2i(12, 7), Vector2i(13, 7), Vector2i(14, 7), Vector2i(15, 7),
	Vector2i(0, 8), Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8), Vector2i(10, 8), Vector2i(11, 8), Vector2i(12, 8), Vector2i(13, 8), Vector2i(14, 8), Vector2i(15, 8),
]
const WALL_RETAINING_FACES := [
	Vector2i(1, 4), Vector2i(2, 4), Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4), Vector2i(12, 4), Vector2i(13, 4), Vector2i(14, 4),
	Vector2i(0, 5), Vector2i(2, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 5), Vector2i(11, 5), Vector2i(12, 5), Vector2i(13, 5), Vector2i(14, 5), Vector2i(15, 5),
	Vector2i(3, 12), Vector2i(4, 12), Vector2i(5, 12), Vector2i(6, 12), Vector2i(9, 12), Vector2i(10, 12), Vector2i(11, 12), Vector2i(12, 12), Vector2i(15, 12),
	Vector2i(7, 13), Vector2i(9, 13), Vector2i(10, 13), Vector2i(11, 13), Vector2i(13, 13),
]
const WALL_RAIL_EDGES := [
	Vector2i(8, 3), Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 3), Vector2i(12, 3), Vector2i(13, 3), Vector2i(14, 3), Vector2i(15, 3),
	Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4), Vector2i(12, 4), Vector2i(13, 4), Vector2i(14, 4), Vector2i(15, 4),
	Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 5), Vector2i(11, 5), Vector2i(12, 5), Vector2i(13, 5), Vector2i(14, 5), Vector2i(15, 5),
	Vector2i(0, 13), Vector2i(1, 13), Vector2i(2, 13), Vector2i(3, 13), Vector2i(4, 13),
	Vector2i(0, 14), Vector2i(1, 14), Vector2i(2, 14), Vector2i(3, 14), Vector2i(4, 14), Vector2i(5, 14), Vector2i(6, 14), Vector2i(7, 14), Vector2i(8, 14),
	Vector2i(0, 15), Vector2i(1, 15), Vector2i(2, 15), Vector2i(3, 15), Vector2i(4, 15), Vector2i(5, 15), Vector2i(6, 15), Vector2i(7, 15), Vector2i(8, 15),
]
const WALL_DAMAGED := [
	Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6),
	Vector2i(2, 10), Vector2i(3, 10), Vector2i(4, 10), Vector2i(5, 10), Vector2i(6, 10), Vector2i(7, 10), Vector2i(10, 10), Vector2i(11, 10), Vector2i(12, 10), Vector2i(13, 10),
	Vector2i(0, 11), Vector2i(2, 11), Vector2i(3, 11), Vector2i(4, 11), Vector2i(2, 12), Vector2i(5, 13),
]
const WALL_STAIRS_RAMPS := [Vector2i(1, 5), Vector2i(7, 12), Vector2i(6, 13)]
const WALL_CURVES := [Vector2i(7, 2), Vector2i(0, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(8, 12), Vector2i(13, 12), Vector2i(14, 12), Vector2i(8, 13), Vector2i(12, 13)]
const WALL := {
	"wall_straight": WALL_RETAINING_FACES, "wall_corner": WALL_CURVES,
	"retaining": WALL_RETAINING_FACES, "arcade": WALL_ARCH_FACADES,
	"parapet": WALL_RAIL_EDGES, "service_wall": WALL_SERVICE_FACADES,
	"damaged_wall": WALL_DAMAGED, "rail_edge": WALL_RAIL_EDGES,
	"top_straight": WALL_TOP_STRAIGHT, "top_corner": WALL_TOP_CORNERS,
	"top_junction": WALL_TOP_JUNCTIONS, "top_pillar": WALL_TOP_PILLARS,
	"arch_facade": WALL_ARCH_FACADES, "service_facade": WALL_SERVICE_FACADES,
	"stairs_ramp": WALL_STAIRS_RAMPS, "curve": WALL_CURVES,
}

# The original prop atlas already has good alpha. Keep it rather than using the
# destructive alpha-clean derivative.
const PROP_STRUCTURAL_POSTS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(3, 0), Vector2i(5, 0)]
const PROP_RAILING_SEGMENTS := [Vector2i(2, 0), Vector2i(4, 0), Vector2i(6, 0), Vector2i(11, 0), Vector2i(12, 0)]
const PROP_STRUCTURAL_TRANSITIONS := [Vector2i(7, 0), Vector2i(9, 0), Vector2i(13, 0), Vector2i(14, 0), Vector2i(15, 0)]
const PROP_LAMPS := [Vector2i(0, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(9, 1), Vector2i(10, 1)]
const PROP_AMBER_LAMPS := [Vector2i(1, 1), Vector2i(7, 1), Vector2i(8, 1), Vector2i(11, 1), Vector2i(12, 1), Vector2i(13, 1), Vector2i(14, 1), Vector2i(15, 1)]
const PROP_SIGN_FRAMES := [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(15, 2)]
const PROP_BANNERS := [Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2), Vector2i(11, 2)]
const PROP_INFO_TERMINALS := [Vector2i(12, 2), Vector2i(13, 2), Vector2i(14, 2)]
const PROP_UTILITY_BOXES := [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3), Vector2i(10, 3), Vector2i(11, 3)]
const PROP_CAMERAS := [Vector2i(12, 3), Vector2i(13, 3), Vector2i(14, 3), Vector2i(15, 3)]
const PROP_BENCHES := [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
const PROP_WASTE_RECEPTACLES := [Vector2i(4, 4), Vector2i(5, 4)]
const PROP_CHAIN_BARRIERS := [Vector2i(6, 4), Vector2i(9, 4), Vector2i(13, 4)]
const PROP_BOLLARDS := [Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5), Vector2i(15, 5)]
const PROP_BARRIERS := [Vector2i(3, 5), Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5), Vector2i(11, 5), Vector2i(12, 5), Vector2i(13, 5), Vector2i(14, 5)]
const PROP_CONES := [Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5), Vector2i(10, 5)]
const PROP_DRAINS := [Vector2i(0, 6), Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6)]
const PROP_SERVICE_HATCHES := [Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6)]
const PROP_WORK_LIGHTS := [Vector2i(12, 6), Vector2i(13, 6), Vector2i(14, 6), Vector2i(15, 6)]
const PROP_PIPE_MODULES := [
	Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7),
	Vector2i(0, 8), Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4, 8), Vector2i(5, 8), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8), Vector2i(15, 8),
]
const PROP_PIPE_CURVES := [Vector2i(11, 7), Vector2i(14, 8)]
const PROP_TECHNICAL_PLATES := [
	Vector2i(4, 7), Vector2i(9, 7), Vector2i(10, 7), Vector2i(9, 8), Vector2i(10, 8), Vector2i(11, 8), Vector2i(12, 8), Vector2i(13, 8),
	Vector2i(0, 9), Vector2i(1, 9), Vector2i(2, 9), Vector2i(3, 9), Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9), Vector2i(7, 9), Vector2i(8, 9), Vector2i(9, 9), Vector2i(10, 9), Vector2i(11, 9), Vector2i(12, 9), Vector2i(13, 9), Vector2i(14, 9), Vector2i(15, 9),
	Vector2i(0, 10), Vector2i(1, 10), Vector2i(2, 10), Vector2i(3, 10), Vector2i(4, 10), Vector2i(5, 10), Vector2i(6, 10), Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10), Vector2i(10, 10), Vector2i(11, 10),
]
const PROP_BASIN_FIXTURES := [Vector2i(0, 11), Vector2i(1, 11), Vector2i(2, 11), Vector2i(3, 11), Vector2i(4, 11), Vector2i(5, 11), Vector2i(6, 11), Vector2i(7, 11), Vector2i(8, 11), Vector2i(9, 11)]
const PROP_PLANTERS := [Vector2i(10, 11), Vector2i(11, 11), Vector2i(12, 11), Vector2i(13, 11), Vector2i(14, 11), Vector2i(15, 11), Vector2i(0, 12), Vector2i(1, 12), Vector2i(2, 12), Vector2i(3, 12), Vector2i(4, 12), Vector2i(5, 12), Vector2i(6, 12), Vector2i(7, 12)]
const PROP_CRATES := [Vector2i(0, 13), Vector2i(1, 13), Vector2i(2, 13), Vector2i(3, 13), Vector2i(4, 13), Vector2i(5, 13), Vector2i(6, 13), Vector2i(7, 13), Vector2i(0, 14), Vector2i(1, 14), Vector2i(2, 14)]
const PROP_CANISTERS := [Vector2i(8, 13), Vector2i(9, 13), Vector2i(10, 13), Vector2i(11, 13), Vector2i(12, 13)]
const PROP_RUBBLE := [
	Vector2i(8, 12), Vector2i(9, 12), Vector2i(10, 12), Vector2i(11, 12), Vector2i(12, 12), Vector2i(13, 12), Vector2i(14, 12), Vector2i(15, 12),
	Vector2i(13, 13), Vector2i(14, 13), Vector2i(15, 13), Vector2i(3, 14), Vector2i(4, 14), Vector2i(5, 14), Vector2i(6, 14), Vector2i(7, 14), Vector2i(8, 14), Vector2i(9, 14), Vector2i(10, 14), Vector2i(11, 14), Vector2i(13, 14), Vector2i(14, 14), Vector2i(15, 14),
	Vector2i(0, 15), Vector2i(1, 15), Vector2i(2, 15), Vector2i(3, 15), Vector2i(4, 15), Vector2i(5, 15), Vector2i(6, 15), Vector2i(7, 15), Vector2i(8, 15), Vector2i(9, 15), Vector2i(10, 15), Vector2i(11, 15), Vector2i(12, 15), Vector2i(13, 15), Vector2i(14, 15), Vector2i(15, 15),
]
const PROP_TIMBER := [Vector2i(12, 14)]
const PROPS := {
	"lamp": PROP_LAMPS, "amber_warning_lamp": PROP_AMBER_LAMPS,
	"railing": PROP_RAILING_SEGMENTS, "bollard": PROP_BOLLARDS,
	"bench": PROP_BENCHES, "utility_box": PROP_UTILITY_BOXES,
	"barrier": PROP_BARRIERS, "drain": PROP_DRAINS,
	"tram_piece": PROP_TECHNICAL_PLATES, "speaker": PROP_INFO_TERMINALS,
	"containment_banner": PROP_BANNERS, "rubble": PROP_RUBBLE,
	"structural_post": PROP_STRUCTURAL_POSTS, "structural_transition": PROP_STRUCTURAL_TRANSITIONS,
	"sign_frame": PROP_SIGN_FRAMES, "info_terminal": PROP_INFO_TERMINALS,
	"camera": PROP_CAMERAS, "waste_receptacle": PROP_WASTE_RECEPTACLES,
	"chain_barrier": PROP_CHAIN_BARRIERS, "cone": PROP_CONES,
	"service_hatch": PROP_SERVICE_HATCHES, "work_light": PROP_WORK_LIGHTS,
	"pipe": PROP_PIPE_MODULES, "pipe_curve": PROP_PIPE_CURVES,
	"technical_plate": PROP_TECHNICAL_PLATES, "basin_fixture": PROP_BASIN_FIXTURES,
	"planter": PROP_PLANTERS, "crate": PROP_CRATES, "canister": PROP_CANISTERS,
	"timber": PROP_TIMBER,
}
const OVERLAP := {
	"imported_floor": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(4, 0)], "imported_curb": [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4)],
	"imported_wall": [Vector2i(0, 7), Vector2i(2, 7), Vector2i(4, 7)], "imported_stair": [Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4)],
	"imported_service_channel": [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)], "imported_track": [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)],
	"seam": [Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5)], "damaged_import": [Vector2i(0, 10), Vector2i(3, 10), Vector2i(8, 11)],
}


static func choose(cells: Array, world_cell: Vector2i, salt: int = 0) -> Vector2i:
	var hash_value := _stable_hash(world_cell, salt)
	return cells[hash_value % cells.size()] as Vector2i


static func choose_normal_civic(world_cell: Vector2i) -> Vector2i:
	# Normal paving is approximately 88% clean / 12% worn. Authored special
	# zones supply the remaining map-level material diversity.
	if _stable_hash(world_cell, 0x41c1) % 100 < 88:
		return choose(BASE_CIVIC_FIELD, world_cell, 0x21a7)
	return choose(WORN_CIVIC, world_cell, 0x7b19)


static func _stable_hash(cell: Vector2i, salt: int) -> int:
	return absi(cell.x * 73856093 ^ cell.y * 19349663 ^ salt * 83492791)
