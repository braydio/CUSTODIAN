This is the feature request file for the procedural enemy generation factory. Once this is implemented in full, this should be moved to a persistent feature document. Until then it should exist in an in-progress / development document for reference by any developer or agent assistant.

---

 + NOTE: The following section focuses heavily on an un-needed alpha-aware sprite detector. As we have the files in a more import friendly layout, this is largely not necessary. The other details should be noted.

---


# CUSTODIAN Procedural Enemy Generation Spec

## Goal

Use a transparent enemy spritesheet as the base visual library for procedurally generated creature enemies.

The system should:

1. Extract usable animation frames from the transparent sheet.
2. Group frames into animation families.
3. Generate visual variants by tinting, scaling, and adding overlays.
4. Generate gameplay variants with different stats and behavior.
5. Spawn enemies deterministically from a seed.
6. Support future enemy sheets without rewriting the system.

---

# 1. Asset Assumption

Current source image:

```text
custodian/content/sprites/enemies/beast_pack/source/beast_sheet.png
```

The sheet has:

```text
transparent background
many small creature frames
multiple implied animation rows
irregular spacing
some rows with different poses/creature types
```

Because spacing is not perfectly uniform, do **not** assume a fixed frame grid at first. Use alpha-based frame detection.

---

# 2. Recommended File Layout

Create this structure:

```text
custodian/
  content/
    sprites/
      enemies/
        beast_pack/
          source/
            beast_sheet.png
          extracted/
            crawl/
            stalk/
            leap/
            idle/
            attack/
            death/
          overlays/
            glow_eye_01.png
            spine_mutation_01.png
            claw_overlay_01.png
            wound_glow_01.png
          generated/
            variant_cache/
  game/
    enemies/
      procgen/
        enemy_variant_profile.gd
        enemy_variant_factory.gd
        enemy_visual_mutator.gd
        enemy_animation_library.gd
      base/
        procedural_enemy.gd
        procedural_enemy.tscn
  tools/
    sprite_extraction/
      extract_alpha_frames.gd
      classify_enemy_frames.gd
      bake_enemy_variants.gd
```

---

# 3. Frame Extraction Tool

## Purpose

Codex should create an editor/runtime-safe extraction script that scans the transparent sheet and finds individual sprites by alpha pixels.

Path:

```text
custodian/tools/sprite_extraction/extract_alpha_frames.gd
```

## Behavior

The tool should:

1. Load the source PNG.
2. Read all pixels.
3. Detect connected alpha regions.
4. Ignore tiny noise blobs.
5. Get bounding boxes for each sprite.
6. Pad each bounding box.
7. Export each detected frame as a separate PNG.
8. Save metadata describing the frame position and size.

Output:

```text
custodian/content/sprites/enemies/beast_pack/extracted/raw/frame_000.png
custodian/content/sprites/enemies/beast_pack/extracted/raw/frame_001.png
...
custodian/content/sprites/enemies/beast_pack/extracted/raw/frame_metadata.json
```

Example metadata:

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

## Important Extraction Rules

Use alpha threshold:

```text
alpha > 8
```

Ignore blobs smaller than:

```text
min_width: 6
min_height: 6
min_area: 20 pixels
```

Apply padding:

```text
padding_x: 4
padding_y: 4
```

Normalize exported frame canvas size later. Do not force all extracted frames to same size during raw extraction.

---

# 4. Animation Classification

The source sheet appears to contain several different pose groups. Codex should not blindly treat every row as one animation. Instead, make a semi-automatic classifier.

Path:

```text
custodian/tools/sprite_extraction/classify_enemy_frames.gd
```

## Classification Strategy

After extraction, classify frames using:

```text
row_hint = vertical center bucket
pose_width
pose_height
sprite aspect ratio
source x-position
manual override file
```

Create a manual map file:

```text
custodian/content/sprites/enemies/beast_pack/source/animation_map.json
```

Example:

```json
{
  "animations": {
    "crawl_east": {
      "frames": ["frame_000", "frame_001", "frame_002", "frame_003"],
      "fps": 8,
      "loop": true
    },
    "idle_east": {
      "frames": ["frame_040", "frame_041", "frame_042", "frame_043"],
      "fps": 5,
      "loop": true
    },
    "attack_east": {
      "frames": ["frame_080", "frame_081", "frame_082", "frame_083"],
      "fps": 10,
      "loop": false
    },
    "death_east": {
      "frames": ["frame_120", "frame_121", "frame_122", "frame_123"],
      "fps": 8,
      "loop": false
    }
  }
}
```

Codex should make the automatic tool generate a first-pass version, but the user can edit it manually.

---

# 5. Normalize Frames

For Godot, each animation should use consistently sized frames.

Create:

```text
custodian/tools/sprite_extraction/bake_enemy_variants.gd
```

This should normalize extracted frames into canvases like:

```text
32x32
48x48
64x64
```

For this sheet, I recommend:

```text
base canvas: 48x48
large mutant canvas: 64x64
```

Most of the creatures look small and low-profile, so `48x48` gives enough room for tails, leap poses, and overlays.

Output:

```text
custodian/content/sprites/enemies/beast_pack/extracted/crawl/crawl_east_000.png
custodian/content/sprites/enemies/beast_pack/extracted/crawl/crawl_east_001.png
...
```

Center frames using:

```text
origin_x = canvas_width / 2
origin_y = canvas_height * 0.65
```

This makes the creature’s feet/body contact point more consistent for top-down placement.

---

# 6. Godot Enemy Animation Library

Create:

```text
custodian/game/enemies/procgen/enemy_animation_library.gd
```

