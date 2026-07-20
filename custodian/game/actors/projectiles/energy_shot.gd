extends Area2D

const CombatConstants = preload("res://game/systems/combat/combat_constants.gd")

@export var speed: float = 1200.0
@export var damage: float = 12.0
@export var max_lifetime: float = 1.2
@export var impact_scene: PackedScene
@export var bullet_color: Color = Color(0.3, 0.8, 1.0, 1.0)
@export var bullet_radius: float = 3.0
@export var team: String = "player"

const IMPACT_SPARK_SCENE := preload("res://game/actors/effects/impact_spark.tscn")

var direction := Vector2.RIGHT
var shooter: Node = null
var age := 0.0
var pulse_phase := 0.0

@onready var visual = get_node_or_null("Visual")
@onready var collision_shape = get_node_or_null("CollisionShape2D")
@onready var glow = get_node_or_null("Glow")


func _ready():
	_apply_visual_style()
	body_entered.connect(_on_body_entered)


func set_direction(dir: Vector2):
	if dir.length_squared() <= 0.0001:
		return
	direction = dir.normalized()
	rotation = direction.angle()


func _physics_process(delta):
	global_position += direction * speed * delta
	age += delta
	pulse_phase += delta * 15.0
	
	if glow:
		glow.modulate.a = 0.3 + 0.2 * sin(pulse_phase)
	
	if age >= max_lifetime:
		queue_free()


func _on_body_entered(body: Node):
	if body == shooter:
		return
	if body.has_method("receive_projectile_hit") and (_is_world_blocker(body) or _can_hit(body)):
		var impact_position := _resolve_impact_position(body)
		if body.is_in_group("runtime_wall_chunk"):
			body.call("receive_projectile_hit", damage, team, impact_position)
		else:
			body.call("receive_projectile_hit", damage, team)
		_apply_game_feel(body, 40.0 if not _is_world_blocker(body) else 0.0)
		_spawn_impact_at(impact_position)
		queue_free()
		return
	if _is_world_blocker(body):
		_spawn_impact_at(_resolve_impact_position(body))
		queue_free()
		return
	if not _can_hit(body):
		return

	if body.has_method("take_damage"):
		var impact_position := _resolve_impact_position(body)
		body.take_damage(damage, CombatConstants.HitStrength.LIGHT)
		_apply_game_feel(body, 50.0)
		_spawn_impact_at(impact_position)
		queue_free()
		return

	if body is StaticBody2D or body is CharacterBody2D:
		_spawn_impact_at(_resolve_impact_position(body))
		queue_free()


func _can_hit(body: Node) -> bool:
	if body == null:
		return false

	if body.has_method("get"):
		var collider_team = body.get("team")
		if collider_team != null and str(collider_team) == team:
			return false

	if team == "defense":
		if body.is_in_group("defense") or body.is_in_group("turret") or body.is_in_group("player"):
			return false
		return body.is_in_group("enemy") or body.is_in_group("enemies")

	if team == "enemy":
		if body.is_in_group("enemy") or body.is_in_group("enemies"):
			return false
		return body.is_in_group("player") or body.is_in_group("defense") or body.is_in_group("turret")

	if team == "player":
		if body.is_in_group("player"):
			return false
		return body.is_in_group("enemy") or body.is_in_group("enemies")

	return true


func _is_world_blocker(body: Node) -> bool:
	if body == null:
		return false
	if not (body is StaticBody2D):
		return false
	if body.is_in_group("player") or body.is_in_group("enemy") or body.is_in_group("enemies") or body.is_in_group("defense") or body.is_in_group("turret"):
		return false
	return true


func _spawn_impact(body: Node = null):
	_spawn_impact_at(_resolve_impact_position(body))


func _spawn_impact_at(impact_position: Vector2) -> void:
	var fx = IMPACT_SPARK_SCENE.instantiate()
	if fx == null:
		return
	var parent = get_parent()
	if parent:
		parent.add_child(fx)
	else:
		get_tree().current_scene.add_child(fx)
	fx.global_position = impact_position


func _apply_game_feel(hit_body: Node, knockback: float) -> void:
	if knockback > 0 and hit_body is CharacterBody2D:
		var knockback_dir = hit_body.global_position.direction_to(global_position)
		hit_body.velocity = knockback_dir * knockback
		hit_body.move_and_slide()


func _resolve_impact_position(body: Node = null) -> Vector2:
	if body is Node2D and not _is_world_blocker(body):
		return _resolve_body_contact_point(body as Node2D)
	return global_position - direction * max(4.0, bullet_radius * 2.0)


func _resolve_body_contact_point(body: Node2D) -> Vector2:
	var fallback: Vector2 = global_position - direction * max(4.0, bullet_radius * 2.0)
	var strike_direction: Vector2 = direction.normalized()
	if strike_direction == Vector2.ZERO:
		var to_body: Vector2 = body.global_position - global_position
		strike_direction = to_body.normalized()
	if strike_direction == Vector2.ZERO:
		return fallback
	return body.global_position - strike_direction * _estimate_body_contact_radius(body, bullet_radius * 2.0)


func _estimate_body_contact_radius(body: Node, fallback_radius: float) -> float:
	var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return fallback_radius
	var shape := shape_node.shape
	if shape is CircleShape2D:
		return max(fallback_radius, (shape as CircleShape2D).radius)
	if shape is RectangleShape2D:
		return max(fallback_radius, min((shape as RectangleShape2D).size.x, (shape as RectangleShape2D).size.y) * 0.5)
	if shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		return max(fallback_radius, capsule.radius + capsule.height * 0.25)
	return fallback_radius


func _apply_visual_style():
	if visual:
		visual.color = bullet_color
		visual.offset_left = -bullet_radius * 2
		visual.offset_top = -bullet_radius * 0.8
		visual.offset_right = bullet_radius * 2.5
		visual.offset_bottom = bullet_radius * 0.8
	
	if glow:
		glow.modulate = bullet_color
		glow.modulate.a = 0.4
	
	if collision_shape:
		var shape = CircleShape2D.new()
		shape.radius = bullet_radius
		collision_shape.shape = shape
