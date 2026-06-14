extends RefCounted
class_name TerrainBuilder

const TerrainRegionScript := preload("res://game/world/procgen/terrain/terrain_region.gd")
const TerrainTileIdsScript := preload("res://game/world/procgen/terrain/terrain_tile_ids.gd")
const WorldProgressProfileScript := preload("res://game/world/procgen/progression/world_progress_profile.gd")
const AscentRoutePlannerScript := preload("res://game/world/procgen/progression/ascent_route_planner.gd")

enum TerrainType {
	GROUND,
	INDUSTRIAL_PLATFORM,
	INDUSTRIAL_EDGE,
	INDUSTRIAL_RAMP,
	INDUSTRIAL_STAIR,
	ROCK_GROUND,
	ROCK_PLATEAU,
	ROCK_CLIFF_EDGE,
	ROCK_CLIFF_CORNER,
	ROCK_CHASM,
	MOUNTAIN_WALL,
}

enum TraversalType {
	WALKABLE,
	BLOCKED,
	LEDGE,
	RAMP,
	STAIR,
	DROP,
}

const HEIGHT_DROP := -1
const HEIGHT_GROUND := 0
const HEIGHT_ELEVATED := 1

const TRAVERSAL_WALKABLE := "walkable"
const TRAVERSAL_BLOCKED := "blocked"
const TRAVERSAL_LEDGE := "ledge"
const TRAVERSAL_RAMP := "ramp"
const TRAVERSAL_STAIR := "stair"
const TRAVERSAL_DROP := "drop"

const DIRECTION_NONE := "none"
const DIRECTION_NORTH := "north"
const DIRECTION_SOUTH := "south"
const DIRECTION_EAST := "east"
const DIRECTION_WEST := "west"

const NO_VISUAL_TILE := ""

var _last_result: Dictionary = {}
var _ascent_route_planner: RefCounted = null


func build_terrain(map_rect: Rect2i, rng: RandomNumberGenerator, context: Dictionary = {}) -> Dictionary:
	var result := _build_baseline(map_rect, context)
	var debug_regions: Array = []
	var warnings: Array[String] = []
	var fallback_used := false

	var required_cells: Array[Vector2i] = _normalize_cell_array(context.get("required_cells", []))
	var start_cell := _resolve_start_cell(map_rect, result, context, required_cells)
	if start_cell != Vector2i(2147483647, 2147483647):
		var cells_to_dedupe: Array[Vector2i] = [start_cell]
		cells_to_dedupe.append_array(required_cells)
		required_cells = _dedupe_cells(cells_to_dedupe)

	var terrain_seed := int(context.get("seed", rng.seed))
	var world_progress_profile = null
	if context.has("world_progress_profile") and context["world_progress_profile"] != null:
		world_progress_profile = context["world_progress_profile"]
	elif context.has("world_progress_profile_path"):
		world_progress_profile = WorldProgressProfileScript.load_from_path(String(context["world_progress_profile_path"]))
	if _ascent_route_planner == null:
		_ascent_route_planner = AscentRoutePlannerScript.new()

	if bool(context.get("enable_ascent_route", false)) and world_progress_profile != null:
		var ascent_snapshot := result.duplicate(true)
		var ascent_region: Dictionary = _ascent_route_planner.call("apply_ascent_route", map_rect, result, context, world_progress_profile)
		if not ascent_region.is_empty():
			if _validate_connectivity(result, start_cell, required_cells).get("ok", false):
				debug_regions.append(ascent_region)
			else:
				result = ascent_snapshot
				warnings.append("WARNING: TerrainBuilder discarded ascent route because connectivity validation failed.")

	if bool(context.get("enable_mountain_boundary", true)):
		var mountain_snapshot := result.duplicate(true)
		var mountain_region := _place_mountain_boundary(map_rect, rng, result, required_cells)
		if not mountain_region.is_empty():
			if _validate_connectivity(result, start_cell, required_cells).get("ok", false):
				debug_regions.append(mountain_region)
			else:
				result = mountain_snapshot
				warnings.append("WARNING: TerrainBuilder discarded mountain boundary because connectivity validation failed.")

	if bool(context.get("enable_industrial_platform", true)):
		var platform_snapshot := result.duplicate(true)
		var platform_region := _place_industrial_platform(map_rect, rng, result, required_cells)
		if not platform_region.is_empty():
			if _validate_connectivity(result, start_cell, required_cells).get("ok", false):
				debug_regions.append(platform_region)
			else:
				result = platform_snapshot
				warnings.append("WARNING: TerrainBuilder discarded elevated platform because no valid access route could be created.")

	var connectivity := _validate_connectivity(result, start_cell, required_cells)
	if not bool(connectivity.get("ok", true)):
		result = _build_baseline(map_rect, context)
		connectivity = _validate_connectivity(result, start_cell, required_cells)
		fallback_used = true
		warnings.append("WARNING: TerrainBuilder fell back to baseline terrain after connectivity validation failed.")

	result["debug_regions"] = debug_regions
	result["regions"] = debug_regions
	result["warnings"] = warnings
	result["connectivity"] = connectivity
	result["fallback_used"] = fallback_used
	result["seed"] = terrain_seed
	result["map_rect"] = map_rect
	result["debug_summary"] = _build_debug_summary(result)
	_last_result = result.duplicate(true)
	return result


