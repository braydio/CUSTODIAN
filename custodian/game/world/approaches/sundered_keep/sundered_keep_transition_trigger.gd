extends Area2D
class_name SunderedKeepTransitionTrigger

@export_file("*.gd", "*.tscn") var target_scene_path: String = "res://game/world/sundered_keep/sundered_keep_map.gd"
@export var target_node_name: StringName = &"SunderedKeepMap"
@export var target_level_id: StringName = &"sundered_keep_front_gate"
@export var target_spawn_id: StringName = &""
@export var vista_controller_path: NodePath
@export var connection_owner_path: NodePath
@export var source_scene_path: NodePath = NodePath("..")
@export var return_world_position := Vector2.ZERO
@export var deactivate_source_on_transition := true
@export var free_source_on_transition := true

var _triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if not _is_player_body(body):
		return

	transition_actor(body)


func enter_from_main(actor: Node) -> void:
	transition_actor(actor)


func reset_transition() -> void:
	_triggered = false


func transition_actor(actor: Node) -> void:
	if _triggered or actor == null or not is_instance_valid(actor):
		return
	if not _is_player_body(actor):
		return
	_triggered = true
	var controller := get_node_or_null(vista_controller_path)
	if controller != null and controller.has_method("play_final_fade"):
		await controller.call("play_final_fade")
	_load_target_scene(actor)


func _load_target_scene(actor: Node) -> void:
	var world := get_node_or_null("/root/GameRoot/World") as Node2D
	if world == null:
		world = get_tree().current_scene as Node2D
	if world == null:
		push_error("[SunderedKeepTransitionTrigger] Missing world root")
		return

	_set_world_branch_visible(world.get_node_or_null("ProcGenRuntime"), false)
	var connected_root := world.get_node_or_null("ConnectedMaps") as Node2D
	if connected_root == null:
		connected_root = Node2D.new()
		connected_root.name = "ConnectedMaps"
		world.add_child(connected_root)
	_set_world_branch_visible(connected_root, true)

	var resolved_target_name := String(target_node_name)
	if resolved_target_name.is_empty():
		resolved_target_name = "SunderedKeepMap"
	var target := connected_root.get_node_or_null(resolved_target_name)
	if target == null:
		target = _instantiate_target()
		if target == null:
			push_error("[SunderedKeepTransitionTrigger] Could not instantiate target: %s" % target_scene_path)
			return
		target.name = resolved_target_name
		target.add_to_group("generated_sundered_keep_connection")
		connected_root.add_child(target)
	else:
		_set_world_branch_visible(target, true)
	_configure_target_connection(target, world)

	if actor is Node2D:
		_move_actor_to_target(actor as Node2D, target)
	_adopt_level_loader_target(target)
	_deactivate_source_scene()


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
	var main_map: Node = null
	if not connection_owner_path.is_empty():
		main_map = get_node_or_null(connection_owner_path)
	if main_map == null:
		main_map = world.get_node_or_null("ProcGenRuntime")
	if main_map == null:
		main_map = world.get_node_or_null("ContractMap")
	target.call("configure_connection", main_map, return_world_position)


func _adopt_level_loader_target(target: Node) -> void:
	if get_tree() == null:
		return
	var loaders := get_tree().get_nodes_in_group("level_loader")
	if loaders.is_empty():
		return
	var loader := loaders[0] as Node
	if loader != null and loader.has_method("adopt_active_level"):
		loader.call("adopt_active_level", target_level_id, target)


func _is_player_body(body: Node) -> bool:
	return body.is_in_group("player") or body.is_in_group("operator") or String(body.name) == "Operator"


func _set_world_branch_visible(branch: Node, value: bool) -> void:
	if branch == null:
		return
	if branch is CanvasItem:
		(branch as CanvasItem).visible = value
	branch.process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED


func _deactivate_source_scene() -> void:
	if not deactivate_source_on_transition:
		return
	var source := get_node_or_null(source_scene_path)
	if source == null:
		source = get_parent()
	if source == null:
		return
	if source is CanvasItem:
		(source as CanvasItem).visible = false
	source.process_mode = Node.PROCESS_MODE_DISABLED
	if free_source_on_transition:
		source.queue_free()
