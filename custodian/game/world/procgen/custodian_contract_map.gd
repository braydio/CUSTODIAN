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
@export var generated_map_size_min: Vector2i = Vector2i(160, 160)
@export var generated_map_size_max: Vector2i = Vector2i(224, 224)
@export_range(1, 128, 1) var generated_room_count_min: int = 12
@export_range(1, 128, 1) var generated_room_count_max: int = 22
@export_range(0.0, 1.0, 0.01) var min_connected_room_ratio: float = 0.75
@export var require_compound_ingress_connectivity: bool = true
@export_group("Special Rooms", "special_room_")
@export var special_room_insertion_enabled: bool = true
@export var special_room_definitions_path: String = "res://content/procgen/special_rooms"
@export_range(0, 8, 1) var special_room_max_per_run: int = 1
@export_group("", "")

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
		"map_size_min": Vector2i(176, 176),
		"map_size_max": Vector2i(224, 224),
		"room_count_min": 15,
		"room_count_max": 24,
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
		"critter_name_prefix": "MIRE",
		"critter_traits": ["lush", "wetland", "grazing"],
		"critter_speed_multiplier": 0.94,
		"critter_scale_multiplier": 1.08,
	},
	"terran_dry": {
		"world_label": "dust basin",
		"map_size_min": Vector2i(152, 152),
		"map_size_max": Vector2i(192, 192),
		"room_count_min": 11,
		"room_count_max": 18,
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
		"critter_name_prefix": "DUST",
		"critter_traits": ["dry", "scarce", "skittish"],
		"critter_speed_multiplier": 1.10,
		"critter_scale_multiplier": 0.98,
	},
	"islands": {
		"world_label": "archipelago shelf",
		"map_size_min": Vector2i(176, 176),
		"map_size_max": Vector2i(224, 224),
		"room_count_min": 14,
		"room_count_max": 23,
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
		"critter_name_prefix": "REEF",
		"critter_traits": ["salt", "humid", "quick"],
		"critter_speed_multiplier": 1.06,
		"critter_scale_multiplier": 1.02,
	},
	"ice_world": {
		"world_label": "cryotic shelf",
		"map_size_min": Vector2i(160, 160),
		"map_size_max": Vector2i(208, 208),
		"room_count_min": 12,
		"room_count_max": 20,
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
		"critter_name_prefix": "FROST",
		"critter_traits": ["cryotic", "pale", "slow-metabolic"],
		"critter_speed_multiplier": 0.90,
		"critter_scale_multiplier": 1.04,
	},
	"lava_world": {
		"world_label": "igneous scar",
		"map_size_min": Vector2i(144, 144),
		"map_size_max": Vector2i(184, 184),
		"room_count_min": 10,
		"room_count_max": 17,
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
		"critter_name_prefix": "ASH",
		"critter_traits": ["heat-hardened", "scarce", "darkened"],
		"critter_speed_multiplier": 1.04,
		"critter_scale_multiplier": 0.96,
	},
	"gas_giant": {
		"world_label": "aerostat platform",
		"map_size_min": Vector2i(192, 192),
		"map_size_max": Vector2i(240, 240),
		"room_count_min": 16,
		"room_count_max": 26,
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
		"critter_name_prefix": "LUMEN",
		"critter_traits": ["aerostat", "drifting", "lumen"],
		"critter_speed_multiplier": 1.12,
		"critter_scale_multiplier": 0.95,
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
var _special_room_inserter: SpecialRoomRuntimeInserter = null

const SPECIAL_ROOM_INSERTER_SCRIPT := preload("res://game/world/procgen/special_rooms/special_room_runtime_inserter.gd")

func _ready() -> void:
	if auto_generate_on_ready:
		if randomize_seed_on_ready:
			contract_seed = randi()
		generate_contract(contract_seed)


func _exit_tree() -> void:
	_active_planet = null
	_active_map = null
	_map_level_data_ready = false
	_map_level_data = {}
	_latest_contract = {}


func generate_contract(seed_value: int) -> void:
	if not is_node_ready():
		await ready

	contract_seed = seed_value
	_rng.seed = int(seed_value)

	var planet_key: String = _pick_planet_key(_rng)
	var planet_seed: int = int(_rng.randi())
	var world_profile := _build_planet_world_profile(planet_key, planet_seed)
	var map_seed: int = int(_rng.randi())
	var best_attempt_seed: int = map_seed

	await _clear_previous_instances()

	var planet_instance: Node = _instantiate_contracted_planet(planet_key, planet_seed)
	var planet_scene_path := _get_planet_scene_path(planet_key)
	var map_instance: ProcGenTilemap = null
	var level_data: Dictionary = {}
	var map_generated := false
	var best_map_instance: ProcGenTilemap = null
	var best_level_data: Dictionary = {}
	var best_map_score: float = -1.0
	for attempt in range(max(1, map_generation_attempts)):
		var attempt_seed: int = map_seed + attempt * 7919
		var candidate_map := await _instantiate_map(attempt_seed, attempt, world_profile)
		if candidate_map == null:
			continue
		var candidate_level_data := await _generate_map_level_data(candidate_map)
		var candidate_metrics := _get_map_layout_metrics(candidate_map, candidate_level_data)
		var candidate_score := _score_map_layout(candidate_metrics)
		if _is_map_layout_acceptable(candidate_metrics):
			if best_map_instance != null and best_map_instance != candidate_map:
				await _dispose_node(best_map_instance)
			best_map_instance = candidate_map
			best_level_data = candidate_level_data
			best_map_score = candidate_score
			best_attempt_seed = attempt_seed
			map_instance = candidate_map
			level_data = candidate_level_data
			map_seed = attempt_seed
			map_generated = true
			break
		elif best_map_instance == null or candidate_score > best_map_score:
			if best_map_instance != null and best_map_instance != candidate_map:
				await _dispose_node(best_map_instance)
			best_map_instance = candidate_map
			best_level_data = candidate_level_data
			best_map_score = candidate_score
			best_attempt_seed = attempt_seed
		else:
			await _dispose_node(candidate_map)
			if _active_map == candidate_map:
				_active_map = null

	if not map_generated:
		map_instance = best_map_instance
		level_data = best_level_data
		map_seed = best_attempt_seed

	if map_instance == null:
		push_error("[CustodianContractMap] Could not generate a usable procgen map")
		return

	if not map_generated:
		push_warning("[CustodianContractMap] Falling back to best available procgen map after %d attempts" % max(1, map_generation_attempts))
	var special_room_sites := _insert_special_rooms(map_instance, level_data, map_seed)
	if not special_room_sites.is_empty():
		level_data["special_room_sites"] = special_room_sites.duplicate(true)
	var contract := {
		"contract_seed": int(contract_seed),
		"world_profile": world_profile.duplicate(true),
		"planet": {
			"key": planet_key,
			"scene_path": planet_scene_path,
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
	
	await _clear_previous_instances()
	
	_init_edgar_systems()
	
	var planet_key: String = _pick_planet_key(_rng)
	var planet_seed: int = int(_rng.randi())
	var world_profile := _build_planet_world_profile(planet_key, planet_seed)
	var planet_instance: Node = _instantiate_contracted_planet(planet_key, planet_seed)
	var planet_scene_path := _get_planet_scene_path(planet_key)
	
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
			"scene_path": planet_scene_path,
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
		await _dispose_node(_active_planet)
	_active_planet = null

	if _active_map and is_instance_valid(_active_map):
		await _dispose_node(_active_map)
	_active_map = null


func _dispose_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.is_inside_tree():
		node.queue_free()
		await node.tree_exited
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()


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

	var scene_path := _get_planet_scene_path(planet_key)
	if scene_path.is_empty():
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


func _get_planet_scene_path(planet_key: String) -> String:
	if not PLANET_LIBRARY.has(planet_key):
		return ""
	var scene_path: String = String(PLANET_LIBRARY[planet_key])
	if not ResourceLoader.exists(scene_path):
		return ""
	return scene_path


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
	var profile_map_size: Vector2i = planet_world_profile.get("map_size", procgen.map_size) as Vector2i
	procgen.map_size = profile_map_size
	var min_rooms: int = maxi(1, int(planet_world_profile.get("room_count_min", generated_room_count_min)))
	var max_rooms: int = maxi(min_rooms, int(planet_world_profile.get("room_count_max", generated_room_count_max)))
	procgen.room_amount = clampi(_rng.randi_range(min_rooms, max_rooms) + room_variance, min_rooms, max_rooms)
	procgen.room_center_ratio = 0.18 + _rng.randf_range(0.0, 0.20)
	procgen.corridor_edge_overlap_min_ratio = 0.14 + _rng.randf_range(0.0, 0.12)
	procgen.corridor_cycle_chance = 0.22 + _rng.randf_range(0.0, 0.18)
	procgen.automaton_iterations = 3 + ((attempt_index + _rng.randi_range(0, 1)) % 2)
	procgen.automaton_noise_rate = 0.48 + _rng.randf_range(0.0, 0.10)
	procgen.automaton_corridor_fixed_width_expand = 1
	procgen.automaton_corridor_non_fixed_width_expand = 1 + ((attempt_index + 1) % 2)


func _insert_special_rooms(map_instance: ProcGenTilemap, level_data: Dictionary, map_seed: int) -> Array[Dictionary]:
	if not special_room_insertion_enabled or special_room_max_per_run <= 0:
		return []
	if map_instance == null:
		return []
	if _special_room_inserter == null:
		_special_room_inserter = SPECIAL_ROOM_INSERTER_SCRIPT.new()
	var inserted: Array[Dictionary] = _special_room_inserter.insert_special_rooms({
		"map_instance": map_instance,
		"parent": map_instance,
		"level_data": level_data,
		"seed": map_seed,
		"definitions_path": special_room_definitions_path,
		"max_rooms": special_room_max_per_run,
	})
	return inserted


func _build_planet_world_profile(planet_key: String, planet_seed: int) -> Dictionary:
	var fallback: Dictionary = PLANET_WORLD_PROFILES.get("terran_dry", {})
	var profile: Dictionary = PLANET_WORLD_PROFILES.get(planet_key, fallback).duplicate(true)
	var profile_rng := RandomNumberGenerator.new()
	profile_rng.seed = int(planet_seed)
	profile["planet_key"] = planet_key
	profile["profile_seed"] = planet_seed
	var min_map_size: Vector2i = profile.get("map_size_min", generated_map_size_min) as Vector2i
	var max_map_size: Vector2i = profile.get("map_size_max", generated_map_size_max) as Vector2i
	min_map_size = min_map_size.maxi(64)
	max_map_size = Vector2i(maxi(max_map_size.x, min_map_size.x), maxi(max_map_size.y, min_map_size.y))
	var map_width := _round_map_dimension(profile_rng.randi_range(min_map_size.x, max_map_size.x))
	var map_height := _round_map_dimension(profile_rng.randi_range(min_map_size.y, max_map_size.y))
	profile["map_size"] = Vector2i(map_width, map_height)
	profile["room_count_min"] = max(1, int(profile.get("room_count_min", generated_room_count_min)))
	profile["room_count_max"] = max(
		int(profile["room_count_min"]),
		int(profile.get("room_count_max", generated_room_count_max))
	)
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
	profile["critter_speed_multiplier"] = clamp(
		float(profile.get("critter_speed_multiplier", 1.0)) + profile_rng.randf_range(-0.03, 0.03),
		0.70,
		1.35
	)
	profile["critter_scale_multiplier"] = clamp(
		float(profile.get("critter_scale_multiplier", 1.0)) + profile_rng.randf_range(-0.03, 0.03),
		0.85,
		1.25
	)
	return profile


func _round_map_dimension(value: int) -> int:
	return max(64, int(round(float(value) / 16.0)) * 16)


func _is_map_layout_acceptable(metrics: Dictionary) -> bool:
	if not bool(metrics.get("valid", false)):
		return false
	if float(metrics.get("connected_ratio", 0.0)) < min_connected_room_ratio:
		return false
	if require_compound_ingress_connectivity and float(metrics.get("ingress_ratio", 0.0)) < 1.0:
		return false
	return true


func _score_map_layout(metrics: Dictionary) -> float:
	if not bool(metrics.get("valid", false)):
		return -1.0
	return float(metrics.get("connected_ratio", 0.0)) + float(metrics.get("ingress_ratio", 0.0)) * 0.1


func _get_map_layout_metrics(map_instance: ProcGenTilemap, level_data: Dictionary) -> Dictionary:
	if map_instance == null or map_instance.procgen_node == null:
		return {"valid": false}
	var spawn_variant: Variant = level_data.get("player_spawn", Vector2i.ZERO)
	if not (spawn_variant is Vector2i):
		return {"valid": false}
	var spawn_tile := spawn_variant as Vector2i
	if not _is_layout_walkable_tile(map_instance, spawn_tile):
		return {"valid": false}

	var reachable := _flood_fill_walkable(map_instance, level_data, spawn_tile)
	if reachable.is_empty():
		return {"valid": false}

	var rooms_total := 0
	var rooms_connected := 0
	for room_item in level_data.get("rooms_by_distance", []):
		if not (room_item is Vector2i):
			continue
		rooms_total += 1
		if reachable.has(room_item):
			rooms_connected += 1
	if rooms_total <= 0:
		return {"valid": false}

	var connected_ratio := float(rooms_connected) / float(rooms_total)
	var ingress_total := 0
	var ingress_connected := 0
	for ingress_item in level_data.get("compound_ingress", []):
		if not (ingress_item is Vector2i):
			continue
		ingress_total += 1
		if reachable.has(ingress_item):
			ingress_connected += 1

	var ingress_ratio := 1.0
	if ingress_total > 0:
		ingress_ratio = float(ingress_connected) / float(ingress_total)

	return {
		"valid": true,
		"connected_ratio": connected_ratio,
		"ingress_ratio": ingress_ratio,
	}


func _flood_fill_walkable(map_instance: ProcGenTilemap, level_data: Dictionary, start_tile: Vector2i) -> Dictionary:
	var reachable := {}
	var open: Array[Vector2i] = [start_tile]
	reachable[start_tile] = true
	var map_size: Vector2i = level_data.get("map_size", Vector2i.ZERO)
	if map_size == Vector2i.ZERO and map_instance != null and map_instance.procgen_node != null:
		map_size = map_instance.procgen_node.map_size
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not open.is_empty():
		var current: Vector2i = open.pop_back()
		for direction in directions:
			var next := current + direction
			if next.x < 0 or next.y < 0 or next.x >= map_size.x or next.y >= map_size.y:
				continue
			if reachable.has(next) or not _is_layout_walkable_tile(map_instance, next):
				continue
			if map_instance != null and map_instance.has_method("can_traverse_elevation") and not bool(map_instance.call("can_traverse_elevation", current, next)):
				continue
			reachable[next] = true
			open.append(next)
	return reachable


func _is_layout_walkable_tile(map_instance: ProcGenTilemap, tile: Vector2i) -> bool:
	if map_instance != null and map_instance.has_method("is_valid_spawn_cell"):
		return bool(map_instance.call("is_valid_spawn_cell", tile))
	if map_instance != null and map_instance.procgen_node != null:
		return not map_instance.procgen_node.is_full_at(tile)
	return false