This script loads animation metadata and builds `SpriteFrames`.

## Responsibilities

```text
- load animation_map.json
- load normalized frame PNGs
- create SpriteFrames resource
- expose get_sprite_frames(enemy_family: String) -> SpriteFrames
```

Example public API:

```gdscript
func get_sprite_frames(family_id: String) -> SpriteFrames:
    pass
```

Example family IDs:

```text
beast_crawler
beast_stalker
beast_leaper
beast_mutant
```

---

# 7. Procedural Enemy Scene

Create:

```text
custodian/game/enemies/base/procedural_enemy.tscn
custodian/game/enemies/base/procedural_enemy.gd
```

Scene structure:

```text
ProceduralEnemy CharacterBody2D
  VisualRoot Node2D
    BodySprite AnimatedSprite2D
    OverlaySprite AnimatedSprite2D
    GlowSprite AnimatedSprite2D
  CollisionShape2D
  Hurtbox Area2D
    CollisionShape2D
  Hitbox Area2D
    CollisionShape2D
  NavigationAgent2D
```

## Script Responsibilities

`procedural_enemy.gd` should:

```text
- accept an EnemyVariantProfile
- apply SpriteFrames
- apply tint/material
- apply scale
- apply animation speed
- apply behavior type
- apply stats
- handle idle/move/attack/death animation states
```

Public method:

```gdscript
func apply_variant(profile: EnemyVariantProfile) -> void:
    pass
```

---

# 8. Enemy Variant Profile Resource

Create:

```text
custodian/game/enemies/procgen/enemy_variant_profile.gd
```

This should be a `Resource`.

Fields:

```gdscript
extends Resource
class_name EnemyVariantProfile

@export var variant_id: String
@export var family_id: String

@export var display_name: String

@export var max_health: int = 20
@export var move_speed: float = 70.0
@export var attack_damage: int = 5
@export var attack_range: float = 20.0
@export var attack_cooldown: float = 1.0
@export var detection_radius: float = 160.0

@export var body_scale: Vector2 = Vector2.ONE
@export var animation_speed_scale: float = 1.0

@export var primary_tint: Color = Color.WHITE
@export var secondary_tint: Color = Color.WHITE
@export var glow_color: Color = Color.TRANSPARENT

@export var overlay_set: Array[String] = []
@export var behavior_id: String = "skirmisher"

@export var threat_level: int = 1
@export var seed: int = 0
```

---

# 9. Enemy Variant Factory

Create:

```text
custodian/game/enemies/procgen/enemy_variant_factory.gd
```

This is the core procedural generation system.

## Public API

```gdscript
func generate_variant(seed: int, biome_id: String, threat_level: int) -> EnemyVariantProfile:
    pass
```

## Inputs

```text
seed
biome_id
threat_level
optional faction_id
optional room_depth
optional alert_level
```

## Output

An `EnemyVariantProfile`.

---

# 10. Variant Families

Codex should implement enemy families as weighted presets.

Example:

```gdscript
const FAMILY_TABLE := {
    "beast_crawler": {
        "weight": 50,
        "base_health": [12, 24],
        "base_speed": [65.0, 95.0],
        "base_damage": [3, 7],
        "behaviors": ["swarm", "skirmisher"],
        "scale": [Vector2(0.9, 0.9), Vector2(1.1, 1.1)]
    },
    "beast_stalker": {
        "weight": 25,
        "base_health": [20, 38],
        "base_speed": [45.0, 70.0],
        "base_damage": [6, 12],
        "behaviors": ["ambusher", "circle_player"],
        "scale": [Vector2(1.0, 1.0), Vector2(1.25, 1.25)]
    },
    "beast_leaper": {
        "weight": 15,
        "base_health": [16, 28],
        "base_speed": [80.0, 120.0],
        "base_damage": [8, 15],
        "behaviors": ["leaper"],
        "scale": [Vector2(0.95, 0.95), Vector2(1.15, 1.15)]
    },
    "beast_mutant": {
        "weight": 10,
        "base_health": [35, 70],
        "base_speed": [35.0, 60.0],
        "base_damage": [12, 22],
        "behaviors": ["bruiser", "charge"],
        "scale": [Vector2(1.2, 1.2), Vector2(1.6, 1.6)]
    }
}
```

---

# 11. Visual Mutation System

Create:

```text
custodian/game/enemies/procgen/enemy_visual_mutator.gd
```

## Supported Mutations

Codex should support these first:

```text
palette tint
glow tint
slight scale variation
animation speed variation
overlay sprites
horizontal flip
minor vertical squash/stretch
```

Avoid destructive pixel mutation at runtime for now. Keep runtime fast.

## Good Variant Types

For this sheet, generate variants like:

```text
Ash Crawler
Rustback Crawler
Pale Slinker
Blue-Grey Stalker
Irradiated Leaper
Spine-Torn Mutant
Void-Flecked Scavenger
```

## Palette Logic

Use subtle colors. Do not make neon enemies unless they are special variants.

Recommended tint ranges:

```text
normal:
  blue-grey
  ash-grey
  cold slate
  desaturated teal

elite:
  darker body
  faint cyan/magenta wound glow
  sharper contrast

corrupted:
  pale body
  purple/blue wound glow
  slightly higher brightness on eyes/spines
```

---

# 12. Shader-Based Tinting

Use a `ShaderMaterial` on `BodySprite`.

Create shader:

```text
custodian/game/enemies/procgen/enemy_palette_tint.gdshader
```

Shader behavior:

```text
- preserve alpha
- tint only visible pixels
- multiply base color by primary_tint
- optionally add glow_color to bright pixels
- avoid tinting transparent background
```

