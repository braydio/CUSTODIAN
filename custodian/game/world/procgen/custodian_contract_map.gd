extends Node2D
class_name CustodianContractMap

## Deterministically generates a CUSTODIAN mission contract consisting of:
## 1) a contracted PixelPlanets planet instance
## 2) a procgen map instance + derived level data

signal contract_generated(contract: Dictionary)
signal contract_generation_failed(result: Dictionary)

const CANDIDATE_EVALUATOR_SCRIPT := preload("res://game/world/procgen/generation/candidate_evaluator.gd")
const CANDIDATE_SEMANTIC_ADAPTER_SCRIPT := preload("res://game/world/procgen/generation/candidate_semantic_adapter.gd")
const CANDIDATE_MATERIALIZER_SCRIPT := preload("res://game/world/procgen/generation/procgen_candidate_materializer.gd")

var _candidate_evaluator: Variant = CANDIDATE_EVALUATOR_SCRIPT.new()
var _candidate_semantic_adapter: Variant = CANDIDATE_SEMANTIC_ADAPTER_SCRIPT.new()
var _candidate_materializer: Variant = CANDIDATE_MATERIALIZER_SCRIPT.new()

@export var auto_generate_on_ready: bool = true
@export var contract_seed: int = 0
@export var randomize_seed_on_ready: bool = true
@export var map_scene: PackedScene = preload("res://game/world/procgen/proc_gen_map.tscn")
@export var planet_offset: Vector2 = Vector2(-420, -320)
@export var map_offset: Vector2 = Vector2.ZERO
@export var map_generation_attempts: int = 12
## Explicit Region Frame selector. Empty is neutral: reusable generator code
## never infers a frame from planet_key, biome, weather or elevation. The
## current production starting-region scene sets this explicitly.
@export var region_frame_profile_id: StringName = &""
@export var generated_map_size_min: Vector2i = Vector2i(160, 160)
@export var generated_map_size_max: Vector2i = Vector2i(224, 224)
@export_range(1, 128, 1) var generated_room_count_min: int = 12
@export_range(1, 128, 1) var generated_room_count_max: int = 22
@export_range(0.0, 1.0, 0.01) var min_connected_room_ratio: float = 0.75
@export var require_compound_ingress_connectivity: bool = true
@export var terrain_rescue_reject_threshold: int = 200
@export_range(0.0, 1.0, 0.01) var pre_terrain_required_connectivity_min: float = 0.95
@export var allow_degraded_best_candidate_fallback: bool = false
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
		"biome_moisture_bias": 0.18, "biome_exposure_bias": -0.05,
		"day_start_hour_min": 7.5, "day_start_hour_max": 10.0,
		"weather_weights": {"clear":0.22,"overcast":0.24,"light_rain":0.24,"heavy_rain":0.12,"mist":0.18},
		"fog_alpha": 0.16,
		"cosmic_underlay_alpha": 0.00,
		"foliage_wind_speed": 0.75,
		"foliage_shrub_wind_strength_px": 0.70,
		"foliage_tree_wind_strength_px": 1.35,
		"foliage_wind_gust_amount": 0.42,
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
		"biome_moisture_bias": -0.20, "biome_exposure_bias": 0.12,
		"day_start_hour_min": 7.5, "day_start_hour_max": 10.0,
		"weather_weights": {"clear":0.62,"overcast":0.12,"dust_wind":0.22,"light_rain":0.04},
		"fog_alpha": 0.08,
		"cosmic_underlay_alpha": 0.01,
		"foliage_wind_speed": 1.25,
		"foliage_shrub_wind_strength_px": 0.70,
		"foliage_tree_wind_strength_px": 1.35,
		"foliage_wind_gust_amount": 0.42,
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
		"biome_moisture_bias": 0.12, "biome_exposure_bias": 0.04,
		"day_start_hour_min": 7.5, "day_start_hour_max": 10.0,
		"weather_weights": {"clear":0.25,"overcast":0.22,"light_rain":0.25,"heavy_rain":0.15,"mist":0.13},
		"fog_alpha": 0.13,
		"cosmic_underlay_alpha": 0.00,
		"foliage_wind_speed": 1.10,
		"foliage_shrub_wind_strength_px": 0.70,
		"foliage_tree_wind_strength_px": 1.35,
		"foliage_wind_gust_amount": 0.42,
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
		"biome_moisture_bias": -0.02, "biome_exposure_bias": 0.12,
		"day_start_hour_min": 7.5, "day_start_hour_max": 10.0,
		"weather_weights": {"clear":0.32,"overcast":0.30,"snow":0.25,"mist":0.13},
		"fog_alpha": 0.11,
		"cosmic_underlay_alpha": 0.04,
		"foliage_wind_speed": 0.55,
		"foliage_shrub_wind_strength_px": 0.70,
		"foliage_tree_wind_strength_px": 1.35,
		"foliage_wind_gust_amount": 0.42,
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
		"biome_moisture_bias": -0.32, "biome_exposure_bias": 0.30,
		"day_start_hour_min": 7.5, "day_start_hour_max": 10.0,
		"weather_weights": {"clear":0.55,"ashfall":0.32,"dust_wind":0.13},
		"fog_alpha": 0.07,
		"cosmic_underlay_alpha": 0.02,
		"foliage_wind_speed": 0.85,
		"foliage_shrub_wind_strength_px": 0.70,
		"foliage_tree_wind_strength_px": 1.35,
		"foliage_wind_gust_amount": 0.42,
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
		"biome_moisture_bias": 0.08, "biome_exposure_bias": 0.22,
		"day_start_hour_min": 7.5, "day_start_hour_max": 10.0,
		"weather_weights": {"clear":0.12,"overcast":0.32,"mist":0.22,"light_rain":0.18,"heavy_rain":0.16},
		"fog_alpha": 0.18,
		"cosmic_underlay_alpha": 0.12,
		"foliage_wind_speed": 1.45,
		"foliage_shrub_wind_strength_px": 0.70,
		"foliage_tree_wind_strength_px": 1.35,
		"foliage_wind_gust_amount": 0.42,
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
var _latest_generation_failure: Dictionary = {}
## Structured per-attempt candidate-loop facts for
## custodian.procgen_performance_baseline.v1, reset and accumulated inside
## generate_contract(); never a second generation pass.
var _last_generation_attempts: Array[Dictionary] = []
var _last_contract_generation_report: Dictionary = {}
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
	_latest_generation_failure = {}


