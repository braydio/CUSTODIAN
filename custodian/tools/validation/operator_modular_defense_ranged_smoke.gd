extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CARBINE_DEFINITION := preload("res://game/actors/operator/carbine_rifle_mk1_definition.tres")
const GUARD_CONTROLLER := preload("res://game/actors/operator/combat/operator_guard_controller.gd")
const BODY_PRESENTER := preload("res://game/actors/operator/presentation/operator_body_presenter.gd")

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
	_validate_mobile_guard_lifecycle(operator)
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
	operator.set("movement_direction", Vector2.LEFT)
	operator.set("velocity", Vector2.LEFT * 32.0)
	operator.call("_play_parry_animation", &"unarmed_parry")
	var moving_lower := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	var moving_upper := operator.get("modular_upper_body_sprite") as AnimatedSprite2D
	_assert_true(moving_lower.animation == &"unarmed/locomotion/walk_01/w/lower_body", "moving parry should retain westward locomotion")
	_assert_true(moving_upper.animation == &"unarmed/defense/parry_01/e/upper_body", "moving parry should retain east guard facing")
	moving_lower.set_frame_and_progress(2, 0.35)
	var lower_frame := moving_lower.frame
	var lower_progress := moving_lower.frame_progress
	operator.call("_play_parry_animation", &"unarmed_parry_success_01")
	_assert_true(moving_lower.animation == &"unarmed/locomotion/walk_01/w/lower_body", "parry contact follow-up should keep moving lower identity when no displacement freeze exists")
	_assert_lower_progress(moving_lower, lower_frame, lower_progress, "parry upper phase change must preserve lower progress")
	_assert_true(moving_upper.animation == &"unarmed/attack/parry_recovery_01/e/upper_body", "parry recovery upper should retain canonical success art")
	_assert_true(float(operator.get("_enemy_impact_lock_timer")) <= 0.0, "parry presentation must not invent an impact lock")
	operator.set("velocity", Vector2.ZERO)

	_assert_animation_exists(operator, "modular_lower_body_sprite", &"unarmed/attack/parry_recovery_01/e/lower_body")
	_assert_animation_exists(operator, "modular_upper_body_sprite", &"unarmed/attack/parry_recovery_01/e/upper_body")
	operator.call("_play_parry_animation", &"unarmed_parry_success_01")

	var lower_sprite := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	var upper_sprite := operator.get("modular_upper_body_sprite") as AnimatedSprite2D
	var fx_sprite := operator.get("modular_upper_fx_sprite") as AnimatedSprite2D
	_assert_true(lower_sprite.animation == &"unarmed/attack/parry_recovery_01/e/lower_body", "stationary parry recovery should preserve the authored paired lower")
	_assert_true(lower_sprite != null and lower_sprite.visible, "parry success should show modular lower body")
	_assert_true(upper_sprite != null and upper_sprite.visible, "parry success should show modular upper body")
	_assert_true(lower_sprite != null and lower_sprite.animation == &"unarmed/attack/parry_recovery_01/e/lower_body", "parry success recovery should play lower right success_01")
	_assert_true(upper_sprite != null and upper_sprite.animation == &"unarmed/attack/parry_recovery_01/e/upper_body", "parry success recovery should play upper right success_01")
	# C2a-R2 canonicalized this renderer. The legacy `unarmed_parry_success_01_fx`
	# was one clip sourcing two different actions -- parry_recovery_01 art on one
	# side and interaction/success_01 on the other -- so it was replaced by the
	# authored success identity. parry_recovery_01 FX stays dormant.
	_assert_true(
		fx_sprite != null and fx_sprite.visible
		and fx_sprite.animation == &"unarmed/defense/parry_success_01/e/fx",
		"post-parry neutral should present the canonical parry_success_01 FX"
	)
	_assert_true(
		fx_sprite != null and String(fx_sprite.animation).find("parry_recovery_01") == -1
		and String(fx_sprite.animation).find("interaction") == -1,
		"post-parry neutral must never present recovery or interaction-success FX"
	)

	_assert_animation_exists(operator, "modular_lower_body_sprite", &"unarmed/defense/parry_01/e/lower_body")
	_assert_animation_exists(operator, "modular_upper_body_sprite", &"unarmed/defense/parry_01/e/upper_body")
	operator.call("_play_parry_animation", &"unarmed_parry")
	_assert_true(lower_sprite != null and lower_sprite.animation == &"unarmed/defense/parry_01/e/lower_body", "failed parry should keep the parry_01 lower-body attempt animation")
	_assert_true(upper_sprite != null and upper_sprite.animation == &"unarmed/defense/parry_01/e/upper_body", "failed parry should keep the parry_01 upper-body attempt animation")


