extends Control
class_name RangedBallisticPip

const PIP_SIZE := Vector2(16.0, 16.0)
const ALIGNED_COLOR := Color(0.78, 1.0, 0.82, 0.95)
const TRACKING_COLOR := Color(0.62, 0.70, 0.68, 0.78)
const OBSTRUCTED_COLOR := Color(1.0, 0.34, 0.18, 0.96)

var _alignment_ratio := 0.0
var _aim_error_degrees := 180.0
var _obstructed := false


func _ready() -> void:
	custom_minimum_size = PIP_SIZE
	size = PIP_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func set_weapon_status(snapshot: Dictionary) -> void:
	_alignment_ratio = clampf(
		float(snapshot.get("ranged_ballistic_alignment_ratio", 0.0)),
		0.0,
		1.0
	)
	_aim_error_degrees = maxf(
		0.0,
		float(snapshot.get("ranged_aim_error_degrees", 180.0))
	)
	_obstructed = bool(snapshot.get("ranged_ballistic_obstructed", false))
	queue_redraw()


func get_presentation_state() -> Dictionary:
	return {
		"alignment_ratio": _alignment_ratio,
		"aim_error_degrees": _aim_error_degrees,
		"obstructed": _obstructed,
	}


func _draw() -> void:
	var center := size * 0.5
	if _obstructed:
		draw_line(center + Vector2(-4.0, -4.0), center + Vector2(4.0, 4.0), OBSTRUCTED_COLOR, 1.5, true)
		draw_line(center + Vector2(4.0, -4.0), center + Vector2(-4.0, 4.0), OBSTRUCTED_COLOR, 1.5, true)
		return
	var aligned := _aim_error_degrees <= 2.0
	var color := ALIGNED_COLOR if aligned else TRACKING_COLOR
	var radius := 2.0 if aligned else 2.5
	draw_circle(center, radius, color)
	draw_line(center + Vector2(0.0, -6.0), center + Vector2(0.0, -3.0), color, 1.0, true)
	draw_line(center + Vector2(0.0, 3.0), center + Vector2(0.0, 6.0), color, 1.0, true)
	draw_line(center + Vector2(-6.0, 0.0), center + Vector2(-3.0, 0.0), color, 1.0, true)
	draw_line(center + Vector2(3.0, 0.0), center + Vector2(6.0, 0.0), color, 1.0, true)
