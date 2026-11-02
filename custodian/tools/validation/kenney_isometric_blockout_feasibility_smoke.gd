extends SceneTree

const SCENE_PATH := "res://scenes/debug/kenney_isometric_blockout_feasibility.tscn"
const SCENE_SCRIPT := preload("res://scenes/debug/kenney_isometric_blockout_feasibility.gd")
const FORBIDDEN_CLASSES := [
	"Area2D", "CharacterBody2D", "StaticBody2D", "RigidBody2D", "AnimatableBody2D",
	"CollisionObject2D", "CollisionShape2D", "CollisionPolygon2D",
	"NavigationRegion2D", "NavigationLink2D", "NavigationObstacle2D",
]
const VISUAL_CLASSES := ["Node2D", "Sprite2D", "Polygon2D", "Line2D", "Label"]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_constants()
	if not ResourceLoader.exists(SCENE_PATH):
		_fail("debug scene is missing")
		_report()
		return
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("debug scene could not be loaded")
		_report()
		return
	var experiment := packed.instantiate() as Node2D
	if experiment == null:
		_fail("debug scene root is not Node2D")
		_report()
		return
	root.add_child(experiment)
	await process_frame
	_check_scene(experiment)
	var native_root := experiment.get_node("EvaluationViewport/ComparisonViewport/NativePresentation")
	var kenney_root := experiment.get_node("EvaluationViewport/ComparisonViewport/KenneyPresentation")
	experiment.call("set_presentation_mode", SCENE_SCRIPT.PresentationMode.NATIVE)
	if not native_root.visible or kenney_root.visible:
		_fail("native mode does not show exactly one presentation")
	experiment.call("set_presentation_mode", SCENE_SCRIPT.PresentationMode.KENNEY)
	if native_root.visible or not kenney_root.visible:
		_fail("Kenney mode does not show exactly one presentation")
	if experiment.call("parity_snapshot") != _expected_snapshot():
		_fail("A/B parity snapshot differs from packet contract")
	if int(experiment.call("selected_runtime_asset_count")) != 16:
		_fail("expected all 16 selected experimental runtime assets")
	if not bool(experiment.call("selected_textures_valid")):
		_fail("one or more selected Kenney textures did not load at source dimensions")
	if str(ProjectSettings.get_setting("application/run/main_scene")) == SCENE_PATH:
		_fail("debug experiment was installed as the production main scene")
	_check_presentation_tree(native_root)
	_check_presentation_tree(kenney_root)
	experiment.free()
	_report()


func _check_constants() -> void:
	if SCENE_SCRIPT.CELL_SIZE != 32:
		_fail("cell size must remain 32")
	if SCENE_SCRIPT.ANCHORS != {
		&"spawn_south_reach": Vector2(-6, 162),
		&"forum_south": Vector2(0, -2464),
		&"adjudication_dais": Vector2(0, -3136),
	}:
		_fail("named spatial anchors differ from packet")
	if SCENE_SCRIPT.SAMPLE_REGIONS != {
		&"north_processional": Rect2(-512, -2400, 1024, 1152),
		&"ashen_forum": Rect2(-1280, -4032, 2560, 1792),
	}:
		_fail("sample region bounds differ from packet")
	if SCENE_SCRIPT.VIEW_SIZE != Vector2i(1280, 720):
		_fail("evaluation viewport must be 1280x720")
	if SCENE_SCRIPT.CAPTURE_POS != Vector2(0, -2000):
		_fail("capture position differs from packet")
	if SCENE_SCRIPT.CAPTURE_ZOOM != Vector2(0.30, 0.30):
		_fail("capture zoom differs from packet")


func _expected_snapshot() -> Dictionary:
	return {
		"cell_size": 32,
		"anchors": {
			&"spawn_south_reach": Vector2(-6, 162),
			&"forum_south": Vector2(0, -2464),
			&"adjudication_dais": Vector2(0, -3136),
		},
		"regions": {
			&"north_processional": Rect2(-512, -2400, 1024, 1152),
			&"ashen_forum": Rect2(-1280, -4032, 2560, 1792),
		},
		"viewport": Vector2i(1280, 720),
		"camera_position": Vector2(0, -2000),
		"camera_zoom": Vector2(0.30, 0.30),
	}


func _check_scene(experiment: Node2D) -> void:
	for required in [
		"EvaluationViewport/ComparisonViewport/SharedSpatialSample/AnchorMarkers",
		"EvaluationViewport/ComparisonViewport/NativePresentation",
		"EvaluationViewport/ComparisonViewport/KenneyPresentation",
		"EvaluationViewport/ComparisonViewport/Camera2D",
	]:
		if experiment.get_node_or_null(required) == null:
			_fail("required experiment node missing: %s" % required)
	var viewport := experiment.get_node("EvaluationViewport/ComparisonViewport") as SubViewport
	if viewport == null or viewport.size != Vector2i(1280, 720):
		_fail("offscreen evaluation viewport must be exactly 1280x720")
	var camera := experiment.get_node("EvaluationViewport/ComparisonViewport/Camera2D") as Camera2D
	if camera == null or camera.position != Vector2(0, -2000) or camera.zoom != Vector2(0.30, 0.30):
		_fail("scene camera does not use the shared capture transform")


func _check_presentation_tree(node: Node) -> void:
	if node.get_class() in FORBIDDEN_CLASSES:
		_fail("presentation owns forbidden authority node %s (%s)" % [node.get_path(), node.get_class()])
	if node.get_class() not in VISUAL_CLASSES:
		_fail("presentation contains non-visual node %s (%s)" % [node.get_path(), node.get_class()])
	if node is Sprite2D and (node as Sprite2D).texture == null:
		_fail("presentation sprite has no texture: %s" % node.get_path())
	for child in node.get_children():
		_check_presentation_tree(child)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	var result := {
		"schema": "custodian.headless_test.result.v1",
		"test": "kenney_isometric_blockout_feasibility",
		"passed": _failures.is_empty(),
		"failure_count": _failures.size(),
		"failures": _failures,
	}
	print("CUSTODIAN_TEST_RESULT_JSON:%s" % JSON.stringify(result))
	print("kenney_isometric_blockout_feasibility_smoke: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
