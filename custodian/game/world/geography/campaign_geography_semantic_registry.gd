class_name CampaignGeographySemanticRegistry
extends RefCounted

## A deterministic semantic projection over existing B1 geography and F02 levels.
## It records intended site sources and crossings; it never stages or generates them.

const SEMANTIC_SCHEMA_VERSION := 1
const SEMANTIC_GENERATION_VERSION := "site-v1"
const LEVEL_DEFINITION_SCHEMA := "custodian.level_definition.v1"
const MAX_DOMAINS := 64
const MAX_SITES_PER_DOMAIN := 128
const MAX_EDGE_BINDINGS_PER_SITE := 64
const MAX_SEMANTIC_ITEMS_PER_SITE := 32
const MAX_ID_LENGTH := 64
const SOURCE_KINDS := ["authored_level", "generated_region"]
const CROSSING_KINDS := ["road", "trail", "gate", "water", "authored_transit"]
const LANDMARK_ROLES := ["dominant", "supporting", "local"]
const VISTA_LAYERS := ["far", "approach", "near"]
const MYSTERY_ORIGINS := ["authored_canon", "unknown_origin"]
const MYSTERY_REVEAL_POLICIES := ["withheld", "site_visit", "later_discovery"]

var last_error := ""
var _domains: Dictionary = {}


## Atomically replaces one Domain's complete semantic plan.
## `level_registry` must be the existing F02 LevelRegistry (or a compatible adapter
## that delegates to its definitions), never an independent geography/source table.
func register_domain_plan(
	geography: CampaignGeographyRegistry,
	level_registry: RefCounted,
	definition: Dictionary
) -> bool:
	last_error = ""
	var candidate := _normalize_domain_plan(geography, level_registry, definition)
	if candidate.has("_error"):
		last_error = String(candidate._error)
		return false
	var domain_id := String(candidate.domain_id)
	if not _domains.has(domain_id) and _domains.size() >= MAX_DOMAINS:
		return _reject("semantic Domain bound exceeded")
	_domains[domain_id] = candidate
	return true


func resolve_domain(domain_id: String) -> Dictionary:
	last_error = ""
	if not _valid_id(domain_id):
		_reject("invalid semantic Domain identity")
		return {}
	if not _domains.has(domain_id):
		_reject("unknown semantic Domain identity %s" % domain_id)
		return {}
	return (_domains[domain_id] as Dictionary).duplicate(true)


func resolve_site(domain_id: String, location_id: String) -> Dictionary:
	last_error = ""
	if not _valid_id(domain_id) or not _valid_id(location_id):
		_reject("invalid semantic site address")
		return {}
	var domain := resolve_domain(domain_id)
	if domain.is_empty():
		return {}
	var sites: Dictionary = domain.sites
	if not sites.has(location_id):
		_reject("unknown semantic site address %s/%s" % [domain_id, location_id])
		return {}
	return (sites[location_id] as Dictionary).duplicate(true)


func domain_ids() -> Array[String]:
	var result: Array[String] = []
	for domain_id: Variant in _domains.keys():
		result.append(String(domain_id))
	result.sort()
	return result


