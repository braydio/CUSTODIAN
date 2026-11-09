# Character 3D Model to Playable In-Game Pipeline

Status: **process guide, not an approval.** It describes how a rigged 3D character becomes
an 8-direction 2D presentation that the game plays, from a source model through headless Blender
to a debug preview and, only after review, a production intake. Nothing in this guide promotes an
asset to production. Production intake has its own owner, family contract and review.

Worked examples in this repository:

| Example | Status | Where |
|---|---|---|
| Operator (Meshy, 24-joint skin) | Playable debug preview, 80 px/m frames, 50 px/m display | `custodian/docs/ai_context/OPERATOR_3D_*` (on `operator-character-master-v1`), `custodian/tools/validation/operator_3d_playable_preview_smoke.gd` |
| Pursuit Frame (existing 2D enemy, 24-joint skin) | Playable debug preview beside the legacy sprite | `custodian/docs/ai_context/PURSUIT_FRAME_3D_PLAYABLE_PREVIEW_V1.md`, branch `agent/pursuit-frame-3d-playable-preview-v1` |

Read this guide first. Then read the example docs for the specific Blender traps that were found the hard way.

---

## 1. Goals and boundaries

**Goal.** Take a rigged character from a source file to a playable enemy or actor that uses the
real gameplay systems: detection, pursuit, navigation, collision, damage, and the existing
semantic presentation authority. Every stage must be reproducible, must check itself, and must
leave the original source untouched.

**Boundaries that hold at every stage.**

1. Source files are never edited. Raw renders are never edited. Derived files are new files with recorded hashes.
2. Gameplay authority stays where it is. A candidate body changes **what is drawn**, never **what the actor does**.
3. Candidate art stays out of production paths (Asset V2 inbox, runtime sprite folders, family contracts) until a separate, approved intake.
4. Every headless run writes a completion marker or a report. Never trust an exit code alone.
5. Long Blender and Godot runs go in the background with a marker file. A foreground run can exceed the tool time limit.

---

## 2. Glossary and invariants

| Term | Meaning | Rule |
|---|---|---|
| Master | The rigged source character (`.glb`) with mesh, skin and skeleton | Read-only. Hash it. |
| Motion source | An animation-only `.glb` for one action | Must share the master's skeleton (same joint names, same rest TRS) |
| Derived skinned clip | Master geometry plus one motion's animation channels | Built by byte-copy, never by re-keying |
| Armature scale | Object scale on the imported armature | glTF is centimetre-based in many exports (0.01). Measure in world space or apply the scale |
| Root bone | The joint whose horizontal translation is extracted to keep the character in place | Default `Hips` |
| Root registration | The pixel where world origin (the feet on the ground plane) lands in every frame | One fixed pixel per canvas class, for every action, direction and frame |
| Canvas | Render size in pixels (for example 256 or 512) | Renders are cropped or padded, never resampled, to the viewport |
| px/m | Pixels per metre in the render camera | Candidate renders: 80. Game sprite space for the Operator: 50 |
| Display scale | Scale applied when drawing a frame in game | `game px/m ÷ render px/m`. For 80 px/m renders at 50 px/m game space: 0.625 |
| Viewport class | A fixed canvas size with one root pixel (for example `256x256` root `(128,180)`) | Smallest class where every frame of every action fits with clearance |
| Clearance | Empty margin between the visible silhouette and the viewport edge | At least 4 px, measured on alpha |
| Direction | One of 8 render azimuths: `S SE E NE N NW W SW` | `S` faces the camera. `E` is screen-right. Verify with stills |
| Mirroring | Deriving one side from the other | Forbidden for candidate sets. Every direction is independently rendered |

**Invariant checks (run them, do not assume them):**

- Root registration: after the render-time offset, the root point's world-space XY drift is 0 for every sampled frame.
- No alpha is lost when cropping: the alpha sum before and after placement is identical.
- No visible pixel lies within the clearance margin of any viewport edge.
- Transparent pixels carry zero RGB.
- Staged frame count equals the source sample count, for every direction.

---

## 3. Architecture

### 3.1 Stages and owners

```
            ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
 source ──► │ 1 Intake     │──►│ 2 Inspect    │──►│ 3 Adapt      │──► derived skinned .glb
 .glb/.fbx  │ hash, catalog│   │ scale, units │   │ byte-copy    │
            └──────────────┘   └──────────────┘   └──────┬───────┘
                                                        │
            ┌──────────────┐   ┌──────────────┐   ┌──────▼───────┐
 review ◄── │ 7 Review     │◄──│ 6 Stage      │◄──│ 4 Verify     │
 Dropbox    │ sheets, table│   │ viewports,   │   │ pose invar.  │
            └──────────────┘   │ clearance    │   └──────┬───────┘
                               └──────┬───────┘          │
            ┌──────────────┐   ┌──────▼───────┐   ┌──────▼───────┐
 playable ◄─│ 9 Godot      │◄──│ 8 Presentation│◄─│ 5 Render +   │
 in-game    │ scene + QA   │   │ adapter       │   │ root removal │
            └──────────────┘   └──────────────┘   │ + cleanup    │
                                                 └──────────────┘
```

