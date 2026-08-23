extends Node

signal toggled(enabled: bool)
signal event_logged(kind: StringName, data: Dictionary)
signal warning_logged(message: String, data: Dictionary)

const OVERLAY_SCENE_PATH := "res://scenes/debug/dev_observatory_overlay.tscn"
const INPUT_ACTION := "debug_observatory"
const EXPORT_INPUT_ACTION := "debug_observatory_export"
const PERFORMANCE_CAPTURE_INPUT_ACTION := "debug_observatory_perf_capture"
const PERFORMANCE_PHASE_INPUT_ACTION := "debug_observatory_perf_phase"
const DEFAULT_EXPORT_DIR := "user://dev_observatory"
const DEFAULT_EXPORT_PATH := "user://dev_observatory/latest_session.json"
const FRAME_SAMPLE_CAPACITY := 600
const HITCH_THRESHOLD_MS := 33.333
const SEVERE_HITCH_THRESHOLD_MS := 50.0
const PERF_PREROLL_FRAMES := 180
const PERF_POSTROLL_SEC := 8.0
const PERF_WORST_FRAME_CAPACITY := 20
const PERF_AUTO_TRIGGER_FRAME_MS := 50.0
const PERF_AUTO_TRIGGER_COUNT := 3
const PERF_EXTERNAL_STALL_THRESHOLD_MS := 2000.0
const PERF_EXTERNAL_STALL_CAPACITY := 20
const PERF_RECOVERY_THRESHOLD_MS := 25.0
const PERF_REARM_DURATION_SEC := 3.0
const PERF_STATE_ARMED := &"ARMED"
const PERF_STATE_CAPTURING := &"CAPTURING"
const PERF_STATE_DEGRADED_LATCHED := &"DEGRADED_LATCHED"
const PERF_STATE_REARMING := &"REARMING"

@export var max_events := 300
@export var sample_interval := 0.25
@export var auto_create_overlay := true

var enabled := false
var events: Array[Dictionary] = []
var total_events_logged := 0
var dropped_event_count := 0
var counters: Dictionary = {}
var gauges: Dictionary = {}
var warnings: Array[Dictionary] = []
var last_export_path := ""
var last_export_absolute_path := ""
var last_export_time := ""
var last_export_error := ""
var performance_capture_enabled := false
var performance_page_active := false
var runtime_tree_sampling_enabled := false
var performance_incident_active := false
var performance_incident_phase := "baseline"

var _sample_accum := 0.0
var _overlay: CanvasLayer = null
var _boot_time_msec := 0
var _runtime_tree_scan_count := 0
var _telemetry_allowed := true
var _force_snapshot_write := false
var _frame_time_samples_ms: PackedFloat32Array = []
var _frame_time_worst_ms := 0.0
var _hitch_count := 0
var _severe_hitch_count := 0
var _last_wall_frame_usec := 0
var _skip_next_wall_sample_reason: StringName = &"startup"
var _application_focused := true
var _focus_out_usec := 0
var _last_tree_paused := false
var _frame_performance_spans: Dictionary = {}
var _frame_samples: Array[Dictionary] = []
var _performance_preroll: Array[Dictionary] = []
var _performance_worst_frames: Array[Dictionary] = []
var _performance_phase_snapshots: Array[Dictionary] = []
var _performance_incident_started_uptime := 0.0
var _performance_incident_ended_uptime := 0.0
var _performance_postroll_remaining := 0.0
var _performance_auto_triggered := false
var _performance_incident_state: StringName = PERF_STATE_ARMED
var _performance_incident_trigger: StringName = &""
var _performance_auto_trigger_count := 0
var _performance_manual_trigger_count := 0
var _performance_external_stalls: Array[Dictionary] = []
var _performance_samples_dropped := 0
var _performance_rearm_progress_sec := 0.0
var _performance_start_snapshot: Dictionary = {}
var _performance_end_snapshot: Dictionary = {}
var _manual_capture_return_state: StringName = PERF_STATE_ARMED
var _last_procgen_runtime_health: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_boot_time_msec = Time.get_ticks_msec()
	_last_tree_paused = get_tree().paused if get_tree() != null else false
	_telemetry_allowed = _dev_allows(&"dev")
	set_process_input(_dev_allows(&"debug_ui"))
	set_process(_dev_allows(&"observatory_sampling"))
	_ensure_input_actions()

	if auto_create_overlay and _dev_allows(&"debug_ui"):
		_create_overlay()

	log_event(&"observatory_ready", {
		"overlay_scene": OVERLAY_SCENE_PATH,
		"input_action": INPUT_ACTION
	})


func _input(event: InputEvent) -> void:
	if not _dev_allows(&"debug_ui"):
		return
	var key_event := event as InputEventKey
	if key_event != null and key_event.echo:
		return
	if event.is_action_pressed(INPUT_ACTION):
		get_viewport().set_input_as_handled()
		toggle()
		return

	if event.is_action_pressed(EXPORT_INPUT_ACTION):
		export_timestamped_session_json()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(PERFORMANCE_PHASE_INPUT_ACTION):
		mark_performance_phase()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(PERFORMANCE_CAPTURE_INPUT_ACTION):
		toggle_performance_incident()
		get_viewport().set_input_as_handled()
		return


func _process(delta: float) -> void:
	if not _dev_allows(&"observatory_sampling"):
		return
	var tree_paused := get_tree().paused if get_tree() != null else false
	if tree_paused != _last_tree_paused:
		_invalidate_wall_clock(&"pause" if tree_paused else &"resume")
		_last_tree_paused = tree_paused
	_sample_frame_time(delta)
	if performance_incident_active and _performance_postroll_remaining > 0.0:
		_performance_postroll_remaining = maxf(0.0, _performance_postroll_remaining - delta)
		if _performance_postroll_remaining <= 0.0:
			stop_performance_incident()
	if not enabled:
		return
	_sample_accum += delta
	if _sample_accum >= sample_interval:
		_sample_accum = 0.0
		_sample_runtime_gauges(
			runtime_tree_sampling_enabled,
			not performance_page_active
		)
		# Deliberate World/Procgen sampling is a one-shot request. Overlay page
		# selection never sets this flag.
		runtime_tree_sampling_enabled = false


func toggle() -> void:
	set_enabled(!enabled)


func set_enabled(value: bool) -> void:
	if value and not _dev_allows(&"debug_ui"):
		return
	if enabled == value:
		return

	var started_usec := Time.get_ticks_usec()
	var visible_before := enabled
	var paused_before := get_tree().paused if get_tree() != null else false
	var scale_before := Engine.time_scale
	if value and performance_incident_active:
		stop_performance_incident(&"observatory_overlay_opened")
	_invalidate_wall_clock(&"overlay_open" if value else &"overlay_close")
	enabled = value
	_sample_accum = 0.0

	if _overlay != null:
		_overlay.visible = enabled

	toggled.emit(enabled)
	var paused_after := get_tree().paused if get_tree() != null else false
	var scale_after := Engine.time_scale
	var overlay_build_usec := int(gauges.get(&"observatory_overlay_build_usec", 0))
	log_event(&"observatory_overlay_toggled", {
		"requested_visible": value, "visible_before": visible_before,
		"visible_after": enabled, "tree_paused_before": paused_before,
		"tree_paused_after": paused_after, "time_scale_before": scale_before,
		"time_scale_after": scale_after, "application_focused": _application_focused,
		"toggle_usec": Time.get_ticks_usec() - started_usec,
		"overlay_build_usec": overlay_build_usec,
		"overlay_text_character_count": int(gauges.get(&"observatory_overlay_text_chars", 0)),
		"overlay_line_count": int(gauges.get(&"observatory_overlay_line_count", 0)),
	})
	if paused_before != paused_after or not is_equal_approx(scale_before, scale_after):
		mark_warning("F9 changed gameplay timing state.", {"paused_before": paused_before, "paused_after": paused_after, "time_scale_before": scale_before, "time_scale_after": scale_after})


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_application_focused = false
			_focus_out_usec = Time.get_ticks_usec()
			_invalidate_wall_clock(&"focus_out")
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_handle_focus_in(Time.get_ticks_usec())


