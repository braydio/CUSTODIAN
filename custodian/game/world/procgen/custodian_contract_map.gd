extends Node2D
class_name CustodianContractMap

## Deterministically generates a CUSTODIAN mission contract consisting of:
## 1) a contracted PixelPlanets planet instance
## 2) a procgen map instance + derived level data

signal contract_generated(contract: Dictionary)

@export var auto_generate_on_ready: bool = true
@export var contract_seed: int = 0
@export var randomize_seed_on_ready: bool = true
@export var map_scene: PackedScene = preload("res://game/world/procgen/proc_gen_map.tscn")
@export var planet_offset: Vector2 = Vector2(-420, -320)
@export var map_offset: Vector2 = Vector2.ZERO
@export var map_generation_attempts: int = 6
@export_range(0.0, 1.0, 0.01) var min_connected_room_ratio: float = 0.85
@export var require_compound_ingress_connectivity: bool = true

enum MapGenerationMode {
	PROCGEN_ONLY,
	EDGAR_ONLY,
	HYBRID,
}

@export var generation_mode: MapGenerationMode = MapGenerationMode.PROCGEN_ONLY
@export var edgar_weight: float = 0.5
@export var room_templates_path: String = "res://game/world/compound/rooms/templates"
@export var room_graph_path: String = "res://game/world/compound/rooms/graphs/default_compound.json"

var _room_loader: RoomLoader
var _room_graph: RoomGraph

const PLANET_LIBRARY := {
	"terran_wet": "res://Planets/Rivers/Rivers.tscn",
	"terran_dry": "res://Planets/DryTerran/DryTerran.tscn",
	"islands": "res://Planets/LandMasses/LandMasses.tscn",
	"ice_world": "res://Planets/IceWorld/IceWorld.tscn",
	"lava_world": "res://Planets/LavaWorld/LavaWorld.tscn",
	"gas_giant": "res://Planets/GasPlanet/GasPlanet.tscn",
}

