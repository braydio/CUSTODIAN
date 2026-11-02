# Humanoid Cutout Rig System

Status: implementation / in-progress
Owner: enemy visuals and asset tooling
Last updated: 2026-07-27

## Purpose

Provide a reusable, editor-friendly rigid paper-doll presentation backend for
96×96 humanoid enemies. It reduces repetitive full-frame drawing while leaving
enemy simulation, navigation, collision, targeting, damage, and combat timing
under their existing authorities.

This system is additive. Authored full-body `SpriteFrames` remain the default
enemy backend and remain the correct choice for perspective-extreme or tightly
timed special actions.

## Ownership Boundary

`HumanoidCutoutRig2D` owns only:

- directional atlas selection;
- rigid visual part placement, rotation, and translation;
- visual draw order;
- generic semantic animation playback;
- editor/dev preview overlays;
- visual-only weapon and hit markers.

It never owns or moves `CharacterBody2D`, collision, navigation, damage
resolution, attack windows, AI facing, or gameplay displacement. No collision
node belongs below a visual limb pivot.

## Rigid Cutout Design

The rig uses hierarchical `Node2D` pivots with `Sprite2D` children: pelvis,
torso/head, near and far segmented arms, near and far segmented legs,
attachments, cape, and weapon. It contains no `Skeleton2D`, `Bone2D`,
`Polygon2D`, mesh weights, bitmap warping, or procedural pixel deformation.

All parts use nearest filtering. Default anchors are integer coordinates.
Continuous modest rotations are the accepted paper-doll compromise. Optional
rotation quantization is review-only and never touches gameplay transforms.

## Atlas Contract

Each direction uses one transparent 480×384 atlas: 5 columns × 4 rows, with
twenty exact 96×96 cells. This is a static part atlas, not an animation sheet.
Every part remains in the same absolute 96×96 position it occupies in the
assembled character; never tightly crop or relocate a part inside its cell.

| Index | Cell | Part |
|---:|:---:|---|
| 0 | 0/0 | `head` |
| 1 | 0/1 | `torso` |
| 2 | 0/2 | `pelvis` |
| 3 | 0/3 | `back_attachment` |
| 4 | 0/4 | `front_attachment` |
| 5 | 1/0 | `upper_arm_back` |
| 6 | 1/1 | `forearm_back` |
| 7 | 1/2 | `hand_back` |
| 8 | 1/3 | `upper_arm_front` |
| 9 | 1/4 | `forearm_front` |
| 10 | 2/0 | `hand_front` |
| 11 | 2/1 | `thigh_back` |
| 12 | 2/2 | `shin_back` |
| 13 | 2/3 | `foot_back` |
| 14 | 2/4 | `thigh_front` |
| 15 | 3/0 | `shin_front` |
| 16 | 3/1 | `foot_front` |
| 17 | 3/2 | `weapon` |
| 18 | 3/3 | `cape` |
| 19 | 3/4 | `reserved` |

The runtime creates `AtlasTexture` regions directly. It does not duplicate,
resize, filter, or resample source pixels.

Runtime naming:

```text
<owner>__rig_atlas__<variant>__<direction>__5x4__96.png
```

Canonical runtime location:

```text
custodian/content/sprites/enemies/<enemy_id>/runtime/body/rig/
```

Canonical source location:

```text
custodian/content/_aseprite/sprites/enemies/<enemy_id>/source/rig/
```

## Parts and Aseprite Workflow

Each directional `.aseprite` source is 96×96, one frame, transparent, and has
the twenty exact part-layer identifiers in the atlas table. Core anatomy is
required; weapon, cape, attachments, and reserved may be blank.

1. Run `tools/aseprite/new_humanoid_rig_source.lua`.
2. Paste or draw each part on its named layer without changing its assembled
   96×96 position.
3. Save S/N/E sources in the mirrored `_aseprite` path.
4. Run `tools/aseprite/export_humanoid_rig_atlas.lua` for each direction.
5. Assign S/N/E atlases to `HumanoidCutoutRigSkin`; author W only when mirroring
   east is unsuitable.
6. Adjust the replaceable profile pivots once in Godot.

The exporter never flattens or modifies the source.

## Resources and Direction Behavior

`HumanoidCutoutRigSkin` is data-only and selects S/N/E plus optional W atlases,
a profile, modulate, and west-mirroring policy. S/N/E are required. A missing W
uses and mirrors east only when enabled; an authored W atlas is never mirrored.
Missing required or malformed atlases warn once per relevant condition.

`HumanoidCutoutRigProfile` exposes the 96×96 frame geometry, baseline, visual
offset, all anatomical/equipment anchors, per-direction draw-order dictionaries,
optional pivot overrides, and optional atlas offsets. Defaults target a generic
58–72-pixel-tall humanoid and are not production-enemy proportions.