| Stage | Tooling | Owner | Output |
|---|---|---|---|
| 1 Intake | hashing, `INPUT_MANIFEST.json` | pipeline | manifest with SHA-256 per input |
| 2 Inspect | headless Blender probe | pipeline | scale, unit, rest-pose findings |
| 3 Adapt | `adapt_motion_to_master.py` | pipeline | `output/derived/<action>_skinned.glb` |
| 4 Verify | `verify_derived_pose.py`, invariant checks | pipeline | `reports/<action>_derived_verification.json` |
| 5 Render | `measure_render.py --root-mode object`, `alpha_cleanup.py` | pipeline | `output/measure/`, `output/clean/` |
| 6 Stage | `pursuit_frame_3d_stage.py` (generalise per character) | pipeline | gitignored `custodian/.ai/<character>_3d_preview/` |
| 7 Review | `make_review_sheets.py`, `publish_review_artifacts.py` | art/review | sheets and a Dropbox bundle |
| 8 Presentation | debug `*_candidate_adapter.gd` | gameplay/presentation | candidate body beside the legacy one |
| 9 Playable | debug scene + smoke + capture | gameplay QA | real-gameplay evidence |

### 3.2 Layers in the game

Keep three responsibilities separate. Do not merge them.

1. **Semantics (existing, do not change).** The actor's behaviour state machine, the enemy's
   presentation action names (for example `locomotion.run`), and `EnemyPresentationController`
   decide *what* should be presented.
2. **Candidate adapter (new, debug only).** Reads semantics through public methods, maps them to
   a staged clip, and draws the frame. It owns no gameplay state.
3. **Staged data.** Versioned manifest plus frames. Keeps geometry, timing and registration facts.

The Operator's production presenter (`OperatorBodyPresenter`, with `present`, `can_present`,
`register_body_layers`, `claim_modular`, `release_modular`) follows the same principle: it claims
an owner and presents a plan. It does not decide gameplay. Follow that model for new bodies.

---

## 4. Repository and workspace organization

| Location | Holds | Committed? |
|---|---|---|
| Source and renders (proof workspace, e.g. `~/Projects/.operator-3d-animation-proof/<name>/`) | `inputs/`, `scripts/`, `reports/`, `output/` | No (external workspace) |
| `custodian/.ai/<character>_3d_preview/` | Staged frames and `manifest.json` | **No** (gitignored by `.ai/`) |
| `custodian/tools/debug/` | Staging scripts, debug adapters, capture drivers, debug scene scripts | Yes |
| `custodian/scenes/debug/` | Debug scenes only | Yes |
| `custodian/tools/validation/` | Headless smokes; register each in `validation_manifest.json` | Yes |
| `custodian/docs/ai_context/` | Workstream and pipeline docs | Yes |
| Dropbox `visual_review/<workstream>/<run>/` | Review evidence | Remote, delete-after-review by default |

**Recommended target layout** (the Pursuit Frame proof currently lives outside the repo; move its
scripts in under this structure when the pipeline is reused):

```
custodian/tools/character3d/
  adapt/            adapt_motion_to_master.py, verify_derived_pose.py
  render/           measure_render.py, root_motion_audit.py, alpha_cleanup.py
  stage/            stage_character_preview.py   (generic; takes a character contract)
  review/           make_review_sheets.py
  contracts/        <character>_camera_contract.json   (px/m, root, canvas, directions)
custodian/tools/debug/<character>_candidate_adapter.gd
custodian/scenes/debug/<character>_3d_playable_preview.tscn
```

Put the camera contract in a JSON file and have every stage read it. Do not repeat the constants
(80, 256, `(128,180)`) in each script. The Operator's `batch.v1` schema shows this pattern
(`custodian/tools/operator/animation_compiler/schemas/batch.v1.schema.json`).

### 4.1 Naming

- Action and clip names: `snake_case`, matching the source file stem (`triple_combo_attack`).
- Directions: `S SE E NE N NW W SW`, uppercase, in that order.
- Frames: `frame_NN.png`, zero-based, two digits.
- Staged viewport folder: `<class_id>/<action>/<direction>/frame_NN.png`, for example
  `standard_256x256/running/E/frame_03.png`.
- Reports: `measure_<action>_c<canvas>_<ppm>.json`, `<action>_derived_verification.json`.
- Workstream IDs: lowercase kebab-case, ending in a version (`pursuit-frame-3d-playable-preview-v1`).

---

## 5. Stage-by-stage workflow

Commands assume the proof workspace is `W=~/Projects/.operator-3d-animation-proof/<name>`.

### Stage 1: Intake and hashing

1. Place the master and motion sources under `$W/inputs/`. Do not rename them after hashing.
2. Hash every input and write `reports/INPUT_MANIFEST.json`:

   ```bash
   sha256sum inputs/character_master.glb inputs/animations/*.glb
   ```

3. Record which motion files are **excluded**, and why. For example, a duplicate file byte-identical to another, or a
   static mesh with no rig. Put the reason in the manifest, not only in your head.

**Gate:** every input has a hash, and every exclusion has a reason.

### Stage 2: Inspect in headless Blender

Run a probe before trusting any number. The probe loads one clip, prints the armature scale and
the frame range, and reports the same quantity in both local and world space.

Reference pattern (the Pursuit Frame probe, reproduced here):

