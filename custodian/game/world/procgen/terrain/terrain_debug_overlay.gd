extends Node2D
class_name TerrainDebugOverlay

@export var enabled: bool = false:
	get:
		return _enabled
	set(value):
		if _enabled == value:
			return
		_enabled = value
		queue_redraw()

@export var cell_size: Vector2 = Vector2(16, 16)

var terrain_result: Dictionary = {}
var _enabled: bool = false


func set_terrain_result(result: Dictionary) -> void:
	terrain_result = result.duplicate(true)
	queue_redraw()


func _draw() -> void:
	if not enabled or terrain_result.is_empty():
		return
	var height_by_cell: Dictionary = terrain_result.get("height_by_cell", {})
	var traversal_by_cell: Dictionary = terrain_result.get("traversal_by_cell", {})
	for cell_variant in height_by_cell.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		var traversal := String(traversal_by_cell.get(cell, "walkable"))
		var height := int(height_by_cell.get(cell, 0))
		var color := Color(0.1, 0.7, 0.2, 0.18)
		if height > 0:
			color = Color(0.2, 0.45, 1.0, 0.22)
		match traversal:
			"blocked":
				color = Color(1.0, 0.0, 0.0, 0.30)
			"ledge":
				color = Color(1.0, 0.25, 0.0, 0.28)
			"drop":
				color = Color(0.08, 0.0, 0.0, 0.42)
			"ramp", "stair":
				color = Color(1.0, 0.9, 0.0, 0.35)
		draw_rect(Rect2(Vector2(cell) * cell_size, cell_size), color, true)
