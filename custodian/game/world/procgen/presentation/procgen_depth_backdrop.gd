class_name ProcgenDepthBackdrop
extends Node2D

const TILE_SIZE := 32
## Upper bound for the coverage-guaranteeing plate scale (zoom >= ~0.5 on the
## 1280x720 base viewport); beyond it the plate stops growing rather than blur.
const MAX_COVER_SCALE := 2.6
## Half-extent (local px) of the optional opaque base fill: covers any visible
## world rectangle up to zoom ~0.2 on a 1280x720 base viewport.
const BASE_FILL_HALF_EXTENT := 8192.0
const MIN_REGION_SCALE := 0.75
const MAX_REGION_SCALE := 1.25
const CARDINAL_NEIGHBORS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]

@export_group("Textures")
@export var underlay_profile: ProcgenUnderlayProfile
var variant_seed: int = 0
var far_texture: Texture2D
var middle_texture: Texture2D
var near_texture: Texture2D

@export_group("Regions")
@export_range(1, 64, 1) var minimum_region_tiles := 4
@export_range(1, 16, 1) var region_padding_tiles := 2

@export_group("Layer Opacity")
var far_alpha := 0.30
var middle_alpha := 0.90
var near_alpha := 0.48

@export_group("Camera Backdrop")
@export var follow_camera := true
@export var camera_overscan_scale := 1.08
@export var camera_search_interval_sec := 0.5

var _regions_root: Node2D
var _camera: Camera2D
var _camera_search_elapsed := 0.0
var _camera_searched := false
var _world_stack: Node2D
var _debug_mode := "hidden"
var _selected_variants := {"far": -1, "middle": -1, "near": -1}
var _configured_visible := false
var _connected_map_isolated := false
var _parallax := {"far": 0.0, "middle": 0.0, "near": 0.0}
var _parallax_max_px := 0.0
var _guarantee_coverage := false
var _base_fill_color := Color(0.0, 0.0, 0.0, 0.0)
var _motion_anchor := Vector2.ZERO
var _motion_anchor_set := false


func _ready() -> void:
	z_as_relative = false
	z_index = -300
	_regions_root = Node2D.new()
	_regions_root.name = "ChasmPresentationRoot"
	add_child(_regions_root)
	set_process(true)
	_set_configured_visible(false)
	if underlay_profile != null:
		_apply_profile(underlay_profile, variant_seed)

func set_underlay_profile(profile: ProcgenUnderlayProfile, seed_value: int = 0) -> void:
	underlay_profile = profile
	variant_seed = seed_value
	_apply_profile(profile, seed_value)


func set_variant_seed(seed_value: int) -> void:
	variant_seed = seed_value
	if underlay_profile != null:
		_apply_profile(underlay_profile, seed_value)

func get_underlay_profile_id() -> StringName:
	return underlay_profile.profile_id if underlay_profile != null else &""

func get_selected_variant_indices() -> Dictionary:
	return _selected_variants.duplicate()


func set_connected_map_isolation(isolated: bool) -> void:
	_connected_map_isolated = isolated
	_refresh_visibility()


func is_connected_map_isolated() -> bool:
	return _connected_map_isolated


func _set_configured_visible(enabled: bool) -> void:
	_configured_visible = enabled
	_refresh_visibility()


func _refresh_visibility() -> void:
	visible = _configured_visible and not _connected_map_isolated

func _apply_profile(profile: ProcgenUnderlayProfile, seed_value: int) -> void:
	if profile == null or not profile.is_valid():
		push_error("[ProcgenDepthBackdrop] Invalid underlay profile; chasm presentation cannot render.")
		return
	_parallax = {"far": profile.far_parallax, "middle": profile.middle_parallax, "near": profile.near_parallax}
	_parallax_max_px = profile.parallax_max_px
	_guarantee_coverage = profile.guarantee_viewport_coverage
	_base_fill_color = profile.base_fill_color
	far_alpha = profile.far_alpha
	middle_alpha = profile.middle_alpha
	near_alpha = profile.near_alpha
	_selected_variants["far"] = _variant_index(seed_value, profile.profile_id, &"far", profile.far_variants.size())
	_selected_variants["middle"] = _variant_index(seed_value, profile.profile_id, &"middle", profile.middle_variants.size())
	_selected_variants["near"] = _variant_index(seed_value, profile.profile_id, &"near", profile.near_variants.size())
	far_texture = profile.far_variants[_selected_variants["far"]]
	middle_texture = profile.middle_variants[_selected_variants["middle"]]
	near_texture = profile.near_variants[_selected_variants["near"]]
	_refresh_existing_layers()

