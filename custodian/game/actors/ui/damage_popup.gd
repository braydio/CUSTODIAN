extends Label

var lifetime := 0.65
var float_height := 22.0
var side_drift := 8.0

func _ready() -> void:
	modulate.a = 1.0
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(randf_range(-side_drift, side_drift), -float_height), lifetime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, lifetime * 0.45).set_delay(lifetime * 0.45)
	tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.14).set_delay(0.08)
	
	await tween.finished
	queue_free()
