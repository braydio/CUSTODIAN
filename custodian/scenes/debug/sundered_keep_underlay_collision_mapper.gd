extends Node2D

const UNDERLAY_DEBUG_SCENE := preload("res://scenes/debug/sundered_keep_production_underlay_debug.tscn")
const UNDERLAY_DEBUG_SCRIPT_PATH := "res://scenes/debug/sundered_keep_production_underlay_debug.gd"
const MAP_SIZE := Vector2(3584.0, 2560.0)
const MARKER_KINDS := [
	"spawn",
	"return_causeway",
	"gatehouse_key",
	"main_gate",
	"level_exit",
	"enemy_spawn_west",
	"enemy_spawn_gate",
]
const MARKER_KIND_LABELS := {
	"spawn": "SPAWN",
	"return_causeway": "RETURN CAUSEWAY",
	"gatehouse_key": "GATEHOUSE KEY",
	"main_gate": "RAISING GATE",
	"level_exit": "LEVEL EXIT",
	"enemy_spawn_west": "ENEMY SPAWN W",
	"enemy_spawn_gate": "ENEMY SPAWN GATE",
}
const MARKER_KIND_TYPES := {
	"spawn": "spawn",
	"return_causeway": "return_causeway",
	"gatehouse_key": "key",
	"main_gate": "gate",
	"level_exit": "level_exit",
	"enemy_spawn_west": "enemy_spawn",
	"enemy_spawn_gate": "enemy_spawn",
}

@export var zoom_step := 1.15
@export var pan_step := 96.0

@onready var _world: Node2D = $World
@onready var _camera: Camera2D = $World/Camera2D
@onready var _overlay: Node2D = $World/CollisionOverlay
@onready var _hud: Label = $CanvasLayer/Help

var _underlay_scene: Node2D = null
var _draft_points: Array[Vector2] = []
var _mouse_world := Vector2.ZERO
var _show_existing := true
var _show_draft := true
var _show_help := true
var _marker_mode := false
var _selected_marker_index := 0
var _draft_markers: Dictionary = {}


func _ready() -> void:
	_camera.make_current()
	_camera.position = Vector2(MAP_SIZE.x * 0.5, MAP_SIZE.y * 0.72)
	_camera.zoom = Vector2(0.32, 0.32)
	_load_underlay_debug_scene()
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
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed:
			if mouse.button_index == MOUSE_BUTTON_LEFT:
				if _marker_mode:
					_set_marker_point(_camera.get_global_mouse_position())
				else:
					_add_point(_camera.get_global_mouse_position())
			elif mouse.button_index == MOUSE_BUTTON_RIGHT:
				if _marker_mode:
					_remove_selected_marker_point()
				else:
					_remove_last_point()
			elif mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom(zoom_step)
			elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(1.0 / zoom_step)
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		_handle_key(event as InputEventKey)


func _load_underlay_debug_scene() -> void:
	_underlay_scene = UNDERLAY_DEBUG_SCENE.instantiate() as Node2D
	if _underlay_scene == null:
		push_error("[SunderedKeepUnderlayCollisionMapper] Could not instantiate underlay debug scene")
		return
	_underlay_scene.name = "SunderedKeepUnderlayReview"
	_world.add_child(_underlay_scene)


func _handle_keyboard_pan() -> void:
	var delta := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		delta.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		delta.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		delta.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		delta.y += 1.0
	if delta == Vector2.ZERO:
		return
	_camera.position += delta.normalized() * pan_step / maxf(0.05, _camera.zoom.x) * get_process_delta_time() * 6.0


