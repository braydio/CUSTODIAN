extends SceneTree

const CAMERA_SCRIPT := preload("res://game/world/camera.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1000, 500)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node2D.new()
	viewport.add_child(world)
	var subject := Node2D.new()
	subject.global_position = Vector2(1000.0, 400.0)
	world.add_child(subject)
	var camera := CAMERA_SCRIPT.new() as CameraController
	camera.enabled = true
	camera.position_smoothing_enabled = false
	camera.global_position = Vector2.ZERO
	camera.zoom = Vector2.ONE
	world.add_child(camera)
	await process_frame
	await process_frame

	camera.set_presentation_subject_constraint(
		subject,
		Vector4(0.04, 0.06, 0.04, 0.08)
	)
	var constrained := camera.call(
		"_constrain_presentation_position_to_subject",
		Vector2.ZERO
	) as Vector2
	var viewport_size := camera.get_viewport_rect().size
	var half_viewport := viewport_size * 0.5
	var expected := Vector2(
		subject.global_position.x - (viewport_size.x * 0.96 - half_viewport.x) / camera.zoom.x,
		subject.global_position.y - (viewport_size.y * 0.92 - half_viewport.y) / camera.zoom.y
	)
	_assert(
		constrained.is_equal_approx(expected),
		"desired camera center was not constrained to the subject safe frame: %s" % constrained
	)
	var unclamped := camera.call(
		"_clamp_camera_position_to_active_bounds",
		Vector2(1200.0, -50.0)
	) as Vector2
	_assert(
		unclamped.is_equal_approx(Vector2(1200.0, -50.0)),
		"unbounded presentation clamp must preserve its candidate"
	)

	camera.clear_presentation_subject_constraint()
	var state := camera.get_presentation_subject_debug_state()
	_assert(not bool(state.get("operator_inside_safe_frame", true)), "cleared subject constraint still reports active containment")

	viewport.queue_free()
	await process_frame
	if _failures.is_empty():
		print("[CameraPresentationSubjectConstraintSmoke] PASS")
		quit(0)
		return
	for failure in _failures:
		push_error("[CameraPresentationSubjectConstraintSmoke] %s" % failure)
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
