extends Node2D

@export var base_radius: float = 22.0
@export var thickness: float = 2.0
@export var pulse_amount: float = 3.0
@export var pulse_speed: float = 5.0
@export var ring_color: Color = Color(1.0, 0.35, 0.25, 0.9)
@export var strike_zone_color: Color = Color(0.55, 1.0, 0.35, 0.95)
@export var strike_zone_thickness_bonus: float = 1.5
@export var approach_color: Color = Color(1.0, 0.72, 0.28, 0.92)
@export var far_radius_bonus: float = 6.0
@export var reliable_radius_offset: float = -2.0
@export var target_state_response: float = 14.0

var _time: float = 0.0
var _in_strike_zone: bool = false
var _target_proximity: float = 0.0
var _display_proximity: float = 0.0
var _target_alignment: float = 0.0
var _display_alignment: float = 0.0
var _reliable_contact: bool = false
var _acquire_pulse: float = 0.0
var _reliable_pulse: float = 0.0


func set_melee_target_state(state: Dictionary) -> void:
	var was_reliable := _reliable_contact
	_target_proximity = clampf(float(state.get("proximity", 0.0)), 0.0, 1.0)
	_target_alignment = clampf(float(state.get("alignment", 0.0)), 0.0, 1.0)
	_reliable_contact = bool(state.get("reliable_contact", false))
	_in_strike_zone = _reliable_contact
	if bool(state.get("newly_acquired", false)):
		_acquire_pulse = 1.0
	if _reliable_contact and not was_reliable:
		_reliable_pulse = 1.0
	queue_redraw()


func set_in_strike_zone(enabled: bool) -> void:
	if _in_strike_zone == enabled:
		return
	_in_strike_zone = enabled
	_reliable_contact = enabled
	_target_proximity = 1.0 if enabled else 0.0
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	var response := 1.0 - exp(-target_state_response * maxf(delta, 0.0))
	_display_proximity = lerpf(_display_proximity, _target_proximity, response)
	_display_alignment = lerpf(_display_alignment, _target_alignment, response)
	_acquire_pulse = maxf(0.0, _acquire_pulse - delta * 3.5)
	_reliable_pulse = maxf(0.0, _reliable_pulse - delta * 4.5)
	queue_redraw()


func _draw() -> void:
	var radius := lerpf(
		base_radius + far_radius_bonus,
		base_radius + reliable_radius_offset,
		_display_proximity
	)
	var pulse_strength := lerpf(pulse_amount, pulse_amount * 0.35, _display_proximity)
	radius += sin(_time * pulse_speed) * pulse_strength
	radius += _acquire_pulse * 2.0 - _reliable_pulse * 1.5
	var color := ring_color.lerp(approach_color, _display_proximity)
	color.a *= lerpf(0.58, 1.0, _display_alignment)
	if _reliable_contact:
		color = strike_zone_color
	var draw_thickness := thickness + (strike_zone_thickness_bonus if _reliable_contact else 0.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, draw_thickness)
	var tick_alpha := clampf(_display_proximity * _display_alignment, 0.0, 1.0)
	var tick_color := color
	tick_color.a *= tick_alpha
	var tick_length := lerpf(1.0, 5.0, _display_proximity)
	for direction: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var outer: Vector2 = direction * (radius + 3.0)
		var inner: Vector2 = direction * (radius + 3.0 - tick_length)
		draw_line(outer, inner, tick_color, maxf(1.0, thickness))
	if _reliable_contact:
		draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 48, color.darkened(0.25), max(1.0, thickness))


func debug_get_melee_target_presentation() -> Dictionary:
	return {
		"target_proximity": _target_proximity,
		"display_proximity": _display_proximity,
		"target_alignment": _target_alignment,
		"display_alignment": _display_alignment,
		"reliable_contact": _reliable_contact,
		"acquire_pulse": _acquire_pulse,
		"reliable_pulse": _reliable_pulse,
	}
