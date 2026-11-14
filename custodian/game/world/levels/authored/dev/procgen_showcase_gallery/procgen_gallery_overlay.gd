extends Node2D
class_name ProcgenGalleryOverlay

const LAYER_COLORS := {
	"terrain": Color(0.35, 0.82, 0.74, 0.48),
	"route": Color(1.0, 0.8, 0.25, 0.9),
	"playability": Color(0.42, 0.9, 0.5, 0.55),
	"sites": Color(1.0, 0.48, 0.36, 0.95),
	"vistas": Color(0.45, 0.7, 1.0, 0.92),
}

var _snapshot: Dictionary = {}
var _enabled_layers: Dictionary = {}
var _last_draw_counts: Dictionary = {}


func _ready() -> void:
	set_process(false)
	set_physics_process(false)


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	queue_redraw()


func clear_snapshot() -> void:
	_snapshot.clear()
	_last_draw_counts.clear()
	queue_redraw()


func set_layer_enabled(layer: String, enabled: bool) -> void:
	if not LAYER_COLORS.has(layer):
		return
	_enabled_layers[layer] = enabled
	queue_redraw()


func get_draw_counts() -> Dictionary:
	return _last_draw_counts.duplicate(true)


func _draw() -> void:
	_last_draw_counts.clear()
	if _snapshot.is_empty():
		return
	var layers: Dictionary = _snapshot.get("layers", {})
	for layer in LAYER_COLORS:
		if not bool(_enabled_layers.get(layer, false)):
			continue
		var points: Variant = layers.get(layer, [])
		if not points is Array:
			continue
		var cap := int(_snapshot.get("layer_limits", {}).get(layer, 1024))
		var count := mini(points.size(), cap)
		_last_draw_counts[layer] = count
		var color: Color = LAYER_COLORS[layer]
		if layer == "route" and count > 1:
			var line := PackedVector2Array()
			for index in range(count):
				if points[index] is Vector2:
					line.append(points[index])
			if line.size() > 1:
				draw_polyline(line, color, 4.0, true)
		for index in range(count):
			var point: Variant = points[index]
			if point is Vector2:
				draw_circle(point, 5.0 if layer in ["sites", "vistas"] else 3.0, color)
