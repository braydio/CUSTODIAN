extends Area2D

@export var speed: float = 380.0
@export var damage: float = 45.0
@export var max_lifetime: float = 3.0
@export var impact_scene: PackedScene
@export var bullet_color: Color = Color(1.0, 0.3, 0.1, 1.0)
@export var bullet_radius: float = 8.0
@export var team: String = "enemy"

const BLOCK_SPARK_SCENE := preload("res://game/actors/effects/block_spark.tscn")
const IMPACT_SPARK_SCENE := preload("res://game/actors/effects/impact_spark.tscn")

var direction := Vector2.RIGHT
var shooter: Node = null
var age := 0.0
var has_spawned_trail := false

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
	global_position += direction * speed * delta
	age += delta
	
	if age >= max_lifetime:
		queue_free()
		return
	
	if not has_spawned_trail and age > 0.1:
		has_spawned_trail = true
		_spawn_missile_trail()


func _on_body_entered(body: Node):
	if body == shooter:
		return
	if body.has_method("receive_projectile_hit") and (_is_world_blocker(body) or _can_hit(body)):
		var result_variant: Variant = body.call("receive_projectile_hit", damage, team)
		_apply_game_feel(body, 80.0 if not _is_world_blocker(body) else 0.0)
		_spawn_explosion()
		queue_free()
		return
	if _is_world_blocker(body):
		_spawn_explosion()
		queue_free()
		return
	if not _can_hit(body):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
		_apply_game_feel(body, 100.0)
		_spawn_explosion()
		queue_free()
		return

	if body is StaticBody2D or body is CharacterBody2D:
		_spawn_explosion()
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


func _spawn_missile_trail():
	var trail = Sprite2D.new()
	trail.texture = _create_trail_texture()
	trail.modulate = bullet_color
	trail.modulate.a = 0.6
	trail.position = Vector2(-bullet_radius * 2, 0)
	trail.rotation = -direction.angle()
	add_child(trail)


func _create_trail_texture() -> Texture2D:
	var img = Image.create(32, 8, false, Image.FORMAT_RGBA8)
	for x in range(32):
		for y in range(8):
			var dist = float(x) / 32.0
			var alpha = 1.0 - dist
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)


func _spawn_explosion():
	var fx = IMPACT_SPARK_SCENE.instantiate()
	if fx == null:
		return
	fx.global_position = global_position
	var parent = get_parent()
	if parent:
		parent.add_child(fx)
	else:
		get_tree().current_scene.add_child(fx)


func _apply_game_feel(hit_body: Node, knockback: float) -> void:
	if knockback > 0 and hit_body is CharacterBody2D:
		var knockback_dir = hit_body.global_position.direction_to(global_position)
		hit_body.velocity = knockback_dir * knockback
		hit_body.move_and_slide()


func _apply_visual_style():
	if visual:
		visual.color = bullet_color
		visual.offset_left = -bullet_radius * 1.5
		visual.offset_top = -bullet_radius
		visual.offset_right = bullet_radius * 3.0
		visual.offset_bottom = bullet_radius
	if collision_shape:
		var shape = CircleShape2D.new()
		shape.radius = bullet_radius
		collision_shape.shape = shape