func generate_contract(seed_value: int) -> void:
	if not is_node_ready():
		await ready

	print("[CustodianContractMap] CONTRACT_BEGIN node=%s instance=%s seed=%s" % [
		str(get_path()),
		str(get_instance_id()),
		str(seed_value),
	])

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
	var best_map_score: float = -1.0
	var best_map_terrain_failed := true
	var best_attempt_index := -1
	var best_attempt_metrics: Dictionary = {}
	var best_candidate: Dictionary = {}
	var selected_candidate: Dictionary = {}
	var _attempt_total_start := Time.get_ticks_msec()
	var attempts_run := 0
	var accepted_attempt := -1
	_last_generation_attempts = []
	for attempt in range(max(1, map_generation_attempts)):
		var _attempt_start := Time.get_ticks_msec()
		var attempt_seed: int = map_seed + attempt * 7919
		var candidate_map := await _instantiate_map(attempt_seed, attempt, world_profile)
		var _t_instantiate := Time.get_ticks_msec() - _attempt_start
		if candidate_map == null:
			print("[CustodianContractMap] Attempt %d: instantiate_map=null (%.1fs)" % [attempt, _t_instantiate / 1000.0])
			continue
		attempts_run += 1
		var candidate_level_data := await _generate_map_level_data(candidate_map)
		var _t_generate := Time.get_ticks_msec() - _attempt_start - _t_instantiate
		var candidate_snapshot: Dictionary = _candidate_semantic_adapter.build_snapshot(
			candidate_map,
			candidate_level_data,
			{"contract_seed": int(contract_seed), "attempt": attempt, "attempt_seed": attempt_seed}
		)
		var evaluation: Dictionary = _candidate_evaluator.evaluate_snapshot(
			candidate_snapshot,
			_get_candidate_evaluation_settings()
		)
		var candidate_metrics: Dictionary = evaluation.get("metrics", {})
		var required_ingresses_valid := bool(candidate_metrics.get("required_ingresses_valid", false))
		var _t_metrics := Time.get_ticks_msec() - _attempt_start - _t_instantiate - _t_generate
		var candidate_score := float(evaluation.get("score", -1.0))
		var accepted := bool(evaluation.get("accepted", false))
		var candidate_record := {
			"semantic_snapshot": candidate_snapshot,
			"evaluation": evaluation,
			"acceptance_mode": "accepted" if accepted else "fallback_candidate",
			"attempt": attempt,
			"attempt_seed": attempt_seed,
			"world_profile": world_profile.duplicate(true),
			"procgen_settings": _capture_candidate_procgen_settings(candidate_map),
			"materialization_settings": _capture_candidate_materialization_settings(candidate_map),
		}
		var _t_total_attempt := Time.get_ticks_msec() - _attempt_start
		var candidate_terrain_failed := bool(evaluation.get("terrain_failed", true))
		_last_generation_attempts.append({
			"attempt": attempt,
			"attempt_seed": attempt_seed,
			"t_instantiate_ms": _t_instantiate,
			"t_generate_ms": _t_generate,
			"t_metrics_ms": _t_metrics,
			"t_total_ms": _t_total_attempt,
			"accepted": accepted,
			"score": candidate_score,
			"terrain_failed": candidate_terrain_failed,
			"metrics": candidate_metrics.duplicate(true),
		})
		print("[CustodianContractMap] Attempt %d: instantiate=%.1fs generate=%.1fs metrics=%.1fs total=%.1fs layout_valid=%s candidate_valid=%s connected=%.2f ingress=%.2f pre_terrain_connected=%.2f pre_terrain_missing=%d baseline_rescue=%d terrain_fallback=%s terrain_connectivity=%s terrain_rescue=%d terrain_rescue_limit=%d terrain_rescue_ok=%s rejection_reasons=%s accepted=%s score=%.2f" % [
			attempt,
			_t_instantiate / 1000.0,
			_t_generate / 1000.0,
			_t_metrics / 1000.0,
			_t_total_attempt / 1000.0,
			str(candidate_metrics.get("layout_valid", false)),
			str(candidate_metrics.get("candidate_valid", false)),
			float(candidate_metrics.get("connected_ratio", 0.0)),
			float(candidate_metrics.get("ingress_ratio", 0.0)),
			float(candidate_metrics.get("pre_terrain_connected_required_ratio", 1.0)),
			int(candidate_metrics.get("pre_terrain_missing_required_count", 0)),
			int(candidate_metrics.get("terrain_baseline_rescue_carved", 0)),
			str(candidate_metrics.get("terrain_fallback", false)),
			str(candidate_metrics.get("terrain_connectivity", true)),
			int(candidate_metrics.get("terrain_rescue_carved", 0)),
			terrain_rescue_reject_threshold,
			str(bool(candidate_metrics.get("terrain_rescue_ok", true))),
			str(candidate_metrics.get("rejection_reasons", [])),
			str(accepted),
			candidate_score,
		])
		if not accepted:
			print("[CustodianContractMap]   layout_debug: %s" % _candidate_evaluator.format_layout_metric_debug(candidate_metrics, _get_candidate_evaluation_settings()))
			if not required_ingresses_valid:
				print(
					"[CustodianContractMap]   required_ingress_failures: %s"
					% [candidate_metrics.get("required_ingress_failures", [])]
				)
		await _dispose_node(candidate_map)
		if _active_map == candidate_map:
			_active_map = null
		if accepted:
			best_map_score = candidate_score
			best_map_terrain_failed = candidate_terrain_failed
			best_attempt_seed = attempt_seed
			best_attempt_index = attempt
			best_attempt_metrics = candidate_metrics.duplicate(true)
			best_candidate = candidate_record
			selected_candidate = candidate_record
			map_seed = attempt_seed
			map_generated = true
			accepted_attempt = attempt
			break
		elif best_candidate.is_empty() or _candidate_evaluator.is_better_fallback_candidate(candidate_score, candidate_terrain_failed, best_map_score, best_map_terrain_failed):
			best_map_score = candidate_score
			best_map_terrain_failed = candidate_terrain_failed
			best_attempt_seed = attempt_seed
			best_attempt_index = attempt
			best_attempt_metrics = candidate_metrics.duplicate(true)
			best_candidate = candidate_record
	var _loop_total_duration_ms := Time.get_ticks_msec() - _attempt_total_start
	print("[CustodianContractMap] Attempt loop total: %.1fs attempts_run=%d max_attempts=%d accepted_attempt=%d" % [
		_loop_total_duration_ms / 1000.0,
		attempts_run,
		max(1, map_generation_attempts),
		accepted_attempt,
	])

	_last_contract_generation_report = {
		"contract_seed": int(contract_seed),
		"attempt_limit": max(1, map_generation_attempts),
		"attempts_run": attempts_run,
		"accepted_attempt": accepted_attempt,
		"total_candidate_loop_duration_ms": _loop_total_duration_ms,
		"using_degraded_fallback": false,
		"degraded_reason": "",
		"final_promotion_duration_ms": 0,
		"final_materialization_duration_ms": 0,
		"attempts": _last_generation_attempts,
	}

	var using_degraded_fallback := false
	if not map_generated and allow_degraded_best_candidate_fallback and _candidate_evaluator.can_use_degraded_fallback(best_attempt_metrics, _get_candidate_evaluation_settings()):
		selected_candidate = best_candidate.duplicate(false)
		selected_candidate["acceptance_mode"] = "degraded_fallback"
		map_seed = best_attempt_seed
		using_degraded_fallback = true
		_last_contract_generation_report["using_degraded_fallback"] = true
		_last_contract_generation_report["degraded_reason"] = "terrain_rescue_above_limit"
		print("[CustodianContractMap] DEGRADED_FALLBACK_ACCEPTED terrain_rescue=%d limit=%d" % [
			int(best_attempt_metrics.get("terrain_rescue_carved", 0)),
			terrain_rescue_reject_threshold,
		])
	elif not map_generated:
		var failure := _build_generation_failure_result(
			"no_accepted_candidate",
			attempts_run,
			best_attempt_index,
			best_map_score,
			best_attempt_metrics
		)
		_active_map = null
		_latest_contract = {}
		_latest_generation_failure = failure
		push_error("[CustodianContractMap] Contract generation failed safely: %s" % str(failure))
		contract_generation_failed.emit(failure)
		return

	if selected_candidate.is_empty():
		var failure := _build_generation_failure_result(
			"no_selected_candidate",
			attempts_run,
			best_attempt_index,
			best_map_score,
			best_attempt_metrics
		)
		_active_map = null
		_latest_contract = {}
		_latest_generation_failure = failure
		push_error("[CustodianContractMap] Contract generation failed safely: %s" % str(failure))
		contract_generation_failed.emit(failure)
		return

	var _final_promotion_start := Time.get_ticks_msec()
	level_data = await _generate_final_map_level_data(selected_candidate)
	var final_materialization_duration_ms := Time.get_ticks_msec() - _final_promotion_start
	_last_contract_generation_report["final_promotion_duration_ms"] = final_materialization_duration_ms
	_last_contract_generation_report["final_materialization_duration_ms"] = final_materialization_duration_ms
	if level_data.is_empty():
		var failure := _build_generation_failure_result(
			"candidate_materialization_failed",
			attempts_run,
			best_attempt_index,
			best_map_score,
			best_attempt_metrics
		)
		if _active_map != null:
			await _dispose_node(_active_map)
		_active_map = null
		_latest_contract = {}
		_latest_generation_failure = failure
		push_error("[CustodianContractMap] Candidate materialization failed safely: %s" % str(failure))
		contract_generation_failed.emit(failure)
		return
	map_instance = _active_map
	if using_degraded_fallback:
		level_data["degraded_fallback"] = true
		level_data["degraded_reason"] = "terrain_rescue_above_limit"
		level_data["degraded_attempt_metrics"] = best_attempt_metrics.duplicate(true)
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
	_latest_generation_failure = {}
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


