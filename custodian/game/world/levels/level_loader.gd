class_name LevelLoader
extends Node

const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")

signal level_entered(level_id: StringName, instance: Node)
signal level_entry_failed(level_id: StringName, reason: String)

@export_file("*.json") var registry_index_path: String = LEVEL_REGISTRY_SCRIPT.DEFAULT_INDEX_PATH

var _registry: RefCounted
var _active_level_id: StringName = &""
var _active_level_instance: Node


func _ready() -> void:
	add_to_group("level_loader")
	ensure_registry()


func ensure_registry() -> bool:
	if _registry != null:
		return true
	_registry = LEVEL_REGISTRY_SCRIPT.new()
	if _registry.load_index(registry_index_path):
		return true
	var reason := "; ".join(_registry.get_errors())
	push_error("[LevelLoader] registry load failed: %s" % reason)
	return false


func get_definition(level_id: StringName) -> RefCounted:
	if not ensure_registry():
		return null
	return _registry.get_level(level_id)


func enter_level(level_id: StringName, actor: Node, context: Dictionary = {}) -> Node:
	var definition := get_definition(level_id)
	if definition == null:
		return _fail(level_id, "level is not registered")
	var entry_path: String = definition.call("get_entry_scene_path")
	var entry_scene := load(entry_path) as PackedScene
	if entry_scene == null:
		return _fail(level_id, "entry scene could not be loaded: %s" % entry_path)
	var instance := entry_scene.instantiate()
	if instance == null:
		return _fail(level_id, "entry scene could not be instantiated: %s" % entry_path)
	var parent: Node = context.get("parent") as Node
	if parent == null:
		parent = get_parent()
	if parent == null:
		instance.queue_free()
		return _fail(level_id, "no parent is available for the level entry scene")
	parent.add_child(instance)
	var entry_position: Variant = context.get("entry_world_position", context.get("return_world_position"))
	if instance is Node2D and entry_position is Vector2:
		(instance as Node2D).global_position = entry_position
	var main_map: Node = context.get("main_map") as Node
	var return_position: Vector2 = context.get("return_world_position", Vector2.ZERO)
	if instance.has_method("configure_connection"):
		instance.call("configure_connection", main_map, return_position)
	var target_spawn_id := _resolve_target_spawn_id(definition, context)
	if not _enter_actor_at_spawn(instance, actor, target_spawn_id):
		instance.queue_free()
		return _fail(
			level_id,
			"target spawn could not be resolved: %s" % String(target_spawn_id)
		)
	_active_level_id = level_id
	_active_level_instance = instance
	level_entered.emit(level_id, instance)
	return instance


func get_active_level_id() -> StringName:
	return _active_level_id


func get_active_level_instance() -> Node:
	if is_instance_valid(_active_level_instance):
		return _active_level_instance
	return null


func adopt_active_level(level_id: StringName, instance: Node) -> void:
	if instance == null or not is_instance_valid(instance):
		return
	_active_level_id = level_id
	_active_level_instance = instance
	level_entered.emit(level_id, instance)


func _resolve_target_spawn_id(definition: RefCounted, context: Dictionary) -> StringName:
	var requested := StringName(str(context.get("target_spawn_id", "")))
	if not requested.is_empty():
		return requested
	var ingress: Variant = definition.get("ingress")
	if ingress != null:
		return ingress.target_spawn_id
	return &""


func _enter_actor_at_spawn(instance: Node, actor: Node, spawn_id: StringName) -> bool:
	if actor == null:
		return true
	if not spawn_id.is_empty() and instance.has_method("enter_from_main_at_spawn"):
		return bool(instance.call("enter_from_main_at_spawn", actor, spawn_id))
	var spawn: Node2D = null
	if not spawn_id.is_empty():
		if instance.has_method("has_spawn") and not bool(instance.call("has_spawn", spawn_id)):
			return false
		spawn = instance.find_child(String(spawn_id), true, false) as Node2D
		if spawn == null or not (actor is Node2D):
			return false
	if instance.has_method("enter_from_main"):
		instance.call("enter_from_main", actor)
	if spawn != null:
		(actor as Node2D).global_position = spawn.global_position
	return spawn_id.is_empty() or spawn != null


func _fail(level_id: StringName, reason: String) -> Node:
	push_error("[LevelLoader] unable to enter %s: %s" % [level_id, reason])
	level_entry_failed.emit(level_id, reason)
	return null
