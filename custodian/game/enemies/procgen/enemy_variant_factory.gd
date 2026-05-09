extends RefCounted
class_name EnemyVariantFactory

const PROFILE_SCRIPT := preload("res://game/enemies/procgen/enemy_variant_profile.gd")
const FACTORY_VERSION := 1

const WOLF_FAMILIES := [
	{
		"id": "wolf_scavenger",
		"weight": 45.0,
		"min_threat": 1,
		"max_threat": 5,
		"nouns": ["Scavenger", "Gnawer", "Mongrel"],
		"health": Vector2i(18, 32),
		"speed": Vector2(85.0, 115.0),
		"damage": Vector2i(5, 9),
		"cooldown": Vector2(0.75, 1.10),
		"range": Vector2(20.0, 26.0),
		"detection": Vector2(150.0, 210.0),
		"scale": Vector2(0.85, 1.00),
		"collision": Vector2(11.0, 14.0),
		"behaviors": [{"id": "pack_hunter", "weight": 55.0}, {"id": "skirmisher", "weight": 45.0}],
		"attack_profiles": [{"id": "bite_basic", "weight": 80.0}, {"id": "bite_quick", "weight": 20.0}],
	},
	{
		"id": "wolf_stalker",
		"weight": 30.0,
		"min_threat": 1,
		"max_threat": 5,
		"nouns": ["Stalker", "Slinker", "Lurker"],
		"health": Vector2i(28, 46),
		"speed": Vector2(70.0, 95.0),
		"damage": Vector2i(8, 14),
		"cooldown": Vector2(0.85, 1.25),
		"range": Vector2(24.0, 32.0),
		"detection": Vector2(190.0, 260.0),
		"scale": Vector2(1.00, 1.15),
		"collision": Vector2(13.0, 16.0),
		"behaviors": [{"id": "ambusher", "weight": 60.0}, {"id": "circle_player", "weight": 40.0}],
		"attack_profiles": [{"id": "bite_basic", "weight": 60.0}, {"id": "bite_lunge", "weight": 40.0}],
	},
	{
		"id": "wolf_alpha",
		"weight": 12.0,
		"min_threat": 2,
		"max_threat": 5,
		"nouns": ["Alpha", "Packlord", "Fang-Leader"],
		"health": Vector2i(50, 80),
		"speed": Vector2(80.0, 105.0),
		"damage": Vector2i(14, 22),
		"cooldown": Vector2(0.95, 1.35),
		"range": Vector2(28.0, 38.0),
		"detection": Vector2(240.0, 330.0),
		"scale": Vector2(1.15, 1.35),
		"collision": Vector2(16.0, 20.0),
		"behaviors": [{"id": "pack_leader", "weight": 70.0}, {"id": "charge", "weight": 30.0}],
		"attack_profiles": [{"id": "bite_heavy", "weight": 65.0}, {"id": "bite_lunge", "weight": 35.0}],
		"special_profiles": [{"id": "howl_alert", "weight": 65.0}, {"id": "howl_buff_pack", "weight": 35.0}],
	},
	{
		"id": "wolf_corrupted",
		"weight": 10.0,
		"min_threat": 2,
		"max_threat": 5,
		"nouns": ["Corrupted Wolf", "Frenzied Wolf", "Void-Flecked Wolf"],
		"health": Vector2i(36, 70),
		"speed": Vector2(75.0, 120.0),
		"damage": Vector2i(12, 20),
		"cooldown": Vector2(0.60, 1.05),
		"range": Vector2(24.0, 34.0),
		"detection": Vector2(210.0, 300.0),
		"scale": Vector2(1.00, 1.25),
		"collision": Vector2(14.0, 18.0),
		"behaviors": [{"id": "frenzy", "weight": 65.0}, {"id": "ambusher", "weight": 35.0}],
		"forced_affix_chance": 0.65,
	},
	{
		"id": "wolf_ancient",
		"weight": 3.0,
		"min_threat": 4,
		"max_threat": 5,
		"nouns": ["Ancient Wolf", "Old Fang", "Bone-Packlord"],
		"health": Vector2i(90, 140),
		"speed": Vector2(55.0, 80.0),
		"damage": Vector2i(20, 32),
		"cooldown": Vector2(1.10, 1.70),
		"range": Vector2(32.0, 46.0),
		"detection": Vector2(280.0, 380.0),
		"scale": Vector2(1.35, 1.60),
		"collision": Vector2(20.0, 25.0),
		"behaviors": [{"id": "bruiser", "weight": 50.0}, {"id": "howl_summoner", "weight": 50.0}],
		"special_profiles": [{"id": "howl_alert", "weight": 40.0}, {"id": "howl_summon_scavengers", "weight": 60.0}],
		"forced_affix_chance": 1.0,
	},
]

