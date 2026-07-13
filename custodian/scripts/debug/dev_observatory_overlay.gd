extends CanvasLayer

@onready var _label: RichTextLabel = $Panel/MarginContainer/ObservatoryLabel

@export var refresh_interval := 0.10
@export var recent_event_limit := 14

var _accum := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


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
	lines.append("[color=gray]F9 toggles this overlay[/color]")
	lines.append("")

	lines.append("[b]Runtime[/b]")
	lines.append("  enabled: %s" % str(observatory.enabled))
	lines.append("  uptime: %.2fs" % observatory.get_uptime_sec())
	lines.append("  events: %s / %s" % [str(observatory.events.size()), str(observatory.max_events)])
	lines.append("")

	lines.append("[b]Gauges[/b]")
	if observatory.gauges.is_empty():
		lines.append("  [color=gray]none[/color]")
	else:
		var gauge_keys: Array = observatory.gauges.keys()
		gauge_keys.sort()
		for key in gauge_keys:
			lines.append("  %s: %s" % [str(key), str(observatory.gauges[key])])

	lines.append("")
	lines.append("[b]Counters[/b]")
	if observatory.counters.is_empty():
		lines.append("  [color=gray]none[/color]")
	else:
		var counter_keys: Array = observatory.counters.keys()
		counter_keys.sort()
		for key in counter_keys:
			lines.append("  %s: %s" % [str(key), str(observatory.counters[key])])

	lines.append("")
	lines.append("[b]Recent Events[/b]")
	var recent_events: Array = observatory.get_recent_events(recent_event_limit)
	if recent_events.is_empty():
		lines.append("  [color=gray]none[/color]")
	else:
		for event_entry in recent_events:
			lines.append("  [%07.2fs] %s %s" % [
				float(event_entry.get("uptime_sec", 0.0)),
				str(event_entry.get("kind", "")),
				_format_data(event_entry.get("data", {}))
			])

	if observatory.warnings.size() > 0:
		lines.append("")
		lines.append("[b]Warnings[/b]")
		var recent_warnings: Array = observatory.get_recent_warnings(5)
		for warning_entry in recent_warnings:
			lines.append("  [%07.2fs] %s" % [
				float(warning_entry.get("uptime_sec", 0.0)),
				str(warning_entry.get("message", ""))
			])

	# Heatmap integration
	var heatmap := get_node_or_null("/root/SectorHeatmap")
	if heatmap != null:
		lines.append("")
		lines.append("[b]HEATMAP[/b]")
		lines.append("  channel: %s" % String(heatmap.call("get_active_channel")))

		var hot_cells: Array = heatmap.call("get_top_hot_cells", String(heatmap.call("get_active_channel")), 4)
		for entry in hot_cells:
			var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
			var value: float = float(entry.get("value", 0.0))
			lines.append("  (%d,%d): %.2f" % [cell.x, cell.y, value])

	_label.text = "\n".join(lines)


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
