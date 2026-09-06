extends CharacterBody2D
class_name BabyOpossum

## Baby Opossum ambient creature.
##
## Behavior is owned by an explicit action state machine: every state names one
## semantic animation, a movement mode, and the state it hands off to when the
## clip (or its authored duration) completes. Nothing plays two animations in
## one tick, and no state can be overwritten by ambient wandering while it is
## running — hide, play-dead, flee, treat, rejection, and scavenging sequences
## are all observable at their authored pace.
##
## Simulation is deterministic: all randomness comes from a seeded RNG whose
## seed is supplied by the spawner (see `set_ambient_seed`), never from
## wall-clock time or instance identity.

const PRESENTATION := preload("res://game/actors/ambient/ambient_creature_presentation_controller.gd")
const AttackRejection := preload("res://game/systems/combat/attack_rejection.gd")
const ANIMATION_SET := preload("res://game/actors/ambient/baby_opossum/baby_opossum_animation_set.tres")
const PROP_LAYER := &"barrel_prop"
const DEFAULT_ACTION_SECONDS := 0.45
const ARRIVAL_DISTANCE_SQUARED := 16.0

enum TrustStage { WILD, WARY, FED, FAMILIAR, FRIEND }
enum Movement { LOCKED, WANDER, FLEE, APPROACH }
enum State {
	IDLE, WANDER, ALERT,
	FLEE_START, FLEE,
	REJECT_HIT, DISAPPROVE,
	PLAY_DEAD_ENTER, PLAY_DEAD_HOLD, PLAY_DEAD_PEEK, PLAY_DEAD_EXIT,
	HIDE_ENTER, HIDE_HOLD, HIDE_PEEK, HIDE_EXIT,
	TREAT_NOTICE, TREAT_APPROACH, TREAT_SNIFF, TREAT_TAKE, TREAT_EAT, FRIEND_HAPPY,
	SEARCH, DIG, FIND_TARGET, LOOK_BACK, EXCITED_IDLE,
	RETRIEVE, GIFT_DROP
}

# action:    semantic clip the state owns.
# movement:  what the body is allowed to do while the state runs.
# hold:      state never expires on its own; only an API call leaves it.
# duration:  explicit seconds; omitted means "as long as the authored clip".
# next:      state entered when the timer expires.
const STATE_TABLE := {
	State.IDLE: {"action": &"idle", "movement": Movement.WANDER, "hold": true},
	State.WANDER: {"action": &"waddle", "movement": Movement.WANDER, "hold": true},
	State.ALERT: {"action": &"alert", "movement": Movement.LOCKED, "next": State.IDLE},
	State.FLEE_START: {"action": &"flee_start", "movement": Movement.LOCKED, "next": State.FLEE},
	State.FLEE: {"action": &"scurry", "movement": Movement.FLEE, "duration": 2.4, "next": State.ALERT},
	State.REJECT_HIT: {"action": &"reject_hit", "movement": Movement.LOCKED, "next": State.DISAPPROVE},
	State.DISAPPROVE: {"action": &"disapprove", "movement": Movement.LOCKED, "duration": 0.72, "next": State.FLEE_START},
	State.PLAY_DEAD_ENTER: {"action": &"play_dead_enter", "movement": Movement.LOCKED, "next": State.PLAY_DEAD_HOLD},
	State.PLAY_DEAD_HOLD: {"action": &"play_dead_hold", "movement": Movement.LOCKED, "hold": true},
	State.PLAY_DEAD_PEEK: {"action": &"play_dead_peek", "movement": Movement.LOCKED, "next": State.PLAY_DEAD_HOLD},
	State.PLAY_DEAD_EXIT: {"action": &"play_dead_exit", "movement": Movement.LOCKED, "next": State.ALERT},
	State.HIDE_ENTER: {"action": &"hide_enter", "movement": Movement.LOCKED, "next": State.HIDE_HOLD},
	State.HIDE_HOLD: {"action": &"hide_hold", "movement": Movement.LOCKED, "hold": true},
	State.HIDE_PEEK: {"action": &"hide_peek", "movement": Movement.LOCKED, "next": State.HIDE_HOLD},
	State.HIDE_EXIT: {"action": &"hide_exit", "movement": Movement.LOCKED, "next": State.IDLE},
	State.TREAT_NOTICE: {"action": &"notice_treat", "movement": Movement.LOCKED, "next": State.TREAT_APPROACH},
	State.TREAT_APPROACH: {"action": &"approach_wary", "movement": Movement.APPROACH, "duration": 1.2, "next": State.TREAT_SNIFF},
	State.TREAT_SNIFF: {"action": &"sniff_treat", "movement": Movement.LOCKED, "next": State.TREAT_TAKE},
	State.TREAT_TAKE: {"action": &"take_treat", "movement": Movement.LOCKED, "next": State.TREAT_EAT},
	State.TREAT_EAT: {"action": &"eat", "movement": Movement.LOCKED, "duration": 1.0, "next": State.FRIEND_HAPPY},
	State.FRIEND_HAPPY: {"action": &"friend_happy", "movement": Movement.LOCKED, "next": State.IDLE},
	State.SEARCH: {"action": &"search", "movement": Movement.LOCKED, "duration": 0.9, "next": State.IDLE},
	State.DIG: {"action": &"dig", "movement": Movement.LOCKED, "next": State.FIND_TARGET},
	State.FIND_TARGET: {"action": &"find_target", "movement": Movement.LOCKED, "next": State.LOOK_BACK},
	State.LOOK_BACK: {"action": &"look_back", "movement": Movement.LOCKED, "next": State.EXCITED_IDLE},
	State.EXCITED_IDLE: {"action": &"excited_idle", "movement": Movement.LOCKED, "duration": 1.1, "next": State.IDLE},
	State.RETRIEVE: {"action": &"retrieve", "movement": Movement.APPROACH, "duration": 1.6, "next": State.IDLE},
	State.GIFT_DROP: {"action": &"gift_drop", "movement": Movement.LOCKED, "next": State.IDLE}
}

