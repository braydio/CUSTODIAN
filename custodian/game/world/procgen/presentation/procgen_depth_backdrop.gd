class_name ProcgenDepthBackdrop
extends Node2D

const TILE_SIZE := 32
const DEFAULT_MARGIN_TILES := 24

@export var forest_texture: Texture2D
@export var mist_texture: Texture2D
@export_range(0, 64, 1) var margin_tiles := DEFAULT_MARGIN_TILES
@export_range(0.0, 1.0, 0.01) var forest_alpha := 0.78
@export_range(0.0, 1.0, 0.01) var mist_alpha := 0.42

var _forest: Sprite2D
var _mist: Sprite2D


func _ready() -> void:
	z_as_relative = false
	z_index = -300
	_forest = _create_region_sprite(
		"EndlessForestDepth",
		forest_texture,
		forest_alpha,
		-2
	)
	_mist = _create_region_sprite(
		"EndlessForestMist",
		mist_texture,
		mist_alpha,
		-1
	)


func configure_from_cells(cells: Array) -> void:
	var bounds := _cell_bounds(cells)
	if bounds.size == Vector2i.ZERO:
		visible = false
		return

	visible = true

	var expanded := bounds.grow(margin_tiles)
	var world_rect := Rect2(
		Vector2(expanded.position * TILE_SIZE),
		Vector2(expanded.size * TILE_SIZE)
	)

	_configure_region_sprite(_forest, world_rect)
	_configure_region_sprite(_mist, world_rect)


func set_streaming_chunk_visible(
	_chunk: Vector2i,
	_is_visible: bool
) -> void:
	# The deep backdrop is deliberately global. Chunk reveal owns terrain,
	# cliffs, props, and fog-edge presentation, not the distant forest.
	pass


func _create_region_sprite(
	node_name: String,
	texture: Texture2D,
	alpha: float,
	local_z: int
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	sprite.z_as_relative = true
	sprite.z_index = local_z
	add_child(sprite)
	return sprite


func _configure_region_sprite(
	sprite: Sprite2D,
	world_rect: Rect2
) -> void:
	if sprite == null or sprite.texture == null:
		return
	sprite.position = world_rect.position
	sprite.region_rect = Rect2(
		Vector2.ZERO,
		world_rect.size
	)


func _cell_bounds(cells: Array) -> Rect2i:
	var initialized := false
	var min_cell := Vector2i.ZERO
	var max_cell := Vector2i.ZERO

	for value: Variant in cells:
		var cell: Vector2i
		if value is Vector2i:
			cell = value as Vector2i
		elif value is Array and (value as Array).size() >= 2:
			var raw := value as Array
			cell = Vector2i(int(raw[0]), int(raw[1]))
		else:
			continue

		if not initialized:
			initialized = true
			min_cell = cell
			max_cell = cell
			continue

		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)

	if not initialized:
		return Rect2i()

	return Rect2i(
		min_cell,
		max_cell - min_cell + Vector2i.ONE
	)
