extends RefCounted
class_name TerrainRegion

enum RegionKind {
	BASELINE,
	MOUNTAIN_WALL,
	CHASM,
	INDUSTRIAL_PLATFORM,
}

var kind: RegionKind = RegionKind.BASELINE
var rect: Rect2i = Rect2i()
var cells: Array[Vector2i] = []
var access_cells: Array[Vector2i] = []
var discarded: bool = false
var reason: String = ""


func _init(
	p_kind: RegionKind = RegionKind.BASELINE,
	p_rect: Rect2i = Rect2i(),
	p_cells: Array[Vector2i] = [],
	p_access_cells: Array[Vector2i] = []
) -> void:
	kind = p_kind
	rect = p_rect
	cells = p_cells.duplicate()
	access_cells = p_access_cells.duplicate()


func to_dictionary() -> Dictionary:
	return {
		"kind": kind,
		"kind_name": kind_to_string(kind),
		"rect": rect,
		"cells": cells.duplicate(),
		"access_cells": access_cells.duplicate(),
		"discarded": discarded,
		"reason": reason,
	}


static func kind_to_string(value: RegionKind) -> String:
	match value:
		RegionKind.MOUNTAIN_WALL:
			return "mountain_wall"
		RegionKind.CHASM:
			return "chasm"
		RegionKind.INDUSTRIAL_PLATFORM:
			return "industrial_platform"
		_:
			return "baseline"
