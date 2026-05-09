# CUSTODIAN Procedural Enemy Variant System

**Status:** Development Specification  
**Last Updated:** 2026-05-06  
**Scope:** Beast Pack (alpha-based) + Wolf (Aseprite JSON) enemy pipelines with shared variant factory

---

## Overview

The procedural enemy system generates deterministic enemy variants from sprite sheets at runtime. It combines:
- **Asset Pipeline:** Extract and normalize animation frames from source spritesheets
- **Variant Factory:** Compose enemy stats, visuals, and behavior from seed + context
- **Runtime Application:** Apply profiles to enemy scenes without baking variants

**Design Principles:**
- Generate data only (profiles), not scenes or sprites
- Deterministic from seed (separate RNG streams for stability)
- Family → Tier → Affix composition for variety
- Safety clamps to prevent broken variants
- DPS normalization per threat level

---

## Table of Contents

1. [Asset Pipelines](#1-asset-pipelines)
   - Beast Pack (Alpha-Based Extraction)
   - Wolf (Aseprite JSON Pipeline)
2. [Procedural Variant Factory](#2-procedural-variant-factory)
   - Core Design
   - Enemy Variant Profile
   - Family System
   - Elite Tiers
   - Affix System
   - Biome Modifications
   - Palette System
   - Deterministic RNG
   - Safety Clamps & DPS Normalization
3. [Enemy Scene Structure](#3-enemy-scene-structure)
4. [Animation System](#4-animation-system)
5. [Visual Mutation System](#5-visual-mutation-system)
6. [Behavior System](#6-behavior-system)
7. [Attack & Special Profiles](#7-attack--special-profiles)
8. [Spawner Integration](#8-spawner-integration)
9. [Test Lab](#9-test-lab)
10. [Implementation Phases](#10-implementation-phases)
11. [File Structure](#11-file-structure)

---

## 1. Asset Pipelines

### Beast Pack (Alpha-Based Extraction)

**Source:** `content/sprites/enemies/beast_pack/source/beast_sheet.png`

The beast sheet has transparent background, irregular spacing, and multiple creature types. Use alpha-based connected-component detection.

#### Extraction Tool
**File:** `tools/sprite_extraction/extract_alpha_frames.gd`

**Behavior:**
1. Load source PNG, read all pixels
2. Detect connected alpha regions (alpha > 8)
3. Ignore blobs smaller than 6×6 pixels or 20 pixel area
4. Get bounding boxes, pad by 4px
5. Export each frame as separate PNG
6. Save `frame_metadata.json`

**Output:**
```
content/sprites/enemies/beast_pack/extracted/raw/frame_000.png
content/sprites/enemies/beast_pack/extracted/raw/frame_metadata.json
```

**Frame Metadata Example:**
```json
{
  "source": "res://content/sprites/enemies/beast_pack/source/beast_sheet.png",
  "frames": [
    {
      "id": "frame_000",
      "source_rect": [17, 22, 31, 20],
      "center": [32, 32],
      "row_hint": 0,
      "width": 31,
      "height": 20
    }
  ]
}
```

#### Animation Classification
**File:** `tools/sprite_extraction/classify_enemy_frames.gd`

Classify frames using:
- Row hint (vertical center bucket)
- Pose width/height and aspect ratio
- Source x-position
- Manual override file

**Manual Map:** `content/sprites/enemies/beast_pack/source/animation_map.json`

```json
{
  "animations": {
    "crawl_east": {
      "frames": ["frame_000", "frame_001", "frame_002", "frame_003"],
      "fps": 8,
      "loop": true
    },
    "idle_east": { ... },
    "attack_east": { ... },
    "death_east": { ... }
  }
}
```

#### Normalization
**File:** `tools/sprite_extraction/bake_enemy_variants.gd`

Normalize all frames to **48×48** canvas (64×64 for large mutants).

**Ground Anchor:** x = 24, y = 32 (65% down)

Output:
```
content/sprites/enemies/beast_pack/extracted/crawl/crawl_east_000.png
content/sprites/enemies/beast_pack/extracted/idle/idle_east_000.png
...
```

---

### Wolf (Aseprite JSON Pipeline)

**Source Files:**
```
content/sprites/enemies/wolf/source/
  wolf-all.png + wolf-all.json
  wolf-idle.png + wolf-idle.json
  wolf-run.png + wolf-run.json
  wolf-bite.png + wolf-bite.json
  wolf-death.png + wolf-death.json
  wolf-howl.png + wolf-howl.json
```

These are already normalized square frames but vary in size per animation (48×48 to 72×72). Use Aseprite JSON as source of truth.

#### Aseprite Export Command
```bash
aseprite -b wolf-idle.aseprite \
  --sheet wolf-idle.png \
  --data wolf-idle.json \
  --format json-array \
  --list-tags \
  --list-slices
```

JSON must include: frame rectangles, frame durations, frame tags, source size.

#### Animation Config
**File:** `content/sprites/enemies/wolf/source/wolf_animation_config.json`

```json
{
  "enemy_id": "wolf",
  "canonical_canvas": [96, 96],
  "ground_anchor": [48, 68],
  "default_fps": 10,
  "animations": {
    "idle_east": {
      "image": "res://content/sprites/enemies/wolf/source/wolf-idle.png",
      "json": "res://content/sprites/enemies/wolf/source/wolf-idle.json",
      "loop": true,
      "fallback_fps": 6
    },
    "run_east": { ... },
    "bite_east": { ... },
    "death_east": { ... },
    "howl_east": { ... }
  }
}
```

#### Baking Rule
**File:** `game/enemies/procgen/wolf_animation_baker.gd`

All frames → **96×96** shared canvas with ground anchor x=48, y=68.

**Why:** Prevents visual "jumping" when switching animations with different source square sizes.

**Baking Steps:**
1. Read animation config and Aseprite JSON files
2. Extract frame rectangles from source sheets
3. Create 96×96 transparent image per frame
4. Paste source frame aligned to ground anchor
5. Export to `content/sprites/enemies/wolf/normalized/`
6. Generate `wolf_animation_manifest.json`

**Ground Anchor Logic:**
```
target_x = anchor_x - (source_frame_width / 2)
target_y = anchor_y - source_frame_height + bottom_padding(6)
```

---

## 2. Procedural Variant Factory

### Core Design

**File:** `game/enemies/procgen/enemy_variant_factory.gd`

The factory is a **deterministic enemy composer** that builds `EnemyVariantProfile` from:
```
seed + biome_id + threat_level + context tags
```

**Critical Rule:** Factory generates **data only**.
- Does NOT instantiate enemies
- Does NOT load sprites
- Does NOT touch scenes

### Enemy Variant Profile

**File:** `game/enemies/procgen/enemy_variant_profile.gd`

```gdscript
extends Resource
class_name EnemyVariantProfile

@export var variant_id: String = ""
@export var archetype_id: String = "wolf"      # wolf, beast, etc.
@export var family_id: String = "wolf_scavenger"
@export var display_name: String = "Wolf"

# Stats
@export var max_health: int = 30
@export var move_speed: float = 90.0
@export var attack_damage: int = 8
@export var attack_range: float = 24.0
@export var attack_cooldown: float = 0.8
@export var detection_radius: float = 180.0
@export var leash_radius: float = 360.0

# Collision
@export var collision_radius: float = 14.0
@export var hurtbox_radius: float = 16.0

# Visuals
@export var body_scale: Vector2 = Vector2.ONE
@export var animation_speed_scale: float = 1.0
@export var primary_tint: Color = Color.WHITE
@export var glow_color: Color = Color.TRANSPARENT
@export var glow_strength: float = 0.0
@export var contrast_boost: float = 1.0
@export var overlay_set: Array[String] = []

# Gameplay
@export var behavior_id: String = "pack_hunter"
@export var attack_profile_id: String = "bite_basic"
@export var special_profile_id: String = ""

# Meta
@export var elite_tier: String = "normal"  # normal, veteran, elite, nemesis
@export var threat_level: int = 1
@export var seed: int = 0
@export var affixes: Array[String] = []

# Debug
var debug_rolls: Dictionary = {}
```

### Deterministic RNG Streams

**Critical Improvement:** Use separate RNG streams so cosmetic changes don't affect stat rolls.

```gdscript
static func generate_wolf_variant(
    seed: int,
    biome_id: String,
    threat_level: int,
    context: Dictionary = {}
) -> EnemyVariantProfile:
    threat_level = clampi(threat_level, 1, 5)
    
    # Separate RNG streams
    var family_rng := _make_rng(seed, "family")
    var tier_rng := _make_rng(seed, "tier")
    var stat_rng := _make_rng(seed, "stats")
    var affix_rng := _make_rng(seed, "affixes")
    var visual_rng := _make_rng(seed, "visuals")
    var behavior_rng := _make_rng(seed, "behavior")
    var name_rng := _make_rng(seed, "name")
    
    # Compose profile
    var biome := BIOME_MODS.get(biome_id, BIOME_MODS["default"])
    var family := _pick_family(family_rng, biome, threat_level, context)
    var tier := _pick_tier(tier_rng, threat_level, context)
    var affixes := _pick_affixes(affix_rng, family, tier, threat_level, context)
    var behavior_id := _pick_behavior(behavior_rng, family, tier, affixes, context)
    var attack_profile_id := _pick_attack_profile(behavior_rng, family, tier, affixes)
    var special_profile_id := _pick_special_profile(behavior_rng, family, tier, affixes)
    var palette := _pick_palette(visual_rng, biome, family, tier, affixes)
    
    var profile := EnemyVariantProfile.new()
    # ... apply all properties ...
    return profile

static func _make_rng(base_seed: int, salt: String) -> RandomNumberGenerator:
    var rng := RandomNumberGenerator.new()
    rng.seed = _stable_seed(base_seed, salt)
    return rng

static func _stable_seed(base_seed: int, salt: String) -> int:
    var text := "%s:%s:%s" % [str(base_seed), salt, str(FACTORY_VERSION)]
    return hash(text) & 0x7fffffff
```

### Wolf Family System

```gdscript
const WOLF_FAMILIES := [
    {
        "id": "wolf_scavenger",
        "weight": 45.0,
        "min_threat": 1, "max_threat": 5,
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
        "min_threat": 1, "max_threat": 5,
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
        "min_threat": 2, "max_threat": 5,
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
        "min_threat": 2, "max_threat": 5,
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
        "forced_affix_chance": 0.65
    },
    {
        "id": "wolf_ancient",
        "weight": 3.0,
        "min_threat": 4, "max_threat": 5,
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
        "special_profiles": [
            {"id": "howl_alert", "weight": 40.0},
            {"id": "howl_summon_scavengers", "weight": 60.0}
        ],
        "forced_affix_chance": 1.0
    }
]
```

### Elite Tiers

```gdscript
const ELITE_TIERS := [
    {
        "id": "normal",
        "weights": {1: 86.0, 2: 78.0, 3: 68.0, 4: 56.0, 5: 46.0},
        "health_mult": 1.00, "damage_mult": 1.00, "speed_mult": 1.00,
        "cooldown_mult": 1.00, "scale_mult": 1.00,
        "affix_min": 0, "affix_max": 0
    },
    {
        "id": "veteran",
        "weights": {1: 13.0, 2: 18.0, 3: 24.0, 4: 28.0, 5: 30.0},
        "health_mult": 1.25, "damage_mult": 1.15, "speed_mult": 1.03,
        "cooldown_mult": 0.95, "scale_mult": 1.08,
        "affix_min": 0, "affix_max": 1
    },
    {
        "id": "elite",
        "weights": {1: 1.0, 2: 4.0, 3: 7.0, 4: 12.0, 5: 16.0},
        "health_mult": 1.65, "damage_mult": 1.35, "speed_mult": 1.06,
        "cooldown_mult": 0.90, "scale_mult": 1.16,
        "affix_min": 1, "affix_max": 2
    },
    {
        "id": "nemesis",
        "weights": {1: 0.0, 2: 0.0, 3: 1.0, 4: 4.0, 5: 8.0},
        "health_mult": 2.25, "damage_mult": 1.55, "speed_mult": 0.96,
        "cooldown_mult": 0.95, "scale_mult": 1.28,
        "affix_min": 2, "affix_max": 3
    }
]

const THREAT_MULTIPLIERS := {
    1: 1.00, 2: 1.20, 3: 1.45, 4: 1.75, 5: 2.10
}
```

### Affix System

```gdscript
const WOLF_AFFIXES := [
    {
        "id": "rabid",
        "prefix": "Rabid",
        "weight": 22.0, "min_threat": 1,
        "health_mult": 0.90, "damage_mult": 1.15, "speed_mult": 1.18,
        "cooldown_mult": 0.82, "detection_mult": 1.10,
        "glow_strength_add": 0.05,
        "tags": ["fast", "aggressive"],
        "incompatible": ["ironhide"]
    },
    {
        "id": "ironhide",
        "prefix": "Ironhide",
        "weight": 16.0, "min_threat": 2,
        "health_mult": 1.45, "damage_mult": 1.05, "speed_mult": 0.82,
        "cooldown_mult": 1.08, "detection_mult": 1.00,
        "contrast_add": 0.15,
        "tags": ["durable"],
        "incompatible": ["rabid"]
    },
    {
        "id": "void_flecked",
        "prefix": "Void-Flecked",
        "weight": 13.0, "min_threat": 2,
        "health_mult": 1.10, "damage_mult": 1.22, "speed_mult": 1.04,
        "cooldown_mult": 0.96, "detection_mult": 1.20,
        "glow_strength_add": 0.22,
        "overlay": "void_wounds_01",
        "tags": ["corrupted"]
    },
    {
        "id": "frostbitten",
        "prefix": "Frostbitten",
        "weight": 12.0, "min_threat": 1,
        "health_mult": 1.05, "damage_mult": 1.00, "speed_mult": 0.92,
        "cooldown_mult": 1.00, "detection_mult": 1.05,
        "glow_strength_add": 0.12,
        "overlay": "frost_breath_01",
        "tags": ["cold"]
    },
    {
        "id": "spine_torn",
        "prefix": "Spine-Torn",
        "weight": 10.0, "min_threat": 3,
        "health_mult": 1.20, "damage_mult": 1.30, "speed_mult": 0.94,
        "cooldown_mult": 1.05, "detection_mult": 1.00,
        "overlay": "corruption_spine_01",
        "tags": ["mutated"]
    },
    {
        "id": "hollow",
        "prefix": "Hollow",
        "weight": 18.0, "min_threat": 1,
        "health_mult": 0.85, "damage_mult": 1.05, "speed_mult": 1.08,
        "cooldown_mult": 0.95, "detection_mult": 0.90,
        "contrast_add": -0.08,
        "tags": ["pale"]
    }
]
```

### Biome Modifications

```gdscript
const BIOME_MODS := {
    "default": {
        "family_weight_mult": {},
        "stat_mult": {"health": 1.0, "damage": 1.0, "speed": 1.0},
        "palettes": ["ash", "slate", "blue_grey"]
    },
    "industrial_ruin": {
        "family_weight_mult": {
            "wolf_scavenger": 1.20, "wolf_stalker": 1.10, "wolf_corrupted": 0.90
        },
        "stat_mult": {"health": 1.0, "damage": 1.0, "speed": 0.97},
        "palettes": ["ash", "rustback", "slate", "blue_grey"]
    },
    "forest_ruin": {
        "family_weight_mult": {"wolf_stalker": 1.25, "wolf_alpha": 1.10},
        "stat_mult": {"health": 1.0, "damage": 0.98, "speed": 1.05},
        "palettes": ["moss_grey", "ash", "pale_green", "blue_grey"]
    },
    "void_contaminated": {
        "family_weight_mult": {"wolf_corrupted": 1.85, "wolf_ancient": 1.30},
        "stat_mult": {"health": 1.10, "damage": 1.15, "speed": 1.03},
        "palettes": ["void_pale", "violet_grey", "blue_grey"]
    }
}
```

### Palette System

```gdscript
const PALETTES := {
    "ash": {
        "primary": Color(0.72, 0.78, 0.78, 1.0),
        "glow": Color(0.25, 0.65, 0.85, 1.0),
        "glow_strength": 0.00, "contrast": 1.00
    },
    "slate": {
        "primary": Color(0.55, 0.66, 0.70, 1.0),
        "glow": Color(0.20, 0.55, 0.85, 1.0),
        "glow_strength": 0.02, "contrast": 1.05
    },
    "blue_grey": {
        "primary": Color(0.58, 0.73, 0.78, 1.0),
        "glow": Color(0.25, 0.72, 0.95, 1.0),
        "glow_strength": 0.04, "contrast": 1.05
    },
    "rustback": {
        "primary": Color(0.78, 0.66, 0.56, 1.0),
        "glow": Color(0.95, 0.45, 0.25, 1.0),
        "glow_strength": 0.03, "contrast": 1.08
    },
    "moss_grey": {
        "primary": Color(0.58, 0.68, 0.60, 1.0),
        "glow": Color(0.55, 0.90, 0.65, 1.0),
        "glow_strength": 0.02, "contrast": 1.00
    },
    "pale_green": {
        "primary": Color(0.70, 0.82, 0.72, 1.0),
        "glow": Color(0.55, 1.00, 0.80, 1.0),
        "glow_strength": 0.04, "contrast": 0.95
    },
    "void_pale": {
        "primary": Color(0.82, 0.82, 0.92, 1.0),
        "glow": Color(0.70, 0.35, 1.00, 1.0),
        "glow_strength": 0.18, "contrast": 1.15
    },
    "violet_grey": {
        "primary": Color(0.62, 0.58, 0.76, 1.0),
        "glow": Color(0.75, 0.35, 1.00, 1.0),
        "glow_strength": 0.14, "contrast": 1.12
    }
}
```

### Safety Clamps & DPS Normalization

```gdscript
const MAX_DPS_BY_THREAT := {
    1: 12.0, 2: 18.0, 3: 26.0, 4: 36.0, 5: 48.0
}

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
    
    # Prevent insane DPS variants
    var dps := float(profile.attack_damage) / profile.attack_cooldown
    var max_dps: float = float(MAX_DPS_BY_THREAT[threat_level])
    if dps > max_dps:
        profile.attack_cooldown = float(profile.attack_damage) / max_dps
        profile.attack_cooldown = clampf(profile.attack_cooldown, 0.35, 2.25)
```

---

## 3. Enemy Scene Structure

### Wolf Enemy Scene
**Files:**
- `game/enemies/wolf/wolf_enemy.tscn`
- `game/enemies/wolf/wolf_enemy.gd`

**Scene Tree:**
```
WolfEnemy (CharacterBody2D)
  VisualRoot (Node2D)
    BodySprite (AnimatedSprite2D)
    OverlaySprite (AnimatedSprite2D)
    GlowSprite (AnimatedSprite2D)
  CollisionShape2D
  Hurtbox (Area2D)
    CollisionShape2D
  Hitbox (Area2D)
    CollisionShape2D
  NavigationAgent2D
```

**Script API:**
```gdscript
func apply_variant(profile: EnemyVariantProfile) -> void:
    # Apply sprite frames
    # Apply body tint (shader)
    # Apply glow tint
    # Apply scale
    # Apply animation speed
    # Apply stats
    # Apply behavior profile
    # Apply collision size
    pass
```

**Animation State Mapping:**
- `idle` → `idle_east`
- `move` → `run_east`
- `attack` → `bite_east`
- `special` → `howl_east`
- `death` → `death_east`

**Direction Handling (until directional sheets exist):**
- East movement: `flip_h = false`
- West movement: `flip_h = true`
- North/South: Use east animation, choose flip based on x velocity

**Collision Rules:**
- Do NOT derive collision from sprite bounds
- Use family-based collision shapes:
  - Normal wolf: radius 12-16
  - Large wolf: radius 18-22
  - Beast crawler: radius 10-12
  - Beast stalker: radius 12-14
  - Beast leaper: radius 10-13
  - Beast mutant: radius 16-20

---

## 4. Animation System

### SpriteFrames Builder
**File:** `game/enemies/procgen/wolf_animation_library.gd`

```gdscript
func get_wolf_sprite_frames() -> SpriteFrames:
    # Load wolf_animation_manifest.json
    # Build SpriteFrames resource
    # Set animation loop mode and speed
    # Add normalized frames
    pass
```

### Generated Manifest
**File:** `content/sprites/enemies/wolf/generated/wolf_animation_manifest.json`

```json
{
  "enemy_id": "wolf",
  "canvas": [96, 96],
  "ground_anchor": [48, 68],
  "animations": {
    "idle_east": {
      "loop": true,
      "frames": [
        {"path": "res://content/sprites/enemies/wolf/normalized/wolf_idle_000.png", "duration_ms": 100}
      ]
    },
    "run_east": { ... },
    "bite_east": { ... },
    "death_east": { ... },
    "howl_east": { ... }
  }
}
```

### Attack Timing Metadata
Add to animation config for precise hitbox control:

```json
{
  "attack_windows": {
    "bite_east": {
      "startup_frames": [0, 1],
      "active_frames": [2, 3],
      "recovery_frames": [4, 5]
    }
  }
}
```

**Runtime Behavior:**
- Hitbox disabled during startup
- Hitbox enabled only during active frames
- Hitbox disabled during recovery

---

## 5. Visual Mutation System

### Shader-Based Tinting
**File:** `game/enemies/procgen/enemy_palette_tint.gdshader`

```glsl
shader_type canvas_item;

uniform vec4 primary_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 glow_tint : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float glow_strength = 0.0;
uniform float contrast_boost = 1.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    if (tex.a <= 0.01) {
        COLOR = tex;
        return;
    }
    
    vec3 base = tex.rgb * primary_tint.rgb;
    
    float brightness = max(max(tex.r, tex.g), tex.b);
    vec3 glow = glow_tint.rgb * brightness * glow_strength;
    
    vec3 contrasted = mix(vec3(0.5), base, contrast_boost);
    
    COLOR = vec4(contrasted + glow, tex.a);
}
```

Apply to `BodySprite` as `ShaderMaterial`.

### Supported Mutations
- Palette tint (primary color)
- Glow tint (eyes, wounds)
- Slight scale variation (±4% x, ±6% y)
- Animation speed variation (±8%)
- Overlay sprites (aligned to same canvas)
- Horizontal flip for direction
- Minor vertical squash/stretch

### Overlay System
**Location:** `content/sprites/enemies/wolf/overlays/`

```
eyes_glow_01.png
bite_slash_01.png
corruption_spine_01.png
frost_breath_01.png
void_wounds_01.png
elite_mark_01.png
```

**Overlay Rules:**
- Normal enemies: 0 overlays
- Veteran enemies: 0-1 overlays
- Elite enemies: 1-2 overlays
- Nemesis enemies: 2-3 overlays

Fallback: If overlay animation missing → hide `OverlaySprite`.

### Variant Name Examples
```
Ash Scavenger
Pale Stalker
Rustback Gnawer
Hollow Alpha
Frostbitten Wolf
Void-Flecked Wolf
Ancient Packlord
Spine-Torn Ravager
```

**Name Generation:**
```gdscript
const NAME_PREFIXES := [
    "Ash", "Pale", "Cold", "Gutter", "Sump", 
    "Rustback", "Hollow", "Old", "Broken", "Starved"
]

# Format: [Prefix/] [Affix Prefix/] [Tier] [Family Noun]
# Example: "Elite Void-Flecked Alpha"
```

---

## 6. Behavior System

### Supported Behavior IDs

**First Implementation (fully support):**
- `pack_hunter` - Basic chase, prefers attacking with pack
- `skirmisher` - Dart in/out, lower damage, higher speed
- `ambusher` - Wait until player close, stronger first bite
- `charge` - Telegraphed straight-line rush

**Stub for Later:**
- `circle_player` - Flank before biting
- `frenzy` - Rapid aggression, low patience
- `pack_leader` - Uses howl, buffs nearby wolves
- `bruiser` - Slow, heavy, more health
- `howl_summoner` - Summon lesser wolves

### Behavior Selection
```gdscript
static func _pick_behavior(...) -> String:
    var candidates: Array = family.get("behaviors", [])
    
    # Affix overrides
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
    
    return _weighted_pick(rng, candidates)["id"]
```

---

## 7. Attack & Special Profiles

### Attack Profiles
```gdscript
const ATTACK_PROFILES := {
    "bite_basic": {
        "animation": "bite_east",
        "active_start_frame": 2, "active_end_frame": 3,
        "lunge_distance": 0.0, "windup_speed_mult": 1.0
    },
    "bite_quick": {
        "animation": "bite_east",
        "active_start_frame": 1, "active_end_frame": 2,
        "lunge_distance": 4.0, "windup_speed_mult": 1.15
    },
    "bite_lunge": {
        "animation": "bite_east",
        "active_start_frame": 2, "active_end_frame": 3,
        "lunge_distance": 16.0, "windup_speed_mult": 1.0
    },
    "bite_heavy": {
        "animation": "bite_east",
        "active_start_frame": 3, "active_end_frame": 4,
        "lunge_distance": 8.0, "windup_speed_mult": 0.85
    },
    "bite_crushing": {
        "animation": "bite_east",
        "active_start_frame": 3, "active_end_frame": 5,
        "lunge_distance": 10.0, "windup_speed_mult": 0.75
    }
}
```

### Special Profiles (Howl)
```gdscript
const SPECIAL_PROFILES := {
    "howl_alert": {
        "animation": "howl_east", "radius": 280.0,
        "effect": "alert_nearby_wolves", "cooldown": 10.0
    },
    "howl_buff_pack": {
        "animation": "howl_east", "radius": 220.0,
        "effect": "buff_nearby_wolves", "cooldown": 14.0
    },
    "howl_summon_scavengers": {
        "animation": "howl_east", "radius": 320.0,
        "effect": "summon_scavenger_wolves", "cooldown": 20.0
    }
}
```

**Howl Behavior (minimum first implementation):**
```gdscript
func perform_howl() -> void:
    play_animation("howl_east")
    emit_signal("howled", global_position, howl_radius)
    # Nearby wolves listen and enter combat state
```

---

## 8. Spawner Integration

### Procedural Enemy Spawner
**File:** `game/enemies/procgen/procedural_enemy_spawner.gd`

```gdscript
func spawn_wolf(position: Vector2, seed: int, biome_id: String, threat_level: int) -> Node2D:
    var profile := EnemyVariantFactory.generate_wolf_variant(seed, biome_id, threat_level)
    var enemy := wolf_enemy_scene.instantiate()
    enemy.global_position = position
    enemy.apply_variant(profile)
    get_tree().current_scene.add_child(enemy)
    return enemy
```

### Deterministic Seed Formula
```gdscript
var enemy_seed := hash("%s:%s:%s:%s" % [
    world_seed,
    room_id,
    spawn_index,
    "wolf"  # or "beast"
])
```

Same seed + biome + threat → same variant. Change world seed → different variants.

---

## 9. Test Lab

### Test Scene
**Files:**
- `game/enemies/procgen/test_enemy_variant_lab.tscn`
- `game/enemies/procgen/test_enemy_variant_lab.gd`

**Purpose:** Visual QA for procedural variants before room integration.

**Features:**
- Generate 20 variants in a grid
- Display: `display_name`, `family_id`, `behavior_id`, `threat_level`, `elite_tier`
- **R** key: Reroll variants
- **1-5** keys: Set threat level
- **H** key: Force howl animation
- **B** key: Force bite animation
- **D** key: Force death animation

**Critical:** Procedural systems need quick visual feedback.

---

## 10. Implementation Phases

### Phase 1 — Asset Pipeline
**Beast Pack:**
1. Create `extract_alpha_frames.gd`
2. Export raw frames from `beast_sheet.png`
3. Create `frame_metadata.json`

**Wolf:**
1. Place wolf PNGs and JSONs in `content/sprites/enemies/wolf/source/`
2. Create `wolf_animation_config.json`
3. Create `wolf_animation_baker.gd`
4. Bake all animations into 96×96 normalized frames
5. Generate `wolf_animation_manifest.json`

### Phase 2 — Animation Loading
1. Create `wolf_animation_library.gd` (or `enemy_animation_library.gd` for beast)
2. Load normalized frames
3. Build `SpriteFrames`
4. Verify idle/run/bite/death/howl play correctly

### Phase 3 — Variant Factory
1. Create `enemy_variant_profile.gd`
2. Create `enemy_variant_factory.gd` with:
   - Separate RNG streams
   - Family/tier/affix system
   - Biome modifications
   - Palette system
   - Safety clamps & DPS normalization
3. Implement name generation

### Phase 4 — Basic Enemy Scene
1. Create `wolf_enemy.tscn` (or `procedural_enemy.tscn` for beast)
2. Add AnimatedSprite2D, collision, hurtbox, hitbox
3. Implement `apply_variant(profile)` method
4. Implement idle/run/bite/death state transitions

### Phase 5 — Visual Mutations
1. Add `enemy_palette_tint.gdshader`
2. Add body scale variation
3. Add animation speed variation
4. Add overlay support
5. Create overlay sprites

### Phase 6 — Behavior System
1. Implement `pack_hunter` behavior
2. Implement `skirmisher` behavior
3. Implement `ambusher` behavior
4. Implement `charge` behavior
5. Stub remaining behaviors

### Phase 7 — Spawner Integration
1. Create `procedural_enemy_spawner.gd`
2. Hook into procgen room spawn points
3. Use deterministic world/room/spawn seeds

### Phase 8 — Test Lab
1. Create `test_enemy_variant_lab.tscn`
2. Add grid display with controls
3. Verify variant generation visually

---

## 11. File Structure

```
custodian/
  content/
    sprites/
      enemies/
        beast_pack/
          source/
            beast_sheet.png
            animation_map.json    # Manual override
          extracted/
            raw/
              frame_000.png
              frame_metadata.json
            crawl/
            idle/
            attack/
            death/
          generated/
            variant_cache/
        
        wolf/
          source/
            wolf-all.png + .json
            wolf-idle.png + .json
            wolf-run.png + .json
            wolf-bite.png + .json
            wolf-death.png + .json
            wolf-howl.png + .json
            wolf_animation_config.json
          normalized/
            wolf_idle_000.png
            wolf_run_000.png
            ...
          generated/
            wolf_spriteframes.tres
            wolf_animation_manifest.json
          overlays/
            eyes_glow_01.png
            corruption_spine_01.png
            ...
  
  game/
    enemies/
      base/
        procedural_enemy.gd
        procedural_enemy.tscn
      
      wolf/
        wolf_enemy.gd
        wolf_enemy.tscn
      
      procgen/
        enemy_variant_profile.gd
        enemy_variant_factory.gd
        enemy_visual_mutator.gd
        enemy_animation_library.gd  # or wolf_animation_library.gd
        wolf_animation_baker.gd
        enemy_palette_tint.gdshader
        procedural_enemy_spawner.gd
        test_enemy_variant_lab.tscn
        test_enemy_variant_lab.gd
  
  tools/
    sprite_extraction/
      extract_alpha_frames.gd    # Beast pack
      classify_enemy_frames.gd    # Beast pack
      bake_enemy_variants.gd      # Beast pack
```

---

## Design Documents Source

This document consolidates:
- `design/ENEMY_FACTORY.md` (2168 lines) — Beast pack + wolf pipelines
- `design/VARIANT_FACTORY.my` (1306 lines) — Variant factory implementation

**Duplication removed:**
- Wolf pipeline details merged (kept more detailed VARIANT_FACTORY.my version)
- Shader code deduplicated
- Family/tier/affix tables kept once
- Implementation phases unified

**Last Consolidation:** 2026-05-06
