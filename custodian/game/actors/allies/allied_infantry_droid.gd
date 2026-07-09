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

@export var show_status_label: bool = true

@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var status_label: Label = get_node_or_null("StatusLabel")

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


func _update_visuals() -> void:
	# Override CombatDrone's ColorRect visual path.
	if anim_sprite == null:
		return

	_update_facing()
	_update_animation()
	_update_sprite_tint()
	_update_health_bar()
	_update_status_label()


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


func _update_status_label() -> void:
	if status_label == null:
		return
	status_label.visible = show_status_label and not destroyed
	if not status_label.visible:
		return
	var fire_text := "FIRE" if fire_at_will else "HOLD"
	var follow_text := get_follow_distance_name().replace("FREE_ROAM", "ROAM")
	status_label.text = "%s %s / %s" % [get_anchor_mode_name(), follow_text, fire_text]


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
