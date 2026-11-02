
Yes. The **Variant Factory** should be more than “pick random tint + stats.” It should be a deterministic enemy composer that builds a complete `EnemyVariantProfile` from:

```text
seed + biome_id + threat_level + room/context tags
```

It should decide:

```text
wolf family
elite tier
affixes
stats
behavior package
visual palette
scale
animation speed
glow
collision size
display name
debug metadata
```

The important design rule:

```text
The factory generates data only.
It does not instantiate enemies.
It does not load sprites.
It does not touch scenes.
```

The enemy scene receives the profile and applies it.

---

# Better Variant Factory Design

## Main Output

Extend your `EnemyVariantProfile` so it has enough information to drive the whole enemy.

```gdscript
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
@export var affixes: Array[String] = []

@export var behavior_id: String = "pack_hunter"
@export var attack_profile_id: String = "bite_basic"
@export var special_profile_id: String = ""

@export var elite_tier: String = "normal"
@export var threat_level: int = 1
@export var seed: int = 0

# Optional but very useful for testing.
var debug_rolls: Dictionary = {}
```

---

# Factory Responsibilities

The factory should have this public API:

```gdscript
static func generate_wolf_variant(
    seed: int,
    biome_id: String,
    threat_level: int,
    context: Dictionary = {}
) -> EnemyVariantProfile:
```

Example call from a procgen room:

```gdscript
var profile := EnemyVariantFactory.generate_wolf_variant(
    enemy_seed,
    "industrial_ruin",
    room_threat_level,
    {
        "room_id": room_id,
        "spawn_index": spawn_index,
        "near_darkness": true,
        "faction": "feral",
        "director_pressure": 0.35
    }
)
```

The `context` dictionary gives you room-specific flavor without hardcoding every spawn.

---

# Deterministic RNG Streams

This is the big improvement.

Do **not** use one RNG stream for everything. If you do, adding a new cosmetic roll later will change every enemy’s stats.

Use separate RNG streams:

```text
family_rng
tier_rng
stat_rng
affix_rng
visual_rng
name_rng
behavior_rng
```

That way cosmetic changes do not accidentally change gameplay rolls.

---

# Full Variant Factory Skeleton

Create:

```text
res://game/enemies/procgen/enemy_variant_factory.gd
```

