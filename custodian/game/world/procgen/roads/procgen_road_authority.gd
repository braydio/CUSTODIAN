class_name ProcgenRoadAuthority
extends RefCounted
## Canonical generated road, path, and parking masks plus deterministic graph decisions.
## Physical floor/wall/region mutation and road presentation stay in ProcGenTilemap.

var main_road_tiles: Dictionary = {}
var road_centerline_tiles: Dictionary = {}
var path_centerline_tiles: Dictionary = {}
var compound_connector_centerline_tiles: Array[Vector2i] = []
var parking_zone_tiles: Dictionary = {}
var ruined_road_cells: Dictionary = {}
var service_hardstand_cells: Dictionary = {}
var road_semantics_summary: Dictionary = {}
var parking_zone_center: Vector2i = Vector2i.ZERO


func reset_generated_roads() -> void:
	main_road_tiles.clear()
	road_centerline_tiles.clear()
	path_centerline_tiles.clear()
	compound_connector_centerline_tiles.clear()
	parking_zone_tiles.clear()
	parking_zone_center = Vector2i.ZERO


func clear_generated_road_tiles(tile: Vector2i) -> void:
	main_road_tiles.erase(tile)
	road_centerline_tiles.erase(tile)
	path_centerline_tiles.erase(tile)
	compound_connector_centerline_tiles.erase(tile)
	parking_zone_tiles.erase(tile)


func clear_path_centerline() -> void:
	path_centerline_tiles.clear()


func clear_compound_connector_centerline() -> void:
	compound_connector_centerline_tiles.clear()


func clear_parking_tiles() -> void:
	parking_zone_tiles.clear()


func clear_road_semantics() -> void:
	ruined_road_cells.clear()
	service_hardstand_cells.clear()
	road_semantics_summary.clear()


func publish_road_semantics(
	ruined: Dictionary,
	hardstand: Dictionary,
	parking: Dictionary,
	use_semantic_parking: bool,
	summary: Dictionary
) -> Dictionary:
	ruined_road_cells = ruined.duplicate(true)
	service_hardstand_cells = hardstand.duplicate(true)
	if use_semantic_parking:
		parking_zone_tiles = parking.duplicate(true)
	road_semantics_summary = summary.duplicate(true)
	road_semantics_summary["parking_cell_count"] = parking_zone_tiles.size()
	return road_semantics_summary.duplicate(true)


func add_road_tile(tile: Vector2i) -> void:
	main_road_tiles[tile] = true


func add_road_centerline_tile(tile: Vector2i) -> void:
	road_centerline_tiles[tile] = true


func add_path_centerline_tile(tile: Vector2i) -> void:
	path_centerline_tiles[tile] = true


func set_parking_zone_center(center: Vector2i) -> void:
	parking_zone_center = center


func add_parking_tile(tile: Vector2i) -> void:
	main_road_tiles[tile] = true
	parking_zone_tiles[tile] = true


func append_compound_connector_centerline(tile: Vector2i) -> void:
	compound_connector_centerline_tiles.append(tile)


func add_parking_centerline_tile(tile: Vector2i) -> void:
	road_centerline_tiles[tile] = true


func is_road_tile(tile: Vector2i) -> bool:
	return main_road_tiles.has(tile)


func is_parking_tile(tile: Vector2i) -> bool:
	return parking_zone_tiles.has(tile)


func get_main_road_tiles() -> Array[Vector2i]:
	return _dictionary_tiles(main_road_tiles)


func get_parking_tiles() -> Array[Vector2i]:
	return _dictionary_tiles(parking_zone_tiles)


func get_ruined_road_tiles() -> Array[Vector2i]:
	return _sorted_dictionary_tiles(ruined_road_cells)


func get_service_hardstand_tiles() -> Array[Vector2i]:
	return _sorted_dictionary_tiles(service_hardstand_cells)


func get_road_semantics_summary() -> Dictionary:
	return road_semantics_summary.duplicate(true)