const AMBIENT_STATES := {State.IDLE: true, State.WANDER: true}
const PLAY_DEAD_STATES := {State.PLAY_DEAD_ENTER: true, State.PLAY_DEAD_HOLD: true, State.PLAY_DEAD_PEEK: true}
const HIDE_STATES := {State.HIDE_ENTER: true, State.HIDE_HOLD: true, State.HIDE_PEEK: true}
const FLEE_STATES := {State.FLEE_START: true, State.FLEE: true}

signal treat_accepted(treat: Node)
signal trust_stage_changed(stage: int)
signal attack_rejected(context: Dictionary)
signal target_found(target: Node)
signal gift_dropped(target: Node)

@export var move_speed := 30.0
@export var flee_speed_multiplier := 2.2
@export var wander_radius := 96.0
@export var flee_safe_distance := 220.0
@export var search_radius := 240.0
@export var trust_stage: TrustStage = TrustStage.WILD
@export var trust_points := 0
@export var behavior_enabled := true

@onready var body_sprite: AnimatedSprite2D = $Body
@onready var prop_sprite: AnimatedSprite2D = get_node_or_null("HideProp")
@onready var presentation := PRESENTATION.new()

var facing_direction := Vector2.DOWN
var home_position := Vector2.ZERO
var carrying_target: Node = null
# Read-only mirrors of the state machine, kept for external queries.
var fleeing := false
var play_dead := false
var is_hidden := false

static var _spawn_ordinal := 0

var _state: int = State.IDLE
var _state_timer := 0.0
var _chained_next := -1
var _wander_target := Vector2.ZERO
var _wander_timer := 0.0
var _approach_target := Vector2.ZERO
var _flee_origin := Vector2.ZERO
var _home_initialized := false
var _seeded := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("ambient_creature")
	add_to_group("ambient_critter")
	add_to_group("passive_target")
	add_to_group(AttackRejection.GROUP)
	_spawn_ordinal += 1
	# Deterministic fallback seed; the spawner normally overrides it immediately.
	if not _seeded: set_ambient_seed(hash("baby_opossum") + _spawn_ordinal)
	home_position = global_position
	_wander_target = home_position
	var extra_layers := {}
	if prop_sprite != null: extra_layers[PROP_LAYER] = prop_sprite
	presentation.setup(ANIMATION_SET, body_sprite, extra_layers)
	_configure_detectors()
	_enter_state(State.IDLE)

