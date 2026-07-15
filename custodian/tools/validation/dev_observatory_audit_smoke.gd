extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")


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
	var operator := OPERATOR_SCENE.instantiate()
	operator.name = "AuditOperator"
	entities.add_child(operator)
	await process_frame

	var attack_context := {"attack_id": "audit:1", "attacker_id": 77, "target_id": operator.get_instance_id()}
	var result: Dictionary = operator.receive_enemy_hit(7.0, &"melee", "enemy", null, Vector2.DOWN, -1.0, attack_context)
	if String(result.get("result", "")) != "damaged":
		failures.append("enemy-to-Operator audit hit did not resolve")
	for event_kind in [&"incoming_hit_result", &"player_damage"]:
		var matching: Array = observatory.get_recent_events(20, event_kind)
		if matching.is_empty() or str((matching[0] as Dictionary).get("data", {}).get("attack_id", "")) != "audit:1":
			failures.append("%s did not retain shared attack_id" % event_kind)

	operator.call("_log_ranged_fire_failure", &"no_reserve_ammo")
	if int(observatory.counters.get("player_ranged_fire_failure_no_reserve_ammo", 0)) != 1:
		failures.append("ranged reason-specific counter missing")
	if int(observatory.counters.get("player_ranged_fire_failure_empty", 0)) != 1:
		failures.append("ranged category counter missing")

	operator.current_health = operator.max_health
	operator.start_field_patch()
	if int(observatory.counters.get("field_patch_rejected_full_health", 0)) != 1:
		failures.append("Field Patch rejection reason counter missing")

	if failures.is_empty():
		print("DEV_OBSERVATORY_AUDIT_SMOKE: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("[DevObservatoryAuditSmoke] %s" % failure)
	quit(1)
