class_name CampaignGeographyRegistry
extends RefCounted

const SCHEMA_VERSION := 1
const SUPPORTED_GENERATION_VERSIONS := ["geo-v1"]
const MAX_DOMAINS := 64
const MAX_LOCATIONS_PER_DOMAIN := 128
const MAX_EDGES_PER_DOMAIN := 256
const MAX_SEED := 2147483647

var last_error := ""
var _domains: Dictionary = {}


func register_domain(definition: Dictionary) -> bool:
	last_error = ""
	var candidate := _normalize_domain(definition)
	if candidate.has("_error"):
		last_error = String(candidate._error)
		return false
	var domain_id := String(candidate.domain_id)
	if _domains.has(domain_id):
		return _reject("duplicate domain identity %s" % domain_id)
	if _domains.size() >= MAX_DOMAINS:
		return _reject("domain bound exceeded")
	_domains[domain_id] = candidate
	return true


func resolve_domain(domain_id: String) -> Dictionary:
	last_error = ""
	if not _valid_id(domain_id):
		_reject("invalid domain identity")
		return {}
	if not _domains.has(domain_id):
		_reject("unknown domain identity %s" % domain_id)
		return {}
	return (_domains[domain_id] as Dictionary).duplicate(true)


func resolve_location(domain_id: String, location_id: String) -> Dictionary:
	last_error = ""
	var domain := resolve_domain(domain_id)
	if domain.is_empty():
		return {}
	if not _valid_id(location_id):
		_reject("invalid location identity")
		return {}
	var locations: Dictionary = domain.locations
	if not locations.has(location_id):
		_reject("unknown location identity %s/%s" % [domain_id, location_id])
		return {}
	return (locations[location_id] as Dictionary).duplicate(true)


func has_domain(domain_id: String) -> bool:
	return _domains.has(domain_id)


func domain_ids() -> Array[String]:
	var result: Array[String] = []
	for key: Variant in _domains.keys():
		result.append(String(key))
	result.sort()
	return result


func location_address_key(domain_id: String, location_id: String) -> String:
	if not _valid_id(domain_id) or not _valid_id(location_id):
		return ""
	return _component(domain_id) + _component(location_id)


