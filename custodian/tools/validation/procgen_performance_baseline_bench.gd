extends SceneTree

## custodian.procgen_performance_baseline.v1
##
## First reproducible, structured, threshold-free procgen generation +
## runtime-streaming performance baseline. Reuses timing boundaries already
## owned by ProcGenTilemap/CustodianContractMap via ProcgenPerformanceSnapshot;
## never duplicates generation work merely to measure it, and never invents a
## universal pass/fail millisecond gate. See
## design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md (S1).
##
## Profiles:
##   quick (default) - small deterministic verification. Proves schema,
##     determinism (double-run same-seed fingerprint match), and benchmark
##     mechanics without running the full matrix. Registered in
##     validation_manifest.json.
##   --full - opt-in baseline capture across the fixed size/seed matrix. Slow;
##     not registered for normal changed-file validation.
##
## Optional --sha=<git-sha> attaches CLI-provided commit metadata, since exact
## Git SHA is not safely discoverable from headless runtime code.

const PROCGEN_MAP_SCENE := preload("res://game/world/procgen/proc_gen_map.tscn")
const CONTRACT_SCENE := preload("res://game/world/procgen/custodian_contract_map.tscn")
const SNAPSHOT_SCRIPT := preload("res://game/world/procgen/diagnostics/procgen_performance_snapshot.gd")

const SCHEMA := "custodian.procgen_performance_baseline.v1"
const REPORT_PATH := "user://performance/procgen_performance_baseline_v1.json"

const QUICK_MAP_SIZE := Vector2i(48, 48)
const QUICK_SEED := 420777

const FULL_SIZES := [Vector2i(160, 160), Vector2i(192, 192), Vector2i(224, 224)]
const FULL_SEEDS := [420777, 420779, 771923]

const RUNTIME_CASE_SIZE_QUICK := Vector2i(64, 64)
const RUNTIME_CASE_SEED := 420777
const RUNTIME_FRAME_SAMPLES := 60

