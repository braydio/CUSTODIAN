extends SceneTree
const GENERATOR := preload("res://tools/level_authoring/level_scaffold_generator.gd")
const LEVEL_REGISTRY := preload("res://game/world/levels/level_registry.gd")
const ROUTE_REGISTRY := preload("res://game/world/routes/route_registry.gd")
const OUTPUT := "user://level_scaffold_route_generator_smoke"
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var generator := GENERATOR.new(); generator.call("_remove_tree", ProjectSettings.globalize_path(OUTPUT))
	var errors: Array[String] = []
	var create := _request("route_alpha", "node_a", true)
	create.edges = [
		_edge("enter_a", "@world_origin", "enter", "node_a", "EntrySpawn", "forward"),
		_edge("a_exfil", "node_a", "return_world", "@world_origin", "", "exfil"),
	]
	var dry_create := create.duplicate(true)
	dry_create.dry_run = true
	var dry_result: Dictionary = generator.generate(dry_create)
	if not bool(dry_result.get("ok", false)) or not bool(dry_result.get("dry_run", false)):
		errors.append("valid route dry-run failed full validation")
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUTPUT)):
		errors.append("route dry-run wrote output")
	var first: Dictionary = generator.generate(create)
	if not bool(first.get("ok", false)): errors.append("route creation failed: %s" % first.get("errors", []))
	var append := _request("route_beta", "node_b", false)
	append.exits = [{"exit_id": "return_world", "node_name": "Exit_Main"}, {"exit_id": "backtrack", "node_name": "Exit_Back"}]
	append.edges = [
		_edge("a_to_b", "node_a", "continue", "node_b", "EntrySpawn", "forward"),
		_edge("b_to_world", "node_b", "return_world", "@world_origin", "", "exfil"),
	]
	var second: Dictionary = generator.generate(append)
	if not bool(second.get("ok", false)): errors.append("route append failed: %s" % second.get("errors", []))
	var levels := LEVEL_REGISTRY.new(); var routes := ROUTE_REGISTRY.new()
	var level_index := OUTPUT + "/custodian/content/levels/levels.json"
	var route_index := OUTPUT + "/custodian/content/routes/routes.json"
	if not levels.load_index(level_index): errors.append_array(Array(levels.get_errors()))
	if not routes.load_index(route_index, levels): errors.append_array(Array(routes.get_errors()))
	var route: RefCounted = routes.get_route(&"fixture_generated_route")
	if route == null or route.nodes.size() != 2 or route.edges.size() != 4: errors.append("generated route registry does not contain the appended graph")
	var scene := load(OUTPUT + "/custodian/game/world/levels/authored/smoke/route_alpha/route_alpha.tscn") as PackedScene
	if scene == null: errors.append("generated route-node scene did not load")
	else:
		var instance := scene.instantiate(); var exit := instance.get_node_or_null("Exits/Exit_Main") as LevelExit2D
		if exit == null or exit.exit_id != &"return_world" or exit.get_node_or_null("CollisionShape2D") == null: errors.append("generated generic exit contract is incomplete")
		instance.free()
	var duplicate := _request("route_gamma", "node_b", false)
	duplicate.edges = [_edge("duplicate_edge", "node_b", "side", "@world_origin", "", "exfil")]
	if bool((generator.generate(duplicate) as Dictionary).get("ok", false)): errors.append("duplicate node append was accepted")
	var duplicate_path := ProjectSettings.globalize_path(OUTPUT + "/custodian/content/levels/smoke/route_gamma/route_gamma.json")
	if FileAccess.file_exists(duplicate_path): errors.append("failed append left generated files behind")
	_run_invalid_cases(generator, errors)
	generator.call("_remove_tree", ProjectSettings.globalize_path(OUTPUT))
	finish(errors)


