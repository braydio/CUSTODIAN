extends Node2D
class_name SunderedKeepMap

const TILE_SIZE := 32.0
const DEFAULT_LEVEL_DATA_PATH := "res://content/levels/sundered_keep/sundered_keep_front_gate_large.json"
const DEFAULT_SIEGE_CONFIG_PATH := "res://content/levels/sundered_keep/gatehouse_siege_config.json"
const SUNDERED_KEEP_ASSETS := preload("res://content/runtime/sundered_keep/sundered_keep_game32_assets.gd")
const SUNDERED_KEEP_INTERACTABLE := preload("res://game/world/sundered_keep/sundered_keep_interactable.gd")
const SUNDERED_KEEP_TILEMAP_LOADER := preload("res://game/world/sundered_keep/sundered_keep_tilemap_loader.gd")
const SUNDERED_KEEP_SIEGE_OBJECTIVE := preload("res://game/world/sundered_keep/sundered_keep_siege_objective.gd")
const PROP_OPERATOR_DEPTH_SORT := preload("res://game/world/prop_operator_depth_sort.gd")
const ELEVATION_MAP_SCRIPT := preload("res://game/world/elevation/elevation_map.gd")
const SPAWN_NODE_SCRIPT := preload("res://game/systems/core/systems/spawn_node.gd")
const DEFENSE_TURRET_SCENE := preload("res://game/actors/defense/turret.tscn")
const CUSTODIAN_HUD_SCENE := preload("res://game/ui/hud/custodian_hud.tscn")
const UI_CATALOG := preload("res://game/ui/theme/black_reliquary_asset_catalog.gd")
const ENEMY_MARINE_SCENE := preload("res://game/actors/enemies/enemy_marine.tscn")
const SUNDERED_KEEP_MARINE_AMBUSH := preload("res://game/world/sundered_keep/sundered_keep_marine_ambush.gd")
const LAST_ROUTEKEEPER_EVENT := preload("res://game/world/events/last_routekeeper/last_routekeeper_event.gd")
const LAST_ROUTEKEEPER_EVENT_ID := &"last_routekeeper"
const LAST_ROUTEKEEPER_TRACE_ITEM_ID := &"routekeeper_trace_note"
const LAST_ROUTEKEEPER_TRACE_ITEM_NAME := "Routekeeper Trace"
const DEFAULT_LEVEL_UNDERLAY_PATH := "res://content/masters/sundered_keep/sundered_keep_main_overlay.png"

const ELEVATION_STEP_PX := 24.0
const CAUSEWAY_BRAZIER_FLICKER_PATH := "res://content/tiles/sundered_keep/entrance/props/causeway_lit_brazier_flicker_01.png"
const CAUSEWAY_BRAZIER_FLICKER_FRAME_SIZE := Vector2i(48, 64)
const CAUSEWAY_BRAZIER_FLICKER_FRAMES := 9
const CAUSEWAY_BRAZIER_FLICKER_FPS := 9.0
const HANGING_BRAZIER_FRAME_SIZE := Vector2i(34, 96)
const HANGING_BRAZIER_FRAMES := 9
const HANGING_BRAZIER_FPS := 9.0
const GATEHOUSE_PREFAB_OPEN_PATH := "res://content/tiles/sundered_keep/entrance/prefabs/gateway_prefab_spritesheet_open_gate.png"
const GATEHOUSE_PREFAB_OPEN_FRAME_SIZE := Vector2i(264, 445)
const GATEHOUSE_PREFAB_OPEN_FRAMES := 8
const GATEHOUSE_PREFAB_OPEN_FPS := 10.0
const GREAT_HALL_DOOR_OPEN_PATH := "res://content/tiles/sundered_keep/entrance/prefabs/open_great_doors_prefab_sheet.png"
const GREAT_HALL_DOOR_OPEN_FRAME_SIZE := Vector2i(246, 297)
const GREAT_HALL_DOOR_OPEN_FRAMES := 8
const GREAT_HALL_DOOR_OPEN_FPS := 10.0
# Sundered Keep readability placeholders live here until production keep-wall art is supplied.
# Every asset in this directory should keep the PLACEHOLDER_ filename prefix.
const PLACEHOLDER_KEEP_WALL_HOME := "res://content/tiles/sundered_keep/placeholders/walls"
const PLACEHOLDER_KEEP_WALL_PREFIX := "PLACEHOLDER_sundered_keep_labyrinth_"
const GREAT_HALL_MARINE_SPAWN_TILE := Vector2i(71, 27)

const SUNDERED_GATE_KEY_ID := &"sundered_gate_key"
const SUNDERED_GATE_KEY_NAME := "Sundered Gate Key"
const SUNDERED_GATE_KEY_FLAVOR := "A corroded winch key stamped with the keep's split-ring seal."
const SIDEARM_LOCKER_ITEM_NAME := "P-9 Field Sidearm"
const SIDEARM_LOCKER_PICKUP_MESSAGE := "P-9 FIELD SIDEARM ACQUIRED"
const SIDEARM_LOCKER_ITEM_ID := &"p9_sidearm"

const WALL_ASSET_DIRS := [
	"res://content/tiles/sundered_keep/entrance/causeway_walls",
	"res://content/tiles/sundered_keep/walls/gatehouse",
	"res://content/tiles/sundered_keep/walls/gothic_castle",
	"res://content/tiles/sundered_keep/walls/great_hall",
	"res://content/tiles/sundered_keep/walls/ramparts",
	"res://content/tiles/sundered_keep/walls",
]

@export var level_data_path: String = DEFAULT_LEVEL_DATA_PATH
@export var siege_config_path: String = DEFAULT_SIEGE_CONFIG_PATH
@export_file("*.png") var level_underlay_path: String = DEFAULT_LEVEL_UNDERLAY_PATH
@export var entrance_tile: Vector2i = Vector2i(56, 76)
@export var return_gate_tile: Vector2i = Vector2i(42, 58)
@export var main_gate_tile: Vector2i = Vector2i(54, 50)
@export var great_hall_door_tile: Vector2i = Vector2i(55, 30)
@export var upper_stair_tile: Vector2i = Vector2i(55, 17)
@export var lower_stair_tile: Vector2i = Vector2i(20, 37)
@export var hatch_tile: Vector2i = Vector2i(25, 39)
@export var return_mooring_origin_tile: Vector2i = Vector2i(39, 56)
@export var key_pickup_tile: Vector2i = Vector2i(73, 56)
@export var sidearm_locker_tile: Vector2i = Vector2i(73, 27)
@export var routekeeper_trace_tile: Vector2i = Vector2i(37, 53)
@export var routekeeper_hint_tile: Vector2i = Vector2i(25, 39)
@export_range(0, 100, 1) var routekeeper_base_spawn_chance_percent := 4
@export_range(0, 100, 1) var routekeeper_post_gate_spawn_chance_percent := 12
@export var force_routekeeper_event := false

var map_size_tiles := Vector2i(112, 80)

var _built := false
var _camera_bounds := Rect2()
var _layers: Dictionary = {}
var _textures: Dictionary = {}
var _elevation_map: Node = null
var _last_actor_elevation_tile := Vector2i(-9999, -9999)
var _underpass_regions: Array[Dictionary] = []
var _shore_walk_regions: Array[Dictionary] = []
var _interior_occlusion_regions: Array[Dictionary] = []
var _roof_occluders: Dictionary = {}
var _active_interior_region_id := ""
var _active_interior_region_ids: Array[String] = []
var _brazier_flicker_frames: SpriteFrames = null
var _hanging_brazier_frames: Dictionary = {}
var _return_gate: Node2D = null
var _route_backtrack_exit: LevelExit2D = null
var _route_exfil_exit: LevelExit2D = null
var _return_mooring_interaction: Node2D = null
var _return_mooring_active_overlay: Sprite2D = null
var _main_gate_interaction: Node2D = null
var _great_hall_door_interaction: Node2D = null
var _key_pickup_interaction: Node2D = null
var _sidearm_locker_interaction: Node2D = null
var _main_gate_closed_sprite: Sprite2D = null
var _main_gate_open_sprite: AnimatedSprite2D = null
var _main_gate_open_frames: SpriteFrames = null
var _main_gate_blockers: Array[Node] = []
var _great_hall_door_closed_sprite: AnimatedSprite2D = null
var _great_hall_door_open_sprite: AnimatedSprite2D = null
var _great_hall_door_blockers: Array[Node] = []
var _main_gate_open := false
var _great_hall_door_open := false
var _has_sundered_gate_key := false
var _sidearm_locker_opened := false
var _return_mooring_created := false
var _last_routekeeper_event: Node2D = null
var _last_routekeeper_interaction: Node2D = null
var _last_routekeeper_trace_recovered := false
var _routekeeper_hint_marker: Node2D = null
var _siege_started := false
var _siege_wave_index := 0
var _siege_pressure_tick := 0
var _siege_state := "dormant"
var _siege_game_over_triggered := false
var _siege_objectives: Dictionary = {}
var _siege_spawn_nodes: Array[Node2D] = []
var _siege_live_enemies: Dictionary = {}
var _siege_required_enemy_ids: Dictionary = {}
var _siege_wave_spawning := false
var _siege_config: Dictionary = {}
var _siege_timer: Timer = null
var _siege_debug_label: Label = null
var _siege_turret: Node2D = null
var _hud: Node = null
var _great_hall_marine_ambush: Node = null
var _great_hall_door_open_frames: SpriteFrames = null
var _minimap_floor_cells: Dictionary = {}
var _minimap_wall_cells: Dictionary = {}
var _level_id := ""
var _level_underlay_sprite: Sprite2D = null
var _level_underlay_rect_tiles := Rect2i()
var _level_underlay_texture_path := ""
var _level_authoring_mask_path := ""
var _stats := {
	"floors": 0,
	"edges": 0,
	"walls": 0,
	"props": 0,
	"blockers": 0,
	"interactables": 0,
	"modules": 0,
	"missing_assets": 0,
}


func _ready() -> void:
	add_to_group("connected_map")
	add_to_group("sundered_keep_map")
	_build_once()
	_ensure_hud()
	set_process(true)


func _process(_delta: float) -> void:
	_update_hud_prompt()
	_update_actor_elevation()


func get_entry_position() -> Vector2:
	return to_global(_tile_center(entrance_tile))


func get_return_gate_position() -> Vector2:
	return to_global(_tile_center(return_gate_tile))


func get_camera_bounds() -> Rect2:
	return Rect2(to_global(_camera_bounds.position), _camera_bounds.size)


func get_elevation_map() -> Node:
	return _elevation_map


func get_elevation_data_at_tile(tile: Vector2i) -> Dictionary:
	if _elevation_map == null:
		return {
			"height": 0,
			"traversal_type": "walkable",
			"direction": "none",
		}
	return _elevation_map.call("get_cell_data", tile) as Dictionary


func get_elevation_at_tile(tile: Vector2i) -> int:
	if _elevation_map == null:
		return 0
	return int(_elevation_map.call("get_height", tile))


func get_elevation_at_global(global_position: Vector2) -> int:
	return get_elevation_at_tile(_global_to_tile(global_position))


