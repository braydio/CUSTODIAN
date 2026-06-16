extends RefCounted
class_name WorldgenIntentNode

enum NodeKind {
	SPAWN,
	MAIN_ROUTE,
	ASCENT_BEAT,
	BRANCH,
	FACTION_SITE,
	STORY_ROOM,
	VISTA,
	RESOURCE_POCKET,
	SAFE_POCKET,
	SHORTCUT,
	EXIT_GATE,
}

var id: String = ""
var kind: NodeKind = NodeKind.MAIN_ROUTE
var cell: Vector2i = Vector2i.ZERO
var radius_tiles: int = 6
var band_id: String = ""
var style_id: String = ""
var faction_id: String = ""
var story_id: String = ""
var runtime_height: int = 0
var ascent_rank: int = 0
var required: bool = false
var tags: Array[String] = []


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"kind_name": kind_to_string(kind),
		"cell": cell,
		"radius_tiles": radius_tiles,
		"band_id": band_id,
		"style_id": style_id,
		"faction_id": faction_id,
		"story_id": story_id,
		"runtime_height": runtime_height,
		"ascent_rank": ascent_rank,
		"required": required,
		"tags": tags.duplicate(),
	}


static func kind_to_string(value: NodeKind) -> String:
	match value:
		NodeKind.SPAWN:
			return "spawn"
		NodeKind.ASCENT_BEAT:
			return "ascent_beat"
		NodeKind.BRANCH:
			return "branch"
		NodeKind.FACTION_SITE:
			return "faction_site"
		NodeKind.STORY_ROOM:
			return "story_room"
		NodeKind.VISTA:
			return "vista"
		NodeKind.RESOURCE_POCKET:
			return "resource_pocket"
		NodeKind.SAFE_POCKET:
			return "safe_pocket"
		NodeKind.SHORTCUT:
			return "shortcut"
		NodeKind.EXIT_GATE:
			return "exit_gate"
		_:
			return "main_route"
