extends ControllableActor
class_name VehicleBase
## Base class for all vehicles.
## Extends ControllableActor for unified control with Operator.
##
## Usage:
##   extends VehicleBase
##   func _ready():
##       setup_vehicle()

# Vehicle properties
@export var max_speed: float = 300.0
@export var acceleration: float = 0.0  # 0 = instant (v1 default)
@export var friction: float = 0.0     # 0 = instant stop (v1 default)

# Health system
@export var vehicle_health: float = 100.0
@export var vehicle_max_health: float = 100.0

# Weapon integration
var weapon: Node = null
@export var weapon_scene: PackedScene = null

# Occupancy
var is_occupied: bool = false
var occupant: Node = null  # Reference to Operator when occupied

# State
var is_destroyed: bool = false
var destruction_effect_scene: PackedScene = null

# Interaction
@export var interaction_prompt: String = "ENTER VEHICLE"
@export var interaction_range: float = 64.0

# Forward-only fire (v1 constraint)
@export var forward_fire_only: bool = true
@export var ambient_critter_launch_speed_threshold: float = 90.0
@export var ambient_critter_squish_speed_threshold: float = 210.0
@export var ambient_critter_launch_force: float = 180.0
@export var ambient_critter_squish_damage: float = 999.0
@export var ambient_critter_impact_cooldown_ms: int = 250
@export var parked_animation: StringName = &"idle"
@export var idle_start_animation: StringName = &"idle_start"
@export var idle_loop_animation: StringName = &"idle_loop"

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

var _recent_ambient_impacts: Dictionary = {}


func _ready() -> void:
	_setup_vehicle()
	if animated_sprite != null and not animated_sprite.animation_finished.is_connected(_on_vehicle_animation_finished):
		animated_sprite.animation_finished.connect(_on_vehicle_animation_finished)
	_update_movement_animation()


func _setup_vehicle() -> void:
	# Override health from export
	current_health = vehicle_health
	max_health = vehicle_max_health
	
	# Add to groups for interaction system
	add_to_group("vehicle")
	add_to_group("interactable")
	
	# Setup weapon if configured
	if weapon_scene:
		weapon = weapon_scene.instantiate()
		if weapon and has_node("WeaponSocket"):
			$WeaponSocket.add_child(weapon)


## Process input - direct velocity mapping (v1, no physics)
func process_input(input_vector: Vector2, aim_vector: Vector2, is_firing: bool) -> void:
	if is_destroyed or not is_occupied:
		return
	
	# Apply movement (direct velocity for v1)
	velocity = input_vector * max_speed
	move_and_slide()
	_handle_ambient_critter_impacts()
	_update_movement_animation()
	
	# Fire weapon if triggered
	if is_firing and weapon:
		_fire_weapon(aim_vector)


## Fire weapon in aim direction.
## For v1: forward-only if configured.
func _fire_weapon(aim_direction: Vector2) -> void:
	if not weapon or not weapon.has_method("fire"):
		return
	
	var fire_direction: Vector2
	if forward_fire_only:
		# Always fire in vehicle's facing direction
		fire_direction = transform.x
	else:
		fire_direction = aim_direction
	
	weapon.fire(global_position, fire_direction)


## Take damage and check for destruction.
func take_damage(amount: float) -> void:
	super.take_damage(amount)
	
	if current_health <= 0 and not is_destroyed:
		destroy()


## Destroy the vehicle.
func destroy() -> void:
	if is_destroyed:
		return
	
	is_destroyed = true
	
	# Spawn destruction effects
	if destruction_effect_scene:
		var effect = destruction_effect_scene.instantiate()
		effect.global_position = global_position
		get_parent().add_child(effect)
	
	# Handle occupant if present
	if is_occupied and occupant:
		# Signal player controller to handle exit
		# (handled by player controller checking vehicle state)
		pass
	
	# Remove from scene
	queue_free()


## Check if can be entered.
func can_be_entered() -> bool:
	return not is_destroyed and not is_occupied


## Enter the vehicle as operator.
func enter(operator: Node) -> void:
	if not can_be_entered():
		return
	
	is_occupied = true
	occupant = operator
	_play_idle_takeoff()
	_update_movement_animation()


## Exit the vehicle.
func exit() -> Vector2:
	if not is_occupied:
		return global_position
	
	var exit_position = global_position
	is_occupied = false
	occupant = null
	velocity = Vector2.ZERO
	_update_movement_animation()
	return exit_position


