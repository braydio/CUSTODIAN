extends Node

@export var contract_map_path: NodePath = NodePath("/root/GameRoot/World/ContractMap")
@export var critter_container_path: NodePath = NodePath("/root/GameRoot/World/Enemies")
@export var critter_scene: PackedScene
@export var critter_count: int = 2
@export var min_distance_from_spawn_tiles: int = 8
@export var preferred_habitat_groups: PackedStringArray = PackedStringArray(["vegetation", "ambient_cover"])

var _contract_map_node: Node = null
var _spawned_critters: Array[Node] = []


func _ready() -> void:
	call_deferred("_bind_contract_map")


func _bind_contract_map() -> void:
	_contract_map_node = get_node_or_null(contract_map_path)
	if _contract_map_node == null or not _contract_map_node.has_signal("contract_generated"):
		return
	var callback := Callable(self, "_on_contract_generated")
	if not _contract_map_node.is_connected("contract_generated", callback):
		_contract_map_node.connect("contract_generated", callback)
	if _contract_map_node.has_method("get_latest_contract"):
		var latest: Variant = _contract_map_node.call("get_latest_contract")
		if latest is Dictionary and not (latest as Dictionary).is_empty():
			_on_contract_generated(latest as Dictionary)


func _on_contract_generated(contract: Dictionary) -> void:
	_clear_spawned_critters()
	if critter_scene == null or critter_count <= 0:
		return

	var map_block: Dictionary = contract.get("map", {}) as Dictionary
	var level_data: Dictionary = map_block.get("level_data", {}) as Dictionary
	var map_instance_variant: Variant = map_block.get("instance")
	if not (map_instance_variant is Node):
		return
	var map_instance := map_instance_variant as Node
	var container := get_node_or_null(critter_container_path)
	if container == null:
		return

	var candidate_tiles := _collect_candidate_tiles(level_data)
	if candidate_tiles.is_empty():
		return

	var spawn_tile: Vector2i = level_data.get("player_spawn", Vector2i.ZERO) as Vector2i
	var habitat_positions := _collect_habitat_positions()
	candidate_tiles.shuffle()
	candidate_tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_world := _tile_to_world(map_instance, a)
		var b_world := _tile_to_world(map_instance, b)
		var a_score := float(a.distance_squared_to(spawn_tile))
		var b_score := float(b.distance_squared_to(spawn_tile))
		if not habitat_positions.is_empty():
			a_score -= _nearest_habitat_distance_squared(a_world, habitat_positions) * 0.45
			b_score -= _nearest_habitat_distance_squared(b_world, habitat_positions) * 0.45
		return a_score > b_score
	)

	var spawned := 0
	for tile in candidate_tiles:
		if tile.distance_to(spawn_tile) < float(min_distance_from_spawn_tiles):
			continue
		var critter := critter_scene.instantiate()
		if critter == null:
			continue
		container.add_child(critter)
		if critter is Node2D:
			(critter as Node2D).global_position = _tile_to_world(map_instance, tile)
			_apply_critter_variation(critter as Node2D, spawned)
		_spawned_critters.append(critter)
		spawned += 1
		if spawned >= critter_count:
			break


func _collect_candidate_tiles(level_data: Dictionary) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for item in level_data.get("random_floor_tiles", []):
		if item is Vector2i:
			tiles.append(item as Vector2i)
	if tiles.is_empty():
		for item in level_data.get("rooms_by_distance", []):
			if item is Vector2i:
				tiles.append(item as Vector2i)
	return tiles


func _apply_critter_variation(critter: Node2D, index: int) -> void:
	var variants := [
		{
			"name": "SCRAP DROID",
			"tint": Color(0.52, 0.48, 0.41, 1.0),
			"scale": Vector2(0.92, 0.92),
		},
		{
			"name": "DUST MITE",
			"tint": Color(0.42, 0.56, 0.52, 1.0),
			"scale": Vector2(0.84, 0.84),
		},
	]
	var data: Dictionary = variants[index % variants.size()]
	if "enemy_name" in critter:
		critter.set("enemy_name", String(data.get("name", "SCRAP DROID")))
	if "base_tint" in critter:
		critter.set("base_tint", data.get("tint", Color.WHITE))
	if critter.has_method("update_visuals"):
		critter.call("update_visuals")
	critter.scale = data.get("scale", Vector2.ONE)


func _collect_habitat_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for group_name in preferred_habitat_groups:
		for node in get_tree().get_nodes_in_group(String(group_name)):
			if node is Node2D:
				positions.append((node as Node2D).global_position)
	return positions


func _nearest_habitat_distance_squared(world_pos: Vector2, habitat_positions: Array[Vector2]) -> float:
	if habitat_positions.is_empty():
		return 0.0
	var best := INF
	for habitat_pos in habitat_positions:
		best = min(best, world_pos.distance_squared_to(habitat_pos))
	return best


func _tile_to_world(map_instance: Node, tile: Vector2i) -> Vector2:
	if map_instance is ProcGenTilemap:
		var procgen_map := map_instance as ProcGenTilemap
		if procgen_map.floor_tilemap != null:
			var tilemap: TileMapLayer = procgen_map.floor_tilemap
			var local := tilemap.map_to_local(tile)
			return tilemap.to_global(local)
	if map_instance is Node2D:
		return (map_instance as Node2D).global_position + Vector2(tile) * 16.0
	return Vector2(tile) * 16.0


func _clear_spawned_critters() -> void:
	for critter in _spawned_critters:
		if critter != null and is_instance_valid(critter):
			critter.queue_free()
	_spawned_critters.clear()
