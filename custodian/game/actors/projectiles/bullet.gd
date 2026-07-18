extends Area2D

const CombatConstants = preload("res://game/systems/combat/combat_constants.gd")

@export var speed: float = 760.0
@export var damage: float = 18.0
@export var max_lifetime: float = 1.6
@export var impact_scene: PackedScene = preload("res://game/actors/effects/impact_spark.tscn")
@export var bullet_color: Color = Color(1.0, 0.85, 0.25, 1.0)
@export var bullet_radius: float = 4.0
@export var team: String = "player"  # player, defense, enemy, or neutral
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 1.5
@export var max_range_px: float = 320.0
@export var falloff_start_px: float = 180.0
@export var falloff_end_px: float = 320.0
@export var min_damage_multiplier: float = 0.45
@export var terrain_ballistics_enabled: bool = true
@export var terrain_ballistics_debug: bool = false
@export var visual_sprite_frames: SpriteFrames
@export var visual_animation: StringName = &"travel"
@export var rotate_visual_to_direction: bool = true
@export var impact_rotation_enabled: bool = true
@export var hide_visual_before_impact: bool = true

const BLOCK_SPARK_SCENE := preload("res://game/actors/effects/block_spark.tscn")
const TerrainBallistics := preload("res://game/world/procgen/terrain/terrain_ballistics.gd")

static var _warning_once := {}

var direction := Vector2.RIGHT
var shooter: Node = null
var terrain_ballistics_provider: Node = null
var age := 0.0
var _distance_traveled := 0.0
var _terrain_query_fail_open := true
var _terrain_query_warning_printed := false
var _last_step_from := Vector2.ZERO
var _last_step_to := Vector2.ZERO
var _last_step_terrain_allowed := true
var _impact_committed := false

@onready var visual = get_node_or_null("Visual")
@onready var collision_shape = get_node_or_null("CollisionShape2D")


func _ready():
	_apply_visual_style()
	body_entered.connect(_on_body_entered)


func set_direction(dir: Vector2):
	if dir.length_squared() <= 0.0001:
		return
	direction = dir.normalized()
	if rotate_visual_to_direction:
		rotation = direction.angle()


func configure_visual(frames: SpriteFrames, animation_name: StringName = &"travel", scale_value: Vector2 = Vector2.ONE) -> void:
	visual_sprite_frames = frames
	visual_animation = animation_name
	if visual is AnimatedSprite2D:
		var sprite := visual as AnimatedSprite2D
		sprite.scale = scale_value
		_apply_visual_style()


func _physics_process(delta):
	var from: Vector2 = global_position
	var to: Vector2 = global_position + direction * speed * delta
	var traveled_this_step := from.distance_to(to)
	_last_step_from = from
	_last_step_to = to
	var terrain_result := _query_terrain_ballistics(from, to)
	_last_step_terrain_allowed = bool(terrain_result.get("allowed", _terrain_query_fail_open))
	if not _last_step_terrain_allowed:
		var blocked_position: Vector2 = terrain_result.get("blocked_at_world", to)
		var terrain_normal: Vector2 = terrain_result.get("normal", terrain_result.get("surface_normal", -direction))
		traveled_this_step = from.distance_to(blocked_position)
		global_position = blocked_position
		_distance_traveled += traveled_this_step
		_spawn_impact_at(blocked_position, terrain_normal)
		queue_free()
		return
	var hit: Dictionary = _sweep_projectile(from, to)
	if not hit.is_empty():
		var hit_position: Vector2 = hit.get("position", to)
		traveled_this_step = from.distance_to(hit_position)
		global_position = hit_position
		var collider: Object = hit.get("collider", null)
		if collider is Node:
			var collider_node := collider as Node
			if not (_last_step_terrain_allowed and _is_generated_terrain_collision(collider_node)):
				if _handle_body_hit(collider_node, global_position, hit.get("normal", Vector2.ZERO)):
					return
		traveled_this_step += hit_position.distance_to(to)
	global_position = to
	_distance_traveled += traveled_this_step
	age += delta
	if age >= max_lifetime or _distance_traveled >= max_range_px:
		queue_free()


