extends CombatDrone

## Test-scene allied infantry droid.
## Uses AnimatedSprite2D instead of CombatDrone's ColorRect visual.
##
## Expected animations:
## - idle_e
## - idle_w
## - run_e
## - run_w
##
## Optional animations:
## - destroyed_e
## - destroyed_w

@export var toggle_key: Key = KEY_T

@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

var _last_facing_east: bool = true


func _ready() -> void:
	# CombatDrone._ready() sets groups, hold position, profile stats,
	# collision shape, health, and calls _update_visuals().
	super._ready()

	# This actor is an ally, but not a static turret/defense placement.
	remove_from_group("defense")
	remove_from_group("turret")
	add_to_group("allied_droid")
	add_to_group("allied_infantry_droid")

	if anim_sprite == null:
		push_error("InfantryDroid: missing AnimatedSprite2D node")
		return

	_update_visuals()


func _unhandled_input(event: InputEvent) -> void:
	if destroyed:
		return
	if get_tree().paused:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == toggle_key:
			_toggle_combat_mode()
			get_viewport().set_input_as_handled()


func _toggle_combat_mode() -> void:
	# fire_at_will is inherited from CombatDrone.
	# Do not redeclare it in this child script.
	fire_at_will = not fire_at_will

	# CombatDrone._update_weapon() already respects fire_at_will, but clear
	# queued burst state immediately so HOLD FIRE feels instant.
	if not fire_at_will:
		_burst_remaining = 0
		_burst_gap_timer = 0.0

	print("[Droid] Combat mode: ", "FIRE AT WILL" if fire_at_will else "HOLD FIRE")
	_update_visuals()


func _update_visuals() -> void:
	# Override CombatDrone's ColorRect visual path.
	if anim_sprite == null:
		return

	_update_facing()
	_update_animation()
	_update_sprite_tint()
	_update_health_bar()


func _update_facing() -> void:
	var facing_vector := velocity

	# If stationary with a target, face the target instead of snapping east.
	if facing_vector.length_squared() <= 4.0 and target != null and is_instance_valid(target):
		facing_vector = target.global_position - global_position

	if facing_vector.length_squared() > 4.0:
		_last_facing_east = facing_vector.x >= 0.0


func _update_animation() -> void:
	var is_moving := velocity.length_squared() > 4.0
	var animation_name := ""

	if destroyed:
		animation_name = "destroyed_e" if _last_facing_east else "destroyed_w"
		if not _has_animation(animation_name):
			animation_name = "idle_e" if _last_facing_east else "idle_w"
	elif is_moving:
		animation_name = "run_e" if _last_facing_east else "run_w"
	else:
		animation_name = "idle_e" if _last_facing_east else "idle_w"

	if not _has_animation(animation_name):
		push_warning("InfantryDroid: missing animation %s" % animation_name)
		return

	if anim_sprite.animation != animation_name:
		anim_sprite.play(animation_name)
	elif not anim_sprite.is_playing() and not destroyed:
		anim_sprite.play()


func _update_sprite_tint() -> void:
	if destroyed:
		anim_sprite.modulate = Color(0.18, 0.18, 0.18, 0.65)
		return

	var health_ratio := _get_health_ratio()
	var health_tint := _get_health_tint(health_ratio)

	if not fire_at_will:
		anim_sprite.modulate = health_tint * Color(0.52, 0.52, 0.52, 0.88)
		anim_sprite.modulate.a = 0.88
	else:
		anim_sprite.modulate = health_tint


func _update_health_bar() -> void:
	if health_bar == null:
		return

	var health_ratio := _get_health_ratio()
	health_bar.value = health_ratio * 100.0
	health_bar.modulate = _get_health_tint(health_ratio)
	health_bar.visible = not destroyed


func _get_health_ratio() -> float:
	if max_health <= 0.0:
		return 1.0
	return clampf(health / max_health, 0.0, 1.0)


func _get_health_tint(health_ratio: float) -> Color:
	if profile != null and health_ratio <= profile.drone_retreat_hp_threshold:
		return critical_tint
	if health_ratio < 0.65:
		return damaged_tint
	return Color.WHITE


func _has_animation(animation_name: String) -> bool:
	if anim_sprite == null or anim_sprite.sprite_frames == null:
		return false
	return anim_sprite.sprite_frames.has_animation(animation_name)


func _destroy() -> void:
	super._destroy()

	# Parent handles manager notification, collision, groups, and physics.
	# This child restores AnimatedSprite2D-specific destroyed presentation.
	_update_visuals()
