extends SceneTree

const FIXTURE := preload("res://tools/validation/helpers/route_runtime_fixture.gd")
const MANAGER_SCRIPT := preload("res://game/world/routes/route_traversal_manager.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var cases: Array[Dictionary] = [
		{"label": "state_restore", "flags": {"fail_state_restore": true}, "persistent": true},
		{"label": "completion", "flags": {"fail_completion": true}},
		{"label": "camera", "flags": {"fail_camera": true}},
		{"label": "duplicate_exit", "flags": {"duplicate_exit_id": true}},
		{"label": "empty_exit", "flags": {"empty_exit_id": true}},
	]
	for test_case: Dictionary in cases:
		await _run_entry_case(test_case, errors)
	await _run_node_to_node_case(errors)
	_finish(errors)


func _run_entry_case(test_case: Dictionary, errors: Array[String]) -> void:
	var helper := FIXTURE.new()
	var options := {"a_flags": test_case.flags}
	if bool(test_case.get("persistent", false)):
		options["a_state"] = "persistent"
	var fixture: Dictionary = helper.create(self, "entry_post_commit_%s" % test_case.label, options)
	if bool(test_case.get("persistent", false)):
		fixture.manager.call("get_route_state_store").call(
			"set_node_state", &"fixture_route", &"a", {"test_state": 41}
		)
	if helper.enter(fixture):
		errors.append("%s initial entry unexpectedly succeeded" % test_case.label)
	_assert_clean_initial_failure(fixture, str(test_case.label), errors)
	var definition: RefCounted = fixture.loader.call("get_definition", &"fixture_a")
	definition.set("target_scene_path", fixture.paths.level_a_retry_scene)
	if not helper.enter(fixture):
		errors.append("%s immediate retry failed" % test_case.label)
	elif fixture.manager.call("get_current_node_id") != &"a":
		errors.append("%s retry did not enter node a" % test_case.label)
	fixture.game_root.queue_free()
	await process_frame


func _assert_clean_initial_failure(fixture: Dictionary, label: String, errors: Array[String]) -> void:
	if fixture.manager.call("has_active_route"):
		errors.append("%s retained an active route" % label)
	if fixture.loader.call("get_active_level_instance") != null:
		errors.append("%s retained loader instance authority" % label)
	if not (fixture.loader.call("get_active_level_id") as StringName).is_empty():
		errors.append("%s retained loader level identity" % label)
	if fixture.actor.process_mode == Node.PROCESS_MODE_DISABLED:
		errors.append("%s left actor disabled" % label)
	if fixture.manager.call("get_phase") != MANAGER_SCRIPT.TransitionPhase.IDLE:
		errors.append("%s did not return manager to IDLE" % label)


func _run_node_to_node_case(errors: Array[String]) -> void:
	var helper := FIXTURE.new()
	var fixture: Dictionary = helper.create(
		self,
		"entry_post_commit_node_rollback",
		{"b_flags": {"fail_completion": true}}
	)
	if not helper.enter(fixture):
		errors.append("node rollback route entry failed")
		fixture.game_root.queue_free()
		await process_frame
		return
	var source: Node = fixture.loader.call("get_active_level_instance")
	var original_position: Vector2 = fixture.actor.global_position
	if bool(fixture.manager.call("request_exit", &"continue", fixture.actor)):
		errors.append("node rollback failure reported success")
	if fixture.manager.call("get_current_node_id") != &"a":
		errors.append("node rollback changed current node")
	if fixture.loader.call("get_active_level_instance") != source:
		errors.append("node rollback did not restore loader source")
	if not fixture.actor.global_position.is_equal_approx(original_position):
		errors.append("node rollback changed actor position")
	if not source.visible or source.process_mode == Node.PROCESS_MODE_DISABLED:
		errors.append("node rollback did not restore source activation")
	var source_exit := source.find_child("Exit_Continue", true, false) as LevelExit2D
	if source_exit == null or source_exit.is_transition_locked():
		errors.append("node rollback did not rebind and unlock source exits")
	fixture.game_root.queue_free()
	await process_frame


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[RouteEntryPostCommitRollbackSmoke] PASS")
		quit(0)
		return
	for error: String in errors:
		push_error("[RouteEntryPostCommitRollbackSmoke] %s" % error)
	quit(1)
