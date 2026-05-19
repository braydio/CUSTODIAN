extends Node2D
class_name ARRNSignalIndicator

@export var radius: float = 18.0
@export var ring_width: float = 2.0

var signal_strength: float = 0.0
var status_color: Color = Color(0.4, 0.4, 0.4, 0.55)


func set_signal(strength: float, color: Color) -> void:
	signal_strength = clampf(strength, 0.0, 1.0)
	status_color = color
	queue_redraw()


func _draw() -> void:
	if signal_strength <= 0.001:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, status_color.darkened(0.4), ring_width)
		return
	var sweep := TAU * signal_strength
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + sweep, 32, status_color, ring_width)
	draw_circle(Vector2.ZERO, 3.0 + 4.0 * signal_strength, status_color)
