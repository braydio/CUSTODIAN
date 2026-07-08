class_name ProcgenComponentAnalyzer
extends RefCounted

const BRIDGE_CANDIDATE_CAP := 12
const CARDINAL_DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


static func analyze(context: Dictionary) -> Dictionary:
	var map_size: Vector2i = context.get("map_size", Vector2i.ZERO)
	var spawn: Vector2i = context.get("spawn", Vector2i.ZERO)
	var floor_cells: Dictionary = context.get("floor_cells", {})
	var is_walkable: Callable = context.get("is_baseline_walkable", Callable())
	var required_entries: Array[Dictionary] = context.get("required_cell_entries", [])
	var components: Array[Array] = []
	var component_by_tile := {}
	var remaining := {}
	for tile_variant in floor_cells.keys():
		if tile_variant is Vector2i and is_walkable.is_valid() and bool(is_walkable.call(tile_variant, map_size)):
			remaining[tile_variant] = true

	while not remaining.is_empty():
		var start := remaining.keys()[0] as Vector2i
		var component: Array[Vector2i] = []
		var open: Array[Vector2i] = [start]
		remaining.erase(start)
		while not open.is_empty():
			var current: Vector2i = open.pop_back()
			component.append(current)
			for direction in CARDINAL_DIRECTIONS:
				var next := current + direction
				if not remaining.has(next):
					continue
				remaining.erase(next)
				open.append(next)
		var component_id := components.size()
		for tile in component:
			component_by_tile[tile] = component_id
		components.append(component)

	var spawn_component := int(component_by_tile.get(spawn, -1))
	var required_components := {}
	var required_entries_by_component := {}
	for entry in required_entries:
		var tile_variant: Variant = entry.get("tile", Vector2i.ZERO)
		if not (tile_variant is Vector2i):
			continue
		var component_id := int(component_by_tile.get(tile_variant, -1))
		var key := str(component_id)
		required_components[key] = int(required_components.get(key, 0)) + 1
		if not required_entries_by_component.has(component_id):
			required_entries_by_component[component_id] = []
		(required_entries_by_component[component_id] as Array).append(entry)

	var largest_missing_size := 0
	for component_id_variant in required_entries_by_component.keys():
		var component_id := int(component_id_variant)
		if component_id == spawn_component or component_id < 0 or component_id >= components.size():
			continue
		largest_missing_size = maxi(largest_missing_size, (components[component_id] as Array).size())

	return {
		"pre_terrain_component_count": components.size(),
		"pre_terrain_spawn_component_size": (components[spawn_component] as Array).size() if spawn_component >= 0 and spawn_component < components.size() else 0,
		"pre_terrain_required_components": required_components,
		"pre_terrain_largest_missing_component_size": largest_missing_size,
		"pre_terrain_bridge_candidates": _find_bridge_candidates(components, spawn_component, required_entries_by_component),
	}


static func _find_bridge_candidates(components: Array[Array], spawn_component: int, required_entries_by_component: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	if spawn_component < 0 or spawn_component >= components.size():
		return candidates
	var spawn_tiles := components[spawn_component] as Array[Vector2i]
	for component_id_variant in required_entries_by_component.keys():
		var component_id := int(component_id_variant)
		if component_id == spawn_component or component_id < 0 or component_id >= components.size():
			continue
		var entries := required_entries_by_component[component_id] as Array
		if entries.is_empty():
			continue
		var other_tiles := components[component_id] as Array[Vector2i]
		var best_from := Vector2i.ZERO
		var best_to := Vector2i.ZERO
		var best_distance := 2147483647
		for from_tile in spawn_tiles:
			for to_tile in other_tiles:
				var distance := absi(from_tile.x - to_tile.x) + absi(from_tile.y - to_tile.y)
				if distance < best_distance:
					best_distance = distance
					best_from = from_tile
					best_to = to_tile
		candidates.append({
			"from_tile": best_from,
			"to_tile": best_to,
			"distance_manhattan": best_distance,
			"from_source": "spawn_component",
			"to_source": String((entries[0] as Dictionary).get("source", "unknown")),
		})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var distance_a := int(a.get("distance_manhattan", 0))
		var distance_b := int(b.get("distance_manhattan", 0))
		if distance_a != distance_b:
			return distance_a < distance_b
		var a_to: Vector2i = a.get("to_tile", Vector2i.ZERO)
		var b_to: Vector2i = b.get("to_tile", Vector2i.ZERO)
		return a_to.x < b_to.x if a_to.x != b_to.x else a_to.y < b_to.y
	)
	return candidates.slice(0, BRIDGE_CANDIDATE_CAP) if candidates.size() > BRIDGE_CANDIDATE_CAP else candidates
