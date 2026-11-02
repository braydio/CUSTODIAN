class_name LevelScaffoldGenerator
extends RefCounted

const REQUEST_SCRIPT := preload("res://tools/level_authoring/level_scaffold_request.gd")
const LEVEL_DEFINITION_SCRIPT := preload("res://game/world/levels/level_definition.gd")
const ROUTE_DEFINITION_SCRIPT := preload("res://game/world/routes/route_definition.gd")
const ROUTE_VALIDATION_REGISTRY_VIEW := preload("res://tools/level_authoring/route_validation_registry_view.gd")
const TEMPLATE_ROOT := "res://tools/level_authoring/templates"
const GENERATOR_VERSION := 1


func generate(data: Dictionary) -> Dictionary:
	var request: RefCounted = REQUEST_SCRIPT.new()
	request.call("configure", data)
	var errors: PackedStringArray = request.call("validate")
	if not errors.is_empty():
		return _failure(errors)
	var output_root := _resolve_output_root(request.output_root)
	var paths := _build_paths(request, output_root)
	var route_preflight := _prepare_route_mutation(request, paths)
	if not bool(route_preflight.get("ok", false)):
		return route_preflight
	var rendered := _render_files(request, paths)
	var route_contract := _validate_rendered_route_contract(request, paths, rendered)
	if not bool(route_contract.get("ok", false)):
		return route_contract
	var preflight := _preflight(request, paths, rendered)
	if not bool(preflight.get("ok", false)):
		return preflight
	if request.dry_run:
		return {
			"ok": true,
			"dry_run": true,
			"level_id": request.level_id,
			"planned_files": rendered.keys(),
			"registry_path": paths.registry,
		}
	return _commit(request, paths, rendered)


func _validate_rendered_route_contract(
	request: RefCounted,
	paths: Dictionary,
	rendered: Dictionary
) -> Dictionary:
	if not request.create_route and not request.append_to_route:
		return {"ok": true}
	var registry_view := ROUTE_VALIDATION_REGISTRY_VIEW.new()
	var existing_result := _load_existing_level_definitions_for_validation(paths, registry_view)
	if not bool(existing_result.get("ok", false)):
		return existing_result
	var route_registry_result := _validate_existing_route_registry_for_validation(paths)
	if not bool(route_registry_result.get("ok", false)):
		return route_registry_result
	var staged_data: Variant = JSON.parse_string(str(rendered.get(paths.definition, "")))
	if not (staged_data is Dictionary):
		return _failure(["staged level definition did not parse"])
	if str((staged_data as Dictionary).get("schema", "")) != "custodian.level_definition.v1":
		return _failure(["staged level definition has invalid schema"])
	var staged_definition := LEVEL_DEFINITION_SCRIPT.new()
	staged_definition.call("configure_from_dictionary", staged_data)
	var staged_errors: PackedStringArray = staged_definition.call("validate", false)
	if not staged_errors.is_empty():
		return _failure(staged_errors)
	registry_view.add_level_definition(staged_definition)
	var route_definition := ROUTE_DEFINITION_SCRIPT.new()
	route_definition.call("configure_from_dictionary", request.route_data)
	var route_errors: PackedStringArray = route_definition.call("validate", registry_view)
	if not route_errors.is_empty():
		return _failure(route_errors)
	return {"ok": true}


