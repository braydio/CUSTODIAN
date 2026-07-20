extends CharacterBody2D
class_name CombatDrone

const BULLET_SCENE := preload("res://game/actors/projectiles/bullet.tscn")
const MECH_GUNSHOT_SOUND: AudioStream = preload("res://content/audio/sfx/combat/mech_gun_shot_01.wav")
const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")
const DroneTargetingScript := preload("res://game/systems/drone/drone_targeting.gd")

@export var drone_id: String = "DRONE_01"
@export var base_tint: Color = Color(0.35, 0.82, 0.95, 1.0)
@export var damaged_tint: Color = Color(1.0, 0.65, 0.24, 1.0)
@export var critical_tint: Color = Color(1.0, 0.22, 0.18, 1.0)
@export_range(0.05, 0.5, 0.01) var target_scan_interval_sec: float = 0.18

var profile: Resource = DroneCommandProfileScript.new()
var squad_mode: int = DroneCommandProfileScript.Mode.FOLLOW
var anchor: Node2D = null
var manager: Node = null
var max_health: float = 45.0
var health: float = 45.0
var destroyed: bool = false
var target: Node2D = null
var command_target: Node2D = null

# When false, _update_weapon skips firing. Owned by DroneManager squad commands.
var fire_at_will: bool = true
var follow_distance_mode: int = DroneCommandProfileScript.FollowDistance.CLOSE
var order_anchor_active: bool = false
var order_anchor_position: Vector2 = Vector2.ZERO

var _slot_index: int = 0
var _hold_position: Vector2 = Vector2.ZERO
var _fire_cooldown_timer: float = 0.0
var _burst_remaining: int = 0
var _burst_gap_timer: float = 0.0
var _targeting: RefCounted = DroneTargetingScript.new()
var _roam_goal: Vector2 = Vector2.ZERO
var _roam_repath_timer: float = 0.0
var _roam_sequence: int = 0
var _command_target_instance_id: int = 0
var _target_scan_timer: float = 0.0

@onready var visual: ColorRect = get_node_or_null("Visual")
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var muzzle: Marker2D = get_node_or_null("Muzzle")


func _ready() -> void:
	add_to_group("ally")
	add_to_group("allied_drone")
	add_to_group("defense")
	add_to_group("turret")
	_hold_position = global_position
	_apply_profile()
	_update_visuals()


func configure(index: int, anchor_node: Node2D, manager_node: Node, command_profile: Resource) -> void:
	_slot_index = index
	anchor = anchor_node
	manager = manager_node
	if command_profile != null:
		profile = command_profile
	drone_id = "DRONE_%02d" % (index + 1)
	_apply_profile()


func set_mode(mode: int) -> void:
	squad_mode = mode
	_target_scan_timer = 0.0
	if mode == DroneCommandProfileScript.Mode.HOLD:
		_hold_position = global_position


func set_fire_at_will(enabled: bool) -> void:
	fire_at_will = enabled
	if not fire_at_will:
		_burst_remaining = 0
		_burst_gap_timer = 0.0


func set_follow_distance_mode(mode: int) -> void:
	follow_distance_mode = mode
	if follow_distance_mode == DroneCommandProfileScript.FollowDistance.FREE_ROAM:
		_roam_goal = Vector2.ZERO
		_roam_repath_timer = 0.0


func set_order_anchor(position: Vector2) -> void:
	order_anchor_position = position
	order_anchor_active = true
	target = null
	_roam_goal = Vector2.ZERO
	_roam_repath_timer = 0.0
	_target_scan_timer = 0.0


func clear_order_anchor() -> void:
	order_anchor_active = false
	target = null
	_roam_goal = Vector2.ZERO
	_roam_repath_timer = 0.0
	_target_scan_timer = 0.0


func set_command_target(hostile: Node2D) -> void:
	command_target = hostile
	target = hostile
	_command_target_instance_id = hostile.get_instance_id() if hostile != null and is_instance_valid(hostile) else 0
	_target_scan_timer = target_scan_interval_sec


func clear_command_target() -> void:
	command_target = null
	target = null
	_command_target_instance_id = 0
	_target_scan_timer = 0.0


func _get_anchor_position() -> Vector2:
	if order_anchor_active:
		return order_anchor_position
	if anchor != null and is_instance_valid(anchor):
		return anchor.global_position
	return global_position


