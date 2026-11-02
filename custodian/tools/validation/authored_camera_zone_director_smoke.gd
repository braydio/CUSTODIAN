extends SceneTree

class TestCamera extends Camera2D:
	var framing_active := false
	var requested_zoom := Vector2.ONE
	func set_presentation_framing_transition(offset: Vector2, value: Vector2, _sec: float) -> void:
		framing_active = true
		requested_zoom = value
	func set_presentation_subject_constraint(_subject: Node2D, _inset: Vector4) -> void:
		pass
	func clear_presentation_framing(_restore := true) -> void:
		framing_active = false
		requested_zoom = Vector2.ONE


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	var subject := Node2D.new()
	root.add_child(subject)
	var camera := TestCamera.new()
	root.add_child(camera)
	var director := AuthoredCameraZoneDirector2D.new()
	director.subject_path = subject.get_path()
	director.camera_path = camera.get_path()
	root.add_child(director)
	for record in [["landing", Rect2(-10, 30, 20, 10), 0.62, 10, false], ["upper", Rect2(-10, 20, 20, 10), 0.68, 20, false], ["deep", Rect2(-10, 10, 20, 10), 0.76, 30, false], ["approach", Rect2(-10, 0, 20, 10), 0.82, 40, false], ["chapel", Rect2(-10, -10, 20, 10), 1.0, 100, true]]:
		var zone := AuthoredCameraZone2D.new()
		zone.profile_id = StringName(record[0])
		zone.region = record[1]
		zone.framing_zoom = Vector2(record[2], record[2])
		zone.priority = record[3]
		zone.release_to_gameplay = record[4]
		director.add_child(zone)
	for probe in [[Vector2(0, 35), 0.62], [Vector2(0, 25), 0.68], [Vector2(0, 15), 0.76], [Vector2(0, 5), 0.82]]:
		subject.position = probe[0]
		director.refresh_now()
		if not is_equal_approx(camera.requested_zoom.x, probe[1]):
			push_error("[AuthoredCameraZoneDirectorSmoke] wrong zone zoom")
			quit(1)
			return
	subject.position = Vector2(0, -5)
	director.refresh_now()
	if camera.framing_active or root.find_children("*", "Camera2D", true, false).size() != 1:
		push_error("[AuthoredCameraZoneDirectorSmoke] gameplay release or camera ownership failed")
		quit(1)
		return
	print("[AuthoredCameraZoneDirectorSmoke] PASS")
	quit(0)
