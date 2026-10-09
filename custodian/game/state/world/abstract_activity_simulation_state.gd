class_name AbstractActivitySimulationState
extends RefCounted

const SCHEMA := "custodian.abstract_activity_state"
const VERSION := 1
const MAX_DOMAINS := 64
const MAX_LOCATIONS_PER_DOMAIN := 128
const MAX_GROUPS := 256
const MAX_CAUSAL_EVENTS := 64
const MAX_ROUTE_LOCATIONS := 64
const ACTIVITY_INTERVAL_TICKS := 60

var locations_by_domain: Dictionary = {}
var groups: Dictionary = {}
var causal_events: Array[Dictionary] = []
var last_error := ""


func register_location(domain_id: String, location_id: String) -> bool:
	last_error = ""
	if not _valid_id(domain_id) or not _valid_id(location_id):
		return _reject("invalid domain or location identity")
	if not locations_by_domain.has(domain_id) and locations_by_domain.size() >= MAX_DOMAINS:
		return _reject("abstract domain bound exceeded")
	var locations: Array = locations_by_domain.get(domain_id, [])
	if locations.has(location_id):
		return _reject("duplicate location identity %s/%s" % [domain_id, location_id])
	if locations.size() >= MAX_LOCATIONS_PER_DOMAIN:
		return _reject("domain location bound exceeded")
	locations.append(location_id)
	locations.sort()
	locations_by_domain[domain_id] = locations
	return true


func register_group(
	domain_id: String,
	group_id: String,
	location_id: String,
	objective_id: String,
	route_location_ids: Array,
	registered_fixed_tick: int = 0,
	condition: float = 1.0,
	pressure: float = 0.0
) -> bool:
	last_error = ""
	if not _valid_id(domain_id) or not _valid_id(group_id) or not _valid_id(objective_id):
		return _reject("invalid domain, group, or objective identity")
	if not _has_location(domain_id, location_id):
		return _reject("group location is not registered in its domain")
	if registered_fixed_tick < 0:
		return _reject("negative group registration tick")
	if not is_finite(condition) or condition < 0.0 or condition > 1.0:
		return _reject("group condition must be within [0, 1]")
	if not is_finite(pressure) or pressure < 0.0 or pressure > 100.0:
		return _reject("group pressure must be within [0, 100]")
	if route_location_ids.size() < 2 or route_location_ids.size() > MAX_ROUTE_LOCATIONS:
		return _reject("patrol route length is outside its supported bound")
	var route: Array[String] = []
	for route_location_variant in route_location_ids:
		var route_location := String(route_location_variant)
		if not _has_location(domain_id, route_location):
			return _reject("patrol route references an unknown location")
		route.append(route_location)
	if route[0] != location_id:
		return _reject("group location must match the first route location")
	var key := _group_key(domain_id, group_id)
	if groups.has(key):
		return _reject("duplicate group identity %s/%s" % [domain_id, group_id])
	if groups.size() >= MAX_GROUPS:
		return _reject("abstract group bound exceeded")
	groups[key] = {
		"domain_id": domain_id,
		"group_id": group_id,
		"location_id": location_id,
		"objective_id": objective_id,
		"route_location_ids": route,
		"route_progress_index": 0,
		"last_advanced_fixed_tick": registered_fixed_tick,
		"condition": condition,
		"pressure": pressure,
	}
	return true


