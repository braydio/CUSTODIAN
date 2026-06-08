# COMBAT_FEEL_SYSTEM

Status: in progress
Owner: gameplay/combat
Runtime target: Godot 4 (`custodian/`)

## Purpose

Define a production-ready mapping from combat design to concrete Godot implementation and required animation assets for CUSTODIAN's top-down operator combat.

## 0. Core Animation Architecture

### Node setup

```
Custodian (CharacterBody2D)
├─ AnimationPlayer
├─ AnimatedSprite2D
├─ HitboxRoot
├─ Hurtbox
├─ CameraShake
```

### State groups

- movement
- combat
- reaction

### Canonical animation names

- `idle`
- `walk`
- `sprint`
- `attack_fast`
- `attack_heavy`
- `attack_dash`
- `equip_weapon`
- `hit_recoil`
- `stagger`
- `death`

### Event marker phases

Example for `attack_fast`:

- start
- windup
- active (damage frame)
- recovery

## 1. Attack Timing Polish

### Design

Use input buffering and cancel windows:

- `input_buffer_time = 0.15s`
- queue attack input during recovery
- execute when cancel window opens

### Godot implementation

Primary script: `custodian/entities/operator/operator.gd`

Implemented in first slice:

- buffered melee input variables:
  - `melee_input_buffer_time`
  - `_buffered_attack_kind`
  - `_buffered_attack_timer`
- cancel window exports:
  - `melee_fast_cancel_start`
  - `melee_heavy_cancel_start`
- buffered request flow:
  - `_try_melee_attack()` starts immediately if available, otherwise buffers input
  - `_update_melee_attack()` consumes buffered input once cancel window is reached

Current chain model:

- `fast -> fast/heavy` (buffered)
- `heavy -> fast/heavy` (buffered)

### Animation requirements

#### Fast attack

4 frames minimum:

1. windup
2. strike (active)
3. follow-through
4. recovery

Required events:

- `damage_start`
- `damage_end`
- `cancel_start`

Current runtime hookup:

- `operator_runtime_frames.tres` fast melee attack uses `res://assets/sprites/operator/runtime/body/melee_fast/melee_fast_baked_operator_only.png`
- fast attack weapon overlay uses `res://assets/sprites/operator/runtime/body/melee_fast/melee_fast_baked_katana.png`
- fast attack FX overlay uses `res://assets/sprites/operator/runtime/body/melee_fast/melee_fast_baked_katana_effects.png`
- melee idle stance now uses the authored body clip `res://assets/sprites/operator/runtime/body/melee_2h/operator_body_melee_2h_stance.png`
- socketed `fallen_star_katana` remains active for non-authored melee movement/fallback poses
- fast melee hit confirm / impact spark timing is frame 5 of the authored strip (1-based)

#### Heavy attack

4 frames minimum:

1. big windup
2. overhead strike
3. impact
4. long recovery

Required events:

- `damage_start`
- `damage_end`
- `cancel_start`

### Profile intent taxonomy

Attack input is profile-relative, not state-relative:

- `ranged.secondary` held -> `ranged_ready`
- `ranged.primary` while `ranged_ready` -> `ranged_fire`
- `ranged.secondary` tap -> reserved for later quick-raise or snapshot behavior; no shot in V1
- `melee.primary` -> `melee_fast`
- `melee.secondary` -> `melee_heavy`
- `unarmed.primary` -> `unarmed_fast`
- `unarmed.secondary` -> `unarmed_heavy`

Ranged secondary is a mode/intent hold, not the default fire button. While it is held, the operator should face
aim direction, show the ranged weapon layer, and keep movement available; primary confirms the shot through the
existing ranged fire path. Lower-body locomotion remains movement-owned so modular upper-body, weapon, cape, and FX
clips can act independently from idle/walk/run.

Upper-body facing is state-owned rather than cursor-owned by default. During ordinary idle/walk/run, upper and lower
body face the locomotion direction together. Ranged-ready, including the sidearm fallback, grants aim direction to
the upper-body/weapon/FX presentation, and directional actions may claim their authored action direction without
changing lower-body locomotion ownership.

The current two-handed ranged-ready idle presentation uses the supplied modular lower-body, upper-body, and weapon
stance layers for east, north, and west. South and diagonals resolve to the nearest available authored stance.
Movement, fire, recover, and reload continue through their established legacy body/overlay paths until matching
modular action layers are supplied.

Sidearm fallback:

