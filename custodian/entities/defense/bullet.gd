extends Area2D

@export var speed: float = 760.0
@export var damage: float = 12.0
@export var max_lifetime: float = 1.6
@export var team: String = "neutral"
@export var bullet_color: Color = Color(0.78, 1.0, 0.82, 1.0)
@export var bullet_radius: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var shooter: Node = null
var age: float = 0.0

@onready var visual = get_node_or_null("Visual")
@onready var collision_shape = get_node_or_null("CollisionShape2D")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_visual_style()


func set_direction(dir: Vector2) -> void:
	if dir.length_squared() <= 0.0001:
		return
	direction = dir.normalized()
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	age += delta
	if age >= max_lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	if _is_world_blocker(body):
		queue_free()
		return

	if not _can_hit(body):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
		return

	if body is StaticBody2D or body is CharacterBody2D:
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


func _apply_visual_style() -> void:
	if visual:
		visual.color = bullet_color
		visual.offset_left = -bullet_radius
		visual.offset_top = -bullet_radius * 0.5
		visual.offset_right = bullet_radius * 2.0
		visual.offset_bottom = bullet_radius * 0.5
	if collision_shape:
		var shape = CircleShape2D.new()
		shape.radius = bullet_radius
		collision_shape.shape = shape
