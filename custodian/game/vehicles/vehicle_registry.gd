class_name VehicleRegistry
extends Node

const VehicleDefinitionScript = preload("res://game/vehicles/vehicle_definition.gd")
const DEFAULT_ARCHETYPES_PATH := "res://content/vehicles/vehicle_archetypes.json"

var vehicles: Dictionary = {}
var load_errors: PackedStringArray = PackedStringArray()


func _ready() -> void:
	if vehicles.is_empty():
		load_registry()


func load_registry(path := DEFAULT_ARCHETYPES_PATH) -> void:
	vehicles.clear()
	load_errors = PackedStringArray()
	var root := _read_json_dictionary(path)
	if root.is_empty():
		load_errors.append("Vehicle registry is empty or unreadable: %s" % path)
		return
	var vehicle_data := Dictionary(root.get("vehicles", {}))
	for vehicle_id in vehicle_data.keys():
		var data := Dictionary(vehicle_data[vehicle_id])
		if not data.has("id"):
			data["id"] = String(vehicle_id)
		var definition = VehicleDefinitionScript.from_dict(data)
		var errors: PackedStringArray = definition.validate()
		if not errors.is_empty():
			load_errors.append_array(errors)
			continue
		vehicles[definition.id] = definition


func get_vehicle(id: String):
	return vehicles.get(id, null)


func has_vehicle(id: String) -> bool:
	return vehicles.has(id)


func get_all_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for id in vehicles.keys():
		ids.append(String(id))
	ids.sort()
	return ids


func find_by_role(role: String) -> Array:
	return _find_by_field("role", role)


func find_by_chassis(chassis: String) -> Array:
	return _find_by_field("chassis", chassis)


func find_by_domain(domain: String) -> Array:
	return _find_by_field("domain", domain)


func find_by_faction(faction: String) -> Array:
	return _find_by_field("faction", faction)


func find_by_tier(tier: String) -> Array:
	return _find_by_field("tier", tier)


func find_pilotable() -> Array:
	var result: Array = []
	for definition in vehicles.values():
		if definition.is_pilotable():
			result.append(definition)
	return result


func query(filters: Dictionary) -> Array:
	var result: Array = []
	for definition in vehicles.values():
		if _matches_filters(definition, filters):
			result.append(definition)
	return result


func _find_by_field(field_name: String, expected: String) -> Array:
	var result: Array = []
	for definition in vehicles.values():
		if String(definition.get(field_name)) == expected:
			result.append(definition)
	return result


func _matches_filters(definition, filters: Dictionary) -> bool:
	for key in filters.keys():
		var expected := String(filters[key])
		if expected.is_empty():
			continue
		if key == "mobility":
			if not definition.has_mobility(expected):
				return false
		elif String(definition.get(String(key))) != expected:
			return false
	return true


static func _read_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("VehicleRegistry: missing JSON file %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed as Dictionary
	push_warning("VehicleRegistry: JSON root is not a dictionary: %s" % path)
	return {}