const PLANET_WORLD_PROFILES := {
	"terran_wet": {
		"world_label": "humid river basin",
		"compound_area_ratio": 0.12,
		"open_layout_chance": 0.58,
		"open_layout_carve_ratio": 0.25,
		"foliage_density": 0.20,
		"foliage_compound_density_multiplier": 0.45,
		"fruit_spawn_chance_shrub": 0.18,
		"fruit_spawn_chance_tree": 0.24,
		"tile_tint": Color(0.88, 0.97, 0.90, 1.0),
		"wall_tint": Color(0.78, 0.90, 0.82, 1.0),
		"foliage_tint": Color(0.94, 1.04, 0.94, 1.0),
		"critter_tint": Color(0.88, 1.06, 0.92, 1.0),
		"critter_count_bonus": 2,
		"ambient_max_count_bonus": 2,
		"ambient_spawn_interval_scale": 0.80,
	},
	"terran_dry": {
		"world_label": "dust basin",
		"compound_area_ratio": 0.16,
		"open_layout_chance": 0.28,
		"open_layout_carve_ratio": 0.12,
		"foliage_density": 0.05,
		"foliage_compound_density_multiplier": 0.12,
		"fruit_spawn_chance_shrub": 0.02,
		"fruit_spawn_chance_tree": 0.04,
		"tile_tint": Color(1.00, 0.93, 0.82, 1.0),
		"wall_tint": Color(0.92, 0.82, 0.70, 1.0),
		"foliage_tint": Color(0.86, 0.80, 0.68, 1.0),
		"critter_tint": Color(1.04, 0.92, 0.82, 1.0),
		"critter_count_bonus": -1,
		"ambient_max_count_bonus": -1,
		"ambient_spawn_interval_scale": 1.18,
	},
	"islands": {
		"world_label": "archipelago shelf",
		"compound_area_ratio": 0.11,
		"open_layout_chance": 0.62,
		"open_layout_carve_ratio": 0.27,
		"foliage_density": 0.17,
		"foliage_compound_density_multiplier": 0.36,
		"fruit_spawn_chance_shrub": 0.16,
		"fruit_spawn_chance_tree": 0.22,
		"tile_tint": Color(0.88, 0.98, 1.00, 1.0),
		"wall_tint": Color(0.78, 0.90, 0.95, 1.0),
		"foliage_tint": Color(0.86, 1.06, 0.95, 1.0),
		"critter_tint": Color(0.84, 1.02, 1.02, 1.0),
		"critter_count_bonus": 1,
		"ambient_max_count_bonus": 1,
		"ambient_spawn_interval_scale": 0.88,
	},
	"ice_world": {
		"world_label": "cryotic shelf",
		"compound_area_ratio": 0.15,
		"open_layout_chance": 0.42,
		"open_layout_carve_ratio": 0.18,
		"foliage_density": 0.03,
		"foliage_compound_density_multiplier": 0.08,
		"fruit_spawn_chance_shrub": 0.00,
		"fruit_spawn_chance_tree": 0.01,
		"tile_tint": Color(0.88, 0.95, 1.05, 1.0),
		"wall_tint": Color(0.78, 0.88, 1.02, 1.0),
		"foliage_tint": Color(0.82, 0.92, 1.00, 1.0),
		"critter_tint": Color(0.82, 0.96, 1.06, 1.0),
		"critter_count_bonus": -1,
		"ambient_max_count_bonus": -1,
		"ambient_spawn_interval_scale": 1.14,
	},
	"lava_world": {
		"world_label": "igneous scar",
		"compound_area_ratio": 0.18,
		"open_layout_chance": 0.18,
		"open_layout_carve_ratio": 0.08,
		"foliage_density": 0.01,
		"foliage_compound_density_multiplier": 0.04,
		"fruit_spawn_chance_shrub": 0.00,
		"fruit_spawn_chance_tree": 0.00,
		"tile_tint": Color(1.04, 0.82, 0.72, 1.0),
		"wall_tint": Color(1.02, 0.68, 0.58, 1.0),
		"foliage_tint": Color(0.90, 0.68, 0.58, 1.0),
		"critter_tint": Color(1.06, 0.78, 0.70, 1.0),
		"critter_count_bonus": -1,
		"ambient_max_count_bonus": 0,
		"ambient_spawn_interval_scale": 1.08,
	},
	"gas_giant": {
		"world_label": "aerostat platform",
		"compound_area_ratio": 0.10,
		"open_layout_chance": 0.68,
		"open_layout_carve_ratio": 0.30,
		"foliage_density": 0.02,
		"foliage_compound_density_multiplier": 0.05,
		"fruit_spawn_chance_shrub": 0.00,
		"fruit_spawn_chance_tree": 0.00,
		"tile_tint": Color(0.92, 0.90, 1.03, 1.0),
		"wall_tint": Color(0.82, 0.80, 0.95, 1.0),
		"foliage_tint": Color(0.88, 0.84, 0.98, 1.0),
		"critter_tint": Color(0.92, 0.90, 1.08, 1.0),
		"critter_count_bonus": 0,
		"ambient_max_count_bonus": 1,
		"ambient_spawn_interval_scale": 0.92,
	},
}

@onready var planet_root: Node2D = $PlanetRoot
@onready var map_root: Node2D = $MapRoot

var _rng := RandomNumberGenerator.new()
var _active_planet: Node = null
var _active_map: ProcGenTilemap = null
var _map_level_data_ready: bool = false
var _map_level_data: Dictionary = {}
var _latest_contract: Dictionary = {}

func _ready() -> void:
	if auto_generate_on_ready:
		if randomize_seed_on_ready:
			contract_seed = randi()
		generate_contract(contract_seed)


