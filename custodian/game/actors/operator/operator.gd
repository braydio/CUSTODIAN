extends ControllableActor

const AnimationASsgResolver = preload("res://game/actors/operator/animations/animation_resolver.gd")
const AnimationStateMachine = preload("res://game/actors/operator/animations/animation_state_machine.gd")
const AttackLightState = preload("res://game/actors/operator/animations/states/attack_light_state.gd")
const AttackFastState = preload("res://game/actors/operator/animations/states/attack_fast_state.gd")
const AttackHeavyState = preload("res://game/actors/operator/animations/states/attack_heavy_state.gd")
const BlockState = preload("res://game/actors/operator/animations/states/block_state.gd")
const EquipWeaponState = preload("res://game/actors/operator/animations/states/equip_weapon_state.gd")
const HitRecoilState = preload("res://game/actors/operator/animations/states/hit_recoil_state.gd")
const IdleState = preload("res://game/actors/operator/animations/states/idle_state.gd")
const WalkState = preload("res://game/actors/operator/animations/states/walk_state.gd")
const SprintState = preload("res://game/actors/operator/animations/states/sprint_state.gd")
const DeathState = preload("res://game/actors/operator/animations/states/death_state.gd")
const SPEED := 150.0
const BULLET_SCENE := preload("res://game/actors/projectiles/bullet.tscn")
const MUZZLE_FLASH_SCENE := preload("res://game/actors/effects/muzzle_flash.tscn")
const IMPACT_SPARK_SCENE := preload("res://game/actors/effects/impact_spark.tscn")
const MELEE_SWING_SCENE := preload("res://game/actors/effects/melee_swing.tscn")
const TARGET_RING_SCENE := preload("res://game/actors/effects/target_ring.tscn")
const DAMAGE_POPUP_SCENE := preload("res://game/actors/ui/damage_popup.tscn")
var health: float = 100.0
var fire_cooldown_remaining := 0.0
var melee_cooldown_remaining := 0.0
var current_recoil := 0.0
var recoil_decay := 18.0
var weapon_profile := 0
var primary_weapon_equipped := false
var equipped_primary_weapon_id := ""
var combat_loadout_mode: StringName = &"melee"
var last_fire_cooldown := 0.0

@export var muzzle_offset: float = 24.0
@export var aim_crosshair_color: Color = Color(0.9, 0.9, 0.9, 1.0)
@export var ammo_standard: int = 120
@export var ammo_heavy: int = 32
@export var ammo_standard_max: int = 240
@export var ammo_heavy_max: int = 80
@export var ammo_standard_magazine_size: int = 28
@export var ammo_heavy_magazine_size: int = 8
@export var ranged_reload_duration: float = 1.7
@export var interaction_range: float = 84.0
@export var melee_damage: float = 28.0
@export var melee_range: float = 72.0
@export var melee_arc_degrees: float = 80.0
@export var melee_cooldown: float = 0.45
@export var melee_light_hit_damage: float = 16.0
@export var melee_light_range: float = 68.0
@export var melee_light_arc_degrees: float = 88.0
@export var melee_light_cancel_start: float = 0.34
@export var melee_fast_hit_damage: float = 7.0
@export var melee_heavy_hit_damage: float = 34.0
@export var melee_heavy_range: float = 84.0
@export var melee_heavy_arc_degrees: float = 58.0
@export var melee_input_buffer_time: float = 0.15
@export var melee_fast_cancel_start: float = 0.50
@export var melee_heavy_cancel_start: float = 0.58
@export var melee_hit_stop_scale: float = 0.8
@export var melee_hit_stop_duration: float = 0.02
@export var melee_camera_shake_power: float = 1.0
@export var melee_light_hit_stop_scale: float = 0.86
@export var melee_light_hit_stop_duration: float = 0.035
@export var melee_light_camera_shake_power: float = 1.4
@export var melee_fast_hit_stop_scale: float = 0.88
@export var melee_fast_hit_stop_duration: float = 0.028
@export var melee_fast_camera_shake_power: float = 1.4
@export var operator_light_reaction_stun_duration: float = 0.22
@export var melee_fast_knockback_force: float = 56.0
@export var melee_fast_recovery_duration: float = 0.2
@export var melee_heavy_hit_stop_scale: float = 0.55
@export var melee_heavy_hit_stop_duration: float = 0.05
@export var melee_heavy_camera_shake_power: float = 4.2
@export var melee_heavy_knockback_force: float = 132.0
@export var repair_rate: float = 15.0
@export var sprint_multiplier: float = 1.7
@export var stamina_max: float = 100.0
@export var stamina_drain_per_second: float = 32.0
@export var stamina_regen_per_second: float = 22.0
@export var stamina_sprint_gate: float = 10.0
@export var stamina_sprint_exhaustion_requires_full_recovery: bool = true
@export var move_acceleration: float = 1200.0
@export var move_deceleration: float = 1500.0
@export var movement_turn_response: float = 14.0
@export var unarmed_move_multiplier: float = 1.12
@export var ranged_firing_move_multiplier: float = 0.72
@export var heavy_attack_stamina_cost: float = 14.0
@export var heavy_attack_blocked_while_sprinting: bool = true
@export var block_move_multiplier: float = 0.6
@export var block_stamina_cost_per_hit: float = 12.0
@export var combat_target_range: float = 360.0
@export var use_tiny_rpg_placeholder_soldier: bool = true
@export_file("*.png") var idle_main_sheet_path := "res://content/sprites/operator/runtime/idle/operator_idle_main.png"
@export_file("*.png") var ranged_2h_stance_sheet_path := "res://content/sprites/operator/runtime/body/ranged_2h/operator_body_ranged_2h_stance.png"
@export_file("*.png") var ranged_2h_aim_sheet_path := "res://content/sprites/operator/runtime/body/ranged_2h/operator_body_ranged_2h_aim_raise.png"
@export_file("*.png") var ranged_2h_fire_walk_sheet_path := "res://content/sprites/operator/runtime/curated/body/ranged_2h/firing_slow_walk.png"
@export var primary_weapon_definition = null
@export var melee_weapon_definition = null
@export var unarmed_definition: OperatorWeaponDefinition = preload("res://game/actors/operator/unarmed_definition.tres")
@export var idle_long_loop_threshold: int = 20
@export var primary_weapon_frames_resource: SpriteFrames
@export var placeholder_sprite_position: Vector2 = Vector2(0, -18)
@export var placeholder_sprite_offset: Vector2 = Vector2.ZERO
@export var right_hand_socket_position: Vector2 = Vector2(10, -16)
@export var left_hand_socket_position: Vector2 = Vector2(12, -28)
@export var primary_weapon_socket_position: Vector2 = Vector2(12, -28)
@export var primary_weapon_sprite_position: Vector2 = Vector2.ZERO
@export var primary_weapon_sprite_scale: Vector2 = Vector2.ONE
@export var primary_weapon_muzzle_socket_position: Vector2 = Vector2(20, 2)
@export var placeholder_collision_offset: Vector2 = Vector2(0, 12)
@export var placeholder_collision_radius: float = 7.0
@export var placeholder_collision_height: float = 22.0
@export var placeholder_melee_hitbox_radius: float = 22.0
@export var placeholder_healthbar_top: float = -54.0
@export var placeholder_healthbar_bottom: float = -48.0

var interaction_target: Node = null
var repair_target: Damageable = null
var build_target: Node = null  # WallBlueprint we're building
var movement_direction := Vector2.DOWN  # Direction player is moving (for walk animations)
var visual_idle_direction := Vector2.DOWN
var arrow_aim_enabled: bool = false
var stamina: float = 100.0
var is_sprinting: bool = false
var _sprint_exhausted: bool = false
var _melee_active: bool = false
var _melee_attack_kind: String = ""
var _melee_attack_key: String = ""
var _melee_elapsed: float = 0.0
var _melee_duration: float = 0.0
var _melee_forward: Vector2 = Vector2.RIGHT
var armed_weapons: Array[OperatorWeaponDefinition] = []
var armed_weapon_index: int = 0
var last_armed_weapon_index: int = 0
var using_unarmed: bool = false
var pending_weapon_selection: Dictionary = {}
var _active_attack_profile: OperatorWeaponDefinition = null
var _missing_animation_warnings: Dictionary = {}
var _melee_heavy_anticipating: bool = false
var _melee_fast_combo_step: int = 0
var _buffered_attack_kind: String = ""
var _buffered_attack_timer: float = 0.0
var _hit_stop_active: bool = false
var _melee_damage_current: float = 0.0
var _melee_range_current: float = 0.0
var _melee_arc_current: float = 0.0
var _melee_hitbox_active: bool = false
var _melee_hit_targets: Dictionary = {}
var _block_phase: StringName = &""
var _block_active: bool = false
var _melee_recovery_active: bool = false
var _melee_recovery_timer: float = 0.0
var _reload_active: bool = false
var _reload_timer: float = 0.0
var _ammo_standard_loaded: int = 0
var _ammo_heavy_loaded: int = 0
var _pending_ranged_shot: Dictionary = {}
var _combat_target: Node2D = null
var _target_ring: Node2D = null
var _idle_loop_counter := 0
var _last_idle_frame := -1
var _last_idle_animation := ""
var _animation_state_machine = null
var _is_dead := false
var _body_recoil_offset := Vector2.ZERO
var _animated_sprite_base_position := Vector2.ZERO
var _melee_weapon_overlay_base_position := Vector2.ZERO
var _melee_fx_overlay_base_position := Vector2.ZERO
var _last_damage_reaction_direction := Vector2.DOWN

# Debug socket visualization
var debug_draw_sockets: bool = false
var debug_right_hand_pos: Vector2 = Vector2.ZERO
var debug_left_hand_pos: Vector2 = Vector2.ZERO
var debug_weapon_socket_pos: Vector2 = Vector2.ZERO
var debug_muzzle_pos: Vector2 = Vector2.ZERO

const WEAPON_PROFILES = [
	{
		"name": "STANDARD",
		"cooldown": 0.16,
		"speed": 780.0,
		"damage": 16.0,
		"spread": 2.0,
		"recoil_kick": 1.2,
		"radius": 3.0,
		"color": Color(1.0, 0.9, 0.35, 1.0),
	},
	{
		"name": "HEAVY",
		"cooldown": 0.34,
		"speed": 620.0,
		"damage": 32.0,
		"spread": 4.0,
		"recoil_kick": 2.2,
		"radius": 5.0,
		"color": Color(1.0, 0.55, 0.25, 1.0),
	},
]


func _get_current_ranged_profile() -> Dictionary:
	var resolved_profile: Dictionary = WEAPON_PROFILES[0].duplicate()
	if primary_weapon_definition == null or not (primary_weapon_definition is OperatorWeaponDefinition):
		return resolved_profile
	var weapon_definition := primary_weapon_definition as OperatorWeaponDefinition
	var fire_rate_rps: float = weapon_definition.get_stat_float("fire_rate_rps", 0.0)
	if fire_rate_rps > 0.001:
		resolved_profile["cooldown"] = 1.0 / fire_rate_rps
	resolved_profile["damage"] = weapon_definition.get_stat_float("damage", float(resolved_profile.get("damage", 16.0)))
	resolved_profile["speed"] = weapon_definition.get_stat_float("projectile_speed_px", float(resolved_profile.get("speed", 780.0)))
	resolved_profile["spread"] = weapon_definition.get_stat_float("spread_deg", float(resolved_profile.get("spread", 2.0)))
	resolved_profile["recoil_kick"] = weapon_definition.get_stat_float("recoil", float(resolved_profile.get("recoil_kick", 1.2)))
	return resolved_profile

const PRIMARY_WEAPON_NONE := ""
const PRIMARY_WEAPON_CARBINE := "carbine_rifle"
const PRIMARY_WEAPON_SWORD := "fallen_star_katana"
const LOADOUT_HOLSTERED := &"holstered"
const LOADOUT_MELEE := &"melee"
const LOADOUT_RANGED := &"ranged"
const RANGED_FIRE_WALK_ANIMATION := &"ranged_2h_fire_walk"
const RANGED_FIRE_WALK_FRAME_WIDTH := 96
const RANGED_FIRE_WALK_BASE_FPS := 10.0
const BODY_RECOIL_RECOVERY_RATE := 18.0
const BODY_RECOIL_PROFILE_PIXELS := {
	"recoil_pistol": 0.7,
	"recoil_standard": 1.0,
	"recoil_shotgun": 1.5,
	"recoil_sniper": 2.0,
	"recoil_minigun": 0.6,
}

@onready var health_bar = $HealthBar
@onready var visual = $Visual
@onready var animated_sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var right_hand_socket = $RightHandSocket if has_node("RightHandSocket") else null
@onready var left_hand_socket = $LeftHandSocket if has_node("LeftHandSocket") else null
@onready var primary_weapon_socket = $PrimaryWeaponSocket if has_node("PrimaryWeaponSocket") else null
@onready var primary_weapon_sprite = $PrimaryWeaponSocket/PrimaryWeaponSprite if has_node("PrimaryWeaponSocket/PrimaryWeaponSprite") else null
@onready var ranged_fx_overlay_sprite = $PrimaryWeaponSocket/RangedFxOverlaySprite if has_node("PrimaryWeaponSocket/RangedFxOverlaySprite") else null
@onready var melee_weapon_overlay_sprite = $MeleeWeaponOverlaySprite if has_node("MeleeWeaponOverlaySprite") else null
@onready var melee_fx_overlay_sprite = $MeleeFxOverlaySprite if has_node("MeleeFxOverlaySprite") else null
@onready var barrel = $PrimaryWeaponSocket/Barrel if has_node("PrimaryWeaponSocket/Barrel") else null
@onready var body_collision = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var hitbox_root: Node2D = $HitboxRoot if has_node("HitboxRoot") else null
@onready var weapon_hitbox: Area2D = $HitboxRoot/WeaponHitbox if has_node("HitboxRoot/WeaponHitbox") else null
@onready var weapon_hitbox_shape: CollisionShape2D = $HitboxRoot/WeaponHitbox/CollisionShape2D if has_node("HitboxRoot/WeaponHitbox/CollisionShape2D") else null
@onready var weapon_factory: Node = get_node_or_null("/root/GameRoot/World/WeaponDefinitionFactory")

func _exit_tree() -> void:
	_animation_state_machine = null


