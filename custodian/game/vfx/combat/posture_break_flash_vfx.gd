class_name PostureBreakFlashVfx
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	z_as_relative = false
	z_index = 31
	animated_sprite.play(&"flash")
	animated_sprite.animation_finished.connect(queue_free)