func _on_body_entered(body: Node):
	if _last_step_terrain_allowed and _is_generated_terrain_collision(body):
		return
	_handle_body_hit(body, _resolve_impact_position(body), Vector2.ZERO)


func set_terrain_ballistics_provider(provider: Node) -> void:
	terrain_ballistics_provider = provider


func _resolve_terrain_ballistics_provider() -> Node:
	if terrain_ballistics_provider != null and is_instance_valid(terrain_ballistics_provider):
		return terrain_ballistics_provider
	if shooter != null and is_instance_valid(shooter) and shooter.has_method("get_terrain_ballistics_provider"):
		var shooter_provider: Variant = shooter.call("get_terrain_ballistics_provider")
		if shooter_provider is Node and is_instance_valid(shooter_provider):
			terrain_ballistics_provider = shooter_provider
			return terrain_ballistics_provider
	if get_tree() == null:
		return null
	var providers := get_tree().get_nodes_in_group("terrain_ballistics_provider")
	if not providers.is_empty():
		terrain_ballistics_provider = providers[0]
	return terrain_ballistics_provider


func _query_terrain_ballistics(from: Vector2, to: Vector2) -> Dictionary:
	if not terrain_ballistics_enabled:
		return {"allowed": true, "blocked_by": "disabled"}
	var provider := _resolve_terrain_ballistics_provider()
	if provider == null or not provider.has_method("can_trace_projectile"):
		return {"allowed": true, "blocked_by": "no_terrain_provider"}
	var result_variant: Variant = provider.call("can_trace_projectile", from, to)
	if result_variant is Dictionary and (result_variant as Dictionary).has("allowed"):
		return result_variant as Dictionary
	if terrain_ballistics_debug and not _terrain_query_warning_printed:
		_terrain_query_warning_printed = true
		push_warning("[TerrainBallistics] Provider returned no allowed field; projectile query failed open.")
	return {"allowed": _terrain_query_fail_open, "blocked_by": "invalid_terrain_result"}


func _is_generated_terrain_collision(body: Node) -> bool:
	var provider := _resolve_terrain_ballistics_provider()
	return provider != null \
			and provider.has_method("is_terrain_collision_body") \
			and bool(provider.call("is_terrain_collision_body", body))


func _handle_body_hit(body: Node, impact_position: Vector2, surface_normal: Vector2 = Vector2.ZERO) -> bool:
	if _impact_committed:
		return true
	if body == shooter:
		return false
	if body.has_method("receive_projectile_hit") and (_is_world_blocker(body) or _can_hit(body)):
		var result_variant: Variant = body.call("receive_projectile_hit", get_scaled_damage(), team)
		var was_blocked: bool = _extract_blocked_result(result_variant)
		_apply_game_feel(body, 0.0)
		if was_blocked:
			_spawn_block_impact_at(impact_position)
		else:
			_spawn_impact_at(impact_position, surface_normal)
		queue_free()
		return true
	if _is_world_blocker(body):
		_spawn_impact_at(impact_position, surface_normal)
		queue_free()
		return true
	if not _can_hit(body):
		return false

	if body.has_method("take_damage"):
		var final_damage: float = get_scaled_damage()
		if crit_chance > 0.0 and randf() < crit_chance:
			final_damage *= crit_multiplier
		var bullet_hit_strength := CombatConstants.HitStrength.HEAVY if final_damage >= damage * 1.5 else CombatConstants.HitStrength.LIGHT
		body.take_damage(final_damage, bullet_hit_strength)
		_apply_game_feel(body, 60.0)
		_spawn_impact_at(impact_position, surface_normal)
		queue_free()
		return true

	if body is StaticBody2D or body is CharacterBody2D:
		_spawn_impact_at(impact_position, surface_normal)
		queue_free()
		return true
	return false


func get_scaled_damage() -> float:
	if falloff_end_px <= falloff_start_px:
		return damage
	var t := clampf((_distance_traveled - falloff_start_px) / (falloff_end_px - falloff_start_px), 0.0, 1.0)
	return damage * lerpf(1.0, min_damage_multiplier, t)


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
	_spawn_impact_at(_resolve_impact_position(body), Vector2.ZERO)


