extends Node2D

@export var base_radius: float = 22.0
@export var thickness: float = 2.0
@export var pulse_amount: float = 3.0
@export var pulse_speed: float = 5.0
@export var ring_color: Color = Color(1.0, 0.35, 0.25, 0.9)

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var radius: float = base_radius + sin(_time * pulse_speed) * pulse_amount
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, ring_color, thickness)