func _ready():
	add_to_group("player")
	# Sync with ControllableActor base class
	current_health = health
	move_speed = SPEED
	
	# Reset any modulation from editor
	if visual:
		visual.modulate = Color(1, 1, 1, 1)
	if animated_sprite:
		var has_scene_frames: bool = animated_sprite.sprite_frames != null and not animated_sprite.sprite_frames.get_animation_names().is_empty()
		animated_sprite.modulate = Color(1.3, 1.3, 1.3, 1)  # Brighten 30%
		animated_sprite.frame_changed.connect(_on_attack_frame_changed)
		if not animated_sprite.animation_finished.is_connected(_on_operator_animation_finished):
			animated_sprite.animation_finished.connect(_on_operator_animation_finished)
		_ensure_runtime_body_animations()
	_configure_weapon_definition_defaults(primary_weapon_definition, "Carbine Rifle", "ranged", "ranged_fire", "ranged_fire")
	_configure_weapon_definition_defaults(melee_weapon_definition, "Fallen Star Katana", "melee", "melee_light", "melee_heavy")
	_rebuild_armed_weapon_list()
	_sync_weapon_selection_from_current_loadout()
	_apply_active_weapon_frames()
	_setup_animation_state_machine()
	if use_tiny_rpg_placeholder_soldier:
		_apply_placeholder_runtime_layout()
	else:
		_capture_runtime_visual_base_positions()
	_reset_melee_overlay_visuals()
	_update_primary_weapon_visual(false)
	stamina = stamina_max
	_ensure_target_ring()
	weapon_profile = 0
	_initialize_magazines()
	disable_hitbox()
	_apply_body_recoil_offset()
	update_visuals()

func _draw():
	if not debug_draw_sockets:
		return
	draw_line(debug_right_hand_pos, debug_weapon_socket_pos, Color(1.0, 0.35, 0.35, 0.9), 2.0)
	draw_line(debug_left_hand_pos, debug_weapon_socket_pos, Color(0.35, 0.8, 1.0, 0.9), 2.0)
	draw_line(debug_weapon_socket_pos, debug_muzzle_pos, Color(1.0, 0.85, 0.25, 0.9), 2.0)
	_draw_socket_marker(debug_right_hand_pos, Color.RED, "RH")
	_draw_socket_marker(debug_left_hand_pos, Color.BLUE, "LH")
	_draw_socket_marker(debug_weapon_socket_pos, Color(0.6, 1.0, 0.6, 1.0), "W")
	_draw_socket_marker(debug_muzzle_pos, Color.YELLOW, "M")


func _draw_socket_marker(pos: Vector2, color: Color, label: String) -> void:
	var marker_radius := 6.0
	draw_circle(pos, marker_radius, color)
	draw_line(pos + Vector2(-marker_radius - 3.0, 0.0), pos + Vector2(marker_radius + 3.0, 0.0), color, 2.0)
	draw_line(pos + Vector2(0.0, -marker_radius - 3.0), pos + Vector2(0.0, marker_radius + 3.0), color, 2.0)
	var font: Font = ThemeDB.fallback_font
	if font != null:
		draw_string(font, pos + Vector2(10.0, -8.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, color)

func _process(delta):
	fire_cooldown_remaining = max(0.0, fire_cooldown_remaining - delta)
	melee_cooldown_remaining = max(0.0, melee_cooldown_remaining - delta)
	current_recoil = max(0.0, current_recoil - recoil_decay * delta)
	_update_pending_ranged_shot(delta)
	_update_body_recoil(delta)
	_update_attack_buffer(delta)
	_update_melee_attack(delta)
	_update_melee_recovery(delta)
	_update_reload(delta)
	_update_animation_state_machine(delta)
	_update_combat_target()
	_update_target_ring()
	_update_interaction_target()
	if _is_dead:
		_update_animation_state_machine(delta)
		return
	_handle_interact_input()
	if _is_terminal_open():
		return
	_handle_loadout_toggle_input()
	try_apply_pending_weapon_selection()
	_handle_aim_input_toggle()
	_handle_reload_input()
	_update_aim()
	_update_animation()
	var is_repairing := false
	if Input.is_action_pressed("repair"):
		is_repairing = _try_repair(delta)
	if is_repairing:
		return
	if Input.is_action_pressed("build"):
		_try_build(delta)
	_handle_attack_input()
	if _wants_block():
		_request_block_state()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not arrow_aim_enabled:
		var mouse_aim_vector := _get_world_mouse_position() - global_position
		if mouse_aim_vector.length_squared() > 0.0001:
			visual_idle_direction = mouse_aim_vector.normalized()


func _physics_process(delta):
	if _is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _is_terminal_open():
		velocity = Vector2.ZERO
		is_sprinting = false
		stamina = min(stamina_max, stamina + stamina_regen_per_second * delta)
		move_and_slide()
		return
	if _is_movement_locked():
		velocity = Vector2.ZERO
		is_sprinting = false
		move_and_slide()
		return

	var direction: Vector2 = Vector2.ZERO
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	var input_direction: Vector2 = direction.normalized() if direction.length_squared() > 0.0001 else Vector2.ZERO

	# Track movement direction for animations
	if input_direction != Vector2.ZERO:
		movement_direction = input_direction
		visual_idle_direction = input_direction

	var moving = input_direction != Vector2.ZERO
	var wants_sprint = Input.is_key_pressed(KEY_CTRL)
	var was_sprinting := is_sprinting
	if _sprint_exhausted and stamina >= stamina_max:
		_sprint_exhausted = false
	var can_start_sprint := stamina > stamina_sprint_gate
	is_sprinting = moving and wants_sprint and not _sprint_exhausted and (was_sprinting or can_start_sprint)
	var movement_profile := get_current_combat_profile()
	var move_speed = SPEED * sprint_multiplier if is_sprinting else SPEED
	if movement_profile != null:
		move_speed *= movement_profile.move_speed_multiplier
	if _is_ranged_firing_move_state():
		move_speed *= _get_ranged_firing_move_multiplier()
	if _is_block_state_active():
		move_speed *= block_move_multiplier
	# Apply cognitive state move speed modifier
	var cognitive := get_node_or_null("/root/CognitiveState")
	if cognitive != null and cognitive.has_method("get_move_speed_multiplier"):
		move_speed *= float(cognitive.call("get_move_speed_multiplier"))
	var target_velocity: Vector2 = input_direction * move_speed
	var accel_rate: float = move_acceleration if moving else move_deceleration
	if movement_profile != null:
		accel_rate *= movement_profile.acceleration_multiplier
	velocity = velocity.move_toward(target_velocity, accel_rate * delta)
	move_and_slide()

	if is_sprinting:
		stamina = max(0.0, stamina - stamina_drain_per_second * delta)
		if stamina <= 0.0:
			is_sprinting = false
			if stamina_sprint_exhaustion_requires_full_recovery:
				_sprint_exhausted = true
	else:
		stamina = min(stamina_max, stamina + stamina_regen_per_second * delta)

	# DEBUG: Press J to damage nearest sector
	if Input.is_key_pressed(KEY_J):
		_damage_nearest_sector(10.0)


func _update_aim():
	var keyboard_aim := _get_keyboard_aim_direction()
	if arrow_aim_enabled:
		if keyboard_aim != Vector2.ZERO:
			aim_direction = keyboard_aim
			visual_idle_direction = keyboard_aim
	else:
		var mouse_aim_vector := _get_world_mouse_position() - global_position
		if mouse_aim_vector.length_squared() > 0.0001:
			aim_direction = mouse_aim_vector.normalized()
	_apply_dynamic_weapon_socket_layout()
	var weapon_display_angle := _get_weapon_display_angle(aim_direction)
	
	# Rotate barrel instead of entire body
	if primary_weapon_socket and _is_using_ranged_2h_primary() and not _is_facing_up(aim_direction):
		primary_weapon_socket.rotation = weapon_display_angle + deg_to_rad(current_recoil * 0.12)
	elif primary_weapon_socket:
		primary_weapon_socket.rotation = 0.0
	elif barrel:
		barrel.rotation = aim_direction.angle() + deg_to_rad(current_recoil * 0.12)


func _update_animation():
	if animated_sprite == null:
		return
	
	# Check if currently firing or attacking (lock to cursor)
	var is_firing = _is_ranged_fire_animation_active()
	var current_animation := String(animated_sprite.animation)
	var is_melee_attack_anim := current_animation.begins_with("melee_2h_fast") or current_animation.begins_with("melee_2h_heavy")
	var is_attacking = _melee_active or (
		animated_sprite.is_playing()
		and (is_melee_attack_anim or current_animation.begins_with("attack"))
	)
	var is_block_anim = _is_block_state_active()
	var is_reloading = _reload_active
	
	# If firing or attacking, use aim direction. Otherwise use movement direction.
	var is_moving = velocity.length() > 0
	var animation_dir: Vector2
	
	if is_firing or is_attacking or is_block_anim or is_reloading or _melee_recovery_active:
		animation_dir = aim_direction
	else:
		animation_dir = movement_direction if is_moving else visual_idle_direction
	
	# Determine direction suffix
	var direction_suffix := _get_direction_suffix(animation_dir)
	var facing_left := _is_facing_left(animation_dir)
	var facing_up := _is_facing_up(animation_dir)

	# Don't override attack animation while playing
	if is_attacking or is_block_anim or _melee_recovery_active or _is_equip_weapon_state_active():
		var active_animation_name := String(animated_sprite.animation)
		animated_sprite.flip_h = facing_left and not active_animation_name.ends_with("_left")
		return

	if is_reloading:
		animated_sprite.flip_h = facing_left
		animated_sprite.speed_scale = 1.0
		if animated_sprite.sprite_frames.has_animation("ranged_2h_reload"):
			if animated_sprite.animation != "ranged_2h_reload" or not animated_sprite.is_playing():
				animated_sprite.play("ranged_2h_reload")
		_update_primary_weapon_visual(false)
		_update_idle_loop_tracking(false, "")
		return
	
	# Set horizontal flip based on facing direction (only for left/right)
	animated_sprite.flip_h = facing_left
	_update_primary_weapon_visual(is_firing)

	var ranged_fire_anim := _get_current_ranged_body_fire_animation(is_moving and not is_sprinting)
	if is_firing and not facing_up and _is_using_ranged_2h_primary() and animated_sprite.sprite_frames.has_animation(ranged_fire_anim):
		animated_sprite.speed_scale = _get_body_animation_speed_scale(ranged_fire_anim)
		if animated_sprite.animation != ranged_fire_anim or not animated_sprite.is_playing():
			animated_sprite.play(ranged_fire_anim)
		_update_idle_loop_tracking(false, "")
		return
	animated_sprite.speed_scale = 1.0
	
	# Play walk or idle based on movement and direction
	if is_moving:
		if is_sprinting:
			var run_anim := String(AnimationResolver.resolve("unarmed_run", animation_dir, animated_sprite)) if _is_current_profile_unarmed() else "run_" + direction_suffix
			if animated_sprite.sprite_frames.has_animation(run_anim):
				animated_sprite.flip_h = facing_left and not run_anim.ends_with("_left")
				if animated_sprite.animation != run_anim:
					animated_sprite.play(run_anim)
				_update_idle_loop_tracking(false, "")
				return
			if animated_sprite.sprite_frames.has_animation("run_right"):
				if animated_sprite.animation != "run_right":
					animated_sprite.play("run_right")
				_update_idle_loop_tracking(false, "")
				return
			_update_idle_loop_tracking(false, "")
			return
		if _is_current_profile_unarmed():
			var unarmed_walk_anim := String(AnimationResolver.resolve("unarmed_walk", animation_dir, animated_sprite))
			if animated_sprite.sprite_frames.has_animation(unarmed_walk_anim):
				animated_sprite.flip_h = facing_left and not unarmed_walk_anim.ends_with("_left")
				if animated_sprite.animation != unarmed_walk_anim:
					animated_sprite.play(unarmed_walk_anim)
				_update_idle_loop_tracking(false, "")
				return
		if not _is_using_ranged_2h_primary() and direction_suffix == "down" and animated_sprite.sprite_frames.has_animation("walk_down_default"):
			if animated_sprite.animation != "walk_down_default":
				animated_sprite.play("walk_down_default")
			_update_idle_loop_tracking(false, "")
			return
		var walk_anim = "walk_" + direction_suffix
		if animated_sprite.sprite_frames.has_animation(walk_anim):
			if animated_sprite.animation != walk_anim:
				animated_sprite.play(walk_anim)
			_update_idle_loop_tracking(false, "")
		else:
			# Fallback to right with flip
			if animated_sprite.animation != "walk_right":
				animated_sprite.play("walk_right")
			_update_idle_loop_tracking(false, "")
	else:
		var melee_body_stance_anim := _get_authored_melee_body_stance_animation()
		if _is_melee_loadout_active() and not melee_body_stance_anim.is_empty():
			var resolved_stance_anim := AnimationResolver.resolve(String(melee_body_stance_anim), animation_dir, animated_sprite)
			if animated_sprite.sprite_frames.has_animation(resolved_stance_anim):
				animated_sprite.flip_h = facing_left and not String(resolved_stance_anim).ends_with("_left")
				if animated_sprite.animation != resolved_stance_anim:
					animated_sprite.play(resolved_stance_anim)
				_update_idle_loop_tracking(false, "")
				return
		var ranged_stance_anim := _get_weapon_animation_name(_get_equipped_primary_weapon_definition(), "ranged_stance", &"ranged_2h_stance")
		if not facing_up and animated_sprite.sprite_frames.has_animation(ranged_stance_anim) and _is_using_ranged_2h_primary():
			if animated_sprite.animation != ranged_stance_anim:
				animated_sprite.play(ranged_stance_anim)
			_update_idle_loop_tracking(false, "")
			return
		var idle_anim = "idle_" + direction_suffix
		if _should_play_idle_long() and animated_sprite.sprite_frames.has_animation("idle_long"):
			idle_anim = "idle_long"
		if animated_sprite.sprite_frames.has_animation(idle_anim):
			if animated_sprite.animation != idle_anim:
				animated_sprite.play(idle_anim)
			_update_idle_loop_tracking(true, idle_anim)
		else:
			# Fallback to right with flip
			if animated_sprite.animation != "idle_right":
				animated_sprite.play("idle_right")
			_update_idle_loop_tracking(true, "idle_right")


func _get_direction_suffix(dir: Vector2) -> String:
	# Determine direction based on angle (8 directions)
	var angle = dir.angle()  # -PI to PI
	
	# Convert to 8 directions
	# Right: 0, Down: PI/2, Left: PI, Up: -PI/2
	if angle >= -PI/8 and angle < PI/8:
		return "right"
	elif angle >= PI/8 and angle < 3*PI/8:
		return "down_right"
	elif angle >= 3*PI/8 and angle < 5*PI/8:
		return "down"
	elif angle >= -3*PI/8 and angle < -PI/8:
		return "up_right"
	elif angle >= -5*PI/8 and angle < -3*PI/8:
		return "up"
	elif angle >= 5*PI/8 or angle < -5*PI/8:
		return "left"
	# Default
	return "down"


func _is_facing_left(dir: Vector2) -> bool:
	return dir.x < -0.05


func _is_facing_up(dir: Vector2) -> bool:
	# Returns true if the direction is primarily upward
	var angle = dir.angle()  # -PI to PI
	# Up is angles between -3*PI/4 and -PI/4
	return angle >= -3*PI/4 and angle <= -PI/4


func _get_weapon_display_angle(dir: Vector2) -> float:
	# Keep the local weapon rotation in a right-facing range and use flip_h for left aim.
	# This avoids rotating past vertical and drawing the weapon upside down.
	var angle := atan2(dir.y, absf(dir.x))
	return -angle if _is_facing_left(dir) else angle


func _request_ranged_shot() -> void:
	if not _is_ranged_loadout_active():
		return
	if _reload_active:
		return
	if not _has_loaded_ammo():
		_try_start_reload()
		return
	var profile := _get_current_ranged_profile()
	last_fire_cooldown = float(profile["cooldown"])
	fire_cooldown_remaining = last_fire_cooldown
	# Apply cognitive attack recovery modifier (instinct reduces cooldown)
	var cognitive := get_node_or_null("/root/CognitiveState")
	if cognitive != null and cognitive.has_method("get_attack_recovery_multiplier"):
		var multiplier: float = float(cognitive.call("get_attack_recovery_multiplier"))
		fire_cooldown_remaining *= multiplier
		last_fire_cooldown *= multiplier
	var fire_animation := _get_current_ranged_body_fire_animation(velocity.length() > 0.01 and not is_sprinting)
	var delay := _get_ranged_fire_release_delay(fire_animation)
	_pending_ranged_shot = {
		"timer": delay,
		"profile": profile.duplicate(true),
		"aim_direction": _get_attack_aim_direction(),
	}
	_play_ranged_fire_animation(fire_animation)
	if delay <= 0.0:
		_emit_pending_ranged_shot()


func _emit_pending_ranged_shot() -> void:
	if _pending_ranged_shot.is_empty():
		return
	var profile: Dictionary = _pending_ranged_shot.get("profile", {})
	var direction: Vector2 = _pending_ranged_shot.get("aim_direction", Vector2.RIGHT)
	_pending_ranged_shot.clear()
	if direction.length_squared() <= 0.0001:
		return
	var spread := float(profile.get("spread", 0.0)) + (current_recoil * 0.2)
	# Apply cognitive accuracy bonus (bearing reduces spread)
	var cognitive := get_node_or_null("/root/CognitiveState")
	if cognitive != null and cognitive.has_method("get_player_accuracy_bonus"):
		var accuracy_bonus: float = float(cognitive.call("get_player_accuracy_bonus"))
		spread = max(0.0, spread - accuracy_bonus)
	var spread_rad := deg_to_rad(randf_range(-spread, spread))
	direction = direction.rotated(spread_rad)

	var bullet = BULLET_SCENE.instantiate()
	if bullet == null:
		return

	var spawn_position: Vector2 = global_position + direction * muzzle_offset
	if barrel:
		spawn_position = barrel.global_position
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction)
	bullet.speed = float(profile.get("speed", 780.0))
	bullet.damage = float(profile.get("damage", 16.0))
	bullet.bullet_radius = float(profile.get("radius", 3.0))
	bullet.bullet_color = profile.get("color", Color(1.0, 0.9, 0.35, 1.0))
	bullet.impact_scene = IMPACT_SPARK_SCENE
	bullet.shooter = self
	# Apply cognitive crit bonus (bearing increases crit chance)
	var cognitive := get_node_or_null("/root/CognitiveState")
	if cognitive != null and cognitive.has_method("get_player_crit_bonus"):
		bullet.crit_chance = float(cognitive.call("get_player_crit_bonus"))

	var container = get_node_or_null("/root/GameRoot/World/Projectiles")
	if container:
		container.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)
	bullet.global_position = spawn_position

	current_recoil += float(profile.get("recoil_kick", 1.2))
	_consume_ammo()
	_spawn_muzzle_flash(direction)
	_apply_body_recoil_impulse(direction)


