extends SceneTree

## Production Gate capture with actual pylon collision shapes outlined in cyan.

const SCENE := preload("res://scenes/awakening_first_return.tscn")
const OUTPUT := "res://../reports/awakening_gate_collision"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 960)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene := SCENE.instantiate() as Node2D
	viewport.add_child(scene)
	var production_camera := scene.get_node("World/Camera2D") as Camera2D
	production_camera.enabled = false
	var camera := Camera2D.new()
	camera.enabled = true
	camera.position = Vector2(0, -5060)
	camera.zoom = Vector2(0.72, 0.72)
	viewport.add_child(camera)
	var output := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output)
	await _settle()
	if not _save(viewport, output.path_join("gate_production.png")):
		quit(1)
		return
	var overlay := Node2D.new()
	overlay.z_index = 100
	scene.get_node("World").add_child(overlay)
	var collision := scene.get_node("World/AwakeningZones/Zone07_GateOfDust/Collision")
	for piece_id in ["gate_pylon_west", "gate_pylon_east"]:
		var shape := collision.get_node_or_null(piece_id + "_body") as CollisionShape2D
		if shape == null or not shape.shape is RectangleShape2D:
			push_error("Gate collision shape missing: " + piece_id)
			quit(1)
			return
		var half_size := (shape.shape as RectangleShape2D).size * 0.5
		var outline := Line2D.new()
		outline.width = 4.0
		outline.default_color = Color(0.0, 1.0, 1.0, 1.0)
		outline.points = PackedVector2Array([
			shape.position + Vector2(-half_size.x, -half_size.y),
			shape.position + Vector2(half_size.x, -half_size.y),
			shape.position + Vector2(half_size.x, half_size.y),
			shape.position + Vector2(-half_size.x, half_size.y),
			shape.position + Vector2(-half_size.x, -half_size.y),
		])
		overlay.add_child(outline)
	await _settle()
	if not _save(viewport, output.path_join("gate_collision_overlay.png")):
		quit(1)
		return
	print("Gate QA captures: " + output)
	quit(0)


func _settle() -> void:
	for frame in 5:
		RenderingServer.force_draw(false)
		await process_frame


func _save(viewport: SubViewport, path: String) -> bool:
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(path) != OK:
		push_error("Gate capture failed: " + path)
		return false
	return true
