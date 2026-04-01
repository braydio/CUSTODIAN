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

const RUNTIME_WALL_SEGMENT_SCRIPT := preload("res://procgen/runtime_wall_segment.gd")

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
@export var reference_open_left_wall_coords: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(8, 3)
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
	Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(11, 3)
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
@export var reference_north_west_corner_coords: Array[Vector2i] = [
	Vector2i(5, 1)
]
@export var reference_north_east_corner_coords: Array[Vector2i] = [
	Vector2i(6, 1)
]
@export var reference_left_terminal_coords: Array[Vector2i] = [
	Vector2i(3, 3)
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
var _wall_health: Dictionary = {}
var _generated_floor_cells: Dictionary = {}
var _generated_wall_cells: Dictionary = {}
var _revealed_chunks: Dictionary = {}
var _queued_chunks: Dictionary = {}
var _streaming_reveal_queue: Array[Vector2i] = []
var _streaming_player: Node2D = null
var _streaming_current_chunk: Vector2i = Vector2i(999999, 999999)
var shadow_system: Node = null


const FOLIAGE_ASSET_PATHS := [
	"res://assets/sprites/environment/foliage/shrub_verdent_32x32_01.png",
	"res://assets/sprites/environment/foliage/shrub_verdent_32x32_02.png",
	"res://assets/sprites/environment/foliage/shrub_verdent_32x32_03.png",
	"res://assets/sprites/environment/foliage/shrub_verdent_64x64_01.png",
	"res://assets/sprites/environment/foliage/shrub_verdent_64x64_02.png",
	"res://assets/sprites/environment/foliage/shrub_verdent_64x64_03.png",
	"res://assets/sprites/environment/foliage/tree_verdent_96x128_01.png",
	"res://assets/sprites/environment/foliage/tree_verdent_96x128_02.png",
	"res://assets/sprites/environment/foliage/tree_verdent_96x128_03.png",
]
@export var foliage_parent_path: NodePath = NodePath("NavigationRegion2D/FoliageLayer")
@export var foliage_density: float = 0.12
@export var foliage_min_wall_distance: int = 1
@export var foliage_jitter_amplitude: Vector2 = Vector2(4, 2)
@export var extra_foliage_textures: Array[Texture2D] = []

var _foliage_parent: Node2D = null
var _foliage_nodes: Array[Node2D] = []
var _foliage_textures: Array[Texture2D] = []

func _ready() -> void:
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
	_load_foliage_textures()
	
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


## Emitted when level data is ready (after generation)
signal level_data_ready(data: Dictionary)


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
		_clear_foliage()
	
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
	if use_cohesive_wall_visuals:
		_apply_wall_visuals(map_size)
	_capture_generated_tile_state(map_size)
	if enable_streaming_reveal:
		_prepare_streaming_reveal()
	elif build_runtime_wall_collision:
		_rebuild_runtime_wall_collision(map_size)


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


func _apply_wall_visuals(map_size: Vector2i) -> void:
	var source = high_walls_source_id if use_high_walls else walls_source_id
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos := Vector2i(x, y)
			if walls_tilemap.get_cell_source_id(pos) < 0:
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
			return _pick_reference_coord(pos, reference_left_terminal_coords, wall_atlas_coord)
		1, 4:
			return _pick_reference_coord(pos, reference_vertical_wall_coords, wall_atlas_coord)
		2:
			return _pick_reference_coord(pos, reference_horizontal_wall_coords, wall_atlas_coord)
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


func _rebuild_runtime_wall_collision(map_size: Vector2i) -> void:
	var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision") as Node2D
	if collision_root == null:
		collision_root = Node2D.new()
		collision_root.name = "RuntimeWallCollision"
		walls_tilemap.add_child(collision_root)

	for child in collision_root.get_children():
		child.queue_free()

	var tile_size: Vector2 = Vector2(16, 16)
	if walls_tilemap.tile_set != null:
		tile_size = Vector2(walls_tilemap.tile_set.tile_size)

	for y in range(map_size.y):
		for x in range(map_size.x):
			var pos := Vector2i(x, y)
			var src := walls_tilemap.get_cell_source_id(pos)
			if src < 0:
				continue
			_spawn_runtime_wall_body(pos)


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
	_refresh_wall_neighbors(pos)
	_refresh_shadows()
	if build_runtime_wall_collision and procgen_node != null:
		call_deferred("_rebuild_runtime_wall_collision", procgen_node.map_size)
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


func _refresh_navigation_after_wall_change() -> void:
	for navigation_node in get_tree().get_nodes_in_group("navigation"):
		if navigation_node != null and navigation_node.has_method("rebuild"):
			navigation_node.call_deferred("rebuild")


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
				}
			var wall_source := walls_tilemap.get_cell_source_id(pos)
			if wall_source >= 0:
				_generated_wall_cells[pos] = {
					"source_id": wall_source,
					"atlas": walls_tilemap.get_cell_atlas_coords(pos),
				}

	_generate_foliage(map_size)