func get_height(cell: Vector2i) -> int:
	return int(_last_result.get("height_by_cell", {}).get(cell, HEIGHT_GROUND))


func get_traversal(cell: Vector2i) -> String:
	return String(_last_result.get("traversal_by_cell", {}).get(cell, TRAVERSAL_WALKABLE))


func is_blocked(cell: Vector2i) -> bool:
	return _is_blocked_traversal(get_traversal(cell))


func can_move_between(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	return _can_move_between_in_result(_last_result, from_cell, to_cell)


func is_valid_spawn_cell(cell: Vector2i) -> bool:
	return _is_walkable_traversal(get_traversal(cell))


func get_last_result() -> Dictionary:
	return _last_result.duplicate(true)


func _build_baseline(map_rect: Rect2i, context: Dictionary) -> Dictionary:
	var height_by_cell := {}
	var traversal_by_cell := {}
	var terrain_type_by_cell := {}
	var tile_by_cell := {}
	var ramp_dir_by_cell := {}
	var blocked_cells := {}

	var floor_lookup := _cell_lookup(_normalize_cell_array(context.get("floor_cells", [])))
	var blocked_lookup := _cell_lookup(_normalize_cell_array(context.get("blocked_cells", [])))
	var use_floor_lookup := not floor_lookup.is_empty()

	for x in range(map_rect.position.x, map_rect.end.x):
		for y in range(map_rect.position.y, map_rect.end.y):
			var cell := Vector2i(x, y)
			if use_floor_lookup and not floor_lookup.has(cell):
				continue
			_set_cell(
				height_by_cell,
				traversal_by_cell,
				terrain_type_by_cell,
				tile_by_cell,
				ramp_dir_by_cell,
				blocked_cells,
				cell,
				HEIGHT_GROUND,
				TRAVERSAL_WALKABLE,
				TerrainType.GROUND,
				NO_VISUAL_TILE
			)

	for blocked_cell in blocked_lookup.keys():
		if not map_rect.has_point(blocked_cell):
			continue
		_set_cell(
			height_by_cell,
			traversal_by_cell,
			terrain_type_by_cell,
			tile_by_cell,
			ramp_dir_by_cell,
			blocked_cells,
			blocked_cell,
			HEIGHT_GROUND,
			TRAVERSAL_BLOCKED,
			TerrainType.MOUNTAIN_WALL,
			NO_VISUAL_TILE
		)

	return {
		"height_by_cell": height_by_cell,
		"traversal_by_cell": traversal_by_cell,
		"terrain_type_by_cell": terrain_type_by_cell,
		"tile_by_cell": tile_by_cell,
		"ramp_dir_by_cell": ramp_dir_by_cell,
		"blocked_cells": blocked_cells,
	}


func _place_mountain_boundary(map_rect: Rect2i, rng: RandomNumberGenerator, result: Dictionary, required_cells: Array[Vector2i]) -> Dictionary:
	if map_rect.size.x < 20 or map_rect.size.y < 20:
		return {}
	var side := rng.randi_range(0, 3)
	var thickness := rng.randi_range(2, 4)
	var length := rng.randi_range(maxi(8, map_rect.size.x / 4), maxi(10, map_rect.size.x / 2))
	var origin := Vector2i(map_rect.position.x, map_rect.position.y)
	match side:
		0:
			origin = Vector2i(map_rect.position.x + rng.randi_range(2, maxi(2, map_rect.size.x - length - 2)), map_rect.position.y)
		1:
			origin = Vector2i(map_rect.end.x - thickness, map_rect.position.y + rng.randi_range(2, maxi(2, map_rect.size.y - length - 2)))
			length = mini(length, map_rect.size.y - 4)
		2:
			origin = Vector2i(map_rect.position.x + rng.randi_range(2, maxi(2, map_rect.size.x - length - 2)), map_rect.end.y - thickness)
		_:
			origin = Vector2i(map_rect.position.x, map_rect.position.y + rng.randi_range(2, maxi(2, map_rect.size.y - length - 2)))
			length = mini(length, map_rect.size.y - 4)

	var size := Vector2i(length, thickness) if side == 0 or side == 2 else Vector2i(thickness, length)
	var rect := Rect2i(origin, size).intersection(map_rect)
	if rect.size.x <= 0 or rect.size.y <= 0:
		return {}
	if _rect_touches_required(rect.grow(2), required_cells):
		return {}

	var cells: Array[Vector2i] = []
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var cell := Vector2i(x, y)
			if not _has_cell(result, cell):
				continue
			cells.append(cell)
			_set_result_cell(result, cell, HEIGHT_GROUND, TRAVERSAL_BLOCKED, TerrainType.MOUNTAIN_WALL, TerrainTileIdsScript.mountain("wall"))

	if cells.is_empty():
		return {}
	var region := TerrainRegionScript.new(TerrainRegionScript.RegionKind.MOUNTAIN_WALL, rect, cells)
	return region.to_dictionary()


func _place_industrial_platform(map_rect: Rect2i, rng: RandomNumberGenerator, result: Dictionary, required_cells: Array[Vector2i]) -> Dictionary:
	if map_rect.size.x < 24 or map_rect.size.y < 20:
		return {}
	var size_options := [Vector2i(5, 5), Vector2i(7, 5), Vector2i(7, 7)]
	var size: Vector2i = size_options[rng.randi_range(0, size_options.size() - 1)]
	var attempts := 12
	for _attempt in range(attempts):
		var min_x := map_rect.position.x + 4
		var max_x := map_rect.end.x - size.x - 4
		var min_y := map_rect.position.y + 4
		var max_y := map_rect.end.y - size.y - 4
		if max_x < min_x or max_y < min_y:
			return {}
		var origin := Vector2i(rng.randi_range(min_x, max_x), rng.randi_range(min_y, max_y))
		var rect := Rect2i(origin, size)
		if _rect_touches_required(rect.grow(2), required_cells):
			continue
		if not _rect_is_available(result, rect):
			continue
		var ramp_side := rng.randi_range(0, 3)
		var ramp_cell := _select_ramp_cell(rect, ramp_side)
		var approach_cell := ramp_cell + _ramp_approach_delta(ramp_side)
		if not map_rect.has_point(approach_cell):
			continue
		if not _has_cell(result, approach_cell):
			continue
		if _is_blocked_traversal(_traversal_from_result(result, approach_cell)):
			continue
		return _stamp_platform(result, rect, ramp_cell, ramp_side)
	return {}


func _stamp_platform(result: Dictionary, rect: Rect2i, ramp_cell: Vector2i, ramp_side: int) -> Dictionary:
	var cells: Array[Vector2i] = []
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var cell := Vector2i(x, y)
			var traversal := TRAVERSAL_WALKABLE
			var terrain_type := TerrainType.INDUSTRIAL_PLATFORM
			var tile_id := TerrainTileIdsScript.industrial("elevated_floor")
			if _is_platform_edge(rect, cell):
				traversal = TRAVERSAL_LEDGE
				terrain_type = TerrainType.INDUSTRIAL_EDGE
				tile_id = _industrial_edge_tile(rect, cell)
			if cell == ramp_cell:
				traversal = TRAVERSAL_RAMP
				terrain_type = TerrainType.INDUSTRIAL_RAMP
				tile_id = _industrial_ramp_tile(ramp_side)
				result["ramp_dir_by_cell"][cell] = _ramp_direction_name(ramp_side)
			_set_result_cell(result, cell, HEIGHT_ELEVATED, traversal, terrain_type, tile_id)
			cells.append(cell)
	var region := TerrainRegionScript.new(TerrainRegionScript.RegionKind.INDUSTRIAL_PLATFORM, rect, cells, [ramp_cell])
	return region.to_dictionary()


func _set_cell(
	height_by_cell: Dictionary,
	traversal_by_cell: Dictionary,
	terrain_type_by_cell: Dictionary,
	tile_by_cell: Dictionary,
	ramp_dir_by_cell: Dictionary,
	blocked_cells: Dictionary,
	cell: Vector2i,
	height: int,
	traversal: String,
	terrain_type: TerrainType,
	tile_id: String
) -> void:
	height_by_cell[cell] = height
	traversal_by_cell[cell] = traversal
	terrain_type_by_cell[cell] = terrain_type
	tile_by_cell[cell] = tile_id
	if _is_blocked_traversal(traversal):
		blocked_cells[cell] = true
	else:
		blocked_cells.erase(cell)
	if traversal != TRAVERSAL_RAMP and traversal != TRAVERSAL_STAIR:
		ramp_dir_by_cell.erase(cell)


func _set_result_cell(result: Dictionary, cell: Vector2i, height: int, traversal: String, terrain_type: TerrainType, tile_id: String) -> void:
	_set_cell(
		result["height_by_cell"],
		result["traversal_by_cell"],
		result["terrain_type_by_cell"],
		result["tile_by_cell"],
		result["ramp_dir_by_cell"],
		result["blocked_cells"],
		cell,
		height,
		traversal,
		terrain_type,
		tile_id
	)


func _validate_connectivity(result: Dictionary, start_cell: Vector2i, required_cells: Array[Vector2i]) -> Dictionary:
	if start_cell == Vector2i(2147483647, 2147483647):
		return {"ok": true, "reachable_count": 0, "missing_required": []}
	if not _is_walkable_traversal(_traversal_from_result(result, start_cell)):
		return {"ok": false, "reachable_count": 0, "missing_required": [start_cell]}
	var reachable := _flood_fill(result, start_cell)
	var missing: Array[Vector2i] = []
	for cell in required_cells:
		if _has_cell(result, cell) and _is_walkable_traversal(_traversal_from_result(result, cell)) and not reachable.has(cell):
			missing.append(cell)
	return {
		"ok": missing.is_empty(),
		"reachable_count": reachable.size(),
		"missing_required": missing,
	}


func _flood_fill(result: Dictionary, start_cell: Vector2i) -> Dictionary:
	var reachable := {}
	var open: Array[Vector2i] = [start_cell]
	reachable[start_cell] = true
	while not open.is_empty():
		var current := open.pop_front() as Vector2i
		for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = current + dir
			if reachable.has(next):
				continue
			if not _has_cell(result, next):
				continue
			if not _can_move_between_in_result(result, current, next):
				continue
			reachable[next] = true
			open.append(next)
	return reachable


func _can_move_between_in_result(result: Dictionary, from_cell: Vector2i, to_cell: Vector2i) -> bool:
	var delta := to_cell - from_cell
	if abs(delta.x) + abs(delta.y) != 1:
		return false

	var height_by_cell: Dictionary = result.get("height_by_cell", {})
	var traversal_by_cell: Dictionary = result.get("traversal_by_cell", {})
	var ramp_dir_by_cell: Dictionary = result.get("ramp_dir_by_cell", {})

	var from_height := int(height_by_cell.get(from_cell, HEIGHT_GROUND))
	var to_height := int(height_by_cell.get(to_cell, HEIGHT_GROUND))
	var from_traversal := String(traversal_by_cell.get(from_cell, TRAVERSAL_WALKABLE))
	var to_traversal := String(traversal_by_cell.get(to_cell, TRAVERSAL_WALKABLE))

	if _is_blocked_traversal(from_traversal):
		return false
	if to_traversal == TRAVERSAL_BLOCKED or to_traversal == TRAVERSAL_LEDGE or to_traversal == TRAVERSAL_DROP:
		return false

	var height_delta := to_height - from_height
	if height_delta == 0:
		return true

	if abs(height_delta) > 1:
		return false

	if from_traversal == TRAVERSAL_STAIR or to_traversal == TRAVERSAL_STAIR:
		return true

	if from_traversal == TRAVERSAL_RAMP:
		var from_dir := String(ramp_dir_by_cell.get(from_cell, DIRECTION_NONE))
		if _direction_to_delta(from_dir) == delta:
			return true

	if to_traversal == TRAVERSAL_RAMP:
		var to_dir := String(ramp_dir_by_cell.get(to_cell, DIRECTION_NONE))
		if _direction_to_delta(to_dir) == -delta:
			return true

	return false


func _build_debug_summary(result: Dictionary) -> Dictionary:
	var traversal_by_cell: Dictionary = result.get("traversal_by_cell", {})
	var height_by_cell: Dictionary = result.get("height_by_cell", {})
	var blocked_count := 0
	var elevated_count := 0
	var ramp_count := 0
	var max_height := 0
	for cell in traversal_by_cell.keys():
		var traversal := String(traversal_by_cell[cell])
		if _is_blocked_traversal(traversal):
			blocked_count += 1
		if int(height_by_cell.get(cell, HEIGHT_GROUND)) > HEIGHT_GROUND:
			elevated_count += 1
		if traversal == TRAVERSAL_RAMP or traversal == TRAVERSAL_STAIR:
			ramp_count += 1
		max_height = maxi(max_height, int(height_by_cell.get(cell, HEIGHT_GROUND)))
	return {
		"seed": int(result.get("seed", 0)),
		"map_size": (result.get("map_rect", Rect2i()) as Rect2i).size,
		"regions": (result.get("debug_regions", []) as Array).size(),
		"blocked_cells": blocked_count,
		"elevated_cells": elevated_count,
		"ramp_or_stair_cells": ramp_count,
		"max_height": max_height,
		"connectivity_ok": bool(result.get("connectivity", {}).get("ok", true)),
		"fallback_used": bool(result.get("fallback_used", false)),
	}


func _resolve_start_cell(map_rect: Rect2i, result: Dictionary, context: Dictionary, required_cells: Array[Vector2i]) -> Vector2i:
	if context.has("start_cell") and context["start_cell"] is Vector2i:
		var context_start := context["start_cell"] as Vector2i
		if _has_cell(result, context_start) and _is_walkable_traversal(_traversal_from_result(result, context_start)):
			return context_start
	for cell in required_cells:
		if _has_cell(result, cell) and _is_walkable_traversal(_traversal_from_result(result, cell)):
			return cell
	for cell in result.get("height_by_cell", {}).keys():
		if cell is Vector2i and map_rect.has_point(cell) and _is_walkable_traversal(_traversal_from_result(result, cell)):
			return cell
	return Vector2i(2147483647, 2147483647)


func _rect_is_available(result: Dictionary, rect: Rect2i) -> bool:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var cell := Vector2i(x, y)
			if not _has_cell(result, cell):
				return false
			if _is_blocked_traversal(_traversal_from_result(result, cell)):
				return false
	return true


func _rect_touches_required(rect: Rect2i, required_cells: Array[Vector2i]) -> bool:
	for cell in required_cells:
		if rect.has_point(cell):
			return true
	return false


func _has_cell(result: Dictionary, cell: Vector2i) -> bool:
	return (result.get("height_by_cell", {}) as Dictionary).has(cell)


func _traversal_from_result(result: Dictionary, cell: Vector2i) -> String:
	return String((result.get("traversal_by_cell", {}) as Dictionary).get(cell, TRAVERSAL_BLOCKED))


func _is_walkable_traversal(traversal: String) -> bool:
	return traversal == TRAVERSAL_WALKABLE or traversal == TRAVERSAL_RAMP or traversal == TRAVERSAL_STAIR


func _is_blocked_traversal(traversal: String) -> bool:
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


func _cell_lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	for cell in cells:
		lookup[cell] = true
	return lookup


func _dedupe_cells(cells: Array[Vector2i]) -> Array[Vector2i]:
	var lookup := {}
	var result: Array[Vector2i] = []
	for cell in cells:
		if lookup.has(cell):
			continue
		lookup[cell] = true
		result.append(cell)
	return result


func _is_platform_edge(rect: Rect2i, cell: Vector2i) -> bool:
	return cell.x == rect.position.x or cell.y == rect.position.y or cell.x == rect.end.x - 1 or cell.y == rect.end.y - 1


func _select_ramp_cell(rect: Rect2i, ramp_side: int) -> Vector2i:
	match ramp_side:
		0:
			return Vector2i(rect.position.x + int(rect.size.x / 2), rect.position.y)
		1:
			return Vector2i(rect.end.x - 1, rect.position.y + int(rect.size.y / 2))
		2:
			return Vector2i(rect.position.x + int(rect.size.x / 2), rect.end.y - 1)
		_:
			return Vector2i(rect.position.x, rect.position.y + int(rect.size.y / 2))


func _ramp_approach_delta(ramp_side: int) -> Vector2i:
	match ramp_side:
		0:
			return Vector2i.UP
		1:
			return Vector2i.RIGHT
		2:
			return Vector2i.DOWN
		_:
			return Vector2i.LEFT


func _ramp_direction_name(ramp_side: int) -> String:
	match ramp_side:
		0:
			return DIRECTION_NORTH
		1:
			return DIRECTION_EAST
		2:
			return DIRECTION_SOUTH
		_:
			return DIRECTION_WEST


func _direction_to_delta(direction: String) -> Vector2i:
	match direction:
		DIRECTION_NORTH:
			return Vector2i.UP
		DIRECTION_SOUTH:
			return Vector2i.DOWN
		DIRECTION_EAST:
			return Vector2i.RIGHT
		DIRECTION_WEST:
			return Vector2i.LEFT
		_:
			return Vector2i.ZERO


func _industrial_ramp_tile(ramp_side: int) -> String:
	match ramp_side:
		0:
			return TerrainTileIdsScript.industrial("ramp_north")
		1:
			return TerrainTileIdsScript.industrial("ramp_east")
		2:
			return TerrainTileIdsScript.industrial("ramp_south")
		_:
			return TerrainTileIdsScript.industrial("ramp_west")


func _industrial_edge_tile(rect: Rect2i, cell: Vector2i) -> String:
	if cell.y == rect.position.y:
		return TerrainTileIdsScript.industrial("edge_north")
	if cell.y == rect.end.y - 1:
		return TerrainTileIdsScript.industrial("edge_south")
	if cell.x == rect.end.x - 1:
		return TerrainTileIdsScript.industrial("edge_east")
	return TerrainTileIdsScript.industrial("edge_west")
