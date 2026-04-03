extends Label

var lifetime := 1.4
var float_height := 48.0

func _ready() -> void:
	modulate.a = 1.0
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - float_height, lifetime).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, lifetime).set_delay(lifetime * 0.5)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.15)
	
	await tween.finished
	queue_free()