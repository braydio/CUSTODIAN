extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const SIDEARM_DEFINITION := preload("res://game/actors/operator/sidearm_pistol_definition.tres")


func _init() -> void:
	var scene_root := Node2D.new()
	scene_root.name = "OperatorModularLayersSmokeRoot"
	root.add_child(scene_root)
	current_scene = scene_root
	var game_root := Node.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var world := Node.new()
	world.name = "World"
	game_root.add_child(world)
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	world.add_child(projectiles)

	var operator := OPERATOR_SCENE.instantiate()
	scene_root.add_child(operator)
	await process_frame
	operator.set_process(false)
	operator.set_physics_process(false)
	operator.set_process_input(false)
	operator.set_process_unhandled_input(false)

	operator.set("using_unarmed", true)
	operator.set("combat_loadout_mode", &"melee")
	operator.set("velocity", Vector2.ZERO)
	operator.set("movement_direction", Vector2.DOWN)
	operator.set("aim_direction", Vector2.DOWN)
	operator.set("visual_idle_direction", Vector2.DOWN)
	operator.call("_update_animation")

	var lower := operator.get_node_or_null("ModularLowerBodySprite") as AnimatedSprite2D
	var upper := operator.get_node_or_null("ModularUpperBodySprite") as AnimatedSprite2D
	var body := operator.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var failures: Array[String] = []

	_check_layer(lower, "lower", &"unarmed_idle_down", failures)
	_check_layer(upper, "upper", &"unarmed_idle_down", failures)
	if body == null:
		failures.append("missing legacy body sprite")
	elif body.visible:
		failures.append("legacy body sprite should be hidden while modular unarmed idle is active")

	operator.set("velocity", Vector2.UP * 32.0)
	operator.set("movement_direction", Vector2.UP)
	operator.set("aim_direction", Vector2.DOWN)
	operator.set("visual_idle_direction", Vector2.DOWN)
	operator.call("_update_animation")

	_check_layer(lower, "lower movement", &"unarmed_walk_up", failures)
	_check_layer(upper, "upper locomotion", &"unarmed_walk_up", failures)
	if body != null and body.visible:
		failures.append("legacy body sprite should be hidden while modular unarmed walk/action split is active")

	operator.set("primary_weapon_equipped", true)
	operator.set("sidearm_weapon_definition", SIDEARM_DEFINITION)
	operator.set("sidearm_slot_equipped", true)
	operator.call("_enter_ranged_ready")
	operator.call("_update_animation")
	var sidearm := operator.get_node_or_null("ModularSidearmSprite") as AnimatedSprite2D
	var upper_fx := operator.get_node_or_null("ModularUpperFxSprite") as AnimatedSprite2D
	var primary_weapon := operator.get_node_or_null("PrimaryWeaponSocket/PrimaryWeaponSprite") as AnimatedSprite2D
	var ranged_fx := operator.get_node_or_null("PrimaryWeaponSocket/RangedFxOverlaySprite") as AnimatedSprite2D
	_check_layer(lower, "sidearm draw lower", &"sidearm_draw_lower_down_right", failures)
	_check_layer(upper, "sidearm draw upper", &"sidearm_draw_upper_down_right", failures)
	_check_layer(sidearm, "sidearm draw weapon", &"sidearm_draw_down_right", failures)
	_check_layer(upper_fx, "sidearm draw FX", &"sidearm_draw_fx_down_right", failures)
	_check_sidearm_alignment(operator, [lower, upper, sidearm, upper_fx], failures)
	_check_four_diagonal_sidearm_coverage(lower, upper, sidearm, upper_fx, failures)
	_check_primary_ranged_layers_hidden(primary_weapon, ranged_fx, "sidearm draw", failures)
	lower.stop()
	operator.call("_update_animation")
	if lower.is_playing():
		failures.append("completed sidearm draw layer restarted while other draw layers were still playing")
	operator.set("_ammo_standard_loaded", 12)
	operator.call("_request_ranged_shot")
	if operator.get("_sidearm_action_phase") != &"drawing":
		failures.append("sidearm fire should not skip the drawing phase")

	for sprite in [lower, upper, sidearm, upper_fx]:
		sprite.stop()
	operator.call("_update_animation")
	_check_held_layer(lower, "held draw lower", &"sidearm_draw_lower_down_right", failures)
	_check_held_layer(upper, "held draw upper", &"sidearm_draw_upper_down_right", failures)
	_check_held_layer(sidearm, "held draw weapon", &"sidearm_draw_down_right", failures)
	_check_held_layer(upper_fx, "held draw FX", &"sidearm_draw_fx_down_right", failures)
	_check_primary_ranged_layers_hidden(primary_weapon, ranged_fx, "held sidearm", failures)

	operator.set("aim_direction", Vector2(-1.0, -1.0).normalized())
	operator.set("_ammo_standard_loaded", 12)
	operator.set("fire_cooldown_remaining", 0.0)
	operator.call("_request_ranged_shot")
	if operator.get("_sidearm_action_phase") != &"firing":
		failures.append("sidearm request did not enter firing phase: phase=%s loaded=%s using_sidearm=%s" % [
			String(operator.get("_sidearm_action_phase")),
			str(operator.get("_ammo_standard_loaded")),
			str(operator.call("_is_using_sidearm_ranged")),
		])
	operator.call("_update_animation")
	_check_layer(lower, "sidearm-fire lower", &"sidearm_fire_lower_up_left", failures)
	_check_layer(upper, "sidearm-fire upper", &"sidearm_fire_upper_up_left", failures)
	_check_layer(sidearm, "sidearm-fire weapon", &"sidearm_fire_up_left", failures)
	_check_layer(upper_fx, "sidearm-fire FX", &"sidearm_fire_fx_up_left", failures)
	_check_primary_ranged_layers_hidden(primary_weapon, ranged_fx, "sidearm fire", failures)
	for sprite in [lower, upper, sidearm, upper_fx]:
		sprite.stop()
	operator.call("_update_animation")
	_check_held_layer(lower, "post-fire held lower", &"sidearm_draw_lower_up_left", failures)
	_check_held_layer(upper, "post-fire held upper", &"sidearm_draw_upper_up_left", failures)
	_check_held_layer(sidearm, "post-fire held weapon", &"sidearm_draw_up_left", failures)
	_check_held_layer(upper_fx, "post-fire held FX", &"sidearm_draw_fx_up_left", failures)
	operator.call("_exit_ranged_ready")
	operator.call("_update_animation")
	if sidearm.visible or upper_fx.visible:
		failures.append("releasing sidearm-ready should hide sidearm weapon/FX layers")
	operator.set("using_unarmed", false)
	operator.set("combat_loadout_mode", &"ranged")
	operator.set("aim_direction", Vector2.DOWN)
	operator.set("velocity", Vector2.ZERO)
	operator.set("fire_cooldown_remaining", 0.0)
	operator.set("_pending_ranged_shot", {})
	operator.call("_enter_ranged_ready")
	operator.call("_update_animation")
	_check_layer(lower, "ranged stance lower", &"ranged_2h_stance_modular_right", failures)
	_check_layer(upper, "ranged stance upper", &"ranged_2h_stance_modular_right", failures)
	_check_layer(sidearm, "ranged stance weapon", &"ranged_2h_stance_modular_right", failures)
	_check_partial_ranged_stance_coverage(lower, upper, sidearm, failures)
	if primary_weapon != null and primary_weapon.visible:
		failures.append("legacy primary ranged overlay should hide while modular ranged stance is active")

	scene_root.queue_free()
	game_root.queue_free()

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return

	print("operator_modular_layers_smoke ok: lower=%s upper=%s body_visible=%s" % [
		String(lower.animation),
		String(upper.animation),
		str(body.visible),
	])
	quit()


