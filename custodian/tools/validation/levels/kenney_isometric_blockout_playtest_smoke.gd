extends SceneTree

const WRAPPER_PATH := "res://game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest.tscn"
const LEVEL_SCRIPT := preload("res://game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest_level.gd")
const PRESENTATION := preload("res://scenes/debug/kenney_isometric_blockout_presentation.gd")
const PLAYTEST_SCENE_PATH := "res://game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest.tscn"
const EVALUATION_BOUNDS := Rect2(-2600, -4300, 5200, 4650)
const FORBIDDEN_PRESENTATION_CLASSES := [
	"Area2D", "CharacterBody2D", "StaticBody2D", "RigidBody2D", "AnimatableBody2D",
	"CollisionObject2D", "CollisionShape2D", "CollisionPolygon2D", "NavigationRegion2D",
	"NavigationLink2D", "NavigationObstacle2D", "Camera2D", "Camera3D", "Node3D",
]
const FORBIDDEN_AUTHORITY_NAMES := ["controller", "transition", "campaign", "procgen", "collision", "navigation"]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(WRAPPER_PATH):
		_fail("standalone playtest wrapper is missing")
		_report()
		return
	var packed := load(WRAPPER_PATH) as PackedScene
	var game_root := packed.instantiate() as Node2D if packed != null else null
	if game_root == null or game_root.name != "GameRoot":
		_fail("wrapper root must be GameRoot")
		_report()
		return
	root.add_child(game_root)
	await process_frame
	await physics_frame

	for path in [
		"World/Level", "World/Operator", "World/PlayerController",
		"World/Camera2D", "World/LevelPlaytestBootstrap",
	]:
		if game_root.get_node_or_null(path) == null:
			_fail("required wrapper node missing: %s" % path)

	var operator := game_root.get_node_or_null("World/Operator") as CharacterBody2D
	var level := game_root.get_node_or_null("World/Level") as KenneyIsometricBlockoutPlaytestLevel
	if operator == null:
		_fail("Operator must be the real CharacterBody2D scene")
	if level == null:
		_fail("World/Level must use KenneyIsometricBlockoutPlaytestLevel")
	if operator != null and operator.global_position.distance_to(Vector2(0, -2464)) > 0.01:
		_fail("bootstrap did not place Operator at Forum South Spawn_Main")

	if level != null:
		var native_root := level.get_node_or_null("NativePresentation") as Node2D
		var kenney_root := level.get_node_or_null("KenneyPresentation") as Node2D
		var camera := game_root.get_node_or_null("World/Camera2D") as Camera2D
		var body := level.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
		if native_root == null or kenney_root == null:
			_fail("both presentation roots must exist")
		else:
			var before_switch := operator.global_position if operator != null else Vector2.ZERO
			var camera_before := camera.global_transform if camera != null else Transform2D.IDENTITY
			var zoom_before := camera.zoom if camera != null else Vector2.ZERO
			var boundary_before := _boundary_snapshot(body)
			level.set_presentation_mode(LEVEL_SCRIPT.PresentationMode.NATIVE)
			if not native_root.visible or kenney_root.visible:
				_fail("native mode must show only native presentation")
			if operator != null and operator.global_position != before_switch:
				_fail("native switch changed Operator position")
			level.set_presentation_mode(LEVEL_SCRIPT.PresentationMode.KENNEY)
			if native_root.visible or not kenney_root.visible:
				_fail("Kenney mode must show only Kenney presentation")
			if operator != null and operator.global_position != before_switch:
				_fail("Kenney switch changed Operator position")
			_check_keyboard_bindings(level, native_root, kenney_root)
			if camera != null and (camera.global_transform != camera_before or camera.zoom != zoom_before):
				_fail("presentation switching changed gameplay camera transform or zoom")
			if _boundary_snapshot(body) != boundary_before:
				_fail("presentation switching changed neutral envelope collision")
			_check_presentation_tree(native_root)
			_check_presentation_tree(kenney_root)
			if body == null or body.get_child_count() != 4:
				_fail("the only experiment collision must be the four-sided neutral envelope")
			elif not _has_four_valid_boundary_shapes(body):
				_fail("evaluation envelope must have four generated collision rails")
			if level.get("camera_bounds") != EVALUATION_BOUNDS:
				_fail("camera bounds differ from the evaluation envelope")
			var navigation_root := level.get_node_or_null("NavigationRoot")
			if navigation_root == null or navigation_root.get_child_count() != 0:
				_fail("NavigationRoot must exist and remain empty")
			_check_collision_ownership(level, body)
			if operator != null and operator.global_position != Vector2(0, -2464):
				_fail("presentation switching changed the Forum South spawn")

	var textures := PRESENTATION.load_kenney_textures()
	if textures.size() != 16 or not PRESENTATION.selected_textures_valid(textures):
		_fail("all 16 selected Kenney textures must load at 256x512")
	if str(ProjectSettings.get_setting("application/run/main_scene")) == PLAYTEST_SCENE_PATH:
		_fail("standalone playtest wrapper must not become the production main scene")

	game_root.free()
	_report()


