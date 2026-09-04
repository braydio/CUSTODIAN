extends CharacterBody2D
class_name BabyOpossum

const PRESENTATION := preload("res://game/actors/ambient/ambient_creature_presentation_controller.gd")
const ANIMATION_SET := preload("res://game/actors/ambient/baby_opossum/baby_opossum_animation_set.gd")
enum TrustStage { WILD, WARY, FED, FAMILIAR, FRIEND }

@export var move_speed := 30.0
@export var flee_speed_multiplier := 2.2
@export var wander_radius := 96.0
@export var trust_stage: TrustStage = TrustStage.WILD
@export var trust_points := 0
@export var behavior_enabled := true

@onready var body_sprite: AnimatedSprite2D = $Body
@onready var presentation := PRESENTATION.new()

var facing_direction := Vector2.DOWN
var home_position := Vector2.ZERO
var fleeing := false
var play_dead := false
var is_hidden := false
var carrying_target: Node = null
var _wander_target := Vector2.ZERO
var _wander_timer := 0.0
var _reaction_timer := 0.0
var _reaction_phase := &""

func _ready() -> void:
	add_to_group("ambient_creature")
	add_to_group("ambient_critter")
	home_position = global_position
	presentation.setup(ANIMATION_SET.new(), body_sprite)
	play_action(&"idle")

func _physics_process(delta: float) -> void:
	if not behavior_enabled: return
	_reaction_timer = maxf(0.0, _reaction_timer - delta)
	if _reaction_timer <= 0.0 and _reaction_phase != &"":
		if _reaction_phase == &"disapprove":
			_reaction_phase = &"flee"
			flee_from(global_position - facing_direction * 32.0)
		else: _reaction_phase = &""
	if fleeing:
		velocity = facing_direction * move_speed * flee_speed_multiplier
		play_action(&"scurry")
	else:
		_wander_timer -= delta
		if _wander_timer <= 0.0: _choose_wander_target()
		var offset := _wander_target - global_position
		if offset.length_squared() > 16.0:
			facing_direction = offset.normalized()
			velocity = facing_direction * move_speed
			play_action(&"waddle")
		else:
			velocity = Vector2.ZERO
			play_action(&"idle")
	move_and_slide()

func play_action(action: StringName, restart := false) -> bool: return presentation.play_action(action, facing_direction, restart)
func has_action(action: StringName) -> bool: return presentation.has_action(action, facing_direction)
func get_action_duration(action: StringName) -> float: return presentation.get_action_duration(action, facing_direction)
func get_animation_capabilities() -> Dictionary: return presentation.get_animation_capabilities()
func get_missing_animation_actions() -> Array[StringName]: return presentation.get_missing_animation_actions()

func take_damage(_amount: float, _hit_strength := 0, _reaction_damage := -1.0) -> Dictionary:
	return {"applied_damage":0.0,"damage_applied":0.0,"target_was_alive":true,"target_health_before":0.0,"target_health_after":0.0,"lethal":false,"blocked":true,"deflected":true,"invulnerable":true,"eligible_hostile":false,"passive":true}

func reject_projectile(projectile: Node = null) -> bool:
	if projectile != null and projectile.has_method("queue_free"): projectile.call_deferred("queue_free")
	_reject_attack(&"reject_projectile")
	return true

func reject_melee(_attacker: Node = null) -> bool:
	_reject_attack(&"reject_melee")
	return true

func on_nearby_attack(origin: Vector2) -> void:
	facing_direction = (origin - global_position).normalized()
	play_action(&"startle", true)

func _reject_attack(action: StringName) -> void:
	facing_direction = facing_direction.normalized()
	play_action(action, true)
	play_action(&"disapprove", true)
	_reaction_phase = &"disapprove"
	_reaction_timer = 0.72

func flee_from(origin: Vector2) -> void:
	fleeing = true
	facing_direction = (global_position - origin).normalized()
	if facing_direction.length_squared() < 0.01: facing_direction = Vector2.RIGHT
	play_action(&"flee_start", true)

func stop_fleeing() -> void:
	fleeing = false
	_reaction_phase = &""

func receive_treat(_treat: Node = null) -> bool:
	play_action(&"notice_treat", true)
	play_action(&"approach_wary", true)
	play_action(&"sniff_treat", true)
	play_action(&"take_treat", true)
	play_action(&"eat", true)
	trust_points += 1
	trust_stage = mini(int(TrustStage.FRIEND), 1 + trust_points / 2)
	if trust_stage >= TrustStage.FED: play_action(&"friend_happy", true)
	return true

func begin_play_dead() -> void:
	play_dead = true
	fleeing = false
	velocity = Vector2.ZERO
	play_action(&"play_dead_enter", true)
	play_action(&"play_dead_hold", true)

func end_play_dead() -> void:
	play_dead = false
	play_action(&"play_dead_exit", true)

func enter_hide() -> void:
	is_hidden = true
	play_action(&"hide_enter", true)
	play_action(&"hide_hold", true)

func exit_hide() -> void:
	is_hidden = false
	play_action(&"hide_exit", true)

func search_for_target() -> Node:
	play_action(&"search", true)
	var nearest: Node2D = null
	var distance := INF
	for candidate in get_tree().get_nodes_in_group("opossum_discoverable"):
		if not candidate is Node2D: continue
		var candidate_distance := global_position.distance_to((candidate as Node2D).global_position)
		if candidate_distance < distance: nearest = candidate; distance = candidate_distance
	if nearest != null:
		play_action(&"dig", true)
		play_action(&"find_target", true)
		play_action(&"look_back", true)
		play_action(&"excited_idle", true)
	return nearest

func retrieve(target: Node = null) -> bool:
	carrying_target = target
	play_action(&"retrieve", true)
	return true

func gift_drop() -> void:
	carrying_target = null
	play_action(&"gift_drop", true)

func _choose_wander_target() -> void:
	_wander_timer = 1.4 + float((get_instance_id() + Time.get_ticks_msec()) % 1200) / 1000.0
	_wander_target = home_position + Vector2.RIGHT.rotated(float(Time.get_ticks_msec() % 628) / 100.0) * wander_radius