func _load_existing_level_definitions_for_validation(
	paths: Dictionary,
	registry_view: RefCounted
) -> Dictionary:
	if not FileAccess.file_exists(paths.registry):
		return {"ok": true}
	var registry_data := _read_json(paths.registry)
	if str(registry_data.get("schema", "")) != "custodian.level_registry.v1":
		return _failure(["invalid level registry schema: %s" % paths.registry])
	var definitions_value: Variant = registry_data.get("definitions", [])
	if not (definitions_value is Array):
		return _failure(["invalid level registry definitions: expected array"])
	for definition_reference: Variant in definitions_value:
		var definition_path := _resolve_generated_reference(paths, str(definition_reference))
		var definition_data := _read_json(definition_path)
		if definition_data.is_empty():
			return _failure(["level definition did not parse: %s" % definition_reference])
		if str(definition_data.get("schema", "")) != "custodian.level_definition.v1":
			return _failure(["invalid level definition schema: %s" % definition_reference])
		var definition := LEVEL_DEFINITION_SCRIPT.new()
		definition.call("configure_from_dictionary", definition_data)
		var definition_errors: PackedStringArray = definition.call("validate")
		if not definition_errors.is_empty():
			return _failure(definition_errors)
		registry_view.call("add_level_definition", definition)
	return {"ok": true}


