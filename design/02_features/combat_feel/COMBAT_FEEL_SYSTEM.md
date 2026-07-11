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
- `melee.secondary` chord (`Shift+primary`) -> `melee_heavy`
- `unarmed.primary` -> `unarmed_fast`
- `unarmed.secondary` chord (`Shift+primary`) -> `unarmed_heavy`

Offhand secondary (`attack_secondary` / `aim_hold`, right mouse or Xbox LT) is context-sensitive, not profile-relative:

- selected ranged primary -> hold offhand secondary for primary ranged-ready, primary fires
- melee/unarmed plus equipped P-9 sidearm -> hold offhand secondary for sidearm-ready, primary fires the P-9
- melee/unarmed with empty offhand or guard-focused offhand item -> hold offhand secondary for guard, primary while held parries

The `block` InputMap action may exist as a compatibility/manual action, but the official player-facing defensive control
is offhand secondary by slot context. Do not route P-9 sidearm and parry onto the same held state.

Ranged secondary is a mode/intent hold, not the default fire button. While it is held, the operator should face
aim direction, show the ranged weapon layer, and keep movement available; primary confirms the shot through the
existing ranged fire path. Lower-body locomotion remains movement-owned so modular upper-body, weapon, cape, and FX
clips can act independently from idle/walk/run.

Upper-body facing is state-owned rather than cursor-owned by default. During ordinary idle/walk/run, upper and lower
body face the locomotion direction together. Ranged-ready, including the sidearm fallback, grants aim direction to
the upper-body/weapon/FX presentation, and directional actions may claim their authored action direction without
changing lower-body locomotion ownership.

The current two-handed ranged-ready presentation is compositional, not a baked locomotion requirement. Lower body
remains movement-owned and reuses the existing modular `unarmed_idle`, `unarmed_walk`, and `unarmed_run` clips across
loadouts; upper body and weapon stance are loadout-owned and follow aim direction. For example, moving north while
aiming east plays lower-body north locomotion with east-facing ranged upper/weapon stance. Legacy full-body ranged
sprites only render when the modular ranged upper/weapon stack is unavailable, so modular lower legs are never shown
on top of a full-body fallback. Primary ranged fire may layer modular upper/weapon/FX action clips over the continuing
lower-body locomotion when those clips exist; reload and missing action coverage retain legacy fallback presentation.

Offhand sidearm:

- The Operator owns a separate `sidearm_weapon_definition` inventory slot.
- The sidearm slot starts empty. Holding offhand secondary while melee/unarmed is selected routes to parry/guard until the recovered P-9 Field Sidearm is explicitly equipped from the status/inventory Equipment page.
- Looting the Sundered Keep Great Hall field-retention locker adds `p9_sidearm` to carried `InventoryManager` equipment. Equipping it fills the sidearm slot and calls `Operator.grant_sidearm(...)`; unequipping clears the slot, calls `remove_sidearm()`, and restores parry/guard.
- If the currently selected/equipped weapon is ranged, held ranged-ready uses it.
- If the selected weapon is melee/unarmed and the sidearm slot is equipped, held offhand secondary uses the default `sidearm_pistol` profile from `pistol_mk1.json`, even when a carbine is carried in another loadout slot.
- Sidearm-ready is visually exclusive from primary-ranged ready: the carried carbine/primary weapon overlay and its FX are hidden while the baked modular sidearm action stack is active.
- Modular sidearm draw/fire lower-body, upper-body, weapon, and FX layers are live for NE/NW/SE/SW. Draw must complete before a shot can begin, the complete draw pose holds on its final frame while ranged-ready remains held, and each completed fire action returns to that held pose. Pure cardinal aim selects the nearest authored diagonal; legacy ranged placeholders remain the fallback for missing reload/recovery coverage.

Parry / guard:

