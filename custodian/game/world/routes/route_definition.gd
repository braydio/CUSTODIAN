class_name RouteDefinition
extends RefCounted

const NODE_SCRIPT := preload("res://game/world/routes/route_node_definition.gd")
const EDGE_SCRIPT := preload("res://game/world/routes/route_edge_definition.gd")
const PROFILE_SCRIPT := preload("res://game/world/routes/route_profile_definition.gd")
const INGRESS_SCRIPT := preload("res://game/world/levels/world_ingress_definition.gd")
const WORLD_ORIGIN := &"@world_origin"

var route_id: StringName = &""
var display_name: String = ""
var world_context: StringName = &""
var default_profile: StringName = &""
var tags: Array[StringName] = []
var ingress: RefCounted
var nodes: Dictionary = {}
var edges: Dictionary = {}
var profiles: Dictionary = {}
var _configuration_errors := PackedStringArray()


func configure_from_dictionary(data: Dictionary) -> void:
	_configuration_errors.clear()
	route_id = StringName(str(data.get("route_id", "")))
	display_name = str(data.get("display_name", ""))
	world_context = StringName(str(data.get("world_context", "")))
	default_profile = StringName(str(data.get("default_profile", "")))
	tags.clear()
	for tag: Variant in data.get("tags", []):
		tags.append(StringName(str(tag)))
	ingress = null
	var ingress_data: Variant = data.get("ingress", {})
	if ingress_data is Dictionary and not ingress_data.is_empty():
		ingress = INGRESS_SCRIPT.new()
		ingress.call("configure_from_dictionary", ingress_data)
	nodes.clear()
	for node_data: Variant in data.get("nodes", []):
		if node_data is Dictionary:
			var node: RefCounted = NODE_SCRIPT.new()
			node.call("configure_from_dictionary", node_data)
			if nodes.has(node.node_id):
				_configuration_errors.append("duplicate node_id: %s" % node.node_id)
			nodes[node.node_id] = node
	edges.clear()
	for edge_data: Variant in data.get("edges", []):
		if edge_data is Dictionary:
			var edge: RefCounted = EDGE_SCRIPT.new()
			edge.call("configure_from_dictionary", edge_data)
			if edges.has(edge.edge_id):
				_configuration_errors.append("duplicate edge_id: %s" % edge.edge_id)
			edges[edge.edge_id] = edge
	profiles.clear()
	for profile_data: Variant in data.get("profiles", []):
		if profile_data is Dictionary:
			var profile: RefCounted = PROFILE_SCRIPT.new()
			profile.call("configure_from_dictionary", profile_data)
			if profiles.has(profile.profile_id):
				_configuration_errors.append("duplicate profile_id: %s" % profile.profile_id)
			profiles[profile.profile_id] = profile


func validate(level_registry: RefCounted) -> PackedStringArray:
	var errors := _configuration_errors.duplicate()
	if route_id.is_empty():
		errors.append("route_id is required")
	if display_name.strip_edges().is_empty():
		errors.append("display_name is required")
	if world_context.is_empty():
		errors.append("world_context is required")
	if nodes.is_empty():
		errors.append("nodes cannot be empty")
	if edges.is_empty():
		errors.append("edges cannot be empty")
	if profiles.is_empty():
		errors.append("profiles cannot be empty")
	if ingress != null:
		for ingress_error: String in ingress.call("validate"):
			errors.append("ingress.%s" % ingress_error)
	if not profiles.has(default_profile):
		errors.append("default_profile does not exist: %s" % default_profile)
	for node_id: Variant in nodes.keys():
		var node: RefCounted = nodes[node_id]
		for node_error: String in node.call("validate"):
			errors.append("node %s: %s" % [node_id, node_error])
		if level_registry == null or not bool(level_registry.call("has_level", node.level_id)):
			errors.append("node %s references unknown level_id %s" % [node_id, node.level_id])
	for edge_id: Variant in edges.keys():
		var edge: RefCounted = edges[edge_id]
		for edge_error: String in edge.call("validate"):
			errors.append("edge %s: %s" % [edge_id, edge_error])
		if edge.from_node_id != WORLD_ORIGIN and not nodes.has(edge.from_node_id):
			errors.append("edge %s has unknown source node %s" % [edge_id, edge.from_node_id])
		if edge.to_node_id != WORLD_ORIGIN and not nodes.has(edge.to_node_id):
			errors.append("edge %s has unknown target node %s" % [edge_id, edge.to_node_id])
		if edge.to_node_id != WORLD_ORIGIN and nodes.has(edge.to_node_id) and level_registry != null:
			var target_node: RefCounted = nodes[edge.to_node_id]
			if not bool(level_registry.call("level_has_spawn", target_node.level_id, edge.target_spawn_id)):
				errors.append("edge %s target spawn does not exist: %s/%s" % [edge_id, target_node.level_id, edge.target_spawn_id])
	for profile_id: Variant in profiles.keys():
		_validate_profile(profiles[profile_id], errors)
	return errors


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