func _handle_attack_input() -> void:
	if _is_blocking():
		return
	if _is_attack_secondary_just_pressed():
		_request_current_profile_intent(false)
		return
	if _is_attack_primary_just_pressed():
		_request_current_profile_intent(true)
		return
	if _is_ranged_loadout_active() and _is_attack_primary_pressed() and fire_cooldown_remaining <= 0.0 and _pending_ranged_shot.is_empty():
		_request_current_profile_intent(true)


func _request_current_profile_intent(primary: bool) -> void:
	var profile := get_current_combat_profile()
	if profile == null:
		return
	var intent := profile.primary_intent if primary else profile.secondary_intent
	if intent.is_empty():
		return
	_request_attack_intent(intent)


func _request_attack_intent(intent: String) -> void:
	match intent:
		"ranged_fire":
			_request_ranged_shot()
		"melee_light", "melee_fast", "melee_heavy", "unarmed_fast", "unarmed_heavy":
			_try_melee_attack(intent)
		_:
			push_warning("Unsupported attack intent: %s" % intent)


func _try_melee_attack(intent: String = ""):
	if not _is_melee_loadout_active():
		return
	var requested_kind := _get_requested_attack_kind(intent)
	if _can_start_attack_now():
		_request_attack_state(requested_kind)
		return
	_buffer_attack(requested_kind)


func _is_attack_primary_just_pressed() -> bool:
	return Input.is_action_just_pressed("attack_primary") \
		or Input.is_action_just_pressed("attack") \
		or Input.is_action_just_pressed("melee_attack")


func _is_attack_primary_pressed() -> bool:
	return Input.is_action_pressed("attack_primary") \
		or Input.is_action_pressed("attack") \
		or Input.is_action_pressed("melee_attack")


func _is_attack_secondary_just_pressed() -> bool:
	return Input.is_action_just_pressed("attack_secondary") \
		or (Input.is_key_pressed(KEY_SHIFT) and _is_attack_primary_just_pressed())


func _get_requested_attack_kind(intent: String = "") -> String:
	if not intent.is_empty():
		return _attack_kind_from_intent(intent)
	var wants_heavy: bool = Input.is_key_pressed(KEY_SHIFT)
	if not wants_heavy:
		return "light"
	if heavy_attack_blocked_while_sprinting and is_sprinting:
		return "light"
	if stamina < heavy_attack_stamina_cost:
		return "light"
	if Input.is_key_pressed(KEY_SHIFT):
		return "heavy"
	return "light"


func _attack_kind_from_intent(intent: String) -> String:
	match intent:
		"melee_heavy":
			return "heavy"
		"unarmed_heavy":
			return "heavy"
		"melee_fast":
			return "fast"
		"unarmed_fast":
			return "fast"
		"melee_light":
			return "light"
		_:
			return "light"


func _can_start_attack_now() -> bool:
	if _melee_active:
		return false
	return melee_cooldown_remaining <= 0.0


func _start_attack_by_kind(kind: String) -> void:
	if kind == "heavy":
		_start_heavy_attack()
	elif kind == "fast":
		_start_fast_attack()
	else:
		_start_light_attack()


func _request_attack_state(kind: String) -> void:
	var state_name := "attack_light"
	if kind == "heavy":
		state_name = "attack_heavy"
	elif kind == "fast":
		state_name = "attack_fast"
	if _animation_state_machine != null and _animation_state_machine.request(state_name, 10):
		return
	_start_attack_by_kind(kind)


func _request_block_state() -> void:
	if _animation_state_machine != null:
		_animation_state_machine.request("block", 8)


func _buffer_attack(kind: String) -> void:
	_buffered_attack_kind = kind
	_buffered_attack_timer = melee_input_buffer_time


func _update_attack_buffer(delta: float) -> void:
	if _buffered_attack_kind.is_empty():
		return
	_buffered_attack_timer = max(0.0, _buffered_attack_timer - delta)
	if _buffered_attack_timer <= 0.0:
		_clear_attack_buffer()


func _consume_buffered_attack() -> String:
	var kind := _buffered_attack_kind
	_clear_attack_buffer()
	return kind


func _clear_attack_buffer() -> void:
	_buffered_attack_kind = ""
	_buffered_attack_timer = 0.0


func _start_light_attack() -> void:
	_active_attack_profile = get_current_combat_profile()
	_melee_active = true
	_melee_heavy_anticipating = false
	_melee_fast_combo_step = 0
	_melee_attack_kind = "light"
	_melee_attack_key = "melee_light"
	_notify_camera_attack_windup(false)
	_melee_elapsed = 0.0
	_melee_duration = 0.46
	_melee_forward = _get_melee_forward_direction()
	_configure_melee_hitbox(melee_light_hit_damage, melee_light_range, melee_light_arc_degrees)
	_play_melee_anim_from_key(_melee_attack_key, &"melee_2h_fast")
	_lock_melee_cooldown(_melee_duration + 0.06)


func _start_fast_attack() -> void:
	_active_attack_profile = get_current_combat_profile()
	_melee_active = true
	_melee_heavy_anticipating = false
	_melee_attack_kind = "fast"
	_notify_camera_attack_windup(false)
	var next_fast_key := "melee_fast_1"
	var fallback_animation: StringName = &"melee_2h_fast"
	var next_duration := 0.42
	var is_unarmed_attack := _is_attack_profile_unarmed(_active_attack_profile)
	if _melee_fast_combo_step >= 1 and animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("melee_2h_fast_2_right"):
		next_fast_key = "melee_fast_2"
		fallback_animation = &"melee_2h_fast_2"
		next_duration = 0.42
		_melee_fast_combo_step = 2
	else:
		_melee_fast_combo_step = 1
		if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("melee_2h_fast_1_right"):
			fallback_animation = &"melee_2h_fast_1"
		next_duration = 0.42
	if is_unarmed_attack:
		next_fast_key = "unarmed_fast_2" if _melee_fast_combo_step >= 2 else "unarmed_fast_1"
		fallback_animation = &"unarmed_attack_fast"
	_melee_attack_key = next_fast_key
	_melee_elapsed = 0.0
	_melee_duration = next_duration
	_melee_forward = _get_melee_forward_direction()
	_configure_melee_hitbox(melee_fast_hit_damage, melee_range, melee_arc_degrees)
	_play_melee_anim_from_key(_melee_attack_key, fallback_animation)
	_lock_melee_cooldown(_melee_duration + 0.10)


func _start_heavy_attack() -> void:
	_active_attack_profile = get_current_combat_profile()
	_melee_heavy_anticipating = false
	_melee_fast_combo_step = 0
	_melee_attack_kind = "heavy"
	var is_unarmed_attack := _is_attack_profile_unarmed(_active_attack_profile)
	_melee_attack_key = "unarmed_heavy" if is_unarmed_attack else "melee_heavy"
	_notify_camera_attack_windup(true)
	stamina = max(0.0, stamina - heavy_attack_stamina_cost)
	_melee_forward = _get_melee_forward_direction()
	if not is_unarmed_attack and animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("melee_2h_heavy_anticipation"):
		_melee_active = false
		_melee_heavy_anticipating = true
		_melee_elapsed = 0.0
		_melee_duration = 0.0
		disable_hitbox()
		_melee_hit_targets.clear()
		animated_sprite.flip_h = _is_facing_left(_melee_forward)
		animated_sprite.play("melee_2h_heavy_anticipation")
		_play_named_melee_weapon_overlay(&"melee_2h_heavy_anticipation_weapon")
		_lock_melee_cooldown(1.10)
		return
	_begin_heavy_attack_active_phase()


func _is_attack_profile_unarmed(profile: OperatorWeaponDefinition) -> bool:
	return profile != null and profile.weapon_kind == "unarmed"


func _is_current_profile_unarmed() -> bool:
	return _is_attack_profile_unarmed(get_current_combat_profile())


func _begin_heavy_attack_active_phase() -> void:
	_melee_heavy_anticipating = false
	_melee_active = true
	_melee_elapsed = 0.0
	_melee_duration = 0.70
	_configure_melee_hitbox(melee_heavy_hit_damage, melee_heavy_range, melee_heavy_arc_degrees)
	_play_melee_anim_from_key(_melee_attack_key, &"melee_2h_heavy")
	if melee_cooldown_remaining <= 0.0:
		_lock_melee_cooldown(_melee_duration + 0.18)


func _get_cancel_start_time() -> float:
	if _melee_attack_kind == "heavy":
		return melee_heavy_cancel_start
	if _melee_attack_kind == "light":
		return melee_light_cancel_start
	return melee_fast_cancel_start


func _update_melee_attack(delta: float) -> void:
	if not _melee_active:
		disable_hitbox()
		return
	_melee_elapsed += delta

	_update_melee_hitbox_transform()
	_sync_melee_hitbox_window_from_animation()
	if _melee_hitbox_active:
		_apply_melee_hitbox_tick()

	if not _buffered_attack_kind.is_empty() and _melee_elapsed >= _get_cancel_start_time():
		_request_attack_state(_consume_buffered_attack())
		return

	if _melee_elapsed < _melee_duration:
		return

	if _melee_attack_kind == "fast" and _buffered_attack_kind.is_empty():
		_start_fast_attack_recovery()
		_melee_fast_combo_step = 0

	_melee_active = false
	_melee_attack_kind = ""
	_melee_attack_key = ""
	_melee_elapsed = 0.0
	_melee_duration = 0.0
	_melee_heavy_anticipating = false
	_active_attack_profile = null
	disable_hitbox()
	_melee_hit_targets.clear()
	if not _melee_recovery_active:
		_reset_melee_overlay_visuals()


func _apply_melee_hitbox_tick() -> void:
	if weapon_hitbox == null:
		return
	var weapon_definition = _active_attack_profile if _active_attack_profile != null else _get_equipped_primary_weapon_definition()
	var window: Dictionary = {}
	if weapon_definition != null and weapon_definition.hit_windows is Dictionary:
		window = weapon_definition.hit_windows.get(_melee_attack_key, {})
	var active_directions := _get_melee_active_hit_directions(animated_sprite.frame if animated_sprite else 0, window)
	var hit_count := 0
	for body in weapon_hitbox.get_overlapping_bodies():
		if not (body is Node2D):
			continue
		var enemy = body as Node2D
		if enemy == null or not enemy.is_in_group("enemy"):
			continue
		if not enemy.has_method("take_damage"):
			continue
		var enemy_id: int = enemy.get_instance_id()
		if _melee_hit_targets.has(enemy_id):
			continue
		var to_enemy = enemy.global_position - global_position
		var dist = to_enemy.length()
		if dist <= 0.001 or dist > _melee_range_current:
			continue
		if not active_directions.is_empty():
			var enemy_direction := _get_melee_hit_direction_label(to_enemy.normalized())
			if not active_directions.has(enemy_direction):
				continue
		var angle = abs(rad_to_deg(_melee_forward.angle_to(to_enemy.normalized())))
		if angle > (_melee_arc_current * 0.5):
			continue
		var impact_position := _resolve_melee_impact_position(enemy)
		enemy.take_damage(_melee_damage_current)
		_melee_hit_targets[enemy_id] = true
		var knockback_dir := global_position.direction_to(enemy.global_position)
		var knockback_force := melee_fast_knockback_force if _melee_attack_kind == "fast" else melee_heavy_knockback_force
		if enemy.has_method("apply_melee_impact"):
			enemy.apply_melee_impact(_melee_attack_kind, knockback_dir, knockback_force)
		else:
			enemy.velocity = knockback_dir * knockback_force
			enemy.move_and_slide()
		hit_count += 1
		_spawn_melee_impact(impact_position)
	if hit_count > 0:
		_on_melee_hit_confirmed()
		print("MELEE HIT: ", hit_count, " target(s), damage=", _melee_damage_current)


