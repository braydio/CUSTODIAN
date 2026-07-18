extends SceneTree

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")
const EXPECTED_BOUNDARY_SEGMENTS := 74

const EXPECTED_ROOTS := {
	"UnderlayRoot": -300,
	"VistaRoot": -200,
	"GrandVistaRoot": -220,
	"PlayableRoot": 0,
	"OcclusionRoot": 100,
}

const EXPECTED_SPRITE_RECTS := {
	"UnderlayRoot/ApproachOceanVoidUnderlay": Rect2(Vector2(-1536, -1236), Vector2(3392, 2718)),
	"UnderlayRoot/ApproachCliffSpiresUnderlay": Rect2(Vector2(-1536, -1236), Vector2(3392, 2718)),
	"UnderlayRoot/ApproachRouteContactShadow": Rect2(Vector2(-620, -480), Vector2(2048, 1706)),
	"VistaRoot/ApproachFirstVistaHorizon": Rect2(Vector2(-1000, -980), Vector2(2600, 1460)),
	"VistaRoot/ApproachFirstVistaFogVeil": Rect2(Vector2(-1000, -360), Vector2(2600, 720)),
	"GrandVistaRoot/GrandVistaPanorama": Rect2(Vector2(-1280, -920), Vector2(2560, 1440)),
	"GrandVistaRoot/GrandVistaOceanSprayOverlay": Rect2(Vector2(-1280, -160), Vector2(2560, 720)),
	"GrandVistaRoot/GrandVistaFogOverlay": Rect2(Vector2(-1280, -520), Vector2(2560, 480)),
	"GrandVistaRoot/GrandVistaShadowVignette": Rect2(Vector2(-1280, -920), Vector2(2560, 1440)),
	"GrandVistaRoot/GrandVistaForegroundParapet": Rect2(Vector2(-1280, 260), Vector2(2560, 360)),
	"GrandVistaRoot/GrandVistaGlueRoot/GrandVistaHorizonSeamFog": Rect2(Vector2(-1280, -460), Vector2(2560, 320)),
	"GrandVistaRoot/GrandVistaGlueRoot/GrandVistaPathContactShadow": Rect2(Vector2(-1280, -160), Vector2(2560, 720)),
	"GrandVistaRoot/GrandVistaGlueRoot/GrandVistaEdgeSprayWrap": Rect2(Vector2(-1280, -160), Vector2(2560, 720)),
	"GrandVistaRoot/GrandVistaGlueRoot/GrandVistaForegroundEdgeMask": Rect2(Vector2(-1280, 220), Vector2(2560, 420)),
	"PlayableRoot/ApproachRouteMaster": Rect2(Vector2(-620, -480), Vector2(2048, 1706)),
	"OcclusionRoot/ApproachEdgeMistWrap": Rect2(Vector2(-620, -480), Vector2(2048, 1706)),
	"OcclusionRoot/ApproachFogStrip01": Rect2(Vector2(-880, -250), Vector2(1500, 520)),
	"OcclusionRoot/ApproachFogStrip02": Rect2(Vector2(-260, -240), Vector2(1500, 520)),
	"OcclusionRoot/ApproachFogStrip03": Rect2(Vector2(320, -230), Vector2(1500, 520)),
	"OcclusionRoot/ApproachFinalGateShadowVeil": Rect2(Vector2(-1000, -340), Vector2(2600, 900)),
}

const EXPECTED_SPRITE_Z := {
	"PlayableRoot/ApproachRouteMaster": 0,
	"OcclusionRoot/ApproachEdgeMistWrap": 5,
	"OcclusionRoot/ApproachFinalGateShadowVeil": 20,
}

const FORBIDDEN_LEGACY_PLAYABLE := [
	"MainlandApproachShadow",
	"OverlookLedgeShadow",
	"LateralTraverseShadow",
	"MainlandApproachPath",
	"HillClimbPath",
	"OverlookLedge",
	"LateralTraversePath",
	"FortressWallMass",
]

const EXPECTED_MARKERS := {
	"EntrySpawn": Vector2(45, 610),
	"RevealStart": Vector2(-40, 300),
	"RevealFull": Vector2(-150, 5),
	"MidGameplayStart": Vector2(50, -55),
	"SecondVistaStart": Vector2(300, -125),
	"SecondVistaFull": Vector2(590, -125),
	"SecondVistaEnd": Vector2(830, -125),
	"TraverseEnd": Vector2(915, -125),
	"ReturnTopdown": Vector2(980, -125),
}


