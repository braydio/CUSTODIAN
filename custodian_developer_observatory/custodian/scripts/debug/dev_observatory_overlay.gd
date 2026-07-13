extends CanvasLayer

@onready var _label: Label = %ObservatoryLabel

@export var refresh_interval := 0.10
@export var recent_event_limit := 14

var _accum := 0.0


func _ready() -> void:
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

	var lines: Array[String] = []

	lines.append("CUSTODIAN // DEVELOPER OBSERVATORY")
	lines.append("F9 toggles this overlay")
	lines.append("")

	lines.append("Runtime")
	lines.append("  enabled: %s" % DevObservatory.enabled)
	lines.append("  uptime: %.2fs" % DevObservatory.get_uptime_sec())
	lines.append("  events: %s / %s" % [DevObservatory.events.size(), DevObservatory.max_events])
	lines.append("")

	lines.append("Gauges")
	if DevObservatory.gauges.is_empty():
		lines.append("  none")
	else:
		var gauge_keys := DevObservatory.gauges.keys()
		gauge_keys.sort()
		for key in gauge_keys:
			lines.append("  %s: %s" % [str(key), str(DevObservatory.gauges[key])])

	lines.append("")
	lines.append("Counters")
	if DevObservatory.counters.is_empty():
		lines.append("  none")
	else:
		var counter_keys := DevObservatory.counters.keys()
		counter_keys.sort()
		for key in counter_keys:
			lines.append("  %s: %s" % [str(key), str(DevObservatory.counters[key])])

	lines.append("")
	lines.append("Recent Events")
	var recent_events := DevObservatory.get_recent_events(recent_event_limit)
	if recent_events.is_empty():
		lines.append("  none")
	else:
		for event_entry in recent_events:
			lines.append("  [%07.2fs] %s %s" % [
				float(event_entry.get("uptime_sec", 0.0)),
				str(event_entry.get("kind", "")),
				_format_data(event_entry.get("data", {}))
			])

	_label.text = "\n".join(lines)


func _format_data(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return str(data)

	var dict := data as Dictionary
	if dict.is_empty():
		return ""

	var chunks: Array[String] = []
	var keys := dict.keys()
	keys.sort()

	for key in keys:
		chunks.append("%s=%s" % [str(key), str(dict[key])])

	return "{%s}" % ", ".join(chunks)