func _physics_process(delta: float) -> void:
	if not behavior_enabled: return
	if not _home_initialized: set_passive_home_position(global_position)
	_tick_state(delta)
	_apply_movement(delta)
	move_and_slide()

# --- Spawner contract -------------------------------------------------------

## Called by the spawner after the actor has been placed. `_ready` runs while
## the node is still at the container origin, so wander must anchor here.
func set_passive_home_position(position: Vector2) -> void:
	home_position = position
	_wander_target = position
	_wander_timer = 0.0
	_home_initialized = true

## Deterministic per-instance seed supplied by the spawner. Never reseeded per
## decision, so an identical contract replays identical wander behavior.
func set_ambient_seed(seed_value: int) -> void:
	_rng.seed = seed_value
	_seeded = true
	_wander_timer = 0.0

# --- Presentation passthrough ----------------------------------------------

func play_action(action: StringName, restart := false) -> bool: return presentation.play_action(action, facing_direction, restart)
func has_action(action: StringName) -> bool: return presentation.has_action(action, facing_direction)
func get_action_duration(action: StringName) -> float: return presentation.get_action_duration(action, facing_direction)
func get_animation_capabilities() -> Dictionary: return presentation.get_animation_capabilities()
func get_missing_animation_actions() -> Array[StringName]: return presentation.get_missing_animation_actions()
func has_prop_layer_action(action: StringName) -> bool: return presentation.has_layer_action(PROP_LAYER, action, facing_direction)

func get_state() -> int: return _state
func get_state_action() -> StringName: return StringName((STATE_TABLE[_state] as Dictionary).get("action", &"idle"))
func is_movement_locked() -> bool: return int((STATE_TABLE[_state] as Dictionary).get("movement", Movement.LOCKED)) == Movement.LOCKED

# --- Damage / attack rejection ---------------------------------------------

func take_damage(_amount: float, _hit_strength := 0, _reaction_damage := -1.0) -> Dictionary:
	return {"applied_damage":0.0,"damage_applied":0.0,"target_was_alive":true,"target_health_before":0.0,"target_health_after":0.0,"lethal":false,"blocked":true,"deflected":true,"invulnerable":true,"eligible_hostile":false,"passive":true}

func is_attack_rejector() -> bool: return true

## Generic passive-target rejection used by projectiles and melee sweeps.
func reject_attack(context: Dictionary = {}) -> Dictionary:
	var origin: Vector2 = context.get("origin", context.get("impact_position", global_position - facing_direction * 32.0))
	var attacker: Variant = context.get("attacker", null)
	if attacker is Node2D and is_instance_valid(attacker): origin = (attacker as Node2D).global_position
	var projectile: Variant = context.get("projectile", null)
	if projectile is Node and is_instance_valid(projectile) and projectile.has_method("queue_free"): (projectile as Node).call_deferred("queue_free")
	_begin_rejection(origin)
	attack_rejected.emit(context)
	return {"rejected": true, "deflected": true, "blocked": true, "invulnerable": true, "passive": true, "damage_applied": 0.0, "applied_damage": 0.0}

func reject_projectile(projectile: Node = null) -> bool:
	var origin := (projectile as Node2D).global_position if projectile is Node2D and is_instance_valid(projectile) else global_position - facing_direction * 32.0
	reject_attack({"kind": &"projectile", "projectile": projectile, "origin": origin})
	return true

func reject_melee(attacker: Node = null) -> bool:
	reject_attack({"kind": &"melee", "attacker": attacker})
	return true

func on_nearby_attack(origin: Vector2) -> void:
	_face_toward(origin)
	if _is_interruptible(): _enter_state(State.ALERT)

# --- Behavior API -----------------------------------------------------------

func flee_from(origin: Vector2) -> void:
	_flee_origin = origin
	_face_away_from(origin)
	_enter_state(State.FLEE_START)

func stop_fleeing() -> void:
	if FLEE_STATES.has(_state): _enter_state(State.IDLE)

