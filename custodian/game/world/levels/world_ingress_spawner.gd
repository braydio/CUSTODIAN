class_name WorldIngressSpawner
extends Node

const LEVEL_REGISTRY_SCRIPT := preload("res://game/world/levels/level_registry.gd")
const LEVEL_LOADER_SCRIPT := preload("res://game/world/levels/level_loader.gd")
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
	var definitions := definitions_override.duplicate()
	if definitions.is_empty():
		var registry: RefCounted = LEVEL_REGISTRY_SCRIPT.new()
		if not registry.call("load_index", registry_index_path):
			_last_errors = registry.call("get_errors")
			_observe(&"level_ingress_placement_failed", {"reason": "; ".join(_last_errors)})
			return []
		definitions = registry.call("get_levels_with_tag", &"world_ingress")
	definitions.sort_custom(_definition_precedes)
	if level_loader == null:
		level_loader = _ensure_level_loader(world)
	var resolver: RefCounted = PLACEMENT_RESOLVER_SCRIPT.new()
	var occupied_tiles: Array[Vector2i] = []
	var placed: Array[Node] = []
	for definition: RefCounted in definitions:
		if definition == null or definition.ingress == null:
			continue
		var result: Dictionary = resolver.call(
			"resolve",
			definition.ingress.placement,
			level_data,
			map_instance,
			occupied_tiles
		)
		if not bool(result.get("ok", false)):
			var reason := "%s: %s" % [definition.level_id, str(result.get("reason", "placement failed"))]
			_last_errors.append(reason)
			_observe(&"level_ingress_placement_failed", {"level_id": String(definition.level_id), "reason": reason})
			continue
		var tile := result.get("tile") as Vector2i
		var ingress := _create_ingress(definition, map_instance)
		if ingress == null:
			continue
		ingress.global_position = _tile_to_world(map_instance, tile)
		world.add_child(ingress)
		occupied_tiles.append(tile)
		placed.append(ingress)
		_last_placements[String(definition.level_id)] = tile
		_observe(&"level_ingress_placed", {
			"level_id": String(definition.level_id),
			"ingress_id": String(definition.ingress.ingress_id),
			"tile": [tile.x, tile.y],
		})
	return placed


func get_last_placements() -> Dictionary:
	return _last_placements.duplicate(true)


func get_last_errors() -> PackedStringArray:
	return _last_errors.duplicate()


func _definition_precedes(a: RefCounted, b: RefCounted) -> bool:
	var a_priority := int(a.ingress.placement.get("priority", 0))
	var b_priority := int(b.ingress.placement.get("priority", 0))
	if a_priority != b_priority:
		return a_priority > b_priority
	return String(a.level_id) < String(b.level_id)


func _create_ingress(definition: RefCounted, map_instance: Node) -> Area2D:
	var ingress := WORLD_INGRESS_SITE_SCRIPT.new() as Area2D
	if ingress == null:
		return null
	ingress.name = "%sIngressSite" % String(definition.ingress.ingress_id).to_pascal_case()
	ingress.add_to_group("generated_world_ingress")
	ingress.add_to_group("generated_world_ingress_%s" % String(definition.level_id).validate_node_name().to_snake_case())
	if String(definition.level_id) == "sundered_keep_front_gate":
		ingress.add_to_group("generated_sundered_keep_connection")
	var entry_scene := load(definition.call("get_entry_scene_path")) as PackedScene
	ingress.call(
		"configure",
		definition.ingress.ingress_id,
		entry_scene,
		definition.target_scene_path,
		definition.ingress.target_spawn_id
	)
	ingress.call("configure_level", definition.level_id, map_instance)
	ingress.call("apply_ingress_definition", definition.ingress)
	ingress.set("allow_legacy_registered_fallback", false)
	return ingress


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