func can_traverse_elevation(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	if _elevation_map == null:
		return true
	return bool(_elevation_map.call("can_traverse", from_tile, to_tile))


func is_tile_in_underpass_region(tile: Vector2i) -> bool:
	return _tile_in_authored_regions(tile, _underpass_regions)


func is_tile_in_shore_walk_region(tile: Vector2i) -> bool:
	return _tile_in_authored_regions(tile, _shore_walk_regions)


func get_active_interior_region_id() -> String:
	return _active_interior_region_id


func return_to_main(actor: Node) -> void:
	if _route_exfil_exit == null or not is_instance_valid(_route_exfil_exit):
		push_error("[SunderedKeep] Route exfil exit is unavailable")
		return
	_route_exfil_exit.request_transition(actor)


func has_spawn(spawn_id: StringName) -> bool:
	return find_child(String(spawn_id), true, false) is Node2D


func get_spawn_position(spawn_id: StringName) -> Vector2:
	var marker := find_child(String(spawn_id), true, false) as Node2D
	return marker.global_position if marker != null else global_position


func activate_route_node(actor: Node, spawn_id: StringName) -> bool:
	if not (actor is Node2D) or not has_spawn(spawn_id):
		return false
	_set_hud_active(true)
	(actor as Node2D).global_position = get_spawn_position(spawn_id)
	_refresh_camera(self, actor)
	return true


func capture_route_state() -> Dictionary:
	return {
		"has_sundered_gate_key": _has_sundered_gate_key,
		"main_gate_open": _main_gate_open,
		"return_mooring_created": _return_mooring_created,
		"great_hall_door_open": _great_hall_door_open,
		"sidearm_locker_opened": _sidearm_locker_opened,
		"routekeeper_trace_recovered": _last_routekeeper_trace_recovered,
		"siege_started": _siege_started,
		"siege_wave_index": _siege_wave_index,
		"siege_pressure_tick": _siege_pressure_tick,
		"siege_state": _siege_state,
		"siege_game_over_triggered": _siege_game_over_triggered,
		"siege_objectives": _get_siege_objective_states(),
		"great_hall_ambush": _get_great_hall_marine_ambush_state(),
	}


func can_restore_route_state(state: Dictionary) -> bool:
	if state.has("siege_objectives") \
	and not (state.get("siege_objectives") is Dictionary):
		return false
	if state.has("great_hall_ambush") \
	and not (state.get("great_hall_ambush") is Dictionary):
		return false
	return true


func restore_route_state(state: Dictionary) -> bool:
	if not can_restore_route_state(state):
		return false
	_has_sundered_gate_key = bool(state.get("has_sundered_gate_key", false))
	_restore_main_gate_open_without_events(bool(state.get("main_gate_open", false)))
	_return_mooring_created = bool(state.get("return_mooring_created", _return_mooring_created))
	_set_return_mooring_active(_return_mooring_created)
	_set_great_hall_door_open(
		bool(state.get("great_hall_door_open", false)),
		false
	)
	_sidearm_locker_opened = bool(state.get("sidearm_locker_opened", false))
	_last_routekeeper_trace_recovered = bool(state.get("routekeeper_trace_recovered", false))
	_siege_started = bool(state.get("siege_started", false))
	_siege_wave_index = int(state.get("siege_wave_index", 0))
	_siege_pressure_tick = int(state.get("siege_pressure_tick", 0))
	_siege_state = str(state.get("siege_state", "dormant"))
	_siege_game_over_triggered = bool(state.get("siege_game_over_triggered", false))
	if _has_sundered_gate_key and _key_pickup_interaction != null and is_instance_valid(_key_pickup_interaction):
		_key_pickup_interaction.remove_from_group("interactable")
		_key_pickup_interaction.visible = false
	if _sidearm_locker_opened and _sidearm_locker_interaction != null and is_instance_valid(_sidearm_locker_interaction):
		_sidearm_locker_interaction.remove_from_group("interactable")
		_sidearm_locker_interaction.visible = false
	if not _restore_siege_objective_states(
		state.get("siege_objectives", {}) as Dictionary
	):
		return false
	if not _restore_great_hall_ambush_state(
		state.get("great_hall_ambush", {}) as Dictionary
	):
		return false
	_restore_siege_runtime_after_route_load()
	_refresh_hud_state()
	return true


func _restore_siege_objective_states(states: Dictionary) -> bool:
	for objective_id_variant: Variant in states.keys():
		var objective_id := StringName(str(objective_id_variant))
		var objective: Node = _siege_objectives.get(String(objective_id)) as Node
		if objective == null or not is_instance_valid(objective):
			push_error(
				"[SunderedKeep] Missing siege objective during route restore: %s"
				% objective_id
			)
			return false
		if not objective.has_method("restore_route_state"):
			push_error(
				"[SunderedKeep] Siege objective lacks route-state restoration: %s"
				% objective_id
			)
			return false
		var objective_state: Variant = states[objective_id_variant]
		if not (objective_state is Dictionary):
			return false
		var restored: Variant = objective.call(
			"restore_route_state",
			objective_state as Dictionary
		)
		if restored is bool and not bool(restored):
			return false
	return true


func _restore_great_hall_ambush_state(state: Dictionary) -> bool:
	if state.is_empty():
		return true
	if _great_hall_marine_ambush == null \
	or not is_instance_valid(_great_hall_marine_ambush):
		push_error(
			"[SunderedKeep] Great Hall ambush is unavailable during route restore"
		)
		return false
	if not _great_hall_marine_ambush.has_method("restore_route_state"):
		push_error(
			"[SunderedKeep] Great Hall ambush lacks route-state restoration"
		)
		return false
	var restored: Variant = _great_hall_marine_ambush.call(
		"restore_route_state",
		state
	)
	return not (restored is bool) or bool(restored)


func _restore_siege_runtime_after_route_load() -> void:
	_siege_live_enemies.clear()
	_siege_required_enemy_ids.clear()
	_siege_wave_spawning = false
	if _siege_state == "active" and _siege_started:
		_ensure_siege_timer()
	if _siege_timer == null:
		return
	if _siege_game_over_triggered:
		_siege_timer.stop()
		return
	match _siege_state:
		"active":
			if _siege_started \
			and is_inside_tree() \
			and _siege_timer.is_stopped():
				_siege_timer.start()
			elif not _siege_started:
				_siege_timer.stop()
		"secured", "collapsed", "dormant":
			_siege_timer.stop()
		_:
			_siege_timer.stop()


func _restore_main_gate_open_without_events(open: bool) -> void:
	_main_gate_open = open
	if _main_gate_closed_sprite != null:
		_main_gate_closed_sprite.visible = not open
	if _main_gate_open_sprite != null:
		_main_gate_open_sprite.visible = open
		_main_gate_open_sprite.stop()
		_main_gate_open_sprite.frame = 0
	if open:
		_clear_main_gate_blockers()
		if _main_gate_interaction != null:
			_main_gate_interaction.remove_from_group("interactable")
			_main_gate_interaction.visible = false
	elif is_inside_tree():
		_add_main_gate_blockers()
	_refresh_hud_state()


func prepare_route_deactivation(_context: Dictionary) -> void:
	_set_hud_active(false)


func complete_route_activation(_context: Dictionary) -> bool:
	_set_hud_active(true)
	return true


func refresh_route_camera(actor: Node) -> bool:
	_refresh_camera(self, actor)
	return true


func get_sundered_keep_debug_state() -> Dictionary:
	return {
		"level_id": _level_id,
		"map_size_tiles": map_size_tiles,
		"underlay_present": _level_underlay_sprite != null and is_instance_valid(_level_underlay_sprite),
		"underlay_texture_path": _level_underlay_texture_path,
		"underlay_rect_tiles": _level_underlay_rect_tiles,
		"authoring_mask_path": _level_authoring_mask_path,
		"floor_sprites": int(_stats["floors"]),
		"edge_sprites": int(_stats["edges"]),
		"wall_sprites": int(_stats["walls"]),
		"prop_sprites": int(_stats["props"]),
		"blocker_bodies": int(_stats["blockers"]),
		"interactable_areas": int(_stats["interactables"]),
		"module_count": int(_stats["modules"]),
		"missing_assets": int(_stats["missing_assets"]),
		"elevation_cells": _get_elevation_cell_count(),
		"bridge_elevation_height": get_elevation_at_tile(Vector2i(56, 60)),
		"underpass_region_count": _underpass_regions.size(),
		"shore_walk_region_count": _shore_walk_regions.size(),
		"interior_occlusion_region_count": _interior_occlusion_regions.size(),
		"roof_occluder_count": _roof_occluders.size(),
		"active_interior_region_id": _active_interior_region_id,
		"active_interior_region_ids": _active_interior_region_ids.duplicate(),
		"roof_occluder_alphas": _get_roof_occluder_alphas(),
		"main_gate_open": _main_gate_open,
		"great_hall_door_open": _great_hall_door_open,
		"has_sundered_gate_key": _player_has_sundered_gate_key(),
		"key_pickup_exists": _key_pickup_interaction != null and is_instance_valid(_key_pickup_interaction),
		"sidearm_locker_opened": _sidearm_locker_opened,
		"sidearm_locker_exists": _sidearm_locker_interaction != null and is_instance_valid(_sidearm_locker_interaction),
		"sidearm_locker_available": not _sidearm_locker_opened \
			and _sidearm_locker_interaction != null \
			and is_instance_valid(_sidearm_locker_interaction) \
			and _sidearm_locker_interaction.is_in_group("interactable"),
		"return_mooring_created": _return_mooring_created,
		"siege_started": _siege_started,
		"siege_state": _siege_state,
		"siege_game_over_triggered": _siege_game_over_triggered,
		"siege_wave_index": _siege_wave_index,
		"siege_pressure_tick": _siege_pressure_tick,
		"siege_objectives": _get_siege_objective_states(),
		"siege_spawn_nodes": _siege_spawn_nodes.size(),
		"siege_live_enemies": _siege_live_enemies.size(),
		"siege_required_enemies": _siege_required_enemy_ids.size(),
		"siege_turret_exists": _siege_turret != null and is_instance_valid(_siege_turret),
		"great_hall_marine_ambush": _get_great_hall_marine_ambush_state(),
		"last_routekeeper_spawned": _last_routekeeper_event != null and is_instance_valid(_last_routekeeper_event),
		"last_routekeeper_recovered": _last_routekeeper_trace_recovered,
		"last_routekeeper_trace_tile": routekeeper_trace_tile,
		"last_routekeeper_hint_tile": routekeeper_hint_tile,
	}


func get_level_data() -> Dictionary:
	return {
		"map_size": map_size_tiles,
		"tile_size": Vector2(TILE_SIZE, TILE_SIZE),
		"floor_cells": _minimap_floor_cells.keys(),
		"wall_cells": _minimap_wall_cells.keys(),
		"rooms": [entrance_tile, return_mooring_origin_tile, main_gate_tile, great_hall_door_tile],
		"interior_rooms": _interior_regions_as_rects(),
		"compound_rect": Rect2i(),
		"compound_ingress": [],
		"compound_buildings": [],
		"region_tiles": {},
	}


func global_to_minimap_tile(global_position: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor(global_position.x / TILE_SIZE)), 0, map_size_tiles.x - 1),
		clampi(int(floor(global_position.y / TILE_SIZE)), 0, map_size_tiles.y - 1)
	)


func minimap_tile_to_global(tile: Vector2i) -> Vector2:
	return _tile_center(tile)


func _interior_regions_as_rects() -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	for region in _interior_occlusion_regions:
		if region.has("rect"):
			result.append(region["rect"] as Rect2i)
	return result


func debug_print_layout_summary() -> void:
	var state := get_sundered_keep_debug_state()
	print("[SunderedKeepDataTilemap] Built %s size=%s floors=%d edges=%d walls=%d props=%d blockers=%d interactables=%d modules=%d missing_assets=%d gate_open=%s key=%s return_mooring=%s" % [
		str(state["level_id"]),
		str(state["map_size_tiles"]),
		int(state["floor_sprites"]),
		int(state["edge_sprites"]),
		int(state["wall_sprites"]),
		int(state["prop_sprites"]),
		int(state["blocker_bodies"]),
		int(state["interactable_areas"]),
		int(state["module_count"]),
		int(state["missing_assets"]),
		str(state["main_gate_open"]),
		str(state["has_sundered_gate_key"]),
		str(state["return_mooring_created"]),
	])


func _build_once() -> void:
	if _built:
		return
	_built = true
	var loader: RefCounted = SUNDERED_KEEP_TILEMAP_LOADER.new()
	var level_data: Dictionary = loader.call("load_level", level_data_path)
	if not level_data.is_empty():
		_build_from_level_data(level_data)
		debug_print_layout_summary()
		return

	_camera_bounds = Rect2(
		Vector2(-TILE_SIZE * 2.0, -TILE_SIZE * 2.0),
		Vector2(float(map_size_tiles.x + 4) * TILE_SIZE, float(map_size_tiles.y + 4) * TILE_SIZE)
	)
	_create_layers()
	_build_level_underlay()
	_build_ocean_backdrop()
	_build_cliff_island_foundation()
	_build_storm_causeway()
	_build_return_mooring(return_mooring_origin_tile)
	_build_main_gate_lock()
	_build_sundered_gate_key_pickup(key_pickup_tile)
	_build_irregular_courtyard()
	_build_great_hall()
	_build_sidearm_locker()
	_build_east_rampart()
	_build_west_service_path()
	_build_traversal_stubs()
	_add_return_gate()
	debug_print_layout_summary()


func _create_layers() -> void:
	_create_layers_from_names([
		"Underlay",
		"TerrainBase",
		"TerrainEdges",
		"FloorDetail",
		"WallsLow",
		"WallsHigh",
		"PropsStatic",
		"PropsBlocking",
		"Traversal",
		"Hazards",
		"Overlays",
		"Effects",
		"WorldUI",
		"RoofOccluders",
		"Collision",
	])


func _create_layers_from_names(names: Array) -> void:
	var z_by_name := {
		"Underlay": -120,
		"TerrainBase": -90,
		"TerrainEdges": -75,
		"FloorDetail": -60,
		"WallsLow": -35,
		"WallsHigh": -15,
		"PropsStatic": -5,
		"PropsBlocking": 5,
		"Traversal": 8,
		"Hazards": 10,
		"Overlays": 15,
		"Effects": 25,
		"WorldUI": 45,
		"RoofOccluders": 60,
		"Collision": 0,
	}
	for layer_name in names:
		if _layers.has(str(layer_name)):
			continue
		var layer := Node2D.new()
		layer.name = str(layer_name)
		layer.z_as_relative = false
		layer.z_index = int(z_by_name.get(str(layer_name), 0))
		add_child(layer)
		_layers[str(layer_name)] = layer


func _build_from_level_data(data: Dictionary) -> void:
	_level_id = str(data.get("level_id", "sundered_keep_front_gate_large"))
	_level_authoring_mask_path = str(data.get("authoring_mask_path", ""))
	map_size_tiles = _array_to_vector2i(data.get("map_size_tiles", [112, 80]), map_size_tiles)
	entrance_tile = _array_to_vector2i(data.get("start_tile", [entrance_tile.x, entrance_tile.y]), entrance_tile)
	return_gate_tile = _array_to_vector2i(data.get("return_gate_tile", [return_gate_tile.x, return_gate_tile.y]), return_gate_tile)
	main_gate_tile = _array_to_vector2i(data.get("main_gate_tile", [main_gate_tile.x, main_gate_tile.y]), main_gate_tile)
	great_hall_door_tile = _array_to_vector2i(data.get("great_hall_door_tile", [great_hall_door_tile.x, great_hall_door_tile.y]), great_hall_door_tile)
	upper_stair_tile = _array_to_vector2i(data.get("upper_stair_tile", [upper_stair_tile.x, upper_stair_tile.y]), upper_stair_tile)
	lower_stair_tile = _array_to_vector2i(data.get("lower_stair_tile", [lower_stair_tile.x, lower_stair_tile.y]), lower_stair_tile)
	hatch_tile = _array_to_vector2i(data.get("hatch_tile", [hatch_tile.x, hatch_tile.y]), hatch_tile)
	return_mooring_origin_tile = _array_to_vector2i(data.get("return_mooring_origin_tile", [return_mooring_origin_tile.x, return_mooring_origin_tile.y]), return_mooring_origin_tile)
	key_pickup_tile = _array_to_vector2i(data.get("key_pickup_tile", [key_pickup_tile.x, key_pickup_tile.y]), key_pickup_tile)

	var bounds_array: Array = data.get("camera_bounds_tiles", [0, 0, map_size_tiles.x, map_size_tiles.y])
	_camera_bounds = Rect2(
		Vector2(float(bounds_array[0]) * TILE_SIZE, float(bounds_array[1]) * TILE_SIZE),
		Vector2(float(bounds_array[2]) * TILE_SIZE, float(bounds_array[3]) * TILE_SIZE)
	)
	_create_layers_from_names(data.get("layers", []))
	_build_level_underlay(data.get("underlay", {}))
	_build_ocean_backdrop()
	_build_elevation_from_level_data(data)
	_build_underpass_and_shore_regions(data)

	for op in data.get("ops", []):
		_apply_level_op(op)

	_build_interior_occlusion_regions(data)
	for marker in data.get("markers", []):
		_apply_marker(marker)
	for interactable in data.get("interactables", []):
		_apply_interactable(interactable)
	for blocker in data.get("blockers", []):
		_apply_blocker(blocker)

	_build_stateful_gates_from_level_data()
	_build_great_hall_marine_ambush()
	_build_sidearm_locker()
	_build_siege_runtime_slice()
	_build_traversal_stubs()
	_add_return_gate()


func _apply_level_op(op: Dictionary) -> void:
	match str(op.get("type", "")):
		"fill_rect":
			_apply_fill_rect(op)
		"fill_weighted_rect":
			_apply_fill_weighted_rect(op)
		"paint_cells":
			_apply_paint_cells(op)
		"stamp_prop":
			_apply_stamp_prop(op)
		"stamp_prefab":
			_apply_stamp_prefab(op)
		"stamp_module":
			_apply_stamp_module(op)
		"stamp_wall":
			_apply_stamp_wall(op)
		"blocker_rect":
			_apply_blocker(op)
		"interactable":
			_apply_interactable(op)
		"marker":
			_apply_marker(op)
		_:
			push_warning("[SunderedKeepDataTilemap] Unknown op type: %s" % str(op.get("type", "")))


func _apply_fill_rect(op: Dictionary) -> void:
	var rect := _array_to_rect2i(op.get("rect", [0, 0, 0, 0]))
	var layer := str(op.get("layer", "TerrainBase"))
	var asset_id := str(op.get("asset_id", ""))
	var category := str(op.get("category", _category_for_layer_asset(layer, asset_id)))
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_add_tile(layer, asset_id, category, Vector2i(x, y))


func _apply_fill_weighted_rect(op: Dictionary) -> void:
	var rect := _array_to_rect2i(op.get("rect", [0, 0, 0, 0]))
	var layer := str(op.get("layer", "TerrainBase"))
	var assets: Array = op.get("assets", [])
	if assets.is_empty():
		return
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var asset_id := _weighted_asset_for_tile(assets, x, y)
			var category := str(op.get("category", _category_for_layer_asset(layer, asset_id)))
			_add_tile(layer, asset_id, category, Vector2i(x, y))


func _apply_paint_cells(op: Dictionary) -> void:
	var layer := str(op.get("layer", "TerrainBase"))
	var asset_id := str(op.get("asset_id", ""))
	var category := str(op.get("category", _category_for_layer_asset(layer, asset_id)))
	for cell in op.get("cells", []):
		_add_tile(layer, asset_id, category, _array_to_vector2i(cell, Vector2i.ZERO))