func _handle_focus_in(focus_in_usec: int) -> void:
	if _focus_out_usec > 0 and focus_in_usec - _focus_out_usec >= int(PERF_EXTERNAL_STALL_THRESHOLD_MS * 1000.0):
		_record_external_stall({"wall_frame_ms": float(focus_in_usec - _focus_out_usec) / 1000.0, "uptime_sec": get_uptime_sec(), "phase": performance_incident_phase, "application_focused": false, "tree_paused": get_tree().paused if get_tree() != null else false, "overlay_visible": enabled, "time_scale": Engine.time_scale}, &"focus_out")
	_focus_out_usec = 0
	_application_focused = true
	_invalidate_wall_clock(&"focus_in")


func _invalidate_wall_clock(reason: StringName) -> void:
	_last_wall_frame_usec = 0
	_skip_next_wall_sample_reason = reason


func log_event(kind: StringName, data: Dictionary = {}) -> void:
	if not _telemetry_allowed:
		return
	total_events_logged += 1
	var entry := {
		"time_msec": Time.get_ticks_msec(),
		"uptime_sec": get_uptime_sec(),
		"kind": kind,
		"data": data
	}

	events.append(entry)

	while events.size() > max_events:
		events.pop_front()
		dropped_event_count += 1

	event_logged.emit(kind, data)


func increment(name: StringName, amount: int = 1) -> void:
	if not _telemetry_allowed:
		return
	counters[name] = int(counters.get(name, 0)) + amount


func adjust_gauge(name: StringName, amount: int) -> void:
	set_gauge(name, int(gauges.get(name, 0)) + amount)


func perf_span_begin() -> int:
	if not performance_incident_active:
		return 0
	return Time.get_ticks_usec()


func perf_span_end(span_name: StringName, started_usec: int) -> void:
	if started_usec <= 0:
		return
	var elapsed_usec := maxi(0, Time.get_ticks_usec() - started_usec)
	var bucket: Dictionary = _frame_performance_spans.get(span_name, {
		"count": 0, "total_usec": 0, "max_usec": 0,
	})
	bucket["count"] = int(bucket["count"]) + 1
	bucket["total_usec"] = int(bucket["total_usec"]) + elapsed_usec
	bucket["max_usec"] = maxi(int(bucket["max_usec"]), elapsed_usec)
	_frame_performance_spans[span_name] = bucket


func accumulate(name: StringName, amount: float) -> void:
	if not _telemetry_allowed:
		return
	counters[name] = float(counters.get(name, 0.0)) + amount


func set_counter(name: StringName, value: int) -> void:
	if not _telemetry_allowed:
		return
	counters[name] = value


func set_gauge(name: StringName, value: Variant) -> void:
	if not _telemetry_allowed and not _force_snapshot_write:
		return
	gauges[name] = value


func mark_warning(message: String, data: Dictionary = {}) -> void:
	if not _telemetry_allowed:
		return
	var entry := {
		"time_msec": Time.get_ticks_msec(),
		"uptime_sec": get_uptime_sec(),
		"message": message,
		"data": data
	}

	warnings.append(entry)

	while warnings.size() > 100:
		warnings.pop_front()

	increment(&"warnings")
	log_event(&"warning", {
		"message": message,
		"data": data
	})

	warning_logged.emit(message, data)


func _dev_allows(capability: StringName) -> bool:
	var dev_mode := get_node_or_null("/root/DevMode")
	return dev_mode == null or (dev_mode.has_method("allows") and bool(dev_mode.call("allows", capability)))


func clear() -> void:
	events.clear()
	total_events_logged = 0
	dropped_event_count = 0
	counters.clear()
	gauges.clear()
	warnings.clear()
	_frame_time_samples_ms.clear()
	_frame_time_worst_ms = 0.0
	_hitch_count = 0
	_severe_hitch_count = 0
	_frame_samples.clear()
	_performance_preroll.clear()
	_performance_worst_frames.clear()
	_performance_phase_snapshots.clear()
	_frame_performance_spans.clear()
	_performance_external_stalls.clear()
	_performance_samples_dropped = 0
	_performance_rearm_progress_sec = 0.0
	performance_incident_active = false
	performance_capture_enabled = false
	_performance_auto_triggered = false
	_performance_incident_trigger = &""
	_performance_auto_trigger_count = 0
	_performance_manual_trigger_count = 0
	_performance_incident_state = PERF_STATE_ARMED
	_invalidate_wall_clock(&"capture_reset")
	log_event(&"observatory_cleared")


func set_performance_capture_enabled(value: bool) -> void:
	# Compatibility shim: capture lifecycle is owned by the incident recorder,
	# never by page selection.
	performance_capture_enabled = value and _dev_allows(&"observatory_sampling")


func set_performance_page_active(value: bool) -> void:
	performance_page_active = value and enabled


func set_runtime_tree_sampling_enabled(value: bool) -> void:
	# Compatibility API for explicit diagnostics. A true value is consumed by
	# the next visible sampling pass and cannot become a periodic recursive scan.
	runtime_tree_sampling_enabled = (
		value and enabled and _dev_allows(&"observatory_sampling")
	)


func get_performance_summary() -> Dictionary:
	var current_ms := 0.0
	if not _frame_time_samples_ms.is_empty():
		current_ms = _frame_time_samples_ms[-1]
	return {
		"sample_count": _frame_time_samples_ms.size(),
		"sample_capacity": FRAME_SAMPLE_CAPACITY,
		"frame_ms_current": current_ms,
		"frame_ms_average": _average(_frame_time_samples_ms),
		"frame_ms_p95": _percentile(_frame_time_samples_ms, 0.95),
		"frame_ms_p99": _percentile(_frame_time_samples_ms, 0.99),
		"frame_ms_worst": _frame_time_worst_ms,
		"hitch_count": _hitch_count,
		"severe_hitch_count": _severe_hitch_count,
		"incident_active": performance_incident_active,
		"incident_phase": performance_incident_phase,
		"incident_sample_count": _frame_samples.size(),
	}


func _sample_frame_time(delta: float) -> void:
	_sample_frame_time_from_ticks(Time.get_ticks_usec(), delta)


func _sample_frame_time_from_ticks(now_usec: int, scaled_delta: float) -> void:
	if _last_wall_frame_usec == 0:
		_last_wall_frame_usec = now_usec
		_skip_next_wall_sample_reason = &""
		return
	var wall_frame_ms := float(now_usec - _last_wall_frame_usec) / 1000.0
	_last_wall_frame_usec = now_usec
	if not _application_focused:
		# Background/application-unfocused frames are not gameplay samples. Clear
		# any spans collected during the frame and keep them out of every
		# performance accumulator, trigger window, dossier, and rearm clock.
		_frame_performance_spans.clear()
		return
	var sample := {
		"uptime_sec": get_uptime_sec(),
		"phase": performance_incident_phase,
		"wall_frame_ms": wall_frame_ms,
		"scaled_delta_ms": maxf(scaled_delta, 0.0) * 1000.0,
		"time_scale": Engine.time_scale,
		"application_focused": _application_focused,
		"tree_paused": get_tree().paused if get_tree() != null else false,
		"overlay_visible": enabled,
		"process_ms": float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0,
		"physics_ms": float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0,
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"rendered_objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"living_enemies": int(gauges.get("living_enemies", gauges.get("active_enemies", 0))),
		"corpse_enemies": int(gauges.get("corpse_enemies", 0)),
		"enemy_active": int(gauges.get("enemy_tier_active", 0)),
		"enemy_nearby": int(gauges.get("enemy_tier_nearby", 0)),
		"enemy_background": int(gauges.get("enemy_tier_background", 0)),
		"enemy_dormant": int(gauges.get("enemy_tier_dormant", 0)),
		"active_vfx": int(gauges.get("active_vfx", 0)),
		"active_audio_players": int(gauges.get("active_combat_audio", 0)),
		"active_combat_audio": int(gauges.get("active_combat_audio", 0)),
		"active_projectiles": int(gauges.get("active_projectiles", 0)),
		"spans": _frame_performance_spans.duplicate(true),
	}
	if wall_frame_ms >= PERF_EXTERNAL_STALL_THRESHOLD_MS:
		_record_external_stall(sample, _skip_next_wall_sample_reason)
		_frame_performance_spans.clear()
		return
	_record_frame_sample(sample)
	_frame_performance_spans.clear()
	if not performance_incident_active:
		_performance_preroll.append(sample)
		while _performance_preroll.size() > PERF_PREROLL_FRAMES:
			_performance_preroll.pop_front()
		_auto_trigger_if_needed()
	else:
		if _frame_samples.size() >= FRAME_SAMPLE_CAPACITY:
			_performance_samples_dropped += 1
		else:
			_frame_samples.append(sample)
		_record_worst_frame(sample)
	_update_incident_rearm(sample)


