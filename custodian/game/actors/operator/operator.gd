extends ControllableActor

signal health_changed(current: float, maximum: float)
signal field_patch_changed(count: int, maximum: int)
signal field_patch_state_changed(active: bool, committed: bool)

const AnimationResolver = preload("res://game/actors/operator/animations/animation_resolver.gd")
const AnimationStateMachine = preload("res://game/actors/operator/animations/animation_state_machine.gd")
const AttackFastState = preload("res://game/actors/operator/animations/states/attack_fast_state.gd")
const AttackHeavyState = preload("res://game/actors/operator/animations/states/attack_heavy_state.gd")
const BlockState = preload("res://game/actors/operator/animations/states/block_state.gd")
const EquipWeaponState = preload("res://game/actors/operator/animations/states/equip_weapon_state.gd")
const HitRecoilState = preload("res://game/actors/operator/animations/states/hit_recoil_state.gd")
const IdleState = preload("res://game/actors/operator/animations/states/idle_state.gd")
const WalkState = preload("res://game/actors/operator/animations/states/walk_state.gd")
const SprintState = preload("res://game/actors/operator/animations/states/sprint_state.gd")
const DeathState = preload("res://game/actors/operator/animations/states/death_state.gd")
const MeleeAttackProfile = preload("res://game/systems/combat/melee_attack_profile.gd")
const SPEED := 150.0
const BULLET_SCENE := preload("res://game/actors/projectiles/bullet.tscn")
const MUZZLE_FLASH_SCENE := preload("res://game/actors/effects/muzzle_flash.tscn")
@export var impact_scene: PackedScene = preload("res://game/actors/effects/impact_spark.tscn")
const MELEE_SWING_SCENE := preload("res://game/actors/effects/melee_swing.tscn")
const TARGET_RING_SCENE := preload("res://game/actors/effects/target_ring.tscn")
const DAMAGE_POPUP_SCENE := preload("res://game/actors/ui/damage_popup.tscn")
const PARRY_CONTACT_SPARK_VFX_SCENE := preload("res://game/vfx/combat/parry_contact_spark_vfx.tscn")
const PARRY_SUCCESS_BURST_VFX_SCENE := preload("res://game/vfx/combat/parry_success_burst_vfx.tscn")
const CRITICAL_ATTACK_RIGHT_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__parry_miss_01__e__8f__96.png"
const CRITICAL_ATTACK_LEFT_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__parry_miss_01__w__8f__96.png"
const CRITICAL_ATTACK_FRAME_COUNT := 8
const CRITICAL_ATTACK_FRAME_SIZE := Vector2i(96, 96)
const CRITICAL_ATTACK_FPS := 15.0
const CRITICAL_HITSPARK_RIGHT_SHEET := "res://content/sprites/operator/new_operator/modular/critical/operator__fx__critical_hitspark_01__e__8f__156x96.png"
const CRITICAL_HITSPARK_LEFT_SHEET := "res://content/sprites/operator/new_operator/modular/critical/operator__fx__critical_hitspark_01__w__8f__156x96.png"
const CRITICAL_HITSPARK_FRAME_COUNT := 8
const CRITICAL_HITSPARK_FRAME_SIZE := Vector2i(156, 96)
const CRITICAL_HITSPARK_FPS := 15.0

enum AttackPhase {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

const ATTACK_MOVE_PROFILES := {
	"unarmed_fast": {
		"startup_time": 0.06,
		"active_time": 0.10,
		"startup_move": 0.95,
		"active_move": 0.85,
		"recovery_move": 1.00,
		"turn_locked": false,
	},
	"melee_fast": {
		"startup_time": 0.08,
		"active_time": 0.12,
		"startup_move": 0.80,
		"active_move": 0.65,
		"recovery_move": 0.85,
		"turn_locked": false,
	},
	"melee_heavy": {
		"startup_time": 0.18,
		"active_time": 0.16,
		"startup_move": 0.45,
		"active_move": 0.10,
		"recovery_move": 0.35,
		"turn_locked": true,
	},
	"unarmed_heavy": {
		"startup_time": 0.18,
		"active_time": 0.16,
		"startup_move": 0.45,
		"active_move": 0.10,
		"recovery_move": 0.35,
		"turn_locked": true,
	},
	"ranged_fire": {
		"startup_time": 0.05,
		"active_time": 0.08,
		"startup_move": 0.65,
		"active_move": 0.55,
		"recovery_move": 0.70,
		"turn_locked": false,
	},
}

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
@export var ammo_standard: int = 48
@export var ammo_heavy: int = 12
@export var ammo_standard_max: int = 72
@export var ammo_heavy_max: int = 16
@export var ammo_standard_magazine_size: int = 24
@export var ammo_heavy_magazine_size: int = 8
@export var ranged_reload_duration: float = 1.7
@export var interaction_range: float = 84.0
@export_group("Deprecated Melee Fallbacks", "melee")
@export var melee_damage: float = 28.0
@export var melee_range: float = 72.0
@export var melee_arc_degrees: float = 80.0
@export var melee_cooldown: float = 0.45
@export var melee_fast_hit_damage: float = 7.0
@export var melee_heavy_hit_damage: float = 34.0
@export var melee_heavy_range: float = 84.0
@export var melee_heavy_arc_degrees: float = 58.0
@export var melee_input_buffer_time: float = 0.15
@export var melee_fast_cancel_start: float = 0.22
@export var melee_heavy_cancel_start: float = 0.58
@export var melee_hit_stop_scale: float = 0.8
@export var melee_hit_stop_duration: float = 0.02
@export var melee_camera_shake_power: float = 1.0
@export var melee_fast_hit_stop_scale: float = 0.88
@export var melee_fast_hit_stop_duration: float = 0.028
@export var melee_fast_camera_shake_power: float = 1.4
@export var operator_light_reaction_stun_duration: float = 0.22
@export var melee_fast_knockback_force: float = 56.0
@export var melee_fast_recovery_duration: float = 0.10
@export var melee_fast_animation_speed_scale: float = 1.35
@export var melee_heavy_hit_stop_scale: float = 0.55
@export var melee_heavy_hit_stop_duration: float = 0.05
@export var melee_heavy_camera_shake_power: float = 4.2
@export var melee_heavy_knockback_force: float = 132.0
@export_group("", "")
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
@export var ranged_ready_move_multiplier: float = 0.88
@export var dodge_speed: float = 480.0
@export var dodge_duration: float = 0.20
@export var dodge_iframe_duration: float = 0.16
@export var dodge_recovery_duration: float = 0.16
@export var dodge_cooldown: float = 0.42
@export var dodge_stamina_cost: float = 16.0
@export var dodge_iframe_debug_enabled: bool = true
@export var heavy_attack_stamina_cost: float = 14.0
@export var heavy_attack_blocked_while_sprinting: bool = true
@export var block_move_multiplier: float = 0.6
@export var block_stamina_cost_per_hit: float = 12.0
@export_group("Parry / Guard")
@export var offhand_guard_item_equipped: bool = false
@export var guard_weak_start_sec: float = 0.0
@export var guard_full_active_sec: float = 0.10
@export var parry_min_guard_time_sec: float = 0.04
@export var parry_windup_sec: float = 0.02
@export var parry_active_sec: float = 0.10
@export var parry_recovery_sec: float = 0.16
@export var parry_success_recovery_sec: float = 0.03
@export var parry_stamina_cost: float = 8.0
@export var parry_success_stamina_refund: float = 6.0
@export var parry_enemy_stagger_sec: float = 0.55
@export var parry_enemy_knockback: float = 44.0
@export var parry_counter_window_sec: float = 0.45
@export var parry_counter_damage_multiplier: float = 1.25
@export var guard_damage_reduction: float = 0.65
@export var guard_chip_damage_minimum: float = 1.0
@export var guard_stamina_cost_per_hit: float = 12.0
@export var guard_break_stamina_threshold: float = 6.0
@export var guard_exit_speed_scale: float = 1.6
@export_group("", "")
@export_group("Field Patch")
@export var field_patch_max_count: int = 2
@export var field_patch_count: int = 1
@export var field_patch_use_duration: float = 1.25
@export var field_patch_restore_fraction: float = 0.35
@export var field_patch_recovery_duration: float = 0.20
@export var field_patch_move_multiplier: float = 0.35
@export_group("", "")
@export var combat_target_range: float = 360.0
@export var use_tiny_rpg_placeholder_soldier: bool = true
@export var modular_locomotion_layers_enabled: bool = true
@export_group("Modular Primary Ranged Fire")
@export var modular_primary_ranged_fire_enabled: bool = true
@export var modular_primary_ranged_fire_fps: float = 14.0
@export var modular_primary_ranged_fire_recover_hold_sec: float = 0.04
@export var modular_primary_ranged_aim_fps: float = 8.0
@export var modular_primary_ranged_aim_cape_enabled: bool = true
@export_group("", "")
@export_file("*.png") var idle_main_sheet_path := "res://content/sprites/operator/runtime/idle/operator_idle_main.png"
@export_file("*.png") var ranged_2h_stance_sheet_path := "res://content/sprites/operator/runtime/body/ranged_2h/operator__body__ranged__stance_01__e__12f__96.png"
@export_file("*.png") var ranged_2h_aim_sheet_path := "res://content/sprites/operator/runtime/body/ranged_2h/operator_body_ranged_2h_aim_raise.png"
@export_file("*.png") var ranged_2h_fire_walk_sheet_path := "res://content/sprites/operator/runtime/curated/body/ranged_2h/firing_slow_walk.png"
@export_group("Knight Test Skin", "knight_test")
@export var knight_test_skin_enabled: bool = false
@export_dir var knight_test_sprite_dir := "res://dev/test_sprites/Knight"
@export var knight_test_frame_size: Vector2i = Vector2i(128, 128)
@export_range(1, 32, 1) var knight_test_frame_columns: int = 15
@export_range(0, 7, 1) var knight_test_row_up_left: int = 0
@export_range(0, 7, 1) var knight_test_row_up: int = 1
@export_range(0, 7, 1) var knight_test_row_up_right: int = 2
@export_range(0, 7, 1) var knight_test_row_right: int = 3
@export_range(0, 7, 1) var knight_test_row_down_right: int = 4
@export_range(0, 7, 1) var knight_test_row_down: int = 5
@export var knight_test_sprite_position: Vector2 = Vector2(0, -18)
@export var knight_test_sprite_offset: Vector2 = Vector2.ZERO
@export var knight_test_sprite_scale: Vector2 = Vector2.ONE
@export_group("", "")
@export var primary_weapon_definition = null
@export var melee_weapon_definition = null
@export var unarmed_definition: OperatorWeaponDefinition = preload("res://game/actors/operator/unarmed_definition.tres")
@export var sidearm_weapon_definition: OperatorWeaponDefinition = preload("res://game/actors/operator/sidearm_pistol_definition.tres")
@export var sidearm_slot_equipped: bool = false
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
@export var ranged_muzzle_obstruction_margin: float = 2.0
@export var ranged_neutral_rotation_limit_degrees: float = 34.0
@export var ranged_vertical_rotation_limit_degrees: float = 18.0
@export var fake_elevation_visual_lift_factor: float = 0.5
@export var fake_elevation_z_scale: float = 0.08

var interaction_target: Node = null
var repair_target: Damageable = null
var build_target: Node = null  # WallBlueprint we're building
var movement_direction := Vector2.DOWN  # Direction player is moving (for walk animations)
var visual_idle_direction := Vector2.DOWN
var arrow_aim_enabled: bool = false
var stamina: float = 100.0
var is_sprinting: bool = false
var is_sneaking: bool = false
var current_noise_radius_px: float = 0.0
var stealth_visibility_mult: float = 1.0
var _sprint_exhausted: bool = false
var _melee_active: bool = false
var _melee_attack_kind: String = ""
var _melee_attack_key: String = ""
var _melee_elapsed: float = 0.0
var _melee_duration: float = 0.0
var _melee_forward: Vector2 = Vector2.RIGHT
var attack_phase: AttackPhase = AttackPhase.NONE
var current_attack_id: String = ""
var attack_phase_time_remaining: float = 0.0
var attack_facing_dir: Vector2 = Vector2.DOWN
var armed_weapons: Array[OperatorWeaponDefinition] = []
var armed_weapon_index: int = 0
var last_armed_weapon_index: int = 0
var using_unarmed: bool = false
var pending_weapon_selection: Dictionary = {}
var _active_attack_profile: OperatorWeaponDefinition = null
var _active_melee_attack_profile: MeleeAttackProfile = null
var _missing_animation_warnings: Dictionary = {}
var _ranged_config_warning_once: Dictionary = {}
var _melee_heavy_anticipating: bool = false
var _melee_fast_windup: bool = false
var _melee_fast_combo_step: int = 0
var _buffered_attack_kind: String = ""
var _buffered_attack_timer: float = 0.0
var _hit_stop_active: bool = false
var _melee_damage_current: float = 0.0
var _melee_range_current: float = 0.0
var _melee_arc_current: float = 0.0
var _melee_hitbox_active: bool = false
var _melee_hit_targets: Dictionary = {}
var _critical_attack_target: Node2D = null
var _critical_attack_damage: float = 0.0
var _block_phase: StringName = &""
var _block_active: bool = false
var _parry_phase: StringName = &""
var _parry_timer: float = 0.0
var _parry_active: bool = false
var _parry_success_lockout: float = 0.0
var _guard_requested_from_secondary: bool = false
var _guard_repress_required_after_parry_success: bool = false
var _parry_neutral_lock_active: bool = false
var _guard_held_timer: float = 0.0
var _offhand_secondary_was_pressed: bool = false
var _counter_window_timer: float = 0.0
var _melee_recovery_active: bool = false
var _melee_recovery_timer: float = 0.0
var _reload_active: bool = false
var _reload_timer: float = 0.0
var _ammo_standard_loaded: int = 0
var _ammo_heavy_loaded: int = 0
var ammo_reserve_by_type: Dictionary = {}
var ammo_capacity_by_type: Dictionary = {}
var loaded_ammo_by_weapon_id: Dictionary = {}
var weapon_heat_by_id: Dictionary = {}
var weapon_heat_delay_by_id: Dictionary = {}
var weapon_overheat_by_id: Dictionary = {}
var last_ranged_fire_failure: StringName = &""
var _pending_ranged_shot: Dictionary = {}
var _ranged_ready_active: bool = false
var _ranged_ready_weapon_definition: OperatorWeaponDefinition = null
var _dodge_active: bool = false
var _dodge_recovery_active: bool = false
var _dodge_timer: float = 0.0
var _dodge_iframe_timer: float = 0.0
var _dodge_recovery_timer: float = 0.0
var _dodge_cooldown_remaining: float = 0.0
var _dodge_direction: Vector2 = Vector2.DOWN
var _dodge_backstep_active: bool = false
var _field_patch_active: bool = false
var _field_patch_timer: float = 0.0
var _field_patch_committed: bool = false
var _field_patch_recovery_timer: float = 0.0
var _field_patch_missing_presentation_warning_emitted: bool = false
var _combat_target: Node2D = null
var _target_ring: Node2D = null
var _target_ring_pending: bool = false
var _idle_loop_counter := 0
var _last_idle_frame := -1
var _last_idle_animation := ""
var _animation_state_machine = null
var _portal_transition_locked := false
var _portal_arrival_animation_active := false
var _arrn_stabilization_locked := false
var _enemy_impact_lock_timer: float = 0.0
var _is_dead := false
var _body_recoil_offset := Vector2.ZERO
var _animated_sprite_base_position := Vector2.ZERO
var _dodge_fx_back_base_position := Vector2.ZERO
var _modular_cape_base_position := Vector2.ZERO
var _modular_lower_body_base_position := Vector2.ZERO
var _modular_upper_body_base_position := Vector2.ZERO
var _modular_sidearm_base_position := Vector2.ZERO
var _modular_upper_fx_base_position := Vector2.ZERO
var _melee_weapon_overlay_base_position := Vector2.ZERO
var _melee_fx_overlay_base_position := Vector2.ZERO
var _last_damage_reaction_direction := Vector2.DOWN
var _production_body_frames: SpriteFrames = null
var _knight_test_frames: SpriteFrames = null
var _knight_test_skin_active: bool = false
var _modular_lower_action_animation: StringName = &""
var _modular_upper_action_animation: StringName = &""
var _modular_upper_fx_action_animation: StringName = &""
var _modular_sidearm_action_animation: StringName = &""
var _modular_sidearm_fx_animation: StringName = &""
var _warned_missing_modular_fast_attack_fx: bool = false
var _sidearm_draw_active: bool = false
var _sidearm_action_phase: StringName = &"holstered"
var _sidearm_action_phase_started: bool = false
var _sidearm_action_direction: Vector2 = Vector2.DOWN
var _primary_ranged_action_phase: StringName = &""
var _primary_ranged_action_timer: float = 0.0
var _primary_ranged_action_suffix: StringName = &"right"
var fake_elevation: float = 0.0
var movement_surface_multiplier: float = 1.0
var _base_world_z_index: int = 2
var _fake_elevation_visual_offset: Vector2 = Vector2.ZERO

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
	var weapon_definition := _get_active_ranged_weapon_definition()
	if weapon_definition == null:
		return resolved_profile
	var fire_rate_rps: float = weapon_definition.get_stat_float("fire_rate_rps", 0.0)
	if fire_rate_rps > 0.001:
		resolved_profile["cooldown"] = 1.0 / fire_rate_rps
	resolved_profile["damage"] = weapon_definition.get_stat_float("damage", float(resolved_profile.get("damage", 16.0)))
	resolved_profile["speed"] = weapon_definition.get_stat_float("projectile_speed_px", float(resolved_profile.get("speed", 780.0)))
	resolved_profile["spread"] = weapon_definition.get_stat_float("spread_deg", float(resolved_profile.get("spread", 2.0)))
	resolved_profile["recoil_kick"] = weapon_definition.get_stat_float("recoil", float(resolved_profile.get("recoil_kick", 1.2)))
	resolved_profile["effective_range_px"] = weapon_definition.get_stat_float("effective_range_px", weapon_definition.get_stat_float("range_px", 180.0))
	resolved_profile["max_range_px"] = weapon_definition.get_stat_float("max_range_px", weapon_definition.get_stat_float("range_px", 320.0))
	resolved_profile["falloff_start_px"] = weapon_definition.get_stat_float("damage_falloff_start_px", float(resolved_profile["effective_range_px"]))
	resolved_profile["falloff_end_px"] = weapon_definition.get_stat_float("damage_falloff_end_px", float(resolved_profile["max_range_px"]))
	resolved_profile["min_damage_multiplier"] = weapon_definition.get_stat_float("min_falloff_damage_mult", 0.5)
	resolved_profile["projectile_scene"] = weapon_definition.get_projectile_value("scene", "res://game/actors/projectiles/bullet.tscn")
	resolved_profile["impact_scene"] = weapon_definition.get_projectile_value("impact_scene", "")
	resolved_profile["visual_sprite_frames"] = weapon_definition.get_projectile_value("visual_sprite_frames", "")
	resolved_profile["visual_animation"] = weapon_definition.get_projectile_value("visual_animation", "travel")
	resolved_profile["visual_scale"] = _dictionary_to_vector2(weapon_definition.get_projectile_value("visual_scale", {}), Vector2.ONE)
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
const DODGE_STEP_ANIMATION := &"operator_dodge_step"
const DODGE_RECOVERY_ANIMATION := &"operator_dodge_recovery"
const DODGE_BACKSTEP_ANIMATION := &"operator_dodge_backstep"
const DODGE_BACKSTEP_RECOVERY_ANIMATION := &"operator_dodge_backstep_recovery"
const DODGE_STEP_RUNTIME_SHEET_PATH := "res://content/sprites/operator/runtime/body/locomotion/operator__body__locomotion__dodge__n__4f__96.png"
const DODGE_RECOVERY_RUNTIME_SHEET_PATH := "res://content/sprites/operator/runtime/body/locomotion/operator__body__locomotion__dodge_recovery__n__4f__96.png"
const DODGE_BACKSTEP_RUNTIME_SHEET_PATH := "res://content/sprites/operator/runtime/body/locomotion/operator__body__locomotion__dodge_backstep__s__4f__96.png"
const DODGE_BACKSTEP_RECOVERY_RUNTIME_SHEET_PATH := "res://content/sprites/operator/runtime/body/locomotion/operator__body__locomotion__dodge_backstep_recovery__s__4f__96.png"
const DODGE_STEP_SHEET_PATH := "res://content/sprites/operator/new_operator/modular/dodge/operator__body__full__dodge_step_01__n__5f__96.png"
const DODGE_STEP_FX_ANIMATION := &"operator_dodge_step_fx"
const DODGE_STEP_FX_SHEET_PATH := "res://content/sprites/operator/new_operator/modular/dodge/operator__fx__full__dodge_step_01__n__5f__96.png"
const DODGE_FULL_NORTH_ANIMATION := &"operator_dodge_full_north"
const DODGE_FULL_SOUTH_ANIMATION := &"operator_dodge_full_south"
const DODGE_FULL_NORTH_SHEET_PATH := "res://content/sprites/operator/runtime/actions/dodge/body/operator__body__full__dodge_01__n__9f__96.png"
const DODGE_FULL_SOUTH_SHEET_PATH := "res://content/sprites/operator/runtime/actions/dodge/body/operator__body__full__dodge_01__s__9f__96.png"
const DODGE_FULL_NORTH_FX_ANIMATION := &"operator_dodge_full_fx_north"
const DODGE_FULL_SOUTH_FX_ANIMATION := &"operator_dodge_full_fx_south"
const DODGE_FULL_NORTH_FX_SHEET_PATH := "res://content/sprites/operator/runtime/actions/dodge/fx/operator__fx__full__dodge_01__n__9f__96.png"
const DODGE_FULL_SOUTH_FX_SHEET_PATH := "res://content/sprites/operator/runtime/actions/dodge/fx/operator__fx__full__dodge_01__s__9f__96.png"
const DODGE_FULL_SEQUENCE_FPS := 25.0
const DODGE_FX_BACK_ALPHA := 0.72
const DODGE_FX_BACK_OFFSET_BY_DIRECTION := {
	"up": Vector2(0, 14),
	"up_right": Vector2(-10, 10),
	"right": Vector2(-16, 2),
	"down_right": Vector2(-10, -6),
	"down": Vector2(0, -12),
	"down_left": Vector2(10, -6),
	"left": Vector2(16, 2),
	"up_left": Vector2(10, 10),
}
const PORTAL_ARRIVAL_ANIMATION := &"unarmed_arrival"
const PORTAL_ARRIVAL_DOWN_ANIMATION := &"unarmed_arrival_down"
const BODY_RECOIL_RECOVERY_RATE := 18.0
const BODY_RECOIL_PROFILE_PIXELS := {
	"recoil_pistol": 0.7,
	"recoil_standard": 1.0,
	"recoil_shotgun": 1.5,
	"recoil_sniper": 2.0,
	"recoil_minigun": 0.6,
}
const MODULAR_PRIMARY_RANGED_MUZZLE_OFFSETS := {
	"right": Vector2(32.0, -10.0),
	"left": Vector2(-32.0, -10.0),
	"down_right": Vector2(31.0, 1.0),
	"down_left": Vector2(-31.0, 1.0),
}
const MODULAR_SIDEARM_MUZZLE_OFFSETS := {
	"up_right": Vector2(34.0, -17.0),
	"up_left": Vector2(-34.0, -17.0),
	"down_right": Vector2(35.0, -13.0),
	"down_left": Vector2(-35.0, -13.0),
}
const KNIGHT_TEST_ANIMATION_SPECS := {
	"idle": {"file": "Idle.png", "fps": 8.0, "loop": true},
	"walk": {"file": "Walk.png", "fps": 10.0, "loop": true},
	"run": {"file": "Run.png", "fps": 12.0, "loop": true},
	"melee": {"file": "Melee.png", "fps": 14.0, "loop": false},
	"melee2": {"file": "Melee2.png", "fps": 14.0, "loop": false},
	"heavy": {"file": "MeleeSpin.png", "fps": 12.0, "loop": false},
	"block_start": {"file": "ShieldBlockStart.png", "fps": 10.0, "loop": false},
	"block_hold": {"file": "ShieldBlockMid.png", "fps": 8.0, "loop": true},
	"hit": {"file": "TakeDamage.png", "fps": 10.0, "loop": false},
	"death": {"file": "Die.png", "fps": 10.0, "loop": false},
}

@onready var health_bar = $HealthBar
@onready var visual = $Visual
@onready var animated_sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var dodge_fx_back_sprite: AnimatedSprite2D = $DodgeFXBackSprite if has_node("DodgeFXBackSprite") else null
@onready var modular_cape_sprite: AnimatedSprite2D = $ModularCapeSprite if has_node("ModularCapeSprite") else null
@onready var modular_lower_body_sprite = $ModularLowerBodySprite if has_node("ModularLowerBodySprite") else null
@onready var modular_upper_body_sprite = $ModularUpperBodySprite if has_node("ModularUpperBodySprite") else null
@onready var modular_sidearm_sprite = $ModularSidearmSprite if has_node("ModularSidearmSprite") else null
@onready var modular_upper_fx_sprite = $ModularUpperFxSprite if has_node("ModularUpperFxSprite") else null
@onready var right_hand_socket = $RightHandSocket if has_node("RightHandSocket") else null
@onready var left_hand_socket = $LeftHandSocket if has_node("LeftHandSocket") else null
@onready var primary_weapon_socket = $PrimaryWeaponSocket if has_node("PrimaryWeaponSocket") else null
@onready var primary_weapon_sprite = $PrimaryWeaponSocket/PrimaryWeaponSprite if has_node("PrimaryWeaponSocket/PrimaryWeaponSprite") else null
@onready var ranged_fx_overlay_sprite = $PrimaryWeaponSocket/RangedFxOverlaySprite if has_node("PrimaryWeaponSocket/RangedFxOverlaySprite") else null
@onready var melee_weapon_overlay_sprite = $MeleeWeaponOverlaySprite if has_node("MeleeWeaponOverlaySprite") else null
@onready var melee_fx_overlay_sprite = $MeleeFxOverlaySprite if has_node("MeleeFxOverlaySprite") else null
@onready var barrel = $PrimaryWeaponSocket/Barrel if has_node("PrimaryWeaponSocket/Barrel") else null
@onready var body_collision = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var blob_shadow = $BlobShadow if has_node("BlobShadow") else null
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
	_base_world_z_index = z_index
	
	# Reset any modulation from editor
	if visual:
		visual.modulate = Color(1, 1, 1, 1)
	if animated_sprite:
		_production_body_frames = animated_sprite.sprite_frames

