extends SceneTree

const FABRICATOR := preload("res://game/infrastructure/structures/field_fabricator_mk1.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
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
	assert(body.sprite_frames != null)
	assert(body.sprite_frames.get_frame_count(&"idle") == 8)
	assert(body.sprite_frames.get_frame_texture(&"idle", 0).get_size() == Vector2(96, 96))
	controller.play_fabricate()
	assert(body.animation == &"fabricate")
	assert(fx.visible)
	assert(fx.sprite_frames != null)
	assert(fx.sprite_frames.get_frame_count(&"fabricate") == 8)
	assert(fx.sprite_frames.get_frame_texture(&"fabricate", 0).get_size() == Vector2(96, 96))
	controller.play_state(&"offline")
	assert(body.animation == &"idle")
	machine.queue_free()
	print("field_fabricator_visual_smoke: PASS partial states idle/fabricate, deterministic fallback")
	quit(0)
