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
	assert(CATALOG_FRAMES.has_animation("melee_1h_dagger/posture/idle_relaxed_01/e/weapon"))
	assert(CATALOG_FRAMES.has_animation("melee_1h_dagger/posture/idle_relaxed_01/w/weapon"))
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
	operator.call("_copy_catalog_animation", CATALOG_FRAMES, lower.sprite_frames, &"melee_1h/posture/draw_weapon_01/e/lower_body")
	assert(lower.sprite_frames.has_animation("melee_1h/posture/draw_weapon_01/e/lower_body"))
	var vigil_definition = operator.get("melee_weapon_definition")
	assert(vigil_definition != null)
	assert(vigil_definition.get_animation_profile() == &"melee_1h_dagger")
	operator.call("_apply_melee_weapon_animation_resources", vigil_definition)
	for suffix in ["e", "w"]:
		var weapon_animation := "melee_1h_dagger/posture/idle_relaxed_01/%s/weapon" % suffix
		assert(weapon.sprite_frames.has_animation(weapon_animation), "missing Vigil posture weapon %s" % suffix)
		assert(weapon.sprite_frames.get_frame_count(weapon_animation) == 4, "Vigil posture weapon must remain four frames")
	operator.set("primary_weapon_equipped", true)
	operator.set("combat_loadout_mode", &"melee")
	operator.set("using_unarmed", false)
	var runtime_resolver = operator.get("_melee_posture_resolver") as MeleePostureResolver
	assert(runtime_resolver.resolve(4.0, true, false, false) == MeleePostureResolver.Posture.RELAXED)
	assert(operator.call("_sync_modular_melee_posture", Vector2.RIGHT))
	assert(weapon.visible, "Vigil posture weapon overlay should be visible")
	assert(weapon.animation == &"melee_1h_dagger/posture/idle_relaxed_01/e/weapon")
	assert(weapon.is_playing(), "Vigil posture weapon overlay should animate")
	var source := FileAccess.get_file_as_string("res://game/actors/operator/operator.gd")
	assert(not source.contains("AnimationResolver.resolve(\"melee_1h_stance_01\""))
	assert(source.contains("_engagement_tracker.engagement_active"))
	assert(source.contains("_sync_modular_melee_posture"))
	operator.free()
	print("operator_melee_posture_smoke: PASS")
	quit(0)
