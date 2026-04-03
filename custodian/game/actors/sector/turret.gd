extends StaticBody2D
class_name Turret

enum TurretState {
	IDLE,
	TARGETING,
	FIRING,
	DISABLED,
	DESTROYED,
}

@export var turret_name: String = "Turret"
@export var turret_type: String = "gunner"  # gunner, blaster, repeater, sniper
@export var range: float = 250.0
@export var fire_rate: float = 1.0  # Shots per second
@export var damage: float = 15.0
@export var max_health: float = 100.0
@export var projectile_armor: float = 10.0
@export var bullet_scene: PackedScene = preload("res://game/actors/projectiles/bullet.tscn")
@export var muzzle_offset: float = 20.0
@export var spread_degrees: float = 2.0

const TURRET_STATS := {
	"gunner": {"damage": 15.0, "fire_rate": 1.0, "range": 250.0, "spread": 2.0, "max_health": 100.0},
	"blaster": {"damage": 35.0, "fire_rate": 0.5, "range": 180.0, "spread": 0.0, "max_health": 120.0},
	"repeater": {"damage": 8.0, "fire_rate": 4.0, "range": 220.0, "spread": 8.0, "max_health": 90.0},
	"sniper": {"damage": 60.0, "fire_rate": 0.3, "range": 500.0, "spread": 0.0, "max_health": 80.0},
}

var health: float = max_health
var fire_timer := 0.0
var target: Node2D = null
var barrel_angle := 0.0
var turret_state: TurretState = TurretState.IDLE

@onready var barrel = get_node_or_null("Barrel")
@onready var barrel_sprite = get_node_or_null("Barrel/Sprite")
@onready var base_visual = get_node_or_null("Base")


func _ready():
	_apply_turret_type()
	health = max_health
	add_to_group("turret")
	add_to_group("structure")
	_update_state_visuals()


func _physics_process(delta):
	if turret_state == TurretState.DESTROYED:
		return

	if not _has_power():
		target = null
		_set_turret_state(TurretState.DISABLED)
		return

	if turret_state == TurretState.DISABLED:
		_set_turret_state(TurretState.IDLE)

	fire_timer += delta
	target = _find_target()

	if target == null:
		_set_turret_state(TurretState.IDLE)
		return

	_set_turret_state(TurretState.TARGETING)
	_aim_at_target(target)

	var effective_fire_rate = fire_rate * get_efficiency()
	if effective_fire_rate > 0.01 and fire_timer >= (1.0 / effective_fire_rate):
		_set_turret_state(TurretState.FIRING)
		_fire()
		fire_timer = 0.0


func _apply_turret_type():
	var stats: Dictionary = TURRET_STATS.get(turret_type, TURRET_STATS["gunner"])
	damage = float(stats["damage"])
	fire_rate = float(stats["fire_rate"])
	range = float(stats["range"])
	spread_degrees = float(stats["spread"])
	max_health = float(stats["max_health"])


func _find_target() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := range

	for enemy in enemies:
		if not (enemy is Node2D):
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


func _aim_at_target(target_node: Node2D):
	var direction = (target_node.global_position - global_position).normalized()
	barrel_angle = direction.angle()
	if barrel:
		barrel.rotation = barrel_angle


func _fire():
	if target == null or bullet_scene == null:
		return
	if not _has_power():
		return

	var bullet = bullet_scene.instantiate()
	if bullet == null:
		return

	var direction = (target.global_position - global_position).normalized()
	if spread_degrees > 0.0:
		direction = direction.rotated(deg_to_rad(randf_range(-spread_degrees, spread_degrees)))

	var spawn_position: Vector2 = global_position + direction * muzzle_offset

	if bullet.has_method("set_direction"):
		bullet.set_direction(direction)
	bullet.set("damage", damage)
	bullet.set("team", "defense")
	bullet.set("shooter", self)

	var container = get_node_or_null("/root/GameRoot/World/Projectiles")
	if container:
		container.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)
	bullet.global_position = spawn_position


func _has_power() -> bool:
	var sector = get_parent()
	if sector and sector is Sector:
		return (sector as Sector).has_power
	return true


func _power_efficiency() -> float:
	var sector = get_parent()
	if sector and sector is Sector:
		var typed_sector = sector as Sector
		var max_p = float(typed_sector.max_power)
		if max_p <= 0.0:
			return 0.0
		return clamp(float(typed_sector.power) / max_p, 0.0, 1.0)
	return 1.0


func get_efficiency() -> float:
	if turret_state == TurretState.DESTROYED or turret_state == TurretState.DISABLED:
		return 0.0
	if not _has_power():
		return 0.0

	var hp_pct = _health_pct()
	var health_efficiency := 1.0
	if hp_pct <= 0.0:
		health_efficiency = 0.0
	elif hp_pct < 0.30:
		health_efficiency = 0.25
	elif hp_pct < 0.60:
		health_efficiency = 0.50

	return clamp(health_efficiency * _power_efficiency(), 0.0, 1.0)


func take_damage(amount: float):
	if turret_state == TurretState.DESTROYED:
		return

	health = max(0.0, health - amount)
	if health <= 0.0:
		_destroy()
		return
	_update_state_visuals()


func receive_projectile_hit(amount: float, _attacker_team: String = "neutral") -> Dictionary:
	if turret_state == TurretState.DESTROYED:
		return {
			"blocked": true,
			"applied_damage": 0.0,
		}
	var incoming: float = max(0.0, amount)
	var applied: float = max(0.0, incoming - max(0.0, projectile_armor))
	if applied <= 0.0:
		return {
			"blocked": true,
			"applied_damage": 0.0,
		}
	take_damage(applied)
	return {
		"blocked": false,
		"applied_damage": applied,
	}


func _health_pct() -> float:
	if max_health <= 0.0:
		return 0.0
	return clamp(health / max_health, 0.0, 1.0)


func _set_turret_state(new_state: TurretState):
	if turret_state == TurretState.DESTROYED and new_state != TurretState.DESTROYED:
		return
	if turret_state == new_state:
		return
	turret_state = new_state
	_update_state_visuals()


func _set_damage_band_color():
	var hp_pct = _health_pct()
	if hp_pct < 0.30:
		_set_barrel_color(Color(0.85, 0.2, 0.2, 1.0))
	elif hp_pct < 0.60:
		_set_barrel_color(Color(0.85, 0.65, 0.2, 1.0))
	else:
		_set_barrel_color(Color(0.2, 0.8, 0.2, 1.0))


func _update_state_visuals():
	match turret_state:
		TurretState.DESTROYED:
			_set_barrel_color(Color(0.25, 0.25, 0.25, 1.0))
			if base_visual:
				base_visual.color = Color(0.2, 0.2, 0.2, 1.0)
		TurretState.DISABLED:
			_set_damage_band_color()
			if base_visual:
				base_visual.modulate = Color(0.4, 0.4, 0.4, 1.0)
		_:
			_set_damage_band_color()
			if base_visual:
				base_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _set_barrel_color(color: Color):
	if barrel_sprite:
		barrel_sprite.modulate = color


func _destroy():
	target = null
	_set_turret_state(TurretState.DESTROYED)
	# Wreck remains in world as tactical geometry and repair candidate.


func is_dead() -> bool:
	return turret_state == TurretState.DESTROYED