func _get_anchor_node_position_or_order_position() -> Vector2:
	return _get_anchor_position()


func get_anchor_mode_name() -> String:
	return "GUARD" if order_anchor_active else "FOLLOW"


func get_follow_distance_name() -> String:
	return DroneCommandProfileScript.follow_distance_name(follow_distance_mode)


func get_fire_mode_name() -> String:
	return "FIRE AT WILL" if fire_at_will else "HOLD FIRE"


func _physics_process(delta: float) -> void:
	if destroyed:
		return
	_fire_cooldown_timer = maxf(0.0, _fire_cooldown_timer - delta)
	_burst_gap_timer = maxf(0.0, _burst_gap_timer - delta)
	_roam_repath_timer = maxf(0.0, _roam_repath_timer - delta)
	_target_scan_timer = maxf(0.0, _target_scan_timer - delta)
	if _target_scan_timer <= 0.0:
		_target_scan_timer = target_scan_interval_sec
		_refresh_target()
	_update_movement(delta)
	_update_weapon()
	_update_visuals()


func _refresh_target() -> void:
	_prune_freed_target_references()
	if squad_mode == DroneCommandProfileScript.Mode.RECALL:
		target = null
		return
	if _must_return_to_order_anchor():
		target = null
		return
	var anchor_position := _get_anchor_position()
	var engage_range := _get_engage_range()
	if _targeting.is_valid_command_target(command_target):
		if command_target.global_position.distance_to(anchor_position) <= engage_range:
			target = command_target
			return
	command_target = null
	_command_target_instance_id = 0
	if target != null and is_instance_valid(target) and not _targeting.is_invalid_enemy(target):
		if target.global_position.distance_to(anchor_position) <= engage_range:
			return
	target = _targeting.acquire_target_at_position(self, anchor_position, squad_mode, profile, engage_range)


func _prune_freed_target_references() -> void:
	var cleared_slots: Array[String] = []
	if _command_target_instance_id != 0 and not is_instance_id_valid(_command_target_instance_id):
		command_target = null
		_command_target_instance_id = 0
		cleared_slots.append("command_target")
		if not is_instance_valid(target):
			target = null
			cleared_slots.append("target")
	elif command_target != null and not is_instance_valid(command_target):
		command_target = null
		_command_target_instance_id = 0
		cleared_slots.append("command_target")
	if target != null and not is_instance_valid(target):
		target = null
		cleared_slots.append("target")
	if cleared_slots.is_empty():
		return
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null:
		if observatory.has_method("increment"):
			observatory.call("increment", &"drone_stale_targets_cleared", cleared_slots.size())
		if observatory.has_method("log_event"):
			observatory.call("log_event", &"drone_stale_target_cleared", {
				"drone_id": drone_id,
				"slots": cleared_slots,
			})


func _update_movement(delta: float) -> void:
	var desired_position := _get_desired_position()
	var to_goal := desired_position - global_position
	var desired_velocity := Vector2.ZERO
	if to_goal.length() > 4.0:
		desired_velocity = to_goal.normalized() * profile.drone_speed
	velocity = velocity.move_toward(desired_velocity, profile.drone_acceleration * delta)
	move_and_slide()


func _get_desired_position() -> Vector2:
	var anchor_position := _get_anchor_position()
	if _must_return_to_order_anchor():
		return _get_follow_desired_position()
	if _should_retreat():
		var retreat_dir := Vector2.RIGHT
		if target != null and is_instance_valid(target):
			retreat_dir = (anchor_position - target.global_position).normalized()
		if retreat_dir.length_squared() <= 0.001:
			retreat_dir = Vector2.RIGHT.rotated(float(_slot_index) * PI)
		return anchor_position + retreat_dir * _get_follow_radius()
	match squad_mode:
		DroneCommandProfileScript.Mode.HOLD:
			if order_anchor_active:
				return _get_follow_desired_position()
			if _hold_position.distance_to(anchor_position) > profile.hold_leash_range:
				return _get_follow_desired_position()
			return _hold_position
		DroneCommandProfileScript.Mode.INTERCEPT:
			if target != null and is_instance_valid(target):
				var away_from_anchor := (target.global_position - anchor_position).normalized()
				if away_from_anchor.length_squared() > 0.001:
					return target.global_position - away_from_anchor * profile.intercept_standoff
			return _get_follow_desired_position()
		DroneCommandProfileScript.Mode.RECALL:
			return anchor_position + _get_orbit_offset().normalized() * profile.recall_distance
		_:
			if follow_distance_mode == DroneCommandProfileScript.FollowDistance.FREE_ROAM:
				return _get_free_roam_desired_position()
			return _get_follow_desired_position()


