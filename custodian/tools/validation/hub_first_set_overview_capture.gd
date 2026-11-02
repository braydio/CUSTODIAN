extends SceneTree

const MAP_SCENE := preload("res://game/world/hub/first_set/hub_first_set_map.tscn")
const LAYOUT := preload("res://game/world/hub/first_set/hub_first_set_layout.gd")
const CAPTURE_SIZE := Vector2i(2048, 2048)
const OUTPUT_PATH := "res://../reports/hub_first_set_blockout/overview.png"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var viewport := SubViewport.new()
	viewport.name = "HubOverviewViewport"
	viewport.size = CAPTURE_SIZE
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var map := MAP_SCENE.instantiate() as HubFirstSetMap
	viewport.add_child(map)
	var camera := Camera2D.new()
	camera.name = "OverviewCamera"
	camera.zoom = Vector2(0.30, 0.30)
	camera.position = LAYOUT.WORLD_BOUNDS.get_center()
	viewport.add_child(camera)
	camera.make_current()
	await process_frame
	await process_frame
	print("Hub overview camera framed; reading viewport")
	var image := viewport.get_texture().get_image()
	if image.get_size() != CAPTURE_SIZE:
		push_error("Hub overview viewport size %s != %s" % [image.get_size(), CAPTURE_SIZE])
		quit(1)
		return
	var absolute_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if directory_error != OK:
		push_error("Could not create Hub overview directory: %s" % error_string(directory_error))
		quit(1)
		return
	var save_error := image.save_png(absolute_path)
	if save_error != OK:
		push_error("Could not save Hub overview: %s" % error_string(save_error))
		quit(1)
		return
	print("HUB_FIRST_SET_OVERVIEW:%s %s" % [absolute_path, image.get_size()])
	quit(0)