var _profile := "quick"
var _git_sha := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--full":
			_profile = "full"
		elif argument.begins_with("--sha="):
			_git_sha = argument.trim_prefix("--sha=")

	var generation_cases: Array[Dictionary] = []
	var contract_cases: Array[Dictionary] = []
	var determinism_ok := true
	var runtime_case_size := RUNTIME_CASE_SIZE_QUICK

	if _profile == "full":
		for map_size in FULL_SIZES:
			for seed_value in FULL_SEEDS:
				generation_cases.append(await _run_generation_case(map_size, seed_value))
		for seed_value in FULL_SEEDS:
			contract_cases.append(await _run_contract_case(seed_value))
		runtime_case_size = FULL_SIZES[1]
	else:
		var first := await _run_generation_case(QUICK_MAP_SIZE, QUICK_SEED)
		var second := await _run_generation_case(QUICK_MAP_SIZE, QUICK_SEED)
		determinism_ok = (
			str(first.get("fingerprint", "a")) == str(second.get("fingerprint", "b"))
		)
		generation_cases.append(first)
		generation_cases.append(second)
		contract_cases.append(await _run_contract_case(QUICK_SEED))

	var runtime_case := await _run_runtime_case(runtime_case_size, RUNTIME_CASE_SEED)

	var report := {
		"schema": SCHEMA,
		"profile": _profile,
		"engine": Engine.get_version_info(),
		"debug_build": OS.is_debug_build(),
		"git_sha": _git_sha,
		"headless": DisplayServer.get_name() == "headless",
		"determinism_ok": determinism_ok,
		"generation_cases": generation_cases,
		"contract_cases": contract_cases,
		"runtime_case": runtime_case,
	}

	var absolute_path := ProjectSettings.globalize_path(REPORT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()

	_print_summary(report, absolute_path)
	quit(0 if determinism_ok else 1)


## generate() completes and emits level_data_ready synchronously before
## returning, so it never needs to be awaited: by the time generate() gives
## control back here, _on_procgen_finished() has already run to completion
## (proven by GEN_END/PIPELINE TIMING always appearing in stdout before
## this call returns). Do not `await map.level_data_ready` after this call;
## the emission already happened and the await would hang forever.
func _generate_and_wait(map: ProcGenTilemap) -> void:
	map.generate()


func _run_generation_case(map_size: Vector2i, seed_value: int) -> Dictionary:
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
	procgen.map_size = map_size
	map.procgen_node = procgen
	map.generation_evaluation_mode = false
	map.generation_output_enabled = true
	map.enable_streaming_reveal = false
	map.build_runtime_wall_collision = false

	var wall_clock_start := Time.get_ticks_msec()
	await _generate_and_wait(map)
	var wall_clock_ms := Time.get_ticks_msec() - wall_clock_start

	var snapshot := SNAPSHOT_SCRIPT.generation_snapshot(map)
	snapshot["case_id"] = "gen_%dx%d_seed%d" % [map_size.x, map_size.y, seed_value]
	snapshot["seed"] = seed_value
	snapshot["map_size"] = {"x": map_size.x, "y": map_size.y}
	snapshot["wall_clock_ms"] = wall_clock_ms

	map.queue_free()
	await process_frame
	return snapshot


func _run_contract_case(seed_value: int) -> Dictionary:
	var contract_map := CONTRACT_SCENE.instantiate() as CustodianContractMap
	contract_map.auto_generate_on_ready = false
	root.add_child(contract_map)
	await process_frame

	var wall_clock_start := Time.get_ticks_msec()
	await contract_map.generate_contract(seed_value)
	var wall_clock_ms := Time.get_ticks_msec() - wall_clock_start

	var snapshot := SNAPSHOT_SCRIPT.contract_snapshot(contract_map)
	snapshot["case_id"] = "contract_seed%d" % seed_value
	snapshot["wall_clock_ms"] = wall_clock_ms
	snapshot["contract_ok"] = not contract_map.get_latest_contract().is_empty()

	contract_map.queue_free()
	await process_frame
	return snapshot


func _run_runtime_case(map_size: Vector2i, seed_value: int) -> Dictionary:
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
	procgen.map_size = map_size
	map.procgen_node = procgen
	map.generation_evaluation_mode = false
	map.generation_output_enabled = true
	map.enable_streaming_reveal = true
	map.build_runtime_wall_collision = true

	await _generate_and_wait(map)

	var queue_peak := (map.get("_streaming_reveal_queue") as Array).size()
	var revealed_peak := map.get_resident_chunk_count()
	var revealed_before := revealed_peak
	var frame_time_ms_samples: Array = []

	for _frame in range(RUNTIME_FRAME_SAMPLES):
		var started := Time.get_ticks_usec()
		await process_frame
		frame_time_ms_samples.append(float(Time.get_ticks_usec() - started) / 1000.0)
		queue_peak = maxi(queue_peak, (map.get("_streaming_reveal_queue") as Array).size())
		revealed_peak = maxi(revealed_peak, map.get_resident_chunk_count())

	var revealed_after := map.get_resident_chunk_count()

	var snapshot := SNAPSHOT_SCRIPT.runtime_snapshot(
		map, self, queue_peak, revealed_peak, frame_time_ms_samples
	)
	snapshot["case_id"] = "runtime_%dx%d_seed%d" % [map_size.x, map_size.y, seed_value]
	snapshot["seed"] = seed_value
	snapshot["map_size"] = {"x": map_size.x, "y": map_size.y}
	snapshot["reveal_throughput_chunks"] = revealed_after - revealed_before
	snapshot["sample_frames"] = RUNTIME_FRAME_SAMPLES

	map.queue_free()
	await process_frame
	return snapshot


func _print_summary(report: Dictionary, absolute_path: String) -> void:
	print("[ProcgenPerformanceBaselineBench] profile=%s determinism_ok=%s" % [
		report["profile"], report["determinism_ok"],
	])
	for case in (report["generation_cases"] as Array):
		var c := case as Dictionary
		print("  generation %-28s total=%dms fill=%dms floor=%d walls=%d fp=%s" % [
			c.get("case_id", "?"),
			int(c.get("total_ms", 0)),
			int(c.get("fill_tilemaps_ms", 0)),
			int(c.get("floor_cell_count", 0)),
			int(c.get("wall_cell_count", 0)),
			str(c.get("fingerprint", "")),
		])
	for case in (report["contract_cases"] as Array):
		var c := case as Dictionary
		var materialized_world: Dictionary = c.get("materialized_world", {})
		print("  contract   %-28s loop=%dms promotion=%dms materialization=%dms fp=%s attempts=%d/%d accepted=%d ok=%s" % [
			c.get("case_id", "?"),
			int(c.get("total_candidate_loop_duration_ms", 0)),
			int(c.get("final_promotion_duration_ms", 0)),
			int(c.get("final_materialization_duration_ms", 0)),
			str(materialized_world.get("fingerprint", "")),
			int(c.get("attempts_run", 0)),
			int(c.get("attempt_limit", 0)),
			int(c.get("accepted_attempt", -1)),
			str(c.get("contract_ok", false)),
		])
	var runtime_case := report["runtime_case"] as Dictionary
	var samples := runtime_case.get("frame_time_ms_samples", []) as Array
	var frame_avg := 0.0
	for sample in samples:
		frame_avg += float(sample)
	frame_avg = frame_avg / float(maxi(1, samples.size()))
	print("  runtime    %-28s frame_avg_ms=%.3f revealed=%d queue_peak=%d draw_calls=%d nodes=%d" % [
		runtime_case.get("case_id", "?"),
		frame_avg,
		int(runtime_case.get("revealed_chunk_count", 0)),
		int(runtime_case.get("streaming_reveal_queue_peak", 0)),
		int(runtime_case.get("draw_calls", 0)),
		int(runtime_case.get("node_count", 0)),
	])
	print("[ProcgenPerformanceBaselineBench] COMPLETE report=%s" % absolute_path)
