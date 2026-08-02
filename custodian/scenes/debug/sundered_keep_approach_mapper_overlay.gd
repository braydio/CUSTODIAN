extends "res://scenes/debug/level_collision_poi_mapper_overlay.gd"


func _draw() -> void:
	super()
	if _mapper == null:
		return
	var state := _mapper.call("get_collision_mapper_state") as Dictionary
	if bool(state.get("zone_mode", false)):
		var draft_rect := state.get("zone_draft_rect", Rect2()) as Rect2
		if draft_rect.size != Vector2.ZERO:
			draw_rect(draft_rect, Color(1.0, 0.55, 0.18, 0.22), true)
			draw_rect(draft_rect, Color(1.0, 0.70, 0.24, 1.0), false, 3.0)
			draw_string(
				ThemeDB.fallback_font,
				draft_rect.position + Vector2(8.0, 18.0),
				"EDIT: %s" % str(state.get("selected_zone", "none")),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				12,
				Color(1.0, 0.84, 0.48, 1.0)
			)
	var level := _mapper.get("_target_level") as Node
	if level == null:
		return
	var subregions := level.get_node_or_null("AuthoredSubregions")
	if subregions == null:
		return
	for region: Node in subregions.get_children():
		if not region.has_meta("authoring_rect"):
			continue
		var rect := region.get_meta("authoring_rect") as Rect2
		rect.position += Vector2(0.0, 180.0)
		draw_rect(rect, Color(0.35, 0.72, 1.0, 0.18), true)
		draw_rect(rect, Color(0.35, 0.72, 1.0, 0.82), false, 2.0)
		draw_string(
			ThemeDB.fallback_font,
			rect.position + Vector2(8.0, 18.0),
			str(region.get_meta("region_id", region.name)),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			12,
			Color(0.82, 0.92, 1.0, 0.92)
		)
