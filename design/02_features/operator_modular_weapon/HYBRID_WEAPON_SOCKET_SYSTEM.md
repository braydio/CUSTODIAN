# Hybrid Weapon Socket System

**Roadmap:** Operator Presentation
**Status:** phase-1 implementation
**Owner:** gameplay/combat + art pipeline
**Runtime target:** Godot 4.x (`custodian/`)
**Last updated:** 2026-07-16

## Purpose

Replace the baked weapon-animation-strip approach (where every weapon × direction ×
action produces a multi-frame strip) with a hybrid authored-body + socketed-weapon
system. The operator body drives arm/hand position through authored animation, and the
weapon sprite is positioned at a per-frame socket with small procedural correction.

This gives scalability (one weapon sprite per direction, not per action) while keeping
anatomically readable silhouettes.

## Design Principles

1. **Body drives the pose.** Upper body animation determines shoulder lean, elbow
   bend, hand placement, torso angle, and recoil response.
2. **Weapon is socketed, not baked.** A directional weapon sprite sits at a
   per-frame grip socket and rotates only within a limited sector correction.
3. **Frame-aware offsets.** Socket positions are authored per frame (or per
   directional state), not a single static offset for the whole animation.
4. **Eight-direction quantization.** The weapon sprite has8 directional variants.
   Fine cursor angle is handled by ±5–12° procedural rotation within each sector.
5. **Runtime muzzle/eject.** Projectile origin and shell ejection are computed
   from authored socket nodes, not baked into strips.
6. **Authored recoil.** The body animation plays the large readable recoil. The
   weapon gets a small procedural kickback.

## Current State vs Target

### What exists now (baked strips)

```text
operator__modular_upper_body__ranged_2h__stance_01__e__5f__96.png
operator__modular_ranged_weapon__ranged_2h__stance_01__e__5f__96.png
```

The weapon strip is a5-frame animation of the weapon in the "stance" pose.
A matching upper body strip shows the arms in the same pose. They are synced
via `_sync_ranged_slave_frame_to_upper()`.

Per-action weapon strips: `stance`, `aim`, `fire`, `relaxed` × 8 directions.

### What the target system needs

```text
# Upper body: authored body-only animations (arms without weapon baked in)
operator__modular_upper_body__ranged_2h__stance_01__e__5f__96.png   (keep)
operator__modular_upper_body__ranged_2h__aim_01__e__5f__96.png     (keep)
operator__modular_upper_body__ranged_2h__fire_01__e__6f__96.png    (keep)
operator__modular_upper_body__ranged_2h__relaxed_01__e__5f__96.png (keep)

# Weapon: ONE static sprite per direction (not per action)
operator__modular_weapon__ranged_2h__e__96.png    (static, directional)
operator__modular_weapon__ranged_2h__se__96.png
operator__modular_weapon__ranged_2h__s__96.png
... (8 directions total)
```

The weapon sprite is positioned at the grip socket (frame-aware offset from
the upper body animation) and receives a small procedural rotation based on
the cursor angle error within the selected sector.

## Architecture

### Runtime authority contract

The upper-body animation is the presentation clock. One canonical eight-way aim
sector selects the upper body, weapon presentation, socket record, draw order,
and projectile baseline. The weapon and upper FX may copy that clock, but may
not resolve direction independently.

Socket metadata is keyed by the live upper-body animation name and frame. Each
record contains operator-local `grip`, `support_grip`, `muzzle`, and `ejection`
points plus `weapon_angle_deg` and `weapon_z`. Runtime layout assignments are
absolute. Recoil is an additive, short-lived presentation offset applied after
the authored record; it never mutates the stored record.

When production socket metadata is enabled for a weapon, projectile origin,
muzzle flash, casing origin, and debug ray all consume the same resolved socket
snapshot. A missing animation/frame record is an error and must not fall back to
a generic forward-distance muzzle.

### Carbine MK1 phase-1 vertical slice

