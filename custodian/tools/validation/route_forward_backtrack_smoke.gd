extends SceneTree

const FIXTURE := preload("res://tools/validation/helpers/route_runtime_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var helper := FIXTURE.new()
	var fixture: Dictionary = helper.create(self, "forward_backtrack")
	var errors: Array[String] = []
	if not helper.enter(fixture):
		errors.append("route did not enter")
	var manager: Node = fixture.manager
	var loader: Node = fixture.loader
	var actor: Node2D = fixture.actor
	var first: Node = loader.call("get_active_level_instance") as Node
	if manager.call("get_current_node_id") != &"a": errors.append("entry did not activate A")
	if not actor.global_position.is_equal_approx(Vector2(100.0, 10.0)): errors.append("entry spawn was not applied")
	if not bool(manager.call("request_exit", &"continue", actor)): errors.append("forward edge failed")
	var second: Node = loader.call("get_active_level_instance") as Node
	if manager.call("get_current_node_id") != &"b": errors.append("forward edge did not activate B")
	if first == second or first.process_mode != Node.PROCESS_MODE_DISABLED: errors.append("source and target authority overlapped")
	if not bool(manager.call("request_exit", &"backtrack", actor)): errors.append("back edge failed")
	if loader.call("get_active_level_instance") != first: errors.append("keep_during_route did not reuse A")
	if manager.call("get_active_session").history.size() != 3: errors.append("route history was not updated")
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[RouteForwardBacktrackSmoke] PASS")
		quit(0)
		return
	for error in errors: push_error("[RouteForwardBacktrackSmoke] %s" % error)
	quit(1)