```gdscript
extends Node
class_name EnemyVariantFactory

const FACTORY_VERSION := 1

const THREAT_MULTIPLIERS := {
    1: 1.00,
    2: 1.20,
    3: 1.45,
    4: 1.75,
    5: 2.10
}

const MAX_DPS_BY_THREAT := {
    1: 12.0,
    2: 18.0,
    3: 26.0,
    4: 36.0,
    5: 48.0
}

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
        "behaviors": [
            {"id": "pack_hunter", "weight": 55.0},
            {"id": "skirmisher", "weight": 45.0}
        ],
        "attack_profiles": [
            {"id": "bite_basic", "weight": 80.0},
            {"id": "bite_quick", "weight": 20.0}
        ]
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
        "behaviors": [
            {"id": "ambusher", "weight": 60.0},
            {"id": "circle_player", "weight": 40.0}
        ],
        "attack_profiles": [
            {"id": "bite_basic", "weight": 60.0},
            {"id": "bite_lunge", "weight": 40.0}
        ]
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
        "behaviors": [
            {"id": "pack_leader", "weight": 70.0},
            {"id": "charge", "weight": 30.0}
        ],
        "attack_profiles": [
            {"id": "bite_heavy", "weight": 65.0},
            {"id": "bite_lunge", "weight": 35.0}
        ],
        "special_profiles": [
            {"id": "howl_alert", "weight": 65.0},
            {"id": "howl_buff_pack", "weight": 35.0}
        ]
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
        "behaviors": [
            {"id": "frenzy", "weight": 65.0},
            {"id": "ambusher", "weight": 35.0}
        ],
        "attack_profiles": [
            {"id": "bite_quick", "weight": 45.0},
            {"id": "bite_lunge", "weight": 55.0}
        ],
        "forced_affix_chance": 0.65
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
        "behaviors": [
            {"id": "bruiser", "weight": 50.0},
            {"id": "howl_summoner", "weight": 50.0}
        ],
        "attack_profiles": [
            {"id": "bite_heavy", "weight": 70.0},
            {"id": "bite_crushing", "weight": 30.0}
        ],
        "special_profiles": [
            {"id": "howl_alert", "weight": 40.0},
            {"id": "howl_summon_scavengers", "weight": 60.0}
        ],
        "forced_affix_chance": 1.0
    }
]

const ELITE_TIERS := [
    {
        "id": "normal",
        "weights": {1: 86.0, 2: 78.0, 3: 68.0, 4: 56.0, 5: 46.0},
        "health_mult": 1.00,
        "damage_mult": 1.00,
        "speed_mult": 1.00,
        "cooldown_mult": 1.00,
        "scale_mult": 1.00,
        "affix_min": 0,
        "affix_max": 0
    },
    {
        "id": "veteran",
        "weights": {1: 13.0, 2: 18.0, 3: 24.0, 4: 28.0, 5: 30.0},
        "health_mult": 1.25,
        "damage_mult": 1.15,
        "speed_mult": 1.03,
        "cooldown_mult": 0.95,
        "scale_mult": 1.08,
        "affix_min": 0,
        "affix_max": 1
    },
    {
        "id": "elite",
        "weights": {1: 1.0, 2: 4.0, 3: 7.0, 4: 12.0, 5: 16.0},
        "health_mult": 1.65,
        "damage_mult": 1.35,
        "speed_mult": 1.06,
        "cooldown_mult": 0.90,
        "scale_mult": 1.16,
        "affix_min": 1,
        "affix_max": 2
    },
    {
        "id": "nemesis",
        "weights": {1: 0.0, 2: 0.0, 3: 1.0, 4: 4.0, 5: 8.0},
        "health_mult": 2.25,
        "damage_mult": 1.55,
        "speed_mult": 0.96,
        "cooldown_mult": 0.95,
        "scale_mult": 1.28,
        "affix_min": 2,
        "affix_max": 3
    }
]

const WOLF_AFFIXES := [
    {
        "id": "rabid",
        "prefix": "Rabid",
        "weight": 22.0,
        "min_threat": 1,
        "health_mult": 0.90,
        "damage_mult": 1.15,
        "speed_mult": 1.18,
        "cooldown_mult": 0.82,
        "detection_mult": 1.10,
        "glow_strength_add": 0.05,
        "tags": ["fast", "aggressive"],
        "incompatible": ["ironhide"]
    },
    {
        "id": "ironhide",
        "prefix": "Ironhide",
        "weight": 16.0,
        "min_threat": 2,
        "health_mult": 1.45,
        "damage_mult": 1.05,
        "speed_mult": 0.82,
        "cooldown_mult": 1.08,
        "detection_mult": 1.00,
        "contrast_add": 0.15,
        "tags": ["durable"],
        "incompatible": ["rabid"]
    },
    {
        "id": "void_flecked",
        "prefix": "Void-Flecked",
        "weight": 13.0,
        "min_threat": 2,
        "health_mult": 1.10,
        "damage_mult": 1.22,
        "speed_mult": 1.04,
        "cooldown_mult": 0.96,
        "detection_mult": 1.20,
        "glow_strength_add": 0.22,
        "overlay": "void_wounds_01",
        "tags": ["corrupted"]
    },
    {
        "id": "frostbitten",
        "prefix": "Frostbitten",
        "weight": 12.0,
        "min_threat": 1,
        "health_mult": 1.05,
        "damage_mult": 1.00,
        "speed_mult": 0.92,
        "cooldown_mult": 1.00,
        "detection_mult": 1.05,
        "glow_strength_add": 0.12,
        "overlay": "frost_breath_01",
        "tags": ["cold"]
    },
    {
        "id": "spine_torn",
        "prefix": "Spine-Torn",
        "weight": 10.0,
        "min_threat": 3,
        "health_mult": 1.20,
        "damage_mult": 1.30,
        "speed_mult": 0.94,
        "cooldown_mult": 1.05,
        "detection_mult": 1.00,
        "overlay": "corruption_spine_01",
        "tags": ["mutated"]
    },
    {
        "id": "hollow",
        "prefix": "Hollow",
        "weight": 18.0,
        "min_threat": 1,
        "health_mult": 0.85,
        "damage_mult": 1.05,
        "speed_mult": 1.08,
        "cooldown_mult": 0.95,
        "detection_mult": 0.90,
        "contrast_add": -0.08,
        "tags": ["pale"]
    }
]

const BIOME_MODS := {
    "default": {
        "family_weight_mult": {},
        "stat_mult": {
            "health": 1.0,
            "damage": 1.0,
            "speed": 1.0
        },
        "palettes": ["ash", "slate", "blue_grey"]
    },
    "industrial_ruin": {
        "family_weight_mult": {
            "wolf_scavenger": 1.20,
            "wolf_stalker": 1.10,
            "wolf_corrupted": 0.90
        },
        "stat_mult": {
            "health": 1.0,
            "damage": 1.0,
            "speed": 0.97
        },
        "palettes": ["ash", "rustback", "slate", "blue_grey"]
    },
    "forest_ruin": {
        "family_weight_mult": {
            "wolf_stalker": 1.25,
            "wolf_alpha": 1.10
        },
        "stat_mult": {
            "health": 1.0,
            "damage": 0.98,
            "speed": 1.05
        },
        "palettes": ["moss_grey", "ash", "pale_green", "blue_grey"]
    },
    "void_contaminated": {
        "family_weight_mult": {
            "wolf_corrupted": 1.85,
            "wolf_ancient": 1.30
        },
        "stat_mult": {
            "health": 1.10,
            "damage": 1.15,
            "speed": 1.03
        },
        "palettes": ["void_pale", "violet_grey", "blue_grey"]
    }
}

const PALETTES := {
    "ash": {
        "primary": Color(0.72, 0.78, 0.78, 1.0),
        "glow": Color(0.25, 0.65, 0.85, 1.0),
        "glow_strength": 0.00,
        "contrast": 1.00
    },
    "slate": {
        "primary": Color(0.55, 0.66, 0.70, 1.0),
        "glow": Color(0.20, 0.55, 0.85, 1.0),
        "glow_strength": 0.02,
        "contrast": 1.05
    },
    "blue_grey": {
        "primary": Color(0.58, 0.73, 0.78, 1.0),
        "glow": Color(0.25, 0.72, 0.95, 1.0),
        "glow_strength": 0.04,
        "contrast": 1.05
    },
    "rustback": {
        "primary": Color(0.78, 0.66, 0.56, 1.0),
        "glow": Color(0.95, 0.45, 0.25, 1.0),
        "glow_strength": 0.03,
        "contrast": 1.08
    },
    "moss_grey": {
        "primary": Color(0.58, 0.68, 0.60, 1.0),
        "glow": Color(0.55, 0.90, 0.65, 1.0),
        "glow_strength": 0.02,
        "contrast": 1.00
    },
    "pale_green": {
        "primary": Color(0.70, 0.82, 0.72, 1.0),
        "glow": Color(0.55, 1.00, 0.80, 1.0),
        "glow_strength": 0.04,
        "contrast": 0.95
    },
    "void_pale": {
        "primary": Color(0.82, 0.82, 0.92, 1.0),
        "glow": Color(0.70, 0.35, 1.00, 1.0),
        "glow_strength": 0.18,
        "contrast": 1.15
    },
    "violet_grey": {
        "primary": Color(0.62, 0.58, 0.76, 1.0),
        "glow": Color(0.75, 0.35, 1.00, 1.0),
        "glow_strength": 0.14,
        "contrast": 1.12
    }
}

const NAME_PREFIXES := [
    "Ash",
    "Pale",
    "Cold",
    "Gutter",
    "Sump",
    "Rustback",
    "Hollow",
    "Old",
    "Broken",
    "Starved"
]


static func generate_wolf_variant(
    seed: int,
    biome_id: String,
    threat_level: int,
    context: Dictionary = {}
) -> EnemyVariantProfile:
    threat_level = clampi(threat_level, 1, 5)

    var family_rng := _make_rng(seed, "family")
    var tier_rng := _make_rng(seed, "tier")
    var stat_rng := _make_rng(seed, "stats")
    var affix_rng := _make_rng(seed, "affixes")
    var visual_rng := _make_rng(seed, "visuals")
    var behavior_rng := _make_rng(seed, "behavior")
    var name_rng := _make_rng(seed, "name")

    var biome := BIOME_MODS.get(biome_id, BIOME_MODS["default"])
    var family := _pick_family(family_rng, biome, threat_level, context)
    var tier := _pick_tier(tier_rng, threat_level, context)
    var affixes := _pick_affixes(affix_rng, family, tier, threat_level, context)
    var behavior_id := _pick_behavior(behavior_rng, family, tier, affixes, context)
    var attack_profile_id := _pick_attack_profile(behavior_rng, family, tier, affixes)
    var special_profile_id := _pick_special_profile(behavior_rng, family, tier, affixes)
    var palette := _pick_palette(visual_rng, biome, family, tier, affixes)

    var profile := EnemyVariantProfile.new()
    profile.seed = seed
    profile.variant_id = "wolf_%s_%s" % [str(seed), str(FACTORY_VERSION)]
    profile.archetype_id = "wolf"
    profile.family_id = str(family["id"])
    profile.elite_tier = str(tier["id"])
    profile.threat_level = threat_level
    profile.behavior_id = behavior_id
    profile.attack_profile_id = attack_profile_id
    profile.special_profile_id = special_profile_id
    profile.affixes = affixes

    _roll_stats(profile, stat_rng, family, tier, affixes, biome, threat_level)
    _roll_visuals(profile, visual_rng, family, tier, affixes, palette)
    _apply_safety_clamps(profile, threat_level)
    _generate_name(profile, name_rng, family, tier, affixes)

    profile.debug_rolls = {
        "factory_version": FACTORY_VERSION,
        "biome_id": biome_id,
        "family": family["id"],
        "tier": tier["id"],
        "affixes": affixes,
        "behavior": behavior_id,
        "attack_profile": attack_profile_id,
        "special_profile": special_profile_id,
        "palette": palette
    }

    return profile


static func _roll_stats(
    profile: EnemyVariantProfile,
    rng: RandomNumberGenerator,
    family: Dictionary,
    tier: Dictionary,
    affixes: Array[String],
    biome: Dictionary,
    threat_level: int
) -> void:
    var threat_mult: float = float(THREAT_MULTIPLIERS[threat_level])
    var biome_stats: Dictionary = biome.get("stat_mult", {})

    var health := _rand_range_i(rng, family["health"])
    var damage := _rand_range_i(rng, family["damage"])
    var speed := _rand_range_f(rng, family["speed"])
    var cooldown := _rand_range_f(rng, family["cooldown"])
    var attack_range := _rand_range_f(rng, family["range"])
    var detection := _rand_range_f(rng, family["detection"])
    var collision := _rand_range_f(rng, family["collision"])

    health = roundi(float(health) * threat_mult * float(tier["health_mult"]) * float(biome_stats.get("health", 1.0)))
    damage = roundi(float(damage) * threat_mult * float(tier["damage_mult"]) * float(biome_stats.get("damage", 1.0)))
    speed = speed * float(tier["speed_mult"]) * float(biome_stats.get("speed", 1.0))
    cooldown = cooldown * float(tier["cooldown_mult"])

    for affix_id in affixes:
        var affix := _get_affix(affix_id)
        health = roundi(float(health) * float(affix.get("health_mult", 1.0)))
        damage = roundi(float(damage) * float(affix.get("damage_mult", 1.0)))
        speed *= float(affix.get("speed_mult", 1.0))
        cooldown *= float(affix.get("cooldown_mult", 1.0))
        detection *= float(affix.get("detection_mult", 1.0))

    profile.max_health = health
    profile.attack_damage = damage
    profile.move_speed = speed
    profile.attack_cooldown = cooldown
    profile.attack_range = attack_range
    profile.detection_radius = detection
    profile.leash_radius = detection * 1.8
    profile.collision_radius = collision
    profile.hurtbox_radius = collision + 2.0


static func _roll_visuals(
    profile: EnemyVariantProfile,
    rng: RandomNumberGenerator,
    family: Dictionary,
    tier: Dictionary,
    affixes: Array[String],
    palette: Dictionary
) -> void:
    var base_scale_range: Vector2 = family["scale"]
    var scale_value := rng.randf_range(base_scale_range.x, base_scale_range.y)
    scale_value *= float(tier["scale_mult"])

    # Small independent x/y variation, but keep it subtle.
    var x_squash := rng.randf_range(0.96, 1.04)
    var y_squash := rng.randf_range(0.97, 1.06)

    profile.body_scale = Vector2(scale_value * x_squash, scale_value * y_squash)

    profile.animation_speed_scale = rng.randf_range(0.92, 1.08)
    if profile.elite_tier == "nemesis":
        profile.animation_speed_scale *= 0.95
    elif profile.elite_tier == "elite":
        profile.animation_speed_scale *= 1.04

    profile.primary_tint = palette["primary"]
    profile.glow_color = palette["glow"]
    profile.glow_strength = float(palette["glow_strength"])
    profile.contrast_boost = float(palette["contrast"])

    var overlays: Array[String] = []

    for affix_id in affixes:
        var affix := _get_affix(affix_id)

        if affix.has("overlay"):
            overlays.append(str(affix["overlay"]))

        profile.glow_strength += float(affix.get("glow_strength_add", 0.0))
        profile.contrast_boost += float(affix.get("contrast_add", 0.0))

    match profile.elite_tier:
        "veteran":
            profile.contrast_boost += 0.05
        "elite":
            profile.contrast_boost += 0.12
            profile.glow_strength += 0.08
            overlays.append("eyes_glow_01")
        "nemesis":
            profile.contrast_boost += 0.20
            profile.glow_strength += 0.16
            overlays.append("eyes_glow_01")
            overlays.append("elite_mark_01")

    profile.overlay_set = overlays


static func _apply_safety_clamps(profile: EnemyVariantProfile, threat_level: int) -> void:
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

    # Prevent accidental insane DPS variants.
    var dps := float(profile.attack_damage) / profile.attack_cooldown
    var max_dps: float = float(MAX_DPS_BY_THREAT[threat_level])

    if dps > max_dps:
        profile.attack_cooldown = float(profile.attack_damage) / max_dps
        profile.attack_cooldown = clampf(profile.attack_cooldown, 0.35, 2.25)


static func _pick_family(
    rng: RandomNumberGenerator,
    biome: Dictionary,
    threat_level: int,
    context: Dictionary
) -> Dictionary:
    var candidates: Array = []
    var family_weight_mult: Dictionary = biome.get("family_weight_mult", {})

    for family in WOLF_FAMILIES:
        if threat_level < int(family["min_threat"]):
            continue
        if threat_level > int(family["max_threat"]):
            continue

        var weight := float(family["weight"])
        weight *= float(family_weight_mult.get(family["id"], 1.0))

        # Optional director pressure: stronger variants slightly more likely.
        var pressure := float(context.get("director_pressure", 0.0))
        if pressure > 0.0:
            if family["id"] in ["wolf_alpha", "wolf_corrupted", "wolf_ancient"]:
                weight *= 1.0 + pressure

        var row := family.duplicate(true)
        row["roll_weight"] = weight
        candidates.append(row)

    return _weighted_pick(rng, candidates)


static func _pick_tier(
    rng: RandomNumberGenerator,
    threat_level: int,
    context: Dictionary
) -> Dictionary:
    var candidates: Array = []
    var pressure := float(context.get("director_pressure", 0.0))

    for tier in ELITE_TIERS:
        var weights: Dictionary = tier["weights"]
        var weight := float(weights.get(threat_level, 0.0))

        if pressure > 0.0 and tier["id"] in ["elite", "nemesis"]:
            weight *= 1.0 + pressure

        var row := tier.duplicate(true)
        row["roll_weight"] = weight
        candidates.append(row)

    return _weighted_pick(rng, candidates)


static func _pick_affixes(
    rng: RandomNumberGenerator,
    family: Dictionary,
    tier: Dictionary,
    threat_level: int,
    context: Dictionary
) -> Array[String]:
    var affixes: Array[String] = []

    var min_count := int(tier["affix_min"])
    var max_count := int(tier["affix_max"])

    var forced_chance := float(family.get("forced_affix_chance", 0.0))
    if rng.randf() < forced_chance:
        max_count = maxi(max_count, 1)

    if max_count <= 0:
        return affixes

    var count := rng.randi_range(min_count, max_count)

    # Give normal enemies a small chance at one light affix.
    if tier["id"] == "normal" and forced_chance <= 0.0:
        if rng.randf() < 0.12:
            count = 1
        else:
            count = 0

    var attempts := 0
    while affixes.size() < count and attempts < 20:
        attempts += 1

        var candidates: Array = []
        for affix in WOLF_AFFIXES:
            if threat_level < int(affix.get("min_threat", 1)):
                continue

            if _affix_conflicts(str(affix["id"]), affixes):
                continue

            var weight := float(affix["weight"])

            # Biome/context nudges.
            if context.get("near_darkness", false) and affix["id"] in ["void_flecked", "hollow"]:
                weight *= 1.35

            var row := affix.duplicate(true)
            row["roll_weight"] = weight
            candidates.append(row)

        if candidates.is_empty():
            break

        var picked := _weighted_pick(rng, candidates)
        affixes.append(str(picked["id"]))

    return affixes


static func _pick_behavior(
    rng: RandomNumberGenerator,
    family: Dictionary,
    tier: Dictionary,
    affixes: Array[String],
    context: Dictionary
) -> String:
    var candidates: Array = family.get("behaviors", [])

    # Minor behavior overrides from affixes.
    if "rabid" in affixes:
        candidates = [
            {"id": "frenzy", "weight": 60.0},
            {"id": "charge", "weight": 40.0}
        ]
    elif "ironhide" in affixes:
        candidates = [
            {"id": "bruiser", "weight": 65.0},
            {"id": "pack_hunter", "weight": 35.0}
        ]

    var picked := _weighted_pick(rng, candidates)
    return str(picked["id"])


static func _pick_attack_profile(
    rng: RandomNumberGenerator,
    family: Dictionary,
    tier: Dictionary,
    affixes: Array[String]
) -> String:
    var candidates: Array = family.get("attack_profiles", [{"id": "bite_basic", "weight": 1.0}])

    if "rabid" in affixes:
        candidates = [
            {"id": "bite_quick", "weight": 65.0},
            {"id": "bite_lunge", "weight": 35.0}
        ]
    elif "ironhide" in affixes:
        candidates = [
            {"id": "bite_heavy", "weight": 75.0},
            {"id": "bite_basic", "weight": 25.0}
        ]

    var picked := _weighted_pick(rng, candidates)
    return str(picked["id"])


static func _pick_special_profile(
    rng: RandomNumberGenerator,
    family: Dictionary,
    tier: Dictionary,
    affixes: Array[String]
) -> String:
    if not family.has("special_profiles"):
        return ""

    # Not every alpha has to howl constantly.
    var chance := 0.45
    if tier["id"] in ["elite", "nemesis"]:
        chance = 0.75

    if rng.randf() > chance:
        return ""

    var picked := _weighted_pick(rng, family["special_profiles"])
    return str(picked["id"])


static func _pick_palette(
    rng: RandomNumberGenerator,
    biome: Dictionary,
    family: Dictionary,
    tier: Dictionary,
    affixes: Array[String]
) -> Dictionary:
    var palette_ids: Array = biome.get("palettes", ["ash", "slate"])

    if family["id"] == "wolf_corrupted":
        palette_ids = ["void_pale", "violet_grey", "blue_grey"]
    elif family["id"] == "wolf_ancient":
        palette_ids = ["void_pale", "ash", "slate"]

    if "void_flecked" in affixes:
        palette_ids = ["void_pale", "violet_grey"]
    elif "frostbitten" in affixes:
        palette_ids = ["blue_grey", "slate", "void_pale"]
    elif "hollow" in affixes:
        palette_ids = ["ash", "void_pale", "pale_green"]

    var palette_id := str(palette_ids[rng.randi_range(0, palette_ids.size() - 1)])
    return PALETTES[palette_id]


static func _generate_name(
    profile: EnemyVariantProfile,
    rng: RandomNumberGenerator,
    family: Dictionary,
    tier: Dictionary,
    affixes: Array[String]
) -> void:
    var nouns: Array = family["nouns"]
    var noun := str(nouns[rng.randi_range(0, nouns.size() - 1)])

    var prefix := ""

    if not affixes.is_empty():
        var affix := _get_affix(affixes[0])
        prefix = str(affix.get("prefix", ""))
    else:
        prefix = str(NAME_PREFIXES[rng.randi_range(0, NAME_PREFIXES.size() - 1)])

    match tier["id"]:
        "normal":
            profile.display_name = "%s %s" % [prefix, noun]
        "veteran":
            profile.display_name = "Veteran %s %s" % [prefix, noun]
        "elite":
            profile.display_name = "Elite %s %s" % [prefix, noun]
        "nemesis":
            profile.display_name = "Nemesis %s %s" % [prefix, noun]
        _:
            profile.display_name = "%s %s" % [prefix, noun]


static func _get_affix(affix_id: String) -> Dictionary:
    for affix in WOLF_AFFIXES:
        if str(affix["id"]) == affix_id:
            return affix
    return {}


static func _affix_conflicts(candidate_id: String, existing: Array[String]) -> bool:
    var candidate := _get_affix(candidate_id)
    var incompatible: Array = candidate.get("incompatible", [])

    for existing_id in existing:
        if existing_id in incompatible:
            return true

        var existing_affix := _get_affix(existing_id)
        var existing_incompatible: Array = existing_affix.get("incompatible", [])
        if candidate_id in existing_incompatible:
            return true

    return false


static func _weighted_pick(rng: RandomNumberGenerator, rows: Array) -> Dictionary:
    if rows.is_empty():
        push_error("EnemyVariantFactory._weighted_pick received empty rows.")
        return {}

    var total := 0.0
    for row in rows:
        total += maxf(0.0, float(row.get("roll_weight", row.get("weight", 0.0))))

    if total <= 0.0:
        return rows[0]

    var roll := rng.randf() * total
    var cursor := 0.0

    for row in rows:
        cursor += maxf(0.0, float(row.get("roll_weight", row.get("weight", 0.0))))
        if roll <= cursor:
            return row

    return rows[rows.size() - 1]


static func _rand_range_i(rng: RandomNumberGenerator, range_value: Vector2i) -> int:
    return rng.randi_range(range_value.x, range_value.y)


static func _rand_range_f(rng: RandomNumberGenerator, range_value: Vector2) -> float:
    return rng.randf_range(range_value.x, range_value.y)


static func _make_rng(base_seed: int, salt: String) -> RandomNumberGenerator:
    var rng := RandomNumberGenerator.new()
    rng.seed = _stable_seed(base_seed, salt)
    return rng


static func _stable_seed(base_seed: int, salt: String) -> int:
    var text := "%s:%s:%s" % [str(base_seed), salt, str(FACTORY_VERSION)]
    return hash(text) & 0x7fffffff
```