func _run_invalid_cases(generator: RefCounted, errors: Array[String]) -> void:
	var cases: Array[Dictionary] = []
	var unknown_target := _request("invalid_unknown_target", "node_unknown_target", false)
	unknown_target.edges = [
		_edge("unknown_target_edge", "node_unknown_target", "continue", "missing_node", "EntrySpawn", "forward"),
	]
	cases.append({"label": "unknown target node", "request": unknown_target, "expected": "unknown target node"})
	var missing_spawn := _request("invalid_missing_spawn", "node_missing_spawn", false)
	missing_spawn.edges = [
		_edge("a_to_missing_spawn", "node_a", "side", "node_missing_spawn", "MissingSpawn", "forward"),
		_edge("missing_spawn_exfil", "node_missing_spawn", "return_world", "@world_origin", "", "exfil"),
	]
	cases.append({"label": "missing target spawn", "request": missing_spawn, "expected": "target spawn does not exist"})
	var disconnected := _request("invalid_disconnected", "node_disconnected", false)
	disconnected.edges = [
		_edge("disconnected_exfil", "node_disconnected", "return_world", "@world_origin", "", "exfil"),
	]
	cases.append({"label": "disconnected profile node", "request": disconnected, "expected": "contains unreachable node"})
	var no_exfil := _request("invalid_no_exfil", "node_no_exfil", false)
	no_exfil.edges = [
		_edge("b_to_no_exfil", "node_b", "side", "node_no_exfil", "EntrySpawn", "forward"),
	]
	cases.append({"label": "reachable node without exfil", "request": no_exfil, "expected": "has no path to @world_origin"})
	var duplicate_edge := _request("invalid_duplicate_edge", "node_duplicate_edge", false)
	duplicate_edge.edges = [
		_edge("a_to_b", "node_duplicate_edge", "return_world", "@world_origin", "", "exfil"),
	]
	cases.append({"label": "duplicate edge ID", "request": duplicate_edge, "expected": "duplicate route edge_id"})
	var duplicate_mapping := _request("invalid_duplicate_mapping", "node_duplicate_mapping", false)
	duplicate_mapping.edges = [
		_edge("duplicate_mapping", "node_a", "continue", "node_duplicate_mapping", "EntrySpawn", "forward"),
		_edge("duplicate_mapping_exfil", "node_duplicate_mapping", "return_world", "@world_origin", "", "exfil"),
	]
	cases.append({"label": "duplicate profile exit mapping", "request": duplicate_mapping, "expected": "ambiguous profile exit mapping"})
	var second_entry := _request("invalid_second_entry", "node_second_entry", false)
	second_entry.edges = [
		_edge("second_entry", "@world_origin", "enter_alt", "node_second_entry", "EntrySpawn", "forward"),
		_edge("second_entry_exfil", "node_second_entry", "return_world", "@world_origin", "", "exfil"),
	]
	cases.append({"label": "second world-origin entry edge", "request": second_entry, "expected": "already has an entry edge"})
	var invalid_direction := _request("invalid_direction", "node_invalid_direction", false)
	invalid_direction.edges = [
		_edge("invalid_direction_edge", "node_a", "side", "node_invalid_direction", "EntrySpawn", "sideways"),
	]
	cases.append({"label": "invalid direction", "request": invalid_direction, "expected": "invalid direction"})
	for test_case: Dictionary in cases:
		_assert_failed_immutable(
			generator,
			test_case.request,
			str(test_case.label),
			str(test_case.expected),
			errors
		)
	var route_definition_path := ProjectSettings.globalize_path(
		OUTPUT + "/custodian/content/routes/fixture_generated_route/fixture_generated_route_route.json"
	)
	var route_registry_path := ProjectSettings.globalize_path(OUTPUT + "/custodian/content/routes/routes.json")
	var level_registry_path := ProjectSettings.globalize_path(OUTPUT + "/custodian/content/levels/levels.json")
	var baseline_route := _read_bytes(route_definition_path)
	var baseline_route_registry := _read_bytes(route_registry_path)
	var baseline_level_registry := _read_bytes(level_registry_path)
	var corrupt_route := JSON.parse_string(baseline_route.get_string_from_utf8()) as Dictionary
	(corrupt_route.nodes as Array).append({"node_id": "ghost", "level_id": "missing_level"})
	(corrupt_route.edges as Array).append(_edge("ghost_exfil", "ghost", "return_world", "@world_origin", "", "exfil"))
	(corrupt_route.profiles[0].enabled_edge_ids as Array).append("ghost_exfil")
	_write_text(route_definition_path, JSON.stringify(corrupt_route, "  ") + "\n")
	var unknown_level := _request("invalid_unknown_level", "node_unknown_level", false)
	_assert_failed_immutable(generator, unknown_level, "unknown target level", "unknown level_id", errors)
	_write_bytes(route_definition_path, baseline_route)
	_write_text(route_registry_path, JSON.stringify({"schema": "invalid.route.registry", "definitions": []}) + "\n")
	var bad_route_registry := _request("invalid_route_registry", "node_bad_route_registry", false)
	_assert_failed_immutable(generator, bad_route_registry, "invalid route registry schema", "invalid route registry schema", errors)
	_write_bytes(route_registry_path, baseline_route_registry)
	_write_text(level_registry_path, JSON.stringify({"schema": "invalid.level.registry", "definitions": []}) + "\n")
	var bad_level_registry := _request("invalid_level_registry", "node_bad_level_registry", false)
	_assert_failed_immutable(generator, bad_level_registry, "invalid level registry schema", "invalid level registry schema", errors)
	_write_bytes(level_registry_path, baseline_level_registry)
