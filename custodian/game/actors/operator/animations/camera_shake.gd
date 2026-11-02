extends Node
class_name CameraShake

@export var shake_power: float = 10.0
@export var shake_duration: float = 0.2
@export var shake_fade: float = 0.1

var current_shake: float = 0.0
var camera: Camera2D = null

func _ready() -> void:
	camera = get_viewport().get_camera_2d()

func shake(power: float = 1.0, duration: float = 0.2) -> void:
	current_shake = shake_power * power
	shake_duration = duration

func _process(delta: float) -> void:
	if current_shake > 0 and camera:
		var offset = Vector2(
			randf_range(-current_shake, current_shake),
			randf_range(-current_shake, current_shake)
		)
		camera.offset = offset
		
		current_shake = lerp(current_shake, 0.0, shake_fade)
		
		if current_shake < 0.5:
			current_shake = 0
			camera.offset = Vector2.ZERO