---

# Why This Factory Is Better

## 1. It has stable randomness

Changing palette logic will not change health rolls.

This matters a lot once you start saving generated rooms.

---

## 2. It separates family, tier, and affixes

A wolf is no longer just one random enemy. It becomes:

```text
family: wolf_stalker
tier: elite
affixes: void_flecked, rabid
behavior: frenzy
attack: bite_lunge
palette: void_pale
```

That gives you a lot of variety without making dozens of handmade enemies.

---

## 3. It has safety clamps

This prevents accidentally generating:

```text
250 speed wolf
0.1 second attack cooldown
80 damage normal enemy
giant collision body
```

Procedural systems need clamps. Otherwise one unlucky table edit can make the game feel broken.

---

## 4. It has DPS normalization

This part is important:

```gdscript
var dps := float(profile.attack_damage) / profile.attack_cooldown
```

A fast weak wolf and slow strong wolf can both be fair. But a fast strong wolf becomes unfair fast. The factory caps this.

---

# Recommended Behavior Profiles

The factory should only set `behavior_id`. Your enemy AI script should interpret it.

Example behavior meanings:

```text
pack_hunter:
  basic chase behavior
  prefers attacking with other wolves nearby
  backs off briefly after biting

skirmisher:
  darts in and out
  shorter commitment
  lower damage, higher speed

ambusher:
  waits until player is close
  slower movement
  stronger first bite

circle_player:
  tries to flank before biting
  good for stalker variants

charge:
  telegraphed straight-line rush
  good for alpha or rabid wolves

frenzy:
  rapid aggression
  low patience
  short cooldown
  dangerous but less defensive

pack_leader:
  uses howl
  buffs nearby wolves
  keeps some distance until pack engages

bruiser:
  slow, heavy, more health
  bigger collision and attack range

howl_summoner:
  rare ancient/nemesis behavior
  can alert or spawn lesser wolves
```

