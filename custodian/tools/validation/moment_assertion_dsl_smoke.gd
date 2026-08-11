extends SceneTree

const ASSERTIONS := preload("res://tools/iteration/godot/moment_assertion_evidence.gd")

class FakeDriver:
	extends RefCounted
	func has_unreleased_inputs() -> bool:
		return false


func _init() -> void:
	var a := Node2D.new()
	var b := Node2D.new()
	a.global_position = Vector2.ZERO
	b.global_position = Vector2(3.0, 4.0)
	root.add_child(a)
	root.add_child(b)
	var timeline: Array[Dictionary] = [
		{"tick": 10, "kind": "marine_dash_hit_resolved", "data": {"attack_id": "dash:1", "spatial_valid": true}},
		{"tick": 11, "kind": "incoming_hit_result", "data": {"attack_id": "dash:1", "result": "damaged"}},
	]
	var definitions := [
		{"type": "event_exactly_once", "event": "incoming_hit_result", "where": {"data.result": "damaged"}},
		{"type": "event_absent", "event": "marine_dash_whiff"},
		{"type": "event_field_compare", "event": "marine_dash_hit_resolved", "field": "data.spatial_valid", "op": "eq", "value": true},
		{"type": "event_same_field", "events": ["marine_dash_hit_resolved", "incoming_hit_result"], "field": "data.attack_id"},
		{"type": "event_between_ticks", "event": "incoming_hit_result", "start_tick": 11, "end_tick": 11, "count_op": "eq", "count": 1},
		{"type": "role_distance_compare", "role_a": "a", "role_b": "b", "op": "eq", "value": 5.0},
	]
	var results := ASSERTIONS.evaluate(definitions, {
		"roles": {"a": a, "b": b}, "driver": FakeDriver.new(), "warnings": [],
		"timeline": timeline, "counters": {}, "probes": [], "metrics": {}, "output_dir": "",
	})
	var failures := []
	for result in results:
		if not bool(result.passed):
			failures.append("expected pass: %s" % result.type)
	var failing := ASSERTIONS.evaluate([
		{"type": "event_exactly_once", "event": "missing"},
		{"type": "event_absent", "event": "incoming_hit_result"},
		{"type": "event_same_field", "events": ["marine_dash_hit_resolved", "missing"], "field": "data.attack_id"},
	], {"roles": {}, "driver": FakeDriver.new(), "warnings": [], "timeline": timeline, "counters": {}, "probes": [], "metrics": {}, "output_dir": ""})
	for result in failing:
		if bool(result.passed):
			failures.append("expected failure: %s" % result.type)
	if failures.is_empty():
		print("moment_assertion_dsl_smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
