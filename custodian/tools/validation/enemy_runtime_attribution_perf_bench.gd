extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const NAVIGATION_SYSTEM_SCRIPT := preload("res://game/systems/core/systems/navigation_system.gd")
const WARMUP_FRAMES := 180
const MEASUREMENT_FRAMES := 300
const POPULATIONS := [0, 1, 2, 4, 8, 10]
const REPORT_PATH := "user://performance/enemy_runtime_attribution_perf_bench.json"
const SPAN_NAMES := [
	"enemy_total", "enemy_active_total", "enemy_nearby_total",
	"enemy_background_total", "enemy_dormant_total", "enemy_behavior",
	"enemy_perception", "enemy_objective_sensor", "enemy_navigation",
	"enemy_separation", "enemy_movement_prepare", "enemy_move_and_slide",
	"enemy_combat", "enemy_animation", "enemy_presentation",
	"enemy_health_ui", "enemy_corpse",
]

var _bench_root: Node2D
var _operator: CharacterBody2D
var _actors: Array[Node2D] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_only := await _measure_root_only()
	var population_runs: Array[Dictionary] = []
	for population in POPULATIONS:
		await _build_clean_state(population, true)
		population_runs.append(await _measure("population_%d" % population, {"actor_count": population}))

	var tier_runs: Array[Dictionary] = []
	var tier_cases := [
		{"label": "8_active", "tiers": ["active", "active", "active", "active", "active", "active", "active", "active"]},
		{"label": "8_nearby", "tiers": ["nearby", "nearby", "nearby", "nearby", "nearby", "nearby", "nearby", "nearby"]},
		{"label": "8_background", "tiers": ["background", "background", "background", "background", "background", "background", "background", "background"]},
		{"label": "8_dormant", "tiers": ["dormant", "dormant", "dormant", "dormant", "dormant", "dormant", "dormant", "dormant"]},
		{"label": "1_active_7_dormant", "tiers": ["active", "dormant", "dormant", "dormant", "dormant", "dormant", "dormant", "dormant"]},
		{"label": "1_active_3_background_4_dormant", "tiers": ["active", "background", "background", "background", "dormant", "dormant", "dormant", "dormant"]},
	]
	for tier_case in tier_cases:
		await _build_clean_state(8, true)
		var tiers: Array = tier_case["tiers"]
		for index in _actors.size():
			_actors[index].remove_from_group("interest_managed")
			_actors[index].call("force_diagnostic_simulation_tier", tiers[index])
		# Allow deferred processing-state changes to settle without production
		# interest classification overwriting the diagnostic matrix.
		await process_frame
		tier_runs.append(await _measure(String(tier_case["label"]), {"tiers": tiers.duplicate()}))

	var legacy_director_runs: Array[Dictionary] = []
	await _build_clean_state(8, true)
	legacy_director_runs.append(await _measure("8_director", {"behavior_path": "director"}))
	await _build_clean_state(8, false)
	legacy_director_runs.append(await _measure("8_legacy", {"behavior_path": "legacy"}))

	var report := {
		"schema": "custodian.enemy_runtime_attribution_perf.v1",
		"engine": Engine.get_version_info(),
		"headless": DisplayServer.get_name() == "headless",
		"warmup_frames": WARMUP_FRAMES,
		"measurement_frames": MEASUREMENT_FRAMES,
		"hardware_thresholds_applied": false,
		"uses_real_grunt_scene": true,
		"isolation": {"benchmark_root_only": root_only, "benchmark_root_operator": population_runs[0]},
		"population_runs": population_runs,
		"tier_runs": tier_runs,
		"legacy_director_runs": legacy_director_runs,
	}
	var absolute_path := ProjectSettings.globalize_path(REPORT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	_print_table("POPULATION", population_runs)
	_print_table("SIMULATION TIER", tier_runs)
	_print_table("BEHAVIOR PATH", legacy_director_runs)
	print("enemy_runtime_attribution_perf_bench: COMPLETE report=%s" % absolute_path)
	await _destroy_state()
	quit(0)


func _measure_root_only() -> Dictionary:
	_bench_root = Node2D.new()
	_bench_root.name = "EnemyAttributionRootOnly"
	root.add_child(_bench_root)
	for _frame in WARMUP_FRAMES:
		await process_frame
	var result := await _measure("root_only", {"actor_count": 0})
	await _destroy_state()
	return result


func _build_clean_state(actor_count: int, director_enabled: bool) -> void:
	await _destroy_state()
	_bench_root = Node2D.new()
	_bench_root.name = "EnemyRuntimeAttributionBench"
	root.add_child(_bench_root)
	var navigation := NAVIGATION_SYSTEM_SCRIPT.new() as NavigationSystem
	navigation.name = "BenchmarkNavigationSystem"
	navigation.set("_init_deferred", true)
	_bench_root.add_child(navigation)
	_operator = CharacterBody2D.new()
	_operator.name = "BenchmarkOperator"
	_operator.position = Vector2(640.0, 0.0)
	_operator.add_to_group("player")
	_bench_root.add_child(_operator)
	for index in actor_count:
		var actor := GRUNT_SCENE.instantiate() as Node2D
		assert(actor != null)
		actor.position = Vector2.RIGHT.rotated(TAU * float(index) / float(maxi(1, actor_count))) * 180.0
		actor.set_meta("stable_spawn_ordinal", index + 1)
		actor.set("behavior_state_machine_enabled", director_enabled)
		_bench_root.add_child(actor)
		if not director_enabled:
			actor.remove_from_group("enemy_behavior_agent")
		_actors.append(actor)
	for _frame in WARMUP_FRAMES:
		await process_frame


func _destroy_state() -> void:
	_actors.clear()
	_operator = null
	if _bench_root != null and is_instance_valid(_bench_root):
		_bench_root.queue_free()
		await process_frame
		await process_frame
	_bench_root = null


func _measure(label: String, metadata: Dictionary) -> Dictionary:
	var observatory := root.get_node_or_null("DevObservatory")
	if observatory != null:
		observatory.call("clear")
		observatory.call("start_performance_incident", &"benchmark")
	var samples: Array[float] = []
	var process_total := 0.0
	var physics_total := 0.0
	var draw_total := 0.0
	var rendered_total := 0.0
	for _frame in MEASUREMENT_FRAMES:
		var started := Time.get_ticks_usec()
		await process_frame
		samples.append(float(Time.get_ticks_usec() - started) / 1000.0)
		process_total += float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
		physics_total += float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
		draw_total += float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		rendered_total += float(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	var incident := {}
	if observatory != null:
		observatory.call("stop_performance_incident", &"benchmark_complete")
		incident = observatory.call("get_performance_incident_report") as Dictionary
	var sorted := samples.duplicate()
	sorted.sort()
	var wall_average := _average(samples)
	var process_average := process_total / float(MEASUREMENT_FRAMES)
	var physics_average := physics_total / float(MEASUREMENT_FRAMES)
	var result := metadata.duplicate(true)
	result.merge({
		"label": label,
		"wall_frame_ms_average": wall_average,
		"wall_frame_ms_p50": _percentile(sorted, 0.50),
		"wall_frame_ms_p95": _percentile(sorted, 0.95),
		"wall_frame_ms_p99": _percentile(sorted, 0.99),
		"wall_frame_ms_worst": sorted[-1],
		"engine_process_ms": process_average,
		"engine_physics_ms": physics_average,
		"unaccounted_ms": maxf(0.0, wall_average - process_average - physics_average),
		"draw_calls_average": draw_total / float(MEASUREMENT_FRAMES),
		"rendered_objects_average": rendered_total / float(MEASUREMENT_FRAMES),
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"physics_body_count": int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)),
		"collision_pair_count": int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)),
		"collision_shape_count": _count_nodes_of_type(_bench_root, "CollisionShape2D"),
		"runtime_cost_states": _runtime_cost_state_counts(),
		"enemy_spans": _normalize_spans(incident.get("aggregate_spans", {}), int(incident.get("samples_retained", MEASUREMENT_FRAMES))),
	}, true)
	return result