func _variant_index(seed_value: int, profile_id: StringName, layer: StringName, count: int) -> int:
	if count <= 1: return 0
	var text := "%d:%s:%s" % [seed_value, String(profile_id), String(layer)]
	return absi(hash(text)) % count


func _process(delta: float) -> void:
	if not follow_camera or _world_stack == null:
		return
	if _camera == null or not is_instance_valid(_camera):
		# First lookup is immediate so the stack never lags the camera at start-up;
		# retries after a failed lookup stay throttled.
		if _camera_searched:
			_camera_search_elapsed += delta
			if _camera_search_elapsed < camera_search_interval_sec:
				return
			_camera_search_elapsed = 0.0
		_camera_searched = true
		_camera = get_viewport().get_camera_2d()
	if _camera == null:
		return
	_world_stack.global_position = _camera.global_position
	_update_depth_motion()


## Smallest uniform plate scale whose painted area covers the visible world
## rectangle plus the parallax margin on every side. Pure so tests can sweep it.
static func required_cover_scale(visible_size: Vector2, zoom: Vector2, texture_size: Vector2, margin_px: float) -> float:
	if zoom.x <= 0.0 or zoom.y <= 0.0:
		return MAX_COVER_SCALE
	var usable := texture_size - Vector2.ONE * (2.0 * margin_px)
	if usable.x <= 0.0 or usable.y <= 0.0:
		return MAX_COVER_SCALE
	return clampf(maxf(visible_size.x / zoom.x / usable.x, visible_size.y / zoom.y / usable.y), 1.0, MAX_COVER_SCALE)


## Bounded layer displacement (local, pre-scale px) for a camera displacement
## since the anchor; smooth, never exceeds max_px in any direction.
static func parallax_offset(camera_delta: Vector2, strength: float, max_px: float) -> Vector2:
	if strength <= 0.0 or max_px <= 0.0:
		return Vector2.ZERO
	var v := -camera_delta * strength
	var length := v.length()
	if length <= 0.0001:
		return Vector2.ZERO
	return v / length * max_px * tanh(length / max_px)


func get_depth_motion_snapshot() -> Dictionary:
	var result := {"stack_scale": 1.0, "base_fill": false, "guarantee_coverage": _guarantee_coverage, "parallax_max_px": _parallax_max_px, "offsets": {}}
	if _world_stack == null or not is_instance_valid(_world_stack):
		return result
	result["stack_scale"] = _world_stack.scale.x
	result["base_fill"] = _world_stack.get_node_or_null("BaseFill") != null
	for layer in ["Far", "Middle", "Near"]:
		var sprite := _world_stack.get_node_or_null(layer) as Sprite2D
		if sprite != null:
			(result["offsets"] as Dictionary)[layer.to_lower()] = sprite.position
	return result


func _update_depth_motion() -> void:
	var moving := _parallax_max_px > 0.0
	if not _guarantee_coverage and not moving:
		return
	if not _motion_anchor_set:
		_motion_anchor = _camera.global_position
		_motion_anchor_set = true
	var margin := _parallax_max_px if moving else 0.0
	if _guarantee_coverage:
		var base := clampf(camera_overscan_scale, 1.0, 1.08)
		var texture_size := Vector2(1536.0, 1024.0)
		if middle_texture != null:
			texture_size = Vector2(middle_texture.get_size())
		var cover := required_cover_scale(get_viewport().get_visible_rect().size, _camera.zoom, texture_size, margin)
		_world_stack.scale = Vector2.ONE * maxf(base, cover)
	if not moving:
		return
	var delta := _camera.global_position - _motion_anchor
	for layer in ["far", "middle", "near"]:
		var sprite := _world_stack.get_node_or_null(layer.capitalize()) as Sprite2D
		if sprite != null:
			sprite.position = parallax_offset(delta, float(_parallax[layer]), _parallax_max_px)


