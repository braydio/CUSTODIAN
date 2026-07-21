extends SceneTree

const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")
const ROUTE_REGISTRY_SCRIPT := preload("res://game/world/routes/route_registry.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var levels: RefCounted = LEVEL_REGISTRY_SCRIPT.new()
	if not levels.call("load_index"):
		for error: String in levels.call("get_errors"):
			errors.append("level registry: %s" % error)
	var routes: RefCounted = ROUTE_REGISTRY_SCRIPT.new()
	if errors.is_empty() and not routes.call("load_index", ROUTE_REGISTRY_SCRIPT.DEFAULT_INDEX_PATH, levels):
		for error: String in routes.call("get_errors"):
			errors.append(str(error))
	var route := routes.call("get_route", &"sundered_keep") as RefCounted
	if route == null:
		errors.append("sundered_keep route did not load")
	else:
		if route.nodes.size() != 3:
			errors.append("expected three route nodes")
		if route.profiles.size() != 3:
			errors.append("expected production, debug_direct_keep, and causeway_only profiles")
		if route.call("get_node_definition", &"front_gate").level_id != &"sundered_keep_front_gate":
			errors.append("front_gate node does not resolve the registered Keep level")
	var source := _read_json("res://content/routes/sundered_keep/sundered_keep_route.json")
	var unknown_level := source.duplicate(true); unknown_level.nodes[0].level_id = "missing_level"
	_expect_invalid(levels, unknown_level, "unknown_level", "unknown level_id", errors)
	var unknown_node := source.duplicate(true); unknown_node.edges[2].to_node_id = "missing_node"
	_expect_invalid(levels, unknown_node, "unknown_node", "unknown target node", errors)
	var unknown_edge := source.duplicate(true); unknown_edge.profiles[0].enabled_edge_ids.append("missing_edge")
	_expect_invalid(levels, unknown_edge, "unknown_edge", "unknown edge", errors)
	var bad_direction := source.duplicate(true); bad_direction.edges[2].direction = "sideways"
	_expect_invalid(levels, bad_direction, "bad_direction", "direction", errors)
	var missing_spawn := source.duplicate(true); missing_spawn.edges[2].target_spawn_id = "MissingSpawn"
	_expect_invalid(levels, missing_spawn, "missing_spawn", "target spawn", errors)
	var duplicate_exit := source.duplicate(true); var duplicate_edge: Dictionary = duplicate_exit.edges[2].duplicate(true)
	duplicate_edge.edge_id = "duplicate_vista_exit"; duplicate_exit.edges.append(duplicate_edge); duplicate_exit.profiles[0].enabled_edge_ids.append("duplicate_vista_exit")
	_expect_invalid(levels, duplicate_exit, "duplicate_exit", "duplicate exit mapping", errors)
	var bad_entry := source.duplicate(true); bad_entry.profiles[0].entry_edge_id = "vista_to_causeway"
	_expect_invalid(levels, bad_entry, "bad_entry", "entry edge must start", errors)
	_expect_duplicate_route_id(levels, source, errors)
	_finish(errors)


func _expect_invalid(levels: RefCounted, data: Dictionary, suffix: String, expected: String, errors: Array[String]) -> void:
	var definition_path := "user://route_contract_%s.json" % suffix
	var index_path := "user://route_contract_%s_index.json" % suffix
	_write_json(definition_path, data); _write_json(index_path, {"schema": "custodian.route_registry.v1", "definitions": [definition_path]})
	var registry := ROUTE_REGISTRY_SCRIPT.new()
	if registry.load_index(index_path, levels): errors.append("%s was accepted" % suffix); return
	if not "; ".join(registry.get_errors()).contains(expected): errors.append("%s did not report %s" % [suffix, expected])


func _expect_duplicate_route_id(levels: RefCounted, source: Dictionary, errors: Array[String]) -> void:
	var a := "user://route_contract_duplicate_a.json"; var b := "user://route_contract_duplicate_b.json"; var index := "user://route_contract_duplicate_index.json"
	_write_json(a, source); _write_json(b, source); _write_json(index, {"schema": "custodian.route_registry.v1", "definitions": [a, b]})
	var registry := ROUTE_REGISTRY_SCRIPT.new()
	if registry.load_index(index, levels) or not "; ".join(registry.get_errors()).contains("duplicate route_id"): errors.append("duplicate route_id was not rejected")


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ); var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed as Dictionary if parsed is Dictionary else {}


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE); file.store_string(JSON.stringify(data, "  ") + "\n")


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("[RouteRegistryContractSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[RouteRegistryContractSmoke] %s" % error)
	quit(1)
