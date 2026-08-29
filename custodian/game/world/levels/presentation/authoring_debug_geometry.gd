class_name AuthoringDebugGeometry
extends RefCounted


static func collision_shape_record(
	level: Node2D,
	collision: CollisionShape2D,
	id: String,
	group: String,
	label: String,
	details := ""
) -> Dictionary:
	if level == null or collision == null or collision.shape == null:
		return {}
	var center := level.to_local(collision.global_position)
	var scale := collision.global_transform.get_scale().abs()
	if collision.shape is RectangleShape2D:
		var size := (collision.shape as RectangleShape2D).size * scale
		return _base_record(id, group, label, "rect", details, collision).merged({
			"rect": Rect2(center - size * 0.5, size),
		})
	if collision.shape is CircleShape2D:
		return _base_record(id, group, label, "circle", details, collision).merged({
			"center": center,
			"radius": (collision.shape as CircleShape2D).radius * maxf(scale.x, scale.y),
		})
	return {}


static func point_record(
	id: String, group: String, label: String, point: Vector2,
	details := "", authority: Node = null
) -> Dictionary:
	return _base_record(id, group, label, "point", details, authority).merged({
		"point": point,
	})


static func rect_record(
	id: String, group: String, label: String, rect: Rect2,
	details := "", authority: Node = null
) -> Dictionary:
	return _base_record(id, group, label, "rect", details, authority).merged({
		"rect": rect,
	})


static func polygon_record(
	id: String, group: String, label: String, polygon: PackedVector2Array,
	details := "", authority: Node = null
) -> Dictionary:
	return _base_record(id, group, label, "polygon", details, authority).merged({
		"polygon": polygon,
	})


static func band_record(
	id: String, group: String, label: String, south_y: float, north_y: float,
	width: float, details := "", authority: Node = null
) -> Dictionary:
	var top := minf(south_y, north_y)
	var bottom := maxf(south_y, north_y)
	return _base_record(id, group, label, "band", details, authority).merged({
		"rect": Rect2(-width * 0.5, top, width, bottom - top),
		"south_y": south_y,
		"north_y": north_y,
	})


static func sprite_record(
	level: Node2D,
	sprite: Sprite2D,
	id: String,
	group: String,
	label: String,
	details := ""
) -> Dictionary:
	if level == null or sprite == null or sprite.texture == null:
		return {}
	var texture_size := sprite.texture.get_size()
	var local_rect := Rect2(-texture_size * 0.5, texture_size)
	if not sprite.centered:
		local_rect.position = Vector2.ZERO
	local_rect.position += sprite.offset
	var corners := PackedVector2Array([
		local_rect.position,
		local_rect.position + Vector2(local_rect.size.x, 0.0),
		local_rect.end,
		local_rect.position + Vector2(0.0, local_rect.size.y),
	])
	var bounds := Rect2()
	for index in corners.size():
		var level_point := level.to_local(sprite.to_global(corners[index]))
		if index == 0:
			bounds = Rect2(level_point, Vector2.ZERO)
		else:
			bounds = bounds.expand(level_point)
	return _base_record(id, group, label, "sprite_rect", details, sprite).merged({
		"rect": bounds,
		"texture_size": texture_size,
		"center": level.to_local(sprite.global_position),
		"z_index": sprite.z_index,
	})


static func _base_record(
	id: String, group: String, label: String, shape: String,
	details: String, authority: Node
) -> Dictionary:
	return {
		"id": id,
		"group": group,
		"label": label,
		"shape": shape,
		"details": details,
		"authority_path": str(authority.get_path()) if authority != null else "",
	}
