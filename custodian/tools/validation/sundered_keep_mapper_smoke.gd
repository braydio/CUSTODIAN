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
	_assert(int(state.get("feature_count", 0)) >= 50, "mapper does not expose retained gameplay feature records")
	_assert((state.get("placements", []) as Array).is_empty(), "mapper did not start with zero manual placements")
	_assert((state.get("palette", []) as Array).size() == 99, "mapper lost the 01-99 tile palette")
	_assert(mapper.has_method("_load_underlay_selection_as_stamp"), "mapper lost underlay stamp sampling")
	_assert(mapper.has_method("_begin_paint_drag"), "mapper lost drag painting")
	_assert(mapper.has_method("_undo") and mapper.has_method("_redo"), "mapper lost undo/redo")
	_assert(mapper.has_method("_apply_collision_drafts"), "mapper cannot author collision rails")
	_test_immediate_placement_preview(mapper)
	_assert(mapper.has_method("_move_selected_feature"), "mapper cannot move production features")
	_assert(
		mapper.has_method("select_feature_at_tile")
		and mapper.has_method("select_feature_by_label"),
		"mapper cannot select production features spatially"
	)
	_assert(
		mapper.has_method("create_selected_feature_at_tile"),
		"mapper cannot create production features"
	)
	var feature_entries := state.get("feature_entries", []) as Array
	_assert(
		not feature_entries.is_empty()
		and _has_feature_label(
			feature_entries,
			"bundle/return_mooring"
		),
		"Return Mooring is not exposed as a complete feature bundle"
	)
	for entry_variant: Variant in feature_entries:
		var entry := entry_variant as Dictionary
		_assert(
			entry.has("anchor") and entry.has("bounds"),
			"feature lacks spatial selection metadata: %s"
			% str(entry.get("label", "unknown"))
		)
	_test_feature_authoring(mapper)
	# Historical/debug mapper scenes may remain on disk, but only the unified
	# mapper's production documents may be runtime authority.
	for retired_path in [
		"res://content/levels/sundered_keep/sundered_keep_underlay_gameplay_tiles.json",
		"res://content/levels/sundered_keep/gatehouse_siege_config.json",
	]:
		_assert(not FileAccess.file_exists(retired_path), "retired runtime data authority still exists: %s" % retired_path)

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
	_assert(
		preview != null
		and preview.process_mode == Node.PROCESS_MODE_DISABLED,
		"production preview can still consume mapper authoring input"
	)
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


func _has_feature_label(entries: Array, label: String) -> bool:
	for entry_variant: Variant in entries:
		if str((entry_variant as Dictionary).get("label", "")) == label:
			return true
	return false


func _test_immediate_placement_preview(mapper: Node) -> void:
	var placed_root := mapper.get_node("World/PlacedGameplayTiles") as Node2D
	_assert(placed_root.z_as_relative == false, "placement preview is not absolute-depth")
	mapper.set("_selected_tile_number", 1)
	_assert(
		bool(mapper.call("_place_selected_tile", Vector2i(10, 10))),
		"palette tile could not be placed in mapper memory"
	)
	_assert(
		placed_root.get_child_count() == 1
		and placed_root.get_child(0) is Sprite2D,
		"palette placement did not create an immediate visible preview sprite"
	)
	mapper.set("_active_underlay_stamp", {
		"type": "underlay_stamp",
		"source_rect_cells": [0, 0, 2, 2],
		"tile_size": 32,
		"category": "underlay_sample",
	})
	_assert(
		bool(mapper.call("_place_underlay_stamp", Vector2i(14, 10))),
		"underlay stamp could not be placed in mapper memory"
	)
	_assert(
		placed_root.get_child_count() == 2
		and placed_root.get_child(1) is Sprite2D,
		"underlay placement did not create an immediate visible preview sprite"
	)
	mapper.call("_clear_placements")


func _test_feature_authoring(mapper: Node) -> void:
	_assert(
		bool(mapper.call(
			"select_feature_by_label",
			"bundle/return_mooring"
		)),
		"Return Mooring bundle cannot be selected"
	)
	var target := Vector2i(20, 50)
	_assert(
		bool(mapper.call("move_selected_feature_to_tile", target)),
		"Return Mooring bundle cannot be moved"
	)
	var moved := mapper.call(
		"get_feature_authoring_document"
	) as Dictionary
	_assert(
		_find_record_origin(
			moved.get("ops", []) as Array,
			"module_id",
			"return_mooring_3x3_01"
		) == target,
		"Return Mooring module did not move with its bundle"
	)
	_assert(
		_find_record_origin(
			moved.get("markers", []) as Array,
			"id",
			"return_mooring_origin"
		) == target,
		"Return Mooring origin marker did not move with its bundle"
	)
	_assert(
		_find_record_origin(
			moved.get("markers", []) as Array,
			"id",
			"return_mooring"
		) == target + Vector2i(2, 2),
		"Return Mooring interaction marker lost its bundle offset"
	)
	_assert(
		_find_record_origin(
			moved.get("shore_walk_regions", []) as Array,
			"id",
			"return_mooring_lower_shore"
		) == target + Vector2i(0, 1),
		"Return Mooring shore region did not move with its bundle"
	)
	_assert(
		bool(mapper.call(
			"select_feature_at_tile",
			target + Vector2i(2, 2)
		)),
		"moved Return Mooring cannot be selected from the map"
	)
	var selected_state := mapper.call(
		"get_sundered_keep_mapper_state"
	) as Dictionary
	_assert(
		str(
			(selected_state.get(
				"selected_feature",
				{}
			) as Dictionary).get("label", "")
		) == "bundle/return_mooring",
		"Return Mooring map hit selected a partial overlapping record"
	)

	var shore_label := (
		"shore_walk_regions/lower_storm_shore_approach"
	)
	_assert(
		bool(mapper.call("select_feature_by_label", shore_label)),
		"generic shore feature cannot be selected"
	)
	var before_count := (
		moved.get("shore_walk_regions", []) as Array
	).size()
	_assert(
		bool(mapper.call(
			"create_selected_feature_at_tile",
			Vector2i(8, 8)
		)),
		"generic spatial feature cannot be created"
	)
	var created := mapper.call(
		"get_feature_authoring_document"
	) as Dictionary
	var created_shores := (
		created.get("shore_walk_regions", []) as Array
	)
	_assert(
		created_shores.size() == before_count + 1,
		"feature creation did not append a production record"
	)
	_assert(
		_find_record_origin(
			created_shores,
			"id",
			"lower_storm_shore_approach_copy_02"
		) == Vector2i(8, 8),
		"created feature lacks a unique identity or requested position"
	)
	mapper.call("_undo_feature_edit")
	var undone := mapper.call(
		"get_feature_authoring_document"
	) as Dictionary
	_assert(
		(undone.get("shore_walk_regions", []) as Array).size()
			== before_count,
		"feature creation is not undoable"
	)
	mapper.call("_redo_feature_edit")
	var redone := mapper.call(
		"get_feature_authoring_document"
	) as Dictionary
	_assert(
		(redone.get("shore_walk_regions", []) as Array).size()
			== before_count + 1,
		"feature creation is not redoable"
	)


func _find_record_origin(
	records: Array,
	key: String,
	value: String
) -> Vector2i:
	for record_variant: Variant in records:
		var record := record_variant as Dictionary
		if str(record.get(key, "")) != value:
			continue
		for spatial_key in ["origin", "tile", "rect"]:
			var position := record.get(spatial_key, []) as Array
			if position.size() >= 2:
				return Vector2i(
					int(position[0]),
					int(position[1])
				)
	return Vector2i(-999, -999)


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