func _apply_stamp_prop(op: Dictionary) -> void:
	var layer := str(op.get("layer", "PropsStatic"))
	var tile := _array_to_vector2i(op.get("tile", [0, 0]), Vector2i.ZERO)
	var category := str(op.get("category", "props"))
	var asset_id := str(op.get("asset_id", ""))
	if _is_hanging_brazier_prop(asset_id):
		_add_animated_hanging_brazier_prop(layer, asset_id, tile, category)
		return
	_add_prop(layer, asset_id, tile, category)
	if bool(op.get("blocks_movement", false)) and layer != "PropsBlocking":
		var size := _array_to_vector2i(op.get("footprint", [1, 1]), Vector2i.ONE)
		_add_blocker(Rect2i(tile, size), str(op.get("blocker_name", "%sBlocker" % str(op.get("asset_id", "")))))


func _apply_stamp_prefab(op: Dictionary) -> void:
	var layer := str(op.get("layer", "WallsHigh"))
	var asset_id := str(op.get("asset_id", ""))
	var category := str(op.get("category", _category_for_layer_asset(layer, asset_id)))
	var tile := _array_to_vector2i(op.get("tile", [0, 0]), Vector2i.ZERO)
	_add_sprite(layer, asset_id, category, tile, Vector2.ZERO)


func _apply_stamp_module(op: Dictionary) -> void:
	var module_id := str(op.get("module_id", ""))
	var origin := _array_to_vector2i(op.get("origin", [0, 0]), Vector2i.ZERO)
	if module_id == "return_mooring_3x3_01":
		_stats["modules"] = int(_stats["modules"]) + 1
		_build_return_mooring(origin)
	else:
		push_warning("[SunderedKeepDataTilemap] Unknown module: %s" % module_id)


func _apply_stamp_wall(op: Dictionary) -> void:
	var rect := _array_to_rect2i(op.get("rect", [0, 0, 1, 1]))
	var asset_id := str(op.get("asset_id", ""))
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_add_wall_tile(Vector2i(x, y), asset_id)


func _apply_blocker(op: Dictionary) -> void:
	var rect := _array_to_rect2i(op.get("rect", [0, 0, 1, 1]))
	var name := str(op.get("name", "LevelBlocker"))
	var role := str(op.get("role", ""))
	if role == "main_gate":
		_main_gate_blockers.append(_add_blocker(rect, name))
	elif role == "great_hall_door":
		_great_hall_door_blockers.append(_add_blocker(rect, name))
	else:
		_add_blocker(rect, name)


func _apply_interactable(op: Dictionary) -> void:
	var tile := _array_to_vector2i(op.get("tile", [0, 0]), Vector2i.ZERO)
	var kind := StringName(str(op.get("kind", "")))
	var node_name := str(op.get("name", "%sInteraction" % str(kind)))
	var prompt := str(op.get("prompt", "INTERACT"))
	var distance := float(op.get("distance", 84.0))
	var interactable := _add_interactable(node_name, kind, prompt, tile, distance)
	match kind:
		&"return_mooring":
			_return_mooring_interaction = interactable
		&"sundered_gate_key":
			_key_pickup_interaction = interactable
		&"main_gate":
			_main_gate_interaction = interactable
		&"great_hall_door":
			_great_hall_door_interaction = interactable
		&"sidearm_locker":
			_sidearm_locker_interaction = interactable


func _apply_marker(marker: Dictionary) -> void:
	var marker_id := str(marker.get("id", ""))
	var tile := _array_to_vector2i(marker.get("tile", [0, 0]), Vector2i.ZERO)
	match marker_id:
		"spawn":
			entrance_tile = tile
		"return_gate":
			return_gate_tile = tile
		"main_gate":
			main_gate_tile = tile
		"great_hall_door":
			great_hall_door_tile = tile
		"sidearm_locker":
			sidearm_locker_tile = tile


func _build_stateful_gates_from_level_data() -> void:
	_build_main_gate_prefab()
	if _main_gate_interaction == null:
		_main_gate_interaction = _add_interactable("MainGateInteraction", &"main_gate", "OPEN MAIN GATE", main_gate_tile + Vector2i(2, 1), 96.0)
	_set_main_gate_open(false)
	_build_great_hall_door(great_hall_door_tile)


func _build_main_gate_prefab() -> void:
	var prefab_tile := _main_gate_prefab_tile()
	_main_gate_closed_sprite = _add_sprite("WallsHigh", "gateway_prefab_structure", "entrance_prefabs", prefab_tile, Vector2.ZERO)
	_main_gate_open_sprite = _add_main_gate_open_animation(prefab_tile)


func _main_gate_prefab_tile() -> Vector2i:
	return main_gate_tile + Vector2i(2, 8)


func _build_elevation_from_level_data(data: Dictionary) -> void:
	_ensure_elevation_map()
	_elevation_map.call("clear")
	var regions: Array = data.get("elevation_regions", [])
	for region_value in regions:
		if not (region_value is Dictionary):
			continue
		var region := region_value as Dictionary
		var rect := _array_to_rect2i(region.get("rect", [0, 0, 0, 0]))
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		var height := int(region.get("height", 0))
		var traversal_type := str(region.get("traversal_type", region.get("traversal", ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE)))
		var direction := str(region.get("direction", ELEVATION_MAP_SCRIPT.DIRECTION_NONE))
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_elevation_map.call("set_cell", Vector2i(x, y), height, traversal_type, direction)


func _build_underpass_and_shore_regions(data: Dictionary) -> void:
	_underpass_regions = _parse_authored_rect_regions(data.get("underpass_regions", []))
	_shore_walk_regions = _parse_authored_rect_regions(data.get("shore_walk_regions", []))
	for region in _underpass_regions:
		_add_underpass_shadow(region)


func _build_interior_occlusion_regions(data: Dictionary) -> void:
	_interior_occlusion_regions.clear()
	_roof_occluders.clear()
	var layer := _layers.get("RoofOccluders", null) as Node2D
	if layer == null:
		return
	for region_value in data.get("interior_occlusion_regions", []):
		if not (region_value is Dictionary):
			continue
		var source := region_value as Dictionary
		var interior_rect := _array_to_rect2i(source.get("interior_rect", [0, 0, 0, 0]))
		var roof_rect := _array_to_rect2i(source.get("roof_rect", [0, 0, 0, 0]))
		if interior_rect.size.x <= 0 or interior_rect.size.y <= 0 or roof_rect.size.x <= 0 or roof_rect.size.y <= 0:
			continue
		var region := {
			"id": str(source.get("id", "interior_%d" % _interior_occlusion_regions.size())),
			"interior_rect": interior_rect,
			"roof_rect": roof_rect,
			"exterior_alpha": float(source.get("exterior_alpha", 0.88)),
			"cutaway_alpha": float(source.get("cutaway_alpha", 0.08)),
		}
		_interior_occlusion_regions.append(region)
		var occluder := _add_rect_overlay(
			layer,
			"RoofOccluder_%s" % str(region["id"]),
			roof_rect,
			Color(0.025, 0.027, 0.032, float(region["exterior_alpha"]))
		)
		occluder.set_meta("interior_region_id", String(region["id"]))
		_roof_occluders[String(region["id"])] = occluder


func _parse_authored_rect_regions(values: Array) -> Array[Dictionary]:
	var regions: Array[Dictionary] = []
	for region_value in values:
		if not (region_value is Dictionary):
			continue
		var source := region_value as Dictionary
		var rect := _array_to_rect2i(source.get("rect", [0, 0, 0, 0]))
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		regions.append({
			"id": str(source.get("id", "region_%d" % regions.size())),
			"rect": rect,
			"shadow_alpha": float(source.get("shadow_alpha", 0.36)),
		})
	return regions


func _add_underpass_shadow(region: Dictionary) -> void:
	var layer := _layers.get("FloorDetail", null) as Node2D
	if layer == null:
		return
	_add_rect_overlay(
		layer,
		"UnderpassShadow_%s" % str(region.get("id", "")),
		region["rect"] as Rect2i,
		Color(0.0, 0.0, 0.0, float(region.get("shadow_alpha", 0.36)))
	)


func _add_rect_overlay(layer: Node2D, overlay_name: String, rect: Rect2i, color: Color) -> Polygon2D:
	var overlay := Polygon2D.new()
	overlay.name = overlay_name
	overlay.position = _tile_top_left(rect.position)
	overlay.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(float(rect.size.x) * TILE_SIZE, 0.0),
		Vector2(float(rect.size.x) * TILE_SIZE, float(rect.size.y) * TILE_SIZE),
		Vector2(0.0, float(rect.size.y) * TILE_SIZE),
	])
	overlay.color = color
	layer.add_child(overlay)
	return overlay


func _ensure_elevation_map() -> void:
	if _elevation_map != null and is_instance_valid(_elevation_map):
		return
	_elevation_map = ELEVATION_MAP_SCRIPT.new()
	_elevation_map.name = "ElevationMap"
	add_child(_elevation_map)


func _get_elevation_cell_count() -> int:
	if _elevation_map == null:
		return 0
	var cells: Dictionary = _elevation_map.call("get_cells")
	return cells.size()


func _update_actor_elevation() -> void:
	if _elevation_map == null or get_tree() == null:
		return
	var actor := _find_operator_actor()
	if actor == null:
		return
	var actor_tile := _global_to_tile((actor as Node2D).global_position)
	if actor_tile == _last_actor_elevation_tile:
		return
	_last_actor_elevation_tile = actor_tile
	_update_roof_occlusion_for_tile(actor_tile)
	if actor.has_method("set_fake_elevation"):
		actor.call("set_fake_elevation", float(get_elevation_at_tile(actor_tile)) * ELEVATION_STEP_PX)


func _find_operator_actor() -> Node2D:
	var actor := get_node_or_null("/root/GameRoot/World/Operator")
	if actor is Node2D:
		return actor as Node2D
	if get_tree() == null:
		return null
	for player_node in get_tree().get_nodes_in_group("player"):
		if player_node is Node2D:
			return player_node as Node2D
	return null


func _update_roof_occlusion_for_tile(actor_tile: Vector2i) -> void:
	var active_region_ids: Array[String] = []
	for region in _interior_occlusion_regions:
		var interior_rect := region["interior_rect"] as Rect2i
		if interior_rect.has_point(actor_tile):
			active_region_ids.append(String(region["id"]))
	if active_region_ids == _active_interior_region_ids:
		return
	_active_interior_region_ids = active_region_ids
	_active_interior_region_id = active_region_ids[0] if not active_region_ids.is_empty() else ""
	for region in _interior_occlusion_regions:
		var region_id := String(region["id"])
		var occluder := _roof_occluders.get(region_id, null) as Polygon2D
		if occluder == null:
			continue
		var alpha := float(region["cutaway_alpha"]) if active_region_ids.has(region_id) else float(region["exterior_alpha"])
		var color := occluder.color
		color.a = alpha
		occluder.color = color


func _get_roof_occluder_alphas() -> Dictionary:
	var result := {}
	for region_id in _roof_occluders:
		var occluder := _roof_occluders[region_id] as Polygon2D
		if occluder != null:
			result[String(region_id)] = occluder.color.a
	return result


func _tile_in_authored_regions(tile: Vector2i, regions: Array[Dictionary]) -> bool:
	for region in regions:
		var rect := region["rect"] as Rect2i
		if rect.has_point(tile):
			return true
	return false


func _weighted_asset_for_tile(assets: Array, x: int, y: int) -> String:
	var total_weight := 0
	for entry in assets:
		total_weight += max(1, int((entry as Dictionary).get("weight", 1)))
	var roll: int = abs((x * 928371 + y * 364479 + total_weight * 97) % max(1, total_weight))
	var cursor := 0
	for entry in assets:
		var asset_entry := entry as Dictionary
		cursor += max(1, int(asset_entry.get("weight", 1)))
		if roll < cursor:
			return str(asset_entry.get("asset_id", ""))
	return str((assets[0] as Dictionary).get("asset_id", ""))


func _category_for_layer_asset(layer: String, asset_id: String) -> String:
	if asset_id.begins_with("return_mooring_floor"):
		return "return_mooring_floor"
	if asset_id.begins_with("return_mooring_"):
		return "return_mooring_overlay"
	if asset_id.begins_with("banner_tall_wall_overlay") or asset_id.begins_with("shield_crest_wall_overlay"):
		return "entrance_overlays"
	if asset_id.begins_with("gateway_prefab"):
		return "entrance_prefabs"
	if asset_id.begins_with(PLACEHOLDER_KEEP_WALL_PREFIX):
		return "placeholder_keep_walls"
	if asset_id.begins_with("castle_wall_support_constructed_cliffside") or asset_id.begins_with("flaming_brazier_hanging_pillar"):
		return "entrance_cliffs"
	if asset_id.begins_with("entrance_causeway_surface"):
		return "causeway_surfaces"
	if asset_id.begins_with("cobblestone_") or asset_id.begins_with("causeway_floor_cobblestone"):
		return "causeway_floors"
	if asset_id.begins_with("entrance_causeway"):
		return "entrance"
	if asset_id == "ocean_void_01" or asset_id.contains("_floor") or asset_id.contains("_flagstone") or asset_id.contains("_threshold") or asset_id.contains("_carpet"):
		return "floors"
	if asset_id.begins_with("ocean_") or asset_id.begins_with("cliff_"):
		return "cliffs"
	if layer.begins_with("Wall"):
		return "walls"
	return "floors"


func _array_to_vector2i(value, fallback: Vector2i) -> Vector2i:
	if not (value is Array) or (value as Array).size() < 2:
		return fallback
	return Vector2i(int(value[0]), int(value[1]))


func _array_to_rect2i(value) -> Rect2i:
	if not (value is Array) or (value as Array).size() < 4:
		return Rect2i()
	return Rect2i(Vector2i(int(value[0]), int(value[1])), Vector2i(int(value[2]), int(value[3])))


func _array_to_color(value, fallback: Color) -> Color:
	if not (value is Array):
		return fallback
	var components := value as Array
	if components.size() < 3:
		return fallback
	var alpha := float(components[3]) if components.size() >= 4 else fallback.a
	return Color(float(components[0]), float(components[1]), float(components[2]), alpha)


func _build_level_underlay(config: Dictionary = {}) -> void:
	var layer := _layers.get("Underlay", null) as Node2D
	if layer == null:
		layer = Node2D.new()
		layer.name = "Underlay"
		layer.z_as_relative = false
		layer.z_index = -120
		add_child(layer)
		_layers["Underlay"] = layer
	for child in layer.get_children():
		child.queue_free()

	_level_underlay_sprite = null
	_level_underlay_rect_tiles = Rect2i()
	_level_underlay_texture_path = ""

	var texture_path := str(config.get("texture_path", level_underlay_path))
	if texture_path.is_empty():
		return

	var rect_tiles := _array_to_rect2i(config.get("rect_tiles", [0, 0, map_size_tiles.x, map_size_tiles.y]))
	if rect_tiles.size.x <= 0 or rect_tiles.size.y <= 0:
		return

	layer.z_index = int(config.get("z_index", layer.z_index))
	var texture := _load_texture(texture_path)
	if texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.name = "LevelShapeUnderlay"
	sprite.centered = false
	sprite.texture = texture
	sprite.position = _tile_top_left(rect_tiles.position)
	sprite.scale = Vector2(
		(float(rect_tiles.size.x) * TILE_SIZE) / max(1.0, float(texture.get_width())),
		(float(rect_tiles.size.y) * TILE_SIZE) / max(1.0, float(texture.get_height()))
	)
	sprite.modulate = _array_to_color(config.get("modulate", [1.0, 1.0, 1.0, 1.0]), Color.WHITE)
	layer.add_child(sprite)

	_level_underlay_sprite = sprite
	_level_underlay_rect_tiles = rect_tiles
	_level_underlay_texture_path = texture_path

	if bool(config.get("expand_camera_bounds", false)):
		var underlay_rect := Rect2(_tile_top_left(rect_tiles.position), Vector2(rect_tiles.size) * TILE_SIZE)
		_camera_bounds = _camera_bounds.merge(underlay_rect)


