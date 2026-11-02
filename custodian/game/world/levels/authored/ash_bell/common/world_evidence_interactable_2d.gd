class_name WorldEvidenceInteractable2D
extends Area2D

signal evidence_recovered(evidence_id: StringName)

@export var evidence_id: StringName
@export var prompt_text := "READ RECORD"
@export var title := ""
@export_multiline var body_text := ""
@export var interaction_distance := 72.0
@export var one_shot_recovery := true

var recovered := false
var _actionable := true


func _ready() -> void:
	add_to_group("interactable")
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 22.0
		collision.shape = shape
		add_child(collision)
	queue_redraw()


func get_interaction_prompt() -> String:
	return prompt_text


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_distance


func can_interact(_actor: Node = null) -> bool:
	return _actionable


func interact(_actor: Node) -> void:
	_show_evidence()
	if not recovered or not one_shot_recovery:
		recovered = true
		evidence_recovered.emit(evidence_id)
	queue_redraw()


func set_recovered(value: bool) -> void:
	recovered = value
	queue_redraw()


func set_actionable(value: bool) -> void:
	_actionable = value
	queue_redraw()


func _show_evidence() -> void:
	var overlay := get_tree().get_first_node_in_group("world_evidence_overlay") as CanvasLayer
	if overlay != null and overlay.visible:
		overlay.visible = false
		return
	if overlay == null:
		overlay = CanvasLayer.new()
		overlay.name = "WorldEvidenceOverlay"
		overlay.add_to_group("world_evidence_overlay")
		var panel := ColorRect.new()
		panel.name = "Panel"
		panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE, 0)
		panel.position = Vector2(-280, -170)
		panel.size = Vector2(560, 340)
		panel.color = Color(0.025, 0.035, 0.04, 0.96)
		var label := Label.new()
		label.name = "Text"
		label.position = Vector2(28, 24)
		label.size = Vector2(504, 292)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(label)
		overlay.add_child(panel)
		get_tree().root.add_child(overlay)
	var label := overlay.get_node("Panel/Text") as Label
	label.text = "%s\n\n%s\n\n[INTERACT / CANCEL TO CLOSE]" % [title, body_text]
	overlay.visible = true


func _draw() -> void:
	draw_rect(Rect2(-14, -18, 28, 36), Color("73868a") if recovered else Color("c0a45c"), false, 3.0)