func generate_contract(seed_value: int) -> void:
	if not is_node_ready():
		await ready

	contract_seed = seed_value
	_rng.seed = int(seed_value)

	var planet_key: String = _pick_planet_key(_rng)
	var planet_seed: int = int(_rng.randi())
	var world_profile := _build_planet_world_profile(planet_key, planet_seed)
	var map_seed: int = int(_rng.randi())

	_clear_previous_instances()

	var planet_instance: Node = _instantiate_contracted_planet(planet_key, planet_seed)
	var map_instance: ProcGenTilemap = null
	var level_data: Dictionary = {}
	var map_generated := false
	for attempt in range(max(1, map_generation_attempts)):
		var attempt_seed: int = map_seed + attempt * 7919
		map_instance = await _instantiate_map(attempt_seed, attempt, world_profile)
		if map_instance == null:
			continue
		level_data = await _generate_map_level_data(map_instance)
		if _is_map_layout_acceptable(map_instance, level_data):
			map_seed = attempt_seed
			map_generated = true
			break
		map_instance.queue_free()
		if _active_map == map_instance:
			_active_map = null

	if not map_generated or map_instance == null:
		push_error("[CustodianContractMap] Could not generate an acceptable procgen map")
		return
	var contract := {
		"contract_seed": int(contract_seed),
		"world_profile": world_profile.duplicate(true),
		"planet": {
			"key": planet_key,
			"scene_path": PLANET_LIBRARY[planet_key],
			"planet_seed": planet_seed,
			"instance": planet_instance,
			"world_profile": world_profile.duplicate(true),
		},
		"map": {
			"map_seed": map_seed,
			"instance": map_instance,
			"level_data": level_data,
		},
	}
	_latest_contract = contract
	contract_generated.emit(contract)


func generate_edgar_contract(seed_value: int) -> Dictionary:
	if not is_node_ready():
		await ready
	
	contract_seed = seed_value
	_rng.seed = int(seed_value)
	
	_clear_previous_instances()
	
	_init_edgar_systems()
	
	var planet_key: String = _pick_planet_key(_rng)
	var planet_seed: int = int(_rng.randi())
	var world_profile := _build_planet_world_profile(planet_key, planet_seed)
	var planet_instance: Node = _instantiate_contracted_planet(planet_key, planet_seed)
	
	var layout: Dictionary = _generate_edgar_layout()
	
	if layout.is_empty() or layout.get("rooms", []).is_empty():
		push_warning("[CustodianContractMap] Edgar layout generation failed, falling back to procgen")
		await generate_contract(seed_value)
		return _latest_contract
	
	var level_data := {
		"generation_mode": "edgar",
		"layout": layout,
		"room_count": layout.get("room_count", 0),
		"world_profile": world_profile.duplicate(true),
	}
	
	var contract := {
		"contract_seed": int(contract_seed),
		"world_profile": world_profile.duplicate(true),
		"planet": {
			"key": planet_key,
			"scene_path": PLANET_LIBRARY[planet_key],
			"planet_seed": planet_seed,
			"instance": planet_instance,
			"world_profile": world_profile.duplicate(true),
		},
		"map": {
			"map_seed": seed_value,
			"level_data": level_data,
			"generation_mode": "edgar",
		},
		"edgar_layout": layout,
	}
	
	_latest_contract = contract
	contract_generated.emit(contract)
	return contract


func _init_edgar_systems() -> void:
	if _room_loader == null:
		_room_loader = RoomLoader.new(_rng)
		var loaded := _room_loader.load_templates_from_directory(room_templates_path)
		if loaded == 0:
			push_warning("[RoomLoader] No templates loaded from: " + room_templates_path)
	
	if _room_graph == null:
		_room_graph = RoomGraph.new(_rng)
		if not _room_graph.load_from_json_file(room_graph_path):
			push_error("[RoomGraph] Failed to load graph from: " + room_graph_path)


func _generate_edgar_layout() -> Dictionary:
	if _room_loader == null or _room_graph == null:
		_init_edgar_systems()
	
	if _room_loader.get_all_templates().is_empty():
		push_error("[CustodianContractMap] No room templates loaded")
		return {}
	
	if not _room_graph.validate():
		push_error("[CustodianContractMap] Room graph validation failed")
		return {}
	
	var assembler := LayoutAssembler.new(_room_loader, _room_graph, _rng)
	return assembler.generate_layout(contract_seed)


func get_latest_contract() -> Dictionary:
	return _latest_contract


