extends Node2D
class_name AbandonedStationSite

const SERVICE_SCRIPT := preload("res://game/world/events/abandoned_station/abandoned_station_service_point.gd")
const EVENT_ID := &"campaign_abandoned_station_site_v1"
const SERVICE_LABELS := ["NORTH RELAY", "EAST CONDUIT", "CORE FEED"]
const TICKS_PER_SECOND := 60
const STABILITY_WINDOW_SECONDS := 90
const STABILITY_WINDOW_TICKS := TICKS_PER_SECOND * STABILITY_WINDOW_SECONDS
const PHASE_IDLE := &"idle"
const PHASE_ACTIVE := &"active"
const PHASE_HAZARD_REVEALED := &"hazard_revealed"
const PHASE_EXPIRED := &"expired"

var event_id: StringName
var service_states: Array[bool] = [false, false, false]
var _stability_phase: StringName = PHASE_IDLE
var _stability_started_tick := -1
var _broadcast: Label
var _local_stability_cue: Polygon2D
var _memory: Node


func configure(p_event_id: StringName, services: Array, memory: Node) -> void:
	event_id = p_event_id
	_memory = memory
	var payload: Dictionary = memory.call("get_payload", event_id) if memory != null else {}
	var completed: Array = payload.get("services", [])
	for index in range(3):
		service_states[index] = bool(completed[index]) if index < completed.size() else false
	_stability_started_tick = int(payload.get("stability_started_tick", -1))
	_stability_phase = _phase_from_payload(payload)
	if _stability_phase == PHASE_ACTIVE and _stability_started_tick < 0:
		_stability_phase = PHASE_IDLE
	if _stability_phase == PHASE_HAZARD_REVEALED and _service_count() < SERVICE_LABELS.size():
		_stability_phase = PHASE_ACTIVE if _stability_started_tick >= 0 else PHASE_IDLE
	if _stability_phase == PHASE_ACTIVE and _service_count() == SERVICE_LABELS.size():
		_stability_phase = PHASE_HAZARD_REVEALED

	_create_local_stability_cue(services)
	for index in range(mini(services.size(), SERVICE_LABELS.size())):
		var point := SERVICE_SCRIPT.new()
		point.name = "StationService_%s" % str(index + 1)
		point.site = self
		point.service_index = index
		point.label_text = SERVICE_LABELS[index]
		add_child(point)
		point.global_position = services[index]

	_broadcast = Label.new()
	_broadcast.name = "EvacuationBroadcast"
	_broadcast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_broadcast.position = Vector2(-142.0, -118.0)
	_broadcast.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42))
	add_child(_broadcast)
	_advance_to_simulation_tick(_current_simulation_tick())
	_refresh_presentation(_current_simulation_tick())


func _process(_delta: float) -> void:
	var current_tick := _current_simulation_tick()
	_advance_to_simulation_tick(current_tick)
	_refresh_presentation(current_tick)
	if _broadcast != null:
		_broadcast.visible = int(Time.get_ticks_msec() / 900) % 2 == 0


func is_service_complete(index: int) -> bool:
	return index >= 0 and index < service_states.size() and service_states[index]


func can_service(index: int) -> bool:
	return index >= 0 \
		and index < service_states.size() \
		and not service_states[index] \
		and _stability_phase != PHASE_EXPIRED \
		and _stability_phase != PHASE_HAZARD_REVEALED


func service_point(index: int) -> void:
	var current_tick := _current_simulation_tick()
	_advance_to_simulation_tick(current_tick)
	if not can_service(index):
		return
	if _stability_phase == PHASE_IDLE:
		_stability_started_tick = current_tick
		_stability_phase = PHASE_ACTIVE
	service_states[index] = true
	if _service_count() == SERVICE_LABELS.size():
		_stability_phase = PHASE_HAZARD_REVEALED
	_persist_state()
	_refresh_presentation(current_tick)


func advance_to_simulation_tick(fixed_tick: int) -> void:
	_advance_to_simulation_tick(fixed_tick)
	_refresh_presentation(fixed_tick)


func get_stability_phase() -> StringName:
	return _stability_phase


func get_stability_started_tick() -> int:
	return _stability_started_tick


func get_remaining_stability_ticks(fixed_tick: int = -1) -> int:
	if _stability_phase != PHASE_ACTIVE:
		return 0
	var current_tick := _current_simulation_tick() if fixed_tick < 0 else fixed_tick
	var elapsed_ticks := maxi(0, current_tick - _stability_started_tick)
	return maxi(0, STABILITY_WINDOW_TICKS - elapsed_ticks)


