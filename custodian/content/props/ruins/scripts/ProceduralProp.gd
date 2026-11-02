@tool
extends Node2D
class_name ProceduralProp

enum VariantIntensity {
	ORIGINAL,
	SUBTLE,
	DRAMATIC,
	RETURNED
}

const PALETTE_SHADER := preload("res://content/props/ruins/shaders/prop_palette_variation.gdshader")

@export var definition: PropDefinition
@export var variant_seed: int = 0
@export var variant_intensity: VariantIntensity = VariantIntensity.SUBTLE
@export var generate_on_ready: bool = true
@export var force_collision_debug: bool = false
@export var regenerate_in_editor: bool = false:
	set(value):
		if not value:
			regenerate_in_editor = false
			return

		regenerate_in_editor = false
		if Engine.is_editor_hint():
			generate_variant()

@export var randomize_seed_in_editor: bool = false:
	set(value):
		if not value:
			randomize_seed_in_editor = false
			return

		randomize_seed_in_editor = false
		if Engine.is_editor_hint():
			variant_seed = randi()
			generate_variant()

@onready var visual_root: Node2D = $VisualRoot
@onready var base_sprite: Sprite2D = $VisualRoot/BaseSprite
@onready var overlay_root: Node2D = $VisualRoot/OverlayRoot
@onready var rubble_root: Node2D = $VisualRoot/RubbleRoot
@onready var collision_root: Node2D = $CollisionRoot
@onready var collision_debug_root: Node2D = $CollisionDebugRoot

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_as_relative = true
	if generate_on_ready:
		generate_variant()


func generate_variant() -> void:
	if not _has_required_nodes():
		push_warning("ProceduralProp scene is missing one or more required child nodes.")
		return

	_clear_children(overlay_root)
	_clear_children(rubble_root)
	_clear_children(collision_root)
	_clear_children(collision_debug_root)

	if definition == null:
		push_warning("ProceduralProp has no PropDefinition assigned.")
		base_sprite.texture = null
		base_sprite.material = null
		collision_debug_root.visible = false
		return

	if definition.base_texture == null:
		push_warning("PropDefinition '%s' has no base texture assigned." % str(definition.id))

	_rng.seed = _resolve_seed()

	_setup_base_sprite()
	_spawn_collision()
	_rebuild_collision_debug()

	if variant_intensity == VariantIntensity.ORIGINAL:
		base_sprite.material = null
		return

	_apply_material_variation()
	_spawn_overlays()
	_spawn_rubble()


func _resolve_seed() -> int:
	if variant_seed != 0:
		return variant_seed

	return PropVariantGenerator.seed_from_position(definition.id, global_position)


func _setup_base_sprite() -> void:
	base_sprite.texture = definition.base_texture
	base_sprite.position = -definition.anchor_offset
	base_sprite.centered = true
	base_sprite.visible = not definition.use_portal_state_sprite
	base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if definition.allow_flip_h and variant_intensity != VariantIntensity.ORIGINAL:
		base_sprite.flip_h = _rng.randf() < 0.5
	else:
		base_sprite.flip_h = false


func _apply_material_variation() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = PALETTE_SHADER

	var brightness_range := _get_brightness_range()
	var saturation_range := _get_saturation_range()
	var hue_shift_range := _get_hue_shift_range()

	mat.set_shader_parameter(
		"brightness",
		_rng.randf_range(brightness_range.x, brightness_range.y)
	)
	mat.set_shader_parameter(
		"saturation",
		_rng.randf_range(saturation_range.x, saturation_range.y)
	)
	mat.set_shader_parameter(
		"hue_shift",
		_rng.randf_range(hue_shift_range.x, hue_shift_range.y)
	)

	base_sprite.material = mat


