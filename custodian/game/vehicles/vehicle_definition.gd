class_name VehicleDefinition
extends RefCounted

const SUPPORTED_RUNTIME_DOMAINS := ["GROUND", "HOVER", "STATIC"]

var id: String = ""
var display_name_template: String = "{faction} {tier} {role} {chassis}"
var faction: String = ""
var domain: String = ""
var chassis: String = ""
var role: String = ""
var tier: String = ""
var variant: String = ""
var interaction_mode: String = ""
var mobility: Array[String] = []
var tags: Array[String] = []
var movement_profile: String = ""
var durability_profile: String = ""
var durability_profile_data: Dictionary = {}
var hardpoint_profile: String = ""
var loadout: String = ""
var visual_kit: String = ""
var restoration_profile: String = ""
var restoration_profile_data: Dictionary = {}
var runtime_scene: String = ""
var spawnable: bool = false
var pilotable: bool = false
var allow_placeholder_spawn: bool = false
var footprint: Dictionary = {}
var seat_profile: Dictionary = {}
var runtime: Dictionary = {}
var source_data: Dictionary = {}


static func from_dict(data: Dictionary):
	var definition = VehicleDefinition.new()
	definition.source_data = data.duplicate(true)
	definition.id = String(data.get("id", ""))
	definition.display_name_template = String(data.get("display_name_template", definition.display_name_template))
	definition.faction = String(data.get("faction", ""))
	definition.domain = String(data.get("domain", ""))
	definition.chassis = String(data.get("chassis", ""))
	definition.role = String(data.get("role", ""))
	definition.tier = String(data.get("tier", ""))
	definition.variant = String(data.get("variant", ""))
	definition.interaction_mode = String(data.get("interaction_mode", ""))
	definition.mobility = _string_array(data.get("mobility", []))
	definition.tags = _string_array(data.get("tags", []))
	definition.movement_profile = String(data.get("movement_profile", ""))
	definition.durability_profile = String(data.get("durability_profile", ""))
	definition.durability_profile_data = Dictionary(data.get("durability_profile_data", {})).duplicate(true)
	definition.hardpoint_profile = String(data.get("hardpoint_profile", ""))
	definition.loadout = String(data.get("loadout", ""))
	definition.visual_kit = String(data.get("visual_kit", ""))
	definition.restoration_profile = String(data.get("restoration_profile", ""))
	definition.restoration_profile_data = Dictionary(data.get("restoration_profile_data", {})).duplicate(true)
	definition.footprint = Dictionary(data.get("footprint", {})).duplicate(true)
	definition.seat_profile = Dictionary(data.get("seat_profile", {})).duplicate(true)
	definition.runtime = Dictionary(data.get("runtime", {})).duplicate(true)
	definition.runtime_scene = String(definition.runtime.get("scene", ""))
	definition.spawnable = bool(definition.runtime.get("spawnable", false))
	definition.pilotable = bool(definition.runtime.get("pilotable", false))
	definition.allow_placeholder_spawn = bool(definition.runtime.get("allow_placeholder_spawn", false))
	return definition


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for field_name in ["id", "faction", "domain", "chassis", "role", "tier", "variant", "interaction_mode"]:
		if String(source_data.get(field_name, "")).strip_edges().is_empty():
			errors.append("%s missing required field '%s'" % [id_or_placeholder(), field_name])
	if mobility.is_empty():
		errors.append("%s must define at least one mobility tag" % id_or_placeholder())
	if movement_profile.is_empty():
		errors.append("%s missing movement_profile" % id_or_placeholder())
	if durability_profile.is_empty():
		errors.append("%s missing durability_profile" % id_or_placeholder())
	elif durability_profile_data.is_empty():
		errors.append("%s references missing durability_profile '%s'" % [id_or_placeholder(), durability_profile])
	elif float(durability_profile_data.get("max_health", 0.0)) <= 0.0:
		errors.append("%s durability_profile '%s' must define positive max_health" % [id_or_placeholder(), durability_profile])
	if hardpoint_profile.is_empty():
		errors.append("%s missing hardpoint_profile" % id_or_placeholder())
	if loadout.is_empty():
		errors.append("%s missing loadout" % id_or_placeholder())
	if visual_kit.is_empty():
		errors.append("%s missing visual_kit" % id_or_placeholder())
	if spawnable and runtime_scene.is_empty():
		errors.append("%s is spawnable but has no runtime.scene" % id_or_placeholder())
	if is_pilotable() and seat_profile.is_empty():
		errors.append("%s is pilotable but has no seat_profile" % id_or_placeholder())
	if spawnable and is_pilotable() and restoration_profile.is_empty():
		errors.append("%s is spawnable and pilotable but has no restoration_profile" % id_or_placeholder())
	if not restoration_profile.is_empty() and restoration_profile_data.is_empty():
		errors.append("%s references missing restoration_profile '%s'" % [id_or_placeholder(), restoration_profile])
	if not restoration_profile_data.is_empty():
		if String(restoration_profile_data.get("initial_state", "")) != "WRECKAGE":
			errors.append("%s restoration profile '%s' must begin in WRECKAGE" % [id_or_placeholder(), restoration_profile])
		if float(restoration_profile_data.get("hold_duration", 0.0)) <= 0.0:
			errors.append("%s restoration profile '%s' must have a positive hold_duration" % [id_or_placeholder(), restoration_profile])
		var restored_fraction := float(restoration_profile_data.get("restored_health_fraction", 0.0))
		if restored_fraction <= 0.0 or restored_fraction > 1.0:
			errors.append("%s restoration profile '%s' must have restored_health_fraction in (0, 1]" % [id_or_placeholder(), restoration_profile])
		if Dictionary(restoration_profile_data.get("cost", {})).is_empty():
			errors.append("%s restoration profile '%s' must define a non-empty cost" % [id_or_placeholder(), restoration_profile])
	if spawnable and not is_runtime_supported() and not allow_placeholder_spawn:
		errors.append("%s uses unsupported runtime domain '%s' without allow_placeholder_spawn" % [id_or_placeholder(), domain])
	return errors


func get_display_name() -> String:
	var display_name := display_name_template
	var values := {
		"faction": _title_case_token(faction),
		"tier": _title_case_token(tier),
		"role": _title_case_token(role),
		"chassis": _title_case_token(chassis),
		"variant": _title_case_token(variant),
	}
	for key in values.keys():
		display_name = display_name.replace("{%s}" % key, String(values[key]))
	return " ".join(display_name.split(" ", false))


func is_pilotable() -> bool:
	return pilotable or interaction_mode == "PILOTABLE"


func is_runtime_supported() -> bool:
	return SUPPORTED_RUNTIME_DOMAINS.has(domain)


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func has_mobility(mobility_tag: String) -> bool:
	return mobility.has(mobility_tag)


func id_or_placeholder() -> String:
	return id if not id.is_empty() else "<missing-id>"


static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(String(item))
	return result


static func _title_case_token(value: String) -> String:
	var parts := value.to_lower().split("_", false)
	for index in range(parts.size()):
		parts[index] = String(parts[index]).capitalize()
	return " ".join(parts)
