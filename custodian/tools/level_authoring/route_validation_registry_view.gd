class_name RouteValidationRegistryView
extends RefCounted

var _levels: Dictionary = {}


func add_level_definition(definition: RefCounted) -> void:
	_levels[definition.level_id] = definition


func has_level(level_id: StringName) -> bool:
	return _levels.has(level_id)


func get_level(level_id: StringName) -> RefCounted:
	return _levels.get(level_id) as RefCounted


func level_has_spawn(level_id: StringName, spawn_id: StringName) -> bool:
	var definition := get_level(level_id)
	return definition != null and definition.spawns.has(spawn_id)
