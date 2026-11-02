class_name ProcgenRequiredCellClassifier
extends RefCounted


static func collect_required_cell_entries(context: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var map_size: Vector2i = context.get("map_size", Vector2i.ZERO)
	var is_inside: Callable = context.get("is_tile_inside_map", Callable())
	var spawn: Vector2i = context.get("spawn", Vector2i.ZERO)
	if _is_inside(is_inside, spawn, map_size):
		entries.append({"tile": spawn, "source": "spawn"})

	var rooms: Array = context.get("rooms_by_distance", [])
	if bool(context.get("is_ascent_field", false)):
		_append_sampled_array(entries, context.get("ascent_field_main_route_cells", []), map_size, 8, "ascent_anchor", is_inside)
		_append_sampled_array(entries, context.get("ascent_field_vista_cells", []), map_size, 4, "ascent_vista", is_inside)
		_append_first(entries, rooms, map_size, 4, "ascent_objective", is_inside)
	else:
		_append_first(entries, rooms, map_size, 4, "room_center", is_inside)

	_append_all(entries, context.get("last_interior_thresholds", []), map_size, "interior_threshold", is_inside)
	_append_all(entries, context.get("last_compound_ingress", []), map_size, "compound_ingress", is_inside)
	_append_sampled_dictionary(entries, context.get("connected_road_required_tiles", {}), map_size, 16, "road_sample", is_inside)
	_append_sampled_dictionary(entries, context.get("connected_parking_required_tiles", {}), map_size, 8, "parking_sample", is_inside)
	_append_sampled_array(entries, context.get("compound_connector_centerline_tiles", []), map_size, 8, "compound_connector_road", is_inside)
	_append_all(entries, context.get("intent_graph_required_cells", []), map_size, "intent_graph_required", is_inside)
	_append_all(entries, context.get("authored_claim_cells", []), map_size, "authored_claim", is_inside)
	return dedupe_entries(entries)


static func entries_to_cells(entries: Array[Dictionary]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var seen := {}
	for entry in entries:
		var tile_variant: Variant = entry.get("tile", Vector2i.ZERO)
		if not (tile_variant is Vector2i) or seen.has(tile_variant):
			continue
		seen[tile_variant] = true
		result.append(tile_variant as Vector2i)
	return result


static func dedupe_entries(entries: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	for entry in entries:
		var tile_variant: Variant = entry.get("tile", Vector2i.ZERO)
		if not (tile_variant is Vector2i) or seen.has(tile_variant):
			continue
		seen[tile_variant] = true
		result.append({
			"tile": tile_variant as Vector2i,
			"source": String(entry.get("source", "unknown")),
		})
	return result


static func _append_first(entries: Array[Dictionary], source: Array, map_size: Vector2i, max_count: int, label: String, is_inside: Callable) -> void:
	for index in range(mini(max_count, source.size())):
		var cell_variant: Variant = source[index]
		if cell_variant is Vector2i and _is_inside(is_inside, cell_variant as Vector2i, map_size):
			entries.append({"tile": cell_variant as Vector2i, "source": label})


static func _append_all(entries: Array[Dictionary], source: Array, map_size: Vector2i, label: String, is_inside: Callable) -> void:
	for cell_variant in source:
		if cell_variant is Vector2i and _is_inside(is_inside, cell_variant as Vector2i, map_size):
			entries.append({"tile": cell_variant as Vector2i, "source": label})


static func _append_sampled_array(entries: Array[Dictionary], source: Array, map_size: Vector2i, max_count: int, label: String, is_inside: Callable) -> void:
	if source.is_empty() or max_count <= 0:
		return
	var sample_count := mini(source.size(), max_count)
	for index in range(sample_count):
		var source_index := index
		if source.size() > max_count:
			source_index = int(round(float(index) * float(source.size() - 1) / float(max_count - 1)))
		var cell_variant: Variant = source[source_index]
		if cell_variant is Vector2i and _is_inside(is_inside, cell_variant as Vector2i, map_size):
			entries.append({"tile": cell_variant as Vector2i, "source": label})


static func _append_sampled_dictionary(entries: Array[Dictionary], source: Dictionary, map_size: Vector2i, max_count: int, label: String, is_inside: Callable) -> void:
	var cells: Array[Vector2i] = []
	for key in source.keys():
		if key is Vector2i and _is_inside(is_inside, key as Vector2i, map_size):
			cells.append(key as Vector2i)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x if a.x != b.x else a.y < b.y
	)
	_append_sampled_array(entries, cells, map_size, max_count, label, is_inside)


static func _is_inside(check: Callable, cell: Vector2i, map_size: Vector2i) -> bool:
	return check.is_valid() and bool(check.call(cell, map_size))