```python
# blender -b --factory-startup --python probe.py -- <clip.glb>
import sys, bpy
from mathutils import Vector
clip = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=clip)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
print("ARM scale", tuple(arm.scale))           # 0.01 means centimetre source units
t0, t1 = arm.animation_data.action.frame_range
bpy.context.scene.frame_set(int(t0)); bpy.context.view_layer.update()
local0 = {b.name: b.head.copy() for b in arm.pose.bones}
bpy.context.scene.frame_set(int(t1)); bpy.context.view_layer.update()
local1 = {b.name: b.head.copy() for b in arm.pose.bones}
print("local max", max((local1[k] - local0[k]).length for k in local0))
print("world max", max((arm.matrix_world @ local1[k] - arm.matrix_world @ local0[k]).length for k in local0))
```

Then decide the unit rule:

- If `arm.scale` is about 0.01, values read in local units are 100× too large. Use world space
  (`arm.matrix_world @ bone.head`) for every reported metric, and label the units in the output.
- Confirm the rest pose matches the master (joint names and rest TRS identical). Compare glTF-level data or
  relative invariants. Do **not** compare Blender bone matrices against empty world matrices. That comparison
  produced a false "21/24 mismatch" in the Operator work.

**Gate:** you can state the scale, the unit rule, and the rest-pose match in one sentence each.

### Stage 3: Adapt the motion to the master

`adapt_motion_to_master.py` copies each motion's raw accessor bytes unchanged into the master's binary
chunk, rebases buffer views and accessors, and keeps node indices. Mesh, skin and nodes are untouched.

Functions (in `scripts/adapt_motion_to_master.py` of the Pursuit proof workspace):

| Function | Role |
|---|---|
| `read_glb(path)` | Parse GLB header, JSON chunk and BIN chunk |
| `write_glb(path, j, binc)` | Write a GLB from a JSON dict and binary blob |
| `bytes_of_accessor(j, binc, acc_idx)` | Raw bytes for one accessor |
| `check_identical_skeleton(master, motion)` | Refuse to adapt if joint names or rest TRS differ |
| `main()` | Entry point |

Invocation (positional arguments):

```bash
python3 -I scripts/adapt_motion_to_master.py \
  inputs/character_master.glb inputs/animations/<action>.glb \
  output/derived/<action>_skinned.glb <action> > reports/_adapt_<action>.json
```

Rules:

- Run `-I` (isolated mode) so a planted module in the working directory cannot be imported.
- Refuse any motion whose skeleton differs. Do not "fix" it silently. Report it and exclude the action.
- Motions that carry no skin import as empties named after bones, with object-level curves.
  Adapt them on the skeleton side, not as bone curves.

**Gate:** `check_identical_skeleton` passes for every included action.

### Stage 4: Verify the pose

`verify_derived_pose.py` is run in Blender for each derived clip, against the original motion:

```bash
blender -b --factory-startup --python scripts/verify_derived_pose.py -- \
  output/derived/<action>_skinned.glb inputs/animations/<action>.glb \
  reports/<action>_derived_verification.json
```

Its helpers: `floats`, `trs_at`, `node_local`, `gt_world` (ground truth from glTF data), and
`invariants(delta)`, which returns the rotation angle and translation length of a pose delta.

What the checks prove, and what they do not:

- **Proven:** rotation and deformation agree with the source for every sampled key (for the
  Pursuit Frame, errors of about 1e-6 to 1e-5 rad).
- **Not yet proven:** joint **positions** against an independent ground truth. The Operator
  notes record that the positional ground-truth check disagreed even on a known-good file, so that
  check was a bug in the ground-truth math, not in the adapter. Treat positional claims as
  unverified until a known-good file passes first.
- **Stronger evidence:** the transparency test. The derived clip reproduces the original's pose
  matrices and evaluated vertices exactly across sampled frames.

Fail a clip if `pass` is false, if the clip does not animate, or if any sampled pick exceeds the
angle tolerance.

**Gate:** every included action has `pass: true` and `animates: true`, and the positional limitation is recorded.

### Stage 5: Render with object-level root removal

The renderer must keep the character in place while preserving the animation's vertical motion.

1. **Remove root translation at the object, not the bone.** `measure_render.py --root-mode object`
   sets `arm.location` each frame from the root bone's horizontal delta, scaled by `arm.scale.x`:

   ```python
   delta_arm = Vector((rest_head.x - head_arm.x, rest_head.y - head_arm.y, 0.0))
   arm.location = Vector((delta_arm.x * arm.scale.x, delta_arm.y * arm.scale.x, 0.0))
   ```

   **Never use the bone mode for final renders.** A bone-level location change is discarded when the
   render re-evaluates the animation. This caused a real defect: the correction was silently dropped
   while the metadata claimed it was applied.

2. **Verify registration after the offset.** Apply the same offset in a probe and confirm that the world-space
   root point stays at the rest position for every sampled frame. The Pursuit Frame probe measured 0.0 m drift after
   the offset, against 0.47 m before it.

3. **Render with a fixed orthographic camera.** `camera_for(azimuth_deg, cam)` places the camera at 45°
   elevation for each of the eight azimuths. For orthographic side views, use
   `direction.to_track_quat("-Z", "Y")`. Using `"Z"` as the up axis rolls the camera 90° at side azimuths.

4. **Choose the canvas and pixel density once per character.** Example: `--ppm 80 --canvas 512` for edge-clipped
   actions, `--canvas 256` for the rest. Re-measure any action that touches the canvas edge at a larger canvas, rather than
   cropping it.