func get_latest_generation_failure() -> Dictionary:
	return _latest_generation_failure


## Structured candidate-loop timing/acceptance report from the most recent
## generate_contract() call, for custodian.procgen_performance_baseline.v1.
## Populated even on generation failure so rejection evidence is retained.
func get_last_contract_generation_report() -> Dictionary:
	return _last_contract_generation_report.duplicate(true)


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

	map_instance.generation_evaluation_mode = true
	_disable_duplicate_tilemap_outputs(map_instance, map_instance)
	var procgen: ProcGen = map_instance.procgen_node
	if procgen == null:
		procgen = _find_procgen_node(map_instance)
	if procgen != null:
		procgen.auto_generate_on_ready = false
		procgen.generate_seed = false
		procgen.seed = map_seed

	map_root.add_child(map_instance)
	if not map_instance.is_node_ready():
		await map_instance.ready

	if map_instance.procgen_node == null:
		map_instance.procgen_node = _find_procgen_node(map_instance)

	if map_instance.procgen_node:
		map_instance.procgen_node.auto_generate_on_ready = false
		map_instance.procgen_node.generate_seed = false
		map_instance.procgen_node.seed = map_seed
		if map_instance.procgen_node.is_generating():
			push_warning("[CustodianContractMap] Candidate map had in-flight ProcGen work after auto-generation was disabled")
			while map_instance.procgen_node.is_generating():
				await get_tree().process_frame
		_apply_map_generation_profile(map_instance, attempt_index, planet_world_profile)
		map_instance.set_seed(map_seed)

	if map_instance is Node2D:
		(map_instance as Node2D).position = map_offset
	_active_map = map_instance
	return map_instance


