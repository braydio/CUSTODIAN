extends Node2D
class_name IsometricVisualAnchor2D

## Ground/sort root for a 2.5D presentation object. This node's position is the
## ground contact; elevation only offsets the child VisualRoot vertically.
## Owns no physics, collision, or navigation.

@export var visual_root_path: NodePath = NodePath("VisualRoot")
@export var profile: IsometricPresentationProfile:
	set(value):
		profile = value
		if is_node_ready():
			apply_profile()

var _visual_base_position := Vector2.ZERO
var _visual_base_captured := false
var _elevation_px := 0.0


func _ready() -> void:
	apply_profile()


func apply_profile() -> void:
	var visual := _get_visual_root()
	if visual != null and not _visual_base_captured:
		_visual_base_position = visual.position
		_visual_base_captured = true
	if profile == null:
		set_visual_elevation_px(0.0)
		return
	z_index = profile.get_band_z_index()
	set_visual_elevation_px(profile.visual_elevation_px)


func set_visual_elevation_px(value: float) -> void:
	_elevation_px = value
	var visual := _get_visual_root()
	if visual == null:
		return
	if not _visual_base_captured:
		_visual_base_position = visual.position
		_visual_base_captured = true
	visual.position = _visual_base_position + Vector2(0.0, -value)


func get_visual_elevation_px() -> float:
	return _elevation_px


func get_ground_world_position() -> Vector2:
	return global_position


func get_sort_world_position() -> Vector2:
	var offset := profile.sort_anchor_offset if profile != null else Vector2.ZERO
	return global_position + offset


func _get_visual_root() -> Node2D:
	return get_node_or_null(visual_root_path) as Node2D