func _record_external_stall(sample: Dictionary, reason: StringName = &"") -> void:
	var stall := {
		"duration_ms": float(sample.get("wall_frame_ms", 0.0)),
		"uptime_sec": float(sample.get("uptime_sec", get_uptime_sec())),
		"phase": sample.get("phase", performance_incident_phase),
		"reason": String(reason) if reason != &"" else "external_or_unclassified_stall",
		"application_focused": bool(sample.get("application_focused", _application_focused)),
		"tree_paused": bool(sample.get("tree_paused", false)),
		"overlay_visible": bool(sample.get("overlay_visible", enabled)),
		"time_scale": float(sample.get("time_scale", Engine.time_scale)),
	}
	_performance_external_stalls.append(stall)
	if _performance_external_stalls.size() > PERF_EXTERNAL_STALL_CAPACITY:
		_performance_external_stalls.pop_front()
	set_gauge(&"performance_incident_external_stall_count", _performance_external_stalls.size())
	log_event(&"performance_external_stall", stall)

func _record_frame_sample(sample: Dictionary) -> void:
	_frame_time_samples_ms.append(float(sample.get("wall_frame_ms", 0.0)))
	if _frame_time_samples_ms.size() > FRAME_SAMPLE_CAPACITY:
		_frame_time_samples_ms.remove_at(0)
	_frame_time_worst_ms = maxf(_frame_time_worst_ms, float(sample.get("wall_frame_ms", 0.0)))
	if float(sample.get("wall_frame_ms", 0.0)) >= HITCH_THRESHOLD_MS:
		_hitch_count += 1
	if float(sample.get("wall_frame_ms", 0.0)) >= SEVERE_HITCH_THRESHOLD_MS:
		_severe_hitch_count += 1


func toggle_performance_incident() -> void:
	if performance_incident_active:
		stop_performance_incident()
	else:
		start_performance_incident()


func start_performance_incident(trigger: StringName = &"manual") -> void:
	if performance_incident_active:
		return
	performance_incident_active = true
	performance_capture_enabled = true
	_performance_incident_trigger = trigger
	if trigger == &"automatic":
		_performance_auto_trigger_count += 1
	else:
		_performance_manual_trigger_count += 1
		_manual_capture_return_state = _performance_incident_state if _performance_incident_state in [PERF_STATE_DEGRADED_LATCHED, PERF_STATE_REARMING] else PERF_STATE_ARMED
	_set_incident_state(PERF_STATE_CAPTURING)
	_performance_postroll_remaining = 0.0
	_performance_incident_started_uptime = get_uptime_sec()
	_performance_incident_ended_uptime = 0.0
	_frame_samples = _performance_preroll.duplicate(true)
	_performance_samples_dropped = 0
	_performance_external_stalls.clear()
	_performance_start_snapshot = _cheap_incident_snapshot()
	_performance_worst_frames.clear()
	for sample in _frame_samples:
		_record_worst_frame(sample)
	_performance_phase_snapshots = [{"phase": performance_incident_phase, "uptime_sec": get_uptime_sec(), "gauges": gauges.duplicate(true), "deltas": {}}]
	_invalidate_wall_clock(&"incident_start")
	log_event(&"performance_incident_started", {"phase": performance_incident_phase, "trigger": trigger, "preroll_samples": _frame_samples.size()})


func stop_performance_incident(reason: StringName = &"manual") -> void:
	if not performance_incident_active:
		return
	performance_incident_active = false
	performance_capture_enabled = false
	_performance_incident_ended_uptime = get_uptime_sec()
	_performance_end_snapshot = _cheap_incident_snapshot()
	_performance_postroll_remaining = 0.0
	_set_incident_state(PERF_STATE_DEGRADED_LATCHED if _performance_incident_trigger == &"automatic" else _manual_capture_return_state)
	_invalidate_wall_clock(&"incident_stop")
	log_event(&"performance_incident_stopped", {"reason": reason, "samples": _frame_samples.size(), "worst_frames": _performance_worst_frames.size()})


func _set_incident_state(value: StringName) -> void:
	if _performance_incident_state == value:
		return
	var previous := _performance_incident_state
	_performance_incident_state = value
	set_gauge(&"performance_incident_state", String(value))
	log_event(&"performance_incident_state_changed", {"from": previous, "to": value})


func _update_incident_rearm(sample: Dictionary) -> void:
	if _performance_incident_state != PERF_STATE_DEGRADED_LATCHED and _performance_incident_state != PERF_STATE_REARMING:
		return
	var healthy := float(sample.get("wall_frame_ms", 0.0)) < PERF_RECOVERY_THRESHOLD_MS
	if not healthy:
		_performance_rearm_progress_sec = 0.0
		_set_incident_state(PERF_STATE_DEGRADED_LATCHED)
		return
	_set_incident_state(PERF_STATE_REARMING)
	_performance_rearm_progress_sec += float(sample.get("wall_frame_ms", 0.0)) / 1000.0
	set_gauge(&"performance_incident_rearm_progress_sec", _performance_rearm_progress_sec)
	if _performance_rearm_progress_sec >= PERF_REARM_DURATION_SEC:
		_performance_rearm_progress_sec = 0.0
		_performance_auto_triggered = false
		_set_incident_state(PERF_STATE_ARMED)


func _cheap_incident_snapshot() -> Dictionary:
	return {
		"uptime_sec": get_uptime_sec(), "overlay_visible": enabled,
		"application_focused": _application_focused,
		"tree_paused": get_tree().paused if get_tree() != null else false,
		"time_scale": Engine.time_scale, "gauges": gauges.duplicate(true),
		"procgen_runtime_health": _get_procgen_runtime_health_snapshot(),
	}


func get_performance_incident_report() -> Dictionary:
	var first := _frame_samples[0] if not _frame_samples.is_empty() else {}
	var last := _frame_samples[-1] if not _frame_samples.is_empty() else {}
	var deltas := {}
	for key in ["node_count", "living_enemies", "corpse_enemies", "active_vfx", "active_audio_players", "draw_calls", "rendered_objects"]:
		deltas["%s_delta" % key] = int(last.get(key, 0)) - int(first.get(key, 0))
	deltas["active_audio_delta"] = deltas.get("active_audio_players_delta", 0)
	var gameplay_values := PackedFloat32Array()
	for sample in _frame_samples:
		gameplay_values.append(float(sample.get("wall_frame_ms", 0.0)))
	var summary := {
		"sample_count": _frame_samples.size(), "frame_ms_average": _average(gameplay_values),
		"frame_ms_p95": _percentile(gameplay_values, 0.95), "frame_ms_p99": _percentile(gameplay_values, 0.99),
		"frame_ms_worst": _percentile(gameplay_values, 1.0), "hitch_count": _count_threshold(gameplay_values, HITCH_THRESHOLD_MS),
		"severe_hitch_count": _count_threshold(gameplay_values, SEVERE_HITCH_THRESHOLD_MS),
	}
	var aggregate_spans := _aggregate_spans(_frame_samples)
	var top_spans := _top_spans(aggregate_spans, _frame_samples.size())
	var likely := _classify_incident({
		"lifetime_deltas": deltas,
		"wall_ms": float(summary.get("frame_ms_average", 0.0)),
		"physics_ms": _average_frame_sample_field("physics_ms"),
		"process_ms": _average_frame_sample_field("process_ms"),
	}, top_spans)
	return {
		"schema": "custodian.dev_observatory.performance_incident.v1",
		"state": String(_performance_incident_state), "trigger": String(_performance_incident_trigger),
		"started_uptime_sec": _performance_incident_started_uptime,
		"ended_uptime_sec": _performance_incident_ended_uptime if _performance_incident_ended_uptime > 0.0 else get_uptime_sec(),
		"phase_summaries": _build_phase_summaries(), "summary": summary,
		"worst_frames": _performance_worst_frames.duplicate(true),
		"external_stalls": _performance_external_stalls.duplicate(true),
		"start_snapshot": _performance_start_snapshot.duplicate(true), "end_snapshot": _performance_end_snapshot.duplicate(true),
		"deltas": deltas, "lifetime_deltas": deltas, "likely_owner": {"classification": likely, "evidence": top_spans},
		"top_spans": top_spans, "aggregate_spans": aggregate_spans,
		"phase_snapshots": _performance_phase_snapshots.duplicate(true),
		"recent_procgen_mutations": _get_recent_procgen_mutations(16),
		"samples_retained": _frame_samples.size(), "samples_dropped": _performance_samples_dropped,
	}


