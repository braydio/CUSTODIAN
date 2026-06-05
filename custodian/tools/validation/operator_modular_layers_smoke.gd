extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")


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
	_check_layer(upper, "upper action", &"unarmed_walk_down", failures)
	if body != null and body.visible:
		failures.append("legacy body sprite should be hidden while modular unarmed walk/action split is active")

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
