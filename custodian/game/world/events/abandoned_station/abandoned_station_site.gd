extends Node2D
class_name AbandonedStationSite

const SERVICE_SCRIPT := preload("res://game/world/events/abandoned_station/abandoned_station_service_point.gd")
const EVENT_ID := &"campaign_abandoned_station_site_v1"
const SERVICE_LABELS := ["NORTH RELAY", "EAST CONDUIT", "CORE FEED"]
const TICKS_PER_SECOND := 60
const STABILITY_WINDOW_SECONDS := 90
const STABILITY_WINDOW_TICKS := TICKS_PER_SECOND * STABILITY_WINDOW_SECONDS
const DECISION_MAINTAIN := &"maintain_containment"
const DECISION_SHUT_DOWN := &"shut_down_coupling"
const DECISION_READBACKS := {
	DECISION_MAINTAIN: "EVIDENCE PRESERVED",
	DECISION_SHUT_DOWN: "EVIDENCE INCOMPLETE",
}
const DECISION_PROMPTS := {
	DECISION_MAINTAIN: "MAINTAIN CONTAINMENT",
	DECISION_SHUT_DOWN: "SHUT DOWN COUPLING",
}
const PHASE_IDLE := &"idle"
const PHASE_ACTIVE := &"active"
const PHASE_HAZARD_REVEALED := &"hazard_revealed"
const PHASE_EXPIRED := &"expired"
const PHASE_RESOLVED := &"resolved"


class ResolutionPoint extends Node2D:
	var controller: Node
	var decision_id: StringName
	var prompt_text := ""
	var readback_text := ""
	var _label: Label


	func _ready() -> void:
		add_to_group("interactable")
		_label = Label.new()
		_label.text = prompt_text + "\n" + readback_text
		_label.position = Vector2(-78.0, 17.0)
		_label.size = Vector2(156.0, 34.0)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 10)
		_label.add_theme_color_override("font_color", Color(0.78, 0.91, 0.95))
		add_child(_label)
		queue_redraw()


	func can_interact(_actor: Node = null) -> bool:
		return is_instance_valid(controller) \
			and bool(controller.call("can_resolve_containment", decision_id))


	func get_interaction_prompt() -> String:
		return String(prompt_text) if can_interact() else ""


	func get_interaction_prompt_body() -> String:
		return String(readback_text)


	func get_interaction_position() -> Vector2:
		return global_position


	func get_interaction_distance() -> float:
		return 76.0


	func interact(_actor: Node) -> void:
		if can_interact():
			controller.call("resolve_containment", decision_id)


	func _draw() -> void:
		var color := Color("77a5a0") if decision_id == DECISION_MAINTAIN else Color("b77d5d")
		draw_circle(Vector2.ZERO, 10.0, color)
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color("d3c897"), 1.5)

var event_id: StringName
var service_states: Array[bool] = [false, false, false]
var _stability_phase: StringName = PHASE_IDLE
var _stability_started_tick := -1
var _broadcast: Label
var _local_stability_cue: Polygon2D
var _memory: Node
var _containment_decision: StringName = &""
var _resolution_points: Array[ResolutionPoint] = []


func configure(p_event_id: StringName, services: Array, memory: Node) -> void:
	event_id = p_event_id
	_memory = memory
	var payload: Dictionary = memory.call("get_payload", event_id) if memory != null else {}
	var completed: Array = payload.get("services", [])
	for index in range(3):
		service_states[index] = bool(completed[index]) if index < completed.size() else false
	_stability_started_tick = int(payload.get("stability_started_tick", -1))
	_stability_phase = _phase_from_payload(payload)
	_containment_decision = StringName(payload.get("containment_decision", ""))
	if _containment_decision not in DECISION_READBACKS:
		_containment_decision = &""
	if _containment_decision != &"":
		_stability_phase = PHASE_RESOLVED
	elif _stability_phase == PHASE_RESOLVED:
		_stability_phase = PHASE_IDLE
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
	_create_resolution_points()

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
		and not _event_completed() \
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


func can_offer_resolution() -> bool:
	return _stability_phase == PHASE_HAZARD_REVEALED \
		and _containment_decision == &"" \
		and not _event_completed()