Production-required sectors are `e`, `w`, `se`, and `sw`. Their live resolver
suffixes are `right`, `left`, `down_right`, and `down_left`. The covered upper
animations are the current modular `stance`, `aim`, and `fire` clips; reverse
aim playback owns lower presentation until separately authored lower sheets are
available, and fire recovery consumes the remaining frames of the fire clip.

The generated source of truth is
`custodian/content/data/operator/generated/operator_weapon_sockets.generated.json`,
loaded by `operator_weapon_socket_library.gd`. The existing 96x96 modular weapon
strips remain compatibility presentation art for this vertical slice. Their
clock is slaved to the upper body, while placement, muzzle/ejection locations,
and draw order come from socket metadata. Static per-sector texture export is an
art follow-up that does not change the socket contract.

Aim transition timing is asymmetric: `ranged_raise_duration = 0.22`,
`ranged_lower_duration = 0.12`, and `ranged_aim_ready_ratio = 0.70`. Fine-angle
correction stays disabled for the phase-1 Carbine art until socket/contact review
passes. Camera aim feedback is owned by `custodian/game/world/camera.gd`; the
Operator only publishes active state and current aim direction.

### Scene node hierarchy (target)

```text
Operator
├── Visual
│   ├── AnimatedSprite2D              (locomotion base / fallback)
│   └── ModularCapeSprite             (cape layer)
├── ModularLowerBodySprite            (legs / locomotion)
├── ModularUpperBodySprite            (torso + arms)
├── ModularUpperFxSprite              (upper body FX)
├── WeaponRoot                        (NEW - replaces PrimaryWeaponSocket)
│   ├── WeaponSprite                  (Sprite2D, not AnimatedSprite2D)
│   ├── MuzzleSocket                  (Marker2D)
│   ├── EjectSocket                   (Marker2D)
│   └── MagazineSocket                (Marker2D, optional)
├── MeleeWeaponOverlaySprite          (melee FX overlay)
├── MeleeFxOverlaySprite              (melee FX layer)
└── HealthBar
```

### Key change: AnimatedSprite2D → Sprite2D

The current `ModularSidearmSprite` is an `AnimatedSprite2D` that plays baked
weapon animation strips. In the target system, the weapon is a `Sprite2D`
(or a lightweight `AnimatedSprite2D` with a single-frame animation per
direction) that is positioned and rotated per frame.

### Per-frame socket metadata

For each upper body animation frame, the system needs:

```gdscript
# Stored as a Resource or Dictionary keyed by animation_name + frame_index
{
    "weapon_position": Vector2(11, -8),      # local to operator root
    "weapon_rotation_degrees": -4.0,         # authored base rotation
    "muzzle_position": Vector2(32, -10),     # local to weapon root
    "draw_order": 1,                         # z_index relative to body
}
```

This can live in:
- A Godot `Resource` (`WeaponSocketTable`) exported per upper-body SpriteFrames
- A JSON metadata file generated by the asset pipeline
- Aseprite slice metadata exported by the ingest script

### Direction quantization

```gdscript
var aim_direction := global_position.direction_to(get_global_mouse_position())
var sector := _resolve_8_way_sector(aim_direction)  # returns Vector2 (e.g. Vector2.RIGHT)
var angle_error := aim_direction.angle() - sector.angle()
var weapon_rotation := clamp(rad_to_deg(angle_error), -12.0, 12.0)
```

### Draw order per direction

```text
aim east:  weapon generally in front of torso
aim west:  weapon may pass behind rear arm
aim north: weapon partially behind shoulders
aim south: weapon fully in front
```

Store per-direction `z_index` for the weapon root. Do not rely only on
Y-sorting for internal character parts.

## Transition Timing

The operator should raise into aim deliberately, but drop out of aim quickly.

### Raise: relaxed → aim

```text
duration: 0.18–0.26 sec
purpose: readable commitment and weapon presentation
```

Authored strip target: 5 frames at 20 fps → 0.25 sec.

### Lower: aim → relaxed

```text
duration: 0.10–0.15 sec
purpose: responsive disengagement and movement recovery
```

