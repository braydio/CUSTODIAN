class_name LootCorpseMarker
extends Node2D

signal reveal_finished
signal collection_finished

@onready var reveal: AnimatedSprite2D = $Reveal
@onready var beacon: AnimatedSprite2D = $Beacon
@onready var ground_ring: AnimatedSprite2D = $GroundRing
@onready var collect_collapse: AnimatedSprite2D = $CollectCollapse

var _collecting := false


func activate(presentation: Dictionary = {}) -> void:
	_collecting = false
	visible = true
	_apply_presentation(presentation)
	beacon.visible = false
	ground_ring.visible = false
	collect_collapse.visible = false
	reveal.visible = true
	reveal.play(&"reveal")
	await reveal.animation_finished
	if _collecting or not is_inside_tree():
		return
	reveal.visible = false
	beacon.visible = true
	ground_ring.visible = true
	beacon.play(&"beacon_loop")
	ground_ring.play(&"ground_ring_loop")
	reveal_finished.emit()


func collect() -> void:
	if _collecting:
		return
	_collecting = true
	reveal.stop()
	beacon.stop()
	ground_ring.stop()
	reveal.visible = false
	beacon.visible = false
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
	for sprite in [reveal, beacon, ground_ring, collect_collapse]:
		sprite.modulate = color
	beacon.scale.y = beam_scale