		animated_sprite.modulate = Color(1.3, 1.3, 1.3, 1)  # Brighten 30%
		animated_sprite.frame_changed.connect(_on_attack_frame_changed)
		if not animated_sprite.animation_finished.is_connected(_on_operator_animation_finished):
			animated_sprite.animation_finished.connect(_on_operator_animation_finished)
		_ensure_runtime_body_animations()
		_apply_knight_test_skin_if_requested()
	if dodge_fx_back_sprite:
		dodge_fx_back_sprite.visible = false
		dodge_fx_back_sprite.z_index = -1
		dodge_fx_back_sprite.modulate = Color(1.0, 1.0, 1.0, DODGE_FX_BACK_ALPHA)
		if dodge_fx_back_sprite.sprite_frames == null:
			dodge_fx_back_sprite.sprite_frames = SpriteFrames.new()
	if modular_cape_sprite:
		modular_cape_sprite.visible = false
		modular_cape_sprite.modulate = Color(1.3, 1.3, 1.3, 1)
	if modular_lower_body_sprite:
		modular_lower_body_sprite.visible = false
		modular_lower_body_sprite.modulate = Color(1.3, 1.3, 1.3, 1)
	if modular_upper_body_sprite:
		modular_upper_body_sprite.visible = false
		modular_upper_body_sprite.modulate = Color(1.3, 1.3, 1.3, 1)
	_configure_weapon_definition_defaults(primary_weapon_definition, "Carbine Rifle", "ranged", "ranged_unfocused_fire", "ranged_ready")
	_configure_weapon_definition_defaults(melee_weapon_definition, "Fallen Star Katana", "melee", "melee_fast", "melee_heavy")
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
	_sync_fake_elevation_visual_state()
	update_visuals()


func set_knight_test_skin_enabled(enabled: bool) -> bool:
	knight_test_skin_enabled = enabled
	_apply_knight_test_skin_if_requested()
	return _knight_test_skin_active


func toggle_knight_test_skin() -> bool:
	return set_knight_test_skin_enabled(not _knight_test_skin_active)


func is_knight_test_skin_active() -> bool:
	return _knight_test_skin_active


func _apply_knight_test_skin_if_requested() -> void:
	if animated_sprite == null:
		return
	if _production_body_frames == null:
		_production_body_frames = animated_sprite.sprite_frames
	if knight_test_skin_enabled:
		if _knight_test_frames == null:
			_knight_test_frames = _build_knight_test_frames()
		if _knight_test_frames == null:
			knight_test_skin_enabled = false
			_knight_test_skin_active = false
			return
		animated_sprite.sprite_frames = _knight_test_frames
		animated_sprite.position = knight_test_sprite_position
		animated_sprite.offset = knight_test_sprite_offset
		animated_sprite.scale = knight_test_sprite_scale
		_animated_sprite_base_position = animated_sprite.position
		_hide_custom_operator_visual_layers()
		_knight_test_skin_active = true
		update_visuals()
		return
	if _knight_test_skin_active and _production_body_frames != null:
		animated_sprite.sprite_frames = _production_body_frames
		if use_tiny_rpg_placeholder_soldier:
			_apply_placeholder_runtime_layout()
		else:
			_capture_runtime_visual_base_positions()
		_refresh_primary_weapon_state()
	_knight_test_skin_active = false


func _hide_custom_operator_visual_layers() -> void:
	_hide_modular_locomotion_layers()
	if primary_weapon_sprite:
		primary_weapon_sprite.visible = false
		primary_weapon_sprite.stop()
	if ranged_fx_overlay_sprite:
		ranged_fx_overlay_sprite.visible = false
		ranged_fx_overlay_sprite.stop()
	if dodge_fx_back_sprite:
		dodge_fx_back_sprite.visible = false
		dodge_fx_back_sprite.stop()
	if melee_weapon_overlay_sprite:
		melee_weapon_overlay_sprite.visible = false
		melee_weapon_overlay_sprite.stop()
	if melee_fx_overlay_sprite:
		melee_fx_overlay_sprite.visible = false
		melee_fx_overlay_sprite.stop()


func _build_knight_test_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	_add_knight_locomotion_animations(frames, "idle", [
		"idle", "idle_right", "idle_down", "idle_up", "idle_down_right", "idle_up_right",
		"idle_long", "ranged_2h_stance", "melee_2h_stance", "unarmed_idle",
		"unarmed_idle_right", "unarmed_idle_down", "unarmed_idle_up", "unarmed_stance", "default",
	])
	_add_knight_locomotion_animations(frames, "walk", [
		"walk_right", "walk_down", "walk_up", "walk_down_right", "walk_up_right",
		"walk_down_default", "walk_east", "unarmed_walk", "unarmed_walk_right",
		"unarmed_walk_down", "unarmed_walk_up",
	])
	_add_knight_locomotion_animations(frames, "run", [
		"run_right", "run_down", "run_up", "run_down_right", "run_up_right",
		"unarmed_run_right", "unarmed_run_down", "unarmed_run_up",
		"unarmed_run_down_right", "unarmed_run_down_left",
	])
	_add_knight_locomotion_animations(frames, "melee", [
		"melee_2h_fast_1", "melee_2h_fast_1_right", "melee_2h_fast",
		"melee_2h_fast_right", "unarmed_attack_fast", "unarmed_attack_fast_right",
		"unarmed_attack_fast_left", "unarmed_attack_fast_down", "unarmed_attack_fast_up",
		"ranged_2h_fire",
	])
	_add_knight_locomotion_animations(frames, "melee2", [
		"melee_2h_fast_2", "melee_2h_fast_2_right", "unarmed_attack_fast_recovery",
		"unarmed_attack_fast_recovery_right", "unarmed_attack_fast_recovery_down",
		"unarmed_attack_fast_recovery_up",
	])
	_add_knight_locomotion_animations(frames, "heavy", [
		"melee_2h_heavy_anticipation", "melee_2h_heavy", "unarmed_attack_heavy",
		"unarmed_attack_heavy_right", "unarmed_attack_heavy_down", "unarmed_attack_heavy_up",
	])
	_add_knight_locomotion_animations(frames, "block_start", ["melee_2h_block_enter", "melee_2h_block_exit"])
	_add_knight_locomotion_animations(frames, "block_hold", ["melee_2h_block_hold"])
	_add_knight_locomotion_animations(frames, "hit", ["unarmed_light_hitreact", "unarmed_light_hitreact_down", "hit_recoil"])
	_add_knight_locomotion_animations(frames, "death", ["death", "unarmed_death"])
	return frames if frames.get_animation_names().size() > 0 else null


func _add_knight_locomotion_animations(frames: SpriteFrames, spec_key: String, names: Array) -> void:
	var spec: Dictionary = KNIGHT_TEST_ANIMATION_SPECS.get(spec_key, {})
	if spec.is_empty():
		return
	var texture := load("%s/%s" % [knight_test_sprite_dir, String(spec.get("file", ""))]) as Texture2D
	if texture == null:
		push_warning("[KnightTestSkin] Missing sheet for %s at %s" % [spec_key, knight_test_sprite_dir])
		return
	for name_variant in names:
		var animation_name := StringName(str(name_variant))
		var row := _get_knight_test_row_for_animation_name(String(animation_name))
		_add_knight_sheet_animation(
			frames,
			animation_name,
			texture,
			row,
			float(spec.get("fps", 8.0)),
			bool(spec.get("loop", true))
		)


func _get_knight_test_row_for_animation_name(animation_name: String) -> int:
	if animation_name.ends_with("_up_right"):
		return knight_test_row_up_right
	if animation_name.ends_with("_down_right"):
		return knight_test_row_down_right
	if animation_name.ends_with("_up"):
		return knight_test_row_up
	if animation_name.ends_with("_down"):
		return knight_test_row_down
	if animation_name == "default" or animation_name == "idle" or animation_name == "idle_long":
		return knight_test_row_down
	return knight_test_row_right


func _add_knight_sheet_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	texture: Texture2D,
	row: int,
	fps: float,
	loop: bool
) -> void:
	if frames.has_animation(animation_name):
		frames.remove_animation(animation_name)
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)
	var frame_size := knight_test_frame_size
	var columns: int = maxi(1, knight_test_frame_columns)
	for column in range(columns):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			column * frame_size.x,
			clampi(row, 0, 7) * frame_size.y,
			frame_size.x,
			frame_size.y
		)
		frames.add_frame(animation_name, atlas)

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
	_dodge_cooldown_remaining = max(0.0, _dodge_cooldown_remaining - delta)
	_dodge_iframe_timer = maxf(0.0, _dodge_iframe_timer - delta)
	_parry_success_lockout = maxf(0.0, _parry_success_lockout - delta)
	var prev_counter_window := _counter_window_timer
	_counter_window_timer = maxf(0.0, _counter_window_timer - delta)
	if prev_counter_window > 0.0 and _counter_window_timer <= 0.0:
		_parry_neutral_lock_active = false
	current_recoil = max(0.0, current_recoil - recoil_decay * delta)
	_update_weapon_heat(delta)
	_update_pending_ranged_shot(delta)
	_update_body_recoil(delta)
	_update_attack_buffer(delta)
	_update_melee_attack(delta)
	_update_melee_recovery(delta)
	_update_reload(delta)
	_update_field_patch(delta)
	_tick_primary_ranged_action_presentation(delta)
	_update_animation_state_machine(delta)
	_update_combat_target()
	_update_target_ring()
	_update_interaction_target()
	if _is_dead:
		_parry_neutral_lock_active = false
		cancel_field_patch(&"dead")
		_cancel_dodge()
		_exit_ranged_ready()
		return
	if _enemy_impact_lock_timer > 0.0:
		_parry_neutral_lock_active = false
		cancel_field_patch(&"impact")
		_cancel_dodge()
		_exit_ranged_ready()
		_update_aim()
		_update_animation()
		return
	_handle_interact_input()
	if _is_terminal_open() or _is_non_terminal_ui_open():
		cancel_field_patch(&"ui")
		_exit_ranged_ready()
		return
	if _portal_transition_locked or _portal_arrival_animation_active:
		cancel_field_patch(&"portal")
		_exit_ranged_ready()
		_update_aim()
		_update_animation()
		return
	_handle_field_patch_input()
	_handle_field_patch_interrupt_input()
	if _field_patch_active:
		_exit_ranged_ready()
		_update_aim()
		_update_animation()
		return
	_handle_loadout_toggle_input()
	try_apply_pending_weapon_selection()
	_handle_aim_input_toggle()
	_handle_reload_input()
	_update_aim()
	_handle_offhand_secondary_input(delta)
	_update_ranged_ready_state()
	_handle_dodge_input()
	_update_animation()
	if Input.is_action_just_pressed("build"):
		if _try_terminal_deploy_or_pickup():
			return
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
	if _is_ui_text_input_focused():
		return
	if event is InputEventMouseMotion and not arrow_aim_enabled:
		var mouse_aim_vector := _get_world_mouse_position() - global_position
		if mouse_aim_vector.length_squared() > 0.0001:
			visual_idle_direction = mouse_aim_vector.normalized()


func _physics_process(delta):
	if _is_dead:
		velocity = Vector2.ZERO
		is_sneaking = false
		_update_stealth_noise_snapshot(false)
		move_and_slide()
		return
	if _enemy_impact_lock_timer > 0.0:
		_enemy_impact_lock_timer = maxf(0.0, _enemy_impact_lock_timer - delta)
		is_sprinting = false
		is_sneaking = false
		velocity = velocity.move_toward(Vector2.ZERO, move_deceleration * 0.55 * delta)
		_update_stealth_noise_snapshot(false)
		move_and_slide()
		return
	if _is_terminal_open() or _is_non_terminal_ui_open() or _is_ui_text_input_focused():
		cancel_field_patch(&"ui")
		velocity = Vector2.ZERO
		is_sprinting = false
		is_sneaking = false
		_update_stealth_noise_snapshot(false)
		stamina = min(stamina_max, stamina + stamina_regen_per_second * delta)
		move_and_slide()
		return
	if _dodge_active:
		_update_dodge(delta)
		_update_stealth_noise_snapshot(true)
		move_and_slide()
		return
	if _dodge_recovery_active:
		_update_dodge_recovery(delta)
		_update_stealth_noise_snapshot(false)
		move_and_slide()
		return
	if _is_movement_locked():
		velocity = Vector2.ZERO
		is_sprinting = false
		is_sneaking = false
		_update_stealth_noise_snapshot(false)
		move_and_slide()
		return
	_refresh_attack_phase_state()

	var input_direction := _get_move_input_vector()

	# Track movement direction for animations
	if input_direction != Vector2.ZERO:
		movement_direction = input_direction
		if not _is_aiming_for_facing():
			visual_idle_direction = input_direction

	var moving = input_direction != Vector2.ZERO
	var wants_sprint = Input.is_key_pressed(KEY_CTRL)
	var was_sprinting := is_sprinting
	if _sprint_exhausted and stamina >= stamina_max:
		_sprint_exhausted = false
	var can_start_sprint := stamina > stamina_sprint_gate
	is_sprinting = moving and wants_sprint and not _is_block_state_active() and not _has_attack_movement_modifier() and not _sprint_exhausted and (was_sprinting or can_start_sprint)
	is_sneaking = moving and InputMap.has_action("sneak") and Input.is_action_pressed("sneak") and not is_sprinting and not _has_attack_movement_modifier()
	var movement_profile := get_current_combat_profile()
	var active_move_speed := SPEED * sprint_multiplier if is_sprinting else SPEED
	if _field_patch_active:
		is_sprinting = false
		active_move_speed = SPEED
	if is_sneaking:
		active_move_speed *= 0.55
	if movement_profile != null:
		active_move_speed *= movement_profile.move_speed_multiplier
	if _is_ranged_ready_active():
		active_move_speed *= ranged_ready_move_multiplier
	active_move_speed *= _get_attack_move_multiplier()
	if _is_block_state_active():
		is_sprinting = false
		active_move_speed *= block_move_multiplier
	if _field_patch_active:
		active_move_speed *= field_patch_move_multiplier
		
	# Apply cognitive state move speed modifier
	var cognitive := get_node_or_null("/root/CognitiveState")
	if cognitive != null and cognitive.has_method("get_move_speed_multiplier"):
		active_move_speed *= float(cognitive.call("get_move_speed_multiplier"))
	set_movement_surface_multiplier(_query_movement_surface_multiplier("operator"))
	active_move_speed *= max(0.0, movement_surface_multiplier)
	var target_velocity: Vector2 = input_direction * active_move_speed
	var accel_rate: float = move_acceleration if moving else move_deceleration
	if movement_profile != null:
		accel_rate *= movement_profile.acceleration_multiplier
	velocity = velocity.move_toward(target_velocity, accel_rate * delta)
	move_and_slide()
	_update_stealth_noise_snapshot(moving)

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
	var controller_aim := _get_controller_aim_direction()
	if controller_aim != Vector2.ZERO:
		aim_direction = controller_aim
		visual_idle_direction = controller_aim
	elif arrow_aim_enabled:
		var keyboard_aim := _get_keyboard_aim_direction()
		if keyboard_aim != Vector2.ZERO:
			aim_direction = keyboard_aim
			visual_idle_direction = keyboard_aim
	else:
		var mouse_aim_vector := _get_world_mouse_position() - global_position
		if mouse_aim_vector.length_squared() > 0.0001:
			aim_direction = mouse_aim_vector.normalized()
	_apply_dynamic_weapon_socket_layout()
	var weapon_display_angle := _get_ranged_weapon_socket_rotation(aim_direction)
	
	# Rotate barrel instead of entire body
	if primary_weapon_socket and _is_using_ranged_weapon_visual() and not _is_facing_up(aim_direction):
		primary_weapon_socket.rotation = weapon_display_angle + deg_to_rad(current_recoil * 0.12)
	elif primary_weapon_socket:
		primary_weapon_socket.rotation = 0.0
	elif barrel:
		barrel.rotation = aim_direction.angle() + deg_to_rad(current_recoil * 0.12)


func _update_animation():
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames == null:
		_hide_modular_locomotion_layers()
		return
	if _is_primary_ranged_transition_presentation_active() or _is_primary_ranged_fire_presentation_active():
		if _is_primary_ranged_fire_presentation_active():
			var lower_base := _get_modular_lower_body_motion_base()
			if _can_reuse_modular_lower_body_for_current_loadout():
				_sync_modular_lower_body_locomotion(lower_base, movement_direction if velocity.length() > 0.01 else visual_idle_direction)
			else:
				_hide_modular_locomotion_layers()
		return
	if _portal_arrival_animation_active:
		if animated_sprite.animation != PORTAL_ARRIVAL_ANIMATION and animated_sprite.animation != PORTAL_ARRIVAL_DOWN_ANIMATION:
			_portal_arrival_animation_active = false
		else:
			return
	if _dodge_active:
		_play_dodge_animation()
		return
	if _dodge_recovery_active:
		_play_dodge_recovery_animation()
		return
	if _field_patch_active:
		_play_field_patch_use_presentation()
		return
	if _parry_neutral_lock_active:
		return

	# Check if currently firing or attacking (lock to cursor)
	var is_firing = _is_ranged_fire_animation_active() and not _is_primary_ranged_fire_recover_presentation_active()
	var current_animation := String(animated_sprite.animation)
	var is_melee_attack_anim := current_animation.begins_with("melee_2h_fast") or current_animation.begins_with("melee_2h_heavy")
	var is_attacking = _melee_active or _melee_fast_windup or (
		animated_sprite.is_playing()
		and (is_melee_attack_anim or current_animation.begins_with("attack") or current_animation.begins_with("unarmed_attack_fast_windup"))
	)
	var is_block_anim = _is_block_state_active()
	var is_reloading = _reload_active
	
	# If firing or attacking, use aim direction. Otherwise use movement direction.
	var is_moving = velocity.length() > 0
	var animation_dir: Vector2
	
	if _is_attack_turn_locked():
		animation_dir = attack_facing_dir
	elif is_firing or is_attacking or is_block_anim or is_reloading or _melee_recovery_active or _is_ranged_ready_active():
		animation_dir = aim_direction
	else:
		animation_dir = movement_direction if is_moving else visual_idle_direction
	
	# Determine direction suffix
	var direction_suffix := _get_direction_suffix(animation_dir)
	var facing_left := _is_facing_left(animation_dir)
	var facing_up := _is_facing_up(animation_dir)

	if _is_using_sidearm_ranged() and not is_reloading and _sync_modular_sidearm_presentation(is_firing):
		_update_idle_loop_tracking(false, "")
		return

	# Don't override attack animation while playing
	if is_attacking or is_block_anim or _melee_recovery_active or _is_equip_weapon_state_active():
		var active_animation_name := String(animated_sprite.animation)
		animated_sprite.flip_h = facing_left and not active_animation_name.ends_with("_left")
		if is_attacking and _sync_modular_action_domains():
			return
		if is_block_anim and _sync_modular_block_hold_movement_presentation():
			return
		if is_block_anim and _is_modular_block_active():
			return
		_hide_modular_locomotion_layers()
		return

	if is_reloading:
		_hide_modular_locomotion_layers()
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
	if is_firing and not facing_up and _is_using_ranged_weapon_visual() and animated_sprite.sprite_frames.has_animation(ranged_fire_anim):
		_hide_modular_locomotion_layers()
		animated_sprite.speed_scale = _get_body_animation_speed_scale(ranged_fire_anim)
		if animated_sprite.animation != ranged_fire_anim or not animated_sprite.is_playing():
			animated_sprite.play(ranged_fire_anim)
		_update_idle_loop_tracking(false, "")
		return
	animated_sprite.speed_scale = 1.0
	
	# Play walk or idle based on movement and direction
	if is_moving:
		if _is_ranged_ready_active() and _is_using_ranged_2h_primary():
			var ranged_ready_lower_base := "unarmed_run" if is_sprinting else "unarmed_walk"
			if _sync_modular_ranged_ready_movement_presentation(
				ranged_ready_lower_base,
				movement_direction,
				_get_modular_upper_locomotion_direction(animation_dir),
				1.0
			):
				_update_idle_loop_tracking(false, "ranged_2h_move_modular")
				return
		if is_sprinting:
			if not _is_ranged_ready_active() and _is_using_ranged_2h_primary() and (direction_suffix == "right" or direction_suffix == "left"):
				var ranged_run_anim := "ranged_2h_run_left" if direction_suffix == "left" and animated_sprite.sprite_frames.has_animation("ranged_2h_run_left") else "ranged_2h_run_right"
				if animated_sprite.sprite_frames.has_animation(ranged_run_anim):
					_hide_modular_locomotion_layers()
					animated_sprite.flip_h = facing_left and not ranged_run_anim.ends_with("_left")
					if animated_sprite.animation != ranged_run_anim:
						animated_sprite.play(ranged_run_anim)
					_update_idle_loop_tracking(false, "")
					return
			if _sync_modular_locomotion_layers("unarmed_run", movement_direction, _get_modular_upper_locomotion_direction(animation_dir)):
				_update_idle_loop_tracking(false, "")
				return
			var run_anim := String(AnimationResolver.resolve("unarmed_run", animation_dir, animated_sprite)) if _is_current_profile_unarmed() else "run_" + direction_suffix
			if animated_sprite.sprite_frames.has_animation(run_anim):
				animated_sprite.flip_h = facing_left and not run_anim.ends_with("_left")
				if animated_sprite.animation != run_anim:
					animated_sprite.play(run_anim)
				_update_idle_loop_tracking(false, "")
				return
			if animated_sprite.sprite_frames.has_animation("run_right"):
				_hide_modular_locomotion_layers()
				if animated_sprite.animation != "run_right":
					animated_sprite.play("run_right")
				_update_idle_loop_tracking(false, "")
				return
			_hide_modular_locomotion_layers()
			_update_idle_loop_tracking(false, "")
			return
		if _sync_modular_locomotion_layers("unarmed_walk", movement_direction, _get_modular_upper_locomotion_direction(animation_dir)):
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
			_hide_modular_locomotion_layers()
			if animated_sprite.animation != "walk_down_default":
				animated_sprite.play("walk_down_default")
			_update_idle_loop_tracking(false, "")
			return
		var walk_anim = "walk_" + direction_suffix
		if animated_sprite.sprite_frames.has_animation(walk_anim):
			_hide_modular_locomotion_layers()
			if animated_sprite.animation != walk_anim:
				animated_sprite.play(walk_anim)
			_update_idle_loop_tracking(false, "")
		else:
			# Fallback to right with flip
			_hide_modular_locomotion_layers()
			if animated_sprite.animation != "walk_right":
				animated_sprite.play("walk_right")
			_update_idle_loop_tracking(false, "")
	else:
		if _sync_modular_ranged_2h_stance_presentation(animation_dir):
			_update_idle_loop_tracking(true, "ranged_2h_stance_modular")
			return
		if _is_using_ranged_2h_primary() and _sync_modular_ranged_relaxed_presentation(animation_dir):
			_update_idle_loop_tracking(true, "ranged_2h_relaxed_modular")
			return
		if _is_current_profile_unarmed() and _sync_modular_locomotion_layers("unarmed_idle", visual_idle_direction, _get_modular_upper_locomotion_direction(animation_dir)):
			_update_idle_loop_tracking(true, "unarmed_idle")
			return
		var melee_body_stance_anim := _get_authored_melee_body_stance_animation()
		if _is_melee_loadout_active() and not melee_body_stance_anim.is_empty():
			var resolved_stance_anim := AnimationResolver.resolve(String(melee_body_stance_anim), animation_dir, animated_sprite)
			if animated_sprite.sprite_frames.has_animation(resolved_stance_anim):
				_hide_modular_locomotion_layers()
				animated_sprite.flip_h = facing_left and not String(resolved_stance_anim).ends_with("_left")
				if animated_sprite.animation != resolved_stance_anim:
					animated_sprite.play(resolved_stance_anim)
				_update_idle_loop_tracking(false, "")
				return
		var ranged_stance_anim := _get_weapon_animation_name(_get_active_ranged_weapon_definition(), "ranged_stance", &"ranged_2h_stance")
		if not facing_up and animated_sprite.sprite_frames.has_animation(ranged_stance_anim) and _is_using_ranged_weapon_visual():
			_hide_modular_locomotion_layers()
			if animated_sprite.animation != ranged_stance_anim:
				animated_sprite.play(ranged_stance_anim)
			_update_idle_loop_tracking(false, "")
			return
		var idle_anim = "idle_" + direction_suffix
		if _should_play_idle_long() and animated_sprite.sprite_frames.has_animation("idle_long"):
			idle_anim = "idle_long"
		if animated_sprite.sprite_frames.has_animation(idle_anim):
			_hide_modular_locomotion_layers()
			if animated_sprite.animation != idle_anim:
				animated_sprite.play(idle_anim)
			_update_idle_loop_tracking(true, idle_anim)
		else:
			# Fallback to right with flip
			_hide_modular_locomotion_layers()
			if animated_sprite.animation != "idle_right":
				animated_sprite.play("idle_right")
			_update_idle_loop_tracking(true, "idle_right")


func _sync_modular_locomotion_layers(base_animation: String, lower_direction: Vector2, upper_direction: Vector2 = Vector2.ZERO, speed_scale: float = 1.0) -> bool:
	if not modular_locomotion_layers_enabled:
		_hide_modular_locomotion_layers()
		return false
	if not _can_reuse_modular_lower_body_for_current_loadout():
		_hide_modular_locomotion_layers()
		return false

	var resolved_upper_direction := upper_direction
	if resolved_upper_direction.length_squared() <= 0.0001:
		resolved_upper_direction = lower_direction

	if not _sync_modular_lower_body_locomotion(base_animation, lower_direction, speed_scale):
		_hide_modular_locomotion_layers()
		return false

	if _is_current_profile_unarmed():
		if not _sync_modular_unarmed_upper_body_locomotion(base_animation, resolved_upper_direction, speed_scale):
			_hide_modular_locomotion_layers()
			return false
		if base_animation == "unarmed_run":
			_play_optional_modular_cape_animation("unarmed_run_cape", resolved_upper_direction, 12.0)
		else:
			_hide_modular_cape_layer()
	elif _is_ranged_ready_active() and _is_using_ranged_2h_primary():
		if not _sync_modular_ranged_ready_upper_layers(resolved_upper_direction):
			_hide_modular_locomotion_layers()
			return false
	elif _is_using_ranged_2h_primary():
		if not _sync_modular_ranged_relaxed_upper_layers(resolved_upper_direction):
			_hide_modular_locomotion_layers()
			return false
	else:
		_hide_modular_locomotion_layers()
		return false

	animated_sprite.visible = false
	return true


func _sync_modular_action_domains() -> bool:
	if not modular_locomotion_layers_enabled:
		return false
	if not _melee_active or _melee_attack_kind != "fast":
		return false
	if not _is_attack_profile_unarmed(_active_attack_profile):
		return false
	if modular_lower_body_sprite == null or modular_upper_body_sprite == null:
		return false
	if modular_lower_body_sprite.sprite_frames == null or modular_upper_body_sprite.sprite_frames == null:
		return false
	if _sync_modular_fast_attack_phase(&"strike"):
		return true
	var lower_base := _get_modular_lower_body_motion_base()
	var lower_direction := movement_direction if velocity.length() > 0.01 else visual_idle_direction
	if not _sync_modular_lower_body_layer(lower_base, lower_direction, 1.0):
		return false
	if not _sync_modular_upper_body_layer("unarmed_fast_strike_upper", _melee_forward, _get_melee_animation_speed_scale(_melee_attack_key), true):
		return false

	animated_sprite.visible = false
	return true


func _has_modular_fast_attack_layer(layer_sprite: AnimatedSprite2D, base_animation: String, direction: Vector2) -> bool:
	if layer_sprite == null or layer_sprite.sprite_frames == null:
		return false
	var resolved := AnimationResolver.resolve(base_animation, direction, layer_sprite)
	return _has_playable_sprite_animation(layer_sprite.sprite_frames, resolved)


func _sync_modular_fast_attack_layer(
	layer_sprite: AnimatedSprite2D,
	base_animation: String,
	direction: Vector2,
	speed_scale: float,
	restart_once: bool
) -> bool:
	if layer_sprite == null or layer_sprite.sprite_frames == null:
		return false
	var resolved := AnimationResolver.resolve(base_animation, direction, layer_sprite)
	if not _has_playable_sprite_animation(layer_sprite.sprite_frames, resolved):
		return false
	layer_sprite.visible = true
	layer_sprite.flip_h = false
	layer_sprite.speed_scale = speed_scale
	if restart_once:
		if layer_sprite.animation != resolved:
			layer_sprite.play(resolved)
	else:
		if layer_sprite.animation != resolved or not layer_sprite.is_playing():
			layer_sprite.play(resolved)
	return true


func _sync_modular_fast_attack_phase(phase: StringName) -> bool:
	if not modular_locomotion_layers_enabled:
		return false
	if modular_lower_body_sprite == null or modular_upper_body_sprite == null:
		return false
	if modular_lower_body_sprite.sprite_frames == null or modular_upper_body_sprite.sprite_frames == null:
		return false
	var lower_base := ""
	var upper_base := ""
	var fx_base := ""
	match phase:
		&"windup":
			lower_base = "unarmed_fast_windup_lower"
			upper_base = "unarmed_fast_windup_upper"
		&"strike":
			lower_base = "unarmed_fast_strike_lower"
			upper_base = "unarmed_fast_strike_upper"
			fx_base = "unarmed_fast_strike_fx_modular"
		&"recovery":
			lower_base = "unarmed_fast_recovery_lower"
			upper_base = "unarmed_fast_recovery_upper"
		_:
			return false
	if not _has_modular_fast_attack_layer(modular_lower_body_sprite, lower_base, _melee_forward):
		return false
	if not _has_modular_fast_attack_layer(modular_upper_body_sprite, upper_base, _melee_forward):
		return false
	var speed := _get_melee_animation_speed_scale(_melee_attack_key)
	var restart_once := phase == &"windup" or phase == &"strike" or phase == &"recovery"
	if not _sync_modular_fast_attack_layer(modular_lower_body_sprite, lower_base, _melee_forward, speed, restart_once):
		return false
	if not _sync_modular_fast_attack_layer(modular_upper_body_sprite, upper_base, _melee_forward, speed, restart_once):
		return false
	_modular_lower_action_animation = AnimationResolver.resolve(lower_base, _melee_forward, modular_lower_body_sprite)
	_modular_upper_action_animation = AnimationResolver.resolve(upper_base, _melee_forward, modular_upper_body_sprite)
	_modular_upper_fx_action_animation = &""
	if not fx_base.is_empty():
		if _sync_modular_fast_attack_layer(modular_upper_fx_sprite, fx_base, _melee_forward, speed, restart_once):
			_modular_upper_fx_action_animation = AnimationResolver.resolve(fx_base, _melee_forward, modular_upper_fx_sprite)
		else:
			if modular_upper_fx_sprite:
				modular_upper_fx_sprite.visible = false
			if not _warned_missing_modular_fast_attack_fx:
				_warned_missing_modular_fast_attack_fx = true
				push_warning("Missing modular unarmed fast strike upper_fx for direction; body layers will play without FX.")
	elif modular_upper_fx_sprite:
		modular_upper_fx_sprite.visible = false
	animated_sprite.visible = false
	return true


func _get_modular_lower_body_motion_base() -> String:
	if velocity.length() <= 0.01:
		return "unarmed_idle"
	if is_sprinting:
		return "unarmed_run"
	return "unarmed_walk"


func _get_modular_upper_locomotion_direction(fallback_direction: Vector2) -> Vector2:
	if _is_ranged_ready_active() and aim_direction.length_squared() > 0.0001:
		return aim_direction.normalized()
	if fallback_direction.length_squared() > 0.0001:
		return fallback_direction.normalized()
	if visual_idle_direction.length_squared() > 0.0001:
		return visual_idle_direction.normalized()
	return Vector2.DOWN


func _sync_modular_lower_body_locomotion(action_name: String, direction: Vector2, speed_scale: float = 1.0) -> bool:
	if not _can_reuse_modular_lower_body_for_current_loadout():
		return false
	return _sync_modular_lower_body_layer(action_name, direction, speed_scale)


func _sync_modular_unarmed_upper_body_locomotion(action_name: String, direction: Vector2, speed_scale: float = 1.0) -> bool:
	if not _is_current_profile_unarmed():
		return false
	return _sync_modular_upper_body_layer(action_name, direction, speed_scale, false)


func _sync_modular_ranged_ready_upper_layers(direction: Vector2) -> bool:
	if not modular_locomotion_layers_enabled or not _is_ranged_ready_active() or not _is_using_ranged_2h_primary():
		return false
	if modular_upper_body_sprite == null or modular_upper_body_sprite.sprite_frames == null:
		return false
	var resolved_direction := direction
	if resolved_direction.length_squared() <= 0.0001:
		resolved_direction = aim_direction if aim_direction.length_squared() > 0.0001 else visual_idle_direction
	if resolved_direction.length_squared() <= 0.0001:
		resolved_direction = Vector2.RIGHT
	if not _sync_modular_upper_body_layer("ranged_2h_stance_modular", resolved_direction, 1.0, false):
		return false
	if not _sync_modular_ranged_weapon_layer(resolved_direction, "ranged_2h_stance_modular"):
		return false
	if primary_weapon_sprite != null:
		primary_weapon_sprite.visible = false
	if ranged_fx_overlay_sprite != null:
		ranged_fx_overlay_sprite.visible = false
	_hide_modular_cape_layer()
	return true


func _sync_modular_ranged_relaxed_upper_layers(direction: Vector2) -> bool:
	if not modular_locomotion_layers_enabled or not _is_using_ranged_2h_primary():
		return false
	if modular_upper_body_sprite == null or modular_upper_body_sprite.sprite_frames == null:
		return false
	var resolved_direction := direction
	if resolved_direction.length_squared() <= 0.0001:
		resolved_direction = visual_idle_direction if visual_idle_direction.length_squared() > 0.0001 else Vector2.RIGHT
	if not _sync_modular_upper_body_layer("ranged_2h_relaxed_modular", resolved_direction, 1.0, false):
		return false
	if not _sync_modular_ranged_weapon_layer(resolved_direction, "ranged_2h_relaxed_modular"):
		return false
	if primary_weapon_sprite != null:
		primary_weapon_sprite.visible = false
	if ranged_fx_overlay_sprite != null:
		ranged_fx_overlay_sprite.visible = false
	_hide_modular_cape_layer()
	return true


