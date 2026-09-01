class_name WorldIngressPlacementResolver
extends RefCounted


func resolve(
	placement: Dictionary,
	level_data: Dictionary,
	map_instance: Node,
	occupied_tiles: Array[Vector2i],
	rejected_tiles: Array[Vector2i] = []
) -> Dictionary:
	var strategy := str(
		placement.get("strategy", "near_compound_ingress")
	)
	if strategy == "procgen_landmark_terminal":
		return _resolve_procgen_landmark_terminal(
			placement,
			level_data,
			map_instance,
			occupied_tiles
		)
	if strategy in ["edge_overlook", "north_edge_overlook"]:
		return _resolve_edge_overlook(
			placement,
			level_data,
			map_instance,
			occupied_tiles,
			rejected_tiles
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


func _resolve_procgen_landmark_terminal(
	placement: Dictionary,
	level_data: Dictionary,
	map_instance: Node,
	occupied_tiles: Array[Vector2i]
) -> Dictionary:
	var landmark_key := str(
		placement.get("landmark_data_key", "sundered_keep_frontage")
	)
	var frontage: Dictionary = level_data.get(landmark_key, {})
	if frontage.is_empty():
		return {
			"ok": false,
			"reason": "missing generated landmark data: %s" % landmark_key,
		}
	var gate_variant: Variant = frontage.get("gate_anchor")
	if not gate_variant is Vector2i:
		return {
			"ok": false,
			"reason": "generated landmark has no gate_anchor",
		}
	var gate_anchor := gate_variant as Vector2i
	if not _is_walkable(gate_anchor, level_data, map_instance):
		return {
			"ok": false,
			"tile": gate_anchor,
			"reason": "generated landmark gate_anchor is not walkable",
		}
	var minimum_spacing := maxi(
		1,
		int(placement.get("minimum_spacing_tiles", 10))
	)
	if not _has_spacing(
		gate_anchor,
		occupied_tiles,
		minimum_spacing
	):
		return {
			"ok": false,
			"tile": gate_anchor,
			"reason": "generated landmark gate_anchor violates ingress spacing",
		}
	var outward: Variant = frontage.get(
		"fortress_outward_direction",
		Vector2i.UP
	)
	return {
		"ok": true,
		"tile": gate_anchor,
		"anchor": frontage.get("overlook_anchor", gate_anchor),
		"outward_direction": (
			outward as Vector2i if outward is Vector2i else Vector2i.UP
		),
		"edge_distance_tiles": gate_anchor.y,
		"generated_landmark_id": frontage.get(
			"landmark_id",
			StringName(landmark_key)
		),
		"generated_terminal_anchor": true,
		"requires_authored_pocket": false,
	}


func _resolve_edge_overlook(
	placement: Dictionary,
	level_data: Dictionary,
	map_instance: Node,
	occupied_tiles: Array[Vector2i],
	rejected_tiles: Array[Vector2i] = []
) -> Dictionary:
	var map_size := level_data.get(
		"map_size",
		Vector2i.ZERO
	) as Vector2i
	if map_size.x <= 0 or map_size.y <= 0:
		return {
			"ok": false,
			"reason": "edge overlook requires map_size",
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
	var candidate_attempt_limit := maxi(
		1,
		int(placement.get("candidate_attempt_limit", lateral_search * 2 + 1))
	)
	var minimum_spacing := maxi(
		1,
		int(placement.get("minimum_spacing_tiles", 10))
	)
	var allowed_edges := _allowed_edges(placement, str(placement.get("strategy", "edge_overlook")))
	var edge_order := _rotated_edges(allowed_edges, level_data)
	var candidates := _interleaved_edge_candidates(
		map_size, max_edge_distance, level_data, anchor, edge_order
	)

	for entry: Dictionary in candidates:
		var candidate := entry.get("tile", Vector2i.ZERO) as Vector2i
		var outward := entry.get("outward", Vector2i.UP) as Vector2i
		var inward := -outward
		if rejected_tiles.has(candidate):
			continue
		if _lateral_distance(candidate, anchor, outward) > lateral_search:
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
			inward,
			approach_depth,
			level_data,
			map_instance
		):
			continue
		var result := {
			"ok": true,
			"tile": candidate,
			"anchor": anchor,
			"outward_direction": outward,
			"edge_distance_tiles": _edge_distance(candidate, map_size, outward),
			"candidate_attempt_limit": candidate_attempt_limit,
			"unlock_causeway": (placement.get("unlock_causeway", {}) as Dictionary).duplicate(true),
		}
		if (
			map_instance != null
			and map_instance.has_method(
				"claim_world_overlook_pocket"
			)
		):
			result["requires_authored_pocket"] = true
			result["pocket_center_tile"] = (
				candidate + inward * int(approach_depth / 2)
			)
			result["pocket_size_tiles"] = (
				Vector2i(9, approach_depth)
				if inward.x == 0 else Vector2i(approach_depth, 9)
			)
		return result

	if map_instance != null and map_instance.has_method(
		"claim_world_overlook_pocket"
	):
		var authored := _best_edge_authoring_candidate(
			anchor,
			map_size,
			max_edge_distance,
			approach_depth,
			lateral_search,
			candidate_attempt_limit,
			level_data,
			map_instance, edge_order, occupied_tiles, minimum_spacing,
			rejected_tiles
		)
		if authored.is_empty():
			return {"ok": false, "reason": "all deterministic edge candidates rejected"}
		var authored_candidate := authored.tile as Vector2i
		var outward := authored.outward as Vector2i
		var inward := -outward
		return {
			"ok": true,
			"tile": authored_candidate,
			"anchor": anchor,
			"outward_direction": outward,
			"edge_distance_tiles": _edge_distance(authored_candidate, map_size, outward),
			"candidate_attempt_limit": candidate_attempt_limit,
			"requires_authored_pocket": true,
			"pocket_center_tile": (
				authored_candidate
				+ inward * int(approach_depth / 2)
			),
			"pocket_size_tiles": Vector2i(9, approach_depth) if inward.x == 0 else Vector2i(approach_depth, 9),
			"unlock_causeway": (placement.get("unlock_causeway", {}) as Dictionary).duplicate(true),
		}

	return {
		"ok": false,
		"tile": Vector2i.ZERO,
		"anchor": anchor,
		"reason": "no valid edge overlook corridor",
	}


func _edge_candidates(
	map_size: Vector2i,
	max_edge_distance: int,
	level_data: Dictionary,
	outward: Vector2i
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var floor_cells: Array = level_data.get("floor_cells", [])
	if floor_cells.is_empty():
		floor_cells = level_data.get("random_floor_tiles", [])
	for raw: Variant in floor_cells:
		if raw is Vector2i:
			var tile := raw as Vector2i
			var edge_distance := _edge_distance(tile, map_size, outward)
			if (
				tile.x >= 0 and tile.x < map_size.x
				and tile.y >= 0 and tile.y < map_size.y
				and edge_distance >= 0
				and edge_distance <= max_edge_distance
			):
				result.append(tile)
	if not result.is_empty():
		return result
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			if _edge_distance(tile, map_size, outward) <= max_edge_distance:
				result.append(tile)
	return result


func _best_edge_authoring_candidate(
	anchor: Vector2i,
	map_size: Vector2i,
	max_edge_distance: int,
	approach_depth: int,
	_lateral_search: int,
	_candidate_attempt_limit: int,
	level_data: Dictionary,
	map_instance: Node,
	edge_order: Array[Vector2i],
	occupied_tiles: Array[Vector2i],
	minimum_spacing: int,
	rejected_tiles: Array[Vector2i] = []
) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	var entries := _interleaved_edge_candidates(map_size, max_edge_distance, {}, anchor, edge_order)
	for entry: Dictionary in entries:
		var candidate := entry.tile as Vector2i
		var outward := entry.outward as Vector2i
		var inward := -outward
		if rejected_tiles.has(candidate):
			continue
		# The authored fallback creates floor, so the candidate itself need not
		# already be walkable. Use the innermost allowed edge band to keep the
		# new pocket as close to mainland as the placement contract permits.
		if _edge_distance(candidate, map_size, outward) != max_edge_distance:
			continue
		if _is_reserved(candidate, level_data):
			continue
		if not _has_spacing(candidate, occupied_tiles, minimum_spacing):
			continue
		var existing_inward_floor := 0
		for step in range(approach_depth):
			if _is_walkable(
				candidate + inward * step,
				level_data,
				map_instance
			):
				existing_inward_floor += 1
		var lateral_penalty := float(
			_lateral_distance(candidate, anchor, outward)
		) * 0.01
		var score := float(existing_inward_floor) - lateral_penalty
		if score > best_score:
			best_score = score
			best = entry
	return best


func _allowed_edges(placement: Dictionary, strategy: String) -> Array[Vector2i]:
	var names: Array = placement.get("allowed_edges", ["north"] if strategy == "north_edge_overlook" else ["north", "east", "south", "west"])
	var result: Array[Vector2i] = []
	var mapping := {"north": Vector2i.UP, "east": Vector2i.RIGHT, "south": Vector2i.DOWN, "west": Vector2i.LEFT}
	for raw: Variant in names:
		var edge := str(raw).to_lower()
		if mapping.has(edge) and not result.has(mapping[edge]):
			result.append(mapping[edge])
	return result if not result.is_empty() else [Vector2i.UP]


func _rotated_edges(edges: Array[Vector2i], level_data: Dictionary) -> Array[Vector2i]:
	var result := edges.duplicate()
	var identity: Variant = level_data.get("generation_id", level_data.get("seed", 0))
	var offset := (str(identity).hash() & 0x7fffffff) % result.size()
	for index in range(offset):
		result.append(result.pop_front())
	return result


func _interleaved_edge_candidates(map_size: Vector2i, max_edge_distance: int, level_data: Dictionary, anchor: Vector2i, edges: Array[Vector2i]) -> Array[Dictionary]:
	var lists: Array = []
	var longest := 0
	for outward in edges:
		var edge_candidates := _edge_candidates(map_size, max_edge_distance, level_data, outward)
		edge_candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var da := _edge_distance(a, map_size, outward)
			var db := _edge_distance(b, map_size, outward)
			if da != db: return da < db
			var la := _lateral_distance(a, anchor, outward)
			var lb := _lateral_distance(b, anchor, outward)
			return la < lb if la != lb else (a.x < b.x if a.x != b.x else a.y < b.y))
		lists.append(edge_candidates)
		longest = maxi(longest, edge_candidates.size())
	var result: Array[Dictionary] = []
	for index in range(longest):
		for edge_index in range(edges.size()):
			if index < lists[edge_index].size():
				result.append({"tile": lists[edge_index][index], "outward": edges[edge_index]})
	return result


func _edge_distance(tile: Vector2i, map_size: Vector2i, outward: Vector2i) -> int:
	if outward == Vector2i.UP: return tile.y
	if outward == Vector2i.DOWN: return map_size.y - 1 - tile.y
	if outward == Vector2i.LEFT: return tile.x
	return map_size.x - 1 - tile.x


func _lateral_distance(tile: Vector2i, anchor: Vector2i, outward: Vector2i) -> int:
	return absi(tile.x - anchor.x) if outward.x == 0 else absi(tile.y - anchor.y)


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
