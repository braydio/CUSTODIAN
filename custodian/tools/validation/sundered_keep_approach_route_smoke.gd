extends SceneTree

const ROUTE_SCENE := preload("res://game/world/routes/sundered_keep/sundered_keep_approach_route.tscn")
const VISTA_ONE := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_vista_one.tscn")
const PRE_LEVEL := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_pre_level.tscn")
const GRAND_VISTA := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_grand_vista.tscn")
const CAUSEWAY := preload("res://game/world/routes/sundered_keep/stages/sundered_keep_causeway_approach.tscn")

const EXPECTED_STAGE_IDS := ["vista_one", "pre_level", "grand_vista", "causeway_approach"]

const CAUSEWAY_EXPECTED_ROOTS := {
	"UnderlayRoot": -300,
	"PlayableRoot": 0,
	"OcclusionRoot": 100,
}

const CAUSEWAY_EXPECTED_MARKERS := {
	"EntrySpawn": Vector2(-80, 430),
	"RevealStart": Vector2(-40, 80),
	"RevealFull": Vector2(0, -250),
	"TraverseStart": Vector2(260, -180),
	"TraverseEnd": Vector2(760, -170),
	"ReturnTopdown": Vector2(720, -80),
}

const CAUSEWAY_EXPECTED_BOUNDARY_SEGMENTS := 13


func _init() -> void:
	var errors: Array[String] = []

	# 1. Base classes
	_check_base_classes(errors)

	# 2. Route registration
	var route := await _check_route(errors)

	# 3. Individual stage instantiation
	var causeway := await _check_causeway_approach(errors)
	await _check_vista_one(errors)
	await _check_pre_level(errors)
	await _check_grand_vista(errors)

	# 4. Stage advancement simulation
	if route != null and causeway != null:
		_check_stage_advancement(route, causeway, errors)

	if errors.is_empty():
		print("[SunderedKeepApproachRouteSmoke] PASS")
		quit(0)
	else:
		for err in errors:
			push_error("[SunderedKeepApproachRouteSmoke] %s" % err)
		_fail("%d checks failed" % errors.size())


func _check_base_classes(errors: Array[String]) -> void:
	var stage_script := load("res://game/world/routes/level_stage.gd")
	if stage_script == null:
		errors.append("level_stage.gd not found")
		return
	if not (stage_script is GDScript):
		errors.append("level_stage.gd is not a GDScript")
		return

	var route_script := load("res://game/world/routes/level_route.gd")
	if route_script == null:
		errors.append("level_route.gd not found")
		return
	if not (route_script is GDScript):
		errors.append("level_route.gd is not a GDScript")


func _check_route(errors: Array[String]) -> Node:
	var route := ROUTE_SCENE.instantiate() as Node
	if route == null:
		errors.append("Could not instantiate SunderedKeepApproachRoute")
		return null
	root.add_child(route)
	await process_frame

	if not (route is SunderedKeepApproachRoute):
		errors.append("Route is not SunderedKeepApproachRoute")
		return route

	var route_obj := route as SunderedKeepApproachRoute
	var registered := route_obj.get("_stage_scenes") as Dictionary
	if registered == null:
		errors.append("Route _stage_scenes is null")
		return route

	for sid in EXPECTED_STAGE_IDS:
		if not registered.has(sid):
			errors.append("Route missing stage: %s" % sid)
		else:
			var scene := registered[sid] as PackedScene
			if scene == null:
				errors.append("Stage %s is not a PackedScene" % sid)

	if route_obj.initial_stage_id != &"vista_one":
		errors.append("initial_stage_id expected vista_one, got %s" % route_obj.initial_stage_id)

	var target_scene := route_obj.final_target_scene as PackedScene
	if target_scene == null:
		errors.append("final_target_scene is null")
	else:
		var wrapper := target_scene.instantiate() as Node
		if wrapper == null:
			errors.append("final_target_scene could not be instantiated")
		else:
			if not wrapper.has_method("configure_connection"):
				errors.append("final_target_scene instance missing configure_connection")
			wrapper.queue_free()

	return route