func _init() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	world.add_child(camera)

	var scene := APPROACH_SCENE.instantiate() as Node2D
	if scene == null:
		_fail("Could not instantiate SunderedKeepApproach")
		return
	root.add_child(scene)
	await process_frame
	await process_frame

	var errors: Array[String] = []

	for root_path: String in EXPECTED_ROOTS:
		var root_node := scene.get_node_or_null(root_path) as Node2D
		if root_node == null:
			errors.append("%s missing" % root_path)
			continue
		if root_node.z_index != int(EXPECTED_ROOTS[root_path]):
			errors.append("%s z_index expected %d, got %d" % [root_path, int(EXPECTED_ROOTS[root_path]), root_node.z_index])
		if root_node.z_as_relative:
			errors.append("%s should use z_as_relative=false" % root_path)

	if scene.get_node_or_null("DistantKeepProxy") != null or scene.get_node_or_null("VistaUnderlay/DistantKeepProxy") != null:
		errors.append("Simplified DistantKeepProxy must not remain in the production runtime scene")
	if scene.get_node_or_null("PathSprites") != null:
		errors.append("Simplified PathSprites root must not remain in the production runtime scene")
	if scene.get_node_or_null("Gameplay/WalkableAreas") != null:
		errors.append("Metadata-only Gameplay/WalkableAreas proxy must not remain in the production runtime scene")

	var playable_root := scene.get_node_or_null("PlayableRoot")
	if playable_root != null:
		for node_name: String in FORBIDDEN_LEGACY_PLAYABLE:
			if playable_root.get_node_or_null(node_name) != null:
				errors.append("PlayableRoot/%s should not render while USE_ROUTE_MASTER is true" % node_name)

	_check_backdrop_coverage(scene, errors)

	for node_path: String in EXPECTED_SPRITE_RECTS:
		var sprite := scene.get_node_or_null(node_path) as Sprite2D
		if sprite == null:
			errors.append("%s missing or not Sprite2D" % node_path)
			continue
		if sprite.texture == null:
			errors.append("%s has null texture" % node_path)
			continue
		if sprite.centered:
			errors.append("%s should use centered=false" % node_path)
		if not sprite.z_as_relative:
			errors.append("%s should inherit root z ordering with z_as_relative=true" % node_path)
		if EXPECTED_SPRITE_Z.has(node_path) and sprite.z_index != int(EXPECTED_SPRITE_Z[node_path]):
			errors.append("%s z_index expected %d, got %d" % [node_path, int(EXPECTED_SPRITE_Z[node_path]), sprite.z_index])
		_check_sprite_rect(node_path, sprite, EXPECTED_SPRITE_RECTS[node_path] as Rect2, errors)

	var vista_root := scene.get_node_or_null("VistaRoot") as CanvasItem
	if vista_root == null or vista_root.modulate.a > 0.01:
		errors.append("VistaRoot should start hidden; alpha=%s" % (vista_root.modulate.a if vista_root else "missing"))
	var grand_vista_root := scene.get_node_or_null("GrandVistaRoot") as CanvasItem
	if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
		errors.append("GrandVistaRoot should start hidden; alpha=%s" % (grand_vista_root.modulate.a if grand_vista_root else "missing"))
	if grand_vista_root != null:
		var glue_root := scene.get_node_or_null("GrandVistaRoot/GrandVistaGlueRoot") as Node2D
		if glue_root == null:
			errors.append("GrandVistaRoot/GrandVistaGlueRoot missing")
		elif not glue_root.z_as_relative:
			errors.append("GrandVistaRoot/GrandVistaGlueRoot should inherit GrandVistaRoot z ordering")
		_collect_collision_nodes(grand_vista_root, "GrandVistaRoot must be visual-only", errors)
	var occlusion_root := scene.get_node_or_null("OcclusionRoot") as CanvasItem
	if occlusion_root == null or occlusion_root.modulate.a < 0.99:
		errors.append("OcclusionRoot should stay visible for edge mist/fog; alpha=%s" % (occlusion_root.modulate.a if occlusion_root else "missing"))
	var final_gate_veil := scene.get_node_or_null("OcclusionRoot/ApproachFinalGateShadowVeil") as CanvasItem
	if final_gate_veil == null or final_gate_veil.modulate.a > 0.01:
		errors.append("ApproachFinalGateShadowVeil should start hidden; alpha=%s" % (final_gate_veil.modulate.a if final_gate_veil else "missing"))

	var markers := scene.get_node_or_null("Markers")
	if markers == null:
		errors.append("Markers missing")
	else:
		for marker_name: String in EXPECTED_MARKERS:
			var marker := markers.get_node_or_null(marker_name) as Marker2D
			if marker == null:
				errors.append("Markers/%s missing" % marker_name)
				continue
			if not _vec2_nearly_equal(marker.position, EXPECTED_MARKERS[marker_name] as Vector2):
				errors.append("Markers/%s expected %s, got %s" % [marker_name, EXPECTED_MARKERS[marker_name], marker.position])

	var boundary := scene.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary == null:
		errors.append("Collision/PathBoundaryCollision missing")
	else:
		if boundary.collision_layer != 1 or boundary.collision_mask != 1:
			errors.append("PathBoundaryCollision should use layer/mask 1")
		var segment_count := 0
		for child in boundary.get_children():
			var shape := child as CollisionShape2D
			if shape == null:
				errors.append("PathBoundaryCollision child %s is not CollisionShape2D" % child.name)
				continue
			if not (shape.shape is CapsuleShape2D):
				errors.append("%s should use CapsuleShape2D thick rail, got %s" % [shape.get_path(), shape.shape])
			else:
				segment_count += 1
		if segment_count != EXPECTED_BOUNDARY_SEGMENTS:
			errors.append("PathBoundaryCollision expected %d thick capsule rails, got %d" % [EXPECTED_BOUNDARY_SEGMENTS, segment_count])
		_check_boundary_segment(boundary, "BoundarySegment_001", Vector2(-167.2, 1024.8), Vector2(-306.4, 969.5), errors)
		_check_boundary_segment(boundary, "BoundarySegment_002", Vector2(-306.4, 969.5), Vector2(-371.1, 885.2), errors)
		_check_boundary_segment(boundary, "BoundarySegment_074", Vector2(-25.6, 990.7), Vector2(-166.4, 1023.7), errors)

	_collect_filled_collision_polygons(scene, errors)
	_check_camera_bounds(scene, errors)

	var controller := scene.get_node_or_null("VistaController") as SunderedKeepVistaController
	if controller == null:
		errors.append("VistaController missing")
	else:
		if not controller.has_camera_target():
			errors.append("VistaController camera target is not bound")
		_check_controller_path(controller, "vista_root_path", NodePath("../VistaRoot"), errors)
		_check_controller_path(controller, "camera_path", NodePath("/root/GameRoot/World/Camera2D"), errors)
		_check_controller_path(controller, "entry_marker_path", NodePath("../Markers/EntrySpawn"), errors)
		_check_controller_path(controller, "reveal_full_marker_path", NodePath("../Markers/RevealFull"), errors)
		_check_controller_path(controller, "mid_gameplay_marker_path", NodePath("../Markers/MidGameplayStart"), errors)
		_check_controller_path(controller, "grand_vista_root_path", NodePath("../GrandVistaRoot"), errors)
		_check_controller_path(controller, "vista_fog_band_path", NodePath("../VistaRoot/ApproachFirstVistaFogVeil"), errors)
		_check_controller_path(controller, "occlusion_root_path", NodePath("../OcclusionRoot"), errors)
		_check_controller_path(controller, "cliff_occluder_path", NodePath("../OcclusionRoot/ApproachEdgeMistWrap"), errors)
		_check_controller_path(controller, "wall_shadow_occluder_path", NodePath("../OcclusionRoot/ApproachFinalGateShadowVeil"), errors)
		_check_controller_path(controller, "final_gate_shadow_veil_path", NodePath("../OcclusionRoot/ApproachFinalGateShadowVeil"), errors)
		_check_controller_path(controller, "distant_keep_path", NodePath("../VistaRoot/ApproachFirstVistaHorizon"), errors)
		_check_controller_path(controller, "second_vista_start_marker_path", NodePath("../Markers/SecondVistaStart"), errors)
		_check_controller_path(controller, "second_vista_full_marker_path", NodePath("../Markers/SecondVistaFull"), errors)
		_check_controller_path(controller, "second_vista_end_marker_path", NodePath("../Markers/SecondVistaEnd"), errors)

		var reveal_start_progress := _marker_progress(scene, "RevealStart", errors)
		var reveal_full_progress := _marker_progress(scene, "RevealFull", errors)
		var mid_progress := _marker_progress(scene, "MidGameplayStart", errors)
		var second_start_progress := _marker_progress(scene, "SecondVistaStart", errors)
		var second_full_progress := _marker_progress(scene, "SecondVistaFull", errors)
		var second_end_progress := _marker_progress(scene, "SecondVistaEnd", errors)
		var traverse_end_progress := _marker_progress(scene, "TraverseEnd", errors)
		_check_marker_order(
			reveal_start_progress,
			reveal_full_progress,
			mid_progress,
			second_start_progress,
			second_full_progress,
			second_end_progress,
			traverse_end_progress,
			errors
		)

		controller.apply_progress(0.0)
		_check_camera_target(controller, Vector2.ZERO, Vector2.ONE, "entry", errors)
		if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
			errors.append("VistaController should keep GrandVistaRoot hidden before second vista")
		if final_gate_veil == null or final_gate_veil.modulate.a > 0.01:
			errors.append("VistaController should keep final gate veil hidden at start")
		controller.apply_progress(0.15)
		if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
			errors.append("VistaController should not reveal GrandVistaRoot during first approach reveal")
		if vista_root == null or vista_root.modulate.a < 0.9:
			errors.append("VistaController should reveal VistaRoot by early overlook progress")
		controller.apply_progress(maxf(reveal_full_progress, second_start_progress - 0.05))
		if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
			errors.append("VistaController should keep GrandVistaRoot hidden through the gameplay traversal gap")
		controller.apply_progress(second_full_progress)
		_check_camera_target(controller, Vector2(0.0, -48.0), Vector2(0.96, 0.96), "grand vista", errors)
		if grand_vista_root == null or grand_vista_root.modulate.a < 0.85:
			errors.append("VistaController did not reveal GrandVistaRoot at second vista full marker")
		controller.apply_progress(minf(1.0, second_end_progress + 0.05))
		if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
			errors.append("VistaController did not hide GrandVistaRoot after second vista marker window")
		controller.apply_progress(1.0)
		_check_camera_target(controller, Vector2.ZERO, Vector2.ONE, "final gate", errors)
		if final_gate_veil == null or final_gate_veil.modulate.a < 0.8:
			errors.append("VistaController did not raise final gate veil near exit")

	if scene.get_node_or_null("ExitTransitionTrigger") != null:
		errors.append("Legacy duplicate ExitTransitionTrigger must not coexist with EventRuntime/LevelExitTrigger")
	_check_event_markers(scene, errors)

	if errors.is_empty():
		print("[SunderedKeepApproachSmoke] PASS")
		quit(0)
	else:
		for err in errors:
			push_error("[SunderedKeepApproachSmoke] %s" % err)
		_fail("%d checks failed" % errors.size())


