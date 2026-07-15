extends SceneTree

const DroneManagerScript := preload("res://game/systems/drone/drone_manager.gd")
const DroneSquadStateScript := preload("res://game/systems/drone/drone_squad_state.gd")
const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")
const ALLIED_DROID_SCENE := preload("res://game/actors/allies/allied_infantry_droid.tscn")


class PassiveCommandTarget:
	extends Node2D

	var dead := false

	func is_passive_enemy() -> bool:
		return true

	func is_dead() -> bool:
		return dead


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_verify_squad_state()
	_verify_follow_profile_contract()
	_verify_combat_drone_fire_cancel()
	await _verify_follow_bands_and_free_roam_goals()
	await _verify_manager_propagation_and_spawn_inheritance()
	print("[DroneFollowerCommandsSmoke] ok")
	quit(0)


func _verify_squad_state() -> void:
	var state := DroneSquadStateScript.new()
	assert(state.fire_at_will, "DroneSquadState should start FIRE AT WILL.")
	assert(state.current_follow_distance == DroneCommandProfileScript.FollowDistance.CLOSE, "DroneSquadState should start CLOSE follow.")
	assert(not state.toggle_fire_at_will(), "toggle_fire_at_will should switch to HOLD FIRE.")
	assert(state.toggle_fire_at_will(), "toggle_fire_at_will should switch back to FIRE AT WILL.")
	assert(state.cycle_follow_distance() == DroneCommandProfileScript.FollowDistance.FAR, "CLOSE should cycle to FAR.")
	assert(state.cycle_follow_distance() == DroneCommandProfileScript.FollowDistance.FREE_ROAM, "FAR should cycle to FREE_ROAM.")
	assert(state.cycle_follow_distance() == DroneCommandProfileScript.FollowDistance.CLOSE, "FREE_ROAM should cycle to CLOSE.")
	var guard_position := Vector2(640.0, 384.0)
	state.set_order_anchor(guard_position)
	assert(state.has_order_anchor(), "set_order_anchor should activate guard anchoring.")
	assert(state.anchor_kind == DroneSquadStateScript.AnchorKind.ORDER_POINT, "Guard order should use ORDER_POINT anchor kind.")
	assert(state.order_anchor_position == guard_position, "Guard order should retain world position.")
	assert(state.get_anchor_label() == "GUARD", "Active order anchor should report GUARD.")
	state.clear_order_anchor()
	assert(not state.has_order_anchor(), "clear_order_anchor should restore Operator anchoring.")
	assert(state.get_anchor_label() == "FOLLOW", "Cleared order anchor should report FOLLOW.")
	var summary := state.get_summary()
	assert(summary.get("fire_at_will") == true, "Summary should include fire_at_will.")
	assert(summary.get("follow_distance") == "CLOSE", "Summary should include follow_distance.")
	assert(summary.get("max_active") == state.max_active_drones, "Summary should include max_active.")


func _verify_follow_profile_contract() -> void:
	var profile := DroneCommandProfileScript.new()
	assert(profile.follow_close_min_radius < profile.follow_close_max_radius, "CLOSE follow band should have min < max.")
	assert(profile.follow_far_min_radius < profile.follow_far_max_radius, "FAR follow band should have min < max.")
	assert(profile.follow_far_min_radius > profile.follow_close_min_radius, "FAR should start outside CLOSE.")
	assert(profile.follow_far_radius > profile.follow_close_radius, "FAR preferred radius should be larger than CLOSE.")
	assert(profile.free_roam_min_radius < profile.free_roam_max_radius, "FREE_ROAM patrol band should have min < max.")
	assert(profile.free_roam_leash_range >= profile.free_roam_max_radius, "FREE_ROAM leash should contain patrol band.")
	assert(profile.free_roam_repath_min > 0.0 and profile.free_roam_repath_max >= profile.free_roam_repath_min, "FREE_ROAM repath timing should be positive and ordered.")
	assert(profile.guard_order_engage_range <= profile.guard_order_leash_range, "Guard engage range should fit inside guard leash.")
	assert(profile.guard_order_return_range <= profile.guard_order_leash_range, "Guard return range should fit inside guard leash.")