func _update_movement_animation() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not is_occupied:
		animated_sprite.stop()
		animated_sprite.animation = parked_animation
		animated_sprite.frame = 0
		return
	var target_animation := idle_loop_animation if animated_sprite.sprite_frames.has_animation(idle_loop_animation) else parked_animation
	if is_occupied and velocity.length_squared() > 4.0 and animated_sprite.sprite_frames.has_animation(&"move"):
		target_animation = &"move"
	if animated_sprite.animation != target_animation:
		animated_sprite.play(target_animation)
	elif not animated_sprite.is_playing():
		animated_sprite.play(target_animation)


func _handle_ambient_critter_impacts() -> void:
	var impact_speed := velocity.length()
	if impact_speed < ambient_critter_launch_speed_threshold:
		return
	var now_ms := Time.get_ticks_msec()
	for collision_index in range(get_slide_collision_count()):
		var collision := get_slide_collision(collision_index)
		if collision == null:
			continue
		var collider := collision.get_collider()
		if not (collider is Node):
			continue
		var critter := collider as Node
		if critter == null or not critter.is_in_group("ambient_critter"):
			continue
		if not _can_apply_ambient_critter_impact(critter, now_ms):
			continue
		_recent_ambient_impacts[critter.get_instance_id()] = now_ms
		_apply_ambient_critter_impact(critter, collision.get_normal(), impact_speed)
	_cleanup_ambient_critter_impacts(now_ms)


func _can_apply_ambient_critter_impact(critter: Node, now_ms: int) -> bool:
	var instance_id := critter.get_instance_id()
	if not _recent_ambient_impacts.has(instance_id):
		return true
	return now_ms - int(_recent_ambient_impacts.get(instance_id, 0)) >= ambient_critter_impact_cooldown_ms


func _cleanup_ambient_critter_impacts(now_ms: int) -> void:
	var stale_ids: Array[int] = []
	for instance_id in _recent_ambient_impacts.keys():
		if now_ms - int(_recent_ambient_impacts.get(instance_id, 0)) > ambient_critter_impact_cooldown_ms * 3:
			stale_ids.append(int(instance_id))
	for instance_id in stale_ids:
		_recent_ambient_impacts.erase(instance_id)


func _apply_ambient_critter_impact(critter: Node, collision_normal: Vector2, impact_speed: float) -> void:
	var impact_direction := velocity.normalized()
	if impact_direction == Vector2.ZERO:
		impact_direction = -collision_normal.normalized()
	if impact_direction == Vector2.ZERO:
		impact_direction = Vector2.RIGHT
	if impact_speed >= ambient_critter_squish_speed_threshold:
		if critter.has_method("take_damage"):
			critter.call("take_damage", ambient_critter_squish_damage)
		return
	var speed_alpha := inverse_lerp(ambient_critter_launch_speed_threshold, ambient_critter_squish_speed_threshold, impact_speed)
	var launch_force := lerpf(ambient_critter_launch_force, ambient_critter_launch_force * 1.9, clampf(speed_alpha, 0.0, 1.0))
	if critter.has_method("apply_melee_impact"):
		critter.call("apply_melee_impact", "heavy", impact_direction, launch_force)
	if critter.has_method("take_damage"):
		critter.call("take_damage", max(1.0, round(lerpf(2.0, 10.0, clampf(speed_alpha, 0.0, 1.0)))))


func _play_idle_takeoff() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if animated_sprite.sprite_frames.has_animation(idle_start_animation):
		animated_sprite.play(idle_start_animation)


func _on_vehicle_animation_finished() -> void:
	if animated_sprite == null or not is_occupied:
		return
	if animated_sprite.animation == idle_start_animation and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(idle_loop_animation):
		animated_sprite.play(idle_loop_animation)


## Get display name for UI.
func get_display_name() -> String:
	return "Vehicle"


## Override can_be_controlled to check occupancy.
func can_be_controlled() -> bool:
	return super.can_be_controlled() and is_occupied


func _get_interact_prompt_key() -> String:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var key_event: InputEventKey = event
			var key_text := key_event.as_text_key_label().strip_edges().to_upper()
			if not key_text.is_empty():
				return key_text
	return "INTERACT"


## Get interaction prompt for UI.
func get_interaction_prompt() -> String:
	if is_occupied:
		return "PRESS %s TO EXIT" % _get_interact_prompt_key()
	if is_destroyed:
		return "Destroyed"
	var prompt_text := interaction_prompt.strip_edges()
	if prompt_text.is_empty():
		prompt_text = "ENTER VEHICLE"
	return "PRESS %s TO %s" % [_get_interact_prompt_key(), prompt_text]
