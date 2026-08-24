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
	root.add_child(operator)
	operator.call("_install_melee_posture_catalog_frames")
	var lower := operator.get_node("ModularLowerBodySprite") as AnimatedSprite2D
	var upper := operator.get_node("ModularUpperBodySprite") as AnimatedSprite2D
	for action in ["idle_ready_01", "idle_relaxed_01"]:
		for suffix in ["e", "w"]:
			operator.call("_copy_catalog_animation", CATALOG_FRAMES, lower.sprite_frames, StringName("melee_1h/posture/%s/%s/lower_body" % [action, suffix]))
			operator.call("_copy_catalog_animation", CATALOG_FRAMES, upper.sprite_frames, StringName("melee_1h/posture/%s/%s/upper_body" % [action, suffix]))
			assert(lower.sprite_frames.has_animation("melee_1h/posture/%s/%s/lower_body" % [action, suffix]), "missing lower %s %s" % [action, suffix])
			assert(upper.sprite_frames.has_animation("melee_1h/posture/%s/%s/upper_body" % [action, suffix]), "missing upper %s %s" % [action, suffix])
	operator.call("_copy_catalog_animation", CATALOG_FRAMES, lower.sprite_frames, &"melee_1h/posture/draw_weapon_01/e/lower_body")
	assert(lower.sprite_frames.has_animation("melee_1h/posture/draw_weapon_01/e/lower_body"))
	var source := FileAccess.get_file_as_string("res://game/actors/operator/operator.gd")
	assert(not source.contains("AnimationResolver.resolve(\"melee_1h_stance_01\""))
	assert(source.contains("_engagement_tracker.engagement_active"))
	assert(source.contains("_sync_modular_melee_posture"))
	operator.free()
	print("operator_melee_posture_smoke: PASS")
	quit(0)