- Empty offhand and `offhand_guard_item_equipped` both route offhand secondary to the defense path.
- Holding offhand secondary starts guard immediately; the guard becomes fully active after a short guard-ready delay.
- Pressing primary while offhand secondary is held starts parry windup, then opens a short active parry window.
- Releasing offhand secondary exits guard. If failed-parry recovery finishes while secondary is still held, the operator re-enters guard through `block_enter`; if secondary was released, the operator returns to normal stance. No parry path may snap directly into `block_hold`.
- Failed parry is not a separate miss animation or VFX branch. When the active parry window expires without success, the Operator lets the original `parry_01` attempt finish, then returns to neutral or re-enters guard through `block_enter` if offhand secondary is still held.
- A front-facing perfect parry cancels the incoming enemy hit, calls `apply_parry_stagger(...)` on the attacker when available, refunds stamina, opens the enemy-owned vulnerable/critical-open window where supported, and requires block release/repress before guard can be raised again.
- Attack input after a successful parry resolves contextually: the Operator first looks for an enemy that validates `can_receive_parry_critical_from(self)`. Only then may it start the explicit critical branch; otherwise it falls back to the normal melee/unarmed attack path.
- The previously misnamed 8-frame `operator__body__unarmed__parry_miss_01__{e,w}__8f__96.png` sheets are currently runtime-mapped as `operator_critical_1h_right/left` for the fast parry-critical attack. They are not parry miss assets.
- Enemies own critical validation and consumption through `receive_parry_critical(...)`. Arbitrary `take_damage()` is normal damage and must not be the only critical-consumption path.
- For `enemy_grunt`, parry critical-open and critical-hit presentation is exclusive: opening the window cancels any queued standard `flinch_fx_s`, and consuming the window plays `crit_s` plus `crit_fx_s` without the normal white body hit flash. Standard flinch/body-flash presentation remains available for non-critical damage.
- Successful parry now adds a world-space contact spark plus an independently owned one-shot success burst at the captured impact point and attaches a floating BREACH marker plus duration-driven countdown reticle to a critical-open grunt. Gameplay timing remains `_parry_critical_window_timer` in `enemy.gd`; VFX only visualize it and are removed on consumption or expiry. Required runtime strips are `content/sprites/effects/combat/critical/combat_fx__parry_success_hit_spark_01__6f__128.png`, `combat_fx__breach_alert__8f__96-48.png`, and `combat_fx__breach_timer_reticle__12f__128.png`. Optional posture-break/expiry strips remain non-blocking and warn once when absent.
- Guard uses the existing block state presentation, drains stamina per hit, and reduces incoming damage to chip damage instead of fully negating it.
- Enemy damage application must check parry first, guard second, then damage. Presentation fallbacks are allowed when parry animations are missing, but simulation authority stays in `operator.gd` and `enemy.gd`.
- Detailed parry/critical branching authority lives in `design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md`.

### Runtime control contract

Current V1 bindings:

- move: `WASD` / Xbox left stick
- aim/look: mouse world cursor / Xbox right stick
- offhand secondary: right mouse / Xbox LT; contextually primary ranged-ready, P-9 sidearm-ready, or parry/guard
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

Unarmed heavy remains available through the secondary chord (`Shift+primary`). Offhand secondary owns guard-ready when
the sidearm slot is empty or defensive, and primary pressed while guard-ready triggers parry. A bare Fists build has
defensive skill expression without overloading the held sidearm-ready state.

Unarmed block presentation uses the modular lower/upper body stack: authored entry, looping hold, and blocked-hit
reaction clips play through the existing block state path, and exit reuses entry in reverse. Parry gameplay now uses
the same state path for timing, plays the generated modular `parry_01` lower/upper/FX stack when available, and falls
back to block animations when `unarmed_parry*` clips are missing. The curated `parry_01` playback is intentionally
registered at 12 FPS for a slightly heavier read. Successful parries spawn an independent world-space success burst
at the captured contact point. It currently reuses the validated six-frame contact strip through a dedicated one-shot
scene, so post-parry body/neutral transitions cannot hide it. `PLACEHOLDER_unarmed_parry_success_fx*` remains an
optional modular motion overlay; missing directional coverage warns and falls back without owning success readability.

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

## Next Agent Slice

Goal: broaden authored parry directional coverage and tune the feel in live combat while preserving exclusive grunt critical presentation.

Files:

- `custodian/game/actors/operator/operator.gd`
- `custodian/game/actors/enemies/enemy.gd`
- `custodian/tools/validation/operator_ranged_ready_input_smoke.gd`
- `custodian/tools/validation/operator_modular_layers_smoke.gd`
- `custodian/tools/validation/grunt_parry_crit_reaction_smoke.gd`
- `custodian/game/vfx/combat/`
- `custodian/content/spriteframes/effects/combat/`
- `REQUIRED_ASSETS.md`
- `custodian/content/sprites/operator/new_operator/modular/`

Constraints:

- Keep offhand secondary unambiguous: ranged primary, P-9 sidearm, or parry/guard by slot context.
- Keep parry/guard simulation in operator/enemy gameplay code; animation and FX remain presentation only.
- Do not layer normal grunt flinch FX or white body hit flash over `crit_s` / `crit_fx_s`.
- Do not put parry on the P-9 sidearm branch until sidearm/defense tradeoffs are deliberately redesigned.

Acceptance checks:

- `cd custodian && godot --headless --script tools/validation/operator_ranged_ready_input_smoke.gd`
- `cd custodian && godot --headless --script tools/validation/operator_modular_layers_smoke.gd`
- `cd custodian && godot --headless --script tools/validation/grunt_parry_crit_reaction_smoke.gd`
- `cd custodian && godot --headless --quit`
- In play, empty offhand hold guards, empty offhand hold plus primary parries, P-9 equipped hold readies sidearm, P-9 held plus primary fires sidearm, and selected ranged primary hold readies the primary ranged weapon.
