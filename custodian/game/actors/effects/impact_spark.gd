extends Node2D

@export var animation_name: StringName = &"impact"
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		queue_free()
		return

	var spark_animation: StringName = animation_name
	if not animated_sprite.sprite_frames.has_animation(spark_animation):
		var animation_names := animated_sprite.sprite_frames.get_animation_names()
		if animation_names.is_empty():
			queue_free()
			return
		spark_animation = animation_names[0]

	z_as_relative = false
	z_index = 20
	animated_sprite.play(spark_animation)
	if not animated_sprite.animation_finished.is_connected(queue_free):
		animated_sprite.animation_finished.connect(queue_free)
