class_name LevelCollisionPoiMapper
extends Node2D

@export_file("*.tscn") var target_scene_path: String
@export_file("*.gd") var target_script_path: String
@export_file("*.json") var target_preview_config_path: String
@export var target_instance_name := "LevelUnderReview"
@export var mapper_title := "Level Collision / POI Mapper"
@export var initial_camera_position := Vector2.ZERO
@export var initial_camera_zoom := Vector2(0.5, 0.5)
@export var zoom_step := 1.15
@export var pan_step := 96.0

@onready var _world: Node2D = $World
@onready var _camera: Camera2D = $World/Camera2D
@onready var _overlay: Node2D = $World/CollisionOverlay
@onready var _hud: Label = $CanvasLayer/Help

var _target_level: Node2D
var _draft_polylines: Array = []
var _active_polyline: Array[Vector2] = []
# Compatibility alias for the older approach mapper subclass. New collision
# authoring uses `_active_polyline` and `_draft_polylines` exclusively.
var _draft_points: Array[Vector2] = []
var _draft_markers: Dictionary = {}
var _marker_schema: Array[Dictionary] = []
var _mouse_world := Vector2.ZERO
var _show_existing := true
var _show_draft := true
var _show_help := true
var _marker_mode := false
var _selected_marker_index := 0
var _semantic_groups := {
	"boundary": true,
	"encounter": true,
	"hazard": true,
	"interaction": true,
	"camera": true,
	"transition": true,
	"art": true,
	"traversal": true,
}
var _show_semantic_labels := true
var _show_grid := true


func _ready() -> void:
	_draft_points = _active_polyline
	_camera.make_current()
	_camera.position = initial_camera_position
	_camera.zoom = initial_camera_zoom
	_load_target_level()
	_refresh_marker_schema()
	_update_help()
	_overlay.queue_redraw()
	if OS.get_cmdline_user_args().has("--mapper-snapshot"):
		_capture_mapper_snapshot_and_quit.call_deferred()


func _process(_delta: float) -> void:
	_handle_keyboard_pan()
	var current_mouse := _camera.get_global_mouse_position()
	if not current_mouse.is_equal_approx(_mouse_world):
		_mouse_world = current_mouse
		_update_help()
		_overlay.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var mouse := event as InputEventMouseButton
		match mouse.button_index:
			MOUSE_BUTTON_LEFT:
				_set_marker_point(_camera.get_global_mouse_position()) if _marker_mode else _add_point(_camera.get_global_mouse_position(), mouse.double_click)
			MOUSE_BUTTON_RIGHT:
				_remove_selected_marker_point() if _marker_mode else _remove_last_point()
			MOUSE_BUTTON_WHEEL_UP:
				_zoom(zoom_step)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(1.0 / zoom_step)
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		_handle_key(event as InputEventKey)


func _load_target_level() -> void:
	if target_scene_path.is_empty():
		push_error("[LevelCollisionPoiMapper] target_scene_path is required")
		return
	var packed := load(target_scene_path) as PackedScene
	if packed == null:
		push_error("[LevelCollisionPoiMapper] Could not load %s" % target_scene_path)
		return
	_target_level = packed.instantiate() as Node2D
	if _target_level == null:
		push_error("[LevelCollisionPoiMapper] Target root must be Node2D")
		return
	_target_level.name = target_instance_name
	if not target_preview_config_path.is_empty():
		var config_file := FileAccess.open(
			target_preview_config_path,
			FileAccess.READ
		)
		if config_file != null:
			var parsed: Variant = JSON.parse_string(config_file.get_as_text())
			if parsed is Dictionary:
				_target_level.set_meta("mapper_preview_config", parsed)
	_world.add_child(_target_level)
	_hide_target_canvas_layers(_target_level)
	_load_existing_collision_polylines()


