extends CanvasLayer

const OVERLAY_MODE_LABELS := {
	0: "OFF",
	1: "RANGES",
	2: "PATHS",
	3: "TARGETING",
	4: "AI STATES",
	5: "ALL",
}

@onready var top_bar: Control = $TopBar
@onready var left_panel: Control = $LeftPanel
@onready var right_panel: Control = $RightPanel
@onready var bottom_panel: Control = $BottomPanel
@onready var header_label: Label = $TopBar/MarginContainer/VBoxContainer/HeaderLabel
@onready var status_label: Label = $TopBar/MarginContainer/VBoxContainer/StatusLabel
@onready var controls_label: Label = $TopBar/MarginContainer/VBoxContainer/ControlsLabel
@onready var stats_label: Label = $LeftPanel/MarginContainer/VBoxContainer/StatsLabel
@onready var inspector_state_label: Label = $RightPanel/MarginContainer/VBoxContainer/InspectorStateLabel
@onready var inspector_label: Label = $RightPanel/MarginContainer/VBoxContainer/InspectorLabel
@onready var log_label: RichTextLabel = $BottomPanel/MarginContainer/VBoxContainer/LogLabel

var _last_stats_version := -1
var _last_events_version := -1
var _last_inspector_version := -1
var _last_minimal := false
var _last_overlay_mode := -1
var _last_enabled := false


func _get_debug_bus() -> Node:
	return get_node_or_null("/root/DebugBus")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if controls_label:
		controls_label.modulate = Color(0.72, 0.82, 0.82, 1.0)
	if header_label:
		header_label.modulate = Color(0.72, 1.0, 0.92, 1.0)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var debug_bus := _get_debug_bus()
	visible = debug_bus != null and debug_bus.enabled
	if not visible:
		_last_enabled = false
		return

	if not _last_enabled or debug_bus.minimal_mode != _last_minimal or debug_bus.overlay_mode != _last_overlay_mode:
		_apply_visibility_state(debug_bus)
		_update_header(debug_bus)
		_last_enabled = true
		_last_minimal = debug_bus.minimal_mode
		_last_overlay_mode = debug_bus.overlay_mode

	if debug_bus.stats_version != _last_stats_version:
		stats_label.text = _format_stats(debug_bus)
		_last_stats_version = debug_bus.stats_version
	if debug_bus.events_version != _last_events_version:
		log_label.text = _format_events(debug_bus)
		_last_events_version = debug_bus.events_version
	if debug_bus.inspector_version != _last_inspector_version:
		inspector_state_label.text = _format_inspector_state(debug_bus)
		inspector_label.text = _format_inspector(debug_bus)
		_last_inspector_version = debug_bus.inspector_version


func _apply_visibility_state(debug_bus: Node) -> void:
	var show_extras: bool = not debug_bus.minimal_mode
	left_panel.visible = true
	right_panel.visible = show_extras
	bottom_panel.visible = show_extras
	top_bar.visible = true


func _update_header(debug_bus: Node) -> void:
	var overlay_label: String = OVERLAY_MODE_LABELS.get(int(debug_bus.overlay_mode), "UNKNOWN")
	var minimal_label := "MINIMAL" if debug_bus.minimal_mode else "FULL"
	var selection_label := "LOCKED" if debug_bus.selected_entity != null else "HOVER"
	status_label.text = "MODE %s  |  OVERLAY %s  |  INSPECT %s" % [minimal_label, overlay_label, selection_label]


func _format_stats(debug_bus: Node) -> String:
	var sections: Array[String] = []
	var categories: Array = debug_bus.stats.keys()
	categories.sort()
	for category in categories:
		var lines: Array[String] = [String(category)]
		var entries: Dictionary = debug_bus.stats[category]
		var keys: Array = entries.keys()
		keys.sort()
		for key in keys:
			lines.append("  %s  %s" % [str(key), str(entries[key])])
		sections.append("\n".join(lines))
	if sections.is_empty():
		return "No runtime stats collected."
	return "\n\n".join(sections)


func _format_events(debug_bus: Node) -> String:
	if debug_bus.events.is_empty():
		return "No debug events yet."
	return "\n".join(debug_bus.events)


func _format_inspector_state(debug_bus: Node) -> String:
	var hovered_name := _object_label(debug_bus.hovered_entity)
	var selected_name := _object_label(debug_bus.selected_entity)
	return "Hover target: %s\nLocked target: %s" % [hovered_name, selected_name]


func _format_inspector(debug_bus: Node) -> String:
	var target: Object = debug_bus.selected_entity if debug_bus.selected_entity != null else debug_bus.hovered_entity
	if target == null:
		return "Move the cursor over an entity, then press F5 or left click to lock inspection."

	var lines: Array[String] = []
	lines.append("%s" % _object_label(target))
	lines.append("Type: %s" % target.get_class())
	if target is Node2D:
		lines.append("World Pos: %s" % str((target as Node2D).global_position))

	var data: Dictionary = debug_bus.inspector_data.get(target.get_instance_id(), {})
	if not data.is_empty():
		lines.append("")
		var keys: Array = data.keys()
		keys.sort()
		for key in keys:
			lines.append("%s: %s" % [key, str(data[key])])
	return "\n".join(lines)


func _object_label(value: Object) -> String:
	if value == null:
		return "none"
	if value is Node:
		return (value as Node).name
	return str(value)