func _request(level_id: String, node_id: String, create: bool) -> Dictionary:
	return {"level_id": level_id, "display_name": level_id, "region": "smoke", "output_root": OUTPUT, "register_level": true, "route_id": "fixture_generated_route", "route_node_id": node_id, "entry_spawn_id": "EntrySpawn", "exits": [{"exit_id": "return_world", "node_name": "Exit_Main"}, {"exit_id": "continue", "node_name": "Exit_Forward"}], "create_route": create, "append_to_route": not create}
func _edge(id: String, source: String, exit_id: String, target: String, spawn: String, direction: String) -> Dictionary:
	return {"edge_id": id, "from_node_id": source, "exit_id": exit_id, "to_node_id": target, "target_spawn_id": spawn, "direction": direction, "transition_style": "fade", "profiles": ["production"]}


func _assert_failed_immutable(
	generator: RefCounted,
	request: Dictionary,
	label: String,
	expected: String,
	errors: Array[String]
) -> void:
	var level_registry_path := ProjectSettings.globalize_path(OUTPUT + "/custodian/content/levels/levels.json")
	var route_registry_path := ProjectSettings.globalize_path(OUTPUT + "/custodian/content/routes/routes.json")
	var route_definition_path := ProjectSettings.globalize_path(
		OUTPUT + "/custodian/content/routes/fixture_generated_route/fixture_generated_route_route.json"
	)
	var snapshots := {
		level_registry_path: _read_bytes(level_registry_path),
		route_registry_path: _read_bytes(route_registry_path),
		route_definition_path: _read_bytes(route_definition_path),
	}
	var result: Dictionary = generator.generate(request)
	if bool(result.get("ok", false)):
		errors.append("%s was accepted" % label)
	elif not "; ".join(result.get("errors", PackedStringArray())).contains(expected):
		errors.append("%s did not report '%s': %s" % [label, expected, result.get("errors", [])])
	for path: String in snapshots.keys():
		if _read_bytes(path) != snapshots[path]:
			errors.append("%s changed %s" % [label, path.get_file()])
	var generated_dir := ProjectSettings.globalize_path(
		OUTPUT + "/custodian/game/world/levels/authored/smoke/%s" % request.level_id
	)
	if DirAccess.dir_exists_absolute(generated_dir):
		errors.append("%s left a generated level directory" % label)


func _read_bytes(path: String) -> PackedByteArray:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_buffer(file.get_length()) if file != null else PackedByteArray()


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_buffer(bytes)


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(text)
func finish(errors: Array[String]) -> void:
	if errors.is_empty(): print("[LevelScaffoldRouteGeneratorSmoke] PASS"); quit(0); return
	for error in errors: push_error("[LevelScaffoldRouteGeneratorSmoke] %s" % error)
	quit(1)
