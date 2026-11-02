extends RefCounted
class_name AbandonedStationPlacementPlanner

const MIN_SITE_DISTANCE_FROM_ROUTE := 2
const SERVICE_SPACING := 1
const MAX_CANDIDATE_ANCHORS := 256


static func plan(map: Node, level_data: Dictionary, seed_value: int) -> Dictionary:
	if map == null or not map.has_method("is_runtime_navigation_walkable"):
		return {}
	var candidates: Array[Vector2i] = []
	var seen: Dictionary = {}
	var source_tiles: Array = level_data.get("floor_cells", [])
	var playability: Dictionary = level_data.get("route_playability", {})
	var route_distance: Dictionary = playability.get("route_distance", {})
	for value in source_tiles:
		if not value is Vector2i:
			continue
		var tile := value as Vector2i
		if seen.has(tile) or not _walkable(map, tile):
			continue
		seen[tile] = true
		var distance_value: Variant = route_distance.get(tile, -1)
		if int(distance_value) < MIN_SITE_DISTANCE_FROM_ROUTE:
			continue
		if _reserved(map, tile, level_data) or not _has_escape_neighbors(map, tile):
			continue
		candidates.append(tile)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_hash := absi((a.x * 73856093) ^ (a.y * 19349663) ^ seed_value)
		var b_hash := absi((b.x * 73856093) ^ (b.y * 19349663) ^ seed_value)
		return a_hash < b_hash if a_hash != b_hash else a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	for anchor in candidates.slice(0, mini(candidates.size(), MAX_CANDIDATE_ANCHORS)):
		var services: Array[Vector2i] = []
		for offset in [Vector2i(-SERVICE_SPACING, 0), Vector2i(0, SERVICE_SPACING), Vector2i(SERVICE_SPACING, 0)]:
			var tile: Vector2i = anchor + (offset as Vector2i)
			if not _walkable(map, tile) or _reserved(map, tile, level_data) or not _has_escape_neighbors(map, tile):
				services.clear()
				break
			services.append(tile)
		if services.size() == 3:
			return {"anchor": anchor, "services": services, "seed": seed_value}
	return {}


static func _walkable(map: Node, tile: Vector2i) -> bool:
	if map.has_method("is_runtime_navigation_walkable"):
		return bool(map.call("is_runtime_navigation_walkable", tile))
	return false


static func _reserved(map: Node, tile: Vector2i, level_data: Dictionary) -> bool:
	if map.has_method("is_encounter_reserved_cell") and bool(map.call("is_encounter_reserved_cell", tile)):
		return true
	for region_value in level_data.get("worldgen_reserved_regions", []):
		if not region_value is Dictionary:
			continue
		var rect: Variant = (region_value as Dictionary).get("rect")
		if rect is Rect2i and (rect as Rect2i).has_point(tile):
			return true
	return false


static func _has_escape_neighbors(map: Node, tile: Vector2i) -> bool:
	if map.has_method("get_runtime_escape_neighbor_count"):
		return int(map.call("get_runtime_escape_neighbor_count", tile)) >= 2
	return true
