extends CanvasLayer

@onready var _label: RichTextLabel = $Panel/MarginContainer/ObservatoryLabel

@export var refresh_interval := 0.25
@export var recent_event_limit := 10

const PAGES := [&"Overview", &"Performance", &"Warnings", &"Events", &"World/Procgen"]

var _accum := 0.0
var _page_index := 0
var _last_text := ""
var _refresh_count := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	visible = false


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	if key_event.keycode != KEY_TAB and key_event.physical_keycode != KEY_TAB:
		return
	var direction := -1 if key_event.shift_pressed else 1
	_set_page((_page_index + direction + PAGES.size()) % PAGES.size())
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return
	_accum += delta
	var current_refresh_interval := (
		maxf(0.5, refresh_interval)
		if _page_index == 1 else maxf(0.25, refresh_interval)
	)
	if _accum < current_refresh_interval:
		return

	_accum = 0.0
	_refresh()


func _refresh() -> void:
	if !visible:
		return

	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory == null:
		return

	var build_started := Time.get_ticks_usec()
	var lines: PackedStringArray = []
	lines.append("[b]CUSTODIAN // DEVELOPER OBSERVATORY[/b]")
	lines.append("[color=gray]F9 close // Tab / Shift+Tab pages // F10 export[/color]")
	lines.append("[color=#8fb8c8]%s[/color]" % _page_header())
	if not observatory.last_export_error.is_empty():
		lines.append("[color=red]export failed: %s[/color]" % observatory.last_export_error)
	elif not observatory.last_export_absolute_path.is_empty():
		lines.append("[color=green]last export: %s[/color]" % observatory.last_export_absolute_path)
	lines.append("")

	match _page_index:
		0:
			_append_overview(lines, observatory)
		1:
			_append_performance(lines, observatory)
		2:
			_append_warnings(lines, observatory)
		3:
			_append_events(lines, observatory)
		4:
			_append_world(lines, observatory)

	var next_text := "\n".join(lines)
	if next_text != _last_text:
		_label.text = next_text
		_last_text = next_text
	_refresh_count += 1
	observatory.set_gauge(&"observatory_overlay_build_usec", Time.get_ticks_usec() - build_started)
	observatory.set_gauge(&"observatory_overlay_text_chars", next_text.length())
	observatory.set_gauge(&"observatory_overlay_line_count", lines.size())
	observatory.set_gauge(&"observatory_overlay_refresh_count", _refresh_count)


func _set_page(index: int) -> void:
	_page_index = clampi(index, 0, PAGES.size() - 1)
	_refresh()


func _page_header() -> String:
	var labels: PackedStringArray = []
	for index in range(PAGES.size()):
		labels.append("[%s]" % PAGES[index] if index == _page_index else String(PAGES[index]))
	return "  ".join(labels)


func _append_overview(lines: PackedStringArray, observatory: Node) -> void:
	lines.append("[b]Runtime[/b]")
	lines.append("  uptime: %.2fs   FPS: %s" % [observatory.get_uptime_sec(), _gauge(observatory, &"fps")])
	lines.append("  events: %s / %s   warnings: %s" % [observatory.events.size(), observatory.max_events, observatory.warnings.size()])
	for key in [&"node_count", &"active_enemies", &"active_projectiles", &"loaded_procgen_root_count"]:
		lines.append("  %s: %s" % [key, _gauge(observatory, key)])
	lines.append("")
	lines.append("[b]Counters[/b]")
	var counter_keys: Array = observatory.counters.keys()
	counter_keys.sort()
	for key in counter_keys.slice(0, 24):
		lines.append("  %s: %s" % [key, _bounded_value(observatory.counters[key])])
	if counter_keys.size() > 24:
		lines.append("  [color=gray]%d more counters in F10 export[/color]" % (counter_keys.size() - 24))
	if counter_keys.is_empty():
		lines.append("  [color=gray]none[/color]")


