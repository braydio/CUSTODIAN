extends SceneTree

const VISTA_SCENE := preload(
	"res://game/world/vistas/sundered_keep/"
	+ "sundered_keep_procgen_vista_presentation.tscn"
)
const TEST_CAMERA := preload(
	"res://tools/validation/fixtures/level_lifecycle_test_camera.gd"
)


class FakeMap:
	extends Node2D

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
	world.add_child(operator)
	var camera := TEST_CAMERA.new()
	camera.name = "Camera2D"
	camera.runtime_map = map_instance
	world.add_child(camera)
	var ingress := Area2D.new()
	ingress.name = "SunderedKeepIngressSite"
	ingress.global_position = Vector2(74, 14) * 32.0
	ingress.set_meta(
		"world_ingress_outward_direction",
		Vector2i.UP
	)
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
		_frontage_level_data()
	)
	await process_frame

	var original_parent := operator.get_parent()
	var original_ingress_position := ingress.global_position
	var first_start := vista.get_node(
		"FirstCameraInfluenceStart"
	) as Marker2D
	var first_apex := vista.get_node("FirstRevealApex") as Marker2D
	var first_return := vista.get_node(
		"FirstCameraReturnComplete"
	) as Marker2D
	var frontage_start := vista.get_node(
		"FrontageRevealStart"
	) as Marker2D
	var frontage_apex := vista.get_node("FrontageApex") as Marker2D
	var gameplay_return := vista.get_node("GameplayReturn") as Marker2D

	_assert_camera_weight(vista, operator, first_start, 0.0, "entry", errors)
	_assert_camera_weight(
		vista,
		operator,
		first_apex,
		1.0,
		"first reveal",
		errors
	)
	if not camera.presentation_framing:
		errors.append("first reveal did not acquire shared-camera framing")
	_assert_camera_weight(
		vista,
		operator,
		first_return,
		1.0,
		"continuous first reveal",
		errors
	)
	_assert_camera_weight(
		vista,
		operator,
		frontage_start,
		1.0,
		"frontage entry",
		errors
	)
	_assert_camera_weight(
		vista,
		operator,
		frontage_apex,
		1.0,
		"fortress camera apex",
		errors
	)
	_assert_camera_weight(
		vista,
		operator,
		gameplay_return,
		0.0,
		"gameplay return",
		errors
	)
	if camera.presentation_framing:
		errors.append("camera framing remained active after frontage return")

	# The continuous production envelope is physically reversible.
	_assert_camera_weight(
		vista,
		operator,
		frontage_apex,
		1.0,
		"reverse fortress camera apex",
		errors
	)
	_assert_camera_weight(
		vista,
		operator,
		frontage_start,
		1.0,
		"reverse frontage entry",
		errors
	)
	_assert_camera_weight(
		vista,
		operator,
		first_apex,
		1.0,
		"reverse first apex",
		errors
	)
	_assert_camera_weight(
		vista,
		operator,
		first_start,
		0.0,
		"reverse world traversal",
		errors
	)

	vista.call(
		"_fit_presentation_to_viewport",
		Vector2(2560.0, 1440.0)
	)
	vista.call("_update_presentation_bounds")
	var state := vista.call("get_world_vista_debug_state") as Dictionary
	var coverage := state.get("viewport_coverage", Vector2.ZERO) as Vector2
	if coverage.x < 2560.0 / 0.78 or coverage.y < 1440.0 / 0.78:
		errors.append("presentation does not cover 2560x1440 cinematic view")
	var storm := vista.get_node(
		"VistaPresentationRoot/VistaArtBundle/ExteriorVistaClip/HorizonPresentation/StormHorizon"
	) as Sprite2D
	var fitted_storm_size := (
		storm.texture.get_size() * storm.scale
		if storm.texture != null
		else Vector2.ZERO
	)
	if storm.region_enabled \
			or fitted_storm_size.x < coverage.x \
			or fitted_storm_size.y < coverage.y:
		errors.append("storm horizon does not cover maximum viewport")
	var void_underlay := vista.get_node(
		"VistaPresentationRoot/VistaArtBundle/ExteriorVistaClip/HorizonPresentation/VoidUnderlay"
	) as Polygon2D
	if void_underlay.polygon.size() < 4:
		errors.append("presentation has no deliberate void underlay")
	var vista_root := vista.get_node("VistaPresentationRoot") as Node2D
	if vista_root.z_as_relative or vista_root.z_index >= 0:
		errors.append("vista presentation root is not absolutely behind gameplay")
	if vista.get_node_or_null(
		"VistaPresentationRoot/VistaArtBundle/ExteriorVistaClip/HorizonPresentation/DistantKeep"
	) != null:
		errors.append("retired DistantKeep duplicate remains in the passive art bundle")
	for path in [
		"VistaPresentationRoot/VistaArtBundle/ExteriorVistaClip/FortressPresentation/OuterWall",
		"VistaPresentationRoot/VistaArtBundle/ExteriorVistaClip/FortressPresentation/CentralCitadel",
	]:
		var sprite := vista.get_node(path) as Sprite2D
		if sprite.texture == null or not vista_root.is_ancestor_of(sprite):
			errors.append("%s is not a behind-gameplay visual layer" % path)
	var clip := vista.get_node("VistaPresentationRoot/VistaArtBundle/ExteriorVistaClip") as Polygon2D
	if clip.clip_children != CanvasItem.CLIP_CHILDREN_ONLY:
		errors.append("vista presentation is not clipped outside gameplay")
	if vista.find_child("ForegroundCliffLip", true, false) != null:
		errors.append("production presentation retained the seam-hiding cliff lip")
	if vista.find_child("GrandVistaCinematicRoot", true, false) != null:
		errors.append("production presentation retained a fixed cinematic stage")
	if _contains_collision(vista):
		errors.append("presentation owns collision instead of procgen")
	if operator.get_parent() != original_parent:
		errors.append("presentation reparented Operator")
	if ingress.global_position != original_ingress_position:
		errors.append("presentation moved the generated terminal ingress")
	if not procgen.visible \
			or procgen.process_mode == Node.PROCESS_MODE_DISABLED:
		errors.append("presentation hid or disabled generated world")
	if state.get("frontage", {}).has("footprint_rect"):
		errors.append("presentation received rectangular floor authority")

	game_root.queue_free()
	if errors.is_empty():
		print("[SunderedKeepWorldVistaSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepWorldVistaSmoke] %s" % error)
	quit(1)


