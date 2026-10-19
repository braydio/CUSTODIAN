extends SceneTree

const PREVIEW := preload("res://scenes/debug/carrow_perimeter_wall_art_preview.tscn")
const OVERVIEW_OUTPUT := "user://carrow_perimeter_source_assembly_overview.png"
const SEAM_SHEET_OUTPUT := "user://carrow_perimeter_native_scale_seams.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := PREVIEW.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var operator := scene.get_node_or_null("World/Operator") as CharacterBody2D
	var camera := scene.get_node_or_null("World/Camera2D") as Camera2D
	var world := scene.get_node_or_null("World") as Node2D
	var sources := scene.get_node_or_null("World/PreviewArt") as Node2D
	var errors: Array[String] = []
	if operator == null:
		errors.append("actual Operator scene did not instantiate")
	if camera == null or not is_equal_approx(camera.zoom.x, 0.84) or camera.zoom.x != camera.zoom.y:
		errors.append("preview is not using the current Camera2D gameplay zoom")
	if sources == null or sources.get_child_count() != 8:
		errors.append("expected four source sprites and four identifying labels")
	if operator != null and operator.global_position != Vector2(1200, 650):
		errors.append("Operator ground position changed from the preview contract")
	if sources != null:
		for child in sources.get_children():
			if child is Sprite2D:
				var sprite := child as Sprite2D
				if sprite.texture == null or sprite.scale != Vector2.ONE:
					errors.append("source sprite missing or resized: %s" % sprite.name)
				elif sprite.texture.get_width() < 500:
					errors.append("unexpected source dimension: %s" % sprite.name)
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return
	# Strip unrelated autoload-owned world props (for example the debug vault
	# chest) so the review scene contains only the Operator, camera and sources.
	if world != null:
		for child in world.get_children():
			if child != operator and child != camera and child != sources:
				child.queue_free()
	camera.set_process(false)
	# Full assembly is an overview only. Native-scale acceptance evidence below is
	# a compact contact sheet of authored ROIs at the production Camera2D zoom.
	camera.zoom = Vector2(0.30, 0.30)
	camera.position = Vector2(800, -350)
	var overview := await _capture_viewport()
	if overview == null:
		quit(1)
		return
	var error_code := overview.save_png(OVERVIEW_OUTPUT)
	if error_code != OK:
		push_error("failed to save assembly overview: %s" % error_string(error_code))
		quit(1)
		return

	camera.zoom = Vector2(0.84, 0.84)
	var centers := [Vector2(250, 34), Vector2(2510, -300), Vector2(1200, 650)]
	var contact := Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	contact.fill(Color("22262a"))
	var placements := [Vector2i(0, 0), Vector2i(960, 0), Vector2i(0, 540)]
	for index in range(centers.size()):
		camera.position = centers[index]
		var full_capture := await _capture_viewport()
		if full_capture == null:
			quit(1)
			return
		var crop := full_capture.get_region(Rect2i(480, 270, 960, 540))
		contact.blit_rect(crop, Rect2i(0, 0, 960, 540), placements[index])
	error_code = contact.save_png(SEAM_SHEET_OUTPUT)
	if error_code != OK:
		push_error("failed to save native-scale seam sheet: %s" % error_string(error_code))
		quit(1)
		return
	print("CARROW_PERIMETER_PREVIEW_PASS")
	print("viewport=1920x1080 gameplay_camera_zoom=0.84 grid=32 operator=%s source_sprites=4" % operator.global_position)
	print("assembly_overview=%s" % ProjectSettings.globalize_path(OVERVIEW_OUTPUT))
	print("native_scale_roi_sheet=%s" % ProjectSettings.globalize_path(SEAM_SHEET_OUTPUT))
	quit()


func _capture_viewport() -> Image:
	await process_frame
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		push_error("this renderer does not provide a captureable root viewport texture")
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		push_error("review viewport capture returned an empty image")
		return null
	return image
