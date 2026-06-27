extends CharacterBody2D
class_name CombatDrone

const BULLET_SCENE := preload("res://game/actors/defense/bullet.tscn")
const DroneCommandProfileScript := preload("res://game/systems/drone/drone_command_profile.gd")
const DroneTargetingScript := preload("res://game/systems/drone/drone_targeting.gd")

@export var drone_id: String = "DRONE_01"
@export var base_tint: Color = Color(0.35, 0.82, 0.95, 1.0)
@export var damaged_tint: Color = Color(1.0, 0.65, 0.24, 1.0)
@export var critical_tint: Color = Color(1.0, 0.22, 0.18, 1.0)

var profile: Resource = DroneCommandProfileScript.new()
var squad_mode: int = DroneCommandProfileScript.Mode.FOLLOW
var anchor: Node2D = null
var manager: Node = null
var max_health: float = 45.0
var health: float = 45.0
var destroyed: bool = false
var target: Node2D = null

# When false, _update_weapon skips firing. Toggled by allied_infantry_droid.
var fire_at_will: bool = true

var _slot_index: int = 0
var _hold_position: Vector2 = Vector2.ZERO
var _fire_cooldown_timer: float = 0.0
var _burst_remaining: int = 0
var _burst_gap_timer: float = 0.0
var _targeting: RefCounted = DroneTargetingScript.new()

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
	set_mode(DroneCommandProfileScript.Mode.FOLLOW)


func set_mode(mode: int) -> void:
	squad_mode = mode
	if mode == DroneCommandProfileScript.Mode.HOLD:
		_hold_position = global_position


func _physics_process(delta: float) -> void:
	if destroyed:
		return
	_fire_cooldown_timer = maxf(0.0, _fire_cooldown_timer - delta)
	_burst_gap_timer = maxf(0.0, _burst_gap_timer - delta)
	_refresh_target()
	_update_movement(delta)
	_update_weapon()
	_update_visuals()


func _refresh_target() -> void:
	if squad_mode == DroneCommandProfileScript.Mode.RECALL:
		target = null
		return
	if target != null and is_instance_valid(target) and not _targeting.is_invalid_enemy(target):
		var range_origin := anchor.global_position if anchor != null else global_position
		if target.global_position.distance_to(range_origin) <= profile.drone_engage_range:
			return
	target = _targeting.acquire_target(self, anchor, squad_mode, profile)


func _update_movement(delta: float) -> void:
	var desired_position := _get_desired_position()
	var to_goal := desired_position - global_position
	var desired_velocity := Vector2.ZERO
	if to_goal.length() > 4.0:
		desired_velocity = to_goal.normalized() * profile.drone_speed
	velocity = velocity.move_toward(desired_velocity, profile.drone_acceleration * delta)
	move_and_slide()


func _get_desired_position() -> Vector2:
	if anchor == null or not is_instance_valid(anchor):
		return global_position
	if _should_retreat():
		var retreat_dir := Vector2.RIGHT
		if target != null and is_instance_valid(target):
			retreat_dir = (anchor.global_position - target.global_position).normalized()
		if retreat_dir.length_squared() <= 0.001:
			retreat_dir = Vector2.RIGHT.rotated(float(_slot_index) * PI)
		return anchor.global_position + retreat_dir * profile.follow_orbit_radius
	match squad_mode:
		DroneCommandProfileScript.Mode.HOLD:
			if _hold_position.distance_to(anchor.global_position) > profile.hold_leash_range:
				return anchor.global_position + _get_orbit_offset()
			return _hold_position
		DroneCommandProfileScript.Mode.INTERCEPT:
			if target != null and is_instance_valid(target):
				var away_from_anchor := (target.global_position - anchor.global_position).normalized()
				if away_from_anchor.length_squared() > 0.001:
					return target.global_position - away_from_anchor * profile.intercept_standoff
			return anchor.global_position + _get_orbit_offset()
		DroneCommandProfileScript.Mode.RECALL:
			return anchor.global_position + _get_orbit_offset().normalized() * profile.recall_distance
		_:
			return anchor.global_position + _get_orbit_offset()


func _get_orbit_offset() -> Vector2:
	var side := -1.0 if _slot_index % 2 == 0 else 1.0
	var ring := float(_slot_index / 2) * 18.0
	return Vector2(side * (profile.follow_orbit_radius + ring), -24.0)


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
	var container := get_node_or_null("/root/GameRoot/World/Projectiles")
	if container != null:
		container.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)
	bullet.global_position = spawn_position


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
