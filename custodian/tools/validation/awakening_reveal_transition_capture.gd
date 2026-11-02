extends SceneTree

## Captures the live camera transition from normal Awakening framing.
const Layout := preload("res://game/world/awakening/awakening_layout.gd")
const SCENE := preload("res://scenes/awakening_first_return.tscn")
const OUTPUT := "res://../reports/awakening_reveal_review"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var label := "current"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			label = argument.trim_prefix("--label=")
	var directory := ProjectSettings.globalize_path(OUTPUT).path_join(label)
	DirAccess.make_dir_recursive_absolute(directory)
	var samples: Array[Dictionary] = []
	for zone_id in [&"zone05_dust_lung", &"zone07_gate_of_dust", &"zone08_custodian_approach"]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1920, 1080)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var scene := SCENE.instantiate() as Node2D
		viewport.add_child(scene)
		var operator := scene.get_node("World/Operator") as Node2D
		var camera := scene.get_node("World/Camera2D") as Camera2D
		camera.operator_ref = operator
		camera.follow_target = operator
		var reveal: Dictionary = Layout.CAMERA_REVEALS[zone_id]
		var zone: Dictionary = Layout.zone_by_id(zone_id)
		var trigger := scene.get_node("World/AwakeningZones/%s/Triggers/CameraReveal" % String(zone["node"])) as Area2D
		trigger.monitoring = false
		operator.global_position = reveal["trigger"]
		camera.snap_to_player_spawn(operator.global_position)
		for frame in 30:
			await physics_frame
		await _save(viewport, directory, String(zone_id), "normal", camera, samples)
		scene.play_camera_reveal(zone_id)
		var transition := float(reveal["transition_sec"])
		await create_timer(transition * 0.5).timeout
		await _save(viewport, directory, String(zone_id), "halfway", camera, samples)
		await create_timer(transition * 0.5 + 0.1).timeout
		await _save(viewport, directory, String(zone_id), "hold", camera, samples)
		await create_timer(float(reveal["hold_sec"]) + 0.6).timeout
		await _save(viewport, directory, String(zone_id), "released", camera, samples)
		viewport.process_mode = Node.PROCESS_MODE_DISABLED
	var path := directory.path_join("zoom_samples.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(samples, "  ") + "\n")
	file.close()
	print("Awakening reveal review: " + path)
	quit(0)


func _save(viewport: SubViewport, directory: String, zone: String, phase: String, camera: Camera2D, samples: Array[Dictionary]) -> void:
	for frame in 2:
		RenderingServer.force_draw(false)
		await process_frame
	var path := directory.path_join("%s_%s.png" % [zone, phase])
	if viewport.get_texture().get_image().save_png(path) != OK:
		push_error("Reveal capture failed: " + path)
		quit(1)
	samples.append({"zone": zone, "phase": phase, "zoom": camera.zoom.x, "target_zoom": camera.target_zoom.x})
