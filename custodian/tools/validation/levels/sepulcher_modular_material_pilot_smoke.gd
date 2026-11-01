extends SceneTree

const SCENE_PATH := "res://game/world/levels/authored/dev/sepulcher_modular_material_pilot/sepulcher_modular_material_pilot.tscn"
const LEVEL_SCRIPT := preload("res://game/world/levels/authored/dev/sepulcher_modular_material_pilot/sepulcher_modular_material_pilot_level.gd")
const EXPECTED_CENTERS := [Vector2(256, 256), Vector2(768, 256), Vector2(256, 768), Vector2(768, 768)]
const EXPECTED_TEXTURES := ["native_paving_nw.png", "native_paving_ne.png", "native_paving_sw.png", "native_paving_se.png"]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(SCENE_PATH):
		_fail("standalone scene is missing")
		_report()
		return
	var packed := load(SCENE_PATH) as PackedScene
	var game_root := packed.instantiate() as Node2D if packed != null else null
	if game_root == null or game_root.name != "GameRoot":
		_fail("scene wrapper root must be GameRoot")
		_report()
		return
	root.add_child(game_root)
	await process_frame
	await physics_frame

	for node_path in ["World/Level", "World/Operator", "World/PlayerController", "World/Camera2D", "World/LevelPlaytestBootstrap"]:
		if game_root.get_node_or_null(node_path) == null:
			_fail("required gameplay node missing: %s" % node_path)

	var level := game_root.get_node_or_null("World/Level") as Node2D
	var operator := game_root.get_node_or_null("World/Operator") as CharacterBody2D
	var camera := game_root.get_node_or_null("World/Camera2D") as Camera2D
	if level == null or operator == null or camera == null:
		_report()
		return
	if operator.global_position.distance_to(Vector2(512, 520)) > 0.01:
		_fail("bootstrap did not place the real Operator at the authored spawn")
	if game_root.get_node_or_null("World/DebugVaultStorage") != null:
		_fail("unrelated VaultManager debug prop appeared in the scene")

	var blockout := level.get_node_or_null("BlockoutPresentation") as Node2D
	var quad := level.get_node_or_null("NativeQuadPresentation") as Node2D
	var repeat := level.get_node_or_null("RepeatDiagnosticPresentation") as Node2D
	if blockout == null or quad == null or repeat == null:
		_fail("all three presentation roots must exist")
		_report()
		return
	_check_quad(quad, false)
	_check_quad(repeat, true)
	if quad.get_child_count() != 4 or repeat.get_child_count() != 4:
		_fail("each paving presentation must contain exactly four independent Sprite2D pieces")

	var camera_transform := camera.global_transform
	var camera_zoom := camera.zoom
	var operator_position := operator.global_position
	var collision_snapshot := _collision_snapshot(level)
	var navigation := level.get_node_or_null("NavigationRoot")
	for mode in [LEVEL_SCRIPT.PresentationMode.BLOCKOUT, LEVEL_SCRIPT.PresentationMode.NATIVE_QUAD, LEVEL_SCRIPT.PresentationMode.REPEAT_NW]:
		level.call("set_presentation_mode", mode)
		if blockout.visible != (mode == LEVEL_SCRIPT.PresentationMode.BLOCKOUT):
			_fail("blockout visibility did not match selected mode %s" % mode)
		if quad.visible != (mode == LEVEL_SCRIPT.PresentationMode.NATIVE_QUAD):
			_fail("native quad visibility did not match selected mode %s" % mode)
		if repeat.visible != (mode == LEVEL_SCRIPT.PresentationMode.REPEAT_NW):
			_fail("repeat diagnostic visibility did not match selected mode %s" % mode)
		if operator.global_position != operator_position or camera.global_transform != camera_transform or camera.zoom != camera_zoom:
			_fail("presentation mode switch changed the Operator or gameplay camera")
		if _collision_snapshot(level) != collision_snapshot:
			_fail("presentation mode switch changed collision geometry")
	if navigation == null or navigation.get_child_count() != 0:
		_fail("sandbox NavigationRoot must remain present and empty")
	var collision_body := level.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if collision_body == null or collision_body.get_child_count() != 4:
		_fail("walkable sandbox must have the four fixed outer boundary rails only")
	if level.get("camera_bounds") != Rect2(0, 0, 1024, 768):
		_fail("camera envelope must equal the unchanged 1024x768 sandbox")

	level.call("_unhandled_input", _pressed_key(KEY_1))
	if level.call("get_presentation_mode") != LEVEL_SCRIPT.PresentationMode.BLOCKOUT:
		_fail("1 must select the neutral blockout")
	level.call("_unhandled_input", _pressed_key(KEY_2))
	if level.call("get_presentation_mode") != LEVEL_SCRIPT.PresentationMode.NATIVE_QUAD:
		_fail("2 must select original-detail paving")
	level.call("_unhandled_input", _pressed_key(KEY_3))
	if level.call("get_presentation_mode") != LEVEL_SCRIPT.PresentationMode.REPEAT_NW:
		_fail("3 must select the repeated-NW diagnostic")
	level.call("_unhandled_input", _pressed_key(KEY_TAB))
	if level.call("get_presentation_mode") != LEVEL_SCRIPT.PresentationMode.BLOCKOUT:
		_fail("Tab must toggle between modes 1 and 2")

	# Exercise native Operator movement while keeping the same scene/controller path as gameplay.
	var start := operator.global_position
	Input.action_press("move_right")
	for _frame in 18:
		await physics_frame
	Input.action_release("move_right")
	if operator.global_position.distance_to(start) < 1.0:
		_fail("real Operator did not move under the normal gameplay input action")
	if str(ProjectSettings.get_setting("application/run/main_scene")) == SCENE_PATH:
		_fail("development preview must not replace the production main scene")

	game_root.free()
	_report()


func _check_quad(root_node: Node2D, expect_repeated: bool) -> void:
	for index in root_node.get_child_count():
		var sprite := root_node.get_child(index) as Sprite2D
		if sprite == null:
			_fail("presentation child %d is not Sprite2D" % index)
			continue
		var texture := sprite.texture as Texture2D
		if texture == null or texture.get_width() != 512 or texture.get_height() != 512:
			_fail("crop %s must retain 512x512 texture dimensions" % sprite.name)
		if sprite.position != EXPECTED_CENTERS[index] or sprite.scale != Vector2.ONE or not is_zero_approx(sprite.rotation):
			_fail("crop %s changed its fixed native placement/scale/rotation" % sprite.name)
		if expect_repeated:
			if texture != (root_node.get_child(0) as Sprite2D).texture:
				_fail("NW-repeat diagnostic must reuse the exact NW texture in all four positions")
		elif texture.resource_path.get_file() != EXPECTED_TEXTURES[index]:
			_fail("native quad piece %s references unexpected texture %s" % [sprite.name, texture.resource_path])


func _collision_snapshot(level: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var body := level.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if body == null:
		return result
	for child in body.get_children():
		if child is CollisionShape2D:
			var shape := child as CollisionShape2D
			result.append({"name": str(shape.name), "position": shape.position, "rotation": shape.rotation, "shape": shape.shape.get_instance_id() if shape.shape != null else 0})
	return result


func _pressed_key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	var result := {"schema": "custodian.headless_test.result.v1", "test": "sepulcher_modular_material_pilot", "passed": _failures.is_empty(), "failure_count": _failures.size(), "failures": _failures}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("sepulcher_modular_material_pilot_smoke: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
