extends RefCounted
class_name WorldStyleBand

var id: String = "baseline"
var distance_min: int = 0
var distance_max: int = 999999
var height_bias: int = 0
var ascent_gain: int = 0
var style_weights: Dictionary = {}
var faction_presence: Dictionary = {}
var story_room_chance: float = 0.0


static func from_dictionary(data: Dictionary):
	var band = load("res://game/world/procgen/progression/world_style_band.gd").new()
	band.id = String(data.get("id", band.id))
	band.distance_min = int(data.get("distance_min", band.distance_min))
	band.distance_max = int(data.get("distance_max", band.distance_max))
	band.height_bias = int(data.get("height_bias", band.height_bias))
	band.ascent_gain = int(data.get("ascent_gain", band.ascent_gain))
	band.style_weights = (data.get("style_weights", {}) as Dictionary).duplicate(true)
	band.faction_presence = (data.get("faction_presence", {}) as Dictionary).duplicate(true)
	band.story_room_chance = float(data.get("story_room_chance", band.story_room_chance))
	return band


func contains_distance(distance_tiles: float) -> bool:
	return distance_tiles >= float(distance_min) and distance_tiles < float(distance_max)


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"distance_min": distance_min,
		"distance_max": distance_max,
		"height_bias": height_bias,
		"ascent_gain": ascent_gain,
		"style_weights": style_weights.duplicate(true),
		"faction_presence": faction_presence.duplicate(true),
		"story_room_chance": story_room_chance,
	}
