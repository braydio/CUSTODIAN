extends Node2D
class_name LevelStage

signal stage_complete(next_stage_id: StringName)

@export var stage_id: StringName = &""
@export var next_stage_id: StringName = &""

var route: Node = null
var actor: Node2D = null


func configure_stage(p_route: Node, p_actor: Node2D, _config := {}) -> void:
	route = p_route
	actor = p_actor
	if actor != null:
		var spawn := get_entry_spawn()
		if spawn != null:
			actor.global_position = spawn.global_position


func get_entry_spawn() -> Marker2D:
	return get_node_or_null("EntrySpawn") as Marker2D


func get_camera_bounds() -> Rect2:
	var bounds := get_node_or_null("CameraBounds") as ReferenceRect
	if bounds != null:
		return Rect2(bounds.global_position, bounds.size)
	return Rect2(global_position - Vector2(1200, 800), Vector2(2400, 1600))


func complete_stage(target_stage_id: StringName = &"") -> void:
	var target := target_stage_id
	if target == &"":
		target = next_stage_id
	stage_complete.emit(target)
