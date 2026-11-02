extends SceneTree

const SCENE_PATH := "res://game/world/levels/authored/dev/sepulcher_modular_material_pilot/sepulcher_modular_material_pilot.tscn"
const FIXED_PLAYER_POSITION := Vector2(512.0, 520.0)
const MODE_OUTPUTS := {
	1: "sepulcher_mode_1_blockout.png",
	2: "sepulcher_mode_2_native_quad.png",
	3: "sepulcher_mode_3_repeat_nw_diagnostic.png",
}

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := (args[0] if not args.is_empty() else "user://sepulcher_paving_capture").simplify_path()
	var absolute_output_dir := ProjectSettings.globalize_path(output_dir)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(absolute_output_dir)
	if mkdir_error != OK:
		_fail("could not create screenshot output directory: %s" % error_string(mkdir_error))
		_report()
		return
	var packed := load(SCENE_PATH) as PackedScene
	var game_root := packed.instantiate() as Node2D if packed != null else null
	if game_root == null:
		_fail("could not instantiate standalone playtest scene")
		_report()
		return
	root.add_child(game_root)
	for _frame in 90:
		await process_frame
	var level := game_root.get_node("World/Level")
	var operator := game_root.get_node("World/Operator") as CharacterBody2D
	var camera := game_root.get_node("World/Camera2D") as Camera2D
	operator.global_position = FIXED_PLAYER_POSITION
	for _frame in 45:
		await process_frame
	var camera_transform := camera.global_transform
	var camera_zoom := camera.zoom
	var camera_offset := camera.offset
	camera.set_process(false)
	camera.set_physics_process(false)
	var outputs: Array[String] = []
	for mode in [1, 2, 3]:
		operator.global_position = FIXED_PLAYER_POSITION
		camera.global_transform = camera_transform
		camera.zoom = camera_zoom
		camera.offset = camera_offset
		level.call("set_presentation_mode", mode)
		for _frame in 2:
			await process_frame
		var capture := root.get_texture().get_image()
		if capture.is_empty():
			_fail("Godot viewport returned an empty image for mode %d" % mode)
			continue
		var output_path := absolute_output_dir.path_join(MODE_OUTPUTS[mode])
		var save_error := capture.save_png(output_path)
		if save_error != OK:
			_fail("could not save mode %d screenshot: %s" % [mode, error_string(save_error)])
		else:
			outputs.append(output_path)
	game_root.free()
	print("SEPULCHER_CAPTURE_OUTPUTS:%s" % JSON.stringify(outputs))
	_report()


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	var result := {"schema": "custodian.headless_test.result.v1", "test": "sepulcher_modular_material_pilot_capture", "passed": _failures.is_empty(), "failure_count": _failures.size(), "failures": _failures}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("sepulcher_modular_material_pilot_capture: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