func _build_ocean_backdrop() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "StormOceanBackdrop"
	backdrop.color = Color(0.014, 0.035, 0.064, 1.0)
	backdrop.size = Vector2(float(map_size_tiles.x) * TILE_SIZE, float(map_size_tiles.y) * TILE_SIZE)
	backdrop.z_as_relative = false
	backdrop.z_index = -130
	add_child(backdrop)

	for y in range(map_size_tiles.y):
		for x in range(map_size_tiles.x):
			if ((x * 17 + y * 31) % 41) == 0:
				_add_tile("TerrainBase", "ocean_dark_water_01", "cliffs", Vector2i(x, y))


func _build_cliff_island_foundation() -> void:
	_fill_polygon_spans({
		8: [Vector2i(25, 49)],
		9: [Vector2i(23, 55)],
		10: [Vector2i(21, 58)],
		11: [Vector2i(20, 59)],
		12: [Vector2i(19, 60)],
		13: [Vector2i(18, 61)],
		14: [Vector2i(18, 61)],
		15: [Vector2i(17, 61)],
		16: [Vector2i(17, 62)],
		17: [Vector2i(17, 62)],
		18: [Vector2i(17, 62)],
		19: [Vector2i(17, 61)],
		20: [Vector2i(16, 61)],
		21: [Vector2i(16, 61)],
		22: [Vector2i(16, 60)],
		23: [Vector2i(16, 59)],
		24: [Vector2i(17, 59)],
		25: [Vector2i(17, 59)],
		26: [Vector2i(18, 58)],
		27: [Vector2i(18, 59)],
		28: [Vector2i(18, 60)],
		29: [Vector2i(17, 61)],
		30: [Vector2i(16, 61)],
		31: [Vector2i(15, 60)],
		32: [Vector2i(15, 59)],
		33: [Vector2i(16, 59)],
		34: [Vector2i(16, 58)],
		35: [Vector2i(17, 58)],
		36: [Vector2i(17, 57)],
		37: [Vector2i(18, 56)],
		38: [Vector2i(19, 55)],
		39: [Vector2i(20, 55)],
		40: [Vector2i(22, 54)],
		41: [Vector2i(24, 53)],
		42: [Vector2i(27, 51)],
		43: [Vector2i(30, 50)],
		44: [Vector2i(34, 48)],
		45: [Vector2i(30, 50)],
		46: [Vector2i(27, 55)],
		47: [Vector2i(27, 55)],
		48: [Vector2i(28, 54)],
		49: [Vector2i(32, 49)],
		50: [Vector2i(36, 45)],
		51: [Vector2i(38, 43)],
		52: [Vector2i(39, 42)],
	}, "cliff_rock_floor_01")
	_fill_polygon_spans({
		13: [Vector2i(24, 54)],
		14: [Vector2i(22, 56)],
		15: [Vector2i(21, 57)],
		16: [Vector2i(20, 58)],
		17: [Vector2i(20, 58)],
		18: [Vector2i(20, 57)],
		19: [Vector2i(21, 56)],
		20: [Vector2i(21, 55)],
		21: [Vector2i(22, 54)],
		22: [Vector2i(23, 53)],
		28: [Vector2i(20, 55)],
		29: [Vector2i(19, 57)],
		30: [Vector2i(18, 58)],
		31: [Vector2i(17, 58)],
		32: [Vector2i(17, 57)],
		33: [Vector2i(18, 56)],
		34: [Vector2i(18, 55)],
		35: [Vector2i(19, 54)],
		36: [Vector2i(20, 53)],
		37: [Vector2i(21, 52)],
		38: [Vector2i(23, 51)],
		39: [Vector2i(25, 50)],
		40: [Vector2i(28, 49)],
	}, "cliff_rock_floor_cracked_01")

	_fill_polygon_spans({
		44: [Vector2i(36, 45)],
		45: [Vector2i(32, 49)],
		46: [Vector2i(27, 54)],
		47: [Vector2i(27, 55)],
		48: [Vector2i(28, 54)],
		49: [Vector2i(32, 49)],
		50: [Vector2i(36, 45)],
		51: [Vector2i(38, 43)],
		52: [Vector2i(39, 42)],
	}, "cliff_rock_floor_01")

	_fill_polygon_spans({
		28: [Vector2i(22, 55)],
		29: [Vector2i(20, 57)],
		30: [Vector2i(18, 59)],
		31: [Vector2i(17, 58)],
		32: [Vector2i(17, 57)],
		33: [Vector2i(18, 57)],
		34: [Vector2i(18, 56)],
		35: [Vector2i(19, 55)],
		36: [Vector2i(20, 54)],
		37: [Vector2i(20, 53)],
		38: [Vector2i(22, 52)],
		39: [Vector2i(24, 51)],
		40: [Vector2i(26, 50)],
		41: [Vector2i(29, 48)],
		42: [Vector2i(33, 46)],
		43: [Vector2i(36, 43)],
	}, "main_courtyard_flagstone_01")

	# Collapsed sea cuts and irregular island corners.
	_add_ocean_hole(Rect2i(Vector2i(12, 8), Vector2i(10, 9)), "NorthwestSeaCut")
	_add_ocean_hole(Rect2i(Vector2i(55, 8), Vector2i(8, 10)), "NortheastSeaCut")
	_add_ocean_hole(Rect2i(Vector2i(11, 39), Vector2i(9, 8)), "SouthwestSeaCut")
	_add_ocean_hole(Rect2i(Vector2i(56, 38), Vector2i(7, 9)), "SoutheastSeaCut")
	_add_ocean_hole(Rect2i(Vector2i(49, 18), Vector2i(6, 6)), "RampartSeaCut")
	_add_ocean_hole(Rect2i(Vector2i(13, 20), Vector2i(5, 7)), "WestGallerySeaCut")
	_add_ocean_hole(Rect2i(Vector2i(57, 27), Vector2i(5, 8)), "EastCourtyardSeaCut")

	_add_cliff_edges()
	_add_ocean_boundaries()


func _build_storm_causeway() -> void:
	var causeway_tiles := {}
	for y in range(45, 54):
		var half_width := 2
		if y == 45:
			half_width = 3
		elif y >= 52:
			half_width = 1
		for x in range(40 - half_width, 40 + half_width + 1):
			var tile := Vector2i(x, y)
			causeway_tiles[tile] = true
			var floor_id := "entrance_causeway_floor_cracked_01" if ((x * 13 + y * 7) % 4) == 0 else "entrance_causeway_floor_01"
			_add_tile("FloorDetail", floor_id, "entrance", tile)
	_add_causeway_edge_line(causeway_tiles)
	for tile in [Vector2i(39, 54), Vector2i(40, 54), Vector2i(41, 54), Vector2i(38, 55), Vector2i(39, 55), Vector2i(40, 55), Vector2i(41, 55), Vector2i(42, 55)]:
		_add_tile("FloorDetail", "entrance_causeway_broken_gap_01", "entrance", tile)
	_add_blocker(Rect2i(Vector2i(38, 54), Vector2i(5, 2)), "SubmergedCausewayBlocker")
	_add_prop("PropsStatic", "prop_sea_spray_rock_01", Vector2i(36, 50))
	_add_prop("PropsStatic", "prop_broken_spire_chunk_01", Vector2i(44, 49))


func _build_return_mooring(origin_tile: Vector2i) -> void:
	_return_mooring_created = true
	_fill_rect(Rect2i(origin_tile, Vector2i(5, 5)), "main_gate_threshold_stone_01")
	_add_wall_run(Rect2i(origin_tile + Vector2i(0, 0), Vector2i(5, 1)), "gothic_castle_wall_straight_s")
	_add_wall_run(Rect2i(origin_tile + Vector2i(0, 0), Vector2i(1, 5)), "rampart_parapet_e")
	_add_wall_run(Rect2i(origin_tile + Vector2i(4, 0), Vector2i(1, 3)), "rampart_parapet_w")

	var layout := [
		["return_mooring_floor_corner_nw", "return_mooring_floor_ring_n", "return_mooring_floor_corner_ne"],
		["return_mooring_floor_ring_w", "return_mooring_floor_center_01", "return_mooring_floor_ring_e"],
		["return_mooring_floor_corner_sw", "return_mooring_floor_ring_s", "return_mooring_floor_corner_se"],
	]
	for row in range(3):
		for col in range(3):
			_add_tile("FloorDetail", str(layout[row][col]), "return_mooring_floor", origin_tile + Vector2i(col + 1, row + 1))

	var center_tile := origin_tile + Vector2i(2, 2)
	_add_tile("Overlays", "return_mooring_glow_overlay_01", "return_mooring_overlay", center_tile)
	_return_mooring_active_overlay = _add_tile("Effects", "return_mooring_active_overlay_01", "return_mooring_overlay", center_tile)
	_add_tile("WorldUI", "return_mooring_prompt_marker_01", "return_mooring_overlay", center_tile)
	_add_prop("PropsBlocking", "prop_return_beacon_01", origin_tile + Vector2i(2, 1))
	_add_prop("PropsBlocking", "prop_return_console_ruined_01", origin_tile + Vector2i(4, 3))
	_add_blocker(Rect2i(origin_tile + Vector2i(2, 1), Vector2i.ONE), "ReturnMooringBeaconBlocker")
	_add_blocker(Rect2i(origin_tile + Vector2i(4, 3), Vector2i(2, 1)), "ReturnMooringConsoleBlocker")
	_add_return_mooring_interaction(center_tile)
	_set_return_mooring_active(true)


func _add_return_mooring_interaction(center_tile: Vector2i) -> void:
	_return_mooring_interaction = _add_interactable(
		"ReturnMooringInteraction",
		&"return_mooring",
		"RETURN TO MAIN MAP",
		center_tile,
		72.0
	)


func _set_return_mooring_active(active: bool) -> void:
	if _return_mooring_active_overlay != null:
		_return_mooring_active_overlay.visible = active
	_refresh_hud_state()


func _build_main_gate_lock() -> void:
	_fill_rect(Rect2i(Vector2i(30, 39), Vector2i(20, 6)), "main_gate_threshold_stone_01")
	_add_wall_run(Rect2i(Vector2i(31, 40), Vector2i(7, 1)), "gothic_castle_wall_straight_s")
	_add_wall_run(Rect2i(Vector2i(42, 40), Vector2i(7, 1)), "gothic_castle_wall_straight_s")
	_add_wall_run(Rect2i(Vector2i(29, 42), Vector2i(1, 5)), "rampart_parapet_e")
	_add_wall_run(Rect2i(Vector2i(50, 42), Vector2i(1, 5)), "rampart_parapet_w")
	_add_wall_run(Rect2i(Vector2i(30, 43), Vector2i(8, 1)), "gothic_castle_wall_straight_s")
	_add_wall_run(Rect2i(Vector2i(42, 43), Vector2i(8, 1)), "gothic_castle_wall_straight_s")
	_add_prop("PropsStatic", "prop_torch_wall_gothic_01", Vector2i(34, 41))
	_add_prop("PropsStatic", "prop_torch_wall_gothic_01", Vector2i(45, 41))
	_add_prop("PropsStatic", "prop_portcullis_chain_01", Vector2i(39, 41))
	_build_main_gate_prefab()
	_main_gate_interaction = _add_interactable("MainGateInteraction", &"main_gate", "OPEN MAIN GATE", main_gate_tile + Vector2i(2, 1), 96.0)
	_set_main_gate_open(false)


func _build_sundered_gate_key_pickup(tile: Vector2i) -> void:
	_fill_rect(Rect2i(tile + Vector2i(-2, -1), Vector2i(5, 3)), "main_gate_threshold_stone_01")
	_add_wall_run(Rect2i(tile + Vector2i(-2, -2), Vector2i(5, 1)), "gothic_castle_wall_straight_s")
	_add_prop("PropsStatic", "prop_gate_winch_01", tile)
	_add_prop("PropsStatic", "prop_crate_stack_wet_01", tile + Vector2i(2, 1))
	_key_pickup_interaction = _add_interactable(
		"SunderedGateKeyPickup",
		&"sundered_gate_key",
		"TAKE %s" % SUNDERED_GATE_KEY_NAME.to_upper(),
		tile,
		76.0
	)


func _build_sidearm_locker() -> void:
	if _sidearm_locker_interaction != null and is_instance_valid(_sidearm_locker_interaction):
		return
	_add_prop("PropsStatic", "prop_crate_stack_wet_01", sidearm_locker_tile + Vector2i(0, -1))
	_sidearm_locker_interaction = _add_interactable(
		"SidearmLockerInteraction",
		&"sidearm_locker",
		"OPEN FIELD-RETENTION LOCKER",
		sidearm_locker_tile,
		76.0
	)


func _build_irregular_courtyard() -> void:
	_fill_polygon_spans({
		27: [Vector2i(25, 53)],
		28: [Vector2i(23, 55)],
		29: [Vector2i(22, 56)],
		30: [Vector2i(21, 57)],
		31: [Vector2i(21, 57)],
		32: [Vector2i(20, 56)],
		33: [Vector2i(20, 55)],
		34: [Vector2i(21, 56)],
		35: [Vector2i(22, 56)],
		36: [Vector2i(23, 55)],
		37: [Vector2i(24, 54)],
		38: [Vector2i(27, 52)],
		39: [Vector2i(31, 49)],
	}, "main_courtyard_flagstone_01")
	_scatter_floor_variants(Rect2i(Vector2i(21, 27), Vector2i(36, 13)), {
		"main_courtyard_flagstone_cracked_01": 6,
		"main_courtyard_flagstone_wet_01": 10,
		"main_courtyard_flagstone_mossy_01": 13,
	})
	_add_wall_run(Rect2i(Vector2i(22, 26), Vector2i(11, 1)), "gothic_castle_wall_damaged_s")
	_add_wall_run(Rect2i(Vector2i(45, 26), Vector2i(11, 1)), "gothic_castle_wall_breach_s")
	_add_wall_run(Rect2i(Vector2i(20, 30), Vector2i(1, 7)), "rampart_parapet_e")
	_add_wall_run(Rect2i(Vector2i(57, 29), Vector2i(1, 3)), "rampart_parapet_w")
	_add_wall_run(Rect2i(Vector2i(57, 35), Vector2i(1, 2)), "rampart_parapet_w")
	_add_wall_run(Rect2i(Vector2i(30, 39), Vector2i(8, 1)), "gothic_castle_wall_breach_n")
	_add_wall_run(Rect2i(Vector2i(43, 39), Vector2i(8, 1)), "gothic_castle_wall_damaged_n")

	_add_prop("PropsBlocking", "prop_courtyard_fountain_broken_01", Vector2i(38, 33))
	_add_prop("PropsBlocking", "prop_gothic_statue_broken_01", Vector2i(25, 30))
	_add_prop("PropsBlocking", "prop_gothic_statue_intact_01", Vector2i(52, 31))
	_add_prop("PropsBlocking", "prop_broken_cart_01", Vector2i(29, 37))
	_add_prop("PropsBlocking", "prop_crate_stack_wet_01", Vector2i(50, 37))
	_add_prop("PropsBlocking", "prop_barrel_wet_01", Vector2i(53, 36))
	_add_prop("PropsBlocking", "prop_fallen_masonry_01", Vector2i(22, 27))
	_add_prop("PropsBlocking", "prop_low_garden_wall_01", Vector2i(44, 30))
	_add_prop("PropsStatic", "prop_torch_wall_gothic_01", Vector2i(33, 27))
	_add_prop("PropsStatic", "prop_torch_wall_gothic_01", Vector2i(47, 27))


