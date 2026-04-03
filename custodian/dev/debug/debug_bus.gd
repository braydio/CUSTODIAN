extends Node

var enabled := false
var minimal_mode := false
var overlay_mode := 0

var stats: Dictionary = {}
var events: Array[String] = []
var overlays: Dictionary = {}
var inspector_data: Dictionary = {}

var selected_entity: Object = null
var hovered_entity: Object = null

var stats_version := 0
var events_version := 0
var overlays_version := 0
var inspector_version := 0

const MAX_EVENTS := 100

func set_stat(category: String, key: String, value) -> void:
	if category.is_empty() or key.is_empty():
		return
	var category_stats: Dictionary = stats.get(category, {})
	var prior = category_stats.get(key, null)
	if prior == value and stats.has(category):
		return
	category_stats[key] = value
	stats[category] = category_stats
	stats_version += 1

func push_event(category: String, msg: String) -> void:
	if not enabled:
		return
	var timestamp := Time.get_ticks_msec() / 1000.0
	var category_text := category if not category.is_empty() else "DEBUG"
	events.append("[%.2f] %s: %s" % [timestamp, category_text, msg])
	if events.size() > MAX_EVENTS:
		events.pop_front()
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
	inspector_version += 1

func toggle_selected_entity(entity: Object) -> void:
	if selected_entity == entity:
		selected_entity = null
	else:
		selected_entity = entity
	inspector_version += 1

func set_inspector_data(entity: Object, data: Dictionary) -> void:
	if entity == null:
		return
	inspector_data[entity.get_instance_id()] = data
	inspector_version += 1

func clear_inspector_data() -> void:
	if inspector_data.is_empty():
		return
	inspector_data.clear()
	inspector_version += 1