func _can_reuse_modular_lower_body_for_current_loadout() -> bool:
	if not modular_locomotion_layers_enabled:
		return false
	if modular_lower_body_sprite == null or modular_lower_body_sprite.sprite_frames == null:
		return false
	if _is_current_profile_unarmed():
		return modular_upper_body_sprite != null and modular_upper_body_sprite.sprite_frames != null
	if _is_ranged_ready_active() and _is_using_ranged_2h_primary():
		return _has_modular_ranged_ready_upper_stack()
	if _is_using_ranged_2h_primary():
		return _has_modular_ranged_relaxed_upper_stack()
	return false


func _has_modular_ranged_ready_upper_stack() -> bool:
	if modular_upper_body_sprite == null or modular_upper_body_sprite.sprite_frames == null:
		return false
	if modular_sidearm_sprite == null or modular_sidearm_sprite.sprite_frames == null:
		return false
	var direction := aim_direction if aim_direction.length_squared() > 0.0001 else visual_idle_direction
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	var upper_animation := AnimationResolver.resolve("ranged_2h_stance_modular", direction, modular_upper_body_sprite)
	if not _has_playable_sprite_animation(modular_upper_body_sprite.sprite_frames, upper_animation):
		return false
	var weapon_animation := AnimationResolver.resolve("ranged_2h_stance_modular", direction, modular_sidearm_sprite)
	return _has_playable_sprite_animation(modular_sidearm_sprite.sprite_frames, weapon_animation)


func _has_modular_ranged_relaxed_upper_stack() -> bool:
	if modular_upper_body_sprite == null or modular_upper_body_sprite.sprite_frames == null:
		return false
	if modular_sidearm_sprite == null or modular_sidearm_sprite.sprite_frames == null:
		return false
	var direction := visual_idle_direction if visual_idle_direction.length_squared() > 0.0001 else Vector2.RIGHT
	var upper_animation := AnimationResolver.resolve("ranged_2h_relaxed_modular", direction, modular_upper_body_sprite)
	if not _has_playable_sprite_animation(modular_upper_body_sprite.sprite_frames, upper_animation):
		return false
	var weapon_animation := AnimationResolver.resolve("ranged_2h_relaxed_modular", direction, modular_sidearm_sprite)
	return _has_playable_sprite_animation(modular_sidearm_sprite.sprite_frames, weapon_animation)


func _sync_modular_sidearm_presentation(_is_firing: bool) -> bool:
	if not modular_locomotion_layers_enabled:
		return false
	if modular_lower_body_sprite == null or modular_upper_body_sprite == null or modular_sidearm_sprite == null or modular_upper_fx_sprite == null:
		return false
	if _sidearm_action_phase in [&"drawing", &"firing"] and _is_sidearm_action_finished():
		_sidearm_action_phase = &"held"
		_sidearm_action_phase_started = false
		_sidearm_draw_active = false
	var firing := _sidearm_action_phase == &"firing"
	var holding := _sidearm_action_phase == &"held"
	var action_direction := aim_direction if holding else _sidearm_action_direction
	var action := "fire" if firing else "draw"
	var start_action := not holding and not _sidearm_action_phase_started
	if not _sync_sidearm_action_sprite(modular_lower_body_sprite, "sidearm_%s_lower" % action, action_direction, holding, start_action):
		return false
	if not _sync_sidearm_action_sprite(modular_upper_body_sprite, "sidearm_%s_upper" % action, action_direction, holding, start_action):
		return false
	if not _sync_sidearm_action_sprite(modular_sidearm_sprite, "sidearm_%s" % action, action_direction, holding, start_action):
		return false
	_sync_sidearm_action_sprite(modular_upper_fx_sprite, "sidearm_%s_fx" % action, action_direction, holding, start_action)
	if start_action:
		_sidearm_action_phase_started = true
	animated_sprite.visible = false
	return true


func _sync_modular_ranged_2h_stance_presentation(direction: Vector2) -> bool:
	if not modular_locomotion_layers_enabled or not _is_ranged_ready_active() or not _is_using_ranged_2h_primary():
		return false
	if _reload_active or _is_ranged_fire_animation_active():
		return false
	if not _sync_modular_locomotion_layers(_get_modular_lower_body_motion_base(), movement_direction if velocity.length() > 0.01 else visual_idle_direction, direction, 1.0):
		return false
	if primary_weapon_sprite:
		primary_weapon_sprite.visible = false
	if ranged_fx_overlay_sprite:
		ranged_fx_overlay_sprite.visible = false
	return true


func _sync_modular_ranged_relaxed_presentation(direction: Vector2) -> bool:
	if not modular_locomotion_layers_enabled or not _is_using_ranged_2h_primary():
		return false
	if _reload_active or _is_ranged_fire_animation_active():
		return false
	if not _sync_modular_locomotion_layers(_get_modular_lower_body_motion_base(), movement_direction if velocity.length() > 0.01 else visual_idle_direction, direction, 1.0):
		return false
	if primary_weapon_sprite:
		primary_weapon_sprite.visible = false
	if ranged_fx_overlay_sprite:
		ranged_fx_overlay_sprite.visible = false
	return true


func _sync_modular_ranged_ready_movement_presentation(
	base_animation: String,
	lower_direction: Vector2,
	upper_direction: Vector2,
	speed_scale: float = 1.0
) -> bool:
	if not modular_locomotion_layers_enabled:
		return false
	if not _is_ranged_ready_active() or not _is_using_ranged_2h_primary():
		return false
	if _reload_active or _is_ranged_fire_animation_active():
		return false
	if modular_lower_body_sprite == null or modular_upper_body_sprite == null or modular_sidearm_sprite == null:
		return false
	if modular_lower_body_sprite.sprite_frames == null or modular_upper_body_sprite.sprite_frames == null or modular_sidearm_sprite.sprite_frames == null:
		return false

	var resolved_upper_direction := upper_direction
	if resolved_upper_direction.length_squared() <= 0.0001 and aim_direction.length_squared() > 0.0001:
		resolved_upper_direction = aim_direction.normalized()
	if resolved_upper_direction.length_squared() <= 0.0001:
		resolved_upper_direction = lower_direction
	if resolved_upper_direction.length_squared() <= 0.0001:
		resolved_upper_direction = visual_idle_direction
	if resolved_upper_direction.length_squared() <= 0.0001:
		resolved_upper_direction = Vector2.DOWN

	if not _sync_modular_lower_body_layer(base_animation, lower_direction, speed_scale):
		_hide_modular_locomotion_layers()
		return false
	if not _sync_modular_upper_body_layer("ranged_2h_stance_modular", resolved_upper_direction, 1.0, false):
		_hide_modular_locomotion_layers()
		return false
	if not _sync_modular_ranged_weapon_layer(resolved_upper_direction, "ranged_2h_stance_modular"):
		_hide_modular_locomotion_layers()
		return false

	animated_sprite.visible = false
	if primary_weapon_sprite:
		primary_weapon_sprite.visible = false
	if ranged_fx_overlay_sprite:
		ranged_fx_overlay_sprite.visible = false
	if modular_upper_fx_sprite:
		modular_upper_fx_sprite.visible = false
	_hide_modular_cape_layer()
	return true


func _sync_modular_ranged_weapon_layer(direction: Vector2, base_animation: String) -> bool:
	if modular_sidearm_sprite == null or modular_sidearm_sprite.sprite_frames == null:
		return false
	var animation := AnimationResolver.resolve(base_animation, direction, modular_sidearm_sprite)
	if not _has_playable_sprite_animation(modular_sidearm_sprite.sprite_frames, animation):
		return false
	modular_sidearm_sprite.visible = true
	modular_sidearm_sprite.flip_h = false
	modular_sidearm_sprite.speed_scale = 1.0
	if modular_sidearm_sprite.animation != animation or not modular_sidearm_sprite.is_playing():
		modular_sidearm_sprite.play(animation)
	return true


func _is_primary_ranged_fire_presentation_active() -> bool:
	return _primary_ranged_action_phase == &"firing"


func _is_primary_ranged_aim_presentation_active() -> bool:
	return _primary_ranged_action_phase == &"aiming"


func _is_primary_ranged_lower_presentation_active() -> bool:
	return _primary_ranged_action_phase == &"lowering"


func _is_primary_ranged_transition_presentation_active() -> bool:
	return _is_primary_ranged_aim_presentation_active() or _is_primary_ranged_lower_presentation_active()


func _tick_primary_ranged_action_presentation(delta: float) -> void:
	if not (_is_primary_ranged_transition_presentation_active() or _is_primary_ranged_fire_presentation_active()):
		return

	_primary_ranged_action_timer -= delta
	if _primary_ranged_action_timer > 0.0:
		return

	_primary_ranged_action_phase = &"recover" if _is_primary_ranged_fire_presentation_active() else &""
	_primary_ranged_action_timer = 0.0
	_update_animation()


func _is_primary_ranged_fire_recover_presentation_active() -> bool:
	return _primary_ranged_action_phase == &"recover"


func _begin_modular_primary_ranged_fire_presentation() -> bool:
	if not modular_primary_ranged_fire_enabled:
		return false
	if not modular_locomotion_layers_enabled:
		return false
	if _is_using_sidearm_ranged():
		return false
	if not _is_using_ranged_2h_primary():
		return false
	if modular_lower_body_sprite == null and modular_upper_body_sprite == null and modular_sidearm_sprite == null and modular_upper_fx_sprite == null:
		return false

	var fire_dir := aim_direction
	if fire_dir.length_squared() <= 0.0001:
		fire_dir = visual_idle_direction
	if fire_dir.length_squared() <= 0.0001:
		fire_dir = Vector2.RIGHT

	var suffix := _primary_ranged_fire_suffix_for_direction(fire_dir)
	_primary_ranged_action_suffix = suffix
	if not _can_reuse_modular_lower_body_for_current_loadout():
		return false

	var longest_duration := 0.0
	var any_layer_played := false

	var lower_base := _get_modular_lower_body_motion_base()
	var lower_direction := movement_direction if velocity.length() > 0.01 else visual_idle_direction
	if lower_direction.length_squared() <= 0.0001:
		lower_direction = fire_dir
	if not _sync_modular_lower_body_locomotion(lower_base, lower_direction):
		return false

	var upper_result := _play_first_available_modular_fire_animation(
		modular_upper_body_sprite,
		_primary_ranged_fire_candidates(&"upper", suffix),
		modular_primary_ranged_fire_fps
	)
	any_layer_played = any_layer_played or bool(upper_result.get("played", false))
	longest_duration = max(longest_duration, float(upper_result.get("duration", 0.0)))

	var weapon_result := _play_first_available_modular_fire_animation(
		modular_sidearm_sprite,
		_primary_ranged_fire_candidates(&"weapon", suffix),
		modular_primary_ranged_fire_fps
	)
	any_layer_played = any_layer_played or bool(weapon_result.get("played", false))
	longest_duration = max(longest_duration, float(weapon_result.get("duration", 0.0)))

	var fx_result := _play_first_available_modular_fire_animation(
		modular_upper_fx_sprite,
		_primary_ranged_fire_candidates(&"fx", suffix),
		modular_primary_ranged_fire_fps
	)
	any_layer_played = any_layer_played or bool(fx_result.get("played", false))
	longest_duration = max(longest_duration, float(fx_result.get("duration", 0.0)))

	if not any_layer_played:
		return false

	_primary_ranged_action_phase = &"firing"
	_primary_ranged_action_timer = max(0.04, longest_duration + modular_primary_ranged_fire_recover_hold_sec)
	_hide_legacy_primary_ranged_presentation_for_modular_fire()
	_hide_modular_cape_layer()
	return true


func _begin_modular_primary_ranged_aim_presentation() -> bool:
	if not modular_primary_ranged_fire_enabled:
		return false
	if not modular_locomotion_layers_enabled:
		return false
	if _is_using_sidearm_ranged():
		return false
	if not _is_ranged_ready_active() or not _is_using_ranged_2h_primary():
		return false
	if _reload_active or _is_ranged_fire_animation_active():
		return false
	if modular_lower_body_sprite == null or modular_upper_body_sprite == null or modular_sidearm_sprite == null:
		return false
	if modular_lower_body_sprite.sprite_frames == null or modular_upper_body_sprite.sprite_frames == null or modular_sidearm_sprite.sprite_frames == null:
		return false

	var action_direction := aim_direction
	if action_direction.length_squared() <= 0.0001:
		action_direction = visual_idle_direction
	if action_direction.length_squared() <= 0.0001:
		action_direction = Vector2.RIGHT

	var lower_animation := AnimationResolver.resolve("ranged_2h_aim_modular", action_direction, modular_lower_body_sprite)
	var upper_animation := AnimationResolver.resolve("ranged_2h_aim_modular", action_direction, modular_upper_body_sprite)
	var weapon_animation := AnimationResolver.resolve("ranged_2h_aim_modular", action_direction, modular_sidearm_sprite)
	if not _has_playable_sprite_animation(modular_lower_body_sprite.sprite_frames, lower_animation):
		return false
	if not _has_playable_sprite_animation(modular_upper_body_sprite.sprite_frames, upper_animation):
		return false
	if not _has_playable_sprite_animation(modular_sidearm_sprite.sprite_frames, weapon_animation):
		return false

	var longest_duration := 0.0
	var lower_result := _play_modular_action_animation(modular_lower_body_sprite, "ranged_2h_aim_modular", action_direction, modular_primary_ranged_aim_fps)
	longest_duration = max(longest_duration, float(lower_result.get("duration", 0.0)))

	var upper_result := _play_modular_action_animation(modular_upper_body_sprite, "ranged_2h_aim_modular", action_direction, modular_primary_ranged_aim_fps)
	longest_duration = max(longest_duration, float(upper_result.get("duration", 0.0)))

	var weapon_result := _play_modular_action_animation(modular_sidearm_sprite, "ranged_2h_aim_modular", action_direction, modular_primary_ranged_aim_fps)
	longest_duration = max(longest_duration, float(weapon_result.get("duration", 0.0)))
	var cape_result := _play_optional_modular_cape_animation("ranged_2h_aim_cape", action_direction, modular_primary_ranged_aim_fps)
	longest_duration = max(longest_duration, float(cape_result.get("duration", 0.0)))

	_primary_ranged_action_phase = &"aiming"
	_primary_ranged_action_timer = max(0.04, longest_duration)
	_hide_legacy_primary_ranged_presentation_for_modular_fire()
	if modular_upper_fx_sprite:
		modular_upper_fx_sprite.visible = false
	return true


func _begin_modular_primary_ranged_lower_presentation() -> bool:
	if not modular_primary_ranged_fire_enabled or not modular_locomotion_layers_enabled:
		return false
	if _is_using_sidearm_ranged() or not _is_using_ranged_2h_primary():
		return false
	if modular_lower_body_sprite == null or modular_upper_body_sprite == null or modular_sidearm_sprite == null:
		return false

	var action_direction := aim_direction
	if action_direction.length_squared() <= 0.0001:
		action_direction = visual_idle_direction
	if action_direction.length_squared() <= 0.0001:
		action_direction = Vector2.RIGHT

	var longest_duration := 0.0
	for sprite in [modular_lower_body_sprite, modular_upper_body_sprite, modular_sidearm_sprite]:
		var result := _play_modular_action_animation_backwards(
			sprite,
			"ranged_2h_aim_modular",
			action_direction,
			modular_primary_ranged_aim_fps
		)
		if not bool(result.get("played", false)):
			return false
		longest_duration = max(longest_duration, float(result.get("duration", 0.0)))

	var cape_result := _play_optional_modular_cape_animation_backwards(
		"ranged_2h_aim_cape",
		action_direction,
		modular_primary_ranged_aim_fps
	)
	longest_duration = max(longest_duration, float(cape_result.get("duration", 0.0)))
	_primary_ranged_action_phase = &"lowering"
	_primary_ranged_action_timer = max(0.04, longest_duration)
	_hide_legacy_primary_ranged_presentation_for_modular_fire()
	if modular_upper_fx_sprite:
		modular_upper_fx_sprite.visible = false
	return true


func _end_modular_primary_ranged_fire_presentation() -> void:
	_primary_ranged_action_phase = &""
	_primary_ranged_action_timer = 0.0


func _primary_ranged_fire_candidates(layer_key: StringName, suffix: StringName) -> Array[StringName]:
	var dir := String(suffix)
	match layer_key:
		&"lower":
			return [
				StringName("ranged_2h_fire_lower_%s" % dir),
				StringName("primary_ranged_fire_lower_%s" % dir),
				StringName("ranged_fire_lower_%s" % dir),
				StringName("ranged_2h_fire_modular_%s" % dir),
			]
		&"upper":
			return [
				StringName("ranged_2h_fire_upper_%s" % dir),
				StringName("primary_ranged_fire_upper_%s" % dir),
				StringName("ranged_fire_upper_%s" % dir),
				StringName("ranged_2h_fire_modular_%s" % dir),
			]
		&"weapon":
			return [
				StringName("ranged_2h_fire_weapon_%s" % dir),
				StringName("primary_ranged_fire_weapon_%s" % dir),
				StringName("ranged_fire_weapon_%s" % dir),
				StringName("ranged_2h_fire_modular_%s" % dir),
				StringName("ranged_2h_fire_%s" % dir),
			]
		&"fx":
			return [
				StringName("ranged_2h_fire_fx_%s" % dir),
				StringName("primary_ranged_fire_fx_%s" % dir),
				StringName("ranged_fire_fx_%s" % dir),
			]
	return []


func _play_first_available_modular_fire_animation(
	sprite: AnimatedSprite2D,
	candidates: Array[StringName],
	target_fps: float
) -> Dictionary:
	if sprite == null or sprite.sprite_frames == null:
		return {"played": false, "duration": 0.0}

	for animation_name in candidates:
		if not _has_playable_sprite_animation(sprite.sprite_frames, animation_name):
			continue

		var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
		sprite.visible = true
		sprite.flip_h = false
		sprite.animation = animation_name
		sprite.frame = 0

		var source_speed := sprite.sprite_frames.get_animation_speed(animation_name)
		if source_speed <= 0.0:
			source_speed = target_fps

		sprite.speed_scale = target_fps / max(0.01, source_speed)
		sprite.play(animation_name)

		var duration: float = float(frame_count) / max(1.0, target_fps)
		return {"played": true, "duration": duration, "animation": animation_name}

	return {"played": false, "duration": 0.0}


func _play_modular_action_animation(
	sprite: AnimatedSprite2D,
	base_animation: String,
	direction: Vector2,
	target_fps: float
) -> Dictionary:
	if sprite == null or sprite.sprite_frames == null:
		return {"played": false, "duration": 0.0}
	var animation_name := AnimationResolver.resolve(base_animation, direction, sprite)
	if not _has_playable_sprite_animation(sprite.sprite_frames, animation_name):
		return {"played": false, "duration": 0.0}

	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	sprite.visible = true
	sprite.flip_h = false
	sprite.animation = animation_name
	sprite.frame = 0

	var source_speed := sprite.sprite_frames.get_animation_speed(animation_name)
	if source_speed <= 0.0:
		source_speed = target_fps
	sprite.speed_scale = target_fps / max(0.01, source_speed)
	sprite.play(animation_name)

	var duration: float = float(frame_count) / max(1.0, target_fps)
	return {"played": true, "duration": duration, "animation": animation_name}


func _play_modular_action_animation_backwards(
	sprite: AnimatedSprite2D,
	base_animation: String,
	direction: Vector2,
	target_fps: float
) -> Dictionary:
	var result := _play_modular_action_animation(sprite, base_animation, direction, target_fps)
	if not bool(result.get("played", false)):
		return result
	var animation_name: StringName = result.get("animation", &"")
	sprite.play_backwards(animation_name)
	return result


func _play_optional_modular_cape_animation(base_animation: String, direction: Vector2, target_fps: float) -> Dictionary:
	if not modular_primary_ranged_aim_cape_enabled:
		_hide_modular_cape_layer()
		return {"played": false, "duration": 0.0}
	# Cape art only exists for upward-facing directions (up, up_left, up_right).
	# Hide the cape when running in directions without authored art to avoid
	# showing the wrong directional sprite from the fallback animation.
	var dir_suffix := AnimationResolver._get_direction_suffix(direction)
	if dir_suffix != "up" and dir_suffix != "up_left" and dir_suffix != "up_right":
		_hide_modular_cape_layer()
		return {"played": false, "duration": 0.0}
	var result := _play_modular_action_animation(modular_cape_sprite, base_animation, direction, target_fps)
	if not bool(result.get("played", false)):
		_hide_modular_cape_layer()
	return result


func _play_optional_modular_cape_animation_backwards(base_animation: String, direction: Vector2, target_fps: float) -> Dictionary:
	if not modular_primary_ranged_aim_cape_enabled:
		_hide_modular_cape_layer()
		return {"played": false, "duration": 0.0}
	var result := _play_modular_action_animation_backwards(modular_cape_sprite, base_animation, direction, target_fps)
	if not bool(result.get("played", false)):
		_hide_modular_cape_layer()
	return result


func _play_field_patch_use_presentation() -> bool:
	var direction := aim_direction if aim_direction.length_squared() > 0.0001 else visual_idle_direction
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT

	var lower_played := _sync_field_patch_action_layer(modular_lower_body_sprite, "field_patch_use_lower", direction, 11.2)
	var upper_played := _sync_field_patch_action_layer(modular_upper_body_sprite, "field_patch_use_upper", direction, 11.2)
	_sync_field_patch_action_layer(modular_upper_fx_sprite, "field_patch_use_fx", direction, 11.2)
	if lower_played and upper_played:
		animated_sprite.visible = false
		if modular_sidearm_sprite:
			modular_sidearm_sprite.visible = false
		_hide_modular_cape_layer()
		return true

	_hide_modular_locomotion_layers()
	if not _field_patch_missing_presentation_warning_emitted:
		_field_patch_missing_presentation_warning_emitted = true
		push_warning("[FieldPatch] Production use animation missing; using fallback locomotion presentation.")
	return false


func _sync_field_patch_action_layer(sprite: AnimatedSprite2D, base_animation: String, direction: Vector2, target_fps: float) -> bool:
	if sprite == null or sprite.sprite_frames == null:
		return false
	var animation_name := AnimationResolver.resolve(base_animation, direction, sprite)
	if not _has_playable_sprite_animation(sprite.sprite_frames, animation_name):
		sprite.visible = false
		return false

	sprite.visible = true
	sprite.flip_h = false
	var source_speed := sprite.sprite_frames.get_animation_speed(animation_name)
	if source_speed <= 0.0:
		source_speed = target_fps
	sprite.speed_scale = target_fps / max(0.01, source_speed)
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)
	return true


func _hide_modular_cape_layer() -> void:
	if modular_cape_sprite:
		modular_cape_sprite.visible = false
		modular_cape_sprite.stop()


func _primary_ranged_fire_suffix_for_direction(direction: Vector2) -> StringName:
	if direction.length_squared() <= 0.0001:
		return &"right"
	return StringName(_get_direction_suffix(direction.normalized()))


func _hide_legacy_primary_ranged_presentation_for_modular_fire() -> void:
	if animated_sprite != null:
		animated_sprite.visible = false
	if primary_weapon_sprite != null:
		primary_weapon_sprite.visible = false
	if ranged_fx_overlay_sprite != null:
		ranged_fx_overlay_sprite.visible = false


func _sync_sidearm_action_sprite(sprite: AnimatedSprite2D, base: String, direction: Vector2, hold_last_frame: bool, start_action: bool = false) -> bool:
	if sprite == null or sprite.sprite_frames == null:
		return false
	var animation := _resolve_sidearm_directional_animation(base, direction, sprite)
	if not _has_playable_sprite_animation(sprite.sprite_frames, animation):
		sprite.visible = false
		return false
	sprite.visible = true
	sprite.flip_h = false
	sprite.speed_scale = 1.0
	if hold_last_frame:
		sprite.stop()
		sprite.animation = animation
		sprite.frame = sprite.sprite_frames.get_frame_count(animation) - 1
	elif start_action or sprite.animation != animation:
		sprite.play(animation)
	return true


func _is_sidearm_action_finished() -> bool:
	var expected_prefix := "sidearm_fire" if _sidearm_action_phase == &"firing" else "sidearm_draw"
	for sprite in [modular_lower_body_sprite, modular_upper_body_sprite, modular_sidearm_sprite]:
		if sprite == null or not String(sprite.animation).begins_with(expected_prefix):
			return false
		if sprite.is_playing():
			return false
	return true


func _resolve_sidearm_directional_animation(base: String, direction: Vector2, sprite: AnimatedSprite2D) -> StringName:
	var vertical := "up" if direction.y < 0.0 else "down"
	var horizontal := "left" if direction.x < 0.0 else "right"
	var candidate := StringName("%s_%s_%s" % [base, vertical, horizontal])
	if sprite != null and sprite.sprite_frames != null and _has_playable_sprite_animation(sprite.sprite_frames, candidate):
		return candidate
	return StringName(base)


func _sync_modular_lower_body_layer(base_animation: String, direction: Vector2, speed_scale: float) -> bool:
	if modular_lower_body_sprite == null or modular_lower_body_sprite.sprite_frames == null:
		return false
	var lower_animation := _resolve_modular_lower_body_locomotion_animation(base_animation, direction)
	if not _has_playable_sprite_animation(modular_lower_body_sprite.sprite_frames, lower_animation):
		return false
	modular_lower_body_sprite.visible = true
	modular_lower_body_sprite.flip_h = false
	modular_lower_body_sprite.speed_scale = speed_scale
	if modular_lower_body_sprite.animation != lower_animation or not modular_lower_body_sprite.is_playing():
		modular_lower_body_sprite.play(lower_animation)
	return true


func _resolve_modular_lower_body_locomotion_animation(base_animation: String, direction: Vector2) -> StringName:
	var frames: SpriteFrames = modular_lower_body_sprite.sprite_frames if modular_lower_body_sprite != null else null
	if frames == null:
		return StringName(base_animation)
	var direction_suffix := _get_direction_suffix(direction)
	var exact_animation := StringName("%s_%s" % [base_animation, direction_suffix])
	if _has_playable_sprite_animation(frames, exact_animation):
		return exact_animation
	if base_animation == "unarmed_walk":
		for fallback_base in ["unarmed_run", "unarmed_idle"]:
			var fallback_animation := StringName("%s_%s" % [fallback_base, direction_suffix])
			if _has_playable_sprite_animation(frames, fallback_animation):
				return fallback_animation
	if _has_playable_sprite_animation(frames, StringName(base_animation)):
		return StringName(base_animation)
	var direct_animation := AnimationResolver.resolve(base_animation, direction, modular_lower_body_sprite)
	if _has_playable_sprite_animation(frames, direct_animation):
		return direct_animation
	return direct_animation


func _sync_modular_upper_body_layer(base_animation: String, direction: Vector2, speed_scale: float, action_once: bool) -> bool:
	if modular_upper_body_sprite == null or modular_upper_body_sprite.sprite_frames == null:
		return false
	var upper_animation := AnimationResolver.resolve(base_animation, direction, modular_upper_body_sprite)
	if not _has_playable_sprite_animation(modular_upper_body_sprite.sprite_frames, upper_animation):
		return false
	modular_upper_body_sprite.visible = true
	modular_upper_body_sprite.flip_h = false
	modular_upper_body_sprite.speed_scale = speed_scale
	if action_once:
		if _modular_upper_action_animation != upper_animation:
			_modular_upper_action_animation = upper_animation
			modular_upper_body_sprite.play(upper_animation)
	else:
		_modular_upper_action_animation = &""
		if modular_upper_body_sprite.animation != upper_animation or not modular_upper_body_sprite.is_playing():
			modular_upper_body_sprite.play(upper_animation)
	return true


func _hide_modular_locomotion_layers() -> void:
	_modular_lower_action_animation = &""
	_modular_upper_action_animation = &""
	_modular_upper_fx_action_animation = &""
	_modular_sidearm_action_animation = &""
	_modular_sidearm_fx_animation = &""
	if animated_sprite:
		animated_sprite.visible = true
	if modular_lower_body_sprite:
		modular_lower_body_sprite.visible = false
	if modular_upper_body_sprite:
		modular_upper_body_sprite.visible = false
	if modular_sidearm_sprite:
		modular_sidearm_sprite.visible = false
	if modular_upper_fx_sprite:
		modular_upper_fx_sprite.visible = false
	_hide_modular_cape_layer()


func _clear_modular_upper_action_layer() -> void:
	_modular_upper_action_animation = &""
	if modular_upper_body_sprite:
		modular_upper_body_sprite.visible = false


func _clear_modular_fast_attack_layers() -> void:
	_modular_lower_action_animation = &""
	_modular_upper_action_animation = &""
	_modular_upper_fx_action_animation = &""
	if modular_lower_body_sprite:
		modular_lower_body_sprite.visible = false
		modular_lower_body_sprite.stop()
	if modular_upper_body_sprite:
		modular_upper_body_sprite.visible = false
		modular_upper_body_sprite.stop()
	if modular_upper_fx_sprite:
		modular_upper_fx_sprite.visible = false
		modular_upper_fx_sprite.stop()
	_hide_modular_cape_layer()


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
	elif angle >= 5*PI/8 and angle < 7*PI/8:
		return "down_left"
	elif angle >= -3*PI/8 and angle < -PI/8:
		return "up_right"
	elif angle >= -5*PI/8 and angle < -3*PI/8:
		return "up"
	elif angle >= -7*PI/8 and angle < -5*PI/8:
		return "up_left"
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


func _get_ranged_weapon_socket_rotation(dir: Vector2) -> float:
	if not _is_using_ranged_2h_primary():
		return _get_weapon_display_angle(dir)
	var aim_state := _get_weapon_aim_state()
	var raw_angle := _get_weapon_display_angle(dir)
	var limit := deg_to_rad(ranged_neutral_rotation_limit_degrees)
	if aim_state == &"up" or aim_state == &"down":
		limit = deg_to_rad(ranged_vertical_rotation_limit_degrees)
	return clampf(raw_angle, -limit, limit)


func _get_ranged_muzzle_origin(direction: Vector2 = Vector2.ZERO) -> Vector2:
	if _get_modular_ranged_muzzle_position(direction) != Vector2.INF:
		return global_position
	if primary_weapon_socket != null:
		return primary_weapon_socket.global_position
	return global_position


