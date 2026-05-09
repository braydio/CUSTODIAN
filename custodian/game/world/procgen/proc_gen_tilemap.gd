class_name ProcGenTilemap
extends Node
## Wires ProcGen output to TileMap layers.
##
## Attach to a node with:
## - ProcGen child (the generator)
## - TileMapLayer child named "Floor" 
## - TileMapLayer child named "Walls"
## - NavigationRegion2D (optional, for auto-bake)
##
## Set tile coordinates in inspector, then call generate()

const RUNTIME_WALL_SEGMENT_SCRIPT := preload("res://game/world/procgen/runtime_wall_segment.gd")
const TILE_ALT_FLIP_H := 4096
const TILE_ALT_FLIP_V := 8192
const TILE_ALT_TRANSPOSE := 16384

@export var procgen_node: ProcGen
@export var floor_tilemap: TileMapLayer
@export var walls_tilemap: TileMapLayer
@export var nav_region: NavigationRegion2D

## TileSet source IDs (from your TileSet)
@export var floor_source_id: int = 0
@export var walls_source_id: int = 1
@export var high_walls_source_id: int = 2
@export var alternate_floor_source_ids: Array[int] = []
@export var full_grid_floor_source_ids: Array[int] = []
@export var full_grid_floor_dimensions: Vector2i = Vector2i(16, 16)

## Atlas coordinates for tiles (set in inspector)
@export var floor_atlas_coord: Vector2i = Vector2i(0, 0)
@export var wall_atlas_coord: Vector2i = Vector2i(0, 0)
@export var high_wall_atlas_coord: Vector2i = Vector2i(0, 0)
@export var use_floor_variants: bool = true
@export var use_wall_variants: bool = true
@export var use_reference_wall_connectors: bool = true
@export var use_wall_passage_variants: bool = true
@export_range(0.0, 1.0, 0.01) var wall_passage_spawn_chance: float = 0.65
@export_range(2, 16, 1) var wall_passage_min_run_tiles: int = 4
@export var floor_variant_coords: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2),
]
@export var full_hole_floor_atlas_coord: Vector2i = Vector2i(9, 2)
@export var use_cohesive_wall_visuals: bool = true
@export var wall_variant_coords: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0),
	Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1),
	Vector2i(6, 1), Vector2i(7, 1), Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1), Vector2i(11, 1),
]
@export var cohesive_wall_cap_coords: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
]
@export var cohesive_wall_body_coords: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)
]
@export var reference_vertical_wall_coords: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)
]
@export var reference_vertical_hole_right_coords: Array[Vector2i] = [
	Vector2i(8, 1)
]
@export var reference_vertical_hole_left_coords: Array[Vector2i] = [
	Vector2i(11, 2)
]
@export var reference_horizontal_wall_coords: Array[Vector2i] = [
	Vector2i(0, 3), Vector2i(2, 2), Vector2i(2, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(9, 3)
]
@export var reference_horizontal_hole_bottom_coords: Array[Vector2i] = [
	Vector2i(9, 0), Vector2i(10, 0)
]
@export var reference_wall_top_coords: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0)
]
@export var reference_open_left_wall_coords: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)
]
@export var reference_open_left_corner_coords: Array[Vector2i] = [
	Vector2i(1, 0)
]
@export var reference_open_left_t_coords: Array[Vector2i] = [
	Vector2i(1, 1), Vector2i(4, 1)
]
@export var reference_open_left_hole_coords: Array[Vector2i] = [
	Vector2i(4, 1), Vector2i(4, 2), Vector2i(4, 3), Vector2i(6, 2), Vector2i(8, 0), Vector2i(11, 1)
]
@export var reference_open_right_wall_coords: Array[Vector2i] = [
	Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2)
]
@export var reference_open_right_corner_coords: Array[Vector2i] = [
	Vector2i(3, 0), Vector2i(3, 2)
]
@export var reference_open_right_t_coords: Array[Vector2i] = [
	Vector2i(3, 1)
]
@export var reference_open_right_hole_coords: Array[Vector2i] = [
	Vector2i(5, 2), Vector2i(7, 1), Vector2i(7, 2), Vector2i(7, 3), Vector2i(8, 2), Vector2i(9, 1), Vector2i(10, 2), Vector2i(11, 0)
]
@export var reference_cross_wall_coords: Array[Vector2i] = [
	Vector2i(2, 0), Vector2i(2, 1), Vector2i(4, 0), Vector2i(7, 0), Vector2i(10, 3)
]
@export var reference_cross_hole_coords: Array[Vector2i] = [
	Vector2i(5, 0), Vector2i(6, 0)
]
@export var reference_passage_wall_coords: Array[Vector2i] = []
@export var reference_north_west_corner_coords: Array[Vector2i] = [
	Vector2i(5, 1)
]
@export var reference_north_east_corner_coords: Array[Vector2i] = [
	Vector2i(6, 1)
]
@export var reference_left_terminal_coords: Array[Vector2i] = [
	Vector2i(1, 3), Vector2i(8, 3)
]
@export var reference_right_terminal_coords: Array[Vector2i] = [
	Vector2i(3, 3), Vector2i(11, 3)
]
@export var high_wall_variant_coords: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0),
	Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0),
]
@export var cohesive_high_wall_cap_coords: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)
]
@export var cohesive_high_wall_body_coords: Array[Vector2i] = [
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)
]

## Use high walls (2-tile tall) vs low walls
@export var use_high_walls: bool = false

## Auto-bake navigation after generation
@export var auto_bake_nav: bool = true

## Clear tilemaps before generating
@export var clear_first: bool = true

## Compound generation (structured base area)
@export var enable_compound_zone: bool = true
@export_range(0.1, 0.2, 0.01) var compound_area_ratio: float = 0.14
@export var compound_min_size: Vector2i = Vector2i(24, 20)
@export var compound_max_size: Vector2i = Vector2i(42, 34)
@export_range(1, 4, 1) var compound_wall_thickness: int = 2
@export_range(2, 8, 1) var compound_building_count: int = 4
@export_range(2, 6, 1) var compound_ingress_count: int = 3

## Layout variation: not cave-like every run
@export_range(0.0, 1.0, 0.01) var open_layout_chance: float = 0.35
@export_range(0.0, 0.6, 0.01) var open_layout_carve_ratio: float = 0.20
@export_group("Constructed Interior Region", "interior_region")
@export var interior_region_enabled: bool = true
@export var interior_region_min_size: Vector2i = Vector2i(26, 18)
@export var interior_region_max_size: Vector2i = Vector2i(44, 30)
@export_range(1, 5, 1) var interior_region_hallway_width: int = 3
@export_range(2, 10, 1) var interior_region_room_count: int = 5
@export_range(1, 4, 1) var interior_region_entrance_count: int = 2
@export var interior_region_debug_logging: bool = false
@export var interior_use_dedicated_tiles: bool = true
@export var interior_floor_source_ids: Array[int] = []
@export var interior_wall_source_ids: Array[int] = []
@export var interior_wall_source_id: int = -1
@export var interior_wall_corner_source_id: int = -1
@export var interior_tile_atlas_coord: Vector2i = Vector2i(0, 0)
@export var interior_floor_use_transforms: bool = true
@export_range(2, 8, 1) var interior_floor_patch_size_tiles: int = 4
@export_range(0.0, 1.0, 0.01) var interior_floor_accent_chance: float = 0.22
@export_group("", "")
@export var build_runtime_wall_collision: bool = true
@export var destructible_runtime_walls: bool = true
@export var wall_tile_max_health: float = 42.0
@export var enable_streaming_reveal: bool = true
@export_range(4, 32, 1) var streaming_chunk_size_tiles: int = 16
@export_range(0, 3, 1) var streaming_immediate_chunk_radius: int = 1
@export_range(1, 4, 1) var streaming_active_chunk_radius: int = 2
@export_range(1, 256, 1) var streaming_reveal_tiles_per_frame: int = 96
@export var streaming_unload_distant_chunks: bool = false
@export_range(2, 8, 1) var streaming_unload_chunk_distance: int = 4

var _last_compound_rect: Rect2i = Rect2i()
var _last_compound_ingress: Array[Vector2i] = []
var _last_compound_buildings: Array[Rect2i] = []
var _last_interior_region_rect: Rect2i = Rect2i()
var _last_interior_rooms: Array[Rect2i] = []
var _last_interior_thresholds: Array[Vector2i] = []
var _region_tiles: Dictionary = {}
var _wall_health: Dictionary = {}
var _generated_floor_cells: Dictionary = {}
var _generated_wall_cells: Dictionary = {}
var _revealed_chunks: Dictionary = {}
var _queued_chunks: Dictionary = {}
var _streaming_reveal_queue: Array[Vector2i] = []
var _streaming_player: Node2D = null
var _streaming_current_chunk: Vector2i = Vector2i(999999, 999999)
var _navigation_rebuild_pending: bool = false
var _navigation_rebuild_deferred: bool = false
var shadow_system: Node = null


const FOLIAGE_ASSET_PATHS := [
	"res://content/sprites/environment/foliage/shrub_verdent_32x32_01.png",
	"res://content/sprites/environment/foliage/shrub_verdent_32x32_02.png",
	"res://content/sprites/environment/foliage/shrub_verdent_32x32_03.png",
	"res://content/sprites/environment/foliage/shrub_verdent_64x64_01.png",
	"res://content/sprites/environment/foliage/shrub_verdent_64x64_02.png",
	"res://content/sprites/environment/foliage/shrub_verdent_64x64_03.png",
	"res://content/sprites/environment/foliage/tree_verdent_96x128_01.png",
	"res://content/sprites/environment/foliage/tree_verdent_96x128_02.png",
	"res://content/sprites/environment/foliage/tree_verdent_96x128_03.png",
]

const FRUIT_TEXTURE_PATH := "res://content/sprites/environment/foliage/fruit_sheet.png"
const FOLIAGE_OCCLUSION_SHADER := preload("res://game/world/procgen/foliage_occlusion_bubble.gdshader")
const FOLIAGE_OCCLUSION_MAX_SHADER_BUBBLES := 8
const DEFAULT_RUIN_PROP_SCENE := preload("res://content/props/ruins/scenes/ProceduralProp.tscn")
const DEFAULT_RUIN_PROP_SPAWN_SET := preload("res://content/props/ruins/data/ruin_prop_spawn_set.tres")
const PROP_SCATTERER_SCRIPT := preload("res://content/props/ruins/scripts/PropScatterer.gd")
const INTERIOR_RUNTIME_DIR := "res://content/tiles/interiors/runtime"
@export var foliage_parent_path: NodePath = NodePath("NavigationRegion2D/FoliageLayer")
@export var foliage_density: float = 0.12
@export var foliage_min_wall_distance: int = 1
@export_range(0, 6, 1) var foliage_indoor_clearance_tiles: int = 3
@export var foliage_jitter_amplitude: Vector2 = Vector2(4, 2)
@export var foliage_debug_logging: bool = false
@export_range(0.0, 1.0, 0.01) var foliage_compound_density_multiplier: float = 0.28
@export_range(0, 8, 1) var foliage_compound_building_clearance: int = 2
@export_range(0, 12, 1) var foliage_spawn_clearance_radius: int = 4
@export var extra_foliage_textures: Array[Texture2D] = []
@export var enable_fruit_spawning: bool = true
@export_range(0.0, 1.0, 0.01) var fruit_spawn_chance_shrub: float = 0.10
@export_range(0.0, 1.0, 0.01) var fruit_spawn_chance_tree: float = 0.14
@export_range(1, 8, 1) var fruit_tiles_wide: int = 3
@export_range(1, 8, 1) var fruit_tiles_high: int = 3
@export var foliage_behind_z_index: int = 1
@export var foliage_front_z_index: int = 3
@export var use_horizontal_wall_overlays: bool = false
@export var horizontal_wall_overlay_texture: Texture2D = null
@export_range(1, 6, 1) var horizontal_wall_overlay_cells_wide: int = 3
@export_range(1, 6, 1) var horizontal_wall_overlay_cells_high: int = 3
@export var horizontal_wall_overlay_z_index: int = 4
@export var horizontal_wall_overlay_tint_with_planet_profile: bool = true
@export var use_vertical_wall_overlays: bool = false
@export_range(1, 6, 1) var vertical_wall_overlay_cells_wide: int = 3
@export_range(1, 6, 1) var vertical_wall_overlay_cells_high: int = 3
@export var tighten_tall_wall_collision: bool = false
@export var show_base_wall_tiles: bool = true
@export var collision_only_on_new_ruined_wall_tiles: bool = false
@export var use_horizontal_wall_endcaps: bool = false
@export var horizontal_wall_endcap_texture: Texture2D
@export var use_horizontal_wall_south_connector: bool = false
@export var horizontal_wall_south_connector_texture: Texture2D
@export_range(0, 4, 1) var horizontal_wall_south_connector_end_buffer_segments: int = 1
@export_range(0.0, 1.0, 0.05) var horizontal_wall_south_connector_spawn_chance: float = 0.35
@export var show_runtime_wall_collision_debug: bool = false
@export_range(0.0, 0.75, 0.05) var horizontal_wall_endcap_overlap_ratio: float = 0.25
@export_range(0, 48, 1) var horizontal_wall_endcap_vertical_jitter_px: int = 12
@export var foliage_player_feet_offset: Vector2 = Vector2(0, 8)
@export var foliage_player_upper_body_offset: Vector2 = Vector2(0, -22)
@export var foliage_player_occlusion_x_padding: float = 10.0
@export var foliage_player_occlusion_radius: float = 80.0
@export var foliage_player_occlusion_softness: float = 12.0
@export_range(0.1, 1.0, 0.05) var foliage_player_occlusion_alpha: float = 0.55
@export_range(1, 8, 1) var foliage_occlusion_max_bubbles: int = 8
@export var foliage_mob_occlusion_enabled: bool = true
@export var foliage_mob_occlusion_groups: PackedStringArray = PackedStringArray(["enemy", "ambient_critter", "mob"])
@export var foliage_mob_occlusion_player_range: float = 360.0
@export var foliage_mob_feet_offset: Vector2 = Vector2(0, 6)
@export var foliage_mob_upper_body_offset: Vector2 = Vector2(0, -18)
@export var foliage_mob_occlusion_x_padding: float = 8.0
@export var foliage_tree_trunk_collision_size: Vector2 = Vector2(18, 12)
@export var foliage_tree_trunk_collision_offset: Vector2 = Vector2(0, -6)
@export var foliage_probabilistic_tree_collision: bool = true
@export_range(1, 8, 1) var foliage_tree_collision_density_radius: int = 4
@export_range(0.0, 1.0, 0.01) var foliage_sparse_tree_collision_threshold: float = 0.08
@export_range(0.0, 1.0, 0.01) var foliage_dense_tree_collision_threshold: float = 0.22
@export_range(0.0, 1.0, 0.01) var foliage_dense_tree_collision_chance: float = 0.28
@export var ruin_prop_parent_path: NodePath = NodePath("NavigationRegion2D/PropLayer")
@export var enable_ruin_prop_spawning: bool = true
@export var ruin_prop_scene: PackedScene = DEFAULT_RUIN_PROP_SCENE
@export var ruin_prop_spawn_set: PropSpawnSet = DEFAULT_RUIN_PROP_SPAWN_SET
@export_range(0, 64, 1) var ruin_prop_count: int = 50
@export_range(1, 12, 1) var ruin_prop_min_distance_tiles: int = 5
@export_range(0, 6, 1) var ruin_prop_indoor_clearance_tiles: int = 2
@export_range(0, 8, 1) var ruin_prop_wall_clearance_tiles: int = 2
@export_range(0, 12, 1) var ruin_prop_spawn_clearance_radius: int = 7
@export_range(0, 8, 1) var ruin_prop_compound_building_clearance: int = 3
@export var ruin_prop_jitter_amplitude: Vector2 = Vector2(5, 3)
@export var ruin_prop_variant_intensity: ProceduralProp.VariantIntensity = ProceduralProp.VariantIntensity.SUBTLE
@export var ruin_prop_debug_logging: bool = false
@export_group("Interior Props", "interior_prop")
@export var interior_prop_spawning_enabled: bool = true
@export_range(0, 80, 1) var interior_prop_count: int = 50
@export_range(1, 8, 1) var interior_prop_min_distance_tiles: int = 1
@export_range(0, 4, 1) var interior_prop_wall_clearance_tiles: int = 0
@export_range(0, 6, 1) var interior_prop_threshold_clearance_tiles: int = 1
@export var interior_prop_jitter_amplitude: Vector2 = Vector2(6, 4)
@export var interior_prop_allow_flip_h: bool = false
@export var interior_prop_debug_logging: bool = false
@export_group("", "")

