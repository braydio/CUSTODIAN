extends Node

@export var contract_map_path: NodePath = NodePath("/root/GameRoot/World/ContractMap")
@export var critter_container_path: NodePath = NodePath("/root/GameRoot/World/Enemies")
@export var critter_scene: PackedScene
@export var critter_count: int = 3
@export var min_distance_from_spawn_tiles: int = 8
@export var preferred_habitat_groups: PackedStringArray = PackedStringArray(["vegetation", "ambient_cover"])

@export var ambient_spawn_enabled: bool = true
@export var ambient_spawn_interval: float = 15.0
@export var ambient_max_count: int = 8
@export var ambient_spawn_radius_min: float = 200.0
@export var ambient_spawn_radius_max: float = 600.0

var _contract_map_node: Node = null
var _spawned_critters: Array[Node] = []
var _ambient_spawn_timer: float = 0.0
var _critter_rng := RandomNumberGenerator.new()
var _planet_world_profile: Dictionary = {}
var _base_critter_count: int = 0
var _base_ambient_max_count: int = 0
var _base_ambient_spawn_interval: float = 0.0
var _profile_critter_speed_multiplier: float = 1.0
var _profile_critter_scale_multiplier: float = 1.0
var _profile_critter_name_prefix: String = ""
var _profile_critter_traits: PackedStringArray = PackedStringArray()

# Shrumb variants - different appearances for atmosphere
var SHRUMB_VARIANTS := [
	{"name": "SHRUMB", "tint": Color(0.45, 0.55, 0.35, 1.0), "scale": Vector2(1.05, 1.05), "speed_mod": 1.0},
	{"name": "SPORE SHRUMB", "tint": Color(0.55, 0.40, 0.50, 1.0), "scale": Vector2(0.98, 0.98), "speed_mod": 1.2},
	{"name": "LUMEN SHRUMB", "tint": Color(0.40, 0.50, 0.60, 1.0), "scale": Vector2(1.10, 1.10), "speed_mod": 0.9},
	{"name": "CLAY SHRUMB", "tint": Color(0.50, 0.45, 0.40, 1.0), "scale": Vector2(1.16, 1.16), "speed_mod": 0.8},
	{"name": "TENDRILE SHRUMB", "tint": Color(0.38, 0.52, 0.42, 1.0), "scale": Vector2(1.02, 1.12), "speed_mod": 1.1},
	{"name": "RUST SHRUMB", "tint": Color(0.48, 0.42, 0.38, 1.0), "scale": Vector2(1.08, 1.08), "speed_mod": 1.0},
	{"name": "Crystalline SHRUMB", "tint": Color(0.42, 0.58, 0.55, 1.0), "scale": Vector2(0.95, 0.95), "speed_mod": 1.3},
	{"name": "MOSS SHRUMB", "tint": Color(0.52, 0.58, 0.38, 1.0), "scale": Vector2(1.06, 1.06), "speed_mod": 0.95},
]


func _ready() -> void:
	_base_critter_count = critter_count
	_base_ambient_max_count = ambient_max_count
	_base_ambient_spawn_interval = ambient_spawn_interval
	_critter_rng.seed = 1
	call_deferred("_bind_contract_map")


func _process(delta: float) -> void:
	if not ambient_spawn_enabled:
		return
	
	_ambient_spawn_timer += delta
	if _ambient_spawn_timer >= ambient_spawn_interval:
		_ambient_spawn_timer = 0.0
		_try_ambient_spawn()


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
	_ambient_spawn_timer = 0.0
	var world_profile: Dictionary = {}
	var world_profile_variant: Variant = contract.get("world_profile", {})
	if world_profile_variant is Dictionary:
		world_profile = world_profile_variant as Dictionary
	else:
		var map_variant: Variant = contract.get("map", {})
		if map_variant is Dictionary:
			var level_data_variant: Variant = (map_variant as Dictionary).get("level_data", {})
			if level_data_variant is Dictionary:
				var nested_profile: Variant = (level_data_variant as Dictionary).get("world_profile", {})
				if nested_profile is Dictionary:
					world_profile = nested_profile as Dictionary
	_apply_planet_world_profile(world_profile)
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
	_shuffle_candidate_tiles(candidate_tiles)
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


func _try_ambient_spawn() -> void:
	if _spawned_critters.size() >= ambient_max_count:
		return
	
	var player := _get_player()
	if player == null:
		return
	
	var container := get_node_or_null(critter_container_path)
	if container == null:
		return
	
	if critter_scene == null:
		return
	
	# Pick random position around player
	var spawn_offset := Vector2.RIGHT.rotated(_critter_rng.randf() * TAU) * _critter_rng.randf_range(ambient_spawn_radius_min, ambient_spawn_radius_max)
	var spawn_pos: Vector2 = player.global_position + spawn_offset
	
	# Check if valid spawn location (not too close to walls, etc.)
	if not _is_valid_spawn_position(spawn_pos):
		return
	
	var critter := critter_scene.instantiate()
	if critter == null:
		return
	
	container.add_child(critter)
	critter.global_position = spawn_pos
	
	# Ambient spawns use profile-offset variation so the local Shrumb population
	# remains tied to the generated world identity.
	_apply_critter_variation(critter, _spawned_critters.size())
	
	_spawned_critters.append(critter)