func _append_performance(lines: PackedStringArray, observatory: Node) -> void:
	var incident: Dictionary = observatory.get_performance_incident_report() if observatory.has_method("get_performance_incident_report") else {}
	lines.append("[b]PERFORMANCE INCIDENT[/b]")
	var incident_elapsed := maxf(0.0, float(incident.get("ended_uptime_sec", 0.0)) - float(incident.get("started_uptime_sec", 0.0)))
	lines.append("  state: %s   phase: %s   elapsed: %.2fs" % [incident.get("state", "ARMED"), observatory.performance_incident_phase, incident_elapsed])
	lines.append("  likely owner: %s" % (incident.get("likely_owner", {}) as Dictionary).get("classification", "unclassified"))
	lines.append("[b]Frame-time diagnostics (wall clock)[/b]")
	lines.append("  FPS: %s" % _gauge(observatory, &"fps"))
	for item in [
		["current frame", &"performance_frame_ms_current", "ms"],
		["rolling average", &"performance_frame_ms_average", "ms"],
		["P95", &"performance_frame_ms_p95", "ms"],
		["P99", &"performance_frame_ms_p99", "ms"],
		["worst", &"performance_frame_ms_worst", "ms"],
		["hitches >=33.3", &"performance_hitch_count", ""],
		["severe >=50", &"performance_severe_hitch_count", ""],
	]:
		lines.append("  %s: %s%s" % [item[0], _gauge(observatory, item[1]), item[2]])
	lines.append("")
	lines.append("[b]Engine / population[/b]")
	for item in [["process", &"performance_process_ms"], ["physics", &"performance_physics_ms"], ["living", &"living_enemies"], ["corpses", &"corpse_enemies"], ["VFX", &"active_vfx"], ["audio", &"active_combat_audio"]]:
		lines.append("  %s: %s" % [item[0], _gauge(observatory, item[1])])
	var top_spans: Array = incident.get("top_spans", [])
	if not top_spans.is_empty():
		lines.append("[b]Top spans[/b]")
		for span in top_spans:
			lines.append("  %s: %.2f ms" % [span.get("name", ""), float(span.get("total_ms", 0.0))])
	lines.append("")
	lines.append("[b]Renderer / world load[/b]")
	for item in [
		["draw calls", &"performance_draw_calls"], ["rendered objects", &"performance_rendered_objects"],
		["nodes", &"node_count"], ["physics bodies", &"physics_body_count"],
		["collision shapes", &"collision_shape_count"], ["active enemies", &"active_enemies"],
		["active projectiles", &"active_projectiles"], ["procgen reveal queue", &"procgen_reveal_queue"],
		["world roots", &"loaded_world_branch_count"], ["procgen roots", &"loaded_procgen_root_count"],
	]:
		lines.append("  %s: %s" % [item[0], _gauge(observatory, item[1])])
	lines.append(
		"  last explicit tree scan: %sus"
		% _gauge(observatory, &"observatory_scan_usec")
	)


func _append_warnings(lines: PackedStringArray, observatory: Node) -> void:
	lines.append("[b]Warnings[/b]")
	var recent: Array = observatory.get_recent_warnings(10)
	if recent.is_empty():
		lines.append("  [color=gray]none[/color]")
	for entry in recent:
		lines.append("  [%07.2fs] %s %s" % [entry.get("uptime_sec", 0.0), entry.get("message", ""), _format_data(entry.get("data", {}))])


func _append_events(lines: PackedStringArray, observatory: Node) -> void:
	lines.append("[b]Recent Events[/b]")
	var recent: Array = observatory.get_recent_events(recent_event_limit)
	if recent.is_empty():
		lines.append("  [color=gray]none[/color]")
	for entry in recent:
		lines.append("  [%07.2fs] %s %s" % [entry.get("uptime_sec", 0.0), entry.get("kind", ""), _format_data(entry.get("data", {}))])


func _append_world(lines: PackedStringArray, observatory: Node) -> void:
	lines.append("[b]World / Procgen[/b]")
	for key in [&"loaded_world_branch_count", &"loaded_procgen_root_count", &"procgen_reveal_queue", &"node_count_world", &"node_count_procgen", &"node_count_props"]:
		lines.append("  %s: %s" % [key, _gauge(observatory, key)])
	var heatmap := get_node_or_null("/root/SectorHeatmap")
	if heatmap == null:
		return
	lines.append("")
	lines.append("[b]Heatmap — %s[/b]" % String(heatmap.call("get_active_channel")))
	for entry in heatmap.call("get_top_hot_cells", String(heatmap.call("get_active_channel")), 8):
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		lines.append("  (%d,%d): %.2f" % [cell.x, cell.y, float(entry.get("value", 0.0))])


func _gauge(observatory: Node, key: StringName) -> String:
	var value: Variant = observatory.gauges.get(key, 0)
	if value is float:
		return "%.2f" % value
	return str(value)


func _format_data(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return str(data)

	var dict := data as Dictionary
	if dict.is_empty():
		return ""

	var chunks: PackedStringArray = []
	var keys: Array = dict.keys()
	keys.sort()

	for key in keys:
		chunks.append("%s=%s" % [str(key), _bounded_value(dict[key])])

	return "{%s}" % ", ".join(chunks)


func _bounded_value(value: Variant) -> String:
	if value is Dictionary or value is Array:
		return "<%s items; see F10 export>" % value.size()
	var text := str(value)
	return text.left(117) + "..." if text.length() > 120 else text
