extends Node
class_name VaultwingBehaviorController

## Focused deterministic authority for the wild Common Vaultwing.
## The actor owns health/public API; this node owns behavior, bands, targets,
## movement commitment, and transition timing.

enum Band { HIGH, ATTACK, GROUND, PERCHED }
enum State {
	HIGH_PATROL, CIRCLE_INTEREST, DIVE_WINDUP, DIVE_STRIKE, CLIMB_OUT,
	PERCH_IDLE, PERCH_ALERT, LAND, GROUND_IDLE, GROUND_STALK, GROUND_ATTACK,
	TAKEOFF, AIR_STAGGER, GROUND_STAGGER, RETREAT, DEAD
}

const PATROL_SPEED := 42.0
const DIVE_SPEED := 260.0
const CLIMB_SPEED := 150.0
const GROUND_SPEED := 34.0
const DIVE_WINDUP_SECONDS := 0.45
const DIVE_STRIKE_SECONDS := 0.30
const CLIMB_OUT_SECONDS := 0.55
const LAND_SECONDS := 0.35
const TAKEOFF_SECONDS := 0.50
const AIR_STAGGER_SECONDS := 0.45
const GROUND_STAGGER_SECONDS := 0.40
const RETREAT_SECONDS := 0.80

var actor: CharacterBody2D
var state: State = State.HIGH_PATROL
var band: Band = Band.HIGH
var state_elapsed := 0.0
var visual_altitude := 0.75
var target: Node2D
var target_position := Vector2.ZERO
var strike_vector := Vector2.RIGHT
var strike_hit := false
var retreat_vector := Vector2.RIGHT
var perch_positions: Array[Vector2] = []
var home_position := Vector2.ZERO
var patrol_direction := Vector2.RIGHT
var _rng := RandomNumberGenerator.new()
var _seeded := false

func configure(owner: CharacterBody2D) -> void:
	actor = owner
	if not _seeded:
		set_seed(hash("vaultwing_common"))
	_enter(State.HIGH_PATROL)

func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value
	_seeded = true
	patrol_direction = _direction_from_rng()

func set_home_position(position: Vector2) -> void:
	home_position = position

func set_perch_positions(positions: Array[Vector2]) -> void:
	perch_positions = positions.duplicate()

func request_interest(position: Vector2, source: Node2D = null) -> void:
	if state == State.DEAD or state == State.DIVE_STRIKE: return
	target_position = position
	target = source
	_enter(State.CIRCLE_INTEREST)

func request_dive(position: Vector2, source: Node2D = null) -> void:
	target_position = position
	target = source
	_enter(State.DIVE_WINDUP)

func request_land() -> void:
	if band == Band.HIGH or band == Band.ATTACK:
		_enter(State.LAND)

func request_takeoff() -> void:
	if band == Band.GROUND or band == Band.PERCHED:
		_enter(State.TAKEOFF)

func notify_damage(amount: float) -> void:
	if state == State.DEAD: return
	if band == Band.ATTACK and amount >= 18.0:
		_enter(State.AIR_STAGGER)
	elif band == Band.GROUND and state not in [State.GROUND_STAGGER, State.DEAD]:
		_enter(State.GROUND_STAGGER)

func force_state(next_state: State) -> void:
	_enter(next_state)