- The Operator owns a separate `sidearm_weapon_definition` inventory slot.
- The sidearm slot starts locked. Holding ranged-ready while melee/unarmed is selected does nothing until the P-9 Field Sidearm is recovered from the Sundered Keep Great Hall field-retention locker.
- Looting the locker calls `Operator.grant_sidearm(...)`, equips the sidearm fallback slot, and initializes its loaded/reserve ammunition without changing the current melee/unarmed selection.
- If the currently selected/equipped weapon is ranged, held ranged-ready uses it.
- If the selected weapon is melee/unarmed and the sidearm slot is equipped, held ranged-ready uses the default `sidearm_pistol` profile from `pistol_mk1.json`, even when a carbine is carried in another loadout slot.
- Sidearm-ready is visually exclusive from primary-ranged ready: the carried carbine/primary weapon overlay and its FX are hidden while the baked modular sidearm action stack is active.
- Modular sidearm draw/fire lower-body, upper-body, weapon, and FX layers are live for NE/NW/SE/SW. Draw must complete before a shot can begin, the complete draw pose holds on its final frame while ranged-ready remains held, and each completed fire action returns to that held pose. Pure cardinal aim selects the nearest authored diagonal; legacy ranged placeholders remain the fallback for missing reload/recovery coverage.

### Runtime control contract

Current V1 bindings:

- move: `WASD` / Xbox left stick
- aim/look: mouse world cursor / Xbox right stick
- hold ranged-ready: right mouse / Xbox LT
- primary fire or melee confirm: left mouse / Xbox RT
- dodge/backstep: `Space` / Xbox B
- interact: `E` / Xbox A
- inventory: `Tab` or `I` / Xbox Y
- reload: `R` / Xbox X
- quick item: `Q` / D-pad up
- cycle item left/right: `Z` / `C` / D-pad left/right
- pause: `Esc` / Start/Menu
- map/objectives: `M` / View/Back

Facing priority is:

1. aim direction while ranged-ready/aim is active or the right stick is expressing aim
2. movement direction while not aiming
3. last facing direction while idle

Dodge direction is movement-first. If movement input is active, dodge follows movement even while aiming. If idle
and aiming, dodge resolves opposite aim direction as a short combat backstep. If idle and not aiming, dodge follows
the current facing direction. The live presentation now prefers the authored north/south 9-frame full dodge body and
FX sequences and lets each sequence continue through the existing deterministic impulse/recovery timers without
restarting the visual at the recovery boundary. Upward movement selects north; horizontal/downward movement selects
south, with horizontal mirroring for left. Runtime V1 retains split `operator_dodge_step` /
`operator_dodge_recovery` and optional aim-backstep tracks as compatibility fallbacks until the full directional suite
is supplied.

Unarmed/Fists is a selectable weapon profile. It must not create separate unarmed combat states; `unarmed_fast`
and `unarmed_heavy` reuse the shared `attack_fast` and `attack_heavy` states while resolving profile-specific
animations, hit windows, FX, and stat multipliers through `unarmed_definition.tres`.

Unarmed heavy is the first fists secondary baseline. It should read as a committed short-range strike with better
control/repositioning than weapons but lower reach, damage, and stagger. Parry/counter is deferred to the block
state path and should not be overloaded onto unarmed secondary.

Asset rule: unarmed body motion and unarmed FX should be separate runtime layers. If an existing clean body strip
matches the needed motion, reuse it for body frames and put fist impact/trail pixels in an unarmed FX overlay.

## 2. Hit Confirmation

### Design

On successful hit:

- hit-stop
- camera shake
- hit spark

### Godot implementation target

- Hit-stop utility on combat manager or operator:
  - temporary `Engine.time_scale` reduction
- camera impulse:
  - `camera.shake(intensity)`
- spawn impact effect scene on confirmed hit

### Godot implementation status (implemented)

Primary scripts:

- `custodian/entities/operator/operator.gd`
- `custodian/scenes/camera.gd`

Runtime behavior implemented:

- on confirmed melee hit, operator triggers:
  - brief hit-stop (`Engine.time_scale` lowered, then restored)
  - camera shake impulse via `Camera2D.shake(power)`
  - melee impact spark spawn at hit position
- runtime spark scenes:
  - `res://entities/effects/impact_spark.tscn` uses `hit_spark_4f_64.png` (4/4 frames)
  - `res://entities/effects/block_spark.tscn` uses `block_spark_4f_128.png` (2/4 frames)
- blocked projectile outcomes:
  - `bullet.gd` first checks `receive_projectile_hit(amount, team)` when available
  - if the result dictionary has `blocked = true`, spawn `block_spark`
  - otherwise spawn normal `impact_spark`
  - fallback path still uses `take_damage(amount)` for entities without the new method

### Animation requirements

- `hit_spark` (3 frames)
- `block_spark` (2 frames)
- optional `swing_trail` (2 frames)

## 3. Animation-Driven Melee Hitboxes

### Design

Damage activation is event-driven, not timer-only.

### Godot implementation target

AnimationPlayer call-method tracks:

- `enable_hitbox()`
- `disable_hitbox()`

Node path:

