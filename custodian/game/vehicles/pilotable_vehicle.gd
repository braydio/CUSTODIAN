class_name PilotableVehicle
extends CharacterBody2D

const VehicleDefinitionScript = preload("res://game/vehicles/vehicle_definition.gd")

enum ControlState { UNOCCUPIED, ENTERING, PILOTED, EXITING, DISABLED }

@export var fallback_vehicle_id: String = "custodian_ground_buggy_scout_light"
@export var movement_profile_path: String = "res://content/vehicles/vehicle_movement_profiles.json"
@export var visual_kits_path: String = "res://content/vehicles/vehicle_visual_kits.json"
@export var interaction_range: float = 64.0
@export var parked_animation: StringName = &"idle"
@export var idle_start_animation: StringName = &"idle_start"
@export var idle_loop_animation: StringName = &"idle_loop"
@export var move_animation: StringName = &"move"
@export var max_health: float = 100.0
@export var current_health: float = 100.0

var vehicle_definition = null
var control_state := ControlState.UNOCCUPIED
var pilot: Node = null
var movement_profile: Dictionary = {}
var current_speed := 0.0
var facing_direction := Vector2.DOWN
var disabled_reason: String = ""

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var exit_marker: Node2D = get_node_or_null("ExitMarker") as Node2D

var _pilot_collision_layer := 0
var _pilot_collision_mask := 0


func _ready() -> void:
	add_to_group("vehicle")
	add_to_group("vehicles")
	add_to_group("interactable")
	add_to_group("pilotable_vehicles")
	if vehicle_definition == null and not fallback_vehicle_id.is_empty():
		_apply_definition_from_registry(fallback_vehicle_id)
	_update_movement_animation()


func apply_vehicle_definition(definition) -> void:
	vehicle_definition = definition
	if vehicle_definition == null:
		return
	name = vehicle_definition.id
	interaction_range = float(vehicle_definition.seat_profile.get("entry_radius", interaction_range))
	movement_profile = _load_profile(movement_profile_path, "profiles", vehicle_definition.movement_profile)
	_apply_visual_kit(vehicle_definition.visual_kit)


func can_enter(actor: Node) -> bool:
	if actor == null:
		return false
	if control_state != ControlState.UNOCCUPIED:
		return false
	if vehicle_definition != null and not vehicle_definition.is_pilotable():
		return false
	if current_health <= 0.0:
		return false
	if actor is Node2D:
		return (actor as Node2D).global_position.distance_to(global_position) <= interaction_range
	return true


func can_be_entered() -> bool:
	var operator := get_node_or_null("/root/GameRoot/World/Operator")
	return can_enter(operator)


func enter_vehicle(actor: Node) -> bool:
	if not can_enter(actor):
		return false
	control_state = ControlState.ENTERING
	pilot = actor
	if pilot is CollisionObject2D:
		var collision_actor := pilot as CollisionObject2D
		_pilot_collision_layer = collision_actor.collision_layer
		_pilot_collision_mask = collision_actor.collision_mask
		collision_actor.collision_layer = 0
		collision_actor.collision_mask = 0
	if pilot is CanvasItem:
		(pilot as CanvasItem).visible = false
	if pilot.has_method("set_physics_process"):
		pilot.set_physics_process(false)
	if pilot.has_method("set_process"):
		pilot.set_process(false)
	if pilot.has_method("set_process_input"):
		pilot.set_process_input(false)
	control_state = ControlState.PILOTED
	_play_idle_takeoff()
	_update_movement_animation()
	return true


func enter(actor: Node) -> void:
	enter_vehicle(actor)


func exit_vehicle() -> bool:
	if control_state != ControlState.PILOTED or pilot == null:
		return false
	control_state = ControlState.EXITING
	var exit_position := _find_exit_position()
	if exit_position == Vector2.INF:
		control_state = ControlState.PILOTED
		push_warning("PilotableVehicle: no valid exit position for %s" % name)
		return false
	if pilot is Node2D:
		(pilot as Node2D).global_position = exit_position
	if pilot is CollisionObject2D:
		var collision_actor := pilot as CollisionObject2D
		collision_actor.collision_layer = _pilot_collision_layer
		collision_actor.collision_mask = _pilot_collision_mask
	if pilot is CanvasItem:
		(pilot as CanvasItem).visible = true
	if pilot.has_method("set_physics_process"):
		pilot.set_physics_process(true)
	if pilot.has_method("set_process"):
		pilot.set_process(true)
	if pilot.has_method("set_process_input"):
		pilot.set_process_input(true)
	pilot = null
	control_state = ControlState.UNOCCUPIED
	velocity = Vector2.ZERO
	current_speed = 0.0
	_update_movement_animation()
	return true


func exit() -> Vector2:
	var exit_position := _find_exit_position()
	if exit_vehicle():
		return exit_position
	return global_position


func route_vehicle_input(input_vector: Vector2, actions: Dictionary, delta: float) -> void:
	if control_state != ControlState.PILOTED:
		return
	if bool(actions.get("exit_pressed", false)):
		return
	_apply_movement(input_vector, bool(actions.get("brake", false)), delta)


func process_input(input_vector: Vector2, _aim_vector: Vector2 = Vector2.ZERO, _is_firing: bool = false) -> void:
	route_vehicle_input(input_vector, {}, get_physics_process_delta_time())


func disable_vehicle(reason: String = "") -> void:
	disabled_reason = reason
	control_state = ControlState.DISABLED
	velocity = Vector2.ZERO
	current_speed = 0.0


func is_piloted() -> bool:
	return control_state == ControlState.PILOTED and pilot != null


func get_display_name() -> String:
	if vehicle_definition != null:
		return vehicle_definition.get_display_name()
	return name


