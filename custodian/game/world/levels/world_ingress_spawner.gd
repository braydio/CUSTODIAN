class_name WorldIngressSpawner
extends Node

const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")
const LEVEL_LOADER_SCRIPT := preload("res://game/world/levels/level_loader.gd")
const ROUTE_REGISTRY_SCRIPT := preload("res://game/world/routes/route_registry.gd")
const ROUTE_MANAGER_SCRIPT := preload("res://game/world/routes/route_traversal_manager.gd")
const PLACEMENT_RESOLVER_SCRIPT := preload("res://game/world/levels/world_ingress_placement_resolver.gd")
const WORLD_INGRESS_SITE_SCRIPT := preload("res://game/world/procgen/ingress/world_ingress_site.gd")

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
		var result: Dictionary = resolver.call(
			"resolve",
			ingress_definition.placement,
			level_data,
			map_instance,
			occupied_tiles
		)
		if not bool(result.get("ok", false)):
			var reason := "%s: %s" % [record.get("identity"), str(result.get("reason", "placement failed"))]
			_last_errors.append(reason)
			_observe(&"level_ingress_placement_failed", {"identity": str(record.get("identity")), "reason": reason})
			continue
		var tile := result.get("tile") as Vector2i
		var ingress := _create_ingress(record, map_instance)
		if ingress == null:
			continue
		ingress.global_position = _tile_to_world(map_instance, tile)
		world.add_child(ingress)
		occupied_tiles.append(tile)
		placed.append(ingress)
		_last_placements[str(record.get("identity"))] = tile
		_observe(&"level_ingress_placed", {
			"identity": str(record.get("identity")),
			"ingress_id": String(ingress_definition.ingress_id),
			"tile": [tile.x, tile.y],
		})
	return placed


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
	var ingress := WORLD_INGRESS_SITE_SCRIPT.new() as Area2D
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
