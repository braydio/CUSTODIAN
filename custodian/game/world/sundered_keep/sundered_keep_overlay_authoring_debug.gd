extends Node2D
class_name SunderedKeepOverlayAuthoringDebug

const DEFAULT_AUTHORING_MASK_PATH := "res://content/levels/sundered_keep/sundered_keep_overlay_authoring.json"

@export_file("*.json") var authoring_mask_path: String = DEFAULT_AUTHORING_MASK_PATH
@export var tile_size: float = 32.0
@export var floor_fill_color := Color(0.12, 0.85, 0.32, 0.18)
@export var floor_outline_color := Color(0.24, 0.95, 0.42, 0.8)
@export var border_void_fill_color := Color(0.92, 0.14, 0.16, 0.12)
@export var border_void_outline_color := Color(1.0, 0.24, 0.24, 0.72)
@export var enclosed_void_fill_color := Color(0.95, 0.84, 0.18, 0.18)
@export var enclosed_void_outline_color := Color(1.0, 0.9, 0.32, 0.82)
@export var centroid_color := Color(0.98, 0.98, 1.0, 0.95)
@export var draw_floor_rects := true
@export var draw_border_void_rects := true
@export var draw_enclosed_void_rects := true

var _data: Dictionary = {}
var _debug_state := {
	"loaded": false,
	"schema": "",
	"floor_rects": 0,
	"border_void_rects": 0,
	"enclosed_void_rects": 0,
	"solid_tiles": 0,
}


func _ready() -> void:
	z_as_relative = false
	z_index = 120
	_load_authoring_mask()


func get_debug_state() -> Dictionary:
	return _debug_state.duplicate(true)


func _draw() -> void:
	if _data.is_empty():
		return
	if draw_border_void_rects:
		_draw_rect_set(_data.get("suggested_border_void_rects", []), border_void_fill_color, border_void_outline_color)
	if draw_floor_rects:
		_draw_rect_set(_data.get("suggested_floor_rects", []), floor_fill_color, floor_outline_color)
	if draw_enclosed_void_rects:
		_draw_rect_set(_data.get("suggested_enclosed_void_rects", []), enclosed_void_fill_color, enclosed_void_outline_color)
	_draw_centroid(_data.get("anchors", {}).get("largest_solid_component_centroid_tile", []))


func _load_authoring_mask() -> void:
	_data.clear()
	_debug_state["loaded"] = false
	_debug_state["schema"] = ""
	_debug_state["floor_rects"] = 0
	_debug_state["border_void_rects"] = 0
	_debug_state["enclosed_void_rects"] = 0
	_debug_state["solid_tiles"] = 0

	if authoring_mask_path.is_empty() or not ResourceLoader.exists(authoring_mask_path):
		queue_redraw()
		return

	var file := FileAccess.open(authoring_mask_path, FileAccess.READ)
	if file == null:
		queue_redraw()
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		queue_redraw()
		return

	_data = parsed as Dictionary
	var stats := _data.get("stats", {}) as Dictionary
	_debug_state["loaded"] = true
	_debug_state["schema"] = str(_data.get("schema", ""))
	_debug_state["floor_rects"] = (_data.get("suggested_floor_rects", []) as Array).size()
	_debug_state["border_void_rects"] = (_data.get("suggested_border_void_rects", []) as Array).size()
	_debug_state["enclosed_void_rects"] = (_data.get("suggested_enclosed_void_rects", []) as Array).size()
	_debug_state["solid_tiles"] = int(stats.get("solid_tiles", 0))
	queue_redraw()


func _draw_rect_set(rects: Array, fill_color: Color, outline_color: Color) -> void:
	for rect_value in rects:
		var rect := _array_to_world_rect(rect_value)
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		draw_rect(rect, fill_color, true)
		draw_rect(rect, outline_color, false, 2.0)


func _draw_centroid(value) -> void:
	if not (value is Array) or (value as Array).size() < 2:
		return
	var point := Vector2((float(value[0]) * tile_size), (float(value[1]) * tile_size))
	var offset := 9.0
	draw_line(point + Vector2(-offset, 0.0), point + Vector2(offset, 0.0), centroid_color, 2.0)
	draw_line(point + Vector2(0.0, -offset), point + Vector2(0.0, offset), centroid_color, 2.0)
	draw_circle(point, 3.0, centroid_color)


func _array_to_world_rect(value) -> Rect2:
	if not (value is Array) or (value as Array).size() < 4:
		return Rect2()
	return Rect2(
		Vector2(float(value[0]) * tile_size, float(value[1]) * tile_size),
		Vector2(float(value[2]) * tile_size, float(value[3]) * tile_size)
	)
