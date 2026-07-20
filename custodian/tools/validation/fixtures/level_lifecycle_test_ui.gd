extends CanvasLayer

var presentation_mode: StringName = &"gameplay"


func set_world_presentation_mode(mode: StringName) -> void:
	presentation_mode = mode


func get_world_presentation_mode() -> StringName:
	return presentation_mode
