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

	_check_external_aim_through_the_seam(operator, prompt_service)
	await _check_camera_motion_does_not_revive_the_mouse(operator, prompt_service)

	operator.queue_free()
	await process_frame
	print("operator_input_aim_source_smoke: PASS")
	quit(0)


## `process_input()` supplies a world-space aim direction. Drive it through the
## real Operator seam and prove the resolved aim is the supplied one.
##
## `arrow_aim_enabled` is false here deliberately: that is the Operator's own
## default, and the case where the pre-D.2 router filed the injected vector as
## `keyboard_aim` and the aim authority then ignored it. External control could
## press a button but not steer -- which is most of what an AI, a vehicle, a
## possession system or a replay needs the seam for.
func _check_external_aim_through_the_seam(operator: Node, prompt_service: Node) -> void:
	prompt_service.call("_set_device_family", &"keyboard_mouse")
	operator.set("arrow_aim_enabled", false)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)

	operator.call("process_input", Vector2.ZERO, Vector2.UP, false)
	operator.call("_sample_input_frame")
	operator.call("_resolve_aim")
	assert(
		(operator.get("aim_direction") as Vector2).is_equal_approx(Vector2.UP),
		"externally supplied aim must own aim with arrow_aim_enabled false, got %s"
			% operator.get("aim_direction")
	)
	assert(
		(operator.call("_get_attack_aim_direction") as Vector2).is_equal_approx(Vector2.UP),
		"an injected attack must use the supplied facing, not the aim that existed "
			+ "before injection, got %s" % operator.call("_get_attack_aim_direction")
	)

	# A retained gamepad direction must not outrank the driver either.
	prompt_service.call("_set_device_family", &"gamepad")
	operator.call("process_input", Vector2.ZERO, Vector2.LEFT, false)
	operator.call("_sample_input_frame")
	operator.call("_resolve_aim")
	assert(
		(operator.get("aim_direction") as Vector2).is_equal_approx(Vector2.LEFT),
		"external aim must not depend on the device family, got %s" % operator.get("aim_direction")
	)
	prompt_service.call("_set_device_family", &"keyboard_mouse")


## Camera movement must not look like pointer movement.
##
## `_get_world_mouse_position()` is a camera-relative coordinate, and the live
## `CameraController` follows the Operator with smoothing, lookahead, ranged lead,
## threat framing, bob and shake. The router used to derive `mouse_moved` from
## changes in that coordinate, so a motionless mouse could take aim back from an
## active gamepad the moment the device family flipped -- which any keyboard press
## does.
##
## The camera here is a real `Camera2D` at the path the Operator actually reads,
## so moving it moves the world mouse coordinate exactly as the real one does.
## The case asserts that coordinate really moved before asserting what it must not
## cause: a negative control that cannot reproduce the input proves nothing.
func _check_camera_motion_does_not_revive_the_mouse(operator: Node, prompt_service: Node) -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	var world := Node2D.new()
	world.name = "World"
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	world.add_child(camera)
	game_root.add_child(world)
	root.add_child(game_root)
	camera.make_current()
	await process_frame

	var aim_controller = operator.get("_aim_controller")
	aim_controller.reset()

	# The gamepad takes aim, and the mouse is parked wherever it is.
	prompt_service.call("_set_device_family", &"gamepad")
	operator.set("global_position", Vector2.ZERO)
	Input.action_press("aim_right", 1.0)
	operator.call("_sample_input_frame")
	operator.call("_resolve_aim")
	Input.action_release("aim_right")
	operator.call("_sample_input_frame")
	operator.call("_resolve_aim")
	assert(
		(operator.get("aim_direction") as Vector2).is_equal_approx(Vector2.RIGHT),
		"the gamepad must own aim before the handoff case means anything"
	)

	# A keyboard press flips the device family. The mouse has not moved; the
	# camera has, which is the whole difference.
	prompt_service.call("_set_device_family", &"keyboard_mouse")
	var before_generation: int = int(prompt_service.call("get_mouse_motion_generation"))
	var first_world_mouse: Vector2 = operator.call("_get_world_mouse_position")
	var observed_world_mouse_motion := false
	for step in 8:
		camera.global_position = Vector2(512.0 * (step + 1), -384.0 * (step + 1))
		operator.set("global_position", camera.global_position)
		await process_frame
		var world_mouse: Vector2 = operator.call("_get_world_mouse_position")
		if first_world_mouse.distance_squared_to(world_mouse) > 0.01:
			observed_world_mouse_motion = true
		operator.call("_sample_input_frame")
		operator.call("_resolve_aim")
		assert(
			not bool((operator.get("_input_frame") as OperatorInputFrame).mouse_moved),
			"camera movement was reported as pointer movement at step %d" % step
		)
	assert(
		observed_world_mouse_motion,
		"this negative control is vacuous unless the camera really moved the world "
			+ "mouse coordinate; it did not"
	)
	assert(
		int(prompt_service.call("get_mouse_motion_generation")) == before_generation,
		"moving the camera must not advance the pointer-motion generation"
	)
	assert(
		(operator.get("aim_direction") as Vector2).is_equal_approx(Vector2.RIGHT),
		"camera movement revived a stale mouse and took aim from the gamepad, aim is %s"
			% operator.get("aim_direction")
	)

	# A real pointer-motion event does hand aim back.
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(96.0, 0.0)
	prompt_service.call("_input", motion)
	assert(
		int(prompt_service.call("get_mouse_motion_generation")) == before_generation + 1,
		"a real mouse-motion event must advance the pointer-motion generation"
	)
	operator.call("_sample_input_frame")
	assert(
		bool((operator.get("_input_frame") as OperatorInputFrame).mouse_moved),
		"a real mouse-motion event must reach the input frame"
	)
	operator.call("_resolve_aim")
	var mouse_vector: Vector2 = (
		(operator.call("_get_world_mouse_position") as Vector2)
		- (operator.get("global_position") as Vector2)
	)
	assert(
		mouse_vector.length_squared() > 0.0001,
		"the handoff case needs a nonzero mouse vector to resolve to"
	)
	assert(
		(operator.get("aim_direction") as Vector2).is_equal_approx(mouse_vector.normalized()),
		"real pointer movement must hand aim back to the mouse, aim is %s"
			% operator.get("aim_direction")
	)

	game_root.queue_free()
	await process_frame