func _get_muzzle_obstruction(direction: Vector2, muzzle_position: Vector2) -> Dictionary:
	if direction.length_squared() <= 0.0001:
		return {}
	var from: Vector2 = _get_ranged_muzzle_origin(direction)
	var to: Vector2 = muzzle_position + direction.normalized() * max(0.0, ranged_muzzle_obstruction_margin)
	if from.distance_squared_to(to) <= 1.0:
		return {}
	var space_state := get_world_2d().direct_space_state
	if space_state == null:
		return {}
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = _get_ranged_fire_ray_exclusions()
	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		return {}
	var collider: Object = hit.get("collider", null)
	var terrain_provider := _find_terrain_ballistics_provider()
	if collider is Node and terrain_provider != null \
			and terrain_provider.has_method("is_terrain_collision_body") \
			and bool(terrain_provider.call("is_terrain_collision_body", collider as Node)) \
			and terrain_provider.has_method("can_trace_projectile"):
		var terrain_result: Variant = terrain_provider.call("can_trace_projectile", from, to)
		if terrain_result is Dictionary and bool((terrain_result as Dictionary).get("allowed", false)):
			return {}
	if _is_ranged_fire_blocker(collider):
		return hit
	return {}


func _get_ranged_fire_ray_exclusions() -> Array[RID]:
	var exclusions: Array[RID] = []
	exclusions.append(get_rid())
	if primary_weapon_socket is CollisionObject2D:
		exclusions.append((primary_weapon_socket as CollisionObject2D).get_rid())
	return exclusions


func _is_ranged_fire_blocker(collider: Object) -> bool:
	if collider == null:
		return false
	if collider == self:
		return false
	if not (collider is StaticBody2D):
		return false
	var node := collider as Node
	if node.is_in_group("player") or node.is_in_group("enemy") or node.is_in_group("enemies") or node.is_in_group("defense") or node.is_in_group("turret"):
		return false
	return true


func _spawn_ranged_impact_at(impact_position: Vector2) -> void:
	if impact_scene == null:
		return
	var parent = get_node_or_null("/root/GameRoot/World/Projectiles")
	var target = parent if parent != null else get_tree().current_scene
	var spark = impact_scene.instantiate()
	if spark == null:
		return
	target.add_child(spark)
	spark.global_position = impact_position


func _get_dev_observatory() -> Node:
	return get_node_or_null("/root/DevObservatory")


func _obs_log(kind: StringName, data: Dictionary = {}) -> void:
	var observatory := _get_dev_observatory()
	if observatory != null and observatory.has_method("log_event"):
		observatory.call("log_event", String(kind), data)


func _obs_increment(counter_name: StringName, amount: int = 1) -> void:
	var observatory := _get_dev_observatory()
	if observatory != null and observatory.has_method("increment"):
		observatory.call("increment", String(counter_name), amount)


func _obs_gauge(gauge_name: StringName, value: Variant) -> void:
	var observatory := _get_dev_observatory()
	if observatory != null and observatory.has_method("set_gauge"):
		observatory.call("set_gauge", String(gauge_name), value)


func _log_ranged_fire_failure(reason: StringName) -> void:
	_obs_increment(&"player_ranged_fire_failures", 1)
	_obs_log(&"player_ranged_fire_failed", {
		"reason": String(reason),
		"weapon": _get_active_weapon_state_key(),
		"position": global_position,
		"loaded_ammo": _get_current_loaded_ammo(),
		"reserve_ammo": _get_current_reserve_ammo(),
		"heat": weapon_heat_by_id.get(_get_active_weapon_state_key(), 0.0),
	})


func _instantiate_ranged_projectile(profile: Dictionary) -> Node:
	var scene_path := str(profile.get("projectile_scene", "res://game/actors/projectiles/bullet.tscn"))
	var scene := _load_packed_scene_from_path(scene_path, &"projectile_scene")
	if scene == null:
		scene = BULLET_SCENE
	return scene.instantiate()


func _load_projectile_impact_scene(scene_path: String, fallback: PackedScene) -> PackedScene:
	var scene := _load_packed_scene_from_path(scene_path, &"impact_scene")
	return scene if scene != null else fallback


func _load_projectile_sprite_frames(frames_path: String) -> SpriteFrames:
	var trimmed_path := frames_path.strip_edges()
	if trimmed_path.is_empty():
		return null
	if not ResourceLoader.exists(trimmed_path):
		_warn_ranged_config_once(StringName("missing_projectile_sprite_frames_%s" % trimmed_path), "[Operator] Missing projectile SpriteFrames: %s" % trimmed_path)
		return null
	var resource := load(trimmed_path)
	if resource is SpriteFrames:
		return resource as SpriteFrames
	_warn_ranged_config_once(StringName("invalid_projectile_sprite_frames_%s" % trimmed_path), "[Operator] Projectile visual path is not SpriteFrames: %s" % trimmed_path)
	return null


func _load_packed_scene_from_path(scene_path: String, warning_kind: StringName) -> PackedScene:
	var trimmed_path := scene_path.strip_edges()
	if trimmed_path.is_empty():
		return null
	if not ResourceLoader.exists(trimmed_path):
		_warn_ranged_config_once(StringName("%s_missing_%s" % [String(warning_kind), trimmed_path]), "[Operator] Configured %s cannot be loaded: %s" % [String(warning_kind), trimmed_path])
		return null
	var resource := load(trimmed_path)
	if resource is PackedScene:
		return resource as PackedScene
	_warn_ranged_config_once(StringName("%s_invalid_%s" % [String(warning_kind), trimmed_path]), "[Operator] Configured %s is not a PackedScene: %s" % [String(warning_kind), trimmed_path])
	return null


func _warn_ranged_config_once(key: StringName, message: String) -> void:
	if _ranged_config_warning_once.has(key):
		return
	_ranged_config_warning_once[key] = true
	push_warning(message)


func _dictionary_to_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value as Vector2
	if value is Dictionary:
		var dict := value as Dictionary
		return Vector2(float(dict.get("x", fallback.x)), float(dict.get("y", fallback.y)))
	return fallback


func _request_ranged_shot() -> void:
	if not _is_ranged_context_active():
		return
	if _reload_active:
		last_ranged_fire_failure = &"reloading"
		_log_ranged_fire_failure(last_ranged_fire_failure)
		return
	if _is_active_weapon_overheated():
		last_ranged_fire_failure = &"overheated"
		_log_ranged_fire_failure(last_ranged_fire_failure)
		return
	if not _has_loaded_ammo():
		last_ranged_fire_failure = &"reload_started" if _get_current_reserve_ammo() > 0 else &"no_ammo"
		_log_ranged_fire_failure(last_ranged_fire_failure)
		_try_start_reload()
		return
	if _is_using_sidearm_ranged():
		if _sidearm_action_phase != &"held":
			last_ranged_fire_failure = &"sidearm_not_held"
			_log_ranged_fire_failure(last_ranged_fire_failure)
			return
		_sidearm_action_phase = &"firing"
		_sidearm_action_phase_started = false
		_sidearm_action_direction = _get_attack_aim_direction()
	var profile := _get_current_ranged_profile()
	last_ranged_fire_failure = &""
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
	if not _is_using_sidearm_ranged():
		_begin_modular_primary_ranged_fire_presentation()
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
	spread *= _get_movement_spread_multiplier()
	spread *= _get_heat_spread_multiplier()
	# Apply cognitive accuracy bonus (bearing reduces spread)
	var cognitive := get_node_or_null("/root/CognitiveState")
	if cognitive != null and cognitive.has_method("get_player_accuracy_bonus"):
		var accuracy_bonus: float = float(cognitive.call("get_player_accuracy_bonus"))
		spread = max(0.0, spread - accuracy_bonus)
	var spread_rad := deg_to_rad(randf_range(-spread, spread))
	direction = direction.rotated(spread_rad)

	var bullet = _instantiate_ranged_projectile(profile)
	if bullet == null:
		return

	var spawn_position: Vector2 = _get_ranged_muzzle_position(direction)
	var muzzle_check := _get_muzzle_obstruction(direction, spawn_position)
	if not muzzle_check.is_empty():
		_spawn_ranged_impact_at(muzzle_check.get("position", spawn_position))
		current_recoil += float(profile.get("recoil_kick", 1.2)) * _get_heat_recoil_multiplier()
		_consume_ammo()
		_apply_heat_for_shot()
		_emit_weapon_noise(spawn_position)
		_spawn_muzzle_flash(direction)
		_apply_body_recoil_impulse(direction)
		_obs_increment(&"player_ranged_shots_blocked", 1)
		_obs_log(&"player_ranged_shot_blocked", {
			"weapon": _get_active_weapon_state_key(),
			"position": global_position,
			"muzzle": spawn_position,
			"impact": muzzle_check.get("position", spawn_position),
			"direction": direction,
			"spread_deg": spread,
			"loaded_ammo": _get_current_loaded_ammo(),
			"reserve_ammo": _get_current_reserve_ammo(),
		})
		_obs_gauge(&"player_loaded_ammo", _get_current_loaded_ammo())
		_obs_gauge(&"player_reserve_ammo", _get_current_reserve_ammo())
		return
	if bullet.has_method("set_direction"):
		bullet.set_direction(direction)
	bullet.speed = float(profile.get("speed", 780.0))
	bullet.damage = float(profile.get("damage", 16.0))
	bullet.max_range_px = float(profile.get("max_range_px", 320.0))
	bullet.falloff_start_px = float(profile.get("falloff_start_px", 180.0))
	bullet.falloff_end_px = float(profile.get("falloff_end_px", 320.0))
	bullet.min_damage_multiplier = float(profile.get("min_damage_multiplier", 0.5))
	bullet.bullet_radius = float(profile.get("radius", 3.0))
	bullet.bullet_color = profile.get("color", Color(1.0, 0.9, 0.35, 1.0))
	bullet.impact_scene = _load_projectile_impact_scene(str(profile.get("impact_scene", "")), impact_scene)
	bullet.shooter = self
	bullet.terrain_ballistics_provider = _find_terrain_ballistics_provider()
	if bullet.has_method("configure_visual"):
		var frames := _load_projectile_sprite_frames(str(profile.get("visual_sprite_frames", "")))
		if frames != null:
			bullet.call("configure_visual", frames, StringName(str(profile.get("visual_animation", "travel"))), profile.get("visual_scale", Vector2.ONE))
	# Apply cognitive crit bonus (bearing increases crit chance)
	if cognitive != null and cognitive.has_method("get_player_crit_bonus"):
		bullet.crit_chance = float(cognitive.call("get_player_crit_bonus"))

	var container = get_node_or_null("/root/GameRoot/World/Projectiles")
	if container:
		container.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)
	bullet.global_position = spawn_position

	current_recoil += float(profile.get("recoil_kick", 1.2)) * _get_heat_recoil_multiplier()
	_consume_ammo()
	_apply_heat_for_shot()
	_emit_weapon_noise(spawn_position)
	_spawn_muzzle_flash(direction)
	_apply_body_recoil_impulse(direction)
	_obs_increment(&"player_ranged_shots_fired", 1)
	_obs_log(&"player_ranged_shot", {
		"weapon": _get_active_weapon_state_key(),
		"position": global_position,
		"muzzle": spawn_position,
		"direction": direction,
		"damage": bullet.damage,
		"speed": bullet.speed,
		"radius": bullet.bullet_radius,
		"spread_deg": spread,
		"loaded_ammo": _get_current_loaded_ammo(),
		"reserve_ammo": _get_current_reserve_ammo(),
	})
	_obs_gauge(&"player_loaded_ammo", _get_current_loaded_ammo())
	_obs_gauge(&"player_reserve_ammo", _get_current_reserve_ammo())
	_obs_gauge(&"player_recoil", current_recoil)


func get_terrain_ballistics_provider() -> Node:
	return _find_terrain_ballistics_provider()


func _find_terrain_ballistics_provider() -> Node:
	var providers := get_tree().get_nodes_in_group("terrain_ballistics_provider")
	return providers[0] if not providers.is_empty() else null


func _handle_attack_input() -> void:
	if _field_patch_active:
		return
	if InputMap.has_action(&"drone_issue_guard_order") and Input.is_action_pressed(&"drone_issue_guard_order"):
		return
	if _is_block_state_active():
		_try_queue_parry_counter_from_block()
		return
	if _is_ranged_ready_active():
		if _is_primary_ranged_aim_presentation_active():
			return
		if _is_attack_primary_just_pressed() and fire_cooldown_remaining <= 0.0 and _pending_ranged_shot.is_empty():
			_request_ranged_shot()
		elif _is_attack_primary_pressed() and fire_cooldown_remaining <= 0.0 and _pending_ranged_shot.is_empty():
			_request_ranged_shot()
		return
	if _is_attack_secondary_chord_just_pressed():
		_request_current_profile_intent(false)
		return
	if _is_ranged_loadout_active():
		return
	if _is_attack_primary_just_pressed():
		_try_start_contextual_attack()
		return


func _request_current_profile_intent(primary: bool) -> void:
	var profile := get_current_combat_profile()
	if profile == null:
		return
	var intent := profile.primary_intent if primary else profile.secondary_intent
	if intent.is_empty():
		return
	_request_attack_intent(intent)


func _request_attack_intent(intent: String) -> void:
	if _field_patch_active:
		cancel_field_patch(&"attack")
		return
	match intent:
		"ranged_ready", "ranged_stance", "ranged_aim":
			_enter_ranged_ready()
		"ranged_fire", "ranged_unfocused_fire", "ranged_focused_fire":
			_request_ranged_shot()
		"melee_fast", "melee_heavy", "unarmed_fast", "unarmed_heavy":
			_try_melee_attack(intent)
		_:
			push_warning("Unsupported attack intent: %s" % intent)


func _try_melee_attack(intent: String = ""):
	if _field_patch_active:
		cancel_field_patch(&"attack")
		return
	if not _is_melee_loadout_active():
		return
	var requested_kind := _get_requested_attack_kind(intent)
	if _can_start_attack_now():
		_request_attack_state(requested_kind)
		return
	_buffer_attack(requested_kind)


func _try_start_contextual_attack() -> void:
	var critical_target := _find_valid_parry_critical_target()
	if critical_target != null:
		_start_critical_attack(critical_target)
		return
	_request_current_profile_intent(true)


func _try_queue_parry_counter_from_block() -> void:
	if _block_phase != &"success" or _parry_phase != &"success":
		return
	if _counter_window_timer <= 0.0:
		return
	if not _is_attack_primary_just_pressed():
		return
	var profile := get_current_combat_profile()
	if profile == null:
		return
	var intent := profile.primary_intent
	if not ["melee_fast", "melee_heavy", "unarmed_fast", "unarmed_heavy"].has(intent):
		return
	_buffer_attack(_get_requested_attack_kind(intent))
	_parry_timer = minf(_parry_timer, 0.016)


func _is_attack_primary_just_pressed() -> bool:
	return Input.is_action_just_pressed("fire_primary") \
		or Input.is_action_just_pressed("attack_primary") \
		or Input.is_action_just_pressed("attack") \
		or Input.is_action_just_pressed("melee_attack")


func _is_attack_primary_pressed() -> bool:
	return Input.is_action_pressed("fire_primary") \
		or Input.is_action_pressed("attack_primary") \
		or Input.is_action_pressed("attack") \
		or Input.is_action_pressed("melee_attack")


func _is_attack_secondary_just_pressed() -> bool:
	return Input.is_action_just_pressed("aim_hold") \
		or Input.is_action_just_pressed("attack_secondary") \
		or (Input.is_key_pressed(KEY_SHIFT) and _is_attack_primary_just_pressed())


func _is_attack_secondary_chord_just_pressed() -> bool:
	return Input.is_key_pressed(KEY_SHIFT) and _is_attack_primary_just_pressed()


func _is_attack_secondary_pressed() -> bool:
	return Input.is_action_pressed("aim_hold") \
		or Input.is_action_pressed("attack_secondary")


func _get_offhand_secondary_mode() -> StringName:
	if _is_ranged_loadout_active():
		return &"primary_ranged_ready"
	if _is_melee_loadout_active() and _get_sidearm_weapon_definition() != null:
		return &"sidearm_ready"
	return &"parry_guard"


func _can_enter_ranged_ready() -> bool:
	if _is_dead or _is_terminal_open() or _portal_transition_locked or _portal_arrival_animation_active or _arrn_stabilization_locked:
		return false
	if _reload_active or _is_block_state_active() or _melee_active or _melee_heavy_anticipating or _melee_fast_windup or _melee_recovery_active:
		return false
	return _get_ranged_ready_candidate_weapon_definition() != null


func _update_ranged_ready_state() -> void:
	var mode := _get_offhand_secondary_mode()
	if mode != &"primary_ranged_ready" and mode != &"sidearm_ready":
		_exit_ranged_ready()
		return
	if _is_attack_secondary_pressed() and _can_enter_ranged_ready():
		_enter_ranged_ready()
	else:
		_exit_ranged_ready()


func _handle_offhand_secondary_input(delta: float) -> void:
	var offhand_pressed := _is_attack_secondary_pressed()
	var offhand_just_pressed := offhand_pressed and not _offhand_secondary_was_pressed
	_offhand_secondary_was_pressed = offhand_pressed

	if _get_offhand_secondary_mode() != &"parry_guard":
		_guard_requested_from_secondary = false
		_guard_repress_required_after_parry_success = false
		_guard_held_timer = 0.0
		_update_parry_guard_timers(delta)
		return

	_update_parry_guard_timers(delta)

	if offhand_just_pressed:
		_start_guard_from_secondary()

	if offhand_pressed:
		if _guard_repress_required_after_parry_success:
			if _parry_phase.is_empty() and _block_phase in [&"enter", &"hold", &"hitreact", &"parry", &"success", &"recovery", &"exit"]:
				_block_phase = &""
				_block_active = false
				_guard_requested_from_secondary = false
			return
		_guard_held_timer += delta
		if _parry_phase.is_empty():
			_guard_requested_from_secondary = true
			if _can_parry_from_guard() and _is_attack_primary_just_pressed():
				_try_start_parry()
			elif _block_phase.is_empty() or _block_phase == &"exit":
				_request_block_state()
			elif _block_phase == &"enter" and _guard_held_timer >= guard_full_active_sec:
				_block_phase = &"hold"
				_block_active = true
				_play_block_animation(&"melee_2h_block_hold")
	else:
		_guard_requested_from_secondary = false
		_guard_repress_required_after_parry_success = false
		_guard_held_timer = 0.0
		if _is_block_state_active() and _block_phase in [&"enter", &"hold", &"hitreact"]:
			_block_phase = &"exit"
			_block_active = false
			_play_block_animation(&"melee_2h_block_exit")


func _start_guard_from_secondary() -> void:
	if not _can_start_guard_from_secondary():
		return
	_guard_requested_from_secondary = true
	_guard_held_timer = maxf(0.0, guard_weak_start_sec)
	_request_block_state()
	if _block_phase.is_empty():
		start_block()


func _can_start_guard_from_secondary() -> bool:
	if _is_dead or _enemy_impact_lock_timer > 0.0:
		return false
	if _is_terminal_open() or _is_ui_text_input_focused() or _portal_transition_locked or _portal_arrival_animation_active or _arrn_stabilization_locked:
		return false
	if _field_patch_active:
		return false
	if _melee_active or _melee_heavy_anticipating or _melee_fast_windup or _melee_recovery_active:
		return false
	if _dodge_active or _dodge_recovery_active:
		return false
	return _is_melee_loadout_active()


func _can_parry_from_guard() -> bool:
	if not _can_start_parry():
		return false
	if _guard_held_timer < parry_min_guard_time_sec:
		return false
	if not _parry_phase.is_empty():
		return false
	return _block_phase in [&"enter", &"hold", &"hitreact"]


func _try_start_parry() -> bool:
	if not _can_start_parry():
		return false

	stamina = maxf(0.0, stamina - parry_stamina_cost)
	_exit_ranged_ready()
	_cancel_reload()
	_clear_attack_buffer()
	_melee_active = false
	_melee_heavy_anticipating = false
	_melee_fast_windup = false
	_melee_recovery_active = false
	_melee_attack_kind = ""
	_melee_attack_key = ""
	_melee_elapsed = 0.0
	_melee_duration = 0.0
	_active_attack_profile = null
	_active_melee_attack_profile = null
	disable_hitbox()
	_melee_hit_targets.clear()
	_reset_melee_overlay_visuals()
	_parry_neutral_lock_active = false

	_parry_phase = &"windup"
	_parry_timer = maxf(0.0, parry_windup_sec)
	_parry_active = false
	_guard_requested_from_secondary = false
	_block_phase = &"parry"
	_block_active = false
	_play_parry_animation(&"unarmed_parry")
	_request_block_state()
	return true


func _can_start_parry() -> bool:
	if stamina < parry_stamina_cost:
		return false
	if _is_dead or _enemy_impact_lock_timer > 0.0:
		return false
	if _is_terminal_open() or _is_ui_text_input_focused() or _portal_transition_locked or _portal_arrival_animation_active or _arrn_stabilization_locked:
		return false
	if _field_patch_active:
		return false
	if _melee_active or _melee_heavy_anticipating or _melee_fast_windup or _melee_recovery_active:
		return false
	if _dodge_active or _dodge_recovery_active:
		return false
	return _is_melee_loadout_active()


func _update_parry_guard_timers(delta: float) -> void:
	if _parry_phase.is_empty():
		return

	_parry_timer = maxf(0.0, _parry_timer - delta)
	match _parry_phase:
		&"windup":
			if _parry_timer <= 0.0:
				_parry_phase = &"active"
				_parry_timer = maxf(0.0, parry_active_sec)
				_parry_active = true
		&"active":
			if _parry_timer <= 0.0:
				_parry_active = false
				_parry_phase = &"recovery"
				_parry_timer = maxf(maxf(0.0, parry_recovery_sec), _get_parry_attempt_remaining_duration())
				_block_phase = &"recovery"
				_block_active = false
		&"success", &"recovery":
			if _parry_timer <= 0.0:
				var completed_phase := _parry_phase
				_parry_phase = &""
				_parry_active = false
				if _block_phase == &"success" and not _buffered_attack_kind.is_empty() and _counter_window_timer > 0.0:
					_block_phase = &""
					_block_active = false
					_request_attack_state(_consume_buffered_attack())
				elif completed_phase == &"success":
					_enter_post_parry_neutral_lock()
				elif _is_attack_secondary_pressed() and _get_offhand_secondary_mode() == &"parry_guard":
					_guard_requested_from_secondary = true
					_block_phase = &"enter"
					_block_active = false
					_play_block_animation(&"melee_2h_block_enter")
					_request_block_state()
				elif _block_phase in [&"parry", &"success", &"recovery"]:
					_block_phase = &""
					_block_active = false
		&"expired":
			_parry_phase = &"recovery"
			_parry_timer = maxf(maxf(0.0, parry_recovery_sec), _get_parry_attempt_remaining_duration())
			_guard_requested_from_secondary = false
			_block_phase = &"recovery"
			_block_active = false


func _get_parry_attempt_remaining_duration() -> float:
	var direction := _get_attack_aim_direction()
	if direction.length_squared() <= 0.001:
		direction = visual_idle_direction
	if direction.length_squared() <= 0.001:
		direction = Vector2.DOWN

	var duration := 0.0
	if _is_current_profile_unarmed() and modular_locomotion_layers_enabled:
		if modular_lower_body_sprite != null and modular_lower_body_sprite.sprite_frames != null:
			var lower_anim := AnimationResolver.resolve("unarmed_parry", direction, modular_lower_body_sprite)
			duration = maxf(duration, _get_sprite_frames_animation_duration(modular_lower_body_sprite.sprite_frames, lower_anim))
		if modular_upper_body_sprite != null and modular_upper_body_sprite.sprite_frames != null:
			var upper_anim := AnimationResolver.resolve("unarmed_parry", direction, modular_upper_body_sprite)
			duration = maxf(duration, _get_sprite_frames_animation_duration(modular_upper_body_sprite.sprite_frames, upper_anim))
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		var body_anim := AnimationResolver.resolve("unarmed_parry", direction, animated_sprite)
		duration = maxf(duration, _get_sprite_frames_animation_duration(animated_sprite.sprite_frames, body_anim))
	if duration <= 0.0:
		return 0.0
	return maxf(0.0, duration - maxf(0.0, parry_windup_sec) - maxf(0.0, parry_active_sec))


func _get_sprite_frames_animation_duration(sprite_frames: SpriteFrames, animation_name: StringName) -> float:
	if not _has_playable_sprite_animation(sprite_frames, animation_name):
		return 0.0
	var speed := sprite_frames.get_animation_speed(animation_name)
	if speed <= 0.001:
		return 0.0
	return float(sprite_frames.get_frame_count(animation_name)) / speed


func _enter_post_parry_neutral_lock() -> void:
	_guard_requested_from_secondary = false
	_guard_repress_required_after_parry_success = _is_attack_secondary_pressed()
	_block_phase = &""
	_block_active = false
	_parry_neutral_lock_active = true
	_play_parry_animation(&"unarmed_parry_success_01")


func _enter_ranged_ready() -> void:
	var ranged_weapon := _get_ranged_ready_candidate_weapon_definition()
	if ranged_weapon == null:
		return
	var already_ready_for_weapon := _ranged_ready_active and _ranged_ready_weapon_definition == ranged_weapon
	var entering_sidearm := not already_ready_for_weapon and ranged_weapon == _get_sidearm_weapon_definition()
	var entering_primary := not already_ready_for_weapon and ranged_weapon != _get_sidearm_weapon_definition()
	_ranged_ready_active = true
	_ranged_ready_weapon_definition = ranged_weapon
	if entering_sidearm:
		_sidearm_draw_active = true
		_sidearm_action_phase = &"drawing"
		_sidearm_action_phase_started = false
		_sidearm_action_direction = aim_direction
		_modular_upper_action_animation = &""
		_modular_sidearm_action_animation = &""
	_clamp_loaded_ammo_to_current_weapon()
	if aim_direction.length_squared() > 0.0001:
		visual_idle_direction = aim_direction
	_apply_active_weapon_frames()
	_apply_dynamic_weapon_socket_layout(ranged_weapon)
	_update_primary_weapon_visual(false)
	if entering_primary:
		_begin_modular_primary_ranged_aim_presentation()


func _exit_ranged_ready() -> void:
	if not _ranged_ready_active:
		return
	var should_lower_primary := not _is_using_sidearm_ranged() and _is_using_ranged_2h_primary()
	var lowered_primary := false
	if should_lower_primary:
		lowered_primary = _begin_modular_primary_ranged_lower_presentation()
	if not lowered_primary:
		_end_modular_primary_ranged_fire_presentation()
	_ranged_ready_active = false
	_ranged_ready_weapon_definition = null
	_sidearm_draw_active = false
	_sidearm_action_phase = &"holstered"
	_sidearm_action_phase_started = false
	if modular_sidearm_sprite and not lowered_primary:
		modular_sidearm_sprite.visible = false
		modular_sidearm_sprite.stop()
	if modular_upper_fx_sprite:
		modular_upper_fx_sprite.visible = false
		modular_upper_fx_sprite.stop()
	if not lowered_primary:
		_hide_modular_cape_layer()
	_apply_active_weapon_frames()
	_apply_dynamic_weapon_socket_layout()
	_update_primary_weapon_visual(false)


func _is_ranged_ready_active() -> bool:
	return _ranged_ready_active and _ranged_ready_weapon_definition != null


func _get_requested_attack_kind(intent: String = "") -> String:
	if not intent.is_empty():
		return _attack_kind_from_intent(intent)
	var wants_heavy: bool = Input.is_key_pressed(KEY_SHIFT)
	if not wants_heavy:
		return "fast"
	if heavy_attack_blocked_while_sprinting and is_sprinting:
		return "fast"
	if stamina < heavy_attack_stamina_cost:
		return "fast"
	if Input.is_key_pressed(KEY_SHIFT):
		return "heavy"
	return "fast"


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
		_:
			return "fast"


func _can_start_attack_now() -> bool:
	if _field_patch_active:
		return false
	if _melee_active:
		return false
	return melee_cooldown_remaining <= 0.0


func _start_attack_by_kind(kind: String) -> void:
	if kind == "critical":
		_start_critical_attack(_critical_attack_target)
	elif kind == "heavy":
		_start_heavy_attack()
	elif kind == "fast":
		_start_fast_attack()
	else:
		_start_fast_attack()


func _get_current_melee_attack_profile(kind: String) -> MeleeAttackProfile:
	var weapon_profile := get_current_combat_profile()
	if weapon_profile == null:
		return null
	match kind:
		"heavy":
			return weapon_profile.heavy_attack_profile
		"fast":
			return weapon_profile.fast_attack_profile
		_:
			return null


func _begin_melee_attack_profile(kind: String) -> MeleeAttackProfile:
	_active_melee_attack_profile = _get_current_melee_attack_profile(kind)
	return _active_melee_attack_profile


func _get_active_melee_movement_profile() -> Dictionary:
	if _active_melee_attack_profile == null:
		return {}
	return {
		"startup_time": _active_melee_attack_profile.windup_sec,
		"active_time": _active_melee_attack_profile.active_sec,
		"startup_move": _active_melee_attack_profile.startup_move_mult,
		"active_move": _active_melee_attack_profile.active_move_mult,
		"recovery_move": _active_melee_attack_profile.recovery_move_mult,
		"turn_locked": _active_melee_attack_profile.turn_locked,
	}


func _get_active_melee_hit_window() -> Dictionary:
	if _active_melee_attack_profile == null or _active_melee_attack_profile.hit_window_frames.is_empty():
		return {}
	var frames: Array[int] = []
	for frame in _active_melee_attack_profile.hit_window_frames:
		frames.append(int(frame))
	return {"frames": frames}


func _request_attack_state(kind: String) -> void:
	if kind == "critical":
		_start_attack_by_kind(kind)
		return
	var state_name := "attack_fast"
	if kind == "heavy":
		state_name = "attack_heavy"
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


func _start_fast_attack() -> void:
	_critical_attack_target = null
	_critical_attack_damage = 0.0
	_active_attack_profile = get_current_combat_profile()
	_melee_active = true
	_parry_neutral_lock_active = false
	_modular_lower_action_animation = &""
	_modular_upper_action_animation = &""
	_modular_upper_fx_action_animation = &""
	_melee_heavy_anticipating = false
	_melee_fast_windup = false
	_melee_attack_kind = "fast"
	var attack_profile: MeleeAttackProfile = _begin_melee_attack_profile("fast")
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
	_melee_forward = _get_melee_forward_direction()
	_begin_attack_movement_profile(_resolve_current_attack_id(), _melee_forward)
	if attack_profile != null:
		_configure_melee_hitbox(attack_profile.damage, attack_profile.range_px, attack_profile.arc_degrees)
	else:
		_configure_melee_hitbox(melee_fast_hit_damage, melee_range, melee_arc_degrees)

	# Try windup phase for unarmed fast attacks (skip for melee weapons)
	if is_unarmed_attack and _try_start_fast_attack_windup():
		return

	# Legacy path: play strike directly (melee weapons or no windup available)
	_play_melee_anim_from_key(_melee_attack_key, fallback_animation)
	_melee_duration = _get_current_melee_animation_duration(next_duration, 0.24, next_duration)
	_lock_melee_cooldown(_melee_duration + 0.04)


