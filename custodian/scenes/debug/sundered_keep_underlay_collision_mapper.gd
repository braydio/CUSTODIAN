extends Node2D

const UNDERLAY_DEBUG_SCENE := preload("res://scenes/debug/sundered_keep_production_underlay_debug.tscn")
const UNDERLAY_DEBUG_SCRIPT_PATH := "res://scenes/debug/sundered_keep_production_underlay_debug.gd"
const MAP_SIZE := Vector2(3584.0, 2560.0)

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
				_add_point(_camera.get_global_mouse_position())
			elif mouse.button_index == MOUSE_BUTTON_RIGHT:
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
			_copy_segments_to_clipboard()
		KEY_ENTER, KEY_KP_ENTER, KEY_U:
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
			_draft_points.clear()
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


func _print_point(point: Vector2) -> void:
	print("[SunderedKeepUnderlayCollisionMapper] world=%s tile=%s" % [_fmt_vec(point), _world_to_tile(point)])


func _format_segment(a: Vector2, b: Vector2) -> String:
	return "[%s, %s]," % [_fmt_vec(a), _fmt_vec(b)]


func _fmt_vec(point: Vector2) -> String:
	return "Vector2(%.1f, %.1f)" % [point.x, point.y]


func _world_to_tile(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / 32.0), floori(point.y / 32.0))


func _update_help() -> void:
	if _hud == null:
		return
	var complete_segments := maxi(0, _draft_points.size() - 1)
	_hud.text = "\n".join([
		"Sundered Keep Main Underlay Collision Mapper",
		"Left click: add point   Right click: undo   C: copy connected polyline segments   Enter/U: apply to underlay map",
		"WASD/arrows: pan   Wheel/+/-: zoom   F: full underlay   S: spawn/causeway   E: existing rails   V: draft   R: reset   H: help",
		"Mouse world: %s   tile: %s" % [_fmt_vec(_mouse_world), _world_to_tile(_mouse_world)],
		"Draft points: %d   Complete segments: %d" % [_draft_points.size(), complete_segments],
	])


func get_collision_mapper_state() -> Dictionary:
	return {
		"underlay_scene": _underlay_scene,
		"draft_points": _draft_points,
		"mouse_world": _mouse_world,
		"show_existing": _show_existing,
		"show_draft": _show_draft,
	}
