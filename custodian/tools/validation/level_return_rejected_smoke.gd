extends SceneTree

const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")
const AUTHORED_LEVEL_SCRIPT := preload("res://game/world/levels/authored_level_2d.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "rejected_return", &"gameplay", &"Spawn_Main")
	fixture.ingress.set("_triggered", true)
	fixture.ingress.call("_enter_approach", fixture.actor)
	var active: Node = fixture.loader.call("get_active_level_instance") as Node
	var rogue: Node2D = AUTHORED_LEVEL_SCRIPT.new()
	rogue.name = "NonActiveAuthoredLevel"
	rogue.draw_placeholder_grid = false
	var collision_root := Node2D.new()
	collision_root.name = "Collision"
	rogue.add_child(collision_root)
	var boundary := StaticBody2D.new()
	boundary.name = "PathBoundaryCollision"
	collision_root.add_child(boundary)
	fixture.world.add_child(rogue)
	rogue.call("configure_level_runtime", {"level_loader": fixture.loader})
	rogue.call("return_to_main", fixture.actor)
	var errors: Array[String] = []
	if active == null:
		errors.append("fixture level did not activate")
	if fixture.loader.call("get_active_level_instance") != active:
		errors.append("rejected return changed loader authority")
	if fixture.procgen.visible or fixture.procgen.process_mode != Node.PROCESS_MODE_DISABLED:
		errors.append("rejected return partially restored the world")
	if not bool(fixture.ingress.call("is_triggered")):
		errors.append("rejected return reset the origin ingress")
	if not rogue.visible or rogue.process_mode == Node.PROCESS_MODE_DISABLED:
		errors.append("AuthoredLevel2D executed its legacy fallback after loader rejection")
	if active != null:
		active.call("return_to_main", fixture.actor)
		await process_frame
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[LevelReturnRejectedSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[LevelReturnRejectedSmoke] %s" % error)
	quit(1)
