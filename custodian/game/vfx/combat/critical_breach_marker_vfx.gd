class_name CriticalBreachMarkerVfx
extends Node2D

@export var rise_distance: float = 8.0

var _duration := 0.8
var _elapsed := 0.0
var _start_position := Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	z_index = 31
	_start_position = position


func configure_duration(duration: float) -> void:
	_duration = maxf(duration, 0.05)
	_elapsed = 0.0
	animated_sprite.play(&"breach")


func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	position = _start_position + Vector2.UP * rise_distance * progress
	if animated_sprite.frame >= 4:
		animated_sprite.pause()
		animated_sprite.frame = 4
