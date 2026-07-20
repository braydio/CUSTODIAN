# CRITICAL-OPEN OPTIONAL VFX

Status: implemented optional polish  
Owner: gameplay/combat feel  
Runtime owner: `custodian/game/actors/enemies/enemy.gd`  
Depends on: `PARRY_CRITICAL_BRANCHING_AND_VFX.md` (live)

## Purpose

Two one-shot VFX bookend the critical-open opportunity window:

```text
posture_break_flash  →  BREACH marker + countdown ring  →  critical attack OR critical_window_expire
```

Both are optional at runtime through `grunt_optional_critical_vfx_enabled`, but their scene/resource dependencies are preloaded and therefore fail loudly when the production contract is incomplete. The former PNG-existence warning stubs have been replaced with real playback scenes.

Implementation note (2026-07-19): both strips are now bound through required preloaded one-shot scenes. The posture-break source sheet contains seven authored 128×128 cells, including its final sparse-fragment decay cell; the live resource therefore uses all seven frames at 24 FPS.

## Replaced Stub State

The following describes the warning-only implementation that this completed slice replaced.

`enemy.gd` lines 18–19 define string paths:

```gdscript
const OPTIONAL_POSTURE_BREAK_FLASH_PATH := "res://content/sprites/effects/combat/critical/posture_break_flash_01.png"
const OPTIONAL_CRITICAL_WINDOW_EXPIRE_PATH := "res://content/sprites/effects/combat/critical/critical_window_expire_01.png"
```

`_warn_for_missing_optional_critical_vfx()` (line 3742) checks `ResourceLoader.exists()` on both paths.  
`_clear_grunt_critical_open_vfx(expired)` (line 3731) prints a warning when the expire asset exists but has no runtime contract.

The two constant paths, the two static warning flags, and the existence-check logic should be replaced by `preload()` scene constants and direct instantiation, matching how `CRITICAL_BREACH_MARKER_VFX_SCENE` and `CRITICAL_WINDOW_RING_VFX_SCENE` are already wired.

---

## Asset 1: Posture-Break Flash

### Purpose

Enemy-centered burst at the instant a successful parry breaks posture and opens the critical window. It is **not** another weapon-contact spark — the parry already has its own. This is broader, heavier, and communicates: "The enemy's combat structure just failed."

### Visual language

Compressed white-hot burst around the enemy's upper torso, surrounded by angular pale-gold fracture lines, a brief vertical pressure flare, brass/ivory shards breaking outward, a faint circular shock boundary, and rapid decay into sparse embers.

Avoid: star-shaped hit sparks, red blood effects, screen-filling flashes, lingering auras, BREACH text overlays.

### Production spec

| Property     | Value                                                                                   |
| ------------ | --------------------------------------------------------------------------------------- |
| Runtime path | `custodian/content/sprites/effects/combat/critical/posture_break_flash_01.png`          |
| Source path  | `custodian/content/sprites/effects/combat/critical/source/posture_break_flash_01.aseprite` |
| Frame size   | 128×128                                                                                 |
| Frame count  | 7                                                                                       |
| Sheet layout | 896×128 horizontal                                                                      |
| Playback     | 24 FPS                                                                                  |
| Duration     | 0.29s                                                                                   |
| Loop         | No                                                                                      |
| Blend        | Additive or screen-like additive                                                        |
| Draw order   | Above enemy body, above ordinary attack FX                                              |

### Frame breakdown

| Frame | Visual                                                           |
| ----: | ---------------------------------------------------------------- |
|     1 | Tiny white compression point at the enemy's torso                |
|     2 | Broad white/ivory posture-break flash                            |
|     3 | Brightest frame; angular gold cracks and vertical pressure flare |
|     4 | Fracture lines widen; metal-like shards kick outward             |
|     5 | Core extinguishes; broken streaks and embers remain              |
|     6 | Two or three fading fragments only                               |
|     7 | Final sparse fragment decay into transparency                    |

Brightest read within the first three frames.

---

## Asset 2: Critical-Window Expiry

### Purpose

Plays when the player does not consume the critical opportunity before its timer expires. Communicates: "The opening has closed." It should not feel like a hit, stun, or reward — it is a loss-of-opportunity effect.

### Visual language

The critical ring rapidly contracts and destabilizes: pale-gold directional marks pull inward, the center briefly forms a dim closing aperture, outer segments fracture or extinguish, a desaturated gray-blue afterimage collapses into the enemy, and the final frame leaves no persistent glow. The visual language is the inverse of the opening — opening is expansion/fracture/confirmation; expiry is contraction/dimming/closure.

### Production spec