Shader:

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

    vec3 tinted = tex.rgb * primary_tint.rgb;

    float brightness = max(max(tex.r, tex.g), tex.b);
    vec3 glow = glow_tint.rgb * brightness * glow_strength;

    tinted = mix(vec3(0.5), tinted, contrast_boost);

    COLOR = vec4(tinted + glow, tex.a);
}
```

---

# 13. Overlay System

Overlays should be separate transparent PNGs aligned to the same normalized canvas size as the body frames.

Examples:

```text
content/sprites/enemies/beast_pack/overlays/glow_eye_01.png
content/sprites/enemies/beast_pack/overlays/spine_mutation_01.png
content/sprites/enemies/beast_pack/overlays/claw_overlay_01.png
content/sprites/enemies/beast_pack/overlays/wound_glow_01.png
```

Overlay rules:

```text
normal enemies: 0 overlays
veteran enemies: 0-1 overlays
elite enemies: 1-2 overlays
mutant enemies: 1-3 overlays
```

The overlay sprite should use the same animation names as the body where possible.

Fallback behavior:

```text
if overlay animation is missing:
    hide OverlaySprite
```

---

# 14. Behavior Generation

The procedural generation should affect both visuals and gameplay.

Behavior IDs:

```text
swarm
skirmisher
ambusher
circle_player
leaper
bruiser
charge
flee_then_return
```

## Behavior Mapping

```text
small crawler:
  swarm
  skirmisher

longer stalking creature:
  ambusher
  circle_player

upright/leaping creature:
  leaper
  charge

large mutated creature:
  bruiser
  charge
```

Codex should create behavior selection based on family.

Example:

```gdscript
func _pick_behavior(rng: RandomNumberGenerator, family_id: String) -> String:
    match family_id:
        "beast_crawler":
            return _weighted_pick(rng, {"swarm": 70, "skirmisher": 30})
        "beast_stalker":
            return _weighted_pick(rng, {"ambusher": 50, "circle_player": 50})
        "beast_leaper":
            return _weighted_pick(rng, {"leaper": 80, "charge": 20})
        "beast_mutant":
            return _weighted_pick(rng, {"bruiser": 60, "charge": 40})
    return "skirmisher"
```

---

# 15. Stat Generation

Stats should be deterministic from seed.

Formula:

```text
base range from family
modified by threat_level
modified by elite/mutation roll
```

Example:

```gdscript
health = base_health * threat_multiplier * elite_multiplier
damage = base_damage * threat_multiplier * elite_multiplier
speed = base_speed * speed_variation
```

Threat multipliers:

```text
threat 1: 1.00
threat 2: 1.20
threat 3: 1.45
threat 4: 1.75
threat 5: 2.10
```

Elite roll:

```text
normal: 80%
veteran: 15%
elite: 4%
mutant: 1%
```

Later rooms can increase elite chance.

---

# 16. Enemy Naming

Generate names based on family + modifier.

Example name tables:

```gdscript
const PREFIXES := [
    "Ash",
    "Pale",
    "Rustback",
    "Cold",
    "Gutter",
    "Void-Flecked",
    "Spine-Torn",
    "Sump",
    "Hollow"
]

const NOUNS := {
    "beast_crawler": ["Crawler", "Scavenger", "Gnawer"],
    "beast_stalker": ["Stalker", "Slinker", "Lurker"],
    "beast_leaper": ["Leaper", "Pouncer", "Skitter"],
    "beast_mutant": ["Mutant", "Brute", "Ravager"]
}
```

Output examples:

```text
Ash Crawler
Pale Slinker
Rustback Gnawer
Void-Flecked Ravager
```

---

# 17. Spawner Integration

Create or update:

```text
custodian/game/enemies/procgen/procedural_enemy_spawner.gd
```

Public method:

```gdscript
func spawn_enemy(position: Vector2, seed: int, biome_id: String, threat_level: int) -> ProceduralEnemy:
    pass
```

Spawner flow:

```text
1. generate EnemyVariantProfile
2. instantiate procedural_enemy.tscn
3. call apply_variant(profile)
4. set global_position
5. add to world
```

Example:

```gdscript
func spawn_enemy(position: Vector2, seed: int, biome_id: String, threat_level: int) -> Node2D:
    var profile := EnemyVariantFactory.generate_variant(seed, biome_id, threat_level)
    var enemy := procedural_enemy_scene.instantiate()
    enemy.global_position = position
    enemy.apply_variant(profile)
    get_tree().current_scene.add_child(enemy)
    return enemy
