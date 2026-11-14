extends RefCounted
class_name StoryRoomPlacer

const StoryRoomTemplateScript := preload("res://game/world/procgen/story/story_room_template.gd")


func _default_templates() -> Array:
	return [
		StoryRoomTemplateScript.make("first_switchback_camp", ["broken_foothills", "slog_ascent"], "scavenger", Vector2i(12, 9), ["set_winch", "haul_crate", "sleep_camp"]),
		StoryRoomTemplateScript.make("erased_archive_wall", ["broken_foothills", "slog_ascent", "upper_exhaustion"], "iconoclast", Vector2i(11, 8), ["scrape_inscription", "index_relic"]),
		StoryRoomTemplateScript.make("machine_pilgrim_rest", ["slog_ascent", "upper_exhaustion"], "cult_mechanist", Vector2i(10, 10), ["pray_to_machine", "repair_wrong"]),
		StoryRoomTemplateScript.make("collapsed_stair_underpass", ["broken_foothills", "slog_ascent"], "", Vector2i(14, 8), ["collapsed_stair", "vista"]),
		StoryRoomTemplateScript.make("dead_patrol_overlook", ["slog_ascent", "upper_exhaustion"], "", Vector2i(10, 7), ["stand_watch", "dead_patrol"]),
	]


func place_story_rooms(context: Dictionary) -> Array[Dictionary]:
	var profile = context.get("world_progress_profile", null)
	if profile == null:
		return []
	var seed := int(context.get("seed", 0))
	var count := int(context.get("count", 6))
	var floor_cells := _normalize_cell_array(context.get("floor_cells", []))
	var blocked_lookup := _lookup(_normalize_cell_array(context.get("blocked_cells", [])))
	var required_lookup := _lookup(_normalize_cell_array(context.get("required_cells", [])))
	var faction_sites: Array = context.get("faction_sites", [])
	var candidates: Array[Vector2i] = []
	for cell in floor_cells:
		if blocked_lookup.has(cell) or required_lookup.has(cell):
			continue
		var progress: Dictionary = profile.get_cell_progress(cell, seed)
		if float(progress.get("distance_tiles", 0.0)) < 128.0:
			continue
		var roll := float(abs(("%d:%d:%d:story" % [seed, cell.x, cell.y]).hash()) % 100000) / 100000.0
		if roll <= float(progress.get("story_room_chance", 0.0)):
			candidates.append(cell)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return profile.get_distance_tiles(a) > profile.get_distance_tiles(b)
	)
	var templates := _default_templates()
	var rooms: Array[Dictionary] = []
	var occupied: Array[Vector2i] = []
	for cell in candidates:
		if rooms.size() >= count:
			break
		if not _far_enough(cell, occupied, 20):
			continue
		var progress: Dictionary = profile.get_cell_progress(cell, seed)
		var faction_id := _nearest_faction_site(cell, faction_sites)
		var template = _pick_template(templates, progress, faction_id, cell, seed)
		if template == null:
			continue
		rooms.append({
			"story_id": template.story_id,
			"cell": cell,
			"band_id": String(progress.get("band_id", "")),
			"dominant_style": String(progress.get("dominant_style", "")),
			"faction_id": faction_id,
			"footprint_tiles": template.footprint_tiles,
			"activity_tags": template.activity_tags.duplicate(),
			"metadata_only_v1": true,
		})
		occupied.append(cell)
	return rooms


func _pick_template(templates: Array, progress: Dictionary, faction_id: String, cell: Vector2i, seed: int):
	var valid: Array = []
	for template in templates:
		if template.accepts(progress, faction_id):
			valid.append(template)
	if valid.is_empty():
		return null
	return valid[int(abs(("%d:%d:%d:%s" % [seed, cell.x, cell.y, faction_id]).hash()) % valid.size())]


func _nearest_faction_site(cell: Vector2i, faction_sites: Array) -> String:
	var best_faction := ""
	var best_dist := INF
	for site in faction_sites:
		if not site is Dictionary:
			continue
		var dist := cell.distance_squared_to((site as Dictionary).get("cell", Vector2i.ZERO))
		if dist < best_dist:
			best_dist = dist
			best_faction = String((site as Dictionary).get("faction_id", ""))
	return best_faction


func _far_enough(cell: Vector2i, occupied: Array[Vector2i], min_distance_tiles: int) -> bool:
	for other in occupied:
		if cell.distance_squared_to(other) < min_distance_tiles * min_distance_tiles:
			return false
	return true


func _lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	for cell in cells:
		lookup[cell] = true
	return lookup


func _normalize_cell_array(value: Variant) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if value is Dictionary:
		for key in (value as Dictionary).keys():
			if key is Vector2i:
				cells.append(key)
	elif value is Array:
		for item in value:
			if item is Vector2i:
				cells.append(item)
	return cells