func _capture_candidate_procgen_settings(map_instance: ProcGenTilemap) -> Dictionary:
	if map_instance == null or map_instance.procgen_node == null:
		return {}
	var procgen := map_instance.procgen_node
	return {
		"map_size": procgen.map_size,
		"room_amount": procgen.room_amount,
		"room_center_ratio": procgen.room_center_ratio,
		"corridor_edge_overlap_min_ratio": procgen.corridor_edge_overlap_min_ratio,
		"corridor_cycle_chance": procgen.corridor_cycle_chance,
		"automaton_iterations": procgen.automaton_iterations,
		"automaton_noise_rate": procgen.automaton_noise_rate,
		"automaton_corridor_fixed_width_expand": procgen.automaton_corridor_fixed_width_expand,
		"automaton_corridor_non_fixed_width_expand": procgen.automaton_corridor_non_fixed_width_expand,
	}


func _capture_candidate_materialization_settings(map_instance: ProcGenTilemap) -> Dictionary:
	if map_instance == null:
		return {}
	return {
		"generation_output_enabled": map_instance.generation_output_enabled,
		"enable_streaming_reveal": map_instance.enable_streaming_reveal,
		"build_runtime_wall_collision": map_instance.build_runtime_wall_collision,
		"show_runtime_wall_collision_debug": map_instance.show_runtime_wall_collision_debug,
		"enable_final_foliage": map_instance.enable_final_foliage,
		"enable_ruin_prop_spawning": map_instance.enable_ruin_prop_spawning,
		"interior_prop_spawning_enabled": map_instance.interior_prop_spawning_enabled,
		"auto_bake_nav": map_instance.auto_bake_nav,
	}