func get_interaction_prompt() -> String:
	var key := _get_action_prompt_key(&"interact", "INTERACT")
	if is_piloted():
		return "PRESS %s TO EXIT %s" % [key, get_display_name().to_upper()]
	if control_state == ControlState.DISABLED:
		return "DISABLED"
	return "PRESS %s TO ENTER %s" % [key, get_display_name().to_upper()]


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_distance() -> float:
	return interaction_range


func interact(actor: Node) -> void:
	var controller := get_node_or_null("/root/GameRoot/World/PlayerController")
	if controller != null and controller.has_method("enter_vehicle"):
		controller.call("enter_vehicle", self)
	else:
		enter_vehicle(actor)


func _apply_movement(input_vector: Vector2, brake: bool, delta: float) -> void:
	var max_speed_value := float(movement_profile.get("max_speed", 175.0))
	var acceleration := float(movement_profile.get("acceleration", 420.0))
	var deceleration := float(movement_profile.get("deceleration", 520.0))
	if brake:
		input_vector = Vector2.ZERO
		deceleration *= 1.65
	var target_velocity := Vector2.ZERO
	if input_vector != Vector2.ZERO:
		var reverse_multiplier := 1.0
		if facing_direction != Vector2.ZERO and input_vector.dot(facing_direction) < -0.25:
			reverse_multiplier = float(movement_profile.get("reverse_multiplier", 0.45))
		target_velocity = input_vector * max_speed_value * reverse_multiplier * _query_movement_surface_multiplier()
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	current_speed = velocity.length()
	move_and_slide()
	if velocity.length_squared() > 4.0:
		facing_direction = velocity.normalized()
	_handle_ambient_critter_impacts()
	_update_movement_animation()


func _query_movement_surface_multiplier() -> float:
	if bool(movement_profile.get("road_speed_multiplier_enabled", true)) and get_tree() != null:
		for map_node in get_tree().get_nodes_in_group("procgen_tilemap"):
			if map_node != null and map_node.has_method("get_movement_surface_multiplier_at_global"):
				return float(map_node.call("get_movement_surface_multiplier_at_global", global_position, "vehicle"))
	return float(movement_profile.get("offroad_speed_multiplier", 1.0))


func _find_exit_position() -> Vector2:
	var base_position := global_position + Vector2(42.0, 0.0)
	if exit_marker != null:
		base_position = exit_marker.global_position
	if _is_exit_position_clear(base_position):
		return base_position
	var offsets: Array[Vector2] = [
		Vector2(42, 0), Vector2(-42, 0), Vector2(0, 42), Vector2(0, -42),
		Vector2(42, 42), Vector2(-42, 42), Vector2(42, -42), Vector2(-42, -42)
	]
	for offset in offsets:
		var candidate: Vector2 = global_position + offset
		if _is_exit_position_clear(candidate):
			return candidate
	return Vector2.INF


func _is_exit_position_clear(position: Vector2) -> bool:
	var world := get_world_2d()
	if world == null:
		return true
	var query := PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hits := world.direct_space_state.intersect_point(query, 4)
	for hit in hits:
		if Dictionary(hit).get("collider") != self:
			return false
	return true


func _apply_definition_from_registry(vehicle_id: String) -> void:
	var registry := VehicleRegistry.new()
	registry.load_registry()
	var definition = registry.get_vehicle(vehicle_id)
	if definition != null:
		apply_vehicle_definition(definition)


func _load_profile(path: String, section: String, profile_id: String) -> Dictionary:
	if profile_id.is_empty() or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return {}
	var profiles := Dictionary((parsed as Dictionary).get(section, {}))
	return Dictionary(profiles.get(profile_id, {})).duplicate(true)


func _apply_visual_kit(visual_kit_id: String) -> void:
	if animated_sprite == null or visual_kit_id.is_empty():
		return
	var kit := _load_profile(visual_kits_path, "visual_kits", visual_kit_id)
	var frames_path := String(kit.get("sprite_frames", ""))
	if not frames_path.is_empty():
		var frames := load(frames_path)
		if frames is SpriteFrames:
			animated_sprite.sprite_frames = frames
	parked_animation = StringName(String(kit.get("default_animation", parked_animation)))
	move_animation = StringName(String(kit.get("movement_animation", move_animation)))


func _update_movement_animation() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not is_piloted():
		animated_sprite.stop()
		if animated_sprite.sprite_frames.has_animation(parked_animation):
			animated_sprite.animation = parked_animation
			animated_sprite.frame = 0
		return
	var target_animation := idle_loop_animation if animated_sprite.sprite_frames.has_animation(idle_loop_animation) else parked_animation
	if velocity.length_squared() > 4.0 and animated_sprite.sprite_frames.has_animation(move_animation):
		target_animation = move_animation
	if animated_sprite.animation != target_animation:
		animated_sprite.play(target_animation)
	elif not animated_sprite.is_playing():
		animated_sprite.play(target_animation)


func _play_idle_takeoff() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if animated_sprite.sprite_frames.has_animation(idle_start_animation):
		animated_sprite.play(idle_start_animation)


func _handle_ambient_critter_impacts() -> void:
	if current_speed < 90.0:
		return
	for collision_index in range(get_slide_collision_count()):
		var collision := get_slide_collision(collision_index)
		if collision == null:
			continue
		var collider := collision.get_collider()
		if collider is Node and (collider as Node).is_in_group("ambient_critter") and collider.has_method("apply_melee_impact"):
			collider.call("apply_melee_impact", "heavy", velocity.normalized(), min(current_speed, 260.0))


func _get_action_prompt_key(action_name: StringName, fallback: String) -> String:
	if not InputMap.has_action(action_name):
		return fallback
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			var label := OS.get_keycode_string(keycode)
			if not label.is_empty():
				return label.to_upper()
	return fallback