func _clear_previous_instances() -> void:
	if _active_planet and is_instance_valid(_active_planet):
		_active_planet.queue_free()
	_active_planet = null

	if _active_map and is_instance_valid(_active_map):
		_active_map.queue_free()
	_active_map = null


func _pick_planet_key(rng: RandomNumberGenerator) -> String:
	var keys: Array = PLANET_LIBRARY.keys()
	keys.sort()
	if keys.is_empty():
		return "terran_dry"
	return String(keys[rng.randi_range(0, keys.size() - 1)])


func _instantiate_contracted_planet(planet_key: String, planet_seed: int) -> Node:
	if not PLANET_LIBRARY.has(planet_key):
		push_warning("[CustodianContractMap] Unknown planet key: %s" % planet_key)
		return null

	var scene_path: String = String(PLANET_LIBRARY[planet_key])
	if not ResourceLoader.exists(scene_path):
		push_warning("[CustodianContractMap] Missing planet scene at %s" % scene_path)
		return null

	var scene_res = load(scene_path)
	if not (scene_res is PackedScene):
		push_warning("[CustodianContractMap] Planet resource is not a scene: %s" % scene_path)
		return null

	var planet = (scene_res as PackedScene).instantiate()
	if planet == null:
		return null

	planet_root.add_child(planet)
	if planet is CanvasItem:
		(planet as CanvasItem).position = planet_offset

	if planet.has_method("set_seed"):
		planet.call("set_seed", planet_seed)
	if planet.has_method("set_rotates"):
		planet.call("set_rotates", false)
	if planet.has_method("set_light"):
		planet.call("set_light", Vector2(0.74, 0.28))

	_active_planet = planet
	return planet


func _instantiate_map(map_seed: int, attempt_index: int = 0, planet_world_profile: Dictionary = {}) -> ProcGenTilemap:
	if map_scene == null:
		return null
	var map_instance = map_scene.instantiate()
	if not (map_instance is ProcGenTilemap):
		return null

	map_root.add_child(map_instance)
	if not map_instance.is_node_ready():
		await map_instance.ready

	# ProcGen may auto-generate in its own _ready before ProcGenTilemap drives generation.
	# Ensure we only trigger after any in-flight generation has completed.
	if map_instance.procgen_node:
		while map_instance.procgen_node.is_generating():
			await get_tree().process_frame
		_apply_map_generation_profile(map_instance, attempt_index, planet_world_profile)

	(map_instance as Node2D).position = map_offset
	map_instance.set_seed(map_seed)
	_active_map = map_instance
	return map_instance


func _generate_map_level_data(map_instance: ProcGenTilemap) -> Dictionary:
	_map_level_data_ready = false
	_map_level_data = {}

	map_instance.level_data_ready.connect(_on_map_level_data_ready, CONNECT_ONE_SHOT)
	map_instance.generate()

	while not _map_level_data_ready:
		await get_tree().process_frame

	return _map_level_data


func _on_map_level_data_ready(level_data: Dictionary) -> void:
	_map_level_data = level_data
	_map_level_data_ready = true


func _apply_map_generation_profile(map_instance: ProcGenTilemap, attempt_index: int, planet_world_profile: Dictionary = {}) -> void:
	if map_instance == null or map_instance.procgen_node == null:
		return
	if not planet_world_profile.is_empty() and map_instance.has_method("apply_planet_world_profile"):
		map_instance.call("apply_planet_world_profile", planet_world_profile)
	var procgen := map_instance.procgen_node
	var room_variance := attempt_index % 3
	procgen.room_amount = 7 + room_variance + _rng.randi_range(0, 2)
	procgen.room_center_ratio = 0.18 + _rng.randf_range(0.0, 0.20)
	procgen.corridor_edge_overlap_min_ratio = 0.14 + _rng.randf_range(0.0, 0.12)
	procgen.corridor_cycle_chance = 0.22 + _rng.randf_range(0.0, 0.18)
	procgen.automaton_iterations = 3 + ((attempt_index + _rng.randi_range(0, 1)) % 2)
	procgen.automaton_noise_rate = 0.48 + _rng.randf_range(0.0, 0.10)
	procgen.automaton_corridor_fixed_width_expand = 1
	procgen.automaton_corridor_non_fixed_width_expand = 1 + ((attempt_index + 1) % 2)


