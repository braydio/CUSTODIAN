extends SceneTree

const POSTURE_STATE_SCRIPT := preload("res://game/actors/operator/presentation/melee_posture_state.gd")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CATALOG_FRAMES := preload("res://game/actors/operator/operator_animation_catalog_frames.tres")
const RUNTIME_FRAMES := preload("res://content/sprites/operator/runtime/operator_runtime_frames.tres")


func _init() -> void:
	var posture_state := POSTURE_STATE_SCRIPT.new() as MeleePostureState
	assert(posture_state.resolve(0.0, false, false, false) == MeleePostureState.Posture.SHEATHED)
	posture_state.begin_draw_grace(3.0)
	assert(posture_state.resolve(2.0, true, false, false) == MeleePostureState.Posture.READY)
	assert(posture_state.resolve(1.1, true, false, false) == MeleePostureState.Posture.RELAXED)
	assert(posture_state.resolve(0.0, true, true, false) == MeleePostureState.Posture.READY)
	assert(posture_state.resolve(0.0, true, false, true) == MeleePostureState.Posture.READY)
	assert(not posture_state.attack_action_bypasses_ready_up())
	for action in ["relaxed_to_ready_01", "ready_to_relaxed_01"]:
		for suffix in ["e", "w"]:
			for layer in ["lower_body", "upper_body"]:
				var body_bridge := StringName("melee_1h/transition/%s/%s/%s" % [action, suffix, layer])
				assert(RUNTIME_FRAMES.has_animation(body_bridge))
				assert(not RUNTIME_FRAMES.get_animation_loop(body_bridge))
			var weapon_bridge := StringName("weapon/vigil_pattern_dagger/melee_1h_dagger/transition/%s/%s/weapon" % [action, suffix])
			assert(RUNTIME_FRAMES.has_animation(weapon_bridge))
			assert(not RUNTIME_FRAMES.get_animation_loop(weapon_bridge))
	var operator := OPERATOR_SCENE.instantiate()
	assert(CATALOG_FRAMES.has_animation("melee_1h/posture/idle_ready_01/e/lower_body"))
	for suffix in ["e", "w"]:
		for layer in ["lower_body", "upper_body"]:
			var draw_body_animation := "melee_1h/posture/draw_01/%s/%s" % [suffix, layer]
			assert(CATALOG_FRAMES.has_animation(draw_body_animation), "missing draw body %s %s" % [suffix, layer])
			assert(CATALOG_FRAMES.get_frame_count(draw_body_animation) == 4)
			assert(not CATALOG_FRAMES.get_animation_loop(draw_body_animation), "draw body must not loop")
		var draw_weapon_animation := "melee_1h_dagger/posture/draw_01/%s/weapon" % suffix
		assert(CATALOG_FRAMES.has_animation(draw_weapon_animation), "missing draw weapon %s" % suffix)
		assert(CATALOG_FRAMES.get_frame_count(draw_weapon_animation) == 4)
		assert(not CATALOG_FRAMES.get_animation_loop(draw_weapon_animation), "draw weapon must not loop")
	assert(CATALOG_FRAMES.get_animation_loop(&"melee_1h/posture/idle_relaxed_01/e/lower_body"))
	assert(CATALOG_FRAMES.get_animation_loop(&"shared/locomotion/idle_01/s/head"))
	assert(not CATALOG_FRAMES.get_animation_loop(&"melee_1h/attack/fast_01/e/lower_body"))
	assert(not CATALOG_FRAMES.get_animation_loop(&"unarmed/reaction/light_hitreact_01/s/full_body"))
	assert(CATALOG_FRAMES.has_animation("melee_1h_dagger/posture/idle_relaxed_01/e/weapon"))
	assert(CATALOG_FRAMES.has_animation("melee_1h_dagger/posture/idle_relaxed_01/w/weapon"))
	for suffix in ["e", "w"]:
		assert(CATALOG_FRAMES.has_animation("melee_1h/posture/idle_ready_01/%s/lower_body" % suffix))
		assert(CATALOG_FRAMES.has_animation("melee_1h/posture/idle_ready_01/%s/upper_body" % suffix))
		assert(CATALOG_FRAMES.has_animation("melee_1h_dagger/posture/idle_ready_01/%s/weapon" % suffix))
		assert(CATALOG_FRAMES.has_animation("melee_1h/locomotion/run_01/%s/lower_body" % suffix))
		assert(CATALOG_FRAMES.has_animation("melee_1h/locomotion/run_01/%s/upper_body" % suffix))
		assert(CATALOG_FRAMES.has_animation("melee_1h_dagger/locomotion/run_01/%s/weapon" % suffix))
	for action in ["run_01", "walk_01"]:
		var expected_frames := 12 if action == "run_01" else 8
		for layer in ["lower_body", "upper_body"]:
			var body_animation := "melee_1h/locomotion/%s/s/%s" % [action, layer]
			assert(CATALOG_FRAMES.has_animation(body_animation), "missing south %s %s" % [action, layer])
			assert(CATALOG_FRAMES.get_frame_count(body_animation) == expected_frames)
		var weapon_animation := "melee_1h_dagger/locomotion/%s/s/weapon" % action
		assert(CATALOG_FRAMES.has_animation(weapon_animation), "missing south Vigil %s" % action)
		assert(CATALOG_FRAMES.get_frame_count(weapon_animation) == expected_frames)
	root.add_child(operator)
	await process_frame
	operator.call("_install_melee_posture_catalog_frames")
	var lower := operator.get_node("ModularLowerBodySprite") as AnimatedSprite2D
	var upper := operator.get_node("ModularUpperBodySprite") as AnimatedSprite2D
	var weapon := operator.get_node("MeleeWeaponOverlaySprite") as AnimatedSprite2D
	for action in ["idle_ready_01", "idle_relaxed_01"]:
		for suffix in ["e", "w"]:
			operator.call("_copy_catalog_animation", CATALOG_FRAMES, lower.sprite_frames, StringName("melee_1h/posture/%s/%s/lower_body" % [action, suffix]))
			operator.call("_copy_catalog_animation", CATALOG_FRAMES, upper.sprite_frames, StringName("melee_1h/posture/%s/%s/upper_body" % [action, suffix]))
			assert(lower.sprite_frames.has_animation("melee_1h/posture/%s/%s/lower_body" % [action, suffix]), "missing lower %s %s" % [action, suffix])
			assert(upper.sprite_frames.has_animation("melee_1h/posture/%s/%s/upper_body" % [action, suffix]), "missing upper %s %s" % [action, suffix])
	for suffix in ["e", "w"]:
		for layer in ["lower_body", "upper_body"]:
			var draw_animation := StringName("melee_1h/posture/draw_01/%s/%s" % [suffix, layer])
			var target := lower.sprite_frames if layer == "lower_body" else upper.sprite_frames
			operator.call("_copy_catalog_animation", CATALOG_FRAMES, target, draw_animation)
			assert(target.has_animation(draw_animation))
	var vigil_definition = operator.get("melee_weapon_definition")
	assert(vigil_definition != null)
	assert(vigil_definition.get_animation_profile() == &"melee_1h_dagger")
	operator.call("_apply_melee_weapon_animation_resources", vigil_definition)
	for suffix in ["e", "w"]:
		for action in ["idle_ready_01", "idle_relaxed_01"]:
			var weapon_animation := "melee_1h_dagger/posture/%s/%s/weapon" % [action, suffix]
			assert(weapon.sprite_frames.has_animation(weapon_animation), "missing Vigil posture weapon %s %s" % [action, suffix])
			var expected_frames := 5 if action == "idle_ready_01" and suffix == "e" else 4
			assert(
				weapon.sprite_frames.get_frame_count(weapon_animation) == expected_frames,
				"Vigil posture weapon frame contract mismatch for %s %s" % [action, suffix],
			)
		var run_weapon_animation := "melee_1h_dagger/locomotion/run_01/%s/weapon" % suffix
		assert(weapon.sprite_frames.has_animation(run_weapon_animation), "missing Vigil run weapon %s" % suffix)
		assert(weapon.sprite_frames.get_frame_count(run_weapon_animation) == 6, "Vigil run weapon must remain six frames")
	var armed_weapons: Array = operator.get("armed_weapons")
	var vigil_index := armed_weapons.find(vigil_definition)
	assert(vigil_index >= 0)
	operator.call("_apply_armed_selection", vigil_index)
	assert(operator.call("_start_vigil_posture_bridge", &"ready_to_relaxed_01"))
	var bridge_lower := operator.get_node("VigilPostureBridgeLower") as AnimatedSprite2D
	var bridge_upper := operator.get_node("VigilPostureBridgeUpper") as AnimatedSprite2D
	var bridge_weapon := operator.get_node("VigilPostureBridgeWeapon") as AnimatedSprite2D
	assert(bridge_lower.animation == &"melee_1h/transition/ready_to_relaxed_01/e/lower_body")
	assert(bridge_upper.animation == &"melee_1h/transition/ready_to_relaxed_01/e/upper_body")
	assert(bridge_weapon.animation == &"weapon/vigil_pattern_dagger/melee_1h_dagger/transition/ready_to_relaxed_01/e/weapon")
	assert(operator.call("_try_start_vigil_ready_fast_startup"), "attack must redirect a passive settle bridge")
	assert(operator.get("_vigil_posture_bridge_action") == &"relaxed_to_ready_01")
	assert(bool(operator.get("_vigil_posture_bridge_attack_queued")))
	assert(bridge_lower.animation == &"melee_1h/transition/relaxed_to_ready_01/e/lower_body")
	operator.set("_vigil_posture_bridge_token", int(operator.get("_vigil_posture_bridge_token")) + 1)
	operator.set("_vigil_posture_bridge_action", &"")
	operator.set("_vigil_posture_bridge_attack_queued", false)
	for sprite in [bridge_lower, bridge_upper, bridge_weapon]:
		sprite.stop()
		sprite.visible = false
	var runtime_posture_state = operator.get("_melee_posture_state") as MeleePostureState
	assert(runtime_posture_state.resolve(4.0, true, false, false) == MeleePostureState.Posture.RELAXED)
	assert(operator.call("_sync_modular_melee_posture", Vector2.LEFT))
	assert(weapon.visible, "Vigil posture weapon overlay should be visible")
	assert(weapon.animation == &"melee_1h_dagger/posture/idle_relaxed_01/w/weapon")
	assert(weapon.is_playing(), "Vigil posture weapon overlay should animate")
	_assert_hidden_legacy_body_does_not_hijack(operator, lower, weapon)
	assert(runtime_posture_state.resolve(0.0, true, true, false) == MeleePostureState.Posture.READY)
	assert(operator.call("_sync_modular_melee_posture", Vector2.LEFT))
	assert(weapon.animation == &"melee_1h_dagger/posture/idle_ready_01/w/weapon")
	assert(weapon.visible and weapon.is_playing(), "Vigil ready weapon overlay should animate")
	_assert_hidden_legacy_body_does_not_hijack(operator, lower, weapon)
	assert(operator.call("_sync_modular_locomotion_layers", "unarmed_run", Vector2.RIGHT, Vector2.RIGHT, 1.0))
	assert(lower.animation == &"melee_1h/locomotion/run_01/e/lower_body")
	assert(upper.animation == &"melee_1h/locomotion/run_01/e/upper_body")
	assert(weapon.animation == &"melee_1h_dagger/locomotion/run_01/e/weapon")
	var socket_snapshot := operator.call("get_melee_locomotion_socket_snapshot") as Dictionary
	assert(bool(socket_snapshot.active), "Vigil run weapon should use locomotion socket mode")
	assert(weapon.visible and not weapon.is_playing(), "socketed Vigil run weapon must use the body clock")
	assert(operator.call("_sync_modular_locomotion_layers", "unarmed_run", Vector2.DOWN, Vector2.DOWN, 1.0))
	assert(lower.animation == &"melee_1h/locomotion/run_01/s/lower_body")
	assert(upper.animation == &"melee_1h/locomotion/run_01/s/upper_body")
	assert(weapon.animation == &"melee_1h_dagger/locomotion/run_01/s/weapon")
	assert(weapon.visible and weapon.is_playing(), "south Vigil run must use its authored weapon strip")
	assert(operator.call("_sync_modular_locomotion_layers", "unarmed_walk", Vector2.DOWN, Vector2.DOWN, 1.0))
	assert(lower.animation == &"melee_1h/locomotion/walk_01/s/lower_body")
	assert(upper.animation == &"melee_1h/locomotion/walk_01/s/upper_body")
	assert(weapon.animation == &"melee_1h_dagger/locomotion/walk_01/s/weapon")
	assert(weapon.visible and weapon.is_playing(), "south Vigil walk must use its authored weapon strip")
	assert(not operator.call("_sync_modular_locomotion_layers", "unarmed_walk", Vector2.RIGHT, Vector2.RIGHT, 1.0), "missing east Vigil walk must retain fallback")
	assert(not lower.visible and not upper.visible and not weapon.visible, "incomplete directional melee locomotion must hide the modular stack")
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.set("visual_idle_direction", Vector2.RIGHT)
	operator.call("start_equip_weapon_presentation")
	assert(lower.visible and upper.visible and weapon.visible, "draw must show lower, upper, and weapon layers")
	assert(lower.animation == &"melee_1h/posture/draw_01/e/lower_body")
	assert(upper.animation == &"melee_1h/posture/draw_01/e/upper_body")
	assert(weapon.animation == &"melee_1h_dagger/posture/draw_01/e/weapon")
	assert(not operator.call("is_equip_weapon_presentation_complete"), "draw must remain active while layers play")
	await create_timer(0.45).timeout
	assert(lower.frame == 3 and upper.frame == 3 and weapon.frame == 3, "draw layers must advance to their final frame")
	assert(operator.call("is_equip_weapon_presentation_complete"), "non-looping draw must complete naturally")
	operator.set("visual_idle_direction", Vector2.LEFT)
	operator.call("start_equip_weapon_presentation")
	assert(lower.animation == &"melee_1h/posture/draw_01/w/lower_body")
	assert(upper.animation == &"melee_1h/posture/draw_01/w/upper_body")
	assert(weapon.animation == &"melee_1h_dagger/posture/draw_01/w/weapon")
	operator.set("aim_direction", Vector2.LEFT)
	runtime_posture_state.posture = MeleePostureState.Posture.RELAXED
	assert(operator.call("_try_start_vigil_ready_fast_startup"), "relaxed Vigil attack should latch through its posture bridge")
	assert(operator.get("_vigil_posture_bridge_action") == &"relaxed_to_ready_01")
	assert(bool(operator.get("_vigil_posture_bridge_attack_queued")))
	await create_timer(0.30).timeout
	var startup_lower := operator.get_node("VigilFastStartupLower") as AnimatedSprite2D
	var startup_upper := operator.get_node("VigilFastStartupUpper") as AnimatedSprite2D
	var startup_weapon := operator.get_node("VigilFastStartupWeapon") as AnimatedSprite2D
	assert(startup_lower.animation == &"melee_1h/transition/idle_fast_transition_01/w/lower_body")
	assert(startup_upper.animation == &"melee_1h/transition/idle_fast_transition_01/w/upper_body")
	assert(startup_weapon.animation == &"melee_1h_dagger/transition/idle_fast_transition_01/w/weapon")
	assert(bool(operator.get("_melee_fast_windup")), "startup transition must reserve the attack startup window")
	assert(not bridge_lower.visible and not bridge_upper.visible and not bridge_weapon.visible, "READY idle must not appear between chained transitions")
	await create_timer(0.30).timeout
	assert(not bool(operator.get("_melee_fast_windup")), "startup transition must release into fast_01")
	assert(bool(operator.get("_melee_active")), "existing fast_01 attack must begin after startup")
	assert(not startup_lower.visible and not startup_upper.visible and not startup_weapon.visible)
	var source := FileAccess.get_file_as_string("res://game/actors/operator/operator.gd")
	assert(not source.contains("AnimationResolver.resolve(\"melee_1h_stance_01\""))
	assert(not source.contains("/posture/draw_weapon_01/"), "runtime must not reference retired draw_weapon_01")
	assert(source.contains("_engagement_tracker.engagement_active"))
	assert(source.contains("_sync_modular_melee_posture"))
	operator.free()
	print("operator_melee_posture_smoke: PASS")
	quit(0)


func _assert_hidden_legacy_body_does_not_hijack(
	operator: Node,
	lower: AnimatedSprite2D,
	weapon: AnimatedSprite2D
) -> void:
	var legacy_body := operator.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert(not legacy_body.visible, "modular posture must own visible body presentation")
	lower.set_frame_and_progress(2, 0.375)
	operator.call("_sync_modular_melee_posture", Vector2.LEFT)
	var expected_animation := weapon.animation
	var expected_frame := weapon.frame
	var expected_progress := weapon.frame_progress
	legacy_body.flip_h = true
	var legacy_frame_count := legacy_body.sprite_frames.get_frame_count(
		legacy_body.animation
	)
	for step in range(3):
		if legacy_frame_count > 0:
			legacy_body.frame = (legacy_body.frame + 1) % legacy_frame_count
		legacy_body.frame_changed.emit()
		assert(weapon.animation == expected_animation)
		assert(not weapon.flip_h, "hidden legacy body flipped explicit W weapon art")
		assert(weapon.frame == expected_frame, "hidden legacy body replaced modular weapon frame")
		assert(
			is_equal_approx(weapon.frame_progress, expected_progress),
			"hidden legacy body replaced modular weapon frame progress"
		)
