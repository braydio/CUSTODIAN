extends SceneTree

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")


func _init() -> void:
	var scene := APPROACH_SCENE.instantiate()
	if scene == null:
		_fail("Could not instantiate SunderedKeepApproach")
		return

	root.add_child(scene)
	await process_frame

	var bad: Array[String] = []

	for visual_root_path in ["UnderlayRoot", "VistaRoot", "PlayableRoot", "OcclusionRoot"]:
		var visual_root := scene.get_node_or_null(visual_root_path)
		if visual_root == null:
			bad.append("Missing %s" % visual_root_path)
			continue
		_collect_collision_under(visual_root, "%s must be visual only" % visual_root_path, bad)

	var boundary := scene.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary == null:
		bad.append("Missing Collision/PathBoundaryCollision")
	else:
		var segment_count := 0
		for child in boundary.get_children():
			var shape := child as CollisionShape2D
			if shape == null:
				bad.append("PathBoundaryCollision child is not CollisionShape2D: %s" % child.get_path())
				continue
			if not (shape.shape is CapsuleShape2D):
				bad.append("PathBoundaryCollision child must use CapsuleShape2D thick rail: %s" % shape.get_path())
				continue
			segment_count += 1
		if segment_count < 13:
			bad.append("Expected at least 13 boundary rail segments, got %d" % segment_count)

	_collect_filled_collision_polygons(scene, bad)

	if not bad.is_empty():
		for item in bad:
			push_error("[SunderedKeepApproachCollisionSmoke] %s" % item)
		quit(1)
		return

	root.remove_child(scene)
	scene.free()
	await process_frame

	print("[SunderedKeepApproachCollisionSmoke] PASS")
	quit(0)


func _collect_collision_under(node: Node, reason: String, bad: Array[String]) -> void:
	if node == null:
		return

	if node is CollisionObject2D or node is CollisionShape2D or node is NavigationRegion2D:
		bad.append("%s: %s" % [reason, node.get_path()])

	for child in node.get_children():
		_collect_collision_under(child, reason, bad)


func _collect_filled_collision_polygons(node: Node, bad: Array[String]) -> void:
	if node is CollisionPolygon2D:
		var polygon := node as CollisionPolygon2D
		if polygon.build_mode == CollisionPolygon2D.BUILD_SOLIDS:
			bad.append("Filled CollisionPolygon2D solid is not allowed for approach path boundary: %s" % polygon.get_path())
	for child in node.get_children():
		_collect_filled_collision_polygons(child, bad)


func _fail(message: String) -> void:
	push_error("[SunderedKeepApproachCollisionSmoke] %s" % message)
	quit(1)
