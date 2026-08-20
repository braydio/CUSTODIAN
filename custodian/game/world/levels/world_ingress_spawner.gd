class_name WorldIngressSpawner
extends Node

const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")
const LEVEL_LOADER_SCRIPT := preload("res://game/world/levels/level_loader.gd")
const ROUTE_REGISTRY_SCRIPT := preload("res://game/world/routes/route_registry.gd")
const ROUTE_MANAGER_SCRIPT := preload("res://game/world/routes/route_traversal_manager.gd")
const PLACEMENT_RESOLVER_SCRIPT := preload("res://game/world/levels/world_ingress_placement_resolver.gd")
const WORLD_INGRESS_SITE_SCRIPT := preload("res://game/world/procgen/ingress/world_ingress_site.gd")
const ASH_BELL_LIFT_INGRESS_SITE_SCRIPT := preload(
	"res://game/world/approaches/ash_bell/"
	+ "ash_bell_lift_ingress_site.gd"
)

@export_file("*.json") var registry_index_path := "res://content/levels/levels.json"
@export var fallback_tile_size := 16.0

var _last_placements: Dictionary = {}
var _last_errors := PackedStringArray()


func place_all(
	level_data: Dictionary,
	map_instance: Node,
	world: Node2D,
	level_loader: Node = null,
	definitions_override: Array = []
) -> Array[Node]:
	_last_placements.clear()
	_last_errors.clear()
	_clear_generated(world)
	if map_instance != null and map_instance.has_method(
		"clear_world_ingress_dressing_clearances"
	):
		map_instance.call("clear_world_ingress_dressing_clearances")
	var definitions: Array = []
	if definitions_override.is_empty():
		var registry: RefCounted = LEVEL_REGISTRY_SCRIPT.new()
		if not registry.call("load_index", registry_index_path):
			_last_errors = registry.call("get_errors")
			_observe(&"level_ingress_placement_failed", {"reason": "; ".join(_last_errors)})
			return []
		for definition: RefCounted in registry.call("get_levels_with_tag", &"world_ingress"):
			definitions.append(_level_record(definition))
		var route_registry: RefCounted = ROUTE_REGISTRY_SCRIPT.new()
		if not route_registry.call("load_index", ROUTE_REGISTRY_SCRIPT.DEFAULT_INDEX_PATH, registry):
			for error: String in route_registry.call("get_errors"):
				_last_errors.append("route registry: %s" % error)
			return []
		for route: RefCounted in route_registry.call("get_routes_with_tag", &"world_ingress"):
			definitions.append(_route_record(route))
	else:
		for definition: Variant in definitions_override:
			if definition is RefCounted:
				definitions.append(_level_record(definition as RefCounted))
	var ingress_ids: Dictionary = {}
	for record: Dictionary in definitions:
		var ingress: RefCounted = record.get("ingress") as RefCounted
		if ingress == null:
			continue
		if ingress_ids.has(ingress.ingress_id):
			_last_errors.append("duplicate ingress_id across level/route registries: %s" % ingress.ingress_id)
		else:
			ingress_ids[ingress.ingress_id] = record.get("identity")
	if not _last_errors.is_empty():
		return []
	definitions.sort_custom(_definition_precedes)
	if level_loader == null:
		level_loader = _ensure_level_loader(world)
	_ensure_route_manager(world)
	var resolver: RefCounted = PLACEMENT_RESOLVER_SCRIPT.new()
	var occupied_tiles: Array[Vector2i] = []
	var placed: Array[Node] = []
	for record: Dictionary in definitions:
		var ingress_definition: RefCounted = record.get("ingress") as RefCounted
		if ingress_definition == null:
			continue
		var result := _resolve_authored_ingress_candidate(
			resolver, ingress_definition.placement, level_data, map_instance,
			occupied_tiles, str(record.get("identity")), String(ingress_definition.ingress_id)
		)
		if not bool(result.get("ok", false)):
			var reason := "%s: %s" % [record.get("identity"), str(result.get("reason", "placement failed"))]
			_last_errors.append(reason)
			_observe(&"level_ingress_placement_failed", {"identity": str(record.get("identity")), "ingress_id": String(ingress_definition.ingress_id), "reason": reason})
			continue
		var tile := result.get("tile") as Vector2i
		var ingress := _create_ingress(record, map_instance)
		if ingress == null:
			continue
		ingress.global_position = _tile_to_world(map_instance, tile)
		ingress.set_meta(
			"world_ingress_outward_direction",
			result.get("outward_direction", Vector2i.ZERO)
		)
		ingress.set_meta(
			"world_ingress_edge_distance_tiles",
			int(result.get("edge_distance_tiles", -1))
		)
		ingress.set_meta(
			"world_ingress_unlock_causeway",
			(result.get("unlock_causeway", {}) as Dictionary).duplicate(true)
		)
		world.add_child(ingress)
		_apply_ingress_dressing_clearance(map_instance, ingress)
		occupied_tiles.append(tile)
		placed.append(ingress)
		_last_placements[str(record.get("identity"))] = tile
		_observe(&"level_ingress_placed", {
			"identity": str(record.get("identity")),
			"ingress_id": String(ingress_definition.ingress_id),
			"tile": [tile.x, tile.y],
		})
	return placed


