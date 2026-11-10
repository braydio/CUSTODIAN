extends SceneTree

const ENVIRONMENT := preload("res://game/world/environment/world_environment_director.gd")
const PRESENTATION_PROFILE := preload("res://game/world/environment/weather_presentation_profile.gd")
const BATCH_COUNT := 200
const QUERIES_PER_BATCH := 64


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var contract := {"contract_seed": 741, "map": {"map_seed": 82}, "world_profile": {
		"profile_seed": 19, "planet_key": "terran_wet",
		"day_start_hour_min": 9.0, "day_start_hour_max": 9.0,
		"weather_weights": {"clear": 1.0},
	}}
	var legacy := ENVIRONMENT.new()
	var profiled := ENVIRONMENT.new()
	var profile := PRESENTATION_PROFILE.new()
	profile.profile_id = &"baseline_high"
	profiled.presentation_profile = profile
	legacy.configure_from_contract(contract, null)
	profiled.configure_from_contract(contract, null)
	legacy.debug_force_weather("heavy_rain")
	profiled.debug_force_weather("heavy_rain")
	for _i in 1000:
		legacy.get_presentation_state()
		profiled.get_presentation_state()
	var legacy_samples := _measure(legacy)
	var profiled_samples := _measure(profiled)
	print(JSON.stringify({
		"fixture": "fixed-contract heavy_rain presentation-state query",
		"batch_count": BATCH_COUNT,
		"queries_per_batch": QUERIES_PER_BATCH,
		"legacy_v1_path": _summarize(legacy_samples),
		"profiled_v2_high_path": _summarize(profiled_samples),
		"gpu_timing": "unavailable through the Godot script Performance API; this is CPU state-query timing only",
	}, "\t"))
	legacy.free()
	profiled.free()
	quit(0)


func _measure(director: Node) -> Array[float]:
	var samples: Array[float] = []
	var sink := 0.0
	for _batch in BATCH_COUNT:
		var started := Time.get_ticks_usec()
		for _query in QUERIES_PER_BATCH:
			var state: Dictionary = director.call("get_presentation_state")
			sink += float(state.get("precipitation_alpha", 0.0))
		samples.append(float(Time.get_ticks_usec() - started) / float(QUERIES_PER_BATCH))
	if sink < 0.0:
		push_warning("Unreachable benchmark sink: %f" % sink)
	return samples


func _summarize(samples: Array[float]) -> Dictionary:
	samples.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	return {
		"p50_query_usec": samples[int(floor(float(samples.size() - 1) * 0.50))],
		"p95_query_usec": samples[int(floor(float(samples.size() - 1) * 0.95))],
		"mean_query_usec": total / float(samples.size()),
	}
