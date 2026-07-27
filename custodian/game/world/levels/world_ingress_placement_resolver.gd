class_name WorldIngressPlacementResolver
extends RefCounted


func resolve(
	placement: Dictionary,
	level_data: Dictionary,
	map_instance: Node,
	occupied_tiles: Array[Vector2i]
) -> Dictionary:
	var strategy := str(
		placement.get("strategy", "near_compound_ingress")
	)
	if strategy == "north_edge_overlook":
		return _resolve_north_edge_overlook(
			placement,
			level_data,
			map_instance,
			occupied_tiles
		)
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


func _resolve_north_edge_overlook(
	placement: Dictionary,
	level_data: Dictionary,
	map_instance: Node,
	occupied_tiles: Array[Vector2i]
) -> Dictionary:
	var map_size := level_data.get(
		"map_size",
		Vector2i.ZERO
	) as Vector2i
	if map_size.x <= 0 or map_size.y <= 0:
		return {
			"ok": false,
			"reason": "north-edge overlook requires map_size",
		}

	var anchor := _resolve_anchor(
		{"strategy": "near_compound_ingress"},
		level_data
	)
	var max_edge_distance := maxi(
		2,
		int(placement.get("max_edge_distance_tiles", 8))
	)
	var approach_depth := maxi(
		4,
		int(placement.get("approach_depth_tiles", 10))
	)
	var lateral_search := maxi(
		4,
		int(placement.get("lateral_search_tiles", 28))
	)
	var minimum_spacing := maxi(
		1,
		int(placement.get("minimum_spacing_tiles", 10))
	)
	var candidates := _north_edge_candidates(
		map_size,
		max_edge_distance,
		level_data
	)
	candidates.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			if a.y != b.y:
				return a.y < b.y
			var a_lateral := absi(a.x - anchor.x)
			var b_lateral := absi(b.x - anchor.x)
			if a_lateral != b_lateral:
				return a_lateral < b_lateral
			return a.x < b.x
	)

	for candidate: Vector2i in candidates:
		if absi(candidate.x - anchor.x) > lateral_search:
			continue
		if not _is_walkable(candidate, level_data, map_instance):
			continue
		if _is_reserved(candidate, level_data):
			continue
		if not _has_spacing(
			candidate,
			occupied_tiles,
			minimum_spacing
		):
			continue
		if not _has_inward_corridor(
			candidate,
			Vector2i.DOWN,
			approach_depth,
			level_data,
			map_instance
		):
			continue
		return {
			"ok": true,
			"tile": candidate,
			"anchor": anchor,
			"outward_direction": Vector2i.UP,
			"edge_distance_tiles": candidate.y,
		}

	if map_instance != null and map_instance.has_method(
		"claim_world_overlook_pocket"
	):
		var authored_candidate := _best_north_edge_authoring_candidate(
			anchor,
			map_size,
			max_edge_distance,
			approach_depth,
			lateral_search,
			level_data,
			map_instance
		)
		var pocket_width := 9
		return {
			"ok": true,
			"tile": authored_candidate,
			"anchor": anchor,
			"outward_direction": Vector2i.UP,
			"edge_distance_tiles": authored_candidate.y,
			"requires_authored_pocket": true,
			"pocket_center_tile": (
				authored_candidate
				+ Vector2i.DOWN * int(approach_depth / 2)
			),
			"pocket_size_tiles": Vector2i(
				pocket_width,
				approach_depth
			),
		}

	return {
		"ok": false,
		"tile": Vector2i.ZERO,
		"anchor": anchor,
		"reason": "no valid north-edge overlook corridor",
	}


func _north_edge_candidates(
	map_size: Vector2i,
	max_edge_distance: int,
	level_data: Dictionary
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var floor_cells: Array = level_data.get("floor_cells", [])
	if floor_cells.is_empty():
		floor_cells = level_data.get("random_floor_tiles", [])
	for raw: Variant in floor_cells:
		if raw is Vector2i:
			var tile := raw as Vector2i
			if tile.y >= 0 and tile.y <= max_edge_distance:
				result.append(tile)
	if not result.is_empty():
		return result
	for y in range(0, mini(map_size.y, max_edge_distance + 1)):
		for x in range(map_size.x):
			result.append(Vector2i(x, y))
	return result


func _best_north_edge_authoring_candidate(
	anchor: Vector2i,
	map_size: Vector2i,
	max_edge_distance: int,
	approach_depth: int,
	lateral_search: int,
	level_data: Dictionary,
	map_instance: Node
) -> Vector2i:
	var pocket_half_width := 4
	var min_x := maxi(
		pocket_half_width + 1,
		anchor.x - lateral_search
	)
	var max_x := mini(
		map_size.x - pocket_half_width - 2,
		anchor.x + lateral_search
	)
	var best := Vector2i(
		clampi(anchor.x, min_x, max_x),
		max_edge_distance
	)
	var best_score := -1
	for x in range(min_x, max_x + 1):
		var score := 0
		for step in range(approach_depth):
			if _is_walkable(
				Vector2i(x, max_edge_distance + step),
				level_data,
				map_instance
			):
				score += 1
		if (
			score > best_score
			or (
				score == best_score
				and absi(x - anchor.x) < absi(best.x - anchor.x)
			)
		):
			best_score = score
			best = Vector2i(x, max_edge_distance)
	return best


func _has_inward_corridor(
	origin: Vector2i,
	inward_direction: Vector2i,
	depth: int,
	level_data: Dictionary,
	map_instance: Node
) -> bool:
	var walkable_count := 0
	for step: int in range(depth):
		var tile := origin + inward_direction * step
		if _is_walkable(tile, level_data, map_instance):
			walkable_count += 1
	return walkable_count >= ceili(float(depth) * 0.80)


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