func step(delta: float) -> void:
	if actor == null or state == State.DEAD: return
	state_elapsed += delta
	actor.velocity = Vector2.ZERO
	match state:
		State.HIGH_PATROL:
			band = Band.HIGH
			actor.velocity = patrol_direction * PATROL_SPEED
			if state_elapsed >= 2.0:
				patrol_direction = patrol_direction.rotated(_rng.randf_range(-0.55, 0.55)).normalized()
				_enter(State.HIGH_PATROL)
		State.CIRCLE_INTEREST:
			band = Band.HIGH
			actor.velocity = patrol_direction * (PATROL_SPEED * 0.55)
			if state_elapsed >= 0.70:
				_enter(State.DIVE_WINDUP if target_position != Vector2.ZERO else State.HIGH_PATROL)
		State.DIVE_WINDUP:
			band = Band.ATTACK
			actor.velocity = Vector2.ZERO
			if state_elapsed == 0.0 or state_elapsed < 0.02:
				strike_vector = (target_position - actor.global_position).normalized()
				if strike_vector == Vector2.ZERO: strike_vector = Vector2.DOWN
			if state_elapsed >= DIVE_WINDUP_SECONDS:
				_enter(State.DIVE_STRIKE)
		State.DIVE_STRIKE:
			band = Band.ATTACK
			actor.velocity = strike_vector * DIVE_SPEED
			if not strike_hit and state_elapsed >= 0.08 and state_elapsed <= 0.22:
				strike_hit = true
				if is_instance_valid(target) and target.has_method("take_damage"):
					target.call("take_damage", 18.0)
					_log_event(&"vaultwing_dive_hit", {"target": target.name})
			if state_elapsed >= DIVE_STRIKE_SECONDS:
				_log_event(&"vaultwing_dive_missed", {}) if not strike_hit else null
				_enter(State.CLIMB_OUT)
		State.CLIMB_OUT:
			band = Band.ATTACK
			actor.velocity = (-strike_vector + Vector2.UP * 0.8).normalized() * CLIMB_SPEED
			if state_elapsed >= CLIMB_OUT_SECONDS:
				_enter(State.HIGH_PATROL)
		State.PERCH_IDLE, State.PERCH_ALERT:
			band = Band.PERCHED
			if state == State.PERCH_IDLE and state_elapsed >= 1.2: _enter(State.HIGH_PATROL)
		State.LAND:
			band = Band.GROUND
			if state_elapsed >= LAND_SECONDS: _enter(State.GROUND_IDLE)
		State.GROUND_IDLE:
			band = Band.GROUND
			if state_elapsed >= 1.4: _enter(State.TAKEOFF)
		State.GROUND_STALK:
			band = Band.GROUND
			actor.velocity = patrol_direction * GROUND_SPEED
			if state_elapsed >= 1.0: _enter(State.GROUND_IDLE)
		State.GROUND_ATTACK:
			band = Band.GROUND
			if state_elapsed >= 0.12 and state_elapsed <= 0.28 and not strike_hit:
				strike_hit = true
				if is_instance_valid(target) and target.has_method("take_damage"):
					target.call("take_damage", 12.0)
			if state_elapsed >= 0.52: _enter(State.GROUND_IDLE)
		State.TAKEOFF:
			band = Band.GROUND if state_elapsed < TAKEOFF_SECONDS * 0.35 else Band.HIGH
			if state_elapsed >= TAKEOFF_SECONDS: _enter(State.HIGH_PATROL)
		State.AIR_STAGGER:
			band = Band.ATTACK
			if state_elapsed >= AIR_STAGGER_SECONDS: _enter(State.LAND)
		State.GROUND_STAGGER:
			band = Band.GROUND
			if state_elapsed >= GROUND_STAGGER_SECONDS: _enter(State.GROUND_IDLE)
		State.RETREAT:
			band = Band.ATTACK if state_elapsed < 0.25 else Band.HIGH
			actor.velocity = retreat_vector * CLIMB_SPEED
			if state_elapsed >= RETREAT_SECONDS: _enter(State.HIGH_PATROL)
	_publish_presentation()

func get_state_name() -> StringName:
	return StringName(State.keys()[state].to_lower())

func get_band_name() -> StringName:
	return StringName(Band.keys()[band].to_lower())

func _enter(next_state: State) -> void:
	state = next_state
	state_elapsed = 0.0
	strike_hit = false
	match state:
		State.HIGH_PATROL: band = Band.HIGH
		State.CIRCLE_INTEREST: band = Band.HIGH
		State.DIVE_WINDUP, State.DIVE_STRIKE, State.CLIMB_OUT, State.AIR_STAGGER: band = Band.ATTACK
		State.PERCH_IDLE, State.PERCH_ALERT: band = Band.PERCHED
		State.LAND, State.GROUND_IDLE, State.GROUND_STALK, State.GROUND_ATTACK, State.GROUND_STAGGER: band = Band.GROUND
		State.TAKEOFF: band = Band.GROUND
		State.RETREAT: band = Band.ATTACK
		State.DEAD: band = Band.GROUND
	if state == State.DIVE_WINDUP: _log_event(&"vaultwing_dive_started", {})
	if state == State.LAND: _log_event(&"vaultwing_landed", {})
	if state == State.TAKEOFF: _log_event(&"vaultwing_takeoff", {})
	if state == State.RETREAT: _log_event(&"vaultwing_retreat_started", {})
	if state == State.AIR_STAGGER: _log_event(&"vaultwing_air_staggered", {})

func _publish_presentation() -> void:
	if actor.has_method("play_action"):
		var action := _presentation_action_for_state()
		if action != &"": actor.call("play_action", action)
	if actor.has_method("apply_visual_altitude"):
		var target_altitude := 0.75 if band == Band.HIGH else (0.52 if band == Band.ATTACK else 0.0)
		if state == State.DIVE_STRIKE: target_altitude = 0.10
		if state == State.CLIMB_OUT: target_altitude = 0.70
		visual_altitude = move_toward(visual_altitude, target_altitude, 2.4 / 60.0)
		actor.call("apply_visual_altitude", visual_altitude)

func _presentation_action_for_state() -> StringName:
	match state:
		State.HIGH_PATROL, State.CIRCLE_INTEREST:
			return &"glide"
		State.DIVE_WINDUP:
			return &"dive_windup"
		State.DIVE_STRIKE:
			return &"dive_strike"
		State.CLIMB_OUT, State.RETREAT:
			return &"climb_out"
		State.PERCH_IDLE, State.PERCH_ALERT:
			return &"perch_idle"
		State.LAND:
			return &"land"
		State.GROUND_IDLE:
			return &"ground_idle"
		State.GROUND_STALK:
			return &"ground_walk"
		State.GROUND_ATTACK:
			return &"bite_attack"
		State.TAKEOFF:
			return &"takeoff"
		State.AIR_STAGGER:
			return &"air_stagger"
		State.GROUND_STAGGER:
			return &"hurt"
		State.DEAD:
			return &"death"
	return &""

func _direction_from_rng() -> Vector2:
	var angle := _rng.randf_range(-PI, PI)
	return Vector2.RIGHT.rotated(angle).normalized()

func _log_event(event_name: StringName, payload: Dictionary) -> void:
	var observatory := actor.get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", event_name, payload)
