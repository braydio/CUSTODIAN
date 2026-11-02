extends SceneTree
const FIXTURE := preload("res://tools/validation/helpers/route_runtime_fixture.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var errors: Array[String] = []
	for policy in ["reset_on_entry", "session", "persistent"]:
		var helper := FIXTURE.new(); var f: Dictionary = helper.create(self, "state_%s" % policy, {"a_state": policy, "a_cache": "snapshot_and_unload"})
		if not helper.enter(f): errors.append("%s entry failed" % policy); continue
		var a: Node = f.loader.call("get_active_level_instance"); a.test_state = 41
		f.manager.call("request_exit", &"continue", f.actor); f.manager.call("request_exit", &"backtrack", f.actor)
		var revisited: Node = f.loader.call("get_active_level_instance")
		var expected: int = 0 if policy == "reset_on_entry" else 41
		if revisited.test_state != expected: errors.append("%s revisit restored %s, expected %s" % [policy, revisited.test_state, expected])
		f.manager.call("request_exit", &"return_world", f.actor)
		await process_frame
		if not helper.enter(f): errors.append("%s second session entry failed" % policy)
		var new_session: Node = f.loader.call("get_active_level_instance")
		var new_expected: int = 41 if policy == "persistent" else 0
		if new_session.test_state != new_expected: errors.append("%s new-session state was %s, expected %s" % [policy, new_session.test_state, new_expected])
		f.manager.call("request_exit", &"return_world", f.actor)
		f.game_root.queue_free(); await process_frame
	if errors.is_empty(): print("[RouteStatePolicySmoke] PASS"); quit(0); return
	for error in errors: push_error("[RouteStatePolicySmoke] %s" % error)
	quit(1)