func _spawn_overlays() -> void:
	if definition.variant_layers.is_empty():
		_spawn_legacy_overlays()
		return

	var eligible_layers: Array[PropVariantLayer] = []
	for layer in definition.variant_layers:
		if layer == null or layer.texture == null:
			continue
		if layer.layer_type == PropVariantLayer.LayerType.RUBBLE:
			continue
		if _rng.randf() <= layer.spawn_chance:
			eligible_layers.append(layer)

	var count: int = min(_get_overlay_count(), eligible_layers.size())
	for i in count:
		var layer_index := _rng.randi_range(0, eligible_layers.size() - 1)
		var layer := eligible_layers[layer_index]
		eligible_layers.remove_at(layer_index)
		_add_overlay_sprite(
			layer.texture,
			_pick_layer_spawn_rect(layer),
			layer.allow_flip_h,
			layer.alpha_min,
			layer.alpha_max,
			layer.z_index
		)


func _spawn_legacy_overlays() -> void:
	var available: Array[Texture2D] = []
	available.append_array(definition.moss_overlays)
	available.append_array(definition.crack_overlays)
	available.append_array(definition.chip_overlays)
	available.append_array(definition.dirt_overlays)

	available = available.filter(func(texture: Texture2D) -> bool: return texture != null)
	if available.is_empty():
		return

	var count: int = min(_get_overlay_count(), available.size())
	for i in count:
		var tex: Texture2D = available[_rng.randi_range(0, available.size() - 1)]
		_add_overlay_sprite(
			tex,
			definition.overlay_spawn_rect,
			definition.allow_overlay_flip_h,
			0.70,
			1.0,
			1
		)


func _spawn_rubble() -> void:
	var count := _get_rubble_count()
	if count <= 0:
		return

	var rubble_layers: Array[PropVariantLayer] = []
	for layer in definition.variant_layers:
		if layer == null or layer.texture == null:
			continue
		if layer.layer_type == PropVariantLayer.LayerType.RUBBLE and _rng.randf() <= layer.spawn_chance:
			rubble_layers.append(layer)

	if not rubble_layers.is_empty():
		for i in min(count, rubble_layers.size()):
			var layer := rubble_layers[_rng.randi_range(0, rubble_layers.size() - 1)]
			_add_rubble_sprite(
				layer.texture,
				_pick_layer_spawn_rect(layer),
				layer.allow_flip_h,
				layer.alpha_min,
				layer.alpha_max,
				layer.z_index
			)
		return

	if definition.rubble_textures.is_empty():
		return

	var available: Array[Texture2D] = definition.rubble_textures.filter(func(texture: Texture2D) -> bool: return texture != null)
	if available.is_empty():
		return

	for i in count:
		var tex: Texture2D = available[_rng.randi_range(0, available.size() - 1)]
		_add_rubble_sprite(tex, definition.rubble_spawn_rect, true, 1.0, 1.0, 1)


func _spawn_collision() -> void:
	if definition.collision_scene == null:
		if definition.collision_shape_size.x <= 0.0 or definition.collision_shape_size.y <= 0.0:
			return
		var body := StaticBody2D.new()
		body.name = "CollisionBody"
		body.collision_layer = 1
		body.collision_mask = 1
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = definition.collision_shape_size
		shape.shape = rectangle
		shape.position = definition.collision_shape_offset
		shape.rotation_degrees = definition.collision_shape_rotation_degrees
		body.add_child(shape)
		collision_root.add_child(body)
		return

	var collision_instance := definition.collision_scene.instantiate()
	collision_root.add_child(collision_instance)


func _rebuild_collision_debug() -> void:
	_clear_children(collision_debug_root)
	collision_debug_root.visible = definition != null and (definition.show_collision_debug or force_collision_debug)

	if not collision_debug_root.visible:
		return

	collision_debug_root.z_index = definition.collision_debug_z_index
	collision_debug_root.z_as_relative = true

	for child in collision_root.get_children():
		_add_collision_debug_for_node(child, Transform2D.IDENTITY)


func get_visual_rect_root_local() -> Rect2:
	if definition == null or definition.base_texture == null:
		return Rect2()
	var texture_size := Vector2(definition.base_texture.get_size())
	return Rect2(-definition.anchor_offset - texture_size * 0.5, texture_size)


