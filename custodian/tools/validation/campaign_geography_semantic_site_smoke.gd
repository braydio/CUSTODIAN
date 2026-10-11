extends SceneTree

const GEOGRAPHY_SCRIPT := preload("res://game/world/geography/campaign_geography_registry.gd")
const SEMANTIC_SCRIPT := preload("res://game/world/geography/campaign_geography_semantic_registry.gd")
const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")
const VISIT_SCRIPT := preload("res://game/world/geography/campaign_visit_reference.gd")
const LEVEL_INDEX := "res://content/levels/levels.json"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if OS.get_cmdline_user_args().has("--negative-control"):
		push_error("CAMPAIGN_GEOGRAPHY_SEMANTIC_SITE_SMOKE: NEGATIVE CONTROL")
		quit(1)
		return
	var level_registry := _new_level_registry()
	if level_registry == null:
		push_error("CAMPAIGN_GEOGRAPHY_SEMANTIC_SITE_SMOKE: F02 LevelRegistry failed to load")
		quit(1)
		return
	_check_reordered_plans_are_deterministic(level_registry)
	_check_domain_qualified_addresses(level_registry)
	_check_directed_transit_stays_directed(level_registry)
	_check_rejections_are_atomic(level_registry)
	_check_optional_slots_are_reference_only(level_registry)
	_check_data_only_boundary(level_registry)
	if failures.is_empty():
		print("CAMPAIGN_GEOGRAPHY_SEMANTIC_SITE_SMOKE: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("CAMPAIGN_GEOGRAPHY_SEMANTIC_SITE_SMOKE: FAIL (%d)" % failures.size())
		quit(1)


func _check_reordered_plans_are_deterministic(level_registry: RefCounted) -> void:
	var first_geography: Variant = _new_geography()
	var second_geography: Variant = _new_geography(true)
	var first := SEMANTIC_SCRIPT.new()
	var second := SEMANTIC_SCRIPT.new()
	_check(first.register_domain_plan(first_geography, level_registry, _domain_plan(first_geography, false)), "base semantic plan rejected: %s" % first.last_error)
	_check(second.register_domain_plan(second_geography, level_registry, _domain_plan(second_geography, true)), "reordered semantic plan rejected: %s" % second.last_error)
	var first_domain := first.resolve_domain("domain.alpha")
	var second_domain := second.resolve_domain("domain.alpha")
	_check(JSON.stringify(first_domain) == JSON.stringify(second_domain), "semantic projection changed under site/metadata input reordering")
	_check(first_domain.location_ids == ["site.a", "site.b"], "semantic locations are not stably ordered")
	var a := first.resolve_site("domain.alpha", "site.a")
	var b := first.resolve_site("domain.alpha", "site.b")
	_check(a.edge_bindings.size() == 1 and b.edge_bindings.size() == 1, "two-site plan did not retain both canonical B1 edge directions")
	_check(a.edge_bindings[0].directed == false and a.edge_bindings[0].ingress_status == "planned", "logical undirected road was misrepresented as a verified physical crossing")
	_check(a.landmarks[0].role == "dominant" and b.landmarks[0].role == "supporting", "landmark hierarchy slots were not retained")
	_check(a.site_purpose == "settlement" and b.site_purpose == "gate", "site purpose was not retained as semantic metadata")
	var visit_one: Variant = VISIT_SCRIPT.new()
	var visit_two: Variant = VISIT_SCRIPT.new()
	var visit_edges: Array[String] = ["road.main"]
	_check(visit_one.configure("visit.one", "domain.alpha", "site.a", "site.b", visit_edges, first_geography), "first repeated-visit fixture rejected")
	_check(visit_two.configure("visit.two", "domain.alpha", "site.b", "site.a", visit_edges, first_geography), "second repeated-visit fixture rejected")
	_check(visit_one.visit_id != visit_two.visit_id, "revisits did not preserve distinct visit identities")
	_check(JSON.stringify(first.resolve_domain("domain.alpha")) == JSON.stringify(first_domain), "return visit changed persistent semantic plan")
	var reconstructed := SEMANTIC_SCRIPT.new()
	var reconstructed_geography: Variant = _new_geography()
	_check(reconstructed.register_domain_plan(reconstructed_geography, level_registry, _domain_plan(reconstructed_geography, false)), "reconstructed B1 semantic plan rejected")
	_check(JSON.stringify(reconstructed.resolve_domain("domain.alpha")) == JSON.stringify(first_domain), "reconstructed B1 registry changed semantic plan bytes")
	_check(JSON.stringify(first_geography.resolve_domain("domain.alpha")) == JSON.stringify(second_geography.resolve_domain("domain.alpha")), "semantic registration mutated its source B1 descriptors")
	var mutated_copy := first.resolve_site("domain.alpha", "site.a")
	mutated_copy.edge_bindings.clear()
	_check(first.resolve_site("domain.alpha", "site.a").edge_bindings.size() == 1, "semantic descriptor copy mutation leaked into stored state")


func _check_domain_qualified_addresses(level_registry: RefCounted) -> void:
	var geography: Variant = _new_geography()
	_check(geography.register_domain(_domain_fixture("domain.other", 54321, false)), "second Domain fixture failed")
	var semantic := SEMANTIC_SCRIPT.new()
	var plan := _domain_plan(geography, false)
	_check(semantic.register_domain_plan(geography, level_registry, plan), "first Domain semantic plan rejected")
	var other_plan := _domain_plan(geography, false, "domain.other")
	_check(semantic.register_domain_plan(geography, level_registry, other_plan), "second Domain semantic plan rejected")
	var first_address: String = semantic.resolve_site("domain.alpha", "site.a").address_key
	var second_address: String = semantic.resolve_site("domain.other", "site.a").address_key
	_check(first_address != second_address, "same LocationId in distinct Domains aliases in semantic address keys")
	var collision_geography := GEOGRAPHY_SCRIPT.new()
	_check(collision_geography.register_domain({"schema_version": 1, "domain_id": "a.b", "domain_seed": 1, "generation_version": "geo-v1", "locations": [{"location_id": "c"}], "edges": []}), "dotted B1 Domain fixture was rejected")
	_check(collision_geography.register_domain({"schema_version": 1, "domain_id": "a", "domain_seed": 1, "generation_version": "geo-v1", "locations": [{"location_id": "b.c"}], "edges": []}), "dotted B1 Location fixture was rejected")
	var collision_semantic := SEMANTIC_SCRIPT.new()
	_check(collision_semantic.register_domain_plan(collision_geography, level_registry, _single_site_plan(collision_geography, "a.b", "c")), "first dotted semantic address rejected")
	_check(collision_semantic.register_domain_plan(collision_geography, level_registry, _single_site_plan(collision_geography, "a", "b.c")), "second dotted semantic address rejected")
	_check(collision_semantic.resolve_site("a.b", "c").address_key != collision_semantic.resolve_site("a", "b.c").address_key, "semantic Domain+Location address key aliases dotted component pairs")


func _check_directed_transit_stays_directed(level_registry: RefCounted) -> void:
	var geography: Variant = _new_directed_geography()
	var semantic := SEMANTIC_SCRIPT.new()
	var location: Dictionary = geography.resolve_location("domain.transit", "site.a")
	var plan := {
		"schema_version": 1,
		"semantic_generation_version": "site-v1",
		"domain_id": "domain.transit",
		"geography_generation_version": "geo-v1",
		"sites": [
			{
				"location_id": "site.a",
				"locality_seed": int(location.locality_seed),
				"source": {"kind": "authored_level", "level_id": "ash_bell_lower_quarter"},
				"edge_bindings": [{"edge_id": "transit.one", "target_location_id": "site.b", "crossing_kind": "authored_transit"}],
			},
		],
	}
	_check(semantic.register_domain_plan(geography, level_registry, plan), "valid directed transit plan rejected: %s" % semantic.last_error)
	var binding: Dictionary = semantic.resolve_site("domain.transit", "site.a").edge_bindings[0]
	_check(binding.directed and binding.crossing_kind == "authored_transit", "directed B1 arc became reciprocal or road-like")
	var invalid := plan.duplicate(true)
	(invalid.sites[0].edge_bindings[0] as Dictionary).crossing_kind = "road"
	_check(not semantic.register_domain_plan(geography, level_registry, invalid), "directed edge accepted as an undirected road")


func _check_rejections_are_atomic(level_registry: RefCounted) -> void:
	var geography: Variant = _new_geography()
	var semantic := SEMANTIC_SCRIPT.new()
	_check(semantic.register_domain_plan(geography, level_registry, _domain_plan(geography, false)), "baseline semantic plan rejected")
	var baseline := JSON.stringify(semantic.resolve_domain("domain.alpha"))
	var bad := _domain_plan(geography, false)
	bad.schema_version = 2
	_reject_atomically(semantic, geography, level_registry, bad, "schema")
	bad = _domain_plan(geography, false)
	bad.semantic_generation_version = "site-v2"
	_reject_atomically(semantic, geography, level_registry, bad, "generation version")
	bad = _domain_plan(geography, false)
	(bad.sites[0] as Dictionary).locality_seed += 1
	_reject_atomically(semantic, geography, level_registry, bad, "stale")
	bad = _domain_plan(geography, false)
	(bad.sites[0] as Dictionary).source.level_id = "missing_level"
	_reject_atomically(semantic, geography, level_registry, bad, "unknown F02 level")
	bad = _domain_plan(geography, false)
	(bad.sites[0] as Dictionary).source.kind = "generated_region"
	(bad.sites[0] as Dictionary).source.profile_id = "missing_profile"
	_reject_atomically(semantic, geography, level_registry, bad, "kind mismatch")
	bad = _domain_plan(geography, false)
	(bad.sites[0] as Dictionary).source.profile_id = "unowned.profile"
	_reject_atomically(semantic, geography, level_registry, bad, "cannot declare a generated profile")
	bad = _domain_plan(geography, false)
	(bad.sites[0] as Dictionary).authored_override = {"kind": "authored_level", "level_id": "ash_bell_west_gate_works"}
	_reject_atomically(semantic, geography, level_registry, bad, "contradicts")
	bad = _domain_plan(geography, false)
	(bad.sites[0] as Dictionary).edge_bindings[0].target_location_id = "unknown.site"
	_reject_atomically(semantic, geography, level_registry, bad, "canonical B1 neighbor")
	bad = _domain_plan(geography, false)
	(bad.sites[0] as Dictionary).edge_bindings[0].ingress_status = "verified"
	_reject_atomically(semantic, geography, level_registry, bad, "proof")
	bad = _domain_plan(geography, false)
	(bad.sites[0] as Dictionary).encounter_cues[0].truth_state = "confirmed"
	_reject_atomically(semantic, geography, level_registry, bad, "unresolved")
	bad = _domain_plan(geography, false)
	(bad.sites[0] as Dictionary).encounter_cues.append((bad.sites[0] as Dictionary).encounter_cues[0].duplicate(true))
	_reject_atomically(semantic, geography, level_registry, bad, "duplicate encounter motif")
	bad = _domain_plan(geography, false)
	(bad.sites[1] as Dictionary).edge_bindings[0].crossing_kind = "trail"
	_reject_atomically(semantic, geography, level_registry, bad, "contradictory semantic crossing")
	bad = _domain_plan(geography, false)
	(bad.sites[0] as Dictionary).landmarks.append((bad.sites[0] as Dictionary).landmarks[0].duplicate(true))
	_reject_atomically(semantic, geography, level_registry, bad, "duplicate landmark")
	bad = _domain_plan(geography, false)
	(bad.sites[0] as Dictionary).mysteries.append((bad.sites[0] as Dictionary).mysteries[0].duplicate(true))
	_reject_atomically(semantic, geography, level_registry, bad, "duplicate mystery")
	_check(JSON.stringify(semantic.resolve_domain("domain.alpha")) == baseline, "failed domain-plan replacement partially mutated registered semantic state")
	var retry := _domain_plan(geography, false)
	_check(semantic.register_domain_plan(geography, level_registry, retry), "valid retry after rejected semantic candidates failed")


func _check_optional_slots_are_reference_only(level_registry: RefCounted) -> void:
	var geography: Variant = _new_geography()
	var semantic := SEMANTIC_SCRIPT.new()
	var empty_plan := _domain_plan(geography, false)
	for site_variant: Variant in empty_plan.sites:
		var site: Dictionary = site_variant
		site.encounter_cues = []
		site.landmarks = []
		site.spatial_intents = []
		site.mysteries = []
		site.ruin_reserves = []
	_check(semantic.register_domain_plan(geography, level_registry, empty_plan), "absent optional Hall slots must be valid")
	var plan := _domain_plan(geography, false)
	var site_b: Dictionary = plan.sites[1]
	site_b.mysteries = [{
		"mystery_ref": "mystery.canon",
		"origin": "authored_canon",
		"reveal_policy": "later_discovery",
		"canon_source_ref": {"kind": "level_tag", "level_id": "ash_bell_west_gate_works", "fact_id": "ash_bell"},
	}]
	site_b.ruin_reserves = [{
		"reserve_id": "ruin.reserve",
		"provenance_ref": {"kind": "level_tag", "level_id": "ash_bell_west_gate_works", "fact_id": "west_gate"},
		"site_purpose_ref": "settlement",
		"room_purpose_ref": "shelter",
		"failure_cause_ref": "abandonment",
	}]
	_check(semantic.register_domain_plan(geography, level_registry, plan), "typed canon/ruin references to existing F02 facts were rejected: %s" % semantic.last_error)
	var resolved := semantic.resolve_site("domain.alpha", "site.b")
	_check(resolved.mysteries[0].canon_source_ref == "level-tag:ash_bell_west_gate_works:ash_bell", "authored mystery provenance was not preserved as a reference")
	_check(resolved.ruin_reserves[0].failure_cause_ref == "abandonment", "procedural-ruin reserve escaped bounded reference-only shape")


func _check_data_only_boundary(level_registry: RefCounted) -> void:
	var child_count_before := root.get_child_count()
	var geography: Variant = _new_geography()
	var geography_before := JSON.stringify(geography.resolve_domain("domain.alpha"))
	var semantic := SEMANTIC_SCRIPT.new()
	_check(semantic is RefCounted, "semantic registry is not data-only RefCounted state")
	_check(semantic.register_domain_plan(geography, level_registry, _domain_plan(geography, false)), "data-only semantic plan rejected")
	_check(root.get_child_count() == child_count_before, "semantic plan instantiated a Node")
	_check(JSON.stringify(geography.resolve_domain("domain.alpha")) == geography_before, "semantic plan mutated source geography")


func _reject_atomically(semantic: Variant, geography: Variant, level_registry: RefCounted, bad: Dictionary, expected_error: String) -> void:
	var before := JSON.stringify(semantic.resolve_domain("domain.alpha"))
	_check(not semantic.register_domain_plan(geography, level_registry, bad), "invalid semantic plan was accepted; expected %s" % expected_error)
	_check(String(semantic.last_error).to_lower().contains(expected_error.to_lower()), "rejection reason did not identify %s: %s" % [expected_error, semantic.last_error])
	_check(JSON.stringify(semantic.resolve_domain("domain.alpha")) == before, "rejected semantic replacement mutated the existing plan")


func _new_level_registry() -> RefCounted:
	var registry: RefCounted = LEVEL_REGISTRY_SCRIPT.new()
	if not bool(registry.call("load_index", LEVEL_INDEX)):
		for error: String in registry.call("get_errors"):
			push_error("F02 registry: %s" % error)
		return null
	return registry


func _new_geography(reverse := false) -> Variant:
	var geography: Variant = GEOGRAPHY_SCRIPT.new()
	_check(geography.register_domain(_domain_fixture("domain.alpha", 12345, reverse)), "B1 fixture registration failed: %s" % geography.last_error)
	return geography


func _new_directed_geography() -> Variant:
	var geography: Variant = GEOGRAPHY_SCRIPT.new()
	var definition := _domain_fixture("domain.transit", 12345, false)
	definition.edges = [{"edge_id": "transit.one", "from_location_id": "site.a", "to_location_id": "site.b", "directed": true}]
	_check(geography.register_domain(definition), "directed B1 fixture registration failed: %s" % geography.last_error)
	return geography


func _domain_plan(geography: Variant, reverse := false, domain_id := "domain.alpha") -> Dictionary:
	var domain: Dictionary = geography.resolve_domain(domain_id)
	var site_a := _site(geography, domain_id, "site.a", "ash_bell_lower_quarter", [
		{"edge_id": "road.main", "target_location_id": "site.b", "crossing_kind": "road"},
	], true)
	var site_b := _site(geography, domain_id, "site.b", "ash_bell_west_gate_works", [
		{"edge_id": "road.main", "target_location_id": "site.a", "crossing_kind": "road"},
	], false)
	if reverse:
		site_a.semantic_tags.reverse()
		site_a.edge_bindings.reverse()
		site_a.encounter_cues.reverse()
		site_a.landmarks.reverse()
		site_a.spatial_intents.reverse()
		site_b.edge_bindings.reverse()
		site_b.landmarks.reverse()
		site_b.mysteries.reverse()
		var swapped: Dictionary = site_a
		site_a = site_b
		site_b = swapped
	return {
		"schema_version": 1,
		"semantic_generation_version": "site-v1",
		"domain_id": domain_id,
		"geography_generation_version": String(domain.generation_version),
		"sites": [site_a, site_b],
	}


func _single_site_plan(geography: Variant, domain_id: String, location_id: String) -> Dictionary:
	var domain: Dictionary = geography.resolve_domain(domain_id)
	var location: Dictionary = geography.resolve_location(domain_id, location_id)
	return {
		"schema_version": 1,
		"semantic_generation_version": "site-v1",
		"domain_id": domain_id,
		"geography_generation_version": String(domain.generation_version),
		"sites": [{
			"location_id": location_id,
			"locality_seed": int(location.locality_seed),
			"source": {"kind": "authored_level", "level_id": "ash_bell_lower_quarter"},
		}],
	}


func _site(geography: Variant, domain_id: String, location_id: String, level_id: String, bindings: Array, landmarked := false) -> Dictionary:
	var location: Dictionary = geography.resolve_location(domain_id, location_id)
	return {
		"location_id": location_id,
		"locality_seed": int(location.locality_seed),
		"source": {"kind": "authored_level", "level_id": level_id},
		"site_purpose": "settlement" if landmarked else "gate",
		"semantic_tags": ["settlement", "ash_bell"] if landmarked else ["gate", "ash_bell"],
		"edge_bindings": bindings,
		"encounter_cues": [{"motif_id": "motif.unresolved", "truth_state": "unresolved", "truth_source_ref": ""}] if landmarked else [],
		"landmarks": [{"landmark_id": "landmark.keep", "role": "dominant" if landmarked else "supporting", "approach_edge_ids": ["road.main"]}],
		"spatial_intents": [{"landmark_id": "landmark.keep", "layer": "far" if landmarked else "near", "intent_ref": "vista.intent"}],
		"mysteries": [{"mystery_ref": "mystery.unknown", "origin": "unknown_origin", "reveal_policy": "later_discovery"}] if landmarked else [],
		"ruin_reserves": [],
	}


func _domain_fixture(domain_id: String, seed: int, reverse: bool) -> Dictionary:
	var locations := [{"location_id": "site.a"}, {"location_id": "site.b"}]
	var edges := [
		{"edge_id": "road.main", "from_location_id": "site.a", "to_location_id": "site.b", "directed": false},
		{"edge_id": "road.main", "from_location_id": "site.b", "to_location_id": "site.a", "directed": false},
	]
	if reverse:
		locations.reverse()
		edges.reverse()
	return {
		"schema_version": 1,
		"domain_id": domain_id,
		"domain_seed": seed,
		"generation_version": "geo-v1",
		"locations": locations,
		"edges": edges,
	}


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
