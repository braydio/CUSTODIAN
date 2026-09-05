extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const VIGIL_FX_FRAMES := preload("res://game/actors/operator/vigil_pattern_dagger_fx_frames.tres")
const VIGIL_OVERLAY_FRAMES := preload("res://game/actors/operator/vigil_pattern_dagger_melee_overlay_frames.tres")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert_canonical_vigil_resources()

	var operator := OPERATOR_SCENE.instantiate()
	root.add_child(operator)
	await process_frame
	operator.set_process(false)
	operator.set_physics_process(false)

	var vigil_definition = operator.get("melee_weapon_definition")
	_expect(vigil_definition != null, "operator is missing a melee_weapon_definition")
	operator.set("combat_loadout_mode", &"melee")
	operator.set("using_unarmed", false)
	operator.set("primary_weapon_equipped", true)
	operator.call("_apply_melee_weapon_animation_resources", vigil_definition)
	var armed_weapons: Array = operator.get("armed_weapons")
	var vigil_index := armed_weapons.find(vigil_definition)
	_expect(vigil_index >= 0, "Vigil definition missing from weapon selection")
	operator.call("_apply_armed_selection", vigil_index)

	var lower := operator.get_node("ModularLowerBodySprite") as AnimatedSprite2D
	var upper := operator.get_node("ModularUpperBodySprite") as AnimatedSprite2D
	var weapon := operator.get_node("MeleeWeaponOverlaySprite") as AnimatedSprite2D
	var legacy_body := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D

	await _run_sheathe_case(operator, lower, upper, weapon, legacy_body, "e", Vector2.RIGHT, vigil_definition, vigil_index)
	await _run_sheathe_case(operator, lower, upper, weapon, legacy_body, "w", Vector2.LEFT, vigil_definition, vigil_index)

	operator.free()
	if _failures.is_empty():
		print("operator_melee_sheathe_smoke: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _run_sheathe_case(
	operator: Node,
	lower: AnimatedSprite2D,
	upper: AnimatedSprite2D,
	weapon: AnimatedSprite2D,
	legacy_body: AnimatedSprite2D,
	suffix: String,
	direction: Vector2,
	vigil_definition,
	vigil_index: int
) -> void:
	# Restore an armed, ready Vigil loadout before each directional case.
	operator.set("pending_weapon_selection", {})
	operator.call("_apply_armed_selection", vigil_index)
	operator.set("visual_idle_direction", direction)
	_expect(
		bool(operator.call("_sync_modular_melee_posture", direction)),
		"%s: failed to reach ready/relaxed posture before sheathe" % suffix
	)

	operator.call("queue_weapon_selection", {"type": "unarmed"})

	_expect(
		operator.get("_animation_state_machine").current_state == "sheathe_weapon",
		"%s: weapon selection did not enter sheathe_weapon state" % suffix
	)
	_expect(
		operator.call("_get_equipped_primary_weapon_definition") == vigil_definition,
		"%s: current weapon must remain Vigil before sheathe commits" % suffix
	)
	_expect(not bool(operator.get("using_unarmed")), "%s: using_unarmed flipped before sheathe committed" % suffix)

	var lower_animation := "melee_1h/posture/sheathe_01/%s/lower_body" % suffix
	var upper_animation := "melee_1h/posture/sheathe_01/%s/upper_body" % suffix
	var weapon_animation := "melee_1h_dagger/posture/sheathe_01/%s/weapon" % suffix
	_expect(String(lower.animation) == lower_animation, "%s: lower body did not play sheathe animation" % suffix)
	_expect(String(upper.animation) == upper_animation, "%s: upper body did not play sheathe animation" % suffix)
	_expect(String(weapon.animation) == weapon_animation, "%s: weapon overlay did not play sheathe animation" % suffix)
	_expect(not lower.flip_h, "%s: lower body must never mirror an authored sheathe strip" % suffix)
	_expect(not upper.flip_h, "%s: upper body must never mirror an authored sheathe strip" % suffix)
	_expect(not weapon.flip_h, "%s: weapon overlay must never mirror an authored sheathe strip" % suffix)
	_expect(lower.frame == 0, "%s: sheathe must start at frame 0" % suffix)
	_expect(upper.frame == 0, "%s: sheathe must start at frame 0" % suffix)
	_expect(weapon.frame == 0, "%s: weapon overlay must start at frame 0" % suffix)

	_assert_hidden_legacy_body_does_not_hijack(operator, lower, weapon, legacy_body, suffix)

	await create_timer(0.4).timeout
	_expect(lower.frame == 3 and upper.frame == 3, "%s: sheathe layers must advance to their final frame" % suffix)
	_expect(
		weapon.frame == lower.frame and is_equal_approx(weapon.frame_progress, lower.frame_progress),
		"%s: weapon overlay must track the modular lower-body frame/progress" % suffix
	)
	_expect(
		not bool(operator.get("using_unarmed")),
		"%s: target selection committed before the state machine processed sheathe completion" % suffix
	)

	operator.call("_update_animation_state_machine", 0.016)

	_expect(bool(operator.get("using_unarmed")), "%s: target selection did not commit after the final sheathe frame" % suffix)
	_expect(not weapon.visible, "%s: weapon overlay must disappear once unarmed commits" % suffix)
	var resolver = operator.get("_melee_posture_resolver")
	_expect(
		resolver.posture == MeleePostureResolver.Posture.SHEATHED,
		"%s: melee posture resolver must report SHEATHED after sheathe commits" % suffix
	)
	_expect(
		operator.get("_animation_state_machine").current_state == "idle",
		"%s: state machine must return to idle after an unarmed commit" % suffix
	)


