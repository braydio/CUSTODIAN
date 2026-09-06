extends Node2D

## Damage number popup that floats upward and fades out.
## Root is Node2D (not Label/Control) so it correctly follows
## the camera transform when parented to a world-space node.

var lifetime := 0.65
var float_height := 22.0
var side_drift := 8.0

@onready var label: Label = $Label

## Proxied to the child Label. Setting this before add_child()
## defers to _ready(); works the same either way.
var text: String = "":
	set(value):
		text = value
		if label != null:
			label.text = value


func _ready() -> void:
	if label != null and not text.is_empty():
		label.text = text

	# Defer tween start to the next frame so the caller has time
	# to set global_position before the animation captures it.
	# This prevents animating from the default (0, 0) position.
	var tween := create_tween()
	tween.tween_callback(_start_float_animation)


func _start_float_animation() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		self, "position",
		position + Vector2(randf_range(-side_drift, side_drift), -float_height),
		lifetime
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, lifetime * 0.45).set_delay(lifetime * 0.45)
	tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.14).set_delay(0.08)

	await tween.finished
	queue_free()
