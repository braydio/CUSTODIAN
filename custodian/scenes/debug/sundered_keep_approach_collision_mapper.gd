extends Node2D

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")
const APPROACH_SCRIPT_PATH := "res://game/world/approaches/sundered_keep/sundered_keep_approach.gd"
const ROUTE_VERTICAL_OFFSET := 180.0
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

var _approach: Node2D = null
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
	_camera.position = Vector2(520.0, -20.0)
	_camera.zoom = Vector2(0.42, 0.42)
	_load_approach()
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


func _draw() -> void:
	pass


func _load_approach() -> void:
	_approach = APPROACH_SCENE.instantiate() as Node2D
	if _approach == null:
		push_error("[SunderedKeepApproachCollisionMapper] Could not instantiate approach")
		return
	_approach.name = "SunderedKeepApproachReview"
	_world.add_child(_approach)


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
				_apply_draft_markers_to_runtime_marker_map()
			else:
				_apply_draft_segments_to_runtime_collision_map()
		KEY_E:
			_show_existing = not _show_existing
			_overlay.queue_redraw()
		KEY_H:
			_show_help = not _show_help
			_hud.visible = _show_help
		KEY_L:
			_focus_late_traverse()
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
	print("[SunderedKeepApproachCollisionMapper] marker %s runtime=%s source=%s" % [marker_id, _fmt_vec(point), _fmt_vec(_to_source_point(point))])
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
	_camera.zoom = (_camera.zoom * factor).clamp(Vector2(0.12, 0.12), Vector2(2.5, 2.5))
	var after := _camera.get_global_mouse_position()
	_camera.position += before - after
	_update_help()
	_overlay.queue_redraw()


func _focus_late_traverse() -> void:
	_camera.position = Vector2(720.0, -90.0)
	_camera.zoom = Vector2(0.62, 0.62)
	_overlay.queue_redraw()


func _copy_segments_to_clipboard() -> void:
	var lines := _format_draft_segment_lines()
	var text := "\n".join(lines)
	DisplayServer.clipboard_set(text)
	print("[SunderedKeepApproachCollisionMapper] Copied %d segment(s) to clipboard" % lines.size())
	if text.is_empty():
		return
	print(text)


func _copy_markers_to_clipboard() -> void:
	var text := _format_authoring_markers_const()
	DisplayServer.clipboard_set(text)
	print("[SunderedKeepApproachCollisionMapper] Copied %d marker override(s) to clipboard" % _draft_markers.size())
	if not text.is_empty():
		print(text)


func _apply_draft_segments_to_runtime_collision_map() -> bool:
	var lines := _format_draft_segment_lines()
	if lines.is_empty():
		push_warning("[SunderedKeepApproachCollisionMapper] No complete draft segments to apply")
		return false

	var script_path := ProjectSettings.globalize_path(APPROACH_SCRIPT_PATH)
	if script_path.is_empty():
		push_warning("[SunderedKeepApproachCollisionMapper] Could not resolve %s" % APPROACH_SCRIPT_PATH)
		return false
	if not FileAccess.file_exists(script_path):
		push_warning("[SunderedKeepApproachCollisionMapper] Missing approach script: %s" % script_path)
		return false

	var file := FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		push_warning("[SunderedKeepApproachCollisionMapper] Could not read approach script: %s" % script_path)
		return false
	var text := file.get_as_text()
	file.close()

	var replaced := _replace_boundary_segments_block(text, _format_boundary_segments_const(lines))
	if replaced == text:
		push_warning("[SunderedKeepApproachCollisionMapper] BOUNDARY_SEGMENTS block was not replaced")
		return false

	file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		push_warning("[SunderedKeepApproachCollisionMapper] Could not write approach script: %s" % script_path)
		return false
	file.store_string(replaced)
	file.close()

	print("[SunderedKeepApproachCollisionMapper] Applied %d segment(s) to %s" % [lines.size(), APPROACH_SCRIPT_PATH])
	_copy_segments_to_clipboard()
	return true


func _apply_draft_markers_to_runtime_marker_map() -> bool:
	if _draft_markers.is_empty():
		push_warning("[SunderedKeepApproachCollisionMapper] No draft markers to apply")
		return false

	var script_path := ProjectSettings.globalize_path(APPROACH_SCRIPT_PATH)
	if script_path.is_empty():
		push_warning("[SunderedKeepApproachCollisionMapper] Could not resolve %s" % APPROACH_SCRIPT_PATH)
		return false
	if not FileAccess.file_exists(script_path):
		push_warning("[SunderedKeepApproachCollisionMapper] Missing approach script: %s" % script_path)
		return false

	var file := FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		push_warning("[SunderedKeepApproachCollisionMapper] Could not read approach script: %s" % script_path)
		return false
	var text := file.get_as_text()
	file.close()

	var replaced := _replace_authoring_markers_block(text, _format_authoring_markers_const())
	if replaced == text:
		push_warning("[SunderedKeepApproachCollisionMapper] AUTHORING_MARKERS block was not replaced")
		return false

	file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		push_warning("[SunderedKeepApproachCollisionMapper] Could not write approach script: %s" % script_path)
		return false
	file.store_string(replaced)
	file.close()

	print("[SunderedKeepApproachCollisionMapper] Applied %d marker override(s) to %s" % [_draft_markers.size(), APPROACH_SCRIPT_PATH])
	_copy_markers_to_clipboard()
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
	const MARKER := "const BOUNDARY_SEGMENTS := ["
	var marker_start := text.find(MARKER)
	if marker_start < 0:
		return text
	var bracket_start := text.find("[", marker_start)
	if bracket_start < 0:
		return text

	var depth := 0
	var index := bracket_start
	while index < text.length():
		var character := text[index]
		if character == "[":
			depth += 1
		elif character == "]":
			depth -= 1
			if depth == 0:
				return text.substr(0, marker_start) + replacement + text.substr(index + 1)
		index += 1
	return text


