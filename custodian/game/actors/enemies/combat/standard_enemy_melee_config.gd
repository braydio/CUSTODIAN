extends Resource
class_name StandardEnemyMeleeConfig

## Authored policy for ordinary baseline enemy melee.
@export var strong_opening_multiplier: float = 3.0
@export var player_contact_range_px: float = 40.0
@export var windup_duration: float = 0.10
@export var recovery_duration: float = 0.40
@export var redecision_delay_sec: float = 0.28
@export var tracking_lock_sec: float = 0.12
@export var range_grace_multiplier: float = 1.15
@export var range_grace_px: float = 10.0
@export var contact_arc_degrees: float = 95.0
