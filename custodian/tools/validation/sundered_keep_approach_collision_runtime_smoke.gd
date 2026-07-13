extends SceneTree

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var scene := APPROACH_SCENE.instantiate() as Node2D
	if scene == null:
		_fail(["Could not instantiate SunderedKeepApproach"])
		return
	root.add_child(scene)
	await process_frame
	await physics_frame

	var boundary := scene.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary == null:
		_fail(["Missing Collision/PathBoundaryCollision"])
		return
	if boundary.collision_layer != 1:
		errors.append("PathBoundaryCollision layer expected 1, got %d" % boundary.collision_layer)

	var probe := CharacterBody2D.new()
	probe.name = "CollisionProbe"
	probe.collision_layer = 2
	probe.collision_mask = 1
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var capsule := CapsuleShape2D.new()
	capsule.radius = 10.0
	capsule.height = 28.0
	shape.shape = capsule
	probe.add_child(shape)
	root.add_child(probe)
	await physics_frame

	# Cross the first mapped rail after ROUTE_VERTICAL_OFFSET has been applied.
	probe.global_position = Vector2(-20.0, 530.0)
	var collision := probe.move_and_collide(Vector2(-100.0, 0.0), true)
	if collision == null:
		errors.append("Collision probe did not hit the mapped approach rail")
	else:
		var collider := collision.get_collider() as Node
		if collider == null or collider.name != "PathBoundaryCollision":
			errors.append("Collision probe hit %s instead of PathBoundaryCollision" % (collider.name if collider != null else "null"))

	if errors.is_empty():
		print("[SunderedKeepApproachCollisionRuntimeSmoke] PASS")
		quit(0)
	else:
		_fail(errors)


func _fail(errors: Array[String]) -> void:
	for error in errors:
		push_error("[SunderedKeepApproachCollisionRuntimeSmoke] %s" % error)
	quit(1)
