extends Node2D
class_name LevelRoute

@export var initial_stage_id: StringName = &""
@export var final_target_scene: PackedScene

var actor: Node2D = null
var main_map: Node = null
var main_return_position := Vector2.ZERO

var _stage_root: Node2D = null
var _current_stage: Node = null
var _stage_scenes: Dictionary = {}


func _ready() -> void:
	_stage_root = get_node_or_null("StageRoot") as Node2D
	if _stage_root == null:
		_stage_root = Node2D.new()
		_stage_root.name = "StageRoot"
		add_child(_stage_root)


func configure_connection(p_main_map: Node, p_main_return_position: Vector2) -> void:
	main_map = p_main_map
	main_return_position = p_main_return_position


func enter_from_main(p_actor: Node) -> void:
	if p_actor is Node2D:
		actor = p_actor as Node2D
	_load_stage(initial_stage_id)


func get_entry_position() -> Vector2:
	if _current_stage != null and _current_stage.has_method("get_entry_spawn"):
		var spawn := _current_stage.call("get_entry_spawn") as Marker2D
		if spawn != null:
			return spawn.global_position
	return global_position


func register_stage(stage_id: StringName, scene: PackedScene) -> void:
	_stage_scenes[stage_id] = scene


func _load_stage(stage_id: StringName) -> void:
	if _current_stage != null:
		_current_stage.queue_free()
		_current_stage = null

	if not _stage_scenes.has(stage_id):
		push_error("[LevelRoute] Missing stage scene for id: %s" % String(stage_id))
		return

	var packed := _stage_scenes[stage_id] as PackedScene
	var stage := packed.instantiate()
	_current_stage = stage
	_stage_root.add_child(stage)

	if stage.has_signal("stage_complete"):
		stage.connect("stage_complete", Callable(self, "_on_stage_complete"))

	if stage.has_method("configure_stage"):
		stage.call("configure_stage", self, actor, {})

	_refresh_camera(stage)


func _on_stage_complete(next_stage_id: StringName) -> void:
	if next_stage_id == &"front_gate":
		_enter_front_gate()
		return
	_load_stage(next_stage_id)


func _enter_front_gate() -> void:
	if final_target_scene == null:
		push_error("[LevelRoute] Missing final_target_scene")
		return

	var front_gate := final_target_scene.instantiate()
	get_parent().add_child(front_gate)

	if front_gate.has_method("configure_connection"):
		front_gate.call("configure_connection", main_map, main_return_position)

	if front_gate.has_method("enter_from_main"):
		front_gate.call("enter_from_main", actor)
	elif actor != null and front_gate.has_method("get_entry_position"):
		actor.global_position = front_gate.call("get_entry_position")

	queue_free()


func _refresh_camera(map_instance: Node) -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", map_instance)
	elif camera != null and actor != null:
		camera.global_position = actor.global_position