var _foliage_parent: Node2D = null
var _ruin_prop_parent: Node2D = null
var _ruin_prop_scatterer: PropScatterer = null
var _interior_prop_nodes: Array[Node2D] = []
var _foliage_nodes: Dictionary = {}
var _foliage_textures: Array[Texture2D] = []
var _interior_prop_textures: Array[Texture2D] = []
var _fruit_texture: Texture2D = null
var _fruit_sprites: Array[Node2D] = []
var _planet_world_profile: Dictionary = {}

func _ready() -> void:
	add_to_group("procgen_tilemap")
	# Auto-find ProcGen if not assigned
	if not procgen_node:
		procgen_node = find_child("ProcGen", true, false) as ProcGen
	
	if not floor_tilemap:
		floor_tilemap = find_child("Floor", true, false) as TileMapLayer
		
	if not walls_tilemap:
		walls_tilemap = find_child("Walls", true, false) as TileMapLayer
	
	if not nav_region:
		nav_region = find_child("NavigationRegion2D", true, false) as NavigationRegion2D

	if shadow_system == null:
		shadow_system = find_child("ShadowOverlay", true, false)
	_foliage_parent = _find_foliage_parent()
	_ruin_prop_parent = _find_ruin_prop_parent()
	_load_foliage_textures()
	_load_interior_prop_textures()
	_apply_planet_visual_profile()
	
	if procgen_node:
		procgen_node.finished.connect(_on_procgen_finished)


func _process(_delta: float) -> void:
	if not enable_streaming_reveal:
		return
	if _generated_floor_cells.is_empty() and _generated_wall_cells.is_empty():
		return
	if not _is_attached_to_runtime_world():
		return

	if _streaming_player == null or not is_instance_valid(_streaming_player):
		_streaming_player = get_tree().get_first_node_in_group("player") as Node2D

	if _streaming_player != null:
		var player_tile := _global_to_tile(_streaming_player.global_position)
		var player_chunk := _tile_to_chunk(player_tile)
		if player_chunk != _streaming_current_chunk:
			_streaming_current_chunk = player_chunk
			_update_streaming_chunks(player_chunk, player_tile)
		_update_foliage_occlusion(_streaming_player)

	_process_streaming_reveal_queue()


func _is_attached_to_runtime_world() -> bool:
	var parent_node := get_parent()
	return parent_node != null and String(parent_node.name) == "ProcGenRuntime"


func generate() -> void:
	if not procgen_node:
		push_error("ProcGenTilemap: No ProcGen node assigned")
		return
	
	if not floor_tilemap or not walls_tilemap:
		push_error("ProcGenTilemap: Missing TileMapLayer references")
		return
	
	procgen_node.generate()


func apply_planet_world_profile(profile: Dictionary) -> void:
	_planet_world_profile = profile.duplicate(true)
	compound_area_ratio = clamp(float(_planet_world_profile.get("compound_area_ratio", compound_area_ratio)), 0.10, 0.20)
	open_layout_chance = clamp(float(_planet_world_profile.get("open_layout_chance", open_layout_chance)), 0.0, 1.0)
	open_layout_carve_ratio = clamp(float(_planet_world_profile.get("open_layout_carve_ratio", open_layout_carve_ratio)), 0.0, 0.6)
	foliage_density = max(0.0, float(_planet_world_profile.get("foliage_density", foliage_density)))
	foliage_compound_density_multiplier = clamp(float(_planet_world_profile.get("foliage_compound_density_multiplier", foliage_compound_density_multiplier)), 0.0, 1.0)
	fruit_spawn_chance_shrub = clamp(float(_planet_world_profile.get("fruit_spawn_chance_shrub", fruit_spawn_chance_shrub)), 0.0, 1.0)
	fruit_spawn_chance_tree = clamp(float(_planet_world_profile.get("fruit_spawn_chance_tree", fruit_spawn_chance_tree)), 0.0, 1.0)
	_apply_planet_visual_profile()


func get_planet_world_profile() -> Dictionary:
	return _planet_world_profile.duplicate(true)


## Emitted when level data is ready (after generation)
signal level_data_ready(data: Dictionary)
signal minimap_tile_changed(tile: Vector2i, terrain_kind: String)


func _on_procgen_finished() -> void:
	_fill_tilemaps()
	_refresh_shadows()
	
	if auto_bake_nav and nav_region:
		nav_region.bake_navigation_polygon(false)
	
	# Emit level data for game systems to use
	var data = get_level_data()
	level_data_ready.emit(data)


func _fill_tilemaps() -> void:
	if clear_first:
		floor_tilemap.clear()
		walls_tilemap.clear()
		_wall_health.clear()
		_clear_region_metadata()
		_clear_foliage()
		_clear_interior_props()
		_clear_ruin_props()
		_clear_horizontal_wall_overlays()
	_apply_planet_visual_profile()
	
	var map_size = procgen_node.map_size
	var open_layout_active := _is_open_layout_active()
	
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos = Vector2i(x, y)
			var is_wall = procgen_node.is_full_at(pos)
			if is_wall and open_layout_active and _should_carve_open(pos):
				is_wall = false
			
			if is_wall:
				_set_wall_tile(pos)
			else:
				_set_floor_tile(pos)

	if enable_compound_zone:
		_apply_compound_layout(map_size)
	if interior_region_enabled:
		_apply_constructed_interior_region(map_size)
	if use_cohesive_wall_visuals:
		_apply_wall_visuals(map_size)
	_capture_generated_tile_state(map_size)
	if enable_streaming_reveal:
		_prepare_streaming_reveal()
	elif build_runtime_wall_collision:
		_rebuild_runtime_wall_collision(map_size)
	if not enable_streaming_reveal:
		_rebuild_horizontal_wall_overlays()


func set_seed(new_seed: int) -> void:
	if procgen_node:
		procgen_node.seed = new_seed
		procgen_node.generate_seed = false


func _select_floor_coord(pos: Vector2i) -> Vector2i:
	var source_id := _select_floor_source_id(pos)
	if full_grid_floor_source_ids.has(source_id):
		return _select_full_grid_floor_coord(pos)
	if not use_floor_variants:
		return floor_atlas_coord
	return _pick_variant_coord(pos, floor_variant_coords, floor_atlas_coord)


func _select_wall_coord(pos: Vector2i) -> Vector2i:
	if use_cohesive_wall_visuals:
		return _select_cohesive_wall_coord(pos)
	if use_high_walls:
		if not use_wall_variants:
			return high_wall_atlas_coord
		return _pick_variant_coord(pos, high_wall_variant_coords, high_wall_atlas_coord)
	if not use_wall_variants:
		return wall_atlas_coord
	return _pick_variant_coord(pos, wall_variant_coords, wall_atlas_coord)


func _pick_variant_coord(pos: Vector2i, variants: Array[Vector2i], fallback: Vector2i) -> Vector2i:
	if variants.is_empty():
		return fallback
	var idx := _tile_noise_hash(pos) % variants.size()
	return variants[idx]


func _tile_noise_hash(pos: Vector2i) -> int:
	var seed_value := 0
	if procgen_node and "seed" in procgen_node:
		seed_value = int(procgen_node.seed)
	var hashed := int(pos.x) * 73856093
	hashed ^= int(pos.y) * 19349663
	hashed ^= seed_value * 83492791
	return abs(hashed)


func _is_open_layout_active() -> bool:
	var seed_token := _tile_noise_hash(Vector2i(17, 31)) % 1000
	return float(seed_token) / 1000.0 < open_layout_chance


func _should_carve_open(pos: Vector2i) -> bool:
	if _count_wall_neighbors(pos) >= 6:
		return false
	var threshold := int(round(open_layout_carve_ratio * 100.0))
	return (_tile_noise_hash(pos + Vector2i(13, 29)) % 100) < threshold


func _count_wall_neighbors(pos: Vector2i) -> int:
	var dirs := [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
	]
	var count := 0
	for d in dirs:
		if procgen_node.is_full_at(pos + d):
			count += 1
	return count


func _set_floor_tile(pos: Vector2i) -> void:
	var source_id := _select_floor_source_id(pos)
	floor_tilemap.set_cell(pos, source_id, _select_floor_coord(pos))
	walls_tilemap.erase_cell(pos)
	_wall_health.erase(pos)


func _select_floor_source_id(pos: Vector2i) -> int:
	if alternate_floor_source_ids.is_empty():
		return floor_source_id
	var source_ids: Array[int] = [floor_source_id]
	for source_id in alternate_floor_source_ids:
		if not source_ids.has(source_id):
			source_ids.append(source_id)
	var idx := _tile_noise_hash(pos + Vector2i(101, 37)) % source_ids.size()
	return source_ids[idx]


func _select_full_grid_floor_coord(pos: Vector2i) -> Vector2i:
	var width: int = maxi(1, full_grid_floor_dimensions.x)
	var height: int = maxi(1, full_grid_floor_dimensions.y)
	var hashed: int = _tile_noise_hash(pos + Vector2i(53, 89))
	return Vector2i(hashed % width, int(hashed / width) % height)


func _set_wall_tile(pos: Vector2i) -> void:
	var source = high_walls_source_id if use_high_walls else walls_source_id
	var coord = _select_wall_coord(pos)
	walls_tilemap.set_cell(pos, source, coord)
	floor_tilemap.erase_cell(pos)
	if not _wall_health.has(pos):
		_wall_health[pos] = wall_tile_max_health


func _set_interior_floor_tile(pos: Vector2i, zone: String = "") -> void:
	if not interior_use_dedicated_tiles or interior_floor_source_ids.is_empty():
		_set_floor_tile(pos)
		return
	var source_id := _select_interior_floor_source_id(pos, zone)
	floor_tilemap.set_cell(pos, source_id, interior_tile_atlas_coord, _select_interior_floor_alternative(pos, zone))
	walls_tilemap.erase_cell(pos)
	_wall_health.erase(pos)


func _select_interior_floor_source_id(pos: Vector2i, zone: String = "") -> int:
	if interior_floor_source_ids.is_empty():
		return _select_floor_source_id(pos)
	var source_ids := interior_floor_source_ids.duplicate()
	var patch_size: int = maxi(1, interior_floor_patch_size_tiles)
	var patch := Vector2i(int(pos.x / patch_size), int(pos.y / patch_size))
	var idx := _tile_noise_hash(patch + Vector2i(337, 911)) % source_ids.size()
	var accent_threshold := int(round(interior_floor_accent_chance * 100.0))
	if zone == "warehouse_bay":
		accent_threshold = maxi(accent_threshold, 38)
	if source_ids.size() > 1 and (_tile_noise_hash(pos + Vector2i(701, 313)) % 100) < accent_threshold:
		idx = _tile_noise_hash(pos + Vector2i(557, 883)) % source_ids.size()
	return source_ids[idx]


func _select_interior_floor_alternative(pos: Vector2i, zone: String = "") -> int:
	if not interior_floor_use_transforms:
		return 0
	var hash := _tile_noise_hash(pos + Vector2i(1249, 787))
	var transform := hash % 8
	match transform:
		1:
			return TILE_ALT_FLIP_H
		2:
			return TILE_ALT_FLIP_V
		3:
			return TILE_ALT_FLIP_H | TILE_ALT_FLIP_V
		4:
			return TILE_ALT_TRANSPOSE
		5:
			return TILE_ALT_TRANSPOSE | TILE_ALT_FLIP_H
		6:
			return TILE_ALT_TRANSPOSE | TILE_ALT_FLIP_V
		7:
			return TILE_ALT_TRANSPOSE | TILE_ALT_FLIP_H | TILE_ALT_FLIP_V
		_:
			return 0


func _set_interior_wall_tile(pos: Vector2i) -> void:
	if not interior_use_dedicated_tiles or (interior_wall_source_id < 0 and interior_wall_source_ids.is_empty()):
		_set_wall_tile(pos)
		return
	var source_id := _select_interior_wall_source_id(pos)
	if interior_wall_corner_source_id >= 0 and _is_interior_corner_wall(pos):
		source_id = interior_wall_corner_source_id
	walls_tilemap.set_cell(pos, source_id, interior_tile_atlas_coord)
	floor_tilemap.erase_cell(pos)
	if not _wall_health.has(pos):
		_wall_health[pos] = wall_tile_max_health


func _select_interior_wall_source_id(pos: Vector2i) -> int:
	if interior_wall_source_ids.is_empty():
		return interior_wall_source_id
	var idx := _tile_noise_hash(pos + Vector2i(977, 389)) % interior_wall_source_ids.size()
	return interior_wall_source_ids[idx]


func _is_interior_corner_wall(pos: Vector2i) -> bool:
	var horizontal_floor := get_region_type_at_tile(pos + Vector2i.LEFT) in ["interior_floor", "interior_threshold"] or get_region_type_at_tile(pos + Vector2i.RIGHT) in ["interior_floor", "interior_threshold"]
	var vertical_floor := get_region_type_at_tile(pos + Vector2i.UP) in ["interior_floor", "interior_threshold"] or get_region_type_at_tile(pos + Vector2i.DOWN) in ["interior_floor", "interior_threshold"]
	return horizontal_floor and vertical_floor


func _apply_wall_visuals(map_size: Vector2i) -> void:
	var source = high_walls_source_id if use_high_walls else walls_source_id
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos := Vector2i(x, y)
			if walls_tilemap.get_cell_source_id(pos) < 0:
				continue
			if get_region_type_at_tile(pos) == "interior_wall" and interior_use_dedicated_tiles and (interior_wall_source_id >= 0 or not interior_wall_source_ids.is_empty()):
				_set_interior_wall_tile(pos)
				continue
			walls_tilemap.set_cell(pos, source, _select_cohesive_wall_coord(pos))


func _select_cohesive_wall_coord(pos: Vector2i) -> Vector2i:
	if not use_high_walls and use_reference_wall_connectors:
		return _select_reference_wall_coord(pos)
	if use_high_walls:
		var high_cap_fallback := high_wall_atlas_coord
		var high_body_fallback := high_wall_atlas_coord
		if not cohesive_high_wall_cap_coords.is_empty():
			high_cap_fallback = cohesive_high_wall_cap_coords[0]
		if not cohesive_high_wall_body_coords.is_empty():
			high_body_fallback = cohesive_high_wall_body_coords[0]
		if _is_wall_top_exposed(pos):
			return _pick_variant_coord(pos, cohesive_high_wall_cap_coords, high_cap_fallback)
		return _pick_variant_coord(pos, cohesive_high_wall_body_coords, high_body_fallback)

	var cap_fallback := wall_atlas_coord
	var body_fallback := wall_atlas_coord
	if not cohesive_wall_cap_coords.is_empty():
		cap_fallback = cohesive_wall_cap_coords[0]
	if not cohesive_wall_body_coords.is_empty():
		body_fallback = cohesive_wall_body_coords[0]
	if _is_wall_top_exposed(pos):
		return _pick_variant_coord(pos, cohesive_wall_cap_coords, cap_fallback)
	return _pick_variant_coord(pos, cohesive_wall_body_coords, body_fallback)


func _select_reference_wall_coord(pos: Vector2i) -> Vector2i:
	if _is_wall_top_exposed(pos):
		if _should_use_wall_passage_variant(pos):
			return _pick_reference_coord(pos + Vector2i(613, 397), reference_passage_wall_coords, wall_atlas_coord)
		if _is_horizontal_wall_surface(pos):
			return _pick_reference_coord(pos, reference_wall_top_coords, wall_atlas_coord)
	var forced_linear_match := _select_reference_linear_wall_coord(pos)
	if forced_linear_match != Vector2i(-1, -1):
		return forced_linear_match
	var stencil_match := _select_reference_wall_coord_by_stencil(pos)
	if stencil_match != Vector2i(-1, -1):
		return stencil_match
	return _select_reference_wall_coord_by_mask(pos)


