extends RefCounted
class_name AscentRoutePlanner

const TerrainRegionScript := preload("res://game/world/procgen/terrain/terrain_region.gd")
const TerrainTileIdsScript := preload("res://game/world/procgen/terrain/terrain_tile_ids.gd")

const TRAVERSAL_WALKABLE := "walkable"
const TRAVERSAL_BLOCKED := "blocked"
const TRAVERSAL_LEDGE := "ledge"
const TRAVERSAL_STAIR := "stair"
const TRAVERSAL_DROP := "drop"
const TERRAIN_ROCK_PLATEAU := 6
const TERRAIN_INDUSTRIAL_STAIR := 4


func apply_ascent_route(_map_rect: Rect2i, result: Dictionary, context: Dictionary, profile) -> Dictionary:
	if profile == null:
		return {}
	var start_cell: Vector2i = context.get("start_cell", Vector2i.ZERO)
	if not _has_cell(result, start_cell):
		return {}
	var seed := int(context.get("seed", 0))
	var required_cells: Array[Vector2i] = _normalize_cell_array(context.get("required_cells", []))
	var route: Array[Vector2i] = _build_required_route(result, start_cell, required_cells, profile)
	if route.size() < 2:
		return {}
	var target_cell: Vector2i = route.back()
	var progress: Dictionary = profile.get_cell_progress(target_cell, seed)
	var total_gain := clampi(int(progress.get("ascent_gain", 0)), 0, 12)
	if total_gain <= 0:
		return {
			"kind": TerrainRegionScript.RegionKind.ASCENT_ROUTE,
			"kind_name": "ascent_route",
			"route_cells": route,
			"target_cell": target_cell,
			"target_height": 0,
			"applied": false,
			"reason": "band has no ascent gain",
		}

	# A gradual field prevents a raised one-cell ribbon from severing narrow corridors.
	for cell_variant in (result.get("height_by_cell", {}) as Dictionary).keys():
		if not cell_variant is Vector2i:
			continue
		var field_cell := cell_variant as Vector2i
		if _is_blocked(result, field_cell):
			continue
		var distance: float = float(profile.get_distance_tiles(field_cell))
		var height := clampi(int(floor(maxf(0.0, distance - 96.0) / 48.0)), 0, 12)
		result["height_by_cell"][field_cell] = height
		result["traversal_by_cell"][field_cell] = TRAVERSAL_WALKABLE
		result["ramp_dir_by_cell"].erase(field_cell)
		result["blocked_cells"].erase(field_cell)

	for cell_variant in (result.get("height_by_cell", {}) as Dictionary).keys():
		if not cell_variant is Vector2i:
			continue
		var field_cell := cell_variant as Vector2i
		if _is_blocked(result, field_cell):
			continue
		var height := int(result["height_by_cell"].get(field_cell, 0))
		for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var neighbor: Vector2i = field_cell + direction
			if _has_cell(result, neighbor) and not _is_blocked(result, neighbor) and int(result["height_by_cell"].get(neighbor, height)) != height:
				result["traversal_by_cell"][field_cell] = TRAVERSAL_STAIR
				break

	for cell in route:
		var route_height := int(result["height_by_cell"].get(cell, 0))
		var traversal := String(result["traversal_by_cell"].get(cell, TRAVERSAL_WALKABLE))
		result["terrain_type_by_cell"][cell] = TERRAIN_INDUSTRIAL_STAIR if traversal == TRAVERSAL_STAIR else TERRAIN_ROCK_PLATEAU
		result["tile_by_cell"][cell] = TerrainTileIdsScript.industrial("stair") if traversal == TRAVERSAL_STAIR else TerrainTileIdsScript.mountain("plateau") if route_height > 0 else ""

	var last_height := int(result["height_by_cell"].get(target_cell, 0))

	return {
		"kind": TerrainRegionScript.RegionKind.ASCENT_ROUTE,
		"kind_name": "ascent_route",
		"route_cells": route,
		"cells": route,
		"target_cell": target_cell,
		"target_height": last_height,
		"profile_ascent_gain": total_gain,
		"applied": true,
		"band_id": String(progress.get("band_id", "unknown")),
		"dominant_style": String(progress.get("dominant_style", "unknown")),
	}


func _build_required_route(result: Dictionary, start_cell: Vector2i, required_cells: Array[Vector2i], profile) -> Array[Vector2i]:
	var stops: Array[Vector2i] = []
	for cell in required_cells:
		if cell != start_cell and _has_cell(result, cell) and not _is_blocked(result, cell):
			stops.append(cell)
	stops.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return profile.get_distance_tiles(a) < profile.get_distance_tiles(b)
	)
	if stops.is_empty():
		stops.append(_select_farthest_cell(result, start_cell, profile))
	var route: Array[Vector2i] = [start_cell]
	var cursor := start_cell
	for stop in stops:
		var segment := _find_path(result, cursor, stop)
		if segment.size() < 2:
			continue
		segment.pop_front()
		route.append_array(segment)
		cursor = stop
	return route


func _select_farthest_cell(result: Dictionary, start_cell: Vector2i, profile) -> Vector2i:
	var best_cell := start_cell
	var best_score := -INF
	for cell_variant in (result.get("height_by_cell", {}) as Dictionary).keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		if _is_blocked(result, cell):
			continue
		var score: float = float(start_cell.distance_squared_to(cell)) + float(profile.get_distance_tiles(cell)) * 8.0
		if score > best_score:
			best_score = score
			best_cell = cell
	return best_cell


func _find_path(result: Dictionary, start_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]:
	var came_from := {start_cell: start_cell}
	var open: Array[Vector2i] = [start_cell]
	while not open.is_empty():
		var current := open.pop_front() as Vector2i
		if current == target_cell:
			break
		for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var next: Vector2i = current + direction
			if came_from.has(next) or not _has_cell(result, next) or _is_blocked(result, next):
				continue
			came_from[next] = current
			open.append(next)
	if not came_from.has(target_cell):
		return []
	var path: Array[Vector2i] = []
	var cursor := target_cell
	while cursor != start_cell:
		path.push_front(cursor)
		cursor = came_from[cursor]
	path.push_front(start_cell)
	return path


func _has_cell(result: Dictionary, cell: Vector2i) -> bool:
	return (result.get("height_by_cell", {}) as Dictionary).has(cell)


func _is_blocked(result: Dictionary, cell: Vector2i) -> bool:
	var traversal := String((result.get("traversal_by_cell", {}) as Dictionary).get(cell, TRAVERSAL_BLOCKED))
	return traversal == TRAVERSAL_BLOCKED or traversal == TRAVERSAL_LEDGE or traversal == TRAVERSAL_DROP


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
