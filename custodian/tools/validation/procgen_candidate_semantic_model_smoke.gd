extends SceneTree

## Proves custodian.procgen_candidate_semantic_model.v1 parity (G2): for the
## same generated candidate, CandidateEvaluator.evaluate_snapshot() over a
## CandidateSemanticAdapter snapshot must return the exact same result as the
## legacy live-Node evaluate_candidate() path, with no Node/TileMap reference
## used anywhere in the snapshot evaluation call. Also proves the snapshot
## fingerprint is stable across two independent builds of the same candidate.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const EVALUATOR_SCRIPT := preload("res://game/world/procgen/generation/candidate_evaluator.gd")
const ADAPTER_SCRIPT := preload("res://game/world/procgen/generation/candidate_semantic_adapter.gd")

const SETTINGS := {
	"pre_terrain_required_connectivity_min": 0.95,
	"terrain_rescue_reject_threshold": 200,
	"min_connected_room_ratio": 0.75,
	"require_compound_ingress_connectivity": true,
}
const SEEDS := [420777, 420779, 771923]
const MAP_SIZE := Vector2i(64, 64)

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var evaluator: Variant = EVALUATOR_SCRIPT.new()
	var adapter: Variant = ADAPTER_SCRIPT.new()

	for seed_value in SEEDS:
		var map := await _generate_candidate(seed_value)
		var level_data: Dictionary = map.get_level_data()

		var legacy: Dictionary = evaluator.evaluate_candidate(map, level_data, SETTINGS)

		var snapshot_a: Dictionary = adapter.build_snapshot(map, level_data, {"seed": seed_value})
		var snapshot_b: Dictionary = adapter.build_snapshot(map, level_data, {"seed": seed_value})
		_check(
			str(snapshot_a.get("fingerprint", "a")) == str(snapshot_b.get("fingerprint", "b")),
			"seed=%d snapshot fingerprint not stable across two builds of the same candidate" % seed_value,
		)

		var snapshot: Dictionary = snapshot_a
		var via_snapshot: Dictionary = evaluator.evaluate_snapshot(snapshot, SETTINGS)

		_check(
			bool(legacy.get("accepted", false)) == bool(via_snapshot.get("accepted", false)),
			"seed=%d accepted mismatch: legacy=%s snapshot=%s" % [
				seed_value, legacy.get("accepted"), via_snapshot.get("accepted"),
			],
		)
		_check(
			is_equal_approx(float(legacy.get("score", -1.0)), float(via_snapshot.get("score", -1.0))),
			"seed=%d score mismatch: legacy=%.4f snapshot=%.4f" % [
				seed_value, float(legacy.get("score", -1.0)), float(via_snapshot.get("score", -1.0)),
			],
		)
		_check(
			bool(legacy.get("terrain_failed", true)) == bool(via_snapshot.get("terrain_failed", true)),
			"seed=%d terrain_failed mismatch" % seed_value,
		)
		var legacy_metrics: Dictionary = legacy.get("metrics", {})
		var snapshot_metrics: Dictionary = via_snapshot.get("metrics", {})
		for key in ["layout_valid", "candidate_valid", "connected_ratio", "ingress_ratio",
				"reachable_count", "rooms_total", "rooms_connected", "rooms_exact_walkable",
				"rooms_represented", "ingress_total", "ingress_connected", "rejection_reasons",
				"required_ingresses_valid", "required_ingress_failures", "spawn_tile"]:
			var a: Variant = legacy_metrics.get(key)
			var b: Variant = snapshot_metrics.get(key)
			_check(
				str(a) == str(b),
				"seed=%d metrics.%s mismatch: legacy=%s snapshot=%s" % [seed_value, key, str(a), str(b)],
			)

		_check(
			snapshot.get("schema") == "custodian.procgen_candidate_semantic_model.v1",
			"seed=%d snapshot schema field missing/wrong" % seed_value,
		)

		map.queue_free()
		await process_frame

	var missing_snapshot: Dictionary = adapter.build_snapshot(null, {})
	var missing_result: Dictionary = evaluator.evaluate_snapshot(missing_snapshot, SETTINGS)
	var missing_metrics: Dictionary = missing_result.get("metrics", {})
	_check(
		missing_metrics.get("rejection_reasons", []) == ["missing_map_instance"],
		"missing-map snapshot did not reject as missing_map_instance",
	)
	_check(
		not missing_result.has("node") and not missing_result.has("map_instance") \
				and not missing_metrics.has("map_instance"),
		"evaluate_snapshot result must remain data-only",
	)

	if _errors.is_empty():
		print("[ProcgenCandidateSemanticModelSmoke] PASS seeds=%s" % [SEEDS])
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenCandidateSemanticModelSmoke] %s" % error)
	quit(1)


func _generate_candidate(seed_value: int) -> ProcGenTilemap:
	var map := PROCGEN_MAP_SCENE.instantiate() as ProcGenTilemap
	root.add_child(map)
	await process_frame
	var legacy_procgen := map.get_node_or_null("ProcGen")
	if legacy_procgen != null:
		legacy_procgen.queue_free()
		await process_frame
	var procgen := map.get_node_or_null("ProcGen2") as ProcGen
	assert(procgen != null)
	procgen.generate_seed = false
	procgen.seed = seed_value
	procgen.map_size = MAP_SIZE
	map.procgen_node = procgen
	map.generation_evaluation_mode = false
	map.generation_output_enabled = true
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false
	# generate() completes and emits level_data_ready synchronously before
	# returning; do not await that signal here, it has already fired.
	map.generate()
	return map


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