func _verify_combat_drone_fire_cancel() -> void:
	var droid := ALLIED_DROID_SCENE.instantiate()
	assert(droid is CombatDrone, "Allied droid should inherit CombatDrone.")
	droid.set("_burst_remaining", 2)
	droid.set("_burst_gap_timer", 0.5)
	droid.call("set_fire_at_will", false)
	assert(droid.get("fire_at_will") == false, "set_fire_at_will(false) should update drone state.")
	assert(int(droid.get("_burst_remaining")) == 0, "set_fire_at_will(false) should clear queued burst count.")
	assert(is_zero_approx(float(droid.get("_burst_gap_timer"))), "set_fire_at_will(false) should clear burst gap timer.")
	droid.free()


func _verify_follow_bands_and_free_roam_goals() -> void:
	var scene_root := Node2D.new()
	scene_root.name = "DroneFollowContractRoot"
	root.add_child(scene_root)

	var operator := CharacterBody2D.new()
	operator.name = "Operator"
	scene_root.add_child(operator)
	operator.global_position = Vector2(1000.0, 1000.0)
	operator.velocity = Vector2(90.0, 0.0)

	var droid := ALLIED_DROID_SCENE.instantiate()
	scene_root.add_child(droid)
	droid.global_position = operator.global_position + Vector2(8.0, 0.0)
	droid.call("configure", 0, operator, null, DroneCommandProfileScript.new())
	await process_frame

	droid.call("set_follow_distance_mode", DroneCommandProfileScript.FollowDistance.CLOSE)
	var close_goal: Vector2 = droid.call("_get_desired_position")
	var close_distance := close_goal.distance_to(operator.global_position)
	assert(close_distance >= droid.profile.follow_player_separation_radius - 0.1, "CLOSE should keep the droid out of the Operator's feet.")

	droid.call("set_follow_distance_mode", DroneCommandProfileScript.FollowDistance.FAR)
	var far_goal: Vector2 = droid.call("_get_desired_position")
	var far_distance := far_goal.distance_to(operator.global_position)
	assert(far_distance >= droid.profile.follow_far_min_radius - 0.1, "FAR should resolve to the backline follow band.")
	assert(far_distance > close_distance + 40.0, "FAR should visibly hang back compared to CLOSE.")

	droid.call("set_follow_distance_mode", DroneCommandProfileScript.FollowDistance.FREE_ROAM)
	droid.set("_roam_repath_timer", 0.0)
	var roam_goal_a: Vector2 = droid.call("_get_desired_position")
	var roam_distance_a := roam_goal_a.distance_to(operator.global_position)
	assert(roam_distance_a >= droid.profile.free_roam_min_radius - 0.1, "FREE_ROAM should choose a local patrol goal outside escort range.")
	assert(roam_distance_a <= droid.profile.free_roam_leash_range + 0.1, "FREE_ROAM goal should stay inside leash.")

	droid.set("_roam_repath_timer", 0.0)
	var roam_goal_b: Vector2 = droid.call("_get_desired_position")
	assert(roam_goal_b.distance_to(roam_goal_a) > 8.0, "FREE_ROAM should periodically choose a new patrol goal without enemies.")
	assert(roam_goal_b.distance_to(operator.global_position) <= droid.profile.free_roam_leash_range + 0.1, "New FREE_ROAM goal should also stay leashed.")

	var guard_position := Vector2(1500.0, 1100.0)
	droid.call("set_order_anchor", guard_position)
	assert(droid.get("order_anchor_active") == true, "Droid should activate order anchor.")
	assert(droid.call("_get_anchor_position") == guard_position, "Droid should resolve guard point as active anchor.")
	droid.global_position = guard_position + Vector2(8.0, 0.0)
	var operator_enemy := Node2D.new()
	operator_enemy.name = "OperatorEnemy"
	operator_enemy.add_to_group("enemy")
	scene_root.add_child(operator_enemy)
	operator_enemy.global_position = operator.global_position + Vector2(40.0, 0.0)
	var guard_enemy := Node2D.new()
	guard_enemy.name = "GuardEnemy"
	guard_enemy.add_to_group("enemy")
	scene_root.add_child(guard_enemy)
	guard_enemy.global_position = guard_position + Vector2(80.0, 0.0)
	droid.call("_refresh_target")
	assert(droid.target == guard_enemy, "Guard targeting should prefer enemies inside the guard zone instead of near the Operator.")
	guard_enemy.global_position = guard_position + Vector2(droid.profile.guard_order_engage_range + 20.0, 0.0)
	droid.call("_refresh_target")
	assert(droid.target == null, "Guard target should clear after leaving guard engage range.")
	var freed_command_target := Node2D.new()
	freed_command_target.name = "FreedCommandTarget"
	freed_command_target.add_to_group("enemy")
	scene_root.add_child(freed_command_target)
	droid.call("set_command_target", freed_command_target)
	freed_command_target.free()
	droid.call("_refresh_target")
	assert(droid.get("command_target") == null, "Freed explicit command targets should be pruned before typed targeting checks.")
	var observatory: Node = root.get_node_or_null("/root/DevObservatory")
	if observatory != null:
		var counters: Dictionary = observatory.get("counters")
		assert(int(counters.get("drone_stale_targets_cleared", 0)) > 0, "Stale target cleanup should reach Developer Observatory.")

	droid.call("set_follow_distance_mode", DroneCommandProfileScript.FollowDistance.CLOSE)
	var guard_close_goal: Vector2 = droid.call("_get_desired_position")
	assert(guard_close_goal.distance_to(guard_position) >= droid.profile.follow_player_separation_radius - 0.1, "GUARD CLOSE should use close formation around guard point.")
	droid.call("_update_visuals")
	var status_label := droid.get_node_or_null("StatusLabel") as Label
	assert(status_label != null and status_label.text.begins_with("GUARD CLOSE"), "Droid status should expose GUARD CLOSE.")

	droid.call("set_follow_distance_mode", DroneCommandProfileScript.FollowDistance.FAR)
	var guard_far_goal: Vector2 = droid.call("_get_desired_position")
	assert(guard_far_goal.distance_to(guard_position) >= droid.profile.follow_far_min_radius - 0.1, "GUARD FAR should hold a perimeter around guard point.")

	droid.call("set_follow_distance_mode", DroneCommandProfileScript.FollowDistance.FREE_ROAM)
	droid.set("_roam_repath_timer", 0.0)
	var guard_roam_goal: Vector2 = droid.call("_get_desired_position")
	assert(guard_roam_goal.distance_to(guard_position) <= droid.profile.guard_order_leash_range + 0.1, "GUARD ROAM should stay inside guard leash.")

	droid.global_position = guard_position + Vector2(droid.profile.guard_order_return_range + 40.0, 0.0)
	droid.target = Node2D.new()
	var return_goal: Vector2 = droid.call("_get_desired_position")
	assert(droid.call("_must_return_to_order_anchor"), "Droid outside guard return range should force return.")
	assert(return_goal.distance_to(guard_position) < droid.global_position.distance_to(guard_position), "Forced return goal should move toward guard anchor.")
	droid.target.free()
	droid.target = null

	droid.call("clear_order_anchor")
	assert(droid.call("_get_anchor_position") == operator.global_position, "Recall should restore Operator anchor position.")

	scene_root.queue_free()
	await process_frame


