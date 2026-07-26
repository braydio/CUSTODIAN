extends SceneTree

const VISTA_SCENE := preload(
	"res://game/world/vistas/sundered_keep/"
	+ "sundered_keep_world_vista.tscn"
)
const TEST_CAMERA := preload(
	"res://tools/validation/fixtures/level_lifecycle_test_camera.gd"
)
const CAMERA_CONTROLLER := preload("res://game/world/camera.gd")


class FakeMap:
	extends Node2D

	func global_to_minimap_tile(point: Vector2) -> Vector2i:
		return Vector2i(floori(point.x / 32.0), floori(point.y / 32.0))

	func get_runtime_tile_size() -> Vector2:
		return Vector2(32.0, 32.0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var procgen := Node2D.new()
	procgen.name = "ProcGenRuntime"
	procgen.process_mode = Node.PROCESS_MODE_ALWAYS
	procgen.add_to_group(&"world_origin_branch")
	world.add_child(procgen)
	var map_instance := FakeMap.new()
	map_instance.name = "GeneratedMap"
	procgen.add_child(map_instance)
	var operator := Node2D.new()
	operator.name = "Operator"
	operator.global_position = Vector2(1536.0, 640.0)
	world.add_child(operator)
	var camera := TEST_CAMERA.new()
	camera.name = "Camera2D"
	camera.runtime_map = map_instance
	world.add_child(camera)
	var route_spy := Node.new()
	route_spy.name = "RouteTraversalManager"
	world.add_child(route_spy)
	var ingress := Area2D.new()
	ingress.name = "SunderedKeepIngressSite"
	ingress.global_position = Vector2(1536.0, 256.0)
	world.add_child(ingress)
	var landmarks := Node2D.new()
	landmarks.name = "WorldLandmarks"
	landmarks.add_to_group(&"world_origin_branch")
	world.add_child(landmarks)
	var vista := VISTA_SCENE.instantiate() as Node2D
	landmarks.add_child(vista)
	vista.call(
		"configure",
		ingress,
		map_instance,
		{"map_size": Vector2i(96, 96)}
	)
	await process_frame

	var original_parent := operator.get_parent()
	var original_ingress_position := ingress.global_position
	var influence_start := vista.get_node("CameraInfluenceStart") as Marker2D
	var apex := vista.get_node("CameraApex") as Marker2D
	var return_complete := vista.get_node("CameraReturnComplete") as Marker2D

	operator.global_position = influence_start.global_position
	vista.call("_process", 0.0)
	_assert_weight(vista, 0.0, "gameplay start", errors)
	operator.global_position = apex.global_position
	vista.call("_process", 0.0)
	_assert_weight(vista, 1.0, "camera apex", errors)
	var state := vista.call("get_world_vista_debug_state") as Dictionary
	var bounds := state.get("presentation_bounds", Rect2()) as Rect2
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		errors.append("Vista did not provide presentation bounds")
	if camera.get_presentation_bounds_override() != bounds:
		errors.append("camera did not receive the Vista bounds override")
	if not camera.presentation_framing:
		errors.append("camera framing was not active at apex")
	if camera.follow_target != vista.get_node("CameraPresentationAnchor"):
		errors.append("camera did not follow the presentation anchor")

	operator.global_position = return_complete.global_position
	vista.call("_process", 0.0)
	_assert_weight(vista, 0.0, "return complete", errors)
	if camera.presentation_framing:
		errors.append("camera framing remained active after return")
	if camera.get_presentation_bounds_override().size != Vector2.ZERO:
		errors.append("camera bounds override remained after return")

	operator.global_position = apex.global_position
	vista.call("_process", 0.0)
	_assert_weight(vista, 1.0, "reverse apex", errors)
	operator.global_position = influence_start.global_position
	vista.call("_process", 0.0)
	_assert_weight(vista, 0.0, "reverse gameplay", errors)

	if operator.get_parent() != original_parent:
		errors.append("Vista reparented Operator")
	if ingress.global_position != original_ingress_position:
		errors.append("Vista moved the real Keep ingress")
	if not procgen.visible or procgen.process_mode == Node.PROCESS_MODE_DISABLED:
		errors.append("Vista hid or disabled ProcGenRuntime")
	if _contains_collision(vista):
		errors.append("Vista owns collision instead of world-map terrain")
	if vista.find_child("GrandVistaCinematicRoot", true, false) != null:
		errors.append("world Vista retained the grand-vista stage")

	var camera_math := CAMERA_CONTROLLER.new()
	var visible_half := camera_math.call(
		"calculate_visible_half_view",
		Vector2(1920.0, 1080.0),
		Vector2(0.78, 0.78)
	) as Vector2
	if visible_half.x <= 960.0 or visible_half.y <= 540.0:
		errors.append("zoomed-out camera bounds do not divide by zoom")
	camera_math.free()

	game_root.queue_free()
	if errors.is_empty():
		print("[SunderedKeepWorldVistaSmoke] PASS")
		quit(0)
		return
	for error: String in errors:
		push_error("[SunderedKeepWorldVistaSmoke] %s" % error)
	quit(1)


func _assert_weight(
	vista: Node,
	expected: float,
	label: String,
	errors: Array[String]
) -> void:
	var state := vista.call("get_world_vista_debug_state") as Dictionary
	if not is_equal_approx(
		float(state.get("camera_weight", -1.0)),
		expected
	):
		errors.append("%s weight did not equal %.1f" % [label, expected])


func _contains_collision(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D:
		return true
	for child: Node in node.get_children():
		if _contains_collision(child):
			return true
	return false
