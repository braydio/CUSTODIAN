@tool
extends Node2D
class_name AshBellLiftPlatformAssembly

@onready var platform_back_idle: Sprite2D = $PlatformBackIdle
@onready var platform_back_vibrate: AnimatedSprite2D = $PlatformBackVibrate
@onready var platform_front: Node2D = $PlatformFront
@onready var front_lip_idle: Sprite2D = $PlatformFront/FrontLipIdle
@onready var front_lip_vibrate: AnimatedSprite2D = $PlatformFront/FrontLipVibrate
@onready var rider_anchor: Marker2D = $RiderAnchor
@onready var safe_boarding_marker: Marker2D = $SafeBoardingMarker

@export var boarding_half_width := 72.0
@export var boarding_min_y := -60.0
@export var boarding_max_y := 24.0

var inward_direction := Vector2.DOWN


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


func set_inward_direction(direction: Vector2) -> void:
	if direction.length_squared() < 0.5:
		inward_direction = Vector2.DOWN
	else:
		inward_direction = direction.normalized()


func is_actor_boarded(actor: Node2D) -> bool:
	if actor == null:
		return false
	var delta := actor.global_position - global_position
	var lateral_direction := Vector2(inward_direction.y, -inward_direction.x)
	var inward_distance := delta.dot(inward_direction)
	var lateral_distance := delta.dot(lateral_direction)
	return (
		absf(lateral_distance) <= boarding_half_width
		and inward_distance >= boarding_min_y
		and inward_distance <= boarding_max_y
	)


func get_boarding_position() -> Vector2:
	return safe_boarding_marker.global_position
