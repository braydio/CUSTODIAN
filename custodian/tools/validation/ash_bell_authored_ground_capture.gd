extends SceneTree

const CAPTURES := [
	{
		"name": "lower_quarter",
		"scene": preload("res://game/world/levels/authored/ash_bell/lower_quarter/lower_quarter.tscn"),
		"cell": Vector2i(64, 78),
	},
	{
		"name": "west_gate_works",
		"scene": preload("res://game/world/levels/authored/ash_bell/west_gate_works/west_gate_works.tscn"),
		"cell": Vector2i(32, 24),
	},
	{
		"name": "station_ix",
		"scene": preload("res://game/world/levels/authored/ash_bell/station_ix/station_ix.tscn"),
		"cell": Vector2i(32, 32),
	},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output := _argument_value("--output=")
	if output.is_empty():
		output = "reports/ash_bell_authored_ground"
	var absolute_output := output if output.is_absolute_path() else ProjectSettings.globalize_path("res://../" + output)
	DirAccess.make_dir_recursive_absolute(absolute_output)
	for contract: Dictionary in CAPTURES:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1280, 720)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.transparent_bg = false
		root.add_child(viewport)
		var level := (contract.scene as PackedScene).instantiate() as Node2D
		viewport.add_child(level)
		var camera := Camera2D.new()
		camera.enabled = true
		camera.position = level.call("cell_center", contract.cell as Vector2i) as Vector2
		viewport.add_child(camera)
		await process_frame
		await process_frame
		await process_frame
		var image := viewport.get_texture().get_image()
		var path := absolute_output.path_join("%s.png" % contract.name)
		if image == null or image.is_empty() or image.save_png(path) != OK:
			push_error("Ash-Bell ground capture failed: %s" % path)
			quit(1)
			return
		print("Ash-Bell ground capture: %s" % path)
		viewport.free()
	quit(0)


func _argument_value(prefix: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return ""
