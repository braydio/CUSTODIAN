class_name AuthoredLevelMapperOverlay
extends Node2D

func _draw() -> void:
	var mapper := get_parent().get_parent()
	if mapper != null and mapper.has_method("get_collision_mapper_state"):
		var state := mapper.get_collision_mapper_state() as Dictionary
		for polyline: Array in state.get("draft_polylines", []):
			for index in range(polyline.size() - 1):
				draw_line(polyline[index], polyline[index + 1], Color(0.15, 0.85, 1.0, 0.75), 3.0)

