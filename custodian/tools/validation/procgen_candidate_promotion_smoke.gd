extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const CONTRACT_MAP_SCRIPT := preload("res://game/world/procgen/custodian_contract_map.gd")
const NAVIGATION_SCRIPT := preload("res://game/systems/core/systems/navigation_system.gd")
const SEED := 3716816988
const MAP_SIZE := Vector2i(72, 64)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map := PROCGEN_MAP_SCENE.instantiate()
	root.add_child(map)
	var tilemap := map as ProcGenTilemap
	assert(tilemap != null)

	var duplicate_tilemap := map.get_node_or_null("ProcGen")
	if duplicate_tilemap != null:
		duplicate_tilemap.queue_free()
		await process_frame

	var procgen := map.get_node("ProcGen2") as ProcGen
	assert(procgen != null)
	procgen.generate_seed = false
	procgen.seed = SEED
	procgen.map_size = MAP_SIZE

	tilemap.generation_evaluation_mode = true
	tilemap.generation_output_enabled = true
	tilemap.enable_streaming_reveal = true
	tilemap.build_runtime_wall_collision = false
	tilemap.show_runtime_wall_collision_debug = false
	tilemap.enable_final_foliage = false
	tilemap.enable_ruin_prop_spawning = false
	tilemap.interior_prop_spawning_enabled = false
	tilemap.generate()

	for _frame in range(360):
		if bool(tilemap.get("_evaluated_candidate_ready")):
			break
		await process_frame
	assert(
		bool(tilemap.get("_evaluated_candidate_ready")),
		"Timed out waiting for evaluated candidate state."
	)

	var generation_id_before := int(tilemap.get("_debug_generation_id"))
	var floor_before := _cell_fingerprint(
		tilemap.debug_get_generated_floor_cells()
	)
	var walls_before := _cell_fingerprint(
		tilemap.debug_get_generated_wall_cells()
	)
	var terrain_before: Dictionary = (
		tilemap.get_level_data().get("terrain_builder", {}) as Dictionary
	).duplicate(true)
	var painted_before := tilemap.get_floor_tilemap().get_used_cells().size()

	var contract_map := CONTRACT_MAP_SCRIPT.new()
	contract_map.auto_generate_on_ready = false
	var promoted: Dictionary = await contract_map._generate_final_map_level_data(
		tilemap
	)
	await process_frame

	assert(not promoted.is_empty(), "Candidate promotion returned no level data.")
	assert(not tilemap.generation_evaluation_mode)
	assert(
		int(tilemap.get("_debug_generation_id")) == generation_id_before,
		"Promotion invoked a second structural generation."
	)
	assert(
		_cell_fingerprint(tilemap.debug_get_generated_floor_cells())
		== floor_before,
		"Promotion changed accepted floor authority."
	)
	assert(
		_cell_fingerprint(tilemap.debug_get_generated_wall_cells())
		== walls_before,
		"Promotion changed accepted wall authority."
	)
	assert(
		promoted.get("terrain_builder", {}) == terrain_before,
		"Promotion rebuilt or changed accepted terrain semantics."
	)
	assert(
		tilemap.get_floor_tilemap().get_used_cells().size() == painted_before,
		"Promotion exposed additional streamed floor cells."
	)

	var navigation := NAVIGATION_SCRIPT.new()
	root.add_child(navigation)
	navigation.set_runtime_tilemaps(
		tilemap.get_floor_tilemap(),
		tilemap.get_walls_tilemap(),
		tilemap
	)
	navigation.rebuild()
	var navigation_before: Dictionary = (
		navigation.get_navigation_authority_debug_snapshot()
	)
	assert(
		int(navigation_before["authoritative_floor_count"])
		== floor_before.size()
	)
	assert(
		int(navigation_before["painted_floor_count"]) == painted_before
	)

	tilemap.streaming_reveal_tiles_per_frame = 100000
	for _frame in range(32):
		if (tilemap.get("_streaming_reveal_queue") as Array).is_empty():
			break
		tilemap.call("_process_streaming_reveal_queue", 0.0)
	navigation.rebuild()
	var navigation_after: Dictionary = (
		navigation.get_navigation_authority_debug_snapshot()
	)
	assert(
		int(navigation_after["authoritative_floor_count"])
		== int(navigation_before["authoritative_floor_count"]),
		"Streaming reveal changed authoritative floor count."
	)
	assert(
		int(navigation_after["painted_floor_count"])
		> int(navigation_before["painted_floor_count"]),
		"Streaming reveal did not expand painted floor authority."
	)
	assert(
		int(navigation_after["navigation_point_count"])
		> int(navigation_before["navigation_point_count"]),
		"Navigation did not expand after streamed tiles were painted."
	)

	print(
		(
			"[ProcgenCandidatePromotionSmoke] PASS generation_id=%d "
			+ "floor=%d walls=%d painted=%d"
		) % [
			generation_id_before,
			floor_before.size(),
			walls_before.size(),
			painted_before,
		]
	)
	map.queue_free()
	navigation.queue_free()
	contract_map.free()
	await process_frame
	quit(0)


func _cell_fingerprint(cells: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	for cell_variant: Variant in cells.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		var data := cells[cell] as Dictionary
		rows.append(
			"%d,%d:%d:%s:%d"
			% [
				cell.x,
				cell.y,
				int(data.get("source_id", -1)),
				str(data.get("atlas", Vector2i(-1, -1))),
				int(data.get("alternative", 0)),
			]
		)
	rows.sort()
	return rows
