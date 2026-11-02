class_name ParryContactSparkVfx
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	z_as_relative = false
	z_index = 30
	animated_sprite.play(&"contact")
	animated_sprite.animation_finished.connect(queue_free)
