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
var hardpoint_profile: String = ""
var loadout: String = ""
var visual_kit: String = ""
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
	definition.hardpoint_profile = String(data.get("hardpoint_profile", ""))
	definition.loadout = String(data.get("loadout", ""))
	definition.visual_kit = String(data.get("visual_kit", ""))
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
