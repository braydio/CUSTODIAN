extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CombatConstants := preload(
	"res://game/systems/combat/combat_constants.gd"
)
const WeaponSocketTracks := preload(
	"res://game/actors/operator/animations/operator_weapon_socket_tracks.gd"
)

var _failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var root := Node2D.new()
	root.name = "OperatorModularIdleHitreactSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame

	var lower := operator.get_node("ModularLowerBodySprite") as AnimatedSprite2D
	var upper := operator.get_node("ModularUpperBodySprite") as AnimatedSprite2D
	var head := operator.get_node("ModularHeadSprite") as AnimatedSprite2D
	var legacy := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	for sprite in [lower, upper]:
		for animation_name in [
			&"operator_idle_hitreact_modular_up",
			&"operator_idle_hitreact_modular_down",
		]:
			_assert(
				sprite.sprite_frames.has_animation(animation_name),
				"%s should contain %s" % [sprite.name, animation_name]
			)
			_assert(
				sprite.sprite_frames.get_frame_count(animation_name) == 5,
				"%s should contain five frames" % animation_name
			)

	operator.set("_damage_reaction_strength", CombatConstants.HitStrength.LIGHT)
	_assert_reaction_direction(
		operator,
		Vector2.UP,
		&"operator_idle_hitreact_modular_up",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")
	_assert_reaction_direction(
		operator,
		Vector2(1.0, -1.0),
		&"operator_idle_hitreact_modular_up",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")
	_assert_reaction_direction(
		operator,
		Vector2(-1.0, -1.0),
		&"operator_idle_hitreact_modular_up",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")
	_assert_reaction_direction(
		operator,
		Vector2.DOWN,
		&"operator_idle_hitreact_modular_down",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")
	_assert_reaction_direction(
		operator,
		Vector2(1.0, 1.0),
		&"operator_idle_hitreact_modular_down",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")
	_assert_reaction_direction(
		operator,
		Vector2(-1.0, 1.0),
		&"operator_idle_hitreact_modular_down",
		lower,
		upper,
		head,
		legacy
	)
	operator.call("finish_damage_reaction_presentation")

	operator.set("visual_idle_direction", Vector2.UP)
	_assert(bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "north setup should begin")
	operator.call("finish_damage_reaction_presentation")
	operator.set("visual_idle_direction", Vector2.RIGHT)
	_assert(bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "east tie should begin")
	_assert(lower.animation == &"operator_idle_hitreact_modular_up", "east should preserve previous north sector")
	operator.call("finish_damage_reaction_presentation")
	operator.set("visual_idle_direction", Vector2.DOWN)
	_assert(bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "south setup should begin")
	operator.call("finish_damage_reaction_presentation")
	operator.set("visual_idle_direction", Vector2.LEFT)
	_assert(bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "west tie should begin")
	_assert(lower.animation == &"operator_idle_hitreact_modular_down", "west should preserve previous south sector")
	operator.call("_update_animation")
	_assert(lower.animation == &"operator_idle_hitreact_modular_down", "locomotion must not overwrite active modular reaction")
	operator.call("finish_damage_reaction_presentation")

	var original_upper_frames := upper.sprite_frames
	var incomplete_frames := original_upper_frames.duplicate() as SpriteFrames
	incomplete_frames.remove_animation(&"operator_idle_hitreact_modular_down")
	upper.sprite_frames = incomplete_frames
	operator.set("visual_idle_direction", Vector2.DOWN)
	var lower_visibility_before := lower.visible
	var upper_visibility_before := upper.visible
	_assert(
		not bool(operator.call("begin_modular_damage_reaction", "hit_recoil")),
		"missing required upper art should use legacy fallback"
	)
	_assert(
		lower.visible == lower_visibility_before and upper.visible == upper_visibility_before,
		"missing required art should fail atomically"
	)
	upper.sprite_frames = original_upper_frames

	operator.set("_damage_reaction_strength", CombatConstants.HitStrength.HEAVY)
	_assert(not bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "knockdown/heavy reaction should retain higher priority")
	operator.set("_damage_reaction_strength", CombatConstants.HitStrength.LIGHT)
	operator.set("_paired_execution_active", true)
	_assert(not bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "execution should retain higher priority")
	operator.set("_paired_execution_active", false)
	operator.set("_is_dead", true)
	_assert(not bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "death should retain higher priority")
	operator.set("_is_dead", false)

	# Cleanup must surrender modular reaction ownership and leave the body in a
	# single-owner state.
	#
	# It cannot assert a *modular* restore here, and that is a characterized
	# runtime limitation rather than a test convenience. With a ranged primary
	# equipped, the restored presentation runs through
	# `_apply_frame_aware_primary_weapon_socket()`, which only supports
	# `OperatorWeaponSocketTracks.REQUIRED_SECTORS` = [e, w, se, sw]. Aim is
	# re-resolved from input on the next physics frame, and headless input has
	# no mouse position, so the aim lands on sector `n` no matter what this test
	# assigns to `aim_direction`. Sector `n` is unsupported, the weapon socket
	# refuses, and the composition correctly falls back to the legacy full body.
	#
	# Asserting the modular restore needs deterministic aim ownership, which is
	# Slice D of the Operator runtime decomposition
	# (`design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`). Until then the
	# invariant worth guarding is the one-body rule through the handoff.
	operator.set("visual_idle_direction", Vector2.DOWN)
	operator.set("movement_direction", Vector2.ZERO)
	_assert(bool(operator.call("begin_modular_damage_reaction", "hit_recoil")), "cleanup setup should begin")
	operator.call("finish_damage_reaction_presentation")
	_assert(not bool(operator.get("_modular_damage_reaction_active")), "cleanup should clear modular reaction ownership")
	await process_frame
	var cleanup_sector = operator.call(
		"resolve_aim_sector", operator.call("_get_frame_aware_weapon_direction")
	)
	var cleanup_owners: Array = operator.call("get_visible_body_owners")
	_assert(
		cleanup_owners.size() == 1,
		"cleanup must leave exactly one visible body owner, saw %d" % cleanup_owners.size()
	)
	if WeaponSocketTracks.REQUIRED_SECTORS.has(cleanup_sector):
		_assert(lower.visible and upper.visible, "supported aim sector should restore modular idle presentation")
	else:
		_assert(
			legacy.visible and not upper.visible,
			"unsupported aim sector %s must fall back to the legacy body" % cleanup_sector
		)

	# Combat tempo + impact feedback pass: the shared incoming-damage
	# presentation package (hit stop + small directional recoil) must fire
	# for BOTH the modular and fallback damage-reaction branches -- it must
	# not be skipped just because begin_modular_damage_reaction() succeeded.
	operator.set("visual_idle_direction", Vector2.DOWN)
	operator.set("movement_direction", Vector2.ZERO)
	operator.set("velocity", Vector2.ZERO)
	operator.set("_enemy_impact_lock_timer", 0.0)
	operator.set("_incoming_hit_stop_active", false)
	operator.set("_last_damage_reaction_direction", Vector2.DOWN)
	var base_time_scale := Engine.time_scale
	operator.call("play_damage_reaction_fx", &"operator_idle_hitreact_modular_down", true)
	_assert(Engine.time_scale < base_time_scale, "modular damage reaction must still trigger the shared hit stop")
	_assert((operator.get("velocity") as Vector2).length() > 0.0, "modular damage reaction must still trigger the shared directional recoil")
	Engine.time_scale = base_time_scale
	operator.set("_incoming_hit_stop_active", false)
	operator.call("finish_damage_reaction_presentation")

	operator.set("velocity", Vector2.ZERO)
	operator.set("_enemy_impact_lock_timer", 0.0)
	operator.call("play_damage_reaction_fx", &"unarmed_light_hitreact_down", false)
	_assert(Engine.time_scale < base_time_scale, "fallback (non-modular) damage reaction must trigger the shared hit stop")
	_assert((operator.get("velocity") as Vector2).length() > 0.0, "fallback (non-modular) damage reaction must trigger the shared directional recoil")
	Engine.time_scale = base_time_scale
	operator.set("_incoming_hit_stop_active", false)

	root.queue_free()
	await process_frame
	if _failed:
		push_error("operator_modular_idle_hitreact_smoke failed")
		quit(1)
		return
	print("[OperatorModularIdleHitreactSmoke] synchronized N/S reaction, fallback, priority, and cleanup passed.")
	quit(0)


func _assert_reaction_direction(
	operator: Node,
	direction: Vector2,
	expected_animation: StringName,
	lower: AnimatedSprite2D,
	upper: AnimatedSprite2D,
	head: AnimatedSprite2D,
	legacy: AnimatedSprite2D
) -> void:
	operator.set("visual_idle_direction", direction)
	_assert(
		bool(operator.call("begin_modular_damage_reaction", "hit_recoil")),
		"reaction should begin for %s" % direction
	)
	_assert(lower.animation == expected_animation, "lower should resolve %s" % expected_animation)
	_assert(upper.animation == expected_animation, "upper should resolve %s" % expected_animation)
	_assert(lower.frame == 0 and upper.frame == 0, "required layers should start on frame zero")
	_assert(lower.visible and upper.visible, "required modular layers should be visible")
	_assert(not legacy.visible, "legacy and modular bodies must not render together")
	# C2a authoring decision 2026-09-12: the modular head is preserved but retired
	# from the active composition (Operator.ACTIVE_MODULAR_HEAD is false). Its art
	# is still published and it may still have a matching clip, so assert the
	# retirement rather than the old "optional head joins" behaviour — otherwise
	# this test would pass again the moment the head quietly came back.
	_assert(
		not head.visible,
		"retired modular head must not draw in a reaction (ACTIVE_MODULAR_HEAD is false)"
	)


func _assert(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
