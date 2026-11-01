extends SceneTree

const SCENE_PATH := "res://game/world/levels/authored/dev/sepulcher_material_operator_v2/sepulcher_material_operator_v2.tscn"
const FIXED_PLAYER_POSITION := Vector2(512.0, 520.0)
const CASES := [
	{"name": "legacy_operator_courtyard", "floor": 2, "canonical": false},
	{"name": "canonical_operator_courtyard", "floor": 2, "canonical": true},
	{"name": "canonical_operator_quiet_floor", "floor": 4, "canonical": true},
	{"name": "canonical_operator_repeat_diagnostic", "floor": 3, "canonical": true},
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := (args[0] if not args.is_empty() else "user://sepulcher_v2_capture").simplify_path()
	var absolute_output_dir := ProjectSettings.globalize_path(output_dir)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(absolute_output_dir)
	if mkdir_error != OK:
		_fail("could not create screenshot output directory: %s" % error_string(mkdir_error))
		_report()
		return
	var packed := load(SCENE_PATH) as PackedScene
	var game_root := packed.instantiate() as Node2D if packed != null else null
	if game_root == null:
		_fail("could not instantiate the V2 gameplay scene")
		_report()
		return
	root.add_child(game_root)
	for _frame in 6:
		await process_frame
	var level := game_root.get_node("World/Level")
	var operator := game_root.get_node("World/Operator") as CharacterBody2D
	var camera := game_root.get_node("World/Camera2D") as Camera2D
	var preview := operator.get_node("CanonicalOperatorPresentation")
	operator.global_position = FIXED_PLAYER_POSITION
	operator.velocity = Vector2.ZERO
	for _frame in 2:
		await process_frame
	if not is_equal_approx(camera.zoom.x, 1.25) or not is_equal_approx(camera.zoom.y, 1.25):
		_fail("dev Camera2D did not settle to the scoped 1.25 zoom")
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.position_smoothing_enabled = false
	var fixed_camera_transform := camera.global_transform
	var fixed_camera_zoom := camera.zoom
	preview.set_process(false)
	preview.call("set_preview_frame", 0)
	operator.set_physics_process(false)
	var output_paths: Array[String] = []
	for item in CASES:
		level.call("set_presentation_mode", int(item["floor"]))
		preview.call("set_canonical_enabled", bool(item["canonical"]))
		operator.global_position = FIXED_PLAYER_POSITION
		camera.global_transform = fixed_camera_transform
		camera.zoom = fixed_camera_zoom
		for _frame in 3:
			await process_frame
		if operator.global_position != FIXED_PLAYER_POSITION:
			_fail("Operator position changed during capture %s" % item["name"])
		if camera.global_transform != fixed_camera_transform or camera.zoom != fixed_camera_zoom:
			_fail("camera settings changed during capture %s" % item["name"])
		var image := root.get_texture().get_image()
		if image.is_empty() or image.get_width() != 1280 or image.get_height() != 720:
			_fail("capture %s did not produce a 1280x720 gameplay viewport" % item["name"])
			continue
		var output_path := absolute_output_dir.path_join("%s.png" % item["name"])
		var save_error := image.save_png(output_path)
		if save_error != OK:
			_fail("could not save %s: %s" % [item["name"], error_string(save_error)])
		else:
			output_paths.append(output_path)
	game_root.free()
	print("SEPULCHER_V2_CAPTURE_OUTPUTS:%s" % JSON.stringify(output_paths))
	_report()


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	var result := {
		"schema": "custodian.headless_test.result.v1",
		"test": "sepulcher_material_operator_v2_capture",
		"passed": _failures.is_empty(),
		"failure_count": _failures.size(),
		"failures": _failures,
	}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("sepulcher_material_operator_v2_capture: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