static func _normalize_domain(definition: Dictionary) -> Dictionary:
	var domain_variant: Variant = definition.get("domain_id", "")
	var seed_variant: Variant = definition.get("domain_seed")
	var generation_variant: Variant = definition.get("generation_version", "")
	if typeof(domain_variant) != TYPE_STRING or typeof(generation_variant) != TYPE_STRING:
		return _error("domain identity and generation version must be strings")
	var domain_id := String(domain_variant)
	var generation_version := String(generation_variant)
	if not _valid_id(domain_id):
		return _error("invalid domain identity")
	if typeof(seed_variant) != TYPE_INT or int(seed_variant) < 0 or int(seed_variant) > MAX_SEED:
		return _error("domain seed must be a bounded non-negative integer")
	if not _valid_id(generation_version) or not SUPPORTED_GENERATION_VERSIONS.has(generation_version):
		return _error("unsupported generation version")
	var schema_variant: Variant = definition.get("schema_version", -1)
	if typeof(schema_variant) != TYPE_INT or int(schema_variant) != SCHEMA_VERSION:
		return _error("unsupported geography schema version")
	var source_locations: Variant = definition.get("locations", [])
	if not source_locations is Array or source_locations.is_empty() or source_locations.size() > MAX_LOCATIONS_PER_DOMAIN:
		return _error("location list is empty or outside its supported bound")
	var locations: Dictionary = {}
	for source_variant: Variant in source_locations:
		if not source_variant is Dictionary:
			return _error("location descriptor must be a dictionary")
		var location_variant: Variant = source_variant.get("location_id", "")
		if typeof(location_variant) != TYPE_STRING:
			return _error("location identity must be a string")
		var location_id := String(location_variant)
		if not _valid_id(location_id):
			return _error("invalid location identity")
		if locations.has(location_id):
			return _error("duplicate location identity %s/%s" % [domain_id, location_id])
		locations[location_id] = {"location_id": location_id, "neighbors": []}
	var source_edges: Variant = definition.get("edges", [])
	if not source_edges is Array or source_edges.size() > MAX_EDGES_PER_DOMAIN:
		return _error("edge list is outside its supported bound")
	var directed_edges: Dictionary = {}
	var edge_records: Dictionary = {}
	var adjacency: Dictionary = {}
	for location_id: String in locations:
		adjacency[location_id] = []
	for edge_variant: Variant in source_edges:
		if not edge_variant is Dictionary:
			return _error("edge descriptor must be a dictionary")
		var edge_id_variant: Variant = edge_variant.get("edge_id", "")
		var from_variant: Variant = edge_variant.get("from_location_id", "")
		var to_variant: Variant = edge_variant.get("to_location_id", "")
		if typeof(edge_id_variant) != TYPE_STRING or typeof(from_variant) != TYPE_STRING or typeof(to_variant) != TYPE_STRING:
			return _error("edge and endpoint identities must be strings")
		var edge_id := String(edge_id_variant)
		var from_id := String(from_variant)
		var to_id := String(to_variant)
		var directed_variant: Variant = edge_variant.get("directed", false)
		if not _valid_id(edge_id) or not _valid_id(from_id) or not _valid_id(to_id):
			return _error("invalid edge or endpoint identity")
		if typeof(directed_variant) != TYPE_BOOL:
			return _error("edge directed flag must be boolean")
		if from_id == to_id:
			return _error("self edges are not supported")
		if not locations.has(from_id) or not locations.has(to_id):
			return _error("edge references unknown location %s" % edge_id)
		var arc_key := _arc_key(edge_id, from_id, to_id)
		if directed_edges.has(arc_key):
			return _error("duplicate edge mapping %s" % edge_id)
		directed_edges[arc_key] = {
			"edge_id": edge_id,
			"from": from_id,
			"to": to_id,
			"directed": bool(directed_variant),
		}
		if not edge_records.has(edge_id):
			edge_records[edge_id] = []
		(edge_records[edge_id] as Array).append(arc_key)
		(adjacency[from_id] as Array).append({
			"edge_id": edge_id,
			"target_location_id": to_id,
			"directed": bool(directed_variant),
		})
	var edge_ids: Array[String] = []
	for edge_id_variant: Variant in edge_records.keys():
		edge_ids.append(String(edge_id_variant))
	edge_ids.sort()
	for edge_id: String in edge_ids:
		var arcs: Array = edge_records[edge_id]
		if arcs.size() == 1:
			var only_arc: Dictionary = directed_edges[arcs[0]]
			if not bool(only_arc.directed):
				return _error("undirected edge %s must have one reciprocal mapping" % edge_id)
		elif arcs.size() == 2:
			var first_arc: Dictionary = directed_edges[arcs[0]]
			var second_arc: Dictionary = directed_edges[arcs[1]]
			if bool(first_arc.directed) or bool(second_arc.directed) \
					or first_arc.from != second_arc.to or first_arc.to != second_arc.from:
				return _error("duplicate edge identity %s is not one reciprocal undirected edge" % edge_id)
		else:
			return _error("duplicate edge identity %s" % edge_id)
	for location_id: String in locations:
		var neighbors: Array = adjacency[location_id]
		neighbors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if a.edge_id == b.edge_id:
				return a.target_location_id < b.target_location_id
			return a.edge_id < b.edge_id
		)
		locations[location_id] = {
			"schema_version": SCHEMA_VERSION,
			"domain_id": domain_id,
			"location_id": location_id,
			"domain_seed": int(seed_variant),
			"generation_version": generation_version,
			"locality_seed": _locality_seed(int(seed_variant), domain_id, location_id, generation_version),
			"neighbors": neighbors,
		}
	var ordered_ids: Array[String] = []
	for location_id: Variant in locations.keys():
		ordered_ids.append(String(location_id))
	ordered_ids.sort()
	var ordered_locations: Dictionary = {}
	for location_id: String in ordered_ids:
		ordered_locations[location_id] = locations[location_id]
	var ordered_edges: Array[Dictionary] = []
	for edge_variant: Variant in source_edges:
		ordered_edges.append((edge_variant as Dictionary).duplicate(true))
	ordered_edges.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.edge_id == b.edge_id:
			if a.from_location_id == b.from_location_id:
				return a.to_location_id < b.to_location_id
			return a.from_location_id < b.from_location_id
		return a.edge_id < b.edge_id
	)
	return {
		"schema_version": SCHEMA_VERSION,
		"domain_id": domain_id,
		"domain_seed": int(seed_variant),
		"generation_version": generation_version,
		"location_ids": ordered_ids,
		"locations": ordered_locations,
		"edges": ordered_edges,
	}


static func _locality_seed(domain_seed: int, domain_id: String, location_id: String, generation_version: String) -> int:
	var payload := "%d:%s%s%s" % [domain_seed, _component(domain_id), _component(location_id), _component(generation_version)]
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(payload.to_utf8_buffer())
	var digest := context.finish()
	var value := 0
	for index in 4:
		value = (value << 8) | int(digest[index])
	return value


static func _component(value: String) -> String:
	return "%d:%s" % [value.to_utf8_buffer().size(), value]


static func _arc_key(edge_id: String, from_id: String, to_id: String) -> String:
	return _component(edge_id) + _component(from_id) + _component(to_id)


static func _valid_id(value: String) -> bool:
	if value.is_empty() or value.length() > 64:
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90) \
				or (code >= 97 and code <= 122) or code == 95 or code == 45 or code == 46):
			return false
	return true


static func _error(message: String) -> Dictionary:
	return {"_error": message}


func _reject(message: String) -> bool:
	last_error = message
	return false