Invocation (one action, one canvas):

```bash
blender -b --factory-startup --python scripts/measure_render.py -- \
  --action <action> --clip output/derived/<action>_skinned.glb --out output/measure \
  --meta reports/measure_<action>_c<canvas>_<ppm>.json \
  --ppm 80 --canvas 512 --root-mode object
```

Run the full set in the background and wait on a completion marker. The Pursuit Frame driver
(`_driver_render.sh`) printed `RENDER_ALL_DONE`; the 512 px re-measure wrote `ALL_DONE`.

**Metadata caveat.** The `*_m` fields that `measure_render.py` writes are in **armature-local units**,
not metres, when the armature scale is 0.01. Convert them with the armature scale, or better, record
world-space values. The Pursuit Frame metadata reported `endpoint_max_bone_head_delta_m: 170.7`, which is 1.707 m in world space.
Do not publish unit-labelled values you have not converted.

**Gate:** the probe's world-space drift is zero, and every action has a render directory per direction and per frame.

### Stage 6: Clean and check alpha

`alpha_cleanup.py` makes derived copies with RGB zeroed where alpha is 0. Visible pixels are checked
for exact identity.

| Function | Role |
|---|---|
| `clean_array(arr)` | Zero RGB on transparent pixels, leaving alpha and visible pixels unchanged |
| `silhouette_mask(alpha)` | Main silhouette (alpha ≥ 8) grown by 2 px, to find stray low-alpha specks |
| `process(src, dst)` | Clean one frame, validate it, return counts |
| `main()` | `--src <dir> --dst <dir> --report <json>` |

```bash
python3 -I scripts/alpha_cleanup.py --src output/measure/c512_80 \
  --dst output/clean/c512_80 --report reports/_alpha_cleanup_c512.json
```

Run it on the whole canvas tree. It writes a report with `low_alpha_px_outside_silhouette`, which should be zero.

**Gate:** `visible_px_preserved` equals the visible count before cleanup, and stray low-alpha pixels are zero.

### Stage 7: Extents, classes and fit

Measure each action from alpha, not from bounding-box width and height alone. A bounding box hides
asymmetric poses.

For every frame of every direction, compute the root-relative extents:

```python
ys, xs = np.nonzero(alpha > 0)
left  = root_x - xs.min();  right = xs.max() - root_x
up    = root_y - ys.min();  down  = ys.max() - root_y
# keep the maxima over all frames and directions, then add the 4 px clearance
```

Then choose the smallest class that contains every frame with clearance. `pursuit_frame_3d_stage.py`
does this in `choose_class` with `place` and `clearance_ok`. The Pursuit Frame result:

| Class | Canvas | Root | Actions that fit |
|---|---|---|---|
| `standard_256x256` | 256×256 | (128, 180) | 10 of 11 |
| `extended_256x320` | 256×320 | (128, 216) | `behit_flyup` (286 px tall) |

Root choice: the top margin must cover the largest up-extent (176 px including clearance), and the bottom
margin must cover the largest down-extent (69 px). Pick the root pixel from those two numbers, then keep it
for every action in the class.

Fit against the current 2D canvas before deciding anything. At 80 px/m, the 96×96 enemy canvas fits none of the 11 actions.
It would need roughly 27 to 47 px/m. Decide the target density and scale explicitly, and record it.

**Gate:** every action has a chosen class, a root pixel, and a measured minimum clearance of at least 4 px.

### Stage 8: Stage the registered frames

`pursuit_frame_3d_stage.py` writes the registered frames into a gitignored folder, with a manifest.

```bash
python3 -I custodian/tools/debug/pursuit_frame_3d_stage.py \
  --workspace <proof workspace>
```

| Function | Role |
|---|---|
| `place(src, src_root, cls)` | Crop or pad so the source root lands on the class root. Pixel-exact |
| `clearance_ok(img)` | True when no visible pixel lies within 4 px of an edge |
| `choose_class(src_frames, src_root)` | Smallest class where every frame fits and no alpha is lost |
| `main()` | Writes frames and `manifest.json` (per action: viewport, root, frame count, timing, source hashes) |

The manifest records `sampling_target_fps`, `authored_frame_range` and `sample_count`. **Do not infer an authored FPS**
from review sheets. The sampling target is not the authored frame rate. Playback FPS is an explicit, adjustable debug value.

**Gate:** frame counts equal the source sample counts, and every frame passes `clearance_ok`.

### Stage 9: Review sheets and evidence

`make_review_sheets.py` makes one sheet per action: 8 directions by 6 evenly spaced frames, at native 1:1 pixels, with labels in a margin outside the cells.

- `sheet(src_root, action, out_dir)`: builds one sheet. `main()` takes `--src`, `--action` (one or more) and `--out`.
- Labels sit outside the cells, so they never cover pixels.
- For edge-clipped actions, use the larger canvas. Keep the canvas name in the file name.

Publish the bundle with `publish_review_artifacts.py`. Its flow is fixed:

1. `--doctor --remote git-dropbox-sync` to check the remote.
2. `--source <absolute dir>` and one `--artifact` per file. Set an explicit `--max-files`.
3. `--dry-run` first, and review the selection.
4. Add `--important --reason "<why subjective review is needed>"` only for a question that objective checks cannot settle. Add
   `--question` for the reviewer. Add `--include-video` only when motion or timing needs a video.