func _get_free_roam_desired_position() -> Vector2:
	var anchor_position := _get_anchor_position()
	if global_position.distance_to(anchor_position) > _get_active_leash_range():
		_roam_repath_timer = 0.0
		return _apply_separation(anchor_position + _get_orbit_offset(profile.follow_free_roam_radius))
	if target != null and is_instance_valid(target):
		var away_from_anchor := (target.global_position - anchor_position).normalized()
		if away_from_anchor.length_squared() > 0.001:
			return _clamp_to_free_roam_leash(target.global_position - away_from_anchor * profile.free_roam_standoff)
	if _should_pick_new_roam_goal():
		_pick_next_roam_goal()
	return _apply_separation(_clamp_to_free_roam_leash(_roam_goal))


func _get_follow_desired_position() -> Vector2:
	var anchor_position := _get_anchor_position()
	var band := _get_follow_band()
	var preferred_radius := float(band.get("preferred", _get_follow_radius()))
	var minimum_radius := float(band.get("min", maxf(0.0, preferred_radius - 32.0)))
	var maximum_radius := float(band.get("max", preferred_radius + 48.0))
	var slot_goal := anchor_position + _get_orbit_offset(preferred_radius)
	var anchor_distance := global_position.distance_to(anchor_position)
	var goal := slot_goal

	if anchor_distance >= minimum_radius and anchor_distance <= maximum_radius:
		if global_position.distance_to(slot_goal) <= profile.follow_arrive_distance:
			goal = global_position
	elif anchor_distance < minimum_radius:
		var away_from_anchor := global_position - anchor_position
		if away_from_anchor.length_squared() <= 0.001:
			away_from_anchor = slot_goal - anchor_position
		if away_from_anchor.length_squared() <= 0.001:
			away_from_anchor = Vector2.RIGHT.rotated(float(_slot_index) * PI)
		goal = anchor_position + away_from_anchor.normalized() * minimum_radius

	return _apply_separation(goal)


func _get_follow_band() -> Dictionary:
	match follow_distance_mode:
		DroneCommandProfileScript.FollowDistance.CLOSE:
			return {
				"min": profile.follow_close_min_radius,
				"max": profile.follow_close_max_radius,
				"preferred": profile.follow_close_radius,
			}
		DroneCommandProfileScript.FollowDistance.FAR:
			return {
				"min": profile.follow_far_min_radius,
				"max": profile.follow_far_max_radius,
				"preferred": profile.follow_far_radius,
			}
		DroneCommandProfileScript.FollowDistance.FREE_ROAM:
			return {
				"min": profile.free_roam_min_radius,
				"max": profile.free_roam_max_radius,
				"preferred": profile.follow_free_roam_radius,
			}
		_:
			return {
				"min": maxf(0.0, profile.follow_orbit_radius - 28.0),
				"max": profile.follow_orbit_radius + 64.0,
				"preferred": profile.follow_orbit_radius,
			}


func _get_orbit_offset(radius: float = -1.0) -> Vector2:
	var resolved_radius: float = radius if radius >= 0.0 else _get_follow_radius()
	var side := -1.0 if _slot_index % 2 == 0 else 1.0
	var ring: float = float(floori(float(_slot_index) / 2.0)) * profile.follow_slot_spacing
	var offset: Vector2 = Vector2(side * (resolved_radius + ring), profile.follow_y_offset)
	var anchor_velocity := _get_anchor_velocity()
	if anchor_velocity.length_squared() > 16.0:
		var trailing: Vector2 = -anchor_velocity.normalized() * resolved_radius
		var lateral: Vector2 = anchor_velocity.normalized().orthogonal() * side * (profile.follow_slot_spacing + ring)
		offset = trailing + lateral + Vector2(0.0, profile.follow_y_offset)
	return offset