func _advance_to_simulation_tick(fixed_tick: int) -> void:
	if _stability_phase != PHASE_ACTIVE or fixed_tick < _stability_started_tick:
		return
	if fixed_tick - _stability_started_tick >= STABILITY_WINDOW_TICKS:
		_stability_phase = PHASE_EXPIRED
		_persist_state()


func _phase_from_payload(payload: Dictionary) -> StringName:
	var stored := StringName(payload.get("stability_phase", String(PHASE_IDLE)))
	if stored in [PHASE_IDLE, PHASE_ACTIVE, PHASE_HAZARD_REVEALED, PHASE_EXPIRED]:
		return stored
	return PHASE_IDLE


func _persist_state() -> void:
	if _memory == null or not _memory.has_method("mark_spawned"):
		return
	_memory.call("mark_spawned", event_id, {
			"services": service_states.duplicate(),
			"stability_phase": String(_stability_phase),
			"stability_started_tick": _stability_started_tick,
	})


func _refresh_presentation(current_tick: int) -> void:
	if _broadcast == null:
		return
	var service_count := _service_count()
	match _stability_phase:
		PHASE_ACTIVE:
			var remaining_seconds := ceili(float(get_remaining_stability_ticks(current_tick)) / float(TICKS_PER_SECOND))
			_broadcast.text = "STABILITY WINDOW %02d SEC\nSERVICES %d/3\nDO NOT LINK TO THE CORE FEED" % [remaining_seconds, service_count]
			_broadcast.add_theme_color_override("font_color", Color(1.0, 0.58, 0.28) if remaining_seconds <= 30 else Color(1.0, 0.72, 0.42))
		PHASE_HAZARD_REVEALED:
			_broadcast.text = "OUTWARD LINK IS UNSAFE\nEVIDENCE PRESERVED\nS3 RESOLUTION PENDING"
			_broadcast.add_theme_color_override("font_color", Color(1.0, 0.38, 0.28))
		PHASE_EXPIRED:
			_broadcast.text = "STABILITY WINDOW EXPIRED\nSERVICES %d/3\nCAMPAIGN AND EXTRACTION INTACT" % service_count
			_broadcast.add_theme_color_override("font_color", Color(1.0, 0.24, 0.18))
		_:
			_broadcast.text = "EVACUATE THIS STATION\nDO NOT LINK TO THE CORE FEED\nSERVICES %d/3\nWINDOW STARTS ON FIRST SERVICE" % service_count
			_broadcast.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42))
	_update_local_stability_cue(current_tick)


func _create_local_stability_cue(services: Array) -> void:
	if services.is_empty():
		return
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for service_position in services:
		var point: Vector2 = service_position
		minimum.x = minf(minimum.x, point.x)
		minimum.y = minf(minimum.y, point.y)
		maximum.x = maxf(maximum.x, point.x)
		maximum.y = maxf(maximum.y, point.y)
	minimum -= Vector2(36.0, 48.0)
	maximum += Vector2(36.0, 36.0)
	_local_stability_cue = Polygon2D.new()
	_local_stability_cue.name = "LocalStabilityCue"
	_local_stability_cue.z_index = 0
	_local_stability_cue.polygon = PackedVector2Array([
		minimum,
		Vector2(maximum.x, minimum.y),
		maximum,
		Vector2(minimum.x, maximum.y),
	])
	_local_stability_cue.color = Color(0.92, 0.2, 0.1, 0.0)
	add_child(_local_stability_cue)


func _update_local_stability_cue(current_tick: int) -> void:
	if _local_stability_cue == null:
		return
	var alpha := 0.0
	if _stability_phase == PHASE_ACTIVE:
		var elapsed := maxi(0, current_tick - _stability_started_tick)
		alpha = lerpf(0.035, 0.13, clampf(float(elapsed) / float(STABILITY_WINDOW_TICKS), 0.0, 1.0))
	elif _stability_phase == PHASE_HAZARD_REVEALED:
		alpha = 0.16
	elif _stability_phase == PHASE_EXPIRED:
		alpha = 0.22
	_local_stability_cue.color = Color(0.92, 0.2, 0.1, alpha)


func _service_count() -> int:
	return service_states.count(true)


func _current_simulation_tick() -> int:
	var game_state := get_node_or_null("/root/GameState")
	return int(game_state.get("tick")) if game_state != null else 0