func configure_from_cells(world_cells: Array) -> void:
	# Compatibility path for the general procgen world. The existing caller
	# supplies generated world/floor cells to establish presentation bounds;
	# it does not yet guarantee explicit chasm cells.
	_clear_regions()
	_debug_mode = "world_fallback"

	var decoded_cells: Array[Vector2i] = []

	for value: Variant in world_cells:
		var cell := _decode_cell(value)

		if cell == Vector2i(-2147483648, -2147483648):
			continue

		decoded_cells.append(cell)

	if decoded_cells.is_empty():
		_set_configured_visible(false)
		push_warning(
			"[ProcgenDepthBackdrop] No world cells received; backdrop hidden."
		)
		return

	_create_world_bounds_stack(decoded_cells)
	_set_configured_visible(true)

	print(
		"[ProcgenDepthBackdrop] World fallback active: cells=%d"
		% decoded_cells.size()
	)


func configure_from_chasm_cells(chasm_cells: Array) -> void:
	_clear_regions()
	_debug_mode = "chasm_camera_follow"
	var decoded_cells: Array[Vector2i] = []
	for value: Variant in chasm_cells:
		var cell := _decode_cell(value)
		if cell == Vector2i(-2147483648, -2147483648):
			continue
		decoded_cells.append(cell)
	if decoded_cells.is_empty():
		_set_configured_visible(false)
		push_warning(
			"[ProcgenDepthBackdrop] No chasm cells received; backdrop hidden."
		)
		return
	_create_world_bounds_stack(decoded_cells)
	if _world_stack != null:
		_world_stack.set_meta("chasm_cell_bounds", _cell_bounds(decoded_cells))
		_world_stack.set_meta("chasm_cell_count", decoded_cells.size())
	_set_configured_visible(true)
	print(
		"[ProcgenDepthBackdrop] Chasm camera backdrop active: cells=%d"
		% decoded_cells.size()
	)


## Hides the global backdrop without configuring any bounds, e.g. when a map
## has chasm cells but none connect to the exterior boundary.
func configure_hidden(reason: String) -> void:
	_clear_regions()
	_debug_mode = reason
	_set_configured_visible(false)


func get_debug_mode() -> String:
	return _debug_mode


func set_streaming_chunk_visible(
	_chunk: Vector2i,
	_is_visible: bool
) -> void:
	# Chasm presentation is derived from complete terrain semantics and remains
	# global. Terrain, cliffs and local fog continue to use chunk visibility.
	pass


func get_region_debug_state() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _regions_root == null:
		return result
	for child: Node in _regions_root.get_children():
		if not child is Node2D:
			continue
		result.append({
			"name": String(child.name),
			"cell_bounds": child.get_meta("chasm_cell_bounds", Rect2i()),
			"cell_count": int(child.get_meta("chasm_cell_count", 0)),
			"scale": (child as Node2D).scale.x,
		})
	return result


func _create_world_bounds_stack(
	world_cells: Array[Vector2i]
) -> void:
	var bounds := _cell_bounds(world_cells)
	_world_stack = Node2D.new()
	_world_stack.name = "CameraDepthBackdrop"
	_world_stack.position = Vector2.ZERO
	_world_stack.scale = Vector2.ONE * clampf(camera_overscan_scale, 1.0, 1.08)
	_world_stack.set_meta("world_cell_bounds", bounds)
	_regions_root.add_child(_world_stack)

	if _base_fill_color.a > 0.0:
		var fill := Polygon2D.new()
		fill.name = "BaseFill"
		fill.polygon = PackedVector2Array([Vector2(-BASE_FILL_HALF_EXTENT, -BASE_FILL_HALF_EXTENT), Vector2(BASE_FILL_HALF_EXTENT, -BASE_FILL_HALF_EXTENT), Vector2(BASE_FILL_HALF_EXTENT, BASE_FILL_HALF_EXTENT), Vector2(-BASE_FILL_HALF_EXTENT, BASE_FILL_HALF_EXTENT)])
		fill.color = _base_fill_color
		fill.z_as_relative = true
		fill.z_index = -4
		_world_stack.add_child(fill)

	_create_layer(
		_world_stack,
		"Far",
		far_texture,
		far_alpha,
		-3
	)

	_create_layer(
		_world_stack,
		"Middle",
		middle_texture,
		middle_alpha,
		-2
	)

	_create_layer(
		_world_stack,
		"Near",
		near_texture,
		near_alpha,
		-1
	)