func receive_treat(treat: Node = null) -> bool:
	if PLAY_DEAD_STATES.has(_state) or HIDE_STATES.has(_state): return false
	if treat is Node2D and is_instance_valid(treat):
		_approach_target = (treat as Node2D).global_position
		_face_toward(_approach_target)
	else:
		_approach_target = global_position
	trust_points += 1
	var previous := trust_stage
	trust_stage = mini(int(TrustStage.FRIEND), 1 + trust_points / 2)
	if trust_stage != previous: trust_stage_changed.emit(int(trust_stage))
	_enter_state(State.TREAT_NOTICE)
	treat_accepted.emit(treat)
	return true

func begin_play_dead() -> void:
	if PLAY_DEAD_STATES.has(_state): return
	_enter_state(State.PLAY_DEAD_ENTER)

func peek_from_play_dead() -> void:
	if _state == State.PLAY_DEAD_HOLD: _enter_state(State.PLAY_DEAD_PEEK)

func end_play_dead() -> void:
	if PLAY_DEAD_STATES.has(_state): _enter_state(State.PLAY_DEAD_EXIT)

func enter_hide() -> void:
	if HIDE_STATES.has(_state): return
	_enter_state(State.HIDE_ENTER)

func peek_from_hide() -> void:
	if _state == State.HIDE_HOLD: _enter_state(State.HIDE_PEEK)

func exit_hide() -> void:
	if HIDE_STATES.has(_state): _enter_state(State.HIDE_EXIT)

## Local sensory sweep for discoverable objects. Returns the nearest candidate
## inside `search_radius`, and runs the dig/point/look-back sequence when one
## is found.
func search_for_target() -> Node:
	var nearest: Node2D = null
	var best := search_radius * search_radius
	for candidate in get_tree().get_nodes_in_group("opossum_discoverable"):
		if not candidate is Node2D or not is_instance_valid(candidate): continue
		var candidate_distance := global_position.distance_squared_to((candidate as Node2D).global_position)
		if candidate_distance <= best:
			nearest = candidate as Node2D
			best = candidate_distance
	if nearest == null:
		_enter_state(State.SEARCH)
		return null
	_approach_target = nearest.global_position
	_face_toward(_approach_target)
	_enter_state(State.SEARCH, State.DIG)
	target_found.emit(nearest)
	return nearest

func retrieve(target: Node = null) -> bool:
	carrying_target = target
	if target is Node2D and is_instance_valid(target):
		_approach_target = (target as Node2D).global_position
		_face_toward(_approach_target)
	else:
		_approach_target = global_position
	_enter_state(State.RETRIEVE)
	return true

func gift_drop() -> void:
	var dropped := carrying_target
	carrying_target = null
	_enter_state(State.GIFT_DROP)
	gift_dropped.emit(dropped)

# --- State machine ----------------------------------------------------------

func _enter_state(state: int, chain_to := -1) -> void:
	_state = state
	var entry: Dictionary = STATE_TABLE[state]
	var action := StringName(entry.get("action", &"idle"))
	_state_timer = 0.0 if bool(entry.get("hold", false)) else _resolve_duration(entry, action)
	_chained_next = chain_to
	fleeing = FLEE_STATES.has(state)
	play_dead = PLAY_DEAD_STATES.has(state)
	is_hidden = HIDE_STATES.has(state)
	if int(entry.get("movement", Movement.LOCKED)) == Movement.LOCKED: velocity = Vector2.ZERO
	play_action(action, true)

func _tick_state(delta: float) -> void:
	var entry: Dictionary = STATE_TABLE[_state]
	if bool(entry.get("hold", false)):
		if AMBIENT_STATES.has(_state): _tick_ambient(delta)
		return
	if _state == State.FLEE and global_position.distance_to(_flee_origin) >= flee_safe_distance:
		_enter_state(State.ALERT)
		return
	_state_timer = maxf(0.0, _state_timer - delta)
	if _state_timer > 0.0: return
	var next := _chained_next if _chained_next >= 0 else int(entry.get("next", State.IDLE))
	_chained_next = -1
	_enter_state(_resolve_next_state(_state, next))

