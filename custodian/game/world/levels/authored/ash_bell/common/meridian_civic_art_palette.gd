class_name MeridianCivicArtPalette
extends RefCounted

const FLOOR := {
	"civic_clean": [Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 1)], "civic_worn": [Vector2i(5, 0), Vector2i(6, 0), Vector2i(9, 1)],
	"civic_cracked": [Vector2i(10, 1), Vector2i(12, 1), Vector2i(3, 10)], "road": [Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)],
	"market": [Vector2i(4, 7), Vector2i(5, 7), Vector2i(7, 7)], "basin": [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)],
	"transit_marking": [Vector2i(2, 5), Vector2i(4, 5), Vector2i(9, 5)], "drain": [Vector2i(9, 2), Vector2i(9, 6), Vector2i(14, 10)],
	"rubble_dusted": [Vector2i(4, 10), Vector2i(5, 10), Vector2i(7, 10)],
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

static func choose(cells: Array, world_cell: Vector2i) -> Vector2i:
	var hash_value := absi(world_cell.x * 73856093 ^ world_cell.y * 19349663)
	return cells[hash_value % cells.size()] as Vector2i
