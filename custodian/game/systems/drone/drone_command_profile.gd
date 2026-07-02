extends Resource
class_name DroneCommandProfile

enum Mode {
	FOLLOW,
	HOLD,
	INTERCEPT,
	RECALL,
}

enum FollowDistance {
	CLOSE,
	FAR,
	FREE_ROAM,
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
@export var follow_close_radius: float = 42.0
@export var follow_far_radius: float = 118.0
@export var follow_free_roam_radius: float = 180.0
@export var free_roam_leash_range: float = 420.0
@export var free_roam_engage_range: float = 360.0
@export var free_roam_standoff: float = 88.0
@export var follow_slot_spacing: float = 18.0
@export var follow_y_offset: float = -24.0
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


static func follow_distance_name(mode: int) -> String:
	match mode:
		FollowDistance.CLOSE:
			return "CLOSE"
		FollowDistance.FAR:
			return "FAR"
		FollowDistance.FREE_ROAM:
			return "FREE_ROAM"
		_:
			return "UNKNOWN"


static func parse_follow_distance(value: String) -> int:
	match value.strip_edges().to_upper():
		"CLOSE", "CLOSE_FOLLOW":
			return FollowDistance.CLOSE
		"FAR", "FAR_FOLLOW":
			return FollowDistance.FAR
		"FREE", "FREE_ROAM", "ROAM":
			return FollowDistance.FREE_ROAM
		_:
			return FollowDistance.CLOSE
