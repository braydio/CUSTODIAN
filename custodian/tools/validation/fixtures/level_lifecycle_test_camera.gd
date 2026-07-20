extends Camera2D

var runtime_map: Node
var presentation_framing := false
var target_zoom := Vector2.ONE


func set_runtime_map(map_instance: Node) -> void:
	runtime_map = map_instance


func set_presentation_framing(active: bool, _offset := Vector2.ZERO, _zoom := Vector2.ONE) -> void:
	presentation_framing = active


func has_presentation_framing() -> bool:
	return presentation_framing
