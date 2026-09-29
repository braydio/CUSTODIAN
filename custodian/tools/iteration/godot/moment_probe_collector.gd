extends RefCounted
class_name MomentProbeCollector

const VALUE_READER := preload("res://tools/iteration/godot/moment_value_reader.gd")

var definitions: Array = []
var roles: Dictionary = {}
var records: Array[Dictionary] = []
var failures: Array[String] = []


func configure(items: Array, role_map: Dictionary) -> void:
	definitions = items
	roles = role_map


func sample_tick(tick: int) -> void:
	for definition: Dictionary in definitions:
		if not _should_sample(definition, tick):
			continue
		var role_name := str(definition.get("role", ""))
		var node := roles.get(role_name) as Node
		if node == null or not is_instance_valid(node):
			if bool(definition.get("required", false)):
				failures.append("required probe role unavailable: %s" % role_name)
			continue
		var values := {}
		var snapshot: Variant = null
		if str(definition.get("snapshot", "")) == "debug":
			if not node.has_method("get_debug_snapshot"):
				if bool(definition.get("required", false)):
					failures.append("required debug snapshot unavailable: %s" % role_name)
				continue
			snapshot = node.call("get_debug_snapshot")
		for field: String in definition.get("fields", []):
			var value: Variant = VALUE_READER.dotted(snapshot, field) if snapshot != null else _read_field(node, field)
			if value == null and bool(definition.get("required", false)):
				failures.append("required probe field unavailable: %s.%s" % [role_name, field])
			else:
				values[field] = _json_value(value)
		records.append({
			"id": str(definition.get("id", "")),
			"role": role_name,
			"tick": tick,
			"values": values,
		})


func _should_sample(definition: Dictionary, tick: int) -> bool:
	if definition.has("ticks"):
		for raw: Variant in definition.ticks:
			if int(raw) == tick:
				return true
		return false
	var start := int(definition.get("start_tick", 0))
	var finish := int(definition.get("end_tick", 2147483647))
	var every := int(definition.get("every_ticks", 1))
	return tick >= start and tick <= finish and (tick - start) % every == 0


func _read_field(node: Node, field: String) -> Variant:
	match field:
		"visible_visual_anchor_delta_px":
			return _visible_visual_anchor_delta_px(node)
		"visible_visual_anchor_nodes":
			return _visible_visual_anchor_nodes(node)
		"global_position":
			return node.global_position if node is Node2D else null
		"position":
			return node.position if node is Node2D else null
		"animation":
			var sprite := _animated_sprite(node)
			return str(sprite.animation) if sprite != null else null
		"frame":
			var sprite := _animated_sprite(node)
			return sprite.frame if sprite != null else null
		"frame_progress":
			var sprite := _animated_sprite(node)
			return sprite.frame_progress if sprite != null else null
		"texture_size":
			return _texture_size(node)
		"visible":
			return node.visible if node is CanvasItem else null
		"effective_visible":
			return _effective_visible(node)
		"modulate":
			return _color_array(node.modulate) if node is CanvasItem else null
		"self_modulate":
			return _color_array(node.self_modulate) if node is CanvasItem else null
		"effective_alpha":
			return _effective_alpha(node)
		"z_index":
			return node.z_index if node is CanvasItem else null
		"z_as_relative":
			return node.z_as_relative if node is CanvasItem else null
		"effective_z_index":
			return _effective_z_index(node)
		"global_bounds":
			return _global_bounds(node)
		"screen_bounds":
			return _screen_bounds(node)
		"collision_shape_count":
			return _count_collision_shapes(node)
		"navigation_node_count":
			return _count_navigation_nodes(node)
		_:
			return node.get(field)


func _animated_sprite(node: Node) -> AnimatedSprite2D:
	if node is AnimatedSprite2D:
		return node
	var sprite := node.find_child("*AnimatedSprite2D*", true, false)
	return sprite as AnimatedSprite2D


func _color_array(color: Color) -> Array:
	return [color.r, color.g, color.b, color.a]


func _texture_size(node: Node) -> Variant:
	if node is Sprite2D and node.texture != null:
		var size: Vector2 = node.texture.get_size()
		return [size.x, size.y]
	var sprite := _animated_sprite(node)
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(sprite.animation):
		var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if texture != null:
			var size: Vector2 = texture.get_size()
			return [size.x, size.y]
	return null


func _local_presentation_rect(node: Node) -> Variant:
	if node is Sprite2D:
		return (node as Sprite2D).get_rect()
	var sprite := _animated_sprite(node)
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(sprite.animation):
		var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if texture == null:
			return null
		var size: Vector2 = texture.get_size()
		var origin: Vector2 = (-size / 2.0) if sprite.centered else Vector2.ZERO
		origin += sprite.offset
		return Rect2(origin, size)
	return null


