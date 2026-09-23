extends Node
class_name VaultwingBehaviorController

enum Band { HIGH, ATTACK, GROUND, PERCHED }
enum State { HIGH_PATROL, CIRCLE_INTEREST, DIVE_WINDUP, DIVE_STRIKE, CLIMB_OUT, PERCH_IDLE, PERCH_ALERT, LAND, GROUND_IDLE, GROUND_STALK, GROUND_ATTACK, TAKEOFF, AIR_STAGGER, GROUND_STAGGER, RETREAT, DEAD }

const PROFILE := preload("res://game/actors/ambient/vaultwing/vaultwing_behavior_profile.tres")

var actor: CharacterBody2D
var profile: Resource = PROFILE
var state: State = State.HIGH_PATROL
var band: Band = Band.HIGH
var state_elapsed := 0.0
var visual_altitude := 0.75
var target: Node2D
var target_position := Vector2.ZERO
var target_position_valid := false
var strike_vector := Vector2.RIGHT
var committed_attack_vector := Vector2.RIGHT
var strike_hit := false
var strike_contact_tested := false
var retreat_vector := Vector2.RIGHT
var perch_positions: Array[Vector2] = []
var home_position := Vector2.ZERO
var patrol_direction := Vector2.RIGHT
var selected_perch := Vector2.ZERO
var selected_perch_valid := false
var _rng := RandomNumberGenerator.new()
var _seeded := false
var _interest_elapsed := 0.0
var _perch_index := 0
var _failed_engagement_elapsed := 0.0
var _pending_after_takeoff: StringName = &""
var _perch_approach_active := false
var _landing_to_perch := false

func _ready() -> void:
	var bus := get_node_or_null("/root/NoiseEventBus")
	if bus != null and bus.has_signal("noise_emitted"): bus.noise_emitted.connect(_on_noise_emitted)

func configure(owner: CharacterBody2D) -> void:
	actor = owner
	if not _seeded: set_seed(hash("vaultwing_common"))
	_enter(State.HIGH_PATROL)

func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value; _seeded = true; patrol_direction = _direction_from_rng()

func set_home_position(position: Vector2) -> void: home_position = position

func set_perch_positions(positions: Array[Vector2]) -> void:
	perch_positions = positions.duplicate()
	perch_positions.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.x < b.x if not is_equal_approx(a.x, b.x) else a.y < b.y
	)

func _remember_target(position: Vector2, source: Node2D = null) -> void:
	target_position = position
	target_position_valid = true
	target = source

func request_interest(position: Vector2, source: Node2D = null) -> void:
	if state == State.DEAD or state in [State.DIVE_WINDUP, State.DIVE_STRIKE, State.CLIMB_OUT, State.AIR_STAGGER, State.GROUND_STAGGER, State.LAND, State.TAKEOFF, State.GROUND_ATTACK, State.RETREAT]:
		_remember_target(position, source)
		return
	_remember_target(position, source)
	_interest_elapsed = 0.0
	if band == Band.HIGH:
		_enter(State.CIRCLE_INTEREST)
	elif band == Band.PERCHED:
		_enter(State.PERCH_ALERT)
	elif state == State.GROUND_IDLE:
		_enter(State.GROUND_STALK)

func request_dive(position: Vector2, source: Node2D = null) -> void:
	if state == State.DEAD or actor == null: return
	_remember_target(position, source)
	if band == Band.PERCHED:
		_pending_after_takeoff = &"INTEREST"
		_enter(State.PERCH_ALERT)
	elif band == Band.GROUND:
		_pending_after_takeoff = &"INTEREST"
		_enter(State.TAKEOFF)
	else:
		_enter(State.DIVE_WINDUP)

func request_land() -> void:
	if band == Band.HIGH or band == Band.ATTACK:
		_landing_to_perch = _select_perch()
		if _landing_to_perch and actor.global_position.distance_to(selected_perch) > profile.perch_approach_radius:
			_perch_approach_active = true
			_enter(State.HIGH_PATROL)
		else:
			_enter(State.LAND)

func request_takeoff() -> void:
	if band == Band.GROUND or band == Band.PERCHED: _enter(State.TAKEOFF)

func notify_damage(amount: float) -> void:
	if state == State.DEAD: return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null: _remember_target(player.global_position, player)
	if actor != null and actor.health / maxf(actor.max_health, 1.0) <= profile.low_health_ratio:
		retreat_vector = _compute_retreat_vector()
		if band == Band.GROUND or band == Band.PERCHED:
			_pending_after_takeoff = &"RETREAT"
			_enter(State.TAKEOFF)
		elif band == Band.ATTACK and state != State.AIR_STAGGER:
			_enter(State.RETREAT)
		return
	if band == Band.ATTACK and amount >= profile.air_stagger_threshold and state not in [State.AIR_STAGGER, State.CLIMB_OUT]:
		_enter(State.AIR_STAGGER)
	elif band == Band.GROUND and state not in [State.GROUND_STAGGER, State.GROUND_ATTACK, State.TAKEOFF]:
		_enter(State.GROUND_STAGGER)

