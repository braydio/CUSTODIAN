extends Node2D
class_name CarrowInteriorLayoutMapperOverlay

func _draw() -> void:
	var mapper := get_parent().get_parent()
	if mapper == null or not mapper.has_method("get_preview_state"):
		return
	var state := mapper.call("get_preview_state") as Dictionary
	var grid: Vector2i = state.get("grid", Vector2i.ZERO)
	if grid == Vector2i.ZERO:
		return
	var tile := 32.0
	var room_rect := Rect2(Vector2.ZERO, Vector2(grid) * tile)
	draw_rect(room_rect, Color(0.95, 0.77, 0.28, 0.12), true)
	draw_rect(room_rect, Color(0.98, 0.82, 0.34, 0.9), false, 3.0)
	if bool(state.get("show_grid", true)):
		for x in range(grid.x + 1):
			draw_line(Vector2(x * tile, 0), Vector2(x * tile, grid.y * tile), Color(0.78, 0.83, 0.9, 0.18), 1.0)
		for y in range(grid.y + 1):
			draw_line(Vector2(0, y * tile), Vector2(grid.x * tile, y * tile), Color(0.78, 0.83, 0.9, 0.18), 1.0)
	for shape_variant in state.get("collision_shapes", []):
		var shape := shape_variant as Dictionary
		var values: Array = shape.get("rect", [])
		if values.size() != 4:
			continue
		var rect := Rect2(Vector2(int(values[0]), int(values[1])) * tile, Vector2(int(values[2]), int(values[3])) * tile)
		var selected := String(shape.get("id", "")) == String(state.get("selected_collision", ""))
		var color := Color(1.0, 0.25, 0.20, 0.38) if selected else Color(1.0, 0.35, 0.24, 0.22)
		draw_rect(rect, color, true)
		draw_rect(rect, Color(1.0, 0.52, 0.37, 0.95), false, 2.0)
	for portal_variant in state.get("portal_cells", []):
		var cell := CarrowInteriorLayoutDraft._cell(portal_variant)
		draw_rect(Rect2(Vector2(cell) * tile, Vector2.ONE * tile), Color(0.15, 0.9, 0.42, 0.38), true)
		draw_rect(Rect2(Vector2(cell) * tile, Vector2.ONE * tile), Color(0.45, 1.0, 0.58, 1.0), false, 2.0)
	for waypoint_variant in state.get("waypoints", []):
		var waypoint := waypoint_variant as Dictionary
		var cell := CarrowInteriorLayoutDraft._cell(waypoint.get("cell", []))
		var center := Vector2(cell) * tile + Vector2.ONE * tile * 0.5
		draw_circle(center, 7.0, Color(0.15, 0.84, 1.0, 0.9))
		draw_string(ThemeDB.fallback_font, center + Vector2(10.0, 4.0), String(waypoint.get("id", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
	if String(state.get("mode", "")) == "COLLISION" and state.get("drag_rect", Rect2i()).size != Vector2i.ZERO:
		var preview: Rect2i = state.drag_rect
		var rect := Rect2(Vector2(preview.position) * tile, Vector2(preview.size) * tile)
		draw_rect(rect, Color(0.1, 0.75, 1.0, 0.22), true)
		draw_rect(rect, Color(0.2, 0.9, 1.0, 0.95), false, 2.0)