func _handle_key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_C:
			if _marker_mode:
				_copy_markers_to_clipboard()
			else:
				_copy_segments_to_clipboard()
		KEY_ENTER, KEY_KP_ENTER, KEY_U:
			if _marker_mode:
				_apply_draft_markers_to_underlay_marker_map()
			else:
				_apply_draft_segments_to_underlay_collision_map()
		KEY_E:
			_show_existing = not _show_existing
			_overlay.queue_redraw()
		KEY_F:
			_focus_full_underlay()
		KEY_H:
			_show_help = not _show_help
			_hud.visible = _show_help
		KEY_R:
			if _marker_mode:
				_draft_markers.clear()
			else:
				_draft_points.clear()
			_overlay.queue_redraw()
			_update_help()
		KEY_M:
			_marker_mode = not _marker_mode
			_overlay.queue_redraw()
			_update_help()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7:
			_selected_marker_index = clampi(event.keycode - KEY_1, 0, MARKER_KINDS.size() - 1)
			_marker_mode = true
			_overlay.queue_redraw()
			_update_help()
		KEY_S:
			_focus_spawn_causeway()
		KEY_V:
			_show_draft = not _show_draft
			_overlay.queue_redraw()
		KEY_EQUAL, KEY_PLUS:
			_zoom(zoom_step)
		KEY_MINUS:
			_zoom(1.0 / zoom_step)


func _add_point(point: Vector2) -> void:
	_draft_points.append(point)
	_print_point(point)
	if _draft_points.size() >= 2:
		var a := _draft_points[_draft_points.size() - 2]
		var b := _draft_points[_draft_points.size() - 1]
		print(_format_segment(a, b))
	_overlay.queue_redraw()
	_update_help()


func _remove_last_point() -> void:
	if _draft_points.is_empty():
		return
	_draft_points.pop_back()
	_overlay.queue_redraw()
	_update_help()


func _set_marker_point(point: Vector2) -> void:
	var marker_id := _selected_marker_id()
	_draft_markers[marker_id] = point
	print("[SunderedKeepUnderlayCollisionMapper] marker %s world=%s tile=%s" % [marker_id, _fmt_vec(point), _world_to_tile(point)])
	_overlay.queue_redraw()
	_update_help()


func _remove_selected_marker_point() -> void:
	var marker_id := _selected_marker_id()
	if not _draft_markers.has(marker_id):
		return
	_draft_markers.erase(marker_id)
	_overlay.queue_redraw()
	_update_help()


func _zoom(factor: float) -> void:
	var before := _camera.get_global_mouse_position()
	_camera.zoom = (_camera.zoom * factor).clamp(Vector2(0.10, 0.10), Vector2(2.5, 2.5))
	var after := _camera.get_global_mouse_position()
	_camera.position += before - after
	_update_help()
	_overlay.queue_redraw()


func _focus_full_underlay() -> void:
	_camera.position = MAP_SIZE * 0.5
	_camera.zoom = Vector2(0.24, 0.24)
	_overlay.queue_redraw()


func _focus_spawn_causeway() -> void:
	_camera.position = Vector2(MAP_SIZE.x * 0.5, MAP_SIZE.y * 0.78)
	_camera.zoom = Vector2(0.48, 0.48)
	_overlay.queue_redraw()


func _copy_segments_to_clipboard() -> void:
	var lines := _format_draft_segment_lines()
	var text := "\n".join(lines)
	DisplayServer.clipboard_set(text)
	print("[SunderedKeepUnderlayCollisionMapper] Copied %d segment(s) to clipboard" % lines.size())
	if text.is_empty():
		return
	print(text)


func _copy_markers_to_clipboard() -> void:
	var text := _format_underlay_authoring_markers_const()
	DisplayServer.clipboard_set(text)
	print("[SunderedKeepUnderlayCollisionMapper] Copied %d marker override(s) to clipboard" % _draft_markers.size())
	if not text.is_empty():
		print(text)


