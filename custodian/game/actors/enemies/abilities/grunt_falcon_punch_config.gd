extends Resource
class_name GruntFalconPunchConfig

@export var tracking_time := 0.50
@export var committed_time := 0.25
@export var leap_time := 0.28
@export var impact_lock_time := 0.08
@export var recovery_time := 0.70
@export var blocked_recovery_time := 0.75
@export var whiff_recovery_time := 0.85
@export var collision_recovery_time := 0.95
@export var committed_reach_buffer_px := 10.0
@export var commitment_cue_time := 0.10
@export var damage_multiplier := 1.35
@export var cooldown := 2.1
@export var launch_band := Vector2(88.0, 184.0)
@export var hit_active_ratio := Vector2(0.38, 0.76)
@export var hit_forward_reach_px := 42.0
@export var hit_lateral_reach_px := 30.0
@export var tracking_speed_multiplier := 0.15
@export var recovery_speed := 0.0
@export var stop_short_px := 28.0
@export var knockback_px := 58.0
@export var victim_hitstop_sec := 0.06
@export var attacker_hitstop_sec := 0.035
@export var camera_shake_strength := 0.22
@export var camera_shake_duration := 0.10
@export_range(0.0, 1.0, 0.01) var cadence_credit_per_attack := 0.35
@export var recent_parry_lockout_sec := 3.0
@export var requires_clear_lane := true
@export var ally_lane_radius_px := 34.0
@export var normal_attacks_required := 1

func total_windup_time() -> float:
	return tracking_time + committed_time