func _resolve_authored_ingress_candidate(
	resolver: RefCounted,
	placement: Dictionary,
	level_data: Dictionary,
	map_instance: Node,
	occupied_tiles: Array[Vector2i],
	identity: String,
	ingress_id: String
) -> Dictionary:
	var rejected: Array[Vector2i] = []
	for attempt in range(12):
		var result := resolver.call(
			"resolve", placement, level_data, map_instance, occupied_tiles, rejected
		) as Dictionary
		if not bool(result.get("ok", false)):
			return result
		if not bool(result.get("requires_authored_pocket", false)):
			return result
		var tile := result.get("tile", Vector2i.ZERO) as Vector2i
		var pocket_result := _author_overlook_pocket(map_instance, result)
		if pocket_result.size != Vector2i.ZERO and _validate_unlock_causeway_contract(map_instance, result):
			result["placement_attempt"] = attempt + 1
			return result
		rejected.append(tile)
		_observe(&"level_ingress_candidate_rejected", {
			"identity": identity,
			"ingress_id": ingress_id,
			"tile": tile,
			"attempt": attempt + 1,
			"reason": "authored pocket is not canonically connector-resolvable",
			"connector_diagnostic": result.get("connector_diagnostic", {}),
		})
	return {
		"ok": false,
		"reason": "no canonically connector-resolvable authored pocket after 12 deterministic candidates",
		"rejected_tiles": rejected,
	}


func _validate_unlock_causeway_contract(map_instance: Node, result: Dictionary) -> bool:
	var config := result.get("unlock_causeway", {}) as Dictionary
	if config.is_empty() or not bool(config.get("initially_isolated", false)):
		return true
	if map_instance == null or not map_instance.has_method("evaluate_runtime_walkable_connector"):
		return false
	var tile := result.get("tile", Vector2i.ZERO) as Vector2i
	var outward := result.get("outward_direction", Vector2i.UP) as Vector2i
	var plan := map_instance.call(
		"evaluate_runtime_walkable_connector",
		_tile_to_world(map_instance, tile),
		-outward,
		int(config.get("width_tiles", 3)),
		int(config.get("max_length_tiles", 18)),
		"ash_bell_threadway",
		"white_thread",
		-1,
		StringName(config.get("routing_profile", "direct"))
	) as Dictionary
	result["connector_diagnostic"] = plan.duplicate(true)
	if bool(plan.get("ok", false)):
		_observe(&"ash_bell_threadway_placement_validated", {
			"tile": tile,
			"island_anchor": plan.get("island_anchor_tile"),
			"endpoint": plan.get("endpoint_tile"),
			"cell_count": (plan.get("cells", []) as Array).size(),
		})
		return true
	return false


func _apply_ingress_dressing_clearance(
	map_instance: Node,
	ingress: Node
) -> void:
	if (
		map_instance == null
		or ingress == null
		or not ingress.has_method("get_procgen_dressing_clearance_world_rect")
		or not map_instance.has_method("claim_world_ingress_dressing_clearance")
	):
		return
	var world_rect := ingress.call(
		"get_procgen_dressing_clearance_world_rect"
	) as Rect2
	if world_rect.has_area():
		map_instance.call(
			"claim_world_ingress_dressing_clearance",
			world_rect
		)


func _author_overlook_pocket(
	map_instance: Node,
	result: Dictionary
) -> Rect2i:
	if (
		map_instance == null
		or not map_instance.has_method(
			"claim_world_overlook_pocket"
		)
	):
		return Rect2i()
	return map_instance.call(
		"claim_world_overlook_pocket",
		result.get("pocket_center_tile") as Vector2i,
		result.get("pocket_size_tiles") as Vector2i,
		result.get("unlock_causeway", {}) as Dictionary
	) as Rect2i