func _select_reference_linear_wall_coord(pos: Vector2i) -> Vector2i:
	var north := _has_wall_cell(pos + Vector2i.UP)
	var east := _has_wall_cell(pos + Vector2i.RIGHT)
	var south := _has_wall_cell(pos + Vector2i.DOWN)
	var west := _has_wall_cell(pos + Vector2i.LEFT)
	var hole_left := _is_void_cell(pos + Vector2i.LEFT)
	var hole_right := _is_void_cell(pos + Vector2i.RIGHT)
	var hole_below := _is_void_cell(pos + Vector2i.DOWN)

	# Make sure obvious linear runs stay populated even when the stencil matcher is too strict.
	if north and south and not east and not west:
		if hole_left:
			return _pick_reference_coord(pos, reference_vertical_hole_left_coords, wall_atlas_coord)
		if hole_right:
			return _pick_reference_coord(pos, reference_vertical_hole_right_coords, wall_atlas_coord)
		return _pick_reference_coord(pos, reference_vertical_wall_coords, wall_atlas_coord)

	if east and west and not north and not south:
		if not hole_below and _should_use_wall_passage_variant(pos):
			return _pick_reference_coord(pos + Vector2i(613, 397), reference_passage_wall_coords, wall_atlas_coord)
		var horizontal_variants := reference_horizontal_hole_bottom_coords if hole_below else reference_horizontal_wall_coords
		return _pick_reference_coord(pos, horizontal_variants, wall_atlas_coord)

	return Vector2i(-1, -1)


func _select_reference_wall_coord_by_stencil(pos: Vector2i) -> Vector2i:
	var stencil := _get_reference_wall_stencil(pos)
	var stencil_groups := _get_reference_stencil_groups()
	var variants: Array = stencil_groups.get(stencil, [])
	if variants.is_empty():
		var relaxed_stencil := _relax_reference_wall_stencil(stencil)
		variants = stencil_groups.get(relaxed_stencil, [])
	if variants.is_empty():
		return Vector2i(-1, -1)
	return _pick_reference_coord(pos, variants, wall_atlas_coord)


func _get_reference_wall_stencil(pos: Vector2i) -> String:
	var rows: Array[String] = []
	for y in range(-1, 2):
		var chars := ""
		for x in range(-1, 2):
			var sample := pos + Vector2i(x, y)
			if _has_wall_cell(sample):
				chars += "W"
			elif _is_void_cell(sample):
				chars += "H"
			else:
				chars += "O"
		rows.append(chars)
	return "/".join(rows)


func _relax_reference_wall_stencil(stencil: String) -> String:
	# Treat holes/edge void on non-wall cells as generic open space for fallback matching.
	# Exact stencil matches still win first, so hole-specific tiles remain available.
	return stencil.replace("H", "O")


func _get_reference_stencil_groups() -> Dictionary:
	return {
		"OWO/OWO/OWO": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
		"OOO/WWW/WWW": [Vector2i(0, 3), Vector2i(2, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(9, 3)],
		"OOO/WWW/OWO": [Vector2i(2, 2)],
		"OOO/OWW/OWW": [Vector2i(1, 0), Vector2i(1, 3), Vector2i(8, 3)],
		"OOO/OWW/OOW": [Vector2i(1, 1), Vector2i(1, 2)],
		"OOO/WWO/WWO": [Vector2i(3, 0)],
		"OOO/WWO/WOO": [Vector2i(3, 1), Vector2i(3, 2)],
		"OWO/WWO/WWO": [Vector2i(3, 3)],
		"OOO/OOW/OWW": [Vector2i(4, 0), Vector2i(7, 0), Vector2i(10, 3)],
		"OOO/OWW/OOH": [Vector2i(4, 1)],
		"OOO/OHW/OHW": [Vector2i(4, 2), Vector2i(4, 3)],
		"OOO/OWW/HWH": [Vector2i(5, 0)],
		"OOH/WHH/WHH": [Vector2i(5, 1), Vector2i(8, 2)],
		"OOH/WWH/WWH": [Vector2i(5, 2)],
		"OOO/WWO/HWH": [Vector2i(6, 0)],
		"HOO/HHW/HHW": [Vector2i(6, 1), Vector2i(11, 1)],
		"HOO/HWW/HWW": [Vector2i(6, 2)],
		"OOO/WWO/HOO": [Vector2i(7, 1)],
		"OOO/WHO/WHO": [Vector2i(7, 2), Vector2i(7, 3), Vector2i(9, 1), Vector2i(10, 2)],
		"OOO/OWH/OWH": [Vector2i(8, 0)],
		"OWH/OWH/OWH": [Vector2i(8, 1)],
		"OOO/WWW/HWH": [Vector2i(9, 0)],
		"HWO/HWO/HWO": [Vector2i(11, 2)],
		"OOO/HWO/HWO": [Vector2i(11, 0)],
		"OOO/WWW/HHH": [Vector2i(10, 0)],
	}


func _select_reference_wall_coord_by_mask(pos: Vector2i) -> Vector2i:
	var north := _has_wall_cell(pos + Vector2i.UP)
	var east := _has_wall_cell(pos + Vector2i.RIGHT)
	var south := _has_wall_cell(pos + Vector2i.DOWN)
	var west := _has_wall_cell(pos + Vector2i.LEFT)
	var mask := _get_reference_wall_mask(north, east, south, west)
	var hole_below := _is_void_cell(pos + Vector2i.DOWN)
	var hole_left := _is_void_cell(pos + Vector2i.LEFT)
	var hole_right := _is_void_cell(pos + Vector2i.RIGHT)

	match mask:
		15:
			var cross_variants := reference_cross_hole_coords if hole_below else reference_cross_wall_coords
			return _pick_reference_coord(pos, cross_variants, wall_atlas_coord)
		13:
			var open_right_t_variants := reference_open_right_hole_coords if hole_left else reference_open_right_t_coords
			return _pick_reference_coord(pos, open_right_t_variants, wall_atlas_coord)
		11:
			var open_right_corner_variants := reference_open_right_hole_coords if hole_left else reference_open_right_corner_coords
			return _pick_reference_coord(pos, open_right_corner_variants, wall_atlas_coord)
		7:
			var open_left_variants := reference_open_left_hole_coords if hole_right else reference_open_left_t_coords
			return _pick_reference_coord(pos, open_left_variants, wall_atlas_coord)
		6:
			return _pick_reference_coord(pos, reference_horizontal_wall_coords, wall_atlas_coord)
		5:
			if hole_left:
				return _pick_reference_coord(pos, reference_vertical_hole_left_coords, wall_atlas_coord)
			if hole_right:
				return _pick_reference_coord(pos, reference_vertical_hole_right_coords, wall_atlas_coord)
			return _pick_reference_coord(pos, reference_vertical_wall_coords, wall_atlas_coord)
		3:
			return _pick_reference_coord(pos, reference_north_east_corner_coords, wall_atlas_coord)
		9:
			return _pick_reference_coord(pos, reference_north_west_corner_coords, wall_atlas_coord)
		12:
			return _pick_reference_coord(pos, reference_horizontal_wall_coords, wall_atlas_coord)
		14:
			return _pick_reference_coord(pos, reference_open_left_t_coords, wall_atlas_coord)
		8:
			return _pick_reference_coord(pos, reference_right_terminal_coords, wall_atlas_coord)
		1, 4:
			return _pick_reference_coord(pos, reference_vertical_wall_coords, wall_atlas_coord)
		2:
			return _pick_reference_coord(pos, reference_left_terminal_coords, wall_atlas_coord)
		10:
			var horizontal_variants := reference_horizontal_hole_bottom_coords if hole_below else reference_horizontal_wall_coords
			return _pick_reference_coord(pos, horizontal_variants, wall_atlas_coord)
		0:
			return wall_atlas_coord
		_:
			var open_right_variants := reference_open_right_hole_coords if hole_left else reference_open_right_wall_coords
			if mask == 13 or mask == 11:
				return _pick_reference_coord(pos, open_right_variants, wall_atlas_coord)
			var open_left_variants := reference_open_left_hole_coords if hole_right else reference_open_left_wall_coords
			if mask == 7:
				return _pick_reference_coord(pos, open_left_variants, wall_atlas_coord)
			if (north and east) or (south and east):
				var left_variants := reference_open_left_hole_coords if hole_right else reference_open_left_wall_coords
				return _pick_reference_coord(pos, left_variants, wall_atlas_coord)
			if (north and west) or (south and west):
				var right_variants := reference_open_right_hole_coords if hole_left else reference_open_right_wall_coords
				return _pick_reference_coord(pos, right_variants, wall_atlas_coord)
			if east or west:
				if east and not west:
					return _pick_reference_coord(pos, reference_left_terminal_coords, wall_atlas_coord)
				if west and not east:
					return _pick_reference_coord(pos, reference_right_terminal_coords, wall_atlas_coord)
				var horizontal_fallback := reference_horizontal_hole_bottom_coords if hole_below else reference_horizontal_wall_coords
				return _pick_reference_coord(pos, horizontal_fallback, wall_atlas_coord)
			if north or south:
				if hole_left:
					return _pick_reference_coord(pos, reference_vertical_hole_left_coords, wall_atlas_coord)
				if hole_right:
					return _pick_reference_coord(pos, reference_vertical_hole_right_coords, wall_atlas_coord)
				return _pick_reference_coord(pos, reference_vertical_wall_coords, wall_atlas_coord)
			return _pick_reference_coord(pos, open_right_variants, wall_atlas_coord)


func _pick_reference_coord(pos: Vector2i, variants: Array, fallback: Vector2i) -> Vector2i:
	if variants.is_empty():
		return fallback
	var typed_variants: Array[Vector2i] = []
	for variant in variants:
		if variant is Vector2i:
			typed_variants.append(variant)
	if typed_variants.is_empty():
		return fallback
	return _pick_variant_coord(pos, typed_variants, fallback)


func _should_use_wall_passage_variant(pos: Vector2i) -> bool:
	if not use_wall_passage_variants or reference_passage_wall_coords.is_empty():
		return false
	if not _is_horizontal_wall_surface(pos):
		return false
	var run := _get_horizontal_wall_surface_run_info(pos)
	var length: int = int(run.get("length", 0))
	if length < wall_passage_min_run_tiles:
		return false
	var start_x: int = int(run.get("start_x", pos.x))
	var index: int = int(run.get("index", 0))
	if index <= 0 or index >= length - 1:
		return false
	var run_key := Vector2i(start_x, pos.y)
	var threshold := int(round(clamp(wall_passage_spawn_chance, 0.0, 1.0) * 1000.0))
	if (_tile_noise_hash(run_key + Vector2i(313, 733)) % 1000) >= threshold:
		return false
	var interior_count: int = maxi(1, length - 2)
	var target_index: int = 1 + (_tile_noise_hash(run_key + Vector2i(719, 421)) % interior_count)
	return index == target_index


func _is_horizontal_wall_surface(pos: Vector2i) -> bool:
	if not _has_wall_cell(pos):
		return false
	if not _is_wall_top_exposed(pos):
		return false
	return _has_wall_cell(pos + Vector2i.LEFT) or _has_wall_cell(pos + Vector2i.RIGHT)


func _get_horizontal_wall_surface_run_info(pos: Vector2i) -> Dictionary:
	var start_x := pos.x
	var end_x := pos.x
	while _is_horizontal_wall_surface(Vector2i(start_x - 1, pos.y)):
		start_x -= 1
	while _is_horizontal_wall_surface(Vector2i(end_x + 1, pos.y)):
		end_x += 1
	return {
		"start_x": start_x,
		"end_x": end_x,
		"length": end_x - start_x + 1,
		"index": pos.x - start_x,
	}


func _get_horizontal_wall_run_info(pos: Vector2i) -> Dictionary:
	var start_x := pos.x
	var end_x := pos.x
	while _is_wall_run_continuation(Vector2i(start_x - 1, pos.y)):
		start_x -= 1
	while _is_wall_run_continuation(Vector2i(end_x + 1, pos.y)):
		end_x += 1
	return {
		"start_x": start_x,
		"end_x": end_x,
		"length": end_x - start_x + 1,
		"index": pos.x - start_x,
	}


func _is_wall_run_continuation(pos: Vector2i) -> bool:
	if not _has_wall_cell(pos):
		return false
	return not _has_wall_cell(pos + Vector2i.UP) and not _has_wall_cell(pos + Vector2i.DOWN)


func _get_reference_wall_mask(north: bool, east: bool, south: bool, west: bool) -> int:
	var mask := 0
	if north:
		mask |= 1
	if east:
		mask |= 2
	if south:
		mask |= 4
	if west:
		mask |= 8
	return mask


func _is_wall_top_exposed(pos: Vector2i) -> bool:
	return not _has_wall_cell(pos + Vector2i.UP)


func _has_wall_cell(pos: Vector2i) -> bool:
	return walls_tilemap != null and walls_tilemap.get_cell_source_id(pos) >= 0


func _has_generated_wall_cell(pos: Vector2i) -> bool:
	if _generated_wall_cells.has(pos):
		return true
	return _has_wall_cell(pos)


func _is_void_cell(pos: Vector2i) -> bool:
	if procgen_node == null:
		return true
	if pos.x < 0 or pos.y < 0 or pos.x >= procgen_node.map_size.x or pos.y >= procgen_node.map_size.y:
		return true
	if is_hole_tile(pos):
		return true
	return not _has_wall_cell(pos) and (floor_tilemap == null or floor_tilemap.get_cell_source_id(pos) < 0)


func _apply_compound_layout(map_size: Vector2i) -> void:
	var compound := _build_compound_layout(map_size)
	var rect: Rect2i = compound.get("rect", Rect2i()) as Rect2i
	var ingress: Array[Vector2i] = compound.get("ingress", []) as Array[Vector2i]
	var buildings: Array[Rect2i] = compound.get("buildings", []) as Array[Rect2i]
	if rect.size.x <= 0 or rect.size.y <= 0:
		_last_compound_rect = Rect2i()
		_last_compound_ingress.clear()
		_last_compound_buildings.clear()
		return

	_last_compound_rect = rect
	_last_compound_ingress = ingress.duplicate()
	_last_compound_buildings = buildings.duplicate()

	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			_set_floor_tile(Vector2i(x, y))

	var ingress_set := {}
	for tile in ingress:
		ingress_set[tile] = true

	var t: int = max(1, compound_wall_thickness)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.position.y + t):
			var top_tile := Vector2i(x, y)
			if not ingress_set.has(top_tile):
				_set_wall_tile(top_tile)
		for y in range(rect.end.y - t, rect.end.y):
			var bottom_tile := Vector2i(x, y)
			if not ingress_set.has(bottom_tile):
				_set_wall_tile(bottom_tile)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.position.x + t):
			var left_tile := Vector2i(x, y)
			if not ingress_set.has(left_tile):
				_set_wall_tile(left_tile)
		for x in range(rect.end.x - t, rect.end.x):
			var right_tile := Vector2i(x, y)
			if not ingress_set.has(right_tile):
				_set_wall_tile(right_tile)
	for tile in ingress:
		_carve_compound_ingress(tile, rect, t)

	for b in buildings:
		for x in range(b.position.x, b.end.x):
			for y in range(b.position.y, b.end.y):
				_set_wall_tile(Vector2i(x, y))
		var center := b.get_center()
		var door := Vector2i(int(center.x), b.position.y)
		_set_floor_tile(door)
		_set_floor_tile(door + Vector2i(0, -1))

	_seal_unreachable_compound_pockets(rect, ingress)