Authored strip target: 4 frames at 28 fps → 0.143 sec.

### Do not simply reverse the raise animation at the same speed

The lowering animation must have its own timing and preferably its own authored
motion:

```text
raise:
weapon comes up
shoulders settle
support hand establishes grip
head aligns behind sights

lower:
weapon drops immediately
shoulders release
support hand loosens
operator returns to locomotion
```

The lower animation should still be visible, but it should not feel like the
player is trapped in it.

### Exposed tuning

```gdscript
@export var ranged_raise_duration := 0.22
@export var ranged_lower_duration := 0.12
@export_range(0.0, 1.0) var ranged_aim_ready_ratio := 0.70
```

The operator becomes fully aim-accurate around 70% through the raise animation.

### Validation constraint

`ranged_lower_duration` must always be less than `ranged_raise_duration`.

## Input Behavior During Transitions

### While raising

- Movement remains allowed, possibly at `0.8–0.9×`.
- Firing should either buffer until the aim-ready frame or use an emergency
  snap-fire path.
- Fine aim correction should ramp in rather than activate instantly.

### While lowering

- Movement speed should recover rapidly.
- Firing input may cancel lowering and return to aim.
- Dodge should generally be allowed to interrupt lowering.
- Weapon swapping should wait until the weapon is sufficiently lowered.

## Ranged Aim Camera Feedback

A camera response is appropriate, but it should be subtle. A large zoom-in would
reduce awareness and may fight the top-down combat layout.

Use a combination of:

```text
small zoom change
+ cursor-direction camera lead
+ smooth transition
+ optional reticle emphasis
```

### Normal combat

```text
camera zoom: 1.00
camera lead: 0–10 px
```

### Aiming

```text
camera zoom: 1.06–1.10 apparent magnification
camera lead toward aim direction: 24–42 px
transition in: 0.18–0.25 sec
transition out: 0.10–0.16 sec
```

In Godot 2D, `Camera2D.zoom` can feel inverted depending on how the project
represents scale. Test the actual visual result rather than assuming that a
larger vector always means "zoom in."

The camera should move slightly toward the cursor or controller aim direction:

```gdscript
var desired_lead := aim_direction.normalized() * aim_camera_lead_px
```

This lets the player see more of what they are aiming at and provides a stronger
aiming cue than zoom alone.

### Exposed tuning

```gdscript
@export_group("Ranged Aim Camera")
@export var ranged_aim_camera_enabled := true
@export var ranged_aim_zoom_multiplier := 1.07
@export var ranged_aim_camera_lead_px := 32.0
@export var ranged_aim_camera_enter_sec := 0.22
@export var ranged_aim_camera_exit_sec := 0.13
@export var ranged_aim_camera_lead_smoothing := 12.0
@export var ranged_aim_reticle_emphasis := 1.15
```

### Camera state interpolation

Do not tween from multiple call sites. Give the camera one authoritative aim
target state.

```gdscript
func set_ranged_aim_camera_active(active: bool, direction: Vector2) -> void:
    _ranged_aim_camera_active = active
    _ranged_aim_camera_direction = direction.normalized()
```

Then update continuously:

```gdscript
func _update_ranged_aim_camera(delta: float) -> void:
    var target_zoom_multiplier := (
        ranged_aim_zoom_multiplier
        if _ranged_aim_camera_active
        else 1.0
    )

    var target_lead := Vector2.ZERO
    if _ranged_aim_camera_active:
        target_lead = (
            _ranged_aim_camera_direction
            * ranged_aim_camera_lead_px
        )

    var zoom_response := (
        ranged_aim_camera_enter_sec
        if _ranged_aim_camera_active
        else ranged_aim_camera_exit_sec
    )

    var zoom_weight := 1.0 - exp(
        -delta / maxf(zoom_response, 0.001)
    )

    _current_aim_zoom_multiplier = lerpf(
        _current_aim_zoom_multiplier,
        target_zoom_multiplier,
        zoom_weight
    )

    _current_aim_camera_lead = _current_aim_camera_lead.lerp(
        target_lead,
        1.0 - exp(-ranged_aim_camera_lead_smoothing * delta)
    )
```

