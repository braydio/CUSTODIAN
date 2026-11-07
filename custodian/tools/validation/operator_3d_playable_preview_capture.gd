extends SceneTree

## Windowed capture for review of the dev-only playable 3D Operator preview.
## Drives real movement input (east, south, south-east) and saves one screenshot per heading.
## Output: res://.ai/operator_3d_animation_preview/captures/
## Run (needs a display): godot --path custodian --script res://tools/validation/operator_3d_playable_preview_capture.gd

const SCENE := "res://scenes/debug/operator_3d_playable_preview_awakening.tscn"
const OUT := "res://.ai/operator_3d_animation_preview/captures"
const SHOTS := [["east", ["move_right"]], ["south", ["move_down"]], ["south_east", ["move_right", "move_down"]]]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var root := (load(SCENE) as PackedScene).instantiate()
	get_root().add_child(root)
	for _i in 10:
		await process_frame
	for shot in SHOTS:
		var name: String = shot[0]
		var actions: Array = shot[1]
		for a in actions:
			Input.action_press(a)
		for _i in 60:
			await physics_frame
			await process_frame
		var image := get_root().get_texture().get_image()
		var path := "%s/%s.png" % [ProjectSettings.globalize_path(OUT), name]
		image.save_png(path)
		print("CAPTURE ", path, " direction=", root.get("current_direction"), " action=", root.get("current_action"))
		for a in actions:
			Input.action_release(a)
		for _i in 20:
			await process_frame
	root.queue_free()
	quit(0)
