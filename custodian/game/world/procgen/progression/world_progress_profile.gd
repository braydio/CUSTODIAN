extends RefCounted
class_name WorldProgressProfile

const WorldStyleBandScript := preload("res://game/world/procgen/progression/world_style_band.gd")

var profile_id: String = "default"
var origin_cell: Vector2i = Vector2i.ZERO
var blend_width_tiles: int = 32
var bands: Array = []


static func load_from_path(path: String):
	var profile = load("res://game/world/procgen/progression/world_progress_profile.gd").new()
	if not FileAccess.file_exists(path):
		push_warning("WorldProgressProfile: missing profile at %s; using fallback." % path)
		profile.bands.append(WorldStyleBandScript.new())
		return profile
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("WorldProgressProfile: could not open profile at %s; using fallback." % path)
		profile.bands.append(WorldStyleBandScript.new())
		return profile
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning("WorldProgressProfile: invalid JSON at %s; using fallback." % path)
		profile.bands.append(WorldStyleBandScript.new())
		return profile
	var data := parsed as Dictionary
	profile.profile_id = String(data.get("id", profile.profile_id))
	var origin_value = data.get("origin_cell", [0, 0])
	if origin_value is Array and origin_value.size() >= 2:
		profile.origin_cell = Vector2i(int(origin_value[0]), int(origin_value[1]))
	profile.blend_width_tiles = int(data.get("blend_width_tiles", profile.blend_width_tiles))
	for raw_band in data.get("bands", []):
		if raw_band is Dictionary:
			profile.bands.append(WorldStyleBandScript.from_dictionary(raw_band))
	if profile.bands.is_empty():
		profile.bands.append(WorldStyleBandScript.new())
	return profile


func get_distance_tiles(cell: Vector2i) -> float:
	return float(cell.distance_to(origin_cell))


func get_band_for_distance(distance_tiles: float):
	for band in bands:
		if band.contains_distance(distance_tiles):
			return band
	return bands.back()


func get_cell_progress(cell: Vector2i, seed: int = 0) -> Dictionary:
	var distance_tiles := get_distance_tiles(cell)
	var band = get_band_for_distance(distance_tiles)
	return {
		"profile_id": profile_id,
		"origin_cell": origin_cell,
		"distance_tiles": distance_tiles,
		"band_id": band.id,
		"height_bias": band.height_bias,
		"ascent_gain": band.ascent_gain,
		"dominant_style": choose_weighted_key(band.style_weights, cell, seed, "style", "baseline"),
		"dominant_faction": choose_weighted_key(band.faction_presence, cell, seed, "faction", "none"),
		"style_weights": band.style_weights.duplicate(true),
		"faction_presence": band.faction_presence.duplicate(true),
		"story_room_chance": band.story_room_chance,
	}


func choose_weighted_key(weights: Dictionary, cell: Vector2i, seed: int, salt: String, fallback: String) -> String:
	if weights.is_empty():
		return fallback
	var total := 0.0
	for key in weights.keys():
		total += maxf(0.0, float(weights[key]))
	if total <= 0.0:
		return fallback
	var basis := "%s:%s:%d:%d:%d" % [profile_id, salt, seed, cell.x, cell.y]
	var roll := float((basis.hash() & 0x7fffffff) % 100000) / 100000.0 * total
	var running := 0.0
	var sorted_keys := weights.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		running += maxf(0.0, float(weights[key]))
		if roll <= running:
			return String(key)
	return String(sorted_keys.back())