| Property     | Value                                                                                      |
| ------------ | ------------------------------------------------------------------------------------------ |
| Runtime path | `custodian/content/sprites/effects/combat/critical/critical_window_expire_01.png`          |
| Source path  | `custodian/content/sprites/effects/combat/critical/source/critical_window_expire_01.aseprite` |
| Frame size   | 128×128                                                                                    |
| Frame count  | 8                                                                                          |
| Sheet layout | 1024×128 horizontal                                                                        |
| Playback     | 20 FPS                                                                                     |
| Duration     | 0.40s                                                                                      |
| Loop         | No                                                                                         |
| Blend        | Additive initially, fading to normal alpha                                                  |
| Draw order   | Around enemy or above body, matching countdown ring depth                                   |

### Frame breakdown

| Frame | Visual                                              |
| ----: | --------------------------------------------------- |
|     1 | Existing circular opportunity shape flickers        |
|     2 | Outer directional ticks bend inward                 |
|     3 | Ring develops several broken gaps                   |
|     4 | Ring rapidly contracts around the enemy             |
|     5 | Small pale-gold closing aperture                    |
|     6 | Aperture collapses into a narrow vertical glint     |
|     7 | Cold gray-blue afterimage and two falling fragments |
|     8 | Complete disappearance                              |

Should read clearly without looking punitive.

---

## Runtime Files To Create

### SpriteFrames resources

Follow the existing atlas-texture pattern from `critical_breach_marker_01.tres` and `critical_window_ring_01.tres`.

**`custodian/content/spriteframes/effects/combat/posture_break_flash_01.tres`**

- `SpriteFrames` resource with one animation named `&"flash"`
- 7 `AtlasTexture` sub-resources slicing `res://content/sprites/effects/combat/critical/posture_break_flash_01.png` at 128×128 intervals: `Rect2(0, 0, 128, 128)` through `Rect2(768, 0, 128, 128)`
- `"loop": 0`, `"speed": 24.0`

**`custodian/content/spriteframes/effects/combat/critical_window_expire_01.tres`**

- `SpriteFrames` resource with one animation named `&"expire"`
- 8 `AtlasTexture` sub-resources slicing `res://content/sprites/effects/combat/critical/critical_window_expire_01.png` at 128×128 intervals: `Rect2(0, 0, 128, 128)` through `Rect2(896, 0, 128, 128)`
- `"loop": 0`, `"speed": 20.0`

### VFX scripts

Follow the existing pattern from `parry_success_burst_vfx.gd` and `parry_contact_spark_vfx.gd`: extend `Node2D`, play the animation in `_ready()`, connect `animation_finished` to `queue_free`.

**`custodian/game/vfx/combat/posture_break_flash_vfx.gd`**

```gdscript
class_name PostureBreakFlashVfx
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
    z_as_relative = false
    z_index = 31
    animated_sprite.play(&"flash")
    animated_sprite.animation_finished.connect(queue_free)
```

**`custodian/game/vfx/combat/critical_window_expire_vfx.gd`**

```gdscript
class_name CriticalWindowExpireVfx
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
    z_as_relative = false
    z_index = 31
    animated_sprite.play(&"expire")
    animated_sprite.animation_finished.connect(queue_free)
```

### VFX scenes

Follow the existing two-load-step pattern from `critical_breach_marker_vfx.tscn`.

**`custodian/game/vfx/combat/posture_break_flash_vfx.tscn`**

```tscn
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://game/vfx/combat/posture_break_flash_vfx.gd" id="1_script"]
[ext_resource type="SpriteFrames" path="res://content/spriteframes/effects/combat/posture_break_flash_01.tres" id="2_frames"]

[node name="PostureBreakFlashVfx" type="Node2D"]
script = ExtResource("1_script")

[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
sprite_frames = ExtResource("2_frames")
animation = &"flash"
modulate = Color(1, 0.85, 0.55, 0.95)
```

The modulate tint gives a warm brass/ivory cast without requiring a shader. Adjust after art review.

**`custodian/game/vfx/combat/critical_window_expire_vfx.tscn`**

```tscn
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://game/vfx/combat/critical_window_expire_vfx.gd" id="1_script"]
[ext_resource type="SpriteFrames" path="res://content/spriteframes/effects/combat/critical_window_expire_01.tres" id="2_frames"]

[node name="CriticalWindowExpireVfx" type="Node2D"]
script = ExtResource("1_script")

[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
sprite_frames = ExtResource("2_frames")
animation = &"expire"
```

---

## Changes To `enemy.gd`

### Replace constants (lines 16–22)

Remove:

```gdscript
const OPTIONAL_POSTURE_BREAK_FLASH_PATH := "res://content/sprites/effects/combat/critical/posture_break_flash_01.png"
const OPTIONAL_CRITICAL_WINDOW_EXPIRE_PATH := "res://content/sprites/effects/combat/critical/critical_window_expire_01.png"

static var _optional_posture_break_warning_emitted := false
static var _optional_expire_warning_emitted := false
```

