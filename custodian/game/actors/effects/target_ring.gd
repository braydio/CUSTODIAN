extends Node2D

@export var base_radius: float = 22.0
@export var thickness: float = 2.0
@export var pulse_amount: float = 3.0
@export var pulse_speed: float = 5.0
@export var ring_color: Color = Color(1.0, 0.35, 0.25, 0.9)
@export var strike_zone_color: Color = Color(0.55, 1.0, 0.35, 0.95)
@export var strike_zone_thickness_bonus: float = 1.5

var _time: float = 0.0
var _in_strike_zone: bool = false


func set_in_strike_zone(enabled: bool) -> void:
	if _in_strike_zone == enabled:
		return
	_in_strike_zone = enabled
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var radius: float = base_radius + sin(_time * pulse_speed) * pulse_amount
	var color := strike_zone_color if _in_strike_zone else ring_color
	var draw_thickness := thickness + (strike_zone_thickness_bonus if _in_strike_zone else 0.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, draw_thickness)
	if _in_strike_zone:
		draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 48, color.darkened(0.25), max(1.0, thickness))