```

---

# 18. Runtime Seed Rules

Use deterministic seeds so procgen maps always spawn the same enemies.

Seed formula:

```gdscript
var enemy_seed := hash("%s:%s:%s:%s" % [
    world_seed,
    room_id,
    spawn_index,
    biome_id
])
```

This makes the same room produce the same enemy variants unless the world seed changes.

---

# 19. Collision Rules

Because visual variants can scale, collision should not scale wildly.

Use family-based collision shapes:

```text
crawler: capsule/small circle, radius 10-12
stalker: capsule, radius 12-14
leaper: capsule, radius 10-13
mutant: larger capsule/circle, radius 16-20
```

Do **not** derive collision directly from sprite bounds. That will make animation frames feel unfair.

---

# 20. Animation State Names

Codex should standardize animation names:

```text
idle_east
move_east
attack_east
hurt_east
death_east
```

Optional later:

```text
idle_north
idle_south
move_north
move_south
attack_north
attack_south
```

For now, if the sheet mostly contains side-view/right-facing frames, support:

```text
east-facing frames
west-facing via horizontal flip
```

That is enough for early gameplay.

---

# 21. Procedural Enemy Config File

Create:

```text
custodian/content/sprites/enemies/beast_pack/beast_pack_config.json
```

Example:

```json
{
  "family_id": "beast_pack",
  "base_canvas_size": [48, 48],
  "default_origin": [24, 32],
  "families": {
    "beast_crawler": {
      "animations": ["idle_east", "move_east", "attack_east", "death_east"],
      "collision_radius": 11
    },
    "beast_stalker": {
      "animations": ["idle_east", "move_east", "attack_east", "death_east"],
      "collision_radius": 13
    },
    "beast_leaper": {
      "animations": ["idle_east", "move_east", "attack_east", "death_east"],
      "collision_radius": 12
    },
    "beast_mutant": {
      "animations": ["idle_east", "move_east", "attack_east", "death_east"],
      "collision_radius": 18
    }
  }
}
```

---

# 22. Editor Debug Panel

Add a simple test scene:

```text
custodian/game/enemies/procgen/test_enemy_variant_lab.tscn
custodian/game/enemies/procgen/test_enemy_variant_lab.gd
```

The test scene should:

```text
- generate 20 enemies with different seeds
- display them in a grid
- show their generated names
- show family_id and behavior_id
- allow reroll with key R
- allow threat_level increase/decrease
```

This is important because procedural enemies need visual QA.

---

# 23. Minimum Viable Implementation

Codex should implement in this order:

## Phase 1 — Extraction

```text
1. Create extract_alpha_frames.gd
2. Export raw frames from transparent spritesheet
3. Create frame_metadata.json
```

## Phase 2 — Manual Animation Map

```text
1. Generate first-pass animation_map.json
2. Let user manually assign frames into idle/move/attack/death groups
3. Normalize frames to 48x48
```

## Phase 3 — Runtime Enemy

```text
1. Create EnemyVariantProfile
2. Create EnemyVariantFactory
3. Create ProceduralEnemy scene/script
4. Load SpriteFrames from extracted animations
```

## Phase 4 — Visual Variants

```text
1. Add shader tinting
2. Add body scale variation
3. Add animation speed variation
4. Add overlay support
```

## Phase 5 — Spawner

```text
1. Add procedural_enemy_spawner.gd
2. Hook it into procgen room spawn points
3. Use deterministic world/room/spawn seeds
```

---

# 24. Important Constraint

Do **not** bake hundreds of variants manually at first.

Use this model:

```text
one clean extracted animation library
+
runtime profile generation
+
shader/overlay mutation
+
seeded stats and behavior
```

That gives you many enemy variants from one spritesheet without bloating the project.

---

# 25. Codex Prompt You Can Paste

```text
Implement a procedural enemy generation pipeline for the Godot project.

Use the transparent spritesheet at:
res://content/sprites/enemies/beast_pack/source/beast_sheet.png

Create tools and runtime scripts to extract alpha-based sprite frames, classify them into animation groups, normalize frames to 48x48 canvases, and generate procedural enemy variants from them.

Required files:
- res://tools/sprite_extraction/extract_alpha_frames.gd
- res://tools/sprite_extraction/classify_enemy_frames.gd
- res://tools/sprite_extraction/bake_enemy_variants.gd
- res://game/enemies/procgen/enemy_variant_profile.gd
- res://game/enemies/procgen/enemy_variant_factory.gd
- res://game/enemies/procgen/enemy_visual_mutator.gd
- res://game/enemies/procgen/enemy_animation_library.gd
- res://game/enemies/base/procedural_enemy.gd
- res://game/enemies/base/procedural_enemy.tscn
- res://game/enemies/procgen/procedural_enemy_spawner.gd
- res://game/enemies/procgen/test_enemy_variant_lab.tscn
- res://game/enemies/procgen/enemy_palette_tint.gdshader

The extractor should scan the source PNG using alpha > 8, detect connected components, ignore tiny blobs, pad each sprite by 4 pixels, export raw frames, and write frame_metadata.json.

The classifier should generate a first-pass animation_map.json based on row grouping and x order, but allow manual edits.

The baker should normalize selected animation frames to 48x48 transparent canvases with the visual origin around x=24, y=32.

The runtime system should generate deterministic EnemyVariantProfile resources from seed, biome_id, and threat_level. Variants should include family_id, display_name, stats, behavior_id, body_scale, animation_speed_scale, primary_tint, glow_color, and overlay_set.

Support enemy families:
- beast_crawler
- beast_stalker
- beast_leaper
- beast_mutant

Support behavior IDs:
- swarm
- skirmisher
- ambusher
- circle_player
- leaper
- bruiser
- charge

The ProceduralEnemy scene should use CharacterBody2D with AnimatedSprite2D body, optional overlay sprite, collision shape, hurtbox, hitbox, and NavigationAgent2D. It should expose apply_variant(profile: EnemyVariantProfile).

Add a test lab scene that generates 20 enemies in a grid with different seeds and displays their names, family_id, behavior_id, and threat level.