func _build_compound_layout(map_size: Vector2i) -> Dictionary:
	var target_area := int(round(float(map_size.x * map_size.y) * compound_area_ratio))
	var aspect := 1.25 + float(_tile_noise_hash(Vector2i(7, 19)) % 40) / 100.0
	var width := int(round(sqrt(float(target_area) * aspect)))
	var height := int(round(float(target_area) / max(1.0, float(width))))
	width = clamp(width, compound_min_size.x, compound_max_size.x)
	height = clamp(height, compound_min_size.y, compound_max_size.y)
	width = min(width, map_size.x - 4)
	height = min(height, map_size.y - 4)

	var jitter_x := int((float(_tile_noise_hash(Vector2i(3, 5)) % 100) / 100.0 - 0.5) * 8.0)
	var jitter_y := int((float(_tile_noise_hash(Vector2i(11, 13)) % 100) / 100.0 - 0.5) * 8.0)
	var start_x: int = clamp(int(map_size.x / 2) - int(width / 2) + jitter_x, 2, map_size.x - width - 2)
	var start_y: int = clamp(int(map_size.y / 2) - int(height / 2) + jitter_y, 2, map_size.y - height - 2)
	var rect := Rect2i(start_x, start_y, width, height)

	var ingress: Array[Vector2i] = []
	var side_count: int = max(2, compound_ingress_count)
	for i in range(side_count):
		var side: int = i % 4
		var side_span: int = width if side < 2 else height
		var offset: int = 2 + (_tile_noise_hash(Vector2i(41 + i * 3, 53 + i * 5)) % max(4, side_span - 4))
		match side:
			0:
				ingress.append(Vector2i(rect.position.x + offset, rect.position.y))
			1:
				ingress.append(Vector2i(rect.position.x + offset, rect.end.y - 1))
			2:
				ingress.append(Vector2i(rect.position.x, rect.position.y + offset))
			_:
				ingress.append(Vector2i(rect.end.x - 1, rect.position.y + offset))

	var buildings: Array[Rect2i] = []
	var inner: Rect2i = rect.grow(-max(3, compound_wall_thickness + 1))
	var cols: int = 2
	var rows: int = int(ceil(float(compound_building_count) / float(cols)))
	var slot_w: int = max(6, int(inner.size.x / cols))
	var slot_h: int = max(6, int(inner.size.y / max(1, rows)))
	var presets: Array[Vector2i] = [
		Vector2i(12, 9), # command-like
		Vector2i(9, 7),  # power-like
		Vector2i(10, 7), # defense-like
		Vector2i(8, 6),  # storage-like
		Vector2i(9, 6),  # fabrication-like
	]
	for i in range(compound_building_count):
		var col: int = i % cols
		var row: int = int(i / cols)
		var preset: Vector2i = presets[i % presets.size()]
		var bw: int = clamp(preset.x, 4, slot_w - 2)
		var bh: int = clamp(preset.y, 4, slot_h - 2)
		var sx: int = inner.position.x + col * slot_w + int((slot_w - bw) * 0.5)
		var sy: int = inner.position.y + row * slot_h + int((slot_h - bh) * 0.5)
		var brect := Rect2i(sx, sy, bw, bh)
		if inner.encloses(brect):
			buildings.append(brect)

	return {
		"rect": rect,
		"ingress": ingress,
		"buildings": buildings,
	}


func _carve_compound_ingress(ingress: Vector2i, rect: Rect2i, wall_thickness: int) -> void:
	var inward := Vector2i.ZERO
	var outward := Vector2i.ZERO
	if ingress.y <= rect.position.y:
		inward = Vector2i.DOWN
		outward = Vector2i.UP
	elif ingress.y >= rect.end.y - 1:
		inward = Vector2i.UP
		outward = Vector2i.DOWN
	elif ingress.x <= rect.position.x:
		inward = Vector2i.RIGHT
		outward = Vector2i.LEFT
	else:
		inward = Vector2i.LEFT
		outward = Vector2i.RIGHT

	var carve_depth: int = max(2, wall_thickness + 1)
	for step in range(carve_depth):
		_set_floor_tile(ingress + inward * step)
	_set_floor_tile(ingress + outward)


func _seal_unreachable_compound_pockets(rect: Rect2i, ingress_tiles: Array[Vector2i]) -> void:
	var frontier: Array[Vector2i] = []
	var visited: Dictionary = {}
	for ingress in ingress_tiles:
		var inward := _get_compound_ingress_inward(ingress, rect)
		for depth in range(1, max(2, compound_wall_thickness + 2)):
			var probe := ingress + inward * depth
			if not rect.has_point(probe):
				continue
			if not _is_floor_like_tile(probe):
				continue
			frontier.append(probe)
			visited[probe] = true
	if frontier.is_empty():
		var center := Vector2i(rect.get_center())
		if rect.has_point(center) and _is_floor_like_tile(center):
			frontier.append(center)
			visited[center] = true

	var index := 0
	while index < frontier.size():
		var current := frontier[index]
		index += 1
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next_tile: Vector2i = current + offset
			if not rect.has_point(next_tile):
				continue
			if visited.has(next_tile) or not _is_floor_like_tile(next_tile):
				continue
			visited[next_tile] = true
			frontier.append(next_tile)

	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var tile := Vector2i(x, y)
			if not _is_floor_like_tile(tile):
				continue
			if visited.has(tile):
				continue
			_set_hole_tile(tile)


func _get_compound_ingress_inward(ingress: Vector2i, rect: Rect2i) -> Vector2i:
	if ingress.y <= rect.position.y:
		return Vector2i.DOWN
	if ingress.y >= rect.end.y - 1:
		return Vector2i.UP
	if ingress.x <= rect.position.x:
		return Vector2i.RIGHT
	return Vector2i.LEFT


func _apply_constructed_interior_region(map_size: Vector2i) -> void:
	var rect := _build_constructed_interior_rect(map_size)
	if rect.size.x <= 0 or rect.size.y <= 0:
		_last_interior_region_rect = Rect2i()
		_last_interior_rooms.clear()
		_last_interior_thresholds.clear()
		return

	_last_interior_region_rect = rect
	_last_interior_rooms.clear()
	_last_interior_thresholds.clear()

	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
				var tile := Vector2i(x, y)
				_set_interior_wall_tile(tile)
				_set_region_tile(tile, "interior_wall", "military_complex")

	var hall_width: int = clampi(interior_region_hallway_width, 1, max(1, rect.size.y - 4))
	var hall_start_y: int = rect.position.y + int(rect.size.y * 0.5) - int(hall_width * 0.5)
	var hall_rect := Rect2i(
		rect.position.x + 1,
		hall_start_y,
		max(1, rect.size.x - 2),
		hall_width
	)
	_carve_interior_floor_rect(hall_rect, "hallway")

	var rooms := _build_constructed_interior_rooms(rect, hall_rect)
	for room in rooms:
		_carve_interior_floor_rect(room, "room")
		_last_interior_rooms.append(room)

	var bay := _build_constructed_interior_bay(rect, hall_rect)
	if bay.size.x > 0 and bay.size.y > 0:
		_carve_interior_floor_rect(bay, "warehouse_bay")
		_last_interior_rooms.append(bay)

	_carve_constructed_interior_thresholds(rect, hall_rect)
	if interior_region_debug_logging:
		print("[InteriorRegion] Built rect=%s rooms=%d thresholds=%d" % [
			str(rect),
			_last_interior_rooms.size(),
			_last_interior_thresholds.size(),
		])


func _build_constructed_interior_rect(map_size: Vector2i) -> Rect2i:
	if map_size.x < interior_region_min_size.x + 6 or map_size.y < interior_region_min_size.y + 6:
		return Rect2i()

	var min_size := interior_region_min_size.maxi(8)
	var max_size := Vector2i(
		maxi(min_size.x, mini(interior_region_max_size.x, map_size.x - 6)),
		maxi(min_size.y, mini(interior_region_max_size.y, map_size.y - 6))
	)
	var width := _hash_range(Vector2i(223, 151), min_size.x, max_size.x)
	var height := _hash_range(Vector2i(331, 197), min_size.y, max_size.y)
	var margin := 3

	if _last_compound_rect.size.x > 0 and _last_compound_rect.size.y > 0:
		var side := _tile_noise_hash(Vector2i(401, 509)) % 4
		match side:
			0:
				return _clamped_rect(
					Vector2i(_last_compound_rect.end.x + 2, _last_compound_rect.position.y + int((_last_compound_rect.size.y - height) * 0.5)),
					Vector2i(width, height),
					map_size,
					margin
				)
			1:
				return _clamped_rect(
					Vector2i(_last_compound_rect.position.x - width - 2, _last_compound_rect.position.y + int((_last_compound_rect.size.y - height) * 0.5)),
					Vector2i(width, height),
					map_size,
					margin
				)
			2:
				return _clamped_rect(
					Vector2i(_last_compound_rect.position.x + int((_last_compound_rect.size.x - width) * 0.5), _last_compound_rect.end.y + 2),
					Vector2i(width, height),
					map_size,
					margin
				)
			_:
				return _clamped_rect(
					Vector2i(_last_compound_rect.position.x + int((_last_compound_rect.size.x - width) * 0.5), _last_compound_rect.position.y - height - 2),
					Vector2i(width, height),
					map_size,
					margin
				)

	var x := int(map_size.x * 0.58) + _hash_range(Vector2i(419, 37), -8, 8)
	var y := int(map_size.y * 0.44) + _hash_range(Vector2i(43, 421), -8, 8)
	return _clamped_rect(Vector2i(x, y), Vector2i(width, height), map_size, margin)


func _clamped_rect(origin: Vector2i, size: Vector2i, map_size: Vector2i, margin: int) -> Rect2i:
	var max_x: int = max(margin, map_size.x - size.x - margin)
	var max_y: int = max(margin, map_size.y - size.y - margin)
	return Rect2i(
		clampi(origin.x, margin, max_x),
		clampi(origin.y, margin, max_y),
		size.x,
		size.y
	)


func _hash_range(token: Vector2i, min_value: int, max_value: int) -> int:
	if max_value <= min_value:
		return min_value
	return min_value + (_tile_noise_hash(token) % (max_value - min_value + 1))


func _build_constructed_interior_rooms(region_rect: Rect2i, hall_rect: Rect2i) -> Array[Rect2i]:
	var rooms: Array[Rect2i] = []
	var count: int = max(1, interior_region_room_count)
	var slots_per_side: int = int(ceil(float(count) * 0.5))
	var usable_width: int = max(1, region_rect.size.x - 4)
	var slot_width: int = max(4, int(usable_width / max(1, slots_per_side)))

	for i in range(count):
		var top_side := i % 2 == 0
		var slot_index := int(i * 0.5)
		var room_w: int = clampi(5 + (_tile_noise_hash(Vector2i(503 + i * 11, 607)) % 6), 4, max(4, slot_width - 1))
		var max_room_h: int
		var room_y: int
		if top_side:
			max_room_h = max(3, hall_rect.position.y - region_rect.position.y - 2)
			var room_h: int = clampi(4 + (_tile_noise_hash(Vector2i(557 + i * 17, 619)) % 5), 3, max_room_h)
			room_y = hall_rect.position.y - room_h
			var room_x := region_rect.position.x + 2 + slot_index * slot_width + int((slot_width - room_w) * 0.5)
			rooms.append(_clamp_rect_inside(Rect2i(room_x, room_y, room_w, room_h), region_rect.grow(-1)))
		else:
			max_room_h = max(3, region_rect.end.y - hall_rect.end.y - 2)
			var room_h: int = clampi(4 + (_tile_noise_hash(Vector2i(563 + i * 17, 631)) % 5), 3, max_room_h)
			room_y = hall_rect.end.y
			var room_x := region_rect.position.x + 2 + slot_index * slot_width + int((slot_width - room_w) * 0.5)
			rooms.append(_clamp_rect_inside(Rect2i(room_x, room_y, room_w, room_h), region_rect.grow(-1)))

	return rooms


func _build_constructed_interior_bay(region_rect: Rect2i, hall_rect: Rect2i) -> Rect2i:
	var bay_w: int = clampi(int(region_rect.size.x * 0.30), 7, max(7, region_rect.size.x - 4))
	var bay_h: int = clampi(int(region_rect.size.y * 0.34), 5, max(5, region_rect.size.y - 4))
	var right_side := (_tile_noise_hash(Vector2i(673, 701)) % 2) == 0
	var bay_x := region_rect.end.x - bay_w - 2 if right_side else region_rect.position.x + 2
	var bay_y := hall_rect.end.y
	if bay_y + bay_h >= region_rect.end.y - 1:
		bay_y = hall_rect.position.y - bay_h
	return _clamp_rect_inside(Rect2i(bay_x, bay_y, bay_w, bay_h), region_rect.grow(-1))


func _clamp_rect_inside(rect: Rect2i, bounds: Rect2i) -> Rect2i:
	var width: int = mini(rect.size.x, bounds.size.x)
	var height: int = mini(rect.size.y, bounds.size.y)
	var max_x: int = bounds.end.x - width
	var max_y: int = bounds.end.y - height
	return Rect2i(
		clampi(rect.position.x, bounds.position.x, max_x),
		clampi(rect.position.y, bounds.position.y, max_y),
		width,
		height
	)


func _carve_interior_floor_rect(rect: Rect2i, zone: String) -> void:
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
				var tile := Vector2i(x, y)
				_set_interior_floor_tile(tile, zone)
				_set_region_tile(tile, "interior_floor", zone)


func _carve_constructed_interior_thresholds(region_rect: Rect2i, hall_rect: Rect2i) -> void:
	var entrance_count: int = max(1, interior_region_entrance_count)
	var candidates: Array[Vector2i] = [
		Vector2i(region_rect.position.x, hall_rect.position.y + int(hall_rect.size.y * 0.5)),
		Vector2i(region_rect.end.x - 1, hall_rect.position.y + int(hall_rect.size.y * 0.5)),
	]
	for i in range(mini(entrance_count, candidates.size())):
		var candidate_index := (i + (_tile_noise_hash(Vector2i(809, 877)) % candidates.size())) % candidates.size()
		var edge_tile := candidates[candidate_index]
		_carve_constructed_interior_threshold(edge_tile, region_rect)


func _carve_constructed_interior_threshold(edge_tile: Vector2i, region_rect: Rect2i) -> void:
	var outward := Vector2i.ZERO
	if edge_tile.x <= region_rect.position.x:
		outward = Vector2i.LEFT
	elif edge_tile.x >= region_rect.end.x - 1:
		outward = Vector2i.RIGHT
	elif edge_tile.y <= region_rect.position.y:
		outward = Vector2i.UP
	else:
		outward = Vector2i.DOWN
	var inward := -outward
	for step in range(3):
		var tile := edge_tile + inward * step
		if region_rect.has_point(tile):
			_set_interior_floor_tile(tile, "doorway")
			_set_region_tile(tile, "interior_threshold", "doorway")
	for step in range(1, 5):
		var exterior_tile := edge_tile + outward * step
		if procgen_node == null:
			break
		if exterior_tile.x < 1 or exterior_tile.y < 1 or exterior_tile.x >= procgen_node.map_size.x - 1 or exterior_tile.y >= procgen_node.map_size.y - 1:
			break
		_set_floor_tile(exterior_tile)
		_set_region_tile(exterior_tile, "exterior_threshold", "doorway")
	_last_interior_thresholds.append(edge_tile)


func _clear_region_metadata() -> void:
	_last_interior_region_rect = Rect2i()
	_last_interior_rooms.clear()
	_last_interior_thresholds.clear()
	_region_tiles.clear()


func _set_region_tile(tile: Vector2i, region_type: String, zone: String) -> void:
	_region_tiles[tile] = {
		"region_type": region_type,
		"zone": zone,
	}


func get_region_type_at_tile(tile: Vector2i) -> String:
	var data: Variant = _region_tiles.get(tile, {})
	if data is Dictionary:
		return String((data as Dictionary).get("region_type", "exterior"))
	return "exterior"


func get_region_data_at_tile(tile: Vector2i) -> Dictionary:
	var data: Variant = _region_tiles.get(tile, {})
	if data is Dictionary:
		return (data as Dictionary).duplicate(true)
	return {
		"region_type": "exterior",
		"zone": "natural",
	}


func is_indoor_tile(tile: Vector2i) -> bool:
	var region_type := get_region_type_at_tile(tile)
	return region_type == "interior_floor" or region_type == "interior_wall" or region_type == "interior_threshold"


func _rebuild_runtime_wall_collision(map_size: Vector2i) -> void:
	var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision") as Node2D
	if collision_root == null:
		collision_root = Node2D.new()
		collision_root.name = "RuntimeWallCollision"
		walls_tilemap.add_child(collision_root)

	_clear_runtime_wall_collision()

	var tile_size: Vector2 = Vector2(16, 16)
	if walls_tilemap.tile_set != null:
		tile_size = Vector2(walls_tilemap.tile_set.tile_size)

	for y in range(map_size.y):
		for x in range(map_size.x):
			var pos := Vector2i(x, y)
			var src := walls_tilemap.get_cell_source_id(pos)
			if src < 0:
				continue
			_spawn_runtime_wall_body(pos, false)
	_rebuild_runtime_wall_collision_debug()


