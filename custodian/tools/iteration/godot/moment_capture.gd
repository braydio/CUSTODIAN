extends RefCounted
class_name MomentCapture

var viewport: Viewport
var output_dir := ""
var mode := "evidence"
var selected_ticks: Dictionary = {}
var required := true
var records: Array[Dictionary] = []
var failures: Array[String] = []


func configure(target: Viewport, path: String, capture: Dictionary, capture_mode: String) -> bool:
	viewport = target
	output_dir = path.path_join("keyframes")
	mode = capture_mode
	required = bool(capture.get("required_keyframes", true))
	for raw_tick: Variant in capture.get("contact_sheet_ticks", []):
		selected_ticks[int(raw_tick)] = true
	if mode == "none":
		return true
	var error := DirAccess.make_dir_recursive_absolute(output_dir)
	if error != OK:
		failures.append("could not create keyframes directory: %s" % error_string(error))
		return false
	return true


func capture_tick(tick: int) -> bool:
	if mode == "none" or not selected_ticks.has(tick):
		return true
	await RenderingServer.frame_post_draw
	var texture := viewport.get_texture()
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		failures.append("tick %d produced an empty viewport image" % tick)
		return false
	var path := output_dir.path_join("tick_%06d.png" % tick)
	var error := image.save_png(path)
	if error != OK:
		failures.append("tick %d save failed: %s" % [tick, error_string(error)])
		return false
	records.append({
		"tick": tick,
		"path": path,
		"sha256": FileAccess.get_sha256(path),
		"render_frame": Engine.get_frames_drawn(),
	})
	return true
