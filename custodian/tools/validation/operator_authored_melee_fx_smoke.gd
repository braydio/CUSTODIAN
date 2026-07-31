extends SceneTree

const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture := Node2D.new()
	fixture.name = "OperatorAuthoredMeleeFxSmokeRoot"
	root.add_child(fixture)
	current_scene = fixture
	var operator := OPERATOR_SCENE.instantiate()
	fixture.add_child(operator)
	await process_frame

	var melee_fx := operator.get_node("MeleeFxOverlaySprite") as AnimatedSprite2D
	var modular_fx := operator.get_node("ModularUpperFxSprite") as AnimatedSprite2D
	assert(melee_fx != null)
	assert(modular_fx != null)
	melee_fx.visible = false
	modular_fx.visible = false
	assert(
		not bool(operator.call("_active_melee_attack_has_authored_fx")),
		"Hidden authored FX incorrectly suppressed the legacy fallback."
	)

	operator.call("_spawn_melee_impact", Vector2(64.0, 64.0))
	var fallback_count := _count_named(fixture, "MeleeSwing")
	assert(fallback_count == 1, "Attack without authored FX did not spawn the legacy swing fallback.")

	var animations := melee_fx.sprite_frames.get_animation_names()
	assert(not animations.is_empty(), "Melee FX overlay has no authored animations.")
	melee_fx.play(animations[0])
	melee_fx.visible = true
	assert(
		bool(operator.call("_active_melee_attack_has_authored_fx")),
		"Visible authored attack FX were not detected."
	)
	operator.call("_spawn_melee_impact", Vector2(96.0, 64.0))
	assert(
		_count_named(fixture, "MeleeSwing") == fallback_count,
		"Authored attack FX still spawned the legacy gold swing."
	)

	fixture.queue_free()
	await process_frame
	print("[OperatorAuthoredMeleeFxSmoke] PASS")
	quit(0)


func _count_named(node: Node, target_name: String) -> int:
	var count := int(node.name == target_name)
	for child in node.get_children():
		count += _count_named(child, target_name)
	return count
