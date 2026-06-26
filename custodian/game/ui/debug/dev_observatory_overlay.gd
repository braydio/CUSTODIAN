extends CanvasLayer

@onready var _label: RichTextLabel = $Panel/MarginContainer/Label


func _process(_delta: float) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	visible = observatory != null and bool(observatory.get("enabled"))
	if not visible or _label == null or observatory == null:
		return

	var lines: PackedStringArray = []
	lines.append("[b]CUSTODIAN OBSERVATORY[/b]")
	lines.append("")
	lines.append("FPS: %d" % Engine.get_frames_per_second())

	var heatmap := get_node_or_null("/root/SectorHeatmap")
	if heatmap != null:
		lines.append("HEATMAP CHANNEL: %s" % String(heatmap.call("get_active_channel")))

	lines.append("")
	lines.append("[b]COUNTERS[/b]")
	for key in observatory.counters.keys():
		lines.append("%s: %s" % [String(key), str(observatory.counters[key])])

	lines.append("")
	lines.append("[b]GAUGES[/b]")
	for key in observatory.gauges.keys():
		lines.append("%s: %s" % [String(key), str(observatory.gauges[key])])

	if heatmap != null:
		lines.append("")
		lines.append("[b]HOT CELLS[/b]")
		for entry in heatmap.call("get_top_hot_cells", String(heatmap.call("get_active_channel")), 6):
			var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
			var value: float = float(entry.get("value", 0.0))
			lines.append("(%d,%d): %.2f" % [cell.x, cell.y, value])

		var death_cells: Array = heatmap.call("get_top_hot_cells", "player_death", 3)
		if not death_cells.is_empty():
			lines.append("")
			lines.append("[b]DEATH HOTSPOTS[/b]")
			for entry in death_cells:
				var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
				var value: float = float(entry.get("value", 0.0))
				lines.append("(%d,%d): %.2f" % [cell.x, cell.y, value])

	lines.append("")
	lines.append("[b]RECENT EVENTS[/b]")
	for entry in observatory.call("get_recent_events", "", 12):
		lines.append("%s | %s | %s" % [
			str(entry.get("time", 0)),
			String(entry.get("kind", "")),
			JSON.stringify(entry.get("data", {})),
		])

	_label.text = "\n".join(lines)

