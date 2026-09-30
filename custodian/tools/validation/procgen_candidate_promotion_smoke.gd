extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const CONTRACT_MAP_SCENE := preload("res://game/world/procgen/custodian_contract_map.tscn")
const NAVIGATION_SCRIPT := preload("res://game/systems/core/systems/navigation_system.gd")
const CANDIDATE_SEMANTIC_ADAPTER_SCRIPT := preload("res://game/world/procgen/generation/candidate_semantic_adapter.gd")
const CANDIDATE_EVALUATOR_SCRIPT := preload("res://game/world/procgen/generation/candidate_evaluator.gd")
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
	var floor_before := _cell_position_fingerprint(
		tilemap.debug_get_generated_floor_cells()
	)
	var walls_before := _cell_position_fingerprint(
		tilemap.debug_get_generated_wall_cells()
	)
	var ocean_before := _semantic_cell_fingerprint(tilemap.debug_get_ocean_cells())
	var chasm_before := _semantic_cell_fingerprint(tilemap.debug_get_chasm_cells())
	var terrain_before: Dictionary = (
		tilemap.get_level_data().get("terrain_builder", {}) as Dictionary
	).duplicate(true)
	var candidate_adapter := CANDIDATE_SEMANTIC_ADAPTER_SCRIPT.new()
	var candidate_snapshot: Dictionary = candidate_adapter.build_snapshot(
		tilemap,
		tilemap.get_level_data(),
		{"contract_seed": SEED, "attempt": 0, "attempt_seed": SEED}
	)
	var candidate_evaluator := CANDIDATE_EVALUATOR_SCRIPT.new()
	var evaluation: Dictionary = candidate_evaluator.evaluate_snapshot(candidate_snapshot)
	assert(bool(evaluation.get("accepted", false)), "Fixture semantic candidate was not accepted.")

	var contract_map := CONTRACT_MAP_SCENE.instantiate() as CustodianContractMap
	contract_map.auto_generate_on_ready = false
	root.add_child(contract_map)
	await process_frame
	var candidate := {
		"semantic_snapshot": candidate_snapshot,
		"evaluation": evaluation,
		"acceptance_mode": "accepted",
		"attempt": 0,
		"attempt_seed": SEED,
		"world_profile": tilemap.get_planet_world_profile(),
		"procgen_settings": contract_map._capture_candidate_procgen_settings(tilemap),
		"materialization_settings": contract_map._capture_candidate_materialization_settings(tilemap),
	}
	var promoted: Dictionary = await contract_map._generate_final_map_level_data(candidate)
	var final_tilemap := contract_map.get("_active_map") as ProcGenTilemap
	await process_frame

	assert(not promoted.is_empty(), "Candidate materialization returned no level data.")
	assert(final_tilemap != null, "Materializer did not attach the final runtime map.")
	assert(final_tilemap != tilemap, "Materializer reused the near-final evaluation map.")
	assert(not final_tilemap.generation_evaluation_mode)
	assert(
		int(tilemap.get("_debug_generation_id")) == generation_id_before,
		"Selection changed the evaluated candidate's structural generation."
	)
	assert(
		_cell_position_fingerprint(final_tilemap.debug_get_generated_floor_cells())
		== floor_before,
		"Final materialization changed accepted floor authority."
	)
	assert(
		_cell_position_fingerprint(final_tilemap.debug_get_generated_wall_cells())
		== walls_before,
		"Final materialization changed accepted wall authority."
	)
	assert(
		_semantic_cell_fingerprint(final_tilemap.debug_get_ocean_cells()) == ocean_before,
		"Final materialization changed accepted ocean semantics."
	)
	assert(
		_semantic_cell_fingerprint(final_tilemap.debug_get_chasm_cells()) == chasm_before,
		"Final materialization changed accepted chasm semantics."
	)
	var final_terrain: Dictionary = promoted.get("terrain_builder", {})
	for field_variant: Variant in terrain_before:
		var field := String(field_variant)
		if field == "generation_mode":
			continue
		if field == "summary":
			var expected_summary: Dictionary = terrain_before[field]
			var final_summary: Dictionary = final_terrain.get(field, {})
			for summary_field_variant: Variant in expected_summary:
				var summary_field := String(summary_field_variant)
				if summary_field == "generation_mode":
					continue
				assert(
					final_summary.get(summary_field) == expected_summary[summary_field],
					"Final materialization changed accepted terrain summary: %s" % summary_field
				)
			continue
		assert(
			final_terrain.get(field) == terrain_before[field],
			"Final materialization changed accepted terrain field: %s" % field
		)
	assert(
		final_tilemap.get_floor_tilemap().get_used_cells().size()
		<= final_tilemap.debug_get_generated_floor_cells().size(),
		"Streaming presentation painted beyond authoritative floor cells."
	)
	var materialization: Dictionary = final_tilemap.get_last_promotion_timing_snapshot()
	assert(int(materialization.get("structural_runtime_materialization_count", 0)) == 1)
	assert(int(materialization.get("runtime_invocation_count", 0)) == 1)
	assert(not (materialization.get("phase_order", PackedStringArray()) as PackedStringArray).is_empty())
	assert(String(materialization.get("verified_semantic_fingerprint", "")) == String(candidate_snapshot["fingerprint"]))
	assert(String(materialization.get("runtime_fingerprint", "")) == CANDIDATE_SEMANTIC_ADAPTER_SCRIPT.fingerprint_runtime_state(final_tilemap))
	var repeated_candidate: Dictionary = await contract_map._generate_final_map_level_data(candidate)
	var repeated_tilemap := contract_map.get("_active_map") as ProcGenTilemap
	assert(not repeated_candidate.is_empty())
	assert(repeated_tilemap != final_tilemap)
	assert(
		CANDIDATE_SEMANTIC_ADAPTER_SCRIPT.fingerprint_runtime_state(repeated_tilemap)
		== String(materialization.get("runtime_fingerprint", "")),
		"Fixed-seed final materialization fingerprint was not deterministic."
	)
	var generation_id_after_materialization := int(final_tilemap.get("_debug_generation_id"))
	var duplicate_materialization := final_tilemap.materialize_accepted_candidate(candidate_snapshot)
	assert(not bool(duplicate_materialization.get("ok", false)))
	assert(int(final_tilemap.get("_debug_generation_id")) == generation_id_after_materialization)

	var navigation := NAVIGATION_SCRIPT.new()
	root.add_child(navigation)
	navigation.set_runtime_tilemaps(
		final_tilemap.get_floor_tilemap(),
		final_tilemap.get_walls_tilemap(),
		final_tilemap
	)
	navigation.rebuild()
	var navigation_before: Dictionary = (
		navigation.get_navigation_authority_debug_snapshot()
	)
	assert(
		int(navigation_before["authoritative_floor_count"])
		== floor_before.size()
	)
	assert(int(navigation_before["painted_floor_count"]) <= floor_before.size())

	final_tilemap.streaming_reveal_tiles_per_frame = 100000
	for _frame in range(32):
		if (final_tilemap.get("_streaming_reveal_queue") as Array).is_empty():
			break
		final_tilemap.call("_process_streaming_reveal_queue", 0.0)
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
			"[ProcgenCandidatePromotionSmoke] PASS final_generation_id=%d "
			+ "floor=%d walls=%d painted=%d"
		) % [
			int(final_tilemap.get("_debug_generation_id")),
			floor_before.size(),
			walls_before.size(),
			final_tilemap.get_floor_tilemap().get_used_cells().size(),
		]
	)
	map.queue_free()
	final_tilemap.queue_free()
	repeated_tilemap.queue_free()
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


func _cell_position_fingerprint(cells: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	for cell_variant: Variant in cells.keys():
		if cell_variant is Vector2i:
			var cell := cell_variant as Vector2i
			rows.append("%d,%d" % [cell.x, cell.y])
	rows.sort()
	return rows


func _semantic_cell_fingerprint(cells: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	for cell_variant in cells.keys():
		if cell_variant is Vector2i:
			var cell := cell_variant as Vector2i
			rows.append("%d,%d" % [cell.x, cell.y])
	rows.sort()
	return rows