func _validate_existing_route_registry_for_validation(paths: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(paths.route_registry):
		return {"ok": true}
	var registry_data := _read_json(paths.route_registry)
	if str(registry_data.get("schema", "")) != "custodian.route_registry.v1":
		return _failure(["invalid route registry schema: %s" % paths.route_registry])
	if not (registry_data.get("definitions", []) is Array):
		return _failure(["invalid route registry definitions: expected array"])
	return {"ok": true}


func _resolve_generated_reference(paths: Dictionary, reference: String) -> String:
	if reference.begins_with("res://"):
		return str(paths.project_root).path_join(reference.trim_prefix("res://"))
	if reference.begins_with("user://"):
		return ProjectSettings.globalize_path(reference)
	if reference.is_absolute_path():
		return reference
	return str(paths.project_root).path_join(reference)


func _resolve_output_root(requested: String) -> String:
	if requested.is_empty():
		return ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()
	if requested.begins_with("res://") or requested.begins_with("user://"):
		return ProjectSettings.globalize_path(requested).simplify_path()
	return requested.simplify_path()


func _build_paths(request: RefCounted, output_root: String) -> Dictionary:
	var project_root := output_root.path_join("custodian")
	var level_dir := project_root.path_join("game/world/levels/authored/%s/%s" % [request.region, request.level_id])
	var content_dir := project_root.path_join("content/levels/%s/%s" % [request.region, request.level_id])
	var validation_dir := project_root.path_join("tools/validation/levels")
	var design_dir := output_root.path_join("design/05_levels")
	return {
		"output_root": output_root,
		"project_root": project_root,
		"level_dir": level_dir,
		"content_dir": content_dir,
		"production_script": level_dir.path_join("%s.gd" % request.level_id),
		"production_scene": level_dir.path_join("%s.tscn" % request.level_id),
		"playtest_scene": level_dir.path_join("%s_playtest.tscn" % request.level_id),
		"authoring_scene": level_dir.path_join("%s_authoring.tscn" % request.level_id),
		"readme": level_dir.path_join("README.md"),
		"definition": content_dir.path_join("%s.json" % request.level_id),
		"manifest": content_dir.path_join("%s.levelgen.json" % request.level_id),
		"smoke": validation_dir.path_join("%s_smoke.gd" % request.level_id),
		"design": design_dir.path_join("%s.md" % request.level_id.to_upper()),
		"registry": project_root.path_join("content/levels/levels.json"),
		"route_definition": project_root.path_join("content/routes/%s/%s_route.json" % [request.route_id, request.route_id]),
		"route_registry": project_root.path_join("content/routes/routes.json"),
	}


func _render_files(request: RefCounted, paths: Dictionary) -> Dictionary:
	var playtest_extras := _playtest_profile_fragments(request.playtest_profile)
	var replacements := {
		"{{LEVEL_ID}}": request.level_id,
		"{{DISPLAY_NAME}}": request.display_name,
		"{{REGION}}": request.region,
		"{{CLASS_NAME}}": request.class_name_value,
		"{{SPAWN_ID}}": request.entry_spawn_id,
		"{{ENTRY_SPAWN_ID}}": request.entry_spawn_id,
		"{{RETURN_SPAWN_ID}}": request.return_spawn_id,
		"{{INGRESS_PROMPT}}": request.ingress_prompt,
		"{{WORLD_CONTEXT}}": request.world_context,
		"{{PLACEMENT_STRATEGY}}": request.placement_strategy,
		"{{INTERACTION_DISTANCE}}": "%.1f" % request.interaction_distance,
		"{{PLAYTEST_PROFILE}}": request.playtest_profile,
		"{{PLAYTEST_EXTRA_RESOURCES}}": playtest_extras.resources,
		"{{PLAYTEST_EXTRA_NODES}}": playtest_extras.nodes,
		"{{CANVAS_WIDTH}}": str(request.canvas_size.x),
		"{{CANVAS_HEIGHT}}": str(request.canvas_size.y),
		"{{CANVAS_HALF_WIDTH}}": str(request.canvas_size.x / 2),
		"{{CANVAS_HALF_HEIGHT}}": str(request.canvas_size.y / 2),
		"{{PRODUCTION_SCRIPT_PATH}}": _resource_path(paths.production_script),
		"{{PRODUCTION_SCENE_PATH}}": _resource_path(paths.production_scene),
		"{{PLAYTEST_SCENE_PATH}}": _resource_path(paths.playtest_scene),
		"{{AUTHORING_SCENE_PATH}}": _resource_path(paths.authoring_scene),
		"{{DEFINITION_PATH}}": _resource_path(paths.definition),
		"{{DESIGN_DOC_PATH}}": _resource_path(paths.design),
		"{{PLACEMENT_OFFSETS_JSON}}": JSON.stringify(request.placement_offsets.map(func(value: Vector2i) -> Array: return [value.x, value.y])),
		"{{CACHE_POLICY}}": request.cache_policy,
		"{{STATE_POLICY}}": request.state_policy,
		"{{PRESENTATION_PROFILE}}": request.presentation_profile,
		"{{TAGS_JSON}}": JSON.stringify(["authored", "playable_map", "route_node", request.region] if not request.route_id.is_empty() else ["authored", "playable_map", "world_ingress", request.region]),
		"{{INGRESS_BLOCK}}": "" if not request.route_id.is_empty() else _ingress_block(request),
	}
	var exit_fragments := _exit_fragments(request.exits)
	replacements["{{LOAD_STEPS}}"] = str(3 + request.exits.size())
	replacements["{{EXIT_SUBRESOURCES}}"] = exit_fragments.subresources
	replacements["{{EXIT_NODES}}"] = exit_fragments.nodes
	var files := {
		paths.production_script: _render_template("authored_level.gd.txt", replacements),
		paths.production_scene: _render_template("authored_level.tscn.txt", replacements),
		paths.playtest_scene: _render_template("authored_level_playtest.tscn.txt", replacements),
		paths.authoring_scene: _render_template("authored_level_authoring.tscn.txt", replacements),
		paths.definition: _render_template("level_definition.json.txt", replacements),
		paths.design: _render_template("level_design.md.txt", replacements),
		paths.smoke: _render_template("level_smoke.gd.txt", replacements),
		paths.readme: "# %s\n\nGenerated authored-level workspace. Production content belongs in `%s.tscn`; runtime test ownership belongs in the playtest wrapper.\n" % [request.display_name, request.level_id],
	}
	var managed_files: Array[String] = []
	for path: String in files.keys():
		managed_files.append(path.trim_prefix(paths.output_root + "/"))
	managed_files.append(paths.manifest.trim_prefix(paths.output_root + "/"))
	if request.create_route or request.append_to_route:
		managed_files.append(paths.route_definition.trim_prefix(paths.output_root + "/"))
	managed_files.sort()
	files[paths.manifest] = JSON.stringify({
		"schema": "custodian.level_scaffold_manifest.v1",
		"generator_version": GENERATOR_VERSION,
		"level_id": request.level_id,
		"managed_files": managed_files,
		"created_utc": Time.get_datetime_string_from_system(true),
		"last_generated_utc": Time.get_datetime_string_from_system(true),
	}, "  ") + "\n"
	return files


func _ingress_block(request: RefCounted) -> String:
	return ",\n  \"ingress\": " + JSON.stringify({
		"ingress_id": request.level_id,
		"prompt_text": request.ingress_prompt,
		"target_spawn_id": request.entry_spawn_id,
		"interaction_distance": request.interaction_distance,
		"placement": {"strategy": request.placement_strategy, "priority": 100, "minimum_spacing_tiles": 10, "search_radius_tiles": 14, "offset_candidates_tiles": request.placement_offsets.map(func(value: Vector2i) -> Array: return [value.x, value.y])},
	}, "  ")


func _exit_fragments(exits: Array[Dictionary]) -> Dictionary:
	var subresources: Array[String] = []
	var nodes: Array[String] = []
	for index in exits.size():
		var exit_data := exits[index]
		var shape_id := "RectangleShape2D_exit_%d" % index
		subresources.append("[sub_resource type=\"RectangleShape2D\" id=\"%s\"]\nsize = Vector2(72, 72)" % shape_id)
		nodes.append("\n".join([
			"[node name=\"%s\" type=\"Area2D\" parent=\"Exits\"]" % str(exit_data.node_name),
			"position = Vector2(%d, 96)" % (96 + index * 96),
			"script = ExtResource(\"2_exit\")",
			"exit_id = &\"%s\"" % str(exit_data.exit_id),
			"[node name=\"CollisionShape2D\" type=\"CollisionShape2D\" parent=\"Exits/%s\"]" % str(exit_data.node_name),
			"shape = SubResource(\"%s\")" % shape_id,
		]))
	return {"subresources": "\n\n".join(subresources), "nodes": "\n\n".join(nodes)}


func _playtest_profile_fragments(profile: String) -> Dictionary:
	if profile == "movement":
		return {"resources": "", "nodes": ""}
	var resources := "\n".join([
		"[ext_resource type=\"Script\" path=\"res://game/systems/core/systems/combat.gd\" id=\"6_combat\"]",
		"[ext_resource type=\"Script\" path=\"res://game/systems/core/systems/navigation_system.gd\" id=\"7_navigation\"]",
		"[ext_resource type=\"Script\" path=\"res://game/systems/core/systems/enemy_director.gd\" id=\"8_director\"]",
	])
	var nodes := "\n".join([
		"[node name=\"Combat\" type=\"Node\" parent=\".\"]",
		"script = ExtResource(\"6_combat\")",
		"[node name=\"NavigationSystem\" type=\"Node\" parent=\".\"]",
		"script = ExtResource(\"7_navigation\")",
		"[node name=\"EnemyDirector\" type=\"Node\" parent=\".\"]",
		"script = ExtResource(\"8_director\")",
	])
	if profile == "full":
		resources += "\n[ext_resource type=\"Script\" path=\"res://game/systems/core/systems/wave_manager.gd\" id=\"9_wave\"]"
		resources += "\n[ext_resource type=\"PackedScene\" path=\"res://game/ui/hud/custodian_hud.tscn\" id=\"10_hud\"]"
		nodes += "\n[node name=\"WaveManager\" type=\"Node\" parent=\".\"]"
		nodes += "\nscript = ExtResource(\"9_wave\")"
		nodes += "\ndebug_spawn_grunt_on_start = false"
		nodes += "\n[node name=\"CustodianHUD\" parent=\".\" instance=ExtResource(\"10_hud\")]"
	return {"resources": resources, "nodes": nodes}


func _render_template(filename: String, replacements: Dictionary) -> String:
	var path := TEMPLATE_ROOT.path_join(filename)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	for token: String in replacements.keys():
		text = text.replace(token, str(replacements[token]))
	return text


func _preflight(request: RefCounted, paths: Dictionary, rendered: Dictionary) -> Dictionary:
	for path: String in rendered.keys():
		if rendered[path].is_empty():
			return _failure(["template rendered empty: %s" % path])
	var managed: Dictionary = {}
	if FileAccess.file_exists(paths.manifest):
		var manifest := _read_json(paths.manifest)
		for relative: Variant in manifest.get("managed_files", []):
			managed[paths.output_root.path_join(str(relative))] = true
	for path: String in rendered.keys():
		if not FileAccess.file_exists(path):
			continue
		if not managed.has(path):
			if request.adopt_existing and _read_text(path) == str(rendered[path]):
				continue
			return _failure(["refusing to overwrite unmanaged file: %s" % path])
		if not request.force_generated:
			return _failure(["generated file exists; use --force-generated: %s" % path])
	if request.register_level and FileAccess.file_exists(paths.registry):
		var registry := _read_json(paths.registry)
		var definition_path := _resource_path(paths.definition)
		if registry.get("definitions", []).has(definition_path) and not request.force_generated:
			return _failure(["definition is already registered: %s" % definition_path])
		for existing_path: Variant in registry.get("definitions", []):
			var existing_abs := ProjectSettings.globalize_path(str(existing_path))
			if FileAccess.file_exists(existing_abs):
				var existing := _read_json(existing_abs)
				if str(existing.get("level_id", "")) == request.level_id and str(existing_path) != definition_path:
					return _failure(["duplicate level_id in registry: %s" % request.level_id])
	return {"ok": true}


func _prepare_route_mutation(request: RefCounted, paths: Dictionary) -> Dictionary:
	request.route_data.clear()
	if not request.create_route and not request.append_to_route:
		return {"ok": true}
	var route: Dictionary
	if request.create_route:
		if FileAccess.file_exists(paths.route_definition):
			return _failure(["route definition already exists: %s" % paths.route_definition])
		route = {
			"schema": "custodian.route_definition.v1",
			"managed_by": "custodian.level_scaffold_generator.v1",
			"route_id": request.route_id,
			"display_name": request.route_id.replace("_", " ").capitalize(),
			"world_context": request.world_context,
			"default_profile": "production",
			"tags": ["authored"], "nodes": [], "edges": [], "profiles": [],
		}
	else:
		if not FileAccess.file_exists(paths.route_definition):
			return _failure(["route definition does not exist: %s" % paths.route_definition])
		route = _read_json(paths.route_definition)
		if str(route.get("managed_by", "")) != "custodian.level_scaffold_generator.v1":
			return _failure(["refusing to overwrite unmanaged route file: %s" % paths.route_definition])
	if str(route.get("route_id", "")) != request.route_id:
		return _failure(["route_id mismatch in route definition"])
	var nodes: Array = route.get("nodes", [])
	for node: Dictionary in nodes:
		if str(node.get("node_id", "")) == request.route_node_id:
			return _failure(["duplicate route node_id: %s" % request.route_node_id])
	nodes.append({"node_id": request.route_node_id, "level_id": request.level_id})
	route.nodes = nodes
	var edges: Array = route.get("edges", [])
	var edge_ids := {}; var profile_exit_keys := {}
	for existing: Dictionary in edges:
		edge_ids[str(existing.get("edge_id", ""))] = true
	for edge: Dictionary in request.edges:
		var edge_id := str(edge.get("edge_id", ""))
		if edge_ids.has(edge_id): return _failure(["duplicate route edge_id: %s" % edge_id])
		edge_ids[edge_id] = true
		edges.append(edge.duplicate(true))
	route.edges = edges
	var profiles: Array = route.get("profiles", [])
	var profiles_by_id := {}
	for profile: Dictionary in profiles:
		var existing_profile_id := str(profile.get("profile_id", ""))
		profiles_by_id[existing_profile_id] = profile
		for enabled_edge_id: Variant in profile.get("enabled_edge_ids", []):
			for existing_edge: Dictionary in edges:
				if str(existing_edge.get("edge_id", "")) == str(enabled_edge_id):
					profile_exit_keys["%s::%s::%s" % [existing_profile_id, existing_edge.from_node_id, existing_edge.exit_id]] = true
	for edge: Dictionary in request.edges:
		for profile_id: Variant in edge.get("profiles", ["production"]):
			var id := str(profile_id)
			if not profiles_by_id.has(id):
				var profile := {"profile_id": id, "entry_edge_id": "", "enabled_edge_ids": []}
				profiles.append(profile); profiles_by_id[id] = profile
			var target_profile: Dictionary = profiles_by_id[id]
			var key := "%s::%s::%s" % [id, edge.from_node_id, edge.exit_id]
			if profile_exit_keys.has(key): return _failure(["ambiguous profile exit mapping: %s" % key])
			profile_exit_keys[key] = true
			(target_profile.enabled_edge_ids as Array).append(edge.edge_id)
			if str(edge.from_node_id) == "@world_origin":
				if not str(target_profile.entry_edge_id).is_empty(): return _failure(["profile %s already has an entry edge" % id])
				target_profile.entry_edge_id = edge.edge_id
	if profiles.is_empty():
		return _failure(["route mutation requires at least one --edge with a profile"])
	for profile: Dictionary in profiles:
		if str(profile.get("entry_edge_id", "")).is_empty(): return _failure(["profile %s has no world-origin entry edge" % profile.get("profile_id", "")])
	route.profiles = profiles
	request.route_data = route
	return {"ok": true}


func _commit(request: RefCounted, paths: Dictionary, rendered: Dictionary) -> Dictionary:
	var stage_root: String = str(paths.output_root).path_join(".levelgen-stage-%s-%d" % [request.level_id, Time.get_ticks_msec()])
	var backups: Dictionary = {}
	var created: Array[String] = []
	var mutation_paths: Array[String] = []
	if request.register_level:
		mutation_paths.append(str(paths.registry))
	if request.create_route or request.append_to_route:
		mutation_paths.append(paths.route_definition)
		mutation_paths.append(paths.route_registry)
	for mutation_path in mutation_paths:
		if FileAccess.file_exists(mutation_path):
			var mutation_file := FileAccess.open(mutation_path, FileAccess.READ)
			backups[mutation_path] = mutation_file.get_buffer(mutation_file.get_length())
			mutation_file.close()
		else:
			created.append(mutation_path)
	for final_path: String in rendered.keys():
		var stage_path: String = stage_root.path_join(final_path.trim_prefix(str(paths.output_root) + "/"))
		if not _write_text(stage_path, rendered[final_path]):
			_remove_tree(stage_root)
			return _failure(["unable to stage %s" % final_path])
		if final_path.ends_with(".json") and _read_json(stage_path).is_empty():
			_remove_tree(stage_root)
			return _failure(["generated JSON did not parse: %s" % final_path])
	for final_path: String in rendered.keys():
		if FileAccess.file_exists(final_path):
			var existing := FileAccess.open(final_path, FileAccess.READ)
			backups[final_path] = existing.get_buffer(existing.get_length())
			existing.close()
		else:
			created.append(final_path)
		if not _write_text(final_path, rendered[final_path]):
			_rollback(created, backups)
			_remove_tree(stage_root)
			return _failure(["unable to commit %s" % final_path])
	if not _validate_committed_resources(paths):
		_rollback(created, backups)
		_remove_tree(stage_root)
		return _failure(["generated Godot resources did not load"])
	if request.register_level and not _update_registry(paths):
		_rollback(created, backups)
		_remove_tree(stage_root)
		return _failure(["registry update failed; generated files rolled back"])
	if (request.create_route or request.append_to_route) and not _commit_route_mutation(request, paths):
		_rollback(created, backups)
		_remove_tree(stage_root)
		return _failure(["route update failed; generated files rolled back"])
	_remove_tree(stage_root)
	return {
		"ok": true,
		"dry_run": false,
		"level_id": request.level_id,
		"created_files": rendered.keys(),
		"definition_path": _resource_path(paths.definition),
		"registry_path": paths.registry,
	}


func _commit_route_mutation(request: RefCounted, paths: Dictionary) -> bool:
	if not _atomic_write_text(paths.route_definition, JSON.stringify(request.route_data, "  ") + "\n"):
		return false
	var registry := {"schema": "custodian.route_registry.v1", "definitions": []}
	if FileAccess.file_exists(paths.route_registry):
		registry = _read_json(paths.route_registry)
	if str(registry.get("schema", "")) != "custodian.route_registry.v1":
		return false
	var definitions: Array = registry.get("definitions", [])
	var route_path := _resource_path(paths.route_definition)
	if not definitions.has(route_path): definitions.append(route_path)
	definitions.sort(); registry.definitions = definitions
	return _atomic_write_text(paths.route_registry, JSON.stringify(registry, "  ") + "\n")


func _validate_committed_resources(paths: Dictionary) -> bool:
	for path in [paths.production_script, paths.production_scene, paths.playtest_scene, paths.authoring_scene]:
		var resource_path := _resource_path(path)
		if not ResourceLoader.exists(resource_path):
			return false
		if load(resource_path) == null:
			return false
	return true


func _update_registry(paths: Dictionary) -> bool:
	var registry := {"schema": "custodian.level_registry.v1", "definitions": []}
	if FileAccess.file_exists(paths.registry):
		registry = _read_json(paths.registry)
	if str(registry.get("schema", "")) != "custodian.level_registry.v1":
		return false
	var definitions: Array = registry.get("definitions", [])
	var definition_path := _resource_path(paths.definition)
	if not definitions.has(definition_path):
		definitions.append(definition_path)
	definitions.sort()
	registry["definitions"] = definitions
	return _atomic_write_text(paths.registry, JSON.stringify(registry, "  ") + "\n")


func _resource_path(absolute_path: String) -> String:
	var res_root := ProjectSettings.globalize_path("res://").trim_suffix("/")
	if absolute_path.begins_with(res_root + "/"):
		return "res://" + absolute_path.trim_prefix(res_root + "/")
	var user_root := ProjectSettings.globalize_path("user://").trim_suffix("/")
	if absolute_path.begins_with(user_root + "/"):
		return "user://" + absolute_path.trim_prefix(user_root + "/")
	return absolute_path


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _write_text(path: String, text: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true


func _atomic_write_text(path: String, text: String) -> bool:
	var temp := "%s.tmp" % path
	if not _write_text(temp, text):
		return false
	var backup := "%s.levelgen-backup" % path
	DirAccess.remove_absolute(backup)
	if FileAccess.file_exists(path) and DirAccess.rename_absolute(path, backup) != OK:
		DirAccess.remove_absolute(temp)
		return false
	if DirAccess.rename_absolute(temp, path) != OK:
		if FileAccess.file_exists(backup): DirAccess.rename_absolute(backup, path)
		return false
	DirAccess.remove_absolute(backup)
	return true


func _rollback(created: Array[String], backups: Dictionary) -> void:
	for path in created:
		DirAccess.remove_absolute(path)
	for path: String in backups.keys():
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(backups[path] as PackedByteArray)
			file.close()


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := path.path_join(name)
		if directory.current_is_dir(): _remove_tree(child)
		else: DirAccess.remove_absolute(child)
		name = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)


func _failure(messages: Variant) -> Dictionary:
	var list := PackedStringArray()
	for message: Variant in messages:
		list.append(str(message))
	return {"ok": false, "errors": list}