func _validate_mobile_guard_lifecycle(operator: Node) -> void:
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("using_unarmed", true)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.set("movement_direction", Vector2.LEFT)
	operator.set("velocity", Vector2.LEFT * 32.0)
	operator.set("_block_phase", &"enter")
	operator.set("_block_active", true)
	operator.set("is_sprinting", false)
	operator.call("_exit_ranged_ready")
	var guard = operator.call("get_guard_controller")
	var lower := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	var upper := operator.get("modular_upper_body_sprite") as AnimatedSprite2D
	var fx := operator.get("modular_upper_fx_sprite") as AnimatedSprite2D
	var legacy := operator.get("animated_sprite") as AnimatedSprite2D

	_assert_true(not bool(operator.call("_is_movement_locked")), "ordinary guard should remain movement-permissive")
	_assert_animation_exists(operator, "modular_lower_body_sprite", &"unarmed/locomotion/walk_01/w/lower_body")
	_assert_animation_exists(operator, "modular_upper_body_sprite", &"unarmed/defense/block_enter_01/e/upper_body")
	guard.set("phase", GUARD_CONTROLLER.Phase.GUARD_ENTER)
	operator.call("_play_block_animation", &"melee_2h_block_enter")
	_assert_guard_pair(operator, &"unarmed/locomotion/walk_01/w/lower_body", &"unarmed/defense/block_enter_01/e/upper_body", "moving enter should separate movement and guard facing")
	_assert_true(not legacy.visible, "moving guard should hide legacy full body")
	_assert_true(not fx.visible, "moving enter should hide the hold overlay")
	_assert_true(is_equal_approx(lower.speed_scale, float(operator.get("block_move_multiplier"))), "moving lower body should use the existing guard movement multiplier")

	# Every upper phase keeps the same movement-owned lower identity and clock.
	lower.set_frame_and_progress(2, 0.35)
	var lower_frame := lower.frame
	var lower_progress := lower.frame_progress
	operator.set("_block_phase", &"hold")
	guard.set("phase", GUARD_CONTROLLER.Phase.GUARD_HOLD)
	operator.call("_play_block_animation", &"melee_2h_block_hold")
	_assert_guard_pair(operator, &"unarmed/locomotion/walk_01/w/lower_body", &"unarmed/defense/block_hold_01/e/upper_body", "moving hold should keep west locomotion while guarding east")
	_assert_lower_progress(lower, lower_frame, lower_progress, "enter-to-hold must preserve lower progress")
	_assert_true(fx.visible and fx.animation == &"unarmed/defense/block_hold_01/e/fx", "moving hold should show east block-hold FX")
	_assert_true(fx.sprite_frames.get_frame_count(fx.animation) == 5, "block-hold FX should retain its authored frames")
	fx.frame = 2
	operator.call("_sync_modular_block_hold_movement_presentation")
	_assert_true(fx.frame == 2, "repeated hold synchronization should not restart the overlay")

	operator.set("_block_phase", &"hitreact")
	guard.set("phase", GUARD_CONTROLLER.Phase.LIGHT_RECOIL)
	operator.call("_play_block_animation", &"melee_2h_block_hitreact")
	_assert_guard_pair(operator, &"unarmed/locomotion/walk_01/w/lower_body", &"unarmed/defense/block_hit_01/e/upper_body", "light recoil should preserve locomotion and use the canonical fallback")
	_assert_lower_progress(lower, lower_frame, lower_progress, "light recoil must preserve lower progress")
	guard.set("phase", GUARD_CONTROLLER.Phase.HEAVY_RECOIL)
	operator.call("_play_block_animation", &"melee_2h_block_hitreact")
	_assert_guard_pair(operator, &"unarmed/locomotion/walk_01/w/lower_body", &"unarmed/defense/block_hit_01/e/upper_body", "heavy recoil should use block-hit while dedicated layers are absent")
	_assert_lower_progress(lower, lower_frame, lower_progress, "heavy recoil must preserve lower progress")

	guard.set("phase", GUARD_CONTROLLER.Phase.GUARD_HOLD)
	operator.set("_block_phase", &"hold")
	operator.call("_play_block_animation", &"melee_2h_block_hold")
	_assert_lower_progress(lower, lower_frame, lower_progress, "recovery-to-hold must preserve lower progress")
	operator.set("_block_phase", &"exit")
	guard.set("phase", GUARD_CONTROLLER.Phase.GUARD_EXIT)
	operator.call("_play_block_animation", &"melee_2h_block_exit")
	_assert_guard_pair(operator, &"unarmed/locomotion/walk_01/w/lower_body", &"unarmed/defense/block_enter_01/e/upper_body", "moving exit should reverse enter over movement locomotion")
	_assert_true(upper.frame == upper.sprite_frames.get_frame_count(upper.animation) - 1, "exit should begin at the upper enter clip's final frame")
	_assert_true(not bool(operator.call("_is_block_animation_finished")), "upper exit should own completion while lower locomotion loops")
	upper.stop()
	_assert_true(bool(operator.call("_is_block_animation_finished")), "stopping the upper exit should complete the action independently of lower locomotion")

	# Stopping during ordinary guard re-composes the stationary authored pair.
	operator.set("velocity", Vector2.ZERO)
	operator.set("_block_phase", &"enter")
	guard.set("phase", GUARD_CONTROLLER.Phase.GUARD_ENTER)
	operator.call("_play_block_animation", &"melee_2h_block_enter")
	_assert_guard_pair(operator, &"unarmed/defense/block_enter_01/e/lower_body", &"unarmed/defense/block_enter_01/e/upper_body", "stationary enter should preserve the authored paired pose")
	operator.set("_block_phase", &"hitreact")
	guard.set("phase", GUARD_CONTROLLER.Phase.LIGHT_RECOIL)
	operator.call("_play_block_animation", &"melee_2h_block_hitreact")
	_assert_guard_pair(operator, &"unarmed/defense/block_hit_01/e/lower_body", &"unarmed/defense/block_hit_01/e/upper_body", "stationary recoil should preserve the authored paired pose")

	# Negative control: one missing required layer selects one complete body.
	var original_frames: SpriteFrames = upper.sprite_frames
	var incomplete_frames := original_frames.duplicate(true) as SpriteFrames
	incomplete_frames.remove_animation(&"unarmed/defense/block_enter_01/e/upper_body")
	upper.sprite_frames = incomplete_frames
	operator.set("velocity", Vector2.LEFT * 32.0)
	operator.set("movement_direction", Vector2.LEFT)
	operator.set("_block_phase", &"enter")
	guard.set("phase", GUARD_CONTROLLER.Phase.GUARD_ENTER)
	operator.call("_play_block_animation", &"melee_2h_block_enter")
	_assert_true(operator.call("get_body_presentation_owner") == BODY_PRESENTER.Owner.LEGACY_FULL_BODY, "missing upper layer should choose the complete fallback")
	_assert_true(legacy.visible and not lower.visible and not upper.visible, "missing layer must not leave half a modular body visible")
	upper.sprite_frames = original_frames

	# Guard break remains impact-locked and never selects the mobile composition.
	operator.set("_block_phase", &"guard_break")
	operator.set("_enemy_impact_lock_timer", 0.4)
	guard.set("phase", GUARD_CONTROLLER.Phase.GUARD_BREAK)
	_assert_true(not bool(operator.call("_is_mobile_guard_composition_allowed")), "guard break must not select mobile composition")
	_assert_true(float(operator.get("_enemy_impact_lock_timer")) > 0.0, "guard break must retain its impact movement lock")
	operator.call("_play_block_animation", &"melee_2h_block_hitreact")
	_assert_true(lower.animation == &"unarmed/defense/block_hit_01/e/lower_body", "guard break should keep the complete paired block presentation")

	operator.set("_enemy_impact_lock_timer", 0.0)
	operator.set("velocity", Vector2.ZERO)
	operator.set("_block_phase", &"")
	operator.set("_block_active", false)


