extends Node

@export var max_events: int = 100
@export var max_commands: int = 64

var enabled := false
var minimal_mode := false
var overlay_mode := 0

var stats: Dictionary = {}
var events: Array[String] = []
var overlays: Dictionary = {}
var debug_overrides: Dictionary = {}
var command_queue: Array[Dictionary] = []

var selected_entity: Object = null
var hovered_entity: Object = null
var selected_entity_snapshot: Dictionary = {}
var inspector_data: Dictionary = {}

var stats_version := 0
var events_version := 0
var overlays_version := 0
var inspector_version := 0
var overrides_version := 0
var command_version := 0


func _ready() -> void:
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_F3 or key_event.physical_keycode == KEY_F3:
			if key_event.shift_pressed:
				minimal_mode = not minimal_mode
			else:
				enabled = not enabled
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_F4 or key_event.physical_keycode == KEY_F4:
			overlay_mode = (overlay_mode + 1) % 6
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_F5 or key_event.physical_keycode == KEY_F5:
			toggle_selected_entity(hovered_entity)
			get_viewport().set_input_as_handled()


func set_stat(category: String, key: String, value: Variant) -> void:
	if category.is_empty() or key.is_empty():
		return
	var category_stats: Dictionary = stats.get(category, {})
	var prior: Variant = category_stats.get(key, null)
	if prior == value and stats.has(category):
		return
	category_stats[key] = value
	stats[category] = category_stats
	stats_version += 1


func set_category(category: String, value: Variant) -> void:
	if category.is_empty():
		return
	if stats.get(category, null) == value:
		return
	stats[category] = value
	stats_version += 1


func push_event(category: String, msg: String) -> void:
	if not enabled:
		return
	var timestamp := Time.get_ticks_msec() / 1000.0
	var category_text := category if not category.is_empty() else "DEBUG"
	events.append("[%.2f] %s: %s" % [timestamp, category_text, msg])
	while events.size() > max_events:
		events.pop_front()
	events_version += 1


func import_observatory_events(observatory_events: Array[Dictionary]) -> void:
	var imported := false
	for entry in observatory_events:
		var kind := str(entry.get("kind", "EVENT"))
		var seconds := float(entry.get("time", 0)) / 1000.0
		var data := entry.get("data", {})
		var line := "[%.2f] %s: %s" % [seconds, kind, JSON.stringify(data)]
		if events.has(line):
			continue
		events.append(line)
		imported = true
	while events.size() > max_events:
		events.pop_front()
	if imported:
		events_version += 1


func clear_frame_overlays() -> void:
	if overlays.is_empty():
		return
	overlays.clear()
	overlays_version += 1


func set_overlay(layer: String, items: Array) -> void:
	if layer.is_empty():
		return
	overlays[layer] = items
	overlays_version += 1


func set_hovered_entity(entity: Object) -> void:
	if hovered_entity == entity:
		return
	hovered_entity = entity
	inspector_version += 1


func set_selected_entity(entity: Object) -> void:
	if selected_entity == entity:
		return
	selected_entity = entity
	_refresh_selected_entity_snapshot()
	inspector_version += 1


func toggle_selected_entity(entity: Object) -> void:
	if entity == null:
		selected_entity = null
	elif selected_entity == entity:
		selected_entity = null
	else:
		selected_entity = entity
	_refresh_selected_entity_snapshot()
	inspector_version += 1


func set_selected_entity_snapshot(snapshot: Dictionary) -> void:
	selected_entity_snapshot = snapshot.duplicate(true)
	inspector_version += 1


func set_inspector_data(entity: Object, data: Dictionary) -> void:
	if entity == null:
		return
	inspector_data[entity.get_instance_id()] = data.duplicate(true)
	if entity == selected_entity:
		selected_entity_snapshot = data.duplicate(true)
	inspector_version += 1


func clear_inspector_data() -> void:
	if inspector_data.is_empty():
		return
	inspector_data.clear()
	selected_entity_snapshot.clear()
	inspector_version += 1


func set_debug_override(key: String, value: Variant) -> void:
	if key.is_empty():
		return
	if debug_overrides.get(key, null) == value:
		return
	debug_overrides[key] = value
	overrides_version += 1


func queue_command(command: Dictionary) -> void:
	if command.is_empty():
		return
	command_queue.append(command.duplicate(true))
	while command_queue.size() > max_commands:
		command_queue.pop_front()
	command_version += 1


func drain_commands() -> Array[Dictionary]:
	var drained := command_queue.duplicate(true)
	command_queue.clear()
	return drained


func _refresh_selected_entity_snapshot() -> void:
	selected_entity_snapshot.clear()
	if selected_entity == null:
		return
	if inspector_data.has(selected_entity.get_instance_id()):
		selected_entity_snapshot = (inspector_data[selected_entity.get_instance_id()] as Dictionary).duplicate(true)