func advance_to_fixed_tick(fixed_tick: int, world_tick: int) -> bool:
	last_error = ""
	if fixed_tick < 0 or world_tick < 0:
		return _reject("activity ticks cannot be negative")
	var keys := _sorted_group_keys()
	# Validate the complete batch before changing any group, so corrupt state
	# fails closed without partially advancing a location population.
	for key in keys:
		var group: Dictionary = groups[key]
		if not _valid_group_record(key, group):
			return _reject("invalid abstract group record %s" % key)
		if fixed_tick < int(group.last_advanced_fixed_tick):
			return _reject("fixed tick moved behind an abstract group's last advance")
	for key in keys:
		var group: Dictionary = groups[key]
		var elapsed := fixed_tick - int(group.last_advanced_fixed_tick)
		if elapsed < ACTIVITY_INTERVAL_TICKS:
			continue
		var route: Array = group.route_location_ids
		var old_index := int(group.route_progress_index)
		var next_index := (old_index + 1) % route.size()
		var old_location := String(group.location_id)
		var next_location := String(route[next_index])
		group.location_id = next_location
		group.route_progress_index = next_index
		group.last_advanced_fixed_tick = fixed_tick
		var domain_id := String(group.domain_id)
		var group_id := String(group.group_id)
		causal_events.append({
			"event_id": "%s.%s.%d" % [domain_id, group_id, fixed_tick],
			"kind": "patrol_route_advanced",
			"cause": "bounded_offscreen_patrol_progression",
			"domain_id": domain_id,
			"group_id": group_id,
			"objective_id": String(group.objective_id),
			"from_location_id": old_location,
			"to_location_id": next_location,
			"from_route_progress_index": old_index,
			"to_route_progress_index": next_index,
			"fixed_tick": fixed_tick,
			"world_tick": world_tick,
		})
		while causal_events.size() > MAX_CAUSAL_EVENTS:
			causal_events.pop_front()
	return true


func get_group(domain_id: String, group_id: String) -> Dictionary:
	var value: Variant = groups.get(_group_key(domain_id, group_id), {})
	return value.duplicate(true) if value is Dictionary else {}


func to_dict() -> Dictionary:
	var domains: Dictionary = {}
	var domain_ids: Array[String] = []
	for domain_variant in locations_by_domain.keys():
		domain_ids.append(String(domain_variant))
	domain_ids.sort()
	for domain_id in domain_ids:
		var location_ids: Array = (locations_by_domain[domain_id] as Array).duplicate()
		location_ids.sort()
		domains[domain_id] = location_ids
	var serialized_groups: Array[Dictionary] = []
	for key in _sorted_group_keys():
		serialized_groups.append((groups[key] as Dictionary).duplicate(true))
	return {
		"schema": SCHEMA,
		"schema_version": VERSION,
		"locations_by_domain": domains,
		"groups": serialized_groups,
		"causal_events": causal_events.duplicate(true),
	}


static func from_dict(data: Dictionary) -> AbstractActivitySimulationState:
	if String(data.get("schema", "")) != SCHEMA or int(data.get("schema_version", 0)) != VERSION:
		return null
	var restored := AbstractActivitySimulationState.new()
	var serialized_domains: Variant = data.get("locations_by_domain", {})
	if not serialized_domains is Dictionary:
		return null
	var domain_ids: Array[String] = []
	for domain_variant in serialized_domains.keys():
		domain_ids.append(String(domain_variant))
	domain_ids.sort()
	for domain_id in domain_ids:
		var serialized_locations: Variant = serialized_domains[domain_id]
		if not serialized_locations is Array or serialized_locations.is_empty():
			return null
		for location_variant in serialized_locations:
			if not restored.register_location(domain_id, String(location_variant)):
				return null
	var serialized_groups: Variant = data.get("groups", [])
	if not serialized_groups is Array or serialized_groups.size() > MAX_GROUPS:
		return null
	for group_variant in serialized_groups:
		if not group_variant is Dictionary:
			return null
		var group: Dictionary = group_variant
		var domain_id := String(group.get("domain_id", ""))
		var group_id := String(group.get("group_id", ""))
		var key := _group_key(domain_id, group_id)
		if restored.groups.has(key) or not restored._valid_group_record(key, group):
			return null
		restored.groups[key] = group.duplicate(true)
	var serialized_events: Variant = data.get("causal_events", [])
	if not serialized_events is Array or serialized_events.size() > MAX_CAUSAL_EVENTS:
		return null
	var seen_event_ids: Dictionary = {}
	var previous_event_tick := -1
	for event_variant in serialized_events:
		if not event_variant is Dictionary:
			return null
		var event: Dictionary = event_variant
		var event_id := String(event.get("event_id", ""))
		var domain_id := String(event.get("domain_id", ""))
		var group_id := String(event.get("group_id", ""))
		var group_key := _group_key(domain_id, group_id)
		if event_id.is_empty() or seen_event_ids.has(event_id):
			return null
		if not restored.groups.has(group_key):
			return null
		var fixed_tick: Variant = event.get("fixed_tick", null)
		var world_tick: Variant = event.get("world_tick", null)
		if not _is_serialized_int(fixed_tick) or not _is_serialized_int(world_tick):
			return null
		if int(fixed_tick) < previous_event_tick or int(fixed_tick) < 0 or int(world_tick) < 0:
			return null
		previous_event_tick = int(fixed_tick)
		var group: Dictionary = restored.groups[group_key]
		var route: Array = group.route_location_ids
		var from_index: Variant = event.get("from_route_progress_index", null)
		var to_index: Variant = event.get("to_route_progress_index", null)
		if not _is_serialized_int(from_index) or not _is_serialized_int(to_index):
			return null
		if int(from_index) < 0 or int(from_index) >= route.size() or int(to_index) < 0 or int(to_index) >= route.size():
			return null
		var from_location_id := String(event.get("from_location_id", ""))
		var to_location_id := String(event.get("to_location_id", ""))
		if String(event.get("kind", "")) != "patrol_route_advanced" \
			or String(event.get("cause", "")) != "bounded_offscreen_patrol_progression" \
			or String(event.get("objective_id", "")) != String(group.objective_id):
			return null
		if event_id != "%s.%s.%d" % [domain_id, group_id, int(fixed_tick)]:
			return null
		if int(fixed_tick) > int(group.last_advanced_fixed_tick):
			return null
		if String(route[int(from_index)]) != from_location_id or String(route[int(to_index)]) != to_location_id:
			return null
		if not restored._has_location(domain_id, from_location_id):
			return null
		if not restored._has_location(domain_id, to_location_id):
			return null
		seen_event_ids[event_id] = true
		restored.causal_events.append(event.duplicate(true))
	return restored


