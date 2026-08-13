extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	root.add_child(map)
	await process_frame
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	map.procgen_node = procgen
	procgen.map_size = Vector2i(40, 30)
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = true
	map.claim_procgen_floor_rect_for_authored_scene_tiles(
		Vector2i(20, 20), Vector2i(22, 8), "test_mainland", "test", 0
	)
	map.claim_world_overlook_pocket(
		Vector2i(20, 6), Vector2i(9, 10),
		{"initially_isolated": true, "gap_depth_tiles": 2}
	)
	var before := map.get_runtime_health_snapshot()
	var floor_before := map.debug_get_generated_floor_cells()
	var plan := map.evaluate_runtime_walkable_connector(
		map.tile_to_global_position(Vector2i(20, 10)), Vector2i.DOWN,
		3, 18, "ash_bell_threadway", "white_thread"
	)
	_check(bool(plan.get("ok", false)), "connector dry-run failed")
	_check(map.debug_get_generated_floor_cells() == floor_before, "dry-run mutated floor authority")
	_check(map.get_runtime_health_snapshot().get("runtime_terrain_commit_count") == before.get("runtime_terrain_commit_count"), "Observatory/dry-run sampling incremented terrain commits")
	var result := map.resolve_runtime_walkable_connector(
		map.tile_to_global_position(Vector2i(20, 10)), Vector2i.DOWN,
		3, 18, "ash_bell_threadway", "white_thread"
	)
	_check(bool(result.get("ok", false)), "connector commit failed")
	await process_frame
	await process_frame
	var after := map.get_runtime_health_snapshot()
	_check(int(after.get("runtime_terrain_commit_count", 0)) == int(before.get("runtime_terrain_commit_count", 0)) + 1, "terrain batch was not counted exactly once")
	_check(int(after.get("runtime_connector_commit_count", 0)) == int(before.get("runtime_connector_commit_count", 0)) + 1, "connector commit was not counted exactly once")
	_check(int(after.get("walkable_boundary_rebuild_count", 0)) == int(before.get("walkable_boundary_rebuild_count", 0)) + 1, "boundary rebuild was not counted exactly once")
	_check(int(after.get("navigation_rebuild_completed_count", 0)) >= int(before.get("navigation_rebuild_completed_count", 0)) + 1, "navigation completion was not counted")
	_check(int(after.get("walkable_boundary_shape_count", 0)) > 0, "boundary shape count is empty")
	var observatory := root.get_node_or_null("DevObservatory")
	if observatory != null:
		var recent := observatory.call("_get_recent_procgen_mutations", 16) as Array
		_check(not recent.is_empty(), "procgen mutation history was not retained")
		var exported := observatory.call(
			"export_session_json",
			"user://dev_observatory/procgen_runtime_health_smoke.json"
		) as String
		_check(not exported.is_empty(), "procgen runtime health export failed")
	map.queue_free()
	await process_frame
	if _errors.is_empty():
		print("[ProcgenRuntimeHealthSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenRuntimeHealthSmoke] %s" % error)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
