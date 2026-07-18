extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CARBINE_DEFINITION := preload("res://game/actors/operator/carbine_rifle_mk1_definition.tres")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observatory := root.get_node_or_null("DevObservatory")
	if observatory == null:
		push_error("[OperatorAmmoReconciliationSmoke] DevObservatory autoload missing")
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
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	world.add_child(projectiles)
	var operator := OPERATOR_SCENE.instantiate()
	operator.name = "AmmoOperator"
	world.add_child(operator)
	await process_frame

	operator.set("primary_weapon_definition", CARBINE_DEFINITION)
	operator.set("primary_weapon_equipped", true)
	operator.set("combat_loadout_mode", "ranged")
	operator.set("equipped_primary_weapon_id", "carbine_rifle")
	operator.set("using_unarmed", false)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.call("_enter_ranged_ready")
	operator.call("_tick_primary_ranged_action_presentation", 10.0)
	operator.call("_initialize_magazines")

	var initial := operator.get_weapon_status() as Dictionary
	_expect(initial.get("active_weapon_id") == "carbine_mk1", "fresh ranged context did not identify carbine_mk1", failures)
	_expect(initial.get("active_weapon_state_key") == "carbine_mk1", "fresh ranged context did not expose carbine state key", failures)
	_expect(int(initial.get("loaded_ammo", -1)) == 24, "fresh carbine did not begin with 24 loaded", failures)
	_expect(int(initial.get("reserve_ammo", -1)) == 48, "fresh carbine did not begin with 48 reserve", failures)
	_expect(int(initial.get("magazine_size", -1)) == 24, "carbine magazine capacity was not 24", failures)
	_expect(int(initial.get("ammo_per_shot", -1)) == 1, "carbine ammo cost was not one per shot", failures)

	var profile := operator.call("_get_current_ranged_profile") as Dictionary
	for shot_index in range(18):
		operator.set("_pending_ranged_shot", {
			"timer": 0.0,
			"profile": profile.duplicate(true),
			"aim_direction": Vector2.RIGHT,
		})
		operator.call("_emit_pending_ranged_shot")

	var final_status := operator.get_weapon_status() as Dictionary
	_expect(int(final_status.get("loaded_ammo", -1)) == 6, "18 carbine shots did not leave exactly 6 loaded", failures)
	_expect(int(final_status.get("reserve_ammo", -1)) == 48, "firing without reload changed carbine reserve", failures)
	_expect(int(observatory.counters.get("player_ranged_shots_fired", 0)) == 18, "shot counter did not reconcile to 18", failures)
	var shot_events: Array = observatory.get_recent_events(30, &"player_ranged_shot")
	_expect(shot_events.size() == 18, "shot ledger did not retain all 18 controlled shots", failures)
	if shot_events.size() == 18:
		var newest_data := (shot_events[0] as Dictionary).get("data", {}) as Dictionary
		var oldest_data := (shot_events[-1] as Dictionary).get("data", {}) as Dictionary
		_expect(int(oldest_data.get("loaded_ammo", -1)) == 23, "first shot ledger row did not consume exactly one round", failures)
		_expect(int(newest_data.get("loaded_ammo", -1)) == 6, "final shot ledger row did not reconcile to six rounds", failures)

	observatory.call("_sample_player_gauges", self)
	_expect(observatory.gauges.get("player_active_weapon_id") == "carbine_mk1", "Observatory did not export active weapon identity", failures)
	_expect(int(observatory.gauges.get("player_magazine_capacity", 0)) == 24, "Observatory did not export magazine capacity", failures)
	_expect(int(observatory.gauges.get("player_ammo_per_shot", 0)) == 1, "Observatory did not export ammo-per-shot", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("[OperatorAmmoReconciliationSmoke] %s" % failure)
		quit(1)
		return
	print("OPERATOR_AMMO_RECONCILIATION_SMOKE: PASS")
	quit(0)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