static func _normalize_domain_plan(
	geography: CampaignGeographyRegistry,
	level_registry: RefCounted,
	definition: Dictionary
) -> Dictionary:
	if geography == null:
		return _error("B1 geography registry is required")
	if not _is_level_registry(level_registry):
		return _error("F02 LevelRegistry is required")
	var domain_id_variant: Variant = definition.get("domain_id", "")
	var schema_variant: Variant = definition.get("schema_version", -1)
	var semantic_version_variant: Variant = definition.get("semantic_generation_version", "")
	if typeof(domain_id_variant) != TYPE_STRING or not _valid_id(String(domain_id_variant)):
		return _error("invalid semantic Domain identity")
	if typeof(schema_variant) != TYPE_INT or int(schema_variant) != SEMANTIC_SCHEMA_VERSION:
		return _error("unsupported semantic schema version")
	if typeof(semantic_version_variant) != TYPE_STRING \
			or String(semantic_version_variant) != SEMANTIC_GENERATION_VERSION:
		return _error("unsupported semantic generation version")
	var domain_id := String(domain_id_variant)
	var geography_domain := geography.resolve_domain(domain_id)
	if geography_domain.is_empty():
		return _error("semantic plan references unknown B1 Domain %s: %s" % [domain_id, geography.last_error])
	var generation_variant: Variant = definition.get("geography_generation_version", "")
	if typeof(generation_variant) != TYPE_STRING \
			or String(generation_variant) != String(geography_domain.generation_version):
		return _error("semantic geography generation version is stale")
	var source_sites: Variant = definition.get("sites", [])
	if not source_sites is Array or source_sites.is_empty() \
			or source_sites.size() > MAX_SITES_PER_DOMAIN:
		return _error("semantic site list is empty or outside its supported bound")
	var canonical_locations: Dictionary = geography_domain.locations
	var normalized_sites: Dictionary = {}
	for site_variant: Variant in source_sites:
		if not site_variant is Dictionary:
			return _error("semantic site descriptor must be a dictionary")
		var site := _normalize_site(
			geography,
			level_registry,
			domain_id,
			canonical_locations,
			site_variant as Dictionary
		)
		if site.has("_error"):
			return site
		var location_id := String(site.location_id)
		if normalized_sites.has(location_id):
			return _error("duplicate semantic site address %s/%s" % [domain_id, location_id])
		normalized_sites[location_id] = site
	var cross_site_error := _validate_cross_site_bindings(normalized_sites)
	if not cross_site_error.is_empty():
		return _error(cross_site_error)
	var ordered_site_ids: Array[String] = []
	for location_id_variant: Variant in normalized_sites.keys():
		ordered_site_ids.append(String(location_id_variant))
	ordered_site_ids.sort()
	var ordered_sites: Dictionary = {}
	for location_id: String in ordered_site_ids:
		ordered_sites[location_id] = normalized_sites[location_id]
	return {
		"schema_version": SEMANTIC_SCHEMA_VERSION,
		"semantic_generation_version": SEMANTIC_GENERATION_VERSION,
		"domain_id": domain_id,
		"geography_schema_version": int(geography_domain.schema_version),
		"geography_generation_version": String(geography_domain.generation_version),
		"location_ids": ordered_site_ids,
		"sites": ordered_sites,
	}


