extends SceneTree

const DroneManagerScript := preload("res://game/systems/drone/drone_manager.gd")
const DroneSquadStateScript := preload("res://game/systems/drone/drone_squad_state.gd")
const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")
const ALLIED_DROID_SCENE := preload("res://game/actors/allies/allied_infantry_droid.tscn")


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

	game_root.queue_free()
	await process_frame
