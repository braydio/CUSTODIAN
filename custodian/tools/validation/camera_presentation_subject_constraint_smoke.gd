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
	camera.position_smoothing_enabled = true
	camera.global_position = Vector2.ZERO
	camera.zoom = Vector2.ONE
	world.add_child(camera)
	await process_frame
	await process_frame

	camera.set_presentation_subject_constraint(
		subject,
		Vector4(0.04, 0.06, 0.04, 0.08)
	)
	camera.call("_keep_presentation_subject_in_view")
	await process_frame
	var state := camera.get_presentation_subject_debug_state()
	var normalized: Vector2 = state.get(
		"operator_screen_normalized",
		Vector2(-1.0, -1.0)
	)
	_assert(bool(state.get("operator_inside_safe_frame", false)), "subject escaped the final safe frame: %s" % state)
	_assert(normalized.x >= 0.04 - 0.001 and normalized.x <= 0.96 + 0.001, "subject x was not constrained to 4%-96%")
	_assert(normalized.y >= 0.06 - 0.001 and normalized.y <= 0.92 + 0.001, "subject y was not constrained to 6%-92%")
	_assert(float(state.get("operator_screen_edge_distance_px", 0.0)) >= 40.0 - 0.5, "edge-distance telemetry does not match the safe frame")

	camera.clear_presentation_subject_constraint()
	state = camera.get_presentation_subject_debug_state()
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