func _build_great_hall() -> void:
	_fill_polygon_spans({
		10: [Vector2i(28, 54)],
		11: [Vector2i(27, 55)],
		12: [Vector2i(27, 56)],
		13: [Vector2i(27, 56)],
		14: [Vector2i(27, 55)],
		15: [Vector2i(27, 55)],
		16: [Vector2i(27, 54)],
		17: [Vector2i(28, 54)],
		18: [Vector2i(28, 53)],
		19: [Vector2i(29, 53)],
		20: [Vector2i(30, 52)],
		21: [Vector2i(31, 50)],
		22: [Vector2i(32, 49)],
		23: [Vector2i(33, 48)],
	}, "great_hall_marble_floor_01")
	_scatter_floor_variants(Rect2i(Vector2i(28, 10), Vector2i(27, 14)), {
		"great_hall_marble_floor_cracked_01": 7,
	})
	for y in range(11, 23):
		_add_tile("FloorDetail", "great_hall_carpet_runner_vertical_01", "floors", Vector2i(39, y))
		_add_tile("FloorDetail", "great_hall_carpet_runner_vertical_01", "floors", Vector2i(40, y))
	_add_room_walls(Rect2i(Vector2i(27, 10), Vector2i(30, 16)), {"south_open_min": 39, "south_open_max": 40, "east_open_min": 17, "east_open_max": 20}, "great_hall")

	# Collapsed east wall exposes ocean and creates a side choke.
	_add_ocean_hole(Rect2i(Vector2i(52, 15), Vector2i(5, 5)), "GreatHallCollapsedSeaCut")
	_add_wall_run(Rect2i(Vector2i(51, 14), Vector2i(1, 6)), "great_hall_wall_broken_exterior_w")
	for y in range(15, 20):
		_add_tile("TerrainEdges", "ocean_foam_edge_w", "cliffs", Vector2i(52, y))

	_build_great_hall_door(Vector2i(39, 25))
	_add_prop("PropsBlocking", "prop_banquet_table_long_01", Vector2i(31, 14))
	_add_prop("PropsBlocking", "prop_banquet_table_long_01", Vector2i(46, 14))
	_add_prop("PropsBlocking", "prop_banquet_table_broken_01", Vector2i(33, 19))
	_add_prop("PropsBlocking", "prop_great_hall_column_01", Vector2i(29, 12))
	_add_prop("PropsBlocking", "prop_great_hall_column_01", Vector2i(50, 12))
	_add_prop("PropsBlocking", "prop_great_hall_column_01", Vector2i(29, 21))
	_add_prop("PropsBlocking", "prop_great_hall_column_01", Vector2i(48, 21))
	_add_prop("PropsBlocking", "prop_fallen_chandelier_01", Vector2i(39, 18))
	_add_prop("PropsBlocking", "prop_throne_ruined_01", Vector2i(39, 10))
	_add_prop("PropsStatic", "prop_brazier_iron_01", Vector2i(35, 11))
	_add_prop("PropsStatic", "prop_brazier_iron_01", Vector2i(44, 11))
	_add_prop("PropsStatic", "prop_banner_torn_large_01", Vector2i(32, 10))
	_add_prop("PropsStatic", "prop_banner_torn_large_01", Vector2i(48, 10))


func _build_east_rampart() -> void:
	_fill_rect(Rect2i(Vector2i(56, 20), Vector2i(6, 24)), "rampart_walkway_floor_01")
	_scatter_floor_variants(Rect2i(Vector2i(56, 20), Vector2i(6, 24)), {"rampart_walkway_broken_01": 5})
	_add_wall_run(Rect2i(Vector2i(56, 19), Vector2i(6, 1)), "rampart_crenellation_s")
	_add_wall_run(Rect2i(Vector2i(61, 20), Vector2i(1, 9)), "rampart_parapet_w")
	_add_wall_run(Rect2i(Vector2i(61, 32), Vector2i(1, 7)), "rampart_broken_gap_w")
	_add_wall_run(Rect2i(Vector2i(56, 43), Vector2i(6, 1)), "rampart_broken_gap_n")
	_add_prop("PropsBlocking", "prop_gargoyle_perch_01", Vector2i(60, 21))
	_add_prop("PropsStatic", "prop_lightning_rod_01", Vector2i(59, 25))
	_add_prop("PropsStatic", "prop_rope_bridge_anchor_01", Vector2i(56, 34))
	_add_prop("PropsStatic", "prop_sea_spray_rock_01", Vector2i(62, 37))
	_add_prop("PropsBlocking", "prop_broken_spire_chunk_01", Vector2i(58, 39))
	for y in range(20, 44):
		_add_tile("TerrainEdges", "ocean_foam_edge_e", "cliffs", Vector2i(62, y))


func _build_west_service_path() -> void:
	_fill_polygon_spans({
		29: [Vector2i(16, 21)],
		30: [Vector2i(15, 22)],
		31: [Vector2i(15, 22)],
		32: [Vector2i(15, 21)],
		33: [Vector2i(16, 21)],
		34: [Vector2i(16, 22)],
		35: [Vector2i(17, 23)],
		36: [Vector2i(17, 24)],
		37: [Vector2i(18, 25)],
		38: [Vector2i(19, 27)],
		39: [Vector2i(20, 29)],
		40: [Vector2i(21, 31)],
	}, "cliff_rock_floor_cracked_01")
	_add_wall_run(Rect2i(Vector2i(14, 30), Vector2i(1, 7)), "rampart_parapet_e")
	_add_prop("PropsBlocking", "prop_sarcophagus_01", Vector2i(18, 34))
	_add_prop("PropsStatic", "prop_bookshelf_tall_01", Vector2i(20, 31))
	_add_prop("PropsBlocking", "prop_fallen_masonry_01", Vector2i(21, 38))
	for y in range(29, 41):
		_add_tile("TerrainEdges", "cliff_edge_w", "cliffs", Vector2i(15, y))


func _build_traversal_stubs() -> void:
	_add_sprite("Traversal", "stone_stairs_up_n", "stairs", upper_stair_tile, Vector2.ZERO)
	_add_sprite("Traversal", "stone_stairs_down_s", "stairs", lower_stair_tile, Vector2.ZERO)
	_add_sprite("Traversal", "floor_hatch_closed_01", "stairs", hatch_tile, Vector2.ZERO)


func _build_great_hall_door(tile: Vector2i) -> void:
	great_hall_door_tile = tile
	_great_hall_door_closed_sprite = _add_great_hall_door_animation(tile)
	_great_hall_door_open_sprite = null
	_great_hall_door_interaction = _add_interactable("GreatHallDoorInteraction", &"great_hall_door", "OPEN GREAT HALL DOOR", tile + Vector2i(1, 1), 88.0)
	_set_great_hall_door_open(false)


func _add_return_gate() -> void:
	var entry_spawn := find_child("EntrySpawn", true, false) as Marker2D
	if entry_spawn == null:
		entry_spawn = Marker2D.new()
		entry_spawn.name = "EntrySpawn"
		entry_spawn.position = _tile_center(entrance_tile)
		add_child(entry_spawn)
	_route_backtrack_exit = get_node_or_null("Exits/Exit_Backtrack") as LevelExit2D
	_route_exfil_exit = get_node_or_null("Exits/Exit_Exfil") as LevelExit2D
	if _route_backtrack_exit == null:
		push_error("[SunderedKeep] Missing authored Exit_Backtrack")
	else:
		_route_backtrack_exit.position = _tile_center(return_gate_tile)
	if _route_exfil_exit == null:
		push_error("[SunderedKeep] Missing authored Exit_Exfil")
	else:
		_route_exfil_exit.position = _tile_center(return_mooring_origin_tile + Vector2i(2, 2))
	_return_gate = _route_backtrack_exit


func _add_cliff_edges() -> void:
	for x in range(18, 56):
		_add_tile("TerrainEdges", "cliff_edge_n", "cliffs", Vector2i(x, 8))
	for x in range(19, 58):
		_add_tile("TerrainEdges", "cliff_edge_s", "cliffs", Vector2i(x, 45))
	for y in range(13, 42):
		_add_tile("TerrainEdges", "cliff_edge_w", "cliffs", Vector2i(12, y))
		_add_tile("TerrainEdges", "cliff_edge_e", "cliffs", Vector2i(62, y))


func _add_ocean_boundaries() -> void:
	_add_blocker(Rect2i(Vector2i(0, 0), Vector2i(80, 6)), "NorthOceanBoundary")
	_add_blocker(Rect2i(Vector2i(0, 54), Vector2i(38, 2)), "SouthOceanBoundaryWest")
	_add_blocker(Rect2i(Vector2i(43, 54), Vector2i(37, 2)), "SouthOceanBoundaryEast")
	_add_blocker(Rect2i(Vector2i(0, 0), Vector2i(9, 56)), "WestOceanBoundary")
	_add_blocker(Rect2i(Vector2i(68, 0), Vector2i(12, 56)), "EastOceanBoundary")


func _fill_polygon_spans(rows: Dictionary, tile_id: String) -> void:
	for y in rows.keys():
		for span in rows[y]:
			for x in range(span.x, span.y + 1):
				_add_tile("TerrainBase", tile_id, "floors", Vector2i(x, int(y)))


func _fill_rect(rect: Rect2i, tile_id: String) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_add_tile("TerrainBase", tile_id, "floors", Vector2i(x, y))


func _add_ocean_hole(rect: Rect2i, blocker_name: String) -> void:
	_fill_rect(rect, "ocean_void_01")
	_add_blocker(rect, blocker_name)


func _add_causeway_edge_line(causeway_tiles: Dictionary) -> void:
	var directions := {
		"ne": Vector2i(1, -1),
		"nw": Vector2i(-1, -1),
		"se": Vector2i(1, 1),
		"sw": Vector2i(-1, 1),
		"n": Vector2i(0, -1),
		"e": Vector2i(1, 0),
		"s": Vector2i(0, 1),
		"w": Vector2i(-1, 0),
	}
	for tile in causeway_tiles.keys():
		var tile_pos := tile as Vector2i
		for suffix in directions.keys():
			var neighbor: Vector2i = tile_pos + directions[suffix]
			if not causeway_tiles.has(neighbor):
				_add_tile("FloorDetail", "entrance_causeway_edge_%s" % suffix, "entrance", tile_pos)


func _scatter_floor_variants(rect: Rect2i, variants: Dictionary) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			for tile_id in variants.keys():
				var divisor := int(variants[tile_id])
				if divisor > 0 and ((x * 31 + y * 17 + tile_id.length()) % divisor) == 0:
					_add_tile("FloorDetail", tile_id, "floors", Vector2i(x, y))
					break


func _add_room_walls(rect: Rect2i, openings: Dictionary, wall_set := "gothic_castle") -> void:
	for x in range(rect.position.x, rect.end.x):
		if not _is_opening(x, "north", openings):
			_add_wall_tile(Vector2i(x, rect.position.y - 1), _wall_asset(wall_set, "straight_s"))
		if not _is_opening(x, "south", openings):
			_add_wall_tile(Vector2i(x, rect.end.y), _wall_asset(wall_set, "straight_n"))
	for y in range(rect.position.y, rect.end.y):
		if not _is_opening(y, "west", openings):
			_add_wall_tile(Vector2i(rect.position.x - 1, y), _wall_asset(wall_set, "straight_e"))
		if not _is_opening(y, "east", openings):
			_add_wall_tile(Vector2i(rect.end.x, y), _wall_asset(wall_set, "straight_w"))


func _wall_asset(wall_set: String, role: String) -> String:
	var assets := {
		"gothic_castle": {
			"straight_n": "gothic_castle_wall_straight_n",
			"straight_e": "rampart_parapet_e",
			"straight_s": "gothic_castle_wall_straight_s",
			"straight_w": "rampart_parapet_w",
		},
		"great_hall": {
			"straight_n": "great_hall_wall_straight_n",
			"straight_e": "rampart_parapet_e",
			"straight_s": "great_hall_wall_straight_test",
			"straight_w": "rampart_parapet_w",
		},
	}
	var wall_assets: Dictionary = assets.get(wall_set, assets["gothic_castle"])
	return str(wall_assets.get(role, ""))


func _is_opening(value: int, side: String, openings: Dictionary) -> bool:
	var min_key := "%s_open_min" % side
	var max_key := "%s_open_max" % side
	if not openings.has(min_key) or not openings.has(max_key):
		return false
	return value >= int(openings[min_key]) and value <= int(openings[max_key])


func _add_wall_run(rect: Rect2i, tile_id: String) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_add_wall_tile(Vector2i(x, y), tile_id)


func _add_wall_tile(tile: Vector2i, tile_id: String) -> void:
	var sprite := _add_sprite("WallsHigh", tile_id, "walls", tile, Vector2(0.0, -32.0))
	if sprite != null:
		_stats["walls"] = int(_stats["walls"]) + 1
		_minimap_wall_cells[tile] = true
		_minimap_floor_cells.erase(tile)
	_add_blocker(Rect2i(tile, Vector2i.ONE), "WallBlocker")


func _add_tile(layer_name: String, tile_id: String, category: String, tile: Vector2i) -> Sprite2D:
	var sprite := _add_sprite(layer_name, tile_id, category, tile, Vector2.ZERO)
	if sprite != null and (category == "floors" or category == "causeway_floors" or category == "return_mooring_floor" or (category == "entrance" and tile_id.contains("_floor"))):
		_stats["floors"] = int(_stats["floors"]) + 1
		if not _minimap_wall_cells.has(tile):
			_minimap_floor_cells[tile] = true
	elif sprite != null and (layer_name == "TerrainEdges" or tile_id.contains("_edge_")):
		_stats["edges"] = int(_stats["edges"]) + 1
	return sprite


func _add_prop(layer_name: String, prop_id: String, tile: Vector2i, category := "props") -> Sprite2D:
	var texture := _load_texture(_asset_path(prop_id, category))
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.name = prop_id
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = _tile_top_left(tile) + Vector2((TILE_SIZE - float(texture.get_width())) * 0.5, TILE_SIZE - float(texture.get_height()))
	(_layers[layer_name] as Node2D).add_child(sprite)
	var depth_height := float(texture.get_height())
	if _is_brazier_prop(prop_id):
		depth_height = max(depth_height, float(CAUSEWAY_BRAZIER_FLICKER_FRAME_SIZE.y))
		_attach_brazier_flicker(sprite, texture.get_size())
	_attach_operator_depth_sort(sprite, depth_height)
	_stats["props"] = int(_stats["props"]) + 1
	if layer_name == "PropsBlocking":
		_add_blocker(Rect2i(tile, Vector2i.ONE), "%sBlocker" % prop_id)
	return sprite


func _is_brazier_prop(prop_id: String) -> bool:
	return prop_id == "causeway_lit_brazier_bowl_01" or prop_id == "brazier_lit_01"


func _is_hanging_brazier_prop(prop_id: String) -> bool:
	return prop_id.begins_with("flaming_brazier_hanging_pillar")


func _add_animated_hanging_brazier_prop(layer_name: String, prop_id: String, tile: Vector2i, category := "entrance_cliffs") -> AnimatedSprite2D:
	var texture_path := _asset_path(prop_id, category)
	var texture := _load_texture(texture_path)
	if texture == null:
		return null
	var frames := _get_hanging_brazier_frames(prop_id, texture)
	if frames == null:
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.name = prop_id
	sprite.sprite_frames = frames
	sprite.animation = "flicker"
	sprite.autoplay = "flicker"
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = _tile_top_left(tile) + Vector2(
		(TILE_SIZE - float(HANGING_BRAZIER_FRAME_SIZE.x)) * 0.5,
		TILE_SIZE - float(HANGING_BRAZIER_FRAME_SIZE.y)
	)
	(_layers[layer_name] as Node2D).add_child(sprite)
	_attach_operator_depth_sort(sprite, float(HANGING_BRAZIER_FRAME_SIZE.y))
	_stats["props"] = int(_stats["props"]) + 1
	sprite.play("flicker")
	return sprite


