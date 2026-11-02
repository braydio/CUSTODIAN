extends Node2D

@export var duration: float = 0.72

var _elapsed := 0.0


func _ready() -> void:
	z_index = 4
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= duration:
		queue_free()


func _draw() -> void:
	var progress := clampf(_elapsed / maxf(0.001, duration), 0.0, 1.0)
	var alpha := 1.0 - progress
	var reach := lerpf(5.0, 24.0, progress)
	var amber := Color(1.0, 0.68, 0.24, alpha * (1.0 - progress))
	var steam := Color(0.86, 0.89, 0.84, alpha * 0.72)
	draw_line(Vector2.ZERO, Vector2(reach, -5.0), steam, 2.0)
	draw_line(Vector2.ZERO, Vector2(reach * 0.8, 4.0), steam, 1.5)
	draw_circle(Vector2(reach * 0.48, -3.0), lerpf(2.0, 5.0, progress), steam)
	draw_circle(Vector2(reach * 0.72, 3.0), lerpf(1.5, 4.0, progress), steam)
	if progress < 0.3:
		draw_circle(Vector2(3.0, 0.0), 2.5, amber)