static func _normalize_site(
	geography: CampaignGeographyRegistry,
	level_registry: RefCounted,
	domain_id: String,
	canonical_locations: Dictionary,
	input: Dictionary
) -> Dictionary:
	var location_variant: Variant = input.get("location_id", "")
	if typeof(location_variant) != TYPE_STRING or not _valid_id(String(location_variant)):
		return _error("invalid semantic location identity")
	var location_id := String(location_variant)
	if not canonical_locations.has(location_id):
		return _error("semantic site references unknown B1 location %s/%s" % [domain_id, location_id])
	var location: Dictionary = geography.resolve_location(domain_id, location_id)
	if location.is_empty():
		return _error("semantic site could not resolve B1 location %s/%s" % [domain_id, location_id])
	var locality_seed_variant: Variant = input.get("locality_seed", -1)
	if typeof(locality_seed_variant) != TYPE_INT \
			or int(locality_seed_variant) != int(location.locality_seed):
		return _error("semantic locality seed is stale for %s/%s" % [domain_id, location_id])
	var source_variant: Variant = input.get("source", {})
	if not source_variant is Dictionary:
		return _error("semantic F02 source reference must be a dictionary")
	var source_result := _resolve_source(level_registry, source_variant as Dictionary)
	if source_result.has("_error"):
		return source_result
	var override_variant: Variant = input.get("authored_override", {})
	if not override_variant is Dictionary:
		return _error("authored override must be a dictionary")
	var source_descriptor: Dictionary = source_result
	var authored_override: Dictionary = {}
	if not (override_variant as Dictionary).is_empty():
		if String(source_descriptor.kind) != "generated_region":
			return _error("authored override contradicts a non-generated F02 source")
		var override_result := _resolve_source(level_registry, override_variant as Dictionary)
		if override_result.has("_error"):
			return override_result
		if String(override_result.kind) != "authored_level":
			return _error("authored override must resolve to an authored F02 level")
		authored_override = override_result
	var effective_source: Dictionary = authored_override if not authored_override.is_empty() else source_descriptor
	var semantic_tags_result := _normalize_id_array(input.get("semantic_tags", []), "semantic tag", MAX_SEMANTIC_ITEMS_PER_SITE)
	if semantic_tags_result.has("_error"):
		return semantic_tags_result
	var site_purpose_result := _optional_id(input.get("site_purpose", ""), "site purpose")
	if site_purpose_result.has("_error"):
		return site_purpose_result
	var edge_result := _normalize_edge_bindings(
		domain_id,
		location_id,
		location,
		input.get("edge_bindings", [])
	)
	if edge_result.has("_error"):
		return edge_result
	var encounter_result := _normalize_encounter_cues(input.get("encounter_cues", []))
	if encounter_result.has("_error"):
		return encounter_result
	var landmark_result := _normalize_landmarks(
		location_id,
		input.get("landmarks", []),
		edge_result.values
	)
	if landmark_result.has("_error"):
		return landmark_result
	var vista_result := _normalize_vista_intents(input.get("spatial_intents", []), landmark_result.values)
	if vista_result.has("_error"):
		return vista_result
	var mystery_result := _normalize_mysteries(
		level_registry,
		effective_source,
		input.get("mysteries", [])
	)
	if mystery_result.has("_error"):
		return mystery_result
	var ruin_result := _normalize_ruin_reserves(
		level_registry,
		effective_source,
		input.get("ruin_reserves", [])
	)
	if ruin_result.has("_error"):
		return ruin_result
	return {
		"domain_id": domain_id,
		"location_id": location_id,
		"address_key": geography.location_address_key(domain_id, location_id),
		"geography_schema_version": int(location.schema_version),
		"geography_generation_version": String(location.generation_version),
		"locality_seed": int(location.locality_seed),
		"source": source_descriptor,
		"source_precedence": "authored_override" if not authored_override.is_empty() else "base_source",
		"authored_override": authored_override,
		"effective_source": effective_source.duplicate(true),
		"site_purpose": String(site_purpose_result.value),
		"semantic_tags": semantic_tags_result.values,
		"edge_bindings": edge_result.values,
		"encounter_cues": encounter_result.values,
		"landmarks": landmark_result.values,
		"spatial_intents": vista_result.values,
		"mysteries": mystery_result.values,
		"ruin_reserves": ruin_result.values,
	}


static func _resolve_source(level_registry: RefCounted, input: Dictionary) -> Dictionary:
	var kind_variant: Variant = input.get("kind", "")
	var level_id_variant: Variant = input.get("level_id", "")
	if typeof(kind_variant) != TYPE_STRING or not SOURCE_KINDS.has(String(kind_variant)):
		return _error("unsupported F02 source kind")
	if typeof(level_id_variant) != TYPE_STRING or not _valid_id(String(level_id_variant)):
		return _error("invalid F02 level reference")
	var kind := String(kind_variant)
	var level_id := StringName(String(level_id_variant))
	if not bool(level_registry.call("has_level", level_id)):
		return _error("unknown F02 level reference %s" % level_id)
	var level: RefCounted = level_registry.call("get_level", level_id) as RefCounted
	if level == null or not level.has_method("get_runtime_kind"):
		return _error("F02 level reference has no runtime-kind contract")
	var runtime_kind := String(level.call("get_runtime_kind"))
	if kind == "authored_level":
		if runtime_kind != "authored_scene":
			return _error("F02 source kind mismatch: expected authored_level")
		if input.has("profile_id"):
			return _error("authored F02 source cannot declare a generated profile")
		var scene_path := String(level.call("get_entry_scene_path"))
		if scene_path.is_empty():
			return _error("authored F02 level has no entry scene")
		return {
			"kind": kind,
			"level_id": String(level_id),
			"definition_schema": LEVEL_DEFINITION_SCHEMA,
			"scene_path": scene_path,
		}
	if runtime_kind != "generated_region":
		return _error("F02 source kind mismatch: expected generated_region")
	if not level.has_method("get_generated_region_request"):
		return _error("generated F02 level has no source request contract")
	var request: Dictionary = level.call("get_generated_region_request")
	var profile_id := String(request.get("profile_id", ""))
	var requested_profile_variant: Variant = input.get("profile_id", "")
	if not _valid_id(profile_id) or typeof(requested_profile_variant) != TYPE_STRING \
			or String(requested_profile_variant) != profile_id:
		return _error("generated F02 profile reference is unknown or mismatched")
	var scene_path := String(request.get("scene_path", ""))
	if scene_path.is_empty():
		return _error("generated F02 source has no scene reference")
	return {
		"kind": kind,
		"level_id": String(level_id),
		"definition_schema": LEVEL_DEFINITION_SCHEMA,
		"profile_id": profile_id,
		"source_seed": int(request.get("seed", 0)),
		"scene_path": scene_path,
	}


