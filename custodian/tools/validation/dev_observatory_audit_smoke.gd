extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const BULLET_SCENE := preload("res://game/actors/projectiles/bullet.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var observatory := root.get_node_or_null("DevObservatory")
	if observatory == null:
		push_error("[DevObservatoryAuditSmoke] DevObservatory autoload missing")
		quit(1)
		return
	observatory.clear()
	var game_root := Node2D.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	current_scene = game_root
	var world := Node2D.new()
	world.name = "World"
	game_root.add_child(world)
	var entities := Node2D.new()
	entities.name = "Entities"
	world.add_child(entities)
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	world.add_child(projectiles)
	var operator := OPERATOR_SCENE.instantiate()
	operator.name = "AuditOperator"
	entities.add_child(operator)
	await process_frame

	var attack_context := {"attack_id": "audit:1", "attacker_id": 77, "target_id": operator.get_instance_id()}
	var result: Dictionary = operator.receive_enemy_hit(7.0, &"melee", "enemy", null, Vector2.DOWN, -1.0, attack_context)
	if String(result.get("result", "")) != "damaged":
		failures.append("enemy-to-Operator audit hit did not resolve")
	if not is_equal_approx(float(observatory.counters.get("player_damage_amount_total", 0.0)), 7.0):
		failures.append("cumulative player damage amount did not record applied damage")
	for event_kind in [&"incoming_hit_result", &"player_damage"]:
		var matching: Array = observatory.get_recent_events(20, event_kind)
		if matching.is_empty() or str((matching[0] as Dictionary).get("data", {}).get("attack_id", "")) != "audit:1":
			failures.append("%s did not retain shared attack_id" % event_kind)
	operator.restore_health(3.0)
	if not is_equal_approx(float(observatory.counters.get("player_healing_amount_total", 0.0)), 3.0):
		failures.append("cumulative player healing amount did not record applied healing")
	operator.take_damage(2.0, false, {"guard_blocked": true})
	if not is_equal_approx(float(observatory.counters.get("player_chip_damage_amount_total", 0.0)), 2.0):
		failures.append("cumulative chip damage amount did not record guarded damage")
	operator.call("_log_ranged_fire_failure", &"no_reserve_ammo")
	if int(observatory.counters.get("player_ranged_fire_failure_no_reserve_ammo", 0)) != 1:
		failures.append("ranged reason-specific counter missing")
	if int(observatory.counters.get("player_ranged_fire_failure_empty", 0)) != 1:
		failures.append("ranged category counter missing")

	operator.current_health = operator.max_health
	operator.start_field_patch()
	if int(observatory.counters.get("field_patch_rejected_full_health", 0)) != 1:
		failures.append("Field Patch rejection reason counter missing")
	operator.current_health = operator.max_health * 0.4
	operator.health = operator.current_health
	operator.field_patch_count = 2
	operator.call("_update_field_patch_observability", 0.25)
	var patch_status: Dictionary = operator.call("get_field_patch_status")
	if not bool(patch_status.get("prompt_visible", false)) or int(observatory.counters.get("field_patch_prompt_shown", 0)) != 1:
		failures.append("Field Patch warning prompt telemetry missing")
	operator.current_health = operator.max_health * 0.2
	operator.health = operator.current_health
	operator.call("_update_field_patch_observability", 0.25)
	patch_status = operator.call("get_field_patch_status")
	if not bool(patch_status.get("prompt_critical", false)) or int(observatory.counters.get("field_patch_prompt_shown", 0)) != 2:
		failures.append("Field Patch critical prompt transition missing")

	var grunt := GRUNT_SCENE.instantiate()
	grunt.name = "AuditGrunt"
	entities.add_child(grunt)
	await process_frame
	grunt.set_physics_process(false)
	grunt.target = operator
	grunt.global_position = Vector2.ZERO
	operator.global_position = Vector2(500.0, 0.0)
	grunt.call("_start_attack_windup", 5.0, false)
	grunt.call("_execute_queued_attack")
	if int(observatory.counters.get("enemy_attack_whiffed_out_of_range", 0)) != 1:
		failures.append("enemy range-whiff reason counter missing")
	var whiffs: Array = observatory.get_recent_events(10, &"enemy_attack_whiff")
	if whiffs.is_empty() or str((whiffs[0] as Dictionary).get("data", {}).get("reason", "")) != "target_out_of_range":
		failures.append("enemy whiff event did not retain terminal range reason")

	var node_stats: Dictionary = observatory.call("_collect_node_stats", game_root)
	var bullet := BULLET_SCENE.instantiate()
	projectiles.add_child(bullet)
	await process_frame
	node_stats = observatory.call("_collect_node_stats", game_root)
	if not bullet.is_in_group("projectiles"):
		failures.append("active bullet root must belong to projectiles group")
	if int(node_stats.get("collision_shape_count_projectiles", 0)) < 1:
		failures.append("an active bullet must own at least one classified projectile collision shape")
	for gauge_name in [
		"collision_shape_count_runtime_walls",
		"collision_shape_count_foliage",
		"collision_shape_count_ruin_props",
		"collision_shape_count_enemies",
		"collision_shape_count_projectiles",
		"physics_body_count_runtime_walls",
		"physics_body_count_foliage",
		"physics_body_count_ruin_props",
	]:
		if not node_stats.has(gauge_name):
			failures.append("split collision gauge missing: %s" % gauge_name)
	observatory.call("_sample_runtime_gauges")
	for peak_gauge in ["node_count_peak", "physics_body_count_peak", "collision_shape_count_peak", "loaded_world_branch_count", "loaded_procgen_root_count"]:
		if not observatory.gauges.has(peak_gauge):
			failures.append("performance/leak gauge missing: %s" % peak_gauge)

	operator.stamina = 33.0
	operator.set("_pending_ranged_shot", {"timer": 1.0, "profile": {}, "aim_direction": Vector2.RIGHT})
	observatory.increment(&"player_ranged_fire_requests")
	operator.set("_last_damage_kind", &"physical")
	operator.set("_last_enemy_attack_kind", &"melee")
	operator.call("_handle_death")
	var death_events: Array = observatory.get_recent_events(2, &"player_death")
	if death_events.is_empty():
		failures.append("player death snapshot event missing")
	else:
		var death_data: Dictionary = (death_events[0] as Dictionary).get("data", {})
		for field in ["health", "stamina", "field_patches_remaining", "seconds_below_half_health_with_patch_available", "last_damage_kind", "last_enemy_attack_kind", "nearest_enemy_count", "active_enemy_count"]:
			if not death_data.has(field):
				failures.append("player death snapshot missing %s" % field)
	if int(observatory.counters.get("field_patch_prompt_ignored_on_death", 0)) != 1:
		failures.append("ignored Field Patch prompt death counter missing")
	if int(observatory.counters.get("player_ranged_request_cancelled_death", 0)) != 1:
		failures.append("pending ranged request was not terminally cancelled on death")
	for gauge_name in ["player_alive", "player_dead", "player_last_live_weapon_id", "player_last_live_loaded_ammo", "player_last_live_reserve_ammo", "player_last_live_stamina"]:
		if not observatory.gauges.has(gauge_name):
			failures.append("post-death resource context gauge missing: %s" % gauge_name)

	if failures.is_empty():
		print("DEV_OBSERVATORY_AUDIT_SMOKE: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("[DevObservatoryAuditSmoke] %s" % failure)
	quit(1)
