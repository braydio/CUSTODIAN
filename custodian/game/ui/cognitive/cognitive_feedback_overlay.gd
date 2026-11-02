extends CanvasLayer

const AXIS_COLORS := {
	&"recollection": Color(0.62, 0.82, 1.0),
	&"instinct": Color(0.95, 0.55, 0.38),
	&"bearing": Color(0.86, 0.72, 1.0),
}

@onready var overlay: ColorRect = $Overlay
var _pulse_intensity := 0.0
var _pulse_duration := 0.0
var _pulse_remaining := 0.0
var _persistent_intensity := 0.0
var _axis := &"recollection"

func _ready() -> void:
	var cognitive := get_node_or_null("/root/CognitiveState")
	if cognitive != null:
		cognitive.cognitive_item_collected.connect(_on_item_collected)
		cognitive.cognitive_threshold_changed.connect(_on_threshold_changed)

func _process(delta: float) -> void:
	if _pulse_remaining > 0.0:
		_pulse_remaining = maxf(0.0, _pulse_remaining - delta)
	var pulse := _pulse_intensity * (_pulse_remaining / maxf(_pulse_duration, 0.001))
	var material := overlay.material as ShaderMaterial
	material.set_shader_parameter("intensity", maxf(_persistent_intensity, pulse))
	material.set_shader_parameter("axis_tint", AXIS_COLORS.get(_axis, Color.WHITE))
	material.set_shader_parameter("phase", Time.get_ticks_msec() * 0.003)

func _on_item_collected(item_id: StringName, _amount: int) -> void:
	_axis = _axis_for_item(item_id)
	_pulse(0.22, 0.20)

func _on_threshold_changed(axis: StringName, old_tier: int, new_tier: int, _value: float) -> void:
	_axis = axis
	if new_tier > old_tier:
		_pulse(0.42 if new_tier == 1 else 0.62, 0.45 if new_tier == 1 else 0.9)
	_persistent_intensity = 0.10 if new_tier >= 2 else 0.0

func _pulse(value: float, duration: float) -> void:
	_pulse_intensity = value; _pulse_duration = duration; _pulse_remaining = duration

func _axis_for_item(item_id: StringName) -> StringName:
	match item_id:
		&"residual_instinct": return &"instinct"
		&"ancient_bearing": return &"bearing"
	return &"recollection"

func get_feedback_snapshot() -> Dictionary:
	return {"axis": _axis, "pulse_remaining": _pulse_remaining, "persistent_intensity": _persistent_intensity, "layer": layer}