5. Retention defaults to `delete-after-review`. Say so in the handoff, and add `--retain-after-review` only if the evidence should be kept.

Keep the previous review bundle until the new one has been evaluated.

**Gate:** the dry run selects the intended files, and the upload returns `status: uploaded` with a run ID.

### Stage 10: Presentation adapter in the game

This stage connects the staged frames to the real enemy. It is where most gameplay bugs appear.

#### 10.1 The contract with the existing presentation

The enemy already exposes what it is doing. Read it, do not replace it:

| Public API | Returns | Use |
|---|---|---|
| `enemy.get_enemy_presentation_action()` | `StringName`, such as `&"locomotion.run"` | Map to a 3D clip |
| `enemy.get_last_move_direction()` | `Vector2` facing | Direction when stationary |
| `enemy.velocity` | `Vector2` | Travel direction when moving |
| `enemy.get_enemy_presentation_frame()` / `get_enemy_presentation_animation()` | Legacy frame and animation name | Diagnostics only |

`EnemyAnimationSet` (`resolve_clip`, `build_sprite_frames`, `get_animation_name`) and
`EnemyPresentationController` (`play`, `select_normal_attack`, `select_flinch_for_severity`, `select_flavor`)
own the semantic names and clip selection. The adapter must not call `play` and must not change the clip the
enemy selects.

#### 10.2 Mapping table

Map only what is validated. Leave everything else inspect-only, and label the rest.

| Enemy action | Candidate clip | Rule |
|---|---|---|
| `locomotion.run`, `locomotion.relaxed_run` | `running` (loop) | Chase |
| `locomotion.walk`, `locomotion.relaxed_walk` | `walking` (loop) | Patrol and walk |
| `posture.alert` | `alert` (play once, hold last frame) | Alert |
| `locomotion.ready_idle`, `locomotion.relaxed_idle`, empty | **Idle fallback**: static walk frame 0, labelled | No authored idle yet |
| Anything else (attacks, reactions, activities) | **Unmapped**: hold the last mapped pose, labelled | Do not invent timing |

Do not map a special skill onto a normal attack, and do not map a combat clip onto a mechanic
it does not represent. Each new mapping needs its own validation and review.

#### 10.3 The adapter: exact functions

`custodian/tools/debug/pursuit_frame_3d_candidate_adapter.gd`, class `PursuitFrame3DCandidateAdapter`:

| Function | What it does |
|---|---|
| `_ready()` | Finds the enemy (parent), loads the manifest, records the legacy nodes' visibility, creates the `Candidate3DBody` `Sprite2D`, opens telemetry, applies presentation |
| `_load_manifest()` | Reads `res://.ai/<character>_3d_preview/manifest.json`, fails loudly if missing |
| `_open_telemetry()` | Opens a JSONL file from `--pf3d-telemetry=<path>` user args |
| `advance(delta)` | Resolves the presentation for one tick. Public so tests can apply a change without waiting |
| `_physics_process(delta)` | Calls `advance`, then writes telemetry |
| `_resolve()` | The mapping table above, returning clip, direction, static flag, loop flag, label |
| `_travel_direction()` | `velocity` when moving, else last facing, else `DOWN` |
| `_compass(v)` | Converts a vector to one of eight screen-space names |
| `_update_frame(clip, dir, static, loops)` | Frame index from time × FPS. Loops or clamps. Applies offset and scale |
| `_texture_for(clip, dir, index)` | Loads one PNG with `Image.load_from_file`, caches up to 48 textures |
| `_apply_scale()` | `current_display_scale()` to the sprite |
| `_apply_presentation()` | Shows exactly one body. Restores legacy visibility exactly when turned off |
| `_write_telemetry()` | One JSON record per tick (see 10.5) |
| `current_display_scale()` | `1.0` for native, else `GAME_PX_PER_M / CANDIDATE_PX_PER_M` (50 / 80) |
| `visible_body_count()` | Number of visible bodies. Must be exactly one |

**Anchoring.** The sprite is positioned at the blob shadow centre (`SHADOW_OFFSET = (0, 13)`, the
`BlobShadow` position in the enemy scene). Its `offset` is `-root_px`, so the root pixel lands exactly
on the shadow centre. Do not move the shadow to fit the sprite. Move the sprite.

**Telemetry.** Open the log from the command line, so normal play is unaffected:
`godot ... -- --pf3d-telemetry=/abs/path/telemetry.jsonl`.

#### 10.4 The debug scene and controls

`custodian/tools/debug/pursuit_frame_3d_playable_preview.gd` (root script) instances the real combat playground,
removes its grunts, and spawns two real `pursuit_frame.tscn` actors: a legacy reference and a candidate with the
adapter. Both are placed inside the Pursuit Frame's 225 px awareness bubble, so detection can happen.

Functions: `_ready()` (builds the arena and actors), `_build_hud()`, `_process()` (HUD text),
`_unhandled_input(event)` (controls), `_capture_screenshot()` (F12).

Controls must not collide with the project's existing bindings. Check the input map before you choose keys.
Those used here: `F1` presentation, `Enter` mode, `[ ]` action, `, .` direction, `; '` frame step, `- =` FPS,
`N` native scale, `/` pause, `F12` screenshot.

Note: the project already binds most letters and the function keys `F2` through `F11` in its dev tools. Check the input map before you assign a key.

