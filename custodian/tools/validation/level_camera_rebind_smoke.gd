extends SceneTree

const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "camera_rebind", &"cinematic", &"Spawn_Main")
	var camera: Camera2D = fixture.camera
	camera.call("set_runtime_map", fixture.procgen)
	camera.call("set_presentation_framing", true)
	camera.global_position = Vector2(71.0, 93.0)
	camera.zoom = Vector2(0.82, 0.82)
	camera.set("target_zoom", Vector2(0.84, 0.84))
	var expected_position := camera.global_position
	var expected_zoom := camera.zoom
	var expected_target_zoom: Vector2 = camera.get("target_zoom") as Vector2
	fixture.ingress.set("_triggered", true)
	fixture.ingress.call("_enter_approach", fixture.actor)
	var level: Node = fixture.loader.call("get_active_level_instance") as Node
	var errors: Array[String] = []
	if level == null:
		errors.append("fixture level did not activate")
	else:
		level.call("return_to_main", fixture.actor)
	if camera.get("runtime_map") != fixture.procgen:
		errors.append("camera did not rebind to the captured origin map")
	if not camera.global_position.is_equal_approx(expected_position):
		errors.append("camera position was not restored")
	if not camera.zoom.is_equal_approx(expected_zoom):
		errors.append("camera zoom was not restored")
	if not (camera.get("target_zoom") as Vector2).is_equal_approx(expected_target_zoom):
		errors.append("camera target zoom was not restored")
	if bool(camera.call("has_presentation_framing")):
		errors.append(
			"runtime-map handoff retained stale presentation framing"
		)
	if camera.get("follow_target") != fixture.actor:
		errors.append("runtime-map handoff did not restore Operator follow")
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[LevelCameraRebindSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[LevelCameraRebindSmoke] %s" % error)
	quit(1)