func _apply_draft_segments_to_underlay_collision_map() -> bool:
	var lines := _format_draft_segment_lines()
	if lines.is_empty():
		push_warning("[SunderedKeepUnderlayCollisionMapper] No complete draft segments to apply")
		return false

	var script_path := ProjectSettings.globalize_path(UNDERLAY_DEBUG_SCRIPT_PATH)
	if script_path.is_empty():
		push_warning("[SunderedKeepUnderlayCollisionMapper] Could not resolve %s" % UNDERLAY_DEBUG_SCRIPT_PATH)
		return false
	if not FileAccess.file_exists(script_path):
		push_warning("[SunderedKeepUnderlayCollisionMapper] Missing underlay debug script: %s" % script_path)
		return false

	var file := FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		push_warning("[SunderedKeepUnderlayCollisionMapper] Could not read underlay debug script: %s" % script_path)
		return false
	var text := file.get_as_text()
	file.close()

	var replacement := _format_underlay_boundary_segments_const(lines)
	var existing_block := _extract_underlay_boundary_segments_block(text)
	if existing_block.is_empty():
		push_warning("[SunderedKeepUnderlayCollisionMapper] UNDERLAY_BOUNDARY_SEGMENTS block was not found")
		return false
	if existing_block == replacement:
		print("[SunderedKeepUnderlayCollisionMapper] UNDERLAY_BOUNDARY_SEGMENTS already up to date with %d segment(s)" % lines.size())
		_copy_segments_to_clipboard()
		return true

	var replaced := _replace_underlay_boundary_segments_block(text, replacement)
	if replaced == text:
		push_warning("[SunderedKeepUnderlayCollisionMapper] UNDERLAY_BOUNDARY_SEGMENTS block was not replaced")
		return false

	file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		push_warning("[SunderedKeepUnderlayCollisionMapper] Could not write underlay debug script: %s" % script_path)
		return false
	file.store_string(replaced)
	file.close()

	print("[SunderedKeepUnderlayCollisionMapper] Applied %d segment(s) to %s" % [lines.size(), UNDERLAY_DEBUG_SCRIPT_PATH])
	_copy_segments_to_clipboard()
	return true


func _apply_draft_markers_to_underlay_marker_map() -> bool:
	if _draft_markers.is_empty():
		push_warning("[SunderedKeepUnderlayCollisionMapper] No draft markers to apply")
		return false
	var script_path := ProjectSettings.globalize_path(UNDERLAY_DEBUG_SCRIPT_PATH)
	if script_path.is_empty() or not FileAccess.file_exists(script_path):
		push_warning("[SunderedKeepUnderlayCollisionMapper] Missing underlay debug script: %s" % script_path)
		return false
	var file := FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		push_warning("[SunderedKeepUnderlayCollisionMapper] Could not read underlay debug script: %s" % script_path)
		return false
	var text := file.get_as_text()
	file.close()
	var replacement := _format_underlay_authoring_markers_const()
	var replaced := _replace_underlay_authoring_markers_block(text, replacement)
	if replaced == text:
		push_warning("[SunderedKeepUnderlayCollisionMapper] UNDERLAY_AUTHORING_MARKERS block was not replaced")
		return false
	file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		push_warning("[SunderedKeepUnderlayCollisionMapper] Could not write underlay debug script: %s" % script_path)
		return false
	file.store_string(replaced)
	file.close()
	print("[SunderedKeepUnderlayCollisionMapper] Applied %d marker override(s) to %s" % [_draft_markers.size(), UNDERLAY_DEBUG_SCRIPT_PATH])
	_copy_markers_to_clipboard()
	return true


func _format_draft_segment_lines() -> Array[String]:
	var lines: Array[String] = []
	var index := 1
	while index < _draft_points.size():
		lines.append(_format_segment(_draft_points[index - 1], _draft_points[index]))
		index += 1
	return lines


func _format_underlay_boundary_segments_const(lines: Array[String]) -> String:
	return "const UNDERLAY_BOUNDARY_SEGMENTS := [\n\t%s\n]" % "\n\t".join(lines)


func _replace_underlay_boundary_segments_block(text: String, replacement: String) -> String:
	var existing_block := _extract_underlay_boundary_segments_block(text)
	if existing_block.is_empty():
		return text
	return text.replace(existing_block, replacement)


func _extract_underlay_boundary_segments_block(text: String) -> String:
	const MARKER := "const UNDERLAY_BOUNDARY_SEGMENTS := ["
	var marker_start := text.find(MARKER)
	if marker_start < 0:
		return ""
	var bracket_start := text.find("[", marker_start)
	if bracket_start < 0:
		return ""

	var depth := 0
	var index := bracket_start
	while index < text.length():
		var character := text[index]
		if character == "[":
			depth += 1
		elif character == "]":
			depth -= 1
			if depth == 0:
				return text.substr(marker_start, index + 1 - marker_start)
		index += 1
	return ""


