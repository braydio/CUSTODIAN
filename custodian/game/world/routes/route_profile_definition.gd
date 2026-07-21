class_name RouteProfileDefinition
extends RefCounted

var profile_id: StringName = &""
var entry_edge_id: StringName = &""
var enabled_edge_ids: Array[StringName] = []
var allow_no_exfil := false


func configure_from_dictionary(data: Dictionary) -> void:
	profile_id = StringName(str(data.get("profile_id", "")))
	entry_edge_id = StringName(str(data.get("entry_edge_id", "")))
	allow_no_exfil = bool(data.get("allow_no_exfil", false))
	enabled_edge_ids.clear()
	for value: Variant in data.get("enabled_edge_ids", []):
		enabled_edge_ids.append(StringName(str(value)))


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if profile_id.is_empty():
		errors.append("profile_id is required")
	if entry_edge_id.is_empty():
		errors.append("entry_edge_id is required")
	if enabled_edge_ids.is_empty():
		errors.append("enabled_edge_ids cannot be empty")
	var seen: Dictionary = {}
	for edge_id in enabled_edge_ids:
		if seen.has(edge_id):
			errors.append("duplicate enabled edge: %s" % edge_id)
		seen[edge_id] = true
	if not entry_edge_id.is_empty() and not enabled_edge_ids.has(entry_edge_id):
		errors.append("entry_edge_id must be enabled")
	return errors
