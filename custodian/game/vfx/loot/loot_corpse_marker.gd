class_name LootCorpseMarker
extends Node2D

signal reveal_finished
signal collection_finished

@onready var reveal: AnimatedSprite2D = $Reveal
@onready var beam_lower: AnimatedSprite2D = $BeamLower
@onready var beam_tip: AnimatedSprite2D = $BeamTip
@onready var ground_ring: AnimatedSprite2D = $GroundRing
@onready var collect_collapse: AnimatedSprite2D = $CollectCollapse

const BEAM_TIP_BASE_POSITION := Vector2(0.0, -136.0)

var _collecting := false


func activate(presentation: Dictionary = {}) -> void:
	_collecting = false
	visible = true
	_apply_presentation(presentation)
	beam_lower.visible = false
	beam_tip.visible = false
	ground_ring.visible = false
	collect_collapse.visible = false
	reveal.visible = true
	reveal.play(&"reveal")
	await reveal.animation_finished
	if _collecting or not is_inside_tree():
		return
	reveal.visible = false
	beam_lower.visible = true
	beam_tip.visible = true
	ground_ring.visible = true
	beam_lower.play(&"beacon_lower_loop")
	beam_tip.play(&"beacon_tip_loop")
	ground_ring.play(&"ground_ring_loop")
	reveal_finished.emit()


func collect() -> void:
	if _collecting:
		return
	_collecting = true
	reveal.stop()
	beam_lower.stop()
	beam_tip.stop()
	ground_ring.stop()
	reveal.visible = false
	beam_lower.visible = false
	beam_tip.visible = false
	ground_ring.visible = false
	collect_collapse.visible = true
	collect_collapse.play(&"collect_collapse")
	await collect_collapse.animation_finished
	collection_finished.emit()
	queue_free()


func set_category(category: StringName) -> void:
	_apply_presentation({"category": category})


func _apply_presentation(presentation: Dictionary) -> void:
	var category := StringName(presentation.get("category", &"common_salvage"))
	var color := Color(1.0, 0.82, 0.46, 1.0)
	var beam_scale := 0.82
	match category:
		&"power":
			color = Color(0.64, 0.92, 1.0, 1.0)
			beam_scale = 0.94
		&"signal":
			color = Color(0.78, 0.65, 1.0, 1.0)
			beam_scale = 1.0
		&"anomaly":
			color = Color(0.88, 0.96, 1.0, 1.0)
			beam_scale = 1.12
	for sprite in [reveal, beam_lower, beam_tip, ground_ring, collect_collapse]:
		sprite.modulate = color
	_apply_beam_scale(beam_scale)


func _apply_beam_scale(scale_y: float) -> void:
	beam_lower.scale.y = scale_y
	beam_tip.scale.y = scale_y
	beam_tip.position = BEAM_TIP_BASE_POSITION
	# Keep at least the authored 8 px overlap after category scaling.
	var lower_top := beam_lower.position.y - 68.0 * scale_y
	var tip_bottom := beam_tip.position.y + 16.0 * scale_y
	var minimum_tip_bottom := lower_top + 8.0 * scale_y
	if tip_bottom < minimum_tip_bottom:
		beam_tip.position.y += minimum_tip_bottom - tip_bottom
