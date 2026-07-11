extends SceneTree

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")
const KEEP_SCENE := preload("res://game/world/sundered_keep/sundered_keep_map.tscn")
const EXPECTED_BOUNDARY_SEGMENTS := 28

const EXPECTED_ROOTS := {
	"UnderlayRoot": -300,
	"VistaRoot": -200,
	"GrandVistaRoot": -220,
	"PlayableRoot": 0,
	"OcclusionRoot": 100,
}

const EXPECTED_SPRITE_RECTS := {
	"UnderlayRoot/ApproachOceanVoidUnderlay": Rect2(Vector2(-1000, -900), Vector2(2600, 1800)),
	"UnderlayRoot/ApproachCliffSpiresUnderlay": Rect2(Vector2(-1000, -900), Vector2(2600, 1800)),
	"UnderlayRoot/ApproachRouteContactShadow": Rect2(Vector2(-620, -660), Vector2(2048, 1706)),
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
	"PlayableRoot/ApproachRouteMaster": Rect2(Vector2(-620, -660), Vector2(2048, 1706)),
	"OcclusionRoot/ApproachEdgeMistWrap": Rect2(Vector2(-620, -660), Vector2(2048, 1706)),
	"OcclusionRoot/ApproachFogStrip01": Rect2(Vector2(-880, -430), Vector2(1500, 520)),
	"OcclusionRoot/ApproachFogStrip02": Rect2(Vector2(-260, -420), Vector2(1500, 520)),
	"OcclusionRoot/ApproachFogStrip03": Rect2(Vector2(320, -410), Vector2(1500, 520)),
	"OcclusionRoot/ApproachFinalGateShadowVeil": Rect2(Vector2(-1000, -520), Vector2(2600, 900)),
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
	"EntrySpawn": Vector2(45, 430),
	"RevealStart": Vector2(-40, 120),
	"RevealFull": Vector2(-150, -175),
	"MidGameplayStart": Vector2(50, -235),
	"SecondVistaStart": Vector2(300, -305),
	"SecondVistaFull": Vector2(590, -305),
	"SecondVistaEnd": Vector2(830, -305),
	"TraverseEnd": Vector2(915, -305),
	"ReturnTopdown": Vector2(980, -305),
}


func _init() -> void:
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
		if sprite.z_as_relative:
			errors.append("%s should use z_as_relative=false" % node_path)
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
			if not (shape.shape is SegmentShape2D):
				errors.append("%s should use SegmentShape2D, got %s" % [shape.get_path(), shape.shape])
			else:
				segment_count += 1
		if segment_count != EXPECTED_BOUNDARY_SEGMENTS:
			errors.append("PathBoundaryCollision expected %d SegmentShape2D rails, got %d" % [EXPECTED_BOUNDARY_SEGMENTS, segment_count])

	_collect_filled_collision_polygons(scene, errors)

	var controller := scene.get_node_or_null("VistaController") as SunderedKeepVistaController
	if controller == null:
		errors.append("VistaController missing")
	else:
		_check_controller_path(controller, "vista_root_path", NodePath("../VistaRoot"), errors)
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
		if grand_vista_root == null or grand_vista_root.modulate.a < 0.85:
			errors.append("VistaController did not reveal GrandVistaRoot at second vista full marker")
		controller.apply_progress(minf(1.0, second_end_progress + 0.05))
		if grand_vista_root == null or grand_vista_root.modulate.a > 0.01:
			errors.append("VistaController did not hide GrandVistaRoot after second vista marker window")
		controller.apply_progress(1.0)
		if final_gate_veil == null or final_gate_veil.modulate.a < 0.8:
			errors.append("VistaController did not raise final gate veil near exit")

	var trigger := scene.get_node_or_null("ExitTransitionTrigger") as SunderedKeepTransitionTrigger
	if trigger == null:
		errors.append("ExitTransitionTrigger missing")
	else:
		if String(trigger.target_scene_path) != "res://game/world/sundered_keep/sundered_keep_map.gd":
			errors.append("ExitTransitionTrigger target path is wrong: %s" % trigger.target_scene_path)
		if not _vec2_nearly_equal(trigger.position, EXPECTED_MARKERS["ReturnTopdown"] as Vector2):
			errors.append("ExitTransitionTrigger should sit near ReturnTopdown; got %s" % trigger.position)
		if trigger.get_node_or_null("CollisionShape2D") == null:
			errors.append("ExitTransitionTrigger missing CollisionShape2D")
		if trigger.vista_controller_path != NodePath("../VistaController"):
			errors.append("ExitTransitionTrigger vista_controller_path is not wired")

	var keep_scene := KEEP_SCENE.instantiate() as Node2D
	if keep_scene == null:
		errors.append("Could not instantiate SunderedKeepMap")
	else:
		root.add_child(keep_scene)
		await process_frame
		_collect_forbidden_grand_vista_nodes(keep_scene, errors)
		keep_scene.queue_free()

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


func _check_controller_path(controller: SunderedKeepVistaController, property_name: String, expected: NodePath, errors: Array[String]) -> void:
	var actual := controller.get(property_name) as NodePath
	if actual != expected:
		errors.append("VistaController.%s expected %s, got %s" % [property_name, expected, actual])


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


func _collect_forbidden_grand_vista_nodes(node: Node, errors: Array[String]) -> void:
	var node_name := String(node.name)
	if node_name.begins_with("GrandVista") or node_name == "GrandVistaRoot":
		errors.append("SunderedKeepMap must not contain grand-vista presentation node: %s" % node.get_path())
	if node is Sprite2D:
		var sprite := node as Sprite2D
		if sprite.texture != null and sprite.texture.resource_path.find("/grand_vista/") >= 0:
			errors.append("SunderedKeepMap must not use grand-vista texture: %s -> %s" % [node.get_path(), sprite.texture.resource_path])
	for child in node.get_children():
		_collect_forbidden_grand_vista_nodes(child, errors)


func _vec2_nearly_equal(a: Vector2, b: Vector2, epsilon := 0.01) -> bool:
	return absf(a.x - b.x) <= epsilon and absf(a.y - b.y) <= epsilon
