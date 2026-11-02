extends SceneTree
const FIXTURE := preload("res://tools/validation/helpers/route_runtime_fixture.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var helper := FIXTURE.new(); var f: Dictionary = helper.create(self, "world_exfil")
	var origin: Vector2 = f.actor.global_position; var errors: Array[String] = []
	if not helper.enter(f): errors.append("route entry failed")
	var active: Node = f.loader.call("get_active_level_instance")
	if not bool(f.manager.call("request_exit", &"return_world", f.actor)): errors.append("world exfil failed")
	await process_frame
	if f.manager.call("has_active_route"): errors.append("session survived exfil")
	if f.loader.call("get_active_level_instance") != null: errors.append("loader authority survived exfil")
	if is_instance_valid(active): errors.append("route node survived route end")
	if not f.actor.global_position.is_equal_approx(origin): errors.append("actor origin was not restored")
	if not f.procgen.visible or f.procgen.process_mode != Node.PROCESS_MODE_ALWAYS: errors.append("origin branch state was not restored")
	if f.ingress.call("is_triggered"): errors.append("ingress did not reset")
	finish(errors)
func finish(errors: Array[String]) -> void:
	if errors.is_empty(): print("[RouteWorldExfilSmoke] PASS"); quit(0); return
	for error in errors: push_error("[RouteWorldExfilSmoke] %s" % error)
	quit(1)