func _format_underlay_authoring_markers_const() -> String:
	var lines: Array[String] = ["const UNDERLAY_AUTHORING_MARKERS := {"]
	for marker_id: String in MARKER_KINDS:
		var point := _marker_world_point(marker_id)
		lines.append("\t\"%s\": {" % marker_id)
		lines.append("\t\t\"label\": \"%s\"," % str(MARKER_KIND_LABELS.get(marker_id, marker_id.to_upper())))
		lines.append("\t\t\"kind\": \"%s\"," % str(MARKER_KIND_TYPES.get(marker_id, marker_id)))
		lines.append("\t\t\"position\": %s," % _fmt_vec(point))
		if marker_id.begins_with("enemy_spawn"):
			lines.append("\t\t\"lane\": \"sundered_keep_%s\"," % marker_id.trim_prefix("enemy_spawn_"))
		lines.append("\t},")
	lines.append("}")
	return "\n".join(lines)


func _replace_underlay_authoring_markers_block(text: String, replacement: String) -> String:
	const MARKER := "const UNDERLAY_AUTHORING_MARKERS := {"
	var marker_start := text.find(MARKER)
	if marker_start < 0:
		return text
	var brace_start := text.find("{", marker_start)
	if brace_start < 0:
		return text
	var depth := 0
	var index := brace_start
	while index < text.length():
		var character := text[index]
		if character == "{":
			depth += 1
		elif character == "}":
			depth -= 1
			if depth == 0:
				return text.substr(0, marker_start) + replacement + text.substr(index + 1)
		index += 1
	return text


func _print_point(point: Vector2) -> void:
	print("[SunderedKeepUnderlayCollisionMapper] world=%s tile=%s" % [_fmt_vec(point), _world_to_tile(point)])


func _format_segment(a: Vector2, b: Vector2) -> String:
	return "[%s, %s]," % [_fmt_vec(a), _fmt_vec(b)]


func _fmt_vec(point: Vector2) -> String:
	return "Vector2(%.1f, %.1f)" % [point.x, point.y]


func _world_to_tile(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / 32.0), floori(point.y / 32.0))


func _selected_marker_id() -> String:
	return MARKER_KINDS[clampi(_selected_marker_index, 0, MARKER_KINDS.size() - 1)]


func _marker_world_point(marker_id: String) -> Vector2:
	if _draft_markers.has(marker_id):
		return _draft_markers[marker_id] as Vector2
	if _underlay_scene != null and _underlay_scene.has_method("get_underlay_authoring_marker_state"):
		var state := _underlay_scene.call("get_underlay_authoring_marker_state") as Dictionary
		var marker_state: Variant = state.get(marker_id, {})
		if marker_state is Dictionary:
			var position: Variant = (marker_state as Dictionary).get("position", Vector2.ZERO)
			if position is Vector2:
				return position
	return Vector2.ZERO


func _update_help() -> void:
	if _hud == null:
		return
	var complete_segments := maxi(0, _draft_points.size() - 1)
	var selected_marker := _selected_marker_id()
	_hud.text = "\n".join([
		"Sundered Keep Main Underlay Collision Mapper",
		"Mode: %s   M: toggle collision/marker   1-7: marker type   Selected marker: %s" % ["MARKER" if _marker_mode else "COLLISION", selected_marker],
		"Collision mode: Left click add rail point   Right click undo   C copy rails   Enter/U apply rails",
		"Marker mode: Left click place selected marker   Right click clear selected marker   C copy markers   Enter/U apply markers",
		"WASD/arrows: pan   Wheel/+/-: zoom   F: full underlay   S: spawn/causeway   E: existing rails   V: draft   R: reset   H: help",
		"Mouse world: %s   tile: %s" % [_fmt_vec(_mouse_world), _world_to_tile(_mouse_world)],
		"Draft points: %d   Complete segments: %d   Draft markers: %d" % [_draft_points.size(), complete_segments, _draft_markers.size()],
	])


func get_collision_mapper_state() -> Dictionary:
	return {
		"underlay_scene": _underlay_scene,
		"draft_points": _draft_points,
		"draft_markers": _draft_markers,
		"marker_kinds": MARKER_KINDS,
		"marker_mode": _marker_mode,
		"selected_marker": _selected_marker_id(),
		"mouse_world": _mouse_world,
		"show_existing": _show_existing,
		"show_draft": _show_draft,
	}