const ELITE_TIERS := [
	{"id": "normal", "weights": {1: 86.0, 2: 78.0, 3: 68.0, 4: 56.0, 5: 46.0}, "health_mult": 1.00, "damage_mult": 1.00, "speed_mult": 1.00, "cooldown_mult": 1.00, "scale_mult": 1.00, "affix_min": 0, "affix_max": 0},
	{"id": "veteran", "weights": {1: 13.0, 2: 18.0, 3: 24.0, 4: 28.0, 5: 30.0}, "health_mult": 1.25, "damage_mult": 1.15, "speed_mult": 1.03, "cooldown_mult": 0.95, "scale_mult": 1.08, "affix_min": 0, "affix_max": 1},
	{"id": "elite", "weights": {1: 1.0, 2: 4.0, 3: 7.0, 4: 12.0, 5: 16.0}, "health_mult": 1.65, "damage_mult": 1.35, "speed_mult": 1.06, "cooldown_mult": 0.90, "scale_mult": 1.16, "affix_min": 1, "affix_max": 2},
	{"id": "nemesis", "weights": {1: 0.0, 2: 0.0, 3: 1.0, 4: 4.0, 5: 8.0}, "health_mult": 2.25, "damage_mult": 1.55, "speed_mult": 0.96, "cooldown_mult": 0.95, "scale_mult": 1.28, "affix_min": 2, "affix_max": 3},
]

const THREAT_MULTIPLIERS := {1: 1.00, 2: 1.20, 3: 1.45, 4: 1.75, 5: 2.10}
const MAX_DPS_BY_THREAT := {1: 12.0, 2: 18.0, 3: 26.0, 4: 36.0, 5: 48.0}

const WOLF_AFFIXES := [
	{"id": "rabid", "prefix": "Rabid", "weight": 22.0, "min_threat": 1, "health_mult": 0.90, "damage_mult": 1.15, "speed_mult": 1.18, "cooldown_mult": 0.82, "detection_mult": 1.10, "glow_strength_add": 0.05, "tags": ["fast", "aggressive"], "incompatible": ["ironhide"]},
	{"id": "ironhide", "prefix": "Ironhide", "weight": 16.0, "min_threat": 2, "health_mult": 1.45, "damage_mult": 1.05, "speed_mult": 0.82, "cooldown_mult": 1.08, "detection_mult": 1.00, "contrast_add": 0.15, "tags": ["durable"], "incompatible": ["rabid"]},
	{"id": "void_flecked", "prefix": "Void-Flecked", "weight": 13.0, "min_threat": 2, "health_mult": 1.10, "damage_mult": 1.22, "speed_mult": 1.04, "cooldown_mult": 0.96, "detection_mult": 1.20, "glow_strength_add": 0.22, "overlay": "void_wounds_01", "tags": ["corrupted"]},
	{"id": "frostbitten", "prefix": "Frostbitten", "weight": 12.0, "min_threat": 1, "health_mult": 1.05, "damage_mult": 1.00, "speed_mult": 0.92, "cooldown_mult": 1.00, "detection_mult": 1.05, "glow_strength_add": 0.12, "overlay": "frost_breath_01", "tags": ["cold"]},
	{"id": "spine_torn", "prefix": "Spine-Torn", "weight": 10.0, "min_threat": 3, "health_mult": 1.20, "damage_mult": 1.30, "speed_mult": 0.94, "cooldown_mult": 1.05, "detection_mult": 1.00, "overlay": "corruption_spine_01", "tags": ["mutated"]},
	{"id": "hollow", "prefix": "Hollow", "weight": 18.0, "min_threat": 1, "health_mult": 0.85, "damage_mult": 1.05, "speed_mult": 1.08, "cooldown_mult": 0.95, "detection_mult": 0.90, "contrast_add": -0.08, "tags": ["pale"]},
]