func _verify_manager_propagation_and_spawn_inheritance() -> void:
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)

	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)

	var operator := Node2D.new()
	operator.name = "Operator"
	world.add_child(operator)

	var allies := Node2D.new()
	allies.name = "Allies"
	world.add_child(allies)

	var manager := DroneManagerScript.new()
	manager.name = "DroneManager"
	manager.spawn_on_ready = false
	manager.drone_scene = ALLIED_DROID_SCENE
	manager.announce_commands = false
	world.add_child(manager)

	var first := manager.spawn_drone(0)
	var second := manager.spawn_drone(1)
	assert(first != null and second != null, "DroneManager should spawn two droids.")

	manager.set_fire_at_will(false)
	manager.set_follow_distance(DroneCommandProfileScript.FollowDistance.FAR)
	assert(first.get("fire_at_will") == false and second.get("fire_at_will") == false, "Manager should propagate HOLD FIRE to all live droids.")
	assert(first.get("follow_distance_mode") == DroneCommandProfileScript.FollowDistance.FAR, "Manager should propagate FAR follow to first droid.")
	assert(second.get("follow_distance_mode") == DroneCommandProfileScript.FollowDistance.FAR, "Manager should propagate FAR follow to second droid.")
	var guard_position := Vector2(920.0, 760.0)
	manager.issue_guard_order(guard_position)
	assert(manager.has_guard_order(), "Manager should activate guard order.")
	assert(first.get("order_anchor_active") == true and first.get("order_anchor_position") == guard_position, "Manager should propagate guard anchor to first droid.")
	assert(second.get("order_anchor_active") == true and second.get("order_anchor_position") == guard_position, "Manager should propagate guard anchor to second droid.")
	assert(manager.get("_guard_order_marker") != null, "Guard order should create a world marker.")
	var commanded_enemy := Node2D.new()
	commanded_enemy.name = "CommandedEnemy"
	commanded_enemy.add_to_group("enemy")
	world.add_child(commanded_enemy)
	commanded_enemy.global_position = guard_position + Vector2(20.0, 0.0)
	assert(manager.call("_resolve_hostile_at_position", commanded_enemy.global_position) == commanded_enemy, "Command hover should resolve a valid hostile under the pointer.")
	manager.set("_command_hover_target", commanded_enemy)
	Input.action_press("drone_issue_guard_order")
	var reticle_state: Dictionary = manager.get_command_reticle_state()
	Input.action_release("drone_issue_guard_order")
	assert(bool(reticle_state.get("active")), "Guard-order chord should activate the command reticle.")
	assert(bool(reticle_state.get("has_hostile")), "Command reticle should report a valid hovered hostile for red tinting.")
	assert(reticle_state.get("world_position") == commanded_enemy.global_position, "Command reticle should lock to the hovered hostile position.")
	manager.issue_target_order(commanded_enemy)
	assert(first.get("command_target") == commanded_enemy and second.get("command_target") == commanded_enemy, "Target click should propagate the explicit hostile to every live droid.")
	assert(first.get("target") == commanded_enemy, "Explicit command target should become the active droid target.")
	assert(manager.squad_state.order_anchor_position == commanded_enemy.global_position, "Target click should place the guard anchor at the hostile position.")

	var commanded_shrumb := PassiveCommandTarget.new()
	commanded_shrumb.name = "CommandedShrumb"
	commanded_shrumb.add_to_group("enemy")
	commanded_shrumb.add_to_group("drone_command_target")
	world.add_child(commanded_shrumb)
	commanded_shrumb.global_position = guard_position + Vector2(30.0, 0.0)
	manager.issue_guard_order(guard_position)
	first.call("clear_command_target")
	first.target = null
	first.call("_refresh_target")
	assert(first.get("target") != commanded_shrumb, "Passive Shrumb should not be acquired automatically by fire-at-will targeting.")
	assert(manager.call("_resolve_hostile_at_position", commanded_shrumb.global_position) == commanded_shrumb, "Command hover should resolve a selectable Shrumb under the pointer.")
	manager.issue_target_order(commanded_shrumb)
	first.global_position = commanded_shrumb.global_position + Vector2(8.0, 0.0)
	first.call("_refresh_target")
	assert(first.get("command_target") == commanded_shrumb and second.get("command_target") == commanded_shrumb, "Target click should propagate an explicit Shrumb target to every live droid.")
	assert(first.get("target") == commanded_shrumb, "Explicit Shrumb command target should become the active droid target.")
	assert(manager.squad_state.order_anchor_position == commanded_shrumb.global_position, "Shrumb target click should place the guard anchor at the Shrumb position.")

	second.call("take_damage", 999.0)
	manager.set_fire_at_will(true)
	var summary: Dictionary = manager.get_squad_summary()
	assert(int(summary.get("live_count", -1)) == 1, "Destroyed droids should be pruned before command propagation.")
	assert(first.get("fire_at_will") == true, "Live droid should receive restored FIRE AT WILL.")

	first.queue_free()
	await process_frame
	var replacement := manager.spawn_drone(0)
	assert(replacement != null, "DroneManager should spawn a replacement after pruning freed droids.")
	assert(replacement.get("fire_at_will") == true, "Newly spawned droid should inherit current fire discipline.")
	assert(replacement.get("follow_distance_mode") == DroneCommandProfileScript.FollowDistance.FAR, "Newly spawned droid should inherit current follow distance.")
	assert(replacement.get("order_anchor_active") == true, "Newly spawned droid should inherit active guard order.")
	assert(replacement.get("order_anchor_position") == commanded_shrumb.global_position, "Replacement should inherit the current target-order anchor position.")
	assert(replacement.get("command_target") == commanded_shrumb, "Replacement should inherit a still-valid explicit Shrumb command target.")

	manager.recall_guard_order()
	assert(not manager.has_guard_order(), "Recall should clear manager guard state.")
	assert(replacement.get("order_anchor_active") == false, "Recall should restore replacement to Operator anchor.")
	assert(manager.get("_guard_order_marker") == null, "Recall should clear the guard-order marker reference.")
	assert(replacement.get("command_target") == null, "Recall should clear the explicit command target.")

	game_root.queue_free()
	await process_frame
