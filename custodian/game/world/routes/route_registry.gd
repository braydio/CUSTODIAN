class_name RouteRegistry
extends RefCounted

const ROUTE_SCRIPT := preload("res://game/world/routes/route_definition.gd")
const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")
const DEFAULT_INDEX_PATH := "res://content/routes/routes.json"

var _routes: Dictionary = {}
var _errors := PackedStringArray()
var _level_registry: RefCounted


func load_index(index_path: String = DEFAULT_INDEX_PATH, level_registry: RefCounted = null) -> bool:
	_routes.clear()
	_errors.clear()
	_level_registry = level_registry
	if _level_registry == null:
		_level_registry = LEVEL_REGISTRY_SCRIPT.new()
		if not _level_registry.call("load_index"):
			for error: String in _level_registry.call("get_errors"):
				_errors.append("level registry: %s" % error)
			return false
	var index_data := _read_json(index_path)
	if index_data.is_empty():
		return false
	if str(index_data.get("schema", "")) != "custodian.route_registry.v1":
		_errors.append("unsupported route registry schema in %s" % index_path)
		return false
	var raw_paths: Variant = index_data.get("definitions", [])
	if not raw_paths is Array:
		_errors.append("definitions must be an array in %s" % index_path)
		return false
	var paths: Array[String] = []
	var seen_paths: Dictionary = {}
	for value: Variant in raw_paths:
		var path := str(value)
		if seen_paths.has(path):
			_errors.append("duplicate route definition path: %s" % path)
			continue
		seen_paths[path] = true
		paths.append(path)
	paths.sort()
	for path in paths:
		var data := _read_json(path)
		if data.is_empty():
			continue
		if str(data.get("schema", "")) != "custodian.route_definition.v1":
			_errors.append("unsupported route definition schema in %s" % path)
			continue
		var route: RefCounted = ROUTE_SCRIPT.new()
		route.call("configure_from_dictionary", data)
		if _routes.has(route.route_id):
			_errors.append("duplicate route_id %s in %s" % [route.route_id, path])
			continue
		var route_errors: PackedStringArray = route.call("validate", _level_registry)
		for error: String in route_errors:
			_errors.append("route %s (%s): %s" % [route.route_id, path, error])
		if route_errors.is_empty():
			_routes[route.route_id] = route
	return _errors.is_empty() and not _routes.is_empty()


func get_route(route_id: StringName) -> RefCounted:
	return _routes.get(route_id) as RefCounted


func get_route_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for route_id: Variant in _routes.keys():
		result.append(route_id as StringName)
	result.sort()
	return result


func get_routes_with_tag(tag: StringName) -> Array[RefCounted]:
	var result: Array[RefCounted] = []
	for route_id in get_route_ids():
		var route := get_route(route_id)
		if route != null and bool(route.call("has_tag", tag)):
			result.append(route)
	return result


func get_errors() -> PackedStringArray:
	return _errors.duplicate()


func _read_json(path: String) -> Dictionary:
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
