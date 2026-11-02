extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

const SPEED = 200

func _physics_process(delta):

	var direction = Vector2.ZERO

	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	velocity = direction.normalized() * SPEED
	move_and_slide()

	update_animation(direction)


func update_animation(direction):

	if direction.length() > 0:
		sprite.play("walk")
		sprite.flip_h = direction.x < 0
	else:
		sprite.play("idle")


func attack():

	sprite.play("attack")