func can_resolve_containment(decision_id: StringName) -> bool:
	return can_offer_resolution() and DECISION_READBACKS.has(decision_id)


func resolve_containment(decision_id: StringName) -> void:
	if not can_resolve_containment(decision_id) or _memory == null \
		or not _memory.has_method("mark_completed"):
		return
	_containment_decision = decision_id
	_stability_phase = PHASE_RESOLVED
	var payload := _state_payload()
	payload["containment_decision"] = String(decision_id)
	payload["containment_readback"] = String(DECISION_READBACKS[decision_id])
	_memory.call("mark_completed", event_id, payload)
	_refresh_presentation(_current_simulation_tick())


func get_resolution_points() -> Array[ResolutionPoint]:
	return _resolution_points.duplicate()


func get_containment_decision() -> StringName:
	return _containment_decision


func get_resolution_readback() -> String:
	return String(DECISION_READBACKS.get(_containment_decision, ""))


func _advance_to_simulation_tick(fixed_tick: int) -> void:
	if _stability_phase != PHASE_ACTIVE or fixed_tick < _stability_started_tick:
		return
	if fixed_tick - _stability_started_tick >= STABILITY_WINDOW_TICKS:
		_stability_phase = PHASE_EXPIRED
		_persist_state()


func _phase_from_payload(payload: Dictionary) -> StringName:
	var stored := StringName(payload.get("stability_phase", String(PHASE_IDLE)))
	if stored in [PHASE_IDLE, PHASE_ACTIVE, PHASE_HAZARD_REVEALED, PHASE_EXPIRED, PHASE_RESOLVED]:
		return stored
	return PHASE_IDLE


func _persist_state() -> void:
	if _memory == null or not _memory.has_method("mark_spawned"):
		return
	_memory.call("mark_spawned", event_id, _state_payload())


func _state_payload() -> Dictionary:
	return {
		"services": service_states.duplicate(),
		"stability_phase": String(_stability_phase),
		"stability_started_tick": _stability_started_tick,
	}


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
			_broadcast.text = "OUTWARD LINK IS UNSAFE\nEVIDENCE OUTCOME PENDING\nS3 RESOLUTION PENDING"
			_broadcast.add_theme_color_override("font_color", Color(1.0, 0.38, 0.28))
		PHASE_EXPIRED:
			_broadcast.text = "STABILITY WINDOW EXPIRED\nSERVICES %d/3\nCAMPAIGN AND EXTRACTION INTACT" % service_count
			_broadcast.add_theme_color_override("font_color", Color(1.0, 0.24, 0.18))
		PHASE_RESOLVED:
			_broadcast.text = "%s\n%s\nSTATION EVENT COMPLETE" % [
				String(DECISION_PROMPTS.get(_containment_decision, "STATION RESOLVED")),
				get_resolution_readback(),
			]
			_broadcast.add_theme_color_override("font_color", Color(0.72, 0.91, 0.78))
		_:
			if _event_completed():
				_broadcast.text = "STATION EVENT ALREADY COMPLETE\nNO CONTAINMENT DECISION RECORDED"
			else:
				_broadcast.text = "EVACUATE THIS STATION\nDO NOT LINK TO THE CORE FEED\nSERVICES %d/3\nWINDOW STARTS ON FIRST SERVICE" % service_count
			_broadcast.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42))
	for point in _resolution_points:
		point.visible = can_offer_resolution()
	_update_local_stability_cue(current_tick)


func _create_resolution_points() -> void:
	for decision_id in [DECISION_MAINTAIN, DECISION_SHUT_DOWN]:
		var point := ResolutionPoint.new()
		point.name = "StationResolution_%s" % String(decision_id).to_pascal_case()
		point.controller = self
		point.decision_id = decision_id
		point.prompt_text = String(DECISION_PROMPTS[decision_id])
		point.readback_text = String(DECISION_READBACKS[decision_id])
		add_child(point)
		point.position = Vector2(-72.0 if decision_id == DECISION_MAINTAIN else 72.0, 76.0)
		_resolution_points.append(point)


func _event_completed() -> bool:
	return _memory != null and _memory.has_method("is_completed") \
		and bool(_memory.call("is_completed", event_id))


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
