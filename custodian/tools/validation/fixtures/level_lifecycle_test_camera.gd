extends Camera2D

var runtime_map: Node
var presentation_framing := false
var target_zoom := Vector2.ONE
var follow_target: Node2D
var presentation_bounds_override := Rect2()


func set_runtime_map(map_instance: Node) -> void:
	presentation_framing = false
	presentation_bounds_override = Rect2()
	follow_target = get_node_or_null("../Operator") as Node2D
	runtime_map = map_instance


func set_presentation_framing(active: bool, _offset := Vector2.ZERO, _zoom := Vector2.ONE) -> void:
	presentation_framing = active


func has_presentation_framing() -> bool:
	return presentation_framing


func clear_presentation_framing(restore_operator_follow := true) -> void:
	presentation_framing = false
	presentation_bounds_override = Rect2()
	if restore_operator_follow:
		follow_target = get_node_or_null("../Operator") as Node2D


func set_follow_target(target: Node2D) -> void:
	follow_target = target


func set_presentation_bounds_override(bounds: Rect2) -> void:
	presentation_bounds_override = bounds


func clear_presentation_bounds_override() -> void:
	presentation_bounds_override = Rect2()


func get_presentation_bounds_override() -> Rect2:
	return presentation_bounds_override