func _get_hanging_brazier_frames(prop_id: String, texture: Texture2D) -> SpriteFrames:
	if _hanging_brazier_frames.has(prop_id):
		return _hanging_brazier_frames[prop_id] as SpriteFrames
	var frames := SpriteFrames.new()
	frames.add_animation("flicker")
	frames.set_animation_loop("flicker", true)
	frames.set_animation_speed("flicker", HANGING_BRAZIER_FPS)
	var frame_count := mini(HANGING_BRAZIER_FRAMES, int(floor(float(texture.get_width()) / float(HANGING_BRAZIER_FRAME_SIZE.x))))
	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			float(frame_index * HANGING_BRAZIER_FRAME_SIZE.x),
			0.0,
			float(HANGING_BRAZIER_FRAME_SIZE.x),
			float(HANGING_BRAZIER_FRAME_SIZE.y)
		)
		frames.add_frame("flicker", atlas)
	_hanging_brazier_frames[prop_id] = frames
	return frames


func _add_main_gate_open_animation(tile: Vector2i) -> AnimatedSprite2D:
	var frames := _get_main_gate_open_frames()
	if frames == null:
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.name = "GatewayPrefabOpenGate"
	sprite.sprite_frames = frames
	sprite.animation = "open"
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = _tile_top_left(tile) + Vector2(
		(TILE_SIZE - float(GATEHOUSE_PREFAB_OPEN_FRAME_SIZE.x)) * 0.5,
		TILE_SIZE - float(GATEHOUSE_PREFAB_OPEN_FRAME_SIZE.y)
	)
	(_layers["WallsHigh"] as Node2D).add_child(sprite)
	return sprite


func _get_main_gate_open_frames() -> SpriteFrames:
	if _main_gate_open_frames != null:
		return _main_gate_open_frames
	var texture := _load_texture(GATEHOUSE_PREFAB_OPEN_PATH)
	if texture == null:
		return null
	var frames := SpriteFrames.new()
	frames.add_animation("open")
	frames.set_animation_loop("open", false)
	frames.set_animation_speed("open", GATEHOUSE_PREFAB_OPEN_FPS)
	var frame_count := mini(GATEHOUSE_PREFAB_OPEN_FRAMES, int(floor(float(texture.get_width()) / float(GATEHOUSE_PREFAB_OPEN_FRAME_SIZE.x))))
	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			float(frame_index * GATEHOUSE_PREFAB_OPEN_FRAME_SIZE.x),
			0.0,
			float(GATEHOUSE_PREFAB_OPEN_FRAME_SIZE.x),
			float(GATEHOUSE_PREFAB_OPEN_FRAME_SIZE.y)
		)
		frames.add_frame("open", atlas)
	_main_gate_open_frames = frames
	return _main_gate_open_frames


func _add_great_hall_door_animation(tile: Vector2i) -> AnimatedSprite2D:
	var frames := _get_great_hall_door_open_frames()
	if frames == null:
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.name = "GreatHallDoorOpenAnimation"
	sprite.sprite_frames = frames
	sprite.animation = "open"
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = _tile_top_left(tile) + Vector2(
		(TILE_SIZE - float(GREAT_HALL_DOOR_OPEN_FRAME_SIZE.x)) * 0.5,
		TILE_SIZE - float(GREAT_HALL_DOOR_OPEN_FRAME_SIZE.y)
	)
	(_layers["Traversal"] as Node2D).add_child(sprite)
	_attach_operator_depth_sort(sprite, float(GREAT_HALL_DOOR_OPEN_FRAME_SIZE.y - 8), 1, 12)
	return sprite


func _get_great_hall_door_open_frames() -> SpriteFrames:
	if _great_hall_door_open_frames != null:
		return _great_hall_door_open_frames
	var texture := _load_texture(GREAT_HALL_DOOR_OPEN_PATH)
	if texture == null:
		return null
	var frames := SpriteFrames.new()
	frames.add_animation("open")
	frames.set_animation_loop("open", false)
	frames.set_animation_speed("open", GREAT_HALL_DOOR_OPEN_FPS)
	var frame_count := mini(GREAT_HALL_DOOR_OPEN_FRAMES, int(floor(float(texture.get_width()) / float(GREAT_HALL_DOOR_OPEN_FRAME_SIZE.x))))
	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			float(frame_index * GREAT_HALL_DOOR_OPEN_FRAME_SIZE.x),
			0.0,
			float(GREAT_HALL_DOOR_OPEN_FRAME_SIZE.x),
			float(GREAT_HALL_DOOR_OPEN_FRAME_SIZE.y)
		)
		frames.add_frame("open", atlas)
	_great_hall_door_open_frames = frames
	return _great_hall_door_open_frames


func _attach_brazier_flicker(sprite: Sprite2D, base_size: Vector2) -> void:
	var frames := _get_brazier_flicker_frames()
	if frames == null:
		return
	var flicker := AnimatedSprite2D.new()
	flicker.name = "BrazierFlicker"
	flicker.sprite_frames = frames
	flicker.animation = "flicker"
	flicker.autoplay = "flicker"
	flicker.centered = false
	flicker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flicker.position = Vector2(
		(base_size.x - float(CAUSEWAY_BRAZIER_FLICKER_FRAME_SIZE.x)) * 0.5,
		base_size.y - float(CAUSEWAY_BRAZIER_FLICKER_FRAME_SIZE.y)
	)
	sprite.add_child(flicker)
	flicker.play("flicker")


func _get_brazier_flicker_frames() -> SpriteFrames:
	if _brazier_flicker_frames != null:
		return _brazier_flicker_frames
	var texture := _load_texture(CAUSEWAY_BRAZIER_FLICKER_PATH)
	if texture == null:
		return null
	var frames := SpriteFrames.new()
	frames.add_animation("flicker")
	frames.set_animation_loop("flicker", true)
	frames.set_animation_speed("flicker", CAUSEWAY_BRAZIER_FLICKER_FPS)
	for frame_index in range(CAUSEWAY_BRAZIER_FLICKER_FRAMES):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			float(frame_index * CAUSEWAY_BRAZIER_FLICKER_FRAME_SIZE.x),
			0.0,
			float(CAUSEWAY_BRAZIER_FLICKER_FRAME_SIZE.x),
			float(CAUSEWAY_BRAZIER_FLICKER_FRAME_SIZE.y)
		)
		frames.add_frame("flicker", atlas)
	_brazier_flicker_frames = frames
	return _brazier_flicker_frames


func _attach_operator_depth_sort(sprite: Node2D, y_offset: float, behind_z := 1, front_z := 3) -> void:
	if sprite == null:
		return
	var depth_sort := PROP_OPERATOR_DEPTH_SORT.new()
	depth_sort.name = "OperatorDepthSort"
	sprite.add_child(depth_sort)
	depth_sort.configure(sprite, y_offset, behind_z, front_z)


func _add_sprite(layer_name: String, asset_id: String, category: String, tile: Vector2i, offset: Vector2) -> Sprite2D:
	var texture := _load_texture(_asset_path(asset_id, category))
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.name = asset_id
	sprite.texture = texture
	sprite.centered = false
	if category == "floors" or category == "return_mooring_floor" or category == "return_mooring_overlay":
		sprite.position = _tile_top_left(tile) + offset
	else:
		var tex_size := texture.get_size()
		sprite.position = _tile_top_left(tile) + Vector2((TILE_SIZE - tex_size.x) * 0.5, TILE_SIZE - tex_size.y) + offset
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	(_layers[layer_name] as Node2D).add_child(sprite)
	return sprite