func force_state(next_state: State) -> void: _enter(next_state)

func step(delta: float) -> void:
	if actor == null or state == State.DEAD: return
	state_elapsed += delta; actor.velocity = Vector2.ZERO; _update_player_interest(delta)
	match state:
		State.HIGH_PATROL:
			_set_band(Band.HIGH); actor.velocity = patrol_direction * profile.patrol_speed
			if _perch_approach_active and selected_perch_valid:
				actor.velocity = actor.global_position.direction_to(selected_perch) * profile.patrol_speed
				if actor.global_position.distance_to(selected_perch) <= profile.perch_approach_radius:
					_perch_approach_active = false
					_landing_to_perch = true
					_enter(State.LAND)
			elif state_elapsed >= 2.0 and not _perch_approach_active:
				if not _perch_approach_active and _should_use_perch() and _select_perch():
					_perch_approach_active = true
				else:
					patrol_direction = patrol_direction.rotated(_rng.randf_range(-0.55, 0.55)).normalized(); _enter(State.HIGH_PATROL)
		State.CIRCLE_INTEREST:
			_set_band(Band.HIGH); actor.velocity = patrol_direction * profile.patrol_speed * 0.55; _interest_elapsed += delta
			if _has_valid_target(): target_position = target.global_position
			if target_position_valid and _interest_elapsed >= 0.70: _enter(State.DIVE_WINDUP)
			elif _interest_elapsed >= 1.6: _enter(State.HIGH_PATROL)
		State.DIVE_WINDUP:
			_set_band(Band.ATTACK)
			if state_elapsed >= profile.dive_windup_seconds: _enter(State.DIVE_STRIKE)
		State.DIVE_STRIKE:
			_set_band(Band.ATTACK); actor.velocity = strike_vector * profile.dive_speed
			if not strike_hit and state_elapsed >= 0.08 and state_elapsed <= 0.22:
				if _hit_target_with_shape(profile.dive_damage, &"dash"):
					strike_hit = true; strike_contact_tested = true; _log_event(&"vaultwing_dive_hit", {"target": target.name if is_instance_valid(target) else ""})
			if state_elapsed >= profile.dive_strike_seconds:
				if not strike_hit: _log_event(&"vaultwing_dive_missed", {})
				_enter(State.CLIMB_OUT)
		State.CLIMB_OUT:
			_set_band(Band.ATTACK); actor.velocity = (-strike_vector + Vector2.UP * 0.8).normalized() * profile.climb_speed
			if state_elapsed >= profile.climb_out_seconds: _enter(State.HIGH_PATROL)
		State.PERCH_IDLE:
			_set_band(Band.PERCHED)
			if state_elapsed >= profile.perch_dwell_seconds: _enter(State.TAKEOFF)
		State.PERCH_ALERT:
			_set_band(Band.PERCHED)
			if state_elapsed >= profile.perch_alert_seconds: _pending_after_takeoff = &"INTEREST"; _enter(State.TAKEOFF)
		State.LAND:
			_set_band(Band.GROUND)
			if state_elapsed >= profile.land_seconds: _enter(State.PERCH_IDLE if _landing_to_perch else State.GROUND_IDLE); _landing_to_perch = false
		State.GROUND_IDLE:
			_set_band(Band.GROUND)
			if _target_in_range(profile.ground_attack_range): _enter(State.GROUND_ATTACK)
			elif _has_valid_target() and actor.global_position.distance_to(target.global_position) <= profile.engagement_radius: _enter(State.GROUND_STALK)
			elif state_elapsed >= 1.4: _enter(State.TAKEOFF)
		State.GROUND_STALK:
			_set_band(Band.GROUND); _failed_engagement_elapsed += delta
			if not _has_valid_target() or actor.global_position.distance_to(target.global_position) > profile.engagement_radius: _enter(State.RETREAT)
			elif _failed_engagement_elapsed >= profile.failed_engagement_seconds: _pending_after_takeoff = &"RETREAT"; _enter(State.TAKEOFF)
			elif _target_in_range(profile.ground_attack_range): _enter(State.GROUND_ATTACK)
			else: actor.velocity = actor.global_position.direction_to(target.global_position) * profile.ground_speed
		State.GROUND_ATTACK:
			_set_band(Band.GROUND)
			if not strike_hit and state_elapsed >= 0.12 and state_elapsed <= 0.28:
				if _hit_target_with_shape(profile.bite_damage, &"melee"): strike_hit = true; strike_contact_tested = true
			if state_elapsed >= 0.52: _enter(State.GROUND_STALK if _has_valid_target() else State.GROUND_IDLE)
		State.TAKEOFF:
			_set_band(Band.GROUND if state_elapsed < profile.takeoff_seconds * 0.35 else Band.HIGH)
			if state_elapsed >= profile.takeoff_seconds:
				var pending := _pending_after_takeoff; _pending_after_takeoff = &""
				if pending == &"INTEREST": _enter(State.CIRCLE_INTEREST)
				elif pending == &"RETREAT": _enter(State.RETREAT)
				else: _enter(State.HIGH_PATROL)
		State.AIR_STAGGER:
			_set_band(Band.ATTACK)
			if state_elapsed >= profile.air_stagger_seconds: _enter(State.LAND)
		State.GROUND_STAGGER:
			_set_band(Band.GROUND)
			if state_elapsed >= profile.ground_stagger_seconds: _enter(State.GROUND_STALK if _has_valid_target() else State.GROUND_IDLE)
		State.RETREAT:
			_set_band(Band.ATTACK if state_elapsed < 0.25 else Band.HIGH); actor.velocity = retreat_vector * profile.climb_speed
			if state_elapsed >= profile.retreat_seconds: _enter(State.HIGH_PATROL)
	_publish_presentation(delta)

