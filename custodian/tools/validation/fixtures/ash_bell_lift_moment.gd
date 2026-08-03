extends Node2D

@onready var presentation: AshBellLiftIngressPresentation = $AshBellLiftIngressPresentation
@onready var operator: Node2D = $Operator

var shaft_visible: bool:
	get:
		return presentation.shaft_window.visible

var lift_position: Vector2:
	get:
		return presentation.lift_root.position

var puppet_active: bool:
	get:
		return presentation.has_presentation_puppet()


func _ready() -> void:
	presentation.reset_presentation()
	queue_redraw()


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	match command:
		"begin_lift_descent":
			presentation.play_descent(operator)
			return true
		"reset_lift_exterior":
			presentation.reset_presentation()
			return true
	return false


func _draw() -> void:
	draw_rect(Rect2(-640.0, -360.0, 1280.0, 720.0), Color("10151c"))
	draw_rect(Rect2(-640.0, 42.0, 1280.0, 318.0), Color("292821"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-310.0, 22.0),
			Vector2(-190.0, -6.0),
			Vector2(190.0, -6.0),
			Vector2(310.0, 22.0),
			Vector2(310.0, 90.0),
			Vector2(-310.0, 90.0),
		]),
		Color("343229")
	)