func _is_floor_like_tile(pos: Vector2i) -> bool:
	return floor_tilemap != null and floor_tilemap.get_cell_source_id(pos) >= 0 and not is_hole_tile(pos)


func is_hole_tile(pos: Vector2i) -> bool:
	if floor_tilemap == null:
		return false
	if floor_tilemap.get_cell_source_id(pos) < 0:
		return false
	return floor_tilemap.get_cell_atlas_coords(pos) == full_hole_floor_atlas_coord


func _set_hole_tile(pos: Vector2i) -> void:
	floor_tilemap.set_cell(pos, floor_source_id, full_hole_floor_atlas_coord)
	walls_tilemap.erase_cell(pos)
	_wall_health.erase(pos)


func damage_wall_tile(pos: Vector2i, amount: float, attacker_team: String = "") -> Dictionary:
	if walls_tilemap == null or walls_tilemap.get_cell_source_id(pos) < 0:
		return {
			"blocked": false,
			"destroyed": false,
			"remaining_health": 0.0,
		}

	var current_health: float = float(_wall_health.get(pos, wall_tile_max_health))
	current_health = max(0.0, current_health - max(0.0, amount))
	_wall_health[pos] = current_health

	if current_health > 0.0:
		return {
			"blocked": false,
			"destroyed": false,
			"remaining_health": current_health,
			"attacker_team": attacker_team,
		}

	_generated_wall_cells.erase(pos)
	_generated_floor_cells[pos] = {
		"source_id": _select_floor_source_id(pos),
		"atlas": _select_floor_coord(pos),
	}
	_set_floor_tile(pos)
	minimap_tile_changed.emit(pos, "floor")
	_refresh_wall_neighbors(pos)
	_rebuild_horizontal_wall_overlays()
	_refresh_shadows()
	if build_runtime_wall_collision:
		_remove_runtime_wall_body(pos)
	_refresh_navigation_after_wall_change()
	return {
		"blocked": false,
		"destroyed": true,
		"remaining_health": 0.0,
		"attacker_team": attacker_team,
	}


func damage_wall_at_global(global_position: Vector2, amount: float, attacker_team: String = "") -> Dictionary:
	if walls_tilemap == null:
		return {}
	var tile := walls_tilemap.local_to_map(walls_tilemap.to_local(global_position))
	return damage_wall_tile(tile, amount, attacker_team)


func _refresh_wall_neighbors(center_tile: Vector2i) -> void:
	for x in range(center_tile.x - 1, center_tile.x + 2):
		for y in range(center_tile.y - 1, center_tile.y + 2):
			var pos := Vector2i(x, y)
			if walls_tilemap.get_cell_source_id(pos) < 0:
				continue
			var source = high_walls_source_id if use_high_walls else walls_source_id
			walls_tilemap.set_cell(pos, source, _select_wall_coord(pos))


func _refresh_navigation_after_wall_change(force_immediate: bool = false) -> void:
	if not force_immediate and enable_streaming_reveal and not _streaming_reveal_queue.is_empty():
		_navigation_rebuild_pending = true
		return
	_queue_navigation_rebuild()


func _queue_navigation_rebuild() -> void:
	if _navigation_rebuild_deferred:
		return
	_navigation_rebuild_deferred = true
	call_deferred("_flush_navigation_rebuild")


func _flush_navigation_rebuild() -> void:
	_navigation_rebuild_deferred = false
	_navigation_rebuild_pending = false
	for navigation_node in get_tree().get_nodes_in_group("navigation"):
		if navigation_node != null and navigation_node.has_method("rebuild"):
			navigation_node.call("rebuild")


func _capture_generated_tile_state(map_size: Vector2i) -> void:
	_generated_floor_cells.clear()
	_generated_wall_cells.clear()
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos := Vector2i(x, y)
			var floor_source := floor_tilemap.get_cell_source_id(pos)
			if floor_source >= 0:
				_generated_floor_cells[pos] = {
					"source_id": floor_source,
					"atlas": floor_tilemap.get_cell_atlas_coords(pos),
					"alternative": floor_tilemap.get_cell_alternative_tile(pos),
				}
			var wall_source := walls_tilemap.get_cell_source_id(pos)
			if wall_source >= 0:
				_generated_wall_cells[pos] = {
					"source_id": wall_source,
					"atlas": walls_tilemap.get_cell_atlas_coords(pos),
					"alternative": walls_tilemap.get_cell_alternative_tile(pos),
				}

	_generate_foliage(map_size)
	_generate_ruin_props(map_size)
	_generate_interior_props(map_size)


func _generate_foliage(map_size: Vector2i) -> void:
	if _foliage_parent == null:
		push_warning("[Foliage] Missing FoliageLayer, skipping foliage spawn")
		return
	_clear_foliage()
	if _foliage_textures.is_empty():
		push_warning("[Foliage] No foliage textures loaded, skipping foliage spawn")
		return
	if enable_streaming_reveal:
		if foliage_debug_logging:
			print("[Foliage] Streaming reveal active; foliage will spawn during tile reveal")
		return

	var placed := 0
	for pos in _generated_floor_cells.keys():
		if _should_place_foliage(pos):
			_place_foliage(pos)
			placed += 1
	if foliage_debug_logging:
		print("[Foliage] Placed %d sprites under %s" % [placed, _foliage_parent.get_path()])


func _clear_foliage() -> void:
	for entry in _foliage_nodes.values():
		var node: Node = null
		if entry is Dictionary:
			node = entry.get("node", null) as Node
		elif entry is Node:
			node = entry as Node
		if is_instance_valid(node):
			node.queue_free()
	_foliage_nodes.clear()
	
	# Clear fruit sprites too
	for sprite in _fruit_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_fruit_sprites.clear()


func _generate_ruin_props(map_size: Vector2i) -> void:
	_clear_ruin_props()
	if not enable_ruin_prop_spawning:
		return
	if _ruin_prop_parent == null:
		if ruin_prop_debug_logging:
			push_warning("[RuinProps] Missing PropLayer, skipping ruin prop spawn")
		return
	if ruin_prop_scene == null or ruin_prop_spawn_set == null or ruin_prop_count <= 0:
		return

	var candidate_tiles: Array[Vector2i] = []
	for tile_variant in _generated_floor_cells.keys():
		var tile := tile_variant as Vector2i
		if _should_place_ruin_prop(tile, map_size):
			candidate_tiles.append(tile)

	if candidate_tiles.is_empty():
		if ruin_prop_debug_logging:
			print("[RuinProps] No valid prop candidate tiles")
		return

	_ruin_prop_scatterer = PROP_SCATTERER_SCRIPT.new() as PropScatterer
	if _ruin_prop_scatterer == null:
		push_warning("[RuinProps] Failed to create PropScatterer")
		return
	_ruin_prop_scatterer.name = "RuinPropScatterer"
	_ruin_prop_scatterer.prop_scene = ruin_prop_scene
	_ruin_prop_scatterer.spawn_set = ruin_prop_spawn_set
	_ruin_prop_scatterer.count = ruin_prop_count
	_ruin_prop_scatterer.min_distance_tiles = ruin_prop_min_distance_tiles
	_ruin_prop_scatterer.seed = _tile_noise_hash(Vector2i(97, 211))
	_ruin_prop_scatterer.variant_intensity = ruin_prop_variant_intensity
	_ruin_prop_parent.add_child(_ruin_prop_scatterer)

	var spawned := _ruin_prop_scatterer.scatter_on_tiles(candidate_tiles, Callable(self, "_ruin_prop_tile_to_world"))
	if ruin_prop_debug_logging:
		print("[RuinProps] Placed %d props under %s" % [spawned.size(), _ruin_prop_parent.get_path()])


func _clear_ruin_props() -> void:
	if _ruin_prop_scatterer != null and is_instance_valid(_ruin_prop_scatterer):
		_ruin_prop_scatterer.queue_free()
	_ruin_prop_scatterer = null
	if _ruin_prop_parent == null:
		return
	for child in _ruin_prop_parent.get_children():
		child.queue_free()


func _should_place_ruin_prop(pos: Vector2i, map_size: Vector2i) -> bool:
	if pos.x <= 1 or pos.y <= 1 or pos.x >= map_size.x - 2 or pos.y >= map_size.y - 2:
		return false
	if is_indoor_tile(pos):
		return false
	if _is_near_indoor_tile(pos, ruin_prop_indoor_clearance_tiles):
		return false
	if _is_near_wall_for_ruin_prop(pos):
		return false
	if _is_inside_ruin_prop_clearance(pos):
		return false
	if _foliage_nodes.has(pos):
		return false
	return true


func _is_near_wall_for_ruin_prop(pos: Vector2i) -> bool:
	if ruin_prop_wall_clearance_tiles <= 0:
		return false
	for x in range(-ruin_prop_wall_clearance_tiles, ruin_prop_wall_clearance_tiles + 1):
		for y in range(-ruin_prop_wall_clearance_tiles, ruin_prop_wall_clearance_tiles + 1):
			if _generated_wall_cells.has(pos + Vector2i(x, y)):
				return true
	return false


func _is_inside_ruin_prop_clearance(pos: Vector2i) -> bool:
	if ruin_prop_spawn_clearance_radius > 0:
		var spawn_tile := get_player_spawn()
		if abs(pos.x - spawn_tile.x) <= ruin_prop_spawn_clearance_radius and abs(pos.y - spawn_tile.y) <= ruin_prop_spawn_clearance_radius:
			return true
	for building in _last_compound_buildings:
		var expanded := building.grow(ruin_prop_compound_building_clearance)
		if expanded.has_point(pos):
			return true
	return false


func _ruin_prop_tile_to_world(pos: Vector2i) -> Vector2:
	return _tile_to_world_position(pos) + _ruin_prop_jitter(pos)


func _ruin_prop_jitter(pos: Vector2i) -> Vector2:
	var seed := _tile_noise_hash(pos + Vector2i(53, 89))
	var x_unit := float(seed % 21) - 10.0
	var y_unit := float((seed / 21) % 11) - 5.0
	return Vector2(
		x_unit / 10.0 * ruin_prop_jitter_amplitude.x,
		y_unit / 5.0 * ruin_prop_jitter_amplitude.y
	).round()


func _generate_interior_props(map_size: Vector2i) -> void:
	_clear_interior_props()
	if not interior_prop_spawning_enabled or interior_prop_count <= 0:
		return
	if _ruin_prop_parent == null:
		if interior_prop_debug_logging:
			push_warning("[InteriorProps] Missing PropLayer, skipping interior props")
		return
	if _interior_prop_textures.is_empty():
		if interior_prop_debug_logging:
			print("[InteriorProps] No props_*.png textures found in %s" % INTERIOR_RUNTIME_DIR)
		return

	var candidate_tiles: Array[Vector2i] = []
	for tile_variant in _generated_floor_cells.keys():
		var tile := tile_variant as Vector2i
		if _should_place_interior_prop(tile, map_size):
			candidate_tiles.append(tile)
	candidate_tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _tile_noise_hash(a + Vector2i(1501, 271)) < _tile_noise_hash(b + Vector2i(1501, 271))
	)

	var placed_tiles: Array[Vector2i] = []
	for tile in candidate_tiles:
		if _interior_prop_nodes.size() >= interior_prop_count:
			break
		if not _is_far_enough_from_tiles(tile, placed_tiles, interior_prop_min_distance_tiles):
			continue
		_place_interior_prop(tile)
		placed_tiles.append(tile)

	if interior_prop_debug_logging:
		print("[InteriorProps] Placed %d props under %s" % [_interior_prop_nodes.size(), _ruin_prop_parent.get_path()])


func _clear_interior_props() -> void:
	for node in _interior_prop_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_interior_prop_nodes.clear()
	if _ruin_prop_parent == null:
		return
	for child in _ruin_prop_parent.get_children():
		if child.is_in_group("interior_runtime_props"):
			child.queue_free()


func _should_place_interior_prop(pos: Vector2i, map_size: Vector2i) -> bool:
	if pos.x <= 1 or pos.y <= 1 or pos.x >= map_size.x - 2 or pos.y >= map_size.y - 2:
		return false
	if get_region_type_at_tile(pos) != "interior_floor":
		return false
	if _is_near_region_type(pos, "interior_threshold", interior_prop_threshold_clearance_tiles):
		return false
	if _is_near_wall_for_interior_prop(pos):
		return false
	return true


func _is_near_wall_for_interior_prop(pos: Vector2i) -> bool:
	if interior_prop_wall_clearance_tiles <= 0:
		return false
	for x in range(-interior_prop_wall_clearance_tiles, interior_prop_wall_clearance_tiles + 1):
		for y in range(-interior_prop_wall_clearance_tiles, interior_prop_wall_clearance_tiles + 1):
			if _generated_wall_cells.has(pos + Vector2i(x, y)):
				return true
	return false


func _is_near_region_type(pos: Vector2i, region_type: String, clearance_tiles: int) -> bool:
	if clearance_tiles <= 0:
		return false
	for x in range(-clearance_tiles, clearance_tiles + 1):
		for y in range(-clearance_tiles, clearance_tiles + 1):
			if get_region_type_at_tile(pos + Vector2i(x, y)) == region_type:
				return true
	return false


func _is_far_enough_from_tiles(tile: Vector2i, placed_tiles: Array[Vector2i], min_distance_tiles: int) -> bool:
	for placed in placed_tiles:
		if tile.distance_to(placed) < float(min_distance_tiles):
			return false
	return true


func _place_interior_prop(pos: Vector2i) -> void:
	if _interior_prop_textures.is_empty() or _ruin_prop_parent == null:
		return
	var texture_index := _tile_noise_hash(pos + Vector2i(383, 1597)) % _interior_prop_textures.size()
	var texture := _interior_prop_textures[texture_index]
	if texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.name = "InteriorProp_%s_%s" % [pos.x, pos.y]
	sprite.texture = texture
	sprite.centered = true
	sprite.z_as_relative = true
	sprite.z_index = 1
	if interior_prop_allow_flip_h:
		sprite.flip_h = (_tile_noise_hash(pos + Vector2i(719, 1223)) % 2) == 0
	var texture_size := texture.get_size()
	var base_offset := Vector2(0, -texture_size.y * 0.5 + _get_tile_size().y * 0.5)
	sprite.add_to_group("interior_runtime_props")
	_ruin_prop_parent.add_child(sprite)
	sprite.global_position = _tile_to_world_position(pos) + base_offset + _interior_prop_jitter(pos)
	_interior_prop_nodes.append(sprite)


func _interior_prop_jitter(pos: Vector2i) -> Vector2:
	var seed := _tile_noise_hash(pos + Vector2i(991, 467))
	var x_unit := float(seed % 21) - 10.0
	var y_unit := float((seed / 21) % 11) - 5.0
	return Vector2(
		x_unit / 10.0 * interior_prop_jitter_amplitude.x,
		y_unit / 5.0 * interior_prop_jitter_amplitude.y
	).round()


func _remove_foliage(pos: Vector2i) -> void:
	var entry = _foliage_nodes.get(pos, null)
	var node := entry as Node2D
	if entry is Dictionary:
		node = entry.get("node", null) as Node2D
	if node != null and is_instance_valid(node):
		node.queue_free()
	_foliage_nodes.erase(pos)


func _should_place_foliage(pos: Vector2i) -> bool:
	if foliage_density <= 0.0:
		return false
	if is_indoor_tile(pos):
		return false
	if _is_near_indoor_tile(pos, foliage_indoor_clearance_tiles):
		return false
	if _is_near_wall(pos):
		return false
	if _is_inside_foliage_clearance(pos):
		return false
	return _would_place_foliage_at(pos)


func _is_near_wall(pos: Vector2i) -> bool:
	if _generated_wall_cells.is_empty():
		return false
	for x in range(-foliage_min_wall_distance, foliage_min_wall_distance + 1):
		for y in range(-foliage_min_wall_distance, foliage_min_wall_distance + 1):
			if _generated_wall_cells.has(pos + Vector2i(x, y)):
				return true
	return false


