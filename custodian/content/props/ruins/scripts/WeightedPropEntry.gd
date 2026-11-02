extends Resource
class_name WeightedPropEntry

@export var definition: PropDefinition
@export_range(0.0, 100.0, 0.1) var weight: float = 1.0
@export_range(0, 64, 1) var min_count: int = 0
@export_range(0, 64, 1) var max_count: int = 1
