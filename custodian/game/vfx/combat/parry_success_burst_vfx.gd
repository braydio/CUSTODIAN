class_name ParrySuccessBurstVfx
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("parry_success_world_vfx")
	z_as_relative = false
	z_index = 31
	animated_sprite.play(&"contact")
	animated_sprite.animation_finished.connect(queue_free)
