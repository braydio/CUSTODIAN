extends SceneTree

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const CONTRACT_MAP_SCRIPT := preload("res://game/world/procgen/custodian_contract_map.gd")
const CONTRACT_WORLD_LOADER_SCRIPT := preload("res://game/systems/core/systems/contract_world_loader.gd")

const CONTRACT_SEEDS := [731101, 731211, 731333]
const MAP_SIZES := [Vector2i(176, 176), Vector2i(208, 224), Vector2i(224, 224)]
const ATTEMPTS_PER_SEED := 12
const TERRAIN_RESCUE_LIMIT := 200
const BASELINE_RESCUE_HARD_CAP := 500

var _contract_metric_helper = null
var _failures: Array[String] = []
var _forced_failure_result: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_contract_metric_helper = CONTRACT_MAP_SCRIPT.new()
	_contract_metric_helper.terrain_rescue_reject_threshold = TERRAIN_RESCUE_LIMIT
	_contract_metric_helper.pre_terrain_required_connectivity_min = 0.95

	var all_metrics: Array[Dictionary] = []
	for seed_index in range(CONTRACT_SEEDS.size()):
		var contract_seed := int(CONTRACT_SEEDS[seed_index])
		var map_size: Vector2i = MAP_SIZES[seed_index % MAP_SIZES.size()]
		var seed_metrics := await _run_contract_seed(contract_seed, map_size)
		all_metrics.append_array(seed_metrics)
		_validate_seed_acceptance(contract_seed, seed_metrics)

	_print_aggregate(all_metrics)
	await _assert_forced_contract_failure_emits_abort()

	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		quit(1)
		return

	print("[ProcgenContractRescueDiagnosticSmoke] ok seeds=%s attempts_per_seed=%d" % [str(CONTRACT_SEEDS), ATTEMPTS_PER_SEED])
	quit(0)


func _run_contract_seed(contract_seed: int, map_size: Vector2i) -> Array[Dictionary]:
	var metrics_list: Array[Dictionary] = []
	print("[ProcgenContractRescueDiagnosticSmoke] seed=%d map_size=%s attempts=%d" % [contract_seed, str(map_size), ATTEMPTS_PER_SEED])
	print("attempt seed map_size room_count floor_cells wall_cells intent_nodes intent_edges pre_terrain_required_count pre_terrain_connected_required_ratio pre_terrain_missing_required_count pre_terrain_missing_by_source baseline_rescue final_rescue terrain_rescue connected_ratio ingress_ratio rejection_reasons")
	for attempt in range(ATTEMPTS_PER_SEED):
		var attempt_seed := contract_seed + attempt * 7919
		var map := await _generate_candidate_map(attempt_seed, map_size, attempt)
		var level_data := map.get_level_data()
		var metrics: Dictionary = _contract_metric_helper._get_map_layout_metrics(map, level_data)
		var pre_terrain: Dictionary = level_data.get("pre_terrain_connectivity", {})
		var pre_repair: Dictionary = pre_terrain.get("pre_terrain_before_repair", {})
		metrics["pre_terrain_before_repair_missing_required_samples"] = pre_repair.get("pre_terrain_missing_required_samples", [])
		metrics["attempt"] = attempt
		metrics["seed"] = attempt_seed
		metrics["map_size"] = map_size
		metrics_list.append(metrics)
		_validate_diagnostics(attempt_seed, level_data, metrics)
		_print_attempt_row(attempt, attempt_seed, map, level_data, metrics)
		map.queue_free()
		await process_frame
	return metrics_list


func _generate_candidate_map(seed: int, map_size: Vector2i, attempt: int) -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	root.add_child(map)
	assert(map != null)
	if not map.is_node_ready():
		await map.ready

	var duplicate_tilemap := map.get_node_or_null("ProcGen")
	if duplicate_tilemap != null:
		duplicate_tilemap.queue_free()
		await process_frame

	var procgen := map.get_node("ProcGen2") as ProcGen
	assert(procgen != null)
	map.procgen_node = procgen
	procgen.auto_generate_on_ready = false
	procgen.generate_seed = false
	procgen.seed = seed
	procgen.map_size = map_size
	procgen.room_amount = 12 + (attempt % 4)
	procgen.room_center_ratio = 0.20
	procgen.corridor_edge_overlap_min_ratio = 0.18
	procgen.corridor_cycle_chance = 0.28
	procgen.automaton_iterations = 3 + (attempt % 2)
	procgen.automaton_noise_rate = 0.52
	procgen.automaton_corridor_fixed_width_expand = 1
	procgen.automaton_corridor_non_fixed_width_expand = 1 + ((attempt + 1) % 2)

	map.generation_evaluation_mode = true
	map.generation_output_enabled = true
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	map.show_runtime_wall_collision_debug = false
	map.enable_final_foliage = false

	map.generate()
	await process_frame
	var terrain_builder: Dictionary = map.get_level_data().get("terrain_builder", {})
	assert(not terrain_builder.get("summary", {}).is_empty(), "Candidate generation missing terrain summary seed=%d size=%s" % [seed, str(map_size)])
	return map