Do not assume the source sheet uses a perfect grid. Use alpha-based connected-component frame detection.
Do not mutate the source sheet destructively.
Do not use background-color detection because the sheet background is transparent.
```

---

 + NOTE: The following section is mainly a restatement of the above, with less focus on the alpha aware enemy sprite detector.

---

The new pipeline should be:

```text
wolf-idle.png  + wolf-idle.json
wolf-run.png   + wolf-run.json
wolf-bite.png  + wolf-bite.json
wolf-death.png + wolf-death.json
wolf-howl.png  + wolf-howl.json
wolf-all.png   + wolf-all.json optional/reference
```

Use the JSON as the source of truth, then bake everything into a **single consistent Godot-ready animation library**.

---

# CUSTODIAN Wolf Enemy Procedural Variant Implementation Spec

## 1. Core Problem

The animation sheets are already normalized, but their square sizes vary slightly by animation.

Example:

```text
wolf-idle.png  frames might be 48x48
wolf-run.png   frames might be 56x56
wolf-bite.png  frames might be 64x64
wolf-death.png frames might be 72x72
```

This is fine for Aseprite, but in Godot it can cause the wolf to visually “jump” when switching animations.

The fix is to bake all wolf frames into one shared canvas size.

Recommended:

```text
canonical wolf frame canvas: 96x96
visual ground anchor: x = 48, y = 68
```

Use `96x96` unless your largest wolf frame is bigger than about `88x88`. If any animation exceeds that, use `128x128`.

---

# 2. Recommended Asset Layout

Use this structure:

```text
custodian/
  content/
    sprites/
      enemies/
        wolf/
          source/
            wolf-all.png
            wolf-all.json
            wolf-idle.png
            wolf-idle.json
            wolf-run.png
            wolf-run.json
            wolf-bite.png
            wolf-bite.json
            wolf-death.png
            wolf-death.json
            wolf-howl.png
            wolf-howl.json

          normalized/
            wolf_idle_000.png
            wolf_idle_001.png
            wolf_run_000.png
            wolf_run_001.png
            wolf_bite_000.png
            wolf_death_000.png
            wolf_howl_000.png

          generated/
            wolf_spriteframes.tres
            wolf_animation_manifest.json

          overlays/
            eyes_glow_01.png
            bite_slash_01.png
            corruption_spine_01.png
            frost_breath_01.png

  game/
    enemies/
      wolf/
        wolf_enemy.tscn
        wolf_enemy.gd

      procgen/
        enemy_variant_profile.gd
        enemy_variant_factory.gd
        wolf_animation_baker.gd
        wolf_animation_library.gd
        enemy_visual_mutator.gd
        enemy_palette_tint.gdshader
        procedural_enemy_spawner.gd
        test_enemy_variant_lab.tscn
        test_enemy_variant_lab.gd
```

---

# 3. Aseprite Export Format

For each animation, generate JSON like this:

```bash
aseprite -b wolf-idle.aseprite \
  --sheet wolf-idle.png \
  --data wolf-idle.json \
  --format json-array \
  --list-tags \
  --list-slices
```

Do the same for:

```text
wolf-run
wolf-bite
wolf-death
wolf-howl
wolf-all
```

If you are exporting from the Aseprite GUI, make sure JSON includes:

```text
frame rectangles
frame durations
frame tags if available
source size
sprite source size
```

Do **not** rely on Godot’s `.import` files for animation data. They are not your source of truth.

---

# 4. Animation Config File

Create:

```text
res://content/sprites/enemies/wolf/source/wolf_animation_config.json
```

Use this to map each file to a Godot animation name.

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
    "run_east": {
      "image": "res://content/sprites/enemies/wolf/source/wolf-run.png",
      "json": "res://content/sprites/enemies/wolf/source/wolf-run.json",
      "loop": true,
      "fallback_fps": 12
    },
    "bite_east": {
      "image": "res://content/sprites/enemies/wolf/source/wolf-bite.png",
      "json": "res://content/sprites/enemies/wolf/source/wolf-bite.json",
      "loop": false,
      "fallback_fps": 12
    },
    "death_east": {
      "image": "res://content/sprites/enemies/wolf/source/wolf-death.png",
      "json": "res://content/sprites/enemies/wolf/source/wolf-death.json",
      "loop": false,
      "fallback_fps": 8
    },
    "howl_east": {
      "image": "res://content/sprites/enemies/wolf/source/wolf-howl.png",
      "json": "res://content/sprites/enemies/wolf/source/wolf-howl.json",
      "loop": false,
      "fallback_fps": 8
    }
  }
}
```

For now, only use east-facing animation. Use `flip_h = true` for west-facing.

---

# 5. Baking Rule

The baker should:

1. Read each PNG and matching Aseprite JSON.
2. Extract each frame rectangle from the source sheet.
3. Create a new transparent `96x96` image.
4. Paste the source frame into the shared canvas.
5. Align every frame using the same ground anchor.
6. Export normalized PNGs.
7. Generate `wolf_animation_manifest.json`.
8. Optionally generate `wolf_spriteframes.tres`.

The important part is this:

```text
Every wolf animation frame must become 96x96, even if the source animation used a smaller square.
```

This prevents animation switching from shifting the sprite.

---

# 6. Ground Anchor Logic

Use a consistent visual foot/body anchor instead of simple center alignment.

Recommended wolf anchor:

```text
canvas size: 96x96
anchor x: 48
anchor y: 68
```

For each source frame:

```text
target_x = anchor_x - source_frame_width / 2
target_y = anchor_y - source_frame_height + bottom_padding
```

Use:

```text
bottom_padding = 6
```

So the wolf’s feet/body bottom stays stable across idle, run, bite, howl, and death.

This is better than centering because attack and death frames often extend outward and would otherwise shift the creature’s apparent position.

---

# 7. Generated Manifest

The baker should output:

```text
res://content/sprites/enemies/wolf/generated/wolf_animation_manifest.json
```

Example:

