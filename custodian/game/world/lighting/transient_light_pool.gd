extends Node2D
class_name TransientLightPool

@export_range(1, 128, 1) var pool_size: int = 24
@export_range(0.05, 8.0, 0.01) var default_scale: float = 1.0

var _available: Array[Sprite2D] = []
var _active: Array[Sprite2D] = []
var _flash_texture: Texture2D = null
var _flash_material: CanvasItemMaterial = null


func _ready() -> void:
	_flash_texture = _create_flash_texture()
	_flash_material = CanvasItemMaterial.new()
	_flash_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for _index in range(pool_size):
		_available.append(_create_flash_sprite())


func flash_at(world_position: Vector2, color: Color, scale: float = 1.0, duration: float = 0.12) -> void:
	var sprite := _acquire_sprite()
	sprite.global_position = world_position
	sprite.modulate = color
	sprite.scale = Vector2.ONE * default_scale * scale
	sprite.visible = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, duration)
	tween.tween_property(sprite, "scale", sprite.scale * 1.35, duration)
	tween.chain().tween_callback(_release_sprite.bind(sprite))


func _acquire_sprite() -> Sprite2D:
	var sprite: Sprite2D
	if _available.is_empty():
		sprite = _active.pop_front()
	else:
		sprite = _available.pop_back()
	_active.append(sprite)
	return sprite


func _release_sprite(sprite: Sprite2D) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	sprite.visible = false
	sprite.modulate = Color.WHITE
	_active.erase(sprite)
	if not _available.has(sprite):
		_available.append(sprite)


func _create_flash_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _flash_texture
	sprite.material = _flash_material
	sprite.visible = false
	sprite.z_as_relative = false
	sprite.z_index = 90
	add_child(sprite)
	return sprite


func _create_flash_texture() -> Texture2D:
	var image := Image.create_empty(48, 48, false, Image.FORMAT_RGBA8)
	var center := Vector2(23.5, 23.5)
	for y in range(48):
		for x in range(48):
			var distance := center.distance_to(Vector2(x, y)) / 23.5
			var alpha := clampf(1.0 - distance, 0.0, 1.0)
			alpha = pow(alpha, 2.4)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)
