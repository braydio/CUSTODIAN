class_name ConstructionZone2D
extends Node2D

@export var zone_id: StringName
@export var size := Vector2(384.0, 320.0):
	set(value):
		size = Vector2(maxf(0.0, value.x), maxf(0.0, value.y))
		queue_redraw()
@export var site_tags: Array[StringName] = []
@export var allowed_categories: Array[StringName] = []
@export var enabled := true

var placement_presentation_visible := false:
	set(value):
		placement_presentation_visible = value
		queue_redraw()


func _ready() -> void:
	add_to_group("construction_zone")
	queue_redraw()


func get_world_rect() -> Rect2:
	return Rect2(global_position - size * 0.5, size)


func contains_world_rect(world_rect: Rect2) -> bool:
	var zone_rect := get_world_rect()
	return enabled \
		and zone_rect.has_point(world_rect.position) \
		and zone_rect.has_point(world_rect.end - Vector2(0.001, 0.001))


func supports_definition(definition: StructureDefinition) -> bool:
	if not enabled or definition == null:
		return false
	if not allowed_categories.is_empty() and not allowed_categories.has(definition.category):
		return false
	for required_tag in definition.required_site_tags:
		if not site_tags.has(required_tag):
			return false
	return true


func set_placement_presentation_visible(value: bool) -> void:
	placement_presentation_visible = value


func _draw() -> void:
	if not placement_presentation_visible:
		return
	var local_rect := Rect2(-size * 0.5, size)
	draw_rect(local_rect, Color(0.18, 0.82, 0.88, 0.035), true)
	draw_rect(local_rect, Color(0.28, 0.9, 0.94, 0.24), false, 2.0)
