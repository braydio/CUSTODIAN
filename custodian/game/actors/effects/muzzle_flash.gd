extends Node2D

@export var lifetime: float = 0.06
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

func _ready():
	if animated_sprite:
		animated_sprite.play("flash")
		if not animated_sprite.animation_finished.is_connected(queue_free):
			animated_sprite.animation_finished.connect(queue_free)
		return
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