func _format_authoring_markers_const() -> String:
	var lines: Array[String] = ["const AUTHORING_MARKERS := {"]
	for marker_id: String in MARKER_KINDS:
		var point := _marker_runtime_point(marker_id)
		var source_point := _to_source_point(point)
		lines.append("\t\"%s\": {" % marker_id)
		lines.append("\t\t\"label\": \"%s\"," % str(MARKER_KIND_LABELS.get(marker_id, marker_id.to_upper())))
		lines.append("\t\t\"kind\": \"%s\"," % str(MARKER_KIND_TYPES.get(marker_id, marker_id)))
		lines.append("\t\t\"position\": %s," % _fmt_vec(source_point))
		if marker_id.begins_with("enemy_spawn"):
			lines.append("\t\t\"lane\": \"sundered_keep_%s\"," % marker_id.trim_prefix("enemy_spawn_"))
		lines.append("\t},")
	lines.append("}")
	return "\n".join(lines)


func _replace_authoring_markers_block(text: String, replacement: String) -> String:
	const MARKER := "const AUTHORING_MARKERS := {"
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
	print("[SunderedKeepApproachCollisionMapper] runtime=%s unshifted=%s" % [_fmt_vec(point), _fmt_vec(_to_source_point(point))])


func _format_segment(a: Vector2, b: Vector2) -> String:
	return "[%s, %s]," % [_fmt_vec(_to_source_point(a)), _fmt_vec(_to_source_point(b))]


func _fmt_vec(point: Vector2) -> String:
	return "Vector2(%.1f, %.1f)" % [point.x, point.y]


func _to_source_point(runtime_point: Vector2) -> Vector2:
	return runtime_point - Vector2(0.0, ROUTE_VERTICAL_OFFSET)


func _selected_marker_id() -> String:
	return MARKER_KINDS[clampi(_selected_marker_index, 0, MARKER_KINDS.size() - 1)]


func _marker_runtime_point(marker_id: String) -> Vector2:
	if _draft_markers.has(marker_id):
		return _draft_markers[marker_id] as Vector2
	if _approach != null and _approach.has_method("get_authoring_marker_state"):
		var state := _approach.call("get_authoring_marker_state") as Dictionary
		var marker_state: Variant = state.get(marker_id, {})
		if marker_state is Dictionary:
			var runtime_position: Variant = (marker_state as Dictionary).get("runtime_position", Vector2.ZERO)
			if runtime_position is Vector2:
				return runtime_position
	return Vector2.ZERO


func _update_help() -> void:
	if _hud == null:
		return
	var source := _to_source_point(_mouse_world)
	var complete_segments := maxi(0, _draft_points.size() - 1)
	var selected_marker := _selected_marker_id()
	_hud.text = "\n".join([
		"Sundered Keep Approach Collision Mapper",
		"Mode: %s   M: toggle collision/marker   1-7: marker type   Selected marker: %s" % ["MARKER" if _marker_mode else "COLLISION", selected_marker],
		"Collision mode: Left click add rail point   Right click undo   C copy rails   Enter/U apply rails",
		"Marker mode: Left click place selected marker   Right click clear selected marker   C copy markers   Enter/U apply markers",
		"WASD/arrows: pan   Wheel/+/-: zoom   L: final traverse   E: existing rails   V: draft   R: reset current mode   H: help",
		"Mouse runtime: %s   BOUNDARY_SEGMENTS source: %s" % [_fmt_vec(_mouse_world), _fmt_vec(source)],
		"Draft points: %d   Complete segments: %d   Draft markers: %d" % [_draft_points.size(), complete_segments, _draft_markers.size()],
	])


func get_collision_mapper_state() -> Dictionary:
	return {
		"approach": _approach,
		"draft_points": _draft_points,
		"draft_markers": _draft_markers,
		"marker_kinds": MARKER_KINDS,
		"marker_mode": _marker_mode,
		"selected_marker": _selected_marker_id(),
		"mouse_world": _mouse_world,
		"show_existing": _show_existing,
		"show_draft": _show_draft,
	}
