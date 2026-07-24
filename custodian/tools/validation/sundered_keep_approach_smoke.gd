extends SceneTree

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")
const REVEAL_DIRECTOR_SCRIPT := preload("res://game/world/approaches/sundered_keep/sundered_keep_reveal_director.gd")
const EXPECTED_BOUNDARY_SEGMENTS := 42

const EXPECTED_ROOTS := {
	"ParallaxRoot": 0,
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
	"VistaRoot/FirstVistaFarParallax/ApproachFirstVistaHorizon": Rect2(Vector2(-1000, -980), Vector2(2600, 1460)),
	"VistaRoot/FirstVistaMistParallax/ApproachFirstVistaFogVeil": Rect2(Vector2(-1000, -360), Vector2(2600, 720)),
	"GrandVistaRoot/LabyrinthFarParallax/GrandVistaPanorama": Rect2(Vector2(-1280, -920), Vector2(2560, 1440)),
	"GrandVistaRoot/LabyrinthMistParallax/GrandVistaOceanSprayOverlay": Rect2(Vector2(-1280, -160), Vector2(2560, 720)),
	"GrandVistaRoot/LabyrinthMistParallax/GrandVistaFogOverlay": Rect2(Vector2(-1280, -520), Vector2(2560, 480)),
	"GrandVistaRoot/LabyrinthFarParallax/GrandVistaShadowVignette": Rect2(Vector2(-1280, -920), Vector2(2560, 1440)),
	"GrandVistaRoot/LabyrinthNearRoot/GrandVistaForegroundParapet": Rect2(Vector2(-1280, 260), Vector2(2560, 360)),
	"GrandVistaRoot/LabyrinthMistParallax/GrandVistaHorizonSeamFog": Rect2(Vector2(-1280, -460), Vector2(2560, 320)),
	"GrandVistaRoot/LabyrinthNearRoot/GrandVistaPathContactShadow": Rect2(Vector2(-1280, -160), Vector2(2560, 720)),
	"GrandVistaRoot/LabyrinthNearRoot/GrandVistaEdgeSprayWrap": Rect2(Vector2(-1280, -160), Vector2(2560, 720)),
	"GrandVistaRoot/LabyrinthNearRoot/GrandVistaForegroundEdgeMask": Rect2(Vector2(-1280, 220), Vector2(2560, 420)),
	"PlayableRoot/ApproachRouteMaster": Rect2(Vector2(-620, -480), Vector2(2048, 1706)),
	"OcclusionRoot/ApproachEdgeMistWrap": Rect2(Vector2(-620, -480), Vector2(2048, 1706)),
	"OcclusionRoot/ApproachFogStrip01": Rect2(Vector2(-880, -250), Vector2(1500, 520)),
	"OcclusionRoot/ApproachFogStrip02": Rect2(Vector2(-260, -240), Vector2(1500, 520)),
	"OcclusionRoot/ApproachFogStrip03": Rect2(Vector2(320, -230), Vector2(1500, 520)),
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
	"EntrySpawn": Vector2(-163, 610),
	"RevealStart": Vector2(-40, 300),
	"RevealFull": Vector2(-150, 5),
	"MidGameplayStart": Vector2(50, -55),
	"RevealControlStart": Vector2(-150, 5),
	"RevealControlEnd": Vector2(50, -55),
	"SecondVistaStart": Vector2(300, -125),
	"SecondVistaFull": Vector2(590, -125),
	"SecondVistaEnd": Vector2(830, -125),
	"TraverseEnd": Vector2(915, -125),
	"ReturnTopdown": Vector2(980, -125),
	"FirstRevealCameraAnchor": Vector2(-135.9, -478.3),
	"SecondVistaCameraAnchor": Vector2(664.5, -480),
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

	for duplicate_name in [
		"FarKeepSilhouetteLayerA",
		"FarKeepSilhouetteLayerB",
	]:
		if scene.get_node_or_null(
			"VistaRoot/FirstVistaFarParallax/%s" % duplicate_name
		) != null:
			errors.append(
				"Duplicate first-vista landmark remains: %s"
				% duplicate_name
			)

	var vista_root := scene.get_node_or_null("VistaRoot") as CanvasItem
	if vista_root == null or vista_root.modulate.a > 0.01:
		errors.append("VistaRoot should start hidden; alpha=%s" % (vista_root.modulate.a if vista_root else "missing"))
	var grand_vista_root := scene.get_node_or_null("GrandVistaRoot") as CanvasItem
	if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
		errors.append("GrandVistaRoot should start hidden; alpha=%s" % (grand_vista_root.modulate.a if grand_vista_root else "missing"))
	if grand_vista_root != null:
		for layer_name in [
			"LabyrinthFarParallax",
			"LabyrinthMistParallax",
			"LabyrinthNearRoot",
		]:
			if grand_vista_root.get_node_or_null(layer_name) == null:
				errors.append("GrandVistaRoot/%s missing" % layer_name)
		_collect_collision_nodes(grand_vista_root, "GrandVistaRoot must be visual-only", errors)
	var parallax_root := scene.get_node_or_null("ParallaxRoot")
	if parallax_root == null:
		errors.append("ParallaxRoot missing")
	else:
		_collect_collision_nodes(
			parallax_root,
			"ParallaxRoot must be presentation-only",
			errors
		)
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
		_check_boundary_segment(boundary, "BoundarySegment_001", Vector2(-215.0, 694.2), Vector2(-241.7, 598.6), errors)
		_check_boundary_segment(boundary, "BoundarySegment_002", Vector2(-241.7, 598.6), Vector2(-260.7, 492.3), errors)
		_check_boundary_segment(boundary, "BoundarySegment_042", Vector2(-347.9, 771.7), Vector2(-213.8, 692.5), errors)

	_collect_filled_collision_polygons(scene, errors)
	_check_camera_bounds(scene, errors)

	var controller := scene.get_node_or_null("VistaController") as SunderedKeepVistaController
	if controller == null:
		errors.append("VistaController missing")
	else:
		if not controller.has_camera_target():
			errors.append("VistaController camera target is not bound")
		if float(controller.get("vista_fog_max_alpha")) > 0.38:
			errors.append(
				"Vista reveal fog exceeds the 0.38 review budget"
			)
		_check_controller_path(controller, "vista_root_path", NodePath("../VistaRoot"), errors)
		_check_controller_path(controller, "camera_path", NodePath("/root/GameRoot/World/Camera2D"), errors)
		_check_controller_path(controller, "entry_marker_path", NodePath("../Markers/EntrySpawn"), errors)
		_check_controller_path(controller, "reveal_full_marker_path", NodePath("../Markers/RevealFull"), errors)
		_check_controller_path(controller, "mid_gameplay_marker_path", NodePath("../Markers/MidGameplayStart"), errors)
		_check_controller_path(
			controller,
			"reveal_control_start_marker_path",
			NodePath("../Markers/RevealControlStart"),
			errors
		)
		_check_controller_path(
			controller,
			"reveal_control_end_marker_path",
			NodePath("../Markers/RevealControlEnd"),
			errors
		)
		_check_controller_path(controller, "grand_vista_root_path", NodePath("../GrandVistaRoot"), errors)
		_check_controller_path(controller, "vista_fog_band_path", NodePath("../VistaRoot/FirstVistaMistParallax/ApproachFirstVistaFogVeil"), errors)
		_check_controller_path(controller, "occlusion_root_path", NodePath("../OcclusionRoot"), errors)
		_check_controller_path(controller, "cliff_occluder_path", NodePath("../OcclusionRoot/ApproachEdgeMistWrap"), errors)
		_check_controller_path(controller, "wall_shadow_occluder_path", NodePath("../OcclusionRoot/ApproachFinalGateShadowVeil"), errors)
		_check_controller_path(controller, "final_gate_shadow_veil_path", NodePath("../OcclusionRoot/ApproachFinalGateShadowVeil"), errors)
		_check_controller_path(
			controller,
			"distant_keep_path",
			NodePath(
				"../ParallaxRoot/RevealDepth/"
				+ "DistantKeep_Parallax2D/"
				+ "DistantSunderedKeepLandmark"
			),
			errors
		)
		_check_controller_path(controller, "first_reveal_camera_anchor_path", NodePath("../Markers/FirstRevealCameraAnchor"), errors)
		_check_controller_path(controller, "second_reveal_camera_anchor_path", NodePath("../Markers/SecondVistaCameraAnchor"), errors)
		_check_controller_path(controller, "second_vista_start_marker_path", NodePath("../Markers/SecondVistaStart"), errors)
		_check_controller_path(controller, "second_vista_full_marker_path", NodePath("../Markers/SecondVistaFull"), errors)
		_check_controller_path(controller, "second_vista_end_marker_path", NodePath("../Markers/SecondVistaEnd"), errors)
		_check_controller_path(
			controller,
			"parallax_reveal_root_path",
			NodePath("../ParallaxRoot/RevealDepth"),
			errors
		)
		_check_controller_path(
			controller,
			"parallax_foreground_root_path",
			NodePath("../ParallaxRoot/ForegroundDepth"),
			errors
		)

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
		_check_camera_target(controller, Vector2(0.0, -18.0), Vector2(1.12, 1.12), "entry", errors)
		if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
			errors.append("VistaController should keep GrandVistaRoot hidden before second vista")
		if final_gate_veil == null or final_gate_veil.modulate.a > 0.01:
			errors.append("VistaController should keep final gate veil hidden at start")
		controller.apply_progress(0.15)
		if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
			errors.append("VistaController should not reveal GrandVistaRoot during first approach reveal")
		if vista_root == null or vista_root.modulate.a > 0.01:
			errors.append("VistaRoot must remain hidden until explicit reveal choreography begins")
		controller.complete_first_reveal()
		controller.apply_progress(maxf(reveal_full_progress, second_start_progress - 0.05))
		if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
			errors.append("VistaController should keep GrandVistaRoot hidden through the gameplay traversal gap")
		controller.apply_progress(second_full_progress)
		if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
			errors.append("Raw progress must not reveal GrandVistaRoot")
		controller.begin_second_reveal()
		controller.set_second_reveal_weight(1.0)
		controller.hold_second_reveal()
		if grand_vista_root == null or grand_vista_root.modulate.a < 0.85:
			errors.append("Explicit second reveal did not reveal GrandVistaRoot")
		_check_camera_target(controller, Vector2(150.0, -115.0), Vector2(0.84, 0.84), "second reveal", errors)
		controller.begin_second_return_to_gameplay()
		controller.set_second_return_to_gameplay_weight(1.0)
		controller.complete_second_reveal()
		controller.apply_progress(second_end_progress)
		_check_camera_target(controller, Vector2(0.0, -48.0), Vector2(0.98, 0.98), "second reveal return", errors)
		controller.apply_progress(minf(1.0, second_end_progress + 0.05))
		if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
			errors.append("VistaController did not hide GrandVistaRoot after second reveal")
		controller.apply_progress(1.0)
		_check_camera_target(controller, Vector2.ZERO, Vector2.ONE, "final gate", errors)
		if final_gate_veil == null or final_gate_veil.modulate.a < 0.35:
			errors.append("VistaController did not raise final gate veil near exit")

	if scene.get_node_or_null("ExitTransitionTrigger") != null:
		errors.append("Legacy duplicate ExitTransitionTrigger must not coexist with EventRuntimeRoot exits")
	_check_event_markers(scene, errors)
	await _check_reveal_director(scene, errors)

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
	if (
		node is CollisionObject2D
		or node is CollisionShape2D
		or node is CollisionPolygon2D
		or node is NavigationRegion2D
	):
		errors.append("%s; found collision node %s" % [context, node.get_path()])
	for child in node.get_children():
		_collect_collision_nodes(child, context, errors)


func _check_event_markers(scene: Node, errors: Array[String]) -> void:
	var markers := scene.get_node_or_null("EventMarkers")
	if markers == null:
		errors.append("EventMarkers root missing")
	var runtime := scene.get_node_or_null("EventRuntimeRoot")
	if runtime == null:
		errors.append("EventRuntimeRoot root missing")
	if not scene.has_method("get_authoring_marker_state"):
		errors.append("Approach does not expose get_authoring_marker_state")
		return
	var marker_state := scene.call("get_authoring_marker_state") as Dictionary
	for marker_id in [
		"spawn",
		"return_causeway",
		"level_exit",
		"first_reveal_trigger",
		"first_reveal_camera_anchor",
		"reveal_control_start",
		"reveal_control_end",
		"return_to_gameplay_trigger",
		"second_reveal_trigger",
		"second_reveal_camera_anchor",
	]:
		if not marker_state.has(marker_id):
			errors.append("AUTHORING_MARKERS missing %s" % marker_id)
	var authored_runtime_paths := {
		"first_reveal_trigger": (
			"SequenceTriggers/FirstVistaRevealTrigger"
		),
		"first_reveal_camera_anchor": (
			"Markers/FirstRevealCameraAnchor"
		),
		"reveal_control_start": (
			"Markers/RevealControlStart"
		),
		"reveal_control_end": (
			"Markers/RevealControlEnd"
		),
		"return_to_gameplay_trigger": (
			"SequenceTriggers/ReturnToGameplayTrigger"
		),
		"second_reveal_trigger": (
			"SequenceTriggers/SecondVistaRevealTrigger"
		),
		"second_reveal_camera_anchor": (
			"Markers/SecondVistaCameraAnchor"
		),
	}
	for marker_id: String in authored_runtime_paths:
		var runtime_node := scene.get_node_or_null(
			authored_runtime_paths[marker_id]
		) as Node2D
		var authored_state := marker_state.get(
			marker_id,
			{}
		) as Dictionary
		if runtime_node == null:
			errors.append(
				"Authored presentation node missing for %s"
				% marker_id
			)
		elif not runtime_node.position.is_equal_approx(
			authored_state.get(
				"runtime_position",
				Vector2.INF
			) as Vector2
		):
			errors.append(
				"Authored presentation marker %s is not runtime authority"
				% marker_id
			)
	if markers != null:
		if markers.get_child_count() != 0:
			errors.append("Vista Approach must not render authoring markers at runtime")
	if runtime != null:
		var level_exit := runtime.get_node_or_null("Exits/Exit_Continue") as LevelExit2D
		var world_exit := runtime.get_node_or_null("Exits/Exit_ReturnWorld") as LevelExit2D
		if level_exit == null or level_exit.exit_id != &"continue":
			errors.append("EventRuntimeRoot/Exits/Exit_Continue authored exit missing")
		if world_exit == null or world_exit.exit_id != &"return_world":
			errors.append("EventRuntimeRoot/Exits/Exit_ReturnWorld authored exit missing")
		var affordance := runtime.get_node_or_null("LevelExitAffordance")
		if affordance == null:
			errors.append("EventRuntimeRoot/LevelExitAffordance missing")
		else:
			if affordance.get_node_or_null("WalkableThreshold") == null:
				errors.append("LevelExitAffordance missing WalkableThreshold")
			var prompt := affordance.get_node_or_null("DestinationPrompt") as Label
			if prompt == null or not prompt.text.contains("RETURN CAUSEWAY"):
				errors.append("LevelExitAffordance destination prompt is missing or unclear")
		for forbidden_name in ["GatehouseKeyInteraction", "MainGateInteraction", "MainGateBlocker", "EnemySpawnWestSpawnNode", "EnemySpawnGateSpawnNode"]:
			if runtime.get_node_or_null(forbidden_name) != null:
				errors.append("EventRuntimeRoot/%s belongs in the Keep entrance, not Vista Approach" % forbidden_name)


func _check_reveal_director(scene: Node, errors: Array[String]) -> void:
	var director := scene.get_node_or_null("RevealDirector")
	if director == null:
		errors.append("RevealDirector missing")
		return
	if director.get_script() != REVEAL_DIRECTOR_SCRIPT:
		errors.append("RevealDirector uses the wrong script")
	if director.threshold_marker_path != NodePath("../Markers/RevealStart"):
		errors.append("RevealDirector must use Markers/RevealStart as its threshold")
	if director.vista_controller_path != NodePath("../VistaController"):
		errors.append("RevealDirector camera choreography is not bound to VistaController")
	if scene.get_node_or_null("OcclusionRoot/RevealMoonlightCue") as PointLight2D == null:
		errors.append("RevealMoonlightCue missing")
	var near_fog := scene.get_node_or_null("OcclusionRoot/ApproachFogStrip01") as Node2D
	var mid_fog := scene.get_node_or_null("OcclusionRoot/ApproachFogStrip02") as Node2D
	var far_fog := scene.get_node_or_null("OcclusionRoot/ApproachFogStrip03") as CanvasItem
	var near_fog_origin := near_fog.position if near_fog != null else Vector2.ZERO
	var mid_fog_origin := mid_fog.position if mid_fog != null else Vector2.ZERO
	var prompt := scene.get_node_or_null("EventRuntimeRoot/LevelExitAffordance") as CanvasItem
	if prompt == null:
		errors.append("RevealDirector cannot validate delayed prompt without LevelExitAffordance")
	elif prompt.modulate.a > 0.01:
		errors.append("LevelExitAffordance must stay hidden until the reveal settles")

	director.anticipation_duration = 0.001
	director.reveal_in_duration = 0.001
	director.reveal_hold_duration = 0.001
	director.return_duration = 0.001
	director.atmosphere_settle_duration = 0.001
	director.second_reveal_in_duration = 0.001
	director.second_reveal_hold_duration = 0.001
	director.second_return_duration = 0.001
	var controller := scene.get_node_or_null("VistaController") as SunderedKeepVistaController
	if controller != null:
		controller.enter_intro_tight_mode()
		controller.apply_progress(0.0)
	var completion_count := [0]
	director.reveal_completed.connect(func() -> void: completion_count[0] += 1)
	var operator := CharacterBody2D.new()
	operator.name = "Operator"
	operator.add_to_group("operator")
	operator.add_to_group("player")
	operator.collision_layer = 1
	operator.collision_mask = 1
	var operator_shape := CollisionShape2D.new()
	var operator_circle := CircleShape2D.new()
	operator_circle.radius = 10.0
	operator_shape.shape = operator_circle
	operator.add_child(operator_shape)
	var world := root.get_node_or_null("GameRoot/World")
	world.add_child(operator)
	var entry := scene.get_node_or_null("Markers/EntrySpawn") as Node2D
	var threshold := scene.get_node_or_null("Markers/RevealStart") as Node2D
	var threshold_axis := (threshold.global_position - entry.global_position).normalized()
	operator.global_position = threshold.global_position + threshold_axis
	director.refresh_bindings()
	await physics_frame
	if director.has_played():
		errors.append("RevealDirector fired from raw progress without the explicit trigger")
	var trigger := scene.get_node_or_null(
		"SequenceTriggers/FirstVistaRevealTrigger"
	) as Area2D
	if trigger == null:
		errors.append("SequenceTriggers/FirstVistaRevealTrigger missing")
	else:
		operator.global_position = trigger.global_position
		for unused in 8:
			await physics_frame
			if director.has_played():
				break
		if not director.has_played():
			errors.append(
				"FirstVistaRevealTrigger physical overlap did not start the reveal"
			)
	if not director.has_played():
		return
	for unused in 20:
		if bool(
			director.get_reveal_state().get(
				"ready_for_return",
				false
			)
		):
			break
		await process_frame
	var return_trigger := scene.get_node_or_null(
		"SequenceTriggers/ReturnToGameplayTrigger"
	) as Area2D
	if return_trigger == null:
		errors.append(
			"SequenceTriggers/ReturnToGameplayTrigger missing"
		)
		return
	operator.global_position = return_trigger.global_position
	for unused in 8:
		await physics_frame
		if bool(
			director.get_reveal_state().get(
				"return_running",
				false
			)
		):
			break
	if not bool(director.get_reveal_state().get("complete", false)):
		await director.reveal_completed
	var state: Dictionary = director.get_reveal_state()
	if not bool(state.get("played", false)) or not bool(state.get("complete", false)):
		errors.append("RevealDirector did not complete its one-shot reveal")
	if not bool(state.get("camera_bound", false)) or not bool(state.get("threshold_bound", false)):
		errors.append("RevealDirector is missing its camera or threshold binding")
	if not bool(state.get("prompt_visible", false)):
		errors.append("LevelExitAffordance did not appear after reveal completion")
	if near_fog == null or near_fog.position.x >= near_fog_origin.x or near_fog.position.y <= near_fog_origin.y:
		errors.append("Near fog did not peel left/down from the reveal centerline")
	if mid_fog == null or mid_fog.position.x <= mid_fog_origin.x or mid_fog.position.y <= mid_fog_origin.y:
		errors.append("Mid fog did not trail right/down behind the near peel")
	if far_fog == null or far_fog.modulate.a < 0.15:
		errors.append("Far haze did not remain after the reveal")
	var reveal_light := scene.get_node_or_null("OcclusionRoot/RevealMoonlightCue") as PointLight2D
	if reveal_light != null and reveal_light.energy > 0.01:
		errors.append("RevealMoonlightCue did not settle back to zero energy")
	if controller != null:
		_check_camera_target(controller, Vector2(0.0, -48.0), Vector2(0.98, 0.98), "reveal return", errors)
	director.play_reveal()
	await process_frame
	if int(completion_count[0]) != 1:
		errors.append("RevealDirector replayed after its one-shot completion")

	var second_completion_count := [0]
	director.second_reveal_completed.connect(
		func() -> void: second_completion_count[0] += 1
	)
	var second_trigger := scene.get_node_or_null(
		"SequenceTriggers/SecondVistaRevealTrigger"
	) as Area2D
	if second_trigger == null:
		errors.append("SequenceTriggers/SecondVistaRevealTrigger missing")
		return
	operator.global_position = second_trigger.global_position
	for unused in 8:
		await physics_frame
		if bool(
			director.get_reveal_state().get(
				"second_played",
				false
			)
		):
			break
	if not bool(
		director.get_reveal_state().get(
			"second_played",
			false
		)
	):
		errors.append(
			"SecondVistaRevealTrigger physical overlap did not start"
		)
		return
	if not bool(
		director.get_reveal_state().get(
			"second_complete",
			false
		)
	):
		await director.second_reveal_completed
	if int(second_completion_count[0]) != 1:
		errors.append("Second reveal did not complete exactly once")


func _vec2_nearly_equal(a: Vector2, b: Vector2, epsilon := 0.01) -> bool:
	return absf(a.x - b.x) <= epsilon and absf(a.y - b.y) <= epsilon
