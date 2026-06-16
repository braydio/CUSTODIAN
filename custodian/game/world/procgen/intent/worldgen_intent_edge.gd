extends RefCounted
class_name WorldgenIntentEdge

enum EdgeKind {
	MAIN_ASCENT,
	BRANCH_PATH,
	SHORTCUT_LOCKED,
	RETURN_PATH,
	FACTION_APPROACH,
	STORY_APPROACH,
}

var id: String = ""
var from_id: String = ""
var to_id: String = ""
var kind: EdgeKind = EdgeKind.MAIN_ASCENT
var width_tiles: int = 5
var target_slope: int = 0
var tags: Array[String] = []


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"from_id": from_id,
		"to_id": to_id,
		"kind": kind,
		"kind_name": kind_to_string(kind),
		"width_tiles": width_tiles,
		"target_slope": target_slope,
		"tags": tags.duplicate(),
	}


static func kind_to_string(value: EdgeKind) -> String:
	match value:
		EdgeKind.BRANCH_PATH:
			return "branch_path"
		EdgeKind.SHORTCUT_LOCKED:
			return "shortcut_locked"
		EdgeKind.RETURN_PATH:
			return "return_path"
		EdgeKind.FACTION_APPROACH:
			return "faction_approach"
		EdgeKind.STORY_APPROACH:
			return "story_approach"
		_:
			return "main_ascent"
