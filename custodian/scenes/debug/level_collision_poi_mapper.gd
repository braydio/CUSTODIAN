class_name LevelCollisionPoiMapper
extends Node2D

@export_file("*.tscn") var target_scene_path: String
@export_file("*.gd") var target_script_path: String
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
var _draft_points: Array[Vector2] = []
var _draft_markers: Dictionary = {}
var _marker_schema: Array[Dictionary] = []
var _mouse_world := Vector2.ZERO
var _show_existing := true
var _show_draft := true
var _show_help := true
var _marker_mode := false
var _selected_marker_index := 0


func _ready() -> void:
	_camera.make_current()
	_camera.position = initial_camera_position
	_camera.zoom = initial_camera_zoom
	_load_target_level()
	_refresh_marker_schema()
	_update_help()
	_overlay.queue_redraw()


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
				_set_marker_point(_camera.get_global_mouse_position()) if _marker_mode else _add_point(_camera.get_global_mouse_position())
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
	_world.add_child(_target_level)


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
			_apply_draft_markers_to_runtime_marker_map() if _marker_mode else _apply_draft_segments_to_runtime_collision_map()
		KEY_E:
			_show_existing = not _show_existing
		KEY_H:
			_show_help = not _show_help
			_hud.visible = _show_help
		KEY_R:
			_draft_markers.clear() if _marker_mode else _draft_points.clear()
		KEY_M:
			_marker_mode = not _marker_mode
		KEY_V:
			_show_draft = not _show_draft
		KEY_EQUAL, KEY_PLUS:
			_zoom(zoom_step)
		KEY_MINUS:
			_zoom(1.0 / zoom_step)
		_:
			if event.keycode >= KEY_1 and event.keycode <= KEY_9:
				_selected_marker_index = clampi(event.keycode - KEY_1, 0, _marker_schema.size() - 1)
				_marker_mode = true
	_update_help()
	_overlay.queue_redraw()


func _add_point(point: Vector2) -> void:
	_draft_points.append(point)
	if _draft_points.size() >= 2:
		print(_format_segment(_draft_points[-2], _draft_points[-1]))


func _remove_last_point() -> void:
	if not _draft_points.is_empty():
		_draft_points.pop_back()


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
	return _replace_target_script(_format_boundary_segments_const(lines), "")


func _apply_draft_markers_to_runtime_marker_map() -> bool:
	if _draft_markers.is_empty():
		push_warning("[LevelCollisionPoiMapper] No draft markers to apply")
		return false
	return _replace_target_script("", _format_authoring_markers_const())


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
	var index := 1
	while index < _draft_points.size():
		lines.append(_format_segment(_draft_points[index - 1], _draft_points[index]))
		index += 1
	return lines


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
	_hud.text = "\n".join([
		mapper_title,
		"Mode: %s   M: toggle collision/marker   1-9: marker type   Selected: %s" % ["MARKER" if _marker_mode else "COLLISION", _selected_marker_id()],
		"Collision mode: Left click add rail point   Right click undo   C copy rails   Enter/U apply rails",
		"Marker mode: Left click place selected marker   Right click clear selected marker   C copy markers   Enter/U apply markers",
		"WASD/arrows: pan   Wheel/+/-: zoom   E: existing rails   V: draft   R: reset current mode   H: help",
		"Mouse runtime: %s   Source: %s" % [_fmt_vec(_mouse_world), _fmt_vec(_to_source_point(_mouse_world))],
	])


func get_collision_mapper_state() -> Dictionary:
	return {
		"target_level": _target_level,
		"approach": _target_level,
		"draft_points": _draft_points,
		"draft_markers": _draft_markers,
		"marker_schema": _marker_schema,
		"marker_kinds": _marker_schema.map(func(item: Dictionary) -> String: return str(item.get("id", ""))),
		"marker_mode": _marker_mode,
		"selected_marker": _selected_marker_id(),
		"mouse_world": _mouse_world,
		"show_existing": _show_existing,
		"show_draft": _show_draft,
	}
