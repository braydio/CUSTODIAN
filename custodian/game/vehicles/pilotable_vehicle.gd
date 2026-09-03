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
@export var exit_search_radii_px := PackedFloat32Array([
	56.0,
	72.0,
	88.0,
	104.0,
	128.0,
	160.0,
	192.0,
	224.0,
	256.0,
])
@export_range(8, 32, 1)
var exit_search_direction_count := 16

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
var _pilot_entry_global_position := Vector2.INF
var _last_exit_candidate_count := 0
var _last_exit_used_emergency_fallback := false


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
	if actor is Node2D:
		_pilot_entry_global_position = (actor as Node2D).global_position
	_obs_increment(&"vehicle_entered")
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
	_obs_increment(&"vehicle_exit_requested")
	_obs_log(&"vehicle_exit_requested", {
		"vehicle_id": name,
		"vehicle_position": global_position,
	})
	var exit_position := _find_exit_position()
	if exit_position == Vector2.INF:
		control_state = ControlState.PILOTED
		push_warning("PilotableVehicle: no valid exit position for %s" % name)
		_obs_increment(&"vehicle_exit_failed_no_safe_position")
		_obs_set_gauge(&"vehicle_exit_last_failure_reason", "no_safe_position")
		_obs_log(&"vehicle_exit_failed", {
			"vehicle_id": name,
			"vehicle_position": global_position,
			"candidate_count": _last_exit_candidate_count,
			"used_emergency_fallback": false,
			"failure_reason": "no_safe_position",
		})
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
	_pilot_entry_global_position = Vector2.INF
	_obs_increment(&"vehicle_exit_succeeded")
	_obs_log(&"vehicle_exit_succeeded", {
		"vehicle_id": name,
		"vehicle_position": global_position,
		"selected_position": exit_position,
		"candidate_count": _last_exit_candidate_count,
		"used_emergency_fallback": _last_exit_used_emergency_fallback,
	})
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
	var turn_response := float(movement_profile.get("turn_response", 10.0))
	if brake:
		input_vector = Vector2.ZERO
		deceleration *= 1.65
	var target_velocity := Vector2.ZERO
	if input_vector != Vector2.ZERO:
		var reverse_multiplier := 1.0
		var target_direction := input_vector.normalized()
		var reversing := facing_direction != Vector2.ZERO and target_direction.dot(facing_direction) < -0.25
		if reversing:
			reverse_multiplier = float(movement_profile.get("reverse_multiplier", 0.45))
		else:
			var current_direction := velocity.normalized() if velocity.length_squared() > 0.01 else facing_direction
			if current_direction == Vector2.ZERO:
				current_direction = target_direction
			var turn_alpha := 1.0 - exp(-maxf(0.01, turn_response) * delta)
			target_direction = current_direction.slerp(target_direction, turn_alpha).normalized()
		target_velocity = target_direction * max_speed_value * reverse_multiplier * _query_movement_surface_multiplier()
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	current_speed = velocity.length()
	move_and_slide()
	if velocity.length_squared() > 4.0:
		facing_direction = velocity.normalized()
	_handle_ambient_critter_impacts()
	_update_movement_animation()
	_obs_set_gauge(&"vehicle_mode", ControlState.keys()[control_state])
	_obs_set_gauge(&"vehicle_id", name)
	_obs_set_gauge(&"vehicle_position", global_position)
	_obs_set_gauge(&"vehicle_speed", current_speed)


func _query_movement_surface_multiplier() -> float:
	if bool(movement_profile.get("road_speed_multiplier_enabled", true)) and get_tree() != null:
		for map_node in get_tree().get_nodes_in_group("procgen_tilemap"):
			if map_node != null and map_node.has_method("get_movement_surface_multiplier_at_global"):
				return float(map_node.call("get_movement_surface_multiplier_at_global", global_position, "vehicle"))
	return float(movement_profile.get("offroad_speed_multiplier", 1.0))


