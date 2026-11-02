extends RefCounted
class_name TerrainRegion

enum RegionKind {
	BASELINE,
	LABYRINTH_ROOM,
	LABYRINTH_CORRIDOR,
	MOUNTAIN_WALL,
	CHASM,
	INDUSTRIAL_PLATFORM,
	RAVINE_PATH,
	SWITCHBACK_TRAIL,
	RIDGE_TRAIL,
	RUINED_TERRACE,
	COLLAPSED_STAIR,
	CLIFF_FACE,
	ASCENT_ROUTE,
	FACTION_WORKSITE,
	FACTION_CAMP,
	STORY_ROOM,
	VISTA,
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
		RegionKind.LABYRINTH_ROOM:
			return "labyrinth_room"
		RegionKind.LABYRINTH_CORRIDOR:
			return "labyrinth_corridor"
		RegionKind.MOUNTAIN_WALL:
			return "mountain_wall"
		RegionKind.CHASM:
			return "chasm"
		RegionKind.INDUSTRIAL_PLATFORM:
			return "industrial_platform"
		RegionKind.RAVINE_PATH:
			return "ravine_path"
		RegionKind.SWITCHBACK_TRAIL:
			return "switchback_trail"
		RegionKind.RIDGE_TRAIL:
			return "ridge_trail"
		RegionKind.RUINED_TERRACE:
			return "ruined_terrace"
		RegionKind.COLLAPSED_STAIR:
			return "collapsed_stair"
		RegionKind.CLIFF_FACE:
			return "cliff_face"
		RegionKind.ASCENT_ROUTE:
			return "ascent_route"
		RegionKind.FACTION_WORKSITE:
			return "faction_worksite"
		RegionKind.FACTION_CAMP:
			return "faction_camp"
		RegionKind.STORY_ROOM:
			return "story_room"
		RegionKind.VISTA:
			return "vista"
		_:
			return "baseline"
