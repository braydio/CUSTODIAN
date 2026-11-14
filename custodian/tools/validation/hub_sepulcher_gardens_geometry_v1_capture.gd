extends SceneTree

const PLAYTEST_SCENE := preload("res://scenes/hub_first_set_blockout_playtest.tscn")
const PREVIEW_SCRIPT := preload("res://game/world/levels/authored/dev/sepulcher_material_operator_v2/operator_2_5d_preview_presentation.gd")
const CANONICAL_IDLE := preload("res://game/world/levels/authored/dev/sepulcher_material_operator_v2/preview/operator_2_5d_idle_relaxed_8dir_15f_128.png")
const CAPTURES := [
	{"name": "01_overall_gardens", "title": "OVERALL GARDENS · WALKABLE MASK + BLOCKED TERRAIN", "player": Vector2(-1984, -3200), "camera": Vector2(-2592, -3136), "zoom": 0.24},
	{"name": "02_north_forum_entrance", "title": "NORTH FORUM ENTRANCE · 128PX OPERATOR CLEARANCE", "player": Vector2(-1376, -3296), "camera": Vector2(-1472, -3200), "zoom": 0.64},
	{"name": "03_south_forum_entrance", "title": "SOUTH FORUM ENTRANCE · 128PX OPERATOR CLEARANCE", "player": Vector2(-1376, -2752), "camera": Vector2(-1472, -2656), "zoom": 0.64},
	{"name": "04_grave_event_clearance", "title": "GRAVE APPROACH · THREE READINGS + TWO CHOICES RETAINED", "player": Vector2(-1984, -3200), "camera": Vector2(-1900, -3050), "zoom": 0.64},
	{"name": "05_west_water_terraces", "title": "WEST WATER TERRACES · WALKABLE RIMS / BLOCKED POOLS", "player": Vector2(-3424, -3104), "camera": Vector2(-3150, -3190), "zoom": 0.58},
	{"name": "06_southern_orchard_secret_paths", "title": "SOUTHERN ORCHARD + PROPOSED SECRET PATHS · NO REWARDS", "player": Vector2(-3392, -2176), "camera": Vector2(-2660, -2220), "zoom": 0.50},
]


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := (args[0] if not args.is_empty() else "user://sepulcher_gardens_geometry_v1").simplify_path()
	var absolute_output_dir := ProjectSettings.globalize_path(output_dir)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(absolute_output_dir)
	if mkdir_error != OK:
		push_error("Could not create capture directory: %s" % error_string(mkdir_error))
		quit(1)
		return
	var playtest := PLAYTEST_SCENE.instantiate() as Node2D
	if playtest == null:
		push_error("Could not load the real Hub first-set playtest")
		quit(1)
		return
	var game_root := SubViewport.new()
	game_root.name = "GameRoot"
	game_root.size = Vector2i(1280, 720)
	game_root.transparent_bg = false
	game_root.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(game_root)
	for child in playtest.get_children():
		playtest.remove_child(child)
		child.owner = null
		game_root.add_child(child)
	playtest.free()
	for _frame in 8:
		await process_frame
	var operator := game_root.get_node("World/Operator") as CharacterBody2D
	var camera := game_root.get_node("World/Camera2D") as Camera2D
	var map := game_root.get_node("World/Level")
	if operator == null or camera == null or map == null:
		push_error("Hub playtest is missing Operator, gameplay camera, or HubFirstSetMap")
		quit(1)
		return
	var preview := Node2D.new()
	preview.name = "CanonicalOperatorPresentation"
	preview.set_script(PREVIEW_SCRIPT)
	preview.set("canonical_idle_sheet", CANONICAL_IDLE)
	operator.add_child(preview)
	for _frame in 4:
		await process_frame
	preview.set_process(false)
	preview.call("set_preview_frame", 0)
	var geometry_overlay := map.get_node_or_null("SepulcherGardensGeometryDebug") as CanvasItem
	if geometry_overlay == null:
		push_error("Expanded Gardens geometry overlay missing")
		quit(1)
		return
	geometry_overlay.visible = true
	map.get_node("Markers").visible = false
	for child in map.get_children():
		if child is Label and str(child.name).begins_with("Label_"):
			(child as Label).visible = false
	operator.z_index = 14
	operator.set_physics_process(false)
	var controller := game_root.get_node("World/PlayerController")
	controller.set_process(false)
	controller.set_physics_process(false)
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.position_smoothing_enabled = false
	var title_layer := CanvasLayer.new()
	title_layer.name = "CaptureTitle"
	game_root.add_child(title_layer)
	var title := Label.new()
	title.position = Vector2(18, 16)
	title.size = Vector2(1220, 56)
	title.add_theme_color_override("font_color", Color("fff2d7"))
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.05, 0.98))
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_font_size_override("font_size", 19)
	title_layer.add_child(title)
	var capture_paths: Array[String] = []
	for item in CAPTURES:
		operator.global_position = item["player"]
		operator.velocity = Vector2.ZERO
		camera.global_position = item["camera"]
		camera.zoom = Vector2.ONE * float(item["zoom"])
		title.text = str(item["title"]) + "   ·   CANONICAL 128 IDLE ONLY · LIVE GAMEPLAY OPERATOR"
		for _frame in 3:
			await process_frame
		var image := game_root.get_texture().get_image()
		if image.is_empty() or image.get_size() != Vector2i(1280, 720):
			push_error("Capture viewport is %s; expected 1280x720" % image.get_size())
			quit(1)
			return
		var output_path := absolute_output_dir.path_join("%s.png" % item["name"])
		var save_error := image.save_png(output_path)
		if save_error != OK:
			push_error("Could not save %s: %s" % [output_path, error_string(save_error)])
			quit(1)
			return
		capture_paths.append(output_path)
	print("SEPULCHER_GARDENS_GEOMETRY_CAPTURE_OUTPUTS:%s" % JSON.stringify(capture_paths))
	quit(0)