func _check_keyboard_bindings(level: Node, native_root: Node2D, kenney_root: Node2D) -> void:
	level.call("_unhandled_input", _pressed_key(KEY_1))
	if not native_root.visible or kenney_root.visible:
		_fail("1 must select native presentation")
	level.call("_unhandled_input", _pressed_key(KEY_2))
	if native_root.visible or not kenney_root.visible:
		_fail("2 must select Kenney presentation")
	level.call("_unhandled_input", _pressed_key(KEY_TAB))
	if not native_root.visible or kenney_root.visible:
		_fail("Tab must toggle Kenney presentation")


func _pressed_key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


func _check_presentation_tree(node: Node) -> void:
	if node.get_class() in FORBIDDEN_PRESENTATION_CLASSES:
		_fail("presentation owns forbidden node %s (%s)" % [node.get_path(), node.get_class()])
	var lower_name := str(node.name).to_lower()
	for forbidden_name in FORBIDDEN_AUTHORITY_NAMES:
		if lower_name.contains(forbidden_name):
			_fail("presentation node name implies forbidden authority: %s" % node.get_path())
	if node.get_script() != null:
		_fail("presentation node owns script authority: %s" % node.get_path())
	if node is Sprite2D and (node as Sprite2D).texture == null:
		_fail("presentation sprite has no texture: %s" % node.get_path())
	for child in node.get_children():
		_check_presentation_tree(child)


func _check_collision_ownership(level: Node, expected_body: StaticBody2D) -> void:
	var collision_objects: Array[CollisionObject2D] = []
	_collect_collision_objects(level, collision_objects)
	if collision_objects.size() != 1 or collision_objects[0] != expected_body:
		_fail("only Collision/PathBoundaryCollision may own experiment collision")


func _collect_collision_objects(node: Node, result: Array[CollisionObject2D]) -> void:
	if node is CollisionObject2D:
		result.append(node as CollisionObject2D)
	for child in node.get_children():
		_collect_collision_objects(child, result)


func _has_four_valid_boundary_shapes(body: StaticBody2D) -> bool:
	for child in body.get_children():
		if not child is CollisionShape2D or (child as CollisionShape2D).shape == null:
			return false
	return true


func _boundary_snapshot(body: StaticBody2D) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	if body == null:
		return snapshot
	for child in body.get_children():
		if not child is CollisionShape2D:
			continue
		var collision := child as CollisionShape2D
		var shape_data := {
			"name": str(collision.name),
			"position": collision.position,
			"rotation": collision.rotation,
			"shape_id": collision.shape.get_instance_id() if collision.shape != null else 0,
		}
		if collision.shape is CapsuleShape2D:
			shape_data["radius"] = (collision.shape as CapsuleShape2D).radius
			shape_data["height"] = (collision.shape as CapsuleShape2D).height
		snapshot.append(shape_data)
	return snapshot


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	var result := {
		"schema": "custodian.headless_test.result.v1",
		"test": "kenney_isometric_blockout_playtest",
		"passed": _failures.is_empty(),
		"failure_count": _failures.size(),
		"failures": _failures,
	}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("kenney_isometric_blockout_playtest_smoke: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