#### 10.5 Telemetry schema

Each record has: `tick`, `presentation`, `mode`, `legacy_action`, `clip_3d`, `direction`, `frame`, `fps`,
`label`, `position`, `velocity`, `root_global`, `shadow_global`, `visible_body_count`, `display_scale`,
`paused`. Use it to prove each claim: travel direction, frame advance, one visible body, root on shadow.

### Stage 11: Automated gameplay tests

Put the headless test in `custodian/tools/validation/` and register it in
`custodian/tools/validation/validation_manifest.json`. Run it with:

```bash
godot --headless --path custodian --script res://tools/validation/<name>_smoke.gd
```

The smoke test should be a state machine in `_process`, not a fixed `await` chain. It must:

1. Assert the actors are the real scene files (`scene_file_path`).
2. Sample the scene over a fixed number of frames.
3. Check movement and detection: the actor's world position changes, and the distance to the target changes in the expected direction.
4. Check frame advance during movement, the clip-to-action mapping, and direction against velocity.
5. Check grounding: the visual root equals the shadow point.
6. Check exactly one visible body, and that the legacy body is hidden.
7. Check reversibility: switch to legacy and back.
8. Check viewport selection for a known inspected clip (for example, the extended class for the tallest action).
9. Check that unchanged gameplay values remain unchanged (collision shape, speed, damage).
10. Check that the production files do not reference the candidate (grep the scene and the enemy script).
11. Print a result line and exit with a non-zero code on any failure.

**Gotchas from this work:**

- Use `adapter.advance(0.0)` in tests after a state change. Physics ticks and process frames are not in lockstep.
- Use `await` only inside a coroutine that the state machine calls. A non-awaited coroutine returns early, and the
  test then quits before its checks run.
- Place actors so the detection rules can fire. Read the profile values (vision 300 px, cone 118°, awareness bubble 225 px)
  rather than guessing.
- In a fresh worktree, run `godot --headless --path custodian --import` once. Otherwise you get "class not found"
  parse errors, and `class_name` lookups fail. Those are not code errors.
- In a fresh worktree, pull the LFS files the scene uses (for example
  `git lfs pull -I custodian/content/sprites/world/shadows/contact_shadow_character_64x32.png`). A
  384-byte pointer file means the content was never fetched.

### Stage 12: Windowed capture and evidence

Headless runs cannot make screenshots. Use a windowed run with a capture driver
(`custodian/tools/debug/pursuit_frame_3d_capture.gd`).

- `--pf3d-mode=inspect`: freezes the AI, steps through the eight directions, and captures a close-up. Use it for orientation checks.
- `--pf3d-mode=chase`: runs the real chase and captures frames. The driver leads the target around a path, so the chase continues. Any run can end when the enemy lands a hit and the world stops. Record that.

Rendering is slow on a software display. A few hundred frames can take several minutes. Start the run in the background with `nohup`,
and check progress through the output directory and the telemetry line count.

**Process hygiene:** stop a stalled run by PID, not with `pkill -f <pattern>`. The pattern can match your own
shell command.

Evidence to publish: a labelled review board, the telemetry and its summary, a short MP4 when motion matters, the 11-action table
(clipping result per action, computed from the staged frames), and the orientation stills.

### Stage 13: Workstream lifecycle and commits

- Create the workstream with `custodian/tools/agent/workstream.py start <id> --agent <name>`. It creates `agent/<id>` in an ephemeral worktree.
  Do not implement from the coordination checkout.
- Commit exact paths only. Use `git add <path>`, never `git add .`. Leave other workstreams' untracked files alone.
- Commit messages end with the attribution line the repository asks for.
- Do not push, merge or promote without an explicit instruction. The lifecycle has separate landing and review steps.
- Before you say "done", state each lifecycle stage truthfully: implemented, validated, landed. These are separate.

---

## 6. Recommended architecture for reuse

The current Pursuit Frame proof was built as a one-off. For the next character, consider these changes in order.

1. **Move the Blender and render scripts into the repository** under `custodian/tools/character3d/`, so the pipeline is
   reviewable, testable and versioned. Keep source inputs and renders in the external workspace.
2. **One camera contract per character.** A JSON file with `pixels_per_meter`, `root_pixel`, `canvas`, `directions`,
   `elevation_degrees`, `mirroring: false`, and the render policy. Every stage reads it, and a schema validates it.
3. **Record units explicitly.** Every metric field carries its unit (`world_m`, `armature_local`). Do not reuse `_m` for both.
4. **One staging tool with a character profile**, rather than a copy per character. The Pursuit Frame stager is the reference
   for `place`, `clearance_ok` and `choose_class`.
5. **A generic candidate adapter** that takes the enemy's semantic names as data (a mapping resource), not in code.
   Each new enemy supplies a mapping table and nothing else.
6. **Keep the candidate debug-only.** Production scenes never reference the adapter, and a regression test enforces it.
7. **A single validation manifest entry per character**, with a `needs_import` flag and the staging prerequisite written down.
8. **Production intake as a separate workstream**: family contract, profile migration, inbox path
   `custodian/asset_drop/inbox/<family>/<state>__<direction>.png`, and review. Never place 256 px or extended-height frames into
   a 96 px family contract.

---

## 7. Best practices