The camera system should combine this with any existing screen shake, cinematic
framing, room bounds, camera dead zone, lock-on offset, and hitstop behavior.
Do not directly overwrite the camera's final position from `operator.gd`.

The recommendation is to use **both a slight zoom and directional camera lead**,
with the lead doing most of the practical work. The zoom communicates "precision
mode," while the lead actually improves visibility toward the target.

## Additional Visual Aiming Indicators

The camera response should not be the only indication. Use one or two secondary
cues.

### Reticle tightening

When aim becomes ready:

```text
reticle expands during raise
→ contracts at aim-ready threshold
→ remains stable while aiming
```

### Operator lighting or silhouette

A very slight weapon or visor glint can indicate that aim is fully established.

### Movement presentation

The lower body can continue moving, but:

```text
upper body faces aim direction
movement speed slightly reduced
turning becomes more deliberate
```

### Optional screen-edge cue

For distant aim, a faint directional marker or line from the operator toward
the cursor can help, but avoid clutter.

## State Transition Contract

```text
RANGED_RELAXED
    ↓ secondary held
RANGED_RAISING
    - play relaxed_to_aim
    - camera begins zoom/lead
    - aim accuracy ramps in
    ↓ ready threshold
RANGED_AIM
    - full socket tracking
    - reticle tight
    - camera fully biased
    ↓ secondary released
RANGED_LOWERING
    - play aim_to_relaxed faster
    - camera exits quickly
    - movement speed restores
    ↓ finished
RANGED_RELAXED
```

### Cancellation rules

```text
LOWERING + aim pressed
→ immediately return to RAISING or AIM

RAISING + aim released
→ transition directly into LOWERING

RAISING + dodge
→ cancel ranged presentation

AIM + paired execution / melee / terminal interaction
→ force camera exit and clean ranged state
```

## Deprecation Path

### Fully deprecated (remove after migration)

| Asset | Reason |
|---|---|
| `operator__modular_ranged_weapon__ranged_2h__stance_01__*` | Replaced by static directional weapon sprite + socket |
| `operator__modular_ranged_weapon__ranged_2h__aim_01__*` | Same |
| `operator__modular_ranged_weapon__ranged_2h__fire_01__*` | Same |
| `operator__modular_ranged_weapon__ranged_2h__relaxed_01__*` | Same |
| `operator_weapon_frames.tres` | Legacy weapon SpriteFrames; replaced by socketed static sprites |
| `carbine_rifle_mk1_definition.tres` `frames_resource` | No longer consumed |
| `sidearm_pistol_definition.tres` `frames_resource` | No longer consumed |
| `_sync_ranged_slave_frame_to_upper()` | No frame-slave sync needed for static sprites |
| `_sync_modular_ranged_weapon_layer()` | Replaced by socket positioning |

### Retained

| Asset | Reason |
|---|---|
| All upper body sheets (`operator__modular_upper_body__*`) | These drive the body pose |
| All lower body sheets (`operator__modular_lower_body__*`) | Locomotion |
| FX sheets (unarmed fast attack, parry, sidearm fire FX) | Overlay dressing |
| `PrimaryWeaponSocket` (renamed to `WeaponRoot`) | Node restructured, not removed |
| `Barrel` (renamed to `MuzzleSocket`) | Same purpose |

### Special cases (keep baked)

```text
paired_execution: fully authored body+weapon animation
cinematic_attack: fully authored
heavy_weapon_special: fully authored if body interaction is unusual
```

## Implementation Phases

### Phase 1 — Carbine frame-socket vertical slice (implemented)

The `e/w/se/sw` stance, aim, and fire frames have generated grip,
support-grip, muzzle, ejection, rotation, and draw-order records. A canonical
eight-way resolver drives both animation suffix and socket sector. Required
sector art is exposed as first-frame `AtlasTexture` views in the Carbine
definition. Projectile and muzzle flash share the resolved frame muzzle;
ejection is exposed for casing presentation. Missing required metadata, texture,
or grip pivot logs an error and does not use the generic forward muzzle.