const BIOME_MODS := {
	"default": {"family_weight_mult": {}, "stat_mult": {"health": 1.0, "damage": 1.0, "speed": 1.0}, "palettes": ["ash", "slate", "blue_grey"]},
	"industrial_ruin": {"family_weight_mult": {"wolf_scavenger": 1.20, "wolf_stalker": 1.10, "wolf_corrupted": 0.90}, "stat_mult": {"health": 1.0, "damage": 1.0, "speed": 0.97}, "palettes": ["ash", "rustback", "slate", "blue_grey"]},
	"forest_ruin": {"family_weight_mult": {"wolf_stalker": 1.25, "wolf_alpha": 1.10}, "stat_mult": {"health": 1.0, "damage": 0.98, "speed": 1.05}, "palettes": ["moss_grey", "ash", "pale_green", "blue_grey"]},
	"void_contaminated": {"family_weight_mult": {"wolf_corrupted": 1.85, "wolf_ancient": 1.30}, "stat_mult": {"health": 1.10, "damage": 1.15, "speed": 1.03}, "palettes": ["void_pale", "violet_grey", "blue_grey"]},
}

const PALETTES := {
	"ash": {"primary": Color(0.72, 0.78, 0.78, 1.0), "glow": Color(0.25, 0.65, 0.85, 1.0), "glow_strength": 0.00, "contrast": 1.00},
	"slate": {"primary": Color(0.55, 0.66, 0.70, 1.0), "glow": Color(0.20, 0.55, 0.85, 1.0), "glow_strength": 0.02, "contrast": 1.05},
	"blue_grey": {"primary": Color(0.58, 0.73, 0.78, 1.0), "glow": Color(0.25, 0.72, 0.95, 1.0), "glow_strength": 0.04, "contrast": 1.05},
	"rustback": {"primary": Color(0.78, 0.66, 0.56, 1.0), "glow": Color(0.95, 0.45, 0.25, 1.0), "glow_strength": 0.03, "contrast": 1.08},
	"moss_grey": {"primary": Color(0.58, 0.68, 0.60, 1.0), "glow": Color(0.55, 0.90, 0.65, 1.0), "glow_strength": 0.02, "contrast": 1.00},
	"pale_green": {"primary": Color(0.70, 0.82, 0.72, 1.0), "glow": Color(0.55, 1.00, 0.80, 1.0), "glow_strength": 0.04, "contrast": 0.95},
	"void_pale": {"primary": Color(0.82, 0.82, 0.92, 1.0), "glow": Color(0.70, 0.35, 1.00, 1.0), "glow_strength": 0.18, "contrast": 1.15},
	"violet_grey": {"primary": Color(0.62, 0.58, 0.76, 1.0), "glow": Color(0.75, 0.35, 1.00, 1.0), "glow_strength": 0.14, "contrast": 1.12},
}

const NAME_PREFIXES := ["Ash", "Pale", "Cold", "Gutter", "Sump", "Rustback", "Hollow", "Old", "Broken", "Starved"]


func build_wolf_variant(seed: int, biome_id: String, threat_level: int, context: Dictionary = {}) -> Resource:
	return generate_wolf_variant(seed, biome_id, threat_level, context)


