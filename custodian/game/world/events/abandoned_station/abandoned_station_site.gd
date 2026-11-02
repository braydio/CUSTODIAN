extends Node2D
class_name AbandonedStationSite

const SERVICE_SCRIPT := preload("res://game/world/events/abandoned_station/abandoned_station_service_point.gd")
const EVENT_ID := &"campaign_abandoned_station_site_v1"
const SERVICE_LABELS := ["NORTH RELAY", "EAST CONDUIT", "CORE FEED"]

var event_id: StringName
var service_states: Array[bool] = [false, false, false]
var _broadcast: Label
var _memory: Node


func configure(p_event_id: StringName, services: Array, memory: Node) -> void:
	event_id = p_event_id
	_memory = memory
	var payload: Dictionary = memory.call("get_payload", event_id) if memory != null else {}
	var completed: Array = payload.get("services", [])
	for index in range(3):
		service_states[index] = bool(completed[index]) if index < completed.size() else false
	for index in range(mini(services.size(), 3)):
		var point := SERVICE_SCRIPT.new()
		point.name = "StationService_%s" % str(index + 1)
		point.site = self
		point.service_index = index
		point.label_text = SERVICE_LABELS[index]
		add_child(point)
		point.global_position = services[index]
	var warning := Label.new()
	warning.name = "EvacuationBroadcast"
	warning.text = "EVACUATE THIS STATION\nDO NOT LINK TO THE CORE FEED"
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.position = Vector2(-142.0, -118.0)
	warning.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42))
	add_child(warning)
	_broadcast = warning


func _process(_delta: float) -> void:
	if _broadcast != null:
		_broadcast.visible = int(Time.get_ticks_msec() / 900) % 2 == 0


func is_service_complete(index: int) -> bool:
	return index >= 0 and index < service_states.size() and service_states[index]


func service_point(index: int) -> void:
	if index < 0 or index >= service_states.size() or service_states[index]:
		return
	service_states[index] = true
	if _broadcast != null:
		_broadcast.queue_redraw()
	if _memory != null and _memory.has_method("mark_spawned"):
		_memory.call("mark_spawned", event_id, {"services": service_states.duplicate()})
	if _broadcast != null:
		_broadcast.text = "EVACUATE THIS STATION\nDO NOT LINK TO THE CORE FEED\nSERVICES %d/3" % service_states.count(true)
	if service_states.all(func(value: bool) -> bool: return value):
		if _memory != null and _memory.has_method("mark_completed"):
			_memory.call("mark_completed", event_id, {"services": service_states.duplicate()})
