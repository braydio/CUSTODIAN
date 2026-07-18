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
const ELEVATION_MAP_SCRIPT := preload("res://game/world/elevation/elevation_map.gd")
const TERRAIN_BUILDER_SCRIPT := preload("res://game/world/procgen/terrain/terrain_builder.gd")
const TERRAIN_BALLISTICS_SCRIPT := preload("res://game/world/procgen/terrain/terrain_ballistics.gd")
const REQUIRED_CELL_CLASSIFIER_SCRIPT := preload("res://game/world/procgen/diagnostics/procgen_required_cell_classifier.gd")
const PRETERRAIN_DIAGNOSTICS_SCRIPT := preload("res://game/world/procgen/diagnostics/procgen_preterrain_diagnostics.gd")
const PRETERRAIN_AUTHORITY_REPAIR_SCRIPT := preload("res://game/world/procgen/diagnostics/procgen_preturn_authority_repair.gd")
const WORLD_PROGRESS_PROFILE_SCRIPT := preload("res://game/world/procgen/progression/world_progress_profile.gd")
const FACTION_SITE_PLACER_SCRIPT := preload("res://game/world/procgen/factions/faction_site_placer.gd")
const STORY_ROOM_PLACER_SCRIPT := preload("res://game/world/procgen/story/story_room_placer.gd")
const ASCENT_SPINE_BUILDER_SCRIPT := preload("res://game/world/procgen/intent/ascent_spine_builder.gd")
const ASCENT_FIELD_BUILDER_SCRIPT := preload("res://game/world/procgen/intent/ascent_field_builder.gd")
const REGION_FOOTPRINT_RESERVER_SCRIPT := preload("res://game/world/procgen/intent/region_footprint_reserver.gd")
const STORY_ROOM_GEOMETRY_STAMPER_SCRIPT := preload("res://game/world/procgen/story/story_room_geometry_stamper.gd")
const FACTION_SITE_GEOMETRY_STAMPER_SCRIPT := preload("res://game/world/procgen/factions/faction_site_geometry_stamper.gd")
const AMBIENT_ACTIVITY_ANCHOR_SCRIPT := preload("res://game/actors/enemies/ambient/ambient_activity_anchor.gd")
const PLACEHOLDER_ATLAS_PATH := "res://content/placeholder_art/placeholder_walls_floors_stairs.png"
const TILE_ALT_FLIP_H := 4096
const TILE_ALT_FLIP_V := 8192
const TILE_ALT_TRANSPOSE := 16384
const TERRAIN_TILE_ATLAS_COORD := Vector2i(0, 0)
const TERRAIN_TILESET_SOURCES := {
	"ground_flat_32": {"source_id": 32, "layer": "floor"},
	"elevated_floor_32": {"source_id": 33, "layer": "floor"},
	"elevation_edge_north_32": {"source_id": 34, "layer": "wall"},
	"elevation_edge_south_32": {"source_id": 35, "layer": "wall"},
	"elevation_edge_east_32": {"source_id": 36, "layer": "wall"},
	"elevation_edge_west_32": {"source_id": 37, "layer": "wall"},
	"ramp_north_32": {"source_id": 38, "layer": "floor"},
	"ramp_south_32": {"source_id": 39, "layer": "floor"},
	"ramp_east_32": {"source_id": 40, "layer": "floor"},
	"ramp_west_32": {"source_id": 41, "layer": "floor"},
	"cliff_shadow_32": {"source_id": 42, "layer": "wall"},
	"stair_metal_32": {"source_id": 43, "layer": "floor"},
	"rock_ground_flat_32": {"source_id": 44, "layer": "floor"},
	"rock_plateau_raised_32": {"source_id": 45, "layer": "floor"},
	"cliff_edge_north_32": {"source_id": 46, "layer": "wall"},
	"cliff_edge_south_32": {"source_id": 47, "layer": "wall"},
	"cliff_edge_east_32": {"source_id": 48, "layer": "wall"},
	"cliff_edge_west_32": {"source_id": 49, "layer": "wall"},
	"cliff_outer_nw_32": {"source_id": 50, "layer": "wall"},
	"cliff_outer_ne_32": {"source_id": 51, "layer": "wall"},
	"cliff_outer_sw_32": {"source_id": 52, "layer": "wall"},
	"cliff_outer_se_32": {"source_id": 53, "layer": "wall"},
	"cliff_inner_nw_32": {"source_id": 54, "layer": "wall"},
	"cliff_inner_ne_32": {"source_id": 55, "layer": "wall"},
	"cliff_inner_sw_32": {"source_id": 56, "layer": "wall"},
	"cliff_inner_se_32": {"source_id": 57, "layer": "wall"},
	"cliff_chasm_drop_32": {"source_id": 58, "layer": "wall"},
	"mountain_wall_impassable_32": {"source_id": 59, "layer": "wall"},
	"terrain_connector_ground_32": {"source_id": 60, "layer": "floor"},
	"terrain_connector_cracked_32": {"source_id": 61, "layer": "floor"},
	"terrain_connector_gravel_32": {"source_id": 62, "layer": "floor"},
	"terrain_connector_dust_32": {"source_id": 63, "layer": "floor"},
	"terrain_connector_edge_n_32": {"source_id": 64, "layer": "floor"},
	"terrain_connector_edge_s_32": {"source_id": 65, "layer": "floor"},
	"terrain_connector_edge_e_32": {"source_id": 66, "layer": "floor"},
	"terrain_connector_edge_w_32": {"source_id": 67, "layer": "floor"},
	"terrain_connector_outer_corner_ne_32": {"source_id": 68, "layer": "floor"},
	"terrain_connector_outer_corner_nw_32": {"source_id": 69, "layer": "floor"},
	"terrain_connector_outer_corner_se_32": {"source_id": 70, "layer": "floor"},
	"terrain_connector_outer_corner_sw_32": {"source_id": 71, "layer": "floor"},
	"terrain_connector_inner_corner_ne_32": {"source_id": 72, "layer": "floor"},
	"terrain_connector_inner_corner_nw_32": {"source_id": 73, "layer": "floor"},
	"terrain_connector_inner_corner_se_32": {"source_id": 74, "layer": "floor"},
	"terrain_connector_inner_corner_sw_32": {"source_id": 75, "layer": "floor"},
	"terrain_connector_centerline_32": {"source_id": 76, "layer": "floor"},
	"terrain_connector_broken_patch_32": {"source_id": 77, "layer": "floor"},
	"terrain_landing_industrial_32": {"source_id": 80, "layer": "floor"},
	"terrain_landing_stone_32": {"source_id": 81, "layer": "floor"},
	"ramp_north_wide_32": {"source_id": 82, "layer": "floor"},
	"ramp_south_wide_32": {"source_id": 83, "layer": "floor"},
	"ramp_east_wide_32": {"source_id": 84, "layer": "floor"},
	"ramp_west_wide_32": {"source_id": 85, "layer": "floor"},
	"ramp_north_broken_32": {"source_id": 86, "layer": "floor"},
	"ramp_south_broken_32": {"source_id": 87, "layer": "floor"},
	"ramp_east_broken_32": {"source_id": 88, "layer": "floor"},
	"ramp_west_broken_32": {"source_id": 89, "layer": "floor"},
	"stair_north_stone_32": {"source_id": 90, "layer": "floor"},
	"stair_south_stone_32": {"source_id": 91, "layer": "floor"},
	"stair_east_stone_32": {"source_id": 92, "layer": "floor"},
	"stair_west_stone_32": {"source_id": 93, "layer": "floor"},
	"stair_north_metal_32": {"source_id": 94, "layer": "floor"},
	"stair_south_metal_32": {"source_id": 95, "layer": "floor"},
	"stair_east_metal_32": {"source_id": 96, "layer": "floor"},
	"stair_west_metal_32": {"source_id": 97, "layer": "floor"},
	"ascent_threshold_32": {"source_id": 98, "layer": "floor"},
	"ascent_lip_connector_32": {"source_id": 99, "layer": "floor"},
	"chasm_void_32": {"source_id": 100, "layer": "wall"},
	"chasm_edge_n_32": {"source_id": 101, "layer": "wall"},
	"chasm_edge_s_32": {"source_id": 102, "layer": "wall"},
	"chasm_edge_e_32": {"source_id": 103, "layer": "wall"},
	"chasm_edge_w_32": {"source_id": 104, "layer": "wall"},
	"chasm_outer_corner_ne_32": {"source_id": 105, "layer": "wall"},
	"chasm_outer_corner_nw_32": {"source_id": 106, "layer": "wall"},
	"chasm_outer_corner_se_32": {"source_id": 107, "layer": "wall"},
	"chasm_outer_corner_sw_32": {"source_id": 108, "layer": "wall"},
	"chasm_inner_corner_ne_32": {"source_id": 109, "layer": "wall"},
	"chasm_inner_corner_nw_32": {"source_id": 110, "layer": "wall"},
	"chasm_inner_corner_se_32": {"source_id": 111, "layer": "wall"},
	"chasm_inner_corner_sw_32": {"source_id": 112, "layer": "wall"},
	"collapsed_gap_32": {"source_id": 113, "layer": "wall"},
	"broken_gap_edge_32": {"source_id": 114, "layer": "wall"},
	"bridge_stone_mid_horizontal_32": {"source_id": 115, "layer": "floor"},
	"bridge_stone_mid_vertical_32": {"source_id": 116, "layer": "floor"},
	"bridge_stone_start_n_32": {"source_id": 117, "layer": "floor"},
	"bridge_stone_start_s_32": {"source_id": 118, "layer": "floor"},
	"bridge_stone_start_e_32": {"source_id": 119, "layer": "floor"},
	"bridge_stone_start_w_32": {"source_id": 120, "layer": "floor"},
	"bridge_metal_mid_horizontal_32": {"source_id": 121, "layer": "floor"},
	"bridge_metal_mid_vertical_32": {"source_id": 122, "layer": "floor"},
	"bridge_broken_segment_32": {"source_id": 123, "layer": "floor"},
}

enum WorldShapeMode {
	LEGACY_CAVE,
	ASCENT_FIELD,
}

@export var procgen_node: ProcGen
@export var floor_tilemap: TileMapLayer
@export var walls_tilemap: TileMapLayer
@export var nav_region: NavigationRegion2D
@export var world_shape_mode: WorldShapeMode = WorldShapeMode.ASCENT_FIELD
@export var generation_evaluation_mode: bool = false
@export var generation_output_enabled: bool = true
@export var debug_log_terrain_source_usage: bool = false
@export var enable_final_foliage: bool = true
@export var foliage_deferred_spawn_enabled: bool = true
@export_range(64, 4096, 64) var foliage_spawn_batch_size: int = 512

## TileSet source IDs (from your TileSet)
@export var floor_source_id: int = 0
@export var walls_source_id: int = 1
@export var high_walls_source_id: int = 2
@export var alternate_floor_source_ids: Array[int] = []
@export var full_grid_floor_source_ids: Array[int] = []
@export var full_grid_floor_dimensions: Vector2i = Vector2i(16, 16)
@export var floor_value_clusters_enabled: bool = true
@export var floor_value_cluster_debug: bool = false
@export_range(0.0, 2.0, 0.05) var floor_value_cluster_strength: float = 1.0
@export var floor_value_cluster_variant_source_ids: Array[int] = []
@export var debug_log_floor_source_under_player: bool = false

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

@export_group("Gameplay Feel / Intent Zones", "intent")
@export var intent_spawn_clearing_enabled: bool = true
@export var intent_spawn_clearing_half_extents_tiles: Vector2i = Vector2i(5, 4)
@export var intent_soft_paths_enabled: bool = true
@export_range(0, 4, 1) var intent_soft_path_width: int = 1
@export var intent_main_roads_enabled: bool = true
@export_range(1, 5, 1) var intent_main_road_half_width: int = 2
@export var intent_parking_zone_half_extents_tiles: Vector2i = Vector2i(4, 3)
@export var road_piece_decals_enabled: bool = true
@export var road_piece_manifest_path: String = ROAD_PIECE_MANIFEST_PATH
@export var path_piece_manifest_path: String = PATH_PIECE_MANIFEST_PATH
@export var road_piece_parent_path: NodePath = NodePath("NavigationRegion2D/RoadPieceLayer")
@export_range(1, 12, 1) var road_piece_straight_stride_tiles: int = 5
@export_range(1, 12, 1) var path_piece_straight_stride_tiles: int = 4
@export var road_piece_z_index: int = 0
@export var intent_compound_connector_corridor_enabled: bool = true
@export_range(18, 72, 1) var intent_compound_connector_min_length_tiles: int = 28
@export_range(18, 96, 1) var intent_compound_connector_max_length_tiles: int = 48
@export_range(1, 5, 1) var intent_compound_connector_half_width: int = 2
@export_range(1, 4, 1) var intent_compound_connector_wall_gap_tiles: int = 1
@export var intent_compound_connector_elevation_enabled: bool = true
@export_range(1.0, 2.0, 0.05) var road_walk_speed_multiplier: float = 1.12
@export_range(1.0, 2.5, 0.05) var road_vehicle_speed_multiplier: float = 1.35
@export var intent_portal_plazas_enabled: bool = true
@export var intent_portal_plaza_half_extents_tiles: Vector2i = Vector2i(3, 2)
@export var intent_mark_foliage_cover: bool = true
@export var intent_decorate_compound_ingress: bool = true
@export_group("", "")

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
@export var interior_threshold_source_ids: Array[int] = []
@export var interior_doorway_source_ids: Array[int] = []
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
var _main_road_tiles: Dictionary = {}
var _road_centerline_tiles: Dictionary = {}
var _path_centerline_tiles: Dictionary = {}
var _road_visual_tiles: Dictionary = {}
var _path_visual_tiles: Dictionary = {}
var _compound_connector_centerline_tiles: Array[Vector2i] = []
var _compound_connector_visual_candidates: Dictionary = {}
var _parking_zone_tiles: Dictionary = {}
var _region_tiles: Dictionary = {}
var _wall_health: Dictionary = {}
var _generated_floor_cells: Dictionary = {}
var _generated_wall_cells: Dictionary = {}
var _runtime_prop_blocker_cells: Dictionary = {}
var _runtime_prop_blocker_sources: Dictionary = {}
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
const FOLIAGE_OCCLUSION_SHADER := preload("res://game/world/procgen/foliage_life.gdshader")
const PROCGEN_FOLIAGE_SPAWNER_SCRIPT := preload("res://game/world/procgen/foliage/procgen_foliage_spawner.gd")
const FOLIAGE_OCCLUSION_MAX_SHADER_BUBBLES := 8
const DEFAULT_RUIN_PROP_SCENE := preload("res://content/props/ruins/scenes/ProceduralProp.tscn")
const DEFAULT_RUIN_PROP_SPAWN_SET := preload("res://content/props/ruins/data/ruin_prop_spawn_set.tres")
const PROP_SCATTERER_SCRIPT := preload("res://content/props/ruins/scripts/PropScatterer.gd")
const PORTAL_TELEPORTER_SCRIPT := preload("res://game/world/procgen/portal_teleporter.gd")
const LIGHT_RIG_SCENE := preload("res://game/world/lighting/light_rig_2d.tscn")
const PORTAL_DEFINITION_ID := &"portal_ring_01"
const INTERIOR_RUNTIME_DIR := "res://content/tiles/interiors/runtime"
const ROAD_PIECE_MANIFEST_PATH := "res://content/tiles/roads_paths/runtime/roads/lane/road_lane_piece_manifest.game32.json"
const ROAD_PIECE_EXPORT_ROOT := "res://content/tiles/roads_paths/runtime/roads/lane"
const PATH_PIECE_MANIFEST_PATH := "res://content/tiles/roads_paths/runtime/placeholders/paths/PLACEHOLDER_path_piece_manifest.game32.json"
const PATH_PIECE_EXPORT_ROOT := "res://content/tiles/roads_paths/runtime/placeholders/paths"
@export var foliage_parent_path: NodePath = NodePath("NavigationRegion2D/FoliageLayer")
@export var foliage_density: float = 0.12
@export var foliage_min_wall_distance: int = 1
@export_range(0, 6, 1) var foliage_indoor_clearance_tiles: int = 3
@export var foliage_jitter_amplitude: Vector2 = Vector2(4, 2)
@export var foliage_debug_logging: bool = false
@export_range(0.0, 1.0, 0.01) var foliage_compound_density_multiplier: float = 0.28
@export_range(0, 8, 1) var foliage_compound_building_clearance: int = 3
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
@export_group("Foliage Motion")
@export var foliage_wind_enabled: bool = true
@export_range(0.0, 4.0, 0.05) var foliage_wind_speed: float = 0.9
@export_range(0.0, 2.0, 0.05) var foliage_shrub_wind_strength_px: float = 0.7
@export_range(0.0, 3.0, 0.05) var foliage_tree_wind_strength_px: float = 1.35
@export_range(0.0, 1.0, 0.01) var foliage_wind_gust_amount: float = 0.42
@export_group("Combat Readability")
@export var combat_readability_enabled: bool = true
@export var combat_readability_enemy_range: float = 260.0
@export var combat_foliage_occlusion_radius: float = 128.0
@export var combat_foliage_occlusion_softness: float = 28.0
@export_range(0.1, 1.0, 0.05) var combat_foliage_occlusion_alpha: float = 0.35
@export var combat_foliage_mob_x_padding: float = 22.0
@export var combat_foliage_hold_seconds: float = 1.25
@export_range(0, 12, 1) var combat_readability_foliage_clearance_tiles: int = 4
@export_range(0, 12, 1) var combat_readability_prop_clearance_tiles: int = 4
@export var debug_log_foliage_occlusion_bubbles: bool = false
@export_group("")
@export var foliage_tree_trunk_collision_size: Vector2 = Vector2(14, 8)
@export var foliage_tree_trunk_collision_offset: Vector2 = Vector2(0, 2)
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
@export var ruin_prop_force_collision_debug: bool = false
@export_group("Runtime Prop Walkability", "runtime_blocker")
@export_range(0, 8, 1) var runtime_blocker_route_clearance_tiles: int = 3
@export_range(1, 4, 1) var runtime_blocker_min_escape_neighbors: int = 2
@export var runtime_blocker_validate_stuck_pockets: bool = true
@export var runtime_blocker_remediate_stuck_pockets: bool = true
@export_group("", "")
@export var enable_portal_pair_teleport: bool = true
@export_range(1, 12, 1) var portal_pair_min_distance_tiles: int = 8
@export_range(0, 96, 1) var portal_teleport_cooldown_frames: int = 60
@export_range(4.0, 48.0, 1.0) var portal_trigger_radius: float = 12.0
@export var portal_trigger_local_offset: Vector2 = Vector2(0, -65)
@export var portal_arrival_offset: Vector2 = Vector2(0, 54)
@export_range(0.0, 2.0, 0.05) var portal_arrival_animation_delay_seconds: float = 0.50
@export var portal_spawn_floor_half_extents_tiles: Vector2i = Vector2i(3, 2)
@export_range(0, 8, 1) var portal_spawn_wall_clearance_tiles: int = 3
@export_range(0.0, 32.0, 0.5) var portal_spawn_collision_probe_radius: float = 8.0
@export_range(0, 4, 1) var portal_spawn_nudge_radius_tiles: int = 2
@export_group("Interior Props", "interior_prop")
@export var interior_prop_spawning_enabled: bool = true
@export_range(0, 80, 1) var interior_prop_count: int = 24
@export_range(1, 8, 1) var interior_prop_min_distance_tiles: int = 3
@export_range(0, 4, 1) var interior_prop_wall_clearance_tiles: int = 0
@export_range(0, 6, 1) var interior_prop_threshold_clearance_tiles: int = 1
@export var interior_prop_jitter_amplitude: Vector2 = Vector2(6, 4)
@export var interior_prop_allow_flip_h: bool = false
@export var interior_prop_debug_logging: bool = false
@export_group("", "")
@export_group("Elevation Metadata", "elevation")
@export var elevation_metadata_enabled: bool = true
@export var elevation_platform_stamps_enabled: bool = true
@export var terrain_builder_mountain_boundary_enabled: bool = true
@export var terrain_builder_debug_logging: bool = true
@export var terrain_debug_overlay: Node2D
@export var elevation_platform_min_size: Vector2i = Vector2i(7, 5)
@export var elevation_platform_max_size: Vector2i = Vector2i(12, 8)
@export_group("", "")
@export_group("World Progression", "world_progress")
@export var world_progression_enabled: bool = true
@export_file("*.json") var world_progress_profile_path: String = "res://content/procgen/world_profiles/sundered_keep_ascent.json"
@export var world_progress_debug_logging: bool = true
@export var ascent_route_enabled: bool = true
@export_group("", "")
@export_group("Faction Ambient Sites", "faction_ambient")
@export var faction_ambient_sites_enabled: bool = true
@export_range(0, 64, 1) var faction_ambient_site_count: int = 18
@export_group("", "")
@export_group("Story Rooms", "story_room")
@export var story_rooms_enabled: bool = true
@export_range(0, 32, 1) var story_room_count: int = 8
@export_group("", "")
@export_group("Worldgen Intent", "worldgen_intent")
@export var worldgen_intent_enabled: bool = true
@export_range(1, 16, 1) var worldgen_intent_route_beat_count: int = 7
@export var worldgen_intent_carve_before_detail: bool = true
@export var worldgen_intent_debug_logging: bool = true
@export_group("", "")

var _foliage_parent: Node2D = null
var _road_piece_parent: Node2D = null
var _road_piece_defs_by_mask: Dictionary = {}
var _road_piece_defs_by_role: Dictionary = {}
var _path_piece_defs_by_mask: Dictionary = {}
var _road_piece_nodes: Array[Node2D] = []
var _road_piece_nodes_by_key: Dictionary = {}
var _ruin_prop_parent: Node2D = null
var _ruin_prop_scatterer: PropScatterer = null
var elevation_map: Node = null
var _terrain_builder: RefCounted = null
var _last_terrain_result: Dictionary = {}
var _last_pre_terrain_connectivity: Dictionary = {}
var _last_floor_value_cluster_summary: Dictionary = {}
var _combat_readability_timer: float = 0.0
var _interior_prop_nodes: Array[Node2D] = []
var _portal_teleporters: Array[Area2D] = []
var _foliage_nodes: Dictionary = {}
var _foliage_textures: Array[Texture2D] = []
var _pending_foliage_tiles: Array[Vector2i] = []
var _foliage_spawn_generation: int = 0
var _foliage_deferred_start_msec: int = 0
var _interior_prop_textures: Array[Texture2D] = []
var _fruit_texture: Texture2D = null
var _fruit_sprites: Array[Node2D] = []
var _foliage_spawner: ProcgenFoliageSpawner = null
var _planet_world_profile: Dictionary = {}
var _world_progress_profile = null
var _world_progress_samples: Dictionary = {}
var _faction_activity_sites: Array[Dictionary] = []
var _story_room_sites: Array[Dictionary] = []
var _special_room_sites: Array[Dictionary] = []
var _faction_site_placer: RefCounted = null
var _story_room_placer: RefCounted = null
var _faction_site_geometry_stamper: RefCounted = null
var _story_room_geometry_stamper: RefCounted = null
var _worldgen_intent_graph = null
var _worldgen_reserved_regions: Array[Dictionary] = []
var _worldgen_intent_floor_cells: Dictionary = {}
var _ascent_field_summary: Dictionary = {}
var _ascent_field_main_route_cells: Array[Vector2i] = []
var _ascent_field_vista_cells: Array[Vector2i] = []
var _world_progress_marker_parent: Node2D = null
var _debug_generation_id: int = 0
var _generation_prop_rejections_protected_zone: int = 0
var _generation_prop_rejections_stuck_risk: int = 0
var _generation_prop_rejections_existing_blocker: int = 0
var _generation_prop_collision_alignment_warnings: int = 0

func _ready() -> void:
	if not generation_output_enabled:
		return
	add_to_group("procgen_tilemap")
	add_to_group("procgen_walkability_provider")
	add_to_group("terrain_ballistics_provider")
	# Auto-find ProcGen if not assigned
	if not procgen_node:
		procgen_node = find_child("ProcGen", true, false) as ProcGen

	if not floor_tilemap:
		floor_tilemap = find_child("Floor", true, false) as TileMapLayer

	if not walls_tilemap:
		walls_tilemap = find_child("Walls", true, false) as TileMapLayer

	if not nav_region:
		nav_region = find_child("NavigationRegion2D", true, false) as NavigationRegion2D

	_ensure_elevation_map()
	if shadow_system == null:
		shadow_system = find_child("ShadowOverlay", true, false)
	_foliage_parent = _find_foliage_parent()
	_road_piece_parent = _find_or_create_road_piece_parent()
	_load_road_piece_manifest()
	_ruin_prop_parent = _find_ruin_prop_parent()
	_world_progress_marker_parent = _find_or_create_world_progress_marker_parent()
	_load_foliage_textures()
	_load_interior_prop_textures()
	_apply_planet_visual_profile()

	if procgen_node:
		procgen_node.finished.connect(_on_procgen_finished)


func _process(delta: float) -> void:
	if _generated_floor_cells.is_empty() and _generated_wall_cells.is_empty():
		return
	if enable_final_foliage and not _pending_foliage_tiles.is_empty():
		_process_foliage_spawn_queue()
	if not _is_attached_to_runtime_world():
		return

	if _streaming_player == null or not is_instance_valid(_streaming_player):
		_streaming_player = get_tree().get_first_node_in_group("player") as Node2D

	if _streaming_player != null:
		_update_combat_readability_state(delta)
		if debug_log_floor_source_under_player:
			debug_print_floor_tile_at_global(_streaming_player.global_position)
		if enable_streaming_reveal:
			var player_tile := _global_to_tile(_streaming_player.global_position)
			var player_chunk := _tile_to_chunk(player_tile)
			if player_chunk != _streaming_current_chunk:
				_streaming_current_chunk = player_chunk
				_update_streaming_chunks(player_chunk, player_tile)
			_update_foliage_occlusion(_streaming_player)
		_update_ruin_prop_occlusion(_streaming_player)
	else:
		_combat_readability_timer = maxf(0.0, _combat_readability_timer - delta)

	if enable_streaming_reveal:
		_process_streaming_reveal_queue()


func _process_foliage_spawn_queue() -> void:
	if _pending_foliage_tiles.is_empty():
		return
	_ensure_foliage_spawner()
	if _foliage_deferred_start_msec == 0:
		_foliage_deferred_start_msec = Time.get_ticks_msec()
	var result: Dictionary = _foliage_spawner.process_pending(_build_foliage_spawner_context())
	if bool(result.get("deferred", false)) and _pending_foliage_tiles.is_empty():
		if foliage_debug_logging:
			print("[ProcGenTilemap] foliage_deferred_spawn_complete elapsed=%dms" % (Time.get_ticks_msec() - _foliage_deferred_start_msec))
		_foliage_deferred_start_msec = 0
		validate_no_stuck_pockets(runtime_blocker_remediate_stuck_pockets)


func _is_attached_to_runtime_world() -> bool:
	var parent_node := get_parent()
	return parent_node != null and String(parent_node.name) == "ProcGenRuntime"


func generate() -> void:
	if not generation_output_enabled:
		push_warning("ProcGenTilemap: generation output is disabled")
		return
	if not procgen_node:
		push_error("ProcGenTilemap: No ProcGen node assigned")
		return

	if not floor_tilemap or not walls_tilemap:
		push_error("ProcGenTilemap: Missing TileMapLayer references")
		return

	procgen_node.generate()


func get_floor_tilemap() -> TileMapLayer:
	return floor_tilemap


func get_walls_tilemap() -> TileMapLayer:
	return walls_tilemap