func _fail(message: String) -> void:
	push_error("[SunderedKeepApproachSmoke] %s" % message)
	quit(1)


func _check_sprite_rect(node_path: String, sprite: Sprite2D, expected: Rect2, errors: Array[String]) -> void:
	if not _vec2_nearly_equal(sprite.position, expected.position):
		errors.append("%s position expected %s, got %s" % [node_path, expected.position, sprite.position])
	var rendered_size := Vector2(
		float(sprite.texture.get_width()) * sprite.scale.x,
		float(sprite.texture.get_height()) * sprite.scale.y
	)
	if not _vec2_nearly_equal(rendered_size, expected.size):
		errors.append("%s rendered size expected %s, got %s" % [node_path, expected.size, rendered_size])


func _check_boundary_segment(boundary: StaticBody2D, segment_name: String, expected_a: Vector2, expected_b: Vector2, errors: Array[String]) -> void:
	var segment_node := boundary.get_node_or_null(segment_name) as CollisionShape2D
	if segment_node == null or not (segment_node.shape is CapsuleShape2D):
		errors.append("PathBoundaryCollision missing %s" % segment_name)
		return
	if not segment_node.has_meta("boundary_a") or not segment_node.has_meta("boundary_b"):
		errors.append("%s missing boundary endpoint metadata" % segment_name)
		return
	var actual_a := segment_node.get_meta("boundary_a") as Vector2
	var actual_b := segment_node.get_meta("boundary_b") as Vector2
	if not _vec2_nearly_equal(actual_a, expected_a) or not _vec2_nearly_equal(actual_b, expected_b):
		errors.append("%s expected %s -> %s, got %s -> %s" % [segment_name, expected_a, expected_b, actual_a, actual_b])
	var rail := segment_node.shape as CapsuleShape2D
	if rail.radius < 9.5:
		errors.append("%s rail radius %.2f is too thin for playable boundary blocking" % [segment_name, rail.radius])