func _assert_guard_pair(operator: Node, lower_identity: StringName, upper_identity: StringName, message: String) -> void:
	var lower := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	var upper := operator.get("modular_upper_body_sprite") as AnimatedSprite2D
	_assert_true(bool(operator.call("_is_modular_block_active")), message + " (owner)")
	_assert_true(lower.visible and lower.animation == lower_identity, message + " (lower)")
	_assert_true(upper.visible and upper.animation == upper_identity, message + " (upper)")


func _assert_lower_progress(sprite: AnimatedSprite2D, frame: int, progress: float, message: String) -> void:
	_assert_true(sprite.frame == frame, message + " (frame)")
	_assert_true(is_equal_approx(sprite.frame_progress, progress), message + " (progress)")

func _validate_unarmed_heavy_fx_survives_visual_update(operator: Node) -> void:
	operator.call("_exit_ranged_ready")
	operator.set("combat_loadout_mode", "melee")
	operator.set("primary_weapon_equipped", false)
	operator.set("using_unarmed", true)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.RIGHT)

	# C2b.1: the FX renderer binds the canonical database, so the unarmed heavy
	# clip is its semantic identity rather than the `fx_map` spelling.
	_assert_animation_exists(operator, "melee_fx_overlay_sprite", &"unarmed/attack/heavy_01/e/fx")
	operator.call("start_attack", "unarmed_heavy")
	var fx_sprite := operator.get("melee_fx_overlay_sprite") as AnimatedSprite2D
	_assert_true(fx_sprite != null and fx_sprite.visible, "unarmed heavy should show its melee FX overlay when the attack starts")
	_assert_true(fx_sprite != null and fx_sprite.animation == &"unarmed/attack/heavy_01/e/fx", "unarmed heavy should play right heavy FX")
	operator.call("_update_primary_weapon_visual", false)
	_assert_true(fx_sprite != null and fx_sprite.visible, "unarmed heavy FX should survive the normal weapon visual update")
	_assert_true(fx_sprite != null and fx_sprite.animation == &"unarmed/attack/heavy_01/e/fx", "weapon visual update should not replace unarmed heavy FX")
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

	_assert_animation_exists(operator, "modular_upper_body_sprite", &"ranged_2h/posture/stance_01/e/upper_body")
	_assert_animation_exists(operator, "modular_lower_body_sprite", &"ranged_2h/cosmetic/aim_01/e/lower_body")
	_assert_animation_exists(operator, "modular_upper_body_sprite", &"ranged_2h/cosmetic/aim_01/e/upper_body")
	operator.call("_enter_ranged_ready")
	_assert_true(bool(operator.call("_is_ranged_ready_active")), "carbine should enter ranged-ready")
	_assert_true(bool(operator.call("_has_modular_ranged_ready_upper_stack")), "east ranged-ready stack should be accepted")
	_assert_true(bool(operator.call("_is_primary_ranged_aim_presentation_active")), "carbine ranged-ready should start modular aim raise")

	var lower_sprite := operator.get("modular_lower_body_sprite") as AnimatedSprite2D
	var upper_sprite := operator.get("modular_upper_body_sprite") as AnimatedSprite2D
	var weapon_sprite := operator.get("weapon_sprite") as Sprite2D
	var cape_sprite := operator.get("modular_cape_sprite") as AnimatedSprite2D
	_assert_true(lower_sprite != null and lower_sprite.animation == &"ranged_2h/cosmetic/aim_01/e/lower_body", "ranged-ready should play lower east aim raise")
	_assert_true(upper_sprite != null and upper_sprite.animation == &"ranged_2h/cosmetic/aim_01/e/upper_body", "ranged-ready should play upper east aim raise")
	_assert_true(weapon_sprite != null, "ranged-ready should have static carbine weapon sprite")
	_assert_true(cape_sprite == null or not cape_sprite.visible, "ranged-ready should hide cape (no ranged-aim cape animation available)")
	operator.call("_tick_primary_ranged_action_presentation", 1.0)
	_assert_true(not bool(operator.call("_is_primary_ranged_aim_presentation_active")), "modular aim raise should finish before stance")
	_assert_true(bool(operator.call("_sync_modular_ranged_2h_stance_presentation", Vector2.RIGHT)), "east ranged-ready should sync modular stance")

	_assert_true(upper_sprite != null and upper_sprite.animation == &"ranged_2h/posture/stance_01/e/upper_body", "ranged-ready should play upper east stance")
	_assert_true(weapon_sprite != null and weapon_sprite.visible and weapon_sprite.texture == CARBINE_DEFINITION.directional_weapon_textures["e"], "ranged-ready should keep static carbine east stance texture")


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