func get_collision_rect_root_local() -> Rect2:
	var points := PackedVector2Array()
	if collision_root != null:
		for child in collision_root.get_children():
			_append_collision_points(child, collision_root.transform, points)
	elif definition != null and definition.collision_scene == null \
			and definition.collision_shape_size.x > 0.0 and definition.collision_shape_size.y > 0.0:
		var shape_transform := Transform2D(
			deg_to_rad(definition.collision_shape_rotation_degrees),
			definition.collision_shape_offset
		)
		_append_rectangle_points(definition.collision_shape_size, shape_transform, points)
	return _rect_from_points(points)


func get_collision_rect_global() -> Rect2:
	var local_rect := get_collision_rect_root_local()
	if local_rect.size == Vector2.ZERO:
		return Rect2()
	var points := PackedVector2Array()
	for corner in _rect_corners(local_rect):
		points.append(global_transform * corner)
	return _rect_from_points(points)


func get_collision_alignment_report() -> Dictionary:
	var visual_rect := get_visual_rect_root_local()
	var collision_rect := get_collision_rect_root_local()
	var texture_size := Vector2.ZERO
	if definition != null and definition.base_texture != null:
		texture_size = Vector2(definition.base_texture.get_size())
	var has_collision := collision_rect.size.x > 0.0 and collision_rect.size.y > 0.0
	var collision_bottom_y := collision_rect.end.y if has_collision else 0.0
	var outside_visual := has_collision and visual_rect.size != Vector2.ZERO \
		and not visual_rect.grow(4.0).encloses(collision_rect)
	var allows_below_anchor := definition != null and definition.collision_allows_below_anchor
	var likely_below_anchor := has_collision and collision_bottom_y > 4.0 and not allows_below_anchor
	var suspicious_positive_y := definition != null and definition.collision_shape_size != Vector2.ZERO \
		and definition.collision_shape_offset.y > 4.0
	return {
		"definition_id": str(definition.id) if definition != null else "",
		"texture_size": texture_size,
		"anchor_offset": definition.anchor_offset if definition != null else Vector2.ZERO,
		"visual_rect_root_local": visual_rect,
		"collision_size": definition.collision_shape_size if definition != null else Vector2.ZERO,
		"collision_offset": definition.collision_shape_offset if definition != null else Vector2.ZERO,
		"collision_rect_root_local": collision_rect,
		"collision_rect_global": get_collision_rect_global(),
		"collision_bottom_y": collision_bottom_y,
		"collision_outside_visual_bounds": outside_visual,
		"likely_below_anchor": likely_below_anchor,
		"suspicious_positive_y": suspicious_positive_y,
		"collision_allows_below_anchor": allows_below_anchor,
		"missing_base_texture": definition == null or definition.base_texture == null,
		"has_collision": has_collision,
	}


func _append_collision_points(node: Node, parent_transform: Transform2D, points: PackedVector2Array) -> void:
	var local_transform := parent_transform
	if node is Node2D:
		local_transform = parent_transform * (node as Node2D).transform
	if node is CollisionShape2D:
		var collision_shape := node as CollisionShape2D
		if not collision_shape.disabled and collision_shape.shape is RectangleShape2D:
			_append_rectangle_points((collision_shape.shape as RectangleShape2D).size, local_transform, points)
	for child in node.get_children():
		_append_collision_points(child, local_transform, points)


func _append_rectangle_points(size: Vector2, shape_transform: Transform2D, points: PackedVector2Array) -> void:
	var half_size := size * 0.5
	for corner in [
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	]:
		points.append(shape_transform * corner)


func _rect_corners(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])


