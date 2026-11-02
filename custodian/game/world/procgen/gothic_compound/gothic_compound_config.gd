extends Resource
class_name GothicCompoundConfig

@export var enabled: bool = true
@export var tile_size: int = 32
@export var min_size: Vector2i = Vector2i(46, 34)
@export var max_size: Vector2i = Vector2i(58, 42)
@export var margin_from_map_edge: int = 6
@export var max_placement_attempts: int = 40
@export var gate_width_tiles: int = 5
@export var outer_margin_fill: int = 5
@export var wall_pillar_stride: int = 5
@export_range(0.0, 1.0, 0.01) var wall_damage_chance: float = 0.10
@export_range(0, 8, 1) var exterior_resource_count: int = 2
@export_range(0, 12, 1) var enemy_marker_count: int = 4
@export_range(0.0, 1.0, 0.001) var decorative_scatter_chance: float = 0.012
@export_range(0.0, 1.0, 0.01) var exterior_scatter_chance: float = 0.06
@export var debug_mark_required_paths: bool = false
