extends SceneTree

const RESOURCE_LEDGER_SCRIPT := preload("res://autoload/resource_ledger.gd")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const MARINE_SCENE := preload("res://game/actors/enemies/enemy_marine.tscn")
const GOTHIC_COMPOUND_MAP_SCRIPT := preload("res://game/world/gothic_compound/gothic_compound_map.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	root.name = "AuthoredVaultGruntLootMarineSmokeRoot"
	get_root().add_child(root)
	await process_frame

	_validate_grunt_loot(root)
	_validate_marine_idle(root)
	await _validate_marine_wall_collision(root)
	_validate_carrow_machine_house(root)

	if _failed:
		push_error("authored_vault_grunt_loot_marine_smoke failed")
		quit(1)
		return
	print("authored_vault_grunt_loot_marine_smoke passed")
	quit()


func _validate_grunt_loot(root: Node) -> void:
	var ledger := get_root().get_node_or_null("ResourceLedger")
	var owns_ledger := false
	if ledger == null:
		ledger = RESOURCE_LEDGER_SCRIPT.new()
		ledger.name = "ResourceLedger"
		get_root().add_child(ledger)
		ledger.call("_ready")
		owns_ledger = true
	if ledger.has_method("clear"):
		ledger.call("clear")

	var grunt := GRUNT_SCENE.instantiate()
	root.add_child(grunt)
	var lifecycle_config := grunt.lifecycle_config as EnemyLifecycleConfig
	var expected_ids := [
		"ruin_scrap",
		"spent_charge_cell",
		"frayed_signal_filament",
		"cracked_field_tag",
		"power_components",
		"memory_glass_fragment",
		"white_thread_knot",
	]
	var table_ids := {}
	for entry in lifecycle_config.loot_table:
		table_ids[str(entry.get("resource_id", ""))] = true
	var defs: Dictionary = ledger.call("get_resource_defs")
	for resource_id in expected_ids:
		_assert_true(table_ids.has(resource_id), "grunt loot table should include %s" % resource_id)
		_assert_true(defs.has(resource_id), "resource defs should include %s" % resource_id)
	grunt.die()
	var death_state: Dictionary = grunt.get_lifecycle_debug_state()
	var payload := death_state.get("pending_payload", {}) as Dictionary
	var rolled := payload.get("resource_ledger", {}) as Dictionary
	_assert_true(int(rolled.get(&"ruin_scrap", 0)) >= 1, "grunt loot should always roll at least one ruin_scrap")
	_assert_true(int(ledger.call("get_amount", "ruin_scrap")) == 0, "grunt loot must remain corpse-bound until collection")
	if owns_ledger:
		ledger.queue_free()
	grunt.queue_free()


func _validate_marine_idle(root: Node) -> void:
	var marine := MARINE_SCENE.instantiate()
	root.add_child(marine)
	var dash: MarineDash = (marine as Enemy).get_marine_dash_ability()
	marine.call("_ensure_directional_animations")
	var sprite := marine.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert_true(sprite != null, "marine should have AnimatedSprite2D")
	_assert_true(sprite.sprite_frames != null, "marine should build SpriteFrames")
	for suffix in ["n", "ne", "e", "se", "s", "sw", "w", "nw"]:
		_assert_true(sprite.sprite_frames.has_animation("marine_idle_%s" % suffix), "marine idle should include %s" % suffix)
	for anim_name in ["marine_dash_charge_e", "marine_dash_inflight_e", "marine_dash_recovery_e"]:
		_assert_true(sprite.sprite_frames.has_animation(anim_name), "marine should include %s animation" % anim_name)
		_assert_true(sprite.sprite_frames.get_frame_count(anim_name) == 5, "marine %s should have 5 frames" % anim_name)
	marine.call("_ensure_custom_enemy_fx_animations")
	var fx_sprite := marine.get_node_or_null("CustomEnemyFxSprite") as AnimatedSprite2D
	_assert_true(fx_sprite != null and fx_sprite.sprite_frames != null, "marine should build dash FX SpriteFrames")
	_assert_true(fx_sprite.sprite_frames.has_animation("marine_dash_attack_fx_e"), "marine should include east dash attack FX animation")
	_assert_true(bool(marine.get("marine_dash_enabled")), "marine dash should be enabled")
	_assert_true(absf(float(dash.config.windup_time) - 0.32) < 0.001, "marine dash windup should match heavy dash spec")
	_assert_true(absf(float(dash.config.travel_time) - 0.18) < 0.001, "marine dash travel time should match heavy dash spec")
	_assert_true(absf(float(dash.config.recovery_time) - 0.42) < 0.001, "marine dash recovery should match heavy dash spec")
	_assert_true(absf(float(dash.config.distance_px) - 150.0) < 0.001, "marine dash distance should match heavy dash spec")
	_assert_true(absf(float(dash.config.damage) - 32.0) < 0.001, "marine dash damage should match tuned heavy dash spec")
	_assert_true(absf(float(dash.config.knockback_px) - 105.0) < 0.001, "marine dash knockback should match tuned heavy dash spec")
	_assert_true(absf(float(dash.config.hit_active_start_ratio) - 0.28) < 0.001, "marine dash hit window should not start during launch anticipation")
	_assert_true(absf(float(dash.config.hit_active_end_ratio) - 0.9) < 0.001, "marine dash hit window should end before recovery")
	_assert_true(absf(float(dash.config.hit_forward_reach_px) - 30.0) < 0.001, "marine dash forward contact should be tuned for reliability")
	_assert_true(absf(float(dash.config.hit_lateral_reach_px) - 22.0) < 0.001, "marine dash lateral contact should be tuned for reliability")
	_assert_true(marine.has_method("get_behavior_attack_range"), "marine should expose behavior attack range")
	_assert_true(float(marine.call("get_behavior_attack_range")) >= 240.0, "marine behavior attack range should allow readable dash windup")
	_validate_pursuit_stop_boundary(marine)
	_validate_marine_tactical_dash(root, marine)
	_validate_marine_dash_hit_gate(root, marine)
	marine.queue_free()


func _validate_pursuit_stop_boundary(marine: Node) -> void:
	marine.global_position = Vector2.ZERO
	marine.set("velocity", Vector2(100.0, 0.0))
	marine.call("_limit_pursuit_inward_velocity", Vector2(40.25, 0.0), 40.0, 1.0 / 60.0)
	var limited_velocity: Vector2 = marine.get("velocity")
	_assert_true(limited_velocity.x <= 15.01, "pursuit velocity should not cross the melee stop boundary in one physics step")
	_assert_true(absf(limited_velocity.y) < 0.001, "pursuit stop limiting should not introduce lateral movement")


func _validate_marine_tactical_dash(root: Node, marine: Node) -> void:
	var dash: MarineDash = (marine as Enemy).get_marine_dash_ability()
	var target := CharacterBody2D.new()
	target.name = "MarineTacticalDashTarget"
	target.add_to_group("player")
	root.add_child(target)
	marine.set("target", target)
	marine.global_position = Vector2.ZERO
	target.global_position = Vector2(125.0, 0.0)
	target.velocity = Vector2.ZERO
	dash.last_attack_hit = true
	dash.request_start(Vector2.RIGHT, 125.0)
	var quick_state: Dictionary = marine.call("get_marine_dash_debug_state")
	_assert_true(is_equal_approx(float(quick_state.charge_ratio), 26.0 / 141.0), "post-hit close dash should retain the original quick charge")
	_assert_true(is_equal_approx(dash.timer, 0.32 + 0.56 * 26.0 / 141.0), "quick telegraph should retain its exact clock")
	dash.finish()
	target.global_position = Vector2(220.0, 0.0)
	target.velocity = Vector2(120.0, 0.0)
	dash.last_attack_hit = false
	dash.request_start(Vector2.RIGHT, 220.0)
	var charged_state: Dictionary = marine.call("get_marine_dash_debug_state")
	_assert_true(is_equal_approx(float(charged_state.charge_ratio), 121.0 / 141.0), "far dash should retain the original charged ratio")
	_assert_true(float(charged_state["charge_ratio"]) > float(quick_state["charge_ratio"]), "far retreating target should produce a longer charged dash than close post-hit pressure")
	_assert_true(is_equal_approx(float(charged_state["distance_share"]) + float(charged_state["damage_share"]), 1.0), "marine charge budget should split cleanly between distance and damage")
	_assert_true(float(charged_state["distance_share"]) < 1.0 and float(charged_state["damage_share"]) < 1.0, "marine charge should not maximize distance and damage together")
	target.velocity = Vector2(0.0, 150.0)
	var total_windup := float(dash.config.windup_time) + float(dash.config.charge_extra_windup) * float(charged_state["charge_ratio"])
	dash.tick(total_windup * 0.61)
	_assert_true(not dash.target_lock_done, "prediction must not lock before the original 62 percent boundary")
	dash.tick(total_windup * 0.07)
	var locked_state: Dictionary = marine.call("get_marine_dash_debug_state")
	var locked_direction: Vector2 = dash.direction
	_assert_true(bool(locked_state["target_locked"]), "marine final windup phase should lock a predicted target direction")
	_assert_true(locked_direction.y > 0.0, "marine predictive lock should lead a laterally moving target")
	target.velocity = Vector2(0.0, -150.0)
	dash.tick(0.0)
	_assert_true(dash.direction.is_equal_approx(locked_direction), "prediction must lock once instead of steering")
	dash.tick(dash.timer)
	_assert_true(dash.phase == &"dash" and is_equal_approx(dash.timer, 0.18), "windup should enter original travel clock")
	dash.tick(dash.timer)
	_assert_true(dash.phase == &"impact_lock" and is_equal_approx(dash.timer, 0.08), "travel timeout should enter original impact lock")
	dash.tick(dash.timer)
	_assert_true(dash.phase == &"recovery" and is_equal_approx(dash.timer, 0.42), "impact lock should enter original recovery")
	_assert_true(not dash.is_hit_window_active(), "recovery must have no active contact")
	dash.tick(dash.timer)
	_assert_true(not dash.is_active() and is_equal_approx(dash.reset_timer, 0.48), "completed recovery should enter lateral reset")
	var first_side := dash.reset_side
	dash.start_reset(false)
	_assert_true(is_equal_approx(dash.reset_side, -first_side), "reset side must alternate deterministically")
	var diagnostic := dash.get_debug_state()
	diagnostic["phase"] = "changed"
	_assert_true(dash.phase.is_empty(), "debug snapshots must not mutate ability state")
	dash.reset_timer = 0.0
	dash.cadence_timer = 0.0
	target.global_position = Vector2(125.0, 0.0)
	marine.global_position = Vector2.ZERO
	dash.try_start(1.09)
	_assert_true(not dash.is_active(), "cadence must not launch before the tuned 1.1 second gate")
	dash.try_start(0.02)
	_assert_true(dash.is_active() and is_zero_approx(dash.cadence_timer), "cadence should launch and reset at the tuned gate")
	dash.finish()
	target.global_position = Vector2(50.0, 0.0)
	dash.try_start(2.0)
	_assert_true(not dash.is_active() and is_equal_approx(dash.reset_timer, 0.36), "too-close target should back away without accruing cadence")
	_assert_true(is_zero_approx(dash.cadence_timer), "close reset must not accrue attack cadence")
	dash.reset_timer = 0.0
	target.queue_free()


func _validate_marine_dash_hit_gate(root: Node, marine: Node) -> void:
	var dash: MarineDash = (marine as Enemy).get_marine_dash_ability()
	var target := CharacterBody2D.new()
	target.name = "MarineDashGateTarget"
	target.add_to_group("player")
	root.add_child(target)
	marine.set("target", target)
	marine.set("global_position", Vector2.ZERO)
	dash.phase = &"dash"
	dash.direction = Vector2.RIGHT
	dash.timer = float(dash.config.travel_time) * 0.80
	target.global_position = Vector2(12.0, 0.0)
	dash.try_apply_hit()
	_assert_true((dash.hit_targets as Array).is_empty(), "marine dash should not hit before active frames")
	dash.timer = float(dash.config.travel_time) * 0.50
	target.global_position = Vector2(34.0, 0.0)
	dash.try_apply_hit()
	_assert_true((dash.hit_targets as Array).is_empty(), "marine dash should not hit beyond close contact")
	target.global_position = Vector2(12.0, 26.0)
	dash.try_apply_hit()
	_assert_true((dash.hit_targets as Array).is_empty(), "marine dash should not hit outside lateral contact")
	target.global_position = Vector2(12.0, 0.0)
	var position_before_hit := target.global_position
	dash.try_apply_hit()
	_assert_true(not (dash.hit_targets as Array).is_empty(), "marine dash should hit during active close contact")
	_assert_true(target.global_position.is_equal_approx(position_before_hit), "marine impact must not call move_and_slide on its target")
	target.queue_free()


func _validate_marine_wall_collision(root: Node) -> void:
	var marine := MARINE_SCENE.instantiate() as Enemy
	marine.position = Vector2(10000.0, 10000.0)
	root.add_child(marine)
	marine.set_physics_process(false)
	var dash := marine.get_marine_dash_ability()
	var wall := StaticBody2D.new()
	wall.position = marine.position + Vector2(18.0, 0.0)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4.0, 100.0)
	collider.shape = shape
	wall.add_child(collider)
	root.add_child(wall)
	await physics_frame
	marine.target = null
	marine.request_marine_dash(Vector2.RIGHT, 150.0)
	dash.tick(dash.timer)
	dash.tick(1.0 / 60.0)
	_assert_true(dash.phase == &"impact_lock", "static wall should end travel immediately")
	_assert_true(marine.position.x < 10004.1, "wall collision must stop before full dash distance")
	_assert_true(marine.velocity.is_zero_approx(), "wall impact must stop actor velocity")
	dash.finish()
	wall.queue_free()
	marine.queue_free()


func _validate_carrow_machine_house(root: Node) -> void:
	var map := GOTHIC_COMPOUND_MAP_SCRIPT.new()
	root.add_child(map)
	var room := map.get_node_or_null("EastMachineHouseInterior")
	_assert_true(room != null, "Carrow Yard should place EastMachineHouseInterior")
	if room == null:
		map.queue_free()
		return
	var storage_count := 0
	for node in get_nodes_in_group("vault_storage"):
		if room.is_ancestor_of(node):
			storage_count += 1
	_assert_true(storage_count >= 3, "East Machine House should contain at least three storage nodes")
	_assert_true(room.get_node_or_null("LeaveEastMachineHouse") != null, "East Machine House should expose its exit doorway")
	map.queue_free()


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
