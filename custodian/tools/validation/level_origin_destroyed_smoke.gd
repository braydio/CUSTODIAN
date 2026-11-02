extends SceneTree

const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "destroyed_origin", &"gameplay", &"Spawn_Main")
	fixture.ingress.set("_triggered", true)
	fixture.ingress.call("_enter_approach", fixture.actor)
	var level: Node = fixture.loader.call("get_active_level_instance") as Node
	fixture.connected.free()
	var returned := bool(fixture.loader.call("complete_return_to_world", level, fixture.actor))
	var errors: Array[String] = []
	if returned:
		errors.append("return succeeded despite a destroyed origin branch")
	if fixture.loader.call("get_active_level_instance") != level:
		errors.append("failed restoration cleared active-level authority")
	if fixture.procgen.visible or fixture.procgen.process_mode != Node.PROCESS_MODE_DISABLED:
		errors.append("failed restoration partially reactivated the surviving origin branch")
	if level != null:
		if level.process_mode == Node.PROCESS_MODE_DISABLED:
			errors.append("failed restoration did not reactivate the outgoing level")
		if level is CanvasItem and not (level as CanvasItem).visible:
			errors.append("failed restoration left the outgoing level hidden")
	if not bool(fixture.ingress.call("is_triggered")):
		errors.append("failed restoration reset the ingress")
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[LevelOriginDestroyedSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[LevelOriginDestroyedSmoke] %s" % error)
	quit(1)
