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

const WALL := {
	"wall_straight": [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4)], "wall_corner": [Vector2i(1, 2), Vector2i(6, 3), Vector2i(0, 5)],
	"retaining": [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], "arcade": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
	"parapet": [Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5)], "service_wall": [Vector2i(0, 9), Vector2i(1, 9), Vector2i(2, 9)],
	"damaged_wall": [Vector2i(0, 10), Vector2i(1, 10), Vector2i(2, 10)], "rail_edge": [Vector2i(7, 7), Vector2i(8, 7), Vector2i(9, 7)],
}
const PROPS := {
	"lamp": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(3, 1)], "amber_warning_lamp": [Vector2i(4, 1), Vector2i(6, 1), Vector2i(8, 1)],
	"railing": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(4, 0)], "bollard": [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4)],
	"bench": [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)], "utility_box": [Vector2i(0, 2), Vector2i(2, 2), Vector2i(5, 2)],
	"barrier": [Vector2i(7, 4), Vector2i(8, 4), Vector2i(10, 4)], "drain": [Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5)],
	"tram_piece": [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], "speaker": [Vector2i(12, 2), Vector2i(13, 2), Vector2i(14, 2)],
	"containment_banner": [Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2)], "rubble": [Vector2i(8, 10), Vector2i(10, 10), Vector2i(13, 11)],
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