- `$HitboxRoot/WeaponHitbox`

### Animation requirements

Attack frame arc example:

- frame 1: windup
- frame 2: active
- frame 3: active
- frame 4: recovery

Events should align with frame 2 start and frame 3 end.

### Godot implementation status (implemented slice)

Primary runtime files:

- `custodian/entities/operator/operator.tscn`
- `custodian/entities/operator/operator.gd`

Implemented behavior:

- Operator scene now includes:
  - `HitboxRoot` (`Node2D`)
  - `HitboxRoot/WeaponHitbox` (`Area2D`)
  - `HitboxRoot/WeaponHitbox/CollisionShape2D` (`CircleShape2D`)
- `operator.gd` now drives melee damage through hitbox activation windows:
  - `enable_hitbox()` / `disable_hitbox()` are real methods
  - hitbox window is synced from attack animation frames
  - only overlapping enemies in active arc/range receive damage
  - per-swing target dedupe prevents repeated damage spam on one frame window

## 4. Enemy Reaction Layer

### Required enemy reactions

- `drone_hit`
- `drone_stagger`
- `drone_attack_windup`

### Frame requirements

- `drone_hit`: 2 frames
- `drone_stagger`: 3 frames
- `drone_attack_windup`: 2 frames

### Godot implementation status (implemented with fallback)

Primary runtime file:

- `custodian/entities/enemies/enemy.gd`

Implemented behavior:

- attack windup phase before damage application:
  - `attack_windup_duration` (current default `0.10s`)
  - queued damage executes when windup ends
- damage reactions:
  - `hit_recoil_duration` for lighter hits
  - `stagger_duration` for hits above `stagger_damage_threshold`
  - stagger cancels queued windup attack
- animation playback rules:
  - uses `drone_attack_windup`, `drone_hit`, `drone_stagger` when present
  - falls back to existing `drone_firing` / `drone_missiles` / idle behavior if missing
  - runtime clip registration in `enemy.gd` loads:
    - `res://assets/sprites/enemies/drone/runtime/idle/drone_idle.png` (128x128 strip)
    - `res://assets/sprites/enemies/drone/runtime/attack/drone_firing.png` (128x128 strip)
    - `res://assets/sprites/enemies/drone/runtime/reaction/drone_hit.png` (2f)
    - `res://assets/sprites/enemies/drone/runtime/reaction/drone_stagger.png` (4f current)
    - `res://assets/sprites/enemies/drone/runtime/attack/drone_attack_windup.png` (2f)
  - idle/firing clips are replaced at runtime so new strips are guaranteed to be used over legacy `enemy.tres` entries
  - firing animation restart is forced on repeat shots for snappier transitions

## 5. Combat Movement Feel

No new logic animation dependency except sprint readability.

### Sprint animation

- 4 frames
- faster playback than walk

### Godot implementation status (implemented slice)

Primary runtime file:

- `custodian/entities/operator/operator.gd`

Implemented behavior:

- velocity now uses acceleration/deceleration smoothing:
  - `move_acceleration`
  - `move_deceleration`
- movement facing transitions are smoothed:
  - `movement_turn_response`
- sprint/combat coupling:
  - heavy attacks can be gated while sprinting (`heavy_attack_blocked_while_sprinting`)
  - heavy attacks consume stamina (`heavy_attack_stamina_cost`)

## 6. Targeting Readability

UI/VFX targets:

- target ring
- threat highlight
- projectile tracer

Animation requirements:

- `target_highlight` (3-frame loop)
- `projectile_impact` (3 frames)

## 7. Encounter Pacing

No animation dependency required for logic.

Enemy classes should visually differentiate:

- light drone
- heavy drone
- ranged drone

Each needs:

- idle
- move
- attack
- hit
- death

## 8. Audio Layer

Animation/event-driven SFX triggers:

- `attack_fast -> swing_fast`
- `attack_heavy -> swing_heavy`
- `hit -> impact`

## First Playable Combat Slice Asset Checklist

### Player

- `idle` (4)
- `walk` (4)
- `sprint` (4)
- `attack_fast` (4)
- `attack_heavy` (4)
- `hit_recoil` (2)
- `death` (4)

### Enemy drone

- `idle` (4)
- `move` (4)
- `attack_windup` (2)
- `attack_fire` (2)
- `hit` (2)
- `stagger` (3)
- `death` (4)

### Effects

- `hit_spark` (3)
- `block_spark` (2)
- `projectile_impact` (3)
- `target_highlight` (3)
- `swing_trail` (2 optional)

Approximate total: ~60 frames.

## Implementation Notes

- Left-facing variants should use flipped right-facing animations unless explicitly overridden.
- For any missing animation, request user-provided asset implementation and specify save location in `custodian/assets/sprites/...` with a short artistic direction note.
