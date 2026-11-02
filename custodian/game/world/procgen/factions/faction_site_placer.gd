extends RefCounted
class_name FactionSitePlacer

const FactionActivitySiteScript := preload("res://game/world/procgen/factions/faction_activity_site.gd")
const ACTIVITIES := {
	"iconoclast": ["scrape_inscription", "index_relic", "stand_watch", "burn_archive", "mark_false_history"],
	"cult_mechanist": ["pray_to_machine", "carry_cable", "repair_wrong", "polish_relic", "chant_into_broken_comm"],
	"scavenger": ["haul_crate", "sleep_camp", "argue_over_salvage", "cook_near_scrap_fire", "set_winch"],
}


func place_sites(context: Dictionary) -> Array[Dictionary]:
	var profile = context.get("world_progress_profile", null)
	if profile == null:
		return []
	var seed := int(context.get("seed", 0))
	var count := int(context.get("count", 12))
	var floor_cells := _normalize_cell_array(context.get("floor_cells", []))
	var blocked_lookup := _lookup(_normalize_cell_array(context.get("blocked_cells", [])))
	var required_lookup := _lookup(_normalize_cell_array(context.get("required_cells", [])))
	var candidates: Array[Vector2i] = []
	for cell in floor_cells:
		if blocked_lookup.has(cell) or required_lookup.has(cell):
			continue
		var progress: Dictionary = profile.get_cell_progress(cell, seed)
		if String(progress.get("dominant_faction", "none")) == "none" or float(progress.get("distance_tiles", 0.0)) < 96.0:
			continue
		candidates.append(cell)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return ("%d:%d:%d" % [seed, a.x, a.y]).hash() < ("%d:%d:%d" % [seed, b.x, b.y]).hash()
	)
	var sites: Array[Dictionary] = []
	var occupied: Array[Vector2i] = []
	for cell in candidates:
		if sites.size() >= count:
			break
		if not _far_enough(cell, occupied, 14):
			continue
		var progress: Dictionary = profile.get_cell_progress(cell, seed)
		var faction := String(progress.get("dominant_faction", "none"))
		var activity := _pick_activity(faction, cell, seed)
		var site := FactionActivitySiteScript.new()
		site.site_id = "%s_%s_%d_%d" % [faction, activity, cell.x, cell.y]
		site.faction_id = faction
		site.activity_id = activity
		site.cell = cell
		site.band_id = String(progress.get("band_id", "unknown"))
		site.style_id = String(progress.get("dominant_style", "unknown"))
		site.radius_tiles = 4 + int(abs(("%s:%d:%d" % [faction, cell.x, cell.y]).hash()) % 3)
		sites.append(site.to_dictionary())
		occupied.append(cell)
	return sites


func _pick_activity(faction: String, cell: Vector2i, seed: int) -> String:
	var activities: Array = ACTIVITIES.get(faction, ["ambient"])
	return String(activities[int(abs(("%s:%d:%d:%d" % [faction, seed, cell.x, cell.y]).hash()) % activities.size())])


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
