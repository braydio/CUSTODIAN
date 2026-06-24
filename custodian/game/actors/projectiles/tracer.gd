extends Area2D

@export var speed: float = 2000.0
@export var damage: float = 22.0
@export var max_lifetime: float = 0.8
@export var impact_scene: PackedScene
@export var bullet_color: Color = Color(1.0, 1.0, 0.5, 1.0)
@export var bullet_radius: float = 2.5
@export var team: String = "player"

const IMPACT_SPARK_SCENE := preload("res://game/actors/effects/impact_spark.tscn")

var direction := Vector2.RIGHT
var shooter: Node = null
var age := 0.0

@onready var visual = get_node_or_null("Visual")
@onready var collision_shape = get_node_or_null("CollisionShape2D")


func _ready():
	_apply_visual_style()
	body_entered.connect(_on_body_entered)


func set_direction(dir: Vector2):
	if dir.length_squared() <= 0.0001:
		return
	direction = dir.normalized()
	rotation = direction.angle()


func _physics_process(delta):
	var from: Vector2 = global_position
	var to: Vector2 = global_position + direction * speed * delta
	var hit: Dictionary = _sweep_projectile(from, to)
	if not hit.is_empty():
		global_position = hit.get("position", to)
		var collider: Object = hit.get("collider", null)
		if collider is Node and _handle_body_hit(collider as Node, global_position):
			return
	global_position = to
	age += delta
	if age >= max_lifetime:
		queue_free()


func _on_body_entered(body: Node):
	_handle_body_hit(body, _resolve_impact_position(body))


func _handle_body_hit(body: Node, impact_position: Vector2) -> bool:
	if body == shooter:
		return false
	if body.has_method("receive_projectile_hit") and (_is_world_blocker(body) or _can_hit(body)):
		body.call("receive_projectile_hit", damage, team)
		_apply_game_feel(body, 30.0 if not _is_world_blocker(body) else 0.0)
		_spawn_impact_at(impact_position)
		queue_free()
		return true
	if _is_world_blocker(body):
		_spawn_impact_at(impact_position)
		queue_free()
		return true
	if not _can_hit(body):
		return false

	if body.has_method("take_damage"):
		body.take_damage(damage)
		_apply_game_feel(body, 40.0)
		_spawn_impact_at(impact_position)
		queue_free()
		return true

	if body is StaticBody2D or body is CharacterBody2D:
		_spawn_impact_at(impact_position)
		queue_free()
		return true
	return false


func _sweep_projectile(from: Vector2, to: Vector2) -> Dictionary:
	if from.distance_squared_to(to) <= 0.01:
		return {}
	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		return {}
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = _get_sweep_exclusions()
	return space_state.intersect_ray(query)


func _get_sweep_exclusions() -> Array[RID]:
	var exclusions: Array[RID] = []
	exclusions.append(get_rid())
	if shooter is CollisionObject2D:
		exclusions.append((shooter as CollisionObject2D).get_rid())
	return exclusions


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
		visual.offset_left = -bullet_radius * 3
		visual.offset_top = -bullet_radius * 0.5
		visual.offset_right = bullet_radius * 3.0
		visual.offset_bottom = bullet_radius * 0.5
	if collision_shape:
		var shape = CircleShape2D.new()
		shape.radius = bullet_radius
		collision_shape.shape = shape