The current modular weapon strips remain visible compatibility art, with the
upper body as their clock. This avoids a broad scene/resource migration before
the extracted static art is reviewed.

### Phase 2 — Static runtime weapon node and full directions

1. Export reviewed one-frame weapon textures for all eight sectors without
   action-strip padding ambiguity.
2. Replace primary-ranged use of `ModularSidearmSprite` with a dedicated
   `Sprite2D` under `WeaponRoot`; retain the modular node only for sidearm and
   migration compatibility.
3. Extend socket metadata to `n/ne/s/nw` and enable reviewed fine-angle limits.
4. Remove primary weapon frame-slaving after the static node passes visual QA.

### Phase 3 — Reload props and casing presentation

1. Assign casing scene/art and spawn it from `EjectionSocket`.
2. Author `MagazineSocket` and `OffhandPropSprite` tracks.
3. Export `mag_out`, `mag_in`, and `reload_commit` events and retain the
   existing exactly-once ammo-transfer guard.
4. Replace bootstrap coordinates with a fresh Aseprite marker export.

### Phase 4 — Legacy cleanup

**Goal:** Remove deprecated weapon sprite infrastructure.

1. Remove `PrimaryWeaponSprite` node and all `operator_weapon_frames.tres`
   references.
2. Remove `carbine_rifle_mk1_definition.tres` and
   `sidearm_pistol_definition.tres` `frames_resource` fields.
3. Remove the legacy `_update_primary_weapon_visual()` code path that
   referenced the old weapon SpriteFrames.
4. Remove `CRITICAL_ATTACK_*_SHEET` and `PAIRED_EXECUTION_*` baked weapon
   constants that are superseded (keep paired execution body sheets for
   now, but decouple their weapon display from the old system).
5. Remove `ranged_2h_reload` animation from the legacy weapon sprite path;
   reload presentation should use the body animation + empty-handed weapon
   socket.

**Acceptance:** No code references the old weapon SpriteFrames; the game
runs with only the socketed static sprite system.

## Migration Notes

### Asset pipeline changes

The ingest pipeline (`tools/pipelines/ingest.py`) currently expects action
strips with5-frame weapon strips. For static weapon sprites:

1. Add a `weapon_static` ingest mode that accepts single-frame directional
   weapon PNGs.
2. The pipeline should generate a `WeaponSocketTable` resource from Aseprite
   slice metadata or a companion JSON.

### Codex agent guidance

When implementing the socket system:

1. Do NOT modify `operator_modular_sidearm_frames.tres` directly — it broke
   the game in a previous attempt. All SpriteFrames changes should go through
   the ingest pipeline or Godot editor.
2. The `_apply_dynamic_weapon_socket_layout()` function already handles
   per-aim-state socket positions — extend it to per-frame.
3. The `OperatorWeaponDefinition` per-aim-state socket exports remain legacy or
   non-production compatibility only. A production-required sector may not fall
   back when its per-frame record is missing.
4. Keep the `weapon_feedback_event` signal contract unchanged — the
   `WeaponFeedbackPresenter` is presentation-only and does not care about
   sprite architecture.

### Validation

```bash
cd custodian
godot --headless --script tools/validation/ranged_combat_balance_smoke.gd
godot --headless --script tools/validation/combat_resource_feedback_smoke.gd
```

## Next Agent Slice

Goal: Implement Phase 2 — reviewed static runtime weapon node plus full
directional socket coverage.

Files: `operator.tscn`, `operator.gd` (weapon display functions), weapon
definition resources, modular sidearm sprite frames.

Constraints: Do not break the `weapon_feedback_event` contract; keep the
compatibility frame-slave path until static art is visually approved; preserve
paired execution presentation and required metadata failure policy.

Acceptance: All eight static textures and frame tracks validate; primary ranged
no longer needs animated weapon strips; muzzle/ejection/contact remain aligned;
no visual regressions in ranged combat.
