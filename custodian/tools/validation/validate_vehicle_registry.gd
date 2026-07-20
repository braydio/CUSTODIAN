extends SceneTree

const VehicleDefinitionScript = preload("res://game/vehicles/vehicle_definition.gd")

const TAXONOMY_PATH := "res://content/vehicles/vehicle_taxonomy.json"
const ARCHETYPES_PATH := "res://content/vehicles/vehicle_archetypes.json"
const MOVEMENT_PROFILES_PATH := "res://content/vehicles/vehicle_movement_profiles.json"
const HARDPOINT_PROFILES_PATH := "res://content/vehicles/vehicle_hardpoint_profiles.json"
const LOADOUTS_PATH := "res://content/vehicles/vehicle_loadouts.json"
const VISUAL_KITS_PATH := "res://content/vehicles/vehicle_visual_kits.json"

var errors: PackedStringArray = PackedStringArray()


func _init() -> void:
	var taxonomy := _read_json(TAXONOMY_PATH)
	var archetypes := _read_json(ARCHETYPES_PATH)
	var movement_profiles := Dictionary(_read_json(MOVEMENT_PROFILES_PATH).get("profiles", {}))
	var hardpoint_profiles := Dictionary(_read_json(HARDPOINT_PROFILES_PATH).get("profiles", {}))
	var loadouts := Dictionary(_read_json(LOADOUTS_PATH).get("loadouts", {}))
	var visual_kits := Dictionary(_read_json(VISUAL_KITS_PATH).get("visual_kits", {}))
	_validate_registry(taxonomy, archetypes, movement_profiles, hardpoint_profiles, loadouts, visual_kits)
	if errors.is_empty():
		print("Vehicle registry validation passed.")
		quit(0)
	else:
		push_error("Vehicle registry validation failed with %d error(s):" % errors.size())
		for error in errors:
			push_error("- %s" % error)
		quit(1)


func _validate_registry(taxonomy: Dictionary, archetypes: Dictionary, movement_profiles: Dictionary, hardpoint_profiles: Dictionary, loadouts: Dictionary, visual_kits: Dictionary) -> void:
	var vehicles := Dictionary(archetypes.get("vehicles", {}))
	if vehicles.is_empty():
		errors.append("No vehicles defined in %s" % ARCHETYPES_PATH)
		return
	var seen_ids := {}
	for registry_key in vehicles.keys():
		var data := Dictionary(vehicles[registry_key])
		var id := String(data.get("id", registry_key))
		if seen_ids.has(id):
			errors.append("Duplicate vehicle id '%s'" % id)
		seen_ids[id] = true
		if id != String(registry_key):
			errors.append("Vehicle key '%s' does not match id '%s'" % [registry_key, id])
		var definition = VehicleDefinitionScript.from_dict(data)
		errors.append_array(definition.validate())
		_validate_taxonomy_value(id, "domain", definition.domain, taxonomy, "domains")
		_validate_taxonomy_value(id, "chassis", definition.chassis, taxonomy, "chassis")
		_validate_taxonomy_value(id, "role", definition.role, taxonomy, "roles")
		_validate_taxonomy_value(id, "tier", definition.tier, taxonomy, "tiers")
		_validate_taxonomy_value(id, "interaction_mode", definition.interaction_mode, taxonomy, "interaction_modes")
		for mobility_tag in definition.mobility:
			_validate_taxonomy_value(id, "mobility", mobility_tag, taxonomy, "mobility")
		if definition.movement_profile.is_empty() or not movement_profiles.has(definition.movement_profile):
			errors.append("%s references missing movement_profile '%s'" % [id, definition.movement_profile])
		if definition.hardpoint_profile.is_empty() or not hardpoint_profiles.has(definition.hardpoint_profile):
			errors.append("%s references missing hardpoint_profile '%s'" % [id, definition.hardpoint_profile])
		if definition.loadout.is_empty() or not loadouts.has(definition.loadout):
			errors.append("%s references missing loadout '%s'" % [id, definition.loadout])
		if definition.visual_kit.is_empty() or not visual_kits.has(definition.visual_kit):
			errors.append("%s references missing visual_kit '%s'" % [id, definition.visual_kit])
		if definition.spawnable and not definition.runtime_scene.is_empty() and not ResourceLoader.exists(definition.runtime_scene):
			errors.append("%s runtime.scene does not exist: %s" % [id, definition.runtime_scene])
		elif definition.spawnable and not definition.runtime_scene.is_empty():
			_validate_spawn_scene(definition)
		if definition.is_pilotable() and definition.movement_profile.is_empty():
			errors.append("%s is pilotable but has no movement_profile" % id)
		if definition.is_pilotable() and definition.seat_profile.is_empty():
			errors.append("%s is pilotable but has no seat_profile" % id)


func _validate_taxonomy_value(vehicle_id: String, field_name: String, value: String, taxonomy: Dictionary, taxonomy_key: String) -> void:
	var allowed := Array(taxonomy.get(taxonomy_key, []))
	if not allowed.has(value):
		errors.append("%s has invalid %s '%s'" % [vehicle_id, field_name, value])


func _validate_spawn_scene(definition) -> void:
	var scene := load(definition.runtime_scene)
	if not (scene is PackedScene):
		errors.append("%s runtime.scene is not a PackedScene: %s" % [definition.id, definition.runtime_scene])
		return
	var instance := (scene as PackedScene).instantiate()
	if not (instance is Node2D):
		errors.append("%s runtime.scene root is not Node2D: %s" % [definition.id, definition.runtime_scene])
	if instance != null and instance.has_method("apply_vehicle_definition"):
		instance.call("apply_vehicle_definition", definition)
	if instance != null:
		instance.free()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("Missing JSON file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed as Dictionary
	errors.append("JSON root must be an object: %s" % path)
	return {}
