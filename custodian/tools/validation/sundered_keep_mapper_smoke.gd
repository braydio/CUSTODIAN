extends SceneTree

const MAPPER_SCENE := preload("res://scenes/debug/sundered_keep_mapper.tscn")
const LEVEL_PATH := "res://content/levels/sundered_keep/sundered_keep_front_gate_large.json"
const COLLISION_PATH := "res://content/levels/sundered_keep/sundered_keep_underlay_collision.json"

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var mapper := MAPPER_SCENE.instantiate()
	if mapper == null:
		_finish(["could not instantiate unified Sundered Keep mapper"])
		return
	root.add_child(mapper)
	await process_frame
	await process_frame

	_assert(
		mapper.has_method("get_sundered_keep_mapper_state"),
		"unified mapper state API is missing"
	)
	var state := mapper.call("get_sundered_keep_mapper_state") as Dictionary
	_assert(str(state.get("mapping_path", "")) == LEVEL_PATH, "mapper does not edit production level data")
	_assert(str(state.get("collision_path", "")) == COLLISION_PATH, "mapper does not own production collision data")
	_assert(int(state.get("feature_count", 0)) >= 200, "mapper does not expose complete authored feature records")
	_assert((state.get("palette", []) as Array).size() == 99, "mapper lost the 01-99 tile palette")
	_assert(mapper.has_method("_load_underlay_selection_as_stamp"), "mapper lost underlay stamp sampling")
	_assert(mapper.has_method("_begin_paint_drag"), "mapper lost drag painting")
	_assert(mapper.has_method("_undo") and mapper.has_method("_redo"), "mapper lost undo/redo")
	_assert(mapper.has_method("_apply_collision_drafts"), "mapper cannot author collision rails")
	_assert(mapper.has_method("_move_selected_feature"), "mapper cannot move production features")
	for retired_path in [
		"res://scenes/debug/sundered_keep_approach_collision_mapper.tscn",
		"res://scenes/debug/sundered_keep_underlay_collision_mapper.tscn",
		"res://scenes/debug/sundered_keep_underlay_gameplay_tile_mapper.tscn",
		"res://content/levels/sundered_keep/sundered_keep_underlay_gameplay_tiles.json",
		"res://content/levels/sundered_keep/gatehouse_siege_config.json",
	]:
		_assert(not FileAccess.file_exists(retired_path), "retired mapper authority still exists: %s" % retired_path)

	var level := _read_json(LEVEL_PATH)
	var collision := _read_json(COLLISION_PATH)
	_assert(str(level.get("mapper_schema", "")) == "custodian.sundered_keep.mapper.v1", "level lacks unified mapper authority")
	_assert(str(level.get("layout_generator", "")) == "res://scenes/debug/sundered_keep_mapper.tscn", "retired generator still owns layout")
	_assert(level.has("mapper_placements"), "production level lacks mapper placement channel")
	_assert(not (level.get("siege", {}) as Dictionary).is_empty(), "siege placement is not mapper-owned")
	_assert(_has_marker(level, "great_hall_marine_spawn"), "marine spawn is not mapper-authored")
	_assert(_has_marker(level, "routekeeper_trace"), "routekeeper placement is not mapper-authored")
	_assert((collision.get("segments", []) as Array).size() == 127, "canonical mapper collision rail count drifted")
	_assert((collision.get("markers", {}) as Dictionary).size() == 7, "canonical mapper marker count drifted")
	var spawn_tile := _marker_tile(level, "spawn")
	var collision_spawn := _collision_marker_position(collision, "spawn")
	_assert(
		collision_spawn == Vector2(spawn_tile * 32) + Vector2(16.0, 16.0),
		"level and collision spawn markers diverged"
	)
	var minimum_spawn_clearance := _minimum_rail_distance(
		collision_spawn,
		collision.get("segments", []) as Array
	)
	_assert(
		minimum_spawn_clearance > float(collision.get("rail_radius", 18.0)) + 16.0,
		"mapper-authored spawn overlaps a collision rail"
	)

	var preview := state.get("underlay_scene") as Node
	_assert(preview != null and preview.name == "ProductionSunderedKeepPreview", "mapper does not preview actual runtime level")
	_assert(preview != null and preview.get_node_or_null("MappedUnderlayBounds/UnderlayBoundaryCollision") != null, "runtime preview did not consume mapper collision")
	var runtime_state := preview.call("get_sundered_keep_debug_state") as Dictionary
	_assert(int(runtime_state.get("blocker_bodies", 0)) == 2, "runtime created permanent non-mapper blocker bodies")

	mapper.queue_free()
	await process_frame
	_finish(_errors)


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_errors.append("missing JSON: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	_errors.append("invalid JSON: %s" % path)
	return {}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _has_marker(level: Dictionary, marker_id: String) -> bool:
	for marker_variant: Variant in level.get("markers", []):
		if str((marker_variant as Dictionary).get("id", "")) == marker_id:
			return true
	return false


func _marker_tile(level: Dictionary, marker_id: String) -> Vector2i:
	for marker_variant: Variant in level.get("markers", []):
		var marker := marker_variant as Dictionary
		if str(marker.get("id", "")) != marker_id:
			continue
		var tile := marker.get("tile", []) as Array
		if tile.size() >= 2:
			return Vector2i(int(tile[0]), int(tile[1]))
	_errors.append("missing tile marker: %s" % marker_id)
	return Vector2i.ZERO


func _collision_marker_position(collision: Dictionary, marker_id: String) -> Vector2:
	var marker := (collision.get("markers", {}) as Dictionary).get(marker_id, {}) as Dictionary
	var position := marker.get("position", []) as Array
	if position.size() >= 2:
		return Vector2(float(position[0]), float(position[1]))
	_errors.append("missing collision marker: %s" % marker_id)
	return Vector2.ZERO


func _minimum_rail_distance(point: Vector2, segments: Array) -> float:
	var minimum := INF
	for segment_variant: Variant in segments:
		var segment := segment_variant as Array
		if segment.size() < 2:
			continue
		var start_values := segment[0] as Array
		var end_values := segment[1] as Array
		if start_values.size() < 2 or end_values.size() < 2:
			continue
		var start := Vector2(float(start_values[0]), float(start_values[1]))
		var end := Vector2(float(end_values[0]), float(end_values[1]))
		var closest := Geometry2D.get_closest_point_to_segment(point, start, end)
		minimum = minf(minimum, point.distance_to(closest))
	return minimum


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[SunderedKeepMapperSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepMapperSmoke] %s" % error)
	quit(1)