func _get_melee_forward_direction() -> Vector2:
	return _get_attack_aim_direction()


func is_attack_state_complete(kind: String) -> bool:
	if _melee_heavy_anticipating:
		return false
	if _melee_recovery_active and kind == "fast":
		return false
	if _melee_active:
		return _melee_attack_kind != kind
	return true


func start_attack(attack_key: String) -> void:
	if attack_key == "melee_light":
		_start_light_attack()
	elif attack_key == "melee_fast" or attack_key == "unarmed_fast":
		_start_fast_attack()
	elif attack_key == "melee_heavy" or attack_key == "unarmed_heavy":
		_start_heavy_attack()


func start_block() -> void:
	if not _is_melee_loadout_active():
		_block_phase = &""
		_block_active = false
		return
	if _block_phase == &"hold":
		return
	_melee_active = false
	_melee_attack_kind = ""
	_melee_attack_key = ""
	_melee_elapsed = 0.0
	_melee_duration = 0.0
	_active_attack_profile = null
	disable_hitbox()
	_melee_hit_targets.clear()
	_reset_melee_overlay_visuals()
	_block_phase = &"enter"
	_block_active = false
	_play_block_animation(&"melee_2h_block_enter")


func update_block_state() -> String:
	if animated_sprite == null:
		_block_phase = &""
		_block_active = false
		return _get_desired_animation_state()
	match _block_phase:
		&"enter":
			if not animated_sprite.is_playing():
				_block_phase = &"hold"
				_block_active = true
				_play_block_animation(&"melee_2h_block_hold")
			return "block"
		&"hold":
			if not _wants_block():
				_block_phase = &"exit"
				_block_active = false
				_play_block_animation(&"melee_2h_block_exit")
			return "block"
		&"exit":
			if not animated_sprite.is_playing():
				_block_phase = &""
				_block_active = false
				return _get_desired_animation_state()
			return "block"
		_:
			if _wants_block():
				start_block()
				return "block"
			return _get_desired_animation_state()


func _play_block_animation(animation_name: StringName) -> void:
	if animated_sprite == null:
		return
	animated_sprite.flip_h = _is_facing_left(aim_direction)
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	_play_block_weapon_overlay(animation_name)


func _play_block_weapon_overlay(animation_name: StringName) -> void:
	if melee_weapon_overlay_sprite == null:
		return
	var weapon_animation := StringName("%s_weapon" % String(animation_name))
	if _play_named_melee_weapon_overlay(weapon_animation):
		return
	melee_weapon_overlay_sprite.visible = false
	melee_weapon_overlay_sprite.stop()
	melee_weapon_overlay_sprite.frame = 0


func _play_melee_anim_from_key(attack_key: String, fallback_animation: StringName = &"") -> void:
	if not _is_melee_loadout_active():
		return
	if animated_sprite == null:
		return
	var weapon_definition = _get_equipped_primary_weapon_definition()
	var base_animation := _get_weapon_animation_name(weapon_definition, attack_key, fallback_animation)
	if _play_melee_anim_resolved(base_animation, _melee_forward, attack_key):
		return
	if not fallback_animation.is_empty() and fallback_animation != base_animation:
		_warn_missing_animation_once(String(base_animation), String(fallback_animation))
		_play_melee_anim_resolved(fallback_animation, _melee_forward, attack_key)


func _play_melee_anim_resolved(base_animation: StringName, direction: Vector2, attack_key: String) -> bool:
	if animated_sprite == null:
		return false
	animated_sprite.flip_h = _is_facing_left(direction)
	var resolved_animation := AnimationResolver.resolve(String(base_animation), direction, animated_sprite)
	if animated_sprite.sprite_frames and _has_playable_sprite_animation(animated_sprite.sprite_frames, resolved_animation):
		animated_sprite.flip_h = _is_facing_left(direction) and not String(resolved_animation).ends_with("_left")
		animated_sprite.play(resolved_animation)
		_play_melee_overlay_from_key(attack_key)
		_sync_melee_hitbox_window_from_animation()
		return true
	var right_fallback := StringName("%s_right" % String(base_animation))
	if animated_sprite.sprite_frames and _has_playable_sprite_animation(animated_sprite.sprite_frames, right_fallback):
		animated_sprite.play(right_fallback)
		return true
	if animated_sprite.sprite_frames and _has_playable_sprite_animation(animated_sprite.sprite_frames, base_animation):
		animated_sprite.play(base_animation)
		return true
	if animated_sprite.sprite_frames and _has_playable_sprite_animation(animated_sprite.sprite_frames, &"attack_right_old"):
		animated_sprite.play("attack_right_old")
		return true
	return false


func _warn_missing_animation_once(animation_name: String, fallback_name: String) -> void:
	if _missing_animation_warnings.has(animation_name):
		return
	_missing_animation_warnings[animation_name] = true
	push_warning("Missing operator animation '%s'; using '%s' fallback" % [animation_name, fallback_name])


func _has_playable_sprite_animation(sprite_frames: SpriteFrames, animation_name: StringName) -> bool:
	return sprite_frames.has_animation(animation_name) and sprite_frames.get_frame_count(animation_name) > 0


func _lock_melee_cooldown(duration: float) -> void:
	var profile := _active_attack_profile if _active_attack_profile != null else get_current_combat_profile()
	if profile != null:
		duration *= profile.recovery_multiplier
	melee_cooldown_remaining = duration
	last_fire_cooldown = max(last_fire_cooldown, duration)
	fire_cooldown_remaining = max(fire_cooldown_remaining, melee_cooldown_remaining)


func _configure_melee_hitbox(damage: float, attack_range: float, attack_arc_degrees: float) -> void:
	var profile := _active_attack_profile if _active_attack_profile != null else get_current_combat_profile()
	var damage_multiplier := profile.damage_multiplier if profile != null else 1.0
	var range_multiplier := profile.range_multiplier if profile != null else 1.0
	_melee_damage_current = damage * damage_multiplier
	_melee_range_current = attack_range * range_multiplier
	_melee_arc_current = attack_arc_degrees
	_melee_hit_targets.clear()
	_update_melee_hitbox_transform()
	disable_hitbox()


func _update_melee_hitbox_transform() -> void:
	if hitbox_root == null or weapon_hitbox == null or weapon_hitbox_shape == null:
		return
	hitbox_root.rotation = _melee_forward.angle()
	weapon_hitbox.position = Vector2(_melee_range_current * 0.62, 0.0)
	if weapon_hitbox_shape.shape is CircleShape2D:
		var circle := weapon_hitbox_shape.shape as CircleShape2D
		circle.radius = max(8.0, _melee_range_current * 0.44)


func _sync_melee_hitbox_window_from_animation() -> void:
	if animated_sprite == null or not _melee_active:
		disable_hitbox()
		return
	var frame: int = animated_sprite.frame
	var weapon_definition = _get_equipped_primary_weapon_definition()
	var window: Dictionary = {}
	if weapon_definition != null and weapon_definition.hit_windows is Dictionary:
		window = weapon_definition.hit_windows.get(_melee_attack_key, {})
	if _is_melee_hit_frame_active(frame, window):
		enable_hitbox()
	else:
		disable_hitbox()


func _is_melee_hit_frame_active(frame: int, window: Dictionary) -> bool:
	var authored_frame: int = frame + 1
	if window.has("frames"):
		var active_frames = window.get("frames", [])
		if active_frames is Array:
			for active_frame in active_frames:
				if int(active_frame) == authored_frame:
					return true
			return false
	var active_start: int = int(window.get("start", 0))
	var active_end: int = int(window.get("end", -1))
	return authored_frame >= active_start and authored_frame <= active_end


func _get_melee_active_hit_directions(frame: int, window: Dictionary) -> Array[String]:
	var authored_frame: int = frame + 1
	var active_directions: Array[String] = []
	var directional_frames = window.get("directional_frames", {})
	if directional_frames is Dictionary:
		var directions = directional_frames.get(str(authored_frame), directional_frames.get(authored_frame, []))
		if directions is Array:
			for direction in directions:
				active_directions.append(str(direction))
	return active_directions


func _get_melee_hit_direction_label(direction: Vector2) -> String:
	var angle := direction.angle()
	if angle >= -PI / 8.0 and angle < PI / 8.0:
		return "east"
	if angle >= PI / 8.0 and angle < 3.0 * PI / 8.0:
		return "southeast"
	if angle >= 3.0 * PI / 8.0 and angle < 5.0 * PI / 8.0:
		return "south"
	if angle >= 5.0 * PI / 8.0 and angle < 7.0 * PI / 8.0:
		return "southwest"
	if angle >= 7.0 * PI / 8.0 or angle < -7.0 * PI / 8.0:
		return "west"
	if angle >= -7.0 * PI / 8.0 and angle < -5.0 * PI / 8.0:
		return "northwest"
	if angle >= -5.0 * PI / 8.0 and angle < -3.0 * PI / 8.0:
		return "north"
	return "northeast"


func enable_hitbox() -> void:
	if weapon_hitbox == null:
		return
	if _melee_hitbox_active:
		return
	_melee_hitbox_active = true
	weapon_hitbox.monitoring = true


func disable_hitbox() -> void:
	if weapon_hitbox == null:
		return
	_melee_hitbox_active = false
	weapon_hitbox.monitoring = false


func _on_attack_frame_changed() -> void:
	_sync_melee_hitbox_window_from_animation()
	_sync_melee_overlay_frames()


func _play_melee_overlay_from_key(attack_key: String) -> void:
	if not _is_melee_loadout_active():
		_reset_melee_overlay_visuals()
		return
	var weapon_definition = _get_equipped_primary_weapon_definition()
	if weapon_definition == null or not (weapon_definition.fx_map is Dictionary):
		_reset_melee_overlay_visuals()
		return
	var overlay_data = weapon_definition.fx_map.get(attack_key, {})
	if overlay_data.is_empty():
		_reset_melee_overlay_visuals()
		return
	var weapon_anim := StringName(str(overlay_data.get("weapon_anim", "")))
	var fx_anim := StringName(str(overlay_data.get("fx_anim", "")))
	if not weapon_anim.is_empty() and melee_weapon_overlay_sprite:
		weapon_anim = AnimationResolver.resolve(String(weapon_anim), _melee_forward, melee_weapon_overlay_sprite)
	if not fx_anim.is_empty() and melee_fx_overlay_sprite:
		fx_anim = AnimationResolver.resolve(String(fx_anim), _melee_forward, melee_fx_overlay_sprite)
	if melee_weapon_overlay_sprite and melee_weapon_overlay_sprite.sprite_frames and melee_weapon_overlay_sprite.sprite_frames.has_animation(weapon_anim):
		melee_weapon_overlay_sprite.visible = true
		melee_weapon_overlay_sprite.flip_h = animated_sprite.flip_h if animated_sprite else false
		melee_weapon_overlay_sprite.play(weapon_anim)
	if melee_fx_overlay_sprite and melee_fx_overlay_sprite.sprite_frames and melee_fx_overlay_sprite.sprite_frames.has_animation(fx_anim):
		melee_fx_overlay_sprite.visible = true
		melee_fx_overlay_sprite.flip_h = animated_sprite.flip_h if animated_sprite else false
		melee_fx_overlay_sprite.play(fx_anim)


func _sync_melee_overlay_frames() -> void:
	if animated_sprite == null:
		return
	if melee_weapon_overlay_sprite and melee_weapon_overlay_sprite.visible:
		melee_weapon_overlay_sprite.flip_h = animated_sprite.flip_h
		melee_weapon_overlay_sprite.frame = animated_sprite.frame
	if melee_fx_overlay_sprite and melee_fx_overlay_sprite.visible:
		melee_fx_overlay_sprite.flip_h = animated_sprite.flip_h
		melee_fx_overlay_sprite.frame = animated_sprite.frame
	if primary_weapon_sprite and primary_weapon_sprite.visible and _is_authored_melee_body_stance_active():
		primary_weapon_sprite.flip_h = animated_sprite.flip_h
		primary_weapon_sprite.frame = animated_sprite.frame


func _reset_melee_overlay_visuals() -> void:
	if melee_weapon_overlay_sprite:
		melee_weapon_overlay_sprite.visible = false
		melee_weapon_overlay_sprite.stop()
		melee_weapon_overlay_sprite.frame = 0
	if melee_fx_overlay_sprite:
		melee_fx_overlay_sprite.visible = false
		melee_fx_overlay_sprite.stop()
		melee_fx_overlay_sprite.frame = 0


func _play_named_melee_weapon_overlay(animation_name: StringName) -> bool:
	if melee_weapon_overlay_sprite == null:
		return false
	if melee_weapon_overlay_sprite.sprite_frames and melee_weapon_overlay_sprite.sprite_frames.has_animation(animation_name):
		melee_weapon_overlay_sprite.visible = true
		melee_weapon_overlay_sprite.flip_h = animated_sprite.flip_h if animated_sprite else false
		melee_weapon_overlay_sprite.play(animation_name)
		return true
	return false


func _play_named_melee_fx_overlay(animation_name: StringName) -> bool:
	if melee_fx_overlay_sprite == null:
		return false
	if melee_fx_overlay_sprite.sprite_frames and melee_fx_overlay_sprite.sprite_frames.has_animation(animation_name):
		melee_fx_overlay_sprite.visible = true
		melee_fx_overlay_sprite.flip_h = animated_sprite.flip_h if animated_sprite else false
		melee_fx_overlay_sprite.play(animation_name)
		return true
	return false


func _play_fast_attack_recovery() -> void:
	if animated_sprite == null or not animated_sprite.sprite_frames:
		return
	if _is_attack_profile_unarmed(_active_attack_profile):
		var recovery_animation := AnimationResolver.resolve("unarmed_attack_fast_recovery", _melee_forward, animated_sprite)
		if _melee_forward.x < -0.05 and animated_sprite.sprite_frames.has_animation("unarmed_attack_fast_recovery_left"):
			recovery_animation = &"unarmed_attack_fast_recovery_left"
		if animated_sprite.sprite_frames.has_animation(recovery_animation):
			animated_sprite.flip_h = _is_facing_left(_melee_forward) and recovery_animation != &"unarmed_attack_fast_recovery_left"
			animated_sprite.play(recovery_animation)
		if melee_weapon_overlay_sprite:
			melee_weapon_overlay_sprite.visible = false
		var recovery_fx := AnimationResolver.resolve("unarmed_attack_fast_recovery_fx", _melee_forward, melee_fx_overlay_sprite)
		if not _play_named_melee_fx_overlay(recovery_fx):
			_reset_melee_overlay_visuals()
		return
	if animated_sprite.sprite_frames.has_animation("melee_2h_fast_recovery"):
		animated_sprite.play("melee_2h_fast_recovery")
		_play_named_melee_weapon_overlay(&"melee_2h_fast_recovery_weapon")
		_play_named_melee_fx_overlay(&"melee_2h_fast_recovery_fx")


