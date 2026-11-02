extends RefCounted
class_name StoryRoomTemplate

var story_id: String = "unknown"
var allowed_bands: Array[String] = []
var required_faction: String = ""
var footprint_tiles: Vector2i = Vector2i(10, 8)
var activity_tags: Array[String] = []


static func make(id: String, bands: Array[String], faction: String, footprint: Vector2i, tags: Array[String]):
	var template = load("res://game/world/procgen/story/story_room_template.gd").new()
	template.story_id = id
	template.allowed_bands = bands.duplicate()
	template.required_faction = faction
	template.footprint_tiles = footprint
	template.activity_tags = tags.duplicate()
	return template


func accepts(progress: Dictionary, faction_id: String) -> bool:
	var band_id := String(progress.get("band_id", ""))
	if not allowed_bands.is_empty() and not allowed_bands.has(band_id):
		return false
	return required_faction.is_empty() or required_faction == faction_id