Direction vectors map deterministically to N/E/S/W without changing AI or
movement direction. Exact diagonal ties preserve the previous axis sector to
avoid presentation flicker.

## Animation-State API

Generic semantic states are:

- `idle` — 1.2 seconds, looping;
- `run` — 0.8 seconds, looping;
- `attack_light` — 0.55 seconds, one-shot;
- `hit_react` — 0.28 seconds, one-shot;
- `death` — 0.9 seconds, one-shot held collapse.

The public API is `set_skin`, `set_facing_vector`, `set_direction_code`,
`play_state`, `stop_state`, `has_state`, `set_playback_speed`,
`set_visual_modulate`, and the weapon-tip/grip/hit anchor getters. State,
completion, and direction signals are presentation notifications only.

Animation tracks target visual pivots and `MotionRoot` only. Their timing never
changes gameplay hit timing.

## Draw Order

Every direction applies explicit relative `z_index` values rather than relying
on tree order. The default rear-to-front order is cape, back attachment, back
arm, back leg, pelvis, torso, head, front leg, front arm, weapon, front
attachment. Profiles may override the order independently per direction without
recreating the scene.

## Enemy Integration

`Enemy.visual_backend` defaults to `AUTHORED_FRAMES`. Existing grunt, savage,
marine, wolf, and ambient scenes therefore preserve their current
`AnimatedSprite2D`/`SpriteFrames` behavior.

`HUMANOID_CUTOUT` activates only when a valid optional child named
`HumanoidCutoutRig2D` exists. It hides the fallback `Visual` and
`AnimatedSprite2D`, then routes ordinary idle, run, light attack, hit reaction,
and death presentation to the rig. Missing semantic states fall back to idle and
report once through warning plus Developer Observatory event.

Falcon Punch, parry-critical phases, paired execution, savage/marine specials,
and authored directional special strips are not ported. Enemies needing those
states remain on authored frames until an explicit compatible fallback policy is
designed.

## Replacement-Pose Strategy

Rigid cutouts are not a mandate to eliminate authored poses. High-impact,
foreshortened, silhouette-breaking, or perspective-extreme actions may:

- swap one or more normal cells for authored replacement part cells; or
- temporarily use an authored full-body fallback strip.

Simulation timing remains external in both cases.

## Editor and Review

The tool-safe scene exposes skin/profile, preview direction/state, speed, pivot
and bounds overlays, baseline, atlas labels, pixel snapping, rest reset, reload,
and review-only rotation quantization. Debug drawings are editor/debug-only.

`game/actors/enemies/dev/humanoid_cutout_rig_review.tscn` provides keyboard and
button controls, a gameplay-size enemy, and a 3× nearest-neighbor preview with no
procgen dependency. Its geometric atlas is unmistakably dev-only.

## Validation

`tools/validation/humanoid_cutout_rig_smoke.gd` verifies atlas dimensions and
regions, all semantic nodes/parts, optional blanks, mirroring, stable direction
ties, loop contracts, root immobility, collision separation, nearest filtering,
default authored backend, grunt compatibility, and absence of deforming nodes.

Also run:

```bash
godot --headless --path . --script res://tools/validation/grunt_animation_smoke.gd
python tools/validation/architecture_ownership_smoke.py
git diff --check
```

## Limitations

- Rigid rotations can expose seams and cannot reproduce organic deformation.
- One generic profile cannot fit every body type; each real skin should receive
  a tuned profile resource.
- N/S/E must be authored independently; mirroring is W-only.
- Generic animation does not replace bespoke special-attack choreography.
- Atlas source layers are single-frame static parts, not replacement animation
  frames.

## Documentation Updates

The active asset convention, current-state summary, file index, Aseprite README,
and compact task packet identify the backend and distinguish source documents,
runtime atlases, authored full-body strips, replacement parts, and dev
placeholders.

## Acceptance Criteria

- [x] Reusable Node2D/Sprite2D rigid rig and replaceable skin/profile resources.
- [x] Fixed 20-cell 480×384 atlas slicing without resampling.
- [x] Required S/N/E and optional authored/mirrored W behavior.
- [x] Five generic semantic animations that affect visual pivots only.
- [x] Inspector and isolated review workflow.
- [x] Aseprite source creation/export tools.
- [x] Dry-run-by-default scaffold with optional dev placeholder generation.
- [x] Optional enemy backend with authored frames still default.
- [x] Focused smoke including existing grunt compatibility.
- [ ] First production skin authored and visually reviewed.

## Next Agent Slice

Create the first real S/N/E skin from Brayden's chosen humanoid source, tune its
profile in the isolated review scene, and decide whether its first
perspective-extreme attack uses replacement cells or an authored full-body
fallback strip. Do not migrate the production grunt as part of that slice.
