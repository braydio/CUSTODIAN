extends Node2D

@export var radius: float = 34.0
@export var color: Color = Color(0.24, 0.92, 1.0, 0.78)

var _pulse_time := 0.0


func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + sin(_pulse_time * 3.2) * 0.08
	var draw_radius := radius * pulse
	draw_arc(Vector2.ZERO, draw_radius, 0.0, TAU, 40, color, 2.0, true)
	draw_line(Vector2(-9.0, 0.0), Vector2(9.0, 0.0), color, 2.0, true)
	draw_line(Vector2(0.0, -9.0), Vector2(0.0, 9.0), color, 2.0, true)