func _check_layer(sprite: AnimatedSprite2D, label: String, expected_animation: StringName, failures: Array[String]) -> void:
	if sprite == null:
		failures.append("missing %s modular sprite" % label)
		return
	if sprite.sprite_frames == null:
		failures.append("%s modular sprite has no SpriteFrames" % label)
		return
	if not sprite.sprite_frames.has_animation(expected_animation):
		failures.append("%s modular frames missing %s" % [label, String(expected_animation)])
		return
	if sprite.sprite_frames.get_frame_count(expected_animation) <= 0:
		failures.append("%s modular animation %s has zero frames" % [label, String(expected_animation)])
	if not sprite.visible:
		failures.append("%s modular sprite is hidden" % label)
	if sprite.animation != expected_animation:
		failures.append("%s modular sprite animation is %s, expected %s" % [
			label,
			String(sprite.animation),
			String(expected_animation),
		])
	if not sprite.is_playing():
		failures.append("%s modular sprite is not playing" % label)


func _check_held_layer(sprite: AnimatedSprite2D, label: String, expected_animation: StringName, failures: Array[String]) -> void:
	if sprite == null or sprite.sprite_frames == null:
		failures.append("missing %s modular sprite/frames" % label)
		return
	if sprite.animation != expected_animation:
		failures.append("%s animation is %s, expected %s" % [label, String(sprite.animation), String(expected_animation)])
	if sprite.is_playing():
		failures.append("%s should hold instead of playing" % label)
	var expected_frame := sprite.sprite_frames.get_frame_count(expected_animation) - 1
	if sprite.frame != expected_frame:
		failures.append("%s frame is %d, expected held frame %d" % [label, sprite.frame, expected_frame])