func _get_recent_procgen_mutations(limit: int = 16) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for index in range(events.size() - 1, -1, -1):
		var event: Dictionary = events[index]
		var kind := str(event.get("kind", ""))
		if kind.begins_with("procgen_runtime_") or kind.begins_with("procgen_walkable_") or kind.begins_with("procgen_navigation_") or kind.begins_with("procgen_shadow_") or kind.begins_with("ash_bell_threadway_resolution_"):
			out.append(event)
			if out.size() >= limit:
				break
	return out


func _count_threshold(values: PackedFloat32Array, threshold: float) -> int:
	var count := 0
	for value in values:
		if value >= threshold:
			count += 1
	return count


func _aggregate_top_spans(samples: Array[Dictionary]) -> Array[Dictionary]:
	return _top_spans(_aggregate_spans(samples))


func _aggregate_spans(samples: Array[Dictionary]) -> Dictionary:
	var aggregate := {}
	for sample in samples:
		for name in (sample.get("spans", {}) as Dictionary).keys():
			var source: Dictionary = sample.get("spans", {})[name]
			var bucket: Dictionary = aggregate.get(name, {"count": 0, "total_usec": 0, "max_usec": 0})
			bucket.count += int(source.get("count", 0))
			bucket.total_usec += int(source.get("total_usec", 0))
			bucket.max_usec = maxi(int(bucket.max_usec), int(source.get("max_usec", 0)))
			aggregate[name] = bucket
	return aggregate


func _build_phase_summaries() -> Dictionary:
	var phases := {}
	for sample in _frame_samples:
		var name := String(sample.get("phase", "unknown"))
		var bucket: Dictionary = phases.get(name, {"values": PackedFloat32Array(), "process": 0.0, "physics": 0.0})
		var values := bucket.values as PackedFloat32Array
		values.append(float(sample.get("wall_frame_ms", 0.0)))
		bucket["values"] = values
		bucket.process += float(sample.get("process_ms", 0.0))
		bucket.physics += float(sample.get("physics_ms", 0.0))
		phases[name] = bucket
	var output := {}
	for name in phases:
		var bucket: Dictionary = phases[name]
		var values: PackedFloat32Array = bucket.values
		var count := maxi(1, values.size())
		var process_avg := float(bucket.process) / count
		var physics_avg := float(bucket.physics) / count
		output[name] = {"average_ms": _average(values), "p95_ms": _percentile(values, 0.95), "p99_ms": _percentile(values, 0.99), "process_ms": process_avg, "physics_ms": physics_avg, "unaccounted_ms": maxf(0.0, _average(values) - process_avg - physics_avg)}
	return output


func _top_spans(spans_variant: Variant, sample_count: int = 1) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if not (spans_variant is Dictionary):
		return rows
	for key in (spans_variant as Dictionary).keys():
		var bucket: Dictionary = spans_variant[key]
		var total_ms := float(bucket.get("total_usec", 0)) / 1000.0
		rows.append({
			"name": String(key), "count": int(bucket.get("count", 0)),
			"total_ms": total_ms, "max_ms": float(bucket.get("max_usec", 0)) / 1000.0,
			"average_ms_per_sample": total_ms / float(maxi(1, sample_count)),
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.total_ms) > float(b.total_ms))
	if rows.size() > 5:
		rows.resize(5)
	return rows


func _classify_incident(summary: Dictionary, top_spans: Array[Dictionary]) -> String:
	var deltas: Dictionary = summary.get("lifetime_deltas", {})
	if int(deltas.get("active_vfx_delta", 0)) > 5:
		return "probable VFX lifetime leak"
	if int(deltas.get("active_audio_players_delta", 0)) > 5:
		return "probable combat audio lifetime leak"
	var wall_ms := float(summary.get("wall_ms", 0.0))
	var process_ms := float(summary.get("process_ms", 0.0))
	var physics_ms := float(summary.get("physics_ms", 0.0))
	var unaccounted_ms := maxf(0.0, wall_ms - process_ms - physics_ms)
	if wall_ms > 0.0 and unaccounted_ms >= maxf(process_ms, physics_ms):
		return "unaccounted wall-time / server-render-unknown dominated"
	if physics_ms > process_ms and physics_ms >= wall_ms * 0.5:
		return "physics monitor elevated — collision remains a hypothesis"
	for span in top_spans:
		if String(span.get("name", "")).begins_with("enemy_") and float(span.get("average_ms_per_sample", 0.0)) > 8.0:
			return "enemy actor script dominated"
	if int(deltas.get("draw_calls_delta", 0)) > 50:
		return "rendering / presentation dominated"
	return "unclassified — inspect worst-frame spans"


func _average_frame_sample_field(field_name: String) -> float:
	if _frame_samples.is_empty():
		return 0.0
	var total := 0.0
	for sample in _frame_samples:
		total += float(sample.get(field_name, 0.0))
	return total / float(_frame_samples.size())


func mark_performance_phase(phase_name: String = "") -> String:
	var names := ["baseline", "spawn", "pursuit", "combat_whiff", "combat_hit", "recovery"]
	var next_phase := phase_name.strip_edges()
	if next_phase.is_empty():
		var current_index := names.find(performance_incident_phase)
		next_phase = names[(current_index + 1) % names.size()]
	performance_incident_phase = next_phase
	var phase_deltas := {}
	if not _performance_phase_snapshots.is_empty():
		var previous_gauges: Dictionary = _performance_phase_snapshots[-1].get("gauges", {})
		for key in ["node_count", "living_enemies", "corpse_enemies", "active_vfx", "active_combat_audio", "draw_calls", "rendered_objects"]:
			phase_deltas["%s_delta" % key] = int(gauges.get(key, 0)) - int(previous_gauges.get(key, 0))
	_performance_phase_snapshots.append({"phase": next_phase, "uptime_sec": get_uptime_sec(), "gauges": gauges.duplicate(true), "deltas": phase_deltas})
	log_event(&"performance_incident_phase", {"phase": next_phase})
	return next_phase


func _record_worst_frame(sample: Dictionary) -> void:
	if float(sample.get("wall_frame_ms", 0.0)) < HITCH_THRESHOLD_MS:
		return
	var dossier := sample.duplicate(true)
	dossier["unaccounted_ms"] = maxf(0.0, float(sample.get("wall_frame_ms", 0.0)) - float(sample.get("process_ms", 0.0)) - float(sample.get("physics_ms", 0.0)))
	dossier["top_subsystem_spans"] = _top_spans(sample.get("spans", {}))
	dossier["recent_transition_events"] = get_recent_events(8)
	_performance_worst_frames.append(dossier)
	_performance_worst_frames.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("wall_frame_ms", 0.0)) > float(b.get("wall_frame_ms", 0.0))
	)
	if _performance_worst_frames.size() > PERF_WORST_FRAME_CAPACITY:
		_performance_worst_frames.resize(PERF_WORST_FRAME_CAPACITY)


func _auto_trigger_if_needed() -> void:
	if _performance_incident_state != PERF_STATE_ARMED or _performance_auto_triggered or _performance_preroll.size() < 30:
		return
	var severe_count := 0
	for index in range(maxi(0, _performance_preroll.size() - 60), _performance_preroll.size()):
		if float(_performance_preroll[index].get("wall_frame_ms", 0.0)) >= PERF_AUTO_TRIGGER_FRAME_MS:
			severe_count += 1
	var total := 0.0
	for index in range(maxi(0, _performance_preroll.size() - 30), _performance_preroll.size()):
		total += float(_performance_preroll[index].get("wall_frame_ms", 0.0))
	if severe_count >= PERF_AUTO_TRIGGER_COUNT or total / 30.0 >= HITCH_THRESHOLD_MS:
		_performance_auto_triggered = true
		start_performance_incident(&"automatic")
		_performance_postroll_remaining = PERF_POSTROLL_SEC