func _is_inside_foliage_clearance(pos: Vector2i) -> bool:
	if foliage_spawn_clearance_radius > 0:
		var spawn_tile := get_player_spawn()
		if abs(pos.x - spawn_tile.x) <= foliage_spawn_clearance_radius and abs(pos.y - spawn_tile.y) <= foliage_spawn_clearance_radius:
			return true
	for building in _last_compound_buildings:
		var expanded := building.grow(foliage_compound_building_clearance)
		if expanded.has_point(pos):
			return true
	return false


func _is_near_indoor_tile(pos: Vector2i, clearance_tiles: int) -> bool:
	if clearance_tiles <= 0:
		return false
	if _region_tiles.is_empty():
		return false
	for x in range(-clearance_tiles, clearance_tiles + 1):
		for y in range(-clearance_tiles, clearance_tiles + 1):
			if is_indoor_tile(pos + Vector2i(x, y)):
				return true
	return false


func _is_inside_compound_zone(pos: Vector2i) -> bool:
	return _last_compound_rect.size.x > 0 and _last_compound_rect.size.y > 0 and _last_compound_rect.has_point(pos)


func _place_foliage(pos: Vector2i) -> void:
	if _foliage_parent == null or _foliage_nodes.has(pos):
		return
	var texture := _pick_foliage_texture(pos)
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.modulate = _get_planet_profile_color("foliage_tint", Color.WHITE)
	var world_pos := _tile_to_world_position(pos) + _foliage_jitter(pos)
	sprite.position = _foliage_parent.to_local(world_pos)
	sprite.z_index = foliage_behind_z_index
	sprite.z_as_relative = false
	var material := ShaderMaterial.new()
	material.shader = FOLIAGE_OCCLUSION_SHADER
	material.set_shader_parameter("bubble_radius", foliage_player_occlusion_radius)
	material.set_shader_parameter("bubble_softness", foliage_player_occlusion_softness)
	material.set_shader_parameter("bubble_alpha", foliage_player_occlusion_alpha)
	material.set_shader_parameter("bubble_enabled", false)
	material.set_shader_parameter("bubble_count", 0)
	for bubble_index in range(FOLIAGE_OCCLUSION_MAX_SHADER_BUBBLES):
		material.set_shader_parameter("bubble_center_%d" % bubble_index, Vector2.ZERO)
	sprite.material = material
	_foliage_parent.add_child(sprite)
	var texture_size := texture.get_size()
	var foliage_kind := _classify_foliage(texture_size)
	var has_trunk_collision := foliage_kind == "tree" and _should_add_tree_trunk_collision(pos)
	if has_trunk_collision:
		_add_tree_trunk_collision(sprite, texture_size)
	_foliage_nodes[pos] = {
		"node": sprite,
		"world_pos": world_pos,
		"base_y": world_pos.y + texture_size.y * 0.5,
		"size": texture_size,
		"kind": foliage_kind,
		"has_collision": has_trunk_collision,
	}
	
	# Optionally spawn fruit on this foliage
	if enable_fruit_spawning and _fruit_texture != null and _should_place_fruit(pos, foliage_kind):
		_place_fruit(sprite, pos, texture_size, foliage_kind)


func _pick_foliage_texture(pos: Vector2i) -> Texture2D:
	if _foliage_textures.is_empty():
		return null
	var idx := _tile_noise_hash(pos + Vector2i(19, 73)) % _foliage_textures.size()
	return _foliage_textures[idx]


func _classify_foliage(foliage_size: Vector2) -> String:
	if foliage_size.y >= 96.0:
		return "tree"
	return "shrub"


func _should_add_tree_trunk_collision(pos: Vector2i) -> bool:
	if not foliage_probabilistic_tree_collision:
		return true
	var local_tree_density := _estimate_local_tree_density(pos)
	if local_tree_density <= foliage_sparse_tree_collision_threshold:
		return true
	var dense_threshold := maxf(foliage_sparse_tree_collision_threshold + 0.01, foliage_dense_tree_collision_threshold)
	var density_t := clampf(
		(local_tree_density - foliage_sparse_tree_collision_threshold) / (dense_threshold - foliage_sparse_tree_collision_threshold),
		0.0,
		1.0
	)
	var collision_chance := lerpf(1.0, foliage_dense_tree_collision_chance, density_t)
	var roll := float(_tile_noise_hash(pos + Vector2i(1459, 811)) % 1000) / 1000.0
	return roll < collision_chance


func _estimate_local_tree_density(center: Vector2i) -> float:
	var radius: int = maxi(1, foliage_tree_collision_density_radius)
	var possible := 0
	var tree_count := 0
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var pos := center + Vector2i(x, y)
			if not _generated_floor_cells.has(pos):
				continue
			if is_indoor_tile(pos) or _is_near_indoor_tile(pos, foliage_indoor_clearance_tiles):
				continue
			if _is_near_wall(pos) or _is_inside_foliage_clearance(pos):
				continue
			possible += 1
			if not _would_place_foliage_at(pos):
				continue
			var texture := _pick_foliage_texture(pos)
			if texture != null and _classify_foliage(texture.get_size()) == "tree":
				tree_count += 1
	if possible <= 0:
		return 0.0
	return float(tree_count) / float(possible)


func _would_place_foliage_at(pos: Vector2i) -> bool:
	var density := foliage_density
	if _is_inside_compound_zone(pos):
		density *= foliage_compound_density_multiplier
	if density <= 0.0:
		return false
	var prob := float(_tile_noise_hash(pos + Vector2i(13, 41)) % 1000) / 1000.0
	return prob < density


func _add_tree_trunk_collision(foliage_sprite: Sprite2D, foliage_size: Vector2) -> void:
	if foliage_sprite == null:
		return
	var body := StaticBody2D.new()
	body.name = "TrunkCollision"
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = foliage_tree_trunk_collision_size
	shape.shape = rectangle
	body.position = Vector2(0, foliage_size.y * 0.5) + foliage_tree_trunk_collision_offset
	body.add_child(shape)
	foliage_sprite.add_child(body)


func _should_place_fruit(pos: Vector2i, foliage_kind: String) -> bool:
	var fruit_prob := float(_tile_noise_hash(pos + Vector2i(17, 89)) % 1000) / 1000.0
	var chance := fruit_spawn_chance_tree if foliage_kind == "tree" else fruit_spawn_chance_shrub
	return fruit_prob < chance


func _place_fruit(foliage_sprite: Sprite2D, foliage_tile: Vector2i, foliage_size: Vector2, foliage_kind: String) -> void:
	if _fruit_texture == null:
		return
	
	var sprite := Sprite2D.new()
	sprite.texture = _fruit_texture
	sprite.modulate = _get_planet_profile_color("foliage_tint", Color.WHITE)
	
	# Slice the square fruit sheet correctly; the previous code only split horizontally.
	var frame_x := _tile_noise_hash(foliage_tile + Vector2i(23, 47)) % fruit_tiles_wide
	var frame_y := _tile_noise_hash(foliage_tile + Vector2i(61, 11)) % fruit_tiles_high
	var frame_size := Vector2(
		float(_fruit_texture.get_size().x) / float(max(1, fruit_tiles_wide)),
		float(_fruit_texture.get_size().y) / float(max(1, fruit_tiles_high))
	)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(frame_x * frame_size.x, frame_y * frame_size.y, frame_size.x, frame_size.y)
	sprite.centered = true
	
	# Anchor fruit to the plant itself so it doesn't float or desync.
	var x_jitter := (float(_tile_noise_hash(foliage_tile + Vector2i(31, 59)) % 100) / 100.0 - 0.5)
	var y_jitter := (float(_tile_noise_hash(foliage_tile + Vector2i(71, 29)) % 100) / 100.0 - 0.5)
	var fruit_offset := Vector2.ZERO
	if foliage_kind == "tree":
		fruit_offset = Vector2(
			x_jitter * foliage_size.x * 0.18,
			-foliage_size.y * 0.18 + y_jitter * foliage_size.y * 0.04
		)
	else:
		fruit_offset = Vector2(
			x_jitter * foliage_size.x * 0.16,
			-foliage_size.y * 0.12 + y_jitter * foliage_size.y * 0.03
		)
	sprite.position = fruit_offset
	sprite.z_index = 1
	sprite.z_as_relative = true
	
	foliage_sprite.add_child(sprite)
	_fruit_sprites.append(sprite)


func _tile_to_world_position(pos: Vector2i) -> Vector2:
	if floor_tilemap == null:
		return Vector2.ZERO
	var local := floor_tilemap.map_to_local(pos)
	var tile_size := _get_tile_size()
	return floor_tilemap.to_global(local + tile_size * 0.5)


func _get_tile_size() -> Vector2:
	if floor_tilemap != null and floor_tilemap.tile_set != null:
		return Vector2(floor_tilemap.tile_set.tile_size)
	return Vector2(16, 16)


func _foliage_jitter(pos: Vector2i) -> Vector2:
	var seed := _tile_noise_hash(pos + Vector2i(7, 13))
	var x_unit := float(seed % 21) - 10.0
	var y_unit := float((seed / 21) % 11) - 5.0
	return Vector2(
		x_unit * (foliage_jitter_amplitude.x / 10.0),
		y_unit * (foliage_jitter_amplitude.y / 5.0)
	)


func _load_foliage_textures() -> void:
	_foliage_textures.clear()
	for path in FOLIAGE_ASSET_PATHS:
		var tex := load(path) as Texture2D
		if tex != null:
			_foliage_textures.append(tex)
	for texture in extra_foliage_textures:
		if texture != null:
			_foliage_textures.append(texture)
	
	if enable_fruit_spawning:
		if ResourceLoader.exists(FRUIT_TEXTURE_PATH):
			_fruit_texture = load(FRUIT_TEXTURE_PATH) as Texture2D
		else:
			_fruit_texture = null


func _load_interior_prop_textures() -> void:
	_interior_prop_textures.clear()
	var files := DirAccess.get_files_at(INTERIOR_RUNTIME_DIR)
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".png"):
			continue
		if not file_name.begins_with("props_") and not file_name.begins_with("prop_"):
			continue
		var texture := load(INTERIOR_RUNTIME_DIR + "/" + file_name) as Texture2D
		if texture != null:
			_interior_prop_textures.append(texture)
	if interior_prop_debug_logging:
		print("[InteriorProps] Loaded %d runtime prop textures" % _interior_prop_textures.size())


func _apply_planet_visual_profile() -> void:
	if floor_tilemap != null:
		floor_tilemap.modulate = _get_planet_profile_color("tile_tint", Color.WHITE)
	if walls_tilemap != null:
		walls_tilemap.modulate = _get_planet_profile_color("wall_tint", Color.WHITE)
		_apply_wall_tile_visibility()


func _apply_wall_tile_visibility() -> void:
	if walls_tilemap == null:
		return
	var alpha := 1.0 if show_base_wall_tiles else 0.0
	walls_tilemap.self_modulate = Color(1.0, 1.0, 1.0, alpha)


func _get_planet_profile_color(key: String, fallback: Color) -> Color:
	var value: Variant = _planet_world_profile.get(key, fallback)
	if value is Color:
		return value as Color
	return fallback


func _find_foliage_parent() -> Node2D:
	if foliage_parent_path != NodePath("") and has_node(foliage_parent_path):
		return get_node(foliage_parent_path) as Node2D
	if foliage_parent_path != NodePath("") and owner != null and owner.has_node(foliage_parent_path):
		return owner.get_node(foliage_parent_path) as Node2D
	if foliage_parent_path != NodePath("") and get_tree() != null and get_tree().current_scene != null:
		if get_tree().current_scene.has_node(foliage_parent_path):
			return get_tree().current_scene.get_node(foliage_parent_path) as Node2D
	var fallback := get_tree().get_root().find_child("FoliageLayer", true, false)
	if fallback is Node2D:
		return fallback
	return null


func _find_ruin_prop_parent() -> Node2D:
	if ruin_prop_parent_path != NodePath("") and has_node(ruin_prop_parent_path):
		return get_node(ruin_prop_parent_path) as Node2D
	if ruin_prop_parent_path != NodePath("") and owner != null and owner.has_node(ruin_prop_parent_path):
		return owner.get_node(ruin_prop_parent_path) as Node2D
	if ruin_prop_parent_path != NodePath("") and get_tree() != null and get_tree().current_scene != null:
		if get_tree().current_scene.has_node(ruin_prop_parent_path):
			return get_tree().current_scene.get_node(ruin_prop_parent_path) as Node2D
	var fallback := get_tree().get_root().find_child("PropLayer", true, false)
	if fallback is Node2D:
		return fallback
	return null


func _update_foliage_occlusion(player: Node2D) -> void:
	if player == null:
		return
	var occluders := _collect_foliage_occluders(player)
	for pos in _foliage_nodes.keys():
		var entry = _foliage_nodes.get(pos, null)
		if not (entry is Dictionary):
			continue
		var sprite := entry.get("node", null) as Sprite2D
		if sprite == null or not is_instance_valid(sprite):
			continue
		var base_y := float(entry.get("base_y", sprite.global_position.y))
		var size := entry.get("size", Vector2.ZERO) as Vector2
		var top_y := base_y - size.y
		var player_in_front := false
		var active_centers: Array[Vector2] = []
		for occluder in occluders:
			var upper := occluder.get("upper", Vector2.ZERO) as Vector2
			var feet := occluder.get("feet", Vector2.ZERO) as Vector2
			var x_padding := float(occluder.get("x_padding", foliage_player_occlusion_x_padding))
			var half_width := size.x * 0.5 + x_padding
			var canopy_contains_upper := (
				upper.x >= sprite.global_position.x - half_width
				and upper.x <= sprite.global_position.x + half_width
				and upper.y >= top_y
				and upper.y <= base_y
			)
			var actor_in_front := feet.y > base_y
			if bool(occluder.get("is_player", false)):
				player_in_front = actor_in_front
			if not actor_in_front and canopy_contains_upper:
				active_centers.append(upper)
				if active_centers.size() >= _get_foliage_occlusion_bubble_limit():
					break
		sprite.z_index = foliage_behind_z_index if player_in_front else foliage_front_z_index
		var material := sprite.material as ShaderMaterial
		if material != null:
			_apply_foliage_occlusion_material(material, active_centers)


func _collect_foliage_occluders(player: Node2D) -> Array[Dictionary]:
	var occluders: Array[Dictionary] = []
	var player_id := player.get_instance_id()
	var seen_ids := {player_id: true}
	occluders.append({
		"node": player,
		"feet": player.global_position + foliage_player_feet_offset,
		"upper": player.global_position + foliage_player_upper_body_offset,
		"x_padding": foliage_player_occlusion_x_padding,
		"is_player": true,
	})
	if not foliage_mob_occlusion_enabled:
		return occluders
	var tree := get_tree()
	if tree == null:
		return occluders
	var max_bubbles := _get_foliage_occlusion_bubble_limit()
	var range_squared := foliage_mob_occlusion_player_range * foliage_mob_occlusion_player_range
	var candidates: Array[Dictionary] = []
	for group_name in foliage_mob_occlusion_groups:
		var group := String(group_name)
		if group.is_empty():
			continue
		for node in tree.get_nodes_in_group(group):
			if not (node is Node2D):
				continue
			var actor := node as Node2D
			var actor_id := actor.get_instance_id()
			if seen_ids.has(actor_id):
				continue
			seen_ids[actor_id] = true
			if not is_instance_valid(actor) or _is_foliage_occluder_inactive(actor):
				continue
			var dist_squared := actor.global_position.distance_squared_to(player.global_position)
			if dist_squared > range_squared:
				continue
			candidates.append({
				"node": actor,
				"feet": actor.global_position + foliage_mob_feet_offset,
				"upper": actor.global_position + foliage_mob_upper_body_offset,
				"x_padding": foliage_mob_occlusion_x_padding,
				"is_player": false,
				"dist_squared": dist_squared,
			})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("dist_squared", 0.0)) < float(b.get("dist_squared", 0.0))
	)
	for candidate in candidates:
		occluders.append(candidate)
		if occluders.size() >= max_bubbles:
			break
	return occluders


