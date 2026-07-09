class_name CriticalWindowRingVfx
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	z_index = 30


func configure_duration(duration: float) -> void:
	var resolved_duration := maxf(duration, 0.05)
	animated_sprite.speed_scale = 1.0 / resolved_duration
	animated_sprite.play(&"countdown")