func _normalize_spans(raw: Dictionary, retained_frames: int) -> Dictionary:
	var output := {}
	for span_name in SPAN_NAMES:
		var bucket: Dictionary = raw.get(span_name, {})
		output[span_name] = {
			"calls": int(bucket.get("count", 0)),
			"total_ms": float(bucket.get("total_usec", 0)) / 1000.0,
			"ms_per_frame": float(bucket.get("total_usec", 0)) / 1000.0 / float(maxi(1, retained_frames)),
			"max_ms": float(bucket.get("max_usec", 0)) / 1000.0,
		}
	return output


func _runtime_cost_state_counts() -> Dictionary:
	var output := {}
	for actor in _actors:
		var state: Dictionary = actor.call("get_runtime_cost_state")
		var tier := String(state.get("simulation_tier", "unknown"))
		if not output.has(tier):
			output[tier] = {"count": 0, "physics_enabled": 0, "presentation_enabled": 0}
		output[tier]["count"] += 1
		output[tier]["physics_enabled"] += int(bool(state.get("physics_process_enabled", false)))
		output[tier]["presentation_enabled"] += int(bool(state.get("presentation_enabled", false)))
	return output


func _count_nodes_of_type(node: Node, type_name: String) -> int:
	if node == null:
		return 0
	var total := int(node.is_class(type_name))
	for child in node.get_children():
		total += _count_nodes_of_type(child, type_name)
	return total


func _average(values: Array[float]) -> float:
	var total := 0.0
	for value in values:
		total += value
	return total / float(maxi(1, values.size()))


func _percentile(sorted_values: Array[float], ratio: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	return sorted_values[clampi(ceili(float(sorted_values.size()) * ratio) - 1, 0, sorted_values.size() - 1)]


func _print_table(title: String, runs: Array[Dictionary]) -> void:
	print("\n%s | wall avg | p95 | process | physics | unaccounted | enemy total" % title)
	for run in runs:
		var spans: Dictionary = run.get("enemy_spans", {})
		var enemy_total: Dictionary = spans.get("enemy_total", {})
		print("%-34s %8.3f %8.3f %8.3f %8.3f %11.3f %11.3f" % [
			run.get("label", ""), run.get("wall_frame_ms_average", 0.0),
			run.get("wall_frame_ms_p95", 0.0), run.get("engine_process_ms", 0.0),
			run.get("engine_physics_ms", 0.0), run.get("unaccounted_ms", 0.0),
			enemy_total.get("ms_per_frame", 0.0),
		])
