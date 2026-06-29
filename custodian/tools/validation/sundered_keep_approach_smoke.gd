extends SceneTree

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")

const EXPECTED_SPRITE_RECTS := {
	"PathSprites/MainlandApproachPath": Rect2(Vector2(-300, 120), Vector2(470, 400)),
	"PathSprites/HillClimbPath": Rect2(Vector2(-190, -120), Vector2(400, 240)),
	"PathSprites/OverlookLedge": Rect2(Vector2(-320, -320), Vector2(640, 200)),
	"PathSprites/LateralTraversePath": Rect2(Vector2(260, -260), Vector2(520, 180)),
	"PathSprites/FortressWallMass": Rect2(Vector2(650, -420), Vector2(350, 380)),
	"Occlusion/CliffOccluder": Rect2(Vector2(520, -420), Vector2(520, 540)),
	"Occlusion/WallShadowOccluder": Rect2(Vector2(-900, -360), Vector2(2100, 130)),
	"VistaUnderlay/UnderlayFogBand": Rect2(Vector2(-900, -620), Vector2(2100, 360)),
	"VistaUnderlay/DistantKeepProxy": Rect2(Vector2(-900, -720), Vector2(2100, 480)),
}


func _init() -> void:
	var scene := APPROACH_SCENE.instantiate() as Node2D
	if scene == null:
		_fail("Could not instantiate SunderedKeepApproach")
		return
	root.add_child(scene)
	await process_frame

	var errors: Array[String] = []

	var entry := scene.get_node_or_null("EntrySpawn") as Marker2D
	if entry == null:
		errors.append("EntrySpawn missing")
	elif entry.position != Vector2(-65, 470):
		errors.append("EntrySpawn expected (-65, 470), got %s" % entry.position)
	if scene.get_node_or_null("ProgressStart") == null:
		errors.append("ProgressStart missing")
	if scene.get_node_or_null("ProgressEnd") == null:
		errors.append("ProgressEnd missing")

	if bool(scene.get("enable_route_blockers")):
		errors.append("enable_route_blockers should default false while the approach is tuned")

	var backdrop := scene.get_node_or_null("ApproachVoidBackdrop") as ColorRect
	if backdrop == null:
		errors.append("ApproachVoidBackdrop missing")
	elif backdrop.color.a < 1.0:
		errors.append("ApproachVoidBackdrop should be opaque")

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
		_check_sprite_rect(node_path, sprite, EXPECTED_SPRITE_RECTS[node_path] as Rect2, errors)

	var cliff_start := scene.get_node_or_null("Occlusion/CliffOccluder") as CanvasItem
	if cliff_start == null or cliff_start.modulate.a > 0.01:
		errors.append("CliffOccluder should start hidden; alpha=%s" % (cliff_start.modulate.a if cliff_start else "missing"))
	var shadow_start := scene.get_node_or_null("Occlusion/WallShadowOccluder") as CanvasItem
	if shadow_start == null or shadow_start.modulate.a > 0.01:
		errors.append("WallShadowOccluder should start hidden; alpha=%s" % (shadow_start.modulate.a if shadow_start else "missing"))
	var fog_start := scene.get_node_or_null("VistaUnderlay/UnderlayFogBand") as CanvasItem
	if fog_start == null or fog_start.modulate.a < 0.24 or fog_start.modulate.a > 0.31:
		errors.append("UnderlayFogBand should start at low alpha around 0.25; alpha=%s" % (fog_start.modulate.a if fog_start else "missing"))

	var walkable_areas := scene.get_node_or_null("Gameplay/WalkableAreas")
	if walkable_areas == null:
		errors.append("Gameplay/WalkableAreas missing")
	else:
		_collect_static_bodies_under(walkable_areas, "WalkableAreas must not contain StaticBody2D", errors)
		_check_walkable_area(walkable_areas, "MainlandApproachWalkArea", errors)
		_check_walkable_area(walkable_areas, "HillClimbWalkArea", errors)
		_check_walkable_area(walkable_areas, "OverlookLedgeWalkArea", errors)
		_check_walkable_area(walkable_areas, "LateralTraverseWalkArea", errors)

	var blockers := scene.get_node_or_null("Gameplay/Blockers")
	if blockers == null:
		errors.append("Gameplay/Blockers missing")
	elif _count_static_bodies(blockers) > 0:
		errors.append("Gameplay/Blockers should be empty when enable_route_blockers is false")

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


func _vec2_nearly_equal(a: Vector2, b: Vector2, epsilon := 0.01) -> bool:
	return absf(a.x - b.x) <= epsilon and absf(a.y - b.y) <= epsilon


func _check_walkable_area(parent: Node, node_name: String, errors: Array[String]) -> void:
	var area := parent.get_node_or_null(node_name) as Area2D
	if area == null:
		errors.append("%s missing or not Area2D" % node_name)
		return
	if area.collision_layer != 0 or area.collision_mask != 0:
		errors.append("%s should use collision layer/mask 0" % node_name)
	if area.monitoring or area.monitorable:
		errors.append("%s should not monitor or be monitorable" % node_name)
	if not bool(area.get_meta("walkable_area", false)):
		errors.append("%s missing walkable_area metadata" % node_name)


func _collect_static_bodies_under(node: Node, reason: String, errors: Array[String]) -> void:
	if node == null:
		return
	if node is StaticBody2D:
		errors.append("%s: %s" % [reason, node.get_path()])
	for child in node.get_children():
		_collect_static_bodies_under(child, reason, errors)


func _count_static_bodies(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is StaticBody2D:
		count += 1
	for child in node.get_children():
		count += _count_static_bodies(child)
	return count