Add:

```gdscript
const POSTURE_BREAK_FLASH_VFX_SCENE := preload("res://game/vfx/combat/posture_break_flash_vfx.tscn")
const CRITICAL_WINDOW_EXPIRE_VFX_SCENE := preload("res://game/vfx/combat/critical_window_expire_vfx.tscn")
```

### Spawn posture-break flash in `_spawn_grunt_critical_open_vfx()` (line 3708)

After the breach marker instantiation block (after the `_critical_window_ring_vfx.configure_duration` call), add:

```gdscript
if grunt_optional_critical_vfx_enabled:
    var posture_flash := POSTURE_BREAK_FLASH_VFX_SCENE.instantiate() as Node2D
    if posture_flash != null:
        posture_flash.position = grunt_critical_breach_marker_offset
        add_child(posture_flash)
```

The posture flash anchors at the same offset as the breach marker (enemy upper torso, default `Vector2(0.0, -62.0)`). It is a one-shot — `queue_free` on animation finish, no reference stored.

### Spawn expiry in `_clear_grunt_critical_open_vfx(expired)` (line 3731)

Replace the existing expiry block:

```gdscript
if expired and grunt_optional_critical_vfx_enabled and ResourceLoader.exists(OPTIONAL_CRITICAL_WINDOW_EXPIRE_PATH):
    push_warning("[CombatVfx] Optional critical-window expiry asset exists but has no runtime strip contract yet: %s" % OPTIONAL_CRITICAL_WINDOW_EXPIRE_PATH)
```

With:

```gdscript
if expired and grunt_optional_critical_vfx_enabled:
    var expire_effect := CRITICAL_WINDOW_EXPIRE_VFX_SCENE.instantiate() as Node2D
    if expire_effect != null:
        expire_effect.position = grunt_critical_window_ring_offset
        add_child(expire_effect)
```

The expire effect anchors at the countdown ring offset (enemy root, default `Vector2.ZERO`). Also a one-shot with no stored reference.

### Simplify `_warn_for_missing_optional_critical_vfx()` (line 3742)

Remove the entire function body. The `preload()` calls will fail loudly at scene load time if the `.tscn` files are missing, which is the correct behavior for required runtime scenes. The PNG existence checks are no longer needed.

Remove the two static warning flags (`_optional_posture_break_warning_emitted`, `_optional_expire_warning_emitted`) since they supported the now-deleted existence-check logic.

The `grunt_optional_critical_vfx_enabled` export remains — it gates both spawn calls above and is still useful as a debug/comparison toggle.

---

## Documentation Updates

### `design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md`

Add to the asset contract table:

| Runtime animation | Asset | Cells / strip | FPS | Loop |
|---|---|---|---:|---:|
| `posture_break_flash` | `custodian/content/sprites/effects/combat/critical/posture_break_flash_01.png` | 7 × 128×128 / 896×128 | 24 | no |
| `critical_window_expire` | `custodian/content/sprites/effects/combat/critical/critical_window_expire_01.png` | 8 × 128×128 / 1024×128 | 20 | no |

Add to the existing BREACH/countdown paragraph:

> Optional posture-break flash spawns at the enemy breach-marker offset when critical-open begins. Optional critical-window expiry spawns at the countdown-ring offset when the opportunity expires unconsumed. Both are one-shot `queue_free`-on-finish scenes gated by `grunt_optional_critical_vfx_enabled`.

### `REQUIRED_ASSETS.md`

The runtime PNGs are supplied and therefore are not listed as outstanding work in the canonical tracker. Their two missing editable `.aseprite` source files remain tracked as `needed`:

```text
custodian/content/sprites/effects/combat/critical/source/posture_break_flash_01.aseprite
custodian/content/sprites/effects/combat/critical/source/critical_window_expire_01.aseprite
```

---

## Acceptance

1. Both `.tscn` scenes load without errors in the Godot editor.
2. `grunt_parry_crit_reaction_smoke.gd` passes without regression.
3. Spawning a `critical_enter` preset grunt through DevConsole shows the posture-break flash at breach-marker offset.
4. Letting a `critical_hold` preset grunt's timer expire shows the expiry ring at countdown-ring offset.
5. Setting `grunt_optional_critical_vfx_enabled = false` suppresses both effects.
6. Removing either `.tscn` file produces a preload error at load time (not a silent runtime skip).

### Validation

```bash
cd custodian
godot --headless --path . --import --quit
godot --headless --path . --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
godot --headless --path . --script res://tools/validation/debug_grunt_spawn_modes_smoke.gd
```
