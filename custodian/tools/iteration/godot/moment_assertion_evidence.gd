extends RefCounted
class_name MomentAssertionEvidence


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
			"counter_value":
				actual = context.counters.get(str(definition.get("counter", "")), 0)
				passed = _compare(actual, definition)
			"probe_compare":
				actual = _probe_value(context.probes, definition)
				passed = _compare(actual, definition)
			"metric_compare":
				actual = _dotted(context.metrics, str(definition.get("metric", "")))
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


static func _dotted(value: Variant, path: String) -> Variant:
	var cursor: Variant = value
	for part: String in path.split("."):
		if not cursor is Dictionary:
			return null
		cursor = (cursor as Dictionary).get(part)
	return cursor