func _valid_group_record(key: String, group: Dictionary) -> bool:
	var domain_id := String(group.get("domain_id", ""))
	var group_id := String(group.get("group_id", ""))
	var location_id := String(group.get("location_id", ""))
	var objective_id := String(group.get("objective_id", ""))
	if not _valid_id(domain_id) or not _valid_id(group_id) or not _valid_id(objective_id):
		return false
	if key != _group_key(domain_id, group_id) or not _has_location(domain_id, location_id):
		return false
	var route_variant: Variant = group.get("route_location_ids", null)
	if not route_variant is Array or route_variant.size() < 2 or route_variant.size() > MAX_ROUTE_LOCATIONS:
		return false
	var progress_variant: Variant = group.get("route_progress_index", null)
	var last_tick_variant: Variant = group.get("last_advanced_fixed_tick", null)
	if not _is_serialized_int(progress_variant) or not _is_serialized_int(last_tick_variant):
		return false
	var progress_index := int(progress_variant)
	if progress_index < 0 or progress_index >= route_variant.size():
		return false
	if String(route_variant[progress_index]) != location_id:
		return false
	for route_location_variant in route_variant:
		if not route_location_variant is String or not _has_location(domain_id, String(route_location_variant)):
			return false
	var last_tick := int(last_tick_variant)
	var condition := float(group.get("condition", -1.0))
	var pressure := float(group.get("pressure", -1.0))
	return last_tick >= 0 and is_finite(condition) and condition >= 0.0 and condition <= 1.0 \
		and is_finite(pressure) and pressure >= 0.0 and pressure <= 100.0


func _has_location(domain_id: String, location_id: String) -> bool:
	var locations: Variant = locations_by_domain.get(domain_id, null)
	return _valid_id(location_id) and locations is Array and locations.has(location_id)


func _sorted_group_keys() -> Array[String]:
	var keys: Array[String] = []
	for key_variant in groups.keys():
		keys.append(String(key_variant))
	keys.sort()
	return keys


func _reject(message: String) -> bool:
	last_error = message
	return false


static func _group_key(domain_id: String, group_id: String) -> String:
	return "%s::%s" % [domain_id, group_id]


static func _valid_id(value: String) -> bool:
	if value.is_empty() or value.length() > 64:
		return false
	for index in value.length():
		var code := value.unicode_at(index)
		var valid := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) \
			or (code >= 97 and code <= 122) or code == 95 or code == 45 or code == 46
		if not valid:
			return false
	return true


static func _is_serialized_int(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return typeof(value) == TYPE_FLOAT and is_finite(value) and is_equal_approx(value, round(value))
