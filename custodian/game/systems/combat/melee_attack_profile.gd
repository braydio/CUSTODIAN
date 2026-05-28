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