func _check_causeway_approach(errors: Array[String]) -> Node:
	var scene := CAUSEWAY.instantiate() as Node
	if scene == null:
		errors.append("Could not instantiate SunderedKeepCausewayApproach")
		return null
	root.add_child(scene)
	await process_frame

	if not (scene is SunderedKeepCausewayApproach):
		errors.append("Causeway approach is not SunderedKeepCausewayApproach")
		return scene

	var stage := scene as SunderedKeepCausewayApproach

	if stage.stage_id != &"causeway_approach":
		errors.append("stage_id expected causeway_approach, got %s" % stage.stage_id)
	if stage.next_stage_id != &"front_gate":
		errors.append("next_stage_id expected front_gate, got %s" % stage.next_stage_id)

	for root_path: String in CAUSEWAY_EXPECTED_ROOTS:
		var root_node := scene.get_node_or_null(root_path) as Node2D
		if root_node == null:
			errors.append("Causeway %s missing" % root_path)
			continue
		if root_node.z_index != int(CAUSEWAY_EXPECTED_ROOTS[root_path]):
			errors.append("Causeway %s z_index expected %d, got %d" % [root_path, int(CAUSEWAY_EXPECTED_ROOTS[root_path]), root_node.z_index])
		if root_node.z_as_relative:
			errors.append("Causeway %s should use z_as_relative=false" % root_path)

	var markers := scene.get_node_or_null("Markers")
	if markers == null:
		errors.append("Causeway Markers missing")
	else:
		for marker_name: String in CAUSEWAY_EXPECTED_MARKERS:
			var marker := markers.get_node_or_null(marker_name) as Marker2D
			if marker == null:
				errors.append("Causeway Markers/%s missing" % marker_name)
				continue
			if not _vec2_nearly_equal(marker.position, CAUSEWAY_EXPECTED_MARKERS[marker_name] as Vector2):
				errors.append("Causeway Markers/%s expected %s, got %s" % [marker_name, CAUSEWAY_EXPECTED_MARKERS[marker_name], marker.position])

	var boundary := scene.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary == null:
		errors.append("Causeway Collision/PathBoundaryCollision missing")
	else:
		if boundary.collision_layer != 1 or boundary.collision_mask != 1:
			errors.append("Causeway PathBoundaryCollision should use layer/mask 1")
		var segment_count := 0
		for child in boundary.get_children():
			var shape := child as CollisionShape2D
			if shape == null:
				errors.append("Causeway PathBoundaryCollision child %s is not CollisionShape2D" % child.name)
				continue
			if not (shape.shape is SegmentShape2D):
				errors.append("Causeway %s should use SegmentShape2D, got %s" % [shape.get_path(), shape.shape])
			else:
				segment_count += 1
		if segment_count < CAUSEWAY_EXPECTED_BOUNDARY_SEGMENTS:
			errors.append("Causeway PathBoundaryCollision expected at least %d SegmentShape2D rails, got %d" % [CAUSEWAY_EXPECTED_BOUNDARY_SEGMENTS, segment_count])

	var controller := scene.get_node_or_null("VistaController") as SunderedKeepVistaController
	if controller == null:
		errors.append("Causeway VistaController missing")
	else:
		_check_controller_path(controller, "vista_root_path", NodePath("../UnderlayRoot"), errors)
		_check_controller_path(controller, "fog_underlay_path", NodePath("../UnderlayRoot/FogUnderlay"), errors)
		_check_controller_path(controller, "occlusion_root_path", NodePath("../OcclusionRoot"), errors)
		_check_controller_path(controller, "cliff_occluder_path", NodePath("../OcclusionRoot/CliffOccluder"), errors)
		_check_controller_path(controller, "wall_shadow_occluder_path", NodePath("../OcclusionRoot/WallShadowOccluder"), errors)
		controller.apply_progress(0.45)
		controller.apply_progress(1.0)

	var exit_area := scene.get_node_or_null("ExitToFrontGate") as Area2D
	if exit_area == null:
		errors.append("Causeway ExitToFrontGate missing")
	else:
		if not _vec2_nearly_equal(exit_area.position, Vector2(760, -170)):
			errors.append("Causeway ExitToFrontGate position expected (760, -170), got %s" % exit_area.position)
		if exit_area.get_node_or_null("CollisionShape2D") == null:
			errors.append("Causeway ExitToFrontGate missing CollisionShape2D")

	return scene