func _spawn_impact_at(impact_position: Vector2, surface_normal: Vector2 = Vector2.ZERO) -> void:
	if _impact_committed:
		return
	_impact_committed = true
	_hide_or_stop_visual_before_impact()
	if impact_scene == null:
		_warn_once(&"missing_impact_scene", "[Bullet] Missing impact_scene; projectile will free without impact VFX.")
		return
	var fx = impact_scene.instantiate()
	if fx == null:
		return
	var parent = get_parent()
	if parent:
		parent.add_child(fx)
	else:
		get_tree().current_scene.add_child(fx)
	fx.global_position = impact_position
	if fx.has_method("configure_impact"):
		fx.call("configure_impact", direction, surface_normal)
	elif impact_rotation_enabled:
		var orient := surface_normal if surface_normal.length_squared() > 0.0001 else -direction
		if orient.length_squared() > 0.0001:
			fx.rotation = orient.angle()


func _spawn_block_impact(body: Node = null) -> void:
	_spawn_block_impact_at(_resolve_impact_position(body))


func _spawn_block_impact_at(impact_position: Vector2) -> void:
	if _impact_committed:
		return
	_impact_committed = true
	_hide_or_stop_visual_before_impact()
	if BLOCK_SPARK_SCENE == null:
		_spawn_impact_at(impact_position)
		return
	var fx = BLOCK_SPARK_SCENE.instantiate()
	if fx == null:
		_spawn_impact_at(impact_position)
		return
	var parent = get_parent()
	if parent:
		parent.add_child(fx)
	else:
		get_tree().current_scene.add_child(fx)
	fx.global_position = impact_position


func _extract_blocked_result(result_variant: Variant) -> bool:
	if result_variant is Dictionary:
		var result: Dictionary = result_variant
		return bool(result.get("blocked", false))
	return false


func _apply_game_feel(hit_body: Node, knockback: float) -> void:
	# Knockback
	if knockback > 0 and hit_body is CharacterBody2D:
		var knockback_dir = hit_body.global_position.direction_to(global_position)
		hit_body.velocity = knockback_dir * knockback
		hit_body.move_and_slide()


func _resolve_impact_position(body: Node = null) -> Vector2:
	if body is Node2D and not _is_world_blocker(body):
		return _resolve_body_contact_point(body as Node2D)
	return global_position - direction * max(4.0, bullet_radius * 1.5)


func _resolve_body_contact_point(body: Node2D) -> Vector2:
	var fallback: Vector2 = global_position - direction * max(4.0, bullet_radius * 1.5)
	var strike_direction := direction.normalized()
	if strike_direction == Vector2.ZERO:
		var to_body := body.global_position - global_position
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
	if visual is AnimatedSprite2D:
		var sprite := visual as AnimatedSprite2D
		if visual_sprite_frames != null:
			sprite.sprite_frames = visual_sprite_frames
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(visual_animation):
			sprite.animation = visual_animation
			sprite.play(visual_animation)
		elif sprite.sprite_frames == null:
			_warn_once(&"missing_projectile_sprite_frames", "[Bullet] Missing projectile SpriteFrames; animated tracer unavailable.")
		else:
			_warn_once(&"missing_projectile_animation", "[Bullet] Projectile SpriteFrames missing animation '%s'." % String(visual_animation))
		sprite.centered = true
		sprite.visible = sprite.sprite_frames != null and sprite.sprite_frames.has_animation(sprite.animation)
	elif visual is ColorRect:
		var fallback := visual as ColorRect
		fallback.color = bullet_color
		fallback.offset_left = -bullet_radius
		fallback.offset_top = -bullet_radius * 0.5
		fallback.offset_right = bullet_radius * 2.2
		fallback.offset_bottom = bullet_radius * 0.5
	if collision_shape:
		var shape = CircleShape2D.new()
		shape.radius = bullet_radius
		collision_shape.shape = shape


func _hide_or_stop_visual_before_impact() -> void:
	if not hide_visual_before_impact or visual == null:
		return
	if visual is AnimatedSprite2D:
		(visual as AnimatedSprite2D).stop()
	if visual is CanvasItem:
		(visual as CanvasItem).visible = false


func _warn_once(key: StringName, message: String) -> void:
	if _warning_once.has(key):
		return
	_warning_once[key] = true
	push_warning(message)
