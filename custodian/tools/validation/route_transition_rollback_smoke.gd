extends SceneTree
const FIXTURE := preload("res://tools/validation/helpers/route_runtime_fixture.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var errors: Array[String] = []
	var cases := [
		["activation", {"b_flags": {"fail_activation": true}}],
		["spawn", {"b_missing_actual_spawn": true}],
		["camera", {"b_flags": {"fail_camera": true}}],
	]
	for test_case in cases:
		var helper := FIXTURE.new(); var f: Dictionary = helper.create(self, "rollback_%s" % test_case[0], test_case[1])
		if not helper.enter(f): errors.append("%s route entry failed" % test_case[0]); continue
		var source: Node = f.loader.call("get_active_level_instance"); var position: Vector2 = f.actor.global_position
		if bool(f.manager.call("request_exit", &"continue", f.actor)): errors.append("%s failure reported success" % test_case[0])
		_assert_source_preserved(f, source, position, str(test_case[0]), errors)
		f.game_root.queue_free(); await process_frame
	var load_helper := FIXTURE.new(); var load_fixture: Dictionary = load_helper.create(self, "rollback_load")
	if load_helper.enter(load_fixture):
		var load_source: Node = load_fixture.loader.call("get_active_level_instance"); var load_position: Vector2 = load_fixture.actor.global_position
		load_fixture.loader.call("get_definition", &"fixture_b").target_scene_path = "user://missing_route_target.tscn"
		if bool(load_fixture.manager.call("request_exit", &"continue", load_fixture.actor)): errors.append("load failure reported success")
		_assert_source_preserved(load_fixture, load_source, load_position, "load", errors)
	load_fixture.game_root.queue_free(); await process_frame
	var state_helper := FIXTURE.new(); var state_fixture: Dictionary = state_helper.create(self, "rollback_state", {"b_cache": "snapshot_and_unload", "b_flags": {"fail_state_restore": true}})
	if state_helper.enter(state_fixture):
		state_fixture.manager.call("request_exit", &"continue", state_fixture.actor)
		var b: Node = state_fixture.loader.call("get_active_level_instance"); b.test_state = 9
		state_fixture.manager.call("request_exit", &"backtrack", state_fixture.actor); await process_frame
		var state_source: Node = state_fixture.loader.call("get_active_level_instance"); var state_position: Vector2 = state_fixture.actor.global_position
		if bool(state_fixture.manager.call("request_exit", &"continue", state_fixture.actor)): errors.append("state failure reported success")
		_assert_source_preserved(state_fixture, state_source, state_position, "state", errors)
	finish(errors)


func _assert_source_preserved(f: Dictionary, source: Node, position: Vector2, label: String, errors: Array[String]) -> void:
	if f.manager.call("get_current_node_id") != &"a": errors.append("%s changed session node" % label)
	if f.loader.call("get_active_level_instance") != source: errors.append("%s changed loader authority" % label)
	if not source.visible or source.process_mode == Node.PROCESS_MODE_DISABLED: errors.append("%s did not reactivate source" % label)
	if not f.actor.global_position.is_equal_approx(position): errors.append("%s changed actor position" % label)
	if f.actor.process_mode == Node.PROCESS_MODE_DISABLED: errors.append("%s did not restore actor lock" % label)
	var continue_exit := source.find_child("Exit_Continue", true, false) as LevelExit2D
	if continue_exit == null or continue_exit.is_transition_locked(): errors.append("%s did not reset source exit" % label)
func finish(errors: Array[String]) -> void:
	if errors.is_empty(): print("[RouteTransitionRollbackSmoke] PASS"); quit(0); return
	for error in errors: push_error("[RouteTransitionRollbackSmoke] %s" % error)
	quit(1)