First implementation should fully support:

```text
pack_hunter
skirmisher
ambusher
charge
```

Stub the rest so the profile can generate them without crashing.

---

# Attack Profiles

Create a simple attack-profile table in your wolf enemy script or a separate config:

```gdscript
const ATTACK_PROFILES := {
    "bite_basic": {
        "animation": "bite_east",
        "active_start_frame": 2,
        "active_end_frame": 3,
        "lunge_distance": 0.0,
        "windup_speed_mult": 1.0
    },
    "bite_quick": {
        "animation": "bite_east",
        "active_start_frame": 1,
        "active_end_frame": 2,
        "lunge_distance": 4.0,
        "windup_speed_mult": 1.15
    },
    "bite_lunge": {
        "animation": "bite_east",
        "active_start_frame": 2,
        "active_end_frame": 3,
        "lunge_distance": 16.0,
        "windup_speed_mult": 1.0
    },
    "bite_heavy": {
        "animation": "bite_east",
        "active_start_frame": 3,
        "active_end_frame": 4,
        "lunge_distance": 8.0,
        "windup_speed_mult": 0.85
    },
    "bite_crushing": {
        "animation": "bite_east",
        "active_start_frame": 3,
        "active_end_frame": 5,
        "lunge_distance": 10.0,
        "windup_speed_mult": 0.75
    }
}
```

