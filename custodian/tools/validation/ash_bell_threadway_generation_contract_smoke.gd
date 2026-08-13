extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const SEED_COUNT := 16

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for seed in range(SEED_COUNT):
		await _validate_seed(seed)
	if _errors.is_empty():
		print("[AshBellThreadwayGenerationContractSmoke] PASS seeds=%d" % SEED_COUNT)
		quit(0)
		return
	for error in _errors:
		push_error("[AshBellThreadwayGenerationContractSmoke] %s" % error)
	quit(1)


func _validate_seed(seed: int) -> void:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	root.add_child(map)
	await process_frame
	var duplicate := map.get_node_or_null("ProcGen")
	if duplicate != null:
		duplicate.queue_free()
		await process_frame
	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	map.procgen_node = procgen
	procgen.map_size = Vector2i(48, 36)
	procgen.seed = seed
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = true
	var lateral := (seed % 7) - 3
	var mainland_center := Vector2i(24 + lateral, 21 + (seed % 3))
	map.claim_procgen_floor_rect_for_authored_scene_tiles(
		mainland_center, Vector2i(25, 8), "generated_mainland", "test", 0
	)
	var pocket := map.claim_world_overlook_pocket(
		Vector2i(24, 6), Vector2i(9, 10),
		{"initially_isolated": true, "gap_depth_tiles": 2}
	)
	var start := Vector2i(24, 10)
	var before := map.debug_get_generated_floor_cells()
	var plan := map.evaluate_runtime_walkable_connector(
		map.tile_to_global_position(start), Vector2i.DOWN, 3, 18,
		"ash_bell_threadway", "white_thread"
	)
	_check(pocket.has_area(), seed, "pocket placement failed", plan)
	_check(not _component_from(map.get_player_spawn(), before).has(start), seed, "pocket was connected before Knot", plan)
	_check(bool(plan.get("ok", false)), seed, "canonical dry-run failed", plan)
	_check(map.debug_get_generated_floor_cells() == before, seed, "dry-run mutated floor", plan)
	var result := map.resolve_runtime_walkable_connector(
		map.tile_to_global_position(start), Vector2i.DOWN, 3, 18,
		"ash_bell_threadway", "white_thread"
	)
	_check(bool(result.get("ok", false)), seed, "commit failed", result)
	var repeat := map.resolve_runtime_walkable_connector(
		map.tile_to_global_position(start), Vector2i.DOWN, 3, 18,
		"ash_bell_threadway", "white_thread"
	)
	_check(bool(repeat.get("already_connected", false)), seed, "repeat was not a no-op", repeat)
	map.queue_free()
	await process_frame


func _component_from(origin: Vector2i, floor: Dictionary) -> Dictionary:
	var result := {}
	if not floor.has(origin):
		return result
	var pending: Array[Vector2i] = [origin]
	result[origin] = true
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_front()
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var neighbor: Vector2i = cell + direction
			if floor.has(neighbor) and not result.has(neighbor):
				result[neighbor] = true
				pending.append(neighbor)
	return result


func _check(condition: bool, seed: int, message: String, diagnostic: Dictionary) -> void:
	if not condition:
		_errors.append("seed=%d %s diagnostic=%s" % [seed, message, diagnostic])
