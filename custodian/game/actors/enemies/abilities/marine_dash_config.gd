extends Resource
class_name MarineDashConfig

## Original Enemy defaults; the Marine scene binds its tuned resource.
@export var windup_time: float = 0.32
@export var travel_time: float = 0.18
@export var impact_lock_time: float = 0.08
@export var recovery_time: float = 0.42
@export var distance_px: float = 150.0
@export var damage: float = 28.0
@export var poise_damage: float = 55.0
@export var knockback_px: float = 95.0
@export var attacker_hitstop: float = 0.045
@export var victim_hitstop: float = 0.09
@export var camera_shake_strength: float = 0.45
@export var camera_shake_duration: float = 0.16
@export var cooldown: float = 1.25
@export var hit_radius: float = 24.0
@export var hit_active_start_ratio: float = 0.28
@export var hit_active_end_ratio: float = 0.9
@export var hit_forward_reach_px: float = 30.0
@export var hit_lateral_reach_px: float = 22.0
@export var launch_band_min: float = 96.0
@export var launch_band_max: float = 240.0
@export var charge_extra_windup: float = 0.56
@export var charge_distance_bonus: float = 0.72
@export var charge_damage_bonus: float = 0.66
@export var prediction_time: float = 0.3
@export var reset_time: float = 0.48
@export var reset_speed: float = 100.0