func _rect_from_points(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var result := Rect2(points[0], Vector2.ZERO)
	for point in points:
		result = result.expand(point)
	return result


func _add_collision_debug_for_node(node: Node, parent_transform: Transform2D) -> void:
	var local_transform := parent_transform

	if node is Node2D:
		local_transform = parent_transform * (node as Node2D).transform

	if node is CollisionShape2D:
		_add_collision_shape_debug(node as CollisionShape2D, local_transform)

	for child in node.get_children():
		_add_collision_debug_for_node(child, local_transform)


func _add_collision_shape_debug(collision_shape: CollisionShape2D, local_transform: Transform2D) -> void:
	if collision_shape.disabled:
		return

	var rectangle := collision_shape.shape as RectangleShape2D

	if rectangle == null:
		return

	var half_size := rectangle.size * 0.5
	var points := PackedVector2Array([
		local_transform * Vector2(-half_size.x, -half_size.y),
		local_transform * Vector2(half_size.x, -half_size.y),
		local_transform * Vector2(half_size.x, half_size.y),
		local_transform * Vector2(-half_size.x, half_size.y),
	])

	var polygon := Polygon2D.new()
	polygon.name = collision_shape.name + "DebugFill"
	polygon.polygon = points
	polygon.color = definition.collision_debug_color
	collision_debug_root.add_child(polygon)

	var outline := Line2D.new()
	outline.name = collision_shape.name + "DebugOutline"
	outline.points = PackedVector2Array([
		points[0],
		points[1],
		points[2],
		points[3],
		points[0],
	])
	outline.width = 1.5
	outline.default_color = definition.collision_debug_outline_color
	outline.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	collision_debug_root.add_child(outline)


func apply_depth_sort(player_feet_y: float) -> void:
	if definition == null or not definition.depth_sort_enabled:
		return
	var base_y := global_position.y + definition.depth_sort_base_y_offset
	z_as_relative = false
	z_index = definition.depth_sort_behind_z_index if player_feet_y > base_y else definition.depth_sort_front_z_index


func resolve_depth_sort_z_index(player_feet_y: float) -> int:
	if definition == null:
		return 0
	if not definition.depth_sort_enabled:
		return z_index
	if definition.portal_platform_enabled:
		var platform_horizon_y := global_position.y + definition.portal_platform_top_offset.y
		return definition.depth_sort_front_z_index if player_feet_y <= platform_horizon_y else definition.depth_sort_behind_z_index
	var base_y := global_position.y + definition.depth_sort_base_y_offset
	return definition.depth_sort_behind_z_index if player_feet_y > base_y else definition.depth_sort_front_z_index


func get_occlusion_bounds() -> Rect2:
	if definition == null:
		return Rect2()
	var size := definition.occlusion_bounds_size
	if size.x <= 0.0 or size.y <= 0.0:
		if definition.collision_shape_size.x > 0.0 and definition.collision_shape_size.y > 0.0:
			size = definition.collision_shape_size
		else:
			return Rect2()
	var offset := definition.occlusion_bounds_offset
	if offset == Vector2.ZERO and definition.collision_shape_size.x > 0.0 and definition.collision_shape_size.y > 0.0:
		offset = definition.collision_shape_offset
	return Rect2(global_position + offset - size * 0.5, size)


func _add_overlay_sprite(
	texture: Texture2D,
	spawn_rect: Rect2,
	allow_flip_h: bool,
	alpha_min: float,
	alpha_max: float,
	z_index: int
) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.position = _random_point_in_rect(spawn_rect)
	sprite.flip_h = allow_flip_h and _rng.randf() < 0.5
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate.a = _rng.randf_range(alpha_min, alpha_max)
	sprite.z_index = z_index
	overlay_root.add_child(sprite)


func _add_rubble_sprite(
	texture: Texture2D,
	spawn_rect: Rect2,
	allow_flip_h: bool,
	alpha_min: float,
	alpha_max: float,
	z_index: int
) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.position = _random_point_in_rect(spawn_rect)
	sprite.flip_h = allow_flip_h and _rng.randf() < 0.5
	sprite.rotation = 0.0
	sprite.scale = Vector2.ONE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate.a = _rng.randf_range(alpha_min, alpha_max)
	sprite.z_index = z_index
	rubble_root.add_child(sprite)


func _get_overlay_count() -> int:
	match variant_intensity:
		VariantIntensity.ORIGINAL:
			return 0
		VariantIntensity.SUBTLE:
			return _rng.randi_range(1, 2)
		VariantIntensity.DRAMATIC:
			return _rng.randi_range(3, 5)
		VariantIntensity.RETURNED:
			return _rng.randi_range(1, 3)
		_:
			return _rng.randi_range(definition.min_overlay_count, definition.max_overlay_count)


func _get_rubble_count() -> int:
	match variant_intensity:
		VariantIntensity.ORIGINAL:
			return 0
		VariantIntensity.SUBTLE:
			return min(_rng.randi_range(definition.min_rubble_count, definition.max_rubble_count), 2)
		VariantIntensity.DRAMATIC:
			return max(_rng.randi_range(definition.min_rubble_count, definition.max_rubble_count), 3)
		VariantIntensity.RETURNED:
			return min(_rng.randi_range(definition.min_rubble_count, definition.max_rubble_count), 3)
		_:
			return _rng.randi_range(definition.min_rubble_count, definition.max_rubble_count)


func _get_brightness_range() -> Vector2:
	match variant_intensity:
		VariantIntensity.SUBTLE:
			return _intersect_range(definition.brightness_min, definition.brightness_max, 0.94, 1.06)
		VariantIntensity.DRAMATIC:
			return _intersect_range(definition.brightness_min, definition.brightness_max, 0.78, 1.22)
		VariantIntensity.RETURNED:
			return _intersect_range(definition.brightness_min, definition.brightness_max, 0.96, 1.08)
		_:
			return Vector2(1.0, 1.0)


func _get_saturation_range() -> Vector2:
	match variant_intensity:
		VariantIntensity.SUBTLE:
			return _intersect_range(definition.saturation_min, definition.saturation_max, 0.92, 1.06)
		VariantIntensity.DRAMATIC:
			return _intersect_range(definition.saturation_min, definition.saturation_max, 0.75, 1.20)
		VariantIntensity.RETURNED:
			return _intersect_range(definition.saturation_min, definition.saturation_max, 0.94, 1.08)
		_:
			return Vector2(1.0, 1.0)


func _get_hue_shift_range() -> Vector2:
	match variant_intensity:
		VariantIntensity.SUBTLE:
			return _intersect_range(definition.hue_shift_min, definition.hue_shift_max, -0.01, 0.01)
		VariantIntensity.DRAMATIC:
			return _intersect_range(definition.hue_shift_min, definition.hue_shift_max, -0.02, 0.02)
		VariantIntensity.RETURNED:
			return _intersect_range(definition.hue_shift_min, definition.hue_shift_max, -0.008, 0.008)
		_:
			return Vector2(0.0, 0.0)


func _intersect_range(definition_min: float, definition_max: float, intensity_min: float, intensity_max: float) -> Vector2:
	var range_min: float = max(min(definition_min, definition_max), intensity_min)
	var range_max: float = min(max(definition_min, definition_max), intensity_max)
	if range_min > range_max:
		return Vector2(intensity_min, intensity_max)

	return Vector2(range_min, range_max)


func _pick_layer_spawn_rect(layer: PropVariantLayer) -> Rect2:
	if layer.spawn_rect.size == Vector2.ZERO:
		if layer.layer_type == PropVariantLayer.LayerType.RUBBLE:
			return definition.rubble_spawn_rect

		return definition.overlay_spawn_rect

	return layer.spawn_rect


func _random_point_in_rect(rect: Rect2) -> Vector2:
	return Vector2(
		_rng.randf_range(rect.position.x, rect.position.x + rect.size.x),
		_rng.randf_range(rect.position.y, rect.position.y + rect.size.y)
	).round()


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		if Engine.is_editor_hint():
			child.free()
		else:
			child.queue_free()


func _has_required_nodes() -> bool:
	return (
		visual_root != null
		and base_sprite != null
		and overlay_root != null
		and rubble_root != null
		and collision_root != null
		and collision_debug_root != null
	)