func _validate_diagnostics(seed: int, level_data: Dictionary, metrics: Dictionary) -> void:
	var pre_terrain: Dictionary = level_data.get("pre_terrain_connectivity", {})
	var terrain_builder: Dictionary = level_data.get("terrain_builder", {})
	var summary: Dictionary = terrain_builder.get("summary", {})
	if pre_terrain.is_empty():
		_failures.append("seed %d missing pre-terrain diagnostics" % seed)
	if not pre_terrain.has("pre_terrain_baseline_connected_required_ratio") \
			or not pre_terrain.has("pre_terrain_layout_connected_required_ratio") \
			or not pre_terrain.has("pre_terrain_semantic_connected_required_ratio"):
		_failures.append("seed %d missing three-graph pre-terrain ratios" % seed)
	if not pre_terrain.has("pre_terrain_component_count") or not pre_terrain.has("pre_terrain_bridge_candidates"):
		_failures.append("seed %d missing component diagnostics" % seed)
	if not summary.has("baseline_rescue_carved_cells"):
		_failures.append("seed %d TerrainBuilder summary missing baseline_rescue_carved_cells" % seed)
	var samples: Array = pre_terrain.get("pre_terrain_missing_required_samples", [])
	var pre_repair: Dictionary = pre_terrain.get("pre_terrain_before_repair", {})
	var pre_repair_samples: Array = pre_repair.get("pre_terrain_missing_required_samples", [])
	for sample in samples:
		_validate_missing_sample(seed, sample)
	for sample in pre_repair_samples:
		_validate_missing_sample(seed, sample)
	if int(metrics.get("terrain_baseline_rescue_carved", 0)) > BASELINE_RESCUE_HARD_CAP:
		_failures.append("seed %d baseline rescue exceeded hard cap: %d" % [seed, int(metrics.get("terrain_baseline_rescue_carved", 0))])


func _validate_missing_sample(seed: int, sample: Variant) -> void:
	if not (sample is Dictionary):
		_failures.append("seed %d missing sample is not dictionary: %s" % [seed, str(sample)])
		return
	var sample_dict := sample as Dictionary
	if String(sample_dict.get("source", "")).is_empty():
		_failures.append("seed %d missing required sample lacks source: %s" % [seed, str(sample)])
	if String(sample_dict.get("reason", "")).is_empty():
		_failures.append("seed %d missing required sample lacks reason: %s" % [seed, str(sample)])


func _validate_seed_acceptance(contract_seed: int, metrics_list: Array[Dictionary]) -> void:
	var accepted_count := 0
	var best: Dictionary = {}
	for metrics in metrics_list:
		if bool(metrics.get("candidate_valid", false)):
			accepted_count += 1
			if best.is_empty() or int(metrics.get("terrain_rescue_carved", 999999)) < int(best.get("terrain_rescue_carved", 999999)):
				best = metrics
	if accepted_count <= 0:
		_failures.append("contract seed %d had no valid production candidate in %d attempts" % [contract_seed, ATTEMPTS_PER_SEED])
		return
	if float(best.get("pre_terrain_connected_required_ratio", 0.0)) < 0.95:
		_failures.append("contract seed %d best candidate pre-terrain ratio below 0.95: %.3f" % [contract_seed, float(best.get("pre_terrain_connected_required_ratio", 0.0))])
	if int(best.get("terrain_rescue_carved", 999999)) > TERRAIN_RESCUE_LIMIT:
		_failures.append("contract seed %d best candidate terrain rescue above limit: %d" % [contract_seed, int(best.get("terrain_rescue_carved", 999999))])
	if bool(best.get("terrain_fallback", true)):
		_failures.append("contract seed %d best candidate used terrain fallback" % contract_seed)
	if not bool(best.get("terrain_connectivity", false)):
		_failures.append("contract seed %d best candidate failed terrain connectivity" % contract_seed)