func _is_foliage_occluder_inactive(actor: Node2D) -> bool:
	if actor.has_method("is_dead") and bool(actor.call("is_dead")):
		return true
	if "dead" in actor and bool(actor.get("dead")):
		return true
	if "health" in actor and float(actor.get("health")) <= 0.0:
		return true
	return false


func _get_foliage_occlusion_bubble_limit() -> int:
	return clampi(foliage_occlusion_max_bubbles, 1, FOLIAGE_OCCLUSION_MAX_SHADER_BUBBLES)


func _apply_foliage_occlusion_material(material: ShaderMaterial, active_centers: Array[Vector2]) -> void:
	var bubble_count := mini(active_centers.size(), _get_foliage_occlusion_bubble_limit())
	material.set_shader_parameter("bubble_radius", foliage_player_occlusion_radius)
	material.set_shader_parameter("bubble_softness", foliage_player_occlusion_softness)
	material.set_shader_parameter("bubble_alpha", foliage_player_occlusion_alpha)
	material.set_shader_parameter("bubble_enabled", false)
	material.set_shader_parameter("bubble_count", bubble_count)
	for bubble_index in range(FOLIAGE_OCCLUSION_MAX_SHADER_BUBBLES):
		var center := active_centers[bubble_index] if bubble_index < bubble_count else Vector2.ZERO
		material.set_shader_parameter("bubble_center_%d" % bubble_index, center)


func _prepare_streaming_reveal() -> void:
	_revealed_chunks.clear()
	_queued_chunks.clear()
	_streaming_reveal_queue.clear()
	_streaming_player = null
	_streaming_current_chunk = Vector2i(999999, 999999)
	_navigation_rebuild_pending = false
	_navigation_rebuild_deferred = false
	_clear_foliage()
	_clear_ruin_props()
	_clear_horizontal_wall_overlays()
	floor_tilemap.clear()
	walls_tilemap.clear()
	_clear_runtime_wall_collision()
	_rebuild_runtime_wall_collision_debug()
	_refresh_shadows()
	var spawn_tile := get_player_spawn()
	_prime_streaming_chunks(spawn_tile)


func _prime_streaming_chunks(center_tile: Vector2i) -> void:
	var center_chunk := _tile_to_chunk(center_tile)
	_streaming_current_chunk = center_chunk
	for x in range(-streaming_active_chunk_radius, streaming_active_chunk_radius + 1):
		for y in range(-streaming_active_chunk_radius, streaming_active_chunk_radius + 1):
			var chunk := center_chunk + Vector2i(x, y)
			var distance := maxi(abs(x), abs(y))
			if distance <= streaming_immediate_chunk_radius:
				_reveal_chunk_immediately(chunk)
			else:
				_queue_chunk_for_reveal(chunk, center_tile)
	_sync_runtime_wall_collision_with_visible_walls()
	_rebuild_horizontal_wall_overlays()
	_refresh_shadows()
	_refresh_navigation_after_wall_change()


func _update_streaming_chunks(center_chunk: Vector2i, center_tile: Vector2i) -> void:
	var unloaded_any := false
	for x in range(-streaming_active_chunk_radius, streaming_active_chunk_radius + 1):
		for y in range(-streaming_active_chunk_radius, streaming_active_chunk_radius + 1):
			_queue_chunk_for_reveal(center_chunk + Vector2i(x, y), center_tile)
	if streaming_unload_distant_chunks:
		var chunk_keys := _revealed_chunks.keys()
		for key in chunk_keys:
			if key is Vector2i:
				var chunk_pos := key as Vector2i
				if maxi(abs(chunk_pos.x - center_chunk.x), abs(chunk_pos.y - center_chunk.y)) > streaming_unload_chunk_distance:
					_unload_chunk(chunk_pos)
					unloaded_any = true
	if unloaded_any:
		_refresh_navigation_after_wall_change()


func _process_streaming_reveal_queue() -> void:
	if _streaming_reveal_queue.is_empty():
		return
	var remaining := streaming_reveal_tiles_per_frame
	var revealed_any := false
	while remaining > 0 and not _streaming_reveal_queue.is_empty():
		var tile: Vector2i = _streaming_reveal_queue.pop_front()
		_reveal_tile(tile)
		revealed_any = true
		remaining -= 1
	if revealed_any:
		_sync_runtime_wall_collision_with_visible_walls()
		_rebuild_horizontal_wall_overlays()
		_refresh_shadows()
		if _streaming_reveal_queue.is_empty() or _navigation_rebuild_pending:
			_refresh_navigation_after_wall_change()


func _queue_chunk_for_reveal(chunk_pos: Vector2i, center_tile: Vector2i) -> void:
	if _revealed_chunks.has(chunk_pos) or _queued_chunks.has(chunk_pos):
		return
	_queued_chunks[chunk_pos] = true
	var tiles := _get_chunk_tiles(chunk_pos)
	tiles.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(center_tile) < b.distance_squared_to(center_tile))
	for tile in tiles:
		_streaming_reveal_queue.append(tile)


func _reveal_chunk_immediately(chunk_pos: Vector2i) -> void:
	if _revealed_chunks.has(chunk_pos):
		return
	var tiles := _get_chunk_tiles(chunk_pos)
	for tile in tiles:
		_reveal_tile(tile)


