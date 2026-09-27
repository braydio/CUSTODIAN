extends Resource
class_name DressingClusterProfile

@export var cluster_id: StringName = &""
@export var required_biome: StringName = &""
@export var allowed_surface_materials: PackedStringArray = PackedStringArray()
@export var footprint_cells: Array[Vector2i] = []
@export var suppression_cells: Array[Vector2i] = []
@export var children: Array[DressingClusterChild] = []
@export_range(0, 65535, 1) var weight: int = 0
@export_range(0, 64, 1) var max_instances_per_map: int = 0
@export_range(0, 256, 1) var min_anchor_spacing_cells: int = 0
@export var allow_sparse_band: bool = false
@export var allow_deep_band: bool = false


func validate_contract() -> PackedStringArray:
	var failures := PackedStringArray()
	if cluster_id == &"": failures.append("missing_cluster_id")
	if required_biome == &"": failures.append("missing_required_biome")
	if allowed_surface_materials.is_empty(): failures.append("missing_surface_materials")
	if footprint_cells.is_empty(): failures.append("empty_footprint")
	if suppression_cells.is_empty(): failures.append("empty_suppression")
	if children.is_empty(): failures.append("empty_children")
	if weight <= 0: failures.append("nonpositive_weight")
	if max_instances_per_map <= 0: failures.append("nonpositive_instance_limit")
	if min_anchor_spacing_cells < 0: failures.append("negative_anchor_spacing")
	if not allow_sparse_band and not allow_deep_band: failures.append("no_allowed_route_band")
	for child in children:
		if child == null:
			failures.append("null_child")
			break
	return failures
