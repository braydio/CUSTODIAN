@tool
extends Node2D
class_name AshBellLiftPlatformAssembly

@onready var platform_back_idle: Sprite2D = $PlatformBackIdle
@onready var platform_back_vibrate: AnimatedSprite2D = $PlatformBackVibrate
@onready var platform_front: Node2D = $PlatformFront
@onready var front_lip_idle: Sprite2D = $PlatformFront/FrontLipIdle
@onready var front_lip_vibrate: AnimatedSprite2D = $PlatformFront/FrontLipVibrate
@onready var rider_anchor: Marker2D = $RiderAnchor

@export var boarding_half_width := 72.0
@export var boarding_min_y := -60.0
@export var boarding_max_y := 24.0


func set_vibrating(active: bool) -> void:
	platform_back_idle.visible = not active
	front_lip_idle.visible = not active
	platform_back_vibrate.visible = active
	front_lip_vibrate.visible = active
	if active:
		platform_back_vibrate.play(&"vibrate")
		front_lip_vibrate.play(&"vibrate")
	else:
		platform_back_vibrate.stop()
		front_lip_vibrate.stop()


func set_depths(back_z: int, front_z: int) -> void:
	platform_back_idle.z_as_relative = false
	platform_back_vibrate.z_as_relative = false
	platform_back_idle.z_index = back_z
	platform_back_vibrate.z_index = back_z
	platform_front.z_as_relative = false
	platform_front.z_index = front_z


func is_actor_boarded(actor: Node2D) -> bool:
	if actor == null:
		return false
	var local_actor := to_local(actor.global_position)
	return (
		absf(local_actor.x) <= boarding_half_width
		and local_actor.y >= boarding_min_y
		and local_actor.y <= boarding_max_y
	)


func get_boarding_position() -> Vector2:
	return rider_anchor.global_position