```json
{
  "enemy_id": "wolf",
  "canvas": [96, 96],
  "ground_anchor": [48, 68],
  "animations": {
    "idle_east": {
      "loop": true,
      "frames": [
        {
          "path": "res://content/sprites/enemies/wolf/normalized/wolf_idle_000.png",
          "duration_ms": 100
        },
        {
          "path": "res://content/sprites/enemies/wolf/normalized/wolf_idle_001.png",
          "duration_ms": 100
        }
      ]
    },
    "run_east": {
      "loop": true,
      "frames": []
    },
    "bite_east": {
      "loop": false,
      "frames": []
    },
    "death_east": {
      "loop": false,
      "frames": []
    },
    "howl_east": {
      "loop": false,
      "frames": []
    }
  }
}
```

---

# 8. Godot SpriteFrames Builder

Create:

```text
res://game/enemies/procgen/wolf_animation_library.gd
```

Responsibilities:

```text
load wolf_animation_manifest.json
build SpriteFrames
set animation loop mode
set animation speed
add each normalized frame
return SpriteFrames resource
```

Public API:

```gdscript
func get_wolf_sprite_frames() -> SpriteFrames:
    pass
```

Animation names:

```text
idle_east
run_east
bite_east
death_east
howl_east
```

Runtime direction handling:

```text
east = flip_h false
west = flip_h true
north/south = use east animation temporarily until proper directional sheets exist
```

---

# 9. Wolf Enemy Scene

Create:

```text
res://game/enemies/wolf/wolf_enemy.tscn
res://game/enemies/wolf/wolf_enemy.gd
```

Scene tree:

```text
WolfEnemy CharacterBody2D
  VisualRoot Node2D
    BodySprite AnimatedSprite2D
    OverlaySprite AnimatedSprite2D
    GlowSprite AnimatedSprite2D
  CollisionShape2D
  Hurtbox Area2D
    CollisionShape2D
  Hitbox Area2D
    CollisionShape2D
  NavigationAgent2D
```

Collision should **not** use sprite bounds.

Use something like:

```text
normal wolf collision radius: 12 to 16
large wolf collision radius: 18 to 22
```

The visual sprite can be 96x96, but the physical body should stay gameplay-readable.

---

# 10. Wolf Enemy Script Behavior

`wolf_enemy.gd` should expose:

```gdscript
func apply_variant(profile: EnemyVariantProfile) -> void:
    pass
```

It should apply:

```text
sprite frames
body tint
glow tint
scale
animation speed
stats
behavior profile
collision size
```

Expected animation state mapping:

```text
idle  -> idle_east
move  -> run_east
attack -> bite_east
special -> howl_east
death -> death_east
```

---

# 11. Enemy Variant Profile

Create or reuse:

```text
res://game/enemies/procgen/enemy_variant_profile.gd
```

```gdscript
extends Resource
class_name EnemyVariantProfile

@export var variant_id: String = ""
@export var archetype_id: String = "wolf"
@export var display_name: String = "Wolf"

@export var max_health: int = 30
@export var move_speed: float = 90.0
@export var attack_damage: int = 8
@export var attack_range: float = 24.0
@export var attack_cooldown: float = 0.8
@export var detection_radius: float = 180.0

@export var body_scale: Vector2 = Vector2.ONE
@export var animation_speed_scale: float = 1.0

@export var primary_tint: Color = Color.WHITE
@export var glow_color: Color = Color.TRANSPARENT
@export var glow_strength: float = 0.0

@export var overlay_set: Array[String] = []
@export var behavior_id: String = "pack_hunter"

@export var elite_tier: String = "normal"
@export var threat_level: int = 1
@export var seed: int = 0
```

---

# 12. Procedural Wolf Families

Use the wolf as an enemy archetype, then generate variants.

Families:

```text
wolf_scavenger
wolf_stalker
wolf_alpha
wolf_corrupted
wolf_ancient
```

Example family table:

```gdscript
const WOLF_FAMILY_TABLE := {
    "wolf_scavenger": {
        "weight": 45,
        "health": [18, 32],
        "speed": [85.0, 115.0],
        "damage": [5, 9],
        "scale": [Vector2(0.85, 0.85), Vector2(1.0, 1.0)],
        "behaviors": {
            "skirmisher": 50,
            "pack_hunter": 50
        }
    },
    "wolf_stalker": {
        "weight": 30,
        "health": [28, 46],
        "speed": [70.0, 95.0],
        "damage": [8, 14],
        "scale": [Vector2(1.0, 1.0), Vector2(1.15, 1.15)],
        "behaviors": {
            "ambusher": 60,
            "circle_player": 40
        }
    },
    "wolf_alpha": {
        "weight": 12,
        "health": [50, 80],
        "speed": [80.0, 105.0],
        "damage": [14, 22],
        "scale": [Vector2(1.15, 1.15), Vector2(1.35, 1.35)],
        "behaviors": {
            "pack_leader": 70,
            "charge": 30
        }
    },
    "wolf_corrupted": {
        "weight": 10,
        "health": [36, 70],
        "speed": [75.0, 120.0],
        "damage": [12, 20],
        "scale": [Vector2(1.0, 1.0), Vector2(1.25, 1.25)],
        "behaviors": {
            "frenzy": 60,
            "ambusher": 40
        }
    },
    "wolf_ancient": {
        "weight": 3,
        "health": [90, 140],
        "speed": [55.0, 80.0],
        "damage": [20, 32],
        "scale": [Vector2(1.35, 1.35), Vector2(1.6, 1.6)],
        "behaviors": {
            "bruiser": 50,
            "howl_summoner": 50
        }
    }
}
```

---

# 13. Procedural Visual Variants

Do **not** bake 200 wolf spritesheets manually.