static func _normalize_edge_bindings(
	domain_id: String,
	location_id: String,
	location: Dictionary,
	input: Variant
) -> Dictionary:
	if not input is Array or (input as Array).size() > MAX_EDGE_BINDINGS_PER_SITE:
		return _error("edge binding list is outside its supported bound")
	var neighbors: Dictionary = {}
	for neighbor_variant: Variant in location.neighbors:
		var neighbor: Dictionary = neighbor_variant
		var key := _edge_target_key(String(neighbor.edge_id), String(neighbor.target_location_id))
		neighbors[key] = neighbor
	var values: Array[Dictionary] = []
	var seen: Dictionary = {}
	for binding_variant: Variant in input:
		if not binding_variant is Dictionary:
			return _error("edge binding must be a dictionary")
		var binding: Dictionary = binding_variant
		var edge_id_variant: Variant = binding.get("edge_id", "")
		var target_variant: Variant = binding.get("target_location_id", "")
		var crossing_variant: Variant = binding.get("crossing_kind", "")
		if typeof(edge_id_variant) != TYPE_STRING or not _valid_id(String(edge_id_variant)) \
				or typeof(target_variant) != TYPE_STRING or not _valid_id(String(target_variant)):
			return _error("invalid canonical edge binding identity")
		if typeof(crossing_variant) != TYPE_STRING or not CROSSING_KINDS.has(String(crossing_variant)):
			return _error("unsupported semantic crossing kind")
		var edge_id := String(edge_id_variant)
		var target_location_id := String(target_variant)
		var key := _edge_target_key(edge_id, target_location_id)
		if seen.has(key):
			return _error("duplicate semantic edge binding %s" % edge_id)
		seen[key] = true
		if not neighbors.has(key):
			return _error("semantic edge binding is not a canonical B1 neighbor %s/%s/%s" % [domain_id, location_id, edge_id])
		var canonical_neighbor: Dictionary = neighbors[key]
		var is_directed := bool(canonical_neighbor.directed)
		if is_directed and String(crossing_variant) != "authored_transit":
			return _error("directed B1 transit must remain authored_transit")
		if not is_directed and String(crossing_variant) == "authored_transit":
			return _error("authored_transit requires a directed B1 edge")
		var ingress_status_variant: Variant = binding.get("ingress_status", "planned")
		if typeof(ingress_status_variant) != TYPE_STRING or String(ingress_status_variant) != "planned":
			return _error("F02 ingress proof is absent; semantic ingress must remain planned")
		var exit_ref_result := _optional_id(binding.get("physical_exit_ref", ""), "physical exit reference")
		if exit_ref_result.has("_error"):
			return exit_ref_result
		var entry_ref_result := _optional_id(binding.get("physical_entry_ref", ""), "physical entry reference")
		if entry_ref_result.has("_error"):
			return entry_ref_result
		values.append({
			"edge_id": edge_id,
			"from_location_id": location_id,
			"target_location_id": target_location_id,
			"directed": is_directed,
			"crossing_kind": String(crossing_variant),
			"physical_exit_ref": String(exit_ref_result.value),
			"physical_entry_ref": String(entry_ref_result.value),
			"ingress_status": "planned",
		})
	values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.edge_id == b.edge_id:
			return a.target_location_id < b.target_location_id
		return a.edge_id < b.edge_id
	)
	return {"values": values}