func _add_blocker(rect: Rect2i, blocker_name: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = blocker_name
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(float(rect.size.x) * TILE_SIZE, float(rect.size.y) * TILE_SIZE)
	shape.shape = rectangle
	shape.position = Vector2(rectangle.size.x * 0.5, rectangle.size.y * 0.5)
	body.position = _tile_top_left(rect.position)
	body.add_child(shape)
	(_layers["Collision"] as Node2D).add_child(body)
	_stats["blockers"] = int(_stats["blockers"]) + 1
	return body


func _add_interactable(node_name: String, kind: StringName, prompt: String, tile: Vector2i, distance: float) -> Node2D:
	var interactable := SUNDERED_KEEP_INTERACTABLE.new() as Node2D
	interactable.name = node_name
	interactable.position = _tile_center(tile)
	interactable.call("configure", self, kind, prompt, distance)
	add_child(interactable)
	_stats["interactables"] = int(_stats["interactables"]) + 1
	return interactable


func _ensure_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		return
	_hud = CUSTODIAN_HUD_SCENE.instantiate()
	if _hud == null:
		push_warning("[SunderedKeep] Unable to instantiate CustodianHUD")
		return
	_hud.name = "SunderedKeepCustodianHUD"
	add_child(_hud)
	_set_hud_active(false)
	_refresh_hud_state()


func _set_hud_active(active: bool) -> void:
	if _hud == null or not is_instance_valid(_hud):
		return
	if _hud.has_method("set_context_active"):
		_hud.call("set_context_active", active)
	else:
		_hud.visible = active


func _refresh_hud_state() -> void:
	if _hud == null or not is_instance_valid(_hud):
		return
	_hud.call("set_location", "SUNDERED KEEP FRONT GATE")
	_hud.set_phase("FREE ROAM PREP" if not _siege_started else "GATEHOUSE SIEGE")
	_hud.set_objective("Hold the gatehouse" if _siege_started else ("Enter the keep" if _main_gate_open else "Open the main gate"))
	_hud.set_key_item_status(_player_has_sundered_gate_key(), SUNDERED_GATE_KEY_NAME)
	_hud.set_main_gate_status(_main_gate_open, not _player_has_sundered_gate_key())
	_hud.set_return_mooring_status(_return_mooring_created, _return_mooring_created)
	if _siege_debug_label != null:
		_hud.set_debug_text(_siege_debug_label.text)


func _update_hud_prompt() -> void:
	if _hud == null or not is_instance_valid(_hud):
		return
	if _hud.has_method("is_context_active") and not bool(_hud.call("is_context_active")):
		return
	var operator_ref := get_node_or_null("/root/GameRoot/World/Operator")
	if operator_ref == null or not ("interaction_target" in operator_ref):
		return
	var target: Node = operator_ref.get("interaction_target")
	if target == null or not is_instance_valid(target):
		return
	var input_hint := _get_interact_prompt_key()
	if target == _return_mooring_interaction:
		_hud.show_interaction(
			"RETURN MOORING",
			"Return to main map",
			input_hint,
			UI_CATALOG.ICON_RETURN_MOORING
		)
	elif target == _main_gate_interaction:
		if _main_gate_open:
			_hud.hide_interaction()
		elif _player_has_sundered_gate_key():
			_hud.show_interaction(
				"MAIN PORTCULLIS",
				"Open gate",
				input_hint,
				UI_CATALOG.ICON_GATE_OPEN
			)
		else:
			_hud.show_interaction(
				"MAIN PORTCULLIS",
				"Requires Sundered Gate Key",
				input_hint,
				UI_CATALOG.ICON_GATE_LOCKED
			)
	elif target == _key_pickup_interaction:
		_hud.show_interaction(
			"SUNDERED GATE KEY",
			"Take key",
			input_hint,
			UI_CATALOG.ICON_KEY_ITEM
		)
	elif target == _great_hall_door_interaction:
		_hud.show_interaction(
			"GREAT HALL",
			"Open door",
			input_hint,
			UI_CATALOG.ICON_OBJECTIVE
		)
	elif target == _sidearm_locker_interaction and not _sidearm_locker_opened:
		_hud.show_interaction(
			"CUSTODIAN LOCKER",
			"Recover P-9 Field Sidearm",
			input_hint,
			UI_CATALOG.ICON_OBJECTIVE
		)
	elif target == _last_routekeeper_interaction and not _last_routekeeper_trace_recovered:
		_hud.show_interaction(
			"ROUTEKEEPER TRACE",
			"Recover route survey",
			input_hint,
			UI_CATALOG.ICON_OBJECTIVE
		)


func _get_interact_prompt_key() -> String:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			return OS.get_keycode_string(keycode)
	return "G"


func _handle_sundered_interaction(kind: StringName, actor: Node) -> void:
	match kind:
		&"return_mooring":
			return_to_main(actor)
		&"sundered_gate_key":
			_grant_sundered_gate_key()
		&"main_gate":
			_try_open_main_gate()
		&"great_hall_door":
			_try_open_great_hall_door()
		&"sidearm_locker":
			_grant_sidearm_locker(actor)
		&"last_routekeeper_trace":
			_recover_last_routekeeper_trace()
		&"repair_gatehouse":
			_repair_siege_objective("gatehouse_core")
		&"repair_mooring":
			_repair_siege_objective("return_mooring")


func _player_has_sundered_gate_key() -> bool:
	var inventory := get_node_or_null("/root/InventoryManager")
	if inventory != null and inventory.has_method("has_item"):
		return bool(inventory.call("has_item", SUNDERED_GATE_KEY_ID, 1))
	return _has_sundered_gate_key


func _grant_sundered_gate_key() -> void:
	if _player_has_sundered_gate_key():
		return
	_has_sundered_gate_key = true
	var inventory := get_node_or_null("/root/InventoryManager")
	if inventory != null and inventory.has_method("add_item"):
		inventory.call("add_item", SUNDERED_GATE_KEY_ID, 1)
	if _key_pickup_interaction != null and is_instance_valid(_key_pickup_interaction):
		_key_pickup_interaction.remove_from_group("interactable")
		_key_pickup_interaction.visible = false
	_refresh_hud_state()
	print("[SunderedKeep] Acquired %s: %s" % [SUNDERED_GATE_KEY_NAME, SUNDERED_GATE_KEY_FLAVOR])


func _grant_sidearm_locker(_actor: Node) -> void:
	if _sidearm_locker_opened:
		return
	var inventory := get_node_or_null("/root/InventoryManager")
	if inventory == null or not inventory.has_method("add_item"):
		push_warning("[SunderedKeep] Sidearm locker opened without InventoryManager")
		return
	inventory.call("add_item", SIDEARM_LOCKER_ITEM_ID, 1)
	_sidearm_locker_opened = true
	if _sidearm_locker_interaction != null and is_instance_valid(_sidearm_locker_interaction):
		_sidearm_locker_interaction.remove_from_group("interactable")
		_sidearm_locker_interaction.visible = false
	if _hud != null and is_instance_valid(_hud):
		_hud.show_interaction(
			SIDEARM_LOCKER_PICKUP_MESSAGE,
			"Custodian service imprint accepted / equip from Equipment",
			_get_interact_prompt_key(),
			UI_CATALOG.ICON_OBJECTIVE
		)
	_refresh_hud_state()
	print("[SunderedKeep] %s: %s recovered from sealed field-retention locker." % [SIDEARM_LOCKER_PICKUP_MESSAGE, SIDEARM_LOCKER_ITEM_NAME])


func _try_open_main_gate() -> void:
	if _main_gate_open:
		return
	if not _player_has_sundered_gate_key():
		if _hud != null and is_instance_valid(_hud):
			_hud.show_interaction(
				"MAIN PORTCULLIS",
				"Requires Sundered Gate Key",
				_get_interact_prompt_key(),
				UI_CATALOG.ICON_GATE_LOCKED
			)
		print("[SunderedKeep] Requires %s. The portcullis winch is locked." % SUNDERED_GATE_KEY_NAME)
		return
	_set_main_gate_open(true)


func _set_main_gate_open(open: bool) -> void:
	_main_gate_open = open
	if _main_gate_closed_sprite != null:
		_main_gate_closed_sprite.visible = not open
	if _main_gate_open_sprite != null:
		_main_gate_open_sprite.visible = open
		if open:
			_main_gate_open_sprite.frame = 0
			_main_gate_open_sprite.play("open")
		else:
			_main_gate_open_sprite.stop()
			_main_gate_open_sprite.frame = 0
	if open:
		_clear_main_gate_blockers()
		if _main_gate_interaction != null:
			_main_gate_interaction.remove_from_group("interactable")
			_main_gate_interaction.visible = false
		_start_siege()
		_maybe_spawn_last_routekeeper_trace()
	else:
		_add_main_gate_blockers()
	_refresh_hud_state()


func _build_siege_runtime_slice() -> void:
	if _siege_debug_label != null:
		return
	_siege_config = _load_siege_config()
	for objective_data in _siege_config.get("objectives", []):
		var objective := objective_data as Dictionary
		var id := str(objective.get("id", "objective_%d" % _siege_objectives.size()))
		var base_tile := _siege_anchor_tile(str(objective.get("tile_offset_from", "main_gate")))
		var objective_tile := base_tile + _array_to_vector2i(objective.get("tile_offset", [0, 0]), Vector2i.ZERO)
		_siege_objectives[id] = _add_siege_objective(
			id,
			str(objective.get("label", id.capitalize())),
			str(objective.get("group", "command_post")),
			objective_tile,
			float(objective.get("hp", 100.0))
		)
		var repair_kind := StringName(str(objective.get("repair_kind", "repair_%s" % id)))
		var repair_prompt := str(objective.get("repair_prompt", "REPAIR %s" % str(objective.get("label", id)).to_upper()))
		var repair_tile := base_tile + _array_to_vector2i(objective.get("repair_tile_offset", [0, 1]), Vector2i.DOWN)
		_add_interactable("%sRepairInteraction" % id.to_pascal_case(), repair_kind, repair_prompt, repair_tile, float(objective.get("repair_distance", 84.0)))
	for spawn_data in _siege_config.get("spawns", []):
		var spawn := spawn_data as Dictionary
		var spawn_tile := _siege_anchor_tile(str(spawn.get("tile_offset_from", "main_gate"))) + _array_to_vector2i(spawn.get("tile_offset", [0, 0]), Vector2i.ZERO)
		_add_siege_spawn_node(str(spawn.get("lane", "sundered_keep")), spawn_tile)
	_build_siege_defense_turret()
	_build_siege_debug_label()
	_update_siege_debug_label()


func _add_siege_objective(id: String, label: String, group_name: String, tile: Vector2i, hp: float) -> Node2D:
	var objective := SUNDERED_KEEP_SIEGE_OBJECTIVE.new() as Node2D
	objective.name = "%sObjective" % id.to_pascal_case()
	objective.call("configure", id, label, group_name, hp)
	objective.position = _tile_center(tile)
	add_child(objective)
	var callback := Callable(self, "_on_siege_objective_changed")
	if objective.has_signal("damaged") and not objective.is_connected("damaged", callback):
		objective.connect("damaged", callback)
	if objective.has_signal("repaired") and not objective.is_connected("repaired", callback):
		objective.connect("repaired", callback)
	return objective


func _add_siege_spawn_node(lane: String, tile: Vector2i) -> void:
	var spawn_node := SPAWN_NODE_SCRIPT.new() as Node2D
	spawn_node.name = "SunderedKeepSpawn_%02d" % _siege_spawn_nodes.size()
	spawn_node.set("lane", lane)
	spawn_node.position = _tile_center(tile)
	add_child(spawn_node)
	_siege_spawn_nodes.append(spawn_node)


func _build_siege_defense_turret() -> void:
	if DEFENSE_TURRET_SCENE == null:
		return
	_siege_turret = DEFENSE_TURRET_SCENE.instantiate() as Node2D
	if _siege_turret == null:
		return
	var turret_config: Dictionary = _siege_config.get("defense_turret", {})
	_siege_turret.name = "GatehouseDefenseTurret"
	var turret_tile := _siege_anchor_tile(str(turret_config.get("tile_offset_from", "main_gate"))) + _array_to_vector2i(turret_config.get("tile_offset", [-6, -2]), Vector2i(-6, -2))
	_siege_turret.position = _tile_center(turret_tile)
	_siege_turret.set("power_required", bool(turret_config.get("power_required", false)))
	_siege_turret.set("range", float(turret_config.get("range", 360.0)))
	_siege_turret.set("damage", float(turret_config.get("damage", 9.0)))
	add_child(_siege_turret)
	var base_sprite := _siege_turret.get_node_or_null("BaseSprite") as Sprite2D
	var barrel_sprite := _siege_turret.get_node_or_null("Barrel/BarrelSprite") as Sprite2D
	if base_sprite != null and barrel_sprite != null and barrel_sprite.texture == null:
		barrel_sprite.texture = base_sprite.texture
		barrel_sprite.scale = Vector2(0.45, 0.45)


func _build_siege_debug_label() -> void:
	_siege_debug_label = Label.new()
	_siege_debug_label.name = "SiegeDebugLabel"
	_siege_debug_label.position = _tile_top_left(main_gate_tile + Vector2i(-8, -5))
	_siege_debug_label.z_as_relative = false
	_siege_debug_label.z_index = 80
	_siege_debug_label.visible = false
	add_child(_siege_debug_label)


func _start_siege() -> void:
	if _siege_started:
		return
	_siege_started = true
	_siege_state = "active"
	_siege_game_over_triggered = false
	_siege_wave_index = 0
	_siege_pressure_tick = 0
	_siege_live_enemies.clear()
	_siege_required_enemy_ids.clear()
	_spawn_siege_wave()
	_ensure_siege_timer()
	_siege_timer.start()
	_update_siege_debug_label()
	_refresh_hud_state()
	print("[SunderedKeep] Siege active: gatehouse objectives exposed, defensive turret online, enemy pressure started.")


func _ensure_siege_timer() -> void:
	if _siege_timer == null:
		_siege_timer = Timer.new()
		_siege_timer.name = "SiegePressureTimer"
		_siege_timer.wait_time = max(0.5, float(_siege_config.get("pressure_interval_seconds", 5.0)))
		_siege_timer.one_shot = false
		_siege_timer.timeout.connect(_on_siege_timer_timeout)
		add_child(_siege_timer)
	else:
		_siege_timer.wait_time = max(0.5, float(_siege_config.get("pressure_interval_seconds", 5.0)))


func _on_siege_timer_timeout() -> void:
	if not _siege_started or _siege_state != "active":
		return
	_siege_pressure_tick += 1
	_apply_siege_pressure()
	if _siege_config.get("extra_wave_pressure_ticks", [2, 5]).has(_siege_pressure_tick):
		_spawn_siege_wave()
	_update_siege_debug_label()


func _spawn_siege_wave() -> void:
	_siege_wave_index += 1
	_siege_wave_spawning = true
	var waves: Array = _siege_config.get("waves", [])
	var wave_data: Dictionary = waves[min(_siege_wave_index - 1, waves.size() - 1)] if not waves.is_empty() else {"composition": ["drone", "drone", "grunt"]}
	var composition: Array = wave_data.get("composition", ["drone"])
	var enemy_director := get_node_or_null("/root/GameRoot/EnemyDirector")
	for index in range(composition.size()):
		var spawn_node := _siege_spawn_nodes[index % max(1, _siege_spawn_nodes.size())]
		var spawn_position := spawn_node.global_position + Vector2(float(index % 2) * 18.0, float(index) * 6.0)
		var enemy_type := str(composition[index])
		var enemy_container := get_node_or_null("/root/GameRoot/World/Enemies")
		var existing_enemy_ids := _child_instance_ids(enemy_container)
		var spawned := false
		if enemy_director != null and enemy_director.has_method("spawn_debug_enemy_type"):
			spawned = bool(enemy_director.call("spawn_debug_enemy_type", enemy_type, spawn_position, &"raider_grunt"))
		else:
			var wave_manager := get_node_or_null("/root/GameRoot/WaveManager")
			if wave_manager != null and wave_manager.has_method("debug_spawn_enemy_type"):
				spawned = bool(wave_manager.call("debug_spawn_enemy_type", enemy_type, spawn_position, 1.0 + float(_siege_wave_index) * 0.2, &"raider_grunt"))
		if spawned:
			_track_new_siege_enemy(enemy_container, existing_enemy_ids)
	_siege_wave_spawning = false


func _child_instance_ids(parent: Node) -> Dictionary:
	var result := {}
	if parent == null:
		return result
	for child in parent.get_children():
		result[child.get_instance_id()] = true
	return result


func _track_new_siege_enemy(enemy_container: Node, existing_enemy_ids: Dictionary) -> void:
	if enemy_container == null:
		return
	for child in enemy_container.get_children():
		var instance_id := child.get_instance_id()
		if existing_enemy_ids.has(instance_id):
			continue
		_siege_live_enemies[instance_id] = child
		if _siege_wave_index == 1:
			_siege_required_enemy_ids[instance_id] = true
		child.tree_exited.connect(_on_siege_enemy_tree_exited.bind(instance_id), CONNECT_ONE_SHOT)
		return


func _on_siege_enemy_tree_exited(instance_id: int) -> void:
	_siege_live_enemies.erase(instance_id)
	_siege_required_enemy_ids.erase(instance_id)
	if not _siege_wave_spawning:
		call_deferred("_check_siege_secured")


func _check_siege_secured() -> void:
	if _siege_started and _siege_state == "active" and not _siege_wave_spawning and _siege_required_enemy_ids.is_empty():
		_complete_siege()


func _complete_siege() -> void:
	_siege_started = false
	_siege_state = "secured"
	if _siege_timer != null:
		_siege_timer.stop()
	_update_siege_debug_label()
	_refresh_hud_state()
	print("[SunderedKeep] Siege secured: enemy pressure stopped.")


func _apply_siege_pressure() -> void:
	if not _siege_started or _siege_state != "active":
		return
	var objective := _most_intact_siege_objective()
	if objective == null:
		_collapse_siege("Sundered Keep objectives destroyed")
		return
	if objective.has_method("take_damage"):
		var damage_amount := float(_siege_config.get("pressure_damage_base", 9.0)) + float(_siege_wave_index) * float(_siege_config.get("pressure_damage_per_wave", 2.0))
		objective.call("take_damage", damage_amount)
	if _all_siege_objectives_destroyed():
		_collapse_siege("Sundered Keep objectives destroyed")


func _collapse_siege(reason: String) -> void:
	_siege_started = false
	_siege_state = "collapsed"
	_siege_game_over_triggered = true
	if _siege_timer != null:
		_siege_timer.stop()
	_update_siege_debug_label()
	_refresh_hud_state()
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("trigger_game_over") and not bool(game_state.get("game_over")):
		game_state.call("trigger_game_over", reason)


func _repair_siege_objective(objective_id: String) -> void:
	var objective: Node = _siege_objectives.get(objective_id, null)
	if objective == null or not is_instance_valid(objective):
		return
	if objective.has_method("repair"):
		objective.call("repair", float(_siege_config.get("repair_amount", 35.0)))
	_siege_state = "active" if _siege_started else "dormant"
	_update_siege_debug_label()
	print("[SunderedKeep] Repaired %s" % objective_id)


func _most_intact_siege_objective() -> Node:
	var best: Node = null
	var best_hp := -1.0
	for objective in _siege_objectives.values():
		if objective == null or not is_instance_valid(objective):
			continue
		if objective.has_method("is_dead") and bool(objective.call("is_dead")):
			continue
		var hp := float(objective.get("current_health")) if "current_health" in objective else 0.0
		if hp > best_hp:
			best_hp = hp
			best = objective
	return best


func _all_siege_objectives_destroyed() -> bool:
	for objective in _siege_objectives.values():
		if objective != null and is_instance_valid(objective):
			if not objective.has_method("is_dead") or not bool(objective.call("is_dead")):
				return false
	return true


func _get_siege_objective_states() -> Dictionary:
	var states: Dictionary = {}
	for objective_id_variant: Variant in _siege_objectives.keys():
		var objective_id := StringName(str(objective_id_variant))
		var objective: Node = _siege_objectives.get(String(objective_id)) as Node
		if objective != null \
		and is_instance_valid(objective) \
		and objective.has_method("capture_route_state"):
			states[objective_id] = objective.call("capture_route_state")
	return states


func _on_siege_objective_changed(_amount: float, _new_hp: float) -> void:
	_update_siege_debug_label()


func _update_siege_debug_label() -> void:
	if _siege_debug_label == null:
		return
	var lines := [
		"SUNDERED KEEP SIEGE: %s" % _siege_state.to_upper(),
		"Wave %d | Pressure %d" % [_siege_wave_index, _siege_pressure_tick],
	]
	for objective_state in _get_siege_objective_states().values():
		lines.append("%s: %d/%d %s" % [
			str(objective_state.get("name", "Objective")),
			int(round(float(objective_state.get("hp", 0.0)))),
			int(round(float(objective_state.get("max_hp", 0.0)))),
			str(objective_state.get("state", "")),
		])
	_siege_debug_label.text = "\n".join(lines)
	if _hud != null and is_instance_valid(_hud):
		_hud.set_debug_text(_siege_debug_label.text)


func _load_siege_config() -> Dictionary:
	if ResourceLoader.exists(siege_config_path):
		var file := FileAccess.open(siege_config_path, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary and str((parsed as Dictionary).get("schema", "")) == "custodian.sundered_keep.gatehouse_siege.v1":
				return parsed as Dictionary
			push_warning("[SunderedKeep] Invalid siege config: %s" % siege_config_path)
	else:
		push_warning("[SunderedKeep] Missing siege config: %s" % siege_config_path)
	return _default_siege_config()


func _default_siege_config() -> Dictionary:
	return {
		"pressure_interval_seconds": 5.0,
		"pressure_damage_base": 9.0,
		"pressure_damage_per_wave": 2.0,
		"repair_amount": 35.0,
		"objectives": [
			{"id": "gatehouse_core", "label": "Gatehouse Core", "group": "command_post", "tile_offset_from": "main_gate", "tile_offset": [2, 4], "hp": 180.0, "repair_kind": "repair_gatehouse", "repair_prompt": "REPAIR GATEHOUSE CORE", "repair_tile_offset": [2, 7], "repair_distance": 96.0},
			{"id": "return_mooring", "label": "Return Mooring", "group": "power_node", "tile_offset_from": "return_mooring_origin", "tile_offset": [2, 2], "hp": 140.0, "repair_kind": "repair_mooring", "repair_prompt": "REPAIR RETURN MOORING", "repair_tile_offset": [2, 4], "repair_distance": 82.0},
		],
		"spawns": [
			{"lane": "sundered_keep", "tile_offset_from": "main_gate", "tile_offset": [-7, -1]},
			{"lane": "sundered_keep", "tile_offset_from": "main_gate", "tile_offset": [8, -1]},
			{"lane": "sundered_keep", "tile_offset_from": "great_hall_door", "tile_offset": [0, 6]},
		],
		"waves": [
			{"composition": ["drone", "drone", "grunt"]},
			{"composition": ["grunt", "drone", "fast", "drone"]},
			{"composition": ["grunt", "grunt", "heavy"]},
		],
		"extra_wave_pressure_ticks": [2, 5],
		"defense_turret": {"tile_offset_from": "main_gate", "tile_offset": [-5, 4], "range": 360.0, "damage": 9.0, "power_required": false},
	}


func _siege_anchor_tile(anchor_id: String) -> Vector2i:
	match anchor_id:
		"return_mooring_origin":
			return return_mooring_origin_tile
		"great_hall_door":
			return great_hall_door_tile
		"entrance":
			return entrance_tile
		_:
			return main_gate_tile


func _try_open_great_hall_door() -> void:
	if _great_hall_door_open:
		return
	_set_great_hall_door_open(true)


func _set_great_hall_door_open(open: bool, play_animation := true) -> void:
	_great_hall_door_open = open
	if _great_hall_door_closed_sprite != null:
		_great_hall_door_closed_sprite.visible = true
		if open:
			if play_animation:
				_great_hall_door_closed_sprite.frame = 0
				_great_hall_door_closed_sprite.play("open")
			else:
				_great_hall_door_closed_sprite.stop()
				var frame_count := _great_hall_door_closed_sprite.sprite_frames.get_frame_count("open")
				_great_hall_door_closed_sprite.frame = maxi(0, frame_count - 1)
		else:
			_great_hall_door_closed_sprite.stop()
			_great_hall_door_closed_sprite.frame = 0
	if _great_hall_door_open_sprite != null:
		_great_hall_door_open_sprite.visible = open
	if open:
		_clear_great_hall_door_blockers()
		if _great_hall_door_interaction != null:
			_great_hall_door_interaction.remove_from_group("interactable")
			_great_hall_door_interaction.visible = false
	else:
		_add_great_hall_door_blockers()


func _add_great_hall_door_blockers() -> void:
	_clear_great_hall_door_blockers()
	_great_hall_door_blockers.append(_add_blocker(Rect2i(great_hall_door_tile, Vector2i(2, 1)), "GreatHallDoorBlocker"))


func _clear_great_hall_door_blockers() -> void:
	for blocker in _great_hall_door_blockers:
		if blocker != null and is_instance_valid(blocker):
			blocker.queue_free()
	_great_hall_door_blockers.clear()


func _add_main_gate_blockers() -> void:
	_clear_main_gate_blockers()
	_main_gate_blockers.append(_add_blocker(Rect2i(main_gate_tile + Vector2i(-1, 0), Vector2i(6, 3)), "PrefabGatehouseGateBlocker"))


func _clear_main_gate_blockers() -> void:
	for blocker in _main_gate_blockers:
		if blocker != null and is_instance_valid(blocker):
			blocker.queue_free()
	_main_gate_blockers.clear()


func _build_great_hall_marine_ambush() -> void:
	if _great_hall_marine_ambush != null and is_instance_valid(_great_hall_marine_ambush):
		return
	var marine := ENEMY_MARINE_SCENE.instantiate() as CharacterBody2D
	if marine == null:
		push_warning("[SunderedKeep] Unable to instantiate Great Hall marine ambush")
		return
	marine.name = "GreatHallDashMarine"
	marine.position = _tile_center(GREAT_HALL_MARINE_SPAWN_TILE)
	marine.set("enemy_name", "GREAT HALL MARINE")
	marine.set("damage", 18.0)
	marine.set("damage_interval", 1.4)
	marine.set("attack_windup_duration", 0.30)
	marine.set("behavior_state_machine_enabled", false)
	marine.set("custom_enemy_fx_scale", Vector2.ONE)
	add_child(marine)
	if marine.has_method("_ensure_directional_animations"):
		marine.call("_ensure_directional_animations")
	if marine.has_method("_ensure_custom_enemy_fx_animations"):
		marine.call("_ensure_custom_enemy_fx_animations")

	var ambush := SUNDERED_KEEP_MARINE_AMBUSH.new()
	ambush.name = "GreatHallMarineAmbush"
	add_child(ambush)
	ambush.call("configure", marine, null)
	_great_hall_marine_ambush = ambush


func _get_great_hall_marine_ambush_state() -> Dictionary:
	if _great_hall_marine_ambush == null or not is_instance_valid(_great_hall_marine_ambush):
		return {
			"exists": false,
			"state": "missing",
			"dash_ready": false,
			"dash_fx_ready": false,
		}
	if _great_hall_marine_ambush.has_method("capture_route_state"):
		return _great_hall_marine_ambush.call("capture_route_state") as Dictionary
	return {
		"exists": true,
		"state": "unknown",
		"dash_ready": false,
		"dash_fx_ready": false,
	}


func _asset_path(asset_id: String, category: String) -> String:
	if SUNDERED_KEEP_ASSETS.ASSETS.has(asset_id):
		var entry: Dictionary = SUNDERED_KEEP_ASSETS.ASSETS[asset_id]
		return str(entry.get("texture", ""))
	if category == "floors":
		return "res://content/tiles/sundered_keep/floors/%s.png" % asset_id
	if category == "entrance":
		return "res://content/tiles/sundered_keep/entrance/%s.png" % asset_id
	if category == "causeway_surfaces":
		return "res://content/tiles/sundered_keep/entrance/causeway_surfaces/%s.png" % asset_id
	if category == "causeway_floors":
		return "res://content/tiles/sundered_keep/entrance/causeway_floors/%s.png" % asset_id
	if category == "entrance_cliffs":
		return "res://content/tiles/sundered_keep/entrance/cliffs/%s.png" % asset_id
	if category == "entrance_overlays":
		return "res://content/tiles/sundered_keep/entrance/overlays/%s.png" % asset_id
	if category == "entrance_props":
		return "res://content/tiles/sundered_keep/entrance/props/%s.png" % asset_id
	if category == "entrance_prefabs":
		return "res://content/tiles/sundered_keep/entrance/prefabs/%s.png" % asset_id
	if category == "placeholder_keep_walls":
		return "%s/%s.png" % [PLACEHOLDER_KEEP_WALL_HOME, asset_id]
	if category == "return_mooring_floor":
		return "res://content/tiles/sundered_keep/return_mooring/floors/%s.png" % asset_id
	if category == "return_mooring_overlay":
		return "res://content/tiles/sundered_keep/return_mooring/overlays/%s.png" % asset_id
	if category == "overlays":
		return "res://content/tiles/sundered_keep/overlays/%s.png" % asset_id
	if category == "walls":
		for dir in WALL_ASSET_DIRS:
			var wall_path := "%s/%s.png" % [dir, asset_id]
			if ResourceLoader.exists(wall_path):
				return wall_path
		return "res://content/tiles/sundered_keep/walls/gothic_castle/%s.png" % asset_id
	if category == "props":
		var prop_paths := [
			"res://content/props/sundered_keep/causeway/%s.png" % asset_id,
			"res://content/props/sundered_keep/return_mooring/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_anchor/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_barrier/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_column/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_debris/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_furniture/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_hanging/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_large/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_light/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_mechanical/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_medium/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_observatory/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_rock/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_rooftop/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_rubble/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_statue/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_storage/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_table/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_tall/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_throne/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_tomb/%s.png" % asset_id,
			"res://content/runtime/sundered_keep/props/prop_wall_low/%s.png" % asset_id,
		]
		for prop_path in prop_paths:
			if ResourceLoader.exists(prop_path):
				return prop_path
	return "res://content/tiles/sundered_keep/%s/%s.png" % [category, asset_id]


func _load_texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path] as Texture2D
	if not ResourceLoader.exists(path):
		push_warning("[SunderedKeepMap] Missing texture: %s" % path)
		_stats["missing_assets"] = int(_stats["missing_assets"]) + 1
		_textures[path] = null
		return null
	var texture := load(path) as Texture2D
	_textures[path] = texture
	return texture


func _tile_top_left(tile: Vector2i) -> Vector2:
	return Vector2(float(tile.x) * TILE_SIZE, float(tile.y) * TILE_SIZE)


func _tile_center(tile: Vector2i) -> Vector2:
	return _tile_top_left(tile) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)


