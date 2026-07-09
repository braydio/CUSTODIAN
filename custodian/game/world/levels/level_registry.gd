class_name LevelRegistry
extends RefCounted

const LEVEL_DEFINITION_SCRIPT := preload("res://game/world/levels/level_definition.gd")

const DEFAULT_INDEX_PATH := "res://content/levels/levels.json"

var _definitions: Dictionary = {}
var _errors := PackedStringArray()


func load_index(index_path: String = DEFAULT_INDEX_PATH) -> bool:
	_definitions.clear()
	_errors.clear()
	var index_data := _read_json_dictionary(index_path)
	if index_data.is_empty():
		return false
	if str(index_data.get("schema", "")) != "custodian.level_registry.v1":
		_errors.append("unsupported level registry schema in %s" % index_path)
		return false
	var paths: Variant = index_data.get("definitions", [])
	if not paths is Array:
		_errors.append("definitions must be an array in %s" % index_path)
		return false
	for path_value: Variant in paths:
		var definition_path := str(path_value)
		var definition_data := _read_json_dictionary(definition_path)
		if definition_data.is_empty():
			continue
		if str(definition_data.get("schema", "")) != "custodian.level_definition.v1":
			_errors.append("unsupported level definition schema in %s" % definition_path)
			continue
		var definition: RefCounted = LEVEL_DEFINITION_SCRIPT.new()
		definition.call("configure_from_dictionary", definition_data)
		var definition_errors: PackedStringArray = definition.call("validate")
		if not definition_errors.is_empty():
			for definition_error: String in definition_errors:
				_errors.append("%s: %s" % [definition_path, definition_error])
			continue
		if _definitions.has(definition.level_id):
			_errors.append("duplicate level_id %s in %s" % [definition.level_id, definition_path])
			continue
		_definitions[definition.level_id] = definition
	return _errors.is_empty() and not _definitions.is_empty()


func has_level(level_id: StringName) -> bool:
	return _definitions.has(level_id)


func get_level(level_id: StringName) -> RefCounted:
	return _definitions.get(level_id) as RefCounted


func get_level_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for level_id: Variant in _definitions.keys():
		ids.append(level_id as StringName)
	ids.sort()
	return ids


func get_errors() -> PackedStringArray:
	return _errors.duplicate()


func _read_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_errors.append("JSON file does not exist: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_errors.append("unable to open JSON file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_errors.append("JSON root must be an object: %s" % path)
		return {}
	return parsed