func _print_attempt_row(attempt: int, seed: int, map: ProcGenTilemap, level_data: Dictionary, metrics: Dictionary) -> void:
	var pre_terrain: Dictionary = level_data.get("pre_terrain_connectivity", {})
	var pre_repair: Dictionary = pre_terrain.get("pre_terrain_before_repair", {})
	var terrain_builder: Dictionary = level_data.get("terrain_builder", {})
	var summary: Dictionary = terrain_builder.get("summary", {})
	var graph: Dictionary = level_data.get("worldgen_intent_graph", {})
	var nodes: Array = graph.get("nodes", [])
	var edges: Array = graph.get("edges", [])
	var missing_by_source: Variant = pre_terrain.get("pre_terrain_missing_required_by_source", {})
	if (missing_by_source as Dictionary).is_empty() and not pre_repair.is_empty():
		missing_by_source = {"before_repair": pre_repair.get("pre_terrain_missing_required_by_source", {})}
	print("%d %d %s %d %d %d %d %d %d %.3f %d %s %d %d %d %.3f %.3f %s" % [
		attempt,
		seed,
		str(level_data.get("map_size", Vector2i.ZERO)),
		(map.procgen_node.get_rooms() as Array).size(),
		(level_data.get("floor_cells", []) as Array).size(),
		(level_data.get("wall_cells", []) as Array).size(),
		nodes.size(),
		edges.size(),
		int(pre_terrain.get("pre_terrain_required_cell_count", 0)),
		float(pre_terrain.get("pre_terrain_connected_required_ratio", 0.0)),
		int(pre_terrain.get("pre_terrain_missing_required_count", 0)),
		str(missing_by_source),
		int(summary.get("baseline_rescue_carved_cells", terrain_builder.get("baseline_rescue_carved_cells", 0))),
		maxi(0, int(summary.get("rescue_carved_cells", terrain_builder.get("rescue_carved_cells", 0))) - int(summary.get("baseline_rescue_carved_cells", terrain_builder.get("baseline_rescue_carved_cells", 0)))),
		int(metrics.get("terrain_rescue_carved", 0)),
		float(metrics.get("connected_ratio", 0.0)),
		float(metrics.get("ingress_ratio", 0.0)),
		str(metrics.get("rejection_reasons", [])),
	])


func _print_aggregate(metrics_list: Array[Dictionary]) -> void:
	var baseline_values: Array[int] = []
	var accepted := 0
	var rejected_pre := 0
	var rejected_rescue := 0
	var source_counts := {}
	for metrics in metrics_list:
		baseline_values.append(int(metrics.get("terrain_baseline_rescue_carved", 0)))
		if bool(metrics.get("candidate_valid", false)):
			accepted += 1
		var reasons: Array = metrics.get("rejection_reasons", [])
		if reasons.has("pre_terrain_required_connectivity"):
			rejected_pre += 1
		if reasons.has("terrain_rescue"):
			rejected_rescue += 1
		var sample_sources: Array = metrics.get("pre_terrain_missing_required_samples", [])
		if sample_sources.is_empty():
			sample_sources = metrics.get("pre_terrain_before_repair_missing_required_samples", [])
		for sample in sample_sources:
			if sample is Dictionary:
				var source := String((sample as Dictionary).get("source", "unknown"))
				source_counts[source] = int(source_counts.get(source, 0)) + 1
	baseline_values.sort()
	var worst: int = baseline_values.back() if not baseline_values.is_empty() else 0
	var median: int = baseline_values[baseline_values.size() / 2] if not baseline_values.is_empty() else 0
	print("aggregate worst_baseline_rescue=%d median_baseline_rescue=%d accepted_candidate_count=%d rejected_by_pre_terrain_connectivity=%d rejected_by_terrain_rescue=%d most_common_missing_required_source=%s" % [
		worst,
		median,
		accepted,
		rejected_pre,
		rejected_rescue,
		_most_common_key(source_counts),
	])


func _most_common_key(counts: Dictionary) -> String:
	var best_key := "none"
	var best_count := 0
	for key in counts.keys():
		var count := int(counts.get(key, 0))
		if count > best_count:
			best_count = count
			best_key = String(key)
	return best_key


func _assert_forced_contract_failure_emits_abort() -> void:
	var contract_map = CONTRACT_MAP_SCRIPT.new()
	contract_map.map_scene = PROCGEN_MAP_SCENE
	contract_map.map_generation_attempts = 1
	contract_map.min_connected_room_ratio = 2.0
	contract_map.allow_degraded_best_candidate_fallback = false
	contract_map.auto_generate_on_ready = false
	var planet_root := Node2D.new()
	planet_root.name = "PlanetRoot"
	contract_map.add_child(planet_root)
	var map_root := Node2D.new()
	map_root.name = "MapRoot"
	contract_map.add_child(map_root)
	root.add_child(contract_map)
	_forced_failure_result = {}
	contract_map.contract_generation_failed.connect(func(result: Dictionary) -> void:
		_forced_failure_result = result.duplicate(true)
	, CONNECT_ONE_SHOT)
	await contract_map.generate_contract(900991)
	if _forced_failure_result.is_empty() or not bool(_forced_failure_result.get("generation_failed", false)):
		_failures.append("forced failure did not emit contract_generation_failed result")
	var loader = CONTRACT_WORLD_LOADER_SCRIPT.new()
	root.add_child(loader)
	loader._on_contract_generation_failed(_forced_failure_result)
	if not loader.is_contract_activation_aborted() or loader.get_active_map_instance() != null:
		_failures.append("ContractWorldLoader did not abort cleanly after forced failure")
	loader.queue_free()
	contract_map.queue_free()
	await process_frame
