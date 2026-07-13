extends Node2D

@export var animation_name: StringName = &"impact"
@export var orient_to_impact: bool = true

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func _ready() -> void:
	z_as_relative = false
	z_index = 20
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		queue_free()
		return
	var playback_animation := animation_name
	if not animated_sprite.sprite_frames.has_animation(playback_animation):
		var animation_names := animated_sprite.sprite_frames.get_animation_names()
		if animation_names.is_empty():
			queue_free()
			return
		playback_animation = animation_names[0]
	animated_sprite.centered = true
	animated_sprite.position = Vector2.ZERO
	animated_sprite.play(playback_animation)
	if not animated_sprite.animation_finished.is_connected(queue_free):
		animated_sprite.animation_finished.connect(queue_free)


func configure_impact(direction: Vector2, surface_normal: Vector2 = Vector2.ZERO) -> void:
	if not orient_to_impact:
		return
	var orient := surface_normal if surface_normal.length_squared() > 0.0001 else -direction
	if orient.length_squared() <= 0.0001:
		return
	rotation = orient.angle()