func _frontage_level_data() -> Dictionary:
	var floor_cells: Dictionary = {}
	for y in range(14, 59):
		for x in range(46, 77):
			floor_cells[Vector2i(x, y)] = true
	return {
		"map_size": Vector2i(96, 96),
		"sundered_keep_frontage": {
			"landmark_id": &"sundered_keep_frontage",
			"gate_anchor": Vector2i(74, 14),
			"fortress_outward_direction": Vector2i.UP,
			"floor_cells": floor_cells,
			"camera_semantic_anchors": {
				"frontage_entry": Vector2i(48, 58),
				"first_influence_start": Vector2i(52, 51),
				"first_reveal_apex": Vector2i(56, 44),
				"first_return_complete": Vector2i(60, 37),
				"frontage_reveal_start": Vector2i(65, 30),
				"frontage_apex": Vector2i(69, 23),
				"gameplay_return": Vector2i(72, 17),
				"gate_threshold": Vector2i(74, 14),
			},
			"visual_module_anchors": {
				"fortress_front_anchor": Vector2i(74, 6),
			},
		},
	}


func _assert_camera_weight(
	vista: Node,
	operator: Node2D,
	marker: Marker2D,
	expected: float,
	label: String,
	errors: Array[String]
) -> void:
	operator.global_position = marker.global_position
	vista.call("_process", 1.0)
	var state := vista.call("get_world_vista_debug_state") as Dictionary
	if not is_equal_approx(
		float(state.get("camera_weight", -1.0)),
		expected
	):
		errors.append("%s camera weight did not equal %.1f" % [
			label,
			expected,
		])


func _contains_collision(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D:
		return true
	for child in node.get_children():
		if _contains_collision(child):
			return true
	return false