Use:

```text
same normalized animation frames
+
shader tint
+
scale change
+
speed change
+
optional overlay
+
stat/behavior variation
```

Variant examples:

```text
Ash Scavenger
Pale Stalker
Rustback Wolf
Hollow Alpha
Frostbitten Wolf
Void-Flecked Wolf
Ancient Packlord
```

Palette families:

```text
normal:
  blue-grey
  ash grey
  slate
  cold dark teal

elite:
  darker body
  brighter eyes
  increased contrast

corrupted:
  pale body
  purple/cyan wound glow
  possible spine overlay

ancient:
  desaturated bone-grey
  dim blue glow
  slower animation
  larger scale
```

---

# 14. Shader

Create:

```text
res://game/enemies/procgen/enemy_palette_tint.gdshader
```

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

---

# 15. Bite Timing / Hitbox Timing

The bite animation should not deal damage during the whole animation.

Add attack timing metadata:

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

If you prefer duration-based:

```json
{
  "attack_windows": {
    "bite_east": {
      "active_start_ms": 120,
      "active_end_ms": 260
    }
  }
}
```

For Godot, frame-based is probably simpler.

Runtime behavior:

```text
bite starts
hitbox disabled during startup
hitbox enabled only during active frames
hitbox disabled during recovery
return to idle/run
```

---

# 16. Howl Behavior

Use `wolf-howl.png` as a special state.

Possible howl effects:

```text
alert nearby wolves
buff pack movement speed
summon small scavenger wolves
fear/stagger player briefly
mark player location
```

Minimum first implementation:

```text
howl makes nearby wolves aggro the player
```

Howl behavior:

```gdscript
func perform_howl() -> void:
    play_animation("howl_east")
    emit_signal("howled", global_position, howl_radius)
```

Nearby wolves listen and enter combat state.

---

# 17. Behavior IDs

Supported wolf behaviors:

```text
pack_hunter
skirmisher
ambusher
circle_player
charge
frenzy
pack_leader
bruiser
howl_summoner
```

First pass implementation should only fully support:

```text
pack_hunter
skirmisher
ambusher
charge
```

Stub the rest cleanly.

---

# 18. Deterministic Variant Factory

Create:

```text
res://game/enemies/procgen/enemy_variant_factory.gd
```

Public method:

```gdscript
func generate_wolf_variant(seed: int, biome_id: String, threat_level: int) -> EnemyVariantProfile:
    pass
```

Generation flow:

```text
1. seed RNG
2. pick wolf family by weighted table
3. roll elite tier
4. roll stats inside family ranges
5. apply threat multiplier
6. choose behavior
7. choose tint
8. choose glow/overlay if elite/corrupted
9. choose display name
10. return EnemyVariantProfile
```

Threat multiplier:

```gdscript
const THREAT_MULTIPLIERS := {
    1: 1.00,
    2: 1.20,
    3: 1.45,
    4: 1.75,
    5: 2.10
}
```

Elite tiers:

```text
normal: 78%
veteran: 16%
elite: 5%
mutant/ancient: 1%
```

---

# 19. Direction Handling

Until you have directional wolf sheets:

```text
east movement: flip_h = false
west movement: flip_h = true
north/south movement: use run_east with flip based on x velocity
```

Do not block implementation waiting on directional animations.

Later you can add:

```text
idle_north
idle_south
run_north
run_south
bite_north
bite_south
```

But this current sheet is enough for early enemy implementation.

---

# 20. Integration With Procgen Spawns

Create:

```text
res://game/enemies/procgen/procedural_enemy_spawner.gd
```

Public method:

```gdscript
func spawn_wolf(position: Vector2, seed: int, biome_id: String, threat_level: int) -> Node2D:
    var profile := EnemyVariantFactory.generate_wolf_variant(seed, biome_id, threat_level)
    var enemy := wolf_enemy_scene.instantiate()
    enemy.global_position = position
    enemy.apply_variant(profile)
    get_tree().current_scene.add_child(enemy)
    return enemy
```

Seed formula:

```gdscript
var enemy_seed := hash("%s:%s:%s:%s" % [
    world_seed,
    room_id,
    spawn_index,
    "wolf"
])
```

That makes the same map seed produce the same wolf variants.

---

# 21. Test Lab Scene

Create:

```text
res://game/enemies/procgen/test_enemy_variant_lab.tscn
```

Purpose:

```text
preview procedural wolf variants before putting them into real rooms
```

The scene should:

```text
generate 20 wolves in a grid
show display_name
show family/archetype
show behavior_id
show threat_level
press R to reroll
press 1-5 to change threat level
press H to force howl animation
press B to force bite animation
press D to force death animation
```

This is critical. Procedural enemy systems need quick visual QA.

---

# 22. Minimum Viable Implementation Order

## Phase 1 — Aseprite JSON pipeline

```text
1. Put wolf PNGs and JSON files under content/sprites/enemies/wolf/source/
2. Create wolf_animation_config.json
3. Create wolf_animation_baker.gd
4. Bake all animations into 96x96 normalized frames
5. Generate wolf_animation_manifest.json
```

## Phase 2 — SpriteFrames loading

```text
1. Create wolf_animation_library.gd
2. Load normalized frames
3. Build SpriteFrames
4. Verify idle/run/bite/death/howl play correctly
```

## Phase 3 — Basic enemy

```text
1. Create wolf_enemy.tscn
2. Add AnimatedSprite2D
3. Add collision/hurtbox/hitbox
4. Implement idle/run/bite/death state transitions
```

## Phase 4 — Procedural variants

