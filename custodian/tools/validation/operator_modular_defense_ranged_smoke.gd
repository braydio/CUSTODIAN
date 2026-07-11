extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CARBINE_DEFINITION := preload("res://game/actors/operator/carbine_rifle_mk1_definition.tres")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorModularDefenseRangedSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	await process_frame

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	_validate_parry_attempt_uses_modular_layers(operator)
	_validate_guard_hold_walk_uses_modular_lower(operator)
	_validate_ranged_2h_stance_uses_modular_layers(operator)

	var heavy_operator := OPERATOR_SCENE.instantiate()
	root.add_child(heavy_operator)
	await process_frame
	_validate_unarmed_heavy_fx_survives_visual_update(heavy_operator)
	heavy_operator.queue_free()

	operator.queue_free()
	if _failed:
		push_error("operator_modular_defense_ranged_smoke failed")
		quit(1)
		return
	print("operator_modular_defense_ranged_smoke passed")
	quit()


func _validate_parry_attempt_uses_modular_layers(operator: Node) -> void:
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("using_unarmed", true)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.call("_exit_ranged_ready")

	_assert_animation_exists(operator, "modular_lower_body_sprite", &"unarmed_parry_success_01_right")
	_assert_animation_exists(operator, "modular_upper_body_sprite", &"unarmed_parry_success_01_right")
	_assert_animation_exists(operator, "modular_upper_fx_sprite", &"unarmed_parry_success_01_fx_right")
	operator.call("_play_parry_animation", &"unarmed_parry_success_01")

	var lower_sprite := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	var upper_sprite := operator.get("modular_upper_body_sprite") as AnimatedSprite2D
	var fx_sprite := operator.get("modular_upper_fx_sprite") as AnimatedSprite2D
	_assert_true(lower_sprite != null and lower_sprite.visible, "parry success should show modular lower body")
	_assert_true(upper_sprite != null and upper_sprite.visible, "parry success should show modular upper body")
	_assert_true(fx_sprite != null and fx_sprite.visible, "parry success should show modular upper FX")
	_assert_true(lower_sprite != null and lower_sprite.animation == &"unarmed_parry_success_01_right", "parry success recovery should play lower right success_01")
	_assert_true(upper_sprite != null and upper_sprite.animation == &"unarmed_parry_success_01_right", "parry success recovery should play upper right success_01")
	_assert_true(fx_sprite != null and fx_sprite.animation == &"unarmed_parry_success_01_fx_right", "parry success recovery should play right success_01 FX")

	_assert_animation_exists(operator, "modular_lower_body_sprite", &"unarmed_parry_right")
	_assert_animation_exists(operator, "modular_upper_body_sprite", &"unarmed_parry_right")
	operator.call("_play_parry_animation", &"unarmed_parry")
	_assert_true(lower_sprite != null and lower_sprite.animation == &"unarmed_parry_right", "failed parry should keep the parry_01 lower-body attempt animation")
	_assert_true(upper_sprite != null and upper_sprite.animation == &"unarmed_parry_right", "failed parry should keep the parry_01 upper-body attempt animation")


func _validate_guard_hold_walk_uses_modular_lower(operator: Node) -> void:
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("using_unarmed", true)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("movement_direction", Vector2.RIGHT)
	operator.set("velocity", Vector2.RIGHT * 32.0)
	operator.set("_block_phase", &"hold")
	operator.set("_block_active", true)
	operator.set("is_sprinting", false)
	operator.call("_exit_ranged_ready")

	_assert_true(not bool(operator.call("_is_movement_locked")), "held guard should not hard-lock movement")
	_assert_animation_exists(operator, "modular_lower_body_sprite", &"unarmed_walk_right")
	_assert_animation_exists(operator, "modular_upper_body_sprite", &"unarmed_block_hold_right")
	_assert_true(bool(operator.call("_sync_modular_block_hold_movement_presentation")), "moving guard hold should sync modular lower walk plus upper block hold")

	var lower_sprite := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	var upper_sprite := operator.get("modular_upper_body_sprite") as AnimatedSprite2D
	var legacy_sprite := operator.get("animated_sprite") as AnimatedSprite2D
	_assert_true(lower_sprite != null and lower_sprite.visible, "moving guard hold should show modular lower body")
	_assert_true(upper_sprite != null and upper_sprite.visible, "moving guard hold should show modular upper body")
	_assert_true(lower_sprite != null and lower_sprite.animation == &"unarmed_walk_right", "moving guard hold should use lower-body walk")
	_assert_true(lower_sprite != null and is_equal_approx(lower_sprite.speed_scale, float(operator.get("block_move_multiplier"))), "moving guard lower walk should use block movement speed scale")
	_assert_true(upper_sprite != null and upper_sprite.animation == &"unarmed_block_hold_right", "moving guard hold should keep upper-body block hold")
	_assert_true(legacy_sprite == null or not legacy_sprite.visible, "moving guard hold should hide legacy full body")

	operator.set("velocity", Vector2.ZERO)
	operator.set("_block_phase", &"")
	operator.set("_block_active", false)


