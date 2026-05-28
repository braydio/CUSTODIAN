extends Resource
class_name OperatorWeaponDefinition

const MeleeAttackProfile = preload("res://game/systems/combat/melee_attack_profile.gd")

@export var weapon_id: StringName = &"carbine_rifle"
@export var weapon_type: StringName = &"ranged_2h"
@export var display_name: String = ""
@export var weapon_kind: String = "melee"
@export var primary_intent: String = "melee_fast"
@export var secondary_intent: String = "melee_heavy"
@export_file("*.json") var weapon_data_path: String = ""
@export var frames_resource: SpriteFrames
@export var animation_map: Dictionary = {
	"ranged_stance": "ranged_2h_stance",
	"ranged_fire": "ranged_2h_fire"
}
@export var hit_windows: Dictionary = {}
@export var fx_map: Dictionary = {}
@export var authored_body_stance_animation: StringName = &""
@export var authored_body_fire_walk_animation: StringName = &""
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
@export var movement_speed_penalty: float = 0.0
@export var movement_accuracy_penalty: float = 0.0
@export var animation_fire_frame: int = 0
@export var recoil_animation: StringName = &"recoil_standard"

@export_group("Combat Profile")
@export var move_speed_multiplier: float = 1.0
@export var acceleration_multiplier: float = 1.0
@export var recovery_multiplier: float = 1.0
@export var range_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var stagger_multiplier: float = 1.0

@export_group("Melee Attacks")
@export var fast_attack_profile: MeleeAttackProfile
@export var heavy_attack_profile: MeleeAttackProfile

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


func get_handling_float(stat_name: String, fallback: float = 0.0) -> float:
	var handling: Variant = get_weapon_data().get("handling", {})
	if handling is Dictionary and handling.has(stat_name):
		return float(handling[stat_name])
	return fallback


func get_animation_int(stat_name: String, fallback: int = 0) -> int:
	var animation: Variant = get_weapon_data().get("animation", {})
	if animation is Dictionary and animation.has(stat_name):
		return int(animation[stat_name])
	return fallback


func get_animation_string(stat_name: String, fallback: String = "") -> String:
	var animation: Variant = get_weapon_data().get("animation", {})
	if animation is Dictionary and animation.has(stat_name):
		return String(animation[stat_name])
	return fallback
