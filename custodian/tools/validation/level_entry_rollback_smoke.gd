extends SceneTree

const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "rollback", &"cinematic", &"MissingSpawn")
	var ingress: Node = fixture.ingress
	var actor: Node2D = fixture.actor
	var loader: Node = fixture.loader
	fixture.connected.visible = false
	fixture.connected.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	var actor_position := actor.global_position
	var camera_position: Vector2 = fixture.camera.global_position
	var camera_zoom: Vector2 = fixture.camera.zoom
	ingress.set("_triggered", true)
	ingress.call("_enter_approach", actor)
	await process_frame
	var errors: Array[String] = []
	if not fixture.procgen.visible or fixture.procgen.process_mode != Node.PROCESS_MODE_ALWAYS:
		errors.append("rollback did not restore ProcGenRuntime")
	if fixture.connected.visible or fixture.connected.process_mode != Node.PROCESS_MODE_WHEN_PAUSED:
		errors.append("rollback did not restore ConnectedMaps exact state")
	if not actor.global_position.is_equal_approx(actor_position):
		errors.append("rollback leaked actor transform")
	if not fixture.camera.global_position.is_equal_approx(camera_position) or not fixture.camera.zoom.is_equal_approx(camera_zoom):
		errors.append("rollback leaked camera state")
	if fixture.ui.presentation_mode != &"gameplay" or fixture.actor.vista_presentation_enabled:
		errors.append("rollback leaked cinematic presentation")
	if loader.call("get_active_level_instance") != null:
		errors.append("failed entry left an active level")
	if bool(ingress.call("is_triggered")):
		errors.append("failed entry left the ingress triggered")
	var fixture_levels: Array[Node] = fixture.world.find_children("LifecycleFixtureLevel", "", true, false)
	if not fixture_levels.is_empty():
		errors.append("failed entry left a duplicate/incomplete level instance")
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[LevelEntryRollbackSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[LevelEntryRollbackSmoke] %s" % error)
	quit(1)