func _instantiate_accepted_final_map(candidate: Dictionary) -> ProcGenTilemap:
	if map_scene == null:
		return null
	var map_value: Variant = map_scene.instantiate()
	if not map_value is ProcGenTilemap:
		return null
	var map_instance := map_value as ProcGenTilemap
	map_instance.generation_evaluation_mode = false
	_disable_duplicate_tilemap_outputs(map_instance, map_instance)
	var procgen: ProcGen = map_instance.procgen_node
	if procgen == null:
		procgen = _find_procgen_node(map_instance)
	if procgen == null:
		map_instance.free()
		return null
	procgen.auto_generate_on_ready = false
	procgen.generate_seed = false
	procgen.seed = int(candidate.get("attempt_seed", -1))

	map_root.add_child(map_instance)
	if not map_instance.is_node_ready():
		await map_instance.ready
	if map_instance.procgen_node == null:
		map_instance.procgen_node = _find_procgen_node(map_instance)
	procgen = map_instance.procgen_node
	if procgen == null:
		await _dispose_node(map_instance)
		return null
	if procgen.is_generating():
		push_warning("[CustodianContractMap] Final candidate map had in-flight ProcGen work after auto-generation was disabled")
		while procgen.is_generating():
			await get_tree().process_frame

	var profile: Dictionary = candidate.get("world_profile", {})
	if not profile.is_empty():
		map_instance.apply_planet_world_profile(profile)
	var materialization_settings: Dictionary = candidate.get("materialization_settings", {})
	for setting_variant: Variant in materialization_settings:
		map_instance.set(String(setting_variant), materialization_settings[setting_variant])
	var procgen_settings: Dictionary = candidate.get("procgen_settings", {})
	for setting_variant: Variant in procgen_settings:
		procgen.set(String(setting_variant), procgen_settings[setting_variant])
	procgen.auto_generate_on_ready = false
	procgen.generate_seed = false
	procgen.seed = int(candidate.get("attempt_seed", -1))
	map_instance.set_seed(int(candidate.get("attempt_seed", -1)))
	var map_node: Variant = map_instance
	if map_node is Node2D:
		(map_node as Node2D).position = map_offset
	_active_map = map_instance
	return map_instance


