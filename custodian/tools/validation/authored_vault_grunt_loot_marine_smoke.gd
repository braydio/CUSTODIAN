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
	_validate_authored_vault_room(root)

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
	for entry in grunt.get("loot_table"):
		table_ids[str(entry.get("resource_id", ""))] = true
	var defs: Dictionary = ledger.call("get_resource_defs")
	for resource_id in expected_ids:
		_assert_true(table_ids.has(resource_id), "grunt loot table should include %s" % resource_id)
		_assert_true(defs.has(resource_id), "resource defs should include %s" % resource_id)
	var awarded := bool(grunt.call("_award_loot_table"))
	_assert_true(awarded, "grunt loot table should award or intentionally roll no typed loot")
	_assert_true(int(ledger.call("get_amount", "ruin_scrap")) >= 1, "grunt loot should always award at least one ruin_scrap")
	if owns_ledger:
		ledger.queue_free()
	grunt.queue_free()


func _validate_marine_idle(root: Node) -> void:
	var marine := MARINE_SCENE.instantiate()
	root.add_child(marine)
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
	_assert_true(absf(float(marine.get("marine_dash_windup_time")) - 0.32) < 0.001, "marine dash windup should match heavy dash spec")
	_assert_true(absf(float(marine.get("marine_dash_time")) - 0.18) < 0.001, "marine dash travel time should match heavy dash spec")
	_assert_true(absf(float(marine.get("marine_dash_recovery_time")) - 0.42) < 0.001, "marine dash recovery should match heavy dash spec")
	_assert_true(absf(float(marine.get("marine_dash_distance_px")) - 150.0) < 0.001, "marine dash distance should match heavy dash spec")
	_assert_true(absf(float(marine.get("marine_dash_damage")) - 32.0) < 0.001, "marine dash damage should match tuned heavy dash spec")
	_assert_true(absf(float(marine.get("marine_dash_knockback_px")) - 105.0) < 0.001, "marine dash knockback should match tuned heavy dash spec")
	_assert_true(absf(float(marine.get("marine_dash_hit_active_start_ratio")) - 0.28) < 0.001, "marine dash hit window should not start during launch anticipation")
	_assert_true(absf(float(marine.get("marine_dash_hit_active_end_ratio")) - 0.9) < 0.001, "marine dash hit window should end before recovery")
	_assert_true(absf(float(marine.get("marine_dash_hit_forward_reach_px")) - 30.0) < 0.001, "marine dash forward contact should be tuned for reliability")
	_assert_true(absf(float(marine.get("marine_dash_hit_lateral_reach_px")) - 22.0) < 0.001, "marine dash lateral contact should be tuned for reliability")
	_assert_true(marine.has_method("get_behavior_attack_range"), "marine should expose behavior attack range")
	_assert_true(float(marine.call("get_behavior_attack_range")) >= 240.0, "marine behavior attack range should allow readable dash windup")
	_validate_marine_tactical_dash(root, marine)
	_validate_marine_dash_hit_gate(root, marine)
	marine.queue_free()