func _check_camera_bounds(scene: Node, errors: Array[String]) -> void:
	if not scene.has_method("get_camera_bounds"):
		errors.append("SunderedKeepApproach should expose get_camera_bounds()")
		return
	var bounds := scene.call("get_camera_bounds") as Rect2
	var expected := Rect2(Vector2(-1280, -980), Vector2(2880, 2206))
	if not _vec2_nearly_equal(bounds.position, expected.position) or not _vec2_nearly_equal(bounds.size, expected.size):
		errors.append("SunderedKeepApproach camera bounds expected %s, got %s" % [expected, bounds])


func _check_backdrop_coverage(scene: Node, errors: Array[String]) -> void:
	var fill := scene.get_node_or_null("UnderlayRoot/BackdropVoidFill") as Polygon2D
	if fill == null:
		errors.append("UnderlayRoot/BackdropVoidFill missing or not Polygon2D")
		return
	if fill.z_index >= -30:
		errors.append("BackdropVoidFill must render below all fitted underlay art")
	if not fill.has_meta("coverage_rect"):
		errors.append("BackdropVoidFill missing coverage_rect metadata")
		return
	var coverage := fill.get_meta("coverage_rect") as Rect2
	var bounds := scene.call("get_camera_bounds") as Rect2
	# Standalone smoke keeps the approach at the origin, matching local coverage.
	if not coverage.encloses(bounds):
		errors.append("BackdropVoidFill %s does not cover camera bounds %s" % [coverage, bounds])
	var required := bounds.grow(768.0)
	if not coverage.encloses(required):
		errors.append("BackdropVoidFill %s lacks the required camera framing slack %s" % [coverage, required])


