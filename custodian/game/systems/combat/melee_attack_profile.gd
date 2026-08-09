extends Resource
class_name MeleeAttackProfile

@export var attack_id: StringName = &"melee_fast"
@export_enum("fast", "heavy") var attack_kind: String = "fast"

@export_category("Hitbox")
@export var damage: float = 10.0
@export var range_px: float = 72.0
@export var arc_degrees: float = 80.0
@export var knockback_force: float = 56.0

@export_category("Timing")
@export var windup_sec: float = 0.08
@export var active_sec: float = 0.12
@export var recovery_sec: float = 0.22
@export var cooldown_sec: float = 0.45
@export var cancel_start_sec: float = 0.22

@export_category("Movement")
@export_enum("mobile", "slowed", "rooted") var movement_profile: String = "mobile"
@export var startup_move_mult: float = 0.80
@export var active_move_mult: float = 0.65
@export var recovery_move_mult: float = 0.85
@export var turn_locked: bool = false

@export_category("Attack Drive")
## Maximum world-space displacement contributed by this attack.
@export var drive_distance_px: float = 0.0
## Time from attack start before forward drive begins.
@export var drive_delay_sec: float = 0.0
## Duration over which the attack contributes forward movement.
@export var drive_duration_sec: float = 0.0
## Fraction of normal movement input retained during the drive.
@export_range(0.0, 1.0, 0.05) var drive_input_influence: float = 0.20
## Higher values front-load the drive and produce stronger deceleration.
@export_range(0.1, 4.0, 0.1) var drive_falloff_power: float = 1.5
## Cancel unused displacement when the drive encounters blocking geometry.
@export var drive_stops_on_collision: bool = true

@export_category("Target Assist")
@export var target_assist_enabled: bool = false
@export var target_acquire_extra_px: float = 0.0
@export_range(0.0, 90.0, 1.0) var target_assist_cone_degrees: float = 30.0
@export_range(0.0, 45.0, 1.0) var target_aim_correction_degrees: float = 0.0
@export var target_drive_bonus_max_px: float = 0.0
@export_range(0.0, 1.0, 0.05) var target_reliable_drive_fraction: float = 0.75

@export_category("Feel")
@export var hit_stop_scale: float = 0.88
@export var hit_stop_duration: float = 0.028
@export var camera_shake_power: float = 1.4

@export_category("Animation")
@export var animation_key: StringName = &"melee_2h_fast"
@export var fallback_animation: StringName = &"melee_2h_fast"
@export var weapon_overlay_animation: StringName = &""
@export var hit_window_frames: PackedInt32Array = []
@export var wound_up_before_hit: bool = false