func get_node_definition(node_id: StringName) -> RefCounted:
	return nodes.get(node_id) as RefCounted


func get_edge(edge_id: StringName) -> RefCounted:
	return edges.get(edge_id) as RefCounted


func get_profile(profile_id: StringName) -> RefCounted:
	return profiles.get(profile_id) as RefCounted


func resolve_exit(profile_id: StringName, node_id: StringName, exit_id: StringName) -> Array[RefCounted]:
	var result: Array[RefCounted] = []
	var profile := get_profile(profile_id)
	if profile == null:
		return result
	for edge_id: StringName in profile.enabled_edge_ids:
		var edge := get_edge(edge_id)
		if edge != null and edge.from_node_id == node_id and edge.exit_id == exit_id:
			result.append(edge)
	return result


func _validate_profile(profile: RefCounted, errors: PackedStringArray) -> void:
	for profile_error: String in profile.call("validate"):
		errors.append("profile %s: %s" % [profile.profile_id, profile_error])
	var entry := get_edge(profile.entry_edge_id)
	if entry == null:
		errors.append("profile %s references unknown entry edge %s" % [profile.profile_id, profile.entry_edge_id])
	elif entry.from_node_id != WORLD_ORIGIN:
		errors.append("profile %s entry edge must start at @world_origin" % profile.profile_id)
	var exit_keys: Dictionary = {}
	for edge_id: StringName in profile.enabled_edge_ids:
		var edge := get_edge(edge_id)
		if edge == null:
			errors.append("profile %s references unknown edge %s" % [profile.profile_id, edge_id])
			continue
		if edge.from_node_id == WORLD_ORIGIN and edge_id != profile.entry_edge_id:
			errors.append("profile %s enables non-entry edge from @world_origin: %s" % [profile.profile_id, edge_id])
		var key := "%s::%s" % [edge.from_node_id, edge.exit_id]
		if exit_keys.has(key):
			errors.append("profile %s has duplicate exit mapping %s" % [profile.profile_id, key])
		exit_keys[key] = edge_id
	if entry != null and not profile.allow_no_exfil:
		_validate_connectivity(profile, entry.to_node_id, errors)


func _validate_connectivity(profile: RefCounted, entry_node_id: StringName, errors: PackedStringArray) -> void:
	var adjacency: Dictionary = {}
	for edge_id: StringName in profile.enabled_edge_ids:
		var edge := get_edge(edge_id)
		if edge == null or edge.from_node_id == WORLD_ORIGIN:
			continue
		if not adjacency.has(edge.from_node_id):
			adjacency[edge.from_node_id] = []
		(adjacency[edge.from_node_id] as Array).append(edge.to_node_id)
	var reachable := _walk(entry_node_id, adjacency, false)
	for node_id: Variant in reachable.keys():
		if node_id == WORLD_ORIGIN:
			continue
		if not _can_reach_world(node_id as StringName, adjacency):
			errors.append("profile %s node %s has no path to @world_origin" % [profile.profile_id, node_id])


func _walk(start: StringName, adjacency: Dictionary, stop_at_world: bool) -> Dictionary:
	var seen: Dictionary = {}
	var pending: Array[StringName] = [start]
	while not pending.is_empty():
		var current: StringName = pending.pop_front()
		if seen.has(current):
			continue
		seen[current] = true
		if stop_at_world and current == WORLD_ORIGIN:
			continue
		for target: Variant in adjacency.get(current, []):
			pending.append(target as StringName)
	return seen


func _can_reach_world(start: StringName, adjacency: Dictionary) -> bool:
	return _walk(start, adjacency, true).has(WORLD_ORIGIN)
