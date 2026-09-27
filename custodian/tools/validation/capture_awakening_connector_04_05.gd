extends SceneTree

const SCENE := preload("res://scenes/awakening_first_return.tscn")
const OUTPUT := "res://../reports/awakening_connector_04_05"

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var instance := SCENE.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	var operator := instance.get_node("World/Operator") as Node2D
	var camera := instance.get_node("World/Camera2D") as Camera2D
	var controller := instance as Node
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.follow_enabled = false
	camera.zoom = Vector2(0.84, 0.84)
	camera.make_current()
	var captures := {
		"connector_C.png": Vector2(0, -2608),
		"connector_B.png": Vector2(352, -2496),
		"connector_A.png": Vector2(704, -2352),
		"connector_overview.png": Vector2(352, -2464),
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for filename in captures:
		var target: Vector2 = captures[filename]
		operator.global_position = target
		camera.global_position = target
		if filename == "connector_overview.png":
			camera.zoom = Vector2(0.78, 0.78)
		else:
			camera.zoom = Vector2(1.0, 1.0)
		controller.call("_update_zone_art_visibility")
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_viewport().get_texture().get_image()
		var path := OUTPUT.path_join(filename)
		var error := image.save_png(ProjectSettings.globalize_path(path))
		if error != OK:
			push_error("failed to save %s: %s" % [path, error])
		else:
			print("CAPTURE %s %s" % [path, str(image.get_size())])
	quit()