func _generate_foliage(map_size: Vector2i) -> void:
	if _foliage_parent == null:
		return
	_clear_foliage()
	if _foliage_textures.is_empty():
		return

	for pos in _generated_floor_cells.keys():
		if _should_place_foliage(pos):
			_place_foliage(pos)


func _clear_foliage() -> void:
	for node in _foliage_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_foliage_nodes.clear()


func _should_place_foliage(pos: Vector2i) -> bool:
	if foliage_density <= 0.0:
		return false
	if _is_near_wall(pos):
		return false
	var prob := float(_tile_noise_hash(pos + Vector2i(13, 41)) % 1000) / 1000.0
	return prob < foliage_density


func _is_near_wall(pos: Vector2i) -> bool:
	if _generated_wall_cells.is_empty():
		return false
	for x in range(-foliage_min_wall_distance, foliage_min_wall_distance + 1):
		for y in range(-foliage_min_wall_distance, foliage_min_wall_distance + 1):
			if _generated_wall_cells.has(pos + Vector2i(x, y)):
				return true
	return false


func _place_foliage(pos: Vector2i) -> void:
	var texture := _pick_foliage_texture(pos)
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = _tile_to_world_position(pos) + _foliage_jitter(pos)
	sprite.z_index = 1
	sprite.z_as_relative = true
	sprite.scale = Vector2.ONE
	_foliage_parent.add_child(sprite)
	_foliage_nodes.append(sprite)


func _pick_foliage_texture(pos: Vector2i) -> Texture2D:
	if _foliage_textures.is_empty():
		return null
	var idx := _tile_noise_hash(pos + Vector2i(19, 73)) % _foliage_textures.size()
	return _foliage_textures[idx]


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


func _prepare_streaming_reveal() -> void:
	_revealed_chunks.clear()
	_queued_chunks.clear()
	_streaming_reveal_queue.clear()
	_streaming_player = null
	_streaming_current_chunk = Vector2i(999999, 999999)
	_clear_foliage()
	floor_tilemap.clear()
	walls_tilemap.clear()
	var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision") as Node
	if collision_root != null:
		for child in collision_root.get_children():
			child.queue_free()
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
	_refresh_shadows()
	_refresh_navigation_after_wall_change()


func _update_streaming_chunks(center_chunk: Vector2i, center_tile: Vector2i) -> void:
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
		_refresh_shadows()
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
			_remove_runtime_wall_body(tile)
	_revealed_chunks.erase(chunk_pos)
	_refresh_shadows()


func _reveal_tile(tile: Vector2i) -> void:
	if _generated_floor_cells.has(tile):
		var floor_data: Dictionary = _generated_floor_cells[tile]
		floor_tilemap.set_cell(tile, int(floor_data.get("source_id", floor_source_id)), floor_data.get("atlas", floor_atlas_coord))
	if _generated_wall_cells.has(tile):
		var wall_data: Dictionary = _generated_wall_cells[tile]
		walls_tilemap.set_cell(tile, int(wall_data.get("source_id", walls_source_id)), wall_data.get("atlas", wall_atlas_coord))
		if build_runtime_wall_collision:
			_spawn_runtime_wall_body(tile)


func _spawn_runtime_wall_body(tile: Vector2i) -> void:
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
	rect.size = Vector2(tile_size.x, tile_size.y)
	shape.shape = rect
	body.add_child(shape)
	collision_root.add_child(body)


func _remove_runtime_wall_body(tile: Vector2i) -> void:
	var collision_root := walls_tilemap.get_node_or_null("RuntimeWallCollision") as Node2D
	if collision_root == null:
		return
	var body := collision_root.get_node_or_null(NodePath(_runtime_wall_body_name(tile)))
	if body != null:
		body.queue_free()


func _runtime_wall_body_name(tile: Vector2i) -> String:
	return "Wall_%d_%d" % [tile.x, tile.y]


func _global_to_tile(global_position: Vector2) -> Vector2i:
	if floor_tilemap != null:
		return floor_tilemap.local_to_map(floor_tilemap.to_local(global_position))
	return Vector2i.ZERO


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
func get_level_data() -> Dictionary:
	return {
		"map_size": procgen_node.map_size,
		"player_spawn": get_player_spawn(),
		"rooms": get_room_centers(),
		"rooms_by_distance": get_rooms_by_distance_from_spawn(),
		"corridor_spawns": get_corridor_spawn_points(),
		"random_floor_tiles": get_random_floor_tiles_in_rooms(20),
		"compound_rect": _last_compound_rect,
		"compound_ingress": _last_compound_ingress,
		"compound_buildings": _last_compound_buildings,
	}
