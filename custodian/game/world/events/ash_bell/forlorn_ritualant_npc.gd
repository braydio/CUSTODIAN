class_name ForlornRitualantNPC
extends CharacterBody2D

signal defeated_nonlethal
signal defeated_violent
signal attack_started
signal clapper_impact
signal thread_pull_started

enum Phase {
	KNEELING,
	RISING,
	HOSTILE,
	DISSOLVING,
	GONE,
}

@export var max_hp: int = 160
@export var move_speed: float = 42.0
@export var attack_range: float = 46.0
@export var attack_cooldown: float = 2.2
@export var survive_to_dissolve_seconds: float = 90.0
@export var target_path: NodePath
@export var site_path: NodePath
@export var animated_sprite_path: NodePath

@onready var target: Node2D = get_node_or_null(target_path)
@onready var site: ForlornRitualantSite = get_node_or_null(site_path)
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null(animated_sprite_path)
@onready var visual: CanvasItem = get_node_or_null("Visual")

var phase: int = Phase.KNEELING
var hp: int
var _attack_timer: float = 0.0
var _hostile_elapsed: float = 0.0


func _ready() -> void:
	add_to_group("ash_bell_forlorn_ritualant")
	hp = max_hp
	_play_anim(&"kneel_idle")


func _physics_process(delta: float) -> void:
	if phase != Phase.HOSTILE:
		return

	_hostile_elapsed += delta
	if _hostile_elapsed >= survive_to_dissolve_seconds:
		dissolve()
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	if distance > attack_range:
		velocity = to_target.normalized() * move_speed
		move_and_slide()
		return

	velocity = Vector2.ZERO
	if _attack_timer <= 0.0:
		_choose_attack(distance)


func become_hostile() -> void:
	if phase == Phase.HOSTILE or phase == Phase.GONE:
		return

	phase = Phase.RISING
	_play_anim(&"rise")
	_set_visual_color(Color(0.42, 0.36, 0.27, 1.0))
	await get_tree().create_timer(0.8).timeout
	if phase == Phase.RISING:
		phase = Phase.HOSTILE
		_attack_timer = 0.5
		_play_anim(&"hostile_idle")
		_set_visual_color(Color(0.50, 0.43, 0.32, 1.0))


func take_damage(amount: float) -> void:
	apply_damage(int(ceil(amount)))


func apply_damage(amount: int, damage_tags: Array[StringName] = []) -> void:
	if phase == Phase.GONE or phase == Phase.DISSOLVING:
		return

	if phase != Phase.HOSTILE:
		become_hostile()

	hp = maxi(0, hp - amount)
	if hp <= 0:
		if damage_tags.has(&"thread_anchor"):
			dissolve()
		else:
			die_violently()


func dissolve() -> void:
	if phase == Phase.GONE:
		return

	phase = Phase.DISSOLVING
	velocity = Vector2.ZERO
	_play_anim(&"dissolve")
	if site != null:
		site.event_state.set_resolution(AshBellEventState.Resolution.RITUALANT_DISSOLVED)
	defeated_nonlethal.emit()
	await get_tree().create_timer(1.25).timeout
	phase = Phase.GONE
	queue_free()


func die_violently() -> void:
	phase = Phase.GONE
	velocity = Vector2.ZERO
	defeated_violent.emit()
	if site != null:
		site.defile_site()
	queue_free()


func _choose_attack(distance: float) -> void:
	_attack_timer = attack_cooldown
	if site != null and site.event_state.thread_tension >= 60:
		_thread_pull()
		return
	if distance <= attack_range:
		_clapper_swing()


func _clapper_swing() -> void:
	attack_started.emit()
	_play_anim(&"clapper_swing")
	await get_tree().create_timer(0.42).timeout
	clapper_impact.emit()
	if site != null:
		site.event_state.add_silence_pressure(8, &"clapper_impact")
	if target != null and target.has_method("take_damage"):
		target.call("take_damage", 8.0)


func _thread_pull() -> void:
	thread_pull_started.emit()
	_play_anim(&"thread_pull")
	if site != null:
		site.event_state.add_thread_tension(5, &"ritualant_thread_pull")


func _play_anim(anim_name: StringName) -> void:
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)


func _set_visual_color(color: Color) -> void:
	if visual != null:
		visual.modulate = color
