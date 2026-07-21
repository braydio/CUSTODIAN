extends SceneTree
const FIXTURE := preload("res://tools/validation/helpers/authored_level_lifecycle_fixture.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var f: Dictionary = FIXTURE.new().create(self, "single_route", &"gameplay", &"Spawn_Main")
	var errors: Array[String] = []
	f.ingress.set("_triggered", true); f.ingress.call("_enter_approach", f.actor)
	if f.route_manager.call("get_current_route_id") != StringName("single_%s" % f.level_id): errors.append("internal single-level route was not created")
	if f.route_manager.call("get_current_node_id") != &"single": errors.append("single node was not activated")
	if not bool(f.route_manager.call("request_exit", &"return_world", f.actor)): errors.append("default return_world edge failed")
	if f.route_manager.call("has_active_route"): errors.append("single-level route did not end")
	if errors.is_empty(): print("[RouteSingleLevelWrapperSmoke] PASS"); quit(0); return
	for error in errors: push_error("[RouteSingleLevelWrapperSmoke] %s" % error)
	quit(1)
