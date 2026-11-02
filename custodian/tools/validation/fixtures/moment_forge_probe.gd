extends Node2D

var current_health := 100.0
var _pulse := 0.0


func _ready() -> void:
	add_to_group("player")
	queue_redraw()


func _physics_process(delta: float) -> void:
	_pulse = fposmod(_pulse + delta, 1.0)
	if Input.is_action_pressed("attack_primary"):
		position.x += 1.0
	queue_redraw()


func _draw() -> void:
	var glow := 0.55 + sin(_pulse * TAU) * 0.25
	draw_circle(Vector2.ZERO, 28.0, Color(0.16, 0.78, 0.92, glow))
	draw_circle(
		Vector2.ZERO,
		18.0,
		Color(0.04, 0.12, 0.20, 1.0)
	)
	draw_line(
		Vector2(-42.0, 0.0),
		Vector2(42.0, 0.0),
		Color(0.84, 0.92, 1.0, 0.75),
		2.0
	)