func _start_fast_attack_recovery() -> void:
	_melee_recovery_active = true
	_melee_recovery_timer = melee_fast_recovery_duration
	# Apply cognitive attack recovery modifier (instinct reduces recovery time)
	var cognitive := get_node_or_null("/root/CognitiveState")
	if cognitive != null and cognitive.has_method("get_attack_recovery_multiplier"):
		var multiplier: float = float(cognitive.call("get_attack_recovery_multiplier"))
		_melee_recovery_timer *= multiplier
	_play_fast_attack_recovery()


func _update_melee_recovery(delta: float) -> void:
	if not _melee_recovery_active:
		return
	_melee_recovery_timer = max(0.0, _melee_recovery_timer - delta)
	if _melee_recovery_timer > 0.0:
		return
	_melee_recovery_active = false
	_reset_melee_overlay_visuals()


func _spawn_melee_impact(pos: Vector2):
	var parent = get_node_or_null("/root/GameRoot/World/Projectiles")
	var target = parent if parent else get_tree().current_scene
	
	var spark = IMPACT_SPARK_SCENE.instantiate()
	if spark:
		target.add_child(spark)
		spark.global_position = pos
	
	var swing = MELEE_SWING_SCENE.instantiate()
	if swing:
		target.add_child(swing)
		swing.global_position = pos
		swing.set_direction(_melee_forward if _melee_forward != Vector2.ZERO else aim_direction)


func _resolve_melee_impact_position(target: Node2D) -> Vector2:
	if target == null:
		return global_position + _melee_forward * max(12.0, _melee_range_current * 0.65)
	var to_target := target.global_position - global_position
	var strike_direction := to_target.normalized() if to_target.length_squared() > 0.001 else _melee_forward.normalized()
	if strike_direction == Vector2.ZERO:
		strike_direction = Vector2.RIGHT
	return target.global_position - strike_direction * _estimate_node_contact_radius(target, 14.0)


func _estimate_node_contact_radius(target: Node, fallback_radius: float = 12.0) -> float:
	if target == null:
		return fallback_radius
	var shape_node := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
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


func _on_melee_hit_confirmed() -> void:
	_notify_camera_attack_impact(_melee_forward, _melee_attack_kind == "heavy")
	_apply_hit_stop()


func _trigger_camera_shake() -> void:
	var camera = _get_world_camera()
	if camera and camera.has_method("shake"):
		var power := melee_heavy_camera_shake_power
		if _melee_attack_kind == "light":
			power = melee_light_camera_shake_power
		elif _melee_attack_kind == "fast":
			power = melee_fast_camera_shake_power
		camera.call("shake", power if power > 0.0 else melee_camera_shake_power)


func _notify_camera_attack_windup(is_heavy: bool) -> void:
	var camera = _get_world_camera()
	if camera and camera.has_method("on_attack_windup"):
		camera.call("on_attack_windup", is_heavy)


func _notify_camera_attack_impact(direction: Vector2, is_heavy: bool) -> void:
	var camera = _get_world_camera()
	if camera and camera.has_method("on_attack_impact"):
		camera.call("on_attack_impact", direction, is_heavy)


func _notify_camera_damage_taken(hit_direction: Vector2) -> void:
	var camera = _get_world_camera()
	if camera and camera.has_method("on_damage_taken"):
		camera.call("on_damage_taken", hit_direction)


func _get_world_camera() -> Node:
	return get_node_or_null("/root/GameRoot/World/Camera2D")


func _apply_hit_stop() -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true
	var previous_scale := Engine.time_scale
	var configured_scale := melee_heavy_hit_stop_scale
	var configured_duration := melee_heavy_hit_stop_duration
	if _melee_attack_kind == "light":
		configured_scale = melee_light_hit_stop_scale
		configured_duration = melee_light_hit_stop_duration
	elif _melee_attack_kind == "fast":
		configured_scale = melee_fast_hit_stop_scale
		configured_duration = melee_fast_hit_stop_duration
	var target_scale: float = clamp(configured_scale if configured_scale > 0.0 else melee_hit_stop_scale, 0.01, 1.0)
	Engine.time_scale = min(previous_scale, target_scale)
	await get_tree().create_timer(configured_duration if configured_duration > 0.0 else melee_hit_stop_duration, true, false, true).timeout
	Engine.time_scale = previous_scale
	_hit_stop_active = false


func _handle_weapon_switch():
	weapon_profile = 0


func _handle_loadout_toggle_input() -> void:
	if Input.is_action_just_pressed("toggle_unarmed"):
		request_toggle_unarmed()
	if Input.is_action_just_pressed("cycle_next_weapon"):
		request_cycle_weapon(1)
	if Input.is_action_just_pressed("cycle_prev_weapon"):
		request_cycle_weapon(-1)


func _handle_aim_input_toggle() -> void:
	if Input.is_action_just_pressed("toggle_aim_input_mode"):
		arrow_aim_enabled = not arrow_aim_enabled


func _handle_reload_input() -> void:
	if Input.is_action_just_pressed("reload_weapon"):
		_try_start_reload()


func get_current_combat_profile() -> OperatorWeaponDefinition:
	if using_unarmed or armed_weapons.is_empty():
		return unarmed_definition
	var index: int = clampi(armed_weapon_index, 0, max(armed_weapons.size() - 1, 0))
	return armed_weapons[index]


func request_toggle_unarmed() -> void:
	_rebuild_armed_weapon_list()
	if armed_weapons.is_empty():
		queue_weapon_selection({"type": "unarmed"})
		return
	if using_unarmed:
		queue_weapon_selection({
			"type": "armed",
			"index": clampi(last_armed_weapon_index, 0, armed_weapons.size() - 1),
		})
		return
	last_armed_weapon_index = clampi(armed_weapon_index, 0, armed_weapons.size() - 1)
	queue_weapon_selection({"type": "unarmed"})


func request_cycle_weapon(direction: int) -> void:
	_rebuild_armed_weapon_list()
	if armed_weapons.is_empty():
		queue_weapon_selection({"type": "unarmed"})
		return
	var base_index := last_armed_weapon_index if using_unarmed else armed_weapon_index
	var next_index := wrapi(base_index + direction, 0, armed_weapons.size())
	queue_weapon_selection({
		"type": "armed",
		"index": next_index,
	})


func queue_weapon_selection(selection: Dictionary) -> void:
	pending_weapon_selection = selection.duplicate(true)
	try_apply_pending_weapon_selection()


func try_apply_pending_weapon_selection() -> void:
	if pending_weapon_selection.is_empty():
		return
	if not can_apply_weapon_selection_now():
		return
	_rebuild_armed_weapon_list()
	var selection_type := str(pending_weapon_selection.get("type", ""))
	match selection_type:
		"unarmed":
			_apply_unarmed_selection()
		"armed":
			_apply_armed_selection(int(pending_weapon_selection.get("index", armed_weapon_index)))
	pending_weapon_selection.clear()
	_refresh_primary_weapon_state()
	_enter_equip_weapon_state_if_available()


func can_apply_weapon_selection_now() -> bool:
	if _is_dead or _melee_active or _melee_heavy_anticipating or _melee_recovery_active or _is_block_state_active() or _reload_active:
		return false
	if _animation_state_machine == null:
		return true
	return _animation_state_machine.current_state in ["idle", "walk", "sprint"]


func _enter_equip_weapon_state_if_available() -> void:
	if _animation_state_machine == null:
		return
	_animation_state_machine.request("equip_weapon", 5)


func _is_equip_weapon_state_active() -> bool:
	return _animation_state_machine != null and _animation_state_machine.current_state == "equip_weapon"


func _apply_unarmed_selection() -> void:
	using_unarmed = true
	primary_weapon_equipped = true
	equipped_primary_weapon_id = String(unarmed_definition.weapon_id) if unarmed_definition != null else "fists"
	combat_loadout_mode = LOADOUT_MELEE
	_cancel_reload()
	_reset_melee_overlay_visuals()


func _apply_armed_selection(index: int) -> void:
	if armed_weapons.is_empty():
		_apply_unarmed_selection()
		return
	armed_weapon_index = clampi(index, 0, armed_weapons.size() - 1)
	last_armed_weapon_index = armed_weapon_index
	using_unarmed = false
	var profile := armed_weapons[armed_weapon_index]
	primary_weapon_equipped = profile != null
	equipped_primary_weapon_id = String(profile.weapon_id) if profile != null else PRIMARY_WEAPON_NONE
	combat_loadout_mode = _get_loadout_mode_for_profile(profile)
	_cancel_reload()
	_reset_melee_overlay_visuals()


func _rebuild_armed_weapon_list() -> void:
	armed_weapons.clear()
	_append_armed_weapon(primary_weapon_definition)
	_append_armed_weapon(melee_weapon_definition)
	if armed_weapons.is_empty():
		armed_weapon_index = 0
		last_armed_weapon_index = 0
		using_unarmed = true
		return
	armed_weapon_index = clampi(armed_weapon_index, 0, armed_weapons.size() - 1)
	last_armed_weapon_index = clampi(last_armed_weapon_index, 0, armed_weapons.size() - 1)


func _append_armed_weapon(profile_variant: Variant) -> void:
	if not (profile_variant is OperatorWeaponDefinition):
		return
	var profile := profile_variant as OperatorWeaponDefinition
	if profile == null or profile == unarmed_definition or profile.weapon_kind == "unarmed":
		return
	if armed_weapons.has(profile):
		return
	armed_weapons.append(profile)


func _configure_weapon_definition_defaults(
	profile_variant: Variant,
	default_display_name: String,
	default_kind: String,
	default_primary_intent: String,
	default_secondary_intent: String
) -> void:
	if not (profile_variant is OperatorWeaponDefinition):
		return
	var profile := profile_variant as OperatorWeaponDefinition
	if profile.display_name.is_empty():
		profile.display_name = default_display_name
	if profile.weapon_kind.is_empty() or (default_kind == "ranged" and profile.weapon_kind == "melee"):
		profile.weapon_kind = default_kind
	if profile.primary_intent.is_empty() or (default_kind == "ranged" and profile.primary_intent.begins_with("melee")):
		profile.primary_intent = default_primary_intent
	if profile.secondary_intent.is_empty() or (default_kind == "ranged" and profile.secondary_intent.begins_with("melee")):
		profile.secondary_intent = default_secondary_intent


func _sync_weapon_selection_from_current_loadout() -> void:
	if armed_weapons.is_empty():
		_apply_unarmed_selection()
		return
	var current_profile = _get_equipped_primary_weapon_definition()
	var index := armed_weapons.find(current_profile)
	if index < 0:
		index = 0
	armed_weapon_index = index
	last_armed_weapon_index = index
	using_unarmed = false
	_apply_armed_selection(index)


func _get_loadout_mode_for_profile(profile: OperatorWeaponDefinition) -> StringName:
	if profile == null:
		return LOADOUT_HOLSTERED
	if profile.weapon_kind == "ranged" or String(profile.weapon_type).begins_with("ranged"):
		return LOADOUT_RANGED
	return LOADOUT_MELEE


func get_weapon_selection_state() -> Dictionary:
	return {
		"using_unarmed": using_unarmed,
		"armed_weapon_index": armed_weapon_index,
		"last_armed_weapon_index": last_armed_weapon_index,
	}


func apply_weapon_selection_state(selection_state: Dictionary) -> void:
	_rebuild_armed_weapon_list()
	using_unarmed = bool(selection_state.get("using_unarmed", using_unarmed))
	armed_weapon_index = clampi(int(selection_state.get("armed_weapon_index", armed_weapon_index)), 0, max(armed_weapons.size() - 1, 0))
	last_armed_weapon_index = clampi(int(selection_state.get("last_armed_weapon_index", last_armed_weapon_index)), 0, max(armed_weapons.size() - 1, 0))
	pending_weapon_selection.clear()
	if using_unarmed or armed_weapons.is_empty():
		_apply_unarmed_selection()
	else:
		_apply_armed_selection(armed_weapon_index)
	_refresh_primary_weapon_state()


func _equip_melee_loadout() -> void:
	_rebuild_armed_weapon_list()
	var index := armed_weapons.find(melee_weapon_definition)
	if index < 0:
		return
	queue_weapon_selection({"type": "armed", "index": index})


func _holster_all_weapons() -> void:
	queue_weapon_selection({"type": "unarmed"})


func _is_melee_loadout_active() -> bool:
	var profile := get_current_combat_profile()
	return combat_loadout_mode == LOADOUT_MELEE and profile != null and profile.weapon_kind in ["melee", "unarmed"]


func _is_ranged_loadout_active() -> bool:
	return combat_loadout_mode == LOADOUT_RANGED and primary_weapon_equipped


func _is_using_melee_weapon_sprite() -> bool:
	if combat_loadout_mode != LOADOUT_MELEE:
		return false
	var weapon_definition = _get_equipped_primary_weapon_definition()
	if weapon_definition == null:
		return false
	return String(weapon_definition.weapon_type).begins_with("melee")


func _ensure_target_ring() -> void:
	if _target_ring != null or TARGET_RING_SCENE == null:
		return
	var ring = TARGET_RING_SCENE.instantiate()
	if ring == null:
		return
	_target_ring = ring as Node2D
	if _target_ring == null:
		return
	_target_ring.visible = false
	var parent = get_node_or_null("/root/GameRoot/World/Projectiles")
	if parent:
		parent.add_child(_target_ring)
	else:
		get_tree().current_scene.add_child(_target_ring)


func _update_combat_target() -> void:
	var old_target: Node2D = _combat_target
	_combat_target = _find_nearest_enemy_target(combat_target_range)
	if old_target != _combat_target and old_target and is_instance_valid(old_target) and old_target.has_method("set_threat_highlight"):
		old_target.call("set_threat_highlight", false)
	if _combat_target and _combat_target.has_method("set_threat_highlight"):
		_combat_target.call("set_threat_highlight", true)


func _update_target_ring() -> void:
	if _target_ring == null:
		return
	if _combat_target == null or not is_instance_valid(_combat_target):
		_target_ring.visible = false
		return
	_target_ring.visible = true
	_target_ring.global_position = _combat_target.global_position
	if _target_ring.has_method("set_in_strike_zone"):
		_target_ring.call("set_in_strike_zone", _is_enemy_in_preview_strike_zone(_combat_target))