func _disable_duplicate_tilemap_outputs(node: Node, owner_map: ProcGenTilemap) -> void:
	for child in node.get_children():
		if child is ProcGenTilemap and child != owner_map:
			(child as ProcGenTilemap).generation_output_enabled = false
		_disable_duplicate_tilemap_outputs(child, owner_map)


func _find_procgen_node(node: Node) -> ProcGen:
	if node is ProcGen:
		return node as ProcGen
	for child in node.get_children():
		var found := _find_procgen_node(child)
		if found != null:
			return found
	return null


func _generate_final_map_level_data(candidate: Dictionary) -> Dictionary:
	var map_instance: ProcGenTilemap = await _instantiate_accepted_final_map(candidate)
	if map_instance == null:
		push_error("[CustodianContractMap] Could not instantiate final accepted candidate runtime.")
		return {}
	print("[CustodianContractMap] FINAL_VISUAL_BEGIN map_path=%s eval_mode_before=%s" % [
		str(map_instance.get_path()),
		str(map_instance.generation_evaluation_mode),
	])
	var _final_start := Time.get_ticks_msec()
	var materialization: Dictionary = _candidate_materializer.materialize(candidate, map_instance)
	print("[CustodianContractMap] FINAL_PROMOTION_END total=%.1fs" % [
		(Time.get_ticks_msec() - _final_start) / 1000.0
	])
	if not bool(materialization.get("ok", false)):
		_last_contract_generation_report["materialization_failure"] = materialization.duplicate(true)
		push_error("[CustodianContractMap] Candidate materializer rejected selected world: %s" % str(materialization))
		await _dispose_node(map_instance)
		_active_map = null
		return {}
	_last_contract_generation_report["materialization"] = materialization.get("report", {}).duplicate(true)
	_last_contract_generation_report["final_materialization_duration_ms"] = Time.get_ticks_msec() - _final_start
	return materialization.get("level_data", {})


func _generate_map_level_data(map_instance: ProcGenTilemap) -> Dictionary:
	_map_level_data_ready = false
	_map_level_data = {}
	var mode := "EVAL_CANDIDATE" if map_instance.generation_evaluation_mode else "FINAL_VISUAL"
	var seed_text := "unknown"
	if map_instance.procgen_node != null:
		seed_text = str(map_instance.procgen_node.seed)
	print("[CustodianContractMap] GENERATE_BEGIN mode=%s seed=%s map_path=%s" % [
		mode,
		seed_text,
		str(map_instance.get_path()),
	])

	map_instance.level_data_ready.connect(_on_map_level_data_ready, CONNECT_ONE_SHOT)
	map_instance.generate()

	while not _map_level_data_ready:
		await get_tree().process_frame

	print("[CustodianContractMap] GENERATE_END mode=%s seed=%s" % [
		mode,
		seed_text,
	])
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
	if region_frame_profile_id != &"":
		profile["region_frame_profile_id"] = String(region_frame_profile_id)
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


func _build_generation_failure_result(
	failure_reason: String,
	attempts_run: int,
	best_rejected_attempt: int,
	best_rejected_score: float,
	best_rejected_metrics: Dictionary
) -> Dictionary:
	return {
		"generation_failed": true,
		"failure_reason": failure_reason,
		"attempts_run": attempts_run,
		"max_attempts": max(1, map_generation_attempts),
		"best_rejected_attempt": best_rejected_attempt,
		"best_rejected_score": best_rejected_score,
		"best_rejected_terrain_rescue": int(best_rejected_metrics.get("terrain_rescue_carved", 0)),
		"best_rejected_baseline_rescue": int(best_rejected_metrics.get("terrain_baseline_rescue_carved", 0)),
		"best_rejected_pre_terrain_required_connectivity": float(best_rejected_metrics.get("pre_terrain_connected_required_ratio", 1.0)),
		"best_rejected_pre_terrain_missing": int(best_rejected_metrics.get("pre_terrain_missing_required_count", 0)),
		"best_rejected_reasons": best_rejected_metrics.get("rejection_reasons", []).duplicate(true),
		"best_rejected_required_ingress_failures": (
			best_rejected_metrics.get("required_ingress_failures", []) as Array
		).duplicate(true),
	}


func _get_candidate_evaluation_settings() -> Dictionary:
	return {
		"pre_terrain_required_connectivity_min": pre_terrain_required_connectivity_min,
		"terrain_rescue_reject_threshold": terrain_rescue_reject_threshold,
		"min_connected_room_ratio": min_connected_room_ratio,
		"require_compound_ingress_connectivity": require_compound_ingress_connectivity,
	}
