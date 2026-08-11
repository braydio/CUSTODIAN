extends RefCounted
class_name HeadlessTestHarness

const RESULT_PREFIX := "CUSTODIAN_TEST_RESULT_JSON:"

var failures: Array[Dictionary] = []
var fixture_root: Node
var observatory: Node
var _tree: SceneTree
var _test_name := "unnamed_test"
var _tracked_actions: Array[StringName] = []


func configure(tree: SceneTree, test_name: String) -> void:
	_tree = tree
	_test_name = test_name
	fixture_root = Node2D.new()
	fixture_root.name = "%sFixtureRoot" % test_name.to_pascal_case()
	tree.root.add_child(fixture_root)
	tree.current_scene = fixture_root
	observatory = tree.root.get_node_or_null("DevObservatory")
	if observatory != null and observatory.has_method("clear"):
		observatory.call("clear")


func expect(condition: bool, message: String, evidence: Dictionary = {}) -> void:
	if not condition:
		failures.append({"message": message, "evidence": _json_safe(evidence)})


func expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	expect(actual == expected, message, {"actual": actual, "expected": expected})


func expect_ne(actual: Variant, unexpected: Variant, message: String) -> void:
	expect(actual != unexpected, message, {"actual": actual, "unexpected": unexpected})


func expect_approx(actual: float, expected: float, epsilon: float, message: String) -> void:
	expect(absf(actual - expected) <= epsilon, message, {
		"actual": actual, "expected": expected, "epsilon": epsilon,
	})


func expect_true(value: Variant, message: String) -> void:
	expect(bool(value), message, {"actual": value, "expected": true})


func expect_false(value: Variant, message: String) -> void:
	expect(not bool(value), message, {"actual": value, "expected": false})


func recent_event(kind: StringName, predicate: Callable = Callable()) -> Dictionary:
	var found := events(kind)
	for event_variant in found:
		var event := event_variant as Dictionary
		var data := event.get("data", {}) as Dictionary
		if not predicate.is_valid() or bool(predicate.call(data)):
			return event.duplicate(true)
	return {}


func events(kind: StringName) -> Array:
	if observatory == null or not observatory.has_method("get_recent_events"):
		return []
	return observatory.call("get_recent_events", 100000, kind)


func counter(name: StringName) -> int:
	if observatory == null:
		return 0
	return int((observatory.get("counters") as Dictionary).get(name, 0))


func wait_physics_ticks(count: int) -> void:
	for _index in range(maxi(0, count)):
		await _tree.physics_frame


func instantiate_scene(packed: PackedScene, parent: Node = null, name: String = "") -> Node:
	var instance := packed.instantiate()
	if not name.is_empty():
		instance.name = name
	(parent if parent != null else fixture_root).add_child(instance)
	return instance


func track_input_action(action: StringName) -> void:
	if not _tracked_actions.has(action):
		_tracked_actions.append(action)


func finish() -> void:
	for action in _tracked_actions:
		Input.action_release(action)
	var result := {
		"schema": "custodian.headless_test.result.v1",
		"test": _test_name,
		"passed": failures.is_empty(),
		"failure_count": failures.size(),
		"failures": failures,
	}
	print(RESULT_PREFIX + JSON.stringify(result))
	if not failures.is_empty():
		for failure in failures:
			printerr("[%s] %s" % [_test_name, failure.get("message", "failure")])
	if fixture_root != null and is_instance_valid(fixture_root):
		if _tree.current_scene == fixture_root:
			_tree.current_scene = null
		fixture_root.free()
		fixture_root = null
	_tree.quit(0 if failures.is_empty() else 1)


func _json_safe(value: Variant) -> Variant:
	if value is Vector2:
		return [value.x, value.y]
	if value is Vector2i:
		return [value.x, value.y]
	if value is StringName:
		return String(value)
	if value is Dictionary:
		var output := {}
		for key in value:
			output[String(key)] = _json_safe(value[key])
		return output
	if value is Array:
		var output := []
		for item in value:
			output.append(_json_safe(item))
		return output
	return value