## Lets a completing state pick a different successor from live actor data.
func _resolve_next_state(finished: int, proposed: int) -> int:
	if finished == State.TREAT_EAT and int(trust_stage) < int(TrustStage.FED): return State.IDLE
	return proposed

func _resolve_duration(entry: Dictionary, action: StringName) -> float:
	if entry.has("duration"): return maxf(0.0, float(entry["duration"]))
	var authored := get_action_duration(action)
	return authored if authored > 0.0 else DEFAULT_ACTION_SECONDS

func _tick_ambient(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0: _choose_wander_target()
	var offset := _wander_target - global_position
	if offset.length_squared() > ARRIVAL_DISTANCE_SQUARED:
		facing_direction = offset.normalized()
		if _state != State.WANDER: _enter_state(State.WANDER)
		else: play_action(&"waddle")
	elif _state != State.IDLE:
		_enter_state(State.IDLE)

func _apply_movement(_delta: float) -> void:
	match int((STATE_TABLE[_state] as Dictionary).get("movement", Movement.LOCKED)):
		Movement.WANDER:
			var offset := _wander_target - global_position
			velocity = offset.normalized() * move_speed if offset.length_squared() > ARRIVAL_DISTANCE_SQUARED else Vector2.ZERO
		Movement.FLEE:
			velocity = facing_direction * move_speed * flee_speed_multiplier
		Movement.APPROACH:
			var to_target := _approach_target - global_position
			velocity = to_target.normalized() * move_speed if to_target.length_squared() > ARRIVAL_DISTANCE_SQUARED else Vector2.ZERO
		_:
			velocity = Vector2.ZERO

func _choose_wander_target() -> void:
	_wander_timer = _rng.randf_range(1.4, 2.6)
	var angle := _rng.randf() * TAU
	var radius := sqrt(_rng.randf()) * wander_radius
	_wander_target = home_position + Vector2.RIGHT.rotated(angle) * radius

func _begin_rejection(origin: Vector2) -> void:
	_flee_origin = origin
	_face_away_from(origin)
	_enter_state(State.REJECT_HIT)

func _is_interruptible() -> bool:
	return AMBIENT_STATES.has(_state)

func _face_toward(target: Vector2) -> void:
	var offset := target - global_position
	if offset.length_squared() > 0.0001: facing_direction = offset.normalized()

func _face_away_from(origin: Vector2) -> void:
	var offset := global_position - origin
	facing_direction = offset.normalized() if offset.length_squared() > 0.0001 else Vector2.RIGHT

# --- Detectors --------------------------------------------------------------

func _configure_detectors() -> void:
	_bind_detector(get_node_or_null("ThreatDetector"), &"_on_threat_detected")
	_bind_detector(get_node_or_null("TreatDetector"), &"_on_treat_detected")
	_bind_detector(get_node_or_null("ContactDetector"), &"_on_contact_detected")

func _bind_detector(detector: Node, handler: StringName) -> void:
	var area := detector as Area2D
	if area == null: return
	area.monitoring = true
	var callback := Callable(self, handler)
	if not area.body_entered.is_connected(callback): area.body_entered.connect(callback)
	if not area.area_entered.is_connected(callback): area.area_entered.connect(callback)

func _on_threat_detected(node: Node) -> void:
	var source := _detector_source(node, &"opossum_threat")
	if source == null or not _is_interruptible(): return
	flee_from(source.global_position)

func _on_treat_detected(node: Node) -> void:
	var source := _detector_source(node, &"opossum_treat")
	if source == null or not _is_interruptible(): return
	receive_treat(source)

func _on_contact_detected(node: Node) -> void:
	var source := _detector_source(node, &"opossum_discoverable")
	if source == null or _state != State.RETRIEVE: return
	carrying_target = source

## Detector bodies are often collision children of the meaningful actor, so a
## single parent hop is allowed when matching the gameplay group.
func _detector_source(node: Node, group: StringName) -> Node2D:
	if node == null or not is_instance_valid(node): return null
	if node.is_in_group(group) and node is Node2D: return node as Node2D
	var parent := node.get_parent()
	if parent != null and parent.is_in_group(group) and parent is Node2D: return parent as Node2D
	return null
