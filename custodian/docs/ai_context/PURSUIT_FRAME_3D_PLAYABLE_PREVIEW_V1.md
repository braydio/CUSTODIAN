# Pursuit Frame 3D Playable Preview V1

Status: **experimental development preview, not a runtime cutover.** The production
Pursuit Frame (`game/actors/enemies/pursuit_frame.tscn`, 96×96 Asset V2 family, four-direction
mirroring policy) is unchanged. Nothing here is approved for production intake.

Workstream: `pursuit-frame-3d-playable-preview-v1`.

## What it is

A dev-only Godot scene that runs the real game systems with a candidate 3D body:

- Scene: `custodian/scenes/debug/pursuit_frame_3d_playable_preview.tscn`
- Root: `custodian/tools/debug/pursuit_frame_3d_playable_preview.gd`
- Adapter: `custodian/tools/debug/pursuit_frame_3d_candidate_adapter.gd`
- Staging: `custodian/tools/character3d/stage/pursuit_frame_stage.py` → `custodian/.ai/pursuit_frame_3d_preview/` (gitignored)

The scene instances the existing combat playground (real controllable Operator, arena walls)
and spawns two real `pursuit_frame.tscn` actors under identical conditions: a **legacy**
reference and a **candidate**. Only the candidate carries the adapter.

The adapter does not own gameplay. It reads the enemy's public presentation action
(`get_enemy_presentation_action()`) and travel direction (`velocity`, `get_last_move_direction()`),
maps them to a staged 3D clip, and draws that frame at the contact shadow. The legacy body is hidden
while candidate mode is on and restored exactly when it is turned off. `enemy.gd`,
`EnemyBehaviorStateMachine`, `EnemyAnimationSet` and `EnemyPresentationController` are untouched.

## Physical scale

The candidate frames are rendered at **80 px/m**. The game's sprite space uses **50 px/m**
(Operator 3D contract: 45° orthographic, root `(64,106)`, no mirroring). The candidate is displayed
at `50 / 80 = 0.625`, so its physical size matches the Operator's in the same scene.
The **native** toggle (`N`) shows the candidate at 1:1 texture pixels, for resolution comparison only.

The displayed root (feet) sits at the `BlobShadow` centre `(0, 13)`, so contact is registered exactly.

## Viewport classes

Each class has one root pixel shared by all actions, directions and frames. There is no per-frame
recentering, no resampling and no mirroring.

| Class | Canvas | Root px | Actions |
|---|---|---|---|
| `standard_256x256` | 256×256 | (128, 180) | running, walking, alert, agree_gesture, casual_walk, arise, attack, skill_01, skill_03, triple_combo_attack |
| `extended_256x320` | 256×320 | (128, 216) | behit_flyup (needs 286 px height) |

Staging checks every frame: no alpha is cropped (alpha sum preserved), no visible pixel lies within
4 px of the viewport edge, and transparent pixels carry zero RGB.

## Action mapping

Gameplay mapping, from the enemy's own locomotion state:

| Enemy presentation action | 3D clip |
|---|---|
| `locomotion.run`, `locomotion.relaxed_run` | `running` (loops) |
| `locomotion.walk`, `locomotion.relaxed_walk` | `walking` (loops) |
| `posture.alert` | `alert` (plays once, holds last frame) |
| `locomotion.ready_idle`, `locomotion.relaxed_idle` | **idle fallback**: static `walking` frame 0, labelled as a fallback, not an authored idle |
| attacks, reactions, activities (any other action) | **unmapped**: holds the last mapped pose, labelled `UNMAPPED GAMEPLAY ACTION` |

Inspect mode (`Enter`) plays any of the 11 staged actions in any direction. The other nine actions
remain inspect-only until their combat timing, reaction physics or semantics are validated. Special
skills are not mapped to the Pursuit Frame's deferred intercept mechanic.

Playback FPS defaults to the staged `sampling_target_fps` (24). The authored FPS is not known, so
do not treat this value as authoritative. Adjust it with `-` and `=`.