func _global_to_tile(global_position: Vector2) -> Vector2i:
	var local_position := to_local(global_position)
	return Vector2i(floori(local_position.x / TILE_SIZE), floori(local_position.y / TILE_SIZE))


func _refresh_camera(map_instance: Node, actor: Node) -> void:
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("set_runtime_map"):
		camera.call("set_runtime_map", map_instance)
	elif camera != null and actor is Node2D:
		camera.global_position = (actor as Node2D).global_position


# ---------------------------------------------------------------------------
# Last Routekeeper Event
# ---------------------------------------------------------------------------

func _maybe_spawn_last_routekeeper_trace() -> void:
	if _last_routekeeper_event != null and is_instance_valid(_last_routekeeper_event):
		return
	if _last_routekeeper_trace_recovered:
		return
	if _world_event_completed(LAST_ROUTEKEEPER_EVENT_ID):
		_last_routekeeper_trace_recovered = true
		return
	if _world_event_spawned(LAST_ROUTEKEEPER_EVENT_ID):
		return
	if not force_routekeeper_event and not _passes_last_routekeeper_roll():
		return
	_spawn_last_routekeeper_trace()


func _passes_last_routekeeper_roll() -> bool:
	if force_routekeeper_event:
		return true
	var chance := routekeeper_post_gate_spawn_chance_percent if _main_gate_open else routekeeper_base_spawn_chance_percent
	if chance <= 0:
		return false
	if chance >= 100:
		return true
	var seed := _world_event_seed(LAST_ROUTEKEEPER_EVENT_ID, "%s:%s:%s" % [_level_id, str(routekeeper_trace_tile), str(_main_gate_open)])
	return int(seed % 100) < chance


func _spawn_last_routekeeper_trace() -> void:
	var event := LAST_ROUTEKEEPER_EVENT.new() as Node2D
	if event == null:
		push_warning("[SunderedKeep] Could not instantiate Last Routekeeper event")
		return
	event.name = "LastRoutekeeperTrace"
	event.position = _tile_center(routekeeper_trace_tile)
	event.call("configure", self, routekeeper_hint_tile)
	add_child(event)
	_last_routekeeper_event = event
	_last_routekeeper_interaction = event.get_node_or_null("LastRoutekeeperTraceInteraction") as Node2D
	if event.has_signal("trace_recovered"):
		event.connect("trace_recovered", Callable(self, "_on_last_routekeeper_trace_recovered"))
	_mark_world_event_spawned(LAST_ROUTEKEEPER_EVENT_ID, {
		"level_id": _level_id,
		"trace_tile": routekeeper_trace_tile,
		"hint_tile": routekeeper_hint_tile,
	})
	print("[SunderedKeep] Last Routekeeper trace spawned at %s hint=%s" % [str(routekeeper_trace_tile), str(routekeeper_hint_tile)])


func _recover_last_routekeeper_trace() -> void:
	if _last_routekeeper_trace_recovered:
		return
	if _last_routekeeper_event == null or not is_instance_valid(_last_routekeeper_event):
		return

	var recovery_lines: Array[String] = []
	if _last_routekeeper_event.has_method("get_recovery_lines"):
		recovery_lines = _last_routekeeper_event.call("get_recovery_lines")

	for line in recovery_lines:
		if line.strip_edges() == "":
			continue
		print("[Routekeeper] %s" % line.replace("\n", " | "))

	if _last_routekeeper_event.has_method("recover_trace"):
		_last_routekeeper_event.call("recover_trace")
	else:
		_on_last_routekeeper_trace_recovered(routekeeper_hint_tile)


func _on_last_routekeeper_trace_recovered(hint_tile: Vector2i) -> void:
	if _last_routekeeper_trace_recovered:
		return
	_last_routekeeper_trace_recovered = true
	_reveal_routekeeper_hint(hint_tile)
	_grant_routekeeper_trace_note()
	_mark_world_event_completed(LAST_ROUTEKEEPER_EVENT_ID, {
		"level_id": _level_id,
		"trace_tile": routekeeper_trace_tile,
		"hint_tile": hint_tile,
	})
	if _last_routekeeper_interaction != null and is_instance_valid(_last_routekeeper_interaction):
		_last_routekeeper_interaction.remove_from_group("interactable")
		_last_routekeeper_interaction.visible = false
	if _hud != null and is_instance_valid(_hud):
		_hud.show_interaction(
			"ROUTEKEEPER TRACE RECOVERED",
			"Local traversal hint reconstructed",
			_get_interact_prompt_key(),
			UI_CATALOG.ICON_OBJECTIVE
		)
	_refresh_hud_state()
	print("[SunderedKeep] Routekeeper trace recovered. Revealed traversal hint at %s" % str(hint_tile))


func _reveal_routekeeper_hint(hint_tile: Vector2i) -> void:
	_minimap_floor_cells[hint_tile] = true

	if _routekeeper_hint_marker != null and is_instance_valid(_routekeeper_hint_marker):
		return

	var marker := _add_routekeeper_hint_marker(hint_tile)
	_routekeeper_hint_marker = marker


func _add_routekeeper_hint_marker(tile: Vector2i) -> Node2D:
	var layer := _layers.get("WorldUI", null) as Node2D
	if layer == null:
		return null

	# Prefer production asset later. Placeholder is a small cyan diamond.
	var marker := Polygon2D.new()
	marker.name = "RoutekeeperHintMarker"
	marker.position = _tile_center(tile)
	marker.polygon = PackedVector2Array([
		Vector2(0, -12),
		Vector2(8, 0),
		Vector2(0, 12),
		Vector2(-8, 0),
	])
	marker.color = Color(0.25, 0.85, 0.95, 0.72)
	layer.add_child(marker)
	return marker


func _grant_routekeeper_trace_note() -> void:
	var inventory := get_node_or_null("/root/InventoryManager")
	if inventory != null and inventory.has_method("add_item"):
		inventory.call("add_item", LAST_ROUTEKEEPER_TRACE_ITEM_ID, 1)

	var archive := get_node_or_null("/root/ArchiveManager")
	if archive != null and archive.has_method("add_entry"):
		archive.call("add_entry", LAST_ROUTEKEEPER_TRACE_ITEM_ID, {
			"title": LAST_ROUTEKEEPER_TRACE_ITEM_NAME,
			"source": "Sundered Keep / Return Causeway",
			"body": "An auxiliary routekeeper marked a return path beneath the broken causeway. Return was not observed.",
		})


# ---------------------------------------------------------------------------
# WorldEventMemory bridge methods
# ---------------------------------------------------------------------------

func _world_event_memory() -> Node:
	return get_node_or_null("/root/WorldEventMemory")


func _world_event_spawned(event_id: StringName) -> bool:
	var memory := _world_event_memory()
	if memory != null and memory.has_method("has_spawned"):
		return bool(memory.call("has_spawned", event_id))
	return false


func _world_event_completed(event_id: StringName) -> bool:
	var memory := _world_event_memory()
	if memory != null and memory.has_method("is_completed"):
		return bool(memory.call("is_completed", event_id))
	return false


func _mark_world_event_spawned(event_id: StringName, payload := {}) -> void:
	var memory := _world_event_memory()
	if memory != null and memory.has_method("mark_spawned"):
		memory.call("mark_spawned", event_id, payload)


func _mark_world_event_completed(event_id: StringName, payload := {}) -> void:
	var memory := _world_event_memory()
	if memory != null and memory.has_method("mark_completed"):
		memory.call("mark_completed", event_id, payload)


func _world_event_seed(event_id: StringName, salt := "") -> int:
	var memory := _world_event_memory()
	if memory != null and memory.has_method("get_event_seed"):
		return int(memory.call("get_event_seed", event_id, salt))
	return abs(hash("%s:%s" % [String(event_id), salt]))
