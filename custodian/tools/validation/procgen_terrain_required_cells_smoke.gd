extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const CONTRACT_MAP_SCRIPT := preload("res://game/world/procgen/custodian_contract_map.gd")
const CONTRACT_WORLD_LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")

const SEEDS := [420777, 420778, 420779]
const MAP_SIZE := Vector2i(112, 92)
const MAX_REASONABLE_REQUIRED_CELLS := 96


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for seed in SEEDS:
		var level_data := await _generate_candidate_level_data(seed)
		var terrain_data: Dictionary = level_data.get("terrain_builder", {})
		var summary: Dictionary = terrain_data.get("summary", {})
		var pre_terrain: Dictionary = level_data.get("pre_terrain_connectivity", {})
		var required_count := int(summary.get("required_cell_count", 0))
		var missing_count := int(summary.get("missing_required_count", -1))
		var pre_required_count := int(pre_terrain.get("pre_terrain_required_cell_count", 0))
		var pre_missing_count := int(pre_terrain.get("pre_terrain_missing_required_count", -1))
		assert(String(summary.get("generation_mode", "")) == "EVAL_CANDIDATE")
		assert(required_count > 0, "Expected TerrainBuilder required cells for seed %d." % seed)
		assert(required_count <= MAX_REASONABLE_REQUIRED_CELLS, "TerrainBuilder required_cells overvalidated seed %d: %d" % [seed, required_count])
		assert(not pre_terrain.is_empty(), "Expected pre-terrain connectivity diagnostics for seed %d." % seed)
		assert(pre_required_count == required_count, "Pre-terrain required count mismatch for seed %d: pre=%d terrain=%d" % [seed, pre_required_count, required_count])
		assert(pre_missing_count >= 0, "Expected pre-terrain missing count for seed %d." % seed)
		assert(pre_terrain.has("pre_terrain_connected_required_ratio"), "Expected pre-terrain connectivity ratio for seed %d." % seed)
		if pre_missing_count > 0:
			var samples: Array = pre_terrain.get("pre_terrain_missing_required_samples", [])
			assert(not samples.is_empty(), "Expected classified missing pre-terrain samples for seed %d." % seed)
			for sample in samples:
				assert(sample is Dictionary and String(sample.get("source", "")).length() > 0, "Missing pre-terrain sample classification for seed %d: %s" % [seed, str(sample)])
				assert(String(sample.get("reason", "")) == "unreachable_from_spawn", "Missing pre-terrain sample reason for seed %d: %s" % [seed, str(sample)])
		assert(bool(summary.get("connectivity_ok", false)), "Terrain connectivity failed for seed %d: %s" % [seed, str(summary)])
		assert(not bool(summary.get("fallback_used", true)), "Terrain fallback used for seed %d: %s" % [seed, str(summary)])
		assert(missing_count == 0, "TerrainBuilder still has missing required cells for seed %d: %s" % [seed, str(summary)])

	_assert_huge_baseline_rescue_invalid()
	await _assert_contract_failure_does_not_mark_valid_world()
	print("[ProcgenTerrainRequiredCellsSmoke] ok seeds=%s max_required=%d" % [str(SEEDS), MAX_REASONABLE_REQUIRED_CELLS])
	quit(0)


func _generate_candidate_level_data(seed: int) -> Dictionary:
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
	procgen.seed = seed
	procgen.map_size = MAP_SIZE

	tilemap.generation_evaluation_mode = true
	tilemap.generation_output_enabled = true
	tilemap.enable_streaming_reveal = false
	tilemap.build_runtime_wall_collision = false
	tilemap.show_runtime_wall_collision_debug = false
	tilemap.enable_final_foliage = false
	tilemap.generate()

	for _frame in range(360):
		var level_data := tilemap.get_level_data()
		var terrain_data: Dictionary = level_data.get("terrain_builder", {})
		var summary: Dictionary = terrain_data.get("summary", {})
		if not summary.is_empty():
			map.queue_free()
			await process_frame
			return level_data
		await process_frame

	map.queue_free()
	await process_frame
	assert(false, "Timed out waiting for procgen terrain summary for seed %d." % seed)
	return {}


func _assert_huge_baseline_rescue_invalid() -> void:
	var contract_map := CONTRACT_MAP_SCRIPT.new()
	contract_map.terrain_rescue_reject_threshold = 200
	contract_map.pre_terrain_required_connectivity_min = 0.95
	var metrics := {
		"layout_valid": true,
		"candidate_valid": false,
		"connected_ratio": 1.0,
		"ingress_ratio": 1.0,
		"pre_terrain_connected_required_ratio": 0.22,
		"terrain_fallback": false,
		"terrain_connectivity": true,
		"terrain_baseline_rescue_carved": 5248,
		"terrain_rescue_carved": 5248,
	}
	assert(not contract_map._is_map_layout_acceptable(metrics), "Huge baseline rescue candidate should be invalid.")
	assert(contract_map._is_terrain_failed_candidate(metrics), "Huge baseline rescue candidate should be treated as terrain/pre-terrain failed.")
	assert(not contract_map._can_use_degraded_fallback({}), "Empty degraded fallback metrics should be rejected.")
	contract_map.free()


func _assert_contract_failure_does_not_mark_valid_world() -> void:
	var contract_map := CONTRACT_MAP_SCRIPT.new()
	var failure := contract_map._build_generation_failure_result(
		"no_accepted_candidate",
		12,
		7,
		-0.90,
		{
			"terrain_rescue_carved": 1952,
			"terrain_baseline_rescue_carved": 1952,
			"pre_terrain_connected_required_ratio": 0.22,
			"pre_terrain_missing_required_count": 14,
			"rejection_reasons": ["pre_terrain_required_connectivity", "terrain_rescue"],
		}
	)
	assert(bool(failure.get("generation_failed", false)), "Failure result must be explicit.")
	assert(String(failure.get("failure_reason", "")) == "no_accepted_candidate", "Failure reason must survive.")
	contract_map.free()

	var loader := CONTRACT_WORLD_LOADER_SCRIPT.new()
	root.add_child(loader)
	loader._on_contract_generation_failed(failure)
	assert(loader.is_contract_activation_aborted(), "ContractWorldLoader should abort activation on generation failure.")
	assert(loader.get_active_map_instance() == null, "ContractWorldLoader should not expose an active map after failure.")
	var enemy_root := Node2D.new()
	enemy_root.name = "Enemies"
	loader.add_child(enemy_root)
	var enemy := Node2D.new()
	enemy.add_to_group("enemy")
	loader._on_failed_enemy_child_entered(enemy)
	assert(enemy.process_mode == Node.PROCESS_MODE_DISABLED, "Future enemies should be disabled after contract failure.")
	assert(enemy.is_queued_for_deletion(), "Future enemies should be removed after contract failure.")
	loader.queue_free()
	await process_frame