static func _validate_cross_site_bindings(sites: Dictionary) -> String:
	var declared: Dictionary = {}
	for location_variant: Variant in sites.keys():
		var site: Dictionary = sites[location_variant]
		for binding_variant: Variant in site.edge_bindings:
			var binding: Dictionary = binding_variant
			var target_id := String(binding.target_location_id)
			if not sites.has(target_id):
				continue
			var key := _edge_target_key(String(binding.edge_id), String(binding.from_location_id))
			declared[key] = binding
	for key_variant: Variant in declared.keys():
		var binding: Dictionary = declared[key_variant]
		if bool(binding.directed):
			continue
		var reverse_key := _edge_target_key(String(binding.edge_id), String(binding.target_location_id))
		if not declared.has(reverse_key):
			continue
		var reverse: Dictionary = declared[reverse_key]
		if String(binding.crossing_kind) != String(reverse.crossing_kind):
			return "reciprocal B1 edge %s has contradictory semantic crossing kinds" % binding.edge_id
		if not String(binding.physical_exit_ref).is_empty() \
				and not String(reverse.physical_entry_ref).is_empty() \
				and String(binding.physical_exit_ref) != String(reverse.physical_entry_ref):
			return "reciprocal B1 edge %s has mismatched physical ingress references" % binding.edge_id
		if not String(binding.physical_entry_ref).is_empty() \
				and not String(reverse.physical_exit_ref).is_empty() \
				and String(binding.physical_entry_ref) != String(reverse.physical_exit_ref):
			return "reciprocal B1 edge %s has mismatched physical egress references" % binding.edge_id
	return ""


static func _normalize_encounter_cues(input: Variant) -> Dictionary:
	if not input is Array or (input as Array).size() > MAX_SEMANTIC_ITEMS_PER_SITE:
		return _error("encounter cue list is outside its supported bound")
	var values: Array[Dictionary] = []
	var seen: Dictionary = {}
	for cue_variant: Variant in input:
		if not cue_variant is Dictionary:
			return _error("encounter cue must be a dictionary")
		var cue: Dictionary = cue_variant
		var motif_result := _required_id(cue.get("motif_id", ""), "encounter motif")
		if motif_result.has("_error"):
			return motif_result
		var motif_id := String(motif_result.value)
		if seen.has(motif_id):
			return _error("duplicate encounter motif reference %s" % motif_id)
		seen[motif_id] = true
		if String(cue.get("truth_state", "unresolved")) != "unresolved" \
				or not String(cue.get("truth_source_ref", "")).is_empty():
			return _error("encounter cue requires an unavailable F02 truth proof; keep it unresolved")
		values.append({"motif_id": motif_id, "truth_state": "unresolved", "truth_source_ref": ""})
	values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.motif_id < b.motif_id)
	return {"values": values}


static func _normalize_landmarks(location_id: String, input: Variant, edge_bindings: Array) -> Dictionary:
	if not input is Array or (input as Array).size() > MAX_SEMANTIC_ITEMS_PER_SITE:
		return _error("landmark list is outside its supported bound")
	var available_edges: Dictionary = {}
	for binding_variant: Variant in edge_bindings:
		var binding: Dictionary = binding_variant
		available_edges[String(binding.edge_id)] = true
	var values: Array[Dictionary] = []
	var seen: Dictionary = {}
	for landmark_variant: Variant in input:
		if not landmark_variant is Dictionary:
			return _error("landmark descriptor must be a dictionary")
		var landmark: Dictionary = landmark_variant
		var id_result := _required_id(landmark.get("landmark_id", ""), "landmark")
		if id_result.has("_error"):
			return id_result
		var landmark_id := String(id_result.value)
		if seen.has(landmark_id):
			return _error("duplicate landmark reference %s" % landmark_id)
		seen[landmark_id] = true
		var role_variant: Variant = landmark.get("role", "")
		if typeof(role_variant) != TYPE_STRING or not LANDMARK_ROLES.has(String(role_variant)):
			return _error("unsupported landmark hierarchy role")
		var approach_result := _normalize_id_array(landmark.get("approach_edge_ids", []), "landmark approach edge", MAX_EDGE_BINDINGS_PER_SITE)
		if approach_result.has("_error"):
			return approach_result
		for edge_id: String in approach_result.values:
			if not available_edges.has(edge_id):
				return _error("landmark approach references an undeclared B1 edge %s at %s" % [edge_id, location_id])
		values.append({
			"landmark_id": landmark_id,
			"role": String(role_variant),
			"location_id": location_id,
			"approach_edge_ids": approach_result.values,
		})
	values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.landmark_id < b.landmark_id)
	return {"values": values}