func get_state_name() -> StringName: return StringName(State.keys()[state].to_lower())
func get_band_name() -> StringName: return StringName(Band.keys()[band].to_lower())

func _enter(next_state: State) -> void:
	state = next_state; state_elapsed = 0.0; strike_hit = false; strike_contact_tested = false
	match state:
		State.HIGH_PATROL, State.CIRCLE_INTEREST: _set_band(Band.HIGH)
		State.DIVE_WINDUP, State.DIVE_STRIKE, State.CLIMB_OUT, State.AIR_STAGGER: _set_band(Band.ATTACK)
		State.PERCH_IDLE, State.PERCH_ALERT: _set_band(Band.PERCHED)
		State.LAND, State.GROUND_IDLE, State.GROUND_STALK, State.GROUND_ATTACK, State.GROUND_STAGGER: _set_band(Band.GROUND)
		State.TAKEOFF: _set_band(Band.GROUND)
		State.RETREAT: _set_band(Band.ATTACK)
		State.DEAD: _set_band(Band.GROUND)
	if state == State.GROUND_STALK: _failed_engagement_elapsed = 0.0
	if state == State.AIR_STAGGER: _landing_to_perch = false
	if state == State.GROUND_ATTACK:
		committed_attack_vector = actor.global_position.direction_to(target.global_position) if _has_valid_target() else patrol_direction
		if committed_attack_vector.length_squared() < 0.01: committed_attack_vector = Vector2.RIGHT
	if state == State.DIVE_WINDUP:
		strike_vector = actor.global_position.direction_to(target_position) if target_position_valid else patrol_direction
		if strike_vector.length_squared() < 0.01: strike_vector = Vector2.DOWN
		committed_attack_vector = strike_vector
		_log_event(&"vaultwing_dive_started", {})
	if state == State.LAND: _log_event(&"vaultwing_landed", {})
	if state == State.TAKEOFF: _log_event(&"vaultwing_takeoff", {})
	if state == State.RETREAT: _log_event(&"vaultwing_retreat_started", {})
	if state == State.AIR_STAGGER: _log_event(&"vaultwing_air_staggered", {})
	if actor != null and actor.has_method("set_band_interaction"): actor.call("set_band_interaction", band)

func _set_band(next_band: Band) -> void:
	if band == next_band and actor != null and not is_zero_approx(state_elapsed): return
	band = next_band
	if actor != null and actor.has_method("set_band_interaction"):
		actor.call("set_band_interaction", band)

func _publish_presentation(delta: float) -> void:
	if actor.has_method("play_action"):
		var action := _presentation_action_for_state()
		if action != &"": actor.call("play_action", action)
	if actor.has_method("apply_visual_altitude"):
		var target_altitude := 0.75 if band == Band.HIGH else (0.52 if band == Band.ATTACK else 0.0)
		if state == State.DIVE_STRIKE: target_altitude = 0.10
		if state == State.CLIMB_OUT: target_altitude = 0.70
		visual_altitude = move_toward(visual_altitude, target_altitude, 2.4 * delta); actor.call("apply_visual_altitude", visual_altitude)

