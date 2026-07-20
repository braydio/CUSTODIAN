extends SceneTree

const FIXTURE_SCRIPT := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture: Dictionary = FIXTURE_SCRIPT.new().create(self, "reentry", &"gameplay", &"Spawn_Main")
	var ingress: Node = fixture.ingress
	var actor: Node = fixture.actor
	var loader: Node = fixture.loader
	var errors: Array[String] = []
	ingress.set("_triggered", true)
	ingress.call("_enter_approach", actor)
	var first: Node = loader.call("get_active_level_instance") as Node
	if first == null:
		errors.append("first entry failed")
	else:
		first.call("return_to_main", actor)
		await process_frame
	ingress.set("_triggered", true)
	ingress.call("_enter_approach", actor)
	var second: Node = loader.call("get_active_level_instance") as Node
	if second == null:
		errors.append("second entry failed")
	elif second == first:
		errors.append("re-entry reused a released instance")
	var active_count := 0
	for node in get_nodes_in_group("authored_level"):
		if is_instance_valid(node) and node.process_mode != Node.PROCESS_MODE_DISABLED:
			active_count += 1
	if active_count != 1:
		errors.append("expected one active authored level after re-entry, got %d" % active_count)
	if second != null:
		second.call("return_to_main", actor)
		await process_frame
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[AuthoredLevelReentrySmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[AuthoredLevelReentrySmoke] %s" % error)
	quit(1)