func _average(values: PackedFloat32Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _percentile(values: PackedFloat32Array, percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values := Array(values)
	sorted_values.sort()
	var index := ceili(clampf(percentile, 0.0, 1.0) * float(sorted_values.size())) - 1
	return float(sorted_values[clampi(index, 0, sorted_values.size() - 1)])


func get_recent_events(limit: int = 20, kind_filter: StringName = &"") -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	for i in range(events.size() - 1, -1, -1):
		var event_entry: Dictionary = events[i]
		if kind_filter == &"" or event_entry.get("kind", &"") == kind_filter:
			out.append(event_entry)

		if out.size() >= limit:
			break

	return out


func get_recent_warnings(limit: int = 10) -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	for i in range(warnings.size() - 1, -1, -1):
		out.append(warnings[i])
		if out.size() >= limit:
			break

	return out


func get_uptime_sec() -> float:
	return float(Time.get_ticks_msec() - _boot_time_msec) / 1000.0


func get_summary() -> Dictionary:
	return {
		"enabled": enabled,
		"uptime_sec": get_uptime_sec(),
		"event_count": events.size(),
		"event_capacity": max_events,
		"total_events_logged": total_events_logged,
		"dropped_event_count": dropped_event_count,
		"event_buffer_saturated": dropped_event_count > 0,
		"counter_count": counters.size(),
		"gauge_count": gauges.size(),
		"warning_count": warnings.size(),
		"counters": counters,
		"gauges": gauges,
		"recent_events": get_recent_events(12),
		"recent_warnings": get_recent_warnings(5)
	}


func export_session_json(path: String = DEFAULT_EXPORT_PATH) -> String:
	# Freeze the incident before the explicit final tree scan so export work is
	# never included in the captured frame stream.
	if performance_incident_active:
		stop_performance_incident()
	_force_snapshot_write = true
	_sample_runtime_gauges(true, true)
	_force_snapshot_write = false
	var resolved_path := path.strip_edges()
	if resolved_path.is_empty():
		resolved_path = DEFAULT_EXPORT_PATH

	if not _ensure_parent_dir(resolved_path):
		last_export_error = "Could not create parent directory for %s" % resolved_path
		mark_warning("Developer Observatory export failed: could not create parent directory.", {
			"path": resolved_path,
		})
		return ""

	var payload := _build_export_payload(resolved_path)
	if not _write_export_payload(resolved_path, payload):
		return ""
	_record_export_success(resolved_path)
	return resolved_path


func _write_export_payload(resolved_path: String, payload: Dictionary) -> bool:
	var file := FileAccess.open(resolved_path, FileAccess.WRITE)
	if file == null:
		var error_code := FileAccess.get_open_error()
		last_export_error = "Could not open %s (error %s)" % [resolved_path, error_code]
		mark_warning("Developer Observatory export failed: could not open file.", {
			"path": resolved_path,
			"error": error_code,
		})
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		last_export_error = "Could not write %s (error %s)" % [resolved_path, write_error]
		mark_warning("Developer Observatory export failed: could not write file.", {
			"path": resolved_path,
			"error": write_error,
		})
		return false
	return true


func _record_export_success(resolved_path: String) -> void:
	last_export_path = resolved_path
	last_export_absolute_path = ProjectSettings.globalize_path(resolved_path)
	last_export_time = Time.get_datetime_string_from_system(false, true)
	last_export_error = ""
	log_event(&"observatory_session_exported", {
		"path": resolved_path,
		"absolute_path": last_export_absolute_path,
		"event_count": events.size(),
		"warning_count": warnings.size(),
		"counter_count": counters.size(),
		"gauge_count": gauges.size(),
	})
	print("[DevObservatory] Session exported: %s" % last_export_absolute_path)

func export_timestamped_session_json() -> String:
	var stamp := Time.get_datetime_string_from_system(false, true)
	stamp = stamp.replace("-", "")
	stamp = stamp.replace(":", "")
	stamp = stamp.replace("T", "_")
	stamp = stamp.replace(" ", "_")

	var timestamped_path := "%s/session_%s.json" % [DEFAULT_EXPORT_DIR, stamp]
	if performance_incident_active:
		stop_performance_incident(&"export")
	_invalidate_wall_clock(&"capture_reset")
	_force_snapshot_write = true
	_sample_runtime_gauges(true, true)
	_force_snapshot_write = false
	if not _ensure_parent_dir(timestamped_path) or not _ensure_parent_dir(DEFAULT_EXPORT_PATH):
		return ""
	var payload := _build_export_payload(timestamped_path)
	if not _write_export_payload(timestamped_path, payload):
		return ""
	var latest_payload := payload.duplicate(true)
	latest_payload["export_path"] = DEFAULT_EXPORT_PATH
	if not _write_export_payload(DEFAULT_EXPORT_PATH, latest_payload):
		return ""
	_record_export_success(timestamped_path)
	return timestamped_path


func _build_export_payload(path: String) -> Dictionary:
	var scene_name := ""
	var scene_path := ""

	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		scene_name = tree.current_scene.name
		scene_path = tree.current_scene.scene_file_path

	return {
		"schema": "custodian.dev_observatory.session.v1",
		"exported_at": Time.get_datetime_string_from_system(false, true),
		"export_path": path,
		"metadata": {
			"project_name": ProjectSettings.get_setting("application/config/name", "CUSTODIAN"),
			"project_version": ProjectSettings.get_setting("application/config/version", ""),
		},
		"engine": {
			"version": _json_safe(Engine.get_version_info()),
			"frames_per_second": Engine.get_frames_per_second(),
			"time_scale": Engine.time_scale,
		},
		"session": {
			"uptime_sec": get_uptime_sec(),
			"boot_time_msec": _boot_time_msec,
			"event_count": events.size(),
			"event_capacity": max_events,
			"total_events_logged": total_events_logged,
			"dropped_event_count": dropped_event_count,
			"event_buffer_saturated": dropped_event_count > 0,
			"counter_count": counters.size(),
			"gauge_count": gauges.size(),
			"warning_count": warnings.size(),
			"observatory_enabled": enabled,
		},
		"performance": _json_safe(get_performance_summary()),
		"performance_incident": _json_safe(get_performance_incident_report()),
		"scene": {
			"name": scene_name,
			"path": scene_path,
		},
		"counters": _json_safe(counters),
		"gauges": _json_safe(gauges),
		"heatmap": _json_safe(_get_heatmap_snapshot()),
		"material_intelligence": _json_safe(
			_get_material_intelligence_snapshot()
		),
		"procgen_runtime_health": _json_safe(_get_procgen_runtime_health_snapshot()),
		"warnings": _json_safe(warnings),
		"events": _json_safe(events),
	}


func _get_heatmap_snapshot() -> Dictionary:
	var heatmap := get_node_or_null("/root/SectorHeatmap")
	if heatmap != null and heatmap.has_method("export_snapshot"):
		var snapshot: Variant = heatmap.call("export_snapshot")
		if snapshot is Dictionary:
			return snapshot as Dictionary
	return {}


func _get_material_intelligence_snapshot() -> Dictionary:
	var material_intelligence := get_node_or_null(
		"/root/MaterialIntelligence"
	)
	if material_intelligence != null \
	and material_intelligence.has_method("get_summary"):
		var summary: Variant = material_intelligence.call("get_summary")
		if summary is Dictionary:
			return summary as Dictionary
	return {}


func _json_safe(value: Variant) -> Variant:
	match typeof(value):
		TYPE_NIL:
			return null
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_STRING_NAME, TYPE_NODE_PATH:
			return String(value)
		TYPE_VECTOR2:
			var v := value as Vector2
			return {"x": v.x, "y": v.y}
		TYPE_VECTOR2I:
			var v := value as Vector2i
			return {"x": v.x, "y": v.y}
		TYPE_VECTOR3:
			var v := value as Vector3
			return {"x": v.x, "y": v.y, "z": v.z}
		TYPE_VECTOR3I:
			var v := value as Vector3i
			return {"x": v.x, "y": v.y, "z": v.z}
		TYPE_RECT2:
			var r := value as Rect2
			return {
				"position": _json_safe(r.position),
				"size": _json_safe(r.size),
			}
		TYPE_RECT2I:
			var r := value as Rect2i
			return {
				"position": _json_safe(r.position),
				"size": _json_safe(r.size),
			}
		TYPE_COLOR:
			var c := value as Color
			return {
				"r": c.r,
				"g": c.g,
				"b": c.b,
				"a": c.a,
				"html": c.to_html(true),
			}
		TYPE_ARRAY:
			var out: Array = []
			for item in value:
				out.append(_json_safe(item))
			return out
		TYPE_DICTIONARY:
			var out := {}
			var dict := value as Dictionary
			for key in dict.keys():
				out[str(key)] = _json_safe(dict[key])
			return out
		TYPE_OBJECT:
			var object := value as Object
			if object == null:
				return null
			if object is Node:
				var node := object as Node
				return {
					"node_name": node.name,
					"node_path": str(node.get_path()) if node.is_inside_tree() else "",
					"class": node.get_class(),
				}
			return str(value)
		_:
			return str(value)


func _ensure_parent_dir(path: String) -> bool:
	var base_dir := path.get_base_dir()
	if base_dir.is_empty():
		return true

	var absolute_dir := ProjectSettings.globalize_path(base_dir)
	var result := DirAccess.make_dir_recursive_absolute(absolute_dir)
	return result == OK or DirAccess.dir_exists_absolute(absolute_dir)


func _sample_runtime_gauges(
	include_tree_scan := false,
	include_runtime_details := true
) -> void:
	set_gauge(&"fps", Engine.get_frames_per_second())
	set_gauge(&"uptime_sec", snappedf(get_uptime_sec(), 0.01))
	_publish_performance_gauges()
	set_gauge(
		&"performance_draw_calls",
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	)
	set_gauge(
		&"performance_rendered_objects",
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	)
	_sample_render_state_gauges()
	if not include_runtime_details:
		return

	var tree := get_tree()
	if tree == null:
		return

	var heatmap := tree.root.get_node_or_null("/root/SectorHeatmap")
	if heatmap != null and heatmap.has_method("get_summary"):
		var heatmap_summary: Variant = heatmap.call("get_summary")
		if heatmap_summary is Dictionary:
			var summary := heatmap_summary as Dictionary
			set_gauge(
				&"heatmap_cells",
				int(summary.get("cell_count", 0))
			)
			set_gauge(
				&"heatmap_samples",
				int(summary.get("total_samples", 0))
			)

	if include_tree_scan:
		var scan_started := Time.get_ticks_usec()
		var node_stats := _collect_node_stats(tree.root)
		var scan_usec := Time.get_ticks_usec() - scan_started
		_runtime_tree_scan_count += 1
		set_gauge(&"observatory_scan_usec", scan_usec)
		set_gauge(
			&"observatory_full_tree_scan_count",
			_runtime_tree_scan_count
		)
		for stat_name in node_stats.keys():
			set_gauge(StringName(str(stat_name)), node_stats[stat_name])
		for peak_name in [
			"node_count",
			"physics_body_count",
			"collision_shape_count",
		]:
			var gauge_name := StringName("%s_peak" % peak_name)
			set_gauge(
				gauge_name,
				maxi(
					int(gauges.get(gauge_name, 0)),
					int(node_stats.get(peak_name, 0))
				)
			)

	var enemies := _get_unique_group_nodes(["enemy", "enemies"])
	set_gauge(&"active_enemies", enemies.size())
	var director_agents := tree.get_nodes_in_group("enemy_behavior_agent").size()
	set_gauge(&"director_behavior_agents", director_agents)
	set_gauge(&"legacy_combat_agents", maxi(0, enemies.size() - director_agents))
	set_gauge(&"ambient_critters", tree.get_nodes_in_group("ambient_critter").size())
	set_gauge(&"active_projectiles", _count_active_projectiles(tree))
	set_gauge(&"active_vfx", tree.get_nodes_in_group("vfx").size())
	set_gauge(&"active_combat_audio", tree.get_nodes_in_group("combat_audio").size())
	_sample_player_gauges(tree)
	_sample_enemy_gauges(enemies)


func _sample_render_state_gauges() -> void:
	var atmosphere_enabled := false
	var procgen_major_visuals_enabled := false
	var procgen_floor_enabled := false
	var procgen_walls_enabled := false
	var procgen_depth_backdrop_enabled := false
	var procgen_runtime_wall_collision_enabled := false
	var procgen_wall_shadows_enabled := false
	var procgen_map_count := 0

	var atmospheres := get_tree().get_nodes_in_group(
		"render_world_atmosphere"
	)
	for atmosphere in atmospheres:
		if atmosphere == null or not is_instance_valid(atmosphere):
			continue

		if atmosphere.has_method("is_render_enabled"):
			atmosphere_enabled = bool(
				atmosphere.call("is_render_enabled")
			)
		elif "visible" in atmosphere:
			atmosphere_enabled = bool(atmosphere.visible)

		if atmosphere_enabled:
			break

	for procgen_map in get_tree().get_nodes_in_group(
		"procgen_render_isolation"
	):
		if procgen_map == null \
				or not is_instance_valid(procgen_map) \
				or not procgen_map.has_method(
					"get_procgen_render_isolation_status"
				):
			continue
		procgen_map_count += 1
		var status := procgen_map.call(
			"get_procgen_render_isolation_status"
		) as Dictionary
		procgen_major_visuals_enabled = procgen_major_visuals_enabled \
			or bool(status.get("major_visuals_enabled", false))
		procgen_floor_enabled = procgen_floor_enabled \
			or bool(status.get("floor_enabled", false))
		procgen_walls_enabled = procgen_walls_enabled \
			or bool(status.get("walls_enabled", false))
		procgen_depth_backdrop_enabled = procgen_depth_backdrop_enabled \
			or bool(status.get("depth_backdrop_enabled", false))
		procgen_runtime_wall_collision_enabled = procgen_runtime_wall_collision_enabled \
			or bool(status.get("runtime_wall_collision_enabled", false))
		procgen_wall_shadows_enabled = procgen_wall_shadows_enabled \
			or bool(status.get("wall_shadows_enabled", false))

	var directional_enabled := (
		_count_enabled_render_lights(
			"render_directional_light"
		) > 0
	)

	var point_light_count := _count_enabled_render_lights(
		"render_point_light"
	)

	set_gauge(
		&"render_atmosphere_enabled",
		atmosphere_enabled
	)
	set_gauge(
		&"render_procgen_major_visuals_enabled",
		procgen_major_visuals_enabled
	)
	set_gauge(
		&"render_procgen_floor_enabled",
		procgen_floor_enabled
	)
	set_gauge(
		&"render_procgen_walls_enabled",
		procgen_walls_enabled
	)
	set_gauge(
		&"render_procgen_depth_backdrop_enabled",
		procgen_depth_backdrop_enabled
	)
	set_gauge(&"procgen_runtime_wall_collision_isolation_enabled", procgen_runtime_wall_collision_enabled)
	set_gauge(&"procgen_wall_shadow_isolation_enabled", procgen_wall_shadows_enabled)
	set_gauge(
		&"render_directional_light_enabled",
		directional_enabled
	)
	set_gauge(
		&"render_point_light_count",
		point_light_count
	)

	var isolation_mode := "production"

	if procgen_map_count > 0 and not procgen_major_visuals_enabled:
		isolation_mode = "procgen_major_visuals_off"
	elif not atmosphere_enabled and directional_enabled:
		isolation_mode = "atmosphere_off"
	elif not directional_enabled:
		isolation_mode = "lighting_reduced"

	set_gauge(
		&"render_isolation_mode",
		isolation_mode
	)
	var procgen_health := _get_procgen_runtime_health_snapshot()
	for key in procgen_health.keys():
		if key == "map_size":
			continue
		var gauge_name := StringName("procgen_%s" % key) if not str(key).begins_with("procgen_") else StringName(key)
		set_gauge(gauge_name, procgen_health[key])


func _get_procgen_runtime_health_snapshot() -> Dictionary:
	var maps := get_tree().get_nodes_in_group("procgen_tilemap") if get_tree() != null else []
	for map_node in maps:
		if map_node != null and is_instance_valid(map_node) and map_node.has_method("get_runtime_health_snapshot"):
			var snapshot := (map_node.call("get_runtime_health_snapshot") as Dictionary).duplicate(true)
			snapshot["snapshot_active"] = true
			snapshot["snapshot_source"] = str(map_node.get_path())
			snapshot["snapshot_captured_uptime_sec"] = get_uptime_sec()
			_last_procgen_runtime_health = snapshot.duplicate(true)
			return snapshot
	if _last_procgen_runtime_health.is_empty():
		return {
			"snapshot_active": false,
			"snapshot_source": "none_loaded",
			"snapshot_captured_uptime_sec": get_uptime_sec(),
		}
	var last_known := _last_procgen_runtime_health.duplicate(true)
	last_known["snapshot_active"] = false
	last_known["snapshot_source"] = "unloaded_generation_%s" % str(last_known.get("generation_id", "unknown"))
	return last_known


func _count_enabled_render_lights(
	group_name: StringName
) -> int:
	var count := 0

	for node in get_tree().get_nodes_in_group(group_name):
		var light := node as Light2D
		if light == null:
			continue
		if not light.enabled:
			continue
		if not light.is_visible_in_tree():
			continue

		count += 1

	return count


func _publish_performance_gauges() -> void:
	var summary := get_performance_summary()
	set_gauge(&"performance_frame_ms_current", float(summary["frame_ms_current"]))
	set_gauge(&"performance_frame_ms_average", float(summary["frame_ms_average"]))
	set_gauge(&"performance_frame_ms_p95", float(summary["frame_ms_p95"]))
	set_gauge(&"performance_frame_ms_p99", float(summary["frame_ms_p99"]))
	set_gauge(&"performance_frame_ms_worst", float(summary["frame_ms_worst"]))
	set_gauge(&"performance_hitch_count", int(summary["hitch_count"]))
	set_gauge(&"performance_severe_hitch_count", int(summary["severe_hitch_count"]))
	set_gauge(&"performance_frame_sample_count", int(summary["sample_count"]))
	set_gauge(&"performance_process_ms", float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
	set_gauge(&"performance_physics_ms", float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
	set_gauge(&"performance_incident_state", String(_performance_incident_state))
	set_gauge(&"performance_incident_auto_trigger_count", _performance_auto_trigger_count)
	set_gauge(&"performance_incident_manual_trigger_count", _performance_manual_trigger_count)
	set_gauge(&"performance_incident_external_stall_count", _performance_external_stalls.size())
	set_gauge(&"performance_incident_rearm_progress_sec", _performance_rearm_progress_sec)


func _sample_player_gauges(tree: SceneTree) -> void:
	var player := tree.get_first_node_in_group("player")
	if player == null:
		return
	var player_alive := true
	if player.has_method("is_alive"):
		player_alive = bool(player.call("is_alive"))
	elif "_is_dead" in player:
		player_alive = not bool(player.get("_is_dead"))
	set_gauge(&"player_alive", player_alive)
	set_gauge(&"player_dead", not player_alive)

	if player is Node2D:
		var p := player as Node2D
		set_gauge(&"player_position", Vector2i(roundi(p.global_position.x), roundi(p.global_position.y)))
		var material_intelligence := tree.root.get_node_or_null(
			"/root/MaterialIntelligence"
		)
		if material_intelligence != null \
		and material_intelligence.has_method("get_material_id_at"):
			var material_id: Variant = material_intelligence.call(
				"get_material_id_at",
				p.global_position
			)
			set_gauge(&"player_material", String(material_id))
			if material_intelligence.has_method("get_material_at"):
				var profile: Variant = material_intelligence.call(
					"get_material_at",
					p.global_position
				)
				if profile != null \
				and "footstep_noise_mult" in profile:
					set_gauge(
						&"player_material_footstep_noise_mult",
						float(profile.get("footstep_noise_mult"))
					)

	if player.has_method("get_health"):
		set_gauge(&"player_health", float(player.call("get_health")))
	elif "current_health" in player:
		set_gauge(&"player_health", float(player.get("current_health")))

	if player.has_method("get_max_health"):
		set_gauge(&"player_max_health", float(player.call("get_max_health")))
	elif "max_health" in player:
		set_gauge(&"player_max_health", float(player.get("max_health")))

	if player.has_method("get_sprint_status"):
		var sprint_status: Variant = player.call("get_sprint_status")
		if sprint_status is Dictionary:
			var status := sprint_status as Dictionary
			set_gauge(&"player_stamina", float(status.get("stamina", 0.0)))
			set_gauge(&"player_stamina_max", float(status.get("stamina_max", 0.0)))
			set_gauge(&"player_sprinting", bool(status.get("is_sprinting", false)))
			if player_alive:
				set_gauge(&"player_last_live_stamina", float(status.get("stamina", 0.0)))

	if player.has_method("get_field_patch_status"):
		var patch_status: Variant = player.call("get_field_patch_status")
		if patch_status is Dictionary:
			var status := patch_status as Dictionary
			set_gauge(&"field_patches_remaining", int(status.get("count", 0)))
			set_gauge(&"field_patches_max", int(status.get("max", 0)))
			set_gauge(&"field_patch_active", bool(status.get("active", false)))

	if player.has_method("get_weapon_status"):
		var weapon_status: Variant = player.call("get_weapon_status")
		if weapon_status is Dictionary:
			var status := weapon_status as Dictionary
			set_gauge(&"player_loaded_ammo", int(status.get("loaded_ammo", 0)))
			set_gauge(&"player_reserve_ammo", int(status.get("reserve_ammo", 0)))
			set_gauge(&"player_active_weapon_id", String(status.get("active_weapon_id", "")))
			set_gauge(&"player_active_weapon_state_key", String(status.get("active_weapon_state_key", "")))
			set_gauge(&"player_magazine_capacity", int(status.get("magazine_size", 0)))
			set_gauge(&"player_ammo_per_shot", int(status.get("ammo_per_shot", 0)))
			set_gauge(&"player_weapon_heat", float(status.get("heat", 0.0)))
			set_gauge(&"player_weapon_overheated", bool(status.get("overheated", false)))
			if player_alive:
				set_gauge(&"player_last_live_weapon_id", String(status.get("active_weapon_id", "")))
				set_gauge(&"player_last_live_loaded_ammo", int(status.get("loaded_ammo", 0)))
				set_gauge(&"player_last_live_reserve_ammo", int(status.get("reserve_ammo", 0)))


func _sample_enemy_gauges(enemies: Array) -> void:
	var living := 0
	var corpses := 0
	var legacy_sample: Dictionary = {}
	var behavior_sample: Dictionary = {}
	var tier_counts := {"active": 0, "nearby": 0, "background": 0, "dormant": 0}
	var physics_enabled_by_tier := {"active": 0, "nearby": 0, "background": 0, "dormant": 0}
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if "dead" in enemy and bool(enemy.get("dead")):
			corpses += 1
		else:
			living += 1
		if enemy.has_method("get_runtime_cost_state"):
			var cost_state: Dictionary = enemy.call("get_runtime_cost_state")
			var tier := String(cost_state.get("simulation_tier", "active"))
			if tier_counts.has(tier):
				tier_counts[tier] += 1
				physics_enabled_by_tier[tier] += int(bool(cost_state.get("physics_process_enabled", false)))
		if behavior_sample.is_empty() and enemy.is_in_group("enemy_behavior_agent") and enemy.has_method("get_behavior_snapshot"):
			var snapshot: Variant = enemy.call("get_behavior_snapshot")
			if snapshot is Dictionary:
				behavior_sample = snapshot
		elif legacy_sample.is_empty() and enemy.has_method("get_behavior_snapshot"):
			var snapshot: Variant = enemy.call("get_behavior_snapshot")
			if snapshot is Dictionary:
				legacy_sample = snapshot
	if not legacy_sample.is_empty():
		set_gauge(&"legacy_enemy_sample", legacy_sample)
	if not behavior_sample.is_empty():
		set_gauge(&"enemy_behavior_sample", behavior_sample)
	for tier in tier_counts:
		set_gauge(StringName("enemy_tier_%s" % tier), tier_counts[tier])
		set_gauge(StringName("enemy_tier_%s_physics_enabled" % tier), physics_enabled_by_tier[tier])
	set_gauge(&"living_enemies", living)
	set_gauge(&"corpse_enemies", corpses)


func _get_unique_group_nodes(group_names: Array) -> Array:
	var tree := get_tree()
	if tree == null:
		return []
	var seen := {}
	var out: Array = []
	for group_name in group_names:
		for node in tree.get_nodes_in_group(StringName(str(group_name))):
			if node == null or not is_instance_valid(node):
				continue
			var id := node.get_instance_id()
			if seen.has(id):
				continue
			seen[id] = true
			out.append(node)
	return out


func _count_active_projectiles(tree: SceneTree) -> int:
	var projectiles := tree.get_nodes_in_group("projectiles")
	if projectiles.size() > 0:
		return projectiles.size()
	var projectile_root := get_node_or_null("/root/GameRoot/World/Projectiles")
	if projectile_root == null:
		return 0
	return projectile_root.get_child_count()


func _count_nodes(root_node: Node) -> int:
	var count := 1
	for child in root_node.get_children():
		count += _count_nodes(child)
	return count


func _collect_node_stats(root_node: Node) -> Dictionary:
	var stats := {
		"node_count": 0,
		"node_count_world": 0,
		"node_count_procgen": 0,
		"node_count_props": 0,
		"node_count_collision": 0,
		"node_count_vfx": 0,
		"node_count_ui": 0,
		"physics_body_count": 0,
		"collision_shape_count": 0,
		"collision_shape_count_runtime_walls": 0,
		"collision_shape_count_foliage": 0,
		"collision_shape_count_ruin_props": 0,
		"collision_shape_count_enemies": 0,
		"collision_shape_count_projectiles": 0,
		"physics_body_count_runtime_walls": 0,
		"physics_body_count_foliage": 0,
		"physics_body_count_ruin_props": 0,
		"process_enabled_node_count": 0,
		"physics_process_enabled_node_count": 0,
		"loaded_world_branch_count": 0,
		"loaded_procgen_root_count": 0,
		"procgen_reveal_queue": 0,
		"node_class_histogram": {},
		"top_level_subtree_counts": {},
	}
	var stack: Array[Dictionary] = [{
		"node": root_node,
		"top_branch": String(root_node.name),
	}]
	while not stack.is_empty():
		var entry := stack.pop_back() as Dictionary
		var node := entry["node"] as Node
		var top_branch := String(entry["top_branch"])
		stats["node_count"] += 1
		var class_histogram := stats["node_class_histogram"] as Dictionary
		var node_class_name := node.get_class()
		class_histogram[node_class_name] = int(
			class_histogram.get(node_class_name, 0)
		) + 1
		var subtree_counts := stats["top_level_subtree_counts"] as Dictionary
		subtree_counts[top_branch] = int(
			subtree_counts.get(top_branch, 0)
		) + 1
		var node_name := StringName(node.name)
		if node_name == &"ProcGenRuntime" or node_name == &"ConnectedMaps":
			stats["loaded_world_branch_count"] += 1
		if node_name == &"ProcGenRuntime":
			stats["loaded_procgen_root_count"] += 1
		if "_streaming_reveal_queue" in node:
			var reveal_queue: Variant = node.get("_streaming_reveal_queue")
			if reveal_queue is Array:
				stats["procgen_reveal_queue"] += reveal_queue.size()
		var path := str(node.get_path()).to_lower()
		if path.begins_with("/root/gameroot/world"):
			stats["node_count_world"] += 1
		if "procgen" in path or node.is_in_group("procgen_walkability_provider"):
			stats["node_count_procgen"] += 1
		if "prop" in path or node.is_in_group("runtime_prop"):
			stats["node_count_props"] += 1
		if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D:
			stats["node_count_collision"] += 1
		if node is CollisionShape2D or node is CollisionPolygon2D:
			stats["collision_shape_count"] += 1
			var shape_category := _get_collision_owner_category(node)
			if shape_category == &"runtime_walls":
				stats["collision_shape_count_runtime_walls"] += 1
			elif shape_category == &"foliage":
				stats["collision_shape_count_foliage"] += 1
			elif shape_category == &"ruin_props":
				stats["collision_shape_count_ruin_props"] += 1
			elif shape_category == &"enemies":
				stats["collision_shape_count_enemies"] += 1
			elif shape_category == &"projectiles":
				stats["collision_shape_count_projectiles"] += 1
		if node is PhysicsBody2D:
			stats["physics_body_count"] += 1
			var body_category := _get_collision_owner_category(node)
			if body_category == &"runtime_walls":
				stats["physics_body_count_runtime_walls"] += 1
			elif body_category == &"foliage":
				stats["physics_body_count_foliage"] += 1
			elif body_category == &"ruin_props":
				stats["physics_body_count_ruin_props"] += 1
		if node is Control or node is CanvasLayer:
			stats["node_count_ui"] += 1
		if "vfx" in path or "effect" in path or node.is_in_group("vfx"):
			stats["node_count_vfx"] += 1
		if node.is_processing():
			stats["process_enabled_node_count"] += 1
		if node.is_physics_processing():
			stats["physics_process_enabled_node_count"] += 1
		for child in node.get_children():
			if child is Node:
				stack.append({
					"node": child,
					"top_branch": (
						String(child.name)
						if node == root_node else top_branch
					),
				})
	return stats


func _get_collision_owner_category(node: Node) -> StringName:
	var cursor := node
	while cursor != null:
		if cursor.is_in_group("enemies") or cursor.is_in_group("enemy"):
			return &"enemies"
		if cursor.is_in_group("projectiles"):
			return &"projectiles"
		if cursor.is_in_group("runtime_prop") or cursor is ProceduralProp:
			return &"ruin_props"
		var name_lower := String(cursor.name).to_lower()
		if "foliage" in name_lower or "tree" in name_lower or "shrub" in name_lower:
			return &"foliage"
		if name_lower == "walls" or "runtimewall" in name_lower or "runtime_wall" in name_lower:
			return &"runtime_walls"
		cursor = cursor.get_parent()
	return &""


func _ensure_input_actions() -> void:
	_ensure_action_key(INPUT_ACTION, KEY_F9)
	_ensure_action_key(EXPORT_INPUT_ACTION, KEY_F10)
	_ensure_action_key(PERFORMANCE_CAPTURE_INPUT_ACTION, KEY_F11)
	_ensure_action_key_with_shift(PERFORMANCE_PHASE_INPUT_ACTION, KEY_F11)


func _ensure_action_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

	if _action_has_key(action, keycode):
		return

	var key := InputEventKey.new()
	key.keycode = keycode
	key.key_label = keycode
	InputMap.action_add_event(action, key)


func _ensure_action_key_with_shift(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event != null and key_event.keycode == keycode and key_event.shift_pressed:
			return
	var key := InputEventKey.new()
	key.keycode = keycode
	key.key_label = keycode
	key.shift_pressed = true
	InputMap.action_add_event(action, key)


func _action_has_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event == null:
			continue
		if key_event.keycode == keycode or key_event.physical_keycode == keycode or key_event.key_label == keycode:
			return true
	return false


func _create_overlay() -> void:
	if _overlay != null:
		return

	var existing := _find_existing_overlay()
	if existing != null:
		_overlay = existing
		_overlay.visible = enabled
		return

	if !ResourceLoader.exists(OVERLAY_SCENE_PATH):
		push_warning("Developer Observatory overlay scene missing: %s" % OVERLAY_SCENE_PATH)
		return

	var scene := load(OVERLAY_SCENE_PATH)
	if scene == null or not scene is PackedScene:
		push_warning("Developer Observatory failed to load overlay scene: %s" % OVERLAY_SCENE_PATH)
		return

	var packed := scene as PackedScene
	var instance := packed.instantiate()
	if !(instance is CanvasLayer):
		push_warning("Developer Observatory overlay scene root must be CanvasLayer.")
		instance.queue_free()
		return

	_overlay = instance
	get_tree().root.call_deferred("add_child", _overlay)
	_overlay.visible = enabled


func _find_existing_overlay() -> CanvasLayer:
	var tree := get_tree()
	if tree == null:
		return null
	var stack: Array[Node] = [tree.root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node != self and node.name == "DevObservatoryOverlay" and node is CanvasLayer:
			return node as CanvasLayer
		for child in node.get_children():
			stack.append(child)
	return null