func _get_follow_radius() -> float:
	match follow_distance_mode:
		DroneCommandProfileScript.FollowDistance.CLOSE:
			return profile.follow_close_radius
		DroneCommandProfileScript.FollowDistance.FAR:
			return profile.follow_far_radius
		DroneCommandProfileScript.FollowDistance.FREE_ROAM:
			return profile.follow_free_roam_radius
		_:
			return profile.follow_orbit_radius


func _get_engage_range() -> float:
	if order_anchor_active:
		return profile.guard_order_engage_range
	if follow_distance_mode == DroneCommandProfileScript.FollowDistance.FREE_ROAM:
		return profile.free_roam_engage_range
	return profile.drone_engage_range


func _get_anchor_velocity() -> Vector2:
	if order_anchor_active:
		return Vector2.ZERO
	if anchor == null or not is_instance_valid(anchor):
		return Vector2.ZERO
	var value = anchor.get("velocity")
	if value is Vector2:
		return value
	return Vector2.ZERO


func _should_pick_new_roam_goal() -> bool:
	if _roam_goal == Vector2.ZERO:
		return true
	if _roam_repath_timer <= 0.0:
		return true
	if global_position.distance_to(_roam_goal) <= profile.follow_arrive_distance:
		return true
	if _roam_goal.distance_to(_get_anchor_position()) > _get_active_leash_range():
		return true
	return false


func _pick_next_roam_goal() -> void:
	var angle_seed := float((_roam_sequence * 137 + _slot_index * 71 + 23) % 360)
	var radius_t := float((_roam_sequence * 53 + _slot_index * 29 + 11) % 100) / 99.0
	var radius := lerpf(profile.free_roam_min_radius, profile.free_roam_max_radius, radius_t)
	var angle := deg_to_rad(angle_seed)
	_roam_goal = _get_anchor_position() + Vector2(cos(angle), sin(angle)) * radius
	_roam_goal = _clamp_to_free_roam_leash(_roam_goal)
	var repath_t := float((_roam_sequence * 41 + _slot_index * 17 + 7) % 100) / 99.0
	_roam_repath_timer = lerpf(profile.free_roam_repath_min, profile.free_roam_repath_max, repath_t)
	_roam_sequence += 1


func _clamp_to_free_roam_leash(position: Vector2) -> Vector2:
	var anchor_position := _get_anchor_position()
	var from_anchor := position - anchor_position
	var leash_range := _get_active_leash_range()
	if from_anchor.length() <= leash_range:
		return position
	if from_anchor.length_squared() <= 0.001:
		return anchor_position
	return anchor_position + from_anchor.normalized() * leash_range


func _apply_separation(goal: Vector2) -> Vector2:
	var separated_goal := goal
	var anchor_position := _get_anchor_position()
	var from_anchor := separated_goal - anchor_position
	if from_anchor.length() < profile.follow_player_separation_radius:
		if from_anchor.length_squared() <= 0.001:
			from_anchor = _get_orbit_offset(maxf(profile.follow_player_separation_radius, _get_follow_radius()))
		separated_goal = anchor_position + from_anchor.normalized() * profile.follow_player_separation_radius

	var drones := get_tree().get_nodes_in_group("allied_drone")
	drones.sort_custom(func(a: Node, b: Node) -> bool:
		return String(a.get("drone_id")) < String(b.get("drone_id"))
	)
	for other in drones:
		if other == self or not (other is Node2D) or not is_instance_valid(other):
			continue
		if other.has_method("is_dead") and bool(other.call("is_dead")):
			continue
		var other_position := (other as Node2D).global_position
		var delta := separated_goal - other_position
		var distance := delta.length()
		if distance >= profile.drone_separation_radius:
			continue
		if delta.length_squared() <= 0.001:
			delta = Vector2.RIGHT.rotated(float(_slot_index + 1) * PI * 0.5)
		var push: float = (profile.drone_separation_radius - distance) * profile.drone_separation_strength
		separated_goal += delta.normalized() * push
	return separated_goal


func _get_active_leash_range() -> float:
	return profile.guard_order_leash_range if order_anchor_active else profile.free_roam_leash_range


func _must_return_to_order_anchor() -> bool:
	return order_anchor_active \
			and global_position.distance_to(order_anchor_position) > profile.guard_order_return_range