**Source and data**
- Hash inputs before you touch them. Keep hashes in the manifest.
- Check armature scale on every import. Assume centimetre units until you have measured otherwise.
- Use a known-good file to validate any new checker. Only then trust it on new data.
- Exclude unrelated or duplicate files, and record each exclusion with its reason.

**Blender (headless, version 5.x)**
- Run with `-b --factory-startup`. Delete the default scene objects you did not import, and track the difference.
- Hide the glTF importer's helper objects for render. Do not delete them.
- Access F-curves through layers, strips and channel bags (`act.layers[...].strips[...].channelbags[...].fcurves`).
  `act.fcurves` no longer exists.
- Set the mode and the active or selected object before an operator. Re-set them after an operator changes selection.
- Update the view layer (`view_layer.update()`) before reading computed matrices.
- Verify render output, not only scene state. Animation re-evaluation at render time can discard bone-level edits.
- Use `BLENDER_EEVEE` for transparent renders in Blender 5.2. `World.use_nodes` still works in 5.2 but is deprecated.

**Pose and math**
- A rotation and its inverse have the same angle. Angle-only checks miss sign flips. Compare full matrices or positions too.
- Test ground-truth math against a known-good file before you blame the adapter.

**Rendering and cleanup**
- Never edit raw renders. Derived copies only.
- Keep one root pixel per viewport class. Do not recentre each frame.
- Do not resample. Crop and pad. A resample changes the pixel density you measured.
- Check that no alpha is lost when you crop. The check is the alpha sum before and after.
- Labels go outside the cells in review sheets.

**Game integration**
- The adapter reads semantics. It never writes them.
- Show exactly one body. Assert it on every sample.
- Anchor the sprite to the existing shadow point. Do not move gameplay collision or the shadow.
- Keep the scale explicit. Record the render density, the game density and the display scale in one place.
- Label every fallback on screen (idle, unmapped). Never present a fallback as an authored animation.

**Testing and evidence**
- Prove movement with telemetry. A stationary screenshot does not prove an animation.
- Prove the regression set still passes: the existing melee smoke, the animation-set smoke and the Asset V2 family check.
- Publish evidence with the question it answers. Keep the previous bundle until the new one is evaluated.

**Repository hygiene**
- Commit exact paths. Leave other workstreams' files alone.
- `git lfs pull` only the files you need. Keep candidate art out of Git.
- Never run `git checkout .` or `git stash` on a shared checkout. Restore tracked files by explicit path.

---

## 8. Step-by-step runbook: a new character to a playable preview

Each step has a gate. Do not start the next step until the gate passes.

1. **Set up the workstream.** Create it with `workstream.py start`. Work in the worktree. Run `godot --headless --path custodian --import`.
2. **Intake.** Put inputs under `inputs/`. Write `INPUT_MANIFEST.json` with hashes and exclusions. *Gate: every input hashed, every exclusion explained.*
3. **Inspect.** Run the probe (section 5, stage 2). Record scale and unit rule. *Gate: scale, unit and rest-pose match are stated.*
4. **Write the camera contract.** Choose `px/m`, root, canvas and directions. Put them in JSON. *Gate: the contract validates.*
5. **Adapt each motion.** Run `adapt_motion_to_master.py` per action. Exclude any skeleton mismatch with a reason. *Gate: all included actions adapt.*
6. **Verify each derived clip.** Run `verify_derived_pose.py`. *Gate: `pass` and `animates` are true for each included action.*
7. **Render.** Run `measure_render.py --root-mode object` for each action and canvas. Run the registration probe after the offset. *Gate: drift is zero in world space.*
8. **Clean.** Run `alpha_cleanup.py`. *Gate: no stray low-alpha pixels; visible pixels preserved.*
9. **Measure and choose classes.** Compute root-relative extents from alpha. Choose the smallest class per action. Record the root pixel. *Gate: clearance ≥ 4 px for every action.*
10. **Stage.** Run the stager into the gitignored folder. *Gate: counts match and every frame passes the clearance check.*
11. **Review sheets.** Build one sheet per action. *Gate: sheets open and labels are outside the cells.*
12. **Dry-run the review bundle.** Run `publish_review_artifacts.py --dry-run`. *Gate: the selection is what you intended.*
13. **Publish the review.** Upload with `--important` and a question. Record the run ID. *Gate: `status: uploaded`.*
14. **Write the adapter and the mapping.** Implement the adapter and the table in section 10.2. Keep unmapped actions labelled. *Gate: code review confirms the adapter never writes semantics.*
15. **Build the debug scene.** Instance the real playground and the real actors. Add the legacy reference and the candidate. Check key bindings against the input map. *Gate: the scene loads with no parse errors.*
16. **Write the smoke test and register it.** Add it to `validation_manifest.json`. *Gate: 100% of checks pass, and the regression set passes.*
17. **Capture evidence.** Run inspect mode for orientation and close-ups. Run chase mode in the background for telemetry. *Gate: stills confirm orientation, telemetry confirms one body and root-on-shadow.*
18. **Publish gameplay evidence.** Build the board, table, telemetry summary and video. Upload with the chase question. *Gate: uploaded and recorded.*
19. **Document.** Update the design doc with a note that the 3D body is an experimental preview, not a cutover. Write the workstream doc. *Gate: docs state the boundary.*
20. **Commit and stop.** Commit exact paths on the workstream branch. Do not push or merge. Report the branch, the SHA, the launch command, the controls, the tests and the remaining human decision.

