extends Resource
class_name EnemyVariantProfile

@export var variant_id: String = ""
@export var archetype_id: String = "wolf"
@export var family_id: String = "wolf_scavenger"
@export var display_name: String = "Wolf"

@export var max_health: int = 30
@export var move_speed: float = 90.0
@export var attack_damage: int = 8
@export var attack_range: float = 24.0
@export var attack_cooldown: float = 0.8
@export var detection_radius: float = 180.0
@export var leash_radius: float = 360.0

@export var collision_radius: float = 14.0
@export var hurtbox_radius: float = 16.0

@export var body_scale: Vector2 = Vector2.ONE
@export var animation_speed_scale: float = 1.0
@export var primary_tint: Color = Color.WHITE
@export var glow_color: Color = Color.TRANSPARENT
@export var glow_strength: float = 0.0
@export var contrast_boost: float = 1.0
@export var overlay_set: Array[String] = []

@export var behavior_id: String = "pack_hunter"
@export var attack_profile_id: String = "bite_basic"
@export var special_profile_id: String = ""

@export var elite_tier: String = "normal"
@export var threat_level: int = 1
@export var seed: int = 0
@export var affixes: Array[String] = []

var debug_rolls: Dictionary = {}


func get_debug_summary() -> Dictionary:
	return {
		"variant_id": variant_id,
		"archetype_id": archetype_id,
		"family_id": family_id,
		"display_name": display_name,
		"elite_tier": elite_tier,
		"threat_level": threat_level,
		"behavior_id": behavior_id,
		"attack_profile_id": attack_profile_id,
		"special_profile_id": special_profile_id,
		"affixes": affixes.duplicate(),
		"seed": seed,
	}
