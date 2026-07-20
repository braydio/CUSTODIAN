extends SceneTree

const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "single_authority", &"gameplay", &"Spawn_Main")
	fixture.ingress.set("_triggered", true)
	fixture.ingress.call("_enter_approach", fixture.actor)
	var level: Node = fixture.loader.call("get_active_level_instance") as Node
	var errors: Array[String] = []
	if level == null:
		errors.append("fixture level did not activate")
	else:
		var returned := bool(fixture.loader.call("complete_return_to_world", level, fixture.actor))
		if not returned:
			errors.append("valid return was rejected")
		if level.process_mode != Node.PROCESS_MODE_DISABLED:
			errors.append("outgoing level still processed during the return call")
		if level is CanvasItem and (level as CanvasItem).visible:
			errors.append("outgoing level remained visible during the return call")
		if not fixture.procgen.visible or fixture.procgen.process_mode != Node.PROCESS_MODE_ALWAYS:
			errors.append("origin did not resume after outgoing authority was disabled")
		if fixture.loader.call("get_active_level_instance") != null:
			errors.append("loader retained active authority after successful return")
		if bool(fixture.ingress.call("is_triggered")):
			errors.append("ingress was not synchronously reset")
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[LevelReturnSingleAuthoritySmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[LevelReturnSingleAuthoritySmoke] %s" % error)
	quit(1)
