extends CanvasLayer

@onready var _label: RichTextLabel = $Panel/MarginContainer/ObservatoryLabel

@export var refresh_interval := 0.10
@export var recent_event_limit := 14

const PAGES := [&"Overview", &"Performance", &"Warnings", &"Events", &"World/Procgen"]

var _accum := 0.0
var _page_index := 0


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
	_accum += delta
	if _accum < refresh_interval:
		return

	_accum = 0.0
	_refresh()


func _refresh() -> void:
	if !visible:
		return

	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory == null:
		return

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

	_label.text = "\n".join(lines)


func _set_page(index: int) -> void:
	_page_index = clampi(index, 0, PAGES.size() - 1)
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("set_performance_capture_enabled"):
		observatory.call("set_performance_capture_enabled", _page_index == 1)
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
	for key in counter_keys:
		lines.append("  %s: %s" % [key, observatory.counters[key]])
	if counter_keys.is_empty():
		lines.append("  [color=gray]none[/color]")


func _append_performance(lines: PackedStringArray, observatory: Node) -> void:
	lines.append("[b]Frame-time diagnostics[/b]")
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
	lines.append("[b]Renderer / world load[/b]")
	for item in [
		["draw calls", &"performance_draw_calls"], ["rendered objects", &"performance_rendered_objects"],
		["nodes", &"node_count"], ["physics bodies", &"physics_body_count"],
		["collision shapes", &"collision_shape_count"], ["active enemies", &"active_enemies"],
		["active projectiles", &"active_projectiles"], ["procgen reveal queue", &"procgen_reveal_queue"],
		["world roots", &"loaded_world_branch_count"], ["procgen roots", &"loaded_procgen_root_count"],
	]:
		lines.append("  %s: %s" % [item[0], _gauge(observatory, item[1])])


func _append_warnings(lines: PackedStringArray, observatory: Node) -> void:
	lines.append("[b]Warnings[/b]")
	var recent: Array = observatory.get_recent_warnings(30)
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
		chunks.append("%s=%s" % [str(key), str(dict[key])])

	return "{%s}" % ", ".join(chunks)
