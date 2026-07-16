extends Control
class_name RangedReticle

const RETICLE_SIZE := Vector2(48.0, 48.0)
const READY_COLOR := Color(0.72, 0.96, 0.88, 0.96)
const DIM_COLOR := Color(0.52, 0.68, 0.64, 0.62)
const HOT_COLOR := Color(1.0, 0.34, 0.20, 0.95)

var _posture: StringName = &"none"
var _transition_ratio := 0.0
var _aim_accuracy_ratio := 0.0
var _recoil := 0.0
var _display_gap := 18.0
var _target_gap := 18.0
var _display_alpha := 0.0
var _target_alpha := 0.0
var _ready_pulse := 0.0
var _color := READY_COLOR


func _ready() -> void:
	custom_minimum_size = RETICLE_SIZE
	size = RETICLE_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	visible = false


func set_weapon_status(snapshot: Dictionary) -> void:
	var previous_posture := _posture
	_posture = StringName(str(snapshot.get("ranged_posture", "none")))
	_transition_ratio = clampf(float(snapshot.get("ranged_transition_ratio", 0.0)), 0.0, 1.0)
	_aim_accuracy_ratio = clampf(float(snapshot.get("ranged_aim_accuracy_ratio", _transition_ratio)), 0.0, 1.0)
	_recoil = maxf(0.0, float(snapshot.get("recoil", 0.0)))
	visible = _posture not in [&"none", &"relaxed"]
	if not visible:
		_target_alpha = 0.0
		queue_redraw()
		return
	if _posture == &"ready" and previous_posture == &"raising":
		_ready_pulse = 1.0
	_resolve_targets()
	queue_redraw()


func _process(delta: float) -> void:
	_display_gap = lerpf(_display_gap, _target_gap, clampf(delta * 18.0, 0.0, 1.0))
	_display_alpha = lerpf(_display_alpha, _target_alpha, clampf(delta * 22.0, 0.0, 1.0))
	_ready_pulse = maxf(0.0, _ready_pulse - delta * 4.5)
	queue_redraw()


func _resolve_targets() -> void:
	_color = READY_COLOR
	match _posture:
		&"raising":
			_target_gap = lerpf(18.0, 8.0, _aim_accuracy_ratio)
			_target_alpha = lerpf(0.2, 0.95, _aim_accuracy_ratio)
		&"ready":
			_target_gap = 8.0
			_target_alpha = 1.0
		&"firing":
			_target_gap = 12.0 + minf(6.0, _recoil * 0.8)
			_target_alpha = 1.0
		&"recovering":
			_target_gap = lerpf(12.0, 8.0, _transition_ratio)
			_target_alpha = 0.96
		&"lowering":
			_target_gap = lerpf(8.0, 18.0, _transition_ratio)
			_target_alpha = lerpf(0.95, 0.15, _transition_ratio)
		&"reloading":
			_target_gap = 15.0
			_target_alpha = 0.52
			_color = DIM_COLOR
		&"overheated":
			_target_gap = 17.0
			_target_alpha = 0.92
			_color = HOT_COLOR
		_:
			_target_gap = 18.0
			_target_alpha = 0.0


func _draw() -> void:
	if _display_alpha <= 0.01:
		return
	var center := size * 0.5
	var pulse_gap := _display_gap + _ready_pulse * 4.0
	var color := Color(_color.r, _color.g, _color.b, _color.a * _display_alpha)
	var arm := 5.0
	var broken := _posture == &"overheated"
	_draw_bracket(center + Vector2(-pulse_gap, 0.0), Vector2.LEFT, arm, color, broken)
	_draw_bracket(center + Vector2(pulse_gap, 0.0), Vector2.RIGHT, arm, color, broken)
	_draw_bracket(center + Vector2(0.0, -pulse_gap), Vector2.UP, arm, color, broken)
	_draw_bracket(center + Vector2(0.0, pulse_gap), Vector2.DOWN, arm, color, broken)
	var dot_alpha := _display_alpha
	if _posture == &"raising":
		dot_alpha *= _aim_accuracy_ratio
	elif _posture == &"firing":
		dot_alpha = 1.0
	elif _posture in [&"reloading", &"overheated"]:
		dot_alpha *= 0.45
	draw_circle(center, 1.5 + _ready_pulse * 1.2, Color(color.r, color.g, color.b, dot_alpha))


func _draw_bracket(origin: Vector2, outward: Vector2, arm: float, color: Color, broken: bool) -> void:
	var inward := -outward
	var tangent := Vector2(-outward.y, outward.x)
	var length := arm * (0.55 if broken else 1.0)
	draw_line(origin, origin + inward * length, color, 1.5, true)
	if not broken:
		draw_line(origin, origin + tangent * 2.5, color, 1.5, true)
		draw_line(origin, origin - tangent * 2.5, color, 1.5, true)
