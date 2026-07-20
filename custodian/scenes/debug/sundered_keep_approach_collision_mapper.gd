extends "res://scenes/debug/level_collision_poi_mapper.gd"


func _init() -> void:
	target_scene_path = "res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn"
	target_script_path = "res://game/world/approaches/sundered_keep/sundered_keep_approach.gd"
	target_instance_name = "SunderedKeepApproachReview"
	mapper_title = "Sundered Keep Approach Collision Mapper"
	initial_camera_position = Vector2(520.0, -20.0)
	initial_camera_zoom = Vector2(0.42, 0.42)
