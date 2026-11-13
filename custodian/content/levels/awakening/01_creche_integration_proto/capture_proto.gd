extends SceneTree

# Load the Creche integration prototype, render two frames, and save a screenshot.
# Run with a display: CRECHE_SHOT=/abs/path.png godot --path custodian -s res://content/levels/awakening/01_creche_integration_proto/capture_proto.gd

const SCENE := "res://content/levels/awakening/01_creche_integration_proto/creche_integration_proto.tscn"


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(960, 704))
	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("CRECHE_PROTO_LOAD_FAILED %s" % SCENE)
		quit(1)
		return
	root.add_child(packed.instantiate())
	await process_frame
	await process_frame
	var shot_path := OS.get_environment("CRECHE_SHOT")
	var image := root.get_texture().get_image()
	var err := image.save_png(shot_path)
	print("CRECHE_PROTO_LOADED sprites=%d screenshot_err=%d path=%s" % [root.get_child(root.get_child_count() - 1).get_child_count(), err, shot_path])
	quit(0 if err == OK else 1)