func get_last_placements() -> Dictionary:
	return _last_placements.duplicate(true)


func get_last_errors() -> PackedStringArray:
	return _last_errors.duplicate()


func _definition_precedes(a: Dictionary, b: Dictionary) -> bool:
	var a_ingress: RefCounted = a.get("ingress") as RefCounted
	var b_ingress: RefCounted = b.get("ingress") as RefCounted
	var a_priority := int(a_ingress.placement.get("priority", 0))
	var b_priority := int(b_ingress.placement.get("priority", 0))
	if a_priority != b_priority:
		return a_priority > b_priority
	return str(a.get("identity")) < str(b.get("identity"))


func _create_ingress(record: Dictionary, map_instance: Node) -> Area2D:
	var definition: RefCounted = record.get("definition") as RefCounted
	var ingress_definition: RefCounted = record.get("ingress") as RefCounted
	var ingress: Area2D = null
	if not String(ingress_definition.site_scene_path).is_empty():
		var site_scene := ResourceLoader.load(
			ingress_definition.site_scene_path
		) as PackedScene
		if site_scene != null:
			ingress = site_scene.instantiate() as Area2D
		if (
			ingress == null
			or not ingress.has_method("configure_route")
			or not ingress.has_method("configure_level")
			or not ingress.has_method("apply_ingress_definition")
		):
			_last_errors.append(
				"%s: custom site_scene_path must instantiate an Area2D-compatible WorldIngressSite"
				% str(record.get("identity"))
			)
			if ingress != null:
				ingress.free()
			return null
	else:
		var ingress_script: Script = WORLD_INGRESS_SITE_SCRIPT
		if str(record.get("identity")) == "forlorn_ritualant_underground":
			ingress_script = ASH_BELL_LIFT_INGRESS_SITE_SCRIPT
		ingress = ingress_script.new() as Area2D
	if ingress == null:
		return null
	ingress.name = "%sIngressSite" % String(ingress_definition.ingress_id).to_pascal_case()
	ingress.add_to_group("generated_world_ingress")
	ingress.add_to_group("generated_world_ingress_%s" % str(record.get("identity")).validate_node_name().to_snake_case())
	if str(record.get("identity")) == "sundered_keep":
		ingress.add_to_group("generated_sundered_keep_connection")
	if str(record.get("mode")) == "route":
		ingress.call("configure_route", definition.route_id, ingress_definition.route_profile, map_instance)
	else:
		ingress.call("configure_level", definition.level_id, map_instance)
	ingress.call("apply_ingress_definition", ingress_definition)
	ingress.set("allow_legacy_registered_fallback", false)
	return ingress


func _level_record(definition: RefCounted) -> Dictionary:
	return {"mode": "level", "identity": String(definition.level_id), "definition": definition, "ingress": definition.ingress}


func _route_record(definition: RefCounted) -> Dictionary:
	return {"mode": "route", "identity": String(definition.route_id), "definition": definition, "ingress": definition.ingress}


func _clear_generated(world: Node) -> void:
	for child in world.get_children():
		if child.is_in_group("generated_world_ingress"):
			child.queue_free()


func _ensure_level_loader(world: Node) -> Node:
	var existing := world.get_node_or_null("LevelLoader")
	if existing != null:
		return existing
	var loader := LEVEL_LOADER_SCRIPT.new()
	loader.name = "LevelLoader"
	world.add_child(loader)
	return loader


func _ensure_route_manager(world: Node) -> Node:
	var existing := world.get_node_or_null("RouteTraversalManager")
	if existing != null:
		return existing
	var manager := ROUTE_MANAGER_SCRIPT.new()
	manager.name = "RouteTraversalManager"
	world.add_child(manager)
	return manager


func _tile_to_world(map_instance: Node, tile: Vector2i) -> Vector2:
	if map_instance is ProcGenTilemap:
		var procgen := map_instance as ProcGenTilemap
		if procgen.floor_tilemap != null:
			return procgen.floor_tilemap.to_global(procgen.floor_tilemap.map_to_local(tile))
	if map_instance is Node2D:
		return (map_instance as Node2D).global_position + Vector2(tile) * fallback_tile_size
	return Vector2(tile) * fallback_tile_size


func _observe(event_name: StringName, payload: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", event_name, payload)
