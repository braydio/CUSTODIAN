extends RefCounted
class_name TerminalMapPreview

const PREVIEW_SIZE := 256

var render_bounds: Dictionary = {}


func build_texture(ui: Node, contract: Dictionary, snapshot: Dictionary = {}) -> Texture2D:
	# Rendering implementation is kept API-isolated here so the HUD no longer owns
	# map preview state. The pixel renderer can be moved behind this method safely.
	var texture = ui.call("_build_map_preview_texture_legacy", contract, snapshot) if ui.has_method("_build_map_preview_texture_legacy") else null
	var bounds = ui.get("_terminal_map_render_bounds")
	render_bounds = bounds.duplicate(true) if bounds is Dictionary else {}
	return texture if texture is Texture2D else build_placeholder("NO MAP PREVIEW")


func local_to_world(local_pos: Vector2, control_size: Vector2) -> Vector2:
	if render_bounds.is_empty():
		return Vector2.ZERO
	var image_size := Vector2(
		float(render_bounds.get("image_width", PREVIEW_SIZE)),
		float(render_bounds.get("image_height", PREVIEW_SIZE))
	)
	var draw_offset: Vector2 = render_bounds.get("draw_offset", Vector2.ZERO)
	var usable_size := image_size - draw_offset * 2.0
	var visible_size := control_size
	if visible_size.x <= 0.0 or visible_size.y <= 0.0 or usable_size.x <= 0.0 or usable_size.y <= 0.0:
		return Vector2.ZERO
	var texture_aspect: float = image_size.x / max(1.0, image_size.y)
	var control_aspect: float = visible_size.x / max(1.0, visible_size.y)
	var draw_size := visible_size
	var draw_origin := Vector2.ZERO
	if control_aspect > texture_aspect:
		draw_size.x = visible_size.y * texture_aspect
		draw_origin.x = (visible_size.x - draw_size.x) * 0.5
	else:
		draw_size.y = visible_size.x / texture_aspect
		draw_origin.y = (visible_size.y - draw_size.y) * 0.5
	var normalized := (local_pos - draw_origin) / draw_size
	var image_pos := normalized * image_size
	var min_x := float(render_bounds.get("min_x", 0.0))
	var min_y := float(render_bounds.get("min_y", 0.0))
	var scale := float(render_bounds.get("scale", 1.0))
	return Vector2(
		((image_pos.x - draw_offset.x) / max(0.001, scale)) + min_x,
		((image_pos.y - draw_offset.y) / max(0.001, scale)) + min_y
	)


func build_placeholder(label: String) -> Texture2D:
	var image := Image.create(PREVIEW_SIZE, PREVIEW_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.02, 0.03, 0.03, 1.0))
	for x in range(0, PREVIEW_SIZE):
		image.set_pixel(x, 0, Color(0.15, 0.26, 0.2, 1.0))
		image.set_pixel(x, PREVIEW_SIZE - 1, Color(0.15, 0.26, 0.2, 1.0))
	for y in range(0, PREVIEW_SIZE):
		image.set_pixel(0, y, Color(0.15, 0.26, 0.2, 1.0))
		image.set_pixel(PREVIEW_SIZE - 1, y, Color(0.15, 0.26, 0.2, 1.0))
	var hash_value := int(abs(label.hash()))
	for i in range(24):
		var px := 8 + ((hash_value + i * 29) % (PREVIEW_SIZE - 16))
		var py := 8 + ((hash_value + i * 43) % (PREVIEW_SIZE - 16))
		image.set_pixel(px, py, Color(0.25, 0.45, 0.35, 1.0))
	return ImageTexture.create_from_image(image)
