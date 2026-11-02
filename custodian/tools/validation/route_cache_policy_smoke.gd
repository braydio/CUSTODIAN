extends SceneTree
const FIXTURE := preload("res://tools/validation/helpers/route_runtime_fixture.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var errors: Array[String] = []
	for policy in ["destroy_on_exit", "destroy_on_forward_exit", "keep_during_route", "snapshot_and_unload"]:
		var helper := FIXTURE.new(); var f: Dictionary = helper.create(self, "cache_%s" % policy, {"a_cache": policy, "b_cache": policy})
		if not helper.enter(f): errors.append("%s entry failed" % policy); continue
		var first: Node = f.loader.call("get_active_level_instance")
		f.manager.call("request_exit", &"continue", f.actor); await process_frame
		var retained_expected: bool = policy == "keep_during_route"
		if is_instance_valid(first) != retained_expected: errors.append("%s forward retention mismatch" % policy)
		var first_b: Node = f.loader.call("get_active_level_instance")
		f.manager.call("request_exit", &"backtrack", f.actor); await process_frame
		var revisit: Node = f.loader.call("get_active_level_instance")
		if retained_expected and revisit != first: errors.append("%s did not reuse retained instance" % policy)
		if not retained_expected and revisit == first: errors.append("%s reused an unloaded instance" % policy)
		var back_retained_expected: bool = policy in ["destroy_on_forward_exit", "keep_during_route"]
		if is_instance_valid(first_b) != back_retained_expected: errors.append("%s back-edge retention mismatch" % policy)
		f.manager.call("request_exit", &"continue", f.actor)
		var revisit_b: Node = f.loader.call("get_active_level_instance")
		if back_retained_expected and revisit_b != first_b: errors.append("%s did not reuse back-retained instance" % policy)
		if not back_retained_expected and revisit_b == first_b: errors.append("%s reused back-unloaded instance" % policy)
		f.manager.call("request_exit", &"return_world", f.actor); f.game_root.queue_free(); await process_frame
	if errors.is_empty(): print("[RouteCachePolicySmoke] PASS"); quit(0); return
	for error in errors: push_error("[RouteCachePolicySmoke] %s" % error)
	quit(1)
