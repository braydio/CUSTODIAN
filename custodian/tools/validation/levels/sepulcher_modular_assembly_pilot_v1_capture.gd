extends SceneTree

const SCENE_PATH := "res://game/world/levels/authored/dev/sepulcher_modular_assembly_pilot_v1/sepulcher_modular_assembly_pilot_v1.tscn"
const SPAWN := Vector2(512.0, 520.0)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := (args[0] if not args.is_empty() else "user://sepulcher_assembly_v1_capture").simplify_path()
	var absolute_output_dir := ProjectSettings.globalize_path(output_dir)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(absolute_output_dir)
	if mkdir_error != OK:
		_fail("could not create screenshot output directory: %s" % error_string(mkdir_error))
		_report([])
		return
	var packed := load(SCENE_PATH) as PackedScene
	var game_root := packed.instantiate() as Node2D if packed != null else null
	if game_root == null:
		_fail("could not instantiate the playable four-asset GameRoot")
		_report([])
		return
	root.add_child(game_root)
	for _frame in 8:
		await process_frame
	var level := game_root.get_node("World/Level")
	var operator := game_root.get_node("World/Operator") as CharacterBody2D
	var controller := game_root.get_node("World/PlayerController")
	var camera := game_root.get_node("World/Camera2D") as Camera2D
	var preview := operator.get_node("CanonicalOperatorPresentation")
	if not bool(preview.call("is_canonical_enabled")):
		_fail("canonical 128px idle Operator must be the default capture visual")
	var captures := [
		{"name": "01_neutral_canonical", "mode": 1, "damage": false, "ring": false, "wall": false, "rotated": true, "wall_diag": false, "contact": false},
		{"name": "02_rotated_paving_only", "mode": 5, "damage": false, "ring": false, "wall": false, "rotated": true, "wall_diag": false, "contact": false},
		{"name": "03_paving_damage_witness_ring", "mode": 5, "damage": true, "ring": true, "wall": false, "rotated": true, "wall_diag": false, "contact": false},
		{"name": "04_full_wall_operator_contact", "mode": 5, "damage": true, "ring": true, "wall": true, "rotated": true, "wall_diag": false, "contact": true},
		{"name": "05_unrotated_tile_and_wall_join_diagnostic", "mode": 5, "damage": false, "ring": false, "wall": true, "rotated": false, "wall_diag": true, "contact": false},
	]
	var output_paths: Array[String] = []
	var spawn_camera_transform := camera.global_transform
	var fixed_camera_zoom := camera.zoom
	for item in captures:
		level.call("set_presentation_mode", int(item.mode))
		level.call("set_damage_enabled", bool(item.damage))
		level.call("set_ring_enabled", bool(item.ring))
		level.call("set_wall_art_enabled", bool(item.wall))
		level.call("set_rotated_paving_enabled", bool(item.rotated))
		level.call("set_wall_join_diagnostic_enabled", bool(item.wall_diag))
		preview.call("set_canonical_enabled", true)
		preview.call("set_preview_frame", 0)
		operator.velocity = Vector2.ZERO
		operator.global_position = SPAWN
		camera.global_transform = spawn_camera_transform
		camera.zoom = fixed_camera_zoom
		camera.position_smoothing_enabled = false
		for _frame in 4:
			await physics_frame
		if bool(item.contact):
			operator.global_position = Vector2(512.0, 330.0)
			for _frame in 2:
				await physics_frame
			Input.action_press("move_up")
			for _frame in 60:
				await physics_frame
			Input.action_release("move_up")
			operator.velocity = Vector2.ZERO
			if operator.global_position.y < 240.0 or operator.global_position.y > 275.0:
				_fail("wall contact capture did not stop at the real wall boundary; y=%s" % operator.global_position.y)
		else:
			camera.global_transform = spawn_camera_transform
			camera.zoom = fixed_camera_zoom
		camera.set_process(false)
		camera.set_physics_process(false)
		preview.set_process(false)
		controller.set_process(false)
		controller.set_physics_process(false)
		operator.set_physics_process(false)
		var player_transform := operator.global_transform
		var camera_transform := camera.global_transform
		var zoom := camera.zoom
		for _frame in 3:
			await process_frame
		if operator.global_transform != player_transform or camera.global_transform != camera_transform or camera.zoom != zoom:
			_fail("actor/camera moved during frozen screenshot %s" % item.name)
		var root_texture := root.get_texture()
		if root_texture == null:
			_fail("capture renderer has no readable viewport texture; run with a display/rendering driver")
			break
		var image := root_texture.get_image()
		if image.is_empty() or image.get_width() != 1280 or image.get_height() != 720:
			_fail("capture %s is not a 1280x720 gameplay frame" % item.name)
			continue
		var output_path := absolute_output_dir.path_join("%s.png" % item.name)
		var save_error := image.save_png(output_path)
		if save_error != OK:
			_fail("could not save %s: %s" % [item.name, error_string(save_error)])
		else:
			output_paths.append(output_path)
		operator.set_physics_process(true)
		controller.set_process(true)
		controller.set_physics_process(true)
		preview.set_process(true)
		camera.set_process(true)
		camera.set_physics_process(true)
		camera.global_transform = spawn_camera_transform
		camera.zoom = fixed_camera_zoom
	operator.global_position = SPAWN
	game_root.queue_free()
	await process_frame
	print("SEPULCHER_ASSEMBLY_CAPTURE_OUTPUTS:%s" % JSON.stringify(output_paths))
	_report(output_paths)


func _fail(message: String) -> void:
	_failures.append(message)


func _report(outputs: Array[String]) -> void:
	var result := {
		"schema": "custodian.headless_test.result.v1",
		"test": "sepulcher_modular_assembly_pilot_v1_capture",
		"passed": _failures.is_empty(),
		"failure_count": _failures.size(),
		"failures": _failures,
		"outputs": outputs,
	}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("sepulcher_modular_assembly_pilot_v1_capture: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
