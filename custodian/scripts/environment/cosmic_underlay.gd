class_name CosmicUnderlay
extends Node2D

@export var drift_amplitude: Vector2 = Vector2(8.0, 5.0)
@export var drift_speed: Vector2 = Vector2(0.035, 0.025)
@export var pulse_strength: float = 0.012
@export var pulse_speed: float = 0.18
@export var base_texture_scale: Vector2 = Vector2.ONE

@onready var sprite: Sprite2D = $Sprite2D

var _time: float = 0.0
var _base_position: Vector2 = Vector2.ZERO
var _base_sprite_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	_base_position = position
	if sprite != null:
		_base_sprite_scale = sprite.scale * base_texture_scale
		sprite.scale = _base_sprite_scale


func _process(delta: float) -> void:
	_time += delta

	var drift: Vector2 = Vector2(
		sin(_time * TAU * drift_speed.x) * drift_amplitude.x,
		cos(_time * TAU * drift_speed.y) * drift_amplitude.y
	)
	position = _base_position + drift

	if sprite != null:
		var pulse: float = 1.0 + sin(_time * TAU * pulse_speed) * pulse_strength
		sprite.scale = _base_sprite_scale * pulse
