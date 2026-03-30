extends Resource
class_name OperatorWeaponDefinition

@export var weapon_id: StringName = &"carbine_rifle"
@export var weapon_type: StringName = &"ranged_2h"
@export_file("*.json") var weapon_data_path: String = ""
@export var frames_resource: SpriteFrames
@export var animation_map: Dictionary = {
	"ranged_stance": "ranged_2h_stance",
	"ranged_fire": "ranged_2h_fire"
}
@export var hit_windows: Dictionary = {}
@export var fx_map: Dictionary = {}
@export var authored_body_stance_animation: StringName = &""
@export var right_hand_socket_position: Vector2 = Vector2(10, -16)
@export var left_hand_socket_position: Vector2 = Vector2(2, -12)
@export var weapon_socket_position: Vector2 = Vector2(12, -16)
@export var weapon_sprite_position: Vector2 = Vector2.ZERO
@export var weapon_sprite_scale: Vector2 = Vector2.ONE
@export var weapon_sprite_rotation_degrees: float = 0.0
@export var muzzle_socket_position: Vector2 = Vector2(20, 2)
@export var right_hand_socket_position_up: Vector2 = Vector2(10, -18)
@export var left_hand_socket_position_up: Vector2 = Vector2(0, -14)
@export var weapon_socket_position_up: Vector2 = Vector2(12, -18)
@export var muzzle_socket_position_up: Vector2 = Vector2(20, 0)
@export var right_hand_socket_position_down: Vector2 = Vector2(10, -14)
@export var left_hand_socket_position_down: Vector2 = Vector2(3, -10)
@export var weapon_socket_position_down: Vector2 = Vector2(12, -14)
@export var muzzle_socket_position_down: Vector2 = Vector2(20, 4)

# === WEAPON STATS (from JSON) ===
@export_group("Combat Stats")
@export var damage: float = 12.0
@export var fire_rate_rps: float = 7.5
@export var magazine_size: int = 28
@export var reload_time_sec: float = 1.7
@export var range_px: float = 300.0
@export var accuracy: float = 0.86
@export var spread_deg: float = 2.0
@export var recoil: float = 0.35
@export var projectile_speed_px: float = 950.0
@export var penetration: int = 1

@export_group("Ammo")
@export var ammo_type: String = "kinetic"
@export var reserve_ammo: int = 112
@export var reload_style: String = "magazine"

# === RUNTIME STATE ===
@export_group("Runtime State")
@export var current_magazine: int = 0
@export var is_reloading: bool = false
@export var reload_timer: float = 0.0

var _cached_weapon_data: Dictionary = {}


func get_weapon_data() -> Dictionary:
	if not _cached_weapon_data.is_empty():
		return _cached_weapon_data
	if weapon_data_path.is_empty():
		return {}
	if not FileAccess.file_exists(weapon_data_path):
		return {}
	var file := FileAccess.open(weapon_data_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_cached_weapon_data = parsed
	return _cached_weapon_data


func get_stat_int(stat_name: String, fallback: int = 0) -> int:
	var stats: Variant = get_weapon_data().get("stats", {})
	if stats is Dictionary and stats.has(stat_name):
		return int(stats[stat_name])
	return fallback


func get_stat_float(stat_name: String, fallback: float = 0.0) -> float:
	var stats: Variant = get_weapon_data().get("stats", {})
	if stats is Dictionary and stats.has(stat_name):
		return float(stats[stat_name])
	return fallback
