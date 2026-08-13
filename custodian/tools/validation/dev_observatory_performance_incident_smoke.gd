extends SceneTree

const OBSERVATORY_SCENE := "res://game/systems/debug/dev_observatory.gd"
const EXPORT_PATH := "user://dev_observatory/performance_incident_smoke.json"

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var observatory := get_root().get_node_or_null("DevObservatory")
	_assert(observatory != null, "DevObservatory autoload is missing")
	_assert(InputMap.has_action("debug_observatory_perf_capture"), "F11 incident action is missing")
	_assert(InputMap.has_action("debug_observatory_perf_phase"), "Shift+F11 phase action is missing")
	if observatory == null:
		quit(1)
		return
	observatory.call("clear")
	observatory.call("_record_frame_sample", {"wall_frame_ms": 10.0})
	observatory.call("_record_frame_sample", {"wall_frame_ms": 20.0})
	var baseline := observatory.call("get_performance_summary") as Dictionary
	observatory.call("_record_external_stall", {"wall_frame_ms": 51000.0, "uptime_sec": 1.0, "application_focused": false, "tree_paused": false, "overlay_visible": false, "time_scale": 1.0}, &"focus_out")
	var after_stall := observatory.call("get_performance_summary") as Dictionary
	_assert(after_stall.get("sample_count") == baseline.get("sample_count"), "external stall contaminated gameplay sample count")
	_assert(after_stall.get("frame_ms_worst") == baseline.get("frame_ms_worst"), "external stall contaminated gameplay worst frame")
	_assert((observatory.get("_performance_external_stalls") as Array).size() == 1, "51-second sample was not retained as an external stall")
	var hitches_before_giant := int((observatory.call("get_performance_summary") as Dictionary).get("hitch_count", 0))
	observatory.call("_invalidate_wall_clock", &"test_external_stall")
	observatory.call("_sample_frame_time_from_ticks", 100000, 0.016)
	observatory.call("_sample_frame_time_from_ticks", 51100000, 0.016)
	var after_giant_ticks := observatory.call("get_performance_summary") as Dictionary
	_assert(int(after_giant_ticks.get("hitch_count", 0)) == hitches_before_giant, "51-second tick sample incremented gameplay hitch counters")
	_assert(not bool(observatory.get("performance_incident_active")), "51-second tick sample auto-triggered an incident")
	observatory.call("_invalidate_wall_clock", &"focus_out")
	observatory.call("_sample_frame_time_from_ticks", 1000000, 0.5)
	_assert(int(observatory.get("_last_wall_frame_usec")) == 1000000, "focus boundary did not reset wall-clock origin")
	Engine.time_scale = 0.1
	observatory.call("_sample_frame_time_from_ticks", 1150000, 0.5)
	Engine.time_scale = 1.0
	_assert(is_equal_approx(float((observatory.get("_performance_preroll") as Array).back().get("wall_frame_ms")), 150.0), "time scale altered wall-frame calculation")
	var stalls_before_focus := (observatory.get("_performance_external_stalls") as Array).size()
	observatory.set("_focus_out_usec", 1000000)
	observatory.call("_handle_focus_in", 6000000)
	_assert((observatory.get("_performance_external_stalls") as Array).size() == stalls_before_focus + 1, "focus loss duration was not retained as an external stall")
	observatory.call("clear")
	observatory.call("_invalidate_wall_clock", &"automatic_trigger_test")
	observatory.call("_sample_frame_time_from_ticks", 1000000, 0.06)
	for index in range(30):
		observatory.call("_sample_frame_time_from_ticks", 1060000 + index * 60000, 0.06)
	_assert(bool(observatory.get("performance_incident_active")), "degraded gameplay did not auto-trigger an incident")
	_assert(int(observatory.get("_performance_auto_trigger_count")) == 1, "automatic trigger count was not exactly one")
	observatory.call("stop_performance_incident", &"automatic_window_complete")
	for index in range(60):
		observatory.call("_sample_frame_time_from_ticks", 3000000 + index * 60000, 0.06)
	_assert(not bool(observatory.get("performance_incident_active")), "degraded latch retriggered automatic capture")
	_assert(int(observatory.get("_performance_auto_trigger_count")) == 1, "degraded latch incremented automatic trigger count")
	for index in range(188):
		observatory.call("_update_incident_rearm", {"wall_frame_ms": 16.0})
	_assert(observatory.get("_performance_incident_state") == &"ARMED", "three healthy seconds did not rearm automatic capture")
	observatory.call("start_performance_incident")
	_assert(bool(observatory.get("performance_incident_active")), "capture did not start with overlay-independent API")
	observatory.call("_record_external_stall", {"wall_frame_ms": 51000.0, "uptime_sec": 2.0, "application_focused": false, "tree_paused": false, "overlay_visible": false, "time_scale": 1.0}, &"focus_out")
	observatory.call("mark_performance_phase", "spawn")
	observatory.call("mark_performance_phase", "combat_hit")
	_assert(observatory.get("performance_incident_phase") == "combat_hit", "phase marker did not advance")
	var started: int = observatory.call("perf_span_begin")
	OS.delay_msec(1)
	observatory.call("perf_span_end", &"enemy_behavior", started)
	var spans := observatory.get("_frame_performance_spans") as Dictionary
	_assert(int((spans.get("enemy_behavior", {}) as Dictionary).get("count", 0)) == 1, "span aggregation count drifted")
	_assert(int((spans.get("enemy_behavior", {}) as Dictionary).get("total_usec", 0)) > 0, "span aggregation did not retain elapsed time")
	Engine.time_scale = 0.1
	OS.delay_msec(2)
	observatory.call("_sample_frame_time", 0.5)
	OS.delay_msec(2)
	observatory.call("_sample_frame_time", 0.5)
	var timed_sample := (observatory.get("_frame_samples") as Array).back() as Dictionary
	_assert(float(timed_sample.get("scaled_delta_ms", 0.0)) >= 500.0, "scaled delta was not retained")
	_assert(float(timed_sample.get("wall_frame_ms", 999.0)) < 100.0, "wall frame time was contaminated by time scale")
	Engine.time_scale = 1.0
	observatory.call("set_gauge", &"living_enemies", 4)
	observatory.call("set_gauge", &"active_vfx", 0)
	observatory.call("set_gauge", &"active_combat_audio", 0)
	observatory.call("adjust_gauge", &"active_vfx", 1)
	observatory.call("adjust_gauge", &"active_vfx", -1)
	observatory.call("adjust_gauge", &"active_combat_audio", 1)
	observatory.call("adjust_gauge", &"active_combat_audio", -1)
	_assert(int(observatory.get("gauges").get("active_vfx", -1)) == 0, "temporary VFX gauge did not return to baseline")
	_assert(int(observatory.get("gauges").get("active_combat_audio", -1)) == 0, "temporary audio gauge did not return to baseline")
	var incident_sample := {"uptime_sec": 1.0, "phase": "spawn", "wall_frame_ms": 147.6, "process_ms": 118.2, "physics_ms": 12.1, "node_count": 100, "living_enemies": 4, "corpse_enemies": 0, "active_vfx": 0, "active_audio_players": 0, "draw_calls": 14, "rendered_objects": 20, "spans": {"enemy_behavior": {"count": 1, "total_usec": 89400, "max_usec": 89400}}}
	observatory.call("_record_frame_sample", incident_sample)
	var captured_samples := observatory.get("_frame_samples") as Array
	captured_samples.append(incident_sample)
	observatory.set("_frame_samples", captured_samples)
	observatory.call("_record_worst_frame", {"sample": {"wall_frame_ms": 147.6}, "recent_events": [], "recent_warnings": []})
	observatory.call("stop_performance_incident")
	var report := observatory.call("get_performance_incident_report") as Dictionary
	_assert((report.get("external_stalls", []) as Array).size() == 1, "incident export did not retain external stall")
	_assert((report.get("worst_frames", []) as Array).size() <= 20, "worst-frame cap exceeded")
	_assert((report.get("phase_snapshots", []) as Array).size() >= 3, "phase snapshots were not retained")
	_assert(report.has("likely_owner"), "incident classification is missing")
	var spawn_phase := (report.get("phase_summaries", {}) as Dictionary).get("spawn", {}) as Dictionary
	_assert(float(spawn_phase.get("process_ms", 0.0)) < 1000.0, "incident process time was summed instead of averaged")
	_assert(float(spawn_phase.get("physics_ms", 0.0)) < 1000.0, "incident physics time was summed instead of averaged")
	_assert(float(spawn_phase.get("average_ms", 0.0)) > 0.0, "incident phase frame average was lost")
	var exported := observatory.call("export_session_json", EXPORT_PATH) as String
	_assert(exported == EXPORT_PATH, "incident export failed")
	var file := FileAccess.open(EXPORT_PATH, FileAccess.READ)
	_assert(file != null, "incident export file is missing")
	if file != null:
		var payload := JSON.parse_string(file.get_as_text()) as Dictionary
		_assert(payload.has("performance_incident"), "incident payload is missing from session export")
		_assert((payload.get("performance_incident", {}) as Dictionary).has("lifetime_deltas"), "incident deltas are missing from export")
		file.close()
	if _errors.is_empty():
		print("[DevObservatoryPerformanceIncidentSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[DevObservatoryPerformanceIncidentSmoke] %s" % error)
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
