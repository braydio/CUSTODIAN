extends SceneTree

const ROUTE_PATH := "res://content/routes/sundered_keep/sundered_keep_route.json"
const FRONT_GATE_PATH := "res://content/levels/sundered_keep/front_gate.json"


func _init() -> void:
	var errors: Array[String] = []
	var route := _read_json(ROUTE_PATH)
	var forward_edge := _find_record(
		route.get("edges", []),
		"edge_id",
		"vista_to_keep_direct"
	)
	_check(
		str(forward_edge.get("transition_style", "")) == "fade",
		"approach-to-gate edge still uses an occluded handoff",
		errors
	)
	_check(
		str(forward_edge.get("target_spawn_id", "")) == "EntrySpawn",
		"handoff does not target the existing causeway spawn",
		errors
	)
	var reverse_edge := _find_record(
		route.get("edges", []),
		"edge_id",
		"keep_to_vista_direct"
	)
	_check(
		str(reverse_edge.get("transition_style", "")) == "fade",
		"gate-to-approach edge still uses an occluded handoff",
		errors
	)
	var front_gate := _read_json(FRONT_GATE_PATH)
	_check(
		(front_gate.get("spawns", []) as Array).has("EntrySpawn"),
		"Front Gate no longer declares EntrySpawn",
		errors
	)
	_finish(errors)


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(_read_text(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _find_record(records: Variant, key: String, value: String) -> Dictionary:
	for raw: Variant in records:
		if raw is Dictionary and str((raw as Dictionary).get(key, "")) == value:
			return raw as Dictionary
	return {}


func _check(ok: bool, message: String, errors: Array[String]) -> void:
	if not ok:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[SunderedKeepCausewayHandoffSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[SunderedKeepCausewayHandoffSmoke] %s" % error)
	quit(1)
