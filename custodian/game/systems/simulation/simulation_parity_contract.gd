class_name SimulationParityContract
extends RefCounted
const FIXTURE_SCHEMA := "custodian.python_sim.godot_port_parity.v2"
const COMMANDS_SCHEMA := "custodian.simulation_commands.v2"
static func validate_fixture(data: Dictionary) -> bool: return data.get("fixture_schema") == FIXTURE_SCHEMA and data.get("commands_schema") == COMMANDS_SCHEMA and data.has("projection") and data.has("projection_sha256")
static func projection(state: WorldSimulationState) -> Dictionary: return SimulationCanonicalJson.normalize(state.parity_projection())
static func differences(expected: Variant, actual: Variant, path: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(expected) != typeof(actual): result.append({"path": path, "python": expected, "godot": actual}); return result
	if expected is Dictionary:
		var keys: Array = expected.keys(); for key in actual.keys(): if key not in keys: keys.append(key)
		keys.sort()
		for key in keys:
			if not expected.has(key) or not actual.has(key): result.append({"path": _join(path, String(key)), "python": expected.get(key), "godot": actual.get(key)})
			else: result.append_array(differences(expected[key], actual[key], _join(path, String(key))))
	elif expected is Array:
		if expected.size() != actual.size(): result.append({"path": path, "python": expected, "godot": actual})
		else: for index in expected.size(): result.append_array(differences(expected[index], actual[index], "%s[%d]" % [path, index]))
	elif expected != actual: result.append({"path": path, "python": expected, "godot": actual})
	return result
static func _join(left: String, right: String) -> String: return right if left.is_empty() else "%s.%s" % [left, right]
