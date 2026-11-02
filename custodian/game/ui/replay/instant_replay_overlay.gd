extends CanvasLayer
class_name InstantReplayOverlay

var _label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	_label = Label.new()
	_label.position = Vector2(24.0, 24.0)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	add_child(_label)


func set_status(cursor_sec: float, duration_sec: float, rate: float, playing: bool, rewinding: bool) -> void:
	if _label == null:
		return
	var behind := maxf(0.0, duration_sec - cursor_sec)
	_label.text = "INSTANT REPLAY   -%04.1fs   %s   %0.1fx\nF5 exit  Space pause  A/D or wheel scrub  1/2/3 speed" % [
		behind,
		"REWIND" if rewinding else ("PLAY" if playing else "PAUSED"),
		rate,
	]
