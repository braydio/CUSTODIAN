extends SceneTree

const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")
const ROUTE_REGISTRY_SCRIPT := preload("res://game/world/routes/route_registry.gd")
const INGRESS_SPAWNER_SCRIPT := preload("res://game/world/levels/world_ingress_spawner.gd")
const INGRESS_DEFINITION_SCRIPT := preload("res://game/world/levels/world_ingress_definition.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var levels := LEVEL_REGISTRY_SCRIPT.new()
	assert(levels.load_index(), "; ".join(levels.get_errors()))
	var routes := ROUTE_REGISTRY_SCRIPT.new()
	assert(routes.load_index(ROUTE_REGISTRY_SCRIPT.DEFAULT_INDEX_PATH, levels), "; ".join(routes.get_errors()))
	var route: RefCounted = routes.get_route(&"ash_bell_lower_quarter")
	assert(route != null)
	var profile: RefCounted = route.get_profile(&"production")
	assert(profile != null)
	assert(route.ingress.site_scene_path == "res://game/world/approaches/ash_bell/lower_quarter/meridian_transit_ingress_site.tscn")
	var ingress_scene := ResourceLoader.load(route.ingress.site_scene_path) as PackedScene
	assert(ingress_scene != null)
	var ingress := ingress_scene.instantiate()
	assert(ingress is MeridianTransitIngressSite)
	ingress.free()
	var ingress_spawner := INGRESS_SPAWNER_SCRIPT.new()
	var spawned_ingress := ingress_spawner.call("_create_ingress", {
		"mode": "route",
		"identity": "ash_bell_lower_quarter",
		"definition": route,
		"ingress": route.ingress,
	}, null) as Area2D
	assert(spawned_ingress is MeridianTransitIngressSite)
	assert(spawned_ingress.route_id == &"ash_bell_lower_quarter")
	assert(spawned_ingress.route_profile == &"production")
	spawned_ingress.free()
	ingress_spawner.free()
	var ritualant: RefCounted = routes.get_route(&"forlorn_ritualant_underground")
	var sundered: RefCounted = routes.get_route(&"sundered_keep")
	assert(ritualant != null and ritualant.ingress.site_scene_path.is_empty())
	assert(sundered != null and sundered.ingress.site_scene_path.is_empty())
	var invalid_ingress := INGRESS_DEFINITION_SCRIPT.new()
	invalid_ingress.configure_from_dictionary({
		"ingress_id": "invalid_custom_site",
		"prompt_text": "ENTER",
		"site_scene_path": "res://missing_custom_ingress.tscn",
	})
	assert(invalid_ingress.site_scene_path == "res://missing_custom_ingress.tscn")
	var invalid_site_rejected := false
	for error: String in invalid_ingress.validate():
		if "site_scene_path must resolve to a PackedScene" in error:
			invalid_site_rejected = true
	assert(invalid_site_rejected)
	assert(route.nodes.size() == 3)
	assert(profile.enabled_edge_ids.size() == 6)
	assert(profile.entry_edge_id == &"enter_lower_quarter")
	assert(route.validate(levels).is_empty())
	var mappings: Dictionary = {}
	for edge_id: StringName in profile.enabled_edge_ids:
		var edge: RefCounted = route.get_edge(edge_id)
		assert(edge != null)
		var key := "%s::%s" % [edge.from_node_id, edge.exit_id]
		assert(not mappings.has(key))
		mappings[key] = true
		if edge.to_node_id != &"@world_origin":
			var target_node: RefCounted = route.get_node_definition(edge.to_node_id)
			assert(levels.level_has_spawn(target_node.level_id, edge.target_spawn_id))
	for node_id: StringName in [&"lower_quarter", &"west_gate_works", &"station_ix"]:
		var node_definition: RefCounted = route.get_node_definition(node_id)
		assert(node_definition != null)
		var level_definition: RefCounted = levels.get_level(node_definition.level_id)
		var scene := ResourceLoader.load(level_definition.target_scene_path) as PackedScene
		assert(scene != null)
		var instance := scene.instantiate()
		assert(instance is AuthoredLevel2D)
		root.add_child(instance)
		await process_frame
		instance.free()
	print("ash_bell_lower_quarter_route_smoke: PASS nodes=3 edges=6")
	quit(0)