func _check_primary_ranged_layers_hidden(primary_weapon: AnimatedSprite2D, ranged_fx: AnimatedSprite2D, phase: String, failures: Array[String]) -> void:
	if primary_weapon != null and primary_weapon.visible:
		failures.append("primary ranged weapon overlay is visible during %s" % phase)
	if ranged_fx != null and ranged_fx.visible:
		failures.append("primary ranged FX overlay is visible during %s" % phase)


func _check_sidearm_alignment(operator: Node, sprites: Array, failures: Array[String]) -> void:
	var expected: Vector2 = operator.get("placeholder_sprite_position")
	for sprite in sprites:
		if sprite != null and not sprite.position.is_equal_approx(expected):
			failures.append("%s is positioned at %s, expected Operator origin layout %s" % [sprite.name, sprite.position, expected])


func _check_four_diagonal_sidearm_coverage(lower: AnimatedSprite2D, upper: AnimatedSprite2D, sidearm: AnimatedSprite2D, fx: AnimatedSprite2D, failures: Array[String]) -> void:
	var suffixes := ["up_right", "up_left", "down_right", "down_left"]
	var specs := [
		[lower, "sidearm_draw_lower", "sidearm_fire_lower"],
		[upper, "sidearm_draw_upper", "sidearm_fire_upper"],
		[sidearm, "sidearm_draw", "sidearm_fire"],
		[fx, "sidearm_draw_fx", "sidearm_fire_fx"],
	]
	for spec in specs:
		var sprite: AnimatedSprite2D = spec[0]
		for suffix in suffixes:
			for base in [spec[1], spec[2]]:
				var animation := StringName("%s_%s" % [base, suffix])
				if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation):
					failures.append("missing four-diagonal sidearm animation %s" % String(animation))


func _check_partial_ranged_stance_coverage(lower: AnimatedSprite2D, upper: AnimatedSprite2D, weapon: AnimatedSprite2D, failures: Array[String]) -> void:
	for sprite in [lower, upper, weapon]:
		if sprite == null or sprite.sprite_frames == null:
			continue
		for suffix in ["", "_right", "_up", "_left"]:
			var animation := StringName("ranged_2h_stance_modular%s" % suffix)
			if not sprite.sprite_frames.has_animation(animation):
				failures.append("missing partial ranged stance animation %s on %s" % [String(animation), sprite.name])