func _validate_marine_tactical_dash(root: Node, marine: Node) -> void:
	var target := CharacterBody2D.new()
	target.name = "MarineTacticalDashTarget"
	target.add_to_group("player")
	root.add_child(target)
	marine.set("target", target)
	marine.global_position = Vector2.ZERO
	target.global_position = Vector2(125.0, 0.0)
	target.velocity = Vector2.ZERO
	marine.set("_marine_dash_last_attack_hit", true)
	marine.call("_configure_marine_dash_charge", 125.0)
	var quick_state: Dictionary = marine.call("get_marine_dash_debug_state")
	target.global_position = Vector2(220.0, 0.0)
	target.velocity = Vector2(120.0, 0.0)
	marine.set("_marine_dash_last_attack_hit", false)
	marine.call("_configure_marine_dash_charge", 220.0)
	var charged_state: Dictionary = marine.call("get_marine_dash_debug_state")
	_assert_true(float(charged_state["charge_ratio"]) > float(quick_state["charge_ratio"]), "far retreating target should produce a longer charged dash than close post-hit pressure")
	_assert_true(is_equal_approx(float(charged_state["distance_share"]) + float(charged_state["damage_share"]), 1.0), "marine charge budget should split cleanly between distance and damage")
	_assert_true(float(charged_state["distance_share"]) < 1.0 and float(charged_state["damage_share"]) < 1.0, "marine charge should not maximize distance and damage together")
	target.velocity = Vector2(0.0, 150.0)
	marine.set("_marine_dash_phase", &"windup")
	marine.set("_marine_dash_target_lock_done", false)
	var total_windup := float(marine.get("marine_dash_windup_time")) + float(marine.get("marine_dash_charge_extra_windup")) * float(charged_state["charge_ratio"])
	marine.set("_marine_dash_timer", total_windup * 0.32)
	marine.call("_update_marine_dash_target_lock")
	var locked_state: Dictionary = marine.call("get_marine_dash_debug_state")
	var locked_direction: Vector2 = marine.get("_marine_dash_direction")
	_assert_true(bool(locked_state["target_locked"]), "marine final windup phase should lock a predicted target direction")
	_assert_true(locked_direction.y > 0.0, "marine predictive lock should lead a laterally moving target")
	marine.call("_finish_marine_dash_attack")
	marine.call("_start_marine_dash_reset", false)
	_assert_true(float((marine.call("get_marine_dash_debug_state") as Dictionary)["reset_timer"]) > 0.0, "marine should enter a lateral reset after a dash")
	target.queue_free()


func _validate_marine_dash_hit_gate(root: Node, marine: Node) -> void:
	var target := CharacterBody2D.new()
	target.name = "MarineDashGateTarget"
	target.add_to_group("player")
	root.add_child(target)
	marine.set("target", target)
	marine.set("global_position", Vector2.ZERO)
	marine.set("_marine_dash_phase", &"dash")
	marine.set("_marine_dash_direction", Vector2.RIGHT)
	marine.set("_marine_dash_timer", float(marine.get("marine_dash_time")) * 0.80)
	target.global_position = Vector2(12.0, 0.0)
	marine.call("_try_apply_marine_dash_hit")
	_assert_true((marine.get("_marine_dash_hit_targets") as Array).is_empty(), "marine dash should not hit before active frames")
	marine.set("_marine_dash_timer", float(marine.get("marine_dash_time")) * 0.50)
	target.global_position = Vector2(34.0, 0.0)
	marine.call("_try_apply_marine_dash_hit")
	_assert_true((marine.get("_marine_dash_hit_targets") as Array).is_empty(), "marine dash should not hit beyond close contact")
	target.global_position = Vector2(12.0, 26.0)
	marine.call("_try_apply_marine_dash_hit")
	_assert_true((marine.get("_marine_dash_hit_targets") as Array).is_empty(), "marine dash should not hit outside lateral contact")
	target.global_position = Vector2(12.0, 0.0)
	marine.call("_try_apply_marine_dash_hit")
	_assert_true(not (marine.get("_marine_dash_hit_targets") as Array).is_empty(), "marine dash should hit during active close contact")
	target.queue_free()


func _validate_authored_vault_room(root: Node) -> void:
	var map := GOTHIC_COMPOUND_MAP_SCRIPT.new()
	root.add_child(map)
	var room := map.get_node_or_null("AuthoredVaultRoom")
	_assert_true(room != null, "gothic compound should place AuthoredVaultRoom")
	if room == null:
		map.queue_free()
		return
	var storage_count := 0
	for node in get_nodes_in_group("vault_storage"):
		if room.is_ancestor_of(node):
			storage_count += 1
	_assert_true(storage_count >= 3, "authored vault room should contain at least three storage nodes")
	_assert_true(room.get_node_or_null("VaultEnemyExit") != null, "authored vault room should expose VaultEnemyExit marker")
	map.queue_free()


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