static func generate_wolf_variant(seed: int, biome_id: String, threat_level: int, context: Dictionary = {}) -> Resource:
	threat_level = clampi(threat_level, 1, 5)
	var family_rng := _make_rng(seed, "family")
	var tier_rng := _make_rng(seed, "tier")
	var stat_rng := _make_rng(seed, "stats")
	var affix_rng := _make_rng(seed, "affixes")
	var visual_rng := _make_rng(seed, "visuals")
	var behavior_rng := _make_rng(seed, "behavior")
	var name_rng := _make_rng(seed, "name")

	var biome: Dictionary = BIOME_MODS.get(biome_id, BIOME_MODS["default"])
	var family := _pick_family(family_rng, biome, threat_level, context)
	var tier := _pick_tier(tier_rng, threat_level)
	var affixes := _pick_affixes(affix_rng, family, tier, threat_level)
	var palette := _pick_palette(visual_rng, biome)

	var threat_mult: float = float(THREAT_MULTIPLIERS[threat_level])
	var profile: Resource = PROFILE_SCRIPT.new()
	profile.seed = seed
	profile.threat_level = threat_level
	profile.variant_id = "wolf_%s_%d" % [_stable_seed(seed, "variant_id"), threat_level]
	profile.archetype_id = "wolf"
	profile.family_id = String(family["id"])
	profile.elite_tier = String(tier["id"])
	profile.affixes.assign(affixes)
	profile.max_health = int(round(float(stat_rng.randi_range(family["health"].x, family["health"].y)) * threat_mult * float(tier["health_mult"]) * float(biome["stat_mult"].get("health", 1.0))))
	profile.move_speed = stat_rng.randf_range(family["speed"].x, family["speed"].y) * float(tier["speed_mult"]) * float(biome["stat_mult"].get("speed", 1.0))
	profile.attack_damage = int(round(float(stat_rng.randi_range(family["damage"].x, family["damage"].y)) * threat_mult * float(tier["damage_mult"]) * float(biome["stat_mult"].get("damage", 1.0))))
	profile.attack_cooldown = stat_rng.randf_range(family["cooldown"].x, family["cooldown"].y) * float(tier["cooldown_mult"])
	profile.attack_range = stat_rng.randf_range(family["range"].x, family["range"].y)
	profile.detection_radius = stat_rng.randf_range(family["detection"].x, family["detection"].y)
	profile.leash_radius = profile.detection_radius * 1.8
	profile.collision_radius = stat_rng.randf_range(family["collision"].x, family["collision"].y)
	profile.hurtbox_radius = profile.collision_radius + 2.0
	var scale_value := stat_rng.randf_range(family["scale"].x, family["scale"].y) * float(tier["scale_mult"])
	profile.body_scale = Vector2(scale_value * visual_rng.randf_range(0.96, 1.04), scale_value * visual_rng.randf_range(0.94, 1.06))
	profile.animation_speed_scale = visual_rng.randf_range(0.92, 1.08)
	profile.primary_tint = palette["primary"]
	profile.glow_color = palette["glow"]
	profile.glow_strength = float(palette["glow_strength"])
	profile.contrast_boost = float(palette["contrast"])
	profile.behavior_id = _pick_behavior(behavior_rng, family, affixes)
	profile.attack_profile_id = _pick_profile_id(behavior_rng, family.get("attack_profiles", [{"id": "bite_basic", "weight": 1.0}]))
	profile.special_profile_id = _pick_profile_id(behavior_rng, family.get("special_profiles", []))

	_apply_affixes(profile, affixes)
	profile.display_name = _make_name(name_rng, profile, family, affixes)
	_apply_safety_clamps(profile, threat_level)
	profile.debug_rolls = {
		"biome_id": biome_id,
		"family": family,
		"tier": tier,
		"palette": palette,
	}
	return profile