func _build_planet_world_profile(planet_key: String, planet_seed: int) -> Dictionary:
	var fallback: Dictionary = PLANET_WORLD_PROFILES.get("terran_dry", {})
	var profile: Dictionary = PLANET_WORLD_PROFILES.get(planet_key, fallback).duplicate(true)
	var profile_rng := RandomNumberGenerator.new()
	profile_rng.seed = int(planet_seed)
	profile["planet_key"] = planet_key
	profile["profile_seed"] = planet_seed
	profile["compound_area_ratio"] = clamp(
		float(profile.get("compound_area_ratio", 0.14)) + profile_rng.randf_range(-0.01, 0.01),
		0.10,
		0.20
	)
	profile["open_layout_chance"] = clamp(
		float(profile.get("open_layout_chance", 0.35)) + profile_rng.randf_range(-0.05, 0.05),
		0.05,
		0.85
	)
	profile["open_layout_carve_ratio"] = clamp(
		float(profile.get("open_layout_carve_ratio", 0.20)) + profile_rng.randf_range(-0.03, 0.03),
		0.03,
		0.45
	)
	profile["foliage_density"] = clamp(
		float(profile.get("foliage_density", 0.12)) + profile_rng.randf_range(-0.02, 0.02),
		0.0,
		0.35
	)
	profile["foliage_compound_density_multiplier"] = clamp(
		float(profile.get("foliage_compound_density_multiplier", 0.28)) + profile_rng.randf_range(-0.06, 0.06),
		0.0,
		0.75
	)
	profile["fruit_spawn_chance_shrub"] = clamp(
		float(profile.get("fruit_spawn_chance_shrub", 0.10)) + profile_rng.randf_range(-0.03, 0.03),
		0.0,
		0.35
	)
	profile["fruit_spawn_chance_tree"] = clamp(
		float(profile.get("fruit_spawn_chance_tree", 0.14)) + profile_rng.randf_range(-0.03, 0.03),
		0.0,
		0.40
	)
	profile["critter_variant_offset"] = profile_rng.randi_range(0, 31)
	return profile


func _is_map_layout_acceptable(map_instance: ProcGenTilemap, level_data: Dictionary) -> bool:
	if map_instance == null or map_instance.procgen_node == null:
		return false
	var spawn_variant: Variant = level_data.get("player_spawn", Vector2i.ZERO)
	if not (spawn_variant is Vector2i):
		return false
	var spawn_tile := spawn_variant as Vector2i
	if map_instance.procgen_node.is_full_at(spawn_tile):
		return false

	var reachable := _flood_fill_walkable(map_instance.procgen_node, spawn_tile)
	if reachable.is_empty():
		return false

	var rooms_total := 0
	var rooms_connected := 0
	for room_item in level_data.get("rooms_by_distance", []):
		if not (room_item is Vector2i):
			continue
		rooms_total += 1
		if reachable.has(room_item):
			rooms_connected += 1
	if rooms_total <= 0:
		return false

	var connected_ratio := float(rooms_connected) / float(rooms_total)
	if connected_ratio < min_connected_room_ratio:
		return false

	if require_compound_ingress_connectivity:
		for ingress_item in level_data.get("compound_ingress", []):
			if ingress_item is Vector2i and not reachable.has(ingress_item):
				return false

	return true


func _flood_fill_walkable(procgen: ProcGen, start_tile: Vector2i) -> Dictionary:
	var reachable := {}
	var open: Array[Vector2i] = [start_tile]
	reachable[start_tile] = true
	var map_size: Vector2i = procgen.map_size
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not open.is_empty():
		var current: Vector2i = open.pop_back()
		for direction in directions:
			var next := current + direction
			if next.x < 0 or next.y < 0 or next.x >= map_size.x or next.y >= map_size.y:
				continue
			if reachable.has(next) or procgen.is_full_at(next):
				continue
			reachable[next] = true
			open.append(next)
	return reachable
