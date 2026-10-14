class_name ProcgenCliffFasciaProfile
extends Resource

## Frame-specific tile vocabulary for the existing presentation-only cliff face.
## Repeated source IDs represent deterministic weight; no gameplay semantics live here.
@export var profile_id: StringName = &""
@export var top_source_ids: Array[int] = []
@export var body_01_source_ids: Array[int] = []
@export var body_02_source_ids: Array[int] = []
@export var body_cracked_source_ids: Array[int] = []
@export var bottom_source_ids: Array[int] = []
@export var bottom_broken_source_ids: Array[int] = []
@export_range(-8, 8, 1) var north_depth_bias := -2
@export_range(-8, 8, 1) var east_depth_bias := 0
@export_range(-8, 8, 1) var south_depth_bias := 2
@export_range(-8, 8, 1) var west_depth_bias := 0

@export_group("Large Contact Integration")
@export_range(8, 48, 1) var contact_min_run_tiles := 10
@export_range(1, 4, 1) var contact_shoulder_tiles := 2
@export var ensure_cardinal_broad_contact := true
## Authored texture-pixel frontier sockets. Missing states fail closed.
@export var contact_socket_by_state: Dictionary = {}

@export_group("Fascia Variation")
@export_range(2, 12, 1) var tangential_variant_run_tiles := 5


func source_pool(role: String) -> Array[int]:
	match role:
		"top": return top_source_ids
		"body_01": return body_01_source_ids
		"body_02": return body_02_source_ids
		"body_cracked": return body_cracked_source_ids
		"bottom": return bottom_source_ids
		"bottom_broken": return bottom_broken_source_ids
	return []


func depth_bias(direction: Vector2i) -> int:
	if direction == Vector2i.UP: return north_depth_bias
	if direction == Vector2i.RIGHT: return east_depth_bias
	if direction == Vector2i.DOWN: return south_depth_bias
	if direction == Vector2i.LEFT: return west_depth_bias
	return 0


func is_valid() -> bool:
	if profile_id == &"" or top_source_ids.is_empty() or body_01_source_ids.is_empty() \
		or body_02_source_ids.is_empty() or body_cracked_source_ids.is_empty() \
		or bottom_source_ids.is_empty() or bottom_broken_source_ids.is_empty():
		return false
	if ensure_cardinal_broad_contact:
		for state in ["south_broad_01", "south_broken_01", "south_rooted_01", "east_broad_01", "west_broad_01", "north_broad_01"]:
			if not contact_socket_by_state.has(StringName(state)):
				return false
	return true
