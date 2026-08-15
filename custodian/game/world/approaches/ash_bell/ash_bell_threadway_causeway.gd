extends Node2D
class_name AshBellThreadwayCauseway

signal resolution_finished
signal visual_resolution_finished

const RESOLVE_TEXTURE := preload(
	"res://content/sprites/world/ingress/ash_bell/ash_bell_threadway_resolve_01__7f__32.png"
)
const FLOOR_TEXTURES: Array[Texture2D] = [
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_1.png"),
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_2.png"),
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_3.png"),
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_4.png"),
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_5.png"),
	preload("res://content/sprites/world/ingress/ash_bell/source/generated/ash_bell_threadway_floor_tiles_6t_32px_6.png"),
]
const SOURCE_TILE_SIZE := Vector2(32.0, 32.0)
const RESOLVE_FRAME_COUNT := 7
const RESOLVE_FPS := 11.0
const CENTERLINE_STAGGER_SECONDS := 0.05

var _map_instance: Node = null
var _persistent_by_tile: Dictionary = {}
var _temporary_blocker: StaticBody2D = null
var _reveal_play_count := 0
var _resolve_frames: SpriteFrames = null


func configure(map_instance: Node, connector: Dictionary, play_reveal: bool) -> void:
	_map_instance = map_instance
	var cells: Array = connector.get("cells", [])
	var variants: Dictionary = connector.get("tile_variants", {})
	var tile_size := _runtime_tile_size()
	for cell_variant in cells:
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		var sprite := Sprite2D.new()
		sprite.name = "ThreadwayFloor_%d_%d" % [cell.x, cell.y]
		sprite.texture = FLOOR_TEXTURES[int(variants.get(cell, 0)) % FLOOR_TEXTURES.size()]
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = tile_size / SOURCE_TILE_SIZE
		sprite.z_as_relative = false
		sprite.z_index = 0
		sprite.visible = not play_reveal
		add_child(sprite)
		sprite.global_position = _tile_to_global(cell)
		_persistent_by_tile[cell] = sprite
	if not play_reveal:
		return
	_build_temporary_blocker(cells, tile_size)
	_play_resolution.call_deferred(connector)


func _play_resolution(connector: Dictionary) -> void:
	_reveal_play_count += 1
	var centerline: Array = connector.get("centerline_cells", [])
	centerline.reverse()
	for center_variant in centerline:
		if not center_variant is Vector2i:
			continue
		var center := center_variant as Vector2i
		_spawn_resolve_vfx(center)
		_reveal_near_center(center)
		await get_tree().create_timer(CENTERLINE_STAGGER_SECONDS).timeout
	await get_tree().create_timer(float(RESOLVE_FRAME_COUNT) / RESOLVE_FPS).timeout
	visual_resolution_finished.emit()


func finish_resolution() -> void:
	_remove_temporary_blocker()
	resolution_finished.emit()


func _spawn_resolve_vfx(cell: Vector2i) -> void:
	if _resolve_frames == null:
		_resolve_frames = SpriteFrames.new()
		_resolve_frames.add_animation(&"resolve")
		_resolve_frames.set_animation_loop(&"resolve", false)
		_resolve_frames.set_animation_speed(&"resolve", RESOLVE_FPS)
		for frame_index in range(RESOLVE_FRAME_COUNT):
			var atlas := AtlasTexture.new()
			atlas.atlas = RESOLVE_TEXTURE
			atlas.region = Rect2(frame_index * 32.0, 0.0, 32.0, 32.0)
			_resolve_frames.add_frame(&"resolve", atlas)
	var effect := AnimatedSprite2D.new()
	effect.sprite_frames = _resolve_frames
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.scale = _runtime_tile_size() / SOURCE_TILE_SIZE
	effect.z_as_relative = false
	effect.z_index = 1
	add_child(effect)
	effect.global_position = _tile_to_global(cell)
	effect.animation_finished.connect(effect.queue_free)
	effect.play(&"resolve")


func _reveal_near_center(center: Vector2i) -> void:
	for cell_variant in _persistent_by_tile.keys():
		var cell := cell_variant as Vector2i
		if cell.distance_squared_to(center) <= 2:
			(_persistent_by_tile[cell] as Sprite2D).visible = true


func _build_temporary_blocker(cells: Array, tile_size: Vector2) -> void:
	_temporary_blocker = StaticBody2D.new()
	_temporary_blocker.name = "ThreadwayResolutionBlocker"
	add_child(_temporary_blocker)
	for cell_variant in cells:
		if not cell_variant is Vector2i:
			continue
		var shape := RectangleShape2D.new()
		shape.size = tile_size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		_temporary_blocker.add_child(collision)
		collision.global_position = _tile_to_global(cell_variant as Vector2i)


func _remove_temporary_blocker() -> void:
	if _temporary_blocker == null:
		return
	_temporary_blocker.queue_free()
	_temporary_blocker = null


func _runtime_tile_size() -> Vector2:
	if _map_instance != null and _map_instance.has_method("get_runtime_tile_size"):
		return _map_instance.call("get_runtime_tile_size") as Vector2
	return SOURCE_TILE_SIZE


func _tile_to_global(cell: Vector2i) -> Vector2:
	if _map_instance != null and _map_instance.has_method("tile_to_global_position"):
		return _map_instance.call("tile_to_global_position", cell) as Vector2
	return Vector2(cell) * _runtime_tile_size() + _runtime_tile_size() * 0.5


func debug_get_persistent_tile_count() -> int:
	return _persistent_by_tile.size()


func debug_get_reveal_play_count() -> int:
	return _reveal_play_count


func debug_has_temporary_blocker() -> bool:
	return _temporary_blocker != null
