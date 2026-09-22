extends CharacterBody2D
class_name Vaultwing

## Common Vaultwing Slice A actor. Health/public combat API lives here; the
## behavior controller owns all aerial/ground state and deterministic choices.

const PRESENTATION := preload("res://game/actors/ambient/ambient_creature_presentation_controller.gd")
const ANIMATION_SET := preload("res://game/actors/ambient/vaultwing/vaultwing_animation_set.tres")
const CONTROLLER_SCRIPT := preload("res://game/actors/ambient/vaultwing/vaultwing_behavior_controller.gd")

@export var max_health := 140.0
@export var health := 140.0
@export var attack_damage := 12.0
@export var behavior_enabled := true

@onready var body_sprite: AnimatedSprite2D = $Body
@onready var shadow: Polygon2D = $Shadow

var presentation := PRESENTATION.new()
var behavior: VaultwingBehaviorController
var facing_direction := Vector2.RIGHT
var _dead := false

func _ready() -> void:
	add_to_group("ambient_creature")
	add_to_group("hostile_fauna")
	add_to_group("vaultwing")
	if ANIMATION_SET.has_method("rescan_runtime"):
		ANIMATION_SET.rescan_runtime()
	presentation.setup(ANIMATION_SET, body_sprite)
	behavior = CONTROLLER_SCRIPT.new()
	add_child(behavior)
	behavior.configure(self)
	_log_event(&"vaultwing_spawned", {})

func _physics_process(delta: float) -> void:
	if _dead or not behavior_enabled: return
	behavior.step(delta)
	if velocity.length_squared() > 0.001: facing_direction = velocity.normalized()
	move_and_slide()

func set_ambient_seed(seed_value: int) -> void:
	if behavior != null: behavior.set_seed(seed_value)

func set_home_position(position: Vector2) -> void:
	if behavior != null: behavior.set_home_position(position)

func set_perch_positions(positions: Array[Vector2]) -> void:
	if behavior != null: behavior.set_perch_positions(positions)

func request_interest(position: Vector2, source: Node2D = null) -> void:
	if behavior != null: behavior.request_interest(position, source)

func request_dive(position: Vector2, source: Node2D = null) -> void:
	if behavior != null: behavior.request_dive(position, source)

func request_land() -> void:
	if behavior != null: behavior.request_land()

func request_takeoff() -> void:
	if behavior != null: behavior.request_takeoff()

func get_state() -> int:
	return behavior.state if behavior != null else VaultwingBehaviorController.State.HIGH_PATROL

func get_state_name() -> StringName:
	return behavior.get_state_name() if behavior != null else &"high_patrol"

func get_altitude_band() -> int:
	return behavior.band if behavior != null else VaultwingBehaviorController.Band.HIGH

func get_altitude_band_name() -> StringName:
	return behavior.get_band_name() if behavior != null else &"high"

func get_behavior_trace_state() -> Dictionary:
	return {"state": get_state_name(), "band": get_altitude_band_name(), "position": global_position}

func play_action(action: StringName, restart := false) -> bool:
	return presentation.play_action(action, facing_direction, restart)

func has_action(action: StringName) -> bool:
	return presentation.has_action(action, facing_direction)

func take_damage(amount: float, _hit_strength := 0, _reaction_damage := -1.0) -> Dictionary:
	var before := health
	if _dead or health <= 0.0:
		return _damage_result(0.0, false, before)
	var applied := minf(maxf(0.0, amount), health)
	health = maxf(0.0, health - applied)
	if behavior != null: behavior.notify_damage(applied)
	if health <= 0.0: die()
	return _damage_result(applied, true, before)

func die() -> void:
	if _dead: return
	_dead = true
	if behavior != null: behavior.force_state(VaultwingBehaviorController.State.DEAD)
	velocity = Vector2.ZERO
	_log_event(&"vaultwing_killed", {})

func apply_visual_altitude(value: float) -> void:
	var altitude := clampf(value, 0.0, 1.0)
	body_sprite.position.y = -lerpf(0.0, 240.0, altitude)
	var scale_value := lerpf(1.0, 0.82, altitude)
	body_sprite.scale = Vector2.ONE * scale_value
	shadow.position = Vector2.ZERO
	shadow.scale = Vector2.ONE * lerpf(1.0, 0.62, altitude)
	shadow.color = Color(0.04, 0.05, 0.07, lerpf(0.72, 0.22, altitude))

func _damage_result(applied: float, was_alive: bool, before: float) -> Dictionary:
	return {
		"applied_damage": applied, "damage_applied": applied,
		"target_was_alive": was_alive, "target_health_before": before,
		"target_health_after": health, "lethal": _dead or health <= 0.0,
		"blocked": false, "eligible_hostile": true, "passive": false,
		"structure": false, "deflected": false, "invulnerable": false,
	}

func _log_event(event_name: StringName, payload: Dictionary) -> void:
	var observatory := get_node_or_null("/root/DevObservatory")
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", event_name, payload)
