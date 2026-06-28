extends Area2D
class_name SunderedKeepTransitionTrigger

@export_file("*.gd", "*.tscn") var target_scene_path: String = "res://game/world/sundered_keep/sundered_keep_map.gd"
@export var target_spawn_id: StringName = &""
@export var vista_controller_path: NodePath
@export var return_world_position := Vector2.ZERO

var _triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if not _is_player_body(body):
		return

	_triggered = true

	var controller := get_node_or_null(vista_controller_path)
	if controller != null and controller.has_method("play_final_fade"):
		await controller.call("play_final_fade")

	_load_target_scene(body)


func _load_target_scene(actor: Node) -> void:
	var world := get_node_or_null("/root/GameRoot/World") as Node2D
	if world == null:
		world = get_tree().current_scene as Node2D
	if world == null:
		push_error("[SunderedKeepTransitionTrigger] Missing world root")
		return

	var connected_root := world.get_node_or_null("ConnectedMaps") as Node2D
	if connected_root == null:
		connected_root = Node2D.new()
		connected_root.name = "ConnectedMaps"
		world.add_child(connected_root)

	var target := connected_root.get_node_or_null("SunderedKeepMap")
	if target == null:
		target = _instantiate_target()
		if target == null:
			push_error("[SunderedKeepTransitionTrigger] Could not instantiate target: %s" % target_scene_path)
			return
		target.name = "SunderedKeepMap"
		target.add_to_group("generated_sundered_keep_connection")
		connected_root.add_child(target)
		_configure_target_connection(target, world)

	if actor is Node2D:
		_move_actor_to_target(actor as Node2D, target)


func _instantiate_target() -> Node:
	var resource := load(target_scene_path)
	if resource is PackedScene:
		return (resource as PackedScene).instantiate()
	if resource is Script:
		var instance: Variant = (resource as Script).new()
		return instance as Node
	return null


func _move_actor_to_target(actor: Node2D, target: Node) -> void:
	var spawn: Node2D = null
	if target_spawn_id != &"":
		spawn = target.find_child(String(target_spawn_id), true, false) as Node2D
	if spawn != null:
		actor.global_position = spawn.global_position
	elif target.has_method("get_entry_position"):
		actor.global_position = target.call("get_entry_position")


func _configure_target_connection(target: Node, world: Node2D) -> void:
	if not target.has_method("configure_connection"):
		return
	var main_map := world.get_node_or_null("ProcGenRuntime")
	if main_map == null:
		main_map = world.get_node_or_null("ContractMap")
	target.call("configure_connection", main_map, return_world_position)


func _is_player_body(body: Node) -> bool:
	return body.is_in_group("player") or body.is_in_group("operator") or String(body.name) == "Operator"
