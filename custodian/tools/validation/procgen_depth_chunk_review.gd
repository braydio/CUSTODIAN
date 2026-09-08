extends SceneTree

const VIEWPORT_SIZE := Vector2i(1600, 900)
const GROUPS := {
	"universal_seed": [
		["civic foundation breach", preload("res://content/backgrounds/procgen/depth_chunks/universal/procgen_depth_universal_civic_foundation_breach_v1_896x576.png")],
		["fractured ravine", preload("res://content/backgrounds/procgen/depth_chunks/universal/procgen_depth_universal_fractured_ravine_v1_896x576.png")],
		["service infrastructure", preload("res://content/backgrounds/procgen/depth_chunks/universal/procgen_depth_universal_service_infrastructure_field_v1_640x448.png")],
		["talus + rubble shelf", preload("res://content/backgrounds/procgen/depth_chunks/universal/procgen_depth_universal_talus_and_rubble_shelf_v1_640x448.png")],
	],
	"scrubland_seed": [
		["dry basin", preload("res://content/backgrounds/procgen/depth_chunks/scrubland/procgen_depth_scrubland_dry_basin_v1_896x576.png")],
		["wash channel", preload("res://content/backgrounds/procgen/depth_chunks/scrubland/procgen_depth_scrubland_wash_channel_v1_640x448.png")],
		["service scar", preload("res://content/backgrounds/procgen/depth_chunks/scrubland/procgen_depth_scrubland_service_scar_v1_640x448.png")],
	],
	"woodland_seed": [
		["canopy basin", preload("res://content/backgrounds/procgen/depth_chunks/woodland/procgen_depth_woodland_canopy_basin_v1_896x576.png")],
		["ravine", preload("res://content/backgrounds/procgen/depth_chunks/woodland/procgen_depth_woodland_ravine_v1_896x576.png")],
	],
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output := "res://../reports/procgen_depth_chunks_v1"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	if DisplayServer.get_name() == "headless":
		_capture_cpu(output)
		quit(0)
		return
	for group_name: String in GROUPS:
		var viewport := SubViewport.new()
		viewport.size = VIEWPORT_SIZE
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.transparent_bg = false
		root.add_child(viewport)
		viewport.add_child(_build_sheet(group_name, GROUPS[group_name]))
		for _frame: int in range(4):
			RenderingServer.force_draw(false)
			await process_frame
		var path := output.path_join("%s.png" % group_name)
		var error := viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
		if error != OK:
			push_error("procgen depth review capture failed: %s" % path)
			quit(1)
			return
		print("procgen depth review: %s" % path)
		viewport.free()
	quit(0)


func _capture_cpu(output: String) -> void:
	for group_name: String in GROUPS:
		var entries: Array = GROUPS[group_name]
		var canvas := Image.create_empty(1600, 900, false, Image.FORMAT_RGBA8)
		canvas.fill(Color("11151b"))
		for index: int in entries.size():
			var panel_origin := Vector2i(32 + (index % 2) * 776, 32 + (index / 2) * 420)
			canvas.fill_rect(Rect2i(panel_origin, Vector2i(744, 388)), Color("171d24"))
			var source := (entries[index][1] as Texture2D).get_image()
			var copy := source.duplicate()
			copy.resize(int(copy.get_width() * 0.72), int(copy.get_height() * 0.72), Image.INTERPOLATE_NEAREST)
			var art_position := panel_origin + Vector2i((744 - copy.get_width()) / 2, 36)
			canvas.blend_rect(copy, Rect2i(Vector2i.ZERO, copy.get_size()), art_position)
			var edge_y := panel_origin.y + 92
			canvas.fill_rect(Rect2i(panel_origin.x, edge_y, 744, 64), Color("343a37"))
			for x: int in range(panel_origin.x, panel_origin.x + 745, 32):
				canvas.fill_rect(Rect2i(x, edge_y, 1, 64), Color(0.6, 0.65, 0.62, 0.3))
			canvas.fill_rect(Rect2i(panel_origin.x + 694, edge_y, 24, 64), Color("d5c47a"))
		var path := output.path_join("%s.png" % group_name)
		var error := canvas.save_png(ProjectSettings.globalize_path(path))
		if error != OK:
			push_error("procgen depth CPU review capture failed: %s" % path)
			return
		print("procgen depth review: %s" % path)


func _build_sheet(group_name: String, entries: Array) -> Control:
	var root_control := Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("11151b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(background)
	var title := Label.new()
	title.text = "PROCGEN DEPTH CHUNK V1 — %s" % group_name.to_upper().replace("_", " ")
	title.position = Vector2(32, 20)
	title.add_theme_font_size_override("font_size", 24)
	root_control.add_child(title)
	for index: int in entries.size():
		var columns := 2
		var panel_position := Vector2(32 + (index % columns) * 776, 70 + (index / columns) * 398)
		root_control.add_child(_build_panel(entries[index], panel_position))
	return root_control


func _build_panel(entry: Array, panel_position: Vector2) -> Control:
	var panel := Control.new()
	panel.position = panel_position
	panel.size = Vector2(744, 366)
	var void_rect := ColorRect.new()
	void_rect.color = Color("171d24")
	void_rect.size = panel.size
	panel.add_child(void_rect)
	var texture := entry[1] as Texture2D
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.position = Vector2(4, 34)
	image.size = Vector2(736, 328)
	panel.add_child(image)
	var terrain := ColorRect.new()
	terrain.color = Color("343a37")
	terrain.position = Vector2(0, 78)
	terrain.size = Vector2(744, 64)
	terrain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(terrain)
	for x: int in range(0, 745, 32):
		var line := ColorRect.new()
		line.color = Color(0.6, 0.65, 0.62, 0.16)
		line.position = Vector2(x, 78)
		line.size = Vector2(1, 64)
		panel.add_child(line)
	var label := Label.new()
	label.text = "%s   |   32 px cells   |   %dx%d source" % [entry[0], texture.get_width(), texture.get_height()]
	label.position = Vector2(10, 5)
	panel.add_child(label)
	var operator_marker := ColorRect.new()
	operator_marker.color = Color("d5c47a")
	operator_marker.position = Vector2(690, 78)
	operator_marker.size = Vector2(24, 64)
	panel.add_child(operator_marker)
	return panel
