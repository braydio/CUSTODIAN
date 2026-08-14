class_name ProcgenDepthBackdrop
extends Node2D

const TILE_SIZE := 32
const MIN_REGION_SCALE := 0.75
const MAX_REGION_SCALE := 1.25
const CARDINAL_NEIGHBORS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]

@export_group("Textures")
@export var far_haze_texture: Texture2D
@export var canopy_texture: Texture2D
@export var wall_growth_texture: Texture2D

@export_group("Regions")
@export_range(1, 64, 1) var minimum_region_tiles := 4
@export_range(1, 16, 1) var region_padding_tiles := 2

@export_group("Layer Opacity")
@export_range(0.0, 1.0, 0.01) var far_haze_alpha := 0.30
@export_range(0.0, 1.0, 0.01) var canopy_alpha := 0.90
@export_range(0.0, 1.0, 0.01) var wall_growth_alpha := 0.48

@export_group("Camera Backdrop")
@export var follow_camera := true
@export var camera_overscan_scale := 1.08
@export var camera_search_interval_sec := 0.5

var _regions_root: Node2D
var _camera: Camera2D
var _camera_search_elapsed := 0.0
var _world_stack: Node2D
var _debug_mode := "hidden"


func _ready() -> void:
	z_as_relative = false
	z_index = -300
	_regions_root = Node2D.new()
	_regions_root.name = "ChasmPresentationRoot"
	add_child(_regions_root)
	set_process(true)
	visible = false


func _process(delta: float) -> void:
	if not follow_camera or _world_stack == null:
		return
	if _camera == null or not is_instance_valid(_camera):
		_camera_search_elapsed += delta
		if _camera_search_elapsed < camera_search_interval_sec:
			return
		_camera_search_elapsed = 0.0
		_camera = get_viewport().get_camera_2d()
	if _camera == null:
		return
	_world_stack.global_position = _camera.global_position


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
		visible = false
		push_warning(
			"[ProcgenDepthBackdrop] No world cells received; backdrop hidden."
		)
		return

	_create_world_bounds_stack(decoded_cells)
	visible = true

	print(
		"[ProcgenDepthBackdrop] World fallback active: cells=%d"
		% decoded_cells.size()
	)


func configure_from_chasm_cells(chasm_cells: Array) -> void:
	_clear_regions()
	_debug_mode = "chasm_regions"
	var regions := _connected_regions(chasm_cells)
	var region_index := 1
	for region_cells: Array[Vector2i] in regions:
		if region_cells.size() < minimum_region_tiles:
			continue
		_create_region_stack(region_cells, region_index)
		region_index += 1
	visible = region_index > 1


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

	_create_layer(
		_world_stack,
		"FarHaze",
		far_haze_texture,
		far_haze_alpha,
		-3
	)

	_create_layer(
		_world_stack,
		"CanopyMass",
		canopy_texture,
		canopy_alpha,
		-2
	)

	_create_layer(
		_world_stack,
		"WallGrowth",
		wall_growth_texture,
		wall_growth_alpha,
		-1
	)


func _create_region_stack(
	region_cells: Array[Vector2i],
	region_index: int
) -> void:
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
	_create_layer(region, "FarHaze", far_haze_texture, far_haze_alpha, -3)
	_create_layer(region, "CanopyMass", canopy_texture, canopy_alpha, -2)
	_create_layer(region, "WallGrowth", wall_growth_texture, wall_growth_alpha, -1)


func _region_scale(region_size: Vector2) -> float:
	var texture_size := Vector2(1536.0, 1024.0)
	if canopy_texture != null:
		texture_size = Vector2(canopy_texture.get_size())
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
	_camera = null
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
