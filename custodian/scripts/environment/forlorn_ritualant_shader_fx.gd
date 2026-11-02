class_name ForlornRitualantShaderFX
extends Node2D

@export var underlay_material: ShaderMaterial
@export var edge_shadow_material: ShaderMaterial
@export var edge_rim_material: ShaderMaterial
@export var temporal_haze_material: ShaderMaterial

@export_range(0.0, 1.0, 0.01) var encounter_intensity: float = 0.35
@export_range(0.0, 1.0, 0.01) var max_intensity: float = 0.75


func _ready() -> void:
	_apply_intensity(encounter_intensity)


func set_encounter_intensity(value: float) -> void:
	encounter_intensity = clamp(value, 0.0, max_intensity)
	_apply_intensity(encounter_intensity)


func _apply_intensity(value: float) -> void:
	if underlay_material != null:
		underlay_material.set_shader_parameter("pulse_strength", lerp(0.015, 0.045, value))
		underlay_material.set_shader_parameter("drift_strength", lerp(0.004, 0.012, value))
		underlay_material.set_shader_parameter("darkness", lerp(0.24, 0.12, value))

	if edge_shadow_material != null:
		edge_shadow_material.set_shader_parameter("shadow_strength", lerp(0.45, 0.90, value))
		edge_shadow_material.set_shader_parameter("flicker_strength", lerp(0.02, 0.09, value))

	if edge_rim_material != null:
		edge_rim_material.set_shader_parameter("rim_strength", lerp(0.18, 0.62, value))
		edge_rim_material.set_shader_parameter("flicker_strength", lerp(0.02, 0.11, value))

	if temporal_haze_material != null:
		temporal_haze_material.set_shader_parameter("haze_strength", lerp(0.06, 0.22, value))
		temporal_haze_material.set_shader_parameter("haze_speed", lerp(0.035, 0.11, value))