func connected_road_tiles(root: Vector2i) -> Dictionary:
	var visited: Dictionary = {}
	if not main_road_tiles.has(root):
		return visited
	var frontier: Array[Vector2i] = [root]
	visited[root] = true
	while not frontier.is_empty():
		var tile: Vector2i = frontier.pop_front()
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = tile + direction
			if visited.has(next) or not main_road_tiles.has(next):
				continue
			visited[next] = true
			frontier.append(next)
	return visited


func road_surface_components() -> Array[Array]:
	var components: Array[Array] = []
	var remaining := {}
	for value in main_road_tiles.keys():
		if value is Vector2i:
			remaining[value] = true
	while not remaining.is_empty():
		var start := remaining.keys()[0] as Vector2i
		var component: Array[Vector2i] = []
		var frontier: Array[Vector2i] = [start]
		remaining.erase(start)
		while not frontier.is_empty():
			var tile: Vector2i = frontier.pop_front()
			component.append(tile)
			for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var next: Vector2i = tile + direction
				if not remaining.has(next):
					continue
				remaining.erase(next)
				frontier.append(next)
		components.append(component)
	return components


func road_surface_components_largest_first() -> Array[Array]:
	var components := road_surface_components()
	components.sort_custom(func(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
		return a.size() > b.size()
	)
	return components


func nearest_component_pair(primary: Array[Vector2i], component: Array[Vector2i]) -> Array[Vector2i]:
	if primary.is_empty() or component.is_empty():
		return []
	var best_from := primary[0]
	var best_to := component[0]
	var best_dist := best_from.distance_squared_to(best_to)
	for from_tile in primary:
		for to_tile in component:
			var distance := from_tile.distance_squared_to(to_tile)
			if distance < best_dist:
				best_dist = distance
				best_from = from_tile
				best_to = to_tile
	return [best_from, best_to]


func next_component_repair_pair(
	primary: Array[Vector2i], component: Array[Vector2i]
) -> Array[Vector2i]:
	return nearest_component_pair(primary, component)


func next_required_road_anchor(
	required_anchors: Array[Vector2i], root_anchor: Vector2i, map_size: Vector2i
) -> Dictionary:
	if required_anchors.is_empty() or main_road_tiles.is_empty():
		return {}
	var root := root_anchor
	if not main_road_tiles.has(root):
		root = required_anchors[0]
	for anchor in required_anchors:
		if main_road_tiles.has(anchor):
			root = anchor
			break
	var connected := connected_road_tiles(root)
	for anchor in required_anchors:
		if _inside_map(anchor, map_size, 1) and not connected.has(anchor):
			return {"from": root, "to": anchor}
	return {}


func edge_prune_plan(map_size: Vector2i) -> Array[Vector2i]:
	var removals: Array[Vector2i] = []
	for component_value in road_surface_components():
		var component := component_value as Array[Vector2i]
		if component.size() >= 32 or not component_touches_edge(component, map_size):
			continue
		removals.append_array(component)
	return removals


func disconnected_prune_plan(spawn: Vector2i, minimum_size: int) -> Array[Vector2i]:
	var removals: Array[Vector2i] = []
	for component_value in road_surface_components():
		var component := component_value as Array[Vector2i]
		if component.has(spawn) or component.size() >= minimum_size:
			continue
		removals.append_array(component)
	return removals


func component_touches_edge(component: Array[Vector2i], map_size: Vector2i) -> bool:
	for tile in component:
		if tile.x <= 2 or tile.y <= 2 or tile.x >= map_size.x - 3 or tile.y >= map_size.y - 3:
			return true
	return false


func _inside_map(tile: Vector2i, map_size: Vector2i, margin: int = 0) -> bool:
	return tile.x >= margin and tile.y >= margin \
			and tile.x < map_size.x - margin and tile.y < map_size.y - margin


func _dictionary_tiles(source: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for value in source.keys():
		if value is Vector2i:
			result.append(value)
	return result


func _sorted_dictionary_tiles(source: Dictionary) -> Array[Vector2i]:
	var result := _dictionary_tiles(source)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	return result
