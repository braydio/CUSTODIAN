extends Resource
class_name DroneCommandProfile

enum Mode {
	FOLLOW,
	HOLD,
	INTERCEPT,
	RECALL,
}

@export var drone_hp: float = 45.0
@export var drone_speed: float = 170.0
@export var drone_acceleration: float = 850.0
@export var drone_engage_range: float = 280.0
@export var drone_weapon_range: float = 220.0
@export var drone_damage: float = 8.0
@export var drone_fire_cooldown: float = 0.55
@export var drone_burst_size: int = 2
@export var drone_burst_gap: float = 0.09
@export var drone_retreat_hp_threshold: float = 0.28
@export var drone_collision_radius: float = 8.0
@export var follow_orbit_radius: float = 54.0
@export var hold_leash_range: float = 360.0
@export var intercept_standoff: float = 72.0
@export var recall_distance: float = 30.0


static func mode_name(mode: int) -> String:
	match mode:
		Mode.FOLLOW:
			return "FOLLOW"
		Mode.HOLD:
			return "HOLD"
		Mode.INTERCEPT:
			return "INTERCEPT"
		Mode.RECALL:
			return "RECALL"
		_:
			return "UNKNOWN"


static func parse_mode(value: String) -> int:
	match value.strip_edges().to_upper():
		"FOLLOW":
			return Mode.FOLLOW
		"HOLD":
			return Mode.HOLD
		"INTERCEPT":
			return Mode.INTERCEPT
		"RECALL":
			return Mode.RECALL
		_:
			return Mode.FOLLOW
