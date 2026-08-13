class_name ConstructionPlacementPreview
extends Node2D

var _definition: StructureDefinition
var _structure_preview: Node2D
var _footprint_size := Vector2.ZERO
var _valid := false
var _reason: StringName = &"outside_construction_zone"


func configure(definition: StructureDefinition) -> void:
	_definition = definition
	if _structure_preview != null:
		_structure_preview.queue_free()
	_structure_preview = null
	if definition != null and definition.placement_preview_scene != null:
		_structure_preview = definition.placement_preview_scene.instantiate() as Node2D
		if _structure_preview != null:
			_structure_preview.name = "StructurePreview"
			add_child(_structure_preview)
	queue_redraw()


func apply_snapshot(snapshot: Dictionary) -> void:
	global_position = snapshot.get("grid_origin", global_position) as Vector2
	rotation = 0.0
	_footprint_size = (snapshot.get("world_rect", Rect2()) as Rect2).size
	_valid = bool(snapshot.get("valid", false))
	_reason = StringName(str(snapshot.get("reason", "outside_construction_zone")))
	if _structure_preview != null:
		_structure_preview.position = _footprint_size * 0.5
		_structure_preview.rotation_degrees = float(snapshot.get("rotation_degrees", 0))
		_structure_preview.modulate = _preview_color()
	queue_redraw()


func _preview_color() -> Color:
	if _valid:
		return Color(0.7, 1.0, 0.96, 0.65)
	if _reason in [&"outside_construction_zone", &"unsupported_zone"]:
		return Color(1.0, 0.72, 0.28, 0.65)
	return Color(1.0, 0.3, 0.28, 0.65)


func _draw() -> void:
	if _footprint_size == Vector2.ZERO:
		return
	var color := _preview_color()
	draw_rect(Rect2(Vector2.ZERO, _footprint_size), Color(color.r, color.g, color.b, 0.16), true)
	draw_rect(Rect2(Vector2.ZERO, _footprint_size), Color(color.r, color.g, color.b, 0.9), false, 2.0)