func _should_retreat() -> bool:
	if max_health <= 0.0:
		return false
	return health / max_health <= profile.drone_retreat_hp_threshold


func _update_weapon() -> void:
	if not fire_at_will:
		_burst_remaining = 0
		return
	if target == null or not is_instance_valid(target):
		_burst_remaining = 0
		return
	if global_position.distance_to(target.global_position) > profile.drone_weapon_range:
		return
	if _burst_remaining > 0:
		if _burst_gap_timer <= 0.0:
			_fire_once()
			_burst_remaining -= 1
			_burst_gap_timer = profile.drone_burst_gap
		return
	if _fire_cooldown_timer <= 0.0:
		_burst_remaining = max(1, profile.drone_burst_size)
		_fire_cooldown_timer = profile.drone_fire_cooldown


func _fire_once() -> void:
	if target == null or not is_instance_valid(target):
		return
	var bullet = BULLET_SCENE.instantiate()
	if bullet == null:
		return
	var spawn_position := global_position
	if muzzle != null:
		spawn_position = muzzle.global_position
	var direction := (target.global_position - spawn_position).normalized()
	if direction.length_squared() <= 0.001:
		return
	if bullet.has_method("set_direction"):
		bullet.call("set_direction", direction)
	bullet.set("damage", profile.drone_damage)
	bullet.set("team", "defense")
	bullet.set("shooter", self)
	bullet.set("bullet_color", Color(0.35, 0.95, 1.0, 1.0))
	bullet.set("max_range_px", profile.drone_weapon_range)
	bullet.set("falloff_start_px", profile.drone_weapon_range)
	bullet.set("falloff_end_px", profile.drone_weapon_range)
	bullet.set("terrain_ballistics_provider", _find_terrain_ballistics_provider())
	var container := get_node_or_null("/root/GameRoot/World/Projectiles")
	if container != null:
		container.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)
	bullet.global_position = spawn_position
	_play_mech_gunshot(spawn_position)


func _play_mech_gunshot(pos: Vector2) -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = MECH_GUNSHOT_SOUND
	player.volume_db = -4.0
	player.max_distance = 640.0
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		player.free()
		return
	parent.add_child(player)
	player.global_position = pos
	player.finished.connect(player.queue_free)
	player.play()


func get_terrain_ballistics_provider() -> Node:
	return _find_terrain_ballistics_provider()


func _find_terrain_ballistics_provider() -> Node:
	var providers := get_tree().get_nodes_in_group("terrain_ballistics_provider")
	return providers[0] if not providers.is_empty() else null


func take_damage(amount: float) -> void:
	if destroyed:
		return
	health = maxf(0.0, health - maxf(0.0, amount))
	if health <= 0.0:
		_destroy()
	else:
		_update_visuals()


func receive_projectile_hit(amount: float, source_team: String = "") -> Dictionary:
	if source_team == "defense" or source_team == "player":
		return {"blocked": false, "ignored": true}
	take_damage(amount)
	return {"blocked": false, "ignored": false}


func is_dead() -> bool:
	return destroyed


func _destroy() -> void:
	destroyed = true
	velocity = Vector2.ZERO
	remove_from_group("turret")
	remove_from_group("defense")
	if manager != null and manager.has_method("notify_drone_destroyed"):
		manager.call("notify_drone_destroyed", self)
	if collision_shape != null:
		collision_shape.disabled = true
	if visual != null:
		visual.modulate = Color(0.12, 0.12, 0.12, 0.55)
	if health_bar != null:
		health_bar.visible = false
	set_physics_process(false)


func _apply_profile() -> void:
	if profile == null:
		profile = DroneCommandProfileScript.new()
	max_health = profile.drone_hp
	health = min(max_health, health if health > 0.0 else max_health)
	if collision_shape != null:
		var circle := CircleShape2D.new()
		circle.radius = profile.drone_collision_radius
		collision_shape.shape = circle


func _update_visuals() -> void:
	var health_ratio := 1.0
	if max_health > 0.0:
		health_ratio = health / max_health
	if visual != null:
		if health_ratio <= profile.drone_retreat_hp_threshold:
			visual.modulate = critical_tint
		elif health_ratio < 0.65:
			visual.modulate = damaged_tint
		else:
			visual.modulate = base_tint
	if health_bar != null:
		health_bar.value = health_ratio * 100.0
