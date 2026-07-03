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

const DEBUG_CONNECTIVITY_MAP: bool = false

var _last_result: Dictionary = {}
var _ascent_route_planner: RefCounted = null


func build_terrain(map_rect: Rect2i, rng: RandomNumberGenerator, context: Dictionary = {}) -> Dictionary:
	var _t_start := Time.get_ticks_msec()
	var _marks := {}
	var _last := _t_start
	
	var result := _build_baseline(map_rect, context)
	_marks["build_baseline"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()
	
	var debug_regions: Array = []
	var warnings: Array[String] = []
	var fallback_used := false
	var rescue_carved_cells := 0

	var required_cells: Array[Vector2i] = _normalize_cell_array(context.get("required_cells", []))
	var start_cell := _resolve_start_cell(map_rect, result, context, required_cells)
	if start_cell != Vector2i(2147483647, 2147483647):
		var cells_to_dedupe: Array[Vector2i] = [start_cell]
		cells_to_dedupe.append_array(required_cells)
		required_cells = _dedupe_cells(cells_to_dedupe)

	var terrain_seed := int(context.get("seed", rng.seed))
	var generation_mode := String(context.get("generation_mode", "FINAL_VISUAL"))
	var quiet_candidate_warnings := generation_mode == "EVAL_CANDIDATE"
	var baseline_rescue_carved_cells := 0
	var baseline_connectivity := _validate_connectivity(result, start_cell, required_cells)
	if not bool(baseline_connectivity.get("ok", true)):
		var baseline_missing: Array = baseline_connectivity.get("missing_required", [])
		var baseline_reachable := int(baseline_connectivity.get("reachable_count", 0))
		baseline_rescue_carved_cells = _rescue_connectivity(result, start_cell, baseline_missing)
		rescue_carved_cells += baseline_rescue_carved_cells
		baseline_connectivity = _validate_connectivity(result, start_cell, required_cells)
		warnings.append("WARNING: TerrainBuilder baseline connectivity was disconnected before terrain features. seed=%s start=%s reachable=%d missing=%s baseline_rescue_carved=%d" % [
			terrain_seed,
			str(start_cell),
			baseline_reachable,
			str(baseline_missing),
			baseline_rescue_carved_cells,
		])
		if not quiet_candidate_warnings:
			push_warning("TerrainBuilder baseline connectivity was disconnected before terrain features.")
			push_warning("  seed=%s start=%s reachable=%d missing=%s baseline_rescue_carved=%d" % [
				terrain_seed,
				str(start_cell),
				baseline_reachable,
				str(baseline_missing),
				baseline_rescue_carved_cells,
			])
		if DEBUG_CONNECTIVITY_MAP:
			_debug_print_connectivity_map(result, baseline_connectivity)
	var world_progress_profile = null
	if context.has("world_progress_profile") and context["world_progress_profile"] != null:
		world_progress_profile = context["world_progress_profile"]
	elif context.has("world_progress_profile_path"):
		world_progress_profile = WorldProgressProfileScript.load_from_path(String(context["world_progress_profile_path"]))
	if _ascent_route_planner == null:
		_ascent_route_planner = AscentRoutePlannerScript.new()

	if context.has("worldgen_reserved_regions"):
		var reserved_snapshot := result.duplicate(true)
		var reserved_region := _apply_reserved_region_elevation(result, context.get("worldgen_reserved_regions", []))
		if not reserved_region.is_empty():
			var reserved_conn := _validate_connectivity(result, start_cell, required_cells)
			if reserved_conn.get("ok", false):
				debug_regions.append(reserved_region)
			else:
				result = reserved_snapshot
				var conn_detail := "start=%s reachable=%d missing=%s" % [str(start_cell), reserved_conn.get("reachable_count", 0), str(reserved_conn.get("missing_required", []))]
				warnings.append("WARNING: TerrainBuilder discarded reserved-region elevation because it newly broke connectivity: %s. seed=%s map=%s" % [conn_detail, terrain_seed, str(map_rect)])
	_marks["reserved_region"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if bool(context.get("enable_ascent_route", false)) and world_progress_profile != null:
		var ascent_snapshot := result.duplicate(true)
		var ascent_region: Dictionary = _ascent_route_planner.call("apply_ascent_route", map_rect, result, context, world_progress_profile)
		if not ascent_region.is_empty():
			var ascent_conn := _validate_connectivity(result, start_cell, required_cells)
			if ascent_conn.get("ok", false):
				debug_regions.append(ascent_region)
			else:
				result = ascent_snapshot
				var conn_detail := "start=%s reachable=%d missing=%s" % [str(start_cell), ascent_conn.get("reachable_count", 0), str(ascent_conn.get("missing_required", []))]
				warnings.append("WARNING: TerrainBuilder discarded ascent route because it newly broke connectivity: %s. seed=%s map=%s" % [conn_detail, terrain_seed, str(map_rect)])
	_marks["ascent_route"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if bool(context.get("enable_mountain_boundary", true)):
		var mountain_snapshot := result.duplicate(true)
		var mountain_region := _place_mountain_boundary(map_rect, rng, result, required_cells)
		if not mountain_region.is_empty():
			var mountain_conn := _validate_connectivity(result, start_cell, required_cells)
			if mountain_conn.get("ok", false):
				debug_regions.append(mountain_region)
			else:
				result = mountain_snapshot
				var conn_detail := "start=%s reachable=%d missing=%s" % [str(start_cell), mountain_conn.get("reachable_count", 0), str(mountain_conn.get("missing_required", []))]
				warnings.append("WARNING: TerrainBuilder discarded mountain boundary because it newly broke connectivity: %s. seed=%s map=%s" % [conn_detail, terrain_seed, str(map_rect)])
	_marks["mountain_boundary"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if bool(context.get("enable_industrial_platform", true)):
		var platform_snapshot := result.duplicate(true)
		var platform_region := _place_industrial_platform(map_rect, rng, result, required_cells)
		if not platform_region.is_empty():
			var platform_conn := _validate_connectivity(result, start_cell, required_cells)
			if platform_conn.get("ok", false):
				debug_regions.append(platform_region)
			else:
				result = platform_snapshot
				var conn_detail := "start=%s reachable=%d missing=%s" % [str(start_cell), platform_conn.get("reachable_count", 0), str(platform_conn.get("missing_required", []))]
				warnings.append("WARNING: TerrainBuilder discarded elevated platform because it newly broke connectivity: %s. seed=%s map=%s" % [conn_detail, terrain_seed, str(map_rect)])
	_marks["industrial_platform"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	var connectivity := _validate_connectivity(result, start_cell, required_cells)
	_marks["connectivity_validate"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()
	
	if not bool(connectivity.get("ok", true)):
		var missing_str: String = str(connectivity.get("missing_required", []))
		var reachable_count: int = connectivity.get("reachable_count", 0)
		if not quiet_candidate_warnings:
			push_warning("TerrainBuilder connectivity failed.")
			push_warning("  seed=%s map_rect=%s" % [terrain_seed, str(map_rect)])
			push_warning("  start_cell=%s" % str(start_cell))
			push_warning("  reachable_cells=%d missing_required=%s" % [reachable_count, missing_str])
		if DEBUG_CONNECTIVITY_MAP:
			_debug_print_connectivity_map(result, connectivity)
		# Attempt rescue: clear blockers along shortest path from start to each missing required cell.
		# This preserves terrain features while guaranteeing connectivity.
		var rescued := _rescue_connectivity(result, start_cell, connectivity.get("missing_required", []))
		rescue_carved_cells += rescued
		_marks["rescue_connectivity"] = Time.get_ticks_msec() - _last
		_last = Time.get_ticks_msec()
		if rescued:
			connectivity = _validate_connectivity(result, start_cell, required_cells)
			var rescued_str: String = str(connectivity.get("missing_required", []))
			if not quiet_candidate_warnings:
				push_warning("  rescue carved %d cells, re-validated: missing=%s reachable=%d" % [rescued, rescued_str, connectivity.get("reachable_count", 0)])
			if not bool(connectivity.get("ok", true)):
				result = _build_baseline(map_rect, context)
				connectivity = _validate_connectivity(result, start_cell, required_cells)
				fallback_used = true
				warnings.append("WARNING: TerrainBuilder fell back to baseline terrain after connectivity validation failed. seed=%s start=%s reachable=%d missing=%s" % [terrain_seed, str(start_cell), reachable_count, missing_str])
			else:
				warnings.append("TerrainBuilder rescued connectivity by carving %d cells toward missing required targets. seed=%s" % [rescued, terrain_seed])
		else:
			result = _build_baseline(map_rect, context)
			connectivity = _validate_connectivity(result, start_cell, required_cells)
			fallback_used = true
			warnings.append("WARNING: TerrainBuilder fell back to baseline terrain after connectivity validation failed (rescue failed). seed=%s start=%s reachable=%d missing=%s" % [terrain_seed, str(start_cell), reachable_count, missing_str])

	_marks["connectivity_rescue"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	result["debug_regions"] = debug_regions
	result["regions"] = debug_regions
	result["warnings"] = warnings
	result["connectivity"] = connectivity
	result["fallback_used"] = fallback_used
	result["seed"] = terrain_seed
	result["map_rect"] = map_rect
	result["generation_mode"] = generation_mode
	result["required_cell_count"] = required_cells.size()
	result["missing_required_count"] = (connectivity.get("missing_required", []) as Array).size()
	result["rescue_carved_cells"] = rescue_carved_cells
	result["baseline_rescue_carved_cells"] = baseline_rescue_carved_cells
	result["debug_summary"] = _build_debug_summary(result)
	_last_result = result.duplicate(true)
	
	var _total := Time.get_ticks_msec() - _t_start
	print("[TerrainBuilder] === PHASES ===")
	for _k in _marks:
		print("[TerrainBuilder]   %s: %d ms" % [_k, _marks[_k]])
	print("[TerrainBuilder]   TOTAL: %d ms" % _total)
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


func _apply_reserved_region_elevation(result: Dictionary, reserved_regions: Array) -> Dictionary:
	var applied_count := 0
	var elevated_count := 0
	for raw_region in reserved_regions:
		if not (raw_region is Dictionary):
			continue
		var region := raw_region as Dictionary
		var rect: Rect2i = region.get("rect", Rect2i())
		var runtime_height := clampi(int(region.get("runtime_height", HEIGHT_GROUND)), HEIGHT_GROUND, HEIGHT_ELEVATED)
		var kind := String(region.get("kind", "intent_region"))
		for x in range(rect.position.x, rect.end.x):
			for y in range(rect.position.y, rect.end.y):
				var cell := Vector2i(x, y)
				if not (result.get("height_by_cell", {}) as Dictionary).has(cell):
					continue
				var tile_id := TerrainTileIdsScript.industrial("elevated_floor") if runtime_height > HEIGHT_GROUND else NO_VISUAL_TILE
				var traversal := TRAVERSAL_WALKABLE
				if runtime_height > HEIGHT_GROUND and _is_rect_edge_cell(rect, cell):
					traversal = TRAVERSAL_STAIR
				_set_result_cell(
					result,
					cell,
					runtime_height,
					traversal,
					TerrainType.INDUSTRIAL_PLATFORM if runtime_height > HEIGHT_GROUND else TerrainType.GROUND,
					tile_id
				)
				if kind == "story_room" or kind == "faction_site":
					(result.get("ramp_dir_by_cell", {}) as Dictionary).erase(cell)
				applied_count += 1
				if runtime_height > HEIGHT_GROUND:
					elevated_count += 1
	if applied_count <= 0:
		return {}
	return {
		"type": "worldgen_reserved_regions",
		"cell_count": applied_count,
		"elevated_count": elevated_count,
	}


func _is_rect_edge_cell(rect: Rect2i, cell: Vector2i) -> bool:
	return cell.x == rect.position.x \
			or cell.y == rect.position.y \
			or cell.x == rect.end.x - 1 \
			or cell.y == rect.end.y - 1


func _validate_connectivity(result: Dictionary, start_cell: Vector2i, required_cells: Array[Vector2i]) -> Dictionary:
	if start_cell == Vector2i(2147483647, 2147483647):
		return {"ok": true, "reason": "no_start_cell", "start_cell": start_cell, "reachable_count": 0, "walkable_count": 0, "missing_required": []}
	var traversal_by_cell: Dictionary = result.get("traversal_by_cell", {})
	var walkable_count := 0
	for traversal in traversal_by_cell.values():
		if _is_walkable_traversal(String(traversal)):
			walkable_count += 1
	if not _is_walkable_traversal(_traversal_from_result(result, start_cell)):
		return {"ok": false, "reason": "start_not_walkable", "start_cell": start_cell, "reachable_count": 0, "walkable_count": walkable_count, "missing_required": [start_cell]}
	var reachable := _flood_fill(result, start_cell)
	var missing: Array[Vector2i] = []
	for cell in required_cells:
		if _has_cell(result, cell) and _is_walkable_traversal(_traversal_from_result(result, cell)) and not reachable.has(cell):
			missing.append(cell)
	return {
		"ok": missing.is_empty(),
		"reason": "ok" if missing.is_empty() else "required_target_unreachable",
		"start_cell": start_cell,
		"reachable_count": reachable.size(),
		"walkable_count": walkable_count,
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
		"required_cell_count": int(result.get("required_cell_count", 0)),
		"missing_required_count": int(result.get("missing_required_count", 0)),
		"rescue_carved_cells": int(result.get("rescue_carved_cells", 0)),
		"baseline_rescue_carved_cells": int(result.get("baseline_rescue_carved_cells", 0)),
		"generation_mode": String(result.get("generation_mode", "FINAL_VISUAL")),
	}


func _rescue_connectivity(result: Dictionary, start_cell: Vector2i, missing_required: Array) -> int:
	if missing_required.is_empty():
		return 0
	if not _has_cell(result, start_cell):
		return 0
	var carved := 0
	for target in missing_required:
		if not (target is Vector2i):
			continue
		var t := target as Vector2i
		if not _has_cell(result, t):
			continue
		carved += _carve_manhattan_corridor(result, start_cell, t, 2)
	return carved


func _carve_manhattan_corridor(result: Dictionary, from_cell: Vector2i, to_cell: Vector2i, radius: int = 1) -> int:
	var carved := 0
	var cursor := from_cell
	carved += _force_walkable_disk(result, cursor, radius)
	while cursor.x != to_cell.x:
		cursor.x += 1 if to_cell.x > cursor.x else -1
		carved += _force_walkable_disk(result, cursor, radius)
	while cursor.y != to_cell.y:
		cursor.y += 1 if to_cell.y > cursor.y else -1
		carved += _force_walkable_disk(result, cursor, radius)
	return carved


func _force_walkable_disk(result: Dictionary, center: Vector2i, radius: int) -> int:
	var carved := 0
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var cell := center + Vector2i(dx, dy)
			if _force_walkable_cell(result, cell):
				carved += 1
	return carved


func _force_walkable_cell(result: Dictionary, cell: Vector2i) -> bool:
	var height_by_cell: Dictionary = result.get("height_by_cell", {})
	var traversal_by_cell: Dictionary = result.get("traversal_by_cell", {})
	var ramp_dir_by_cell: Dictionary = result.get("ramp_dir_by_cell", {})
	var blocked_cells: Dictionary = result.get("blocked_cells", {})
	var changed := not _has_cell(result, cell)
	if int(height_by_cell.get(cell, HEIGHT_GROUND)) != HEIGHT_GROUND:
		changed = true
	if String(traversal_by_cell.get(cell, TRAVERSAL_WALKABLE)) != TRAVERSAL_WALKABLE:
		changed = true
	if blocked_cells.has(cell) or ramp_dir_by_cell.has(cell):
		changed = true
	_set_result_cell(result, cell, HEIGHT_GROUND, TRAVERSAL_WALKABLE, TerrainType.GROUND, "rescue_walkable_ground")
	return changed


func _debug_print_connectivity_map(result: Dictionary, connectivity: Dictionary) -> void:
	var height_by_cell: Dictionary = result.get("height_by_cell", {})
	var traversal_by_cell: Dictionary = result.get("traversal_by_cell", {})
	var missing: Array = connectivity.get("missing_required", [])
	var missing_lookup := {}
	for cell in missing:
		missing_lookup[cell] = true

	# Determine bounds from the result data
	var min_cell := Vector2i(999999, 999999)
	var max_cell := Vector2i(-999999, -999999)
	for cell in height_by_cell.keys():
		if cell is Vector2i:
			var c := cell as Vector2i
			min_cell = Vector2i(mini(min_cell.x, c.x), mini(min_cell.y, c.y))
			max_cell = Vector2i(maxi(max_cell.x, c.x), maxi(max_cell.y, c.y))
	if min_cell.x == 999999:
		return

	# Flood fill to get reachable cells
	var start_cell := Vector2i(2147483647, 2147483647)
	for cell in missing_lookup.keys():
		start_cell = cell as Vector2i
		break
	if start_cell.x == 2147483647:
		return
	var reachable := _flood_fill(result, start_cell)

	push_warning("--- ASCII connectivity map (S=start T=target .=reachable ?=walkable_but_disconnected #=blocked_terrain) ---")
	var map_width := min_cell.distance_to(Vector2i(max_cell.x, min_cell.y)) + 1
	if map_width > 200:
		push_warning("Map too wide (%d), skipping ASCII dump." % map_width)
		return
	for y in range(min_cell.y, max_cell.y + 1):
		var line := ""
		for x in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(x, y)
			if not _has_cell(result, cell):
				line += " "
				continue
			if missing_lookup.has(cell):
				line += "T"
			elif cell == start_cell:
				line += "S"
			elif reachable.has(cell):
				line += "."
			elif _is_walkable_traversal(String(traversal_by_cell.get(cell, TRAVERSAL_BLOCKED))):
				line += "?"
			else:
				line += "#"
		push_warning(line)
	push_warning("--- end connectivity map ---")


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
