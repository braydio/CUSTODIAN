extends SceneTree

const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "physics_reentry", &"gameplay", &"Spawn_Main")
	var old_actor: Node = fixture.actor
	var origin_position := (old_actor as Node2D).global_position
	old_actor.free()
	var actor := CharacterBody2D.new()
	actor.name = "Operator"
	actor.add_to_group("player")
	actor.global_position = origin_position
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	actor.add_child(collision)
	(fixture.world as Node).add_child(actor)
	var ingress: Area2D = fixture.ingress
	var loader: Node = fixture.loader
	await physics_frame
	await physics_frame
	var errors: Array[String] = []
	var first: Node = loader.call("get_active_level_instance") as Node
	if first == null:
		errors.append("physics body_entered did not activate the first level")
	else:
		first.call("return_to_main", actor)
		await process_frame
	actor.global_position = origin_position + Vector2(512.0, 0.0)
	await physics_frame
	await physics_frame
	actor.global_position = origin_position
	await physics_frame
	await physics_frame
	var second: Node = loader.call("get_active_level_instance") as Node
	if second == null:
		errors.append("physical leave/re-enter did not activate a second level")
	elif second == first:
		errors.append("physical re-entry reused the released instance")
	if second != null:
		second.call("return_to_main", actor)
		await process_frame
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[WorldIngressPhysicsReentrySmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[WorldIngressPhysicsReentrySmoke] %s" % error)
	quit(1)
