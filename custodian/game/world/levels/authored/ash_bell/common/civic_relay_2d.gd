class_name CivicRelay2D
extends Area2D

signal repaired_changed(relay_id: StringName, repaired: bool)

@export var relay_id: StringName = &""
@export var prompt_text := "REPAIR CIVIC RELAY"
@export var interaction_distance := 64.0

var repaired := false
var _actionable := true


func _ready() -> void:
	add_to_group("interactable")
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = 24.0
		collision.shape = shape
		add_child(collision)
	queue_redraw()


func get_interaction_prompt() -> String:
	return prompt_text if can_interact() else ""


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func can_interact(_actor: Node = null) -> bool:
	return _actionable and not repaired


func interact(actor: Node) -> void:
	if can_interact(actor):
		set_repaired(true)


func set_repaired(value: bool, emit_signal := true) -> void:
	if repaired == value:
		return
	repaired = value
	queue_redraw()
	if emit_signal:
		repaired_changed.emit(relay_id, repaired)


func set_actionable(value: bool) -> void:
	_actionable = value
	queue_redraw()


func is_actionable() -> bool:
	return _actionable and not repaired


func _draw() -> void:
	var body_color := Color("b6c9ce") if repaired else Color("b57b31")
	if not _actionable and not repaired:
		body_color = Color("4c5358")
	draw_rect(Rect2(-18, -24, 36, 48), Color("20262b"), true)
	draw_rect(Rect2(-14, -20, 28, 40), body_color, false, 4.0)
	draw_circle(Vector2(0, -8), 5.0, body_color)
