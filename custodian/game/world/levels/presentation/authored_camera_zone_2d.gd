extends Node2D
class_name AuthoredCameraZone2D

@export var profile_id: StringName
@export var region := Rect2()
@export var framing_zoom := Vector2.ONE
@export var framing_offset := Vector2.ZERO
@export_range(0.0, 2.0, 0.01) var transition_sec := 0.5
@export var priority := 0
@export var release_to_gameplay := false


func contains_global_point(global_point: Vector2) -> bool:
	return region.has_point(to_local(global_point))
