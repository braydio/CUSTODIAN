class_name VehicleInputAdapter
extends RefCounted


static func read_actions() -> Dictionary:
	return {
		"primary": _is_pressed(&"attack_primary") or _is_pressed(&"fire"),
		"secondary": _is_pressed(&"attack_secondary"),
		"interact_pressed": _is_just_pressed(&"interact"),
		"exit_pressed": _is_just_pressed(&"interact"),
		"brake": _is_pressed(&"brake")
	}


static func read_movement_vector() -> Vector2:
	var input_vector := Vector2.ZERO
	input_vector.x = _strength(&"move_right") - _strength(&"move_left")
	input_vector.y = _strength(&"move_down") - _strength(&"move_up")
	return input_vector.normalized() if input_vector.length_squared() > 0.0001 else Vector2.ZERO


static func _strength(action: StringName) -> float:
	return Input.get_action_strength(action) if InputMap.has_action(action) else 0.0


static func _is_pressed(action: StringName) -> bool:
	return Input.is_action_pressed(action) if InputMap.has_action(action) else false


static func _is_just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action) if InputMap.has_action(action) else false