func _get_chunk_tiles(chunk_pos: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var start_x := chunk_pos.x * streaming_chunk_size_tiles
	var start_y := chunk_pos.y * streaming_chunk_size_tiles
	for x in range(start_x, start_x + streaming_chunk_size_tiles):
		for y in range(start_y, start_y + streaming_chunk_size_tiles):
			var tile := Vector2i(x, y)
			if _generated_floor_cells.has(tile) or _generated_wall_cells.has(tile):
				tiles.append(tile)
	_revealed_chunks[chunk_pos] = true
	_queued_chunks.erase(chunk_pos)
	return tiles


func _unload_chunk(chunk_pos: Vector2i) -> void:
	if not _revealed_chunks.has(chunk_pos):
		return
	var start_x := chunk_pos.x * streaming_chunk_size_tiles
	var start_y := chunk_pos.y * streaming_chunk_size_tiles
	for x in range(start_x, start_x + streaming_chunk_size_tiles):
		for y in range(start_y, start_y + streaming_chunk_size_tiles):
			var tile := Vector2i(x, y)
			floor_tilemap.erase_cell(tile)
			walls_tilemap.erase_cell(tile)
			_remove_foliage(tile)
			_remove_runtime_wall_body(tile)
	_revealed_chunks.erase(chunk_pos)
	_sync_runtime_wall_collision_with_visible_walls()
	_rebuild_horizontal_wall_overlays()
	_refresh_shadows()


func _reveal_tile(tile: Vector2i) -> void:
	if _generated_floor_cells.has(tile):
		var floor_data: Dictionary = _generated_floor_cells[tile]
		floor_tilemap.set_cell(tile, int(floor_data.get("source_id", floor_source_id)), floor_data.get("atlas", floor_atlas_coord), int(floor_data.get("alternative", 0)))
		if _should_place_foliage(tile):
			_place_foliage(tile)
	if _generated_wall_cells.has(tile):
		var wall_data: Dictionary = _generated_wall_cells[tile]
		walls_tilemap.set_cell(tile, int(wall_data.get("source_id", walls_source_id)), wall_data.get("atlas", wall_atlas_coord), int(wall_data.get("alternative", 0)))
		_remove_foliage(tile)
		if build_runtime_wall_collision:
			_spawn_runtime_wall_body(tile)


func _spawn_runtime_wall_body(tile: Vector2i, refresh_debug: bool = true) -> void:
	if collision_only_on_new_ruined_wall_tiles and not _tile_uses_new_ruined_wall_treatment(tile):
		return
	var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision") as Node2D
	if collision_root == null:
		collision_root = Node2D.new()
		collision_root.name = "RuntimeWallCollision"
		walls_tilemap.add_child(collision_root)
	var node_name := _runtime_wall_body_name(tile)
	if collision_root.has_node(NodePath(node_name)):
		return
	var tile_size: Vector2 = Vector2(16, 16)
	if walls_tilemap.tile_set != null:
		tile_size = Vector2(walls_tilemap.tile_set.tile_size)
	var body: StaticBody2D
	if destructible_runtime_walls:
		var segment := RUNTIME_WALL_SEGMENT_SCRIPT.new()
		segment.setup(self, tile)
		body = segment
	else:
		body = StaticBody2D.new()
	body.name = node_name
	body.position = walls_tilemap.map_to_local(tile)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var collision_profile := _get_runtime_wall_collision_profile(tile, tile_size)
	var collision_size: Vector2 = collision_profile.get("size", Vector2(tile_size.x, tile_size.y))
	shape.position = collision_profile.get("offset", Vector2.ZERO)
	rect.size = collision_size
	shape.shape = rect
	body.add_child(shape)
	collision_root.add_child(body)
	if refresh_debug:
		_rebuild_runtime_wall_collision_debug()


func _remove_runtime_wall_body(tile: Vector2i) -> void:
	var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision") as Node2D
	if collision_root == null:
		return
	var body := collision_root.get_node_or_null(NodePath(_runtime_wall_body_name(tile)))
	if body != null:
		collision_root.remove_child(body)
		body.queue_free()
	_rebuild_runtime_wall_collision_debug()


func _runtime_wall_body_name(tile: Vector2i) -> String:
	return "Wall_%d_%d" % [tile.x, tile.y]


func _clear_runtime_wall_collision() -> void:
	var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision") as Node2D
	if collision_root == null:
		return
	for child in collision_root.get_children():
		collision_root.remove_child(child)
		child.queue_free()


func _sync_runtime_wall_collision_with_visible_walls() -> void:
	if walls_tilemap == null or not build_runtime_wall_collision:
		return
	var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision") as Node2D
	if collision_root == null:
		collision_root = Node2D.new()
		collision_root.name = "RuntimeWallCollision"
		walls_tilemap.add_child(collision_root)

	var visible_wall_tiles := {}
	for tile in walls_tilemap.get_used_cells():
		if walls_tilemap.get_cell_source_id(tile) >= 0:
			visible_wall_tiles[tile] = true
			_spawn_runtime_wall_body(tile, false)

	for child in collision_root.get_children():
		var tile := _wall_tile_from_runtime_body_name(String(child.name))
		if tile == Vector2i(999999, 999999) or not visible_wall_tiles.has(tile):
			collision_root.remove_child(child)
			child.queue_free()
	_rebuild_runtime_wall_collision_debug()


func _wall_tile_from_runtime_body_name(body_name: String) -> Vector2i:
	if not body_name.begins_with("Wall_"):
		return Vector2i(999999, 999999)
	var parts := body_name.split("_")
	if parts.size() != 3:
		return Vector2i(999999, 999999)
	if not String(parts[1]).is_valid_int() or not String(parts[2]).is_valid_int():
		return Vector2i(999999, 999999)
	return Vector2i(int(parts[1]), int(parts[2]))


func _get_runtime_wall_collision_debug_root() -> Node2D:
	if walls_tilemap == null:
		return null
	var debug_root := walls_tilemap.get_node_or_null("RuntimeWallCollisionDebug") as Node2D
	if debug_root == null:
		debug_root = Node2D.new()
		debug_root.name = "RuntimeWallCollisionDebug"
		walls_tilemap.add_child(debug_root)
	return debug_root


func _rebuild_runtime_wall_collision_debug() -> void:
	var debug_root := _get_runtime_wall_collision_debug_root()
	if debug_root == null:
		return
	for child in debug_root.get_children():
		child.queue_free()
	debug_root.visible = show_runtime_wall_collision_debug
	if not show_runtime_wall_collision_debug:
		return

	var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision") as Node2D
	if collision_root == null:
		return

	for child in collision_root.get_children():
		var body := child as StaticBody2D
		if body == null:
			continue
		var shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape == null:
			for grandchild in body.get_children():
				if grandchild is CollisionShape2D:
					shape = grandchild as CollisionShape2D
					break
		if shape == null:
			continue
		var rectangle := shape.shape as RectangleShape2D
		if rectangle == null:
			continue
		var poly := Polygon2D.new()
		poly.color = Color(1.0, 0.1, 0.1, 0.24)
		poly.position = body.position + shape.position
		poly.polygon = PackedVector2Array([
			Vector2(-rectangle.size.x * 0.5, -rectangle.size.y * 0.5),
			Vector2(rectangle.size.x * 0.5, -rectangle.size.y * 0.5),
			Vector2(rectangle.size.x * 0.5, rectangle.size.y * 0.5),
			Vector2(-rectangle.size.x * 0.5, rectangle.size.y * 0.5),
		])
		debug_root.add_child(poly)


func _should_use_horizontal_wall_overlay_collision(tile: Vector2i) -> bool:
	return false


func _should_use_vertical_wall_overlay_collision(tile: Vector2i, right_side: bool) -> bool:
	return false


func _tile_uses_new_ruined_wall_treatment(tile: Vector2i) -> bool:
	return false


func _get_runtime_wall_collision_profile(tile: Vector2i, tile_size: Vector2) -> Dictionary:
	return {"size": Vector2(tile_size.x, tile_size.y), "offset": Vector2.ZERO}


func _get_horizontal_wall_overlay_root() -> Node2D:
	if walls_tilemap == null:
		return null
	return walls_tilemap.get_node_or_null("RuntimeWallVisuals") as Node2D


func _clear_horizontal_wall_overlays() -> void:
	var overlay_root := _get_horizontal_wall_overlay_root()
	if overlay_root == null:
		return
	for child in overlay_root.get_children():
		child.queue_free()


func _rebuild_horizontal_wall_overlays() -> void:
	_clear_horizontal_wall_overlays()
	return


func _create_horizontal_wall_overlay_run(parent: Node2D, row_y: int, start_x: int, end_x: int) -> void:
	if parent == null or start_x > end_x:
		return

	var tile_size := _get_tile_size()
	var run_tiles := end_x - start_x + 1
	var run_width := tile_size.x * float(run_tiles)
	if run_width <= 0.0:
		return

	var overlay_height := tile_size.y * float(max(1, horizontal_wall_overlay_cells_high))
	var nominal_cap_width := tile_size.x * float(max(1, horizontal_wall_overlay_cells_wide))
	var variant_row := _tile_noise_hash(Vector2i(start_x, row_y) + Vector2i(193, 401)) % 4
	var tint := Color.WHITE
	if horizontal_wall_overlay_tint_with_planet_profile:
		tint = _get_planet_profile_color("wall_tint", Color.WHITE)

	var origin := walls_tilemap.map_to_local(Vector2i(start_x, row_y)) - tile_size * 0.5
	var container := Node2D.new()
	container.name = "HorizontalWall_%d_%d_%d" % [row_y, start_x, end_x]
	container.position = origin
	parent.add_child(container)

	if run_tiles == 1:
		_add_horizontal_wall_overlay_sprite(
			container,
			Rect2(96.0, float(variant_row * 96), 96.0, 96.0),
			Vector2.ZERO,
			Vector2(run_width, overlay_height),
			tint
		)
		return

	var cap_width := minf(nominal_cap_width, run_width * 0.5)
	var middle_width := maxf(0.0, run_width - cap_width * 2.0)
	_add_horizontal_wall_overlay_sprite(
		container,
		Rect2(0.0, float(variant_row * 96), 96.0, 96.0),
		Vector2.ZERO,
		Vector2(cap_width, overlay_height),
			tint
		)
	if middle_width > 0.0:
		var repeat_width := nominal_cap_width
		var cursor_x := cap_width
		var remaining_width := middle_width
		while remaining_width > 0.0:
			var segment_width := minf(repeat_width, remaining_width)
			_add_horizontal_wall_overlay_sprite(
				container,
				Rect2(96.0, float(variant_row * 96), 96.0, 96.0),
				Vector2(cursor_x, 0.0),
				Vector2(segment_width, overlay_height),
				tint
			)
			cursor_x += segment_width
			remaining_width -= segment_width
	_add_horizontal_wall_overlay_sprite(
		container,
		Rect2(192.0, float(variant_row * 96), 96.0, 96.0),
		Vector2(run_width - cap_width, 0.0),
		Vector2(cap_width, overlay_height),
		tint
	)
	_add_horizontal_wall_south_connector_sprites(container, row_y, start_x, end_x, run_width, overlay_height, tint)
	_add_horizontal_wall_endcap_sprites(container, row_y, start_x, end_x, run_width, overlay_height, tint)


func _rebuild_horizontal_top_wall_overlays(overlay_root: Node2D) -> void:
	var rows: Dictionary = {}
	for cell_variant in walls_tilemap.get_used_cells():
		var cell: Vector2i = cell_variant
		if walls_tilemap.get_cell_source_id(cell) < 0:
			continue
		if _has_generated_wall_cell(cell + Vector2i.UP):
			continue
		if not rows.has(cell.y):
			rows[cell.y] = []
		var row_cells: Array = rows[cell.y]
		row_cells.append(cell.x)
		rows[cell.y] = row_cells

	var row_keys := rows.keys()
	row_keys.sort()
	for row_key in row_keys:
		var row_y := int(row_key)
		var x_values: Array = rows[row_key]
		x_values.sort()
		if x_values.is_empty():
			continue
		var run_start := int(x_values[0])
		var previous := int(x_values[0])
		for i in range(1, x_values.size()):
			var x_value := int(x_values[i])
			if x_value != previous + 1:
				_create_horizontal_wall_overlay_run(overlay_root, row_y, run_start, previous)
				run_start = x_value
			previous = x_value
		_create_horizontal_wall_overlay_run(overlay_root, row_y, run_start, previous)


func _rebuild_vertical_side_wall_overlays(overlay_root: Node2D) -> void:
	var left_columns: Dictionary = {}
	var right_columns: Dictionary = {}
	for cell_variant in walls_tilemap.get_used_cells():
		var cell: Vector2i = cell_variant
		if walls_tilemap.get_cell_source_id(cell) < 0:
			continue
		if not _has_generated_wall_cell(cell + Vector2i.LEFT):
			if not left_columns.has(cell.x):
				left_columns[cell.x] = []
			var left_values: Array = left_columns[cell.x]
			left_values.append(cell.y)
			left_columns[cell.x] = left_values
		if not _has_generated_wall_cell(cell + Vector2i.RIGHT):
			if not right_columns.has(cell.x):
				right_columns[cell.x] = []
			var right_values: Array = right_columns[cell.x]
			right_values.append(cell.y)
			right_columns[cell.x] = right_values

	_create_vertical_wall_overlay_runs(overlay_root, left_columns, false)
	_create_vertical_wall_overlay_runs(overlay_root, right_columns, true)


func _create_vertical_wall_overlay_runs(parent: Node2D, columns: Dictionary, right_side: bool) -> void:
	var column_keys := columns.keys()
	column_keys.sort()
	for column_key in column_keys:
		var column_x := int(column_key)
		var y_values: Array = columns[column_key]
		y_values.sort()
		if y_values.is_empty():
			continue
		var run_start := int(y_values[0])
		var previous := int(y_values[0])
		for i in range(1, y_values.size()):
			var y_value := int(y_values[i])
			if y_value != previous + 1:
				_create_vertical_wall_overlay_run(parent, column_x, run_start, previous, right_side)
				run_start = y_value
			previous = y_value
		_create_vertical_wall_overlay_run(parent, column_x, run_start, previous, right_side)


func _create_vertical_wall_overlay_run(parent: Node2D, column_x: int, start_y: int, end_y: int, right_side: bool) -> void:
	if parent == null or start_y > end_y:
		return
	var tile_size := _get_tile_size()
	var run_tiles := end_y - start_y + 1
	var run_height := tile_size.y * float(run_tiles)
	if run_height <= 0.0:
		return

	var overlay_width := tile_size.x * float(max(1, vertical_wall_overlay_cells_wide))
	var segment_height := tile_size.y * float(max(1, vertical_wall_overlay_cells_high))
	var variant_row := _tile_noise_hash(Vector2i(column_x, start_y) + Vector2i(317, 977)) % 4
	var tint := Color.WHITE
	if horizontal_wall_overlay_tint_with_planet_profile:
		tint = _get_planet_profile_color("wall_tint", Color.WHITE)

	var base_origin := walls_tilemap.map_to_local(Vector2i(column_x, start_y)) - tile_size * 0.5
	var side_offset_x := -overlay_width + tile_size.x if not right_side else 0.0
	var container := Node2D.new()
	container.name = "VerticalWall_%d_%d_%d_%s" % [column_x, start_y, end_y, "R" if right_side else "L"]
	container.position = base_origin + Vector2(side_offset_x, 0.0)
	parent.add_child(container)

	var cursor_y := 0.0
	var remaining_height := run_height
	while remaining_height > 0.0:
		var piece_height := minf(segment_height, remaining_height)
		_add_vertical_wall_overlay_sprite(
			container,
			Rect2(96.0, float(variant_row * 96), 96.0, 96.0),
			Vector2(0.0, cursor_y),
			Vector2(overlay_width, piece_height),
			tint,
			right_side
		)
		cursor_y += piece_height
		remaining_height -= piece_height


func _add_horizontal_wall_overlay_sprite(parent: Node2D, region: Rect2, position: Vector2, size: Vector2, tint: Color) -> void:
	if parent == null or horizontal_wall_overlay_texture == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var sprite := Sprite2D.new()
	sprite.texture = horizontal_wall_overlay_texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.position = position
	sprite.scale = Vector2(size.x / region.size.x, size.y / region.size.y)
	sprite.z_index = horizontal_wall_overlay_z_index
	sprite.z_as_relative = false
	sprite.modulate = tint
	parent.add_child(sprite)


func _add_vertical_wall_overlay_sprite(parent: Node2D, region: Rect2, position: Vector2, size: Vector2, tint: Color, right_side: bool) -> void:
	if parent == null or horizontal_wall_overlay_texture == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var sprite := Sprite2D.new()
	sprite.texture = horizontal_wall_overlay_texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = true
	sprite.position = position + size * 0.5
	sprite.rotation_degrees = 90.0 if right_side else -90.0
	sprite.scale = Vector2(size.y / region.size.x, size.x / region.size.y)
	sprite.z_index = horizontal_wall_overlay_z_index
	sprite.z_as_relative = false
	sprite.modulate = tint
	parent.add_child(sprite)


func _add_horizontal_wall_south_connector_sprites(parent: Node2D, row_y: int, start_x: int, end_x: int, run_width: float, overlay_height: float, tint: Color) -> void:
	if not use_horizontal_wall_south_connector or horizontal_wall_south_connector_texture == null:
		return
	var segment_count: int = end_x - start_x + 1
	var end_buffer: int = max(0, horizontal_wall_south_connector_end_buffer_segments)
	var usable_start: int = end_buffer
	var usable_end: int = segment_count - end_buffer - 1
	if usable_end < usable_start:
		return
	for local_index in range(usable_start, usable_end + 1):
		var absolute_tile := Vector2i(start_x + local_index, row_y)
		var roll: float = float(_tile_noise_hash(absolute_tile + Vector2i(1409, 223)) % 1000) / 1000.0
		if roll > horizontal_wall_south_connector_spawn_chance:
			continue
		var size := Vector2(28.0, 48.5)
		var x_center := (float(local_index) + 0.5) * _get_tile_size().x
		var position := Vector2(x_center - size.x * 0.5, overlay_height - 4.0)
		if position.x < 0.0 or position.x + size.x > run_width:
			continue
		_add_horizontal_wall_south_connector_sprite(parent, position, size, tint)


func _add_horizontal_wall_south_connector_sprite(parent: Node2D, position: Vector2, size: Vector2, tint: Color) -> void:
	if parent == null or horizontal_wall_south_connector_texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = horizontal_wall_south_connector_texture
	sprite.centered = false
	sprite.position = position
	var tex_size := horizontal_wall_south_connector_texture.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		sprite.scale = Vector2(size.x / tex_size.x, size.y / tex_size.y)
	sprite.z_index = horizontal_wall_overlay_z_index + 1
	sprite.z_as_relative = false
	sprite.modulate = tint
	parent.add_child(sprite)


func _add_horizontal_wall_endcap_sprites(parent: Node2D, row_y: int, start_x: int, end_x: int, run_width: float, overlay_height: float, tint: Color) -> void:
	if not use_horizontal_wall_endcaps or horizontal_wall_endcap_texture == null:
		return
	var tile_size := _get_tile_size()
	var endcap_size := Vector2(
		tile_size.x * float(max(1, horizontal_wall_overlay_cells_wide)),
		tile_size.y * float(max(1, horizontal_wall_overlay_cells_high))
	)
	var overlap_width := endcap_size.x * clampf(horizontal_wall_endcap_overlap_ratio, 0.0, 0.75)
	var left_variant := _tile_noise_hash(Vector2i(start_x, row_y) + Vector2i(601, 97)) % 7
	var right_variant := _tile_noise_hash(Vector2i(end_x, row_y) + Vector2i(887, 131)) % 7
	var left_jitter := _compute_horizontal_wall_endcap_vertical_jitter(Vector2i(start_x, row_y), false)
	var right_jitter := _compute_horizontal_wall_endcap_vertical_jitter(Vector2i(end_x, row_y), true)
	_add_horizontal_wall_endcap_sprite(
		parent,
		Rect2(float(left_variant * 96), 0.0, 96.0, 96.0),
		Vector2(-(endcap_size.x - overlap_width), left_jitter + (overlay_height - endcap_size.y)),
		endcap_size,
		tint,
		false
	)
	_add_horizontal_wall_endcap_sprite(
		parent,
		Rect2(float(right_variant * 96), 0.0, 96.0, 96.0),
		Vector2(run_width - overlap_width, right_jitter + (overlay_height - endcap_size.y)),
		endcap_size,
		tint,
		true
	)


func _compute_horizontal_wall_endcap_vertical_jitter(tile: Vector2i, mirror_side: bool) -> float:
	var jitter_range: int = max(0, horizontal_wall_endcap_vertical_jitter_px)
	if jitter_range <= 0:
		return 0.0
	var offset_seed := Vector2i(709, 431)
	if mirror_side:
		offset_seed = Vector2i(911, 557)
	var jitter: int = _tile_noise_hash(tile + offset_seed) % (jitter_range + 1)
	return -float(jitter)


func _add_horizontal_wall_endcap_sprite(parent: Node2D, region: Rect2, position: Vector2, size: Vector2, tint: Color, flip_h: bool) -> void:
	if parent == null or horizontal_wall_endcap_texture == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var sprite := Sprite2D.new()
	sprite.texture = horizontal_wall_endcap_texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.position = position
	sprite.flip_h = flip_h
	sprite.scale = Vector2(size.x / region.size.x, size.y / region.size.y)
	sprite.z_index = horizontal_wall_overlay_z_index + 1
	sprite.z_as_relative = false
	sprite.modulate = tint
	parent.add_child(sprite)


func _global_to_tile(global_position: Vector2) -> Vector2i:
	if floor_tilemap != null:
		return floor_tilemap.local_to_map(floor_tilemap.to_local(global_position))
	return Vector2i.ZERO


func global_to_minimap_tile(global_position: Vector2) -> Vector2i:
	return _global_to_tile(global_position)


func minimap_tile_to_global(tile: Vector2i) -> Vector2:
	if floor_tilemap != null:
		return floor_tilemap.to_global(floor_tilemap.map_to_local(tile))
	return Vector2.ZERO


func _tile_to_chunk(tile: Vector2i) -> Vector2i:
	return Vector2i(
		int(floor(float(tile.x) / max(1.0, float(streaming_chunk_size_tiles)))),
		int(floor(float(tile.y) / max(1.0, float(streaming_chunk_size_tiles))))
	)


func get_runtime_tile_size() -> Vector2:
	if floor_tilemap != null and floor_tilemap.tile_set != null:
		var base_size := Vector2(floor_tilemap.tile_set.tile_size)
		var world_scale := floor_tilemap.global_scale
		return Vector2(base_size.x * absf(world_scale.x), base_size.y * absf(world_scale.y))
	return Vector2(16, 16)


func _refresh_shadows() -> void:
	if shadow_system == null:
		return
	if shadow_system.has_method("initialize"):
		shadow_system.call("initialize", floor_tilemap, walls_tilemap)
	if shadow_system.has_method("request_regenerate"):
		shadow_system.call("request_regenerate")


## Returns the largest room's center tile (good for player spawn)
func get_player_spawn() -> Vector2i:
	var rooms = procgen_node.get_rooms()
	if rooms.is_empty():
		return Vector2i(procgen_node.map_size / 2)
	
	var largest: Rect2i = rooms[0]
	for room in rooms:
		if room.get_area() > largest.get_area():
			largest = room
	
	return Vector2i(largest.get_center())


## Returns all room centers (for enemy spawns, loot, etc)
func get_room_centers() -> Array[Vector2i]:
	var rooms = procgen_node.get_rooms()
	var centers: Array[Vector2i] = []
	
	for room in rooms:
		centers.append(Vector2i(room.get_center()))
	
	return centers


## Returns room centers sorted by distance from player spawn (far = objective)
func get_rooms_by_distance_from_spawn() -> Array[Vector2i]:
	var player_pos = get_player_spawn()
	var rooms = procgen_node.get_rooms()
	
	# Create array of [center, distance] pairs
	var room_distances: Array = []
	for room in rooms:
		var center = Vector2i(room.get_center())
		var dist = center.distance_to(player_pos)
		room_distances.append({"center": center, "distance": dist})
	
	# Sort by distance (furthest first)
	room_distances.sort_custom(func(a, b): return a.distance > b.distance)
	
	# Extract just centers
	var sorted_centers: Array[Vector2i] = []
	for rd in room_distances:
		sorted_centers.append(rd.center)
	
	return sorted_centers


## Returns random floor tiles in rooms (for pickups, ammo, etc)
func get_random_floor_tiles_in_rooms(count: int = 10) -> Array[Vector2i]:
	var rooms = procgen_node.get_rooms()
	var floor_tiles: Array[Vector2i] = []
	
	for room in rooms:
		for x in range(room.position.x + 1, room.position.x + room.size.x - 1):
			for y in range(room.position.y + 1, room.position.y + room.size.y - 1):
				var pos = Vector2i(x, y)
				if not procgen_node.is_full_at(pos):
					floor_tiles.append(pos)
	
	floor_tiles.shuffle()
	return floor_tiles.slice(0, min(count, floor_tiles.size()))


## Returns corridor endpoints (good for wave spawns)
func get_corridor_spawn_points(count: int = 5) -> Array[Vector2i]:
	var corridors = procgen_node.get_corridor_areas()
	
	# Find dead-ends (corridor tiles with only 1 neighbor)
	var dead_ends: Array[Vector2i] = []
	
	for pos in corridors:
		var neighbor_count = 0
		var neighbors = [
			pos + Vector2i.UP, pos + Vector2i.DOWN,
			pos + Vector2i.LEFT, pos + Vector2i.RIGHT
		]
		for n in neighbors:
			if n in corridors:
				neighbor_count += 1
		
		if neighbor_count <= 1:
			dead_ends.append(pos)
	
	dead_ends.shuffle()
	return dead_ends.slice(0, min(count, dead_ends.size()))


## Returns all data as a dict (for debugging or passing to game)
func _dict_keys_as_vector2i_array(source: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for key in source.keys():
		if key is Vector2i:
			result.append(key)
	return result


func get_level_data() -> Dictionary:
	return {
		"map_size": procgen_node.map_size,
		"tile_size": get_runtime_tile_size(),
		"player_spawn": get_player_spawn(),
		"rooms": get_room_centers(),
		"rooms_by_distance": get_rooms_by_distance_from_spawn(),
		"corridor_spawns": get_corridor_spawn_points(),
		"random_floor_tiles": get_random_floor_tiles_in_rooms(20),
		"compound_rect": _last_compound_rect,
		"compound_ingress": _last_compound_ingress,
		"compound_buildings": _last_compound_buildings,
		"interior_region_rect": _last_interior_region_rect,
		"interior_rooms": _last_interior_rooms,
		"interior_thresholds": _last_interior_thresholds,
		"region_tiles": _region_tiles.duplicate(true),
		"floor_cells": _dict_keys_as_vector2i_array(_generated_floor_cells),
		"wall_cells": _dict_keys_as_vector2i_array(_generated_wall_cells),
		"world_profile": get_planet_world_profile(),
	}
