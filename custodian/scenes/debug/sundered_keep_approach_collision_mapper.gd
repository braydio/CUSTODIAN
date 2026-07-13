extends Node2D

const APPROACH_SCENE := preload("res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn")
const APPROACH_SCRIPT_PATH := "res://game/world/approaches/sundered_keep/sundered_keep_approach.gd"
const ROUTE_VERTICAL_OFFSET := 180.0

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
				_add_point(_camera.get_global_mouse_position())
			elif mouse.button_index == MOUSE_BUTTON_RIGHT:
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
			_copy_segments_to_clipboard()
		KEY_ENTER, KEY_KP_ENTER, KEY_U:
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
			_draft_points.clear()
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


func _print_point(point: Vector2) -> void:
	print("[SunderedKeepApproachCollisionMapper] runtime=%s unshifted=%s" % [_fmt_vec(point), _fmt_vec(_to_source_point(point))])


func _format_segment(a: Vector2, b: Vector2) -> String:
	return "[%s, %s]," % [_fmt_vec(_to_source_point(a)), _fmt_vec(_to_source_point(b))]


func _fmt_vec(point: Vector2) -> String:
	return "Vector2(%.1f, %.1f)" % [point.x, point.y]


func _to_source_point(runtime_point: Vector2) -> Vector2:
	return runtime_point - Vector2(0.0, ROUTE_VERTICAL_OFFSET)


func _update_help() -> void:
	if _hud == null:
		return
	var source := _to_source_point(_mouse_world)
	var complete_segments := maxi(0, _draft_points.size() - 1)
	_hud.text = "\n".join([
		"Sundered Keep Approach Collision Mapper",
		"Left click: add point   Right click: undo   C: copy connected polyline segments   Enter/U: apply to runtime collision map",
		"WASD/arrows: pan   Wheel/+/-: zoom   L: final traverse   E: existing rails   V: draft   R: reset   H: help",
		"Mouse runtime: %s   BOUNDARY_SEGMENTS source: %s" % [_fmt_vec(_mouse_world), _fmt_vec(source)],
		"Draft points: %d   Complete segments: %d" % [_draft_points.size(), complete_segments],
	])


func get_collision_mapper_state() -> Dictionary:
	return {
		"approach": _approach,
		"draft_points": _draft_points,
		"mouse_world": _mouse_world,
		"show_existing": _show_existing,
		"show_draft": _show_draft,
	}