The factory gives you:

```gdscript
profile.attack_profile_id = "bite_lunge"
```

The wolf enemy script decides how that works.

---

# Special Profiles

Same idea for howl:

```gdscript
const SPECIAL_PROFILES := {
    "howl_alert": {
        "animation": "howl_east",
        "radius": 280.0,
        "effect": "alert_nearby_wolves",
        "cooldown": 10.0
    },
    "howl_buff_pack": {
        "animation": "howl_east",
        "radius": 220.0,
        "effect": "buff_nearby_wolves",
        "cooldown": 14.0
    },
    "howl_summon_scavengers": {
        "animation": "howl_east",
        "radius": 320.0,
        "effect": "summon_scavenger_wolves",
        "cooldown": 20.0
    }
}
```

---

# Example Generated Variants

The factory can produce enemies like:

```text
Ash Scavenger
family: wolf_scavenger
tier: normal
behavior: pack_hunter
attack: bite_basic
stats: low health, fast, basic bite
```

```text
Rabid Slinker
family: wolf_stalker
tier: veteran
affixes: rabid
behavior: frenzy
attack: bite_quick
stats: fast, lower health, scary cooldown
```

```text
Elite Void-Flecked Alpha
family: wolf_alpha
tier: elite
affixes: void_flecked
behavior: pack_leader
special: howl_buff_pack
visuals: glow eyes, void wounds, larger body
```