static func _normalize_vista_intents(input: Variant, landmarks: Array) -> Dictionary:
	if not input is Array or (input as Array).size() > MAX_SEMANTIC_ITEMS_PER_SITE:
		return _error("spatial intent list is outside its supported bound")
	var known_landmarks: Dictionary = {}
	for landmark_variant: Variant in landmarks:
		var landmark: Dictionary = landmark_variant
		known_landmarks[String(landmark.landmark_id)] = true
	var values: Array[Dictionary] = []
	var seen: Dictionary = {}
	for intent_variant: Variant in input:
		if not intent_variant is Dictionary:
			return _error("spatial intent must be a dictionary")
		var intent: Dictionary = intent_variant
		var id_result := _required_id(intent.get("landmark_id", ""), "spatial landmark")
		if id_result.has("_error"):
			return id_result
		var landmark_id := String(id_result.value)
		if not known_landmarks.has(landmark_id):
			return _error("spatial intent references undeclared landmark %s" % landmark_id)
		var layer_variant: Variant = intent.get("layer", "")
		if typeof(layer_variant) != TYPE_STRING or not VISTA_LAYERS.has(String(layer_variant)):
			return _error("unsupported spatial compression layer")
		var key := "%s|%s" % [landmark_id, String(layer_variant)]
		if seen.has(key):
			return _error("duplicate spatial intent reference %s" % key)
		seen[key] = true
		var constraint_result := _required_id(intent.get("intent_ref", ""), "spatial intent reference")
		if constraint_result.has("_error"):
			return constraint_result
		values.append({"landmark_id": landmark_id, "layer": String(layer_variant), "intent_ref": String(constraint_result.value)})
	values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.landmark_id == b.landmark_id:
			return a.layer < b.layer
		return a.landmark_id < b.landmark_id
	)
	return {"values": values}


static func _normalize_mysteries(level_registry: RefCounted, source: Dictionary, input: Variant) -> Dictionary:
	if not input is Array or (input as Array).size() > MAX_SEMANTIC_ITEMS_PER_SITE:
		return _error("mystery reference list is outside its supported bound")
	var values: Array[Dictionary] = []
	var seen: Dictionary = {}
	for mystery_variant: Variant in input:
		if not mystery_variant is Dictionary:
			return _error("mystery reference must be a dictionary")
		var mystery: Dictionary = mystery_variant
		var id_result := _required_id(mystery.get("mystery_ref", ""), "mystery")
		if id_result.has("_error"):
			return id_result
		var mystery_id := String(id_result.value)
		if seen.has(mystery_id):
			return _error("duplicate mystery reference %s" % mystery_id)
		seen[mystery_id] = true
		var origin_variant: Variant = mystery.get("origin", "")
		if typeof(origin_variant) != TYPE_STRING or not MYSTERY_ORIGINS.has(String(origin_variant)):
			return _error("unsupported mystery origin")
		var reveal_variant: Variant = mystery.get("reveal_policy", "")
		if typeof(reveal_variant) != TYPE_STRING or not MYSTERY_REVEAL_POLICIES.has(String(reveal_variant)):
			return _error("unsupported mystery reveal policy")
		var canon_source_ref := ""
		if String(origin_variant) == "authored_canon":
			var source_ref_result := _validate_level_fact_ref(level_registry, mystery.get("canon_source_ref", {}), source)
			if source_ref_result.has("_error"):
				return source_ref_result
			canon_source_ref = String(source_ref_result.value)
		elif not String(mystery.get("canon_source_ref", "")).is_empty():
			return _error("unknown-origin mystery cannot carry authored canon provenance")
		values.append({
			"mystery_ref": mystery_id,
			"origin": String(origin_variant),
			"reveal_policy": String(reveal_variant),
			"canon_source_ref": canon_source_ref,
		})
	values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.mystery_ref < b.mystery_ref)
	return {"values": values}