func _check_controller_path(controller: SunderedKeepVistaController, property_name: String, expected: NodePath, errors: Array[String]) -> void:
	var actual := controller.get(property_name) as NodePath
	if actual != expected:
		errors.append("VistaController.%s expected %s, got %s" % [property_name, expected, actual])


func _check_camera_target(controller: SunderedKeepVistaController, expected_offset: Vector2, expected_zoom: Vector2, label: String, errors: Array[String]) -> void:
	if not controller.has_method("get_camera_target_state"):
		errors.append("VistaController must expose an authored camera target state")
		return
	var state := controller.get_camera_target_state()
	var actual_offset: Vector2 = state.get("offset", Vector2(INF, INF))
	var actual_zoom: Vector2 = state.get("zoom", Vector2.ZERO)
	if not _vec2_nearly_equal(actual_offset, expected_offset):
		errors.append("VistaController %s offset expected %s, got %s" % [label, expected_offset, actual_offset])
	if not _vec2_nearly_equal(actual_zoom, expected_zoom):
		errors.append("VistaController %s zoom expected %s, got %s" % [label, expected_zoom, actual_zoom])


func _marker_progress(scene: Node2D, marker_name: String, errors: Array[String]) -> float:
	var start := scene.get_node_or_null("Markers/RevealStart") as Node2D
	var end := scene.get_node_or_null("Markers/ReturnTopdown") as Node2D
	var marker := scene.get_node_or_null("Markers/%s" % marker_name) as Node2D
	if start == null or end == null or marker == null:
		errors.append("Cannot calculate marker progress for %s" % marker_name)
		return 0.0
	var progress_axis := end.global_position - start.global_position
	var total := progress_axis.length()
	if total <= 0.01:
		errors.append("Cannot calculate marker progress because RevealStart/ReturnTopdown axis is degenerate")
		return 0.0
	var along := (marker.global_position - start.global_position).dot(progress_axis.normalized())
	return clampf(along / total, 0.0, 1.0)