func _try_start_fast_attack_windup() -> bool:
	# Start the windup phase for unarmed fast attacks.
	# Returns true if windup was started, false if fallback to direct strike.
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false
	var windup_anim := AnimationResolver.resolve("unarmed_attack_fast_windup", _melee_forward, animated_sprite)
	if not animated_sprite.sprite_frames.has_animation(windup_anim):
		return false
	_melee_active = false
	_melee_fast_windup = true
	_melee_elapsed = 0.0
	_melee_duration = 0.0
	disable_hitbox()
	_melee_hit_targets.clear()
	animated_sprite.flip_h = _is_facing_left(_melee_forward)
	animated_sprite.speed_scale = _get_melee_animation_speed_scale(_melee_attack_key)
	animated_sprite.play(windup_anim)
	if _sync_modular_fast_attack_phase(&"windup"):
		animated_sprite.visible = false
	else:
		_clear_modular_fast_attack_layers()
	_lock_melee_cooldown(0.60)
	return true


func _begin_fast_attack_strike_phase() -> void:
	# Transition from windup to strike phase.
	_melee_fast_windup = false
	_melee_active = true
	_melee_elapsed = 0.0
	var attack_profile: MeleeAttackProfile = _active_melee_attack_profile
	if attack_profile != null:
		_configure_melee_hitbox(attack_profile.damage, attack_profile.range_px, attack_profile.arc_degrees)
		_melee_duration = attack_profile.recovery_sec
		_play_melee_anim_from_key(_melee_attack_key, attack_profile.fallback_animation)
	else:
		_configure_melee_hitbox(melee_fast_hit_damage, melee_range, melee_arc_degrees)
		_melee_duration = _get_current_melee_animation_duration(0.42, 0.24, 0.42)
		_play_melee_anim_from_key(_melee_attack_key, &"unarmed_attack_fast")
	if melee_cooldown_remaining <= 0.0:
		_lock_melee_cooldown(_melee_duration + 0.04)


func _start_heavy_attack() -> void:
	_critical_attack_target = null
	_critical_attack_damage = 0.0
	_active_attack_profile = get_current_combat_profile()
	_parry_neutral_lock_active = false
	_modular_upper_action_animation = &""
	_melee_heavy_anticipating = false
	_melee_fast_combo_step = 0
	_melee_attack_kind = "heavy"
	var is_unarmed_attack := _is_attack_profile_unarmed(_active_attack_profile)
	_melee_attack_key = "unarmed_heavy" if is_unarmed_attack else "melee_heavy"
	_begin_melee_attack_profile("heavy")
	_notify_camera_attack_windup(true)
	stamina = max(0.0, stamina - heavy_attack_stamina_cost)
	_melee_forward = _get_melee_forward_direction()
	_begin_attack_movement_profile(_resolve_current_attack_id(), _melee_forward)
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
	_melee_fast_windup = false
	_melee_active = true
	_melee_elapsed = 0.0
	var attack_profile: MeleeAttackProfile = _active_melee_attack_profile
	_melee_duration = attack_profile.recovery_sec if attack_profile != null else 0.70
	if attack_profile != null:
		_configure_melee_hitbox(attack_profile.damage, attack_profile.range_px, attack_profile.arc_degrees)
		_play_melee_anim_from_key(_melee_attack_key, attack_profile.fallback_animation)
	else:
		_configure_melee_hitbox(melee_heavy_hit_damage, melee_heavy_range, melee_heavy_arc_degrees)
		_play_melee_anim_from_key(_melee_attack_key, &"melee_2h_heavy")
	if melee_cooldown_remaining <= 0.0:
		_lock_melee_cooldown(_melee_duration + 0.18)


func _get_cancel_start_time() -> float:
	if _active_melee_attack_profile != null:
		return _active_melee_attack_profile.cancel_start_sec
	if _melee_attack_kind == "heavy":
		return melee_heavy_cancel_start
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
	_melee_fast_windup = false
	_critical_attack_target = null
	_critical_attack_damage = 0.0
	disable_hitbox()
	_melee_hit_targets.clear()
	if not _melee_recovery_active:
		_active_attack_profile = null
		_active_melee_attack_profile = null
		_reset_melee_overlay_visuals()


func _apply_melee_hitbox_tick() -> void:
	if weapon_hitbox == null:
		return
	var weapon_definition = _active_attack_profile if _active_attack_profile != null else _get_equipped_primary_weapon_definition()
	var window: Dictionary = _get_active_melee_hit_window()
	if weapon_definition != null and weapon_definition.hit_windows is Dictionary:
		var weapon_window: Dictionary = weapon_definition.hit_windows.get(_melee_attack_key, {})
		if not weapon_window.is_empty():
			window = weapon_window
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
		var critical_consumed := false
		if _melee_attack_kind == "critical" and enemy == _critical_attack_target and enemy.has_method("receive_parry_critical"):
			var result: Variant = enemy.call("receive_parry_critical", self, _critical_attack_damage, {
				"impact_position": impact_position,
				"attack_key": _melee_attack_key,
			})
			if result is Dictionary:
				critical_consumed = bool((result as Dictionary).get("critical", false))
		if not critical_consumed:
			enemy.take_damage(_melee_damage_current)
		_melee_hit_targets[enemy_id] = true
		var knockback_dir := global_position.direction_to(enemy.global_position)
		var knockback_force: float = _active_melee_attack_profile.knockback_force if _active_melee_attack_profile != null else (melee_fast_knockback_force if _melee_attack_kind == "fast" else melee_heavy_knockback_force)
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
	if _melee_heavy_anticipating or _melee_fast_windup:
		return false
	if _melee_recovery_active and kind == "fast":
		return false
	if _melee_active:
		return _melee_attack_kind != kind
	return true


func start_attack(attack_key: String) -> void:
	if attack_key == "melee_fast" or attack_key == "unarmed_fast":
		_start_fast_attack()
	elif attack_key == "melee_heavy" or attack_key == "unarmed_heavy":
		_start_heavy_attack()


func start_block() -> void:
	if not _is_melee_loadout_active():
		_block_phase = &""
		_block_active = false
		return
	if not _parry_phase.is_empty() and _block_phase in [&"parry", &"success", &"recovery"]:
		return
	if _block_phase == &"hold":
		return
	_melee_active = false
	_melee_attack_kind = ""
	_melee_attack_key = ""
	_melee_elapsed = 0.0
	_melee_duration = 0.0
	_active_attack_profile = null
	_active_melee_attack_profile = null
	disable_hitbox()
	_melee_hit_targets.clear()
	_reset_melee_overlay_visuals()
	_parry_neutral_lock_active = false
	_block_phase = &"enter"
	_block_active = false
	_play_block_animation(&"melee_2h_block_enter")


func update_block_state() -> String:
	if animated_sprite == null:
		_block_phase = &""
		_block_active = false
		return _get_desired_animation_state()
	match _block_phase:
		&"parry", &"success", &"recovery":
			if _parry_phase.is_empty():
				_block_phase = &""
				_block_active = false
				return _get_desired_animation_state()
			return "block"
		&"expired":
			if _wants_block():
				start_block()
				return "block"
			return "block"
		&"enter":
			if _is_block_animation_finished():
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
		&"hitreact":
			if _is_block_animation_finished():
				_block_phase = &"hold"
				_block_active = true
				_play_block_animation(&"melee_2h_block_hold")
			return "block"
		&"exit":
			if _is_block_animation_finished():
				_block_phase = &""
				_block_active = false
				return _get_desired_animation_state()
			return "block"
		_:
			if _wants_block():
				start_block()
				return "block"
			return _get_desired_animation_state()


func try_parry_incoming_attack(attacker: Node2D, hit_direction: Vector2, hit_data: Dictionary = {}) -> bool:
	if not _parry_active:
		return false

	var guard_dir := _get_attack_aim_direction()
	if guard_dir.length_squared() <= 0.001:
		guard_dir = visual_idle_direction
	if guard_dir.length_squared() <= 0.001:
		guard_dir = Vector2.DOWN

	var incoming_from := -hit_direction.normalized()
	if incoming_from.length_squared() <= 0.001:
		incoming_from = global_position.direction_to(attacker.global_position) if attacker != null and is_instance_valid(attacker) else -guard_dir
	var facing_dot := guard_dir.normalized().dot(incoming_from.normalized())
	if facing_dot < 0.35:
		return false

	_on_parry_success(attacker, hit_direction, hit_data)
	return true


func try_guard_incoming_attack(damage: float, hit_direction: Vector2, stamina_cost_override: float = -1.0) -> Dictionary:
	if not _is_blocking():
		return {"blocked": false, "damage": damage}

	var guard_dir := _get_attack_aim_direction()
	if guard_dir.length_squared() <= 0.001:
		guard_dir = visual_idle_direction
	if guard_dir.length_squared() <= 0.001:
		guard_dir = Vector2.DOWN

	var incoming_from := -hit_direction.normalized()
	if incoming_from.length_squared() <= 0.001:
		incoming_from = guard_dir
	var facing_dot := guard_dir.normalized().dot(incoming_from.normalized())
	if facing_dot < 0.15:
		return {"blocked": false, "damage": damage}

	var stamina_cost := stamina_cost_override if stamina_cost_override >= 0.0 else guard_stamina_cost_per_hit
	if offhand_guard_item_equipped:
		stamina_cost *= 0.75
	stamina = maxf(0.0, stamina - stamina_cost)

	var reduction := guard_damage_reduction
	if offhand_guard_item_equipped:
		reduction = clampf(reduction + 0.12, 0.0, 0.9)
	var reduced_damage := maxf(guard_chip_damage_minimum, damage * (1.0 - reduction))

	if stamina <= guard_break_stamina_threshold:
		_block_phase = &"hitreact"
		_block_active = false
		_play_block_animation(&"melee_2h_block_hitreact")
		reduced_damage = maxf(guard_chip_damage_minimum, damage * 0.65)
	elif _is_current_profile_unarmed():
		_block_phase = &"hitreact"
		_block_active = false
		_play_block_animation(&"melee_2h_block_hitreact")

	return {
		"blocked": true,
		"damage": reduced_damage,
	}


func _is_failed_parry_hitreact_context() -> bool:
	return not _parry_phase.is_empty() and _parry_phase != &"success"


func _play_failed_parry_block_hitreact() -> void:
	_parry_active = false
	_parry_phase = &""
	_parry_timer = 0.0
	_block_phase = &"hitreact"
	_block_active = false
	_guard_requested_from_secondary = false
	_play_block_animation(&"melee_2h_block_hitreact")


func _on_parry_success(attacker: Node2D, hit_direction: Vector2, hit_data: Dictionary) -> void:
	var contact_position := global_position
	if hit_data.get("impact_position") is Vector2:
		contact_position = hit_data["impact_position"]
	elif attacker != null and is_instance_valid(attacker):
		contact_position = _resolve_melee_impact_position(attacker)
	else:
		var contact_direction := -hit_direction.normalized()
		if contact_direction.length_squared() <= 0.001:
			contact_direction = _get_attack_aim_direction()
		contact_position += contact_direction.normalized() * 22.0
	_parry_active = false
	_parry_phase = &"success"
	var success_recovery := maxf(0.0, parry_success_recovery_sec)
	_parry_timer = success_recovery
	_parry_success_lockout = maxf(_parry_success_lockout, success_recovery)
	_counter_window_timer = maxf(_counter_window_timer, parry_counter_window_sec)
	_block_phase = &"success"
	_block_active = false
	_guard_repress_required_after_parry_success = _is_attack_secondary_pressed()

	stamina = min(stamina_max, stamina + parry_success_stamina_refund)

	if attacker != null and is_instance_valid(attacker):
		var away_from_operator := global_position.direction_to(attacker.global_position)
		if attacker.has_method("apply_parry_stagger"):
			attacker.call("apply_parry_stagger", away_from_operator, parry_enemy_stagger_sec, parry_enemy_knockback)
		elif attacker.has_method("apply_melee_impact"):
			attacker.call("apply_melee_impact", "parry", away_from_operator, parry_enemy_knockback)

	_play_parry_animation(&"unarmed_parry_success")
	_spawn_parry_contact_spark(contact_position)
	_spawn_parry_success_fx(contact_position)
	_notify_camera_attack_impact(hit_direction, false)


func _spawn_parry_contact_spark(contact_position: Vector2) -> void:
	var spark := PARRY_CONTACT_SPARK_VFX_SCENE.instantiate() as Node2D
	if spark == null:
		push_error("[CombatVfx] Required parry contact spark scene could not instantiate.")
		return
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(spark)
	spark.global_position = contact_position


func _play_parry_animation(base_animation: StringName) -> void:
	var direction := _get_attack_aim_direction()
	if direction.length_squared() <= 0.001:
		direction = visual_idle_direction
	if direction.length_squared() <= 0.001:
		direction = Vector2.DOWN

	var fallback := &"unarmed_block_enter"
	if base_animation == &"unarmed_parry_recovery":
		fallback = &"unarmed_block_exit"
	elif base_animation == &"unarmed_parry_success":
		fallback = &"unarmed_block_hitreact"
	elif base_animation == &"unarmed_parry_success_01":
		fallback = &"unarmed_block_exit"

	if _is_current_profile_unarmed() \
		and modular_locomotion_layers_enabled \
		and _play_modular_unarmed_parry(String(base_animation), direction):
		return

	if animated_sprite == null or animated_sprite.sprite_frames == null:
		_play_block_animation(fallback)
		return

	var resolved := AnimationResolver.resolve(String(base_animation), direction, animated_sprite)
	if animated_sprite.sprite_frames.has_animation(resolved):
		animated_sprite.visible = true
		animated_sprite.flip_h = _is_facing_left(direction)
		animated_sprite.play(resolved)
		_clear_modular_upper_action_layer()
		return

	_warn_missing_animation_once(String(resolved), String(fallback))
	_play_block_animation(fallback)


func _play_modular_unarmed_parry(base_animation: String, direction: Vector2) -> bool:
	if modular_lower_body_sprite == null or modular_upper_body_sprite == null:
		return false
	if modular_lower_body_sprite.sprite_frames == null or modular_upper_body_sprite.sprite_frames == null:
		return false

	var resolved_base := "unarmed_parry_success" if base_animation == "unarmed_parry_success" else base_animation
	var lower_anim := AnimationResolver.resolve(resolved_base, direction, modular_lower_body_sprite)
	var upper_anim := AnimationResolver.resolve(resolved_base, direction, modular_upper_body_sprite)
	if not _has_playable_sprite_animation(modular_lower_body_sprite.sprite_frames, lower_anim):
		return false
	if not _has_playable_sprite_animation(modular_upper_body_sprite.sprite_frames, upper_anim):
		return false

	_hide_modular_locomotion_layers()
	modular_lower_body_sprite.visible = true
	modular_lower_body_sprite.flip_h = false
	modular_lower_body_sprite.speed_scale = 1.0
	modular_lower_body_sprite.play(lower_anim)
	modular_upper_body_sprite.visible = true
	modular_upper_body_sprite.flip_h = false
	modular_upper_body_sprite.speed_scale = 1.0
	modular_upper_body_sprite.play(upper_anim)
	_modular_upper_action_animation = upper_anim
	animated_sprite.visible = false

	if modular_upper_fx_sprite != null and modular_upper_fx_sprite.sprite_frames != null:
		var fx_base := "unarmed_parry_fx"
		if base_animation == "unarmed_parry_success_01":
			fx_base = "unarmed_parry_success_01_fx"
		elif base_animation == "unarmed_parry_recovery":
			fx_base = "unarmed_parry_recovery_fx"
		var fx_anim := AnimationResolver.resolve(fx_base, direction, modular_upper_fx_sprite)
		if _has_playable_sprite_animation(modular_upper_fx_sprite.sprite_frames, fx_anim):
			modular_upper_fx_sprite.visible = true
			modular_upper_fx_sprite.flip_h = false
			modular_upper_fx_sprite.speed_scale = 1.0
			modular_upper_fx_sprite.play(fx_anim)
	return true


func _spawn_parry_success_fx(contact_position: Vector2) -> Node2D:
	var burst := PARRY_SUCCESS_BURST_VFX_SCENE.instantiate() as Node2D
	if burst == null:
		push_error("[CombatVfx] Required parry success burst scene could not instantiate.")
		return null
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(burst)
	burst.global_position = contact_position

	var direction := _get_attack_aim_direction()
	if direction.length_squared() <= 0.001:
		direction = visual_idle_direction
	if direction.length_squared() <= 0.001:
		direction = Vector2.DOWN
	if _play_modular_parry_fx(direction, "PLACEHOLDER_unarmed_parry_success_fx"):
		return burst
	var placeholder_animation := AnimationResolver.resolve(
		"PLACEHOLDER_unarmed_parry_success_fx",
		direction,
		modular_upper_fx_sprite
	)
	_warn_missing_animation_once(String(placeholder_animation), "independent world-space parry success burst")
	_play_modular_parry_fx(direction, "unarmed_parry_fx")
	return burst


