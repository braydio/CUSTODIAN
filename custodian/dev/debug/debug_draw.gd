extends Node2D

var _last_overlays_version := -1
var _last_overlay_mode := -1
var _last_enabled := false


func _get_debug_bus() -> Node:
	return get_node_or_null("/root/DebugBus")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

func _process(_delta: float) -> void:
	var debug_bus := _get_debug_bus()
	if debug_bus == null:
		return
	var needs_redraw := false
	if debug_bus.enabled != _last_enabled:
		needs_redraw = true
		_last_enabled = debug_bus.enabled
	if debug_bus.overlay_mode != _last_overlay_mode:
		needs_redraw = true
		_last_overlay_mode = debug_bus.overlay_mode
	if debug_bus.overlays_version != _last_overlays_version:
		needs_redraw = true
		_last_overlays_version = debug_bus.overlays_version
	if needs_redraw:
		queue_redraw()

func _draw() -> void:
	var debug_bus := _get_debug_bus()
	if debug_bus == null or not debug_bus.enabled:
		return
	match debug_bus.overlay_mode:
		0:
			return
		1:
			_draw_ranges()
		2:
			_draw_paths()
		3:
			_draw_targeting()
		4:
			_draw_ai_states()
		5:
			_draw_all()

func _draw_ranges() -> void:
	var debug_bus := _get_debug_bus()
	if debug_bus == null:
		return
	for circle in debug_bus.overlays.get("ranges", []):
		var pos: Vector2 = circle.get("pos", Vector2.ZERO)
		var radius: float = circle.get("radius", 0.0)
		var color: Color = circle.get("color", Color(1, 0.2, 0.2, 0.6))
		if radius > 0.0:
			draw_arc(pos, radius, 0.0, TAU, 48, color, 2.0)

func _draw_paths() -> void:
	var debug_bus := _get_debug_bus()
	if debug_bus == null:
		return
	for path in debug_bus.overlays.get("paths", []):
		var points: Array = path.get("points", [])
		if points.size() < 2:
			continue
		var color: Color = path.get("color", Color(0.2, 0.8, 1.0, 0.7))
		var width: float = path.get("width", 2.0)
		draw_polyline(points, color, width)

func _draw_targeting() -> void:
	var debug_bus := _get_debug_bus()
	if debug_bus == null:
		return
	for line in debug_bus.overlays.get("targeting", []):
		var from_pos: Vector2 = line.get("from", Vector2.ZERO)
		var to_pos: Vector2 = line.get("to", Vector2.ZERO)
		var color: Color = line.get("color", Color(1.0, 0.85, 0.2, 0.7))
		var width: float = line.get("width", 2.0)
		draw_line(from_pos, to_pos, color, width)

func _draw_ai_states() -> void:
	var debug_bus := _get_debug_bus()
	if debug_bus == null:
		return
	for marker in debug_bus.overlays.get("ai_states", []):
		var pos: Vector2 = marker.get("pos", Vector2.ZERO)
		var radius: float = marker.get("radius", 8.0)
		var color: Color = marker.get("color", Color(0.6, 0.9, 0.4, 0.8))
		draw_circle(pos, radius, color)

func _draw_all() -> void:
	_draw_ranges()
	_draw_paths()
	_draw_targeting()
	_draw_ai_states()
