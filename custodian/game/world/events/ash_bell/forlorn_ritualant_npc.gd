class_name ForlornRitualantNPC
extends CharacterBody2D

signal defeated_nonlethal
signal defeated_violent
signal attack_started
signal stilling_pin_impact
signal thread_pull_started
signal ninth_answer_started
signal orra_late_started

enum Phase {
	KNEELING,
	RISING,
	HOSTILE,
	RESOLVING,
	DISSOLVING,
	GONE,
}

@export var max_hp: int = 160
@export var move_speed: float = 42.0
@export var attack_range: float = 46.0
@export var thread_pull_range: float = 184.0
@export var attack_cooldown: float = 2.2
@export var pin_windup_seconds := 0.42
@export var thread_pull_windup_seconds := 0.58
@export var ninth_answer_windup_seconds := 0.9
@export var orra_late_delay_seconds := 1.05
@export var pin_damage := 8.0
@export var ninth_answer_damage := 10.0
@export var survive_to_dissolve_seconds: float = 90.0
@export var target_path: NodePath
@export var site_path: NodePath
@export var animated_sprite_path: NodePath
@export var combat_bounds_path: NodePath

@onready var target: Node2D = get_node_or_null(target_path)
@onready var site: ForlornRitualantSite = get_node_or_null(site_path)
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null(animated_sprite_path)
@onready var visual: CanvasItem = get_node_or_null("Visual")
@onready var combat_bounds: CollisionShape2D = get_node_or_null(combat_bounds_path)

var phase: int = Phase.KNEELING
var hp: int
var _attack_timer: float = 0.0
var _hostile_elapsed: float = 0.0
var _attack_in_progress := false
var _attack_count := 0
var _last_attack := &""


func _ready() -> void:
	add_to_group("ash_bell_forlorn_ritualant")
	hp = max_hp
	# Production sprites active; hide the collapsed-robes placeholder entirely.
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		animated_sprite.visible = true
		if visual != null:
			visual.visible = false
	_play_anim(&"kneel_idle")


func _physics_process(delta: float) -> void:
	if phase != Phase.HOSTILE:
		return
	if not _combat_execution_allowed():
		velocity = Vector2.ZERO
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
	if _attack_in_progress:
		velocity = Vector2.ZERO
		return
	if distance > thread_pull_range:
		var bounded_goal := _clamp_to_combat_bounds(target.global_position)
		var to_bounded_goal := bounded_goal - global_position
		velocity = to_bounded_goal.normalized() * move_speed \
			if to_bounded_goal.length_squared() > 0.01 else Vector2.ZERO
		move_and_slide()
		global_position = _clamp_to_combat_bounds(global_position)
		return

	velocity = Vector2.ZERO
	if _attack_timer <= 0.0:
		_choose_attack(distance)


func _clamp_to_combat_bounds(world_position: Vector2) -> Vector2:
	if combat_bounds == null or not (combat_bounds.shape is RectangleShape2D):
		return world_position
	var rect_shape := combat_bounds.shape as RectangleShape2D
	var half_size := rect_shape.size * 0.5
	var center := combat_bounds.global_position
	return Vector2(
		clampf(world_position.x, center.x - half_size.x, center.x + half_size.x),
		clampf(world_position.y, center.y - half_size.y, center.y + half_size.y)
	)


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
		site.event_state.ritualant_hostile = false
		if site.event_state.resolution != AshBellEventState.Resolution.SITE_STABILIZED:
			site.event_state.set_resolution(AshBellEventState.Resolution.RITUALANT_DISSOLVED)
	defeated_nonlethal.emit()
	await get_tree().create_timer(1.25).timeout
	phase = Phase.GONE
	queue_free()


func begin_stabilized_resolution() -> void:
	if phase == Phase.GONE or phase == Phase.DISSOLVING:
		return
	phase = Phase.RESOLVING
	_attack_in_progress = false
	velocity = Vector2.ZERO
	_play_anim(&"kneel_idle")
	_set_visual_color(Color(0.62, 0.58, 0.48, 1.0))


func interrupt_for_stabilization() -> void:
	if phase == Phase.GONE or phase == Phase.DISSOLVING:
		return
	phase = Phase.RESOLVING
	_attack_in_progress = false
	velocity = Vector2.ZERO
	_play_anim(&"hostile_idle")


func die_violently() -> void:
	phase = Phase.GONE
	velocity = Vector2.ZERO
	defeated_violent.emit()
	if site != null:
		site.defile_site()
	queue_free()


func _choose_attack(distance: float) -> void:
	_attack_timer = attack_cooldown
	_attack_count += 1
	if _attack_count % 5 == 0:
		_orra_comes_late()
		return
	if _attack_count % 3 == 0:
		_ninth_answer()
		return
	if distance <= attack_range:
		_pin_strike()
		return
	if distance <= thread_pull_range:
		_thread_pull()
		return


