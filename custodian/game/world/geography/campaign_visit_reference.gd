class_name CampaignVisitReference
extends RefCounted

var visit_id := ""
var domain_id := ""
var entry_location_id := ""
var active_location_id := ""
var accessible_edge_ids: Array[String] = []
var last_error := ""


func configure(
	new_visit_id: String,
	new_domain_id: String,
	new_entry_location_id: String,
	new_active_location_id: String,
	new_accessible_edge_ids: Array[String],
	geography: CampaignGeographyRegistry
) -> bool:
	last_error = ""
	if not _valid_id(new_visit_id) or not _valid_id(new_domain_id) \
			or not _valid_id(new_entry_location_id) or not _valid_id(new_active_location_id):
		return _reject("invalid visit or geography identity")
	if geography == null or geography.resolve_domain(new_domain_id).is_empty():
		return _reject("visit references an unknown domain")
	if geography.resolve_location(new_domain_id, new_entry_location_id).is_empty():
		return _reject("visit entry location is unknown")
	if geography.resolve_location(new_domain_id, new_active_location_id).is_empty():
		return _reject("visit active location is unknown")
	var domain := geography.resolve_domain(new_domain_id)
	var known_edge_ids: Dictionary = {}
	for edge_variant: Variant in domain.edges:
		known_edge_ids[String((edge_variant as Dictionary).edge_id)] = true
	var normalized_edges: Array[String] = []
	for edge_id: String in new_accessible_edge_ids:
		if edge_id.is_empty() or not known_edge_ids.has(edge_id):
			return _reject("visit references an unknown edge")
		if normalized_edges.has(edge_id):
			return _reject("visit has duplicate accessible edge identity")
		normalized_edges.append(edge_id)
	normalized_edges.sort()
	visit_id = new_visit_id
	domain_id = new_domain_id
	entry_location_id = new_entry_location_id
	active_location_id = new_active_location_id
	accessible_edge_ids = normalized_edges
	return true


func to_descriptor() -> Dictionary:
	return {
		"visit_id": visit_id,
		"domain_id": domain_id,
		"entry_location_id": entry_location_id,
		"active_location_id": active_location_id,
		"accessible_edge_ids": accessible_edge_ids.duplicate(),
	}


func _reject(message: String) -> bool:
	last_error = message
	return false


static func _valid_id(value: String) -> bool:
	if value.is_empty() or value.length() > 64:
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90) \
				or (code >= 97 and code <= 122) or code == 95 or code == 45 or code == 46):
			return false
	return true
