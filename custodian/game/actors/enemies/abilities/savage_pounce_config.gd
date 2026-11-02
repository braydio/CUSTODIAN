extends Resource
class_name SavagePounceConfig

## Original Savage pounce tuning, moved out of the shared Enemy coordinator.
@export var windup_time: float = 0.28
@export var leap_time: float = 0.18
@export var recovery_time: float = 0.55
@export var distance_px: float = 64.0
@export var damage: float = 18.0
@export var knockback_px: float = 52.0
@export var cooldown: float = 1.8
@export var launch_band_min: float = 44.0
@export var launch_band_max: float = 132.0
@export var hit_active_start_ratio: float = 0.20
@export var hit_active_end_ratio: float = 0.86
@export var hit_forward_reach_px: float = 30.0
@export var hit_lateral_reach_px: float = 22.0
