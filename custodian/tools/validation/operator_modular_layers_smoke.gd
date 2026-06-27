extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")


func _init() -> void:
	var scene_root := Node2D.new()
	scene_root.name = "OperatorModularLayersSmokeRoot"
	root.add_child(scene_root)
	current_scene = scene_root

	var operator := OPERATOR_SCENE.instantiate()
	scene_root.add_child.call_deferred(operator)
	await process_frame
	await process_frame

	operator.set_process(false)
	operator.set_physics_process(false)
	operator.set_process_input(false)
	operator.set_process_unhandled_input(false)

	var lower := operator.get_node_or_null("ModularLowerBodySprite") as AnimatedSprite2D
	var upper := operator.get_node_or_null("ModularUpperBodySprite") as AnimatedSprite2D
	var weapon := operator.get_node_or_null("ModularSidearmSprite") as AnimatedSprite2D
	var body := operator.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var primary_weapon := operator.get_node_or_null("PrimaryWeaponSocket/PrimaryWeaponSprite") as AnimatedSprite2D
	var ranged_fx := operator.get_node_or_null("PrimaryWeaponSocket/RangedFxOverlaySprite") as AnimatedSprite2D
	var failures: Array[String] = []

	operator.set("using_unarmed", true)
	operator.set("combat_loadout_mode", &"melee")
	operator.set("velocity", Vector2.ZERO)
	operator.set("movement_direction", Vector2.DOWN)
	operator.set("aim_direction", Vector2.DOWN)
	operator.set("visual_idle_direction", Vector2.DOWN)
	operator.call("_update_animation")

	_check_layer(lower, "unarmed idle lower", &"unarmed_idle_down", failures)
	_check_layer(upper, "unarmed idle upper", &"unarmed_idle_down", failures)
	_check_hidden(body, "legacy body should be hidden during modular unarmed idle", failures)

	operator.set("velocity", Vector2.RIGHT * 32.0)
	operator.set("is_sprinting", false)
	operator.set("movement_direction", Vector2.RIGHT)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.call("_update_animation")

	_check_layer(lower, "unarmed move lower", &"unarmed_walk_right", failures)
	_check_layer(upper, "unarmed move upper", &"unarmed_walk_right", failures)
	_check_hidden(body, "legacy body should be hidden during modular unarmed locomotion", failures)

	operator.call("_exit_ranged_ready")
	operator.set("using_unarmed", false)
	operator.set("combat_loadout_mode", &"ranged")
	operator.set("primary_weapon_equipped", true)
	operator.set("equipped_primary_weapon_id", "carbine_rifle")
	operator.set("sidearm_slot_equipped", false)
	operator.set("velocity", Vector2.ZERO)
	operator.set("movement_direction", Vector2.DOWN)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.set("visual_idle_direction", Vector2.DOWN)
	operator.set("fire_cooldown_remaining", 0.0)
	operator.set("_pending_ranged_shot", {})
	operator.call("_enter_ranged_ready")
	operator.call("_update_animation")

	_check_layer(lower, "ranged-ready idle lower", &"unarmed_idle_right", failures)
	_check_layer(upper, "ranged-ready idle upper", &"ranged_2h_stance_modular_right", failures)
	_check_layer(weapon, "ranged-ready idle weapon", &"ranged_2h_stance_modular_right", failures)
	_check_hidden(body, "legacy body should be hidden during modular ranged-ready idle", failures)
	_check_hidden(primary_weapon, "legacy primary weapon should hide during modular ranged-ready idle", failures)
	_check_hidden(ranged_fx, "legacy ranged fx should hide during modular ranged-ready idle", failures)

	operator.set("velocity", Vector2.UP * 32.0)
	operator.set("is_sprinting", true)
	operator.set("movement_direction", Vector2.UP)
	operator.set("aim_direction", Vector2.RIGHT)
	operator.call("_update_animation")

	_check_layer(lower, "ranged-ready move lower", &"unarmed_run_up", failures)
	_check_layer(upper, "ranged-ready move upper", &"ranged_2h_stance_modular_right", failures)
	_check_layer(weapon, "ranged-ready move weapon", &"ranged_2h_stance_modular_right", failures)
	_check_hidden(body, "legacy body should stay hidden during modular ranged-ready movement", failures)
	if body != null and body.sprite_frames != null and body.sprite_frames.has_animation(&"ranged_run_east"):
		failures.append("ranged-ready modular movement should not require baked ranged_run_east")

	var upper_frames := upper.sprite_frames
	upper.sprite_frames = SpriteFrames.new()
	operator.call("_update_animation")

	if lower != null and lower.visible:
		failures.append("modular lower body should hide when modular ranged upper stack is unavailable")
	if body != null and not body.visible:
		failures.append("legacy body should become visible when modular ranged composition falls back")

	upper.sprite_frames = upper_frames
	scene_root.queue_free()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("operator_modular_layers_smoke ok")
	quit()


func _check_layer(sprite: AnimatedSprite2D, label: String, expected_animation: StringName, failures: Array[String]) -> void:
	if sprite == null:
		failures.append("missing %s sprite" % label)
		return
	if sprite.sprite_frames == null:
		failures.append("%s has no SpriteFrames" % label)
		return
	if not sprite.sprite_frames.has_animation(expected_animation):
		failures.append("%s missing animation %s" % [label, String(expected_animation)])
		return
	if not sprite.visible:
		failures.append("%s sprite is hidden" % label)
	if sprite.animation != expected_animation:
		failures.append("%s animation is %s, expected %s" % [label, String(sprite.animation), String(expected_animation)])
	if not sprite.is_playing():
		failures.append("%s sprite is not playing" % label)


func _check_hidden(sprite: AnimatedSprite2D, message: String, failures: Array[String]) -> void:
	if sprite != null and sprite.visible:
		failures.append(message)