func _find_nearest_enemy_target(max_distance: float) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = max_distance
	var nearest_strike_target: Node2D = null
	var nearest_strike_dist: float = INF
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not (enemy is Node2D):
			continue
		var enemy_node := enemy as Node2D
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if enemy_node.has_method("is_passive_enemy") and bool(enemy_node.call("is_passive_enemy")):
			continue
		if enemy_node.has_method("is_dead") and bool(enemy_node.call("is_dead")):
			continue
		var dist: float = global_position.distance_to(enemy_node.global_position)
		if _is_enemy_in_preview_strike_zone(enemy_node) and dist < nearest_strike_dist:
			nearest_strike_dist = dist
			nearest_strike_target = enemy_node
		if dist <= nearest_dist:
			nearest_dist = dist
			nearest = enemy_node
	return nearest_strike_target if nearest_strike_target != null else nearest


func _is_enemy_in_preview_strike_zone(enemy: Node2D) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if not _is_melee_loadout_active():
		return false
	var to_enemy := enemy.global_position - global_position
	var dist := to_enemy.length()
	if dist <= 0.001:
		return false
	var preview := _get_preview_melee_range_arc()
	if dist > float(preview.get("range", melee_range)):
		return false
	var forward := _get_attack_aim_direction()
	if forward.length_squared() <= 0.001:
		forward = aim_direction if aim_direction.length_squared() > 0.001 else Vector2.RIGHT
	var angle: float = abs(rad_to_deg(forward.normalized().angle_to(to_enemy.normalized())))
	return angle <= float(preview.get("arc", melee_arc_degrees)) * 0.5


func _get_preview_melee_range_arc() -> Dictionary:
	if _melee_active:
		return {"range": _melee_range_current, "arc": _melee_arc_current}
	var profile := get_current_combat_profile()
	var intent := String(profile.primary_intent) if profile != null else "melee_light"
	var base_range := melee_light_range
	var base_arc := melee_light_arc_degrees
	match _attack_kind_from_intent(intent):
		"fast":
			base_range = melee_range
			base_arc = melee_arc_degrees
		"heavy":
			base_range = melee_heavy_range
			base_arc = melee_heavy_arc_degrees
	var range_multiplier := profile.range_multiplier if profile != null else 1.0
	return {"range": base_range * range_multiplier, "arc": base_arc}


func _spawn_muzzle_flash(direction: Vector2):
	var flash = MUZZLE_FLASH_SCENE.instantiate()
	if flash == null:
		return
	var spawn_position: Vector2 = global_position + direction * (muzzle_offset - 4.0)
	if barrel:
		spawn_position = barrel.global_position
	flash.rotation = direction.angle()
	var parent = get_node_or_null("/root/GameRoot/World/Projectiles")
	if parent:
		parent.add_child(flash)
	else:
		get_tree().current_scene.add_child(flash)
	flash.global_position = spawn_position


func _spawn_damage_popup(amount: float) -> void:
	var popup := DAMAGE_POPUP_SCENE.instantiate()
	popup.text = str(int(amount))
	popup.modulate = Color(1, 0.3, 0.3, 1)
	get_tree().current_scene.add_child(popup)
	popup.global_position = global_position + Vector2(randf_range(-10, 10), -30)


func _has_ammo() -> bool:
	return _has_loaded_ammo()


func _is_using_ranged_2h_primary() -> bool:
	if combat_loadout_mode != LOADOUT_RANGED:
		return false
	var weapon_definition = _get_equipped_primary_weapon_definition()
	if weapon_definition != null:
		return String(weapon_definition.weapon_type) == "ranged_2h"
	return primary_weapon_equipped and equipped_primary_weapon_id == PRIMARY_WEAPON_CARBINE


func _is_blocking() -> bool:
	return _block_active


func _is_block_state_active() -> bool:
	return not _block_phase.is_empty()


func _is_movement_locked() -> bool:
	return _reload_active or _is_block_state_active() or _melee_active or _melee_heavy_anticipating


func _is_ranged_fire_animation_active() -> bool:
	return _is_ranged_loadout_active() and (not _pending_ranged_shot.is_empty() or fire_cooldown_remaining > 0.0)


func _is_ranged_firing_move_state() -> bool:
	return _is_ranged_fire_animation_active() and velocity.length() > 0.01 and not is_sprinting


func _get_ranged_firing_move_multiplier() -> float:
	var multiplier := ranged_firing_move_multiplier
	var weapon_definition = _get_equipped_primary_weapon_definition()
	if weapon_definition is OperatorWeaponDefinition:
		var handling_multiplier := 1.0 + (weapon_definition as OperatorWeaponDefinition).get_handling_float("movement_speed_penalty", (weapon_definition as OperatorWeaponDefinition).movement_speed_penalty)
		multiplier *= max(0.2, handling_multiplier)
	return clampf(multiplier, 0.15, 1.0)


func _get_current_ranged_body_fire_animation(is_moving: bool) -> StringName:
	var weapon_definition = _get_equipped_primary_weapon_definition()
	if is_moving:
		var mapped_move_anim := _get_weapon_animation_name(weapon_definition, "ranged_fire_walk", RANGED_FIRE_WALK_ANIMATION)
		if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(mapped_move_anim):
			return mapped_move_anim
	return _get_weapon_animation_name(weapon_definition, "ranged_fire", &"ranged_2h_fire")


func _get_body_animation_speed_scale(animation_name: StringName) -> float:
	if animation_name == RANGED_FIRE_WALK_ANIMATION:
		return _get_ranged_firing_move_multiplier()
	return 1.0


func _get_ranged_fire_release_delay(animation_name: StringName) -> float:
	var weapon_definition = _get_equipped_primary_weapon_definition()
	var fire_frame := 0
	if weapon_definition is OperatorWeaponDefinition:
		fire_frame = max(0, (weapon_definition as OperatorWeaponDefinition).get_animation_int("fire_frame", (weapon_definition as OperatorWeaponDefinition).animation_fire_frame))
	if fire_frame <= 0 or animated_sprite == null or animated_sprite.sprite_frames == null:
		return 0.0
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var fps: float = animated_sprite.sprite_frames.get_animation_speed(animation_name) * _get_body_animation_speed_scale(animation_name)
	if fps <= 0.001:
		return 0.0
	return float(fire_frame) / fps


func _play_ranged_fire_animation(animation_name: StringName) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return
	animated_sprite.flip_h = _is_facing_left(aim_direction)
	animated_sprite.speed_scale = _get_body_animation_speed_scale(animation_name)
	animated_sprite.play(animation_name)
	_update_primary_weapon_visual(true)


func _update_pending_ranged_shot(delta: float) -> void:
	if _pending_ranged_shot.is_empty():
		return
	var timer: float = float(_pending_ranged_shot.get("timer", 0.0))
	timer = max(0.0, timer - delta)
	_pending_ranged_shot["timer"] = timer
	if timer <= 0.0:
		_emit_pending_ranged_shot()


func _ensure_runtime_body_animations() -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if animated_sprite.sprite_frames.has_animation(RANGED_FIRE_WALK_ANIMATION):
		return
	var runtime_frames := animated_sprite.sprite_frames.duplicate() as SpriteFrames
	if runtime_frames == null:
		return
	animated_sprite.sprite_frames = runtime_frames
	var fire_walk_texture: Texture2D = _load_optional_texture(ranged_2h_fire_walk_sheet_path, null)
	if fire_walk_texture == null:
		return
	var frame_count: int = max(1, fire_walk_texture.get_width() / RANGED_FIRE_WALK_FRAME_WIDTH)
	_add_sheet_animation(runtime_frames, String(RANGED_FIRE_WALK_ANIMATION), fire_walk_texture, frame_count, true, RANGED_FIRE_WALK_BASE_FPS)


func _update_body_recoil(delta: float) -> void:
	if _body_recoil_offset == Vector2.ZERO:
		return
	_body_recoil_offset = _body_recoil_offset.move_toward(Vector2.ZERO, BODY_RECOIL_RECOVERY_RATE * delta)
	_apply_body_recoil_offset()


func _apply_body_recoil_impulse(direction: Vector2) -> void:
	var recoil_pixels := float(BODY_RECOIL_PROFILE_PIXELS.get("recoil_standard", 1.0))
	var weapon_definition = _get_equipped_primary_weapon_definition()
	if weapon_definition is OperatorWeaponDefinition:
		var recoil_key := (weapon_definition as OperatorWeaponDefinition).get_animation_string("recoil_animation", String((weapon_definition as OperatorWeaponDefinition).recoil_animation))
		if not recoil_key.is_empty():
			recoil_pixels = float(BODY_RECOIL_PROFILE_PIXELS.get(recoil_key, recoil_pixels))
	var normalized_direction := direction.normalized()
	if normalized_direction == Vector2.ZERO:
		normalized_direction = Vector2.RIGHT
	_body_recoil_offset += -normalized_direction * recoil_pixels
	if _body_recoil_offset.length() > 3.0:
		_body_recoil_offset = _body_recoil_offset.normalized() * 3.0
	_apply_body_recoil_offset()


func _apply_body_recoil_offset() -> void:
	if animated_sprite:
		animated_sprite.position = _animated_sprite_base_position + _body_recoil_offset
	if melee_weapon_overlay_sprite:
		melee_weapon_overlay_sprite.position = _melee_weapon_overlay_base_position + _body_recoil_offset
	if melee_fx_overlay_sprite:
		melee_fx_overlay_sprite.position = _melee_fx_overlay_base_position + _body_recoil_offset


func _wants_block() -> bool:
	return _is_melee_loadout_active() and Input.is_action_pressed("block") and not _is_terminal_open()





func _add_sheet_animation(frames: SpriteFrames, animation_name: String, texture: Texture2D, frame_count: int, loop: bool, fps: float) -> void:
	if texture == null or frame_count <= 0:
		return
	if not frames.has_animation(animation_name):
		frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop)
	frames.set_animation_speed(animation_name, fps)

	var frame_width: int = texture.get_width() / frame_count
	var frame_height: int = texture.get_height()
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame(animation_name, atlas)


func _load_optional_texture(path: String, fallback: Texture2D) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		var imported := load(path)
		if imported is Texture2D:
			return imported as Texture2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image != null and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return fallback


func _should_play_idle_long() -> bool:
	return not _has_active_idle_input() and _idle_loop_counter >= idle_long_loop_threshold


func _has_active_idle_input() -> bool:
	return Input.is_action_pressed("move_left") \
		or Input.is_action_pressed("move_right") \
		or Input.is_action_pressed("move_up") \
		or Input.is_action_pressed("move_down") \
		or Input.is_action_pressed("aim_left") \
		or Input.is_action_pressed("aim_right") \
		or Input.is_action_pressed("aim_up") \
		or Input.is_action_pressed("aim_down") \
		or Input.is_action_pressed("attack") \
		or Input.is_action_pressed("attack_primary") \
		or Input.is_action_pressed("attack_secondary") \
		or Input.is_action_pressed("toggle_unarmed") \
		or Input.is_action_pressed("reload_weapon") \
		or Input.is_action_pressed("block") \
		or Input.is_action_pressed("interact") \
		or Input.is_action_pressed("repair") \
		or Input.is_key_pressed(KEY_CTRL) \
		or _melee_active \
		or _reload_active \
		or _melee_recovery_active


func _update_idle_loop_tracking(is_idle_anim: bool, animation_name: String) -> void:
	if not is_idle_anim or _has_active_idle_input():
		_idle_loop_counter = 0
		_last_idle_frame = -1
		_last_idle_animation = ""
		return
	if _last_idle_animation != animation_name:
		_last_idle_frame = -1
		_last_idle_animation = animation_name
	if animation_name != "idle_long" and _last_idle_frame >= 0 and animated_sprite.frame < _last_idle_frame:
		_idle_loop_counter += 1
	_last_idle_frame = animated_sprite.frame


func _apply_placeholder_runtime_layout() -> void:
	var weapon_definition = _get_equipped_primary_weapon_definition()
	if animated_sprite:
		animated_sprite.position = placeholder_sprite_position
		animated_sprite.offset = placeholder_sprite_offset
	if melee_weapon_overlay_sprite:
		melee_weapon_overlay_sprite.position = placeholder_sprite_position
		melee_weapon_overlay_sprite.offset = placeholder_sprite_offset
	if melee_fx_overlay_sprite:
		melee_fx_overlay_sprite.position = placeholder_sprite_position
		melee_fx_overlay_sprite.offset = placeholder_sprite_offset
	_apply_dynamic_weapon_socket_layout(weapon_definition)
	if primary_weapon_socket:
		primary_weapon_socket.rotation = 0.0
	if primary_weapon_sprite:
		primary_weapon_sprite.scale = weapon_definition.weapon_sprite_scale if weapon_definition else primary_weapon_sprite_scale
	if body_collision:
		body_collision.position = placeholder_collision_offset
		if body_collision.shape is CapsuleShape2D:
			var capsule := body_collision.shape as CapsuleShape2D
			capsule.radius = placeholder_collision_radius
			capsule.height = placeholder_collision_height
	if weapon_hitbox_shape and weapon_hitbox_shape.shape is CircleShape2D:
		var hit_circle := weapon_hitbox_shape.shape as CircleShape2D
		hit_circle.radius = placeholder_melee_hitbox_radius
	if health_bar:
		health_bar.offset_left = -18.0
		health_bar.offset_right = 18.0
		health_bar.offset_top = placeholder_healthbar_top
		health_bar.offset_bottom = placeholder_healthbar_bottom
	_capture_runtime_visual_base_positions()


func _capture_runtime_visual_base_positions() -> void:
	if animated_sprite:
		_animated_sprite_base_position = animated_sprite.position
	if melee_weapon_overlay_sprite:
		_melee_weapon_overlay_base_position = melee_weapon_overlay_sprite.position
	if melee_fx_overlay_sprite:
		_melee_fx_overlay_base_position = melee_fx_overlay_sprite.position


func _apply_dynamic_weapon_socket_layout(weapon_definition = null) -> void:
	if weapon_definition == null:
		weapon_definition = _get_equipped_primary_weapon_definition()
	var aim_state := _get_weapon_aim_state()
	var facing_left := _is_facing_left(aim_direction) and _is_using_ranged_2h_primary()
	
	# Get positions from weapon definition
	var right_pos = _mirror_socket_vector_if_needed(
		_get_weapon_definition_vector(weapon_definition, aim_state, "right_hand_socket_position", right_hand_socket_position),
		facing_left
	)
	var left_pos = _mirror_socket_vector_if_needed(
		_get_weapon_definition_vector(weapon_definition, aim_state, "left_hand_socket_position", left_hand_socket_position),
		facing_left
	)
	var muzzle_pos = _mirror_socket_vector_if_needed(
		_get_weapon_definition_vector(weapon_definition, aim_state, "muzzle_socket_position", primary_weapon_muzzle_socket_position),
		facing_left
	)
	var weapon_socket_pos = _mirror_socket_vector_if_needed(
		_get_weapon_definition_vector(weapon_definition, aim_state, "weapon_socket_position", primary_weapon_socket_position),
		facing_left
	) + _body_recoil_offset
	var weapon_sprite_pos = _mirror_socket_vector_if_needed(
		_get_weapon_definition_vector(weapon_definition, aim_state, "weapon_sprite_position", primary_weapon_sprite_position),
		facing_left
	)
	
	if right_hand_socket:
		right_hand_socket.position = right_pos
	if left_hand_socket:
		left_hand_socket.position = left_pos
	if primary_weapon_socket:
		primary_weapon_socket.position = weapon_socket_pos
	if primary_weapon_sprite:
		primary_weapon_sprite.position = weapon_sprite_pos
	if barrel:
		barrel.position = muzzle_pos
	
	# Debug - always update these from weapon def so they show even if nodes don't exist
	debug_right_hand_pos = right_pos
	debug_left_hand_pos = left_pos
	debug_weapon_socket_pos = primary_weapon_socket.position if primary_weapon_socket else primary_weapon_socket_position
	debug_muzzle_pos = muzzle_pos
	queue_redraw()


