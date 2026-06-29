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

	var path_sprites := scene.get_node_or_null("PathSprites")
	var vista_underlay := scene.get_node_or_null("VistaUnderlay")
	var occlusion := scene.get_node_or_null("Occlusion")
	var walkable_areas := scene.get_node_or_null("Gameplay/WalkableAreas")
	var blockers := scene.get_node_or_null("Gameplay/Blockers")

	if path_sprites == null:
		bad.append("Missing PathSprites")
	if vista_underlay == null:
		bad.append("Missing VistaUnderlay")
	if occlusion == null:
		bad.append("Missing Occlusion")
	if walkable_areas == null:
		bad.append("Missing Gameplay/WalkableAreas")
	if blockers == null:
		bad.append("Missing Gameplay/Blockers")

	_collect_collision_under(path_sprites, "PathSprites must be visual only", bad)
	_collect_collision_under(vista_underlay, "VistaUnderlay must be visual only", bad)
	_collect_collision_under(occlusion, "Occlusion must be visual only", bad)
	_collect_static_bodies_under(walkable_areas, "WalkableAreas must not contain StaticBody2D", bad)

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


func _collect_static_bodies_under(node: Node, reason: String, bad: Array[String]) -> void:
	if node == null:
		return

	if node is StaticBody2D:
		bad.append("%s: %s" % [reason, node.get_path()])

	for child in node.get_children():
		_collect_static_bodies_under(child, reason, bad)


func _fail(message: String) -> void:
	push_error("[SunderedKeepApproachCollisionSmoke] %s" % message)
	quit(1)
