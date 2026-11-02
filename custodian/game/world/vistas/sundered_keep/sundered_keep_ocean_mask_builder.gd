@tool
extends RefCounted
class_name SunderedKeepOceanMaskBuilder


static func build(
	floor_cells: Dictionary,
	ocean_cells: Dictionary,
	map_size: Vector2i,
	world_origin: Vector2,
	world_cell_size: Vector2,
	grid_origin: Vector2i = Vector2i.ZERO
) -> Dictionary:
	if map_size.x <= 0 or map_size.y <= 0:
		return {}
	var image := Image.create(map_size.x, map_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for cell_variant in ocean_cells.keys():
		if not cell_variant is Vector2i:
			continue
		var cell := cell_variant as Vector2i
		if floor_cells.has(cell):
			continue
		var pixel := cell - grid_origin
		if pixel.x >= 0 and pixel.y >= 0 and pixel.x < map_size.x and pixel.y < map_size.y:
			image.set_pixel(pixel.x, pixel.y, Color.WHITE)
	return {
		"image": image,
		"texture": ImageTexture.create_from_image(image),
		"mask_world_origin": world_origin,
		"mask_world_size": Vector2(map_size) * world_cell_size,
		"mask_grid_size": Vector2(map_size),
	}


static func apply_to_sprite(sprite: Sprite2D, mask: Dictionary) -> bool:
	if sprite == null or not sprite.material is ShaderMaterial or mask.is_empty():
		return false
	var material := sprite.material as ShaderMaterial
	material.set_shader_parameter("ocean_mask", mask.get("texture"))
	material.set_shader_parameter("mask_world_origin", mask.get("mask_world_origin", Vector2.ZERO))
	material.set_shader_parameter("mask_world_size", mask.get("mask_world_size", Vector2.ZERO))
	material.set_shader_parameter("mask_grid_size", mask.get("mask_grid_size", Vector2.ZERO))
	material.set_shader_parameter("mask_enabled", true)
	return true