func apply_planet_world_profile(profile: Dictionary) -> void:
	_planet_world_profile = profile.duplicate(true)
	compound_area_ratio = clamp(float(_planet_world_profile.get("compound_area_ratio", compound_area_ratio)), 0.10, 0.20)
	open_layout_chance = clamp(float(_planet_world_profile.get("open_layout_chance", open_layout_chance)), 0.0, 1.0)
	open_layout_carve_ratio = clamp(float(_planet_world_profile.get("open_layout_carve_ratio", open_layout_carve_ratio)), 0.0, 0.6)
	foliage_density = max(0.0, float(_planet_world_profile.get("foliage_density", foliage_density)))
	foliage_compound_density_multiplier = clamp(float(_planet_world_profile.get("foliage_compound_density_multiplier", foliage_compound_density_multiplier)), 0.0, 1.0)
	fruit_spawn_chance_shrub = clamp(float(_planet_world_profile.get("fruit_spawn_chance_shrub", fruit_spawn_chance_shrub)), 0.0, 1.0)
	fruit_spawn_chance_tree = clamp(float(_planet_world_profile.get("fruit_spawn_chance_tree", fruit_spawn_chance_tree)), 0.0, 1.0)
	foliage_wind_speed = clampf(float(_planet_world_profile.get("foliage_wind_speed", foliage_wind_speed)), 0.0, 4.0)
	foliage_shrub_wind_strength_px = clampf(float(_planet_world_profile.get("foliage_shrub_wind_strength_px", foliage_shrub_wind_strength_px)), 0.0, 2.0)
	foliage_tree_wind_strength_px = clampf(float(_planet_world_profile.get("foliage_tree_wind_strength_px", foliage_tree_wind_strength_px)), 0.0, 3.0)
	foliage_wind_gust_amount = clampf(float(_planet_world_profile.get("foliage_wind_gust_amount", foliage_wind_gust_amount)), 0.0, 1.0)
	_apply_planet_visual_profile()


func get_planet_world_profile() -> Dictionary:
	return _planet_world_profile.duplicate(true)


## Emitted when level data is ready (after generation)
signal level_data_ready(data: Dictionary)
signal minimap_tile_changed(tile: Vector2i, terrain_kind: String)


func _on_procgen_finished() -> void:
	_debug_generation_id += 1
	_reset_generation_prop_observability()
	var mode := "EVAL_CANDIDATE" if generation_evaluation_mode else "FINAL_VISUAL"
	var seed_text := "unknown"
	if procgen_node != null:
		seed_text = str(procgen_node.seed)
	print("[ProcGenTilemap] GEN_BEGIN id=%d mode=%s seed=%s path=%s output_enabled=%s" % [
		_debug_generation_id,
		mode,
		seed_text,
		str(get_path()),
		str(generation_output_enabled),
	])
	var _t_start := Time.get_ticks_msec()
	_fill_tilemaps()
	var _t_fill := Time.get_ticks_msec() - _t_start
	_refresh_shadows()
	var _t_shadows := Time.get_ticks_msec() - _t_start - _t_fill

	var _t_nav := 0
	if auto_bake_nav and nav_region and not generation_evaluation_mode:
		nav_region.bake_navigation_polygon(false)
		_t_nav = Time.get_ticks_msec() - _t_start - _t_fill - _t_shadows

	# Emit level data for game systems to use
	var data = get_level_data()
	level_data_ready.emit(data)

	print("[ProcGenTilemap] GEN_END id=%d mode=%s seed=%s total=%dms" % [
		_debug_generation_id,
		mode,
		seed_text,
		Time.get_ticks_msec() - _t_start,
	])

	print("[ProcGen] === PIPELINE TIMING ===")
	print("[ProcGen]   mode: %s" % mode)
	print("[ProcGen]   seed: %s" % seed_text)
	print("[ProcGen]   fill_tilemaps: %d ms" % _t_fill)
	print("[ProcGen]   refresh_shadows: %d ms" % _t_shadows)
	if _t_nav > 0:
		print("[ProcGen]   nav_bake: %d ms" % _t_nav)
	print("[ProcGen]   TOTAL: %d ms" % (Time.get_ticks_msec() - _t_start))