func _find_valid_parry_critical_target() -> Node2D:
	var best_target: Node2D = null
	var best_distance := INF
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not (enemy is Node2D):
			continue
		var enemy_node := enemy as Node2D
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if enemy_node.has_method("is_dead") and bool(enemy_node.call("is_dead")):
			continue
		if not enemy_node.has_method("can_receive_parry_critical_from"):
			continue
		if not bool(enemy_node.call("can_receive_parry_critical_from", self)):
			continue
		if not _is_enemy_in_preview_strike_zone(enemy_node):
			continue
		var distance := global_position.distance_to(enemy_node.global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = enemy_node
	return best_target


func _start_critical_attack(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		_try_melee_attack()
		return
	if _melee_active or melee_cooldown_remaining > 0.0:
		_critical_attack_target = target
		_buffer_attack("critical")
		return

	_active_attack_profile = get_current_combat_profile()
	_active_melee_attack_profile = _get_current_melee_attack_profile("fast")
	_parry_neutral_lock_active = false
	_modular_lower_action_animation = &""
	_modular_upper_action_animation = &""
	_modular_upper_fx_action_animation = &""
	_melee_heavy_anticipating = false
	_melee_fast_windup = false
	_melee_fast_combo_step = 0
	_melee_attack_kind = "critical"
	_melee_attack_key = "critical_attack_01"
	_critical_attack_target = target
	_notify_camera_attack_windup(true)

	_melee_forward = global_position.direction_to(target.global_position)
	if _melee_forward.length_squared() <= 0.001:
		_melee_forward = _get_melee_forward_direction()
	_begin_attack_movement_profile(_resolve_current_attack_id(), _melee_forward)

	var damage := melee_fast_hit_damage * parry_counter_damage_multiplier
	var attack_range := melee_range
	var attack_arc := melee_arc_degrees
	if _active_melee_attack_profile != null:
		damage = _active_melee_attack_profile.damage * parry_counter_damage_multiplier
		attack_range = _active_melee_attack_profile.range_px
		attack_arc = _active_melee_attack_profile.arc_degrees
	_critical_attack_damage = damage
	_melee_active = true
	_melee_elapsed = 0.0
	_configure_melee_hitbox(damage, attack_range, attack_arc)
	_counter_window_timer = 0.0
	_play_critical_attack_animation()
	_melee_duration = _get_current_melee_animation_duration(0.42, 0.24, 0.56)
	_lock_melee_cooldown(_melee_duration + 0.08)


func _play_critical_attack_animation() -> void:
	var animation_name := _ensure_operator_critical_attack_animation(_melee_forward)
	if not animation_name.is_empty():
		animated_sprite.visible = true
		animated_sprite.flip_h = false
		animated_sprite.speed_scale = 1.0
		animated_sprite.play(animation_name)
		_clear_modular_fast_attack_layers()
		_reset_melee_overlay_visuals()
		_play_operator_critical_hitspark(_melee_forward)
		return
	_warn_missing_animation_once("operator_critical_1h", "unarmed_attack_fast")
	_play_melee_anim_from_key("unarmed_fast_1", &"unarmed_attack_fast")


func _ensure_operator_critical_attack_animation(direction: Vector2) -> StringName:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return &""
	var facing_left := _is_facing_left(direction)
	var animation_name := &"operator_critical_1h_left" if facing_left else &"operator_critical_1h_right"
	if _has_playable_sprite_animation(animated_sprite.sprite_frames, animation_name):
		return animation_name
	var sheet_path := CRITICAL_ATTACK_LEFT_SHEET if facing_left else CRITICAL_ATTACK_RIGHT_SHEET
	if not ResourceLoader.exists(sheet_path):
		return &""
	var texture := load(sheet_path) as Texture2D
	if texture == null:
		return &""
	animated_sprite.sprite_frames.add_animation(animation_name)
	animated_sprite.sprite_frames.set_animation_loop(animation_name, false)
	animated_sprite.sprite_frames.set_animation_speed(animation_name, CRITICAL_ATTACK_FPS)
	for frame_index in range(CRITICAL_ATTACK_FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * CRITICAL_ATTACK_FRAME_SIZE.x, 0, CRITICAL_ATTACK_FRAME_SIZE.x, CRITICAL_ATTACK_FRAME_SIZE.y)
		animated_sprite.sprite_frames.add_frame(animation_name, atlas)
	return animation_name


func _play_operator_critical_hitspark(direction: Vector2) -> bool:
	if modular_upper_fx_sprite == null or modular_upper_fx_sprite.sprite_frames == null:
		return false
	var fx_animation := _ensure_operator_critical_hitspark_animation(direction)
	if fx_animation.is_empty():
		_warn_missing_animation_once("operator_critical_hitspark", "critical attack visual-only FX")
		return false
	modular_upper_fx_sprite.visible = true
	modular_upper_fx_sprite.flip_h = false
	modular_upper_fx_sprite.speed_scale = 1.0
	modular_upper_fx_sprite.play(fx_animation)
	_modular_upper_fx_action_animation = fx_animation
	return true


func _ensure_operator_critical_hitspark_animation(direction: Vector2) -> StringName:
	if modular_upper_fx_sprite == null or modular_upper_fx_sprite.sprite_frames == null:
		return &""
	var facing_left := _is_facing_left(direction)
	var animation_name := &"operator_critical_hitspark_left" if facing_left else &"operator_critical_hitspark_right"
	if _has_playable_sprite_animation(modular_upper_fx_sprite.sprite_frames, animation_name):
		return animation_name
	var sheet_path := CRITICAL_HITSPARK_LEFT_SHEET if facing_left else CRITICAL_HITSPARK_RIGHT_SHEET
	if not ResourceLoader.exists(sheet_path):
		return &""
	var texture := load(sheet_path) as Texture2D
	if texture == null:
		return &""
	modular_upper_fx_sprite.sprite_frames.add_animation(animation_name)
	modular_upper_fx_sprite.sprite_frames.set_animation_loop(animation_name, false)
	modular_upper_fx_sprite.sprite_frames.set_animation_speed(animation_name, CRITICAL_HITSPARK_FPS)
	for frame_index in range(CRITICAL_HITSPARK_FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * CRITICAL_HITSPARK_FRAME_SIZE.x, 0, CRITICAL_HITSPARK_FRAME_SIZE.x, CRITICAL_HITSPARK_FRAME_SIZE.y)
		modular_upper_fx_sprite.sprite_frames.add_frame(animation_name, atlas)
	return animation_name


func _play_modular_parry_fx(direction: Vector2, base_animation: String = "unarmed_parry_fx") -> bool:
	if not modular_locomotion_layers_enabled:
		return false
	if modular_upper_fx_sprite == null or modular_upper_fx_sprite.sprite_frames == null:
		return false
	var fx_animation := AnimationResolver.resolve(base_animation, direction, modular_upper_fx_sprite)
	if not _has_playable_sprite_animation(modular_upper_fx_sprite.sprite_frames, fx_animation):
		return false
	modular_upper_fx_sprite.visible = true
	modular_upper_fx_sprite.flip_h = false
	modular_upper_fx_sprite.speed_scale = 1.0
	modular_upper_fx_sprite.play(fx_animation)
	return true


func _play_block_animation(phase_key: StringName) -> void:
	var profile := get_current_combat_profile()
	var resolved := _get_weapon_animation_name(profile, String(phase_key), phase_key)

	if _is_current_profile_unarmed() and modular_locomotion_layers_enabled \
		and _play_modular_unarmed_block(String(resolved)):
		animated_sprite.visible = false
		return

	if animated_sprite == null:
		return
	animated_sprite.visible = true
	animated_sprite.flip_h = _is_facing_left(aim_direction)
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(resolved):
		animated_sprite.play(resolved)
	if not _is_current_profile_unarmed():
		_play_block_weapon_overlay(phase_key)


func _play_modular_unarmed_block(base_animation: String) -> bool:
	if modular_lower_body_sprite == null or modular_upper_body_sprite == null:
		return false
	if modular_lower_body_sprite.sprite_frames == null or modular_upper_body_sprite.sprite_frames == null:
		return false

	var direction := aim_direction if aim_direction.length_squared() > 0.001 else visual_idle_direction
	var resolved_base := "unarmed_block_enter" if base_animation == "unarmed_block_exit" else base_animation

	if base_animation == "unarmed_block_exit":
		# Exit: lower body uses directional locomotion (modular walking),
		# only upper body plays the exit animation (enter played backwards).
		var lower_base := _get_modular_lower_body_motion_base()
		var lower_direction := movement_direction if velocity.length() > 0.01 else visual_idle_direction
		if not _sync_modular_lower_body_layer(lower_base, lower_direction, 1.0):
			return false
		var upper_anim := AnimationResolver.resolve(resolved_base, direction, modular_upper_body_sprite)
		if not _has_playable_sprite_animation(modular_upper_body_sprite.sprite_frames, upper_anim):
			return false
		modular_upper_body_sprite.visible = true
		modular_upper_body_sprite.flip_h = false
		modular_upper_body_sprite.speed_scale = guard_exit_speed_scale
		modular_upper_body_sprite.play_backwards(upper_anim)
		animated_sprite.visible = false
		return true

	if base_animation == "unarmed_block_hold" and velocity.length() > 0.01:
		return _sync_modular_block_hold_movement_presentation()

	# Enter / hold / hitreact: both layers play the same animation
	var lower_anim := AnimationResolver.resolve(resolved_base, direction, modular_lower_body_sprite)
	var upper_anim := AnimationResolver.resolve(resolved_base, direction, modular_upper_body_sprite)
	if not _has_playable_sprite_animation(modular_lower_body_sprite.sprite_frames, lower_anim):
		return false
	if not _has_playable_sprite_animation(modular_upper_body_sprite.sprite_frames, upper_anim):
		return false

	_hide_modular_locomotion_layers()
	modular_lower_body_sprite.visible = true
	modular_lower_body_sprite.speed_scale = 1.0
	modular_upper_body_sprite.visible = true
	modular_upper_body_sprite.speed_scale = 1.0
	modular_lower_body_sprite.play(lower_anim)
	modular_upper_body_sprite.play(upper_anim)
	return true


func _sync_modular_block_hold_movement_presentation() -> bool:
	if _block_phase != &"hold":
		return false
	if not _is_current_profile_unarmed() or not modular_locomotion_layers_enabled:
		return false
	if modular_lower_body_sprite == null or modular_upper_body_sprite == null:
		return false
	if modular_lower_body_sprite.sprite_frames == null or modular_upper_body_sprite.sprite_frames == null:
		return false

	var upper_direction := aim_direction if aim_direction.length_squared() > 0.001 else visual_idle_direction
	if upper_direction.length_squared() <= 0.001:
		upper_direction = Vector2.DOWN
	var upper_anim := AnimationResolver.resolve("unarmed_block_hold", upper_direction, modular_upper_body_sprite)
	if not _has_playable_sprite_animation(modular_upper_body_sprite.sprite_frames, upper_anim):
		return false

	var lower_synced := false
	if velocity.length() > 0.01:
		var lower_direction := movement_direction if movement_direction.length_squared() > 0.001 else visual_idle_direction
		if lower_direction.length_squared() <= 0.001:
			lower_direction = upper_direction
		lower_synced = _sync_modular_lower_body_layer("unarmed_walk", lower_direction, clampf(block_move_multiplier, 0.2, 1.0))
	if not lower_synced:
		var lower_anim := AnimationResolver.resolve("unarmed_block_hold", upper_direction, modular_lower_body_sprite)
		if not _has_playable_sprite_animation(modular_lower_body_sprite.sprite_frames, lower_anim):
			return false
		modular_lower_body_sprite.visible = true
		modular_lower_body_sprite.flip_h = false
		modular_lower_body_sprite.speed_scale = 1.0
		if modular_lower_body_sprite.animation != lower_anim or not modular_lower_body_sprite.is_playing():
			modular_lower_body_sprite.play(lower_anim)

	modular_upper_body_sprite.visible = true
	modular_upper_body_sprite.flip_h = false
	modular_upper_body_sprite.speed_scale = 1.0
	if modular_upper_body_sprite.animation != upper_anim or not modular_upper_body_sprite.is_playing():
		modular_upper_body_sprite.play(upper_anim)
	if modular_upper_fx_sprite != null:
		modular_upper_fx_sprite.visible = false
	_hide_modular_cape_layer()
	animated_sprite.visible = false
	return true


func _is_modular_block_active() -> bool:
	return modular_locomotion_layers_enabled \
		and _is_current_profile_unarmed() \
		and modular_lower_body_sprite != null \
		and modular_lower_body_sprite.visible \
		and _is_block_state_active()


func _is_block_animation_finished() -> bool:
	if _is_modular_block_active() and modular_upper_body_sprite != null:
		return not modular_upper_body_sprite.is_playing()
	return animated_sprite != null and not animated_sprite.is_playing()


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
		animated_sprite.speed_scale = _get_melee_animation_speed_scale(attack_key)
		animated_sprite.play(resolved_animation)
		_play_melee_overlay_from_key(attack_key)
		_sync_melee_hitbox_window_from_animation()
		return true
	var right_fallback := StringName("%s_right" % String(base_animation))
	if animated_sprite.sprite_frames and _has_playable_sprite_animation(animated_sprite.sprite_frames, right_fallback):
		animated_sprite.speed_scale = _get_melee_animation_speed_scale(attack_key)
		animated_sprite.play(right_fallback)
		return true
	if animated_sprite.sprite_frames and _has_playable_sprite_animation(animated_sprite.sprite_frames, base_animation):
		animated_sprite.speed_scale = _get_melee_animation_speed_scale(attack_key)
		animated_sprite.play(base_animation)
		return true
	if animated_sprite.sprite_frames and _has_playable_sprite_animation(animated_sprite.sprite_frames, &"attack_right_old"):
		animated_sprite.speed_scale = _get_melee_animation_speed_scale(attack_key)
		animated_sprite.play("attack_right_old")
		return true
	return false


func _warn_missing_animation_once(animation_name: String, fallback_name: String) -> void:
	if _missing_animation_warnings.has(animation_name):
		return
	_missing_animation_warnings[animation_name] = true
	push_warning("Missing operator animation '%s'; using '%s' fallback" % [animation_name, fallback_name])


func _has_playable_sprite_animation(sprite_frames: SpriteFrames, animation_name: StringName) -> bool:
	if sprite_frames == null:
		return false
	return sprite_frames.has_animation(animation_name) and sprite_frames.get_frame_count(animation_name) > 0


func _get_melee_animation_speed_scale(attack_key: String) -> float:
	if attack_key.begins_with("melee_fast") or attack_key.begins_with("unarmed_fast"):
		return max(0.1, melee_fast_animation_speed_scale)
	return 1.0


func _get_current_melee_animation_duration(fallback_duration: float, min_duration: float, max_duration: float) -> float:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return fallback_duration
	var animation_name: StringName = animated_sprite.animation
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return fallback_duration
	var fps: float = animated_sprite.sprite_frames.get_animation_speed(animation_name) * max(0.1, animated_sprite.speed_scale)
	if fps <= 0.001:
		return fallback_duration
	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(animation_name)
	return clampf(float(frame_count) / fps, min_duration, max_duration)


func _lock_melee_cooldown(duration: float) -> void:
	var profile := _active_attack_profile if _active_attack_profile != null else get_current_combat_profile()
	if _active_melee_attack_profile != null:
		duration = max(duration, _active_melee_attack_profile.cooldown_sec)
	elif profile != null:
		duration *= profile.recovery_multiplier
	melee_cooldown_remaining = duration
	last_fire_cooldown = max(last_fire_cooldown, duration)
	fire_cooldown_remaining = max(fire_cooldown_remaining, melee_cooldown_remaining)


func _configure_melee_hitbox(damage: float, attack_range: float, attack_arc_degrees: float) -> void:
	var profile := _active_attack_profile if _active_attack_profile != null else get_current_combat_profile()
	var damage_multiplier := 1.0 if _active_melee_attack_profile != null else (profile.damage_multiplier if profile != null else 1.0)
	var range_multiplier := 1.0 if _active_melee_attack_profile != null else (profile.range_multiplier if profile != null else 1.0)
	_melee_damage_current = damage * damage_multiplier
	if _counter_window_timer > 0.0 and _melee_attack_kind == "fast":
		_melee_damage_current *= parry_counter_damage_multiplier
		_counter_window_timer = 0.0
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
	var window: Dictionary = _get_active_melee_hit_window()
	if weapon_definition != null and weapon_definition.hit_windows is Dictionary:
		var weapon_window: Dictionary = weapon_definition.hit_windows.get(_melee_attack_key, {})
		if not weapon_window.is_empty():
			window = weapon_window
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
		melee_weapon_overlay_sprite.speed_scale = _get_melee_animation_speed_scale(attack_key)
		melee_weapon_overlay_sprite.play(weapon_anim)
	if melee_fx_overlay_sprite and melee_fx_overlay_sprite.sprite_frames and melee_fx_overlay_sprite.sprite_frames.has_animation(fx_anim):
		melee_fx_overlay_sprite.visible = true
		melee_fx_overlay_sprite.flip_h = animated_sprite.flip_h if animated_sprite else false
		melee_fx_overlay_sprite.speed_scale = _get_melee_animation_speed_scale(attack_key)
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
	if modular_upper_body_sprite and modular_upper_body_sprite.visible and not _modular_upper_action_animation.is_empty():
		var frame_count: int = 0
		if modular_upper_body_sprite.sprite_frames:
			frame_count = modular_upper_body_sprite.sprite_frames.get_frame_count(modular_upper_body_sprite.animation)
		if frame_count > 0:
			modular_upper_body_sprite.frame = mini(animated_sprite.frame, frame_count - 1)
	if modular_lower_body_sprite and modular_lower_body_sprite.visible and not _modular_lower_action_animation.is_empty():
		var lower_frame_count: int = 0
		if modular_lower_body_sprite.sprite_frames:
			lower_frame_count = modular_lower_body_sprite.sprite_frames.get_frame_count(modular_lower_body_sprite.animation)
		if lower_frame_count > 0:
			modular_lower_body_sprite.frame = mini(animated_sprite.frame, lower_frame_count - 1)
	if modular_upper_fx_sprite and modular_upper_fx_sprite.visible and not _modular_upper_fx_action_animation.is_empty():
		var fx_frame_count: int = 0
		if modular_upper_fx_sprite.sprite_frames:
			fx_frame_count = modular_upper_fx_sprite.sprite_frames.get_frame_count(modular_upper_fx_sprite.animation)
		if fx_frame_count > 0:
			modular_upper_fx_sprite.frame = mini(animated_sprite.frame, fx_frame_count - 1)
	if primary_weapon_sprite and primary_weapon_sprite.visible and _is_authored_melee_body_stance_active():
		primary_weapon_sprite.flip_h = animated_sprite.flip_h
		primary_weapon_sprite.frame = animated_sprite.frame


func _reset_melee_overlay_visuals() -> void:
	if melee_weapon_overlay_sprite:
		melee_weapon_overlay_sprite.visible = false
		melee_weapon_overlay_sprite.stop()
		melee_weapon_overlay_sprite.frame = 0
		melee_weapon_overlay_sprite.speed_scale = 1.0
	if melee_fx_overlay_sprite:
		melee_fx_overlay_sprite.visible = false
		melee_fx_overlay_sprite.stop()
		melee_fx_overlay_sprite.frame = 0
		melee_fx_overlay_sprite.speed_scale = 1.0
	if not _melee_active and not _melee_fast_windup and not _melee_recovery_active:
		_clear_modular_fast_attack_layers()


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
		if _sync_modular_fast_attack_phase(&"recovery"):
			animated_sprite.visible = false
		else:
			_clear_modular_fast_attack_layers()
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
	_active_attack_profile = null
	_active_melee_attack_profile = null
	_reset_melee_overlay_visuals()


func _spawn_melee_impact(pos: Vector2):
	var parent = get_node_or_null("/root/GameRoot/World/Projectiles")
	var target = parent if parent else get_tree().current_scene
	
	var spark = impact_scene.instantiate()
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
		var power: float = _active_melee_attack_profile.camera_shake_power if _active_melee_attack_profile != null else melee_heavy_camera_shake_power
		if _active_melee_attack_profile == null:
			if _melee_attack_kind == "fast":
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
	var configured_scale: float = _active_melee_attack_profile.hit_stop_scale if _active_melee_attack_profile != null else melee_heavy_hit_stop_scale
	var configured_duration: float = _active_melee_attack_profile.hit_stop_duration if _active_melee_attack_profile != null else melee_heavy_hit_stop_duration
	if _active_melee_attack_profile == null:
		if _melee_attack_kind == "fast":
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


func _handle_field_patch_input() -> void:
	if _is_action_just_pressed_any(["use_field_patch"]):
		start_field_patch()


func _handle_field_patch_interrupt_input() -> void:
	if not _field_patch_active:
		return
	if _is_action_just_pressed_any(["dodge"]):
		cancel_field_patch(&"dodge")
		return
	if _is_action_just_pressed_any(["reload_weapon", "reload"]):
		cancel_field_patch(&"reload")
		return
	if _is_attack_primary_just_pressed() or _is_attack_secondary_chord_just_pressed():
		cancel_field_patch(&"attack")
		return
	if Input.is_action_just_pressed("build") or Input.is_action_just_pressed("repair"):
		cancel_field_patch(&"field_work")


func can_use_field_patch() -> bool:
	if _is_dead:
		return false
	if _field_patch_active:
		return false
	if _field_patch_recovery_timer > 0.0:
		return false
	if field_patch_count <= 0:
		return false
	if current_health >= max_health:
		return false
	if _is_terminal_open() or _is_non_terminal_ui_open() or _is_ui_text_input_focused():
		return false
	if _portal_transition_locked or _portal_arrival_animation_active or _arrn_stabilization_locked:
		return false
	if _reload_active:
		return false
	if _dodge_active or _dodge_recovery_active:
		return false
	if _melee_active or _melee_heavy_anticipating or _melee_fast_windup or _melee_recovery_active:
		return false
	if attack_phase != AttackPhase.NONE:
		return false
	return true


func start_field_patch() -> void:
	if not can_use_field_patch():
		return

	_field_patch_active = true
	_field_patch_timer = maxf(0.05, field_patch_use_duration)
	_field_patch_committed = false
	is_sprinting = false
	is_sneaking = false
	_exit_ranged_ready()
	_cancel_reload()
	field_patch_state_changed.emit(true, false)
	_obs_increment(&"field_patch_started", 1)
	_obs_log(&"field_patch_started", {
		"position": global_position,
		"health": current_health,
		"max_health": max_health,
		"patches_remaining": field_patch_count,
		"use_duration": field_patch_use_duration,
	})


func cancel_field_patch(reason: StringName = &"unknown") -> void:
	if not _field_patch_active:
		return
	if _field_patch_committed:
		return

	_field_patch_active = false
	_field_patch_timer = 0.0
	_field_patch_committed = false
	field_patch_state_changed.emit(false, false)
	print("[FieldPatch] interrupted: ", reason)
	_obs_increment(&"field_patch_cancelled", 1)
	_obs_log(&"field_patch_cancelled", {
		"reason": String(reason),
		"position": global_position,
		"health": current_health,
		"patches_remaining": field_patch_count,
	})


func _update_field_patch(delta: float) -> void:
	_field_patch_recovery_timer = maxf(0.0, _field_patch_recovery_timer - delta)

	if not _field_patch_active:
		return

	if _is_dead:
		cancel_field_patch(&"dead")
		return
	if _is_terminal_open() or _is_non_terminal_ui_open() or _is_ui_text_input_focused():
		cancel_field_patch(&"ui")
		return
	if _portal_transition_locked or _portal_arrival_animation_active or _arrn_stabilization_locked:
		cancel_field_patch(&"runtime_lock")
		return

	_field_patch_timer -= delta
	if _field_patch_timer <= 0.0:
		_commit_field_patch()


func _commit_field_patch() -> void:
	if not _field_patch_active or _field_patch_committed:
		return

	_field_patch_committed = true
	_field_patch_active = false
	_field_patch_timer = 0.0
	_field_patch_recovery_timer = maxf(0.0, field_patch_recovery_duration)

	field_patch_count = max(0, field_patch_count - 1)
	var restore_amount := max_health * field_patch_restore_fraction
	restore_health(restore_amount)

	field_patch_changed.emit(field_patch_count, field_patch_max_count)
	field_patch_state_changed.emit(false, true)
	print("[FieldPatch] restored ", restore_amount, " hp")
	_obs_increment(&"field_patch_committed", 1)
	_obs_log(&"field_patch_committed", {
		"position": global_position,
		"restore_amount": restore_amount,
		"health": current_health,
		"max_health": max_health,
		"patches_remaining": field_patch_count,
	})
	_obs_gauge(&"player_health", current_health)
	_obs_gauge(&"field_patches_remaining", field_patch_count)


func restore_health(amount: float) -> void:
	if _is_dead:
		return

	var applied := maxf(0.0, amount)
	if applied <= 0.0:
		return

	current_health = minf(max_health, current_health + applied)
	health = current_health
	health_changed.emit(current_health, max_health)
	update_visuals()


func add_field_patches(amount: int) -> int:
	var before := field_patch_count
	field_patch_count = clampi(field_patch_count + maxi(0, amount), 0, field_patch_max_count)
	if field_patch_count != before:
		field_patch_changed.emit(field_patch_count, field_patch_max_count)
	return field_patch_count - before


func get_field_patch_status() -> Dictionary:
	return {
		"count": field_patch_count,
		"max": field_patch_max_count,
		"active": _field_patch_active,
		"time_remaining": _field_patch_timer,
		"use_duration": field_patch_use_duration,
		"recovery_remaining": _field_patch_recovery_timer,
	}


func _handle_reload_input() -> void:
	if _is_action_just_pressed_any(["reload_weapon", "reload"]):
		_try_start_reload()


func _is_action_just_pressed_any(action_names: Array) -> bool:
	for action_name in action_names:
		var normalized_name := StringName(str(action_name))
		if InputMap.has_action(normalized_name) and Input.is_action_just_pressed(normalized_name):
			return true
	return false


func _is_action_pressed_any(action_names: Array) -> bool:
	for action_name in action_names:
		var normalized_name := StringName(str(action_name))
		if InputMap.has_action(normalized_name) and Input.is_action_pressed(normalized_name):
			return true
	return false


func _handle_dodge_input() -> void:
	if not _is_action_just_pressed_any(["dodge"]):
		return
	_try_start_dodge()


func _try_start_dodge() -> bool:
	if not _can_start_dodge():
		return false
	_parry_neutral_lock_active = false
	_dodge_direction = _resolve_dodge_direction()
	_dodge_backstep_active = _is_dodge_backstep_request(_dodge_direction)
	_dodge_active = true
	_dodge_recovery_active = false
	_dodge_timer = maxf(0.05, dodge_duration)
	_dodge_iframe_timer = minf(maxf(0.0, dodge_iframe_duration), _dodge_timer)
	_dodge_recovery_timer = 0.0
	_dodge_cooldown_remaining = maxf(dodge_cooldown, _dodge_timer + maxf(0.0, dodge_recovery_duration))
	stamina = maxf(0.0, stamina - dodge_stamina_cost)
	is_sprinting = false
	is_sneaking = false
	_exit_ranged_ready()
	_cancel_reload()
	velocity = _dodge_direction * dodge_speed
	movement_direction = _dodge_direction
	visual_idle_direction = aim_direction.normalized() if _is_aiming_for_facing() and aim_direction.length_squared() > 0.0001 else _dodge_direction
	_play_dodge_animation(true)
	_obs_increment(&"player_dodges_started", 1)
	_obs_log(&"player_dodge_started", {
		"position": global_position,
		"direction": _dodge_direction,
		"backstep": _dodge_backstep_active,
		"duration": dodge_duration,
		"iframe_duration": dodge_iframe_duration,
		"cooldown": _dodge_cooldown_remaining,
		"stamina": stamina,
	})
	_obs_gauge(&"player_stamina", stamina)
	return true


func _can_start_dodge() -> bool:
	if _dodge_active or _dodge_recovery_active or _dodge_cooldown_remaining > 0.0:
		return false
	if _is_dead or _enemy_impact_lock_timer > 0.0 or _is_terminal_open() or _is_ui_text_input_focused():
		return false
	if _portal_transition_locked or _portal_arrival_animation_active or _arrn_stabilization_locked:
		return false
	if _field_patch_active:
		return false
	if _melee_active or _melee_heavy_anticipating or _melee_fast_windup or _melee_recovery_active or _is_block_state_active():
		return false
	return stamina >= dodge_stamina_cost


func _resolve_dodge_direction() -> Vector2:
	var move_vector := _get_move_input_vector()
	if move_vector.length_squared() > 0.04:
		return move_vector.normalized()
	if _is_aiming_for_facing() and aim_direction.length_squared() > 0.0001:
		return -aim_direction.normalized()
	if visual_idle_direction.length_squared() > 0.0001:
		return visual_idle_direction.normalized()
	if movement_direction.length_squared() > 0.0001:
		return movement_direction.normalized()
	return Vector2.DOWN


func _is_dodge_backstep_request(dodge_direction: Vector2) -> bool:
	if not _is_aiming_for_facing() or aim_direction.length_squared() <= 0.0001:
		return false
	return dodge_direction.normalized().dot(-aim_direction.normalized()) > 0.95


func _update_dodge(delta: float) -> void:
	_dodge_timer = maxf(0.0, _dodge_timer - delta)
	var remaining_ratio := _dodge_timer / maxf(0.05, dodge_duration)
	var eased_speed := dodge_speed * lerpf(0.45, 1.0, remaining_ratio)
	velocity = _dodge_direction * eased_speed
	if _dodge_timer <= 0.0:
		_dodge_active = false
		_start_dodge_recovery()


func _start_dodge_recovery() -> void:
	_dodge_iframe_timer = 0.0
	_dodge_recovery_timer = maxf(0.0, dodge_recovery_duration)
	if _dodge_recovery_timer <= 0.0 or not _has_dodge_recovery_animation():
		_dodge_recovery_active = false
		velocity = velocity.move_toward(Vector2.ZERO, move_deceleration * get_physics_process_delta_time())
		return
	_dodge_recovery_active = true
	_play_dodge_recovery_animation(true)


func _update_dodge_recovery(delta: float) -> void:
	_dodge_recovery_timer = maxf(0.0, _dodge_recovery_timer - delta)
	velocity = velocity.move_toward(Vector2.ZERO, move_deceleration * delta)
	if _dodge_recovery_timer <= 0.0:
		_dodge_recovery_active = false
		_dodge_backstep_active = false
		_hide_dodge_fx()


func _cancel_dodge() -> void:
	_dodge_active = false
	_dodge_recovery_active = false
	_dodge_timer = 0.0
	_dodge_iframe_timer = 0.0
	_dodge_recovery_timer = 0.0
	_dodge_backstep_active = false
	_hide_dodge_fx()


func _is_dodge_invulnerable() -> bool:
	return _dodge_active and _dodge_iframe_timer > 0.0 and not _is_dead


func is_dodge_invulnerable() -> bool:
	return _is_dodge_invulnerable()


func _should_ignore_incoming_damage_for_dodge(source: String = "") -> bool:
	if not _is_dodge_invulnerable():
		return false
	if dodge_iframe_debug_enabled:
		print("[Operator] Dodge i-frame avoided incoming damage: ", source)
	_obs_increment(&"player_iframe_avoids", 1)
	_obs_log(&"player_damage_avoided_by_iframe", {
		"source": source,
		"position": global_position,
		"dodge_timer": _dodge_timer,
		"iframe_timer": _dodge_iframe_timer,
		"direction": _dodge_direction,
	})
	return true


func _play_dodge_animation(force_restart: bool = false) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	_hide_modular_locomotion_layers()
	_update_primary_weapon_visual(false)
	animated_sprite.flip_h = _is_facing_left(_dodge_direction)
	animated_sprite.speed_scale = 1.0
	var animation_name := _get_dodge_step_animation()
	if animated_sprite.sprite_frames.has_animation(animation_name):
		if force_restart or animated_sprite.animation != animation_name or not animated_sprite.is_playing():
			if force_restart:
				animated_sprite.set_frame_and_progress(0, 0.0)
			animated_sprite.play(animation_name)
	_play_dodge_fx(force_restart)


func _play_dodge_recovery_animation(force_restart: bool = false) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	_hide_modular_locomotion_layers()
	_update_primary_weapon_visual(false)
	animated_sprite.flip_h = _is_facing_left(_dodge_direction)
	animated_sprite.speed_scale = 1.0
	if _is_full_dodge_animation(animated_sprite.animation):
		return
	var animation_name := _get_dodge_recovery_animation()
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return
	if force_restart or animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		if force_restart:
			animated_sprite.set_frame_and_progress(0, 0.0)
		animated_sprite.play(animation_name)


func _get_dodge_step_animation() -> StringName:
	var full_animation := _get_full_dodge_animation()
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(full_animation):
		return full_animation
	if _dodge_backstep_active and animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(DODGE_BACKSTEP_ANIMATION):
		return DODGE_BACKSTEP_ANIMATION
	return DODGE_STEP_ANIMATION


func _get_full_dodge_animation() -> StringName:
	return DODGE_FULL_NORTH_ANIMATION if _dodge_direction.y < -0.05 else DODGE_FULL_SOUTH_ANIMATION


func _get_full_dodge_fx_animation() -> StringName:
	return DODGE_FULL_NORTH_FX_ANIMATION if _dodge_direction.y < -0.05 else DODGE_FULL_SOUTH_FX_ANIMATION


func _is_full_dodge_animation(animation_name: StringName) -> bool:
	return animation_name == DODGE_FULL_NORTH_ANIMATION or animation_name == DODGE_FULL_SOUTH_ANIMATION


func _get_dodge_recovery_animation() -> StringName:
	if _dodge_backstep_active and animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(DODGE_BACKSTEP_RECOVERY_ANIMATION):
		return DODGE_BACKSTEP_RECOVERY_ANIMATION
	return DODGE_RECOVERY_ANIMATION


func _has_dodge_recovery_animation() -> bool:
	return animated_sprite != null \
		and animated_sprite.sprite_frames != null \
		and (
			animated_sprite.sprite_frames.has_animation(_get_full_dodge_animation())
			or animated_sprite.sprite_frames.has_animation(_get_dodge_recovery_animation())
		)


func _play_dodge_fx(force_restart: bool = false) -> void:
	if dodge_fx_back_sprite == null or dodge_fx_back_sprite.sprite_frames == null:
		return
	var animation_name := _get_full_dodge_fx_animation()
	if not dodge_fx_back_sprite.sprite_frames.has_animation(animation_name):
		animation_name = DODGE_STEP_FX_ANIMATION
	if not dodge_fx_back_sprite.sprite_frames.has_animation(animation_name):
		return
	dodge_fx_back_sprite.visible = true
	dodge_fx_back_sprite.z_index = -1
	dodge_fx_back_sprite.modulate = Color(1.0, 1.0, 1.0, DODGE_FX_BACK_ALPHA)
	dodge_fx_back_sprite.position = _dodge_fx_back_base_position + _body_recoil_offset + _fake_elevation_visual_offset + _get_dodge_fx_back_offset(_dodge_direction)
	dodge_fx_back_sprite.flip_h = _is_facing_left(_dodge_direction)
	dodge_fx_back_sprite.speed_scale = 1.0
	if force_restart or dodge_fx_back_sprite.animation != animation_name or not dodge_fx_back_sprite.is_playing():
		if force_restart:
			dodge_fx_back_sprite.set_frame_and_progress(0, 0.0)
		dodge_fx_back_sprite.play(animation_name)


func _hide_dodge_fx() -> void:
	if dodge_fx_back_sprite == null:
		return
	dodge_fx_back_sprite.visible = false
	dodge_fx_back_sprite.stop()
	dodge_fx_back_sprite.frame = 0
	dodge_fx_back_sprite.speed_scale = 1.0
	dodge_fx_back_sprite.position = _dodge_fx_back_base_position + _body_recoil_offset + _fake_elevation_visual_offset


func _get_dodge_fx_back_offset(direction: Vector2) -> Vector2:
	var direction_suffix := _get_direction_suffix(direction)
	return DODGE_FX_BACK_OFFSET_BY_DIRECTION.get(direction_suffix, Vector2.ZERO)


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
	if _is_dead or _melee_active or _melee_heavy_anticipating or _melee_fast_windup or _melee_recovery_active or _is_block_state_active() or _reload_active:
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


func _is_ranged_context_active() -> bool:
	return _is_ranged_loadout_active() or _is_ranged_ready_active()


func _get_active_ranged_weapon_definition() -> OperatorWeaponDefinition:
	if _ranged_ready_weapon_definition != null:
		return _ranged_ready_weapon_definition
	return _get_primary_ranged_weapon_definition()


func _get_primary_ranged_weapon_definition() -> OperatorWeaponDefinition:
	if primary_weapon_definition is OperatorWeaponDefinition:
		var ranged_weapon := primary_weapon_definition as OperatorWeaponDefinition
		if ranged_weapon.weapon_kind == "ranged" or String(ranged_weapon.weapon_type).begins_with("ranged"):
			return ranged_weapon
	return null


func _get_sidearm_weapon_definition() -> OperatorWeaponDefinition:
	if not sidearm_slot_equipped:
		return null
	if sidearm_weapon_definition == null:
		return null
	if sidearm_weapon_definition.weapon_kind == "ranged" or String(sidearm_weapon_definition.weapon_type).begins_with("ranged"):
		return sidearm_weapon_definition
	return null


func _get_ranged_ready_candidate_weapon_definition() -> OperatorWeaponDefinition:
	var mode := _get_offhand_secondary_mode()
	if mode == &"parry_guard":
		return null
	var equipped_weapon = _get_equipped_primary_weapon_definition()
	if mode == &"primary_ranged_ready" and equipped_weapon is OperatorWeaponDefinition:
		var equipped_definition := equipped_weapon as OperatorWeaponDefinition
		if equipped_definition.weapon_kind == "ranged" or String(equipped_definition.weapon_type).begins_with("ranged"):
			return equipped_definition
	if mode != &"sidearm_ready":
		return null
	var sidearm := _get_sidearm_weapon_definition()
	if sidearm != null:
		return sidearm
	return null


func _is_using_sidearm_ranged() -> bool:
	return _is_ranged_ready_active() and _ranged_ready_weapon_definition == _get_sidearm_weapon_definition()


func grant_sidearm(definition: OperatorWeaponDefinition = null) -> Dictionary:
	if definition != null:
		sidearm_weapon_definition = definition
	if sidearm_weapon_definition == null:
		return {
			"granted": false,
			"weapon_id": &"",
			"loaded": _ammo_standard_loaded,
			"reserve": ammo_standard,
		}
	_configure_weapon_definition_defaults(sidearm_weapon_definition, "P-9 Sidearm", "ranged", "ranged_unfocused_fire", "ranged_ready")
	sidearm_slot_equipped = true
	_register_weapon_ammo_state(sidearm_weapon_definition, true)
	var sidearm_type := _get_weapon_ammo_type(sidearm_weapon_definition)
	var sidearm_reserve: int = _get_sidearm_initial_reserve(sidearm_weapon_definition)
	if int(ammo_reserve_by_type.get(sidearm_type, 0)) <= 0 and sidearm_reserve > 0:
		ammo_reserve_by_type[sidearm_type] = min(int(ammo_capacity_by_type.get(sidearm_type, sidearm_reserve)), sidearm_reserve)
	_sync_legacy_ammo_fields()
	_refresh_primary_weapon_state()
	_update_primary_weapon_visual(false)
	update_visuals()
	return {
		"granted": true,
		"weapon_id": sidearm_weapon_definition.weapon_id,
		"loaded": int(loaded_ammo_by_weapon_id.get(_get_weapon_state_key(sidearm_weapon_definition), 0)),
		"reserve": int(ammo_reserve_by_type.get(sidearm_type, 0)),
	}


## Remove the sidearm, returning ammo to reserve and updating visuals.
## Returns a Dictionary with {released: bool, weapon_id: StringName}.
func remove_sidearm() -> Dictionary:
	if not sidearm_slot_equipped:
		return {"released": false, "weapon_id": &""}
	
	var weapon_id := &""
	if sidearm_weapon_definition != null:
		weapon_id = sidearm_weapon_definition.weapon_id
		var sidearm_key := _get_weapon_state_key(sidearm_weapon_definition)
		var sidearm_type := _get_weapon_ammo_type(sidearm_weapon_definition)
		var loaded := int(loaded_ammo_by_weapon_id.get(sidearm_key, 0))
		ammo_reserve_by_type[sidearm_type] = min(int(ammo_capacity_by_type.get(sidearm_type, 0)), int(ammo_reserve_by_type.get(sidearm_type, 0)) + loaded)
		loaded_ammo_by_weapon_id.erase(sidearm_key)
		_sync_legacy_ammo_fields()
	
	sidearm_slot_equipped = false
	
	# Switch out of sidearm ranged mode if active
	if combat_loadout_mode == LOADOUT_RANGED and _ranged_ready_weapon_definition == _get_sidearm_weapon_definition():
		_exit_ranged_ready()
		combat_loadout_mode = LOADOUT_MELEE
		_refresh_primary_weapon_state()
	
	_refresh_primary_weapon_state()
	_update_primary_weapon_visual(false)
	update_visuals()
	
	return {"released": true, "weapon_id": weapon_id}


func _is_using_melee_weapon_sprite() -> bool:
	if _is_ranged_ready_active():
		return false
	if combat_loadout_mode != LOADOUT_MELEE:
		return false
	var weapon_definition = _get_equipped_primary_weapon_definition()
	if weapon_definition == null:
		return false
	return String(weapon_definition.weapon_type).begins_with("melee")


func _ensure_target_ring() -> void:
	if _target_ring != null and is_instance_valid(_target_ring):
		return
	if _target_ring_pending or TARGET_RING_SCENE == null:
		return
	_target_ring_pending = true
	call_deferred("_ensure_target_ring_deferred")


func _ensure_target_ring_deferred() -> void:
	_target_ring_pending = false
	if not is_inside_tree():
		return
	if _target_ring != null and is_instance_valid(_target_ring):
		return
	var ring = TARGET_RING_SCENE.instantiate()
	if ring == null:
		return
	var ring_node := ring as Node2D
	if ring_node == null:
		ring.queue_free()
		return
	ring_node.visible = false
	var parent = get_node_or_null("/root/GameRoot/World/Projectiles")
	if parent:
		parent.add_child(ring_node)
	elif get_tree() != null and get_tree().current_scene != null:
		get_tree().current_scene.add_child(ring_node)
	else:
		ring_node.queue_free()
		return
	_target_ring = ring_node


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
	if _combat_target.has_method("has_active_critical_target_reticle") and bool(_combat_target.call("has_active_critical_target_reticle")):
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
	var intent := String(profile.primary_intent) if profile != null else "melee_fast"
	var base_range := melee_range
	var base_arc := melee_arc_degrees
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
	var spawn_position: Vector2 = _get_ranged_muzzle_position(direction)
	flash.rotation = direction.angle()
	var parent = get_node_or_null("/root/GameRoot/World/Projectiles")
	if parent:
		parent.add_child(flash)
	else:
		get_tree().current_scene.add_child(flash)
	flash.global_position = spawn_position


func _get_ranged_muzzle_position(direction: Vector2) -> Vector2:
	var modular_position := _get_modular_ranged_muzzle_position(direction)
	if modular_position != Vector2.INF:
		return modular_position
	if barrel:
		return barrel.global_position
	return global_position + direction.normalized() * muzzle_offset


func _get_modular_ranged_muzzle_position(direction: Vector2) -> Vector2:
	if modular_sidearm_sprite == null:
		return Vector2.INF
	var suffix := ""
	if _is_using_sidearm_ranged() and _sidearm_action_phase == &"firing":
		suffix = _get_sidearm_muzzle_suffix(direction)
		if MODULAR_SIDEARM_MUZZLE_OFFSETS.has(suffix):
			return modular_sidearm_sprite.global_position + MODULAR_SIDEARM_MUZZLE_OFFSETS[suffix]
	elif _is_primary_ranged_fire_presentation_active() or _is_primary_ranged_fire_recover_presentation_active():
		suffix = String(_primary_ranged_fire_suffix_for_direction(direction))
		if MODULAR_PRIMARY_RANGED_MUZZLE_OFFSETS.has(suffix):
			return modular_sidearm_sprite.global_position + MODULAR_PRIMARY_RANGED_MUZZLE_OFFSETS[suffix]
	return Vector2.INF


func _get_sidearm_muzzle_suffix(direction: Vector2) -> String:
	var resolved := direction
	if resolved.length_squared() <= 0.0001:
		resolved = _sidearm_action_direction
	if resolved.length_squared() <= 0.0001:
		resolved = aim_direction
	if resolved.length_squared() <= 0.0001:
		resolved = Vector2.DOWN
	var vertical := "up" if resolved.y < 0.0 else "down"
	var horizontal := "left" if resolved.x < 0.0 else "right"
	return "%s_%s" % [vertical, horizontal]


func _spawn_damage_popup(amount: float) -> void:
	var popup := DAMAGE_POPUP_SCENE.instantiate()
	popup.text = str(int(amount))
	popup.modulate = Color(1, 0.3, 0.3, 1)
	get_tree().current_scene.add_child(popup)
	popup.global_position = global_position + Vector2(randf_range(-10, 10), -30)


func _has_ammo() -> bool:
	return _has_loaded_ammo()


func _is_using_ranged_weapon_visual() -> bool:
	if not _is_ranged_context_active():
		return false
	var weapon_definition = _get_active_ranged_weapon_definition() if _is_ranged_ready_active() else _get_equipped_primary_weapon_definition()
	if weapon_definition is OperatorWeaponDefinition:
		var weapon_type := String((weapon_definition as OperatorWeaponDefinition).weapon_type)
		return (weapon_definition as OperatorWeaponDefinition).weapon_kind == "ranged" or weapon_type.begins_with("ranged")
	return primary_weapon_equipped and equipped_primary_weapon_id == PRIMARY_WEAPON_CARBINE


func _is_using_ranged_2h_primary() -> bool:
	if not _is_ranged_context_active():
		return false
	var weapon_definition = _get_active_ranged_weapon_definition() if _is_ranged_ready_active() else _get_equipped_primary_weapon_definition()
	if weapon_definition != null:
		return String(weapon_definition.weapon_type) == "ranged_2h"
	return primary_weapon_equipped and equipped_primary_weapon_id == PRIMARY_WEAPON_CARBINE


func _is_blocking() -> bool:
	return _block_active


func _is_block_state_active() -> bool:
	return not _block_phase.is_empty()


func _is_movement_locked() -> bool:
	return _reload_active or _portal_transition_locked or _portal_arrival_animation_active or _arrn_stabilization_locked


func _has_attack_movement_modifier() -> bool:
	_refresh_attack_phase_state()
	return attack_phase != AttackPhase.NONE


func _get_attack_move_multiplier() -> float:
	_refresh_attack_phase_state()
	if attack_phase == AttackPhase.NONE:
		return 1.0
	var profile := _get_current_attack_move_profile()
	match attack_phase:
		AttackPhase.STARTUP:
			return float(profile.get("startup_move", 0.75))
		AttackPhase.ACTIVE:
			return float(profile.get("active_move", 0.5))
		AttackPhase.RECOVERY:
			return float(profile.get("recovery_move", 0.75))
		_:
			return 1.0


func _is_attack_turn_locked() -> bool:
	_refresh_attack_phase_state()
	if attack_phase == AttackPhase.NONE:
		return false
	return bool(_get_current_attack_move_profile().get("turn_locked", false))


func _get_current_attack_move_profile() -> Dictionary:
	if _active_melee_attack_profile != null:
		return _get_active_melee_movement_profile()
	if current_attack_id.is_empty():
		return {}
	return ATTACK_MOVE_PROFILES.get(current_attack_id, {})


func _refresh_attack_phase_state() -> void:
	if _melee_heavy_anticipating or _melee_fast_windup:
		if current_attack_id.is_empty():
			current_attack_id = _resolve_current_attack_id()
		attack_phase = AttackPhase.STARTUP
		attack_phase_time_remaining = float(_get_current_attack_move_profile().get("startup_time", 0.18))
		return
	if _melee_active:
		if current_attack_id.is_empty():
			current_attack_id = _resolve_current_attack_id()
		var profile := _get_current_attack_move_profile()
		var startup_time := float(profile.get("startup_time", 0.08))
		var active_time := float(profile.get("active_time", 0.12))
		if _melee_elapsed < startup_time:
			attack_phase = AttackPhase.STARTUP
			attack_phase_time_remaining = startup_time - _melee_elapsed
		elif _melee_elapsed < startup_time + active_time:
			attack_phase = AttackPhase.ACTIVE
			attack_phase_time_remaining = startup_time + active_time - _melee_elapsed
		else:
			attack_phase = AttackPhase.RECOVERY
			attack_phase_time_remaining = max(0.0, _melee_duration - _melee_elapsed)
		return
	if _melee_recovery_active:
		if current_attack_id.is_empty():
			current_attack_id = _resolve_current_attack_id()
		attack_phase = AttackPhase.RECOVERY
		attack_phase_time_remaining = _melee_recovery_timer
		return
	if _is_ranged_fire_animation_active():
		current_attack_id = "ranged_fire"
		attack_phase = AttackPhase.ACTIVE if _pending_ranged_shot.is_empty() else AttackPhase.STARTUP
		attack_phase_time_remaining = max(fire_cooldown_remaining, 0.0)
		attack_facing_dir = aim_direction if aim_direction.length_squared() > 0.0001 else visual_idle_direction
		return
	attack_phase = AttackPhase.NONE
	current_attack_id = ""
	attack_phase_time_remaining = 0.0


func _begin_attack_movement_profile(attack_id: String, facing_dir: Vector2) -> void:
	current_attack_id = attack_id
	attack_phase = AttackPhase.STARTUP
	attack_phase_time_remaining = float(_get_current_attack_move_profile().get("startup_time", 0.08))
	if facing_dir.length_squared() > 0.0001:
		attack_facing_dir = facing_dir.normalized()


func _resolve_current_attack_id() -> String:
	if _active_melee_attack_profile != null and not String(_active_melee_attack_profile.attack_id).is_empty():
		return String(_active_melee_attack_profile.attack_id)
	if _melee_attack_key.begins_with("unarmed_heavy"):
		return "unarmed_heavy"
	if _melee_attack_key.begins_with("unarmed_fast"):
		return "unarmed_fast"
	if _melee_attack_kind == "heavy":
		return "melee_heavy"
	if _melee_attack_kind == "fast":
		return "unarmed_fast" if _is_attack_profile_unarmed(_active_attack_profile) else "melee_fast"
	return "melee_fast"


func _is_ranged_fire_animation_active() -> bool:
	return _is_ranged_context_active() and (not _pending_ranged_shot.is_empty() or fire_cooldown_remaining > 0.0)


func _is_ranged_firing_move_state() -> bool:
	return _is_ranged_fire_animation_active() and velocity.length() > 0.01 and not is_sprinting


func _get_ranged_firing_move_multiplier() -> float:
	var multiplier := ranged_firing_move_multiplier
	var weapon_definition = _get_active_ranged_weapon_definition()
	if weapon_definition is OperatorWeaponDefinition:
		var handling_multiplier := 1.0 + (weapon_definition as OperatorWeaponDefinition).get_handling_float("movement_speed_penalty", (weapon_definition as OperatorWeaponDefinition).movement_speed_penalty)
		multiplier *= max(0.2, handling_multiplier)
	return clampf(multiplier, 0.15, 1.0)


func _get_current_ranged_body_fire_animation(is_moving: bool) -> StringName:
	var weapon_definition = _get_active_ranged_weapon_definition()
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
	var weapon_definition = _get_active_ranged_weapon_definition()
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
	var runtime_frames := animated_sprite.sprite_frames.duplicate() as SpriteFrames
	if runtime_frames == null:
		return
	var changed := false
	if not runtime_frames.has_animation(RANGED_FIRE_WALK_ANIMATION):
		var fire_walk_texture: Texture2D = _load_optional_texture(ranged_2h_fire_walk_sheet_path, null)
		if fire_walk_texture != null:
			var fire_walk_frame_count: int = max(1, fire_walk_texture.get_width() / RANGED_FIRE_WALK_FRAME_WIDTH)
			_add_sheet_animation(runtime_frames, String(RANGED_FIRE_WALK_ANIMATION), fire_walk_texture, fire_walk_frame_count, true, RANGED_FIRE_WALK_BASE_FPS)
			changed = true
	changed = _ensure_optional_sheet_animation(
		runtime_frames,
		DODGE_STEP_ANIMATION,
		[DODGE_STEP_RUNTIME_SHEET_PATH, DODGE_STEP_SHEET_PATH],
		false,
		18.0
	) or changed
	changed = _ensure_optional_sheet_animation(
		runtime_frames,
		DODGE_RECOVERY_ANIMATION,
		[DODGE_RECOVERY_RUNTIME_SHEET_PATH],
		false,
		18.0
	) or changed
	changed = _ensure_optional_sheet_animation(
		runtime_frames,
		DODGE_BACKSTEP_ANIMATION,
		[DODGE_BACKSTEP_RUNTIME_SHEET_PATH],
		false,
		18.0
	) or changed
	changed = _ensure_optional_sheet_animation(
		runtime_frames,
		DODGE_BACKSTEP_RECOVERY_ANIMATION,
		[DODGE_BACKSTEP_RECOVERY_RUNTIME_SHEET_PATH],
		false,
		18.0
	) or changed
	changed = _ensure_optional_sheet_animation(
		runtime_frames,
		DODGE_FULL_NORTH_ANIMATION,
		[DODGE_FULL_NORTH_SHEET_PATH],
		false,
		DODGE_FULL_SEQUENCE_FPS
	) or changed
	changed = _ensure_optional_sheet_animation(
		runtime_frames,
		DODGE_FULL_SOUTH_ANIMATION,
		[DODGE_FULL_SOUTH_SHEET_PATH],
		false,
		DODGE_FULL_SEQUENCE_FPS
	) or changed
	if changed:
		animated_sprite.sprite_frames = runtime_frames
	_ensure_dodge_fx_animation()


func _ensure_optional_sheet_animation(
	runtime_frames: SpriteFrames,
	animation_name: StringName,
	sheet_paths: Array,
	loop: bool,
	fps: float
) -> bool:
	if runtime_frames.has_animation(animation_name):
		return false
	for sheet_path in sheet_paths:
		var texture: Texture2D = _load_optional_texture(String(sheet_path), null)
		if texture == null:
			continue
		var frame_count: int = max(1, texture.get_width() / 96)
		_add_sheet_animation(runtime_frames, String(animation_name), texture, frame_count, loop, fps)
		return true
	return false


func _ensure_dodge_fx_animation() -> void:
	if dodge_fx_back_sprite == null:
		return
	if dodge_fx_back_sprite.sprite_frames == null:
		dodge_fx_back_sprite.sprite_frames = SpriteFrames.new()
	var runtime_fx_frames := dodge_fx_back_sprite.sprite_frames.duplicate() as SpriteFrames
	if runtime_fx_frames == null:
		return
	var changed := false
	changed = _ensure_optional_sheet_animation(runtime_fx_frames, DODGE_FULL_NORTH_FX_ANIMATION, [DODGE_FULL_NORTH_FX_SHEET_PATH], false, DODGE_FULL_SEQUENCE_FPS) or changed
	changed = _ensure_optional_sheet_animation(runtime_fx_frames, DODGE_FULL_SOUTH_FX_ANIMATION, [DODGE_FULL_SOUTH_FX_SHEET_PATH], false, DODGE_FULL_SEQUENCE_FPS) or changed
	changed = _ensure_optional_sheet_animation(runtime_fx_frames, DODGE_STEP_FX_ANIMATION, [DODGE_STEP_FX_SHEET_PATH], false, 18.0) or changed
	if changed:
		dodge_fx_back_sprite.sprite_frames = runtime_fx_frames


func _update_body_recoil(delta: float) -> void:
	if _body_recoil_offset == Vector2.ZERO:
		return
	_body_recoil_offset = _body_recoil_offset.move_toward(Vector2.ZERO, BODY_RECOIL_RECOVERY_RATE * delta)
	_apply_body_recoil_offset()


func _apply_body_recoil_impulse(direction: Vector2) -> void:
	var recoil_pixels := float(BODY_RECOIL_PROFILE_PIXELS.get("recoil_standard", 1.0))
	var weapon_definition = _get_active_ranged_weapon_definition()
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
		animated_sprite.position = _animated_sprite_base_position + _body_recoil_offset + _fake_elevation_visual_offset
	if dodge_fx_back_sprite:
		var dodge_offset := _get_dodge_fx_back_offset(_dodge_direction) if _dodge_active else Vector2.ZERO
		dodge_fx_back_sprite.position = _dodge_fx_back_base_position + _body_recoil_offset + _fake_elevation_visual_offset + dodge_offset
	if modular_cape_sprite:
		modular_cape_sprite.position = _modular_cape_base_position + _body_recoil_offset + _fake_elevation_visual_offset
	if modular_lower_body_sprite:
		modular_lower_body_sprite.position = _modular_lower_body_base_position + _body_recoil_offset + _fake_elevation_visual_offset
	if modular_upper_body_sprite:
		modular_upper_body_sprite.position = _modular_upper_body_base_position + _body_recoil_offset + _fake_elevation_visual_offset
	if modular_sidearm_sprite:
		modular_sidearm_sprite.position = _modular_sidearm_base_position + _body_recoil_offset + _fake_elevation_visual_offset
	if modular_upper_fx_sprite:
		modular_upper_fx_sprite.position = _modular_upper_fx_base_position + _body_recoil_offset + _fake_elevation_visual_offset
	if melee_weapon_overlay_sprite:
		melee_weapon_overlay_sprite.position = _melee_weapon_overlay_base_position + _body_recoil_offset + _fake_elevation_visual_offset
	if melee_fx_overlay_sprite:
		melee_fx_overlay_sprite.position = _melee_fx_overlay_base_position + _body_recoil_offset + _fake_elevation_visual_offset


func set_fake_elevation(value: float) -> void:
	fake_elevation = max(0.0, value)
	_sync_fake_elevation_visual_state()


func set_movement_surface_multiplier(value: float) -> void:
	movement_surface_multiplier = max(0.0, value)


func _query_movement_surface_multiplier(actor_kind: String) -> float:
	if get_tree() == null:
		return 1.0
	for map_node in get_tree().get_nodes_in_group("procgen_tilemap"):
		if map_node != null and map_node.has_method("get_movement_surface_multiplier_at_global"):
			return float(map_node.call("get_movement_surface_multiplier_at_global", global_position, actor_kind))
	return 1.0


func _sync_fake_elevation_visual_state() -> void:
	var t := clampf(fake_elevation / 24.0, 0.0, 1.0)
	_fake_elevation_visual_offset = Vector2(0.0, -fake_elevation * fake_elevation_visual_lift_factor)
	z_index = _base_world_z_index + int(round(fake_elevation * fake_elevation_z_scale))
	if blob_shadow:
		blob_shadow.scale = Vector2.ONE.lerp(Vector2(0.65, 0.65), t)
		blob_shadow.modulate = Color(1.0, 1.0, 1.0, lerpf(1.0, 0.55, t))
		blob_shadow.queue_redraw()
	_apply_body_recoil_offset()


func _wants_block() -> bool:
	if not _is_melee_loadout_active() or _is_terminal_open():
		return false
	if Input.is_action_pressed("block"):
		return true
	return _get_offhand_secondary_mode() == &"parry_guard" \
		and _is_attack_secondary_pressed() \
		and not _guard_repress_required_after_parry_success \
		and (_guard_requested_from_secondary or _block_phase in [&"enter", &"hold", &"hitreact"])





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
	if not FileAccess.file_exists(path):
		return fallback
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
		or Input.is_action_pressed("fire_primary") \
		or Input.is_action_pressed("attack_secondary") \
		or Input.is_action_pressed("aim_hold") \
		or Input.is_action_pressed("dodge") \
		or Input.is_action_pressed("toggle_unarmed") \
		or Input.is_action_pressed("reload_weapon") \
		or Input.is_action_pressed("reload") \
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
	if dodge_fx_back_sprite:
		dodge_fx_back_sprite.position = placeholder_sprite_position
		dodge_fx_back_sprite.offset = placeholder_sprite_offset
	if modular_cape_sprite:
		modular_cape_sprite.position = placeholder_sprite_position
		modular_cape_sprite.offset = placeholder_sprite_offset
	if modular_lower_body_sprite:
		modular_lower_body_sprite.position = placeholder_sprite_position
		modular_lower_body_sprite.offset = placeholder_sprite_offset
	if modular_upper_body_sprite:
		modular_upper_body_sprite.position = placeholder_sprite_position
		modular_upper_body_sprite.offset = placeholder_sprite_offset
	if modular_sidearm_sprite:
		modular_sidearm_sprite.position = placeholder_sprite_position
		modular_sidearm_sprite.offset = placeholder_sprite_offset
	if modular_upper_fx_sprite:
		modular_upper_fx_sprite.position = placeholder_sprite_position
		modular_upper_fx_sprite.offset = placeholder_sprite_offset
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
	if dodge_fx_back_sprite:
		_dodge_fx_back_base_position = dodge_fx_back_sprite.position
	if modular_cape_sprite:
		_modular_cape_base_position = modular_cape_sprite.position
	if modular_lower_body_sprite:
		_modular_lower_body_base_position = modular_lower_body_sprite.position
	if modular_upper_body_sprite:
		_modular_upper_body_base_position = modular_upper_body_sprite.position
	if modular_sidearm_sprite:
		_modular_sidearm_base_position = modular_sidearm_sprite.position
	if modular_upper_fx_sprite:
		_modular_upper_fx_base_position = modular_upper_fx_sprite.position
	if melee_weapon_overlay_sprite:
		_melee_weapon_overlay_base_position = melee_weapon_overlay_sprite.position
	if melee_fx_overlay_sprite:
		_melee_fx_overlay_base_position = melee_fx_overlay_sprite.position


func _apply_dynamic_weapon_socket_layout(weapon_definition = null) -> void:
	if weapon_definition == null:
		weapon_definition = _get_active_ranged_weapon_definition() if _is_ranged_ready_active() else _get_equipped_primary_weapon_definition()
	var aim_state := _get_weapon_aim_state()
	var facing_left := _is_facing_left(aim_direction) and _is_using_ranged_weapon_visual()
	
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
	if _is_using_melee_weapon_sprite() and not _is_ranged_ready_active():
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
	if _is_primary_ranged_aim_presentation_active() or _is_primary_ranged_fire_presentation_active():
		_hide_legacy_primary_ranged_presentation_for_modular_fire()
		return
	if _knight_test_skin_active:
		_hide_custom_operator_visual_layers()
		if primary_weapon_socket:
			primary_weapon_socket.rotation = 0.0
		return
	if _is_using_sidearm_ranged():
		if primary_weapon_socket:
			primary_weapon_socket.rotation = 0.0
		if primary_weapon_sprite:
			primary_weapon_sprite.visible = false
			primary_weapon_sprite.stop()
		if ranged_fx_overlay_sprite:
			ranged_fx_overlay_sprite.visible = false
			ranged_fx_overlay_sprite.stop()
		return
	var is_melee_mode = _is_using_melee_weapon_sprite() and not _is_ranged_ready_active()
	var show_attack_weapon_overlay := is_melee_mode and (_melee_active or _melee_heavy_anticipating or _melee_fast_windup or _melee_recovery_active)
	var show_block_weapon_overlay := is_melee_mode and _is_block_state_active()
	if melee_weapon_overlay_sprite:
		melee_weapon_overlay_sprite.visible = show_attack_weapon_overlay or show_block_weapon_overlay
		if not melee_weapon_overlay_sprite.visible:
			melee_weapon_overlay_sprite.stop()
			melee_weapon_overlay_sprite.frame = 0
	if melee_fx_overlay_sprite:
		melee_fx_overlay_sprite.visible = (_melee_active and not _melee_attack_kind.is_empty()) or _melee_recovery_active
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
	if _is_using_melee_weapon_sprite() and not _is_ranged_ready_active():
		if primary_weapon_socket:
			primary_weapon_socket.rotation = 0.0
		var using_attack_overlay := _melee_active or _melee_heavy_anticipating or _melee_fast_windup
		primary_weapon_sprite.visible = not using_attack_overlay and not _is_block_state_active()
		primary_weapon_sprite.flip_h = animated_sprite.flip_h if animated_sprite else false
		var melee_stance_anim := _get_weapon_animation_name(_get_equipped_primary_weapon_definition(), "melee_stance", &"melee_stance")
		if primary_weapon_sprite.visible and primary_weapon_sprite.sprite_frames and primary_weapon_sprite.sprite_frames.has_animation(melee_stance_anim):
			if primary_weapon_sprite.animation != melee_stance_anim or not primary_weapon_sprite.is_playing():
				primary_weapon_sprite.play(melee_stance_anim)
		return
	if not _is_using_ranged_weapon_visual():
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
	var ranged_weapon_definition = _get_active_ranged_weapon_definition()
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
		ranged_weapon_definition,
		"ranged_fire" if is_firing else "ranged_stance",
		&"ranged_2h_fire" if is_firing else &"ranged_2h_stance"
	)
	if not is_firing and is_sprinting and velocity.length() > 0.0 and primary_weapon_sprite.sprite_frames:
		var sprinting_left := _is_facing_left(velocity)
		if sprinting_left and primary_weapon_sprite.sprite_frames.has_animation("equipped_run_left"):
			target_animation = &"equipped_run_left"
			primary_weapon_sprite.flip_h = false
		elif primary_weapon_sprite.sprite_frames.has_animation("equipped_run_right"):
			target_animation = &"equipped_run_right"
			primary_weapon_sprite.flip_h = sprinting_left
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
	var weapon_definition = _get_active_ranged_weapon_definition() if _is_ranged_ready_active() else _get_equipped_primary_weapon_definition()
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
	elif _is_using_ranged_weapon_visual():
		var ranged_stance_anim := _get_weapon_animation_name(_get_active_ranged_weapon_definition(), "ranged_stance", &"ranged_2h_stance")
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
	_animation_state_machine.register_state(AttackFastState.new())
	_animation_state_machine.register_state(AttackHeavyState.new())
	_animation_state_machine.register_state(DeathState.new())
	_animation_state_machine.current_state = "idle"


func _update_animation_state_machine(delta: float) -> void:
	if _animation_state_machine == null:
		return
	if _portal_transition_locked or _portal_arrival_animation_active:
		return
	_animation_state_machine._process(delta)
	if _melee_active or _melee_heavy_anticipating or _melee_fast_windup:
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


func play_portal_arrival_animation() -> bool:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false
	var animation_name := PORTAL_ARRIVAL_DOWN_ANIMATION
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		animation_name = PORTAL_ARRIVAL_ANIMATION
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return false
	_portal_transition_locked = false
	_portal_arrival_animation_active = true
	velocity = Vector2.ZERO
	is_sprinting = false
	movement_direction = Vector2.DOWN
	visual_idle_direction = Vector2.DOWN
	animated_sprite.flip_h = false
	animated_sprite.speed_scale = 1.0
	_hide_custom_operator_visual_layers()
	if primary_weapon_socket:
		primary_weapon_socket.rotation = 0.0
	_update_idle_loop_tracking(false, "")
	animated_sprite.play(animation_name)
	return true


func set_portal_transition_locked(locked: bool) -> void:
	_portal_transition_locked = locked
	if locked:
		velocity = Vector2.ZERO
		is_sprinting = false
		_clear_attack_buffer()


func set_arrn_stabilization_locked(locked: bool) -> void:
	_arrn_stabilization_locked = locked
	if locked:
		velocity = Vector2.ZERO
		is_sprinting = false
		_clear_attack_buffer()


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
	
	var finished_animation := String(animated_sprite.animation)
	if _portal_arrival_animation_active and (finished_animation == String(PORTAL_ARRIVAL_ANIMATION) or finished_animation == String(PORTAL_ARRIVAL_DOWN_ANIMATION)):
		_portal_arrival_animation_active = false
		animated_sprite.speed_scale = 1.0
		_update_primary_weapon_visual(false)
		_update_animation()
		return
	if _melee_heavy_anticipating and finished_animation.begins_with("melee_2h_heavy_anticipation"):
		_begin_heavy_attack_active_phase()
	if _melee_fast_windup and finished_animation.begins_with("unarmed_attack_fast_windup"):
		_begin_fast_attack_strike_phase()


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


func _consume_ammo() -> void:
	var key := _get_active_weapon_state_key()
	var cost := _get_current_ammo_per_shot()
	loaded_ammo_by_weapon_id[key] = max(0, int(loaded_ammo_by_weapon_id.get(key, 0)) - cost)
	_sync_legacy_ammo_fields()


func _initialize_magazines() -> void:
	ammo_capacity_by_type = {
		"kinetic_light": ammo_standard_max,
		"kinetic_heavy": ammo_heavy_max,
		"energy_cell": 40,
		"shell": 16,
		"scrap_charge": 16,
	}
	ammo_reserve_by_type = {
		"kinetic_light": clampi(ammo_standard, 0, ammo_standard_max),
		"kinetic_heavy": clampi(ammo_heavy, 0, ammo_heavy_max),
		"energy_cell": 0,
		"shell": 0,
		"scrap_charge": 0,
	}
	loaded_ammo_by_weapon_id.clear()
	_register_weapon_ammo_state(primary_weapon_definition, true)
	if sidearm_slot_equipped:
		_register_weapon_ammo_state(sidearm_weapon_definition, true)
	_sync_legacy_ammo_fields()


func _normalize_ammo_type(ammo_type: String) -> String:
	return "kinetic_light" if ammo_type == "kinetic" or ammo_type.is_empty() else ammo_type


func _get_weapon_ammo_type(weapon_definition: OperatorWeaponDefinition) -> String:
	if weapon_definition == null:
		return "kinetic_light"
	return _normalize_ammo_type(String(weapon_definition.get_ammo_value("ammo_type", weapon_definition.ammo_type)))


func _get_weapon_state_key(weapon_definition: OperatorWeaponDefinition) -> String:
	if weapon_definition == null:
		return "fallback_ranged"
	return String(weapon_definition.weapon_id) if not String(weapon_definition.weapon_id).is_empty() else str(weapon_definition.get_instance_id())


func _get_active_weapon_state_key() -> String:
	return _get_weapon_state_key(_get_active_ranged_weapon_definition())


func _register_weapon_ammo_state(weapon_definition: OperatorWeaponDefinition, fill_magazine: bool = false) -> void:
	if weapon_definition == null:
		return
	var ammo_type := _get_weapon_ammo_type(weapon_definition)
	var max_reserve := int(weapon_definition.get_ammo_value("max_reserve", weapon_definition.max_reserve_ammo))
	ammo_capacity_by_type[ammo_type] = max(int(ammo_capacity_by_type.get(ammo_type, 0)), max_reserve)
	if not ammo_reserve_by_type.has(ammo_type):
		var starting_reserve := int(weapon_definition.get_ammo_value("starting_reserve", weapon_definition.get_ammo_value("reserve", weapon_definition.reserve_ammo)))
		ammo_reserve_by_type[ammo_type] = clampi(starting_reserve, 0, int(ammo_capacity_by_type[ammo_type]))
	var key := _get_weapon_state_key(weapon_definition)
	if not loaded_ammo_by_weapon_id.has(key):
		loaded_ammo_by_weapon_id[key] = _get_weapon_magazine_size(weapon_definition) if fill_magazine else 0


func _get_weapon_magazine_size(weapon_definition: OperatorWeaponDefinition) -> int:
	if weapon_definition == null:
		return ammo_standard_magazine_size
	return max(1, int(weapon_definition.get_ammo_value("magazine_size", weapon_definition.get_ammo_value("capacity", weapon_definition.get_stat_int("magazine_size", weapon_definition.magazine_size)))))


func _get_standard_magazine_size() -> int:
	var weapon_definition := _get_active_ranged_weapon_definition()
	if weapon_definition != null:
		return _get_weapon_magazine_size(weapon_definition)
	return ammo_standard_magazine_size


func _get_heavy_magazine_size() -> int:
	return ammo_heavy_magazine_size


func _get_current_magazine_size() -> int:
	return _get_standard_magazine_size()


func _get_current_loaded_ammo() -> int:
	var weapon_definition := _get_active_ranged_weapon_definition()
	_register_weapon_ammo_state(weapon_definition)
	return int(loaded_ammo_by_weapon_id.get(_get_weapon_state_key(weapon_definition), 0))


func _get_current_reserve_ammo() -> int:
	var weapon_definition := _get_active_ranged_weapon_definition()
	_register_weapon_ammo_state(weapon_definition)
	return int(ammo_reserve_by_type.get(_get_weapon_ammo_type(weapon_definition), 0))


func _get_current_ammo_per_shot() -> int:
	var weapon_definition := _get_active_ranged_weapon_definition()
	if weapon_definition == null:
		return 1
	return max(1, int(weapon_definition.get_ammo_value("ammo_per_shot", weapon_definition.ammo_per_shot)))


func _get_sidearm_initial_reserve(weapon_definition: OperatorWeaponDefinition) -> int:
	if weapon_definition == null:
		return 0
	var weapon_data := weapon_definition.get_weapon_data()
	var ammo_data: Variant = weapon_data.get("ammo", {})
	if ammo_data is Dictionary:
		return max(0, int((ammo_data as Dictionary).get("starting_reserve", (ammo_data as Dictionary).get("reserve", weapon_definition.reserve_ammo))))
	return max(0, weapon_definition.reserve_ammo)


func _clamp_loaded_ammo_to_current_weapon() -> void:
	var capacity := _get_current_magazine_size()
	var key := _get_active_weapon_state_key()
	var loaded := int(loaded_ammo_by_weapon_id.get(key, 0))
	if loaded <= capacity:
		return
	var ammo_type := _get_weapon_ammo_type(_get_active_ranged_weapon_definition())
	var overflow := loaded - capacity
	loaded_ammo_by_weapon_id[key] = capacity
	ammo_reserve_by_type[ammo_type] = min(int(ammo_capacity_by_type.get(ammo_type, 0)), int(ammo_reserve_by_type.get(ammo_type, 0)) + overflow)
	_sync_legacy_ammo_fields()


func _has_loaded_ammo() -> bool:
	if not _is_ranged_context_active():
		return false
	return _get_current_loaded_ammo() > 0


func _get_current_reload_duration() -> float:
	var weapon_definition := _get_active_ranged_weapon_definition()
	if weapon_definition != null:
		return max(0.05, weapon_definition.get_stat_float("reload_time_sec", ranged_reload_duration))
	return ranged_reload_duration


func _can_reload() -> bool:
	if not _is_ranged_context_active() or _reload_active:
		return false
	if _field_patch_active:
		return false
	if _melee_active or _melee_heavy_anticipating or _melee_fast_windup or _melee_recovery_active or _is_block_state_active():
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
	var weapon_definition := _get_active_ranged_weapon_definition()
	var key := _get_weapon_state_key(weapon_definition)
	var ammo_type := _get_weapon_ammo_type(weapon_definition)
	var loaded := int(loaded_ammo_by_weapon_id.get(key, 0))
	var reserve := int(ammo_reserve_by_type.get(ammo_type, 0))
	var transfer: int = mini(maxi(0, capacity - loaded), reserve)
	loaded_ammo_by_weapon_id[key] = loaded + transfer
	ammo_reserve_by_type[ammo_type] = reserve - transfer
	_sync_legacy_ammo_fields()
	_cancel_reload()


func _cancel_reload() -> void:
	_reload_active = false
	_reload_timer = 0.0


func add_ammo(standard: int, heavy: int) -> Dictionary:
	var gained_std := add_ammo_type("kinetic_light", standard)
	var gained_hvy := add_ammo_type("kinetic_heavy", heavy)
	print("AMMO CACHE COLLECTED: +", gained_std, " STD / +", gained_hvy, " HVY")
	return {
		"standard": gained_std,
		"heavy": gained_hvy,
	}


func add_ammo_type(ammo_type: String, amount: int) -> int:
	var normalized := _normalize_ammo_type(ammo_type)
	var capacity := int(ammo_capacity_by_type.get(normalized, 0))
	if capacity <= 0:
		return 0
	var old_amount := int(ammo_reserve_by_type.get(normalized, 0))
	ammo_reserve_by_type[normalized] = clampi(old_amount + max(0, amount), 0, capacity)
	_sync_legacy_ammo_fields()
	return int(ammo_reserve_by_type[normalized]) - old_amount


func _sync_legacy_ammo_fields() -> void:
	ammo_standard = int(ammo_reserve_by_type.get("kinetic_light", ammo_standard))
	ammo_heavy = int(ammo_reserve_by_type.get("kinetic_heavy", ammo_heavy))
	ammo_standard_max = int(ammo_capacity_by_type.get("kinetic_light", ammo_standard_max))
	ammo_heavy_max = int(ammo_capacity_by_type.get("kinetic_heavy", ammo_heavy_max))
	_ammo_standard_loaded = int(loaded_ammo_by_weapon_id.get(_get_active_weapon_state_key(), _ammo_standard_loaded))


func _get_active_heat_key() -> String:
	return _get_active_weapon_state_key()


func _get_active_weapon_heat() -> float:
	return float(weapon_heat_by_id.get(_get_active_heat_key(), 0.0))


func _is_active_weapon_overheated() -> bool:
	return float(weapon_overheat_by_id.get(_get_active_heat_key(), 0.0)) > 0.0


func _apply_heat_for_shot() -> void:
	var weapon_definition := _get_active_ranged_weapon_definition()
	if weapon_definition == null or not weapon_definition.get_heat_bool("enabled", weapon_definition.heat_enabled):
		return
	var key := _get_weapon_state_key(weapon_definition)
	var heat_max := maxf(1.0, weapon_definition.get_heat_float("max", weapon_definition.heat_max))
	var heat_per_shot := weapon_definition.get_heat_float("per_shot", weapon_definition.heat_per_shot) * weapon_definition.heat_per_shot_mult
	var new_heat := minf(heat_max, float(weapon_heat_by_id.get(key, 0.0)) + heat_per_shot)
	weapon_heat_by_id[key] = new_heat
	weapon_heat_delay_by_id[key] = weapon_definition.get_heat_float("decay_delay_sec", weapon_definition.heat_decay_delay_sec)
	var threshold := weapon_definition.get_heat_float("overheat_threshold", weapon_definition.overheat_threshold)
	if new_heat >= threshold and float(weapon_overheat_by_id.get(key, 0.0)) <= 0.0:
		weapon_overheat_by_id[key] = weapon_definition.get_heat_float("overheat_lockout_sec", weapon_definition.overheat_lockout_sec) * weapon_definition.overheat_lockout_mult


func _update_weapon_heat(delta: float) -> void:
	for weapon_variant in [primary_weapon_definition, sidearm_weapon_definition]:
		if not (weapon_variant is OperatorWeaponDefinition):
			continue
		var weapon_definition := weapon_variant as OperatorWeaponDefinition
		if not weapon_definition.get_heat_bool("enabled", weapon_definition.heat_enabled):
			continue
		var key := _get_weapon_state_key(weapon_definition)
		var delay := maxf(0.0, float(weapon_heat_delay_by_id.get(key, 0.0)) - delta)
		weapon_heat_delay_by_id[key] = delay
		var previous_lockout := float(weapon_overheat_by_id.get(key, 0.0))
		var lockout := maxf(0.0, previous_lockout - delta)
		weapon_overheat_by_id[key] = lockout
		if delay > 0.0:
			continue
		var decay := weapon_definition.get_heat_float("decay_per_sec", weapon_definition.heat_decay_per_sec) * weapon_definition.heat_decay_mult
		if lockout > 0.0:
			decay *= 1.5
		weapon_heat_by_id[key] = maxf(0.0, float(weapon_heat_by_id.get(key, 0.0)) - decay * delta)
		if previous_lockout > 0.0 and lockout <= 0.0:
			var heat_max := maxf(1.0, weapon_definition.get_heat_float("max", weapon_definition.heat_max))
			weapon_heat_by_id[key] = minf(float(weapon_heat_by_id[key]), heat_max * 0.7)


func _get_heat_ratio() -> float:
	var weapon_definition := _get_active_ranged_weapon_definition()
	if weapon_definition == null:
		return 0.0
	return clampf(_get_active_weapon_heat() / maxf(1.0, weapon_definition.get_heat_float("max", weapon_definition.heat_max)), 0.0, 1.0)


func _get_heat_spread_multiplier() -> float:
	var weapon_definition := _get_active_ranged_weapon_definition()
	if weapon_definition == null:
		return 1.0
	return lerpf(1.0, weapon_definition.get_heat_float("spread_mult_at_max", weapon_definition.heat_spread_mult_at_max), _get_heat_ratio())


func _get_heat_recoil_multiplier() -> float:
	var weapon_definition := _get_active_ranged_weapon_definition()
	if weapon_definition == null:
		return 1.0
	return lerpf(1.0, weapon_definition.get_heat_float("recoil_mult_at_max", weapon_definition.heat_recoil_mult_at_max), _get_heat_ratio())


func _get_movement_spread_multiplier() -> float:
	var weapon_definition := _get_active_ranged_weapon_definition()
	if weapon_definition == null:
		return 1.0
	if is_sneaking:
		return weapon_definition.get_handling_float("sneak_spread_mult", 0.75)
	if is_sprinting:
		return weapon_definition.get_handling_float("sprinting_spread_mult", 2.25)
	if velocity.length_squared() > 1.0:
		return weapon_definition.get_handling_float("walking_spread_mult", 1.35)
	return weapon_definition.get_handling_float("standing_spread_mult", 0.85)


func _emit_weapon_noise(position: Vector2) -> void:
	var weapon_definition := _get_active_ranged_weapon_definition()
	if weapon_definition == null:
		return
	var bus := get_node_or_null("/root/NoiseEventBus")
	if bus == null or not bus.has_method("emit_at"):
		return
	var suppressed := weapon_definition.get_noise_bool("suppressed", weapon_definition.suppressed)
	var radius := weapon_definition.get_noise_float("shot_radius_px", weapon_definition.shot_noise_radius_px)
	if suppressed:
		radius *= weapon_definition.get_noise_float("suppressed_radius_mult", weapon_definition.suppressed_radius_mult)
	bus.call("emit_at", self, position, radius, &"gunshot", weapon_definition.get_noise_float("alert_threat_value", weapon_definition.alert_threat_value), weapon_definition.get_noise_float("shot_loudness", weapon_definition.shot_loudness), suppressed, &"player")


func get_weapon_status() -> Dictionary:
	var profile := _get_current_ranged_profile()
	var ranged_context_active := _is_ranged_context_active()
	var ranged_weapon_definition := _get_active_ranged_weapon_definition() if ranged_context_active else null
	var ammo_type := _get_weapon_ammo_type(ranged_weapon_definition) if ranged_weapon_definition != null else ""
	var heat_max := maxf(1.0, ranged_weapon_definition.get_heat_float("max", ranged_weapon_definition.heat_max)) if ranged_weapon_definition != null else 100.0
	var heat := _get_active_weapon_heat() if ranged_weapon_definition != null else 0.0
	var noise_radius := ranged_weapon_definition.get_noise_float("shot_radius_px", ranged_weapon_definition.shot_noise_radius_px) if ranged_weapon_definition != null else 0.0
	var is_suppressed := ranged_weapon_definition.get_noise_bool("suppressed", ranged_weapon_definition.suppressed) if ranged_weapon_definition != null else false
	if is_suppressed and ranged_weapon_definition != null:
		noise_radius *= ranged_weapon_definition.get_noise_float("suppressed_radius_mult", ranged_weapon_definition.suppressed_radius_mult)
	var cooldown_total = max(last_fire_cooldown, float(profile["cooldown"]))
	var weapon_name := "CARBINE"
	var display_profile := ranged_weapon_definition if ranged_weapon_definition != null else get_current_combat_profile()
	if display_profile != null and not display_profile.display_name.is_empty():
		weapon_name = display_profile.display_name.to_upper()
	elif display_profile != null:
		var weapon_data: Dictionary = display_profile.get_weapon_data()
		weapon_name = str(weapon_data.get("name", weapon_name)).to_upper()
	return {
		"equipped": primary_weapon_equipped,
		"primary_weapon_id": equipped_primary_weapon_id,
		"weapon_name": weapon_name,
		"ranged_context_active": ranged_context_active,
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
		"last_fire_failure": String(last_ranged_fire_failure),
		"ammo_type": ammo_type,
		"loaded_ammo": _get_current_loaded_ammo() if ranged_weapon_definition != null else 0,
		"reserve_ammo": _get_current_reserve_ammo() if ranged_weapon_definition != null else 0,
		"max_reserve_ammo": int(ammo_capacity_by_type.get(ammo_type, 0)),
		"magazine_size": _get_current_magazine_size() if ranged_weapon_definition != null else 0,
		"heat": heat,
		"heat_max": heat_max,
		"heat_ratio": heat / heat_max,
		"overheated": _is_active_weapon_overheated(),
		"overheat_remaining": float(weapon_overheat_by_id.get(_get_active_heat_key(), 0.0)),
		"noise_radius_px": noise_radius,
		"suppressed": is_suppressed,
		"effective_range_px": float(profile.get("effective_range_px", 0.0)),
		"max_range_px": float(profile.get("max_range_px", 0.0)),
		"ammo_standard": ammo_standard,
		"ammo_heavy": ammo_heavy,
		"ammo_standard_loaded": _ammo_standard_loaded,
		"ammo_heavy_loaded": _ammo_heavy_loaded,
		"ammo_standard_magazine_size": _get_standard_magazine_size(),
		"ammo_heavy_magazine_size": _get_heavy_magazine_size(),
	}


func get_active_weapon_icon_texture() -> Texture2D:
	var weapon_definition := _get_active_ranged_weapon_definition() if _is_ranged_context_active() else get_current_combat_profile()
	if weapon_definition == null or weapon_definition.frames_resource == null:
		return null
	var frames: SpriteFrames = weapon_definition.frames_resource
	var preferred: Array[StringName] = []
	if weapon_definition.weapon_kind == "ranged" or String(weapon_definition.weapon_type).begins_with("ranged"):
		preferred.append(_get_weapon_animation_name(weapon_definition, "ranged_stance", &"ranged_2h_stance"))
		preferred.append(&"ranged_2h_stance")
		preferred.append(&"stance")
	else:
		preferred.append(_get_weapon_animation_name(weapon_definition, "stance", &""))
		preferred.append(&"stance")
		preferred.append(&"idle")
	for animation_name in preferred:
		if not animation_name.is_empty() and frames.has_animation(animation_name) and frames.get_frame_count(animation_name) > 0:
			return frames.get_frame_texture(animation_name, 0)
	for animation_name in frames.get_animation_names():
		if frames.get_frame_count(animation_name) > 0:
			return frames.get_frame_texture(animation_name, 0)
	return null


func get_sprint_status() -> Dictionary:
	return {
		"is_sprinting": is_sprinting,
		"stamina": stamina,
		"stamina_max": stamina_max,
		"sprint_exhausted": _sprint_exhausted,
	}


func get_stealth_snapshot() -> Dictionary:
	return {
		"is_sneaking": is_sneaking,
		"noise_radius_px": current_noise_radius_px,
		"visibility_mult": stealth_visibility_mult,
		"global_position": global_position,
		"velocity": velocity,
		"is_sprinting": is_sprinting,
		"is_firing": _is_ranged_fire_animation_active() or not _pending_ranged_shot.is_empty(),
		"is_dodging": _dodge_active or _dodge_recovery_active,
		"cover_visibility_mult": 1.0,
		"light_visibility_mult": 1.0,
	}


func _update_stealth_noise_snapshot(moving: bool) -> void:
	var attacking := _melee_active or attack_phase != AttackPhase.NONE
	var firing := _is_ranged_fire_animation_active() or _pending_ranged_shot.size() > 0
	if firing:
		current_noise_radius_px = 45.0
		stealth_visibility_mult = 1.4
	elif attacking:
		current_noise_radius_px = 100.0
		stealth_visibility_mult = 1.0
	elif is_sprinting:
		current_noise_radius_px = 110.0
		stealth_visibility_mult = 1.25
	elif is_sneaking:
		current_noise_radius_px = 18.0
		stealth_visibility_mult = 0.45
	elif moving:
		current_noise_radius_px = 45.0
		stealth_visibility_mult = 1.0
	else:
		current_noise_radius_px = 10.0
		stealth_visibility_mult = 0.9


func _get_move_input_vector() -> Vector2:
	var move_input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if move_input.length_squared() <= 0.0001:
		return Vector2.ZERO
	if move_input.length() > 1.0:
		return move_input.normalized()
	return move_input


func _get_controller_aim_direction() -> Vector2:
	var aim_input := Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)
	if aim_input.length_squared() <= 0.04:
		return Vector2.ZERO
	return aim_input.normalized()