func _mirror_socket_vector_if_needed(value: Vector2, mirror_x: bool) -> Vector2:
	if not mirror_x:
		return value
	return Vector2(-value.x, value.y)


func _get_weapon_definition_vector(weapon_definition, aim_state: StringName, base_property: String, fallback: Vector2) -> Vector2:
	if weapon_definition == null:
		return fallback
	match base_property:
		"right_hand_socket_position":
			if aim_state == &"up":
				return weapon_definition.right_hand_socket_position_up
			if aim_state == &"down":
				return weapon_definition.right_hand_socket_position_down
			return weapon_definition.right_hand_socket_position
		"left_hand_socket_position":
			if aim_state == &"up":
				return weapon_definition.left_hand_socket_position_up
			if aim_state == &"down":
				return weapon_definition.left_hand_socket_position_down
			return weapon_definition.left_hand_socket_position
		"weapon_socket_position":
			if aim_state == &"up":
				return weapon_definition.weapon_socket_position_up
			if aim_state == &"down":
				return weapon_definition.weapon_socket_position_down
			return weapon_definition.weapon_socket_position
		"muzzle_socket_position":
			if aim_state == &"up":
				return weapon_definition.muzzle_socket_position_up
			if aim_state == &"down":
				return weapon_definition.muzzle_socket_position_down
			return weapon_definition.muzzle_socket_position
		"weapon_sprite_position":
			return weapon_definition.weapon_sprite_position
	return fallback


func _get_weapon_aim_state() -> StringName:
	if _is_using_melee_weapon_sprite():
		return _get_body_animation_aim_state()
	if aim_direction.y <= -0.35:
		return &"up"
	if aim_direction.y >= 0.35:
		return &"down"
	return &"neutral"


func _get_body_animation_aim_state() -> StringName:
	if animated_sprite == null:
		return &"neutral"
	var anim_name := String(animated_sprite.animation)
	if anim_name.contains("_up"):
		return &"up"
	if anim_name.contains("_down"):
		return &"down"
	return &"neutral"


func _update_primary_weapon_visual(is_firing: bool) -> void:
	var is_melee_mode = _is_using_melee_weapon_sprite()
	var show_attack_weapon_overlay := is_melee_mode and (_melee_active or _melee_heavy_anticipating or _melee_recovery_active)
	var show_block_weapon_overlay := is_melee_mode and _is_block_state_active()
	if melee_weapon_overlay_sprite:
		melee_weapon_overlay_sprite.visible = show_attack_weapon_overlay or show_block_weapon_overlay
		if not melee_weapon_overlay_sprite.visible:
			melee_weapon_overlay_sprite.stop()
			melee_weapon_overlay_sprite.frame = 0
	if melee_fx_overlay_sprite:
		melee_fx_overlay_sprite.visible = (_melee_active and (_melee_attack_kind == "fast" or _melee_attack_kind == "light")) or _melee_recovery_active
		if not melee_fx_overlay_sprite.visible:
			melee_fx_overlay_sprite.stop()
			melee_fx_overlay_sprite.frame = 0
	if ranged_fx_overlay_sprite:
		ranged_fx_overlay_sprite.visible = false
		ranged_fx_overlay_sprite.flip_h = animated_sprite.flip_h if animated_sprite else false
		if ranged_fx_overlay_sprite.sprite_frames and ranged_fx_overlay_sprite.sprite_frames.has_animation("hidden"):
			ranged_fx_overlay_sprite.play("hidden")
	
	if primary_weapon_sprite == null:
		return
	if _is_using_melee_weapon_sprite():
		if primary_weapon_socket:
			primary_weapon_socket.rotation = 0.0
		var using_attack_overlay := _melee_active or _melee_heavy_anticipating
		primary_weapon_sprite.visible = not using_attack_overlay and not _is_block_state_active()
		primary_weapon_sprite.flip_h = animated_sprite.flip_h if animated_sprite else false
		var melee_stance_anim := _get_weapon_animation_name(_get_equipped_primary_weapon_definition(), "melee_stance", &"melee_stance")
		if primary_weapon_sprite.visible and primary_weapon_sprite.sprite_frames and primary_weapon_sprite.sprite_frames.has_animation(melee_stance_anim):
			if primary_weapon_sprite.animation != melee_stance_anim or not primary_weapon_sprite.is_playing():
				primary_weapon_sprite.play(melee_stance_anim)
		return
	if not _is_using_ranged_2h_primary():
		if primary_weapon_socket:
			primary_weapon_socket.rotation = 0.0
		primary_weapon_sprite.visible = false
		if primary_weapon_sprite.sprite_frames and primary_weapon_sprite.sprite_frames.has_animation("hidden"):
			primary_weapon_sprite.play("hidden")
		if ranged_fx_overlay_sprite and ranged_fx_overlay_sprite.sprite_frames and ranged_fx_overlay_sprite.sprite_frames.has_animation("hidden"):
			ranged_fx_overlay_sprite.play("hidden")
		return
	primary_weapon_sprite.visible = true
	primary_weapon_sprite.flip_h = animated_sprite.flip_h if animated_sprite else false
	if _reload_active:
		if primary_weapon_socket:
			primary_weapon_socket.rotation = 0.0
		if primary_weapon_sprite.sprite_frames and primary_weapon_sprite.sprite_frames.has_animation("ranged_2h_reload"):
			if primary_weapon_sprite.animation != &"ranged_2h_reload" or not primary_weapon_sprite.is_playing():
				primary_weapon_sprite.play("ranged_2h_reload")
		if ranged_fx_overlay_sprite and ranged_fx_overlay_sprite.sprite_frames and ranged_fx_overlay_sprite.sprite_frames.has_animation("ranged_2h_reload_fx"):
			ranged_fx_overlay_sprite.visible = true
			if ranged_fx_overlay_sprite.animation != &"ranged_2h_reload_fx" or not ranged_fx_overlay_sprite.is_playing():
				ranged_fx_overlay_sprite.play("ranged_2h_reload_fx")
		return
	var facing_up := _is_facing_up(aim_direction)
	if facing_up:
		primary_weapon_sprite.visible = false
		if ranged_fx_overlay_sprite and ranged_fx_overlay_sprite.sprite_frames and ranged_fx_overlay_sprite.sprite_frames.has_animation("hidden"):
			ranged_fx_overlay_sprite.play("hidden")
		return
	var target_animation := _get_weapon_animation_name(
		_get_equipped_primary_weapon_definition(),
		"ranged_fire" if is_firing else "ranged_stance",
		&"ranged_2h_fire" if is_firing else &"ranged_2h_stance"
	)
	if not is_firing and is_sprinting and velocity.length() > 0.0 and primary_weapon_sprite.sprite_frames and primary_weapon_sprite.sprite_frames.has_animation("equipped_run_right"):
		target_animation = &"equipped_run_right"
	if primary_weapon_sprite.sprite_frames and primary_weapon_sprite.sprite_frames.has_animation(target_animation):
		if primary_weapon_sprite.animation != target_animation or (is_firing and not primary_weapon_sprite.is_playing()):
			primary_weapon_sprite.play(target_animation)
	if ranged_fx_overlay_sprite:
		ranged_fx_overlay_sprite.flip_h = primary_weapon_sprite.flip_h
		if is_firing and ranged_fx_overlay_sprite.sprite_frames and ranged_fx_overlay_sprite.sprite_frames.has_animation("ranged_2h_fire_fx"):
			ranged_fx_overlay_sprite.visible = true
			if ranged_fx_overlay_sprite.animation != &"ranged_2h_fire_fx" or not ranged_fx_overlay_sprite.is_playing():
				ranged_fx_overlay_sprite.play("ranged_2h_fire_fx")
		else:
			ranged_fx_overlay_sprite.visible = false
			if ranged_fx_overlay_sprite.sprite_frames and ranged_fx_overlay_sprite.sprite_frames.has_animation("hidden"):
				ranged_fx_overlay_sprite.play("hidden")


func _get_equipped_primary_weapon_definition():
	if using_unarmed:
		return unarmed_definition
	if not primary_weapon_equipped:
		return null
	if combat_loadout_mode == LOADOUT_RANGED and primary_weapon_definition != null:
		return primary_weapon_definition
	if combat_loadout_mode == LOADOUT_MELEE and melee_weapon_definition != null:
		return melee_weapon_definition
	if primary_weapon_definition != null and String(primary_weapon_definition.weapon_id) == equipped_primary_weapon_id:
		return primary_weapon_definition
	if melee_weapon_definition != null and String(melee_weapon_definition.weapon_id) == equipped_primary_weapon_id:
		return melee_weapon_definition
	return null


func _apply_active_weapon_frames() -> void:
	if primary_weapon_sprite == null:
		return
	var weapon_definition = _get_equipped_primary_weapon_definition()
	if weapon_definition != null and weapon_definition.frames_resource:
		primary_weapon_sprite.sprite_frames = weapon_definition.frames_resource
	elif primary_weapon_frames_resource:
		primary_weapon_sprite.sprite_frames = primary_weapon_frames_resource


func _refresh_primary_weapon_state() -> void:
	_apply_active_weapon_frames()
	if use_tiny_rpg_placeholder_soldier:
		_apply_placeholder_runtime_layout()
	if primary_weapon_sprite == null:
		return

	if _is_using_melee_weapon_sprite():
		var melee_stance_anim := _get_weapon_animation_name(_get_equipped_primary_weapon_definition(), "melee_stance", &"melee_stance")
		if primary_weapon_sprite.sprite_frames and primary_weapon_sprite.sprite_frames.has_animation(melee_stance_anim):
			primary_weapon_sprite.play(melee_stance_anim)
	elif _is_using_ranged_2h_primary():
		var ranged_stance_anim := _get_weapon_animation_name(_get_equipped_primary_weapon_definition(), "ranged_stance", &"ranged_2h_stance")
		if primary_weapon_sprite.sprite_frames and primary_weapon_sprite.sprite_frames.has_animation(ranged_stance_anim):
			primary_weapon_sprite.play(ranged_stance_anim)
	elif primary_weapon_sprite.sprite_frames and primary_weapon_sprite.sprite_frames.has_animation("hidden"):
		primary_weapon_sprite.play("hidden")

	_update_primary_weapon_visual(false)


func _setup_animation_state_machine() -> void:
	_animation_state_machine = AnimationStateMachine.new()
	_animation_state_machine.sprite = animated_sprite
	_animation_state_machine.actor = self
	_animation_state_machine.register_state(IdleState.new())
	_animation_state_machine.register_state(WalkState.new())
	_animation_state_machine.register_state(SprintState.new())
	_animation_state_machine.register_state(BlockState.new())
	_animation_state_machine.register_state(EquipWeaponState.new())
	var hit_recoil_state := HitRecoilState.new()
	hit_recoil_state.recoil_duration = operator_light_reaction_stun_duration
	_animation_state_machine.register_state(hit_recoil_state)
	_animation_state_machine.register_state(AttackLightState.new())
	_animation_state_machine.register_state(AttackFastState.new())
	_animation_state_machine.register_state(AttackHeavyState.new())
	_animation_state_machine.register_state(DeathState.new())
	_animation_state_machine.current_state = "idle"


func _update_animation_state_machine(delta: float) -> void:
	if _animation_state_machine == null:
		return
	_animation_state_machine._process(delta)
	if _melee_active:
		return
	if _is_block_state_active():
		_animation_state_machine.request("block", 8)
		return
	var desired_state := _get_desired_animation_state()
	var state_priority := 1 if desired_state == "walk" or desired_state == "sprint" else 0
	_animation_state_machine.request(desired_state, state_priority)


func _get_desired_animation_state() -> String:
	if velocity.length() <= 0.01:
		return "idle"
	if is_sprinting:
		return "sprint"
	return "walk"


func _get_weapon_animation_name(weapon_definition, key: String, fallback: StringName = &"") -> StringName:
	if weapon_definition != null and weapon_definition.animation_map is Dictionary:
		var mapped_value = weapon_definition.animation_map.get(key, null)
		if mapped_value != null:
			var mapped_name := String(mapped_value)
			if not mapped_name.is_empty():
				return StringName(mapped_name)
	return fallback


func _on_operator_animation_finished() -> void:
	if animated_sprite == null:
		return
	if _melee_heavy_anticipating and animated_sprite.animation == &"melee_2h_heavy_anticipation":
		_begin_heavy_attack_active_phase()


func _get_authored_melee_body_stance_animation() -> StringName:
	var weapon_definition = _get_equipped_primary_weapon_definition()
	if weapon_definition != null and weapon_definition.authored_body_stance_animation != StringName():
		return weapon_definition.authored_body_stance_animation
	return &""


func _is_authored_melee_body_stance_active() -> bool:
	if not _is_melee_loadout_active() or animated_sprite == null or _melee_active:
		return false
	var body_stance_anim := _get_authored_melee_body_stance_animation()
	return not body_stance_anim.is_empty() and animated_sprite.animation == body_stance_anim


func _consume_ammo():
	_ammo_standard_loaded = max(0, _ammo_standard_loaded - 1)


func _initialize_magazines() -> void:
	var standard_load: int = min(_get_standard_magazine_size(), ammo_standard)
	_ammo_standard_loaded = max(0, standard_load)
	ammo_standard = max(0, ammo_standard - standard_load)
	var heavy_load: int = min(_get_heavy_magazine_size(), ammo_heavy)
	_ammo_heavy_loaded = max(0, heavy_load)
	ammo_heavy = max(0, ammo_heavy - heavy_load)


func _get_standard_magazine_size() -> int:
	if primary_weapon_definition != null and primary_weapon_definition is OperatorWeaponDefinition:
		return max(1, (primary_weapon_definition as OperatorWeaponDefinition).get_stat_int("magazine_size", ammo_standard_magazine_size))
	return ammo_standard_magazine_size


func _get_heavy_magazine_size() -> int:
	return ammo_heavy_magazine_size


