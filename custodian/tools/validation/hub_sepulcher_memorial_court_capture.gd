extends SceneTree

const HUB_HOST_SCENE := preload("res://scenes/hub_runtime_host.tscn")
const OPERATOR_SCENE := preload("res://game/actors/operator/operator.tscn")
const CAMERA_SCRIPT := preload("res://game/world/camera.gd")
const CAPTURE_SHOTS := [
	{"name": "court_approach_east", "camera": Vector2(-1860.0, -3200.0), "operator": Vector2(-1664.0, -3200.0), "zoom": 0.72, "court": true, "title": "EAST APPROACH · OPERATOR + MEMORIAL COURT"},
	{"name": "court_before", "camera": Vector2(-1910.0, -3200.0), "operator": Vector2(-1664.0, -3200.0), "zoom": 0.72, "court": false, "title": "BEFORE · MATCHED CAMERA / WORLD POSITION"},
	{"name": "court_after", "camera": Vector2(-1910.0, -3200.0), "operator": Vector2(-1664.0, -3200.0), "zoom": 0.72, "court": true, "title": "AFTER · MATCHED CAMERA / WORLD POSITION"},
	{"name": "court_full_contact", "camera": Vector2(-1910.0, -3200.0), "operator": Vector2(-1664.0, -3200.0), "zoom": 0.72, "court": true, "title": "FULL COURT · SLAB / INDEX RING / WALL CONTACT"},
	{"name": "court_interaction_clearance", "camera": Vector2(-1920.0, -2950.0), "operator": Vector2(-1664.0, -3200.0), "zoom": 0.64, "court": true, "title": "GRAVE INTERACTION POINTS · 3 READINGS / 2 RESOLUTIONS"},
]


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := (args[0] if not args.is_empty() else "/tmp/sepulcher_memorial_court_capture").simplify_path()
	var absolute_output_dir := ProjectSettings.globalize_path(output_dir) if output_dir.begins_with("user://") else output_dir
	var mkdir_error := DirAccess.make_dir_recursive_absolute(absolute_output_dir)
	if mkdir_error != OK:
		push_error("Could not create capture directory %s: %s" % [absolute_output_dir, error_string(mkdir_error)])
		quit(1)
		return
	var host := HUB_HOST_SCENE.instantiate() as Node2D
	if host == null:
		push_error("Could not instantiate production Hub runtime host")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.name = "GameRoot"
	viewport.size = Vector2i(1280, 720)
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for child in host.get_children():
		host.remove_child(child)
		child.owner = null
		viewport.add_child(child)
	host.free()
	for _frame in 8:
		await process_frame
	var world := viewport.get_node_or_null("World") as Node2D
	var map := viewport.get_node_or_null("World/Level") as HubFirstSetMap
	if world == null or map == null:
		push_error("Production Hub host lacks World or production map")
		quit(1)
		return
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.set_script(CAMERA_SCRIPT)
	camera.set("base_zoom", Vector2(0.55, 0.55))
	camera.enabled = true
	world.add_child(camera)
	var operator := OPERATOR_SCENE.instantiate() as CharacterBody2D
	operator.name = "Operator"
	world.add_child(operator)
	if not map.enter_from_main_at_spawn(operator, &"Spawn_SouthReach"):
		push_error("Production Operator could not enter the Hub")
		quit(1)
		return
	await process_frame
	var presentation := map.get_node_or_null("SepulcherMemorialCourtPresentation") as CanvasItem
	if presentation == null:
		push_error("Production Memorial Court presentation helper is missing")
		quit(1)
		return
	map.get_node("Markers").visible = false
	for child in map.get_children():
		if child is Label and str(child.name).begins_with("Label_"):
			(child as Label).visible = false
	operator.set_physics_process(false)
	operator.velocity = Vector2.ZERO
	var controller := viewport.get_node_or_null("World/PlayerController")
	if controller != null:
		controller.set_process(false)
		controller.set_physics_process(false)
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.position_smoothing_enabled = false
	var title_layer := CanvasLayer.new()
	title_layer.name = "CaptureTitle"
	viewport.add_child(title_layer)
	var title := Label.new()
	title.position = Vector2(18.0, 16.0)
	title.size = Vector2(1244.0, 48.0)
	title.add_theme_color_override("font_color", Color("fff2d7"))
	title.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.04, 0.98))
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_font_size_override("font_size", 18)
	title_layer.add_child(title)
	var paths: Array[String] = []
	for item: Dictionary in CAPTURE_SHOTS:
		operator.global_position = item["operator"]
		camera.global_position = item["camera"]
		camera.zoom = Vector2.ONE * float(item["zoom"])
		presentation.visible = bool(item["court"])
		title.text = String(item["title"]) + "   ·   PRODUCTION HUB · 32PX GRID"
		for _frame in 3:
			await process_frame
		var image := viewport.get_texture().get_image()
		if image.is_empty() or image.get_size() != Vector2i(1280, 720):
			push_error("Unexpected capture viewport size: %s" % image.get_size())
			quit(1)
			return
		var output_path := absolute_output_dir.path_join(String(item["name"]) + ".png")
		var save_error := image.save_png(output_path)
		if save_error != OK:
			push_error("Could not save %s: %s" % [output_path, error_string(save_error)])
			quit(1)
			return
		paths.append(output_path)
	print("SEPULCHER_MEMORIAL_COURT_CAPTURE_OUTPUTS:%s" % JSON.stringify(paths))
	quit(0)