func _is_aiming_for_facing() -> bool:
	return _is_ranged_ready_active() \
		or _is_action_pressed_any(["aim_hold", "attack_secondary"]) \
		or _get_controller_aim_direction() != Vector2.ZERO


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


func _log_incoming_hit_result(
	result: StringName,
	hit_kind: StringName,
	amount: float,
	applied_damage: float,
	attacker: Node2D = null,
	extra: Dictionary = {}
) -> void:
	var data := {
		"result": String(result),
		"hit_kind": String(hit_kind),
		"amount": amount,
		"applied_damage": applied_damage,
		"position": global_position,
		"health": current_health,
		"stamina": stamina,
	}
	if attacker != null and is_instance_valid(attacker):
		data["attacker"] = attacker.name
		data["attacker_position"] = attacker.global_position
	for key in extra.keys():
		data[key] = extra[key]

	_obs_increment(&"incoming_hits_total", 1)
	_obs_increment(StringName("incoming_hit_%s" % String(result)), 1)
	_obs_log(&"incoming_hit_result", data)


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
		_configure_weapon_definition_defaults(primary_weapon_definition, "Carbine Rifle", "ranged", "ranged_unfocused_fire", "ranged_ready")
		_rebuild_armed_weapon_list()
		if ammo_reserve_by_type.is_empty():
			_initialize_magazines()
		else:
			_register_weapon_ammo_state(primary_weapon_definition, true)
			_sync_legacy_ammo_fields()
		print("[Operator] Loaded weapon: ", weapon_id, " | Magazine: ", _get_current_magazine_size())


