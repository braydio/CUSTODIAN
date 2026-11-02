class_name GameFeelManager
extends Node
## Centralized game feel effects: hit-stop, screen shake, knockback
##
## Use GameFeel.hit_stop(), GameFeel.screen_shake(), etc.

const SCREEN_SHAKE_SCENE := preload("res://game/actors/operator/animations/camera_shake.gd")


## Hit-stop: briefly slow down time for impact feel
## duration: seconds to freeze (0.05-0.15 feels good)
## decay: how fast to return to normal (optional)
func hit_stop(duration: float = 0.08) -> void:
	if duration <= 0 or Engine.time_scale < 1.0:
		return
	
	Engine.time_scale = 0.1
	await get_tree().create_timer(duration).timeout
	Engine.time_scale = 1.0


## Screen shake via camera
## intensity: 0-100, recommended 5-20
## duration: seconds
func screen_shake(intensity: float = 10.0, duration: float = 0.2) -> void:
	var camera = _get_camera()
	if camera == null:
		return
	
	if camera.has_method("shake"):
		camera.shake(intensity, duration)


## Apply knockback to a CharacterBody2D
## direction: Vector2 pointing AWAY from damage source
## force: knockback strength (50-200 recommended)
func apply_knockback(body: CharacterBody2D, direction: Vector2, force: float = 100.0) -> void:
	if body == null:
		return
	
	if body is CharacterBody2D:
		body.velocity = direction.normalized() * force
		body.move_and_slide()


## Combined effect: hit_stop + screen_shake + knockback
## Call this for best impact feel
func on_hit(
	hit_body: Node,
	damage_source_position: Vector2,
	knockback_force: float = 80.0,
	hit_stop_duration: float = 0.06,
	shake_intensity: float = 8.0
) -> void:
	# Hit-stop
	hit_stop(hit_stop_duration)
	
	# Screen shake
	screen_shake(shake_intensity)
	
	# Knockback on character bodies
	if hit_body is CharacterBody2D:
		var knockback_dir = hit_body.global_position.direction_to(damage_source_position)
		# Actually knock BACK (away from damage source)
		knockback_dir = -knockback_dir
		apply_knockback(hit_body, knockback_dir, knockback_force)


## Utility: get the main camera
func _get_camera() -> Camera2D:
	var world = get_tree().get_first_node_in_group("world")
	if world and world.has_node("Camera2D"):
		return world.get_node("Camera2D")
	
	# Fallback: search in scene
	return get_tree().get_first_node_in_group("camera")