func _presentation_action_for_state() -> StringName:
	match state:
		State.HIGH_PATROL, State.CIRCLE_INTEREST: return &"glide"
		State.DIVE_WINDUP: return &"dive_windup"
		State.DIVE_STRIKE: return &"dive_strike"
		State.CLIMB_OUT, State.RETREAT: return &"climb_out"
		State.PERCH_IDLE, State.PERCH_ALERT: return &"perch_idle"
		State.LAND: return &"land"
		State.GROUND_IDLE: return &"ground_idle"
		State.GROUND_STALK: return &"ground_walk"
		State.GROUND_ATTACK: return &"bite_attack"
		State.TAKEOFF: return &"takeoff"
		State.AIR_STAGGER: return &"air_stagger"
		State.GROUND_STAGGER: return &"hurt"
		State.DEAD: return &"death"
	return &""

func _update_player_interest(delta: float) -> void:
	if state != State.HIGH_PATROL: return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null: return
	if actor.global_position.distance_to(player.global_position) <= profile.awareness_radius:
		_interest_elapsed += delta
		if _interest_elapsed >= 0.75: request_interest(player.global_position, player)
	else: _interest_elapsed = 0.0

func _on_noise_emitted(event: Variant) -> void:
	if state != State.HIGH_PATROL or actor == null or event == null: return
	var position: Vector2 = event.get("position", Vector2.INF); var radius := float(event.get("radius_px", 0.0))
	if position == Vector2.INF or radius <= 0.0 or actor.global_position.distance_to(position) > radius: return
	request_interest(position, event.get("source") as Node2D)

func _has_valid_target() -> bool: return is_instance_valid(target) and target is Node2D
func _target_in_range(distance: float) -> bool: return _has_valid_target() and actor.global_position.distance_to(target.global_position) <= distance

func _select_perch() -> bool:
	if perch_positions.is_empty(): return false
	selected_perch = perch_positions[_perch_index % perch_positions.size()]; _perch_index += 1; selected_perch_valid = true; return true

func _should_use_perch() -> bool: return not perch_positions.is_empty() and _rng.randf() < 0.20

func _hit_target_with_shape(amount: float, hit_kind: StringName) -> bool:
	if not _has_valid_target() or not _target_is_in_strike_shape(): return false
	var result: Variant; var direction := strike_vector if hit_kind == &"dash" else actor.global_position.direction_to(target.global_position)
	var context := {"contact_model":"vaultwing_shape", "spatial_valid":true, "contact_position":target.global_position, "vaultwing_attack":String(hit_kind)}
	if target.has_method("receive_enemy_hit"): result = target.call("receive_enemy_hit", amount, hit_kind, "enemy", actor, direction, -1.0, context)
	elif target.has_method("take_damage"): result = target.call("take_damage", amount)
	else: return false
	return result is Dictionary and float((result as Dictionary).get("applied_damage", 0.0)) > 0.0

func _target_is_in_strike_shape() -> bool:
	var target_pos := target.global_position
	var direction: Vector2 = strike_vector if state == State.DIVE_STRIKE else committed_attack_vector
	var origin: Vector2 = actor.global_position + direction * 44.0
	var shape_node := actor.get_node_or_null("StrikeArea/StrikeShape") as CollisionShape2D
	if shape_node == null or shape_node.shape == null: return actor.global_position.distance_to(target_pos) <= profile.ground_attack_range
	var query := PhysicsShapeQueryParameters2D.new(); query.shape = shape_node.shape; query.transform = Transform2D(direction.angle(), origin); query.collision_mask = 0x7fffffff; query.collide_with_bodies = true
	for hit in actor.get_world_2d().direct_space_state.intersect_shape(query, 16):
		var collider := hit.get("collider") as Node
		if collider == target or (collider != null and target.is_ancestor_of(collider)) or (collider != null and collider.is_ancestor_of(target)): return true
	return false

func _compute_retreat_vector() -> Vector2:
	if _has_valid_target():
		var away := target.global_position.direction_to(actor.global_position)
		if away.length_squared() > 0.01: return away.normalized()
	var toward_home := actor.global_position.direction_to(home_position)
	if actor.global_position.distance_to(home_position) > profile.territorial_radius and toward_home.length_squared() > 0.01:
		return toward_home.normalized()
	var safe := -strike_vector
	return safe.normalized() if safe.length_squared() > 0.01 else patrol_direction

func _direction_from_rng() -> Vector2: return Vector2.RIGHT.rotated(_rng.randf_range(-PI, PI)).normalized()

func _log_event(event_name: StringName, payload: Dictionary) -> void:
	var observatory := actor.get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"): observatory.call("log_event", event_name, payload)
