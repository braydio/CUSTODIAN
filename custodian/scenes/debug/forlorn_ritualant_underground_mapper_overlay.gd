extends "res://scenes/debug/level_collision_poi_mapper_overlay.gd"


func _draw() -> void:
	super()
	if _mapper == null:
		return
	var state := _mapper.call("get_collision_mapper_state") as Dictionary
	var records := state.get("semantic_geometry", []) as Array
	var by_id := {}
	for record: Dictionary in records:
		by_id[str(record.get("id", ""))] = record
	var chamber := (by_id.get("encounter.ritualant_chamber", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var combat := (by_id.get("encounter.combat_bounds", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var thread_left := (by_id.get("encounter.thread_hazard_left", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var thread_right := (by_id.get("encounter.thread_hazard_right", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var warning := (by_id.get("encounter.thread_warning", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var arena_art := (by_id.get("art.ritualant_arena_expanded_base", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var decal_left := (by_id.get("art.decal", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var warning_left := (by_id.get("art.thread_warning_left", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var ritualant := (by_id.get("encounter.ritualant", {}) as Dictionary).get("point", Vector2.ZERO) as Vector2
	var fountain_art := (by_id.get("art.dry_fountain_basin", {}) as Dictionary).get("center", Vector2.ZERO) as Vector2
	var fountain_zone := (by_id.get("encounter.fountain_zone", {}) as Dictionary).get("rect", Rect2()) as Rect2
	var level := state.get("target_level") as Node
	var hostility := &""
	if level != null:
		var site := level.get_node_or_null("PlayableRoot/ForlornRitualantSite")
		if site != null and site.has_method("debug_get_last_hostility_reason"):
			hostility = site.call("debug_get_last_hostility_reason") as StringName
	var camera_name := _active_camera_under_mouse(records, state.get("mouse_world", Vector2.ZERO) as Vector2)
	var lines := [
		"CHAPEL combat/visible %.1f%%" % (100.0 * combat.get_area() / maxf(chamber.get_area(), 1.0)),
		"RITUALANT %s" % ritualant,
		"THREAD hazards L%s R%s gap=%dpx  warning %s" % [thread_left.size, thread_right.size, int(thread_right.position.x - thread_left.end.x), warning.size],
		"ARENA ART %s (presentation only, native scale)" % arena_art.size,
		"THREAD art decal=%s warning=%s; gameplay=%s" % [decal_left.size, warning_left.size, thread_left.size],
		"FOUNTAIN art/game delta %s" % (fountain_zone.get_center() - fountain_art),
		"HOSTILITY last=%s" % (String(hostility) if not hostility.is_empty() else "none"),
		"LIFT dock=(0, 1696) interaction=96px",
		"CAMERA under mouse=%s" % camera_name,
	]
	var anchor := chamber.position + Vector2(10.0, 24.0)
	for index in lines.size():
		draw_string(ThemeDB.fallback_font, anchor + Vector2(0.0, index * 18.0), lines[index], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(1.0, 0.94, 0.72, 0.96))


func _active_camera_under_mouse(records: Array, point: Vector2) -> String:
	var selected := "none"
	var selected_priority := -2147483648
	for record: Dictionary in records:
		if str(record.get("group", "")) != "camera":
			continue
		var rect := record.get("rect", Rect2()) as Rect2
		if not rect.has_point(point):
			continue
		var details := str(record.get("details", ""))
		var priority := int(details.get_slice(";", 0).trim_prefix("priority "))
		if priority > selected_priority:
			selected_priority = priority
			selected = str(record.get("label", "none"))
	return selected