```text
1. Create EnemyVariantProfile
2. Create EnemyVariantFactory
3. Generate stats, names, scale, tint, behavior
4. Apply variants to wolf_enemy
```

## Phase 5 — Spawning

```text
1. Create procedural_enemy_spawner.gd
2. Spawn seeded wolf variants from procgen rooms
3. Keep collision independent from sprite size
```

---

# 23. Codex Prompt

Paste this to Codex:

```text
Implement a Godot 4 procedural wolf enemy pipeline using existing Aseprite-exported wolf animation sheets.

Existing files:
res://content/sprites/enemies/wolf/source/wolf-all.png
res://content/sprites/enemies/wolf/source/wolf-idle.png
res://content/sprites/enemies/wolf/source/wolf-run.png
res://content/sprites/enemies/wolf/source/wolf-bite.png
res://content/sprites/enemies/wolf/source/wolf-death.png
res://content/sprites/enemies/wolf/source/wolf-howl.png

Matching Aseprite JSON files will exist beside each PNG:
wolf-all.json
wolf-idle.json
wolf-run.json
wolf-bite.json
wolf-death.json
wolf-howl.json

Do not use alpha connected-component detection. These are already normalized animation sheets. Use the Aseprite JSON as the source of truth for frame rectangles and frame durations.

Create:
- res://content/sprites/enemies/wolf/source/wolf_animation_config.json
- res://game/enemies/procgen/wolf_animation_baker.gd
- res://game/enemies/procgen/wolf_animation_library.gd
- res://game/enemies/procgen/enemy_variant_profile.gd
- res://game/enemies/procgen/enemy_variant_factory.gd
- res://game/enemies/procgen/enemy_visual_mutator.gd
- res://game/enemies/procgen/enemy_palette_tint.gdshader
- res://game/enemies/wolf/wolf_enemy.tscn
- res://game/enemies/wolf/wolf_enemy.gd
- res://game/enemies/procgen/procedural_enemy_spawner.gd
- res://game/enemies/procgen/test_enemy_variant_lab.tscn
- res://game/enemies/procgen/test_enemy_variant_lab.gd

The animation config should map:
wolf-idle.png/json  -> idle_east
wolf-run.png/json   -> run_east
wolf-bite.png/json  -> bite_east
wolf-death.png/json -> death_east
wolf-howl.png/json  -> howl_east

Because source animation sheets have normalized square frames but slightly different square sizes per animation, bake all frames into a shared 96x96 transparent canvas. Use a consistent ground anchor of x=48, y=68. This prevents the wolf from visually shifting when switching animations.

The baker should:
1. read wolf_animation_config.json
2. parse each Aseprite JSON file
3. extract frame rectangles from each PNG
4. paste each frame into a 96x96 transparent canvas using the shared ground anchor
5. save normalized frames to:
   res://content/sprites/enemies/wolf/normalized/
6. write:
   res://content/sprites/enemies/wolf/generated/wolf_animation_manifest.json

The animation library should:
1. read wolf_animation_manifest.json
2. build a SpriteFrames resource
3. preserve animation loop settings
4. approximate animation FPS from frame duration data
5. expose get_wolf_sprite_frames() -> SpriteFrames

The wolf enemy scene should be CharacterBody2D with:
- VisualRoot Node2D
- BodySprite AnimatedSprite2D
- OverlaySprite AnimatedSprite2D
- GlowSprite AnimatedSprite2D
- CollisionShape2D
- Hurtbox Area2D
- Hitbox Area2D
- NavigationAgent2D

The wolf script should expose:
apply_variant(profile: EnemyVariantProfile) -> void

It should support these animation states:
idle -> idle_east
move -> run_east
attack -> bite_east
death -> death_east
special/howl -> howl_east

Use east-facing animations by default and flip_h=true for west movement. For north/south movement, temporarily use the east animation and choose flip_h based on x velocity.

Implement EnemyVariantProfile as a Resource with:
variant_id
archetype_id
display_name
max_health
move_speed
attack_damage
attack_range
attack_cooldown
detection_radius
body_scale
animation_speed_scale
primary_tint
glow_color
glow_strength
overlay_set
behavior_id
elite_tier
threat_level
seed

Implement EnemyVariantFactory.generate_wolf_variant(seed, biome_id, threat_level). It should produce deterministic variants using RandomNumberGenerator seeded with the given seed.

Support wolf variant families:
- wolf_scavenger
- wolf_stalker
- wolf_alpha
- wolf_corrupted
- wolf_ancient

Support behavior IDs:
- pack_hunter
- skirmisher
- ambusher
- circle_player
- charge
- frenzy
- pack_leader
- bruiser
- howl_summoner

Only fully implement pack_hunter, skirmisher, ambusher, and charge initially. Stub the others safely.

Add shader-based tinting using enemy_palette_tint.gdshader. Preserve alpha. Do not tint transparent pixels.

Add a test lab scene that spawns 20 procedural wolf variants in a grid. It should display each wolf's generated name, behavior_id, elite_tier, and threat_level. Add input actions or simple key handling:
R = reroll
1-5 = set threat level
B = force bite animation
H = force howl animation
D = force death animation

Do not modify source PNGs.
Do not rely on .import files for animation metadata.
Do not derive collision from sprite bounds.
Use stable family-based collision sizes instead.
```

---

 - Note: As this file is getting rather long, please review the document ENEMY_VARIANT_FACTORY.md for detailed and extensive notes on the procedural enemy variant factory.

Please consolidate the contents of this sheet to avoid duplication and write it to a development file for active tracking and context. Do the same for the VARIANT_FACTORY.md file.
