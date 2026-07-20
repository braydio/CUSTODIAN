extends SceneTree

const MAPPER_SCENE := preload("res://scenes/debug/level_collision_poi_mapper.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var mapper := MAPPER_SCENE.instantiate()
	mapper.set("target_scene_path", "res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")
	mapper.set("target_script_path", "res://game/world/approaches/sundered_keep/sundered_keep_approach.gd")
	root.add_child(mapper)
	await process_frame
	await process_frame
	var errors: Array[String] = []
	var state := mapper.call("get_collision_mapper_state") as Dictionary
	if state.get("target_level") == null: errors.append("generic mapper did not load target")
	if state.get("approach") != state.get("target_level"): errors.append("legacy approach alias is not preserved")
	var marker_ids: Array = state.get("marker_kinds", [])
	for expected in ["spawn", "return_causeway", "level_exit"]:
		if not marker_ids.has(expected): errors.append("dynamic marker schema missing %s" % expected)
	for stale in ["gatehouse_key", "main_gate", "enemy_spawn_west", "enemy_spawn_gate"]:
		if marker_ids.has(stale): errors.append("stale Sundered marker remains: %s" % stale)
	var replacement_lines: Array[String] = ["[Vector2(1.0, 2.0), Vector2(3.0, 4.0)],"]
	var replacement := str(mapper.call("_format_boundary_segments_const", replacement_lines))
	var replaced := str(mapper.call("_replace_boundary_segments_block", "const BOUNDARY_SEGMENTS := [\n]\n", replacement))
	if not replaced.contains("Vector2(3.0, 4.0)"): errors.append("boundary replacement helper failed")
	var marker_text := str(mapper.call("_format_authoring_markers_const"))
	if not marker_text.contains("\"node_name\"") or not marker_text.contains("\"spawn\""):
		errors.append("marker formatter omitted generic schema data")
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[LevelCollisionPoiMapperSmoke] PASS")
		quit(0)
		return
	for error in errors: push_error("[LevelCollisionPoiMapperSmoke] %s" % error)
	quit(1)