static func _normalize_ruin_reserves(level_registry: RefCounted, source: Dictionary, input: Variant) -> Dictionary:
	if not input is Array or (input as Array).size() > MAX_SEMANTIC_ITEMS_PER_SITE:
		return _error("procedural ruin reference list is outside its supported bound")
	var values: Array[Dictionary] = []
	var seen: Dictionary = {}
	for reserve_variant: Variant in input:
		if not reserve_variant is Dictionary:
			return _error("procedural ruin reserve must be a dictionary")
		var reserve: Dictionary = reserve_variant
		var id_result := _required_id(reserve.get("reserve_id", ""), "procedural ruin reserve")
		if id_result.has("_error"):
			return id_result
		var reserve_id := String(id_result.value)
		if seen.has(reserve_id):
			return _error("duplicate procedural ruin reserve %s" % reserve_id)
		seen[reserve_id] = true
		var provenance_result := _validate_level_fact_ref(level_registry, reserve.get("provenance_ref", {}), source)
		if provenance_result.has("_error"):
			return provenance_result
		var refs: Dictionary = {}
		for field: String in ["site_purpose_ref", "room_purpose_ref", "failure_cause_ref"]:
			var ref_result := _optional_id(reserve.get(field, ""), field)
			if ref_result.has("_error"):
				return ref_result
			refs[field] = String(ref_result.value)
		values.append({"reserve_id": reserve_id, "provenance_ref": String(provenance_result.value)}.merged(refs, true))
	values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.reserve_id < b.reserve_id)
	return {"values": values}


static func _validate_level_fact_ref(level_registry: RefCounted, input: Variant, source: Dictionary) -> Dictionary:
	if not input is Dictionary:
		return _error("typed F02 fact reference must be a dictionary")
	var fact: Dictionary = input
	var kind_variant: Variant = fact.get("kind", "")
	var level_id_variant: Variant = fact.get("level_id", "")
	var fact_id_variant: Variant = fact.get("fact_id", "")
	if typeof(kind_variant) != TYPE_STRING or String(kind_variant) != "level_tag" \
			or typeof(level_id_variant) != TYPE_STRING or String(level_id_variant) != String(source.level_id) \
			or typeof(fact_id_variant) != TYPE_STRING or not _valid_id(String(fact_id_variant)):
		return _error("typed F02 fact reference is invalid or outside its site source")
	var level_id := StringName(String(level_id_variant))
	if not bool(level_registry.call("has_level", level_id)):
		return _error("typed F02 fact reference names an unknown level")
	var level: RefCounted = level_registry.call("get_level", level_id) as RefCounted
	if level == null or not level.has_method("has_tag") \
			or not bool(level.call("has_tag", StringName(String(fact_id_variant)))):
		return _error("typed F02 fact reference is not declared by its level")
	return {"value": "level-tag:%s:%s" % [level_id, String(fact_id_variant)]}


static func _normalize_id_array(input: Variant, label: String, limit: int) -> Dictionary:
	if not input is Array or (input as Array).size() > limit:
		return _error("%s list is outside its supported bound" % label)
	var values: Array[String] = []
	for value_variant: Variant in input:
		var result := _required_id(value_variant, label)
		if result.has("_error"):
			return result
		var value := String(result.value)
		if values.has(value):
			return _error("duplicate %s identity %s" % [label, value])
		values.append(value)
	values.sort()
	return {"values": values}


static func _required_id(value: Variant, label: String) -> Dictionary:
	if typeof(value) != TYPE_STRING or not _valid_id(String(value)):
		return _error("invalid %s identity" % label)
	return {"value": String(value)}


static func _optional_id(value: Variant, label: String) -> Dictionary:
	if typeof(value) != TYPE_STRING:
		return _error("%s must be a string" % label)
	if String(value).is_empty():
		return {"value": ""}
	return _required_id(value, label)


static func _is_level_registry(value: RefCounted) -> bool:
	return value != null and value.has_method("has_level") and value.has_method("get_level")


static func _edge_target_key(edge_id: String, target_location_id: String) -> String:
	return _component(edge_id) + _component(target_location_id)


static func _component(value: String) -> String:
	return "%d:%s" % [value.to_utf8_buffer().size(), value]


static func _valid_id(value: String) -> bool:
	if value.is_empty() or value.length() > MAX_ID_LENGTH:
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
