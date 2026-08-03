extends Node2D
class_name OperatorPresentationRig2D

const OPERATOR_VISUAL_NAMES := {
	"Visual": true,
	"DodgeFXBackSprite": true,
	"AnimatedSprite2D": true,
	"ModularCapeSprite": true,
	"ModularLowerBodySprite": true,
	"ModularUpperBodySprite": true,
	"ModularHeadSprite": true,
	"ModularSidearmSprite": true,
	"ModularUpperFxSprite": true,
	"MeleeWeaponOverlaySprite": true,
	"MeleeFxOverlaySprite": true,
	"PrimaryWeaponSprite": true,
	"RangedFxOverlaySprite": true,
	"OffhandPropSprite": true,
}

@onready var pose_root: Node2D = $PoseRoot
@onready var parts_root: Node2D = $PoseRoot/PartsRoot

var _source_visibility: Array[Dictionary] = []


func capture_from_operator(operator: Node) -> bool:
	clear_parts()
	if not (operator is Node2D):
		return false
	var operator_inverse := (operator as Node2D).global_transform.affine_inverse()
	for source: CanvasItem in _collect_visual_sources(operator):
		_source_visibility.append({"node": weakref(source), "visible": source.visible})
		if not source.visible:
			continue
		var clone := _clone_visual(source)
		if clone == null:
			continue
		parts_root.add_child(clone)
		clone.transform = operator_inverse * source.global_transform
	return parts_root.get_child_count() > 0


func hide_source_visuals() -> void:
	for record: Dictionary in _source_visibility:
		var source := (record.get("node") as WeakRef).get_ref() as CanvasItem
		if source != null and is_instance_valid(source):
			source.visible = false


func restore_source_visuals() -> void:
	for record: Dictionary in _source_visibility:
		var source := (record.get("node") as WeakRef).get_ref() as CanvasItem
		if source != null and is_instance_valid(source):
			source.visible = bool(record.get("visible", true))
	_source_visibility.clear()


func play_pose(pose_name: StringName) -> void:
	reset_pose()
	if pose_name != &"lift_braced":
		return
	pose_root.position = Vector2(0.0, 1.0)
	pose_root.scale = Vector2(1.0, 0.985)
	for child in parts_root.get_children():
		var part := child as Node2D
		if part == null:
			continue
		var part_name := String(part.name)
		if "Cape" in part_name:
			part.rotation -= 0.025
			part.position.y += 1.0
		elif "Weapon" in part_name or "Sidearm" in part_name:
			part.rotation += 0.015
		elif "LowerBody" in part_name:
			part.scale.y *= 0.985


func reset_pose() -> void:
	pose_root.position = Vector2.ZERO
	pose_root.rotation = 0.0
	pose_root.scale = Vector2.ONE


func clear_parts() -> void:
	restore_source_visuals()
	if not is_node_ready():
		return
	for child in parts_root.get_children():
		child.free()
	reset_pose()


func get_part_count() -> int:
	return parts_root.get_child_count() if is_node_ready() else 0


func _exit_tree() -> void:
	restore_source_visuals()


func _collect_visual_sources(operator: Node) -> Array[CanvasItem]:
	var result: Array[CanvasItem] = []
	_collect_visual_sources_recursive(operator, result)
	return result


func _collect_visual_sources_recursive(node: Node, result: Array[CanvasItem]) -> void:
	for child in node.get_children():
		if child is CollisionObject2D or child is CollisionShape2D:
			continue
		if child is CanvasItem and OPERATOR_VISUAL_NAMES.has(String(child.name)):
			result.append(child as CanvasItem)
		_collect_visual_sources_recursive(child, result)


func _clone_visual(source: CanvasItem) -> Node2D:
	var clone: Node2D
	if source is AnimatedSprite2D:
		var source_animated := source as AnimatedSprite2D
		var animated := AnimatedSprite2D.new()
		animated.sprite_frames = source_animated.sprite_frames
		animated.animation = source_animated.animation
		animated.frame = source_animated.frame
		animated.frame_progress = source_animated.frame_progress
		animated.centered = source_animated.centered
		animated.offset = source_animated.offset
		animated.flip_h = source_animated.flip_h
		animated.flip_v = source_animated.flip_v
		animated.pause()
		clone = animated
	elif source is Sprite2D:
		var source_sprite := source as Sprite2D
		var sprite := Sprite2D.new()
		sprite.texture = source_sprite.texture
		sprite.centered = source_sprite.centered
		sprite.offset = source_sprite.offset
		sprite.flip_h = source_sprite.flip_h
		sprite.flip_v = source_sprite.flip_v
		sprite.region_enabled = source_sprite.region_enabled
		sprite.region_rect = source_sprite.region_rect
		clone = sprite
	elif source is ColorRect:
		var source_rect := source as ColorRect
		var polygon := Polygon2D.new()
		polygon.polygon = PackedVector2Array([
			Vector2(source_rect.offset_left, source_rect.offset_top),
			Vector2(source_rect.offset_right, source_rect.offset_top),
			Vector2(source_rect.offset_right, source_rect.offset_bottom),
			Vector2(source_rect.offset_left, source_rect.offset_bottom),
		])
		polygon.color = source_rect.color
		clone = polygon
	else:
		return null
	clone.name = source.name
	clone.visible = true
	clone.modulate = source.modulate
	clone.self_modulate = source.self_modulate
	clone.z_as_relative = source.z_as_relative
	clone.z_index = source.z_index
	clone.texture_filter = source.texture_filter
	clone.texture_repeat = source.texture_repeat
	clone.material = source.material
	return clone