func _create_region_stack(
	region_cells: Array[Vector2i],
	region_index: int
) -> void:
	# Retained for non-production archaeology only. Production configuration
	# uses the seam-safe camera-following world stack.
	var bounds := _cell_bounds(region_cells)
	var expanded := bounds.grow(region_padding_tiles)
	var world_rect := Rect2(
		Vector2(expanded.position * TILE_SIZE),
		Vector2(expanded.size * TILE_SIZE)
	)

	var region := Node2D.new()
	region.name = "ChasmRegion_%02d" % region_index
	region.position = world_rect.get_center()
	region.set_meta("chasm_cell_bounds", bounds)
	region.set_meta("chasm_cell_count", region_cells.size())
	_regions_root.add_child(region)

	var scale_value := _region_scale(world_rect.size)
	region.scale = Vector2.ONE * scale_value
	_create_layer(region, "Far", far_texture, far_alpha, -3)
	_create_layer(region, "Middle", middle_texture, middle_alpha, -2)
	_create_layer(region, "Near", near_texture, near_alpha, -1)


func _region_scale(region_size: Vector2) -> float:
	var texture_size := Vector2(1536.0, 1024.0)
	if middle_texture != null:
		texture_size = Vector2(middle_texture.get_size())
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return MIN_REGION_SCALE
	return clampf(
		maxf(
			region_size.x / texture_size.x,
			region_size.y / texture_size.y
		),
		MIN_REGION_SCALE,
		MAX_REGION_SCALE
	)


func _create_layer(
	parent: Node2D,
	node_name: String,
	texture: Texture2D,
	alpha: float,
	local_z: int
) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = true
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	sprite.z_as_relative = true
	sprite.z_index = local_z
	parent.add_child(sprite)


func _refresh_existing_layers() -> void:
	if _world_stack == null or not is_instance_valid(_world_stack):
		return
	var base_fill := _world_stack.get_node_or_null("BaseFill") as Polygon2D
	if base_fill != null:
		base_fill.color = _base_fill_color
	_update_layer(_world_stack.get_node_or_null("Far"), far_texture, far_alpha)
	_update_layer(_world_stack.get_node_or_null("Middle"), middle_texture, middle_alpha)
	_update_layer(_world_stack.get_node_or_null("Near"), near_texture, near_alpha)


func _update_layer(node: Node, texture: Texture2D, alpha: float) -> void:
	var sprite := node as Sprite2D
	if sprite == null:
		return
	sprite.texture = texture
	sprite.modulate.a = alpha


func _connected_regions(cells: Array) -> Array[Array]:
	var remaining: Dictionary = {}
	for value: Variant in cells:
		var cell := _decode_cell(value)
		if cell != Vector2i(-2147483648, -2147483648):
			remaining[cell] = true

	var regions: Array[Array] = []
	while not remaining.is_empty():
		var start := remaining.keys()[0] as Vector2i
		var pending: Array[Vector2i] = [start]
		var region: Array[Vector2i] = []
		remaining.erase(start)
		while not pending.is_empty():
			var cell: Vector2i = pending.pop_back()
			region.append(cell)
			for offset in CARDINAL_NEIGHBORS:
				var neighbor := cell + offset
				if not remaining.has(neighbor):
					continue
				remaining.erase(neighbor)
				pending.append(neighbor)
		regions.append(region)
	regions.sort_custom(
		func(a: Array, b: Array) -> bool:
			return a.size() > b.size()
	)
	return regions


func _decode_cell(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value as Vector2i
	if value is Array and (value as Array).size() >= 2:
		var raw := value as Array
		return Vector2i(int(raw[0]), int(raw[1]))
	return Vector2i(-2147483648, -2147483648)


func _clear_regions() -> void:
	_world_stack = null
	_motion_anchor_set = false
	_camera = null
	_camera_searched = false
	_camera_search_elapsed = 0.0
	if _regions_root == null:
		return
	for child: Node in _regions_root.get_children():
		child.free()


func _cell_bounds(cells: Array) -> Rect2i:
	if cells.is_empty():
		return Rect2i()
	var min_cell := cells[0] as Vector2i
	var max_cell := min_cell
	for value: Variant in cells:
		var cell := value as Vector2i
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	return Rect2i(min_cell, max_cell - min_cell + Vector2i.ONE)
