extends Node2D
class_name OperatorFlashlight

const AIM_EPSILON_SQUARED := 0.0001

@export var enabled_on_spawn := false
@export var beam_color := Color("e8d7b2")
@export_range(0.0, 8.0, 0.01) var beam_energy := 1.15
@export_range(0.1, 8.0, 0.01) var beam_texture_scale := 2.75
@export_range(0.0, 256.0, 1.0) var beam_height := 24.0
@export_range(0.0, 8.0, 0.01) var local_glow_energy := 0.30
@export_range(0.1, 8.0, 0.01) var local_glow_texture_scale := 1.75
@export var shadows_enabled := true
@export var beam_base_rotation := -PI / 2.0

@onready var beam_pivot: Node2D = %BeamPivot
@onready var beam_light: PointLight2D = %BeamLight
@onready var local_glow: PointLight2D = %LocalGlow

var is_enabled := false
var _last_valid_direction := Vector2.RIGHT


func _ready() -> void:
	beam_light.add_to_group("render_point_light")
	local_glow.add_to_group("render_point_light")
	_apply_presentation_tuning()
	_update_facing()
	set_flashlight_enabled(enabled_on_spawn)


func _process(_delta: float) -> void:
	_update_facing()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flashlight_toggle", false):
		toggle_flashlight()


func toggle_flashlight() -> void:
	set_flashlight_enabled(not is_enabled)


func set_flashlight_enabled(value: bool) -> void:
	is_enabled = value
	beam_light.enabled = value
	local_glow.enabled = value


func _update_facing() -> void:
	var owner := get_parent()
	if owner != null and "aim_direction" in owner:
		var candidate: Vector2 = owner.aim_direction
		if candidate.length_squared() > AIM_EPSILON_SQUARED:
			_last_valid_direction = candidate.normalized()
	beam_pivot.rotation = _last_valid_direction.angle() + beam_base_rotation


func _apply_presentation_tuning() -> void:
	beam_light.color = beam_color
	beam_light.energy = beam_energy
	beam_light.texture_scale = beam_texture_scale
	beam_light.height = beam_height
	beam_light.shadow_enabled = shadows_enabled
	local_glow.color = beam_color
	local_glow.energy = local_glow_energy
	local_glow.texture_scale = local_glow_texture_scale
	local_glow.shadow_enabled = false