**Human decisions that must come after step 20:** whether the candidate reads as properly scaled, readable,
grounded and convincing in play; whether to replace or sit beside the existing body; whether the target
density is 96 px or a new class; and whether production intake is approved.

---

## 9. Acceptance checklist (what "playable in game" means)

A character is **playable in the debug preview** when all of these are true:

- [ ] Inputs hashed; exclusions recorded with reasons.
- [ ] Root-motion removal is object-level, and root registration is verified in the render output.
- [ ] Every included action has a verified derived clip (`pass`, `animates`), with the positional limit recorded.
- [ ] Every frame is staged at a chosen class, with ≥ 4 px clearance and no lost alpha.
- [ ] The real actor (the scene file used in production) detects, pursues and moves; its world position changes.
- [ ] Frames advance during movement; direction follows travel; mapping follows the enemy's own action.
- [ ] Exactly one body is visible on every sample; the legacy body restores exactly when toggled.
- [ ] The visual root sits on the existing contact shadow.
- [ ] Collision, speed, damage and health are unchanged; production scenes do not reference the candidate.
- [ ] The smoke test passes, and so does the regression set.
- [ ] Evidence (telemetry, stills, video, table) is published with the question it answers.
- [ ] Docs state that the body is an experimental preview.

The character is **ready for production intake** only after a separate review, a family and profile contract, and
an explicit approval. None of those are implied by the checklist above.

---

## 10. Known gaps and open items

- **Positional ground truth** is unverified for the Pursuit Frame and the Operator. Rotation and deformation checks pass.
- **Attacks, reactions and deaths are not authored** in the candidate preview. The held locomotion pose shows instead.
- **Idle is a labelled fallback.** No authored 3D idle exists yet.
- **Direction naming** (`S` toward the camera, `E` screen-right) is verified by stills, not by an automated check. Re-check it for each new character.
- **Blob shadow** renders as a flat box in captures. This matches the existing game shadow. Judge its look as a separate art decision.
- **Feet extend below the root** by roughly 10 px at 45° elevation, because the root is the foot centre on the ground plane.
- **The playground's ally drones** log `combat_drone.gd:602` null errors when they fire, because the playground has no `World/Projectiles` node. Not caused by the candidate.
- **The enemy's E/W facing** question in the enemy-presentation packet is still open. It needs its own verification on the legacy sprites.
- **The Pursuit Frame proof scripts** are still outside the repository. Move them under `custodian/tools/character3d/` before reuse.

---

## 11. References

Repository:

- `custodian/AGENTS.md` and `AGENTS.md`: repository rules, ephemeral worktrees, validation routing.
- `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`: lifecycle, claims, landing.
- `custodian/tools/agent/workstream.py`: `start`, `checkpoint`, `finish`.
- `custodian/tools/iteration/publish_review_artifacts.py`: Dropbox review workflow (flags above).
- `custodian/tools/validation/validation_manifest.json`: smoke test registry.
- `custodian/tools/operator/animation_compiler/schemas/batch.v1.schema.json`: example of a camera contract schema.
- `custodian/tools/operator/model_to_sprite/render_static_blender.py`: static render path (`configure_scene`, `set_placement`, `evaluated_bounds`).
- `custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py`: retargeting and render proof path.
- `custodian/game/actors/operator/presentation/operator_body_presenter.gd`: presenter ownership model.
- `custodian/game/actors/enemies/presentation/enemy_animation_set.gd`, `enemy_presentation_controller.gd`: semantic presentation authority.
- `custodian/game/actors/enemies/components/enemy_behavior_profile.gd`: detection values for the Pursuit Frame (vision, cone, awareness bubble).
- `custodian/game/actors/enemies/pursuit_frame.tscn`: the production actor.
- `custodian/docs/ai_context/OPERATOR_3D_BLENDER_PIPELINE.md` (branch `operator-character-master-v1`): Blender API traps, export history, Operator-specific notes.
- `custodian/docs/ai_context/PURSUIT_FRAME_3D_PLAYABLE_PREVIEW_V1.md`: Pursuit Frame preview, controls, evidence and limits.
- `design/02_features/enemies/PURSUIT_FRAME.md`: production design boundary for the Pursuit Frame.

External (proof workspaces, not committed):

- `~/Projects/.operator-3d-animation-proof/pursuit_frame_3d_v1/`: `scripts/adapt_motion_to_master.py`, `verify_derived_pose.py`, `measure_render.py`, `root_motion_audit.py`, `alpha_cleanup.py`, `make_review_sheets.py`, `_driver_derive_verify.sh`, `_driver_render.sh`; `reports/INPUT_MANIFEST.json`, `reports/extents_c512_80_clearance4.json`.
- `~/Projects/.operator-3d-animation-proof/operator_running_scale_probe_v1/`: Operator scripts (`compact_viewports.py`, `export_aseprite.py`, `stage_godot_preview.py`).

External tools and versions:

- Blender 5.2.3 LTS, headless (`blender -b --factory-startup --python ...`).
- Godot 4.7 (project `config/features` pins 4.7). Headless tests: `godot --headless --path custodian --script res://...`.
- FFmpeg (for MP4 encoding of capture frames).
- Git LFS 3.x.
- Python 3 with NumPy and Pillow (stage and review scripts).
