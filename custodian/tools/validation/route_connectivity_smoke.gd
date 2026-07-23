extends SceneTree
const LEVEL_REGISTRY := preload("res://game/world/levels/level_registry.gd")
const ROUTE_REGISTRY := preload("res://game/world/routes/route_registry.gd")
const ROUTE_DEFINITION := preload("res://game/world/routes/route_definition.gd")
func _init() -> void:
	var levels := LEVEL_REGISTRY.new(); var routes := ROUTE_REGISTRY.new(); var errors: Array[String] = []
	if not levels.load_index(): errors.append_array(Array(levels.get_errors()))
	if not routes.load_index("res://content/routes/routes.json", levels): errors.append_array(Array(routes.get_errors()))
	var route: RefCounted = routes.get_route(&"sundered_keep")
	if route != null:
		for profile_id in [&"production", &"debug_direct_keep", &"causeway_only"]:
			var profile: RefCounted = route.get_profile(profile_id)
			if profile == null: errors.append("missing profile %s" % profile_id)
			elif route.get_edge(profile.entry_edge_id).from_node_id != &"@world_origin": errors.append("%s entry is not world-origin" % profile_id)
	var source := _read_json("res://content/routes/sundered_keep/sundered_keep_route.json")
	var disconnected_node := _profile_case(source, ["enter_vista", "vista_exfil", "keep_exfil"])
	_expect_error(levels, disconnected_node, "contains unreachable node front_gate", "disconnected enabled node", errors)
	var disconnected_pair := _profile_case(
		source,
		["enter_vista", "vista_exfil", "causeway_to_keep", "keep_to_causeway"]
	)
	_expect_error(levels, disconnected_pair, "contains unreachable node return_causeway", "disconnected enabled edge pair", errors)
	var no_exfil := _profile_case(source, ["enter_vista", "vista_to_causeway"])
	_expect_error(levels, no_exfil, "node return_causeway has no path to @world_origin", "reachable node without exfil", errors)
	finish(errors)


func _profile_case(source: Dictionary, enabled_edges: Array[String]) -> Dictionary:
	var result := source.duplicate(true)
	result.profiles = [{
		"profile_id": "production",
		"entry_edge_id": "enter_vista",
		"enabled_edge_ids": enabled_edges,
	}]
	result.default_profile = "production"
	return result


func _expect_error(
	levels: RefCounted,
	data: Dictionary,
	expected: String,
	label: String,
	errors: Array[String]
) -> void:
	var definition := ROUTE_DEFINITION.new()
	definition.configure_from_dictionary(data)
	var actual := "; ".join(definition.validate(levels))
	if not actual.contains(expected):
		errors.append("%s did not report '%s': %s" % [label, expected, actual])


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed as Dictionary if parsed is Dictionary else {}


func finish(errors: Array[String]) -> void:
	if errors.is_empty(): print("[RouteConnectivitySmoke] PASS"); quit(0); return
	for error in errors: push_error("[RouteConnectivitySmoke] %s" % error)
	quit(1)
