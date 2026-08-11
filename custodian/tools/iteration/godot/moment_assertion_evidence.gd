extends RefCounted
class_name MomentAssertionEvidence

const VALUE_READER := preload("res://tools/iteration/godot/moment_value_reader.gd")


static func evaluate(definitions: Array, context: Dictionary) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for definition: Dictionary in definitions:
		var kind := str(definition.get("type", ""))
		var actual: Variant = null
		var passed := false
		match kind:
			"role_exists":
				actual = context.roles.has(str(definition.get("role", "")))
				passed = bool(actual)
			"no_unreleased_inputs":
				actual = bool(context.driver.has_unreleased_inputs())
				passed = not bool(actual)
			"warning_count":
				actual = (context.warnings as Array).size()
				passed = _compare(actual, definition)
			"event_count":
				actual = _event_count(context.timeline, str(definition.get("event", "")))
				passed = _compare(actual, definition)
			"event_exactly_once":
				actual = _matching_events(context.timeline, definition).size()
				passed = actual == 1
			"event_absent":
				actual = _matching_events(context.timeline, definition).size()
				passed = actual == 0
			"event_field_compare":
				actual = _event_field(context.timeline, definition)
				passed = _compare(actual, definition)
			"event_same_field":
				actual = _same_event_field(context.timeline, definition)
				passed = bool(actual.get("equal", false))
			"event_between_ticks":
				actual = _events_between_ticks(context.timeline, definition)
				var count_definition := definition.duplicate()
				count_definition["op"] = definition.get("count_op", "eq")
				count_definition["value"] = definition.get("count", 1)
				passed = _compare(actual, count_definition)
			"role_distance_compare":
				actual = _role_distance(context.roles, definition)
				passed = _compare(actual, definition)
			"counter_value":
				actual = context.counters.get(str(definition.get("counter", "")), 0)
				passed = _compare(actual, definition)
			"probe_compare":
				actual = _probe_value(context.probes, definition)
				passed = _compare(actual, definition)
			"metric_compare":
				actual = VALUE_READER.dotted(context.metrics, str(definition.get("metric", "")))
				passed = _compare(actual, definition)
			"output_exists":
				var path := str(definition.get("path", ""))
				actual = FileAccess.file_exists(str(context.output_dir).path_join(path))
				passed = bool(actual)
			"event_order":
				actual = _event_order(context.timeline, definition.get("events", []))
				passed = bool(actual)
			_:
				actual = "unsupported assertion"
				passed = false
		output.append({
			"type": kind,
			"severity": str(definition.get("severity", "error")),
			"passed": passed,
			"actual": actual,
			"expected": definition,
			"message": str(definition.get("message", "")),
		})
	return output


static func _compare(actual: Variant, definition: Dictionary) -> bool:
	var expected: Variant = definition.get("value", definition.get("expected", 0))
	match str(definition.get("op", "eq")):
		"eq": return actual == expected
		"ne": return actual != expected
		"gt": return actual != null and actual > expected
		"gte": return actual != null and actual >= expected
		"lt": return actual != null and actual < expected
		"lte": return actual != null and actual <= expected
	return false


static func _event_count(timeline: Array, event_name: String) -> int:
	var count := 0
	for item: Dictionary in timeline:
		if str(item.get("kind", "")) == event_name:
			count += 1
	return count


static func _matching_events(timeline: Array, definition: Dictionary) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	var wanted := str(definition.get("event", ""))
	var where := definition.get("where", {}) as Dictionary
	for item: Dictionary in timeline:
		if str(item.get("kind", "")) != wanted:
			continue
		var accepted := true
		for path in where:
			if VALUE_READER.dotted(item, str(path)) != where[path]:
				accepted = false
				break
		if accepted:
			matches.append(item)
	return matches


static func _event_field(timeline: Array, definition: Dictionary) -> Variant:
	var matches := _matching_events(timeline, definition)
	if matches.is_empty():
		return null
	var selected := matches[0] if str(definition.get("select", "last")) == "first" else matches[-1]
	return VALUE_READER.dotted(selected, str(definition.get("field", "")))


static func _same_event_field(timeline: Array, definition: Dictionary) -> Dictionary:
	var values := []
	var field := str(definition.get("field", ""))
	for event_name in definition.get("events", []):
		var matches := _matching_events(timeline, {"event": str(event_name)})
		values.append(VALUE_READER.dotted(matches[-1], field) if not matches.is_empty() else null)
	var equal := not values.is_empty() and values[0] != null
	for value in values:
		equal = equal and value != null and value == values[0]
	return {"equal": equal, "values": values}


static func _events_between_ticks(timeline: Array, definition: Dictionary) -> int:
	var count := 0
	var wanted := str(definition.get("event", ""))
	var start_tick := int(definition.get("start_tick", 0))
	var end_tick := int(definition.get("end_tick", 2147483647))
	for item: Dictionary in timeline:
		var tick := int(item.get("tick", -1))
		if str(item.get("kind", "")) == wanted and tick >= start_tick and tick <= end_tick:
			count += 1
	return count


static func _role_distance(roles: Dictionary, definition: Dictionary) -> Variant:
	var a := roles.get(str(definition.get("role_a", ""))) as Node2D
	var b := roles.get(str(definition.get("role_b", ""))) as Node2D
	if a == null or b == null or not is_instance_valid(a) or not is_instance_valid(b):
		return null
	return a.global_position.distance_to(b.global_position)


static func _event_order(timeline: Array, names: Array) -> bool:
	var index := -1
	for name: Variant in names:
		var found := false
		for cursor in range(index + 1, timeline.size()):
			if str(timeline[cursor].get("kind", "")) == str(name):
				index = cursor
				found = true
				break
		if not found:
			return false
	return true


static func _probe_value(probes: Array, definition: Dictionary) -> Variant:
	var wanted_id := str(definition.get("probe", ""))
	var wanted_tick := int(definition.get("tick", -1))
	var field := str(definition.get("field", ""))
	for record: Dictionary in probes:
		if str(record.get("id", "")) == wanted_id and int(record.get("tick", -2)) == wanted_tick:
			return (record.get("values", {}) as Dictionary).get(field)
	return null