static func _make_rng(base_seed: int, salt: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _stable_seed(base_seed, salt)
	return rng


static func _stable_seed(base_seed: int, salt: String) -> int:
	var text := "%d:%s:%d" % [base_seed, salt, FACTORY_VERSION]
	var value := 2166136261
	for index in range(text.length()):
		value = value ^ text.unicode_at(index)
		value = (value * 16777619) & 0x7fffffff
	return maxi(1, value)


static func _pick_family(rng: RandomNumberGenerator, biome: Dictionary, threat_level: int, _context: Dictionary) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var family_weight_mult: Dictionary = biome.get("family_weight_mult", {})
	for family in WOLF_FAMILIES:
		if threat_level < int(family["min_threat"]) or threat_level > int(family["max_threat"]):
			continue
		var copy: Dictionary = family.duplicate(true)
		copy["weight"] = float(copy["weight"]) * float(family_weight_mult.get(copy["id"], 1.0))
		candidates.append(copy)
	return _weighted_pick(rng, candidates)


static func _pick_tier(rng: RandomNumberGenerator, threat_level: int) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for tier in ELITE_TIERS:
		var copy: Dictionary = tier.duplicate(true)
		copy["weight"] = float(copy["weights"].get(threat_level, 0.0))
		candidates.append(copy)
	return _weighted_pick(rng, candidates)


static func _pick_affixes(rng: RandomNumberGenerator, family: Dictionary, tier: Dictionary, threat_level: int) -> Array[String]:
	var affix_min := int(tier["affix_min"])
	var affix_max := int(tier["affix_max"])
	if rng.randf() < float(family.get("forced_affix_chance", 0.0)):
		affix_min = max(1, affix_min)
		affix_max = max(affix_min, affix_max)
	var target_count := rng.randi_range(affix_min, affix_max)
	var picked: Array[String] = []
	for _i in range(target_count):
		var candidates: Array[Dictionary] = []
		for affix in WOLF_AFFIXES:
			if threat_level < int(affix["min_threat"]):
				continue
			if String(affix["id"]) in picked:
				continue
			var incompatible: Array = affix.get("incompatible", [])
			var blocked := false
			for id in picked:
				if id in incompatible:
					blocked = true
					break
			if blocked:
				continue
			candidates.append(affix)
		if candidates.is_empty():
			break
		picked.append(String(_weighted_pick(rng, candidates)["id"]))
	return picked


static func _pick_palette(rng: RandomNumberGenerator, biome: Dictionary) -> Dictionary:
	var palette_ids: Array = biome.get("palettes", ["ash"])
	var picked_id := String(palette_ids[rng.randi_range(0, palette_ids.size() - 1)])
	return PALETTES.get(picked_id, PALETTES["ash"])


static func _pick_behavior(rng: RandomNumberGenerator, family: Dictionary, affixes: Array[String]) -> String:
	var candidates: Array = family.get("behaviors", [{"id": "pack_hunter", "weight": 1.0}])
	if "rabid" in affixes:
		candidates = [{"id": "frenzy", "weight": 60.0}, {"id": "charge", "weight": 40.0}]
	elif "ironhide" in affixes:
		candidates = [{"id": "bruiser", "weight": 65.0}, {"id": "pack_hunter", "weight": 35.0}]
	return String(_weighted_pick(rng, candidates)["id"])


static func _pick_profile_id(rng: RandomNumberGenerator, candidates: Array) -> String:
	if candidates.is_empty():
		return ""
	return String(_weighted_pick(rng, candidates)["id"])


static func _weighted_pick(rng: RandomNumberGenerator, candidates: Array) -> Dictionary:
	if candidates.is_empty():
		return {}
	var total := 0.0
	for candidate in candidates:
		total += max(0.0, float(candidate.get("weight", 1.0)))
	if total <= 0.0:
		return candidates[0]
	var roll := rng.randf() * total
	for candidate in candidates:
		roll -= max(0.0, float(candidate.get("weight", 1.0)))
		if roll <= 0.0:
			return candidate
	return candidates[candidates.size() - 1]


static func _apply_affixes(profile: Resource, affix_ids: Array[String]) -> void:
	for affix_id in affix_ids:
		var affix := _get_affix(affix_id)
		if affix.is_empty():
			continue
		profile.max_health = int(round(float(profile.max_health) * float(affix.get("health_mult", 1.0))))
		profile.attack_damage = int(round(float(profile.attack_damage) * float(affix.get("damage_mult", 1.0))))
		profile.move_speed *= float(affix.get("speed_mult", 1.0))
		profile.attack_cooldown *= float(affix.get("cooldown_mult", 1.0))
		profile.detection_radius *= float(affix.get("detection_mult", 1.0))
		profile.glow_strength += float(affix.get("glow_strength_add", 0.0))
		profile.contrast_boost += float(affix.get("contrast_add", 0.0))
		if affix.has("overlay"):
			profile.overlay_set.append(String(affix["overlay"]))


static func _get_affix(affix_id: String) -> Dictionary:
	for affix in WOLF_AFFIXES:
		if String(affix["id"]) == affix_id:
			return affix
	return {}


static func _make_name(rng: RandomNumberGenerator, profile: Resource, family: Dictionary, affix_ids: Array[String]) -> String:
	var parts: Array[String] = []
	if profile.elite_tier != "normal":
		parts.append(profile.elite_tier.capitalize())
	for affix_id in affix_ids:
		var affix := _get_affix(affix_id)
		if not affix.is_empty():
			parts.append(String(affix["prefix"]))
	if parts.is_empty() and rng.randf() < 0.55:
		parts.append(NAME_PREFIXES[rng.randi_range(0, NAME_PREFIXES.size() - 1)])
	var nouns: Array = family.get("nouns", ["Wolf"])
	parts.append(String(nouns[rng.randi_range(0, nouns.size() - 1)]))
	return " ".join(parts)


static func _apply_safety_clamps(profile: Resource, threat_level: int) -> void:
	profile.max_health = clampi(profile.max_health, 8, 240)
	profile.attack_damage = clampi(profile.attack_damage, 2, 60)
	profile.move_speed = clampf(profile.move_speed, 35.0, 145.0)
	profile.attack_cooldown = clampf(profile.attack_cooldown, 0.35, 2.25)
	profile.attack_range = clampf(profile.attack_range, 16.0, 54.0)
	profile.detection_radius = clampf(profile.detection_radius, 100.0, 420.0)
	profile.leash_radius = clampf(profile.leash_radius, 220.0, 720.0)
	profile.collision_radius = clampf(profile.collision_radius, 9.0, 28.0)
	profile.hurtbox_radius = clampf(profile.hurtbox_radius, 10.0, 32.0)
	profile.glow_strength = clampf(profile.glow_strength, 0.0, 0.45)
	profile.contrast_boost = clampf(profile.contrast_boost, 0.75, 1.45)
	var dps: float = float(profile.attack_damage) / profile.attack_cooldown
	var max_dps: float = float(MAX_DPS_BY_THREAT[threat_level])
	if dps > max_dps:
		profile.attack_cooldown = clampf(float(profile.attack_damage) / max_dps, 0.35, 2.25)
