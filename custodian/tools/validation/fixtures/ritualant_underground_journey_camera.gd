extends Camera2D

var follow_target: Node2D
var framing_offset := Vector2.ZERO
var framing_zoom := Vector2.ONE


func _process(delta: float) -> void:
	if follow_target == null or not is_instance_valid(follow_target):
		follow_target = get_node_or_null("../Operator") as Node2D
	if follow_target != null:
		global_position = global_position.lerp(
			follow_target.global_position + framing_offset,
			1.0 - exp(-6.0 * delta)
		)
	zoom = zoom.lerp(framing_zoom, 1.0 - exp(-5.0 * delta))


func set_presentation_framing(active: bool, offset := Vector2.ZERO, value := Vector2.ONE) -> void:
	framing_offset = offset if active else Vector2.ZERO
	framing_zoom = value if active else Vector2.ONE


func set_presentation_framing_transition(offset: Vector2, value: Vector2, _duration: float) -> void:
	set_presentation_framing(true, offset, value)


func set_presentation_subject_constraint(_subject: Node2D, _inset: Vector4) -> void:
	pass


func clear_presentation_framing(_restore := true) -> void:
	set_presentation_framing(false)
