extends SceneTree

const REGISTRY_SCRIPT := preload("res://game/world/geography/campaign_geography_registry.gd")
const VISIT_SCRIPT := preload("res://game/world/geography/campaign_visit_reference.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if OS.get_cmdline_user_args().has("--negative-control"):
		push_error("CAMPAIGN_GEOGRAPHY_IDENTITY_SMOKE: NEGATIVE CONTROL")
		quit(1)
		return
	_check_deterministic_fixtures()
	_check_visits_reuse_domain_identity()
	_check_collision_safe_addresses()
	_check_rejections_are_atomic()
	_check_scene_identity_is_not_geography()
	_check_data_only_boundary()
	if failures.is_empty():
		print("CAMPAIGN_GEOGRAPHY_IDENTITY_SMOKE: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("CAMPAIGN_GEOGRAPHY_IDENTITY_SMOKE: FAIL (%d)" % failures.size())
		quit(1)


func _check_deterministic_fixtures() -> void:
	var first := _new_registry(false)
	var second := _new_registry(true)
	_check(first.domain_ids() == second.domain_ids(), "fixed domain fixture IDs changed with registration order")
	for domain_id: String in first.domain_ids():
		var first_domain := first.resolve_domain(domain_id)
		var second_domain := second.resolve_domain(domain_id)
		_check(JSON.stringify(first_domain) == JSON.stringify(second_domain), "normalized Domain descriptor changed with fixture order: %s" % domain_id)
		_check(first_domain.location_ids.size() >= 2, "Domain fixture must declare at least two locations")
		_check(not first_domain.edges.is_empty(), "Domain fixture must declare an explicit connection")
		for location_id: String in first_domain.location_ids:
			var location := first.resolve_location(domain_id, location_id)
			_check(location.domain_id == domain_id and location.domain_seed == first_domain.domain_seed, "location descriptor lost Domain seed provenance")
			_check(location.generation_version == first_domain.generation_version and location.schema_version == first_domain.schema_version, "location descriptor lost generation/schema provenance")
			_check(location.locality_seed >= 0 and location.locality_seed <= 4294967295, "locality provenance seed is outside uint32")
			_check(location.neighbors.size() > 0, "fixture location has no declared adjacency")
		var location_copy := first.resolve_location(domain_id, first_domain.location_ids[0])
		location_copy.neighbors.clear()
		_check(not first.resolve_location(domain_id, first_domain.location_ids[0]).neighbors.is_empty(), "resolved descriptor mutation leaked into registry state")


func _check_visits_reuse_domain_identity() -> void:
	var registry := _new_registry(false)
	var first_visit = VISIT_SCRIPT.new()
	var second_visit = VISIT_SCRIPT.new()
	_check(first_visit.configure("visit-01", "domain.alpha", "site.a", "site.b", ["road.main"], registry), "first visit reference was rejected")
	_check(second_visit.configure("visit-02", "domain.alpha", "site.b", "site.a", ["road.main"], registry), "second visit reference was rejected")
	var first_site := registry.resolve_location(first_visit.domain_id, first_visit.entry_location_id)
	var second_site := registry.resolve_location(second_visit.domain_id, second_visit.active_location_id)
	_check(first_visit.visit_id != second_visit.visit_id, "visits must retain distinct visit identities")
	_check(first_visit.domain_id == second_visit.domain_id, "visits to the same Domain must share its persistent identity")
	_check(first_site.locality_seed == second_site.locality_seed, "return visit changed locality generation provenance")
	_check(first_site.neighbors == second_site.neighbors, "return visit changed canonical adjacency")
	_check(registry.resolve_domain(first_visit.domain_id).generation_version == registry.resolve_domain(second_visit.domain_id).generation_version, "return visit changed generation version")
	_check(first_visit.accessible_edge_ids == second_visit.accessible_edge_ids, "visits changed the canonical accessible edge identity")
	var visit_before := JSON.stringify(first_visit.to_descriptor())
	_check(not first_visit.configure("visit-invalid", "domain.alpha", "site.a", "site.b", ["missing.edge"], registry), "visit accepted an unknown accessible edge")
	_check(JSON.stringify(first_visit.to_descriptor()) == visit_before, "rejected visit configuration partially mutated its reference")
	_check(first_visit.to_descriptor().domain_id == second_visit.to_descriptor().domain_id, "visit descriptors diverged from the same Domain")


func _check_collision_safe_addresses() -> void:
	var registry := REGISTRY_SCRIPT.new()
	var first_key: String = registry.location_address_key("a.b", "c")
	var second_key: String = registry.location_address_key("a", "b.c")
	_check(not first_key.is_empty() and not second_key.is_empty(), "valid dotted components were rejected")
	_check(first_key != second_key, "length-prefixed location address aliases dotted component pairs")
	for invalid_id: String in ["", "space id", "semi;colon", "x".repeat(65)]:
		_check(registry.location_address_key("domain", invalid_id).is_empty(), "invalid address component was accepted: %s" % invalid_id)


func _check_rejections_are_atomic() -> void:
	var registry := _new_registry(false)
	var baseline := JSON.stringify(registry.resolve_domain("domain.alpha"))
	_check(not registry.register_domain(_domain_fixture("domain.alpha", 999, false)), "duplicate Domain ID was accepted")
	_check(registry.last_error.contains("duplicate domain"), "duplicate Domain rejection reason was not exposed")
	var invalid := _invalid_fixture("bad.schema", {"schema_version": 2})
	_check(not registry.register_domain(invalid), "unsupported geography schema was accepted")
	_check(registry.last_error.contains("schema"), "unsupported schema rejection reason was not exposed")
	invalid = _invalid_fixture("bad.version", {"generation_version": "geo-v2"})
	_check(not registry.register_domain(invalid), "unsupported generation version was accepted")
	_check(registry.last_error.contains("generation version"), "unsupported generator rejection reason was not exposed")
	invalid = _invalid_fixture("bad.seed", {"domain_seed": -1})
	_check(not registry.register_domain(invalid), "negative seed provenance was accepted")
	_check(registry.last_error.contains("seed"), "bad provenance rejection reason was not exposed")
	invalid = _invalid_fixture("bad.id", {"locations": [{"location_id": "bad id"}]})
	_check(not registry.register_domain(invalid), "illegal location identity was accepted")
	invalid = _invalid_fixture("bad.location.duplicate", {"locations": [{"location_id": "A"}, {"location_id": "A"}]})
	_check(not registry.register_domain(invalid), "duplicate location identity was accepted")
	invalid = _invalid_fixture("bad.id.type", {"domain_id": 42})
	_check(not registry.register_domain(invalid), "non-string Domain identity was coerced and accepted")
	invalid = _invalid_fixture("bad.unknown", {"edges": [{"edge_id": "e", "from_location_id": "A", "to_location_id": "MISSING", "directed": true}]})
	_check(not registry.register_domain(invalid), "unknown edge target was accepted")
	invalid = _invalid_fixture("bad.reciprocal", {"edges": [{"edge_id": "e", "from_location_id": "A", "to_location_id": "B", "directed": false}]})
	_check(not registry.register_domain(invalid), "missing reciprocal undirected mapping was accepted")
	invalid = _invalid_fixture("bad.duplicate", {"edges": [
		{"edge_id": "e", "from_location_id": "A", "to_location_id": "B", "directed": true},
		{"edge_id": "e", "from_location_id": "B", "to_location_id": "A", "directed": true},
	]})
	_check(not registry.register_domain(invalid), "conflicting duplicate edge identity was accepted")
	_check(not registry.resolve_location("domain.alpha", "ROUTE_A"), "unknown route node silently resolved as a geographic location")
	_check(registry.last_error.contains("unknown location"), "unknown location rejection reason was not exposed")
	_check(JSON.stringify(registry.resolve_domain("domain.alpha")) == baseline, "rejected definitions partially mutated an existing Domain")
	_check(registry.domain_ids().size() == 2, "rejected definitions partially registered a Domain")
	_check(not registry.has_domain("bad.schema") and not registry.has_domain("bad.version") and not registry.has_domain("bad.seed"), "rejected definitions partially registered")


func _check_scene_identity_is_not_geography() -> void:
	var registry := _new_registry(false)
	var route_node_id := "site.a"
	var level_id := "site.a"
	var geographic_location := registry.resolve_location("domain.alpha", "site.a")
	_check(not geographic_location.is_empty(), "explicit geographic address did not resolve")
	_check(registry.resolve_location("domain.other", route_node_id).is_empty(), "route-node coincidence bypassed the Domain address")
	_check(registry.resolve_location("domain.alpha", level_id).location_id == "site.a", "explicit location lookup failed when scene ID happened to match")
	_check(route_node_id == level_id, "fixture must exercise coincident route and level IDs")


func _check_data_only_boundary() -> void:
	var child_count_before := root.get_child_count()
	var registry := _new_registry(false)
	var visit = VISIT_SCRIPT.new()
	_check(registry is RefCounted and visit is RefCounted, "geography authority is not data-only RefCounted state")
	_check(root.get_child_count() == child_count_before, "geography registration instantiated a gameplay scene node")
	_check(registry.domain_ids().size() == 2, "data-only registry lost a fixture Domain")


func _new_registry(reverse: bool) -> CampaignGeographyRegistry:
	var registry = REGISTRY_SCRIPT.new()
	var fixtures := [
		_domain_fixture("domain.alpha", 12345, reverse),
		_domain_fixture("domain.beta", 54321, reverse),
	]
	if reverse:
		fixtures.reverse()
	for fixture: Dictionary in fixtures:
		_check(registry.register_domain(fixture), "valid fixed-seed Domain fixture rejected: %s" % registry.last_error)
	return registry


func _domain_fixture(domain_id: String, seed: int, reverse: bool) -> Dictionary:
	var locations := [
		{"location_id": "site.a"},
		{"location_id": "site.b"},
	]
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


func _invalid_fixture(domain_id: String, overrides: Dictionary) -> Dictionary:
	var definition := _domain_fixture(domain_id, 123, false)
	for key: Variant in overrides:
		definition[key] = overrides[key]
	return definition


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