func _check_vista_one(errors: Array[String]) -> void:
	var scene := VISTA_ONE.instantiate() as Node
	if scene == null:
		errors.append("Could not instantiate SunderedKeepVistaOne")
		return
	root.add_child(scene)
	await process_frame

	if scene.get("stage_id") != &"vista_one":
		errors.append("VistaOne stage_id expected vista_one, got %s" % scene.get("stage_id"))
	if scene.get("next_stage_id") != &"pre_level":
		errors.append("VistaOne next_stage_id expected pre_level, got %s" % scene.get("next_stage_id"))

	var spawn := scene.get_node_or_null("EntrySpawn") as Marker2D
	if spawn == null:
		errors.append("VistaOne EntrySpawn missing")

	scene.queue_free()


func _check_pre_level(errors: Array[String]) -> void:
	var scene := PRE_LEVEL.instantiate() as Node
	if scene == null:
		errors.append("Could not instantiate SunderedKeepPreLevel")
		return
	root.add_child(scene)
	await process_frame

	if scene.get("stage_id") != &"pre_level":
		errors.append("PreLevel stage_id expected pre_level, got %s" % scene.get("stage_id"))
	if scene.get("next_stage_id") != &"grand_vista":
		errors.append("PreLevel next_stage_id expected grand_vista, got %s" % scene.get("next_stage_id"))

	var spawn := scene.get_node_or_null("EntrySpawn") as Marker2D
	if spawn == null:
		errors.append("PreLevel EntrySpawn missing")

	var exit_trigger := scene.get_node_or_null("ExitToGrandVistaTrigger") as Area2D
	if exit_trigger == null:
		errors.append("PreLevel ExitToGrandVistaTrigger missing")

	scene.queue_free()


func _check_grand_vista(errors: Array[String]) -> void:
	var scene := GRAND_VISTA.instantiate() as Node
	if scene == null:
		errors.append("Could not instantiate SunderedKeepGrandVista")
		return
	root.add_child(scene)
	await process_frame

	if scene.get("stage_id") != &"grand_vista":
		errors.append("GrandVista stage_id expected grand_vista, got %s" % scene.get("stage_id"))
	if scene.get("next_stage_id") != &"causeway_approach":
		errors.append("GrandVista next_stage_id expected causeway_approach, got %s" % scene.get("next_stage_id"))

	var spawn := scene.get_node_or_null("EntrySpawn") as Marker2D
	if spawn == null:
		errors.append("GrandVista EntrySpawn missing")

	scene.queue_free()


func _check_stage_advancement(route_node: Node, causeway_node: Node, errors: Array[String]) -> void:
	var causeway := causeway_node as SunderedKeepCausewayApproach
	if causeway == null:
		return

	# Check that complete_stage() emits the right signal
	var emitted_stage := &""
	var signal_callback := func(id: Variant): emitted_stage = id
	causeway.stage_complete.connect(signal_callback)
	causeway.complete_stage()
	await process_frame
	if emitted_stage == &"":
		errors.append("Causeway complete_stage() did not emit stage_complete signal")
	causeway.stage_complete.disconnect(signal_callback)


func _check_controller_path(controller: SunderedKeepVistaController, property_name: String, expected: NodePath, errors: Array[String]) -> void:
	var actual := controller.get(property_name) as NodePath
	if actual != expected:
		errors.append("Causeway VistaController.%s expected %s, got %s" % [property_name, expected, actual])


func _vec2_nearly_equal(a: Vector2, b: Vector2, epsilon := 0.01) -> bool:
	return absf(a.x - b.x) <= epsilon and absf(a.y - b.y) <= epsilon


func _fail(message: String) -> void:
	push_error("[SunderedKeepApproachRouteSmoke] %s" % message)
	quit(1)