func unequip_primary_weapon() -> void:
	_holster_all_weapons()


func toggle_primary_carbine() -> void:
	if _is_ranged_loadout_active():
		_holster_all_weapons()
		return
	equip_primary_carbine()


func receive_enemy_hit(amount: float, hit_kind: StringName = &"melee", _attacker_team: String = "enemy", attacker: Node2D = null, hit_direction: Vector2 = Vector2.ZERO, guard_stamina_cost_override: float = -1.0) -> Dictionary:
	var resolved_hit_direction := hit_direction
	if resolved_hit_direction.length_squared() <= 0.001 and attacker != null and is_instance_valid(attacker):
		resolved_hit_direction = attacker.global_position.direction_to(global_position)
	if resolved_hit_direction.length_squared() <= 0.001:
		resolved_hit_direction = -visual_idle_direction.normalized() if visual_idle_direction.length_squared() > 0.001 else Vector2.DOWN

	if try_parry_incoming_attack(attacker, resolved_hit_direction, {"damage": amount, "hit_kind": hit_kind}):
		_log_incoming_hit_result(&"parried", hit_kind, amount, 0.0, attacker)
		return {
			"result": &"parried",
			"hit_kind": hit_kind,
			"dodged": false,
			"blocked": false,
			"parried": true,
			"applied_damage": 0.0,
		}

	if _should_ignore_incoming_damage_for_dodge(String(hit_kind)):
		_log_incoming_hit_result(&"dodged", hit_kind, amount, 0.0, attacker)
		return {
			"result": &"dodged",
			"hit_kind": hit_kind,
			"dodged": true,
			"blocked": false,
			"parried": false,
			"applied_damage": 0.0,
		}

	var guard_result := try_guard_incoming_attack(amount, resolved_hit_direction, guard_stamina_cost_override)
	if bool(guard_result.get("blocked", false)):
		var final_damage := float(guard_result.get("damage", amount))
		if final_damage > 0.0:
			take_damage(final_damage, false)
		_log_incoming_hit_result(&"blocked", hit_kind, amount, final_damage, attacker, {
			"guard_damage": final_damage,
		})
		return {
			"result": &"blocked",
			"hit_kind": hit_kind,
			"dodged": false,
			"parried": false,
			"blocked": true,
			"applied_damage": max(0.0, final_damage),
		}

	if _is_failed_parry_hitreact_context():
		_play_failed_parry_block_hitreact()
		take_damage(amount, false)
		_log_incoming_hit_result(&"damaged", hit_kind, amount, amount, attacker, {
			"block_hitreact": true,
		})
		return {
			"result": &"damaged",
			"hit_kind": hit_kind,
			"dodged": false,
			"parried": false,
			"blocked": false,
			"block_hitreact": true,
			"applied_damage": max(0.0, amount),
		}

	if _is_block_state_active():
		_block_phase = &"exit"
		_block_active = false
		_play_block_animation(&"melee_2h_block_exit")

	take_damage(amount)
	_log_incoming_hit_result(&"damaged", hit_kind, amount, amount, attacker)
	return {
		"result": &"damaged",
		"hit_kind": hit_kind,
		"dodged": false,
		"parried": false,
		"blocked": false,
		"applied_damage": max(0.0, amount),
	}


func receive_projectile_hit(amount: float, _attacker_team: String = "neutral") -> Dictionary:
	return receive_enemy_hit(amount, &"projectile", _attacker_team)

func take_damage(amount: float, trigger_reaction: bool = true):
	if _is_dead:
		return

	if _should_ignore_incoming_damage_for_dodge("take_damage"):
		return

	if amount > 0.0 and _field_patch_active and not _field_patch_committed:
		cancel_field_patch(&"damage")

	health = max(0.0, health - amount)
	current_health = health
	health_changed.emit(current_health, max_health)

	_obs_increment(&"player_hits_taken", 1)
	_obs_log(&"player_damage", {
		"amount": amount,
		"position": global_position,
		"health": health,
		"max_health": max_health,
	})
	_obs_gauge(&"player_health", health)

	var heatmap := get_node_or_null("/root/SectorHeatmap")
	if heatmap != null:
		heatmap.call("add", global_position, "damage_taken", amount)

	var world_history := get_node_or_null("/root/WorldHistory")
	if world_history != null:
		world_history.call("record", "", "player_damage", global_position, {
			"amount": amount,
			"health": health,
		})

	var hit_direction := -aim_direction.normalized() if aim_direction.length_squared() > 0.001 else Vector2.DOWN
	_last_damage_reaction_direction = hit_direction
	_notify_camera_damage_taken(hit_direction)
	update_visuals()
	_spawn_damage_popup(amount)

	if health <= 0.0:
		print("OPERATOR DOWN!")
		_handle_death()
		return

	if trigger_reaction:
		_request_damage_reaction(amount)

	if visual:
		visual.modulate = Color(1, 1, 1)
		await get_tree().create_timer(0.1).timeout
		if not _is_dead:
			update_visuals()


func apply_enemy_dash_impact(direction: Vector2, knockback_px: float, victim_hitstop_sec: float) -> void:
	if _is_dead:
		return

	if _should_ignore_incoming_damage_for_dodge("apply_enemy_dash_impact"):
		return

	if _field_patch_active and not _field_patch_committed:
		cancel_field_patch(&"dash_impact")

	var impact_direction := direction.normalized() if direction.length_squared() > 0.0001 else Vector2.DOWN
	_enemy_impact_lock_timer = maxf(_enemy_impact_lock_timer, maxf(0.16, victim_hitstop_sec + 0.13))
	_last_damage_reaction_direction = impact_direction
	_interrupt_active_combat_for_damage_reaction()
	velocity = impact_direction * (knockback_px / maxf(0.16, _enemy_impact_lock_timer))
	if _animation_state_machine != null:
		_animation_state_machine.request("hit_recoil", 24)
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("on_damage_taken"):
		camera.call("on_damage_taken", impact_direction)


func apply_enemy_falcon_punch_impact(direction: Vector2, knockback_px: float, victim_hitstop_sec: float) -> void:
	if _is_dead:
		return
	if _should_ignore_incoming_damage_for_dodge("apply_enemy_falcon_punch_impact"):
		return
	if _field_patch_active and not _field_patch_committed:
		cancel_field_patch(&"falcon_punch_impact")
	var impact_direction := direction.normalized() if direction.length_squared() > 0.0001 else Vector2.DOWN
	_enemy_impact_lock_timer = maxf(_enemy_impact_lock_timer, maxf(0.13, victim_hitstop_sec + 0.10))
	_last_damage_reaction_direction = impact_direction
	_interrupt_active_combat_for_damage_reaction()
	velocity = impact_direction * (knockback_px / maxf(0.13, _enemy_impact_lock_timer))
	if _animation_state_machine != null:
		_animation_state_machine.request("hit_recoil", 24)
	var camera := get_node_or_null("/root/GameRoot/World/Camera2D")
	if camera != null and camera.has_method("on_damage_taken"):
		camera.call("on_damage_taken", impact_direction)

func _request_damage_reaction(_amount: float) -> void:
	if _animation_state_machine == null:
		return
	_interrupt_active_combat_for_damage_reaction()
	_animation_state_machine.request("hit_recoil", 20)


func get_damage_reaction_animation(_reaction_name: String) -> StringName:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return &""
	var profile := get_current_combat_profile()
	var mapped := _get_weapon_animation_name(profile, "unarmed_light_hitreact", &"") if profile != null else &""
	if mapped == StringName() and unarmed_definition != null:
		mapped = _get_weapon_animation_name(unarmed_definition, "unarmed_light_hitreact", &"")
	if mapped == StringName():
		mapped = &"unarmed_light_hitreact"
	var resolved := AnimationResolver.resolve(String(mapped), _last_damage_reaction_direction, animated_sprite)
	if _has_playable_sprite_animation(animated_sprite.sprite_frames, resolved):
		return resolved
	if _has_playable_sprite_animation(animated_sprite.sprite_frames, &"unarmed_light_hitreact_down"):
		return &"unarmed_light_hitreact_down"
	if _has_playable_sprite_animation(animated_sprite.sprite_frames, &"unarmed_light_hitreact"):
		return &"unarmed_light_hitreact"
	return &""


func play_damage_reaction_fx(_animation_name: StringName) -> void:
	if melee_weapon_overlay_sprite:
		melee_weapon_overlay_sprite.visible = false
		melee_weapon_overlay_sprite.stop()
	if melee_fx_overlay_sprite == null or melee_fx_overlay_sprite.sprite_frames == null:
		return
	var fx_animation := &"unarmed_light_hitreact_fx_down"
	if not melee_fx_overlay_sprite.sprite_frames.has_animation(fx_animation):
		return
	melee_fx_overlay_sprite.visible = true
	melee_fx_overlay_sprite.flip_h = false
	melee_fx_overlay_sprite.speed_scale = 1.0
	melee_fx_overlay_sprite.set_frame_and_progress(0, 0.0)
	melee_fx_overlay_sprite.play(fx_animation)


func _interrupt_active_combat_for_damage_reaction() -> void:
	_buffered_attack_kind = ""
	_buffered_attack_timer = 0.0
	_melee_active = false
	_melee_attack_kind = ""
	_melee_attack_key = ""
	_melee_elapsed = 0.0
	_melee_duration = 0.0
	_melee_heavy_anticipating = false
	_melee_fast_windup = false
	_melee_recovery_active = false
	_melee_recovery_timer = 0.0
	_active_attack_profile = null
	_active_melee_attack_profile = null
	_block_phase = &""
	_block_active = false
	disable_hitbox()
	_melee_hit_targets.clear()
	_reset_melee_overlay_visuals()

func _handle_death() -> void:
	if _is_dead:
		return
	_is_dead = true
	cancel_field_patch(&"dead")
	_obs_increment(&"player_deaths", 1)
	_obs_log(&"player_death", {
		"position": global_position,
	})
	_obs_gauge(&"player_health", 0.0)
	var heatmap := get_node_or_null("/root/SectorHeatmap")
	if heatmap != null:
		heatmap.call("add", global_position, "player_death", 1.0)
	var world_history := get_node_or_null("/root/WorldHistory")
	if world_history != null:
		world_history.call("record", "", "player_death", global_position, {})
	current_health = 0.0  # Sync with ControllableActor
	health_changed.emit(current_health, max_health)
	_buffered_attack_kind = ""
	_melee_active = false
	_melee_attack_kind = ""
	_melee_attack_key = ""
	_active_attack_profile = null
	_active_melee_attack_profile = null
	fire_cooldown_remaining = 0.0
	melee_cooldown_remaining = 0.0
	is_sprinting = false
	stamina = 0.0
	velocity = Vector2.ZERO
	disable_hitbox()
	if _animation_state_machine != null:
		_animation_state_machine.request("death", 20)
	if animated_sprite and animated_sprite.sprite_frames:
		var death_animation := "unarmed_death" if _is_current_profile_unarmed() else "death"
		if not animated_sprite.sprite_frames.has_animation(death_animation):
			death_animation = "death"
		if animated_sprite.sprite_frames.has_animation(death_animation):
			animated_sprite.play(death_animation)
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_method("lose_life"):
		gs.lose_life("Custodian eliminated after a fatal strike")
	await get_tree().create_timer(1.6).timeout
	_finish_death()

func _finish_death() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.game_over:
		return
	health = max_health
	current_health = health
	stamina = stamina_max
	_sprint_exhausted = false
	_buffered_attack_kind = ""
	_buffered_attack_timer = 0.0
	_melee_active = false
	_melee_attack_kind = ""
	_melee_attack_key = ""
	_melee_elapsed = 0.0
	_melee_duration = 0.0
	_melee_heavy_anticipating = false
	_melee_fast_windup = false
	_melee_recovery_active = false
	_melee_recovery_timer = 0.0
	_active_attack_profile = null
	_active_melee_attack_profile = null
	_block_phase = &""
	_block_active = false
	_reload_active = false
	_reload_timer = 0.0
	_field_patch_active = false
	_field_patch_timer = 0.0
	_field_patch_committed = false
	_field_patch_recovery_timer = 0.0
	_pending_ranged_shot.clear()
	_portal_transition_locked = false
	_portal_arrival_animation_active = false
	_arrn_stabilization_locked = false
	fire_cooldown_remaining = 0.0
	melee_cooldown_remaining = 0.0
	_hit_stop_active = false
	velocity = Vector2.ZERO
	disable_hitbox()
	_melee_hit_targets.clear()
	_reset_melee_overlay_visuals()
	update_visuals()
	health_changed.emit(current_health, max_health)
	_is_dead = false
	if _animation_state_machine != null:
		# DeathState is terminal and non-interruptible; respawn must force the
		# state machine back to an input-eligible state before queued weapon
		# selections can apply again.
		_animation_state_machine.current_state = ""
		_animation_state_machine.request("idle", 0)
	try_apply_pending_weapon_selection()

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
	if _is_terminal_carry_active():
		return false
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


func _try_terminal_deploy_or_pickup() -> bool:
	var terminal_deployment := get_node_or_null("/root/GameRoot/World/TerminalDeployment")
	if terminal_deployment == null or not terminal_deployment.has_method("handle_build_action"):
		return false
	return bool(terminal_deployment.call("handle_build_action"))


func _is_terminal_carry_active() -> bool:
	var terminal_deployment := get_node_or_null("/root/GameRoot/World/TerminalDeployment")
	if terminal_deployment == null or not terminal_deployment.has_method("is_carrying_terminal"):
		return false
	return bool(terminal_deployment.call("is_carrying_terminal"))


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


func _is_non_terminal_ui_open() -> bool:
	for node in get_tree().get_nodes_in_group("inventory_ui"):
		if node is CanvasItem and (node as CanvasItem).visible:
			return true
	return false


func _is_ui_text_input_focused() -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	var focus_owner := viewport.gui_get_focus_owner()
	if focus_owner == null:
		return false
	return focus_owner is LineEdit or focus_owner is TextEdit
