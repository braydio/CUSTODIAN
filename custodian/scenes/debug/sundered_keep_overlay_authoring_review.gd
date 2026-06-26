extends Node2D

const SUNDERED_KEEP_MAP := preload("res://game/world/sundered_keep/sundered_keep_map.gd")
const AUTHORING_DEBUG_OVERLAY := preload("res://game/world/sundered_keep/sundered_keep_overlay_authoring_debug.gd")

@export_file("*.json") var authoring_mask_path: String = "res://content/levels/sundered_keep/sundered_keep_overlay_authoring.json"
@export var camera_zoom := Vector2(0.58, 0.58)

@onready var _world: Node2D = $World
@onready var _camera: Camera2D = $World/Camera2D
@onready var _review_note: Label = $World/ReviewNote

var _map: Node2D = null
var _overlay_debug: SunderedKeepOverlayAuthoringDebug = null


func _ready() -> void:
	_map = SUNDERED_KEEP_MAP.new()
	_map.name = "SunderedKeepMap"
	_world.add_child(_map)

	_overlay_debug = AUTHORING_DEBUG_OVERLAY.new()
	_overlay_debug.name = "OverlayAuthoringDebug"
	_overlay_debug.authoring_mask_path = authoring_mask_path
	_world.add_child(_overlay_debug)

	_camera.enabled = true
	_camera.zoom = camera_zoom
	await get_tree().process_frame
	_center_camera()
	_refresh_note()


func get_review_state() -> Dictionary:
	var overlay_state := {}
	if _overlay_debug != null:
		overlay_state = _overlay_debug.get_debug_state()
	var map_state := {}
	if _map != null and _map.has_method("get_sundered_keep_debug_state"):
		map_state = _map.call("get_sundered_keep_debug_state") as Dictionary
	return {
		"overlay": overlay_state,
		"map": map_state,
	}


func _center_camera() -> void:
	if _map == null or not _map.has_method("get_sundered_keep_debug_state"):
		return
	var state := _map.call("get_sundered_keep_debug_state") as Dictionary
	var map_size := state.get("map_size_tiles", Vector2i(112, 80)) as Vector2i
	_camera.position = Vector2(float(map_size.x) * 16.0, float(map_size.y) * 16.0)


func _refresh_note() -> void:
	var overlay_state := _overlay_debug.get_debug_state() if _overlay_debug != null else {}
	_review_note.text = "Sundered Keep overlay authoring review. Green = suggested footprint, red = border void, yellow = enclosed void. Mask loaded=%s floor_rects=%d border_void_rects=%d" % [
		str(bool(overlay_state.get("loaded", false))),
		int(overlay_state.get("floor_rects", 0)),
		int(overlay_state.get("border_void_rects", 0)),
	]
