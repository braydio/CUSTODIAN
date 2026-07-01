extends SceneTree

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")
const EXPECTED_BOUNDARY_SEGMENTS := 13

const EXPECTED_ROOTS := {
	"UnderlayRoot": -300,
	"VistaRoot": -200,
	"PlayableRoot": 0,
	"OcclusionRoot": 100,
}

const EXPECTED_SPRITE_RECTS := {
	"UnderlayRoot/OceanUnderlay": Rect2(Vector2(-900, -700), Vector2(2100, 1400)),
	"UnderlayRoot/CliffDepthUnderlay": Rect2(Vector2(-500, -440), Vector2(520, 540)),
	"UnderlayRoot/FogUnderlay": Rect2(Vector2(-900, -620), Vector2(2100, 360)),
	"VistaRoot/HorizonSky": Rect2(Vector2(-900, -700), Vector2(2100, 380)),
	"VistaRoot/FarSea": Rect2(Vector2(-900, -520), Vector2(2100, 260)),
	"VistaRoot/DistantSunderedKeep": Rect2(Vector2(-260, -670), Vector2(540, 250)),
	"VistaRoot/VistaFogBand": Rect2(Vector2(-900, -380), Vector2(2100, 160)),
	"PlayableRoot/MainlandApproachPath": Rect2(Vector2(-300, 120), Vector2(470, 400)),
	"PlayableRoot/HillClimbPath": Rect2(Vector2(-190, -120), Vector2(400, 240)),
	"PlayableRoot/OverlookLedge": Rect2(Vector2(-320, -320), Vector2(640, 200)),
	"PlayableRoot/LateralTraversePath": Rect2(Vector2(260, -260), Vector2(520, 180)),
	"PlayableRoot/FortressWallMass": Rect2(Vector2(650, -420), Vector2(350, 380)),
	"OcclusionRoot/CliffOccluder": Rect2(Vector2(520, -420), Vector2(520, 540)),
	"OcclusionRoot/WallShadowOccluder": Rect2(Vector2(-900, -360), Vector2(2100, 130)),
}

const EXPECTED_MARKERS := {
	"EntrySpawn": Vector2(-80, 430),
	"RevealStart": Vector2(-40, 80),
	"RevealFull": Vector2(0, -250),
	"TraverseStart": Vector2(260, -180),
	"TraverseEnd": Vector2(760, -170),
	"ReturnTopdown": Vector2(720, -80),
}


func _init() -> void:
	var scene := APPROACH_SCENE.instantiate() as Node2D
	if scene == null:
		_fail("Could not instantiate SunderedKeepApproach")
		return
	root.add_child(scene)
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
		_check_sprite_rect(node_path, sprite, EXPECTED_SPRITE_RECTS[node_path] as Rect2, errors)

	var vista_root := scene.get_node_or_null("VistaRoot") as CanvasItem
	if vista_root == null or vista_root.modulate.a > 0.01:
		errors.append("VistaRoot should start hidden; alpha=%s" % (vista_root.modulate.a if vista_root else "missing"))
	var occlusion_root := scene.get_node_or_null("OcclusionRoot") as CanvasItem
	if occlusion_root == null or occlusion_root.modulate.a > 0.01:
		errors.append("OcclusionRoot should start hidden; alpha=%s" % (occlusion_root.modulate.a if occlusion_root else "missing"))
	var fog_underlay := scene.get_node_or_null("UnderlayRoot/FogUnderlay") as CanvasItem
	if fog_underlay == null or fog_underlay.modulate.a < 0.24 or fog_underlay.modulate.a > 0.36:
		errors.append("FogUnderlay should start subtle; alpha=%s" % (fog_underlay.modulate.a if fog_underlay else "missing"))

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
		if segment_count < EXPECTED_BOUNDARY_SEGMENTS:
			errors.append("PathBoundaryCollision expected at least %d SegmentShape2D rails, got %d" % [EXPECTED_BOUNDARY_SEGMENTS, segment_count])

	_collect_filled_collision_polygons(scene, errors)

	var controller := scene.get_node_or_null("VistaController") as SunderedKeepVistaController
	if controller == null:
		errors.append("VistaController missing")
	else:
		_check_controller_path(controller, "vista_root_path", NodePath("../VistaRoot"), errors)
		_check_controller_path(controller, "vista_fog_band_path", NodePath("../VistaRoot/VistaFogBand"), errors)
		_check_controller_path(controller, "fog_underlay_path", NodePath("../UnderlayRoot/FogUnderlay"), errors)
		_check_controller_path(controller, "occlusion_root_path", NodePath("../OcclusionRoot"), errors)
		_check_controller_path(controller, "cliff_occluder_path", NodePath("../OcclusionRoot/CliffOccluder"), errors)
		_check_controller_path(controller, "wall_shadow_occluder_path", NodePath("../OcclusionRoot/WallShadowOccluder"), errors)
		_check_controller_path(controller, "distant_keep_path", NodePath("../VistaRoot/DistantSunderedKeep"), errors)
		controller.apply_progress(0.45)
		if vista_root == null or vista_root.modulate.a < 0.9:
			errors.append("VistaController did not reveal VistaRoot at overlook progress")
		controller.apply_progress(1.0)
		if occlusion_root == null or occlusion_root.modulate.a < 0.9:
			errors.append("VistaController did not raise OcclusionRoot alpha at traversal progress")

	var trigger := scene.get_node_or_null("ExitTransitionTrigger") as SunderedKeepTransitionTrigger
	if trigger == null:
		errors.append("ExitTransitionTrigger missing")
	else:
		if String(trigger.target_scene_path) != "res://game/world/sundered_keep/sundered_keep_map.gd":
			errors.append("ExitTransitionTrigger target path is wrong: %s" % trigger.target_scene_path)
		if trigger.get_node_or_null("CollisionShape2D") == null:
			errors.append("ExitTransitionTrigger missing CollisionShape2D")
		if trigger.vista_controller_path != NodePath("../VistaController"):
			errors.append("ExitTransitionTrigger vista_controller_path is not wired")

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


func _collect_filled_collision_polygons(node: Node, errors: Array[String]) -> void:
	if node is CollisionPolygon2D:
		var polygon := node as CollisionPolygon2D
		if polygon.build_mode == CollisionPolygon2D.BUILD_SOLIDS:
			errors.append("Filled CollisionPolygon2D solid is not allowed for approach path boundary: %s" % polygon.get_path())
	for child in node.get_children():
		_collect_filled_collision_polygons(child, errors)


func _vec2_nearly_equal(a: Vector2, b: Vector2, epsilon := 0.01) -> bool:
	return absf(a.x - b.x) <= epsilon and absf(a.y - b.y) <= epsilon