func _fill_tilemaps() -> void:
	var _t_start := Time.get_ticks_msec()
	var _marks := {}
	var _last := _t_start

	if clear_first:
		floor_tilemap.clear()
		walls_tilemap.clear()
		_wall_health.clear()
		_clear_region_metadata()
		_clear_elevation_metadata()
		_clear_foliage()
		_clear_road_piece_decals()
		_clear_interior_props()
		_clear_ruin_props()
		_clear_horizontal_wall_overlays()
		_clear_runtime_wall_collision()
		_clear_world_progression_runtime()
		_rebuild_runtime_wall_collision_debug()
	_marks["setup_clear"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()
	_apply_planet_visual_profile()

	var map_size = procgen_node.map_size
	_ensure_world_progress_profile()
	_ensure_site_placers()
	_marks["planet_profile"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if world_shape_mode == WorldShapeMode.LEGACY_CAVE:
		_fill_legacy_cave_substrate(map_size)
		if worldgen_intent_enabled:
			_build_worldgen_intent_graph(map_size)
			if worldgen_intent_carve_before_detail:
				_apply_worldgen_intent_floor_cells(map_size)
		_marks["substrate_legacy"] = Time.get_ticks_msec() - _last
	else:
		_fill_ascent_field_substrate(map_size)
		_marks["substrate_ascent"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if enable_compound_zone:
		_apply_compound_layout(map_size)
	if interior_region_enabled:
		_apply_constructed_interior_region(map_size)
	if intent_spawn_clearing_enabled:
		_stamp_spawn_clearing(map_size)
	_marks["compound_interior_spawn"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if intent_soft_paths_enabled:
		_carve_interest_paths(map_size)
	_marks["interest_paths"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if intent_main_roads_enabled:
		_carve_main_roads(map_size)
	if use_cohesive_wall_visuals:
		_apply_wall_visuals(map_size)
	_protect_compound_ingress_tiles(map_size)
	_enforce_road_walkability(map_size)
	_prune_small_edge_road_components(map_size)
	_refresh_road_path_visuals()
	_capture_generated_tile_state(map_size)
	_marks["roads_walls_capture"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if elevation_metadata_enabled:
		_apply_terrain_builder(map_size)
		_protect_compound_ingress_tiles(map_size)
		_enforce_road_walkability(map_size)
		_repair_road_surface_components(map_size, maxi(1, intent_main_road_half_width - 1))
		_apply_compound_connector_elevation(map_size)
		_prune_small_edge_road_components(map_size)
		_refresh_road_path_visuals()
		_capture_generated_tile_state(map_size)
	_marks["terrain_elevation"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if world_progression_enabled:
		_build_world_progress_samples(map_size)
	if faction_ambient_sites_enabled:
		_place_faction_ambient_sites(map_size)
		_stamp_worldgen_faction_site_geometry()
	if story_rooms_enabled:
		_place_story_rooms(map_size)
		_stamp_worldgen_story_room_geometry()
	_marks["progress_faction_story"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if intent_main_roads_enabled:
		_repair_road_surface_components(map_size, maxi(1, intent_main_road_half_width - 1))
		_enforce_road_walkability(map_size)
		_prune_small_edge_road_components(map_size)
		_refresh_road_path_visuals()
		_refresh_compound_connector_pack_visuals(map_size)
		_capture_generated_tile_state(map_size)
	_marks["roads_pass2"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if not generation_evaluation_mode:
		_apply_floor_value_clusters(
			_last_terrain_result,
			int(procgen_node.seed) if procgen_node != null else 0
		)
		_marks["floor_value_clusters"] = Time.get_ticks_msec() - _last
	else:
		_marks["floor_value_clusters"] = 0
	_last = Time.get_ticks_msec()

	if enable_streaming_reveal:
		_prepare_streaming_reveal()
	elif build_runtime_wall_collision:
		_rebuild_runtime_wall_collision(map_size)
	_marks["streaming_reveal_or_walls"] = Time.get_ticks_msec() - _last
	_last = Time.get_ticks_msec()

	if not generation_evaluation_mode:
		if enable_streaming_reveal:
			print("[ProcGenTilemap] props_foliage SKIP mode=FINAL_VISUAL_STREAMING_REVEAL")
			_marks["props_foliage"] = 0
			_last = Time.get_ticks_msec()
			_generate_ruin_props(map_size)
			_generate_interior_props(map_size)
		else:
			print("[ProcGenTilemap] props_foliage %s mode=FINAL_VISUAL" % ("RUN" if enable_final_foliage else "SKIP"))
			if enable_final_foliage:
				_generate_foliage(map_size)
			_marks["props_foliage"] = Time.get_ticks_msec() - _last
			_last = Time.get_ticks_msec()
			_generate_ruin_props(map_size)
			_generate_interior_props(map_size)
		_marks["props_visual"] = Time.get_ticks_msec() - _last
	else:
		print("[ProcGenTilemap] props_foliage SKIP mode=EVAL_CANDIDATE")
		_marks["props_foliage"] = 0
		_marks["props_visual"] = 0
	_last = Time.get_ticks_msec()

	if not generation_evaluation_mode and not enable_streaming_reveal:
		_rebuild_horizontal_wall_overlays()
	_marks["horiz_wall_overlays"] = Time.get_ticks_msec() - _last
	if debug_log_terrain_source_usage:
		var usage := debug_dump_runtime_tileset_source_usage()
		print("[TerrainRuntimeTiles] floor_source_counts=%s" % str(usage["floor_source_counts"]))
		print("[TerrainRuntimeTiles] wall_source_counts=%s" % str(usage["wall_source_counts"]))
		print("[TerrainRuntimeTiles] gameplay_pack_counts=%s" % str(usage["gameplay_pack_counts"]))

	# Print timing summary
	var _total := Time.get_ticks_msec() - _t_start
	print("[ProcGen] === FILL_TILEMAPS PHASES ===")
	for _k in _marks:
		print("[ProcGen]   %s: %d ms" % [_k, _marks[_k]])
	print("[ProcGen]   FILL_TILEMAPS TOTAL: %d ms" % _total)


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


func _apply_floor_value_clusters(result: Dictionary, seed: int) -> void:
	_last_floor_value_cluster_summary = {
		"clusters": 0,
		"cells_changed": 0,
		"skipped": 0,
		"changed_cells": [],
	}
	if not floor_value_clusters_enabled or floor_value_cluster_strength <= 0.0:
		return
	if floor_tilemap == null or walls_tilemap == null:
		return

	var variant_sources := _get_floor_value_cluster_variant_sources()
	if variant_sources.size() < 2:
		print("[ProcGen] floor_value_clusters SKIP no registered floor value variants")
		return

	var map_size := procgen_node.map_size if procgen_node != null else _used_floor_bounds_size()
	var required_lookup := {}
	if procgen_node != null:
		for required_cell in _collect_terrain_required_cells(map_size):
			required_lookup[required_cell] = true

	var eligible_cells: Array[Vector2i] = []
	var skipped := 0
	for cell_variant in _generated_floor_cells.keys():
		if not (cell_variant is Vector2i):
			continue
		var cell := cell_variant as Vector2i
		if _is_floor_value_cluster_cell_safe(cell, variant_sources, required_lookup, result):
			eligible_cells.append(cell)
		else:
			skipped += 1
	eligible_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	if eligible_cells.is_empty():
		_last_floor_value_cluster_summary["skipped"] = skipped
		if floor_value_cluster_debug:
			print("[ProcGen] floor_value_clusters: clusters=0 cells_changed=0 skipped=%d" % skipped)
		return

	var map_area := maxi(1, map_size.x * map_size.y)
	var cluster_count := clampi(int(round(float(map_area) / 1400.0)), 12, 35)
	cluster_count = mini(cluster_count, eligible_cells.size())
	var clusters: Array[Dictionary] = []
	for cluster_index in range(cluster_count):
		var center_hash := _floor_value_cluster_hash(Vector2i(cluster_index, cluster_index * 17), seed, 101)
		var radius_hash := _floor_value_cluster_hash(Vector2i(cluster_index, 0), seed, 211)
		var strength_hash := _floor_value_cluster_hash(Vector2i(0, cluster_index), seed, 307)
		var family_hash := _floor_value_cluster_hash(Vector2i(cluster_index, cluster_index), seed, 401)
		clusters.append({
			"center": eligible_cells[center_hash % eligible_cells.size()],
			"radius": 3.0 + float(radius_hash % 7),
			"strength": (0.15 + float(strength_hash % 301) / 1000.0) * floor_value_cluster_strength,
			"source_id": variant_sources[family_hash % variant_sources.size()],
			"salt": cluster_index,
		})

	var changed_cells: Array[Vector2i] = []
	for cell in eligible_cells:
		var total_score := 0.0
		var dominant_score := 0.0
		var dominant_cluster: Dictionary = {}
		for cluster in clusters:
			var center: Vector2i = cluster["center"]
			var radius := float(cluster["radius"])
			var distance := cell.distance_to(center)
			if distance >= radius:
				continue
			var contribution := float(cluster["strength"]) * (1.0 - distance / radius)
			total_score += contribution
			if contribution > dominant_score:
				dominant_score = contribution
				dominant_cluster = cluster
		if dominant_cluster.is_empty():
			continue
		var fleck_noise := _floor_value_cluster_noise(cell, seed, 503)
		var island_noise := _floor_value_cluster_noise(cell / 2, seed, 607)
		var threshold := 0.27 + (island_noise - 0.5) * 0.10
		if total_score + fleck_noise * 0.12 <= threshold:
			continue
		# Sparse deterministic holes/flecks break up circular falloff boundaries.
		if fleck_noise < 0.14 and dominant_score < 0.30:
			continue
		var source_id := int(dominant_cluster["source_id"])
		var existing_source := floor_tilemap.get_cell_source_id(cell)
		if source_id == existing_source:
			var current_index := variant_sources.find(source_id)
			source_id = variant_sources[(current_index + 1) % variant_sources.size()]
		var atlas := _floor_value_cluster_atlas_coord(cell, source_id, int(dominant_cluster["salt"]))
		floor_tilemap.set_cell(cell, source_id, atlas, 0)
		_generated_floor_cells[cell] = {
			"source_id": source_id,
			"atlas": atlas,
			"alternative": 0,
		}
		changed_cells.append(cell)

	_last_floor_value_cluster_summary = {
		"clusters": clusters.size(),
		"cells_changed": changed_cells.size(),
		"skipped": skipped,
		"changed_cells": changed_cells,
	}
	if floor_value_cluster_debug:
		print("[ProcGen] floor_value_clusters: clusters=%d cells_changed=%d skipped=%d" % [
			clusters.size(),
			changed_cells.size(),
			skipped,
		])


func get_last_floor_value_cluster_summary() -> Dictionary:
	return _last_floor_value_cluster_summary.duplicate(true)


func _get_floor_value_cluster_variant_sources() -> Array[int]:
	var requested := floor_value_cluster_variant_source_ids.duplicate()
	if requested.is_empty():
		requested.append(floor_source_id)
		requested.append_array(alternate_floor_source_ids)
	var valid: Array[int] = []
	if floor_tilemap == null or floor_tilemap.tile_set == null:
		return valid
	for source_id in requested:
		if valid.has(source_id) or not floor_tilemap.tile_set.has_source(source_id):
			continue
		var source := floor_tilemap.tile_set.get_source(source_id) as TileSetAtlasSource
		if source != null and source.has_tile(Vector2i.ZERO):
			valid.append(source_id)
	return valid


func _is_floor_value_cluster_cell_safe(
	cell: Vector2i,
	variant_sources: Array[int],
	required_lookup: Dictionary,
	result: Dictionary
) -> bool:
	if not _generated_floor_cells.has(cell) or _generated_wall_cells.has(cell):
		return false
	if walls_tilemap.get_cell_source_id(cell) >= 0:
		return false
	if required_lookup.has(cell) \
			or _last_interior_thresholds.has(cell) \
			or _last_compound_ingress.has(cell) \
			or _road_centerline_tiles.has(cell) \
			or _path_centerline_tiles.has(cell):
		return false
	if _is_combat_readability_floor_tile(cell):
		return false
	var source_id := floor_tilemap.get_cell_source_id(cell)
	if not variant_sources.has(source_id):
		return false
	var elevation_data := get_elevation_data_at_tile(cell)
	if int(elevation_data.get("height", 0)) != 0 \
			or String(elevation_data.get("traversal_type", ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE)) != ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE:
		return false
	var tile_by_cell: Dictionary = result.get("tile_by_cell", {})
	if not String(tile_by_cell.get(cell, "")).is_empty():
		return false
	var region_type := get_region_type_at_tile(cell).to_lower()
	for blocked_token in [
		"road", "path", "parking", "connector", "rescue", "spawn", "portal",
		"interior", "threshold", "door", "gate", "objective", "authored",
		"reserved", "compound", "elevation", "mountain", "drop", "ledge",
	]:
		if region_type.contains(blocked_token):
			return false
	return true


func _is_combat_readability_floor_tile(tile: Vector2i) -> bool:
	var region := get_region_type_at_tile(tile).to_lower()
	match region:
		"spawn_clearing", \
		"soft_path", \
		"main_road", \
		"parking_zone", \
		"portal_plaza", \
		"compound_approach", \
		"compound_ingress", \
		"compound_connector_road", \
		"compound_connector_ramp", \
		"compound_connector_elevated_road", \
		"terrain_elevation_access", \
		"terrain_rescue_floor":
			return true
	if region.begins_with("faction_") or region.begins_with("story_room_"):
		return true
	return false


func _floor_value_cluster_atlas_coord(cell: Vector2i, source_id: int, salt: int) -> Vector2i:
	if full_grid_floor_source_ids.has(source_id):
		var width := maxi(1, full_grid_floor_dimensions.x)
		var height := maxi(1, full_grid_floor_dimensions.y)
		var hashed := _floor_value_cluster_hash(cell, source_id, 701 + salt)
		return Vector2i(hashed % width, int(hashed / width) % height)
	return floor_atlas_coord


func _floor_value_cluster_hash(cell: Vector2i, seed: int, salt: int) -> int:
	var hashed := int(cell.x) * 73856093
	hashed ^= int(cell.y) * 19349663
	hashed ^= seed * 83492791
	hashed ^= salt * 2654435761
	return absi(hashed)


func _floor_value_cluster_noise(cell: Vector2i, seed: int, salt: int) -> float:
	return float(_floor_value_cluster_hash(cell, seed, salt) % 10000) / 9999.0


func _used_floor_bounds_size() -> Vector2i:
	if floor_tilemap == null:
		return Vector2i.ONE
	var used_rect := floor_tilemap.get_used_rect()
	return Vector2i(maxi(1, used_rect.size.x), maxi(1, used_rect.size.y))


func _is_gameplay_pack_source_id(source_id: int) -> bool:
	return (source_id >= 60 and source_id <= 77) \
			or (source_id >= 80 and source_id <= 99) \
			or (source_id >= 100 and source_id <= 123)


func debug_dump_runtime_tileset_source_usage() -> Dictionary:
	var floor_source_counts := {}
	var wall_source_counts := {}
	var gameplay_pack_counts := {
		"connector": 0,
		"ascent": 0,
		"chasm_bridge": 0,
	}
	if floor_tilemap != null:
		_count_tilemap_source_usage(floor_tilemap, floor_source_counts, gameplay_pack_counts)
	if walls_tilemap != null:
		_count_tilemap_source_usage(walls_tilemap, wall_source_counts, gameplay_pack_counts)
	return {
		"floor_source_counts": floor_source_counts,
		"wall_source_counts": wall_source_counts,
		"gameplay_pack_counts": gameplay_pack_counts,
	}


func _count_tilemap_source_usage(tilemap: TileMapLayer, source_counts: Dictionary, gameplay_pack_counts: Dictionary) -> void:
	for cell in tilemap.get_used_cells():
		var source_id := tilemap.get_cell_source_id(cell)
		if source_id < 0:
			continue
		source_counts[source_id] = int(source_counts.get(source_id, 0)) + 1
		if not _is_gameplay_pack_source_id(source_id):
			continue
		if source_id <= 77:
			gameplay_pack_counts["connector"] = int(gameplay_pack_counts["connector"]) + 1
		elif source_id <= 99:
			gameplay_pack_counts["ascent"] = int(gameplay_pack_counts["ascent"]) + 1
		else:
			gameplay_pack_counts["chasm_bridge"] = int(gameplay_pack_counts["chasm_bridge"]) + 1


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
	var source_id := _select_interior_surface_source_id(pos, zone)
	floor_tilemap.set_cell(pos, source_id, interior_tile_atlas_coord, _select_interior_surface_alternative(pos, zone))
	walls_tilemap.erase_cell(pos)
	_wall_health.erase(pos)


func _select_interior_surface_source_id(pos: Vector2i, zone: String = "") -> int:
	if zone == "doorway" and not interior_doorway_source_ids.is_empty():
		return _select_interior_opening_source_id(interior_doorway_source_ids)
	if zone == "threshold" and not interior_threshold_source_ids.is_empty():
		return _select_interior_opening_source_id(interior_threshold_source_ids)
	return _select_interior_floor_source_id(pos, zone)


func _select_interior_surface_alternative(pos: Vector2i, zone: String = "") -> int:
	if zone == "doorway" or zone == "threshold":
		return 0
	return _select_interior_floor_alternative(pos, zone)


func _select_interior_opening_source_id(source_ids: Array[int]) -> int:
	return source_ids[0]


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


func _is_tile_inside_map(tile: Vector2i, map_size: Vector2i, margin: int = 1) -> bool:
	return tile.x >= margin and tile.y >= margin and tile.x < map_size.x - margin and tile.y < map_size.y - margin


func _stamp_spawn_clearing(map_size: Vector2i) -> void:
	if procgen_node == null:
		return
	var spawn := get_player_spawn()
	var half_extents := Vector2i(
		maxi(0, intent_spawn_clearing_half_extents_tiles.x),
		maxi(0, intent_spawn_clearing_half_extents_tiles.y)
	)
	for x in range(-half_extents.x, half_extents.x + 1):
		for y in range(-half_extents.y, half_extents.y + 1):
			var tile := spawn + Vector2i(x, y)
			if not _is_tile_inside_map(tile, map_size, 1):
				continue
			_set_floor_tile(tile)
			_set_region_tile(tile, "spawn_clearing", "safe")


func _carve_main_roads(map_size: Vector2i) -> void:
	_main_road_tiles.clear()
	_road_centerline_tiles.clear()
	_road_visual_tiles.clear()
	_compound_connector_centerline_tiles.clear()
	_compound_connector_visual_candidates.clear()
	_parking_zone_tiles.clear()
	if procgen_node == null:
		return

	var spawn := get_player_spawn()
	var road_width := maxi(1, intent_main_road_half_width)
	var compound_anchor := _pick_primary_road_compound_anchor(spawn)
	var trunk_anchor := compound_anchor if compound_anchor != Vector2i.ZERO else spawn
	var required_road_anchors: Array[Vector2i] = [spawn, trunk_anchor]
	var road_targets: Array[Vector2i] = []
	for threshold in _last_interior_thresholds:
		road_targets.append(threshold)
	if road_targets.is_empty():
		for room_center in get_rooms_by_distance_from_spawn().slice(0, 3):
			road_targets.append(room_center)

	if trunk_anchor != spawn:
		_carve_main_road_path(spawn, trunk_anchor, road_width, map_size)
	for ingress in _last_compound_ingress:
		if ingress != trunk_anchor:
			_carve_main_road_path(trunk_anchor, ingress, road_width, map_size)
		required_road_anchors.append(ingress)
	for target in road_targets:
		if target != trunk_anchor:
			_carve_main_road_path(trunk_anchor, target, maxi(1, road_width - 1), map_size)
		required_road_anchors.append(target)

	if intent_compound_connector_corridor_enabled:
		_carve_compound_connector_corridor(spawn, trunk_anchor, map_size)
	if not _compound_connector_centerline_tiles.is_empty():
		required_road_anchors.append(_compound_connector_centerline_tiles.back())
	_repair_road_connectivity(required_road_anchors, trunk_anchor, road_width, map_size)
	var parking_anchor := _pick_parking_anchor(spawn, trunk_anchor, map_size)
	_carve_main_road_path(spawn, parking_anchor, maxi(1, road_width - 1), map_size)
	_stamp_parking_zone(parking_anchor, map_size)
	_repair_road_surface_components(map_size, maxi(1, road_width - 1))


func _pick_primary_road_compound_anchor(spawn: Vector2i) -> Vector2i:
	if _last_compound_ingress.is_empty():
		return Vector2i.ZERO
	if _last_compound_rect.size.x > 0:
		for ingress in _last_compound_ingress:
			if ingress == _last_compound_ingress[0]:
				return ingress
	return _pick_closest_road_target(spawn, _last_compound_ingress)


func _repair_road_connectivity(required_anchors: Array[Vector2i], root_anchor: Vector2i, width: int, map_size: Vector2i) -> void:
	if required_anchors.is_empty() or _main_road_tiles.is_empty():
		return
	var root := root_anchor
	if not _main_road_tiles.has(root):
		root = required_anchors[0]
	for anchor in required_anchors:
		if _main_road_tiles.has(anchor):
			root = anchor
			break
	var connected := _collect_connected_road_tiles(root)
	for anchor in required_anchors:
		if not _is_tile_inside_map(anchor, map_size, 1):
			continue
		if connected.has(anchor):
			continue
		_carve_main_road_path(root, anchor, maxi(1, width), map_size)
		connected = _collect_connected_road_tiles(root)


func _repair_road_surface_components(map_size: Vector2i, width: int) -> void:
	var components := _collect_road_surface_components()
	if components.size() <= 1:
		return
	components.sort_custom(func(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
		return a.size() > b.size()
	)
	var primary: Array[Vector2i] = components[0]
	for index in range(1, components.size()):
		var component: Array[Vector2i] = components[index]
		var pair := _find_nearest_road_component_pair(primary, component)
		if pair.size() != 2:
			continue
		_carve_main_road_path(pair[0], pair[1], maxi(1, width), map_size)
		primary = _dict_keys_as_vector2i_array(_collect_connected_road_tiles(primary[0]))


func _collect_road_surface_components() -> Array[Array]:
	var components: Array[Array] = []
	var remaining := {}
	for tile_variant in _main_road_tiles.keys():
		if tile_variant is Vector2i:
			remaining[tile_variant] = true
	while not remaining.is_empty():
		var start := remaining.keys()[0] as Vector2i
		var component: Array[Vector2i] = []
		var frontier: Array[Vector2i] = [start]
		remaining.erase(start)
		while not frontier.is_empty():
			var tile: Vector2i = frontier.pop_front()
			component.append(tile)
			for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var next: Vector2i = tile + direction
				if not remaining.has(next):
					continue
				remaining.erase(next)
				frontier.append(next)
		components.append(component)
	return components


func _find_nearest_road_component_pair(primary: Array[Vector2i], component: Array[Vector2i]) -> Array[Vector2i]:
	if primary.is_empty() or component.is_empty():
		return []
	var best_from := primary[0]
	var best_to := component[0]
	var best_dist := best_from.distance_squared_to(best_to)
	for from_tile in primary:
		for to_tile in component:
			var dist := from_tile.distance_squared_to(to_tile)
			if dist < best_dist:
				best_dist = dist
				best_from = from_tile
				best_to = to_tile
	return [best_from, best_to]


func _prune_small_edge_road_components(map_size: Vector2i) -> void:
	for component_variant in _collect_road_surface_components():
		var component := component_variant as Array[Vector2i]
		if component.size() >= 32 or not _road_component_touches_edge(component, map_size):
			continue
		for tile in component:
			_main_road_tiles.erase(tile)
			_road_centerline_tiles.erase(tile)
			_road_visual_tiles.erase(tile)
			_parking_zone_tiles.erase(tile)
			var region := get_region_type_at_tile(tile)
			if region == "main_road" or region == "compound_connector_road" or region == "parking_zone":
				_region_tiles.erase(tile)
			_remove_road_piece_decal(tile)


func _road_component_touches_edge(component: Array[Vector2i], map_size: Vector2i) -> bool:
	for tile in component:
		if tile.x <= 2 or tile.y <= 2 or tile.x >= map_size.x - 3 or tile.y >= map_size.y - 3:
			return true
	return false


func _collect_connected_road_tiles(root: Vector2i) -> Dictionary:
	var visited: Dictionary = {}
	if not _main_road_tiles.has(root):
		return visited
	var frontier: Array[Vector2i] = [root]
	visited[root] = true
	while not frontier.is_empty():
		var tile: Vector2i = frontier.pop_front()
		for dir in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = tile + dir
			if visited.has(next) or not _main_road_tiles.has(next):
				continue
			visited[next] = true
			frontier.append(next)
	return visited


func _pick_closest_road_target(anchor: Vector2i, targets: Array[Vector2i]) -> Vector2i:
	if targets.is_empty():
		return anchor
	var best := targets[0]
	var best_dist := best.distance_squared_to(anchor)
	for target in targets:
		var dist := target.distance_squared_to(anchor)
		if dist < best_dist:
			best = target
			best_dist = dist
	return best


func _pick_road_edge_anchor(spawn: Vector2i, map_size: Vector2i) -> Vector2i:
	var anchors := [
		Vector2i(clampi(spawn.x, 2, map_size.x - 3), 2),
		Vector2i(clampi(spawn.x, 2, map_size.x - 3), map_size.y - 3),
		Vector2i(2, clampi(spawn.y, 2, map_size.y - 3)),
		Vector2i(map_size.x - 3, clampi(spawn.y, 2, map_size.y - 3)),
	]
	anchors.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_squared_to(spawn) < b.distance_squared_to(spawn)
	)
	return anchors[0]


func _pick_parking_anchor(spawn: Vector2i, primary_anchor: Vector2i, map_size: Vector2i) -> Vector2i:
	var direction := primary_anchor - spawn
	var halfway := spawn + Vector2i(int(round(float(direction.x) * 0.35)), int(round(float(direction.y) * 0.35)))
	var side := Vector2i(-_int_sign(direction.y), _int_sign(direction.x))
	if side == Vector2i.ZERO:
		side = Vector2i.RIGHT
	var offset_distance := intent_main_road_half_width + intent_parking_zone_half_extents_tiles.x + 1
	var candidate := halfway + side * offset_distance
	return Vector2i(
		clampi(candidate.x, 2 + intent_parking_zone_half_extents_tiles.x, map_size.x - 3 - intent_parking_zone_half_extents_tiles.x),
		clampi(candidate.y, 2 + intent_parking_zone_half_extents_tiles.y, map_size.y - 3 - intent_parking_zone_half_extents_tiles.y)
	)


func _int_sign(value: int) -> int:
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0


func _carve_main_road_path(from_tile: Vector2i, to_tile: Vector2i, width: int, map_size: Vector2i) -> void:
	var current := from_tile
	_road_centerline_tiles[current] = true
	_road_visual_tiles[current] = true
	_carve_road_brush(current, width, map_size)
	var step_index := 0
	var horizontal_first := (_tile_noise_hash(from_tile + to_tile + Vector2i(1709, 313)) % 2) == 0
	if horizontal_first:
		while current.x != to_tile.x:
			current.x += 1 if to_tile.x > current.x else -1
			_road_centerline_tiles[current] = true
			step_index += 1
			if step_index % maxi(1, road_piece_straight_stride_tiles) == 0:
				_road_visual_tiles[current] = true
			_carve_road_brush(current, width, map_size)
		while current.y != to_tile.y:
			current.y += 1 if to_tile.y > current.y else -1
			_road_centerline_tiles[current] = true
			step_index += 1
			if step_index % maxi(1, road_piece_straight_stride_tiles) == 0:
				_road_visual_tiles[current] = true
			_carve_road_brush(current, width, map_size)
	else:
		while current.y != to_tile.y:
			current.y += 1 if to_tile.y > current.y else -1
			_road_centerline_tiles[current] = true
			step_index += 1
			if step_index % maxi(1, road_piece_straight_stride_tiles) == 0:
				_road_visual_tiles[current] = true
			_carve_road_brush(current, width, map_size)
		while current.x != to_tile.x:
			current.x += 1 if to_tile.x > current.x else -1
			_road_centerline_tiles[current] = true
			step_index += 1
			if step_index % maxi(1, road_piece_straight_stride_tiles) == 0:
				_road_visual_tiles[current] = true
			_carve_road_brush(current, width, map_size)
	_road_visual_tiles[current] = true


func _carve_road_brush(center: Vector2i, width: int, map_size: Vector2i) -> void:
	for x in range(-width, width + 1):
		for y in range(-width, width + 1):
			var tile := center + Vector2i(x, y)
			if not _is_tile_inside_map(tile, map_size, 1):
				continue
			if is_indoor_tile(tile):
				continue
			if _is_road_blocked_by_impassable_authority(tile):
				continue
			_main_road_tiles[tile] = true
			_set_road_path_tile(tile, "road")
			_set_region_tile(tile, "main_road", "travel")


func _carve_compound_connector_corridor(spawn: Vector2i, primary_anchor: Vector2i, map_size: Vector2i) -> void:
	if _last_compound_rect.size.x <= 0 or _last_compound_ingress.is_empty():
		return
	var ingress := _last_compound_ingress[0]
	var outward := -_get_compound_ingress_inward(ingress, _last_compound_rect)
	if outward == Vector2i.ZERO:
		return
	var side_axis := Vector2i(-outward.y, outward.x)
	var length_min: int = mini(intent_compound_connector_min_length_tiles, intent_compound_connector_max_length_tiles)
	var length_max: int = maxi(intent_compound_connector_min_length_tiles, intent_compound_connector_max_length_tiles)
	var length: int = length_min + (_tile_noise_hash(ingress + Vector2i(2039, 577)) % maxi(1, length_max - length_min + 1))
	var width: int = maxi(1, intent_compound_connector_half_width)
	var wall_offset: int = width + maxi(1, intent_compound_connector_wall_gap_tiles)
	_compound_connector_centerline_tiles.clear()
	_compound_connector_visual_candidates.clear()

	var last_center := ingress
	for step in range(1, length + 1):
		var center := ingress + outward * step
		if not _is_tile_inside_map(center, map_size, wall_offset + 1):
			break
		last_center = center
		_compound_connector_centerline_tiles.append(center)
		_road_centerline_tiles[center] = true
		if step == 1 or step == length or step % maxi(1, road_piece_straight_stride_tiles) == 0:
			_road_visual_tiles[center] = true
		_carve_road_brush(center, width, map_size)
		for lateral in range(-width, width + 1):
			_compound_connector_visual_candidates[center + side_axis * lateral] = lateral == 0
		_set_region_tile(center, "compound_connector_road", "compound_ingress")
		for side in [-1, 1]:
			_stamp_compound_connector_wall(center + side_axis * int(side) * wall_offset, side_axis * int(side), map_size)

	if not _compound_connector_centerline_tiles.is_empty():
		_carve_main_road_path(spawn, last_center, maxi(1, width - 1), map_size)
		if primary_anchor != Vector2i.ZERO and primary_anchor != ingress:
			_carve_main_road_path(last_center, primary_anchor, maxi(1, width - 1), map_size)
		# Joining the corridor to the broader road graph repaints region metadata as
		# main_road. Restore the connector footprint label so the final visual pass
		# can select Connector Pack art without changing floor authority.
		for centerline_tile in _compound_connector_centerline_tiles:
			for lateral in range(-width, width + 1):
				var connector_tile := centerline_tile + side_axis * lateral
				if _main_road_tiles.has(connector_tile):
					_set_region_tile(connector_tile, "compound_connector_road", "compound_ingress")


func _stamp_compound_connector_wall(center: Vector2i, outward_axis: Vector2i, map_size: Vector2i) -> void:
	var wall_thickness := maxi(1, compound_wall_thickness)
	for offset in range(wall_thickness):
		var tile := center + outward_axis * offset
		if not _is_tile_inside_map(tile, map_size, 1):
			continue
		if _main_road_tiles.has(tile) or is_indoor_tile(tile):
			continue
		_set_wall_tile(tile)
		_set_region_tile(tile, "compound_connector_wall", "compound_ingress")


func _protect_compound_ingress_tiles(map_size: Vector2i) -> void:
	for ingress in _last_compound_ingress:
		if not _is_tile_inside_map(ingress, map_size, 1):
			continue
		_set_road_path_tile(ingress, "road")
		_main_road_tiles[ingress] = true
		_road_centerline_tiles[ingress] = true
		_road_visual_tiles[ingress] = true
		_set_region_tile(ingress, "compound_ingress", "compound_approach")


func _stamp_parking_zone(center: Vector2i, map_size: Vector2i) -> void:
	var half := Vector2i(
		maxi(1, intent_parking_zone_half_extents_tiles.x),
		maxi(1, intent_parking_zone_half_extents_tiles.y)
	)
	for x in range(-half.x, half.x + 1):
		for y in range(-half.y, half.y + 1):
			var tile := center + Vector2i(x, y)
			if not _is_tile_inside_map(tile, map_size, 1):
				continue
			if is_indoor_tile(tile):
				continue
			if _is_road_blocked_by_impassable_authority(tile):
				continue
			_main_road_tiles[tile] = true
			_parking_zone_tiles[tile] = true
			_set_road_path_tile(tile, "road")
			_set_region_tile(tile, "parking_zone", "vehicle_staging")
			if x == 0 or y == 0 or (abs(x) % 3 == 0 and abs(y) % 2 == 0):
				_road_centerline_tiles[tile] = true
				_road_visual_tiles[tile] = true


func _set_road_path_tile(pos: Vector2i, surface_kind: String = "road") -> void:
	if floor_tilemap == null or walls_tilemap == null:
		return
	if _is_road_blocked_by_impassable_authority(pos):
		_clear_procgen_road_authority_at(pos)
		return
	_set_floor_tile(pos)
	_clear_road_blocking_wall(pos)


func claim_procgen_floor_rect_for_authored_scene_world(
	global_center: Vector2,
	size_tiles: Vector2i,
	region_type: String = "authored_scene_floor",
	zone: String = "authored_scene",
	margin_tiles: int = 1
) -> Rect2i:
	return claim_procgen_floor_rect_for_authored_scene_tiles(
		_global_to_tile(global_center),
		size_tiles,
		region_type,
		zone,
		margin_tiles
	)


func claim_procgen_floor_rect_for_authored_scene_tiles(
	center_tile: Vector2i,
	size_tiles: Vector2i,
	region_type: String = "authored_scene_floor",
	zone: String = "authored_scene",
	margin_tiles: int = 1
) -> Rect2i:
	if floor_tilemap == null or walls_tilemap == null:
		return Rect2i()

	var footprint_size := Vector2i(maxi(1, size_tiles.x), maxi(1, size_tiles.y))
	var half_extents := Vector2i(
		int(floor(float(footprint_size.x) * 0.5)),
		int(floor(float(footprint_size.y) * 0.5))
	)
	var footprint_rect := Rect2i(center_tile - half_extents, footprint_size)
	var claim_rect := footprint_rect.grow(maxi(0, margin_tiles))
	var map_size := procgen_node.map_size if procgen_node != null else Vector2i(999999, 999999)

	for x in range(claim_rect.position.x, claim_rect.end.x):
		for y in range(claim_rect.position.y, claim_rect.end.y):
			var tile := Vector2i(x, y)
			if procgen_node != null and not _is_tile_inside_map(tile, map_size, 0):
				continue
			_clear_procgen_road_authority_at(tile)
			_force_authored_scene_floor_authority(tile, region_type, zone, false)

	if build_runtime_wall_collision:
		_sync_runtime_wall_collision_with_visible_walls()
	_rebuild_horizontal_wall_overlays()
	_refresh_shadows()
	_refresh_navigation_after_wall_change(true)
	return footprint_rect


func _force_authored_scene_floor_authority(tile: Vector2i, region_type: String, zone: String, refresh_collision_debug: bool = true) -> void:
	var source_id := _select_floor_source_id(tile)
	var atlas := _select_floor_coord(tile)
	_generated_floor_cells[tile] = {
		"source_id": source_id,
		"atlas": atlas,
		"alternative": 0,
	}
	floor_tilemap.set_cell(tile, source_id, atlas, 0)
	_clear_procgen_wall_authority_at(tile, refresh_collision_debug)
	_ensure_elevation_map()
	elevation_map.call(
		"set_cell",
		tile,
		ELEVATION_MAP_SCRIPT.DEFAULT_HEIGHT,
		ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE,
		ELEVATION_MAP_SCRIPT.DIRECTION_NONE
	)
	_set_region_tile(tile, region_type, zone)


func _clear_procgen_wall_authority_at(tile: Vector2i, refresh_collision_debug: bool = true) -> void:
	if walls_tilemap != null:
		walls_tilemap.erase_cell(tile)
	_wall_health.erase(tile)
	_generated_wall_cells.erase(tile)
	if build_runtime_wall_collision:
		_remove_runtime_wall_body(tile, refresh_collision_debug)
	_remove_foliage(tile)
	_remove_road_piece_decal(tile)


func _clear_procgen_road_authority_at(tile: Vector2i) -> void:
	_main_road_tiles.erase(tile)
	_road_centerline_tiles.erase(tile)
	_path_centerline_tiles.erase(tile)
	_road_visual_tiles.erase(tile)
	_path_visual_tiles.erase(tile)
	_compound_connector_centerline_tiles.erase(tile)
	_parking_zone_tiles.erase(tile)
	_remove_road_piece_decal(tile)


func _enforce_road_walkability(map_size: Vector2i) -> void:
	for tile_variant in _main_road_tiles.keys():
		if tile_variant is Vector2i:
			var tile := tile_variant as Vector2i
			if not _is_tile_inside_map(tile, map_size, 1) or is_indoor_tile(tile) or _is_road_blocked_by_impassable_authority(tile):
				_clear_procgen_road_authority_at(tile)
				continue
			_set_road_path_tile(tile, "road")
	for tile_variant in _region_tiles.keys():
		if not (tile_variant is Vector2i):
			continue
		var tile := tile_variant as Vector2i
		if get_region_type_at_tile(tile) != "soft_path":
			continue
		if not _is_tile_inside_map(tile, map_size, 1) or is_indoor_tile(tile) or _is_road_blocked_by_impassable_authority(tile):
			continue
		_set_road_path_tile(tile, "path")


func _clear_road_blocking_wall(pos: Vector2i) -> void:
	_clear_procgen_wall_authority_at(pos)


func _refresh_road_path_visuals() -> void:
	_clear_road_piece_decals()
	for tile_variant in _main_road_tiles.keys():
		if tile_variant is Vector2i:
			var road_tile := tile_variant as Vector2i
			if _is_road_blocked_by_impassable_authority(road_tile):
				_clear_procgen_road_authority_at(road_tile)
				continue
			if not _should_preserve_road_floor_visual(road_tile):
				_set_road_path_tile(road_tile, "road")
				_apply_connector_region_visual(road_tile)
	for tile_variant in _region_tiles.keys():
		if not (tile_variant is Vector2i):
			continue
		var tile := tile_variant as Vector2i
		if _main_road_tiles.has(tile):
			continue
		if get_region_type_at_tile(tile) == "soft_path":
			if _is_road_blocked_by_impassable_authority(tile):
				continue
			_set_road_path_tile(tile, "path")
	_spawn_road_piece_decals()


func _is_road_blocked_by_impassable_authority(tile: Vector2i) -> bool:
	var region_type := get_region_type_at_tile(tile)
	if region_type == "ascent_field_blocker" \
			or region_type == "terrain_mountain_wall" \
			or region_type == "terrain_blocked" \
			or region_type == "terrain_drop" \
			or region_type == "terrain_elevation_ledge" \
			or region_type == "compound_connector_wall":
		return true
	var wall_data: Variant = _generated_wall_cells.get(tile, {})
	if wall_data is Dictionary and String((wall_data as Dictionary).get("authority", "")) == "ascent_field_blocker":
		return true
	var traversal := String(get_elevation_data_at_tile(tile).get("traversal_type", ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE))
	return traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_BLOCKED \
			or traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_LEDGE \
			or traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_DROP


func _should_preserve_road_floor_visual(tile: Vector2i) -> bool:
	var region_type := get_region_type_at_tile(tile)
	return region_type == "compound_connector_elevated_road" or region_type == "compound_connector_ramp"


func _apply_connector_region_visual(tile: Vector2i) -> void:
	var region_type := get_region_type_at_tile(tile)
	if _compound_connector_centerline_tiles.has(tile) or region_type == "compound_connector_road":
		_apply_terrain_tile_visual(tile, "terrain_connector_centerline_32")
	elif region_type == "terrain_rescue_floor" \
			or region_type == "pre_terrain_required_connector" \
			or region_type == "authority_repair":
		_apply_terrain_tile_visual(tile, _deterministic_connector_repair_tile_id(tile))


func _deterministic_connector_repair_tile_id(tile: Vector2i) -> String:
	const REPAIR_TILES: Array[String] = [
		"terrain_connector_ground_32",
		"terrain_connector_cracked_32",
		"terrain_connector_gravel_32",
		"terrain_connector_dust_32",
		"terrain_connector_broken_patch_32",
	]
	return REPAIR_TILES[_tile_noise_hash(tile) % REPAIR_TILES.size()]


func _find_or_create_road_piece_parent() -> Node2D:
	var existing := get_node_or_null(road_piece_parent_path) as Node2D
	if existing != null:
		return existing
	var parent: Node = nav_region if nav_region != null else self
	var parent_path := String(road_piece_parent_path)
	if not parent_path.is_empty() and parent_path.contains("/"):
		var path_parts := parent_path.split("/")
		var root_name := String(path_parts[0])
		var root_candidate := get_node_or_null(NodePath(root_name))
		if root_candidate != null:
			parent = root_candidate
	var layer := Node2D.new()
	layer.name = "RoadPieceLayer"
	parent.add_child(layer)
	return layer


func _load_road_piece_manifest() -> void:
	_road_piece_defs_by_mask = _load_surface_piece_manifest(road_piece_manifest_path, ROAD_PIECE_EXPORT_ROOT, false)
	_road_piece_defs_by_role = _load_road_lane_role_manifest(road_piece_manifest_path, ROAD_PIECE_EXPORT_ROOT)
	_path_piece_defs_by_mask = _load_surface_piece_manifest(path_piece_manifest_path, PATH_PIECE_EXPORT_ROOT, true)


func _load_road_lane_role_manifest(manifest_path: String, export_root: String) -> Dictionary:
	var defs_by_role: Dictionary = {}
	if manifest_path.is_empty() or not FileAccess.file_exists(manifest_path):
		return defs_by_role
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not (parsed is Dictionary):
		return defs_by_role
	var pieces: Variant = (parsed as Dictionary).get("pieces", [])
	if not (pieces is Array):
		return defs_by_role
	for piece_variant in pieces as Array:
		if not (piece_variant is Dictionary):
			continue
		var piece := piece_variant as Dictionary
		var lane_role := String(piece.get("lane_role", "")).strip_edges().to_lower()
		var file_path := String(piece.get("file", ""))
		if lane_role.is_empty() or file_path.is_empty():
			continue
		var res_path := export_root + "/" + file_path
		if not ResourceLoader.exists(res_path):
			continue
		var stored := piece.duplicate(true)
		stored["res_path"] = res_path
		var defs: Array = defs_by_role.get(lane_role, [])
		defs.append(stored)
		defs_by_role[lane_role] = defs
	return defs_by_role


func _load_surface_piece_manifest(manifest_path: String, export_root: String, path_pieces_only: bool) -> Dictionary:
	var defs_by_mask: Dictionary = {}
	if manifest_path.is_empty() or not FileAccess.file_exists(manifest_path):
		return defs_by_mask
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not (parsed is Dictionary):
		return defs_by_mask
	var pieces: Variant = (parsed as Dictionary).get("pieces", [])
	if not (pieces is Array):
		return defs_by_mask
	for piece_variant in pieces as Array:
		if not (piece_variant is Dictionary):
			continue
		var piece := piece_variant as Dictionary
		if not _piece_matches_surface(piece, path_pieces_only):
			continue
		var file_path := String(piece.get("file", ""))
		var bitmask := int(piece.get("connection_bitmask", 0))
		if file_path.is_empty() or bitmask <= 0:
			continue
		var res_path := export_root + "/" + file_path
		if not ResourceLoader.exists(res_path):
			continue
		var defs: Array = defs_by_mask.get(bitmask, [])
		var stored := piece.duplicate(true)
		stored["res_path"] = res_path
		defs.append(stored)
		defs_by_mask[bitmask] = defs
	return defs_by_mask


func _piece_matches_surface(piece: Dictionary, path_pieces_only: bool) -> bool:
	var kind := String(piece.get("kind", ""))
	var width_class := String(piece.get("width_class", ""))
	var tags: Array = piece.get("tags", []) as Array
	var name := String(piece.get("name", piece.get("id", ""))).to_lower()
	var is_path_piece := kind == "transition" or tags.has("rubble") or tags.has("path") or name.contains("rubble")
	is_path_piece = is_path_piece or width_class == "tiny" or width_class == "short"
	if path_pieces_only:
		return is_path_piece
	return not is_path_piece


func _clear_road_piece_decals() -> void:
	for node in _road_piece_nodes:
		if node != null and is_instance_valid(node):
			node.queue_free()
	_road_piece_nodes.clear()
	_road_piece_nodes_by_key.clear()


func _remove_road_piece_decal(tile: Vector2i) -> void:
	for surface in ["road", "path"]:
		var key := _surface_tile_key(surface, tile)
		var node := _road_piece_nodes_by_key.get(key, null) as Node2D
		if node != null and is_instance_valid(node):
			node.queue_free()
		_road_piece_nodes_by_key.erase(key)


func _spawn_road_piece_decals() -> void:
	if not road_piece_decals_enabled or (_road_piece_defs_by_mask.is_empty() and _road_piece_defs_by_role.is_empty()):
		return
	if _road_piece_parent == null or not is_instance_valid(_road_piece_parent):
		_road_piece_parent = _find_or_create_road_piece_parent()
	if not _road_piece_defs_by_role.is_empty():
		for tile_variant in _main_road_tiles.keys():
			if not (tile_variant is Vector2i):
				continue
			_reveal_road_lane_piece_decal(tile_variant as Vector2i)
	else:
		for tile_variant in _road_visual_tiles.keys():
			if not (tile_variant is Vector2i):
				continue
			_reveal_surface_piece_decal(tile_variant as Vector2i, "road")
	for tile_variant in _path_visual_tiles.keys():
		if not (tile_variant is Vector2i):
			continue
		_reveal_surface_piece_decal(tile_variant as Vector2i, "path")


func _reveal_road_piece_decal(tile: Vector2i) -> void:
	if not _road_piece_defs_by_role.is_empty():
		_reveal_road_lane_piece_decal(tile)
	else:
		_reveal_surface_piece_decal(tile, "road")
	_reveal_surface_piece_decal(tile, "path")


func _reveal_road_lane_piece_decal(tile: Vector2i) -> void:
	if not road_piece_decals_enabled or _road_piece_defs_by_role.is_empty():
		return
	if _road_piece_parent == null or not is_instance_valid(_road_piece_parent):
		_road_piece_parent = _find_or_create_road_piece_parent()
	if not _main_road_tiles.has(tile):
		return
	var role := _get_road_lane_role(tile)
	var piece := _select_road_lane_piece_definition(tile, role)
	if piece.is_empty():
		return
	_spawn_road_piece_decal(tile, piece, "road")


func _get_road_lane_role(tile: Vector2i) -> String:
	var center := _find_nearest_road_centerline_tile(tile)
	if center == Vector2i.ZERO and not _road_centerline_tiles.has(Vector2i.ZERO):
		return "center"
	var offset := tile - center
	if offset == Vector2i.ZERO:
		return "center"
	var signed_offset := _get_signed_road_lane_offset(center, offset)
	if signed_offset == 0:
		return "center"
	var distance := mini(2, absi(signed_offset))
	if signed_offset < 0:
		return "left_%d" % distance
	return "right_%d" % distance


func _find_nearest_road_centerline_tile(tile: Vector2i) -> Vector2i:
	if _road_centerline_tiles.has(tile):
		return tile
	var radius := maxi(intent_main_road_half_width, intent_compound_connector_half_width)
	radius = maxi(radius, maxi(intent_parking_zone_half_extents_tiles.x, intent_parking_zone_half_extents_tiles.y))
	var best := Vector2i.ZERO
	var best_dist := 999999
	for center_variant in _road_centerline_tiles.keys():
		if not (center_variant is Vector2i):
			continue
		var center := center_variant as Vector2i
		var delta := tile - center
		if absi(delta.x) > radius + 1 or absi(delta.y) > radius + 1:
			continue
		var dist := delta.length_squared()
		if dist < best_dist:
			best = center
			best_dist = dist
	return best


func _get_signed_road_lane_offset(center: Vector2i, offset: Vector2i) -> int:
	var horizontal_links := int(_road_centerline_tiles.has(center + Vector2i.LEFT)) + int(_road_centerline_tiles.has(center + Vector2i.RIGHT))
	var vertical_links := int(_road_centerline_tiles.has(center + Vector2i.UP)) + int(_road_centerline_tiles.has(center + Vector2i.DOWN))
	if horizontal_links > vertical_links:
		return offset.y
	if vertical_links > horizontal_links:
		return -offset.x
	if absi(offset.x) > absi(offset.y):
		return -offset.x
	return offset.y


func _select_road_lane_piece_definition(tile: Vector2i, lane_role: String) -> Dictionary:
	var exact: Array = _road_piece_defs_by_role.get(lane_role, [])
	if exact.is_empty() and (lane_role == "left_2" or lane_role == "right_2"):
		exact = _road_piece_defs_by_role.get(lane_role.substr(0, lane_role.length() - 1) + "1", [])
	if exact.is_empty():
		exact = _road_piece_defs_by_role.get("center", [])
	if exact.is_empty():
		return {}
	var index := _tile_noise_hash(tile + Vector2i(719, 1471)) % exact.size()
	return (exact[index] as Dictionary).duplicate(true)


func _reveal_surface_piece_decal(tile: Vector2i, surface_kind: String) -> void:
	if not road_piece_decals_enabled:
		return
	if _road_piece_parent == null or not is_instance_valid(_road_piece_parent):
		_road_piece_parent = _find_or_create_road_piece_parent()
	var source_tiles := _road_centerline_tiles
	var visual_tiles := _road_visual_tiles
	var defs_by_mask := _road_piece_defs_by_mask
	if surface_kind == "path":
		source_tiles = _path_centerline_tiles
		visual_tiles = _path_visual_tiles
		defs_by_mask = _path_piece_defs_by_mask
	if defs_by_mask.is_empty() or not source_tiles.has(tile) or not visual_tiles.has(tile):
		return
	if surface_kind == "road" and not _main_road_tiles.has(tile):
		return
	if surface_kind == "path" and get_region_type_at_tile(tile) != "soft_path":
		return
	var mask := _get_road_piece_mask(tile, source_tiles)
	if mask <= 0:
		return
	var piece := _select_surface_piece_definition(tile, mask, defs_by_mask)
	if piece.is_empty():
		return
	_spawn_road_piece_decal(tile, piece, surface_kind)


func _get_road_piece_mask(tile: Vector2i, source_tiles: Dictionary) -> int:
	var mask := 0
	if source_tiles.has(tile + Vector2i.UP):
		mask |= 1
	if source_tiles.has(tile + Vector2i.RIGHT):
		mask |= 2
	if source_tiles.has(tile + Vector2i.DOWN):
		mask |= 4
	if source_tiles.has(tile + Vector2i.LEFT):
		mask |= 8
	return mask


func _select_road_piece_definition(tile: Vector2i, mask: int) -> Dictionary:
	return _select_surface_piece_definition(tile, mask, _road_piece_defs_by_mask)


func _select_surface_piece_definition(tile: Vector2i, mask: int, defs_by_mask: Dictionary) -> Dictionary:
	var exact: Array = defs_by_mask.get(mask, [])
	if exact.is_empty():
		match mask:
			1, 4, 5:
				exact = defs_by_mask.get(5, [])
			2, 8, 10:
				exact = defs_by_mask.get(10, [])
			3, 6, 9, 12:
				exact = defs_by_mask.get(mask, [])
			7, 11, 13, 14:
				exact = defs_by_mask.get(mask, defs_by_mask.get(15, []))
			_:
				exact = defs_by_mask.get(15, [])
	if exact.is_empty():
		return {}
	var index := _tile_noise_hash(tile + Vector2i(1901, 877)) % exact.size()
	return (exact[index] as Dictionary).duplicate(true)


func _spawn_road_piece_decal(tile: Vector2i, piece: Dictionary, surface_kind: String = "road") -> void:
	var key := _surface_tile_key(surface_kind, tile)
	if _road_piece_nodes_by_key.has(key):
		return
	var texture := ResourceLoader.load(String(piece.get("res_path", ""))) as Texture2D
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = "%s_%s" % [surface_kind, String(piece.get("id", "piece"))]
	sprite.texture = texture
	sprite.centered = true
	sprite.global_position = _tile_to_world_position(tile)
	sprite.z_index = road_piece_z_index
	sprite.z_as_relative = false
	if piece.has("lane_role"):
		sprite.set_meta("lane_role", String(piece.get("lane_role", "")))
	_road_piece_parent.add_child(sprite)
	_road_piece_nodes.append(sprite)
	_road_piece_nodes_by_key[key] = sprite


func _surface_tile_key(surface_kind: String, tile: Vector2i) -> String:
	return "%s:%d:%d" % [surface_kind, tile.x, tile.y]


func _carve_interest_paths(map_size: Vector2i) -> void:
	if procgen_node == null:
		return
	_path_centerline_tiles.clear()
	_path_visual_tiles.clear()
	var spawn := get_player_spawn()
	var path_width := maxi(0, intent_soft_path_width)
	for ingress in _last_compound_ingress:
		_carve_soft_path(spawn, ingress, path_width, map_size)
	for threshold in _last_interior_thresholds:
		_carve_soft_path(spawn, threshold, path_width, map_size)


func _carve_soft_path(from_tile: Vector2i, to_tile: Vector2i, width: int, map_size: Vector2i) -> void:
	var current := from_tile
	_path_centerline_tiles[current] = true
	_path_visual_tiles[current] = true
	var step_index := 0
	while current.x != to_tile.x:
		current.x += 1 if to_tile.x > current.x else -1
		_path_centerline_tiles[current] = true
		step_index += 1
		if step_index % maxi(1, path_piece_straight_stride_tiles) == 0:
			_path_visual_tiles[current] = true
		_carve_path_brush(current, width, map_size)
	while current.y != to_tile.y:
		current.y += 1 if to_tile.y > current.y else -1
		_path_centerline_tiles[current] = true
		step_index += 1
		if step_index % maxi(1, path_piece_straight_stride_tiles) == 0:
			_path_visual_tiles[current] = true
		_carve_path_brush(current, width, map_size)
	_path_visual_tiles[current] = true


func _carve_path_brush(center: Vector2i, width: int, map_size: Vector2i) -> void:
	for x in range(-width, width + 1):
		for y in range(-width, width + 1):
			var tile := center + Vector2i(x, y)
			if not _is_tile_inside_map(tile, map_size, 1):
				continue
			if is_indoor_tile(tile):
				continue
			if walls_tilemap != null and walls_tilemap.get_cell_source_id(tile) >= 0:
				continue
			_set_road_path_tile(tile, "path")
			_set_region_tile(tile, "soft_path", "travel")


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
			var compound_tile := Vector2i(x, y)
			_set_floor_tile(compound_tile)
			_clear_road_blocking_wall(compound_tile)

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
		if intent_decorate_compound_ingress:
			_decorate_compound_ingress(tile, rect)

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


func _decorate_compound_ingress(ingress: Vector2i, rect: Rect2i) -> void:
	if procgen_node == null:
		return
	var inward: Vector2i = _get_compound_ingress_inward(ingress, rect)
	var outward: Vector2i = -inward
	var map_size: Vector2i = procgen_node.map_size
	for step in range(1, 4):
		var approach_tile: Vector2i = ingress + outward * step
		if not _is_tile_inside_map(approach_tile, map_size, 1):
			continue
		_set_floor_tile(approach_tile)
		_set_region_tile(approach_tile, "compound_approach", "compound_ingress")
	var outside_anchor: Vector2i = ingress + outward * 2
	var side_axis := Vector2i(-inward.y, inward.x)
	for side in [-1, 1]:
		var cover_tile: Vector2i = outside_anchor + side_axis * int(side) * 2
		if not _is_tile_inside_map(cover_tile, map_size, 1):
			continue
		if walls_tilemap != null and walls_tilemap.get_cell_source_id(cover_tile) >= 0:
			continue
		_set_region_tile(cover_tile, "cover_anchor", "compound_ingress")


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
			if _is_reserved_pre_terrain_traversal_cell(tile, map_size):
				_preserve_reserved_pre_terrain_floor_authority(tile)
				continue
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
		var room_zone := _pick_room_zone(room, _last_interior_rooms.size())
		_carve_interior_floor_rect(room, room_zone)
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


func _pick_room_zone(room: Rect2i, room_index: int) -> String:
	var zones := [
		"storage",
		"security",
		"maintenance",
		"archive",
		"generator",
		"barracks",
		"lab",
	]
	var token := room.position + Vector2i(room_index * 37, 777)
	var index := _tile_noise_hash(token) % zones.size()
	return zones[index]


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
			_set_interior_floor_tile(tile, "doorway" if step == 0 else "threshold")
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


func _is_reserved_pre_terrain_traversal_cell(tile: Vector2i, map_size: Vector2i) -> bool:
	if tile == get_player_spawn():
		return true
	if _worldgen_intent_floor_cells.has(tile):
		return true
	if _ascent_field_main_route_cells.has(tile) or _ascent_field_vista_cells.has(tile):
		return true
	if _main_road_tiles.has(tile) or _parking_zone_tiles.has(tile):
		return true
	if _compound_connector_centerline_tiles.has(tile) or _last_compound_ingress.has(tile):
		return true
	if _worldgen_intent_graph != null:
		for required_cell in _worldgen_intent_graph.get_required_cells():
			if required_cell == tile and _is_tile_inside_map(required_cell, map_size):
				return true
	return false


func _preserve_reserved_pre_terrain_floor_authority(tile: Vector2i) -> void:
	var source_id := _select_floor_source_id(tile)
	var atlas := _select_floor_coord(tile)
	_generated_floor_cells[tile] = {
		"source_id": source_id,
		"atlas": atlas,
		"alternative": 0,
		"authority": "reserved_pre_terrain_traversal",
	}
	_generated_wall_cells.erase(tile)
	if floor_tilemap != null:
		floor_tilemap.set_cell(tile, source_id, atlas, 0)
	if walls_tilemap != null:
		walls_tilemap.erase_cell(tile)
	_wall_health.erase(tile)

	var region_data := get_region_data_at_tile(tile)
	var region_type := String(region_data.get("region_type", "exterior"))
	if region_type == "interior_wall":
		_set_region_tile(tile, "worldgen_intent_floor", "ascent_route")


func _clear_region_metadata() -> void:
	_last_interior_region_rect = Rect2i()
	_last_interior_rooms.clear()
	_last_interior_thresholds.clear()
	_main_road_tiles.clear()
	_road_centerline_tiles.clear()
	_path_centerline_tiles.clear()
	_road_visual_tiles.clear()
	_path_visual_tiles.clear()
	_compound_connector_centerline_tiles.clear()
	_compound_connector_visual_candidates.clear()
	_parking_zone_tiles.clear()
	_region_tiles.clear()


func _ensure_world_progress_profile() -> void:
	if not world_progression_enabled:
		_world_progress_profile = null
		return
	if _world_progress_profile == null:
		_world_progress_profile = WORLD_PROGRESS_PROFILE_SCRIPT.load_from_path(world_progress_profile_path)
	var spawn := get_player_spawn()
	if spawn != Vector2i.ZERO:
		_world_progress_profile.origin_cell = spawn


func _ensure_site_placers() -> void:
	if _faction_site_placer == null:
		_faction_site_placer = FACTION_SITE_PLACER_SCRIPT.new()
	if _story_room_placer == null:
		_story_room_placer = STORY_ROOM_PLACER_SCRIPT.new()


func _fill_legacy_cave_substrate(map_size: Vector2i) -> void:
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


func _fill_ascent_field_substrate(map_size: Vector2i) -> void:
	_build_worldgen_intent_graph(map_size, true)
	if _worldgen_intent_graph == null:
		return
	var builder := ASCENT_FIELD_BUILDER_SCRIPT.new()
	var field: Dictionary = builder.call("build_field", _worldgen_intent_graph, map_size, procgen_node.seed if procgen_node != null else 0)
	_worldgen_intent_floor_cells = field.get("floor_cells", {})
	_worldgen_reserved_regions = field.get("reserved_regions", [])
	_ascent_field_summary = field.get("debug_summary", {})
	_ascent_field_main_route_cells = field.get("main_route_cells", [])
	_ascent_field_vista_cells = field.get("vista_cells", [])
	_apply_ascent_field_authority(field, map_size)


func _apply_ascent_field_authority(field: Dictionary, map_size: Vector2i) -> void:
	_generated_floor_cells.clear()
	_generated_wall_cells.clear()
	var floor_cells: Dictionary = field.get("floor_cells", {})
	var wall_cells: Dictionary = field.get("wall_cells", {})
	for key in floor_cells.keys():
		if not (key is Vector2i):
			continue
		var tile := key as Vector2i
		if not _is_tile_inside_map(tile, map_size, 0):
			continue
		_set_ascent_field_floor_authority(tile, "ascent_field_floor", "exterior_ascent")
	for key in wall_cells.keys():
		if not (key is Vector2i):
			continue
		var tile := key as Vector2i
		if not _is_tile_inside_map(tile, map_size, 0):
			continue
		if _generated_floor_cells.has(tile):
			continue
		_set_ascent_field_wall_authority(tile)


func _set_ascent_field_floor_authority(tile: Vector2i, region_type: String, zone: String) -> void:
	var source_id := _select_floor_source_id(tile)
	var atlas := _select_floor_coord(tile)
	_generated_floor_cells[tile] = {
		"source_id": source_id,
		"atlas": atlas,
		"alternative": 0,
		"authority": "ascent_field",
	}
	_generated_wall_cells.erase(tile)
	if floor_tilemap != null:
		floor_tilemap.set_cell(tile, source_id, atlas, 0)
	if walls_tilemap != null:
		walls_tilemap.erase_cell(tile)
	_wall_health.erase(tile)
	_set_region_tile(tile, region_type, zone)


func _set_ascent_field_wall_authority(tile: Vector2i) -> void:
	var source = high_walls_source_id if use_high_walls else walls_source_id
	var coord = _select_wall_coord(tile)
	_generated_wall_cells[tile] = {
		"source_id": source,
		"atlas": coord,
		"alternative": 0,
		"authority": "ascent_field_blocker",
	}
	_generated_floor_cells.erase(tile)
	if walls_tilemap != null:
		walls_tilemap.set_cell(tile, source, coord, 0)
	if floor_tilemap != null:
		floor_tilemap.erase_cell(tile)
	if not _wall_health.has(tile):
		_wall_health[tile] = wall_tile_max_health
	_set_region_tile(tile, "ascent_field_blocker", "cliff_ruin_boundary")


func _build_worldgen_intent_graph(map_size: Vector2i, force_ascent_field_origin: bool = false) -> void:
	_worldgen_intent_graph = null
	_worldgen_reserved_regions.clear()
	_worldgen_intent_floor_cells.clear()
	if not worldgen_intent_enabled:
		return

	_ensure_world_progress_profile()
	var builder := ASCENT_SPINE_BUILDER_SCRIPT.new()
	var origin := Vector2i(map_size.x / 2, map_size.y - 12) if force_ascent_field_origin else get_player_spawn()
	if origin == Vector2i.ZERO:
		origin = Vector2i(map_size.x / 2, map_size.y - 12)
	if _world_progress_profile != null:
		_world_progress_profile.origin_cell = origin
	_worldgen_intent_graph = builder.call("build", {
		"seed": procgen_node.seed if procgen_node != null else 0,
		"map_size": map_size,
		"origin_cell": origin,
		"route_beat_count": worldgen_intent_route_beat_count,
		"world_progress_profile": _world_progress_profile,
	})

	var reserver := REGION_FOOTPRINT_RESERVER_SCRIPT.new()
	var reservations: Dictionary = reserver.call("build_reservations", _worldgen_intent_graph, map_size)
	_worldgen_intent_floor_cells = reservations.get("floor_cells", {})
	_worldgen_reserved_regions = reservations.get("reserved_regions", [])

	if worldgen_intent_debug_logging:
		print("[ProcGenTilemap] intent graph nodes=%d edges=%d floor_cells=%d regions=%d" % [
			_worldgen_intent_graph.nodes.size(),
			_worldgen_intent_graph.edges.size(),
			_worldgen_intent_floor_cells.size(),
			_worldgen_reserved_regions.size(),
		])


func _apply_worldgen_intent_floor_cells(map_size: Vector2i) -> void:
	if _worldgen_intent_floor_cells.is_empty():
		return
	for key in _worldgen_intent_floor_cells.keys():
		if not (key is Vector2i):
			continue
		var tile := key as Vector2i
		if not _is_tile_inside_map(tile, map_size, 0):
			continue
		var source_id := _select_floor_source_id(tile)
		var atlas := _select_floor_coord(tile)
		_generated_floor_cells[tile] = {
			"source_id": source_id,
			"atlas": atlas,
			"alternative": 0,
			"authority": "worldgen_intent",
		}
		if floor_tilemap != null:
			floor_tilemap.set_cell(tile, source_id, atlas, 0)
		_clear_procgen_wall_authority_at(tile, false)
		_set_region_tile(tile, "worldgen_intent_floor", "ascent_route")
	if build_runtime_wall_collision:
		_sync_runtime_wall_collision_with_visible_walls()


func _stamp_worldgen_faction_site_geometry() -> void:
	if _worldgen_reserved_regions.is_empty():
		return
	if _faction_site_geometry_stamper == null:
		_faction_site_geometry_stamper = FACTION_SITE_GEOMETRY_STAMPER_SCRIPT.new()
	_faction_site_geometry_stamper.call("stamp_faction_sites", self, _faction_activity_sites, _worldgen_reserved_regions)


func _stamp_worldgen_story_room_geometry() -> void:
	if _worldgen_reserved_regions.is_empty():
		return
	if _story_room_geometry_stamper == null:
		_story_room_geometry_stamper = STORY_ROOM_GEOMETRY_STAMPER_SCRIPT.new()
	_story_room_geometry_stamper.call("stamp_story_rooms", self, _story_room_sites, _worldgen_reserved_regions)


func _build_world_progress_samples(map_size: Vector2i) -> void:
	_world_progress_samples.clear()
	if _world_progress_profile == null:
		return
	for x in range(0, map_size.x, 16):
		for y in range(0, map_size.y, 16):
			var cell := Vector2i(x, y)
			_world_progress_samples[cell] = _world_progress_profile.get_cell_progress(cell, procgen_node.seed)
	if world_progress_debug_logging:
		print("WorldProgression: profile=%s samples=%s" % [_world_progress_profile.profile_id, _world_progress_samples.size()])


func get_world_progress_at_tile(tile: Vector2i) -> Dictionary:
	_ensure_world_progress_profile()
	if _world_progress_profile == null:
		return {}
	return _world_progress_profile.get_cell_progress(tile, procgen_node.seed if procgen_node != null else 0)


func _place_faction_ambient_sites(map_size: Vector2i) -> void:
	_faction_activity_sites.clear()
	if _world_progress_profile == null or _faction_site_placer == null:
		return
	_faction_activity_sites = _faction_site_placer.call("place_sites", {
		"seed": _tile_noise_hash(Vector2i(661, 911)),
		"map_size": map_size,
		"floor_cells": _dict_keys_as_vector2i_array(_generated_floor_cells),
		"blocked_cells": _dict_keys_as_vector2i_array(_generated_wall_cells),
		"required_cells": _collect_terrain_required_cells(map_size),
		"count": faction_ambient_site_count,
		"world_progress_profile": _world_progress_profile,
	})
	for site in _faction_activity_sites:
		var cell: Vector2i = site.get("cell", Vector2i.ZERO)
		if not _is_tile_inside_map(cell, map_size):
			continue
		if get_region_type_at_tile(cell) == "exterior":
			_set_region_tile(cell, "faction_%s_%s" % [String(site.get("faction_id", "none")), String(site.get("activity_id", "ambient"))], "faction_activity")
		_spawn_ambient_activity_anchor(site)


func _place_story_rooms(map_size: Vector2i) -> void:
	_story_room_sites.clear()
	if _world_progress_profile == null or _story_room_placer == null:
		return
	_story_room_sites = _story_room_placer.call("place_story_rooms", {
		"seed": _tile_noise_hash(Vector2i(1201, 1709)),
		"map_size": map_size,
		"floor_cells": _dict_keys_as_vector2i_array(_generated_floor_cells),
		"blocked_cells": _dict_keys_as_vector2i_array(_generated_wall_cells),
		"required_cells": _collect_terrain_required_cells(map_size),
		"count": story_room_count,
		"world_progress_profile": _world_progress_profile,
		"faction_sites": _faction_activity_sites,
	})
	for room in _story_room_sites:
		var cell: Vector2i = room.get("cell", Vector2i.ZERO)
		if not _is_tile_inside_map(cell, map_size):
			continue
		if get_region_type_at_tile(cell) == "exterior":
			_set_region_tile(cell, "story_room_%s" % String(room.get("story_id", "unknown")), "story_room")
		_spawn_placeholder_marker(cell, Vector2i(3, 2), "StoryRoom_%s" % String(room.get("story_id", "unknown")))


func _find_or_create_world_progress_marker_parent() -> Node2D:
	var existing := get_node_or_null("WorldProgressMarkers") as Node2D
	if existing != null:
		return existing
	var parent := Node2D.new()
	parent.name = "WorldProgressMarkers"
	add_child(parent)
	return parent


func _clear_world_progression_runtime() -> void:
	_world_progress_samples.clear()
	_worldgen_intent_graph = null
	_worldgen_reserved_regions.clear()
	_worldgen_intent_floor_cells.clear()
	_ascent_field_summary.clear()
	_ascent_field_main_route_cells.clear()
	_ascent_field_vista_cells.clear()
	_faction_activity_sites.clear()
	_story_room_sites.clear()
	_special_room_sites.clear()
	if _world_progress_marker_parent == null:
		_world_progress_marker_parent = _find_or_create_world_progress_marker_parent()
	for child in _world_progress_marker_parent.get_children():
		child.queue_free()


func _spawn_ambient_activity_anchor(site: Dictionary) -> void:
	if _world_progress_marker_parent == null:
		return
	var anchor := AMBIENT_ACTIVITY_ANCHOR_SCRIPT.new()
	anchor.name = "Ambient_%s" % String(site.get("site_id", "site"))
	anchor.faction_id = String(site.get("faction_id", "none"))
	anchor.activity_id = String(site.get("activity_id", "ambient"))
	anchor.escalation_radius_px = float(site.get("escalation_radius_tiles", 6)) * get_runtime_tile_size().x
	anchor.noncombat_first = bool(site.get("noncombat_first", true))
	_world_progress_marker_parent.add_child(anchor)
	anchor.global_position = _tile_to_world_position(site.get("cell", Vector2i.ZERO))
	_add_placeholder_marker_sprite(anchor, Vector2i(2, 2))


func _spawn_placeholder_marker(cell: Vector2i, atlas_coord: Vector2i, marker_name: String) -> void:
	if _world_progress_marker_parent == null:
		return
	var marker := Node2D.new()
	marker.name = marker_name
	_world_progress_marker_parent.add_child(marker)
	marker.global_position = _tile_to_world_position(cell)
	_add_placeholder_marker_sprite(marker, atlas_coord)


func _add_placeholder_marker_sprite(parent: Node2D, atlas_coord: Vector2i) -> void:
	var texture := load(PLACEHOLDER_ATLAS_PATH) as Texture2D
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2(atlas_coord * 32), Vector2(32, 32))
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.72)
	sprite.z_index = 2
	parent.add_child(sprite)


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


func register_special_room_site(site: Dictionary) -> void:
	if site.is_empty():
		return
	_special_room_sites.append(site.duplicate(true))


func get_special_room_sites() -> Array[Dictionary]:
	return _special_room_sites.duplicate(true)


func is_road_surface_tile(tile: Vector2i) -> bool:
	return _main_road_tiles.has(tile) or get_region_type_at_tile(tile) == "soft_path"


func is_parking_zone_tile(tile: Vector2i) -> bool:
	return _parking_zone_tiles.has(tile)


func get_main_road_tiles() -> Array[Vector2i]:
	return _dict_keys_as_vector2i_array(_main_road_tiles)


func get_parking_zone_tiles() -> Array[Vector2i]:
	return _dict_keys_as_vector2i_array(_parking_zone_tiles)


func debug_get_generated_floor_cells() -> Dictionary:
	return _generated_floor_cells.duplicate(true)


func debug_get_generated_wall_cells() -> Dictionary:
	return _generated_wall_cells.duplicate(true)


func register_runtime_prop_blocker(
	center_tile: Vector2i,
	radius_tiles: int = 1,
	owner: Node = null,
	kind: StringName = &"runtime_prop"
) -> String:
	var owner_id := str(owner.get_instance_id()) if is_instance_valid(owner) else "%s:%s" % [String(kind), center_tile]
	_unregister_runtime_prop_blocker_id(owner_id)
	var cells: Array[Vector2i] = []
	var radius := maxi(0, radius_tiles)
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			cells.append(center_tile + Vector2i(x, y))
	_register_runtime_prop_blocker_cells(owner_id, cells, owner, kind, center_tile)
	return owner_id


func unregister_runtime_prop_blocker(owner_or_id: Variant) -> void:
	var owner_id := ""
	if owner_or_id is Node and is_instance_valid(owner_or_id):
		owner_id = str((owner_or_id as Node).get_instance_id())
	else:
		owner_id = str(owner_or_id)
	_unregister_runtime_prop_blocker_id(owner_id)


func has_runtime_prop_blocker_at_tile(tile: Vector2i) -> bool:
	return _runtime_prop_blocker_cells.has(tile) and not (_runtime_prop_blocker_cells[tile] as Dictionary).is_empty()


func is_runtime_walkable_after_props(tile: Vector2i) -> bool:
	return _generated_floor_cells.has(tile) \
		and not _generated_wall_cells.has(tile) \
		and not has_runtime_prop_blocker_at_tile(tile)


func _is_runtime_walkable_after_props(tile: Vector2i) -> bool:
	return is_runtime_walkable_after_props(tile)


func get_runtime_escape_neighbor_count(tile: Vector2i) -> int:
	var open_count := 0
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		if is_runtime_walkable_after_props(tile + direction):
			open_count += 1
	return open_count


func debug_get_runtime_prop_blocker_cells() -> Dictionary:
	return _runtime_prop_blocker_cells.duplicate(true)


func _register_foliage_runtime_blocker(foliage_node: Node) -> void:
	_register_runtime_prop_node(foliage_node, &"tree_trunk")


func _register_runtime_prop_node(owner: Node, kind: StringName) -> void:
	if owner == null or not is_instance_valid(owner):
		return
	var cells: Array[Vector2i] = []
	if owner is ProceduralProp and (owner as ProceduralProp).definition != null \
			and (owner as ProceduralProp).definition.collision_scene == null:
		var collision_rect := (owner as ProceduralProp).get_collision_rect_global()
		if collision_rect.size.x > 0.0 and collision_rect.size.y > 0.0:
			cells = _collision_cells_for_global_rect(collision_rect)
	if cells.is_empty():
		cells = _collision_cells_for_node(owner)
	if cells.is_empty():
		return
	var source_tile := _global_to_tile((owner as Node2D).global_position) if owner is Node2D else cells[0]
	_register_runtime_prop_blocker_cells(str(owner.get_instance_id()), cells, owner, kind, source_tile)


func _collision_cells_for_global_rect(collision_rect: Rect2) -> Array[Vector2i]:
	if collision_rect.size.x <= 0.0 or collision_rect.size.y <= 0.0:
		return []
	var corner_tiles: Array[Vector2i] = [
		_global_to_tile(collision_rect.position),
		_global_to_tile(Vector2(collision_rect.end.x, collision_rect.position.y)),
		_global_to_tile(collision_rect.end),
		_global_to_tile(Vector2(collision_rect.position.x, collision_rect.end.y)),
	]
	var min_tile := corner_tiles[0]
	var max_tile := corner_tiles[0]
	for corner_tile in corner_tiles:
		min_tile = Vector2i(mini(min_tile.x, corner_tile.x), mini(min_tile.y, corner_tile.y))
		max_tile = Vector2i(maxi(max_tile.x, corner_tile.x), maxi(max_tile.y, corner_tile.y))
	var cells: Array[Vector2i] = []
	for y in range(min_tile.y, max_tile.y + 1):
		for x in range(min_tile.x, max_tile.x + 1):
			cells.append(Vector2i(x, y))
	_sort_tiles(cells)
	return cells


func _register_runtime_prop_blocker_cells(
	owner_id: String,
	cells: Array[Vector2i],
	owner: Node,
	kind: StringName,
	source_tile: Vector2i
) -> void:
	if owner_id.is_empty() or cells.is_empty():
		return
	_runtime_prop_blocker_sources[owner_id] = {
		"owner": owner,
		"kind": kind,
		"source_tile": source_tile,
		"cells": cells.duplicate(),
	}
	for cell in cells:
		var owners: Dictionary = _runtime_prop_blocker_cells.get(cell, {})
		owners[owner_id] = true
		_runtime_prop_blocker_cells[cell] = owners
	_obs_increment(&"procgen_runtime_blockers_registered")
	_obs_gauge(&"procgen_runtime_blocker_sources", _runtime_prop_blocker_sources.size())
	_obs_gauge(&"procgen_runtime_prop_blocker_cells", _runtime_prop_blocker_cells.size())


func _unregister_runtime_prop_blocker_id(owner_id: String) -> void:
	if owner_id.is_empty() or not _runtime_prop_blocker_sources.has(owner_id):
		return
	var source: Dictionary = _runtime_prop_blocker_sources[owner_id]
	for cell_variant in source.get("cells", []):
		if not cell_variant is Vector2i or not _runtime_prop_blocker_cells.has(cell_variant):
			continue
		var owners: Dictionary = _runtime_prop_blocker_cells[cell_variant]
		owners.erase(owner_id)
		if owners.is_empty():
			_runtime_prop_blocker_cells.erase(cell_variant)
		else:
			_runtime_prop_blocker_cells[cell_variant] = owners
	_runtime_prop_blocker_sources.erase(owner_id)
	_obs_increment(&"procgen_runtime_blockers_unregistered")
	_obs_gauge(&"procgen_runtime_blocker_sources", _runtime_prop_blocker_sources.size())
	_obs_gauge(&"procgen_runtime_prop_blocker_cells", _runtime_prop_blocker_cells.size())


func _collision_cells_for_node(owner: Node) -> Array[Vector2i]:
	var lookup: Dictionary = {}
	var stack: Array[Node] = [owner]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CollisionShape2D:
			var collision := node as CollisionShape2D
			if collision.disabled or collision.shape == null:
				continue
			var half_extents := Vector2(8.0, 8.0)
			if collision.shape is RectangleShape2D:
				half_extents = (collision.shape as RectangleShape2D).size * 0.5
			elif collision.shape is CircleShape2D:
				var radius := (collision.shape as CircleShape2D).radius
				half_extents = Vector2(radius, radius)
			elif collision.shape is CapsuleShape2D:
				var capsule := collision.shape as CapsuleShape2D
				half_extents = Vector2(capsule.radius, capsule.height * 0.5)
			var corner_tiles: Array[Vector2i] = []
			for corner in [Vector2(-half_extents.x, -half_extents.y), Vector2(half_extents.x, -half_extents.y), Vector2(-half_extents.x, half_extents.y), Vector2(half_extents.x, half_extents.y)]:
				corner_tiles.append(_global_to_tile(collision.to_global(corner)))
			var min_tile: Vector2i = corner_tiles[0]
			var max_tile: Vector2i = corner_tiles[0]
			for corner_tile in corner_tiles:
				min_tile = Vector2i(mini(min_tile.x, corner_tile.x), mini(min_tile.y, corner_tile.y))
				max_tile = Vector2i(maxi(max_tile.x, corner_tile.x), maxi(max_tile.y, corner_tile.y))
			for y in range(min_tile.y, max_tile.y + 1):
				for x in range(min_tile.x, max_tile.x + 1):
					lookup[Vector2i(x, y)] = true
		for child in node.get_children():
			if child is Node:
				stack.append(child)
	var cells: Array[Vector2i] = []
	for cell_variant in lookup.keys():
		cells.append(cell_variant as Vector2i)
	_sort_tiles(cells)
	return cells


func validate_no_stuck_pockets(remediate: bool = true) -> Dictionary:
	if not runtime_blocker_validate_stuck_pockets:
		return {"flagged": [], "remediated": 0}
	var candidate_lookup: Dictionary = {}
	for blocker_variant in _runtime_prop_blocker_cells.keys():
		var blocker := blocker_variant as Vector2i
		for y in range(-1, 2):
			for x in range(-1, 2):
				candidate_lookup[blocker + Vector2i(x, y)] = true
	var candidates: Array[Vector2i] = []
	for candidate_variant in candidate_lookup.keys():
		candidates.append(candidate_variant as Vector2i)
	_sort_tiles(candidates)
	var flagged: Array[Vector2i] = []
	var remediated := 0
	for tile in candidates:
		if not is_runtime_walkable_after_props(tile):
			continue
		if get_runtime_escape_neighbor_count(tile) >= runtime_blocker_min_escape_neighbors:
			continue
		flagged.append(tile)
		if remediate:
			var cleared_for_tile := 0
			var cleared_source_ids: Array[String] = []
			while get_runtime_escape_neighbor_count(tile) < runtime_blocker_min_escape_neighbors \
					and _clear_one_blocker_near_tile(tile, cleared_source_ids):
				cleared_for_tile += 1
			if cleared_for_tile > 0:
				remediated += 1
				push_warning("[ProcGenStuckPocket] cleared %d runtime collision owner(s) near tile=%s" % [cleared_for_tile, tile])
				var pocket_id := "%s:%d:%d" % [_get_generation_seed(), tile.x, tile.y]
				_obs_warning("Procgen stuck pocket collision remediated.", {
					"pocket_id": pocket_id,
					"tile": tile,
					"center_cell": tile,
					"cell_count": 1,
					"cleared_sources": cleared_for_tile,
					"cleared_source_ids": cleared_source_ids,
					"blocker_source": ",".join(cleared_source_ids),
					"remediation_action": "disabled_collision/unregistered_blocker",
					"seed": _get_generation_seed(),
				})
	if remediated > 0:
		_queue_navigation_rebuild()
	_obs_increment(&"procgen_stuck_pockets_detected", flagged.size())
	_obs_increment(&"procgen_stuck_pockets_remediated", remediated)
	_obs_increment(&"procgen_validation_pockets_detected", flagged.size())
	_obs_increment(&"procgen_validation_pockets_repaired", remediated)
	_obs_gauge(&"procgen_stuck_pockets_last_scan", flagged.size())
	_obs_gauge(&"procgen_stuck_pockets_detected_last_generation", flagged.size())
	_obs_gauge(&"procgen_stuck_pockets_remediated_last_generation", remediated)
	_obs_log(&"procgen_stuck_pocket_validation", {
		"flagged": flagged.size(),
		"remediated": remediated,
		"seed": _get_generation_seed(),
	})
	return {"flagged": flagged, "remediated": remediated}


func _clear_one_blocker_near_tile(tile: Vector2i, cleared_source_ids: Array[String] = []) -> bool:
	var ids: Array[String] = []
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var owners: Dictionary = _runtime_prop_blocker_cells.get(tile + direction, {})
		for owner_id_variant in owners.keys():
			var owner_id := str(owner_id_variant)
			if not ids.has(owner_id):
				ids.append(owner_id)
	ids.sort()
	if ids.is_empty():
		return false
	var source: Dictionary = _runtime_prop_blocker_sources.get(ids[0], {})
	_disable_collision_shapes(source.get("owner", null) as Node)
	_unregister_runtime_prop_blocker_id(ids[0])
	cleared_source_ids.append(ids[0])
	return true


func _disable_collision_shapes(owner: Node) -> void:
	if owner == null or not is_instance_valid(owner):
		return
	var stack: Array[Node] = [owner]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CollisionShape2D:
			(node as CollisionShape2D).set_deferred("disabled", true)
		for child in node.get_children():
			if child is Node:
				stack.append(child)


func _sort_tiles(tiles: Array[Vector2i]) -> void:
	tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x if a.y == b.y else a.y < b.y
	)


func debug_print_floor_tile_at_global(world_pos: Vector2) -> void:
	var tile := _global_to_tile(world_pos)
	var report := debug_get_floor_tile_report(tile)
	print("[FloorDebug] tile=%s source=%s atlas=%s alt=%s region=%s generated=%s wall=%s spawn_valid=%s" % [
		report.get("tile", tile),
		report.get("source_id", -1),
		report.get("atlas", Vector2i(-1, -1)),
		report.get("alternative", -1),
		report.get("region_type", "unknown"),
		report.get("generated_floor", false),
		report.get("generated_wall", false),
		report.get("valid_spawn_cell", false),
	])


func debug_get_floor_tile_report(tile: Vector2i) -> Dictionary:
	var source_id := -1
	var atlas := Vector2i(-1, -1)
	var alternative := -1
	if floor_tilemap != null:
		source_id = floor_tilemap.get_cell_source_id(tile)
		atlas = floor_tilemap.get_cell_atlas_coords(tile)
		alternative = floor_tilemap.get_cell_alternative_tile(tile)
	return {
		"tile": tile,
		"source_id": source_id,
		"atlas": atlas,
		"alternative": alternative,
		"region_type": get_region_type_at_tile(tile),
		"generated_floor": _generated_floor_cells.has(tile),
		"generated_wall": _generated_wall_cells.has(tile),
		"valid_spawn_cell": is_valid_spawn_cell(tile),
	}


func debug_get_stuck_report_at_global(world_pos: Vector2) -> Dictionary:
	var tile := _global_to_tile(world_pos)
	var floor_source := floor_tilemap.get_cell_source_id(tile) if floor_tilemap != null else -1
	var wall_source := walls_tilemap.get_cell_source_id(tile) if walls_tilemap != null else -1
	if floor_source < 0 and _generated_floor_cells.has(tile):
		floor_source = int((_generated_floor_cells[tile] as Dictionary).get("source_id", -1))
	if wall_source < 0 and _generated_wall_cells.has(tile):
		wall_source = int((_generated_wall_cells[tile] as Dictionary).get("source_id", -1))
	var nearby_names: Array[String] = []
	var nearby_sources: Dictionary = {}
	for y in range(-1, 2):
		for x in range(-1, 2):
			var owners: Dictionary = _runtime_prop_blocker_cells.get(tile + Vector2i(x, y), {})
			for owner_id_variant in owners.keys():
				nearby_sources[str(owner_id_variant)] = true
	for owner_id_variant in nearby_sources.keys():
		var source: Dictionary = _runtime_prop_blocker_sources.get(owner_id_variant, {})
		var owner := source.get("owner", null) as Node
		var label := String(source.get("kind", &"runtime_prop"))
		if owner != null and is_instance_valid(owner):
			label = "%s:%s" % [label, owner.name]
		nearby_names.append(label)
	nearby_names.sort()
	var blocker_details: Array[Dictionary] = []
	for owner_id_variant in nearby_sources.keys():
		var source: Dictionary = _runtime_prop_blocker_sources.get(owner_id_variant, {})
		blocker_details.append({
			"owner_id": str(owner_id_variant),
			"kind": String(source.get("kind", &"runtime_prop")),
			"source_tile": source.get("source_tile", Vector2i.ZERO),
			"cells": source.get("cells", []),
		})
	return {
		"seed": int(procgen_node.seed) if procgen_node != null and "seed" in procgen_node else 0,
		"tile": tile,
		"floor_source_id": floor_source,
		"wall_source_id": wall_source,
		"region_type": get_region_type_at_tile(tile),
		"region_data": get_region_data_at_tile(tile),
		"runtime_prop_blocked": has_runtime_prop_blocker_at_tile(tile),
		"nearby_collision_bodies": nearby_names,
		"escape_neighbor_count": get_runtime_escape_neighbor_count(tile),
		"runtime_walkable": is_runtime_walkable_after_props(tile),
		"reachable_area_tiles": _count_local_runtime_reachable_tiles(tile, 4),
		"blocker_sources": blocker_details,
		"local_collision_mask": _get_local_runtime_collision_mask(tile, 2),
	}


func debug_print_stuck_report(world_pos: Vector2) -> Dictionary:
	var report := debug_get_stuck_report_at_global(world_pos)
	print("[StuckDebug] tile=%s floor_source=%s wall_source=%s region=%s runtime_prop_blocked=%s nearby_bodies=%s escape_neighbors=%s runtime_walkable=%s" % [
		report.get("tile"), report.get("floor_source_id"), report.get("wall_source_id"),
		report.get("region_data"), report.get("runtime_prop_blocked"),
		report.get("nearby_collision_bodies"), report.get("escape_neighbor_count"),
		report.get("runtime_walkable"),
	])
	_obs_log(&"procgen_stuck_debug_report", report)
	return report


func find_nearest_runtime_walkable_global(world_pos: Vector2, radius_tiles: int = 4) -> Vector2:
	var origin := _global_to_tile(world_pos)
	var candidates: Array[Vector2i] = []
	var radius := maxi(0, radius_tiles)
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var tile := origin + Vector2i(x, y)
			if tile.distance_squared_to(origin) <= 2 \
					or not is_runtime_walkable_after_props(tile) \
					or get_runtime_escape_neighbor_count(tile) < maxi(2, runtime_blocker_min_escape_neighbors) \
					or _count_local_runtime_reachable_tiles(tile, 3) < 8 \
					or _has_runtime_blocker_within(tile, 1):
				continue
				candidates.append(tile)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := a.distance_squared_to(origin)
		var db := b.distance_squared_to(origin)
		if da == db:
			return a.x < b.x if a.y == b.y else a.y < b.y
		return da < db
	)
	return tile_to_global_position(candidates[0]) if not candidates.is_empty() else Vector2.INF


func _has_runtime_blocker_within(center: Vector2i, radius: int) -> bool:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if has_runtime_prop_blocker_at_tile(center + Vector2i(x, y)):
				return true
	return false


func _count_local_runtime_reachable_tiles(origin: Vector2i, radius: int) -> int:
	if not is_runtime_walkable_after_props(origin):
		return 0
	var visited: Dictionary = {origin: true}
	var queue: Array[Vector2i] = [origin]
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for direction: Vector2i in directions:
			var neighbor: Vector2i = current + direction
			if visited.has(neighbor) or abs(neighbor.x - origin.x) > radius or abs(neighbor.y - origin.y) > radius:
				continue
			if not is_runtime_walkable_after_props(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)
	return visited.size()


func _get_local_runtime_collision_mask(center: Vector2i, radius: int) -> Array[String]:
	var rows: Array[String] = []
	for y in range(-radius, radius + 1):
		var row := ""
		for x in range(-radius, radius + 1):
			var tile := center + Vector2i(x, y)
			if _generated_wall_cells.has(tile):
				row += "W"
			elif has_runtime_prop_blocker_at_tile(tile):
				row += "P"
			elif is_runtime_walkable_after_props(tile):
				row += "."
			else:
				row += "#"
		rows.append(row)
	return rows


func debug_get_compound_ingress_footprints() -> Array[Vector2i]:
	var footprints: Array[Vector2i] = []
	for ingress in _last_compound_ingress:
		footprints.append(ingress)
	return footprints


func debug_get_protected_passable_road_cells() -> Array[Vector2i]:
	var protected: Array[Vector2i] = []
	for tile in get_main_road_tiles():
		protected.append(tile)
	for tile in get_parking_zone_tiles():
		if not protected.has(tile):
			protected.append(tile)
	for tile in debug_get_compound_ingress_footprints():
		if not protected.has(tile):
			protected.append(tile)
	return protected


func debug_has_wall_visual_at(tile: Vector2i) -> bool:
	return walls_tilemap != null and walls_tilemap.get_cell_source_id(tile) >= 0


func debug_has_wall_authority_at(tile: Vector2i) -> bool:
	if _generated_wall_cells.has(tile):
		return true
	return debug_runtime_wall_body_exists(tile)


func debug_is_road_blocked_by_impassable_authority(tile: Vector2i) -> bool:
	return _is_road_blocked_by_impassable_authority(tile)


func debug_can_place_foliage_at(tile: Vector2i) -> bool:
	return _should_place_foliage(tile)


func debug_get_authored_scene_authority_report(rect: Rect2i) -> Dictionary:
	var wall_visual_count := 0
	var wall_authority_count := 0
	var floor_count := 0
	var blocked_elevation_count := 0
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var tile := Vector2i(x, y)
			if debug_has_wall_visual_at(tile):
				wall_visual_count += 1
			if debug_has_wall_authority_at(tile):
				wall_authority_count += 1
			if _generated_floor_cells.has(tile):
				floor_count += 1
			var traversal := String(get_elevation_data_at_tile(tile).get("traversal_type", ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE))
			if traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_BLOCKED \
					or traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_LEDGE \
					or traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_DROP:
				blocked_elevation_count += 1
	return {
		"rect": rect,
		"wall_visual_count": wall_visual_count,
		"wall_authority_count": wall_authority_count,
		"floor_count": floor_count,
		"blocked_elevation_count": blocked_elevation_count,
	}


func debug_runtime_wall_body_exists(tile: Vector2i) -> bool:
	if walls_tilemap == null:
		return false
	var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision") as Node2D
	return collision_root != null and collision_root.has_node(NodePath(_runtime_wall_body_name(tile)))


func debug_get_road_piece_decal_count() -> int:
	return _road_piece_nodes.size()


func debug_get_road_piece_decal_texture_paths() -> Array[String]:
	var paths: Array[String] = []
	for node in _road_piece_nodes:
		var sprite := node as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		paths.append(sprite.texture.resource_path)
	return paths


func debug_get_road_piece_decal_role_counts() -> Dictionary:
	var counts: Dictionary = {}
	for node in _road_piece_nodes:
		if not node.has_meta("lane_role"):
			continue
		var role := String(node.get_meta("lane_role", ""))
		if role.is_empty():
			continue
		counts[role] = int(counts.get(role, 0)) + 1
	return counts


func get_movement_surface_multiplier_at_tile(tile: Vector2i, actor_kind: String = "operator") -> float:
	if not is_road_surface_tile(tile):
		return 1.0
	if actor_kind == "vehicle":
		return maxf(1.0, road_vehicle_speed_multiplier)
	return maxf(1.0, road_walk_speed_multiplier)


func get_movement_surface_multiplier_at_global(global_position: Vector2, actor_kind: String = "operator") -> float:
	return get_movement_surface_multiplier_at_tile(_global_to_tile(global_position), actor_kind)


func get_elevation_map() -> Node:
	_ensure_elevation_map()
	return elevation_map


func get_elevation_data_at_tile(tile: Vector2i) -> Dictionary:
	if elevation_map == null:
		return {
			"height": ELEVATION_MAP_SCRIPT.DEFAULT_HEIGHT,
			"traversal_type": ELEVATION_MAP_SCRIPT.TRAVERSAL_FLAT,
			"direction": ELEVATION_MAP_SCRIPT.DIRECTION_NONE,
		}
	return elevation_map.get_cell_data(tile)


func get_elevation_at_tile(tile: Vector2i) -> int:
	return int(get_elevation_data_at_tile(tile).get("height", ELEVATION_MAP_SCRIPT.DEFAULT_HEIGHT))


func get_elevation_at_global(global_position: Vector2) -> int:
	return get_elevation_at_tile(_global_to_tile(global_position))


func get_elevation_data_at_global(global_position: Vector2) -> Dictionary:
	return get_elevation_data_at_tile(_global_to_tile(global_position))


func can_traverse_elevation(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	if elevation_map == null:
		return abs((to_tile - from_tile).x) + abs((to_tile - from_tile).y) == 1
	return elevation_map.can_traverse(from_tile, to_tile)


func can_actor_move_between_tiles(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	if elevation_map != null and elevation_map.has_method("can_traverse"):
		return bool(elevation_map.call("can_traverse", from_tile, to_tile))
	if _terrain_builder != null and _terrain_builder.has_method("can_move_between"):
		return bool(_terrain_builder.call("can_move_between", from_tile, to_tile))
	return abs((to_tile - from_tile).x) + abs((to_tile - from_tile).y) == 1


func get_actor_elevation_cost(from_tile: Vector2i, to_tile: Vector2i) -> float:
	if not can_actor_move_between_tiles(from_tile, to_tile):
		return INF
	var from_data := get_elevation_data_at_tile(from_tile)
	var to_data := get_elevation_data_at_tile(to_tile)
	var from_height := int(from_data.get("height", 0))
	var to_height := int(to_data.get("height", 0))
	var traversal := String(to_data.get("traversal_type", "walkable"))
	var cost := 1.0
	if to_height > from_height:
		cost += 0.35
	if traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_STAIR:
		cost += 0.2
	elif traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_RAMP:
		cost += 0.15
	return cost


func is_valid_spawn_cell(tile: Vector2i) -> bool:
	if _generated_floor_cells.is_empty() and procgen_node != null:
		return not procgen_node.is_full_at(tile)
	if not _generated_floor_cells.has(tile):
		return false
	if _generated_wall_cells.has(tile):
		return false
	if elevation_map != null and elevation_map.has_method("is_valid_spawn_cell"):
		return bool(elevation_map.call("is_valid_spawn_cell", tile))
	var elevation_data := get_elevation_data_at_tile(tile)
	var traversal := String(elevation_data.get("traversal_type", ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE))
	return traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE or traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_RAMP or traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_STAIR


func is_indoor_tile(tile: Vector2i) -> bool:
	var region_type := get_region_type_at_tile(tile)
	return region_type == "interior_floor" or region_type == "interior_wall" or region_type == "interior_threshold"


func get_intensity_at_tile(tile: Vector2i) -> float:
	if procgen_node == null:
		return 0.0
	var spawn := get_player_spawn()
	var map_vector := Vector2(float(procgen_node.map_size.x), float(procgen_node.map_size.y))
	var max_dist := maxf(1.0, map_vector.length())
	var value := clampf(tile.distance_to(spawn) / max_dist, 0.0, 1.0)
	var region := get_region_type_at_tile(tile)
	match region:
		"spawn_clearing":
			value -= 0.35
		"soft_path":
			value -= 0.10
		"compound_approach":
			value += 0.08
		"cover_anchor":
			value += 0.10
		"interior_threshold":
			value += 0.15
		"interior_floor":
			value += 0.22
		"main_road":
			value -= 0.08
		"parking_zone":
			value -= 0.12
		"portal_plaza":
			value += 0.30
		"destroyed_wall_floor":
			value += 0.12
		"foliage_cover":
			value += 0.05
	if _last_compound_rect.size.x > 0 and _last_compound_rect.has_point(tile):
		value += 0.08
	if _last_interior_region_rect.size.x > 0 and _last_interior_region_rect.has_point(tile):
		value += 0.12
	return clampf(value, 0.0, 1.0)


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


func _set_destroyed_wall_floor_tile(pos: Vector2i) -> void:
	if floor_tilemap == null or walls_tilemap == null:
		return
	var source_id := _select_floor_source_id(pos)
	var atlas := _select_floor_coord(pos)
	_generated_floor_cells[pos] = {
		"source_id": source_id,
		"atlas": atlas,
		"alternative": 0,
	}
	floor_tilemap.set_cell(pos, source_id, atlas, 0)
	walls_tilemap.erase_cell(pos)
	_wall_health.erase(pos)
	_set_region_tile(pos, "destroyed_wall_floor", "debris")


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
	_set_destroyed_wall_floor_tile(pos)
	minimap_tile_changed.emit(pos, "destroyed_wall_floor")
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
			var source := high_walls_source_id if use_high_walls else walls_source_id
			var coord := _select_wall_coord(pos)
			walls_tilemap.set_cell(pos, source, coord)
			if _generated_wall_cells.has(pos):
				_generated_wall_cells[pos] = {
					"source_id": source,
					"atlas": coord,
					"alternative": walls_tilemap.get_cell_alternative_tile(pos),
				}


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
	var rebuilt := false
	for navigation_node in get_tree().get_nodes_in_group("navigation"):
		if navigation_node != null and navigation_node.has_method("rebuild"):
			if navigation_node.has_method("set_runtime_tilemaps"):
				navigation_node.call("set_runtime_tilemaps", floor_tilemap, walls_tilemap, self)
			navigation_node.call("rebuild")
			rebuilt = true
	if not rebuilt and nav_region != null:
		nav_region.bake_navigation_polygon(false)


func _capture_generated_tile_state(map_size: Vector2i) -> void:
	if not enable_streaming_reveal:
		_generated_floor_cells.clear()
		_generated_wall_cells.clear()
	# Streaming reveal keeps undiscovered authoritative cells unpainted, so merge
	# visible TileMap cells without clearing the dictionaries in that mode.
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
				_generated_wall_cells.erase(pos)
			var wall_source := walls_tilemap.get_cell_source_id(pos)
			if wall_source >= 0:
				_generated_wall_cells[pos] = {
					"source_id": wall_source,
					"atlas": walls_tilemap.get_cell_atlas_coords(pos),
					"alternative": walls_tilemap.get_cell_alternative_tile(pos),
				}
				_generated_floor_cells.erase(pos)


func _ensure_elevation_map() -> void:
	if elevation_map != null and is_instance_valid(elevation_map):
		return
	var existing := get_node_or_null("ElevationMap")
	if existing != null:
		elevation_map = existing
		return
	elevation_map = ELEVATION_MAP_SCRIPT.new()
	elevation_map.name = "ElevationMap"
	add_child(elevation_map)


func _ensure_terrain_builder() -> void:
	if _terrain_builder == null:
		_terrain_builder = TERRAIN_BUILDER_SCRIPT.new()


func _clear_elevation_metadata() -> void:
	_ensure_elevation_map()
	elevation_map.clear()
	_last_terrain_result.clear()
	_last_pre_terrain_connectivity.clear()


func _apply_terrain_builder(map_size: Vector2i) -> void:
	_ensure_elevation_map()
	_ensure_terrain_builder()
	var terrain_rng := RandomNumberGenerator.new()
	var terrain_seed := _tile_noise_hash(Vector2i(1901, 2909))
	terrain_rng.seed = terrain_seed
	var required_cell_entries := _collect_terrain_required_cell_entries(map_size)
	var required_cells := _terrain_required_entries_to_cells(required_cell_entries)
	var pre_repair_connectivity := _compute_pre_terrain_connectivity(map_size, required_cell_entries)
	var pre_terrain_repair := _repair_pre_terrain_required_connectivity(map_size, required_cell_entries)
	_last_pre_terrain_connectivity = _compute_pre_terrain_connectivity(map_size, required_cell_entries)
	_last_pre_terrain_connectivity["pre_terrain_before_repair"] = pre_repair_connectivity
	_last_pre_terrain_connectivity["pre_terrain_authority_repair_carved_cells"] = int(pre_terrain_repair.get("carved_cells", 0))
	var context := {
		"seed": terrain_seed,
		"floor_cells": _dict_keys_as_vector2i_array(_generated_floor_cells),
		"blocked_cells": _dict_keys_as_vector2i_array(_generated_wall_cells),
		"start_cell": get_player_spawn(),
		"required_cells": required_cells,
		"enable_industrial_platform": elevation_platform_stamps_enabled,
		"enable_mountain_boundary": terrain_builder_mountain_boundary_enabled,
		"enable_ascent_route": ascent_route_enabled and world_progression_enabled,
		"world_progress_profile": _world_progress_profile,
		"world_progress_profile_path": world_progress_profile_path,
		"worldgen_intent_graph": _worldgen_intent_graph,
		"worldgen_reserved_regions": _worldgen_reserved_regions,
		"worldgen_intent_floor_cells": _worldgen_intent_floor_cells,
		"generation_mode": "EVAL_CANDIDATE" if generation_evaluation_mode else "FINAL_VISUAL",
	}
	_last_terrain_result = _terrain_builder.build_terrain(Rect2i(Vector2i.ZERO, map_size), terrain_rng, context)
	if elevation_map.has_method("apply_build_result"):
		elevation_map.call("apply_build_result", _last_terrain_result)
	_apply_terrain_visuals(_last_terrain_result)
	_update_terrain_debug_overlay()
	_log_terrain_builder_summary(_last_terrain_result)


func _repair_pre_terrain_required_connectivity(map_size: Vector2i, required_cell_entries: Array[Dictionary]) -> Dictionary:
	return PRETERRAIN_AUTHORITY_REPAIR_SCRIPT.repair({
		"compute_diagnostics": func() -> Dictionary:
			return _compute_pre_terrain_connectivity(map_size, required_cell_entries),
		"set_bridge_floor": func(tile: Vector2i) -> int:
			return _set_pre_terrain_bridge_floor(tile, map_size),
		"carve_bridge": func(from_tile: Vector2i, to_tile: Vector2i) -> int:
			return _carve_pre_terrain_authority_bridge(from_tile, to_tile, map_size),
	})


func _carve_pre_terrain_authority_bridge(from_tile: Vector2i, to_tile: Vector2i, map_size: Vector2i) -> int:
	var carved := 0
	var current := from_tile
	carved += _set_pre_terrain_bridge_floor(current, map_size)
	var x_step := 1 if to_tile.x >= current.x else -1
	while current.x != to_tile.x:
		current.x += x_step
		carved += _set_pre_terrain_bridge_floor(current, map_size)
	var y_step := 1 if to_tile.y >= current.y else -1
	while current.y != to_tile.y:
		current.y += y_step
		carved += _set_pre_terrain_bridge_floor(current, map_size)
	return carved


func _set_pre_terrain_bridge_floor(tile: Vector2i, map_size: Vector2i) -> int:
	if not _is_tile_inside_map(tile, map_size, 1):
		return 0
	var was_walkable := _is_pre_terrain_walkable_cell(tile, map_size)
	_set_floor_tile_and_generated_state(tile, "pre_terrain_required_connector", "authority_repair")
	_apply_terrain_tile_visual(tile, _deterministic_connector_repair_tile_id(tile))
	return 0 if was_walkable else 1


func _collect_terrain_required_cells(map_size: Vector2i) -> Array[Vector2i]:
	return _terrain_required_entries_to_cells(_collect_terrain_required_cell_entries(map_size))


func _collect_terrain_required_cell_entries(map_size: Vector2i) -> Array[Dictionary]:
	var intent_required_cells: Array = []
	if _worldgen_intent_graph != null:
		intent_required_cells = _worldgen_intent_graph.get_required_cells()
	return REQUIRED_CELL_CLASSIFIER_SCRIPT.collect_required_cell_entries({
		"map_size": map_size,
		"spawn": get_player_spawn(),
		"is_ascent_field": world_shape_mode == WorldShapeMode.ASCENT_FIELD,
		"rooms_by_distance": get_rooms_by_distance_from_spawn(),
		"last_interior_thresholds": _last_interior_thresholds,
		"last_compound_ingress": _last_compound_ingress,
		"connected_road_required_tiles": _get_connected_road_required_tiles(),
		"connected_parking_required_tiles": _get_connected_parking_required_tiles(),
		"compound_connector_centerline_tiles": _compound_connector_centerline_tiles,
		"ascent_field_main_route_cells": _ascent_field_main_route_cells,
		"ascent_field_vista_cells": _ascent_field_vista_cells,
		"intent_graph_required_cells": intent_required_cells,
		"is_tile_inside_map": Callable(self, "_is_tile_inside_map"),
	})


func _terrain_required_entries_to_cells(entries: Array[Dictionary]) -> Array[Vector2i]:
	return REQUIRED_CELL_CLASSIFIER_SCRIPT.entries_to_cells(entries)


func _get_connected_road_required_tiles() -> Dictionary:
	var connected := _get_connected_road_tiles_from_spawn()
	var result := {}
	for tile_variant in connected.keys():
		if tile_variant is Vector2i and _main_road_tiles.has(tile_variant):
			result[tile_variant] = true
	return result


func _get_connected_parking_required_tiles() -> Dictionary:
	var connected := _get_connected_road_tiles_from_spawn()
	var result := {}
	for tile_variant in _parking_zone_tiles.keys():
		if tile_variant is Vector2i and connected.has(tile_variant):
			result[tile_variant] = true
	return result


func _get_connected_road_tiles_from_spawn() -> Dictionary:
	var spawn := get_player_spawn()
	if _main_road_tiles.has(spawn):
		return _collect_connected_road_tiles(spawn)
	var best_root := Vector2i.ZERO
	var best_distance := INF
	for tile_variant in _main_road_tiles.keys():
		if not (tile_variant is Vector2i):
			continue
		var tile := tile_variant as Vector2i
		var distance := tile.distance_squared_to(spawn)
		if distance < best_distance:
			best_distance = distance
			best_root = tile
	if best_distance == INF:
		return {}
	return _collect_connected_road_tiles(best_root)


func _compute_pre_terrain_connectivity(map_size: Vector2i, required_cell_entries: Array[Dictionary]) -> Dictionary:
	return PRETERRAIN_DIAGNOSTICS_SCRIPT.compute({
		"map_size": map_size,
		"spawn": get_player_spawn(),
		"required_cell_entries": required_cell_entries,
		"floor_cells": _generated_floor_cells,
		"wall_cells": _generated_wall_cells,
		"road_cells": _main_road_tiles,
		"parking_cells": _parking_zone_tiles,
		"is_layout_walkable": Callable(self, "_is_layout_pre_terrain_walkable_cell"),
		"is_baseline_walkable": Callable(self, "_is_pre_terrain_walkable_cell"),
		"is_semantic_walkable": Callable(self, "_is_semantic_required_walkable_cell"),
		"classify_missing_reason": Callable(self, "_classify_pre_terrain_missing_reason"),
		"build_missing_sample": Callable(self, "_build_pre_terrain_missing_sample"),
		"get_region_data_at_tile": Callable(self, "get_region_data_at_tile"),
	})


func _is_pre_terrain_walkable_cell(cell: Vector2i, map_size: Vector2i) -> bool:
	if not _is_tile_inside_map(cell, map_size):
		return false
	if not _generated_floor_cells.has(cell):
		return false
	if _generated_wall_cells.has(cell):
		return false
	return true


func _is_layout_pre_terrain_walkable_cell(cell: Vector2i, map_size: Vector2i) -> bool:
	if not _is_tile_inside_map(cell, map_size):
		return false
	return is_valid_spawn_cell(cell)


func _is_semantic_required_walkable_cell(cell: Vector2i, map_size: Vector2i) -> bool:
	if _is_pre_terrain_walkable_cell(cell, map_size):
		return true
	if not _is_tile_inside_map(cell, map_size):
		return false
	if _generated_wall_cells.has(cell):
		return false
	var region_type := get_region_type_at_tile(cell)
	return _main_road_tiles.has(cell) \
			or _parking_zone_tiles.has(cell) \
			or region_type == "compound_ingress" \
			or region_type == "compound_connector_road" \
			or region_type == "main_road" \
			or region_type == "parking_zone" \
			or region_type == "interior_threshold" \
			or region_type == "authored_scene_floor"


func _classify_pre_terrain_missing_reason(cell: Vector2i, map_size: Vector2i) -> String:
	if not _is_tile_inside_map(cell, map_size):
		return "missing_from_floor_authority"
	if _generated_wall_cells.has(cell):
		return "blocked_by_wall_authority"
	if not _generated_floor_cells.has(cell):
		return "missing_from_floor_authority"
	if not _is_pre_terrain_walkable_cell(cell, map_size):
		return "not_walkable_pre_terrain"
	return "unreachable_from_spawn"


func _build_pre_terrain_missing_sample(cell: Vector2i, source: String, reason: String, reachable: Dictionary) -> Dictionary:
	var region := get_region_data_at_tile(cell)
	return {
		"tile": cell,
		"source": source if not source.is_empty() else "unknown",
		"reason": reason,
		"region_type": String(region.get("region_type", "exterior")),
		"zone": String(region.get("zone", "natural")),
		"is_floor": _generated_floor_cells.has(cell),
		"is_wall": _generated_wall_cells.has(cell),
		"is_road": _main_road_tiles.has(cell) or get_region_type_at_tile(cell) == "main_road",
		"is_parking": _parking_zone_tiles.has(cell),
		"is_indoor": is_indoor_tile(cell),
		"nearest_reachable_distance": _nearest_reachable_manhattan_distance(cell, reachable),
	}


func _nearest_reachable_manhattan_distance(cell: Vector2i, reachable: Dictionary) -> int:
	if reachable.is_empty():
		return -1
	var best := 2147483647
	for tile_variant in reachable.keys():
		if not (tile_variant is Vector2i):
			continue
		var tile := tile_variant as Vector2i
		var distance := absi(tile.x - cell.x) + absi(tile.y - cell.y)
		if distance < best:
			best = distance
	return best if best != 2147483647 else -1


func _dedupe_vector2i_array(cells: Array[Vector2i]) -> Array[Vector2i]:
	var seen := {}
	var result: Array[Vector2i] = []
	for cell in cells:
		if seen.has(cell):
			continue
		seen[cell] = true
		result.append(cell)
	return result


func _apply_terrain_visuals(terrain_result: Dictionary) -> void:
	var traversal_by_cell: Dictionary = terrain_result.get("traversal_by_cell", {})
	var tile_by_cell: Dictionary = terrain_result.get("tile_by_cell", {})
	for cell_variant in traversal_by_cell.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		var traversal := String(traversal_by_cell.get(cell, ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE))
		var tile_id := String(tile_by_cell.get(cell, ""))
		var visual_tile_id := _resolve_live_terrain_visual_tile_id(cell, tile_id)
		var rendered_tile := _apply_terrain_tile_visual(cell, visual_tile_id)
		if traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_BLOCKED:
			if tile_id.is_empty():
				continue
			if not rendered_tile:
				_set_wall_tile(cell)
			if tile_id == "mountain_wall_impassable_32":
				_set_region_tile(cell, "terrain_mountain_wall", "blocked")
			else:
				_set_region_tile(cell, "terrain_blocked", "blocked")
		elif traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_DROP:
			if tile_id.is_empty():
				continue
			if not rendered_tile:
				_set_hole_tile(cell)
			_set_region_tile(cell, "terrain_drop", "blocked")
		elif traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_LEDGE:
			if tile_id.is_empty():
				continue
			_set_region_tile(cell, "terrain_elevation_ledge", "elevated")
		elif traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_RAMP or traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_STAIR:
			if tile_id.is_empty():
				continue
			_set_region_tile(cell, "terrain_elevation_access", "elevated")
		elif int(terrain_result.get("height_by_cell", {}).get(cell, 0)) > 0:
			if tile_id.is_empty():
				continue
			_set_region_tile(cell, "terrain_elevated_floor", "elevated")
		elif traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE and tile_id == "rescue_walkable_ground":
			_ensure_walkable_terrain_floor_authority(cell, rendered_tile, "terrain_rescue_floor", "walkable")
			_apply_terrain_tile_visual(cell, _deterministic_connector_repair_tile_id(cell))
		elif _is_walkable_terrain_traversal(traversal):
			_ensure_walkable_terrain_floor_authority(cell, rendered_tile, "terrain_walkable_floor", "walkable")


func _resolve_live_terrain_visual_tile_id(cell: Vector2i, tile_id: String) -> String:
	if tile_id == "cliff_chasm_drop_32":
		return "chasm_void_32" if _tile_noise_hash(cell) % 2 == 0 else "collapsed_gap_32"
	return tile_id


func _is_walkable_terrain_traversal(traversal: String) -> bool:
	return traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE \
			or traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_RAMP \
			or traversal == ELEVATION_MAP_SCRIPT.TRAVERSAL_STAIR


func _ensure_walkable_terrain_floor_authority(cell: Vector2i, rendered_tile: bool, region_type: String, zone: String) -> void:
	if rendered_tile and _generated_floor_cells.has(cell) and not _generated_wall_cells.has(cell):
		return
	_set_floor_tile_and_generated_state(cell, region_type, zone)


func _apply_compound_connector_elevation(map_size: Vector2i) -> void:
	if not intent_compound_connector_elevation_enabled:
		return
	if _compound_connector_centerline_tiles.is_empty():
		return
	_ensure_elevation_map()
	var width := maxi(1, intent_compound_connector_half_width)
	var count := _compound_connector_centerline_tiles.size()
	var ramp_index := clampi(int(round(float(count) * 0.55)), 1, maxi(1, count - 2))
	var direction := _get_compound_connector_outward_direction()
	var side_axis := Vector2i(-direction.y, direction.x)
	var ramp_direction := _direction_name_from_delta(direction)
	var ramp_tile_id := _ramp_tile_id_from_delta(direction)
	for index in range(count):
		var center := _compound_connector_centerline_tiles[index]
		for lateral in range(-width, width + 1):
			var tile := center + side_axis * lateral
			if not _is_tile_inside_map(tile, map_size, 1) or not _main_road_tiles.has(tile):
				continue
			if index < ramp_index:
				elevation_map.set_cell(tile, 1, ELEVATION_MAP_SCRIPT.TRAVERSAL_WALKABLE, ELEVATION_MAP_SCRIPT.DIRECTION_NONE)
				_apply_terrain_tile_visual(tile, "terrain_landing_industrial_32")
				_set_region_tile(tile, "compound_connector_elevated_road", "compound_ingress")
			elif index == ramp_index:
				elevation_map.set_cell(tile, 1, ELEVATION_MAP_SCRIPT.TRAVERSAL_RAMP, ramp_direction)
				_apply_terrain_tile_visual(tile, ramp_tile_id)
				_set_region_tile(tile, "compound_connector_ramp", "compound_ingress")
			_clear_road_blocking_wall(tile)


func _refresh_compound_connector_pack_visuals(map_size: Vector2i) -> void:
	if _compound_connector_visual_candidates.is_empty():
		return
	for tile_variant in _compound_connector_visual_candidates:
		if not (tile_variant is Vector2i):
			continue
		var tile := tile_variant as Vector2i
		if not _is_tile_inside_map(tile, map_size, 1) \
				or not _main_road_tiles.has(tile) \
				or _is_road_blocked_by_impassable_authority(tile) \
				or _should_preserve_road_floor_visual(tile):
			continue
		var is_centerline := bool(_compound_connector_visual_candidates[tile])
		var tile_id := "terrain_connector_centerline_32" if is_centerline else _deterministic_connector_repair_tile_id(tile)
		_apply_terrain_tile_visual(tile, tile_id)


func _get_compound_connector_outward_direction() -> Vector2i:
	if _last_compound_rect.size.x <= 0 or _last_compound_ingress.is_empty():
		return Vector2i.DOWN
	return -_get_compound_ingress_inward(_last_compound_ingress[0], _last_compound_rect)


func _direction_name_from_delta(delta: Vector2i) -> String:
	match delta:
		Vector2i.UP:
			return ELEVATION_MAP_SCRIPT.DIRECTION_NORTH
		Vector2i.DOWN:
			return ELEVATION_MAP_SCRIPT.DIRECTION_SOUTH
		Vector2i.LEFT:
			return ELEVATION_MAP_SCRIPT.DIRECTION_WEST
		Vector2i.RIGHT:
			return ELEVATION_MAP_SCRIPT.DIRECTION_EAST
		_:
			return ELEVATION_MAP_SCRIPT.DIRECTION_NONE


func _ramp_tile_id_from_delta(delta: Vector2i) -> String:
	match delta:
		Vector2i.UP:
			return "ramp_north_wide_32"
		Vector2i.DOWN:
			return "ramp_south_wide_32"
		Vector2i.LEFT:
			return "ramp_west_wide_32"
		Vector2i.RIGHT:
			return "ramp_east_wide_32"
		_:
			return "ramp_south_wide_32"


func _apply_terrain_tile_visual(cell: Vector2i, tile_id: String) -> bool:
	if tile_id.is_empty():
		return false
	if not TERRAIN_TILESET_SOURCES.has(tile_id):
		return false
	var def: Dictionary = TERRAIN_TILESET_SOURCES[tile_id]
	var source_id := int(def.get("source_id", -1))
	if source_id < 0:
		return false
	var layer := String(def.get("layer", "floor"))
	if layer == "wall":
		_set_terrain_wall_visual(cell, source_id)
	else:
		_set_terrain_floor_visual(cell, source_id)
	return true


func _set_terrain_floor_visual(cell: Vector2i, source_id: int) -> void:
	if floor_tilemap == null:
		return
	floor_tilemap.set_cell(cell, source_id, TERRAIN_TILE_ATLAS_COORD)
	_generated_floor_cells[cell] = {
		"source_id": source_id,
		"atlas": TERRAIN_TILE_ATLAS_COORD,
		"alternative": 0,
	}
	if walls_tilemap != null:
		walls_tilemap.erase_cell(cell)
	_generated_wall_cells.erase(cell)
	_wall_health.erase(cell)


func _set_terrain_wall_visual(cell: Vector2i, source_id: int) -> void:
	if walls_tilemap == null:
		return
	walls_tilemap.set_cell(cell, source_id, TERRAIN_TILE_ATLAS_COORD)
	_generated_wall_cells[cell] = {
		"source_id": source_id,
		"atlas": TERRAIN_TILE_ATLAS_COORD,
		"alternative": 0,
	}
	if floor_tilemap != null:
		floor_tilemap.erase_cell(cell)
	_generated_floor_cells.erase(cell)
	if not _wall_health.has(cell):
		_wall_health[cell] = wall_tile_max_health


func _update_terrain_debug_overlay() -> void:
	if terrain_debug_overlay == null:
		return
	if terrain_debug_overlay.has_method("set_terrain_result"):
		terrain_debug_overlay.call("set_terrain_result", _last_terrain_result)


func set_terrain_debug_enabled(enabled: bool) -> void:
	if terrain_debug_overlay == null:
		return
	if terrain_debug_overlay.get("enabled") != null:
		terrain_debug_overlay.set("enabled", enabled)
	else:
		terrain_debug_overlay.visible = enabled


func _log_terrain_builder_summary(terrain_result: Dictionary) -> void:
	if not terrain_builder_debug_logging:
		return
	var summary: Dictionary = terrain_result.get("debug_summary", {})
	print("TerrainBuilder: seed=%s mode=%s map_size=%s required=%s missing=%s rescue_carved=%s baseline_rescue=%s regions=%s blocked=%s elevated=%s ramps=%s connectivity=%s fallback=%s" % [
		str(summary.get("seed", 0)),
		str(summary.get("generation_mode", "FINAL_VISUAL")),
		str(summary.get("map_size", Vector2i.ZERO)),
		str(summary.get("required_cell_count", 0)),
		str(summary.get("missing_required_count", 0)),
		str(summary.get("rescue_carved_cells", 0)),
		str(summary.get("baseline_rescue_carved_cells", 0)),
		str(summary.get("regions", 0)),
		str(summary.get("blocked_cells", 0)),
		str(summary.get("elevated_cells", 0)),
		str(summary.get("ramp_or_stair_cells", 0)),
		str(summary.get("connectivity_ok", true)),
		str(summary.get("fallback_used", false)),
	])
	if generation_evaluation_mode and not bool(summary.get("fallback_used", false)):
		return
	for warning in terrain_result.get("warnings", []):
		push_warning(str(warning))


func _ensure_foliage_spawner() -> void:
	if _foliage_spawner == null:
		_foliage_spawner = PROCGEN_FOLIAGE_SPAWNER_SCRIPT.new()


func _build_foliage_spawner_context(map_size: Vector2i = Vector2i.ZERO) -> Dictionary:
	return {
		"host": self,
		"map_size": map_size,
		"foliage_parent": _foliage_parent,
		"foliage_nodes": _foliage_nodes,
		"fruit_sprites": _fruit_sprites,
		"foliage_textures": _foliage_textures,
		"fruit_texture": _fruit_texture,
		"generated_floor_cells": _generated_floor_cells,
		"generated_wall_cells": _generated_wall_cells,
		"region_tiles": _region_tiles,
		"last_compound_buildings": _last_compound_buildings,
		"last_compound_rect": _last_compound_rect,
		"pending_foliage_tiles": _pending_foliage_tiles,
		"enable_streaming_reveal": enable_streaming_reveal,
		"foliage_debug_logging": foliage_debug_logging,
		"foliage_deferred_spawn_enabled": foliage_deferred_spawn_enabled,
		"foliage_spawn_batch_size": foliage_spawn_batch_size,
		"foliage_density": foliage_density,
		"foliage_compound_density_multiplier": foliage_compound_density_multiplier,
		"foliage_indoor_clearance_tiles": foliage_indoor_clearance_tiles,
		"foliage_min_wall_distance": foliage_min_wall_distance,
		"foliage_spawn_clearance_radius": foliage_spawn_clearance_radius,
		"foliage_compound_building_clearance": foliage_compound_building_clearance,
		"foliage_jitter_amplitude": foliage_jitter_amplitude,
		"foliage_behind_z_index": foliage_behind_z_index,
		"foliage_front_z_index": foliage_front_z_index,
		"foliage_player_occlusion_radius": foliage_player_occlusion_radius,
		"foliage_player_occlusion_softness": foliage_player_occlusion_softness,
		"foliage_player_occlusion_alpha": foliage_player_occlusion_alpha,
		"foliage_wind_enabled": foliage_wind_enabled,
		"foliage_wind_speed": foliage_wind_speed,
		"foliage_shrub_wind_strength_px": foliage_shrub_wind_strength_px,
		"foliage_tree_wind_strength_px": foliage_tree_wind_strength_px,
		"foliage_wind_gust_amount": foliage_wind_gust_amount,
		"foliage_occlusion_shader": FOLIAGE_OCCLUSION_SHADER,
		"foliage_occlusion_max_shader_bubbles": FOLIAGE_OCCLUSION_MAX_SHADER_BUBBLES,
		"foliage_tree_trunk_collision_size": foliage_tree_trunk_collision_size,
		"foliage_tree_trunk_collision_offset": foliage_tree_trunk_collision_offset,
		"foliage_probabilistic_tree_collision": foliage_probabilistic_tree_collision,
		"foliage_tree_collision_density_radius": foliage_tree_collision_density_radius,
		"foliage_sparse_tree_collision_threshold": foliage_sparse_tree_collision_threshold,
		"foliage_dense_tree_collision_threshold": foliage_dense_tree_collision_threshold,
		"foliage_dense_tree_collision_chance": foliage_dense_tree_collision_chance,
		"intent_mark_foliage_cover": intent_mark_foliage_cover,
		"enable_fruit_spawning": enable_fruit_spawning,
		"fruit_spawn_chance_tree": fruit_spawn_chance_tree,
		"fruit_spawn_chance_shrub": fruit_spawn_chance_shrub,
		"fruit_tiles_wide": fruit_tiles_wide,
		"fruit_tiles_high": fruit_tiles_high,
		"tile_noise_hash": Callable(self, "_tile_noise_hash"),
		"tile_to_world_position": Callable(self, "_tile_to_world_position"),
		"get_planet_profile_color": Callable(self, "_get_planet_profile_color"),
		"get_player_spawn": Callable(self, "get_player_spawn"),
		"is_road_surface_tile": Callable(self, "is_road_surface_tile"),
		"is_parking_zone_tile": Callable(self, "is_parking_zone_tile"),
		"is_indoor_tile": Callable(self, "is_indoor_tile"),
		"is_inside_combat_readability_clearance": Callable(self, "_is_inside_combat_readability_spawn_clearance"),
		"get_region_type_at_tile": Callable(self, "get_region_type_at_tile"),
		"get_region_data_at_tile": Callable(self, "get_region_data_at_tile"),
		"set_region_tile": Callable(self, "_set_region_tile"),
		"is_inside_tree_trunk_clearance": Callable(self, "_is_inside_tree_trunk_clearance"),
		"register_runtime_prop_blocker": Callable(self, "_register_foliage_runtime_blocker"),
		"unregister_runtime_prop_blocker": Callable(self, "unregister_runtime_prop_blocker"),
	}


func _generate_foliage(map_size: Vector2i) -> void:
	_ensure_foliage_spawner()
	var result: Dictionary = _foliage_spawner.generate(_build_foliage_spawner_context(map_size))
	if bool(result.get("deferred", false)) and not _pending_foliage_tiles.is_empty():
		_foliage_deferred_start_msec = Time.get_ticks_msec()
	else:
		_foliage_deferred_start_msec = 0


func _clear_foliage() -> void:
	_ensure_foliage_spawner()
	_foliage_spawner.clear(_build_foliage_spawner_context())
	_foliage_deferred_start_msec = 0


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
	_ruin_prop_scatterer.force_collision_debug = ruin_prop_force_collision_debug
	_ruin_prop_parent.add_child(_ruin_prop_scatterer)

	var spawned := _ruin_prop_scatterer.scatter_on_tiles(
		candidate_tiles,
		Callable(self, "_ruin_prop_tile_to_world"),
		{},
		Callable(self, "_validate_ruin_prop_candidate")
	)
	_configure_portal_pair(candidate_tiles, spawned, map_size)
	_reject_ruin_props_after_route_finalization(spawned)
	_obs_gauge(&"procgen_scattered_prop_count", spawned.size())
	for prop in spawned:
		if prop != null and is_instance_valid(prop) and not prop.is_queued_for_deletion() \
				and not bool(prop.get_meta("procgen_candidate_rejected", false)):
			_register_runtime_prop_node(prop, &"ruin_prop")
			_enforce_ruin_prop_blocker_clearance(prop)
			_observe_ruin_prop_collision(prop)
	validate_no_stuck_pockets(runtime_blocker_remediate_stuck_pockets)
	if ruin_prop_debug_logging:
		print("[RuinProps] Placed %d props under %s" % [spawned.size(), _ruin_prop_parent.get_path()])


func _reject_ruin_props_after_route_finalization(spawned: Array[ProceduralProp]) -> void:
	# Portal pairing reserves/carves connector paths after the initial scatter.
	# Revalidate before any blocker is registered so those late route cells cannot
	# turn a decorative candidate into a live collision-remediation warning.
	for prop in spawned:
		if prop == null or not is_instance_valid(prop) or prop.is_queued_for_deletion() or _is_portal_prop(prop):
			continue
		var verdict := _validate_spawned_ruin_prop_candidate(prop)
		if bool(verdict.get("allowed", true)):
			continue
		verdict["remediation_action"] = "removed_prop_before_blocker_registration"
		_obs_log(&"procgen_prop_candidate_removed_after_route_reservation", verdict)
		prop.set_meta("procgen_candidate_rejected", true)
		prop.queue_free()


func _validate_spawned_ruin_prop_candidate(prop: ProceduralProp) -> Dictionary:
	var collision_rect := prop.get_collision_rect_global()
	var footprint := _collision_cells_for_global_rect(collision_rect)
	var verdict := {
		"allowed": true,
		"definition_id": str(prop.definition.id) if prop.definition != null else "unknown",
		"spawn_tile": _get_prop_source_tile(prop),
		"prop_global_position": prop.global_position,
		"collision_rect_global": collision_rect,
		"collision_rect_tile_footprint": footprint,
		"seed": _get_generation_seed(),
	}
	for cell in footprint:
		var protected_zone := _get_ruin_prop_protected_zone_type(cell)
		if not protected_zone.is_empty():
			verdict["allowed"] = false
			verdict["protected_zone_type"] = String(protected_zone)
			_record_ruin_prop_candidate_rejection(&"protected_zone", verdict)
			return verdict
		if _runtime_prop_blocker_cells.has(cell):
			verdict["allowed"] = false
			verdict["protected_zone_type"] = "existing_runtime_blocker"
			_record_ruin_prop_candidate_rejection(&"existing_blocker", verdict)
			return verdict
	if _would_ruin_prop_footprint_create_stuck_risk(footprint):
		verdict["allowed"] = false
		verdict["protected_zone_type"] = "local_escape"
		_record_ruin_prop_candidate_rejection(&"stuck_risk", verdict)
	return verdict


func _reset_generation_prop_observability() -> void:
	_generation_prop_rejections_protected_zone = 0
	_generation_prop_rejections_stuck_risk = 0
	_generation_prop_rejections_existing_blocker = 0
	_generation_prop_collision_alignment_warnings = 0
	_obs_gauge(&"procgen_prop_candidates_rejected_protected_zone", 0)
	_obs_gauge(&"procgen_prop_candidates_rejected_stuck_risk", 0)
	_obs_gauge(&"procgen_prop_candidates_rejected_existing_blocker", 0)
	_obs_gauge(&"procgen_stuck_pockets_detected_last_generation", 0)
	_obs_gauge(&"procgen_stuck_pockets_remediated_last_generation", 0)
	_obs_gauge(&"procgen_prop_collision_alignment_warning_count_last_generation", 0)


func _validate_ruin_prop_candidate(
	definition: PropDefinition,
	source_tile: Vector2i,
	world_position: Vector2
) -> Dictionary:
	var verdict := {
		"allowed": true,
		"definition_id": str(definition.id) if definition != null else "unknown",
		"spawn_tile": source_tile,
		"prop_global_position": world_position,
		"seed": _get_generation_seed(),
	}
	if definition == null:
		return verdict
	# Bespoke collision scenes (currently the paired portal endpoints) keep their
	# dedicated placement validator because a union rectangle would fill authored gaps.
	if definition.collision_scene != null:
		return verdict
	if definition.collision_shape_size.x <= 0.0 or definition.collision_shape_size.y <= 0.0:
		return verdict

	var collision_rect := _get_definition_collision_rect_global(definition, world_position)
	var footprint := _collision_cells_for_global_rect(collision_rect)
	verdict["collision_rect_global"] = collision_rect
	verdict["collision_rect_tile_footprint"] = footprint
	for cell in footprint:
		var protected_zone := _get_ruin_prop_protected_zone_type(cell)
		if not protected_zone.is_empty():
			verdict["allowed"] = false
			verdict["protected_zone_type"] = String(protected_zone)
			verdict["remediation_action"] = "rejected_before_spawn"
			_record_ruin_prop_candidate_rejection(&"protected_zone", verdict)
			return verdict
		if _runtime_prop_blocker_cells.has(cell):
			verdict["allowed"] = false
			verdict["protected_zone_type"] = "existing_runtime_blocker"
			verdict["remediation_action"] = "rejected_before_spawn"
			_record_ruin_prop_candidate_rejection(&"existing_blocker", verdict)
			return verdict

	if _would_ruin_prop_footprint_create_stuck_risk(footprint):
		verdict["allowed"] = false
		verdict["protected_zone_type"] = "local_escape"
		verdict["remediation_action"] = "rejected_before_spawn"
		_record_ruin_prop_candidate_rejection(&"stuck_risk", verdict)
	return verdict


func _get_definition_collision_rect_global(definition: PropDefinition, world_position: Vector2) -> Rect2:
	var half_size := definition.collision_shape_size * 0.5
	var rotation := deg_to_rad(definition.collision_shape_rotation_degrees)
	var transform := Transform2D(rotation, world_position + definition.collision_shape_offset)
	var corners: Array[Vector2] = [
		transform * Vector2(-half_size.x, -half_size.y),
		transform * Vector2(half_size.x, -half_size.y),
		transform * Vector2(half_size.x, half_size.y),
		transform * Vector2(-half_size.x, half_size.y),
	]
	var min_point := corners[0]
	var max_point := corners[0]
	for corner in corners:
		min_point = Vector2(minf(min_point.x, corner.x), minf(min_point.y, corner.y))
		max_point = Vector2(maxf(max_point.x, corner.x), maxf(max_point.y, corner.y))
	return Rect2(min_point, max_point - min_point)


func _would_ruin_prop_footprint_create_stuck_risk(footprint: Array[Vector2i]) -> bool:
	if footprint.is_empty():
		return false
	var footprint_lookup: Dictionary = {}
	var neighbor_lookup: Dictionary = {}
	for cell in footprint:
		footprint_lookup[cell] = true
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			neighbor_lookup[cell + direction] = true
	for neighbor_variant in neighbor_lookup.keys():
		var neighbor := neighbor_variant as Vector2i
		if footprint_lookup.has(neighbor) or not is_runtime_walkable_after_props(neighbor):
			continue
		var current_exits := get_runtime_escape_neighbor_count(neighbor)
		if current_exits < runtime_blocker_min_escape_neighbors:
			continue
		var projected_exits := 0
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var adjacent: Vector2i = neighbor + (direction as Vector2i)
			if not footprint_lookup.has(adjacent) and is_runtime_walkable_after_props(adjacent):
				projected_exits += 1
		if projected_exits < runtime_blocker_min_escape_neighbors:
			return true
	return false


func _record_ruin_prop_candidate_rejection(reason: StringName, payload: Dictionary) -> void:
	match reason:
		&"protected_zone":
			_generation_prop_rejections_protected_zone += 1
			_obs_increment(&"procgen_prop_candidates_rejected_protected_zone")
			_obs_gauge(&"procgen_prop_candidates_rejected_protected_zone", _generation_prop_rejections_protected_zone)
		&"stuck_risk":
			_generation_prop_rejections_stuck_risk += 1
			_obs_increment(&"procgen_prop_candidates_rejected_stuck_risk")
			_obs_gauge(&"procgen_prop_candidates_rejected_stuck_risk", _generation_prop_rejections_stuck_risk)
		&"existing_blocker":
			_generation_prop_rejections_existing_blocker += 1
			_obs_increment(&"procgen_prop_candidates_rejected_existing_blocker")
			_obs_gauge(&"procgen_prop_candidates_rejected_existing_blocker", _generation_prop_rejections_existing_blocker)
	_obs_log(&"procgen_prop_candidate_rejected", payload)


func _get_generation_seed() -> int:
	return int(procgen_node.seed) if procgen_node != null and "seed" in procgen_node else 0


func _observe_ruin_prop_collision(prop: ProceduralProp) -> void:
	var report := prop.get_collision_alignment_report()
	if not bool(report.get("has_collision", false)):
		return
	report["source_tile"] = _get_prop_source_tile(prop)
	var alignment_anomaly := bool(report.get("likely_below_anchor", false)) \
		or bool(report.get("collision_outside_visual_bounds", false)) \
		or bool(report.get("suspicious_positive_y", false)) \
		or bool(report.get("missing_base_texture", false))
	if ruin_prop_force_collision_debug or alignment_anomaly:
		_obs_log(&"prop_collision_alignment_warning", report)
	if alignment_anomaly:
		var message := "[PropCollisionAlignment] definition=%s bottom_y=%.2f outside_visual=%s" % [
			report.get("definition_id", "unknown"),
			float(report.get("collision_bottom_y", 0.0)),
			str(report.get("collision_outside_visual_bounds", false)),
		]
		push_warning(message)
		_obs_increment(&"prop_collision_alignment_warnings")
		_generation_prop_collision_alignment_warnings += 1
		_obs_gauge(&"procgen_prop_collision_alignment_warning_count_last_generation", _generation_prop_collision_alignment_warnings)
		_obs_warning(message, report)



func _enforce_ruin_prop_blocker_clearance(prop: ProceduralProp) -> bool:
	# Portal side blockers are deliberately authored around the portal's own
	# approach lane, whose connector terminates at the portal footprint.
	if _is_portal_prop(prop):
		return false
	var owner_id := str(prop.get_instance_id())
	var source: Dictionary = _runtime_prop_blocker_sources.get(owner_id, {})
	var protected_cell: Variant = null
	for cell_variant in source.get("cells", []):
		var cell := cell_variant as Vector2i
		if _is_protected_ruin_prop_blocker_cell(cell):
			protected_cell = cell
			break
	if protected_cell == null:
		return false

	var report := prop.get_collision_alignment_report()
	report["source_tile"] = _get_prop_source_tile(prop)
	report["blocker_cell"] = protected_cell
	report["prop_global_position"] = prop.global_position
	report["collision_rect_global"] = prop.get_collision_rect_global()
	report["collision_rect_tile_footprint"] = source.get("cells", []).duplicate()
	report["protected_zone_type"] = String(_get_ruin_prop_protected_zone_type(protected_cell as Vector2i))
	report["remediation_action"] = "disabled_collision/unregistered_blocker"
	report["seed"] = _get_generation_seed()
	report["anomaly"] = "protected_clear_zone_overlap"
	report["collision_disabled"] = true
	var message := "[PropCollisionAlignment] disabled runtime footprint overlapping protected clear zone definition=%s cell=%s zone=%s" % [
		report.get("definition_id", "unknown"),
		protected_cell,
		report.get("protected_zone_type", "unknown"),
	]
	push_warning(message)
	_disable_collision_shapes(prop)
	_unregister_runtime_prop_blocker_id(owner_id)
	_obs_log(&"prop_collision_alignment_warning", report)
	_obs_increment(&"prop_collision_alignment_warnings")
	_generation_prop_collision_alignment_warnings += 1
	_obs_gauge(&"procgen_prop_collision_alignment_warning_count_last_generation", _generation_prop_collision_alignment_warnings)
	_obs_increment(&"procgen_runtime_blockers_cleared_for_protected_zones")
	_obs_warning(message, report)
	return true


func _is_protected_ruin_prop_blocker_cell(cell: Vector2i) -> bool:
	return not _get_ruin_prop_protected_zone_type(cell).is_empty()


func _get_ruin_prop_protected_zone_type(cell: Vector2i) -> StringName:
	if _is_inside_required_route_clearance(cell, 0):
		return &"required_route"
	var spawn_tile := get_player_spawn()
	if abs(cell.x - spawn_tile.x) <= ruin_prop_spawn_clearance_radius \
			and abs(cell.y - spawn_tile.y) <= ruin_prop_spawn_clearance_radius:
		return &"player_spawn"
	for building in _last_compound_buildings:
		if building.grow(ruin_prop_compound_building_clearance).has_point(cell):
			return &"compound_structure"
	for threshold in _last_interior_thresholds:
		if threshold is Vector2i and cell.distance_to(threshold) <= float(combat_readability_prop_clearance_tiles):
			return &"story_room_threshold"
	for ingress in _last_compound_ingress:
		if ingress is Vector2i:
			if cell.distance_to(ingress) <= float(combat_readability_prop_clearance_tiles):
				return &"compound_threshold"
	for site in _faction_activity_sites:
		var faction_cell: Variant = site.get("cell", Vector2i.ZERO)
		if faction_cell is Vector2i and cell.distance_to(faction_cell) <= float(combat_readability_prop_clearance_tiles):
			return &"faction_activity"
	for site in _story_room_sites:
		var story_cell: Variant = site.get("cell", Vector2i.ZERO)
		if story_cell is Vector2i and cell.distance_to(story_cell) <= float(combat_readability_prop_clearance_tiles):
			return &"story_room"
	for portal in _portal_teleporters:
		if portal is Node2D and is_instance_valid(portal) \
				and cell.distance_to(_global_to_tile((portal as Node2D).global_position)) <= float(combat_readability_prop_clearance_tiles):
			return &"portal"
	if _is_inside_combat_readability_spawn_clearance(cell, combat_readability_prop_clearance_tiles):
		return &"combat_readability"
	return &""


func _clear_ruin_props() -> void:
	_portal_teleporters.clear()
	var ruin_source_ids: Array[String] = []
	for owner_id_variant in _runtime_prop_blocker_sources.keys():
		var source: Dictionary = _runtime_prop_blocker_sources[owner_id_variant]
		if source.get("kind", &"") == &"ruin_prop":
			ruin_source_ids.append(str(owner_id_variant))
	for owner_id in ruin_source_ids:
		_unregister_runtime_prop_blocker_id(owner_id)
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
	if not is_valid_spawn_cell(pos):
		return false
	if is_indoor_tile(pos):
		return false
	if _is_near_indoor_tile(pos, ruin_prop_indoor_clearance_tiles):
		return false
	if _is_near_wall_for_ruin_prop(pos):
		return false
	if _is_inside_ruin_prop_clearance(pos):
		return false
	if _is_inside_combat_readability_spawn_clearance(pos, combat_readability_prop_clearance_tiles):
		return false
	if _is_inside_required_route_clearance(pos, runtime_blocker_route_clearance_tiles):
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


func _is_inside_tree_trunk_clearance(pos: Vector2i) -> bool:
	if _is_inside_required_route_clearance(pos, runtime_blocker_route_clearance_tiles):
		return true
	for building in _last_compound_buildings:
		if building.grow(3).has_point(pos):
			return true
	for y in range(-3, 4):
		for x in range(-3, 4):
			if _generated_wall_cells.has(pos + Vector2i(x, y)):
				return true
	return _is_inside_combat_readability_spawn_clearance(pos, 4)


func _is_inside_required_route_clearance(pos: Vector2i, radius: int = 3) -> bool:
	var clearance := maxi(0, radius)
	for y in range(-clearance, clearance + 1):
		for x in range(-clearance, clearance + 1):
			var tile := pos + Vector2i(x, y)
			if _main_road_tiles.has(tile) \
					or _road_centerline_tiles.has(tile) \
					or _path_centerline_tiles.has(tile) \
					or _ascent_field_main_route_cells.has(tile) \
					or _compound_connector_centerline_tiles.has(tile):
				return true
	return false


func _is_inside_combat_readability_spawn_clearance(pos: Vector2i, radius: int = -1) -> bool:
	var clearance_radius := radius
	if clearance_radius < 0:
		clearance_radius = combat_readability_foliage_clearance_tiles
	if clearance_radius <= 0:
		return false
	if _is_combat_readability_floor_tile(pos):
		return true
	var anchors: Array[Vector2i] = [get_player_spawn()]
	for ingress in _last_compound_ingress:
		if ingress is Vector2i:
			anchors.append(ingress)
	for site in _faction_activity_sites:
		var cell: Variant = site.get("cell", Vector2i.ZERO)
		if cell is Vector2i:
			anchors.append(cell)
	for site in _story_room_sites:
		var cell: Variant = site.get("cell", Vector2i.ZERO)
		if cell is Vector2i:
			anchors.append(cell)
	for portal in _portal_teleporters:
		if portal is Node2D and is_instance_valid(portal):
			anchors.append(_global_to_tile((portal as Node2D).global_position))
	for anchor in anchors:
		if pos.distance_to(anchor) <= float(clearance_radius):
			return true
	return false


func _ruin_prop_tile_to_world(pos: Vector2i) -> Vector2:
	return _tile_to_world_position(pos) + _ruin_prop_jitter(pos)


func _portal_tile_to_world(pos: Vector2i) -> Vector2:
	return _tile_to_world_position(pos)


func _ruin_prop_jitter(pos: Vector2i) -> Vector2:
	var seed := _tile_noise_hash(pos + Vector2i(53, 89))
	var x_unit := float(seed % 21) - 10.0
	var y_unit := float((seed / 21) % 11) - 5.0
	return Vector2(
		x_unit / 10.0 * ruin_prop_jitter_amplitude.x,
		y_unit / 5.0 * ruin_prop_jitter_amplitude.y
	).round()


func _configure_portal_pair(candidate_tiles: Array[Vector2i], spawned: Array[ProceduralProp], map_size: Vector2i) -> void:
	_portal_teleporters.clear()
	if not enable_portal_pair_teleport:
		return

	var portal_definition := _get_portal_prop_definition()
	if portal_definition == null:
		return

	var portal_props: Array[ProceduralProp] = []
	var blocked_tiles: Dictionary = {}
	for prop in spawned:
		if prop == null or not is_instance_valid(prop):
			continue
		var source_tile := _get_prop_source_tile(prop)
		if prop.has_meta("source_tile"):
			blocked_tiles[source_tile] = true
		if _is_portal_prop(prop):
			var resolved_tile := _resolve_portal_endpoint_tile(
				source_tile,
				_build_tile_lookup(candidate_tiles),
				blocked_tiles,
				portal_props,
				map_size,
				false,
				true
			)
			if bool(resolved_tile.get("ok", false)):
				var safe_tile := resolved_tile["tile"] as Vector2i
				_stamp_portal_plaza(safe_tile, map_size)
				prop.global_position = _portal_tile_to_world(safe_tile)
				prop.set_meta("source_tile", safe_tile)
				blocked_tiles[safe_tile] = true
				portal_props.append(prop)
			else:
				if ruin_prop_debug_logging:
					push_warning("[RuinProps] Discarding unsafe portal prop at tile %s" % [source_tile])
				prop.queue_free()

	while portal_props.size() < 2:
		var tile_result := _pick_portal_pair_tile(candidate_tiles, blocked_tiles, portal_props, map_size, true)
		if not bool(tile_result.get("ok", false)):
			tile_result = _pick_portal_pair_tile(candidate_tiles, blocked_tiles, portal_props, map_size, false)
		if not bool(tile_result.get("ok", false)):
			if ruin_prop_debug_logging:
				push_warning("[RuinProps] Could not find a valid tile for portal pair endpoint")
			break

		var tile := tile_result["tile"] as Vector2i
		_stamp_portal_plaza(tile, map_size)
		var prop := _spawn_guaranteed_ruin_prop(portal_definition, tile)
		if prop == null:
			break
		blocked_tiles[tile] = true
		portal_props.append(prop)
		spawned.append(prop)

	if portal_props.size() < 2:
		return

	while portal_props.size() > 2:
		var extra: ProceduralProp = portal_props.pop_back()
		if extra != null and is_instance_valid(extra):
			extra.queue_free()

	if intent_soft_paths_enabled:
		var spawn_tile := get_player_spawn()
		var portal_a_tile := _get_prop_source_tile(portal_props[0])
		var portal_b_tile := _get_prop_source_tile(portal_props[1])
		_carve_generated_soft_path(spawn_tile, portal_a_tile, intent_soft_path_width, map_size)
		_carve_generated_soft_path(spawn_tile, portal_b_tile, intent_soft_path_width, map_size)

	var first: Area2D = _attach_portal_teleporter(portal_props[0])
	var second: Area2D = _attach_portal_teleporter(portal_props[1])
	if first == null or second == null:
		return

	first.call("link_to", second)
	second.call("link_to", first)
	_portal_teleporters = [first, second]


func _is_tile_currently_visible(tile: Vector2i) -> bool:
	if not enable_streaming_reveal:
		return true
	return _revealed_chunks.has(_tile_to_chunk(tile))


func _set_floor_tile_and_generated_state(pos: Vector2i, region_type: String = "", zone: String = "") -> void:
	if floor_tilemap == null or walls_tilemap == null:
		return
	var source_id := _select_floor_source_id(pos)
	var atlas := _select_floor_coord(pos)
	_generated_floor_cells[pos] = {
		"source_id": source_id,
		"atlas": atlas,
		"alternative": 0,
	}
	_generated_wall_cells.erase(pos)
	_clear_road_blocking_wall(pos)
	if not region_type.is_empty():
		_set_region_tile(pos, region_type, zone)
	if _is_tile_currently_visible(pos):
		floor_tilemap.set_cell(pos, source_id, atlas, 0)
		walls_tilemap.erase_cell(pos)
		if build_runtime_wall_collision:
			_remove_runtime_wall_body(pos)


func _stamp_portal_plaza(center: Vector2i, map_size: Vector2i) -> void:
	if not intent_portal_plazas_enabled:
		return
	var half_extents := Vector2i(
		maxi(0, intent_portal_plaza_half_extents_tiles.x),
		maxi(0, intent_portal_plaza_half_extents_tiles.y)
	)
	for x in range(-half_extents.x, half_extents.x + 1):
		for y in range(-half_extents.y, half_extents.y + 1):
			var tile := center + Vector2i(x, y)
			if not _is_tile_inside_map(tile, map_size, 1):
				continue
			if is_indoor_tile(tile):
				continue
			_set_floor_tile_and_generated_state(tile, "portal_plaza", "portal")
			_remove_foliage(tile)


func _carve_generated_soft_path(from_tile: Vector2i, to_tile: Vector2i, width: int, map_size: Vector2i) -> void:
	var current := from_tile
	_path_centerline_tiles[current] = true
	_path_visual_tiles[current] = true
	var step_index := 0
	while current.x != to_tile.x:
		current.x += 1 if to_tile.x > current.x else -1
		_path_centerline_tiles[current] = true
		step_index += 1
		if step_index % maxi(1, path_piece_straight_stride_tiles) == 0:
			_path_visual_tiles[current] = true
		_carve_generated_path_brush(current, width, map_size)
	while current.y != to_tile.y:
		current.y += 1 if to_tile.y > current.y else -1
		_path_centerline_tiles[current] = true
		step_index += 1
		if step_index % maxi(1, path_piece_straight_stride_tiles) == 0:
			_path_visual_tiles[current] = true
		_carve_generated_path_brush(current, width, map_size)
	_path_visual_tiles[current] = true


func _carve_generated_path_brush(center: Vector2i, width: int, map_size: Vector2i) -> void:
	for x in range(-width, width + 1):
		for y in range(-width, width + 1):
			var tile := center + Vector2i(x, y)
			if not _is_tile_inside_map(tile, map_size, 1):
				continue
			if is_indoor_tile(tile):
				continue
			if _generated_wall_cells.has(tile):
				continue
			_set_floor_tile_and_generated_state(tile, "soft_path", "travel")


func _get_portal_prop_definition() -> PropDefinition:
	if ruin_prop_spawn_set == null:
		return null
	for entry in ruin_prop_spawn_set.entries:
		if entry == null or entry.definition == null:
			continue
		if entry.definition.id == PORTAL_DEFINITION_ID:
			return entry.definition
	return null


func _is_portal_prop(prop: ProceduralProp) -> bool:
	return prop.definition != null and prop.definition.id == PORTAL_DEFINITION_ID


func _pick_portal_pair_tile(
	candidate_tiles: Array[Vector2i],
	blocked_tiles: Dictionary,
	existing_portals: Array[ProceduralProp],
	map_size: Vector2i,
	require_min_distance: bool
) -> Dictionary:
	var candidate_lookup := _build_tile_lookup(candidate_tiles)
	var best_tile := Vector2i.ZERO
	var best_score := -INF
	var found := false
	var player_spawn := get_player_spawn()

	for tile in candidate_tiles:
		var resolved := _resolve_portal_endpoint_tile(
			tile,
			candidate_lookup,
			blocked_tiles,
			existing_portals,
			map_size,
			require_min_distance
		)
		if not bool(resolved.get("ok", false)):
			continue
		var safe_tile := resolved["tile"] as Vector2i

		var score := float(safe_tile.distance_squared_to(player_spawn))
		if not existing_portals.is_empty():
			score = _min_distance_squared_to_portals(safe_tile, existing_portals)
		score += float(_tile_noise_hash(safe_tile + Vector2i(311, 719)) % 1000) / 1000.0

		if not found or score > best_score:
			found = true
			best_score = score
			best_tile = safe_tile

	if not found:
		return {"ok": false}

	return {
		"ok": true,
		"tile": best_tile,
	}


func _is_far_enough_from_existing_portals(tile: Vector2i, existing_portals: Array[ProceduralProp]) -> bool:
	for portal in existing_portals:
		var portal_tile := _get_prop_source_tile(portal)
		if portal_tile.distance_to(tile) < float(portal_pair_min_distance_tiles):
			return false
	return true


func _min_distance_squared_to_portals(tile: Vector2i, existing_portals: Array[ProceduralProp]) -> float:
	var result := INF
	for portal in existing_portals:
		var portal_tile := _get_prop_source_tile(portal)
		result = min(result, float(tile.distance_squared_to(portal_tile)))
	return result


func _is_safe_portal_tile(pos: Vector2i, map_size: Vector2i) -> bool:
	if not is_valid_spawn_cell(pos):
		return false
	if _is_inside_ruin_prop_clearance(pos):
		return false
	if _foliage_nodes.has(pos):
		return false
	if not _has_clear_portal_floor_footprint(pos, map_size):
		return false
	if _has_wall_near_portal(pos, map_size):
		return false
	if _has_portal_center_collision(pos):
		return false
	return true


func _resolve_portal_endpoint_tile(
	base_tile: Vector2i,
	candidate_lookup: Dictionary,
	blocked_tiles: Dictionary,
	existing_portals: Array[ProceduralProp],
	map_size: Vector2i,
	require_min_distance: bool,
	allow_base_tile_even_if_blocked: bool = false
) -> Dictionary:
	if candidate_lookup.has(base_tile) and (allow_base_tile_even_if_blocked or not blocked_tiles.has(base_tile)):
		if _is_safe_portal_tile(base_tile, map_size):
			if not require_min_distance or _is_far_enough_from_existing_portals(base_tile, existing_portals):
				return {
					"ok": true,
					"tile": base_tile,
				}

	for radius in range(1, maxi(0, portal_spawn_nudge_radius_tiles) + 1):
		for offset in _get_portal_nudge_ring(radius):
			var tile := base_tile + offset
			if not candidate_lookup.has(tile):
				continue
			if blocked_tiles.has(tile):
				continue
			if not _is_safe_portal_tile(tile, map_size):
				continue
			if require_min_distance and not _is_far_enough_from_existing_portals(tile, existing_portals):
				continue
			return {
				"ok": true,
				"tile": tile,
			}

	return {"ok": false}


func _get_portal_nudge_ring(radius: int) -> Array[Vector2i]:
	var offsets: Array[Vector2i] = []
	if radius <= 0:
		offsets.append(Vector2i.ZERO)
		return offsets
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if max(abs(x), abs(y)) != radius:
				continue
			offsets.append(Vector2i(x, y))
	offsets.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_score := float(a.x * a.x + a.y * a.y)
		var b_score := float(b.x * b.x + b.y * b.y)
		if a_score == b_score:
			if a.x == b.x:
				return a.y < b.y
			return a.x < b.x
		return a_score < b_score
	)
	return offsets


func _build_tile_lookup(tiles: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	for tile in tiles:
		lookup[tile] = true
	return lookup


func _has_portal_center_collision(pos: Vector2i) -> bool:
	if portal_spawn_collision_probe_radius <= 0.0:
		return false
	if floor_tilemap == null:
		return false
	var world := floor_tilemap.get_world_2d()
	if world == null:
		return false
	var space_state: PhysicsDirectSpaceState2D = world.direct_space_state
	if space_state == null:
		return false

	var shape := CircleShape2D.new()
	shape.radius = portal_spawn_collision_probe_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	var transform := Transform2D.IDENTITY
	transform.origin = _portal_tile_to_world(pos)
	query.transform = transform
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 1

	var player := get_tree().get_first_node_in_group("player")
	if player is CollisionObject2D:
		query.exclude = [player.get_rid()]

	return not space_state.intersect_shape(query, 8).is_empty()


func _has_clear_portal_floor_footprint(pos: Vector2i, map_size: Vector2i) -> bool:
	var extents := Vector2i(
		maxi(0, portal_spawn_floor_half_extents_tiles.x),
		maxi(0, portal_spawn_floor_half_extents_tiles.y)
	)
	for x in range(-extents.x, extents.x + 1):
		for y in range(-extents.y, extents.y + 1):
			var tile := pos + Vector2i(x, y)
			if tile.x <= 1 or tile.y <= 1 or tile.x >= map_size.x - 2 or tile.y >= map_size.y - 2:
				return false
			if not is_valid_spawn_cell(tile):
				return false
			if _generated_wall_cells.has(tile):
				return false
			if is_indoor_tile(tile):
				return false
	return true


func _has_wall_near_portal(pos: Vector2i, map_size: Vector2i) -> bool:
	if portal_spawn_wall_clearance_tiles <= 0:
		return false
	for x in range(-portal_spawn_wall_clearance_tiles, portal_spawn_wall_clearance_tiles + 1):
		for y in range(-portal_spawn_wall_clearance_tiles, portal_spawn_wall_clearance_tiles + 1):
			var tile := pos + Vector2i(x, y)
			if tile.x <= 1 or tile.y <= 1 or tile.x >= map_size.x - 2 or tile.y >= map_size.y - 2:
				return true
			if _generated_wall_cells.has(tile):
				return true
	return false


func _update_ruin_prop_occlusion(player: Node2D) -> void:
	if player == null or _ruin_prop_parent == null:
		return
	var player_feet := player.global_position + foliage_player_feet_offset
	var portal_player_feet_y := _get_portal_depth_feet_y(player)
	var player_upper := player.global_position + foliage_player_upper_body_offset
	for prop in _collect_ruin_props():
		if prop == null or not is_instance_valid(prop):
			continue
		if prop.definition != null and prop.definition.portal_platform_enabled:
			prop.z_as_relative = false
			prop.z_index = prop.resolve_depth_sort_z_index(portal_player_feet_y)
			continue
		var bounds := prop.get_occlusion_bounds()
		if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
			prop.apply_depth_sort(player_feet.y)
			continue
		var z_index := _resolve_ruin_prop_depth_z_index(prop, player_feet, player_upper, bounds)
		prop.z_as_relative = false
		prop.z_index = z_index


func _resolve_ruin_prop_depth_z_index(prop: ProceduralProp, player_feet: Vector2, player_upper: Vector2, bounds: Rect2) -> int:
	if prop == null or prop.definition == null:
		return 0
	var definition := prop.definition
	var left := bounds.position.x - definition.occlusion_side_padding
	var right := bounds.end.x + definition.occlusion_side_padding
	var top := bounds.position.y - definition.occlusion_front_padding
	var bottom := bounds.end.y + definition.occlusion_front_padding
	var x_overlap := player_upper.x >= left and player_upper.x <= right
	if not x_overlap:
		return definition.depth_sort_behind_z_index if player_feet.y > bounds.end.y else definition.depth_sort_front_z_index
	if player_feet.y <= top:
		return definition.depth_sort_front_z_index
	if player_feet.y >= bottom:
		return definition.depth_sort_behind_z_index
	if player_upper.y <= bounds.position.y + bounds.size.y * 0.5:
		return definition.depth_sort_front_z_index
	return definition.depth_sort_behind_z_index


func _get_portal_depth_feet_y(player: Node2D) -> float:
	var feet_y := player.global_position.y + foliage_player_feet_offset.y
	var collision_shape := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null and collision_shape.shape != null:
		var shape := collision_shape.shape
		if shape is CapsuleShape2D:
			var capsule := shape as CapsuleShape2D
			feet_y = collision_shape.global_position.y + max(capsule.height * 0.5, capsule.radius)
		elif shape is CircleShape2D:
			feet_y = collision_shape.global_position.y + (shape as CircleShape2D).radius
		elif shape is RectangleShape2D:
			feet_y = collision_shape.global_position.y + (shape as RectangleShape2D).size.y * 0.5
	if player.has_method("get"):
		var fake_elevation_value: Variant = player.get("fake_elevation")
		var lift_factor_value: Variant = player.get("fake_elevation_visual_lift_factor")
		if fake_elevation_value is float or fake_elevation_value is int:
			var lift_factor := 0.5
			if lift_factor_value is float or lift_factor_value is int:
				lift_factor = float(lift_factor_value)
			feet_y -= float(fake_elevation_value) * lift_factor
	return feet_y


func _collect_ruin_props() -> Array[ProceduralProp]:
	var result: Array[ProceduralProp] = []
	if _ruin_prop_parent == null:
		return result
	var stack: Array[Node] = [_ruin_prop_parent]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node == null or not is_instance_valid(node):
			continue
		for child in node.get_children():
			if child is ProceduralProp:
				result.append(child as ProceduralProp)
			elif child is Node:
				stack.append(child)
	return result


func _get_prop_source_tile(prop: ProceduralProp) -> Vector2i:
	if prop != null and prop.has_meta("source_tile"):
		return prop.get_meta("source_tile") as Vector2i
	return floor_tilemap.local_to_map(floor_tilemap.to_local(prop.global_position)) if floor_tilemap != null else Vector2i.ZERO


func _spawn_guaranteed_ruin_prop(definition: PropDefinition, tile: Vector2i) -> ProceduralProp:
	if ruin_prop_scene == null or _ruin_prop_scatterer == null:
		return null

	var prop := ruin_prop_scene.instantiate() as ProceduralProp
	if prop == null:
		return null

	prop.definition = definition
	prop.variant_intensity = ruin_prop_variant_intensity
	prop.variant_seed = PropVariantGenerator.seed_from_world_cell(definition.id, tile, _ruin_prop_scatterer.seed)
	prop.generate_on_ready = false
	prop.force_collision_debug = ruin_prop_force_collision_debug
	_ruin_prop_scatterer.add_child(prop)
	prop.global_position = _portal_tile_to_world(tile)
	prop.set_meta("source_tile", tile)
	prop.generate_variant()
	return prop


func _attach_portal_teleporter(prop: ProceduralProp) -> Area2D:
	if prop == null or not is_instance_valid(prop):
		return null
	for child in prop.get_children():
		if child is Area2D and child.get_script() == PORTAL_TELEPORTER_SCRIPT:
			return child as Area2D

	var teleporter := PORTAL_TELEPORTER_SCRIPT.new() as Area2D
	if teleporter == null:
		return null
	teleporter.name = "PortalTeleporter"
	var portal_definition := prop.definition
	_attach_portal_light_rig(prop, portal_definition)
	if portal_definition != null and portal_definition.portal_platform_enabled:
		var ramp_bottom_offset := portal_definition.portal_platform_bottom_offset - portal_definition.portal_platform_trigger_offset
		teleporter.position = portal_definition.portal_platform_trigger_offset
		teleporter.set("trigger_shape_size", portal_definition.portal_platform_trigger_shape_size)
		teleporter.set("trigger_shape_offset", portal_definition.portal_platform_trigger_shape_offset)
		teleporter.set("ramp_top_local_offset", Vector2.ZERO)
		teleporter.set("ramp_bottom_local_offset", ramp_bottom_offset)
		teleporter.set("ramp_lane_half_width", portal_definition.portal_platform_lane_half_width)
		teleporter.set("ramp_bottom_width", portal_definition.portal_platform_bottom_width)
		teleporter.set("ramp_top_width", portal_definition.portal_platform_top_width)
		teleporter.set("ramp_side_block_width", portal_definition.portal_platform_side_block_width)
		teleporter.set("ramp_side_block_extra_height", portal_definition.portal_platform_side_block_height)
		teleporter.set("ramp_required_elevation", portal_definition.portal_platform_required_elevation)
		teleporter.set("ramp_max_elevation", portal_definition.portal_platform_max_elevation)
		teleporter.set("ramp_speed_multiplier", portal_definition.portal_platform_speed_multiplier)
		teleporter.set("ramp_dual_approach", portal_definition.portal_platform_dual_approach)
		teleporter.set("fx_offset", portal_trigger_local_offset - portal_definition.portal_platform_trigger_offset)
		teleporter.set("generate_side_block_collision", portal_definition.collision_scene == null)
		teleporter.set("arrival_offset", ramp_bottom_offset)
		teleporter.set("require_ramp_elevation_to_teleport", true)
		teleporter.set("require_body_still_in_trigger_at_teleport_frame", true)
		teleporter.set("stop_body_velocity_on_arrival", true)
	else:
		teleporter.position = portal_trigger_local_offset
		teleporter.set("trigger_shape_size", Vector2.ZERO)
		teleporter.set("trigger_shape_offset", Vector2.ZERO)
		teleporter.set("arrival_offset", portal_arrival_offset)
		teleporter.set("require_ramp_elevation_to_teleport", false)
		teleporter.set("require_body_still_in_trigger_at_teleport_frame", true)
		teleporter.set("stop_body_velocity_on_arrival", true)
	teleporter.set("trigger_radius", portal_trigger_radius)
	teleporter.set("arrival_animation_delay_seconds", portal_arrival_animation_delay_seconds)
	teleporter.set("cooldown_frames", portal_teleport_cooldown_frames)
	prop.add_child(teleporter)
	return teleporter


func _attach_portal_light_rig(prop: ProceduralProp, portal_definition: PropDefinition) -> void:
	if prop.get_node_or_null("PortalLightRig") != null:
		return
	var light_rig := LIGHT_RIG_SCENE.instantiate() as LightRig2D
	if light_rig == null:
		return
	light_rig.name = "PortalLightRig"
	light_rig.position = portal_definition.portal_platform_trigger_offset if portal_definition != null else Vector2(0, -56)
	light_rig.light_color = Color(0.25, 0.62, 1.0, 1.0)
	light_rig.energy = 1.0
	light_rig.pulse_enabled = true
	light_rig.pulse_speed = 0.55
	light_rig.pulse_amount = 0.14
	light_rig.glow_scale = 1.7
	prop.add_child(light_rig)


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

	var candidate_tiles := _build_intentional_interior_prop_candidates(map_size)
	if candidate_tiles.is_empty():
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


func _build_intentional_interior_prop_candidates(map_size: Vector2i) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var seen: Dictionary = {}
	for room in _last_interior_rooms:
		if room.size.x <= 2 or room.size.y <= 2:
			continue
		_append_interior_prop_room_edge_candidates(room, map_size, candidates, seen)
	return candidates


func _append_interior_prop_room_edge_candidates(room: Rect2i, map_size: Vector2i, candidates: Array[Vector2i], seen: Dictionary) -> void:
	var left := room.position.x
	var right := room.end.x - 1
	var top := room.position.y
	var bottom := room.end.y - 1
	var edge_step := maxi(2, interior_prop_min_distance_tiles)
	var edge_points: Array[Vector2i] = [
		Vector2i(left, top),
		Vector2i(right, top),
		Vector2i(left, bottom),
		Vector2i(right, bottom),
	]
	for x in range(left + edge_step, right, edge_step):
		edge_points.append(Vector2i(x, top))
		edge_points.append(Vector2i(x, bottom))
	for y in range(top + edge_step, bottom, edge_step):
		edge_points.append(Vector2i(left, y))
		edge_points.append(Vector2i(right, y))
	for tile in edge_points:
		if seen.has(tile):
			continue
		if not _should_place_interior_prop(tile, map_size):
			continue
		seen[tile] = true
		candidates.append(tile)


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
	if not is_valid_spawn_cell(pos):
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
	sprite.set_meta("source_tile", pos)
	sprite.set_meta("region_zone", String(get_region_data_at_tile(pos).get("zone", "room")))
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
	_ensure_foliage_spawner()
	_foliage_spawner.remove_at(_build_foliage_spawner_context(), pos)


func _should_place_foliage(pos: Vector2i) -> bool:
	_ensure_foliage_spawner()
	return _foliage_spawner.can_place_at(_build_foliage_spawner_context(), pos)


func _is_near_wall(pos: Vector2i) -> bool:
	_ensure_foliage_spawner()
	return _foliage_spawner._is_near_wall(_build_foliage_spawner_context(), pos)


func _is_inside_foliage_clearance(pos: Vector2i) -> bool:
	_ensure_foliage_spawner()
	return _foliage_spawner._is_inside_foliage_clearance(_build_foliage_spawner_context(), pos)


func _is_near_indoor_tile(pos: Vector2i, clearance_tiles: int) -> bool:
	_ensure_foliage_spawner()
	return _foliage_spawner._is_near_indoor_tile(_build_foliage_spawner_context(), pos, clearance_tiles)


func _is_inside_compound_zone(pos: Vector2i) -> bool:
	_ensure_foliage_spawner()
	return _foliage_spawner._is_inside_compound_zone(_build_foliage_spawner_context(), pos)


func _place_foliage(pos: Vector2i) -> void:
	_ensure_foliage_spawner()
	_foliage_spawner.place_at(_build_foliage_spawner_context(), pos)


func _pick_foliage_texture(pos: Vector2i) -> Texture2D:
	_ensure_foliage_spawner()
	return _foliage_spawner._pick_foliage_texture(_build_foliage_spawner_context(), pos)


func _classify_foliage(foliage_size: Vector2) -> String:
	return "tree" if foliage_size.y >= 96.0 else "shrub"


func _should_add_tree_trunk_collision(pos: Vector2i) -> bool:
	_ensure_foliage_spawner()
	return _foliage_spawner._should_add_tree_trunk_collision(_build_foliage_spawner_context(), pos)


func _estimate_local_tree_density(center: Vector2i) -> float:
	_ensure_foliage_spawner()
	return _foliage_spawner._estimate_local_tree_density(_build_foliage_spawner_context(), center)


func _would_place_foliage_at(pos: Vector2i) -> bool:
	_ensure_foliage_spawner()
	return _foliage_spawner._would_place_foliage_at(_build_foliage_spawner_context(), pos)


func _is_no_random_foliage_region_tile(pos: Vector2i) -> bool:
	_ensure_foliage_spawner()
	return _foliage_spawner._is_no_random_foliage_region_tile(_build_foliage_spawner_context(), pos)


func _add_tree_trunk_collision(foliage_sprite: Sprite2D, foliage_size: Vector2) -> void:
	_ensure_foliage_spawner()
	_foliage_spawner._add_tree_trunk_collision(_build_foliage_spawner_context(), foliage_sprite, foliage_size)


func _should_place_fruit(pos: Vector2i, foliage_kind: String) -> bool:
	_ensure_foliage_spawner()
	return _foliage_spawner._should_place_fruit(_build_foliage_spawner_context(), pos, foliage_kind)


func _place_fruit(foliage_sprite: Sprite2D, foliage_tile: Vector2i, foliage_size: Vector2, foliage_kind: String) -> void:
	_ensure_foliage_spawner()
	_foliage_spawner._place_fruit(_build_foliage_spawner_context(), foliage_sprite, foliage_tile, foliage_size, foliage_kind)


func _tile_to_world_position(pos: Vector2i) -> Vector2:
	if floor_tilemap == null:
		return Vector2.ZERO
	if floor_tilemap.tile_set == null:
		var tile_size := _get_tile_size()
		return floor_tilemap.to_global((Vector2(pos) * tile_size) + (tile_size * 0.5))
	return floor_tilemap.to_global(floor_tilemap.map_to_local(pos))


func _get_tile_size() -> Vector2:
	if floor_tilemap != null and floor_tilemap.tile_set != null:
		return Vector2(floor_tilemap.tile_set.tile_size)
	return Vector2(16, 16)


func get_terrain_ballistics_context() -> Dictionary:
	if _last_terrain_result.is_empty():
		return {}
	return {
		"height_by_cell": _last_terrain_result.get("height_by_cell", {}),
		"traversal_by_cell": _last_terrain_result.get("traversal_by_cell", {}),
		"terrain_type_by_cell": _last_terrain_result.get("terrain_type_by_cell", {}),
		"tile_by_cell": _last_terrain_result.get("tile_by_cell", {}),
		"edge_profile_by_cell": _last_terrain_result.get("edge_profile_by_cell", {}),
		"tile_size": get_runtime_tile_size(),
		"world_to_tile": Callable(self, "_global_to_tile"),
		"tile_to_world": Callable(self, "tile_to_global_position"),
	}


func can_trace_projectile(from_world: Vector2, to_world: Vector2) -> Dictionary:
	var context := get_terrain_ballistics_context()
	if context.is_empty():
		return {
			"allowed": true,
			"blocked_by": "no_terrain_context",
			"blocked_at_world": to_world,
		}
	return TERRAIN_BALLISTICS_SCRIPT.trace_projectile_tiles(context, from_world, to_world)


func is_terrain_collision_body(body: Node) -> bool:
	if body == null:
		return false
	var current: Node = body
	while current != null:
		if current == floor_tilemap or current == walls_tilemap:
			return true
		current = current.get_parent()
	return false


func _foliage_jitter(pos: Vector2i) -> Vector2:
	_ensure_foliage_spawner()
	return _foliage_spawner._foliage_jitter(_build_foliage_spawner_context(), pos)


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
	var combat_active := _is_combat_readability_active()
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
				"x_padding": combat_foliage_mob_x_padding if combat_active else foliage_mob_occlusion_x_padding,
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


func _update_combat_readability_state(delta: float) -> void:
	if not combat_readability_enabled:
		_combat_readability_timer = 0.0
		return
	var player := _streaming_player
	if player == null or not is_instance_valid(player):
		var tree := get_tree()
		if tree != null:
			player = tree.get_first_node_in_group("player") as Node2D
	if player == null:
		_combat_readability_timer = maxf(0.0, _combat_readability_timer - delta)
		return

	var active := false
	var range_squared := combat_readability_enemy_range * combat_readability_enemy_range
	var tree := get_tree()
	if tree != null:
		for group_name in foliage_mob_occlusion_groups:
			var group := String(group_name)
			if group.is_empty():
				continue
			for node in tree.get_nodes_in_group(group):
				if not (node is Node2D):
					continue
				var actor := node as Node2D
				if actor == player or _is_foliage_occluder_inactive(actor):
					continue
				if actor.global_position.distance_squared_to(player.global_position) <= range_squared:
					active = true
					break
			if active:
				break
	if active:
		_combat_readability_timer = combat_foliage_hold_seconds
	else:
		_combat_readability_timer = maxf(0.0, _combat_readability_timer - delta)


func _is_combat_readability_active() -> bool:
	return _combat_readability_timer > 0.0


func debug_get_combat_readability_state() -> Dictionary:
	return {
		"enabled": combat_readability_enabled,
		"active": _is_combat_readability_active(),
		"timer": _combat_readability_timer,
		"enemy_range": combat_readability_enemy_range,
		"foliage_radius": combat_foliage_occlusion_radius if _is_combat_readability_active() else foliage_player_occlusion_radius,
		"foliage_softness": combat_foliage_occlusion_softness if _is_combat_readability_active() else foliage_player_occlusion_softness,
		"foliage_alpha": combat_foliage_occlusion_alpha if _is_combat_readability_active() else foliage_player_occlusion_alpha,
	}


func _apply_foliage_occlusion_material(material: ShaderMaterial, active_centers: Array[Vector2]) -> void:
	var bubble_count := mini(active_centers.size(), _get_foliage_occlusion_bubble_limit())
	var combat_active := _is_combat_readability_active()
	material.set_shader_parameter("bubble_radius", combat_foliage_occlusion_radius if combat_active else foliage_player_occlusion_radius)
	material.set_shader_parameter("bubble_softness", combat_foliage_occlusion_softness if combat_active else foliage_player_occlusion_softness)
	material.set_shader_parameter("bubble_alpha", combat_foliage_occlusion_alpha if combat_active else foliage_player_occlusion_alpha)
	material.set_shader_parameter("bubble_enabled", bubble_count > 0)
	material.set_shader_parameter("bubble_count", bubble_count)
	if debug_log_foliage_occlusion_bubbles and bubble_count > 0:
		print("[FoliageOcclusion] combat=%s bubbles=%d radius=%.1f alpha=%.2f" % [
			combat_active,
			bubble_count,
			combat_foliage_occlusion_radius if combat_active else foliage_player_occlusion_radius,
			combat_foliage_occlusion_alpha if combat_active else foliage_player_occlusion_alpha,
		])
	for bubble_index in range(FOLIAGE_OCCLUSION_MAX_SHADER_BUBBLES):
		var center := Vector2.ZERO
		if bubble_index < bubble_count:
			center = active_centers[bubble_index]
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
	_clear_road_piece_decals()
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
			if _streaming_reveal_queue.is_empty():
				validate_no_stuck_pockets(runtime_blocker_remediate_stuck_pockets)
			_refresh_navigation_after_wall_change()


func _queue_chunk_for_reveal(chunk_pos: Vector2i, center_tile: Vector2i) -> void:
	if _revealed_chunks.has(chunk_pos) or _queued_chunks.has(chunk_pos):
		return
	_queued_chunks[chunk_pos] = true
	var tiles := _get_chunk_tiles(chunk_pos)
	tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _streaming_reveal_priority(a, center_tile) < _streaming_reveal_priority(b, center_tile)
	)
	for tile in tiles:
		_streaming_reveal_queue.append(tile)


func _streaming_reveal_priority(tile: Vector2i, center_tile: Vector2i) -> float:
	var score := float(tile.distance_squared_to(center_tile))
	var region := get_region_type_at_tile(tile)
	match region:
		"spawn_clearing":
			score -= 240.0
		"portal_plaza":
			score -= 220.0
		"compound_approach":
			score -= 180.0
		"compound_ingress":
			score -= 160.0
		"interior_threshold":
			score -= 140.0
		"soft_path":
			score -= 120.0
		"interior_floor":
			score -= 80.0
		"destroyed_wall_floor":
			score -= 60.0
		"foliage_cover":
			score += 30.0
	if _generated_wall_cells.has(tile):
		score += 12.0
	return score


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
			_remove_road_piece_decal(tile)
			_remove_runtime_wall_body(tile)
	_revealed_chunks.erase(chunk_pos)
	_sync_runtime_wall_collision_with_visible_walls()
	_rebuild_horizontal_wall_overlays()
	_refresh_shadows()


func _reveal_tile(tile: Vector2i) -> void:
	if _generated_floor_cells.has(tile):
		var floor_data: Dictionary = _generated_floor_cells[tile]
		floor_tilemap.set_cell(tile, int(floor_data.get("source_id", floor_source_id)), floor_data.get("atlas", floor_atlas_coord), int(floor_data.get("alternative", 0)))
		_reveal_road_piece_decal(tile)
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


func _remove_runtime_wall_body(tile: Vector2i, refresh_debug: bool = true) -> void:
	var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision") as Node2D
	if collision_root == null:
		return
	var body := collision_root.get_node_or_null(NodePath(_runtime_wall_body_name(tile)))
	if body != null:
		collision_root.remove_child(body)
		body.queue_free()
	if refresh_debug:
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
	var root := walls_tilemap.get_node_or_null("RuntimeWallVisuals") as Node2D
	if root == null:
		root = Node2D.new()
		root.name = "RuntimeWallVisuals"
		walls_tilemap.add_child(root)
	return root


func _clear_horizontal_wall_overlays() -> void:
	var overlay_root := _get_horizontal_wall_overlay_root()
	if overlay_root == null:
		return
	for child in overlay_root.get_children():
		child.queue_free()


func _rebuild_horizontal_wall_overlays() -> void:
	_clear_horizontal_wall_overlays()
	if walls_tilemap == null:
		return
	var overlay_root := _get_horizontal_wall_overlay_root()
	if overlay_root == null:
		return
	if use_horizontal_wall_overlays and horizontal_wall_overlay_texture != null:
		_rebuild_horizontal_top_wall_overlays(overlay_root)
	if use_vertical_wall_overlays and horizontal_wall_overlay_texture != null:
		_rebuild_vertical_side_wall_overlays(overlay_root)


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
	if floor_tilemap == null:
		return Vector2.ZERO
	if floor_tilemap.tile_set == null:
		var tile_size := _get_tile_size()
		return floor_tilemap.to_global((Vector2(tile) * tile_size) + (tile_size * 0.5))
	return floor_tilemap.to_global(floor_tilemap.map_to_local(tile))


func tile_to_global_position(tile: Vector2i) -> Vector2:
	return minimap_tile_to_global(tile)


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
	if world_shape_mode == WorldShapeMode.ASCENT_FIELD:
		if _worldgen_intent_graph != null:
			var origin: Vector2i = _worldgen_intent_graph.origin_cell
			if origin != Vector2i.ZERO:
				return origin
		if procgen_node != null:
			return Vector2i(procgen_node.map_size.x / 2, procgen_node.map_size.y - 12)
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
	if world_shape_mode == WorldShapeMode.ASCENT_FIELD:
		return _get_ascent_objective_anchors_by_distance_from_spawn()

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


func _get_ascent_objective_anchors_by_distance_from_spawn() -> Array[Vector2i]:
	var player_pos := get_player_spawn()
	var map_size := procgen_node.map_size if procgen_node != null else Vector2i.ZERO
	var anchors: Array[Vector2i] = []

	anchors.append_array(_sample_vector2i_array(_ascent_field_main_route_cells, map_size, 18))
	anchors.append_array(_sample_vector2i_array(_ascent_field_vista_cells, map_size, 6))

	if _worldgen_intent_graph != null:
		for cell in _worldgen_intent_graph.get_required_cells():
			if _is_tile_inside_map(cell, map_size):
				anchors.append(cell)

	for threshold in _last_interior_thresholds:
		if _is_tile_inside_map(threshold, map_size):
			anchors.append(threshold)

	for ingress in _last_compound_ingress:
		if _is_tile_inside_map(ingress, map_size):
			anchors.append(ingress)

	anchors = _dedupe_vector2i_array(anchors)
	var walkable_anchors: Array[Vector2i] = []
	for anchor in anchors:
		if is_valid_spawn_cell(anchor):
			walkable_anchors.append(anchor)

	if walkable_anchors.is_empty():
		walkable_anchors = _sample_vector2i_array(_dict_keys_as_vector2i_array(_generated_floor_cells), map_size, 18)

	var anchor_distances: Array = []
	for anchor in walkable_anchors:
		anchor_distances.append({
			"center": anchor,
			"distance": anchor.distance_to(player_pos),
		})
	anchor_distances.sort_custom(func(a, b): return a.distance > b.distance)

	var sorted_anchors: Array[Vector2i] = []
	for item in anchor_distances:
		sorted_anchors.append(item.center)
	return sorted_anchors


func _sample_vector2i_array(source: Array[Vector2i], map_size: Vector2i, max_count: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if source.is_empty() or max_count <= 0:
		return result
	if source.size() <= max_count:
		for cell in source:
			if _is_tile_inside_map(cell, map_size):
				result.append(cell)
		return result

	var last_index := source.size() - 1
	for i in range(max_count):
		var sample_index := int(round(float(i) * float(last_index) / float(max_count - 1)))
		var cell := source[sample_index]
		if _is_tile_inside_map(cell, map_size):
			result.append(cell)
	return result


## Returns random floor tiles in rooms (for pickups, ammo, etc)
func get_random_floor_tiles_in_rooms(count: int = 10) -> Array[Vector2i]:
	var rooms = procgen_node.get_rooms()
	var floor_tiles: Array[Vector2i] = []

	for room in rooms:
		for x in range(room.position.x + 1, room.position.x + room.size.x - 1):
			for y in range(room.position.y + 1, room.position.y + room.size.y - 1):
				var pos = Vector2i(x, y)
				if not procgen_node.is_full_at(pos) and is_valid_spawn_cell(pos):
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
			if is_valid_spawn_cell(pos):
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


func _world_shape_mode_name() -> String:
	match world_shape_mode:
		WorldShapeMode.LEGACY_CAVE:
			return "legacy_cave"
		_:
			return "ascent_field"


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
		"main_road_tiles": get_main_road_tiles(),
		"parking_zone_tiles": get_parking_zone_tiles(),
		"road_walk_speed_multiplier": road_walk_speed_multiplier,
		"road_vehicle_speed_multiplier": road_vehicle_speed_multiplier,
		"interior_region_rect": _last_interior_region_rect,
		"interior_rooms": _last_interior_rooms,
		"interior_thresholds": _last_interior_thresholds,
		"region_tiles": _region_tiles.duplicate(true),
		"elevation_cells": elevation_map.get_serialized_cells() if elevation_map != null else [],
		"pre_terrain_connectivity": _last_pre_terrain_connectivity.duplicate(true),
		"terrain_builder": _get_terrain_builder_level_data(),
		"floor_cells": _dict_keys_as_vector2i_array(_generated_floor_cells),
		"wall_cells": _dict_keys_as_vector2i_array(_generated_wall_cells),
		"runtime_prop_blocker_cells": _dict_keys_as_vector2i_array(_runtime_prop_blocker_cells),
		"runtime_prop_blocker_source_count": _runtime_prop_blocker_sources.size(),
		"world_profile": get_planet_world_profile(),
		"world_shape_mode": _world_shape_mode_name(),
		"world_progression_enabled": world_progression_enabled,
		"world_progress_profile_id": _world_progress_profile.profile_id if _world_progress_profile != null else "",
		"world_progress_samples": _world_progress_samples.duplicate(true),
		"worldgen_intent_enabled": worldgen_intent_enabled,
		"worldgen_intent_graph": _worldgen_intent_graph.to_dictionary() if _worldgen_intent_graph != null else {},
		"ascent_field_summary": _ascent_field_summary.duplicate(true),
		"main_route_cells": _ascent_field_main_route_cells.duplicate(),
		"vista_cells": _ascent_field_vista_cells.duplicate(),
		"worldgen_reserved_regions": _worldgen_reserved_regions.duplicate(true),
		"faction_activity_sites": _faction_activity_sites.duplicate(true),
		"story_room_sites": _story_room_sites.duplicate(true),
		"special_room_sites": _special_room_sites.duplicate(true),
		"intent_zones_enabled": true,
	}


func _get_dev_observatory() -> Node:
	return get_node_or_null("/root/DevObservatory")


func _obs_log(kind: StringName, data: Dictionary = {}) -> void:
	var observatory := _get_dev_observatory()
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", kind, data)


func _obs_increment(counter_name: StringName, amount: int = 1) -> void:
	var observatory := _get_dev_observatory()
	if observatory != null and observatory.has_method("increment"):
		observatory.call("increment", counter_name, amount)


func _obs_gauge(gauge_name: StringName, value: Variant) -> void:
	var observatory := _get_dev_observatory()
	if observatory != null and observatory.has_method("set_gauge"):
		observatory.call("set_gauge", gauge_name, value)


func _obs_warning(message: String, data: Dictionary = {}) -> void:
	var observatory := _get_dev_observatory()
	if observatory != null and observatory.has_method("mark_warning"):
		observatory.call("mark_warning", message, data)


func _get_terrain_builder_level_data() -> Dictionary:
	if _last_terrain_result.is_empty():
		return {
			"connectivity_ok": true,
			"fallback_used": false,
			"pre_terrain_connectivity": _last_pre_terrain_connectivity.duplicate(true),
		}
	var connectivity: Dictionary = _last_terrain_result.get("connectivity", {})
	var summary: Dictionary = _last_terrain_result.get("debug_summary", {})
	return {
		"connectivity_ok": bool(connectivity.get("ok", summary.get("connectivity_ok", true))),
		"fallback_used": bool(_last_terrain_result.get("fallback_used", summary.get("fallback_used", false))),
		"rescue_carved_cells": int(_last_terrain_result.get("rescue_carved_cells", summary.get("rescue_carved_cells", 0))),
		"baseline_rescue_carved_cells": int(_last_terrain_result.get("baseline_rescue_carved_cells", summary.get("baseline_rescue_carved_cells", 0))),
		"reachable_count": int(connectivity.get("reachable_count", 0)),
		"missing_required": connectivity.get("missing_required", []).duplicate(),
		"pre_terrain_connectivity": _last_pre_terrain_connectivity.duplicate(true),
		"summary": summary.duplicate(true),
	}