func _pin_strike() -> void:
	_attack_in_progress = true
	_last_attack = &"pin_strike"
	attack_started.emit()
	_play_anim(&"pin_strike")
	_bark(&"pin_strike_bark")
	await get_tree().create_timer(pin_windup_seconds).timeout
	if not _combat_execution_allowed():
		_attack_in_progress = false
		return
	stilling_pin_impact.emit()
	var contact_valid := (
		target != null
		and is_instance_valid(target)
		and target.global_position.distance_to(global_position) <= attack_range
	)
	if contact_valid and site != null:
		site.event_state.add_silence_pressure(8, &"pin_strike")
	if contact_valid and target.has_method("take_damage"):
		target.call("take_damage", pin_damage)
	_finish_attack()


func _thread_pull() -> void:
	_attack_in_progress = true
	_last_attack = &"thread_pull"
	attack_started.emit()
	thread_pull_started.emit()
	_play_anim(&"thread_pull")
	_bark(&"thread_pull_bark")
	var target_start := target.global_position if target != null else Vector2.ZERO
	await get_tree().create_timer(thread_pull_windup_seconds).timeout
	if (
		not _combat_execution_allowed()
		or target == null
		or not is_instance_valid(target)
	):
		_attack_in_progress = false
		return
	var radial := (target_start - global_position).normalized()
	var lateral_escape := absf((target.global_position - target_start).cross(radial))
	if lateral_escape <= 28.0 and target.global_position.distance_to(global_position) <= thread_pull_range + 24.0:
		target.global_position = target.global_position.move_toward(global_position, 56.0)
	if site != null:
		site.event_state.add_thread_tension(5, &"ritualant_thread_pull")
	_finish_attack()


func _ninth_answer() -> void:
	_attack_in_progress = true
	_last_attack = &"ninth_answer"
	attack_started.emit()
	ninth_answer_started.emit()
	_play_anim(&"ninth_answer")
	_bark(&"ninth_answer_bark")
	var lane_x := target.global_position.x if target != null else global_position.x
	if site != null:
		site.begin_ninth_answer_lane(lane_x)
	await get_tree().create_timer(ninth_answer_windup_seconds).timeout
	if (
		_combat_execution_allowed()
		and target != null
		and is_instance_valid(target)
	):
		if absf(target.global_position.x - lane_x) <= 30.0 and target.has_method("take_damage"):
			target.call("take_damage", ninth_answer_damage)
	if site != null:
		site.end_ninth_answer_lane()
	_finish_attack()


func _orra_comes_late() -> void:
	_attack_in_progress = true
	_last_attack = &"orra_late"
	attack_started.emit()
	orra_late_started.emit()
	_play_anim(&"orra_late")
	_bark(&"orra_late_windup_bark")
	var target_start := target.global_position if target != null else Vector2.ZERO
	var behind := target_start + Vector2(0.0, 42.0)
	if site != null:
		site.begin_orra_late(behind)
	await get_tree().create_timer(orra_late_delay_seconds).timeout
	if (
		_combat_execution_allowed()
		and target != null
		and is_instance_valid(target)
	):
		var caught := target.global_position.distance_to(target_start) <= 44.0
		if site != null:
			site.resolve_orra_late(caught)
		_bark(&"orra_late_resolve_bark")
	_finish_attack()


func _finish_attack() -> void:
	_attack_in_progress = false
	if phase == Phase.HOSTILE:
		_play_anim(&"hostile_idle")


func _combat_execution_allowed() -> bool:
	if phase != Phase.HOSTILE:
		return false
	if site == null or site.event_state == null:
		return false
	if not site.event_state.ritualant_hostile:
		return false
	if site.is_dialogue_input_captured():
		return false
	if site.is_encounter_resolving():
		return false
	return true


func _bark(node_id: StringName) -> void:
	if site != null:
		site.request_dialogue.emit(site.dialogue_id, node_id)


func debug_force_attack(attack_id: StringName) -> void:
	match attack_id:
		&"pin_strike": _pin_strike()
		&"thread_pull": _thread_pull()
		&"ninth_answer": _ninth_answer()
		&"orra_late": _orra_comes_late()


func debug_get_last_attack() -> StringName:
	return _last_attack


func _play_anim(anim_name: StringName) -> void:
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		return
	var fallback := {
		&"ninth_answer": &"thread_pull",
		&"orra_late": &"thread_pull",
		&"dissolve": &"dissolve",
		&"death_violent": &"hostile_idle",
	}.get(anim_name, &"hostile_idle") as StringName
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(fallback):
		animated_sprite.play(fallback)


func debug_get_animation_contract() -> Dictionary:
	return {
		"ninth_answer": "10f_128_missing_fallback_thread_pull",
		"orra_late": "8f_128_missing_fallback_thread_pull",
		"dissolve": "10f_128_missing_fallback_existing_dissolve",
		"death_violent": "8f_128_missing_fallback_hostile_idle",
	}


func _set_visual_color(color: Color) -> void:
	if visual != null:
		visual.modulate = color