func _find_exit_position() -> Vector2:
	var candidates := _build_exit_candidates()
	_last_exit_candidate_count = candidates.size()
	_last_exit_used_emergency_fallback = false
	_obs_set_gauge(&"vehicle_exit_last_candidate_count", candidates.size())
	for candidate in candidates:
		if not _is_exit_position_clear(candidate):
			_obs_increment(&"vehicle_exit_candidate_rejected_collision")
			continue
		if not _is_exit_candidate_reachable(candidate):
			_obs_increment(&"vehicle_exit_candidate_rejected_navigation")
			continue
		return candidate

	# Emergency softlock escape only after local search is exhausted. This is
	# a last-resort anti-softlock measure, not a substitute for a real local
	# exit: reaching it means the geometry immediately around the vehicle is
	# malformed and should be investigated via the emergency-fallback counter.
	if (
		_pilot_entry_global_position != Vector2.INF
		and _is_exit_position_clear(_pilot_entry_global_position)
	):
		_last_exit_used_emergency_fallback = true
		_obs_increment(&"vehicle_exit_emergency_fallback")
		_obs_log(&"vehicle_exit_emergency_fallback", {
			"vehicle_id": name,
			"vehicle_position": global_position,
			"entry_position": _pilot_entry_global_position,
			"candidate_count": candidates.size(),
		})
		return _pilot_entry_global_position

	return Vector2.INF


func _build_exit_candidates() -> Array[Vector2]:
	var result: Array[Vector2] = []

	if exit_marker != null:
		result.append(exit_marker.global_position)

	var forward := facing_direction.normalized()
	if forward.length_squared() < 0.01:
		forward = Vector2.DOWN

	var right := Vector2(-forward.y, forward.x)

	for radius in exit_search_radii_px:
		result.append(global_position + right * radius)
		result.append(global_position - right * radius)
		result.append(global_position - forward * radius)
		result.append(global_position + forward * radius)

		for index in exit_search_direction_count:
			var direction := Vector2.RIGHT.rotated(
				TAU * float(index) / float(exit_search_direction_count)
			)
			var candidate := global_position + direction * radius
			if not result.has(candidate):
				result.append(candidate)

	return result


func _is_exit_candidate_reachable(candidate: Vector2) -> bool:
	var navigation := get_node_or_null("/root/GameRoot/NavigationSystem")
	if (
		navigation != null
		and navigation.has_method("compute_path_immediate")
	):
		var path := navigation.call(
			"compute_path_immediate",
			global_position,
			candidate
		) as PackedVector2Array
		return not path.is_empty()
	return _is_exit_position_traversable(candidate)


func _is_exit_position_clear(position: Vector2) -> bool:
	if not _is_exit_position_traversable(position):
		return false
	var world := get_world_2d()
	if world == null:
		return true
	var pilot_shape_node := _get_pilot_collision_shape_node()
	var shape: Shape2D = null
	var local_offset := Vector2.ZERO
	if pilot_shape_node != null and pilot_shape_node.shape != null:
		shape = pilot_shape_node.shape.duplicate()
		local_offset = pilot_shape_node.position
	else:
		var fallback := CapsuleShape2D.new()
		fallback.radius = 12.0
		fallback.height = 24.0
		shape = fallback
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, position + local_offset)
	query.collision_mask = _pilot_collision_mask if _pilot_collision_mask != 0 else 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var exclusions: Array[RID] = [get_rid()]
	if pilot is CollisionObject2D:
		exclusions.append((pilot as CollisionObject2D).get_rid())
	query.exclude = exclusions
	return world.direct_space_state.intersect_shape(query, 8).is_empty()


func _get_pilot_collision_shape_node() -> CollisionShape2D:
	if pilot == null:
		return null
	return pilot.get_node_or_null("CollisionShape2D") as CollisionShape2D


func _is_exit_position_traversable(position: Vector2) -> bool:
	var navigation := get_node_or_null("/root/GameRoot/NavigationSystem")
	if navigation != null and navigation.has_method("is_in_walkable_area"):
		return bool(navigation.call("is_in_walkable_area", position))
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


func _observatory() -> Node:
	return get_node_or_null("/root/DevObservatory")


func _obs_increment(counter_name: StringName, amount: int = 1) -> void:
	var observatory := _observatory()
	if observatory != null and observatory.has_method("increment"):
		observatory.call("increment", counter_name, amount)


func _obs_set_gauge(gauge_name: StringName, value: Variant) -> void:
	var observatory := _observatory()
	if observatory != null and observatory.has_method("set_gauge"):
		observatory.call("set_gauge", gauge_name, value)


func _obs_log(event_name: StringName, data: Dictionary = {}) -> void:
	var observatory := _observatory()
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", event_name, data)


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
