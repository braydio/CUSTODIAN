extends Resource
class_name MaterialProfile

@export var material_id: StringName = &"unknown"
@export var display_name := "Unknown"

@export var footstep_noise_mult := 1.0
@export var stealth_visibility_mult := 1.0
@export var bullet_impact_fx: StringName = &"default"
@export var melee_impact_fx: StringName = &"default"
@export var footstep_sound_family: StringName = &"default"

@export var tags: Array[StringName] = []
@export var notes := ""
