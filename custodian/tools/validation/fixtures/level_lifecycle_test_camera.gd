extends Camera2D

var runtime_map: Node
var presentation_framing := false
var target_zoom := Vector2.ONE
var follow_target: Node2D


func set_runtime_map(map_instance: Node) -> void:
	presentation_framing = false
	follow_target = get_node_or_null("../Operator") as Node2D
	runtime_map = map_instance


func set_presentation_framing(active: bool, _offset := Vector2.ZERO, _zoom := Vector2.ONE) -> void:
	presentation_framing = active


func has_presentation_framing() -> bool:
	return presentation_framing