func _validate_unarmed_heavy_fx_survives_visual_update(operator: Node) -> void:
	operator.call("_exit_ranged_ready")
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("using_unarmed", true)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)

	_assert_animation_exists(operator, "melee_fx_overlay_sprite", &"unarmed_attack_heavy_fx_right")
	operator.call("start_attack", "unarmed_heavy")
	var fx_sprite := operator.get("melee_fx_overlay_sprite") as AnimatedSprite2D
	_assert_true(fx_sprite != null and fx_sprite.visible, "unarmed heavy should show its melee FX overlay when the attack starts")
	_assert_true(fx_sprite != null and fx_sprite.animation == &"unarmed_attack_heavy_fx_right", "unarmed heavy should play right heavy FX")
	operator.call("_update_primary_weapon_visual", false)
	_assert_true(fx_sprite != null and fx_sprite.visible, "unarmed heavy FX should survive the normal weapon visual update")
	_assert_true(fx_sprite != null and fx_sprite.animation == &"unarmed_attack_heavy_fx_right", "weapon visual update should not replace unarmed heavy FX")
	operator.call("_reset_melee_overlay_visuals")
	operator.set("_melee_active", false)
	operator.set("_melee_attack_kind", "")
	operator.set("_melee_attack_key", "")


func _validate_ranged_2h_stance_uses_modular_layers(operator: Node) -> void:
	operator.call("_exit_ranged_ready")
	operator.set("primary_weapon_definition", CARBINE_DEFINITION)
	operator.set("primary_weapon_equipped", true)
	operator.set("combat_loadout_mode", "ranged")
	operator.set("equipped_primary_weapon_id", "carbine_rifle")
	operator.set("using_unarmed", false)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)

	_assert_animation_exists(operator, "modular_upper_body_sprite", &"ranged_2h_stance_modular_right")
	_assert_animation_exists(operator, "modular_sidearm_sprite", &"ranged_2h_stance_modular_right")
	_assert_animation_exists(operator, "modular_lower_body_sprite", &"ranged_2h_aim_modular_right")
	_assert_animation_exists(operator, "modular_upper_body_sprite", &"ranged_2h_aim_modular_right")
	_assert_animation_exists(operator, "modular_sidearm_sprite", &"ranged_2h_aim_modular_right")
	operator.call("_enter_ranged_ready")
	_assert_true(bool(operator.call("_is_ranged_ready_active")), "carbine should enter ranged-ready")
	_assert_true(bool(operator.call("_has_modular_ranged_ready_upper_stack")), "east ranged-ready stack should be accepted")
	_assert_true(bool(operator.call("_is_primary_ranged_aim_presentation_active")), "carbine ranged-ready should start modular aim raise")

	var lower_sprite := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	var upper_sprite := operator.get("modular_upper_body_sprite") as AnimatedSprite2D
	var weapon_sprite := operator.get("modular_sidearm_sprite") as AnimatedSprite2D
	var cape_sprite := operator.get("modular_cape_sprite") as AnimatedSprite2D
	_assert_true(lower_sprite != null and lower_sprite.animation == &"ranged_2h_aim_modular_right", "ranged-ready should play lower east aim raise")
	_assert_true(upper_sprite != null and upper_sprite.animation == &"ranged_2h_aim_modular_right", "ranged-ready should play upper east aim raise")
	_assert_true(weapon_sprite != null and weapon_sprite.animation == &"ranged_2h_aim_modular_right", "ranged-ready should play weapon east aim raise")
	_assert_true(cape_sprite == null or not cape_sprite.visible, "ranged-ready should hide cape (no ranged-aim cape animation available)")
	operator.call("_tick_primary_ranged_action_presentation", 1.0)
	_assert_true(not bool(operator.call("_is_primary_ranged_aim_presentation_active")), "modular aim raise should finish before stance")
	_assert_true(bool(operator.call("_sync_modular_ranged_2h_stance_presentation", Vector2.RIGHT)), "east ranged-ready should sync modular stance")

	_assert_true(upper_sprite != null and upper_sprite.animation == &"ranged_2h_stance_modular_right", "ranged-ready should play upper east stance")
	_assert_true(weapon_sprite != null and weapon_sprite.animation == &"ranged_2h_stance_modular_right", "ranged-ready should play weapon east stance")


func _assert_animation_exists(operator: Node, sprite_property: String, animation_name: StringName) -> void:
	var sprite := operator.get(sprite_property) as AnimatedSprite2D
	_assert_true(sprite != null, "%s should exist" % sprite_property)
	if sprite == null:
		return
	_assert_true(sprite.sprite_frames != null, "%s should have SpriteFrames" % sprite_property)
	if sprite.sprite_frames == null:
		return
	_assert_true(sprite.sprite_frames.has_animation(animation_name), "%s should contain %s" % [sprite_property, String(animation_name)])
	_assert_true(sprite.sprite_frames.get_frame_count(animation_name) > 0, "%s should have frames" % String(animation_name))


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