func _hide_target_canvas_layers(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
		_hide_target_canvas_layers(child)


func _refresh_marker_schema() -> void:
	_marker_schema.clear()
	if _target_level != null and _target_level.has_method("get_authoring_marker_schema"):
		var schema: Variant = _target_level.call("get_authoring_marker_schema")
		if schema is Array:
			for raw: Variant in schema:
				if raw is Dictionary and not str((raw as Dictionary).get("id", "")).is_empty():
					_marker_schema.append((raw as Dictionary).duplicate(true))
	if _marker_schema.is_empty() and _target_level != null and _target_level.has_method("get_authoring_marker_state"):
		var state := _target_level.call("get_authoring_marker_state") as Dictionary
		var ids := state.keys()
		ids.sort()
		for marker_id: Variant in ids:
			var data := state[marker_id] as Dictionary
			_marker_schema.append({
				"id": str(marker_id),
				"kind": str(data.get("kind", marker_id)),
				"label": str(data.get("label", marker_id)),
				"node_name": str(data.get("node_name", str(marker_id).to_pascal_case())),
			})
	if _marker_schema.is_empty():
		_marker_schema.append({"id": "spawn", "kind": "spawn", "label": "MAIN ENTRY", "node_name": "Spawn_Main"})
	_selected_marker_index = clampi(_selected_marker_index, 0, _marker_schema.size() - 1)


func _handle_keyboard_pan() -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
	if direction != Vector2.ZERO:
		_camera.position += direction.normalized() * pan_step / maxf(0.05, _camera.zoom.x) * get_process_delta_time() * 6.0


func _handle_key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_C:
			_copy_markers_to_clipboard() if _marker_mode else _copy_segments_to_clipboard()
		KEY_ENTER, KEY_KP_ENTER, KEY_U:
			if _marker_mode:
				_apply_draft_markers_to_runtime_marker_map()
			else:
				_finish_active_polyline()
				_apply_draft_segments_to_runtime_collision_map()
		KEY_SPACE:
			if not _marker_mode:
				_finish_active_polyline()
		KEY_N:
			if not _marker_mode:
				_finish_active_polyline()
		KEY_ESCAPE:
			if not _marker_mode:
				_active_polyline.clear()
		KEY_E:
			_show_existing = not _show_existing
		KEY_H:
			_show_help = not _show_help
			_hud.visible = _show_help
		KEY_R:
			_draft_markers.clear() if _marker_mode else _active_polyline.clear()
		KEY_M:
			_marker_mode = not _marker_mode
		KEY_PAGEUP:
			_cycle_selected_marker(-1)
		KEY_PAGEDOWN:
			_cycle_selected_marker(1)
		KEY_V:
			_show_draft = not _show_draft
		KEY_L:
			_show_semantic_labels = not _show_semantic_labels
		KEY_G:
			_show_grid = not _show_grid
		KEY_0:
			_toggle_all_semantic_groups()
		KEY_P:
			_save_mapper_snapshot()
		KEY_F1:
			_apply_semantic_preset(["boundary", "encounter", "hazard", "interaction"])
		KEY_F2:
			_apply_semantic_preset(["boundary", "art", "traversal"])
		KEY_F3:
			_apply_semantic_preset(["camera", "transition", "art"])
		KEY_F4:
			_apply_semantic_preset([])
		KEY_EQUAL, KEY_PLUS:
			_zoom(zoom_step)
		KEY_MINUS:
			_zoom(1.0 / zoom_step)
		_:
			if not _marker_mode and event.keycode >= KEY_1 and event.keycode <= KEY_8:
				_toggle_semantic_group(event.keycode - KEY_1)
			elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
				_selected_marker_index = clampi(event.keycode - KEY_1, 0, _marker_schema.size() - 1)
				_marker_mode = true
	_update_help()
	_overlay.queue_redraw()


func _cycle_selected_marker(direction: int) -> void:
	if _marker_schema.is_empty():
		return
	_selected_marker_index = posmod(
		_selected_marker_index + direction,
		_marker_schema.size()
	)
	_marker_mode = true


func _add_point(point: Vector2, finish_on_double_click := false) -> void:
	_active_polyline.append(point)
	if _active_polyline.size() >= 2:
		print(_format_segment(_active_polyline[-2], _active_polyline[-1]))
	if finish_on_double_click:
		_finish_active_polyline()


func _finish_active_polyline() -> void:
	var cleaned: Array[Vector2] = []
	for point in _active_polyline:
		if cleaned.is_empty() or not point.is_equal_approx(cleaned[-1]):
			cleaned.append(point)
	if cleaned.size() >= 2:
		_draft_polylines.append(cleaned)
	_active_polyline.clear()


func _remove_last_point() -> void:
	if not _active_polyline.is_empty():
		_active_polyline.pop_back()


func _set_marker_point(point: Vector2) -> void:
	_draft_markers[_selected_marker_id()] = point


func _remove_selected_marker_point() -> void:
	_draft_markers.erase(_selected_marker_id())


func _zoom(factor: float) -> void:
	var before := _camera.get_global_mouse_position()
	_camera.zoom = (_camera.zoom * factor).clamp(Vector2(0.12, 0.12), Vector2(2.5, 2.5))
	_camera.position += before - _camera.get_global_mouse_position()


func _copy_segments_to_clipboard() -> void:
	DisplayServer.clipboard_set("\n".join(_format_draft_segment_lines()))


func _copy_markers_to_clipboard() -> void:
	DisplayServer.clipboard_set(_format_authoring_markers_const())


func _apply_draft_segments_to_runtime_collision_map() -> bool:
	var lines := _format_draft_segment_lines()
	if lines.is_empty():
		push_warning("[LevelCollisionPoiMapper] No complete draft segments to apply")
		return false
	var applied := _replace_target_script(_format_boundary_segments_const(lines), "")
	if applied:
		_apply_draft_segments_to_preview()
	return applied


func _apply_draft_markers_to_runtime_marker_map() -> bool:
	if _draft_markers.is_empty():
		push_warning("[LevelCollisionPoiMapper] No draft markers to apply")
		return false
	var applied := _replace_target_script("", _format_authoring_markers_const())
	if applied:
		_apply_draft_markers_to_preview()
		_write_marker_positions_to_target_scene()
	return applied


func _apply_draft_segments_to_preview() -> void:
	if _target_level == null:
		return
	var boundary := _target_level.get_node_or_null("Collision/PathBoundaryCollision") as StaticBody2D
	if boundary == null:
		boundary = _target_level.find_child("PathBoundaryCollision", true, false) as StaticBody2D
	if boundary == null:
		return
	for child in boundary.get_children():
		child.queue_free()
	var index := 1
	for segment: Array in _compiled_draft_segments(true):
		_add_preview_boundary_segment(boundary, "BoundarySegment_%03d" % index, segment[0], segment[1])
		index += 1


func _add_preview_boundary_segment(parent: StaticBody2D, node_name: String, a: Vector2, b: Vector2) -> void:
	var direction := b - a
	var shape := CapsuleShape2D.new()
	shape.radius = 10.0
	shape.height = maxf(direction.length() + 20.0, 20.0)
	var collision := CollisionShape2D.new()
	collision.name = node_name
	collision.shape = shape
	collision.position = (a + b) * 0.5
	if direction.length_squared() > 0.001:
		collision.rotation = direction.angle() - PI * 0.5
	collision.set_meta("boundary_a", a)
	collision.set_meta("boundary_b", b)
	parent.add_child(collision)


func _apply_draft_markers_to_preview() -> void:
	if _target_level == null:
		return
	for schema: Dictionary in _marker_schema:
		var marker_id := str(schema.get("id", ""))
		if not _draft_markers.has(marker_id):
			continue
		var node := _target_level.find_child(str(schema.get("node_name", "")), true, false) as Node2D
		if node != null:
			node.global_position = _draft_markers[marker_id] as Vector2


func _write_marker_positions_to_target_scene() -> bool:
	var absolute := ProjectSettings.globalize_path(target_scene_path)
	if target_scene_path.is_empty() or not FileAccess.file_exists(absolute):
		return false
	var file := FileAccess.open(absolute, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var replaced := text
	for schema: Dictionary in _marker_schema:
		var marker_id := str(schema.get("id", ""))
		if not _draft_markers.has(marker_id):
			continue
		replaced = _replace_scene_node_position(
			replaced,
			str(schema.get("node_name", "")),
			_to_source_point(_draft_markers[marker_id] as Vector2)
		)
	if replaced == text:
		return true
	return _atomic_write_scene_verified(absolute, replaced)


func _replace_scene_node_position(text: String, node_name: String, point: Vector2) -> String:
	var header_token := "[node name=\"%s\"" % node_name
	var header_start := text.find(header_token)
	if header_start < 0:
		push_warning("[LevelCollisionPoiMapper] Scene node not found: %s" % node_name)
		return text
	var block_end := text.find("\n[node ", header_start + 1)
	if block_end < 0:
		block_end = text.length()
	var block := text.substr(header_start, block_end - header_start)
	var position_line := "position = %s" % _fmt_vec(point)
	var position_start := block.find("\nposition = ")
	if position_start >= 0:
		var line_end := block.find("\n", position_start + 1)
		if line_end < 0:
			line_end = block.length()
		block = block.substr(0, position_start + 1) + position_line + block.substr(line_end)
	else:
		var header_end := block.find("\n")
		block = block.substr(0, header_end + 1) + position_line + "\n" + block.substr(header_end + 1)
	return text.substr(0, header_start) + block + text.substr(block_end)


func _atomic_write_scene_verified(path: String, text: String) -> bool:
	if not text.begins_with("[gd_scene"):
		return false
	var temp_path := "%s.mapper-tmp.tscn" % path.trim_suffix(".tscn")
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	var load_path := ProjectSettings.localize_path(temp_path)
	var packed := ResourceLoader.load(load_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		DirAccess.remove_absolute(temp_path)
		push_warning("[LevelCollisionPoiMapper] Refusing invalid scene write")
		return false
	var backup_path := "%s.mapper-backup" % path
	DirAccess.remove_absolute(backup_path)
	if DirAccess.rename_absolute(path, backup_path) != OK:
		DirAccess.remove_absolute(temp_path)
		return false
	if DirAccess.rename_absolute(temp_path, path) != OK:
		DirAccess.rename_absolute(backup_path, path)
		return false
	DirAccess.remove_absolute(backup_path)
	print("[LevelCollisionPoiMapper] Updated scene markers in %s" % target_scene_path)
	return true


func _replace_target_script(boundary_replacement: String, marker_replacement: String) -> bool:
	var absolute := ProjectSettings.globalize_path(target_script_path)
	if target_script_path.is_empty() or not FileAccess.file_exists(absolute):
		push_warning("[LevelCollisionPoiMapper] Missing target script: %s" % target_script_path)
		return false
	var file := FileAccess.open(absolute, FileAccess.READ)
	if file == null:
		return false
	var original := file.get_as_text()
	file.close()
	var replaced := original
	if not boundary_replacement.is_empty():
		replaced = _replace_boundary_segments_block(replaced, boundary_replacement)
	if not marker_replacement.is_empty():
		replaced = _replace_authoring_markers_block(replaced, marker_replacement)
	if replaced == original:
		push_warning("[LevelCollisionPoiMapper] Target constants were not replaced")
		return false
	if not _atomic_write_verified(absolute, replaced):
		return false
	print("[LevelCollisionPoiMapper] Updated %s" % target_script_path)
	print("Review with: git diff -- %s" % target_script_path)
	return true


func _atomic_write_verified(path: String, text: String) -> bool:
	if not text.contains("const BOUNDARY_SEGMENTS := [") or not text.contains("const AUTHORING_MARKERS := {"):
		push_warning("[LevelCollisionPoiMapper] Refusing write without both authoring constants")
		return false
	var temp_path := "%s.tmp" % path
	var backup_path := "%s.mapper-backup" % path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	file = FileAccess.open(temp_path, FileAccess.READ)
	if file == null or file.get_as_text() != text:
		DirAccess.remove_absolute(temp_path)
		return false
	file.close()
	DirAccess.remove_absolute(backup_path)
	if DirAccess.rename_absolute(path, backup_path) != OK:
		DirAccess.remove_absolute(temp_path)
		return false
	if DirAccess.rename_absolute(temp_path, path) != OK:
		DirAccess.rename_absolute(backup_path, path)
		return false
	DirAccess.remove_absolute(backup_path)
	return true


func _format_draft_segment_lines() -> Array[String]:
	var lines: Array[String] = []
	for segment: Array in _compiled_draft_segments(false):
		lines.append(_format_segment(segment[0], segment[1]))
	return lines


func _compiled_draft_segments(include_active: bool) -> Array:
	var polylines := _draft_polylines.duplicate(true)
	if include_active and _active_polyline.size() >= 2:
		polylines.append(_active_polyline.duplicate())
	return compile_polylines(polylines)


static func compile_polylines(polylines: Array) -> Array:
	var result: Array = []
	for polyline_variant: Variant in polylines:
		if not polyline_variant is Array:
			continue
		var polyline := polyline_variant as Array
		for index in range(polyline.size() - 1):
			var a := polyline[index] as Vector2
			var b := polyline[index + 1] as Vector2
			if a == null or b == null or a.is_equal_approx(b):
				continue
			result.append([a, b])
	return result


static func reconstruct_polylines(segments: Array) -> Array:
	var unused: Array = []
	for segment_variant: Variant in segments:
		if not segment_variant is Array or (segment_variant as Array).size() < 2:
			continue
		var segment := segment_variant as Array
		var a := segment[0] as Vector2
		var b := segment[1] as Vector2
		if a == null or b == null or a.is_equal_approx(b):
			continue
		unused.append([a, b])
	var result: Array = []
	while not unused.is_empty():
		var seed: Array = unused.pop_front()
		var chain: Array = [seed[0], seed[1]]
		var extended := true
		while extended:
			extended = false
			for index in range(unused.size()):
				var candidate := unused[index] as Array
				if (candidate[0] as Vector2).is_equal_approx(chain[-1] as Vector2):
					chain.append(candidate[1])
					unused.remove_at(index)
					extended = true
					break
				if (candidate[1] as Vector2).is_equal_approx(chain[-1] as Vector2):
					chain.append(candidate[0])
					unused.remove_at(index)
					extended = true
					break
			for index in range(unused.size()):
				var candidate := unused[index] as Array
				if (candidate[1] as Vector2).is_equal_approx(chain[0] as Vector2):
					chain.push_front(candidate[0])
					unused.remove_at(index)
					extended = true
					break
				if (candidate[0] as Vector2).is_equal_approx(chain[0] as Vector2):
					chain.push_front(candidate[1])
					unused.remove_at(index)
					extended = true
					break
		result.append(chain)
	return result


func _load_existing_collision_polylines() -> void:
	var segments: Array = []
	if _target_level != null and _target_level.has_method("get_boundary_segments"):
		var raw: Variant = _target_level.call("get_boundary_segments")
		if raw is Array:
			segments = raw
	if segments.is_empty() and _target_level != null:
		var boundary := _target_level.find_child("PathBoundaryCollision", true, false) as StaticBody2D
		if boundary != null:
			for child in boundary.get_children():
				if child.has_meta("boundary_a") and child.has_meta("boundary_b"):
					segments.append([child.get_meta("boundary_a"), child.get_meta("boundary_b")])
	_draft_polylines = reconstruct_polylines(segments)


func _format_boundary_segments_const(lines: Array[String]) -> String:
	return "const BOUNDARY_SEGMENTS := [\n\t%s\n]" % "\n\t".join(lines)


func _replace_boundary_segments_block(text: String, replacement: String) -> String:
	return _replace_balanced_block(text, "const BOUNDARY_SEGMENTS := [", "[", "]", replacement)


func _replace_authoring_markers_block(text: String, replacement: String) -> String:
	return _replace_balanced_block(text, "const AUTHORING_MARKERS := {", "{", "}", replacement)


func _replace_balanced_block(text: String, marker: String, open: String, close: String, replacement: String) -> String:
	var marker_start := text.find(marker)
	if marker_start < 0:
		return text
	var block_start := text.find(open, marker_start)
	var depth := 0
	for index in range(block_start, text.length()):
		var character := text[index]
		if character == open: depth += 1
		elif character == close:
			depth -= 1
			if depth == 0:
				return text.substr(0, marker_start) + replacement + text.substr(index + 1)
	return text


func _format_authoring_markers_const() -> String:
	var lines: Array[String] = ["const AUTHORING_MARKERS := {"]
	for schema in _marker_schema:
		var marker_id := str(schema.get("id", ""))
		var runtime_point := _marker_runtime_point(marker_id)
		lines.append("\t\"%s\": {" % marker_id)
		lines.append("\t\t\"node_name\": \"%s\"," % str(schema.get("node_name", marker_id.to_pascal_case())))
		lines.append("\t\t\"label\": \"%s\"," % str(schema.get("label", marker_id.to_upper())))
		lines.append("\t\t\"kind\": \"%s\"," % str(schema.get("kind", marker_id)))
		lines.append("\t\t\"position\": %s," % _fmt_vec(_to_source_point(runtime_point)))
		lines.append("\t},")
	lines.append("}")
	return "\n".join(lines)


func _format_segment(a: Vector2, b: Vector2) -> String:
	return "[%s, %s]," % [_fmt_vec(_to_source_point(a)), _fmt_vec(_to_source_point(b))]


func _fmt_vec(point: Vector2) -> String:
	return "Vector2(%.1f, %.1f)" % [point.x, point.y]


func _to_source_point(runtime_point: Vector2) -> Vector2:
	if _target_level != null and _target_level.has_method("runtime_to_authoring_point"):
		return _target_level.call("runtime_to_authoring_point", runtime_point) as Vector2
	return runtime_point


func _selected_marker_id() -> String:
	return str(_marker_schema[clampi(_selected_marker_index, 0, _marker_schema.size() - 1)].get("id", "spawn"))


func _marker_runtime_point(marker_id: String) -> Vector2:
	if _draft_markers.has(marker_id):
		return _draft_markers[marker_id] as Vector2
	if _target_level != null and _target_level.has_method("get_authoring_marker_state"):
		var state := _target_level.call("get_authoring_marker_state") as Dictionary
		if state.get(marker_id) is Dictionary:
			return (state[marker_id] as Dictionary).get("runtime_position", Vector2.ZERO) as Vector2
	return Vector2.ZERO


func _update_help() -> void:
	if _hud == null:
		return
	var lines := PackedStringArray([
		mapper_title,
		"Mode: %s   M: collision/marker   Marker mode 1-9: type   PgUp/PgDn: cycle   Selected: %s" % ["MARKER" if _marker_mode else "COLLISION", _selected_marker_id()],
		"Marker keys: %s" % _marker_shortcuts_text(),
		"Collision: Left click add   double-click/Space finish   N new chain   Right click undo   Enter/U save",
		"Collision: R cancel active   C copy rails   E existing   V draft",
		"Marker mode: Left click place selected marker   Right click clear selected marker   C copy markers   Enter/U apply markers",
		"Semantic: 1 boundary  2 encounter  3 hazards  4 interactions  5 cameras  6 transitions  7 art  8 traversal  0 all",
		"Presets: F1 gameplay   F2 art alignment   F3 presentation   F4 clean",
		"L: labels   G: 32px grid   P: snapshot+JSON   WASD/arrows: pan   Wheel/+/-: zoom   E: rails   V: draft   H: help",
		"Mouse runtime: %s   Source: %s" % [_fmt_vec(_mouse_world), _fmt_vec(_to_source_point(_mouse_world))],
	])
	var under_cursor := get_debug_geometry_under_point(_mouse_world)
	if not under_cursor.is_empty():
		lines.append("UNDER CURSOR")
		for record: Dictionary in under_cursor:
			lines.append("  %s — %s" % [str(record.get("label", record.get("id", ""))), str(record.get("details", ""))])
	_hud.text = "\n".join(lines)


func _marker_shortcuts_text() -> String:
	var shortcuts: Array[String] = []
	for index in range(mini(_marker_schema.size(), 9)):
		shortcuts.append(
			"%d=%s"
			% [
				index + 1,
				str(_marker_schema[index].get("id", "")),
			]
		)
	return "  ".join(shortcuts)


func get_collision_mapper_state() -> Dictionary:
	return {
		"target_level": _target_level,
		"approach": _target_level,
		"draft_points": _active_polyline,
		"draft_polylines": _draft_polylines,
		"active_polyline": _active_polyline,
		"draft_markers": _draft_markers,
		"marker_schema": _marker_schema,
		"marker_kinds": _marker_schema.map(func(item: Dictionary) -> String: return str(item.get("id", ""))),
		"marker_mode": _marker_mode,
		"selected_marker": _selected_marker_id(),
		"mouse_world": _mouse_world,
		"show_existing": _show_existing,
		"show_draft": _show_draft,
		"semantic_geometry": _get_semantic_geometry(),
		"semantic_groups": _semantic_groups,
		"show_semantic_labels": _show_semantic_labels,
		"show_grid": _show_grid,
	}


func _get_semantic_geometry() -> Array[Dictionary]:
	if _target_level == null or not _target_level.has_method("get_authoring_debug_geometry"):
		return []
	var raw: Variant = _target_level.call("get_authoring_debug_geometry")
	var records: Array[Dictionary] = []
	if raw is Array:
		for value: Variant in raw:
			if value is Dictionary and not (value as Dictionary).is_empty():
				records.append(value as Dictionary)
	return records


func get_debug_geometry_under_point(point: Vector2) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for record: Dictionary in _get_semantic_geometry():
		if not bool(_semantic_groups.get(str(record.get("group", "")), true)):
			continue
		if _debug_record_contains_point(record, point):
			matches.append(record)
	return matches


func _debug_record_contains_point(record: Dictionary, point: Vector2) -> bool:
	match str(record.get("shape", "")):
		"rect", "sprite_rect", "band":
			return (record.get("rect", Rect2()) as Rect2).has_point(point)
		"circle":
			return point.distance_to(record.get("center", Vector2.ZERO) as Vector2) <= float(record.get("radius", 0.0))
		"point":
			return point.distance_to(record.get("point", Vector2.ZERO) as Vector2) <= 18.0 / maxf(_camera.zoom.x, 0.05)
		"polygon":
			return Geometry2D.is_point_in_polygon(point, record.get("polygon", PackedVector2Array()) as PackedVector2Array)
	return false


func _toggle_semantic_group(index: int) -> void:
	var groups := ["boundary", "encounter", "hazard", "interaction", "camera", "transition", "art", "traversal"]
	if index < 0 or index >= groups.size():
		return
	var group: String = groups[index]
	_semantic_groups[group] = not bool(_semantic_groups[group])


func _toggle_all_semantic_groups() -> void:
	var enable := false
	for group: String in _semantic_groups:
		if not bool(_semantic_groups[group]):
			enable = true
			break
	for group: String in _semantic_groups:
		_semantic_groups[group] = enable


func _apply_semantic_preset(enabled_groups: Array) -> void:
	for group: String in _semantic_groups:
		_semantic_groups[group] = enabled_groups.has(group)


func _save_mapper_snapshot() -> void:
	var level_id := target_scene_path.get_file().get_basename()
	var relative_dir := "reports/level_maps/%s" % level_id
	var absolute_dir := ProjectSettings.globalize_path("res://../%s" % relative_dir)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	var png_path := "%s/full_map.png" % absolute_dir
	var json_path := "%s/full_map.json" % absolute_dir
	var export := {
		"level": level_id,
		"gameplay_bounds": _records_for_groups(["boundary", "encounter"]),
		"camera_zones": _records_for_groups(["camera"]),
		"hazards": _records_for_groups(["hazard"]),
		"interactions": _records_for_groups(["interaction"]),
		"art_bounds": _records_for_groups(["art"]),
		"transitions": _records_for_groups(["transition", "traversal"]),
	}
	var file := FileAccess.open(json_path, FileAccess.WRITE)
	if file == null:
		push_error("[LevelCollisionPoiMapper] Could not save mapper JSON snapshot")
		return
	file.store_string(JSON.stringify(_json_safe(export), "  "))
	file.close()
	if DisplayServer.get_name() == "headless":
		push_warning(
			"[LevelCollisionPoiMapper] Saved full_map.json; the dummy headless renderer "
			+ "cannot capture full_map.png. Use P from the rendered mapper."
		)
		return
	var viewport_texture := get_viewport().get_texture()
	if viewport_texture == null:
		push_warning(
			"[LevelCollisionPoiMapper] Saved full_map.json; the dummy headless renderer "
			+ "cannot capture full_map.png. Use P from the rendered mapper."
		)
		return
	var image := viewport_texture.get_image()
	if image == null or image.is_empty() or image.save_png(png_path) != OK:
		push_error("[LevelCollisionPoiMapper] Saved full_map.json but could not save full_map.png")
		return
	print("[LevelCollisionPoiMapper] Saved %s/full_map.png and full_map.json" % relative_dir)


func _capture_mapper_snapshot_and_quit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_save_mapper_snapshot()
	get_tree().quit()


func _records_for_groups(groups: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record: Dictionary in _get_semantic_geometry():
		if groups.has(str(record.get("group", ""))):
			result.append(record)
	return result


func _json_safe(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key: Variant in (value as Dictionary).keys():
			result[str(key)] = _json_safe((value as Dictionary)[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value:
			result.append(_json_safe(item))
		return result
	if value is Vector2:
		return [value.x, value.y]
	if value is Rect2:
		return [value.position.x, value.position.y, value.size.x, value.size.y]
	if value is PackedVector2Array:
		var result: Array = []
		for point: Vector2 in value:
			result.append([point.x, point.y])
		return result
	if value is StringName or value is NodePath:
		return str(value)
	return value
