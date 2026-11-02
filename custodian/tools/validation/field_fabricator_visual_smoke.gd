extends SceneTree

const FABRICATOR := preload("res://game/infrastructure/structures/field_fabricator_mk1.tscn")
const UI_SPY := preload("res://tools/validation/fixtures/fabricator_ui_spy.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_root := Node.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)
	var ui := UI_SPY.new()
	ui.name = "UI"
	game_root.add_child(ui)
	var machine := FABRICATOR.instantiate()
	root.add_child(machine)
	await process_frame
	var body := machine.get_node("Body") as AnimatedSprite2D
	var fx := machine.get_node("FX") as AnimatedSprite2D
	var controller := machine.get_node("VisualController") as FieldFabricatorVisualController
	assert(body != null)
	assert(fx != null)
	assert(controller != null)
	assert(machine.get_node_or_null("Core") == null)
	var expected_fps := {&"idle": 6.0, &"startup": 9.0, &"fabricate": 8.0, &"fabricate_complete": 9.0, &"offline": 6.0}
	for state in expected_fps:
		controller.play_state(state)
		assert(body.animation == state)
		assert(body.sprite_frames.get_frame_count(state) == 8)
		assert(body.sprite_frames.get_frame_texture(state, 0).get_size() == Vector2(156, 156))
		assert(is_equal_approx(body.sprite_frames.get_animation_speed(state), expected_fps[state]))
		assert(body.sprite_frames.get_animation_loop(state) == (state in [&"idle", &"fabricate", &"offline"]))
	for state in [&"idle", &"startup", &"fabricate", &"fabricate_complete"]:
		controller.play_state(state)
		assert(fx.visible)
		assert(fx.animation == state)
		assert(fx.sprite_frames.get_frame_count(state) == 8)
		assert(fx.sprite_frames.get_frame_texture(state, 0).get_size() == Vector2(156, 156))
	controller.play_state(&"fabricate")
	body.frame = 3
	controller.play_state(&"fabricate")
	assert(body.frame == 3, "Re-selecting an active loop must not restart its animation.")
	controller.play_state(&"offline")
	assert(body.animation == &"offline")
	assert(not fx.visible)
	controller.play_state(&"startup")
	assert(not body.sprite_frames.get_animation_loop(&"startup"))
	var interaction := machine.get_node("Interaction") as FieldFabricatorInteraction
	assert(interaction.position == Vector2(0, 48))
	assert(interaction.is_in_group("interactable"))
	assert(interaction.get_interaction_prompt().contains("OFFLINE"))
	interaction.interact(null)
	assert(bool(ui.get("opened")))
	machine.queue_free()
	game_root.queue_free()
	print("field_fabricator_visual_smoke: PASS 5 body, 4 FX, offline, interaction")
	quit(0)