func _assert_hidden_legacy_body_does_not_hijack(
	operator: Node,
	lower: AnimatedSprite2D,
	weapon: AnimatedSprite2D,
	legacy_body: AnimatedSprite2D,
	suffix: String
) -> void:
	_expect(not legacy_body.visible, "%s: modular sheathe must own visible body presentation" % suffix)
	_expect(
		int(operator.get("_melee_overlay_clock_owner")) == 2,
		"%s: active sheathe must claim MODULAR_LOWER_BODY overlay clock ownership" % suffix
	)
	var expected_animation := weapon.animation
	var expected_frame := weapon.frame
	var expected_progress := weapon.frame_progress
	# Simulate the previously-identified race: the legacy body reports itself
	# as slaved-attack-active (and visible) at the same moment modular sheathe
	# owns the overlay. Ownership, not visibility, must be what protects the
	# weapon overlay here.
	legacy_body.visible = true
	legacy_body.flip_h = true
	operator.set("_melee_recovery_active", true)
	var legacy_frame_count := 0
	if legacy_body.sprite_frames != null and legacy_body.sprite_frames.has_animation(legacy_body.animation):
		legacy_frame_count = legacy_body.sprite_frames.get_frame_count(legacy_body.animation)
	for step in range(3):
		if legacy_frame_count > 0:
			legacy_body.frame = (legacy_body.frame + 1) % legacy_frame_count
		legacy_body.frame_changed.emit()
		_expect(weapon.animation == expected_animation, "%s: hidden legacy body changed the sheathe weapon animation" % suffix)
		_expect(not weapon.flip_h, "%s: hidden legacy body flipped explicit sheathe weapon art" % suffix)
		_expect(weapon.frame == expected_frame, "%s: hidden legacy body replaced the modular sheathe weapon frame" % suffix)
		_expect(
			is_equal_approx(weapon.frame_progress, expected_progress),
			"%s: hidden legacy body replaced the modular sheathe weapon frame progress" % suffix
		)
		_expect(String(lower.animation).contains("/posture/sheathe_01/"), "%s: hidden legacy body replaced the modular lower body animation" % suffix)
	operator.set("_melee_recovery_active", false)
	legacy_body.visible = false


func _assert_canonical_vigil_resources() -> void:
	for animation_name in [&"vigil_dagger_fast_03_fx_left", &"vigil_dagger_fast_03_fx_right"]:
		_expect(VIGIL_FX_FRAMES.has_animation(animation_name), "missing %s" % animation_name)
		_expect(VIGIL_FX_FRAMES.get_frame_count(animation_name) == 8, "%s must be 8 frames (canonical fast_03 fx)" % animation_name)
	for animation_name in [&"vigil_dagger_fast_02_weapon_left", &"vigil_dagger_fast_02_weapon_right"]:
		_expect(VIGIL_OVERLAY_FRAMES.has_animation(animation_name), "missing %s" % animation_name)
		_expect(VIGIL_OVERLAY_FRAMES.get_frame_count(animation_name) == 8, "%s must be 8 frames (canonical fast_02 weapon)" % animation_name)

	var fx_source := FileAccess.get_file_as_string(
		"res://game/actors/operator/vigil_pattern_dagger_fx_frames.tres"
	)
	_expect(
		not fx_source.contains("legacy_operator_modular_fx_melee_1h_chain_03"),
		"Vigil FX resource must not reference the legacy chain_03 FX source"
	)
	var overlay_source := FileAccess.get_file_as_string(
		"res://game/actors/operator/vigil_pattern_dagger_melee_overlay_frames.tres"
	)
	_expect(
		not overlay_source.contains("legacy_operator_weapon_vigil_pattern_dagger_chain_02"),
		"Vigil weapon overlay resource must not reference the legacy chain_02 weapon source"
	)
	_expect(
		fx_source.contains("melee_1h/attack/fast_03/operator__fx__melee_1h__attack__fast_03__"),
		"Vigil FX resource must reference canonical melee_1h/attack/fast_03 art"
	)
	_expect(
		overlay_source.contains("melee_1h_dagger/attack/fast_02/operator__weapon__melee_1h_dagger__attack__fast_02__"),
		"Vigil weapon overlay resource must reference canonical melee_1h_dagger/attack/fast_02 art"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
