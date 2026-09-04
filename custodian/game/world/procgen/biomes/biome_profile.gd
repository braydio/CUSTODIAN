extends Resource
class_name BiomeProfile

@export var biome_id: StringName = &"scrubland"
@export_range(0.0, 1.0, 0.01) var foliage_density_ceiling: float = 0.08
@export_range(0.0, 1.0, 0.01) var tree_probability: float = 0.08
@export var foliage_tint: Color = Color.WHITE