```text
Nemesis Spine-Torn Bone-Packlord
family: wolf_ancient
tier: nemesis
affixes: spine_torn, ironhide
behavior: howl_summoner
special: howl_summon_scavengers
visuals: huge, slow, durable, glowing wounds
```

---

# Codex Task Addendum

Paste this after the previous implementation spec:

```text
Expand EnemyVariantFactory into a deterministic data-composition system, not a simple random stat picker.

The factory must:
- use separate deterministic RNG streams for family, tier, stats, affixes, visuals, behavior, and naming
- generate EnemyVariantProfile only
- never instantiate scenes
- never load animation resources
- support biome-specific family weights and palette choices
- support wolf families: wolf_scavenger, wolf_stalker, wolf_alpha, wolf_corrupted, wolf_ancient
- support elite tiers: normal, veteran, elite, nemesis
- support affixes: rabid, ironhide, void_flecked, frostbitten, spine_torn, hollow
- support behavior IDs: pack_hunter, skirmisher, ambusher, circle_player, charge, frenzy, pack_leader, bruiser, howl_summoner
- support attack profile IDs: bite_basic, bite_quick, bite_lunge, bite_heavy, bite_crushing
- support special profile IDs: howl_alert, howl_buff_pack, howl_summon_scavengers
- include safety clamps for health, speed, cooldown, detection radius, collision radius, glow strength, and contrast
- include DPS normalization so generated wolves cannot exceed a max DPS budget per threat level
- write useful debug_rolls into the profile so generated enemies can be inspected in the test lab

Important:
The same seed, biome_id, threat_level, and context dictionary should always generate the same profile.
Changing cosmetic logic should not affect stat rolls.
Use separate RNG streams derived from the base seed and salt strings.
```

This gives you a factory that can scale from “basic wolf enemies” to a real procedural enemy ecosystem without rewriting the enemy scene every time.
