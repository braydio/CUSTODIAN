extends Resource
class_name EnemyBehaviorProfile

@export_category("Identity")
@export var profile_id: StringName = &"raider_grunt"
@export var display_name: String = "Raider Grunt"

@export_category("Perception")
@export var vision_range_px: float = 220.0
@export var vision_cone_degrees: float = 100.0
@export var peripheral_vision_mult: float = 0.55
@export var hearing_range_px: float = 160.0
@export var investigation_memory_sec: float = 4.0
@export var lost_sight_memory_sec: float = 2.0
@export var detection_gain_per_sec: float = 1.6
@export var detection_decay_per_sec: float = 0.8
@export var detection_notice_threshold: float = 0.35
@export var detection_alert_threshold: float = 1.0
@export var operator_awareness_bubble_px: float = 170.0
@export var operator_awareness_score: float = 160.0

@export_category("Operator Stealth Modifiers")
@export var crouch_detection_mult: float = 0.45
@export var moving_detection_mult: float = 1.0
@export var sprint_detection_mult: float = 1.8
@export var attack_noise_alert_mult: float = 2.5

@export_category("Objective Weights")
@export var aggression_weight: float = 0.45
@export var theft_weight: float = 0.75
@export var sabotage_weight: float = 0.35
@export var self_preservation_weight: float = 0.35
@export var curiosity_weight: float = 0.25

@export_category("Vault Theft")
@export var can_steal_resources: bool = true
@export var max_resource_types_to_steal: int = 2
@export var max_total_resource_units: int = 20
@export var storage_open_seconds: float = 1.4
@export var stealing_seconds: float = 1.2
@export var loot_escape_speed_mult: float = 0.85
@export var drop_loot_on_hit_chance: float = 0.25
@export var abandon_loot_on_panic: bool = true

@export_category("Storage Sabotage")
@export var can_sabotage_storage: bool = true
@export var sabotage_seconds: float = 2.5
@export var sabotage_damage: int = 10

@export_category("Morale")
@export var morale_max: float = 100.0
@export var morale_panic_threshold: float = 25.0
@export var morale_loss_on_ally_death: float = 18.0
@export var morale_loss_on_stagger: float = 12.0
@export var morale_loss_on_turret_hit: float = 8.0

@export_category("Movement")
@export var patrol_speed: float = 55.0
@export var investigate_speed: float = 65.0
@export var engage_speed: float = 75.0
@export var flee_speed: float = 95.0
@export var objective_speed: float = 70.0

@export_category("Ambient Routine")
@export var ambient_activity_weight: float = 0.35
@export var ambient_activity_duration_sec: float = 4.0
@export var ambient_anchor_search_radius_px: float = 220.0
@export var noncombat_warning_seconds: float = 0.8


static func create_profile(id: StringName) -> Resource:
	var profile = load("res://game/actors/enemies/components/enemy_behavior_profile.gd").new()
	match id:
		&"raider_savage":
			profile.profile_id = &"raider_savage"
			profile.display_name = "Raider Savage"
			profile.aggression_weight = 0.92
			profile.theft_weight = 0.10
			profile.sabotage_weight = 0.35
			profile.self_preservation_weight = 0.08
			profile.curiosity_weight = 0.55
			profile.vision_range_px = 205.0
			profile.hearing_range_px = 145.0
			profile.detection_gain_per_sec = 2.1
			profile.detection_decay_per_sec = 0.45
			profile.detection_notice_threshold = 0.25
			profile.detection_alert_threshold = 0.85
			profile.can_steal_resources = false
			profile.can_sabotage_storage = true
			profile.sabotage_seconds = 1.6
			profile.sabotage_damage = 8
			profile.morale_max = 70.0
			profile.morale_panic_threshold = 8.0
			profile.morale_loss_on_ally_death = 8.0
			profile.morale_loss_on_stagger = 20.0
			profile.morale_loss_on_turret_hit = 14.0
			profile.patrol_speed = 62.0
			profile.investigate_speed = 82.0
			profile.engage_speed = 104.0
			profile.flee_speed = 88.0
			profile.objective_speed = 76.0
			profile.ambient_activity_weight = 0.12
			profile.noncombat_warning_seconds = 0.15
		&"iconoclast_looter":
			profile.profile_id = &"iconoclast_looter"
			profile.display_name = "Iconoclast Looter"
			profile.aggression_weight = 0.28
			profile.theft_weight = 1.0
			profile.sabotage_weight = 0.55
			profile.self_preservation_weight = 0.55
			profile.curiosity_weight = 0.35
			profile.vision_range_px = 240.0
			profile.hearing_range_px = 190.0
			profile.operator_awareness_bubble_px = 190.0
			profile.operator_awareness_score = 175.0
			profile.max_total_resource_units = 28
			profile.loot_escape_speed_mult = 0.95
			profile.sabotage_damage = 8
			profile.ambient_activity_weight = 0.55
			profile.noncombat_warning_seconds = 1.1
		&"zealot_wanderer":
			profile.profile_id = &"zealot_wanderer"
			profile.display_name = "Zealot Wanderer"
			profile.aggression_weight = 0.75
			profile.theft_weight = 0.15
			profile.sabotage_weight = 0.65
			profile.self_preservation_weight = 0.12
			profile.curiosity_weight = 0.75
			profile.vision_range_px = 175.0
			profile.hearing_range_px = 135.0
			profile.detection_gain_per_sec = 1.15
			profile.can_steal_resources = false
			profile.can_sabotage_storage = true
			profile.sabotage_damage = 14
			profile.ambient_activity_weight = 0.7
			profile.noncombat_warning_seconds = 0.5
		_:
			profile.profile_id = &"raider_grunt"
			profile.display_name = "Raider Grunt"
			profile.ambient_activity_weight = 0.25
			profile.noncombat_warning_seconds = 0.4
	return profile