func _check_marker_order(
	reveal_start_progress: float,
	reveal_full_progress: float,
	mid_progress: float,
	second_start_progress: float,
	second_full_progress: float,
	second_end_progress: float,
	traverse_end_progress: float,
	errors: Array[String]
) -> void:
	if not (reveal_start_progress < reveal_full_progress):
		errors.append("RevealStart progress must be before RevealFull progress")
	if not (reveal_full_progress < mid_progress):
		errors.append("RevealFull progress must be before MidGameplayStart progress")
	if not (mid_progress < second_start_progress):
		errors.append("SecondVistaStart must come after playable traversal has begun")
	if second_start_progress - reveal_full_progress < 0.25:
		errors.append("SecondVistaStart must leave a real gameplay traversal gap after RevealFull")
	if not (second_start_progress < second_full_progress and second_full_progress < second_end_progress):
		errors.append("Second vista markers must progress Start < Full < End")
	if second_end_progress > traverse_end_progress:
		errors.append("SecondVistaEnd should finish before TraverseEnd progress")


func _collect_filled_collision_polygons(node: Node, errors: Array[String]) -> void:
	if node is CollisionPolygon2D:
		var polygon := node as CollisionPolygon2D
		if polygon.build_mode == CollisionPolygon2D.BUILD_SOLIDS:
			errors.append("Filled CollisionPolygon2D solid is not allowed for approach path boundary: %s" % polygon.get_path())
	for child in node.get_children():
		_collect_filled_collision_polygons(child, errors)


func _collect_collision_nodes(node: Node, context: String, errors: Array[String]) -> void:
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D:
		errors.append("%s; found collision node %s" % [context, node.get_path()])
	for child in node.get_children():
		_collect_collision_nodes(child, context, errors)


func _check_event_markers(scene: Node, errors: Array[String]) -> void:
	var markers := scene.get_node_or_null("EventMarkers")
	if markers == null:
		errors.append("EventMarkers root missing")
	var runtime := scene.get_node_or_null("EventRuntime")
	if runtime == null:
		errors.append("EventRuntime root missing")
	if not scene.has_method("get_authoring_marker_state"):
		errors.append("Approach does not expose get_authoring_marker_state")
		return
	var marker_state := scene.call("get_authoring_marker_state") as Dictionary
	for marker_id in ["spawn", "return_causeway"]:
		if not marker_state.has(marker_id):
			errors.append("AUTHORING_MARKERS missing %s" % marker_id)
	if markers != null:
		if markers.get_child_count() != 0:
			errors.append("Vista Approach must not render authoring markers at runtime")
	if runtime != null:
		var level_exit := runtime.get_node_or_null("LevelExitTrigger") as SunderedKeepTransitionTrigger
		if level_exit == null:
			errors.append("EventRuntime/LevelExitTrigger missing")
		else:
			if not bool(scene.get("bypass_return_causeway_for_keep_testing")):
				errors.append("Vista Approach should bypass Return Causeway by default during Keep testing")
			if not level_exit.target_scene_path.ends_with("sundered_keep_map.gd"):
				errors.append("Default Vista endpoint must target SunderedKeepMap directly")
			if level_exit.target_node_name != &"SunderedKeepMap":
				errors.append("Default Vista endpoint must use the stable SunderedKeepMap node name")
			if level_exit.target_level_id != &"sundered_keep_front_gate":
				errors.append("Direct Vista endpoint must retain the sundered_keep_front_gate level id")
			if level_exit.required_entry_direction != Vector2.RIGHT:
				errors.append("LevelExitTrigger must reject entry from the unauthored side")
		var affordance := runtime.get_node_or_null("LevelExitAffordance")
		if affordance == null:
			errors.append("EventRuntime/LevelExitAffordance missing")
		else:
			if affordance.get_node_or_null("WalkableThreshold") == null:
				errors.append("LevelExitAffordance missing WalkableThreshold")
			var prompt := affordance.get_node_or_null("DestinationPrompt") as Label
			if prompt == null or not prompt.text.contains("ENTER SUNDERED KEEP"):
				errors.append("LevelExitAffordance destination prompt is missing or unclear")
		for forbidden_name in ["GatehouseKeyInteraction", "MainGateInteraction", "MainGateBlocker", "EnemySpawnWestSpawnNode", "EnemySpawnGateSpawnNode"]:
			if runtime.get_node_or_null(forbidden_name) != null:
				errors.append("EventRuntime/%s belongs in the Keep entrance, not Vista Approach" % forbidden_name)


func _vec2_nearly_equal(a: Vector2, b: Vector2, epsilon := 0.01) -> bool:
	return absf(a.x - b.x) <= epsilon and absf(a.y - b.y) <= epsilon