## Controls

Chosen to avoid the project's existing bindings (WASD, P, Z, C, F5, and the dev-mode keys F2–F4, F9–F10).

| Key | Action |
|---|---|
| `F1` | candidate ↔ legacy presentation |
| `Enter` | gameplay mapping ↔ action inspection |
| `[` `]` | previous / next inspected action |
| `,` `.` | previous / next inspected direction |
| `;` `'` | step frame back / forward |
| `-` `=` | playback FPS down / up |
| `N` | game scale (50 px/m) ↔ native 1:1 (80 px/m) |
| `/` | pause / resume enemy AI on both actors |
| `F12` | screenshot |

## Verification

Headless smoke (23 checks, all pass): `custodian/tools/validation/pursuit_frame_3d_playable_preview_smoke.gd`

```
godot --headless --path custodian --script res://tools/validation/pursuit_frame_3d_playable_preview_smoke.gd
```

Covers: real actor identity; detection and chase (the candidate closes on the Operator and enters
`engage_operator`); frames advance during movement; locomotion mapping; direction follows travel;
visual root registered to the contact shadow; exactly one visible body; reversible A/B; viewport
selection; collision (28×28), speed (96) and damage (15) unchanged; production scene and `enemy.gd`
do not reference the candidate.

Regression (also pass): `standard_enemy_melee_smoke.gd`, `pursuit_frame_animation_set_smoke.gd`,
`pursuit_frame_asset_family_smoke.py`.

Windowed evidence capture (needs a display):

```
godot --path custodian --script res://tools/debug/pursuit_frame_3d_capture.gd -- \
  --pf3d-out=<abs dir> --pf3d-telemetry=<abs dir>/telemetry.jsonl
```

Telemetry records, per tick: presentation mode, legacy action, 3D clip, direction, frame, FPS, label,
enemy position and velocity, root and shadow positions, visible body count and display scale.

## Known limits

- The idle is a labelled fallback, not an authored 3D idle.
- Attacks and reactions show the held locomotion pose. They are not authored in this preview.
- Ally drones in the playground log `combat_drone.gd:602` null `add_child` errors when they fire. The
  drone's fallback path needs `/root/GameRoot/World/Projectiles` or `get_tree().current_scene`. The playground
  has no `World/Projectiles` node, and this preview is not the current scene. The candidate does not
  cause it. The playground alone logs none in 300 frames, so the errors appear only once drones engage.
- Direction naming (`S` faces the camera, `E` is screen-right) follows the render camera convention.
  It is verified only by the capture screenshots, not by an automated check.
- The source metadata labels endpoint and root residual values as metres. They are armature-local units
  under a 0.01 armature scale. See the transform finding below.

## Transform finding (source diagnostic)

- `endpoint_max_bone_head_delta_m` is measured in armature-local units. The arise clip's armature scale
  is 0.01, so the true world value is 1.707 m (the reported 170.7 is local units). That is genuine bone
  motion for a rise, not a measurement or deformation defect.
- `root_xy_residual_after_m` (41 m reported) is also local units: 0.41 m world. The render's object-level
  offset cancels it. Hips XY drift after the offset is 0.0 m in world space for arise, running and attack.
  Before the offset it reaches 0.47 m.
- Conclusion: no upstream source defect. Rotation and deformation verification stands. Positional
  ground truth remains an open item in the Operator pipeline notes. The metadata unit labels are wrong.

## Inputs

- Proof workspace: `~/Projects/.operator-3d-animation-proof/pursuit_frame_3d_v1/`
- Cleaned frames: `output/clean/c256_80/`, `output/clean/c512_80/` (9,440 frames, unmodified renders)
- Extents: `reports/extents_c512_80_clearance4.json`
- Staged manifest (per action, with source meta hashes): `custodian/.ai/pursuit_frame_3d_preview/manifest.json`

Staging: `python3 -I custodian/tools/character3d/stage/pursuit_frame_stage.py --workspace <proof workspace>`