func _get_player() -> Node:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		return players[0]
	return get_node_or_null("/root/GameRoot/World/Player")


func _is_valid_spawn_position(pos: Vector2) -> bool:
	# Check distance from player - don't spawn too close
	var player := _get_player()
	if player:
		if pos.distance_to(player.global_position) < 100.0:
			return false
	
	# Could add wall/collision checks here
	return true


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


func _shuffle_candidate_tiles(tiles: Array[Vector2i]) -> void:
	if tiles.size() < 2:
		return
	for i in range(tiles.size() - 1, 0, -1):
		var swap_index := _critter_rng.randi_range(0, i)
		var temp := tiles[i]
		tiles[i] = tiles[swap_index]
		tiles[swap_index] = temp


func _apply_critter_variation(critter: Node2D, index: int) -> void:
	var variant_offset := int(_planet_world_profile.get("critter_variant_offset", 0))
	var data: Dictionary = SHRUMB_VARIANTS[(index + variant_offset) % SHRUMB_VARIANTS.size()]
	var tint := data.get("tint", Color.WHITE) as Color
	var planet_tint := _get_planet_profile_color("critter_tint", Color.WHITE)
	var final_tint := Color(
		tint.r * planet_tint.r,
		tint.g * planet_tint.g,
		tint.b * planet_tint.b,
		tint.a
	)
	var variant_name := String(data.get("name", "SHRUMB"))
	if not _profile_critter_name_prefix.is_empty():
		variant_name = "%s %s" % [_profile_critter_name_prefix, variant_name]
	if "enemy_name" in critter:
		critter.set("enemy_name", variant_name)
	if "base_tint" in critter:
		critter.set("base_tint", final_tint)
	var speed_mod := float(data.get("speed_mod", 1.0)) * _profile_critter_speed_multiplier
	if "speed" in critter:
		critter.set("speed", float(critter.get("speed")) * speed_mod)
	if critter.has_method("update_visuals"):
		critter.call("update_visuals")
	var base_scale: Vector2 = data.get("scale", Vector2.ONE)
	critter.scale = base_scale * _profile_critter_scale_multiplier
	critter.set_meta("shrumb_variant", variant_name)
	critter.set_meta("shrumb_traits", _profile_critter_traits)
	critter.set_meta("world_profile", String(_planet_world_profile.get("world_label", "")))


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


func get_shrumb_count() -> int:
	return _spawned_critters.size()


func get_shrumb_variants() -> Array:
	return SHRUMB_VARIANTS


func add_shrumb_variants(count: int) -> void:
	# Add more variants dynamically if needed
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_planet_world_profile.get("profile_seed", 0)) + SHRUMB_VARIANTS.size() * 97 + count
	var base_tints := [
		Color(0.45, 0.55, 0.35),
		Color(0.55, 0.40, 0.50),
		Color(0.40, 0.50, 0.60),
		Color(0.50, 0.45, 0.40),
		Color(0.38, 0.52, 0.42),
		Color(0.48, 0.42, 0.38),
		Color(0.42, 0.58, 0.55),
		Color(0.52, 0.58, 0.38),
	]
	var base_names := [
		"SHRUMB", "SPORE", "LUMEN", "CLAY", "TENDRILE", "RUST", "CRYSTALLINE", "MOSS"
	]
	for i in range(count):
		var idx = SHRUMB_VARIANTS.size() + i
		var tint = base_tints[idx % base_tints.size()]
		SHRUMB_VARIANTS.append({
			"name": base_names[idx % base_names.size()] + " SHRUMB",
			"tint": tint,
			"scale": Vector2(rng.randf_range(0.95, 1.16), rng.randf_range(0.95, 1.16)),
			"speed_mod": rng.randf_range(0.8, 1.3),
		})


func _apply_planet_world_profile(profile: Dictionary) -> void:
	_planet_world_profile = profile.duplicate(true)
	_critter_rng.seed = int(_planet_world_profile.get("profile_seed", 1))
	critter_count = max(1, _base_critter_count + int(_planet_world_profile.get("critter_count_bonus", 0)))
	ambient_max_count = max(critter_count, _base_ambient_max_count + int(_planet_world_profile.get("ambient_max_count_bonus", 0)))
	ambient_spawn_interval = max(3.0, _base_ambient_spawn_interval * float(_planet_world_profile.get("ambient_spawn_interval_scale", 1.0)))
	_profile_critter_speed_multiplier = clampf(float(_planet_world_profile.get("critter_speed_multiplier", 1.0)), 0.70, 1.35)
	_profile_critter_scale_multiplier = clampf(float(_planet_world_profile.get("critter_scale_multiplier", 1.0)), 0.85, 1.25)
	_profile_critter_name_prefix = String(_planet_world_profile.get("critter_name_prefix", "")).strip_edges()
	_profile_critter_traits = _to_packed_string_array(_planet_world_profile.get("critter_traits", []))


func _get_planet_profile_color(key: String, fallback: Color) -> Color:
	var value: Variant = _planet_world_profile.get(key, fallback)
	if value is Color:
		return value as Color
	return fallback


func _to_packed_string_array(value: Variant) -> PackedStringArray:
	var result := PackedStringArray()
	if value is PackedStringArray:
		return value as PackedStringArray
	if value is Array:
		for item in value as Array:
			result.append(String(item))
	return result
