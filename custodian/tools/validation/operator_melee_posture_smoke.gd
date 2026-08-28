extends SceneTree

const RESOLVER_SCRIPT := preload("res://game/actors/operator/presentation/melee_posture_resolver.gd")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CATALOG_FRAMES := preload("res://game/actors/operator/operator_animation_catalog_frames.tres")


func _init() -> void:
	var resolver := RESOLVER_SCRIPT.new() as MeleePostureResolver
	assert(resolver.resolve(0.0, false, false, false) == MeleePostureResolver.Posture.SHEATHED)
	resolver.begin_draw_grace(3.0)
	assert(resolver.resolve(2.0, true, false, false) == MeleePostureResolver.Posture.READY)
	assert(resolver.resolve(1.1, true, false, false) == MeleePostureResolver.Posture.RELAXED)
	assert(resolver.resolve(0.0, true, true, false) == MeleePostureResolver.Posture.READY)
	assert(resolver.resolve(0.0, true, false, true) == MeleePostureResolver.Posture.READY)
	assert(resolver.attack_action_bypasses_ready_up())
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
			assert(weapon.sprite_frames.get_frame_count(weapon_animation) == 4, "Vigil posture weapon must remain four frames")
		var run_weapon_animation := "melee_1h_dagger/locomotion/run_01/%s/weapon" % suffix
		assert(weapon.sprite_frames.has_animation(run_weapon_animation), "missing Vigil run weapon %s" % suffix)
		assert(weapon.sprite_frames.get_frame_count(run_weapon_animation) == 6, "Vigil run weapon must remain six frames")
	var armed_weapons: Array = operator.get("armed_weapons")
	var vigil_index := armed_weapons.find(vigil_definition)
	assert(vigil_index >= 0)
	operator.call("_apply_armed_selection", vigil_index)
	var runtime_resolver = operator.get("_melee_posture_resolver") as MeleePostureResolver
	assert(runtime_resolver.resolve(4.0, true, false, false) == MeleePostureResolver.Posture.RELAXED)
	assert(operator.call("_sync_modular_melee_posture", Vector2.RIGHT))
	assert(weapon.visible, "Vigil posture weapon overlay should be visible")
	assert(weapon.animation == &"melee_1h_dagger/posture/idle_relaxed_01/e/weapon")
	assert(weapon.is_playing(), "Vigil posture weapon overlay should animate")
	assert(runtime_resolver.resolve(0.0, true, true, false) == MeleePostureResolver.Posture.READY)
	assert(operator.call("_sync_modular_melee_posture", Vector2.LEFT))
	assert(weapon.animation == &"melee_1h_dagger/posture/idle_ready_01/w/weapon")
	assert(weapon.visible and weapon.is_playing(), "Vigil ready weapon overlay should animate")
	assert(operator.call("_sync_modular_locomotion_layers", "unarmed_run", Vector2.RIGHT, Vector2.RIGHT, 1.0))
	assert(lower.animation == &"melee_1h/locomotion/run_01/e/lower_body")
	assert(upper.animation == &"melee_1h/locomotion/run_01/e/upper_body")
	assert(weapon.animation == &"melee_1h_dagger/locomotion/run_01/e/weapon")
	var socket_snapshot := operator.call("get_melee_locomotion_socket_snapshot") as Dictionary
	assert(bool(socket_snapshot.active), "Vigil run weapon should use locomotion socket mode")
	assert(weapon.visible and not weapon.is_playing(), "socketed Vigil run weapon must use the body clock")
	assert(not operator.call("_sync_modular_locomotion_layers", "unarmed_walk", Vector2.RIGHT, Vector2.RIGHT, 1.0), "missing Vigil walk art must retain fallback")
	assert(not lower.visible and not upper.visible and not weapon.visible, "melee locomotion fallback must hide the incomplete modular stack")
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
	var source := FileAccess.get_file_as_string("res://game/actors/operator/operator.gd")
	assert(not source.contains("AnimationResolver.resolve(\"melee_1h_stance_01\""))
	assert(not source.contains("/posture/draw_weapon_01/"), "runtime must not reference retired draw_weapon_01")
	assert(source.contains("_engagement_tracker.engagement_active"))
	assert(source.contains("_sync_modular_melee_posture"))
	operator.free()
	print("operator_melee_posture_smoke: PASS")
	quit(0)
