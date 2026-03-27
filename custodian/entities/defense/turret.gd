extends Damageable
class_name DefenseTurret

enum TurretType {
	GUNNER,
	BLASTER,
	REPEATER,
	SNIPER,
}

const BULLET_SCENE := preload("res://entities/defense/bullet.tscn")

@export var turret_name: String = "Turret"
@export var turret_type: TurretType = TurretType.GUNNER
@export var range: float = 250.0
@export var damage: float = 10.0
@export var fire_rate: float = 0.6
@export var power_required: bool = true

var target: Node2D = null
var fire_timer: float = 0.0
var sector_reference: Sector = null
var enemies_in_range: Array[Node2D] = []

const FIRE_EFFICIENCY_BY_STATE := {
	"operational": 1.0,
	"damaged": 0.6,
	"critical": 0.3,
	"destroyed": 0.0,
}

@onready var base_sprite: Sprite2D = $BaseSprite
@onready var barrel: Node2D = $Barrel
@onready var barrel_sprite: Sprite2D = $Barrel/BarrelSprite
@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	sector_reference = get_parent() as Sector
	configure_turret_type()

	if not range_area.body_entered.is_connected(_on_enemy_enter):
		range_area.body_entered.connect(_on_enemy_enter)
	if not range_area.body_exited.is_connected(_on_enemy_exit):
		range_area.body_exited.connect(_on_enemy_exit)

	add_to_group("turret")
	add_to_group("structure")
	add_to_group("defense")

	super._ready()
	_set_base_tint_by_type()
	_update_damage_visuals()


func configure_turret_type() -> void:
	match turret_type:
		TurretType.GUNNER:
			range = 250.0
			damage = 10.0
			fire_rate = 0.6
			max_health = 100.0
		TurretType.BLASTER:
			range = 180.0
			damage = 25.0
			fire_rate = 1.1
			max_health = 120.0
		TurretType.REPEATER:
			range = 200.0
			damage = 4.0
			fire_rate = 0.2
			max_health = 90.0
		TurretType.SNIPER:
			range = 400.0
			damage = 40.0
			fire_rate = 1.8
			max_health = 80.0

	current_health = min(current_health, max_health)
	_set_range_radius(range)


func _set_range_radius(radius: float) -> void:
	if range_shape == null:
		return
	if range_shape.shape == null or not (range_shape.shape is CircleShape2D):
		range_shape.shape = CircleShape2D.new()
	var circle := range_shape.shape as CircleShape2D
	circle.radius = max(8.0, radius)


func _physics_process(delta: float) -> void:
	if is_dead():
		return

	if not has_power():
		target = null
		_set_power_visual(false)
		return
	_set_power_visual(true)

	_prune_enemies_in_range()
	if target == null or not is_instance_valid(target):
		target = acquire_target()
	elif target.global_position.distance_to(global_position) > range:
		target = acquire_target()

	fire_timer -= delta
	if target:
		rotate_barrel()
		var fire_eff = float(FIRE_EFFICIENCY_BY_STATE.get(state, 0.0))
		var effective_fire_rate = fire_rate * fire_eff
		if effective_fire_rate <= 0.001:
			return
		if fire_timer <= 0.0:
			shoot()
			fire_timer = 1.0 / effective_fire_rate


func _on_enemy_enter(body: Node) -> void:
	if not (body is Node2D):
		return
	if not body.is_in_group("enemy") and not body.is_in_group("enemies"):
		return
	if body.has_method("is_passive_enemy") and bool(body.call("is_passive_enemy")):
		return
	var enemy := body as Node2D
	if enemies_in_range.has(enemy):
		return
	enemies_in_range.append(enemy)


func _on_enemy_exit(body: Node) -> void:
	if not (body is Node2D):
		return
	enemies_in_range.erase(body as Node2D)
	if body == target:
		target = null


func _prune_enemies_in_range() -> void:
	enemies_in_range = enemies_in_range.filter(func(enemy: Node2D) -> bool:
		if enemy == null or not is_instance_valid(enemy):
			return false
		if enemy.has_method("is_passive_enemy") and bool(enemy.call("is_passive_enemy")):
			return false
		if enemy.has_method("is_dead") and bool(enemy.is_dead()):
			return false
		if enemy.global_position.distance_to(global_position) > range:
			return false
		return true
	)


func acquire_target() -> Node2D:
	var closest: Node2D = null
	var closest_dist := INF

	for enemy in enemies_in_range:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("is_passive_enemy") and bool(enemy.call("is_passive_enemy")):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy

	return closest


func rotate_barrel() -> void:
	if target == null:
		return
	var dir = target.global_position - global_position
	if dir.length_squared() <= 0.0001:
		return
	barrel.rotation = dir.angle()


func shoot() -> void:
	if target == null or not is_instance_valid(target):
		return
	var bullet = BULLET_SCENE.instantiate()
	if bullet == null:
		return

	var spawn_position: Vector2 = muzzle.global_position
	var dir = (target.global_position - muzzle.global_position).normalized()
	if bullet.has_method("set_direction"):
		bullet.set_direction(dir)
	else:
		bullet.set("direction", dir)

	bullet.set("damage", damage)
	bullet.set("team", "defense")
	bullet.set("shooter", self)

	var container = get_node_or_null("/root/GameRoot/World/Projectiles")
	if container:
		container.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)
	bullet.global_position = spawn_position

	# Lightweight visual kickback.
	barrel.scale = Vector2(1.08, 1.08)
	get_tree().create_timer(0.05).timeout.connect(func() -> void:
		if is_instance_valid(barrel):
			barrel.scale = Vector2.ONE
	)


func has_power() -> bool:
	if not power_required:
		return true
	if sector_reference == null or not is_instance_valid(sector_reference):
		sector_reference = get_parent() as Sector
	if sector_reference == null:
		return true
	return bool(sector_reference.has_power)


func destroy() -> void:
	current_health = 0.0
	state = "destroyed"
	set_physics_process(false)
	range_area.monitoring = false
	barrel.visible = false
	base_sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)
	destroyed.emit()


func _on_state_changed(_new_state: String) -> void:
	_update_damage_visuals()


func _on_destroyed() -> void:
	destroy()


func _set_power_visual(powered: bool) -> void:
	if is_dead():
		return
	if powered:
		_update_damage_visuals()
	else:
		base_sprite.modulate = Color(0.35, 0.35, 0.35, 1.0)
		barrel_sprite.modulate = Color(0.35, 0.35, 0.35, 1.0)


func _update_damage_visuals() -> void:
	var hp_pct = get_efficiency()
	if hp_pct < 0.30:
		barrel_sprite.modulate = Color(0.9, 0.2, 0.2, 1.0)
	elif hp_pct < 0.60:
		barrel_sprite.modulate = Color(0.9, 0.7, 0.2, 1.0)
	else:
		barrel_sprite.modulate = Color(0.2, 0.8, 0.2, 1.0)

	base_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _set_base_tint_by_type() -> void:
	match turret_type:
		TurretType.GUNNER:
			base_sprite.modulate = Color(0.78, 0.86, 0.95, 1.0)
		TurretType.BLASTER:
			base_sprite.modulate = Color(0.96, 0.80, 0.72, 1.0)
		TurretType.REPEATER:
			base_sprite.modulate = Color(0.76, 0.92, 0.78, 1.0)
		TurretType.SNIPER:
			base_sprite.modulate = Color(0.80, 0.80, 1.0, 1.0)
