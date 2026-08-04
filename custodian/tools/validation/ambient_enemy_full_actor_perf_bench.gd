extends SceneTree

const GRUNT_SCENE := preload(
	"res://game/actors/enemies/enemy_grunt.tscn"
)
const GRUNT_ANIMATION_LIBRARY := preload(
	"res://game/enemies/procgen/grunt_animation_library.gd"
)
const NAVIGATION_SYSTEM_SCRIPT := preload(
	"res://game/systems/core/systems/navigation_system.gd"
)
const SAMPLE_FRAMES := 120
const SETTLE_FRAMES := 12
const GLOBAL_WARMUP_FRAMES := 120
const ACTOR_COUNTS := [0, 1, 2, 4, 8]
const REPORT_PATH := (
	"user://performance/ambient_enemy_full_actor_perf_bench.json"
)

var _bench_root: Node2D
var _player: CharacterBody2D
var _actors: Array[Node2D] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_bench_root = Node2D.new()
	_bench_root.name = "AmbientEnemyFullActorPerfBench"
	root.add_child(_bench_root)
	var navigation := NAVIGATION_SYSTEM_SCRIPT.new() as NavigationSystem
	navigation.name = "BenchmarkNavigationSystem"
	# The actor benchmark exercises normal broker/spatial ownership without
	# introducing procgen graph construction into the actor-count comparison.
	navigation.set("_init_deferred", true)
	_bench_root.add_child(navigation)

	_player = CharacterBody2D.new()
	_player.name = "BenchmarkOperator"
	_player.position = Vector2(640.0, 0.0)
	_player.add_to_group("player")
	_bench_root.add_child(_player)

	var prewarm_started := Time.get_ticks_usec()
	GRUNT_ANIMATION_LIBRARY.get_grunt_sprite_frames()
	GRUNT_ANIMATION_LIBRARY.get_grunt_fx_sprite_frames()
	var prewarm_usec := Time.get_ticks_usec() - prewarm_started
	for _warmup_frame in GLOBAL_WARMUP_FRAMES:
		await process_frame

	var runs: Array[Dictionary] = []
	for actor_count in ACTOR_COUNTS:
		_ensure_actor_count(actor_count)
		for _settle_frame in SETTLE_FRAMES:
			await process_frame
		var run := await _measure_run(actor_count)
		runs.append(run)
		print(
			(
				"ambient_enemy_full_actor_perf_bench actors=%d "
				+ "average_ms=%.3f p95_ms=%.3f worst_ms=%.3f "
				+ "process_ms=%.3f physics_ms=%.3f nodes=%d"
			)
			% [
				actor_count,
				float(run["frame_ms_average"]),
				float(run["frame_ms_p95"]),
				float(run["frame_ms_worst"]),
				float(run["engine_process_ms"]),
				float(run["engine_physics_ms"]),
				int(run["node_count"]),
			]
		)

	var report := {
		"schema": "custodian.ambient_enemy_full_actor_perf.v1",
		"engine": Engine.get_version_info(),
		"sample_frames_per_run": SAMPLE_FRAMES,
		"settle_frames_per_run": SETTLE_FRAMES,
		"global_warmup_frames": GLOBAL_WARMUP_FRAMES,
		"prewarm_usec": prewarm_usec,
		"uses_real_grunt_scene": true,
		"hardware_thresholds_applied": false,
		"runs": runs,
	}
	var absolute_path := ProjectSettings.globalize_path(REPORT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(
		"ambient_enemy_full_actor_perf_bench: COMPLETE report=%s"
		% absolute_path
	)
	_bench_root.queue_free()
	quit(0)


func _ensure_actor_count(target_count: int) -> void:
	while _actors.size() < target_count:
		var ordinal := _actors.size() + 1
		var actor := GRUNT_SCENE.instantiate() as Node2D
		assert(actor != null)
		var angle := TAU * float(ordinal - 1) / float(maxi(1, target_count))
		actor.position = Vector2.RIGHT.rotated(angle) * 180.0
		actor.set_meta("stable_spawn_ordinal", ordinal)
		_bench_root.add_child(actor)
		_actors.append(actor)


func _measure_run(actor_count: int) -> Dictionary:
	var samples: Array[float] = []
	var process_total := 0.0
	var physics_total := 0.0
	for _sample_index in SAMPLE_FRAMES:
		var started := Time.get_ticks_usec()
		await process_frame
		samples.append(
			float(Time.get_ticks_usec() - started) / 1000.0
		)
		process_total += float(
			Performance.get_monitor(Performance.TIME_PROCESS)
		) * 1000.0
		physics_total += float(
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		) * 1000.0
	var sorted_samples := samples.duplicate()
	sorted_samples.sort()
	return {
		"actor_count": actor_count,
		"living_actor_count": _actors.size(),
		"frame_ms_average": _average(samples),
		"frame_ms_p50": _percentile(sorted_samples, 0.50),
		"frame_ms_p95": _percentile(sorted_samples, 0.95),
		"frame_ms_p99": _percentile(sorted_samples, 0.99),
		"frame_ms_worst": sorted_samples[-1],
		"engine_process_ms": process_total / float(SAMPLE_FRAMES),
		"engine_physics_ms": physics_total / float(SAMPLE_FRAMES),
		"node_count": int(
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		),
		"rendered_objects": int(
			Performance.get_monitor(
				Performance.RENDER_TOTAL_OBJECTS_IN_FRAME
			)
		),
	}


func _average(values: Array[float]) -> float:
	var total := 0.0
	for value in values:
		total += value
	return total / float(maxi(1, values.size()))


func _percentile(sorted_values: Array[float], ratio: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	var index := clampi(
		ceili(float(sorted_values.size()) * ratio) - 1,
		0,
		sorted_values.size() - 1
	)
	return sorted_values[index]
