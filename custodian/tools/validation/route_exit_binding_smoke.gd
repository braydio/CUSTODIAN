extends SceneTree
const FIXTURE := preload("res://tools/validation/helpers/route_runtime_fixture.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var helper := FIXTURE.new(); var f: Dictionary = helper.create(self, "exit_binding", {"trigger_exits": true})
	var errors: Array[String] = []
	if not helper.enter(f): errors.append("route entry failed")
	var active: Node = f.loader.call("get_active_level_instance")
	var exit := active.find_child("Exit_Continue", true, false) as LevelExit2D
	if exit == null or exit.transition_requested.get_connections().is_empty(): errors.append("active exit was not bound")
	if exit != null:
		f.actor.global_position = exit.global_position
		await physics_frame; await process_frame; await physics_frame; await process_frame
	if f.manager.call("get_current_node_id") != &"b": errors.append("physics body entry did not traverse")
	finish(errors)
func finish(errors: Array[String]) -> void:
	if errors.is_empty(): print("[RouteExitBindingSmoke] PASS"); quit(0); return
	for error in errors: push_error("[RouteExitBindingSmoke] %s" % error)
	quit(1)
