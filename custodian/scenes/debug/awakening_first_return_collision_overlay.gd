extends "res://scenes/debug/level_collision_poi_mapper_overlay.gd"

const Layout := preload("res://game/world/awakening/awakening_layout.gd")


func _draw() -> void:
	super._draw()
	if _mapper == null or not _mapper.has_method("get_collision_mapper_state"): return
	var state := _mapper.call("get_collision_mapper_state") as Dictionary
	if bool(state.get("show_actual_colliders", false)):
		_draw_actual_colliders(state.get("actual_colliders", []) as Array, str(state.get("selected_collision_id", "")))
	if bool(state.get("show_protected_paths", false)):
		_draw_protected_paths()
	if bool(state.get("show_registration_bounds", false)):
		_draw_registration_bounds(state.get("registration_bounds", []) as Array)
	if bool(state.get("show_draft", true)):
		_draw_closed_proposals(state.get("draft_polylines", []) as Array)


func _draw_actual_colliders(records: Array, selected_id: String) -> void:
	for record_variant: Variant in records:
		if not record_variant is Dictionary: continue
		var record := record_variant as Dictionary
		var points := record.get("world_points", PackedVector2Array()) as PackedVector2Array
		if points.size() < 2: continue
		var color := Color(0.2, 1.0, 0.55, 1.0) if str(record.get("id", "")) == selected_id else (Color(1.0, 0.18, 0.18, 0.92) if bool(record.get("blocking", false)) else Color(0.95, 0.68, 0.2, 0.75))
		var closed := PackedVector2Array(points)
		closed.append(points[0])
		draw_polyline(closed, color, 3.0)
		draw_string(ThemeDB.fallback_font, points[0] + Vector2(4, -5), "%s | %s | %s" % [str(record.get("zone_id", "")), str(record.get("kind", "")), str(record.get("id", ""))], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)


func _draw_protected_paths() -> void:
	for rect: Rect2 in Layout.CONNECTORS.values():
		draw_rect(rect, Color(0.15, 0.85, 1.0, 0.16), true)
		draw_rect(rect, Color(0.15, 0.85, 1.0, 0.95), false, 2.0)
	for rect: Rect2 in Layout.PASSAGES.values():
		draw_rect(rect, Color(0.25, 1.0, 0.72, 0.14), true)
		draw_rect(rect, Color(0.25, 1.0, 0.72, 0.95), false, 2.0)
	for rect: Rect2 in Layout.THRESHOLDS.values():
		draw_rect(rect, Color(0.95, 0.7, 0.2, 0.18), true)
		draw_rect(rect, Color(0.95, 0.7, 0.2, 0.95), false, 2.0)
	draw_rect(Layout.south_reach_barrier_rect(), Color(1.0, 0.15, 0.15, 0.22), true)


func _draw_registration_bounds(records: Array) -> void:
	for record_variant: Variant in records:
		if not record_variant is Dictionary: continue
		var record := record_variant as Dictionary
		var points := record.get("world_points", PackedVector2Array()) as PackedVector2Array
		if points.size() < 4: continue
		var closed := PackedVector2Array(points)
		closed.append(points[0])
		draw_polyline(closed, Color(0.92, 0.75, 0.22, 0.95), 3.0)
		draw_string(ThemeDB.fallback_font, points[0] + Vector2(4, -5), str(record.get("id", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.92, 0.75, 0.22, 0.95))


func _draw_closed_proposals(polylines: Array) -> void:
	for polyline: Variant in polylines:
		if not polyline is Array or (polyline as Array).size() < 3: continue
		var points := PackedVector2Array()
		for point: Variant in polyline:
			if point is Vector2: points.append(point)
		if points.size() >= 3:
			draw_line(points[-1], points[0], Color(0.15, 0.85, 1.0, 0.75), 3.0)