func _get_current_magazine_size() -> int:
	return _get_standard_magazine_size()


func _get_current_loaded_ammo() -> int:
	return _ammo_standard_loaded


func _get_current_reserve_ammo() -> int:
	return ammo_standard


func _has_loaded_ammo() -> bool:
	if not _is_ranged_loadout_active():
		return false
	return _get_current_loaded_ammo() > 0


func _get_current_reload_duration() -> float:
	if primary_weapon_definition != null and primary_weapon_definition is OperatorWeaponDefinition:
		return max(0.05, (primary_weapon_definition as OperatorWeaponDefinition).get_stat_float("reload_time_sec", ranged_reload_duration))
	return ranged_reload_duration


func _can_reload() -> bool:
	if not _is_ranged_loadout_active() or _reload_active:
		return false
	if _melee_active or _melee_heavy_anticipating or _melee_recovery_active or _is_block_state_active():
		return false
	return _get_current_loaded_ammo() < _get_current_magazine_size() and _get_current_reserve_ammo() > 0


func _try_start_reload() -> void:
	if not _can_reload():
		return
	_reload_active = true
	_reload_timer = _get_current_reload_duration()
	last_fire_cooldown = max(last_fire_cooldown, _reload_timer)
	fire_cooldown_remaining = max(fire_cooldown_remaining, _reload_timer)
	_update_primary_weapon_visual(false)


func _update_reload(delta: float) -> void:
	if not _reload_active:
		return
	_reload_timer = max(0.0, _reload_timer - delta)
	if _reload_timer > 0.0:
		return
	_finish_reload()


func _finish_reload() -> void:
	if not _reload_active:
		return
	var capacity: int = _get_current_magazine_size()
	var needed_standard: int = max(0, capacity - _ammo_standard_loaded)
	var transfer_standard: int = min(needed_standard, ammo_standard)
	_ammo_standard_loaded += transfer_standard
	ammo_standard -= transfer_standard
	_cancel_reload()


func _cancel_reload() -> void:
	_reload_active = false
	_reload_timer = 0.0


func add_ammo(standard: int, heavy: int) -> Dictionary:
	var old_std = ammo_standard
	var old_hvy = ammo_heavy
	ammo_standard = min(ammo_standard_max, ammo_standard + max(0, standard))
	ammo_heavy = min(ammo_heavy_max, ammo_heavy + max(0, heavy))
	var gained_std = ammo_standard - old_std
	var gained_hvy = ammo_heavy - old_hvy
	print("AMMO CACHE COLLECTED: +", gained_std, " STD / +", gained_hvy, " HVY")
	return {
		"standard": gained_std,
		"heavy": gained_hvy,
	}


func get_weapon_status() -> Dictionary:
	var profile := _get_current_ranged_profile()
	var cooldown_total = max(last_fire_cooldown, float(profile["cooldown"]))
	var weapon_name := "CARBINE"
	var combat_profile := get_current_combat_profile()
	if combat_profile != null and not combat_profile.display_name.is_empty():
		weapon_name = combat_profile.display_name.to_upper()
	elif primary_weapon_definition != null and primary_weapon_definition is OperatorWeaponDefinition:
		var weapon_data: Dictionary = (primary_weapon_definition as OperatorWeaponDefinition).get_weapon_data()
		weapon_name = str(weapon_data.get("name", weapon_name)).to_upper()
	return {
		"equipped": primary_weapon_equipped,
		"primary_weapon_id": equipped_primary_weapon_id,
		"weapon_name": weapon_name,
		"using_unarmed": using_unarmed,
		"armed_weapon_index": armed_weapon_index,
		"last_armed_weapon_index": last_armed_weapon_index,
		"aim_mode": "arrows" if arrow_aim_enabled else "mouse",
		"aim_direction": aim_direction,
		"player_position": global_position,
		"loadout_mode": String(combat_loadout_mode),
		"blocking": _is_blocking(),
		"profile": String(profile["name"]),
		"cooldown_remaining": fire_cooldown_remaining,
		"cooldown_total": cooldown_total,
		"reloading": _reload_active,
		"ammo_standard": ammo_standard,
		"ammo_heavy": ammo_heavy,
		"ammo_standard_loaded": _ammo_standard_loaded,
		"ammo_heavy_loaded": _ammo_heavy_loaded,
		"ammo_standard_magazine_size": _get_standard_magazine_size(),
		"ammo_heavy_magazine_size": _get_heavy_magazine_size(),
	}


func get_sprint_status() -> Dictionary:
	return {
		"is_sprinting": is_sprinting,
		"stamina": stamina,
		"stamina_max": stamina_max,
		"sprint_exhausted": _sprint_exhausted,
	}


func _get_keyboard_aim_direction() -> Vector2:
	var aim_input := Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)
	if aim_input.length_squared() <= 0.0001:
		return Vector2.ZERO
	return aim_input.normalized()


func _get_attack_aim_direction() -> Vector2:
	if arrow_aim_enabled:
		var keyboard_aim := _get_keyboard_aim_direction()
		if keyboard_aim != Vector2.ZERO:
			return keyboard_aim
	if aim_direction.length_squared() > 0.0001:
		return aim_direction.normalized()
	var mouse_aim_vector := _get_world_mouse_position() - global_position
	if mouse_aim_vector.length_squared() > 0.0001:
		return mouse_aim_vector.normalized()
	return Vector2.RIGHT


func _get_world_mouse_position() -> Vector2:
	var camera := _get_world_camera()
	if camera != null and camera.has_method("get_global_mouse_position"):
		return camera.get_global_mouse_position()
	return get_global_mouse_position()


func equip_primary_carbine() -> void:
	_create_weapon_from_factory("carbine_mk1")
	_rebuild_armed_weapon_list()
	var index := armed_weapons.find(primary_weapon_definition)
	if index >= 0:
		queue_weapon_selection({"type": "armed", "index": index})


func _create_weapon_from_factory(weapon_id: String) -> void:
	if weapon_factory and weapon_factory.has_method("create_weapon_definition"):
		primary_weapon_definition = weapon_factory.create_weapon_definition(weapon_id)
		_configure_weapon_definition_defaults(primary_weapon_definition, "Carbine Rifle", "ranged", "ranged_fire", "ranged_fire")
		_rebuild_armed_weapon_list()
		_initialize_magazines()
		print("[Operator] Loaded weapon: ", weapon_id, " | Magazine: ", _get_current_magazine_size())


func unequip_primary_weapon() -> void:
	_holster_all_weapons()


func toggle_primary_carbine() -> void:
	if _is_ranged_loadout_active():
		_holster_all_weapons()
		return
	equip_primary_carbine()


func receive_projectile_hit(amount: float, _attacker_team: String = "neutral") -> Dictionary:
	if _is_blocking() and stamina >= block_stamina_cost_per_hit:
		stamina = max(0.0, stamina - block_stamina_cost_per_hit)
		return {
			"blocked": true,
			"applied_damage": 0.0,
		}
	if _is_block_state_active():
		_block_phase = &"exit"
		_block_active = false
		_play_block_animation(&"melee_2h_block_exit")
	take_damage(amount)
	return {
		"blocked": false,
		"applied_damage": max(0.0, amount),
	}

func take_damage(amount: float):
	if _is_dead:
		return
	health -= amount
	current_health = health  # Sync with ControllableActor interface
	var hit_direction := -aim_direction.normalized() if aim_direction.length_squared() > 0.001 else Vector2.DOWN
	_last_damage_reaction_direction = hit_direction
	_notify_camera_damage_taken(hit_direction)
	update_visuals()
	_spawn_damage_popup(amount)
	if health > 0.0:
		_request_damage_reaction(amount)
	
	# Flash effect
	if visual:
		visual.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.1).timeout
		update_visuals()
	
	if health <= 0:
		health = 0
		print("OPERATOR DOWN!")
		_handle_death()


func _request_damage_reaction(_amount: float) -> void:
	if _animation_state_machine == null:
		return
	_animation_state_machine.request("hit_recoil", 20)


func get_damage_reaction_animation(_reaction_name: String) -> StringName:
	var profile := get_current_combat_profile()
	if profile == null:
		return &""
	var mapped := _get_weapon_animation_name(profile, "unarmed_light_hitreact", &"")
	if mapped == StringName():
		return &""
	return AnimationResolver.resolve(String(mapped), _last_damage_reaction_direction, animated_sprite)

func _handle_death() -> void:
	if _is_dead:
		return
	_is_dead = true
	current_health = 0.0  # Sync with ControllableActor
	_buffered_attack_kind = ""
	_melee_active = false
	_melee_attack_kind = ""
	_melee_attack_key = ""
	fire_cooldown_remaining = 0.0
	melee_cooldown_remaining = 0.0
	is_sprinting = false
	stamina = 0.0
	velocity = Vector2.ZERO
	disable_hitbox()
	if _animation_state_machine != null:
		_animation_state_machine.request("death", 20)
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("lose_life"):
		gs.lose_life("Operator eliminated after a fatal strike")
	await get_tree().create_timer(1.6).timeout
	_finish_death()

func _finish_death() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.game_over:
		return
	health = max_health
	stamina = stamina_max
	_sprint_exhausted = false
	_buffered_attack_kind = ""
	_melee_active = false
	_melee_attack_kind = ""
	_melee_attack_key = ""
	fire_cooldown_remaining = 0.0
	melee_cooldown_remaining = 0.0
	velocity = Vector2.ZERO
	disable_hitbox()
	update_visuals()
	_is_dead = false
	if _animation_state_machine != null:
		_animation_state_machine.request("idle", 0)

func update_visuals():
	if health_bar:
		health_bar.value = (health / max_health) * 100.0
	
	if visual:
		var health_pct = health / max_health
		if health_pct > 0.7:
			visual.modulate = Color(0.2, 0.6, 0.8)  # Blue - healthy
		elif health_pct > 0.3:
			visual.modulate = Color(0.8, 0.6, 0.2)  # Yellow - damaged
		else:
			visual.modulate = Color(0.8, 0.2, 0.2)  # Red - critical


func get_display_name() -> String:
	return "Operator"


func can_be_controlled() -> bool:
	return is_alive() and not _is_dead and not _is_terminal_open()


## ControllableActor interface implementation
func process_input(input_vector: Vector2, aim_vector: Vector2, is_firing: bool) -> void:
	# Operator handles its own input natively via _physics_process
	# This method exists for interface compliance but operator uses native input
	pass

func _damage_nearest_sector(amount: float):
	var sectors = []
	var world = get_node("/root/GameRoot/World")
	if world:
		sectors = world.find_children("*", "Sector")
	
	if sectors.size() > 0:
		var nearest = sectors[0]
		var nearest_dist = global_position.distance_to(nearest.global_position)
		for sector in sectors:
			var dist = global_position.distance_to(sector.global_position)
			if dist < nearest_dist:
				nearest = sector
				nearest_dist = dist
		if nearest.has_method("take_damage"):
			nearest.take_damage(amount)
			print("Damaged sector: ", nearest.sector_name)


func _try_repair(delta: float) -> bool:
	repair_target = _find_nearest_repair_target(interaction_range)
	if repair_target == null:
		return false
	var repair_amount = repair_rate * delta
	repair_target.repair(repair_amount)
	return true


func _find_nearest_repair_target(max_distance: float) -> Damageable:
	var nearest: Damageable = null
	var nearest_dist := max_distance
	for candidate in get_tree().get_nodes_in_group("structure"):
		if not (candidate is Damageable):
			continue
		var structure := candidate as Damageable
		if structure == null or not is_instance_valid(structure):
			continue
		if structure.get_state() == "destroyed":
			continue
		if structure.current_health >= structure.max_health:
			continue
		if not (structure is Node2D):
			continue
		var dist = global_position.distance_to((structure as Node2D).global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = structure
	return nearest


func get_repair_prompt() -> String:
	var target = _find_nearest_repair_target(interaction_range)
	if target == null:
		return ""
	var hp_percent = int(round(target.get_efficiency() * 100.0))
	return "HOLD H TO REPAIR %s (%d%% HP)" % [target.name.to_upper(), hp_percent]


func get_build_prompt() -> String:
	build_target = _find_nearest_blueprint()
	if build_target == null:
		return ""
	return "HOLD %s TO BUILD %s" % [_get_action_prompt_key("build", "B"), build_target.get_wall_type_name().to_upper()]


func get_interaction_prompt() -> String:
	if interaction_target and interaction_target.has_method("get_interaction_prompt"):
		return String(interaction_target.get_interaction_prompt())
	var repair_prompt = get_repair_prompt()
	if not repair_prompt.is_empty():
		return repair_prompt
	var build_prompt = get_build_prompt()
	if not build_prompt.is_empty():
		return build_prompt
	return ""


func _find_nearest_blueprint() -> Node:
	var wall_placer = get_node_or_null("/root/GameRoot/World/WallPlacer")
	if wall_placer == null:
		return null
	
	var nearest: Node = null
	var nearest_dist := interaction_range
	var pos = global_position
	
	for blueprint in wall_placer.get_blueprints():
		var dist = pos.distance_to(blueprint.global_position)
		if dist < nearest_dist:
			nearest = blueprint
			nearest_dist = dist
	
	return nearest


func _try_build(delta: float) -> bool:
	build_target = _find_nearest_blueprint()
	if build_target == null:
		return false
	
	var wall_build_system = get_node_or_null("/root/GameRoot/World/WallBuildSystem")
	if wall_build_system == null:
		return false
	
	if wall_build_system.start_build(build_target):
		print("Started building: ", build_target.get_wall_type_name())
		return true
	return false


func _handle_interact_input():
	if not Input.is_action_just_pressed("interact"):
		return
	if _is_terminal_open():
		return
	if interaction_target and interaction_target.has_method("interact"):
		interaction_target.interact(self)


func _update_interaction_target():
	interaction_target = _find_best_interactable(interaction_range)


func _find_best_interactable(max_distance: float) -> Node:
	var candidates = get_tree().get_nodes_in_group("interactable")
	var best: Node = null
	var best_dist := max_distance
	for candidate in candidates:
		if not (candidate is Node2D):
			continue
		var target_pos = (candidate as Node2D).global_position
		if candidate.has_method("get_interaction_position"):
			target_pos = candidate.get_interaction_position()
		var dist = global_position.distance_to(target_pos)
		var allowed = max_distance
		if candidate.has_method("get_interaction_distance"):
			allowed = min(max_distance, float(candidate.get_interaction_distance()))
		if dist <= allowed and dist <= best_dist:
			best = candidate
			best_dist = dist
	return best


func _get_action_prompt_key(action_name: StringName, fallback: String) -> String:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
			return OS.get_keycode_string(keycode)
		if event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			return "M%d" % mouse_event.button_index
	return fallback


func _is_terminal_open() -> bool:
	var ui = get_node_or_null("/root/GameRoot/UI")
	if ui and ui.has_method("is_terminal_open"):
		return bool(ui.is_terminal_open())
	return false
