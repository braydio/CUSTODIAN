extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	operator.set_process(false)
	operator.set_physics_process(false)
	var prompt_service := root.get_node("InputPromptService")
	prompt_service.call("_set_device_family", &"gamepad")
	# Slice D moved the retained controller direction into OperatorAimController.
	# The actor no longer keeps a copy, so the assertions read the owner.
	operator.call("_sample_input_frame")
	operator.call("_resolve_aim")
	var aim_controller = operator.get("_aim_controller")
	assert(aim_controller != null, "the aim authority must exist after the first resolve")

	Input.action_press("aim_right", 1.0)
	operator.call("_sample_input_frame")
	operator.call("_update_aim")
	Input.action_release("aim_right")
	operator.call("_sample_input_frame")
	assert(operator.get("aim_direction").is_equal_approx(Vector2.RIGHT))
	assert(aim_controller.last_controller_aim.is_equal_approx(Vector2.RIGHT))

	operator.set("global_position", Vector2(12000.0, -9000.0))
	operator.call("_update_aim")
	assert(operator.get("aim_direction").is_equal_approx(Vector2.RIGHT), "neutral gamepad aim must ignore stale mouse position")
	assert((operator.call("_get_attack_aim_direction") as Vector2).is_equal_approx(Vector2.RIGHT), "attack direction must use retained gamepad aim")

	Input.action_press("aim_left", 0.1)
	operator.call("_sample_input_frame")
	operator.call("_update_aim")
	Input.action_release("aim_left")
	operator.call("_sample_input_frame")
	assert(operator.get("aim_direction").is_equal_approx(Vector2.RIGHT), "sub-deadzone stick input must not replace retained aim")

	aim_controller.reset()
	operator.set("movement_direction", Vector2.UP)
	operator.call("_update_aim")
	assert(operator.get("aim_direction").is_equal_approx(Vector2.UP), "first-use gamepad fallback must use movement/facing")

	prompt_service.call("_set_device_family", &"keyboard_mouse")
	operator.set("arrow_aim_enabled", true)
	Input.action_press("aim_down", 1.0)
	operator.call("_sample_input_frame")
	operator.call("_update_aim")
	Input.action_release("aim_down")
	operator.call("_sample_input_frame")
	assert(operator.get("aim_direction").is_equal_approx(Vector2.DOWN), "KBM mode must resume keyboard aim ownership")

	operator.queue_free()
	await process_frame
	print("operator_input_aim_source_smoke: PASS")
	quit(0)
