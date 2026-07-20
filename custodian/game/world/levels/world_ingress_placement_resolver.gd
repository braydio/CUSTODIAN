class_name WorldIngressPlacementResolver
extends RefCounted


func resolve(
	placement: Dictionary,
	level_data: Dictionary,
	map_instance: Node,
	occupied_tiles: Array[Vector2i]
) -> Dictionary:
	var anchor := _resolve_anchor(placement, level_data)
	var minimum_spacing := maxi(1, int(placement.get("minimum_spacing_tiles", 10)))
	var search_radius := maxi(0, int(placement.get("search_radius_tiles", 14)))
	var candidates := _configured_candidates(anchor, placement)
	for radius in range(0, search_radius + 1):
		for offset in _ring_offsets(radius):
			candidates.append(anchor + offset)
	var seen: Dictionary = {}
	for tile in candidates:
		if seen.has(tile):
			continue
		seen[tile] = true
		if not _is_walkable(tile, level_data, map_instance):
			continue
		if _is_reserved(tile, level_data):
			continue
		if not _has_spacing(tile, occupied_tiles, minimum_spacing):
			continue
		return {"ok": true, "tile": tile, "anchor": anchor}
	return {
		"ok": false,
		"tile": Vector2i.ZERO,
		"anchor": anchor,
		"reason": "no valid tile within search radius",
	}


func _resolve_anchor(placement: Dictionary, level_data: Dictionary) -> Vector2i:
	var strategy := str(placement.get("strategy", "near_compound_ingress"))
	if strategy == "near_player_spawn" and level_data.get("player_spawn") is Vector2i:
		return level_data.get("player_spawn") as Vector2i
	var ingress_tiles: Array[Vector2i] = []
	for raw: Variant in level_data.get("compound_ingress", []):
		if raw is Vector2i:
			ingress_tiles.append(raw)
	ingress_tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	if not ingress_tiles.is_empty():
		return ingress_tiles[0]
	if level_data.get("player_spawn") is Vector2i:
		return level_data.get("player_spawn") as Vector2i
	return Vector2i.ZERO


func _configured_candidates(anchor: Vector2i, placement: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for raw: Variant in placement.get("offset_candidates_tiles", []):
		if raw is Vector2i:
			result.append(anchor + (raw as Vector2i))
		elif raw is Array and (raw as Array).size() >= 2:
			result.append(anchor + Vector2i(int(raw[0]), int(raw[1])))
	return result


func _ring_offsets(radius: int) -> Array[Vector2i]:
	if radius == 0:
		return [Vector2i.ZERO]
	var result: Array[Vector2i] = []
	for x in range(-radius, radius + 1):
		result.append(Vector2i(x, -radius))
		result.append(Vector2i(x, radius))
	for y in range(-radius + 1, radius):
		result.append(Vector2i(-radius, y))
		result.append(Vector2i(radius, y))
	return result


func _is_walkable(tile: Vector2i, level_data: Dictionary, map_instance: Node) -> bool:
	if map_instance != null:
		for method_name in [&"is_walkable_floor_tile", &"is_walkable_tile", &"is_floor_tile"]:
			if map_instance.has_method(method_name):
				return bool(map_instance.call(method_name, tile))
	var source: Array = level_data.get("floor_cells", [])
	if source.is_empty():
		source = level_data.get("random_floor_tiles", [])
	if source.is_empty():
		return true
	return source.has(tile)


func _is_reserved(tile: Vector2i, level_data: Dictionary) -> bool:
	for raw: Variant in level_data.get("reserved_world_ingress_tiles", []):
		if raw is Vector2i and raw == tile:
			return true
	for raw: Variant in level_data.get("reserved_regions", []):
		if raw is Rect2i and (raw as Rect2i).has_point(tile):
			return true
	return false


func _has_spacing(tile: Vector2i, occupied_tiles: Array[Vector2i], minimum_spacing: int) -> bool:
	var minimum_sq := minimum_spacing * minimum_spacing
	for occupied in occupied_tiles:
		if tile.distance_squared_to(occupied) < minimum_sq:
			return false
	return true
