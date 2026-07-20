extends SceneTree

const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "ingress_return", &"gameplay", &"Spawn_Main")
	var ingress: Node = fixture.ingress
	var actor: Node2D = fixture.actor
	var loader: Node = fixture.loader
	var origin_position := actor.global_position
	ingress.set("_triggered", true)
	ingress.call("_enter_approach", actor)
	var errors: Array[String] = []
	var level: Node = loader.call("get_active_level_instance") as Node
	if level == null:
		errors.append("registered authored level did not activate")
	else:
		level.call("return_to_main", actor)
		await process_frame
	if not fixture.procgen.visible or fixture.procgen.process_mode != Node.PROCESS_MODE_ALWAYS:
		errors.append("ProcGenRuntime was not restored to its exact source state")
	if not fixture.connected.visible or fixture.connected.process_mode != Node.PROCESS_MODE_INHERIT:
		errors.append("ConnectedMaps was not restored")
	if not actor.global_position.is_equal_approx(origin_position):
		errors.append("actor did not return to the captured world position")
	if loader.call("get_active_level_instance") != null or not String(loader.call("get_active_level_id")).is_empty():
		errors.append("LevelLoader retained stale active-level authority")
	if bool(ingress.call("is_triggered")):
		errors.append("origin ingress remained triggered after return")
	if fixture.ui.presentation_mode != &"gameplay" or fixture.actor.vista_presentation_enabled:
		errors.append("gameplay presentation was not restored")
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[AuthoredLevelIngressReturnSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[AuthoredLevelIngressReturnSmoke] %s" % error)
	quit(1)