func _effective_visible(node: Node) -> Variant:
	if not node is CanvasItem:
		return null
	var cursor: Node = node
	while cursor is CanvasItem:
		if not (cursor as CanvasItem).visible:
			return false
		cursor = cursor.get_parent()
	return true


func _effective_alpha(node: Node) -> Variant:
	if not node is CanvasItem:
		return null
	var alpha: float = (node as CanvasItem).self_modulate.a
	var cursor: Node = node
	while cursor is CanvasItem:
		alpha *= (cursor as CanvasItem).modulate.a
		cursor = cursor.get_parent()
	return alpha


func _effective_z_index(node: Node) -> Variant:
	if not node is CanvasItem:
		return null
	var total := 0
	var cursor: Node = node
	while cursor is CanvasItem:
		var item: CanvasItem = cursor
		total += item.z_index
		if not item.z_as_relative:
			break
		cursor = cursor.get_parent()
	return total


func _global_bounds(node: Node) -> Variant:
	if not node is Node2D:
		return null
	var rect: Variant = _local_presentation_rect(node)
	if rect == null:
		return null
	var local_rect: Rect2 = rect
	var xform: Transform2D = (node as Node2D).get_global_transform()
	return _transformed_bounds(xform, local_rect)


func _screen_bounds(node: Node) -> Variant:
	if not node is Node2D:
		return null
	var viewport := node.get_viewport()
	if viewport == null:
		return null
	var rect: Variant = _local_presentation_rect(node)
	if rect == null:
		return null
	var local_rect: Rect2 = rect
	var xform: Transform2D = viewport.get_canvas_transform() * (node as Node2D).get_global_transform()
	return _transformed_bounds(xform, local_rect)


func _transformed_bounds(xform: Transform2D, rect: Rect2) -> Array:
	var corners := [
		xform * rect.position,
		xform * (rect.position + Vector2(rect.size.x, 0.0)),
		xform * (rect.position + Vector2(0.0, rect.size.y)),
		xform * (rect.position + rect.size),
	]
	var min_point: Vector2 = corners[0]
	var max_point: Vector2 = corners[0]
	for corner: Vector2 in corners:
		min_point = min_point.min(corner)
		max_point = max_point.max(corner)
	return [min_point.x, min_point.y, max_point.x - min_point.x, max_point.y - min_point.y]


func _count_collision_shapes(node: Node) -> int:
	var count := 0
	for found: Node in node.find_children("*", "CollisionShape2D", true, false):
		if not (found as CollisionShape2D).disabled:
			count += 1
	for found: Node in node.find_children("*", "CollisionPolygon2D", true, false):
		if not (found as CollisionPolygon2D).disabled:
			count += 1
	return count


func _count_navigation_nodes(node: Node) -> int:
	var count := 0
	for type_name in ["NavigationRegion2D", "NavigationAgent2D", "NavigationObstacle2D"]:
		count += node.find_children("*", type_name, true, false).size()
	return count


func _visible_visual_anchor_delta_px(node: Node) -> Variant:
	var sprites := _operator_visual_sprites(node)
	if sprites.is_empty():
		return null
	var canonical := Vector2(0.0, -18.0)
	var maximum_delta := 0.0
	var visible_count := 0
	for sprite: AnimatedSprite2D in sprites:
		if not sprite.visible:
			continue
		visible_count += 1
		maximum_delta = maxf(
			maximum_delta,
			maxf(
				sprite.position.distance_to(canonical),
				sprite.offset.length()
			)
		)
	return maximum_delta if visible_count > 0 else null


func _visible_visual_anchor_nodes(node: Node) -> Array[String]:
	var names: Array[String] = []
	for sprite: AnimatedSprite2D in _operator_visual_sprites(node):
		if sprite.visible:
			names.append(str(sprite.name))
	return names


func _operator_visual_sprites(node: Node) -> Array[AnimatedSprite2D]:
	var sprites: Array[AnimatedSprite2D] = []
	for child_name: String in [
		"AnimatedSprite2D",
		"DodgeFXBackSprite",
		"ModularCapeSprite",
		"ModularLowerBodySprite",
		"ModularUpperBodySprite",
		"ModularHeadSprite",
		"ModularSidearmSprite",
		"ModularUpperFxSprite",
		"MeleeWeaponOverlaySprite",
		"MeleeFxOverlaySprite",
	]:
		var sprite := node.get_node_or_null(child_name) as AnimatedSprite2D
		if sprite != null:
			sprites.append(sprite)
	return sprites


func _json_value(value: Variant) -> Variant:
	if value is Vector2:
		return [value.x, value.y]
	if value is Vector2i:
		return [value.x, value.y]
	if value is StringName:
		return str(value)
	if value is Dictionary:
		var output := {}
		for key in value:
			output[str(key)] = _json_value(value[key])
		return output
	if value is Array:
		var output := []
		for item in value:
			output.append(_json_value(item))
		return output
	return value
