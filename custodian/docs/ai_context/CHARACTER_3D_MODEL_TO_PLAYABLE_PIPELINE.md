# Character 3D Model to Playable Pipeline

Status: **process guide, not an approval.** It describes how a rigged 3D character becomes an
eight-direction 2.5D presentation that the game plays: from a source model, through retargeting and
headless Blender rendering, root removal, cleanup, viewport classification and staging, to a
developer-only Godot preview, validation, and finally a separate Asset V2 approval.

Nothing in this guide promotes an asset to production. Production intake has its own family
contract, review, and approval receipt (section 11).

| Worked example | Status | Where |
|---|---|---|
| Pursuit Frame (existing 2D enemy; 24-joint skin) | Debug preview beside the legacy sprite; 80 px/m frames shown at 0.625 | `custodian/docs/ai_context/PURSUIT_FRAME_3D_PLAYABLE_PREVIEW_V1.md`; scene `custodian/scenes/debug/pursuit_frame_3d_playable_preview.tscn` |
| Operator (Meshy, 24-joint skin) | Debug preview of 80 and 50 px/m candidate sets inside the Awakening scene | `custodian/docs/ai_context/OPERATOR_3D_*` on branch `operator-character-master-v1`; scene `custodian/scenes/debug/operator_3d_playable_preview_awakening.tscn`; smoke `custodian/tools/validation/operator_3d_playable_preview_smoke.gd` |

---

## 1. Reproducibility at a glance

Read this section before trusting any stage. It says what the repository reproduces by itself
and what it does not.

**Repository-owned (committed, runnable from this checkout):**

- `custodian/tools/character3d/` holds every tool the Pursuit Frame workflow runs, plus the
  Operator staging tool. `adapt/adapt_motion_to_master.py`, `adapt/verify_derived_pose.py`,
  `render/alpha_cleanup.py`, `render/root_motion_audit.py` and `review/make_review_sheets.py` are
  byte-identical copies of the proof-workspace scripts. `render/measure_render.py` and
  `stage/operator_stage.py` are repository versions with paths turned into arguments (section 6).
- `custodian/tools/character3d/pipeline.py` is the single driver. `validate_contract.py` and
  `contracts/*.json` describe each character.
- Tests: `custodian/tools/validation/test_character3d_tools.py` (23 unit tests) and the two Godot
  preview smokes.

**External (named, not committed, required to reproduce):** see the register in section 16. The short
form: the Pursuit source GLBs, the Pursuit and Operator proof-workspace outputs, the Operator
probe reports, Blender 5.2.3, Godot 4.7, the LFS sprite content, and Python with NumPy and Pillow.

**Verified in the session that produced this revision (2026-11-09):**

| Check | Result |
|---|---|
| `pipeline.py verify-inputs` on the Pursuit inputs | 12 of 12 `OK` against the recorded SHA-256 |
| `pipeline.py adapt` for `arise` and `running`, scratch workspace | Derived clips byte-identical to the originals (`539badb6…`, `79924d0c…`) |
| `pipeline.py verify` for `running`, scratch workspace | Same pass result, keyframe count (20) and zero failures as the original |
| `pipeline.py render` for `running`, scratch workspace | Metadata identical in every key. 91 of 120 frames pixel-identical; the rest differ by at most 4 of 255 per channel. The same tool run twice gives 90 of 120 and at most 2 (section 1, note) |
| `pipeline.py clean` for `running`, from the original frames | 120 of 120 frames byte-identical |
| `pipeline.py sheets` for `running`, from the original frames | Sheet byte-identical to the original |
| Adapter determinism (three runs) | Identical hashes |
| `validate_contract.py` on `pursuit_frame.v1.json` and `operator.v1.json` | Both `VALID` |
| `test_character3d_tools.py` | 23 of 23 pass |
| `pipeline.py stage` for Pursuit | 11 actions staged at eight directions each; manifest written |
| `pipeline.py stage` for Operator | 4,936 frames staged (4,616 at 80 px/m, 320 at 50 px/m) |
| Pursuit preview smoke | 23 of 23 pass |
| Operator preview smoke | `PASS` |
| Pursuit `agree_gesture` inspect, headless, eight directions × 312 frames (2,496 loads) | No crash (section 13) |

**Renderer determinism.** The Blender renderer is not bit-deterministic. The same render, run twice,
differs by a few units in 255 on some frames, so frame-level equality is the wrong test. The test that
holds is metadata equality plus per-frame pixel differences bounded by the renderer's own run-to-run
variation.

**Not yet reproduced:** the full chain for every action and both characters. The `running` action is
reproduced end to end. Section 14, item 1 tracks the rest.

---

## 2. Goals and boundaries

**Goal.** A reproducible multi-character 3D-to-2.5D development pipeline. A source model goes through
retargeting, rendering, cleanup and classification into staged frames. A character-specific adapter
then plays those frames in a development-only Godot preview that uses the real gameplay systems.
Each stage checks itself and leaves its inputs untouched.

**Boundaries that hold at every stage.**

1. Source files and raw renders are never edited. Derived files are new files whose hashes are recorded.
2. Gameplay authority stays where it is. A candidate body changes **what is drawn**, never **what the actor does**.
3. Candidate art stays out of production paths: the Asset V2 inbox, runtime sprite folders and family
   contracts. Experimental frames are never ingested into an incompatible family.
4. Preview code is developer-only. Production scenes never reference a candidate adapter, and a
   regression test enforces it.
5. Each character keeps its own presentation adapter and stager. Shared tooling covers the geometry
   stages only. Gameplay logic is never copied between characters (section 10).
6. Every headless run writes a report or a completion marker. Trust a result only after reading it.

---

## 3. Glossary and invariants

| Term | Meaning | Rule |
|---|---|---|
| Master | Rigged source character (`.glb`): mesh, skin, skeleton | Read-only. Hash it |
| Motion source | Animation-only `.glb` for one action | Must share the master's joint names and rest transforms |
| Derived skinned clip | Master geometry plus one motion's animation channels | Built by byte copy of the motion's accessors. Never re-keyed |
| Armature scale | Object scale of the imported armature | glTF exports are often centimetre-based (0.01). Measure in world space |
| Root bone | Joint whose horizontal translation is removed so the character stays in place | `Hips` |
| Root registration | Pixel where the world origin (feet on the ground plane) lands | Fixed for every frame in a class (`fixed_per_class`), or set per action (`per_action_pivot`) |
| Canvas | Render size in pixels (for example 256 or 512) | Crop or pad to the viewport. Never resample |
| Render px/m | Pixels per metre in the render camera | Candidate renders: 80 |
| Game px/m | Pixels per metre of the game's sprite space | Pursuit reference: 50 |
| Display scale | Scale applied when a frame is drawn in game | Pursuit: `game px/m ÷ render px/m` = 50 ÷ 80 = 0.625 |
| Canvas class | Fixed viewport size, for example `standard_256x256` | Smallest class where every frame of every action fits with clearance |
| Clearance | Empty margin between silhouette and viewport edge | At least 4 px, measured on alpha |
| Direction | One of eight render azimuths `S SE E NE N NW W SW` | `S` faces the camera; `E` is screen-right; `W` is screen-left. Verify with stills |
| Mirroring | Deriving one side from the other | Forbidden. Every direction is rendered independently |

**Invariants to check, not assume:**

- Root registration: after the render-time offset, the root point's world-space XY drift is zero for every frame.
- No alpha is lost when cropping: the alpha sum before and after placement is identical.
- No visible pixel lies within the clearance margin of a canvas-class edge.
- Transparent pixels carry zero RGB.
- Staged frame counts equal the source sample counts for every direction.

---

## 4. Architecture

### 4.1 Layers

```
 ┌──────── shared geometry tooling: custodian/tools/character3d/ ────────┐
 │ adapt → verify → render (root removal) → clean → sheets               │
 │                       └──────────→ stage (one stager per character)   │
 └─────────────────────────────────────┬─────────────────────────────────┘
                                       │ gitignored custodian/.ai/<char>_*
 ┌─────────── per-character presentation (game, debug only) ─────────────┐
 │ Pursuit: pursuit_frame_3d_candidate_adapter.gd + preview root         │
 │ Operator: operator_3d_playable_preview.gd + operator_3d_preview_catalog│
 └─────────────────────────────────────┬─────────────────────────────────┘
                                       │ reads public semantics only
 ┌──────────── gameplay authority (existing, not modified) ──────────────┐
 │ enemy state machine, EnemyAnimationSet, EnemyPresentationController   │
 │ Operator presenter plan and owner registry (OperatorBodyPresenter)    │
 └──────────────────────────────────────────────────────────────────────┘
```

Keep three game-side responsibilities separate:

1. **Semantics (existing, unchanged).** The actor's state machine and presentation action names decide *what* is presented.
2. **Candidate adapter (debug only, per character).** Reads semantics through public methods, maps them to a staged clip, and draws the frame. It owns no gameplay state.
3. **Staged data.** A versioned manifest and frames. Records geometry, timing and registration.

### 4.2 What is shared and what is per character

| Concern | Shared (`custodian/tools/character3d/`) | Per character |
|---|---|---|
| Adapt, verify, render, clean, sheets | Yes (`adapt/`, `render/`, `review/`) | Inputs only |
| Contract schema and validator | Yes (`contracts/character_contract.v1.schema.json`, `validate_contract.py`) | Contract values (`contracts/<char>.v1.json`) |
| Staging | No. Each stager writes its own format | `stage/pursuit_frame_stage.py`, `stage/operator_stage.py` |
| Presentation adapter | No | `tools/debug/pursuit_frame_3d_candidate_adapter.gd`, or the Operator preview pair |
| Debug scene and controls | No | `scenes/debug/pursuit_frame_3d_playable_preview.tscn`, or the Awakening Operator scene |
| Gameplay logic | Never copied | Stays in the actor |

The two adapters are intentionally different. The Pursuit adapter reads `EnemyPresentationController`
semantics. The Operator preview drives `OperatorBodyPresenter` ownership and an Awakening scene that is
instantiated intact. Merging them now would couple two unrelated presentation models and would not
improve reproducibility.

---

## 5. The character adapter contract

Each character has one contract file: `custodian/tools/character3d/contracts/<character_id>.v1.json`.
It is validated against `contracts/character_contract.v1.schema.json` by `validate_contract.py`. Both
shipped contracts are generated by `contracts/build_contracts.py` from the same reports their stagers
read, so the numbers match the frames that were produced.

### 5.1 Fields

| Concern | Schema field | Meaning and rule |
|---|---|---|
| Model identity | `character_id`, `display_name`, `status` | `status` is `experimental_debug_preview`, `candidate_unapproved`, or `production_approved`. Only the last permits production use, and no contract in this repository uses it |
| Source identity and hashes | `source.master`, `source.motions` | SHA-256 for the master and each motion. An excluded motion has `included: false`, a `null` hash, and a reason |
| Eight-direction ordering | `directions.order`, `azimuth_deg`, `mirroring`, `screen_convention` | Fixed `S SE E NE N NW W SW`, azimuths `0…315`. `mirroring` must be `false`. The screen convention is stated in words |
| Render density and camera | `render.px_per_m`, `elevation_deg`, `projection`, `root_bone`, `root_mode`, `engine` | Orthographic, 45°, 80 px/m, root bone `Hips`, object-level root removal |
| Game density and display scale | `game.px_per_m`, `game.display_scale`, `game.display_scale_rule` | The display scale and the rule that produced it, in words |
| Root pivot policy | `registration.policy`, `registration.rule` | `fixed_per_class` (Pursuit) or `per_action_pivot` (Operator). The rule states how the pivot is used |
| Canvas classes | `canvas_classes[]` | `id`, `width`, `height`, `root_px` (or `null` under a per-action policy), `clearance_px` |
| Animation metadata | `actions.<name>.frame_count`, `sample_count`, `sampling_target_fps`, `authored_frame_range`, `loop` | Recorded from render metadata. `sampling_target_fps` is not an authored frame rate |
| Action semantics | `actions.<name>.status`, `semantic` | `mapped_debug`, `inspect_only` or `unmapped`, with the game action it represents |
| Per-action fit | `actions.<name>.viewport`, `viewport_px`, `root_px`, `clip_fit`, `flags` | Class, root, fit state. `flags` carries review warnings verbatim |
| Staging location | `staging.output_root`, `gitignored`, `manifest_name` | Output must be under `custodian/.ai/` and gitignored |
| External dependencies | `dependencies_external[]` | Every input outside this repository, in words |

### 5.2 Hash verification

`pipeline.py verify-inputs --contract <c> --workspace <w>` hashes each source file named under
`inputs/` and compares it with the contract. Each line is `OK`, `MISMATCH`, `MISSING` or `EXTERNAL`.
`EXTERNAL` means the hint does not point into the workspace, so the owning workspace must check it.
A mismatch or a missing file exits non-zero.

### 5.3 Physical scale: preserved as implemented

Two conventions exist in the repository. Both are preserved, and neither is changed here.

**Pursuit Frame baseline: 0.625 (preserved).** Frames rendered at 80 px/m are drawn at
`50 / 80 = 0.625`. The game reference is 50 px/m, the same as the Operator's runtime 2.5D contract, so
the candidate matches the Operator's physical size in one scene. The adapter's `current_display_scale()`
returns this value, and the smoke test asserts it.

**Operator preview convention (preserved, as implemented).** `operator_3d_playable_preview.gd`
(`_show`) draws 80 px/m frames at scale 1.0. The physical-match toggle (`F6`) draws 50 px/m frames at
`80 / 50 = 1.6`. So the preview's default reference is 80 px/m, not 50. The runtime 2.5D reference for the
Operator is 50 px/m.

**Open decision (not resolved here).** The two conventions disagree about which pixel density is the
Operator's physical reference. Until a decision is recorded, any cross-character size comparison must say
which convention it uses. The Operator contract records `display_scale` as `1.0`, with this discrepancy
written into `display_scale_rule`.

### 5.4 Changing the contract

Change the schema. If you add a JSON Schema keyword, extend `validate_contract.py`: it refuses any keyword it
does not implement rather than skipping it. Add a test, and regenerate the contracts with
`build_contracts.py`.

---

## 6. Repository organization

```
custodian/tools/character3d/
  pipeline.py                  single driver: verify-inputs, adapt, verify, render, clean, sheets, stage, validate
  validate_contract.py         dependency-free validator for the v1 schema
  adapt/
    adapt_motion_to_master.py  byte-copies motion accessors into the master (copy of the proof script)
    verify_derived_pose.py     pose invariants against the source motion (copy)
  render/
    measure_render.py          object-level root removal and orthographic render (copy)
    root_motion_audit.py       root-motion numerical audit (copy)
    alpha_cleanup.py           derived cleanup with alpha checks (copy)
  review/
    make_review_sheets.py      one sheet per action, labels outside the cells (copy)
  stage/
    pursuit_frame_stage.py     Pursuit viewports, clearance and manifest (moved from tools/debug, history kept)
    operator_stage.py          Operator 80/50 px/m staging (repository copy; paths are arguments)
  contracts/
    character_contract.v1.schema.json
    pursuit_frame.v1.json
    operator.v1.json
    build_contracts.py
custodian/tools/debug/
  pursuit_frame_3d_candidate_adapter.gd, pursuit_frame_3d_playable_preview.gd, pursuit_frame_3d_capture.gd
  operator_3d_playable_preview.gd, operator_3d_preview_catalog.gd, operator_3d_preview_sprite.gd
custodian/scenes/debug/
  pursuit_frame_3d_playable_preview.tscn, operator_3d_playable_preview_awakening.tscn
custodian/tools/validation/
  pursuit_frame_3d_playable_preview_smoke.gd, operator_3d_playable_preview_smoke.gd
  operator_3d_playable_motion_capture.gd, operator_3d_playable_preview_capture.gd
  test_character3d_tools.py
custodian/.ai/   gitignored staged output: pursuit_frame_3d_preview/, operator_3d_animation_preview/
```

**Naming.** Actions use `snake_case`, matching the source file stem. Directions are uppercase in the fixed
order. Frames are `frame_NN.png`, zero-based. Staged viewport folders are
`<class_id>/<action>/<direction>/frame_NN.png`. Reports are `measure_<action>_c<canvas>_<ppm>.json` and
`<action>_derived_verification.json`. Workstream IDs are lowercase kebab-case with a version suffix.

**What the copies changed.** Three files differ from their sources; the rest are byte-identical.

- `pursuit_frame_stage.py` is the original stager, moved with history kept.
- `operator_stage.py` was copied from `operator_running_scale_probe_v1/scripts/stage_godot_preview.py`.
  The hard-coded `REPO = ~/Projects/CUSTODIAN` and its probe and batch paths became the `--repo`,
  `--probe` and `--batch` arguments. The original wrote into the coordination checkout.
- `measure_render.py` derived its master from its own location (`parents[1]`). That works in the
  proof workspace and fails in the repository, where it resolves to the wrong folder. The master is
  now the `--master` argument, which the driver always passes. A regression test forbids the pattern.

The driver also runs `adapt` from inside the workspace with relative paths (section 7, stage 3).

---

## 7. Workflow: source model to staged frames

Use the driver. Every stage accepts `--dry-run`, which prints the exact commands and runs nothing.
Commands use `W` for the workspace and `C` for the contract. `--action` limits a stage to named
actions, and `--canvas` overrides the canvas for render, clean and sheets.

```bash
C=custodian/tools/character3d/contracts/pursuit_frame.v1.json
W=~/Projects/.operator-3d-animation-proof/pursuit_frame_3d_v1
python3 -I custodian/tools/character3d/pipeline.py verify-inputs --contract $C --workspace $W
python3 -I custodian/tools/character3d/pipeline.py adapt    --contract $C --workspace $W [--action arise]
python3 -I custodian/tools/character3d/pipeline.py verify   --contract $C --workspace $W
python3 -I custodian/tools/character3d/pipeline.py render   --contract $C --workspace $W [--canvas 512]
python3 -I custodian/tools/character3d/pipeline.py clean    --contract $C --workspace $W
python3 -I custodian/tools/character3d/pipeline.py sheets   --contract $C --workspace $W
python3 -I custodian/tools/character3d/pipeline.py stage    --contract $C --workspace $W
python3 -I custodian/tools/character3d/pipeline.py validate --contract $C
```

The Operator stage takes its own arguments:

```bash
python3 -I custodian/tools/character3d/pipeline.py stage \
  --contract custodian/tools/character3d/contracts/operator.v1.json \
  --workspace ~/Projects/.operator-3d-animation-proof/operator_running_scale_probe_v1 \
  --batch ~/Projects/.operator-3d-animation-proof/operator_sprite_batch_v1
```

### Stage 1: Intake

Place sources under `inputs/`, keep their names, and hash them into `reports/INPUT_MANIFEST.json`.
Record every exclusion with its reason. *Gate:* `verify-inputs` returns no `MISMATCH` or `MISSING`, and
every exclusion has a reason.

### Stage 2: Inspect in headless Blender

Load one clip and print the armature scale, then the same quantity in local and world space. If the scale
is about 0.01, report world-space values only and label units. Confirm the rest pose matches the master by
joint names and rest transforms. Compare glTF-level data, not Blender bone matrices against empty matrices.
That comparison produced a false "21 of 24 mismatch" in the Operator work.

*Gate:* the scale, the unit rule and the rest-pose match are each stated in one sentence.

### Stage 3: Retarget (adapt)

`adapt/adapt_motion_to_master.py` copies each motion's raw accessor bytes into the master's binary chunk,
rebases buffer views and accessors, and keeps node indices. Mesh, skin and nodes are untouched. Its
functions are `read_glb`, `write_glb`, `bytes_of_accessor`, `check_identical_skeleton` and `main`.

The adapter records its input path in `extras.derived_from_motion.path`. The driver therefore runs it from
inside the workspace with relative paths. Absolute paths change the output hash for identical content. This
was found by reproduction in the session that produced this revision, and `pipeline.py` now passes relative
paths.

*Gate:* every included action adapts, `check_identical_skeleton` passes, and a repeat run gives the same hash.

### Stage 4: Verify the pose

`adapt/verify_derived_pose.py` runs in Blender against the original motion and writes
`reports/<action>_derived_verification.json`. Its helpers are `floats`, `trs_at`, `node_local`, `gt_world`
and `invariants(delta)`, which returns a rotation angle and a translation length.

What the checks prove: rotation and deformation agree with the source for each sampled key. For the Pursuit
Frame the errors were about 1e-6 to 1e-5 rad. What they do not prove: joint **positions** against an
independent ground truth. The Operator notes record that the positional check disagreed even on a known-good
file, so that check had a bug in its ground-truth math, not in the adapter. Stronger evidence is the
transparency test, in which the derived clip reproduces the original's pose matrices and evaluated vertices.

*Gate:* every included action has `pass: true` and `animates: true`, and the positional limit is recorded.

### Stage 5: Render with object-level root removal

`render/measure_render.py --root-mode object --master <workspace>/inputs/character_master.glb` removes the
root's horizontal translation at the object level, not the bone level:

```python
delta_arm = Vector((rest_head.x - head_arm.x, rest_head.y - head_arm.y, 0.0))
arm.location = Vector((delta_arm.x * arm.scale.x, delta_arm.y * arm.scale.x, 0.0))
```

A bone-level location change is discarded when the render re-evaluates the animation. That caused a real defect
in the Pursuit work: the correction was dropped while the metadata claimed it was applied. Always use `object`.
Other functions: `fcurves_of`, `camera_for(azimuth_deg, cam)`, and the inner `pose_snapshot`. For orthographic
side views use `direction.to_track_quat("-Z", "Y")`. Using `"Z"` as up rolls the camera 90° at side azimuths.

**Verify registration after the offset.** Apply the same offset in a probe and confirm the world-space root
point stays fixed. The Pursuit probe measured 0.0 m drift after the offset, against 0.47 m before it.

**Metadata caveat.** Fields ending in `_m` are in armature-local units when the armature scale is 0.01. The
Pursuit metadata reported `endpoint_max_bone_head_delta_m: 170.7`, which is 1.707 m in world space. Convert, or
record world-space values, before publishing a unit-labelled number.

*Gate:* the probe's world-space drift is zero, and every action has a folder per direction with a frame per sample.

### Stage 6: Clean

`render/alpha_cleanup.py` writes derived copies with RGB zeroed where alpha is 0. Visible pixels are checked for
exact identity. Its functions are `clean_array`, `silhouette_mask` (alpha ≥ 8 grown by 2 px, to find stray
specks), `process` and `main`. Its report includes `low_alpha_px_outside_silhouette`, which should be zero.

*Gate:* visible pixels are preserved and stray low-alpha pixels are zero.

### Stage 7: Classify viewports and stage

Compute root-relative extents from alpha for every frame and direction, keep the maxima, add the clearance, and
choose the smallest canvas class that holds every frame of the action.

```python
ys, xs = np.nonzero(alpha > 0)
left = root_x - xs.min();  right = xs.max() - root_x
up = root_y - ys.min();    down = ys.max() - root_y
```

`stage/pursuit_frame_stage.py` makes the choice in `choose_class`, using `place` (pixel-exact crop and pad) and
`clearance_ok`. It writes `custodian/.ai/pursuit_frame_3d_preview/manifest.json`, with each action's viewport,
root, frame counts, sampling target and source hashes.

Pursuit result: 10 of 11 actions fit `standard_256x256` with root `(128, 180)`. `behit_flyup` (286 px tall) needs
`extended_256x320` with root `(128, 216)`. At 80 px/m the existing 96×96 enemy canvas fits none of the 11 actions,
and would need roughly 27 to 47 px/m. The target density is therefore an explicit decision, not a default.

The Operator stage works differently by design. It places each action at its own pivot from the external review
report (`per_action_pivot`). It also copies review `flags` such as `ROOT MOTION UNREVIEWED` and
`SEMANTIC REVIEW PENDING` into the staged metadata. Those flags must be cleared before any approval.

*Gate:* every action has a class or pivot. Pursuit actions have at least 4 px of clearance, and staged counts match
the source counts.

### Stage 8: Review sheets

`review/make_review_sheets.py` writes one sheet per action: eight directions by six evenly spaced frames, at
native 1:1 pixels, with labels in a margin outside the cells. Run it per canvas. Edge-clipped actions use the
larger canvas, and the canvas is part of the file name.

Publish the bundle with `custodian/tools/iteration/publish_review_artifacts.py`:

1. `--doctor --remote git-dropbox-sync`
2. `--source <absolute dir>`, one `--artifact` per file, and an explicit `--max-files`
3. `--dry-run` first, and check the selection
4. Add `--important --reason "<why subjective review is needed>" --question "<question>"` only when objective checks cannot settle it. Add `--include-video` only for motion.
5. Retention defaults to `delete-after-review`. Say so in the handoff.

*Gate:* the dry run selects what you intended, and the upload returns `status: uploaded` with a run ID.

---

## 8. Game-side presentation (debug only)

### 8.1 The contract with existing presentation

The game already exposes what the enemy is doing. Read it; do not replace it.

| Public API | Returns | Use |
|---|---|---|
| `enemy.get_enemy_presentation_action()` | `StringName`, such as `&"locomotion.run"` | Map to a candidate clip |
| `enemy.get_last_move_direction()` | `Vector2` facing | Direction when stationary |
| `enemy.velocity` | `Vector2` | Travel direction when moving |
| `enemy.get_enemy_presentation_frame()`, `get_enemy_presentation_animation()` | Legacy frame and name | Diagnostics only |

`EnemyAnimationSet` (`resolve_clip`, `build_sprite_frames`, `get_animation_name`) and
`EnemyPresentationController` (`play`, `select_normal_attack`, `select_flinch_for_severity`, `select_flavor`) own
semantic names and clip choice. The candidate adapter never calls `play` and never changes the clip.

### 8.2 Pursuit Frame adapter

`custodian/tools/debug/pursuit_frame_3d_candidate_adapter.gd`, class `PursuitFrame3DCandidateAdapter`, is attached
as a child of a real `pursuit_frame.tscn` actor.

| Function | Role |
|---|---|
| `_ready()` | Finds the enemy, loads the manifest, records legacy visibility, creates the `Candidate3DBody` sprite, opens telemetry, applies presentation |
| `_load_manifest()` | Reads `res://.ai/pursuit_frame_3d_preview/manifest.json`; fails if missing |
| `advance(delta)` | Resolves one tick. Public so tests can apply a change immediately |
| `_resolve()` | The mapping table (section 8.3) |
| `_travel_direction()`, `_compass(v)` | Velocity or last facing, reduced to one of eight names |
| `_update_frame(clip, dir, static, loops)` | Frame index from time × FPS; loops or clamps; applies offset and scale |
| `_texture_for(clip, dir, index)` | Loads one PNG with `Image.load_from_file`; caches up to 48 textures |
| `current_display_scale()` | `1.0` for native, else `50 / 80` (section 5.3) |
| `_apply_presentation()` | Shows exactly one body; restores legacy visibility exactly when turned off |
| `_write_telemetry()` | One JSON line per tick |
| `visible_body_count()` | Must be exactly one |

The sprite's `offset` is `-root_px`, so the root pixel lands on the blob-shadow centre `(0, 13)`. Move the sprite,
never the shadow.

The debug root `pursuit_frame_3d_playable_preview.gd` instances the real combat playground, removes its grunts, and
spawns a legacy reference and a candidate under the same conditions. Both start inside the Pursuit Frame's 225 px
awareness bubble, so detection can happen. Its controls use keys the project does not already bind: `F1`, `Enter`,
`[ ]`, `, .`, `; '`, `- =`, `N`, `/`, `F12`.

### 8.3 Pursuit mapping table

| Enemy action | Candidate clip | Rule |
|---|---|---|
| `locomotion.run`, `locomotion.relaxed_run` | `running` (loop) | Chase |
| `locomotion.walk`, `locomotion.relaxed_walk` | `walking` (loop) | Walk |
| `posture.alert` | `alert` (plays once, holds last frame) | Alert |
| `locomotion.ready_idle`, `locomotion.relaxed_idle`, empty | Idle fallback: static walk frame 0, labelled | No authored idle yet |
| Anything else | Unmapped: holds the last mapped pose, labelled | Attacks and reactions are not authored |

### 8.4 Operator preview

The Operator preview is a different design, and its reference is the existing code.

- `custodian/tools/debug/operator_3d_playable_preview.gd` instantiates the real Awakening scene intact. It keeps the
  real Operator's movement, input, collision, camera and shadow, and pauses only the per-frame sprite presentation on
  that instance. The 3D candidate is claimed through `OperatorBodyPresenter` as the single visible body.
- `operator_3d_preview_catalog.gd` is a preview-only reader of `res://.ai/operator_3d_animation_preview`. It exposes
  `meta`, `has_action`, `frame_count`, `pivot`, `frame_size`, `loop`, `texture` and `direction_for_velocity`. It is
  not a production SpriteFrames database and not an animation authority.
- `OperatorBodyPresenter` ownership functions (`register_body_layers`, `claim_modular`, `release_modular`, `present`,
  `can_present`) are unchanged by the preview.
- Controls: `F3` preview on or off, `F4` inspect, `F5` 80/50 px/m, `F6` physical match, `[ ]` action, `; '` direction,
  `, .` frame, `SPACE` pause, `- =` FPS.

Its validation is `custodian/tools/validation/operator_3d_playable_preview_smoke.gd`. Its capture drivers are
`operator_3d_playable_preview_capture.gd` and `operator_3d_playable_motion_capture.gd`.

### 8.5 Telemetry

The Pursuit adapter writes one JSON object per tick, enabled by `godot ... -- --pf3d-telemetry=<abs path>`. Fields:
`tick`, `presentation`, `mode`, `legacy_action`, `clip_3d`, `direction`, `frame`, `fps`, `label`, `position`,
`velocity`, `root_global`, `shadow_global`, `visible_body_count`, `display_scale`, `paused`.

---

## 9. Validation

Run every item and record the result, not just the exit code.

| Level | Command | Proves |
|---|---|---|
| Contract | `python3 -I custodian/tools/character3d/validate_contract.py <contract>` | Schema conformance |
| Unit (tools) | `python3 -I custodian/tools/validation/test_character3d_tools.py` | Contract rejection cases, placement, clearance, class choice, stager path handling, driver planning, hash verification, staged-manifest consistency |
| Pursuit smoke | `godot --headless --path custodian --script res://tools/validation/pursuit_frame_3d_playable_preview_smoke.gd` | Real actor identity, detection and chase, frame advance, direction, grounding, one body, A/B, viewport choice, unchanged collision, speed and damage |
| Operator smoke | `godot --headless --path custodian --script res://tools/validation/operator_3d_playable_preview_smoke.gd` | Operator preview behaviour, as its own file defines it |
| Regression | `godot --headless --path custodian --script res://tools/validation/standard_enemy_melee_smoke.gd`; `pursuit_frame_animation_set_smoke.gd`; `python3 -I custodian/tools/validation/pursuit_frame_asset_family_smoke.py` | Production enemy behaviour and the 96 px family are unchanged |
| Windowed | `godot --path custodian --script res://tools/debug/pursuit_frame_3d_capture.gd -- --pf3d-mode=inspect ...` | Orientation and contact stills, which headless runs cannot produce |

Before running Godot in a fresh worktree:

1. `git lfs pull -I "custodian/content/sprites/**"`. A file a few hundred bytes long is an LFS pointer, not content.
2. `godot --headless --path custodian --import`. Without this, `class_name` lookups fail and scripts report parse errors that are not code errors.
3. Stage the frames (section 7). Otherwise the smokes fail with "staged manifest missing".

Register every new smoke in `custodian/tools/validation/validation_manifest.json`. Python tests use `"type": "python"`.

**Gotchas from this work.**

- In a smoke test, call `adapter.advance(0.0)` after a state change. Physics ticks and process frames are not in step.
- A coroutine that is not awaited returns before its checks run, and the test then quits early. Await every step.
- Place actors inside the detection rules: vision 300 px in a 118° cone, and an awareness bubble of 225 px. Read the profile values rather than guessing.
- The playground's ally drones log `combat_drone.gd:602` null `add_child` errors when they fire. The playground has no `World/Projectiles` node, and the preview is not the current scene. The candidate does not cause this.
- Do not use `pkill -f <pattern>` to stop a run. The pattern can match your own shell command. Stop by PID.

---

## 10. Adding a third character

Add a character by implementing its own parts. Do not copy another character's gameplay logic.

1. Create `custodian/tools/character3d/contracts/<id>.v1.json` with a builder in the style of `build_contracts.py`, and validate it.
2. Run the shared stages with `pipeline.py adapt`, `verify`, `render`, `clean` and `sheets`. Add a row to the external-dependency register for every input outside the repository.
3. Write `custodian/tools/character3d/stage/<id>_stage.py`. Choose the registration policy first, because it decides the output format. Register the stager in `pipeline.py`'s `STAGERS` map. Do not reuse another character's stager.
4. Write `custodian/tools/debug/<id>_candidate_adapter.gd`, reading only the semantic API of its own actor. Map only validated actions, and label every fallback.
5. Write `custodian/scenes/debug/<id>_3d_playable_preview.tscn` around a real scene with the real actor. Check the input map before you choose keys.
6. Write a headless smoke and register it. Assert the properties the Pursuit smoke asserts: real actor identity, movement, grounding, one body, reversibility, and unchanged gameplay values.
7. Add the character to the table of worked examples at the top of this guide.

**What not to copy:** state machines, damage, detection values, navigation, collision, timing, and presentation
controllers. These belong to the character's own actor. An adapter that re-implements any of them is a bug.

---

## 11. Asset V2 approval (production gate, not automated here)

Nothing in this guide ingests a candidate. A character reaches production only through its own workstream, after
these gates. Each one is a stop.

1. **Family contract.** The target family must exist and be registered. The Pursuit Frame production family is
   `custodian/content/metadata/assets/families/pursuit_frame.asset.json`: 96×96 frames, four directions, mirroring.
   The 256 px, eight-direction candidates are **incompatible** with that contract and must not be placed in it. A
   new profile needs its own migration.
2. **Human-named inbox.** The preferred human intake is `custodian/asset_drop/inbox/<family>/`, per
   `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md`. `custodian/content/sprites/_pipeline/inbox/` is the expert backend
   for generated manifests. Use it only when the cheat sheet directs you there.
3. **Approval receipt.** `custodian/AGENTS.md` requires an explicit review receipt that pins the immutable SHA-256 and
   state mapping before ingest. A Dropbox archive or a legacy `active` status is not approval.
4. **Checks.** `custodian/tools/assets/asset.py plan`, `status`, `doctor` and `needs --check`, plus consumer checks and
   the focused scene tests.
5. **No review media in runtime.** Review sheets, videos and telemetry are evidence. Never copy them into runtime paths.

**Current status of the two previews:** neither is approved. The Pursuit candidate is `experimental_debug_preview`. The
Operator candidate is `candidate_unapproved`, carries open review flags (`ROOT MOTION UNREVIEWED`,
`SEMANTIC REVIEW PENDING`), and has an unresolved physical-scale convention (section 5.3).

---

## 12. Rollback

Every change in this work is additive, except one file that was moved and two that were edited.

| Scope | Rollback |
|---|---|
| Preview code and docs | Revert the commits that added them. They are listed in the workstream report |
| Stager move | `git mv custodian/tools/character3d/stage/pursuit_frame_stage.py custodian/tools/debug/pursuit_frame_3d_stage.py`, then revert the docs references |
| Staged frames | Delete `custodian/.ai/pursuit_frame_3d_preview/` and `custodian/.ai/operator_3d_animation_preview/`. They are gitignored and regenerable |
| Validation registration | Remove the two preview entries and `character3d_tools_unit` from `validation_manifest.json` |
| Production files | None are changed by this work. Confirm with `git diff origin/main -- custodian/content/metadata custodian/game` before any push |

Rollback is a commit-level revert on the workstream branch. Do not run `git checkout .`, `git reset --hard` or
`git stash` on a shared checkout. Restore single files by explicit path.

---

## 13. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `class_name` not found; many parse errors on first run | Class cache not built in a fresh worktree | `godot --headless --path custodian --import` |
| A file a few hundred bytes long where a PNG should be | LFS pointer, not fetched | `git lfs pull -I "<path>"` |
| "Staged candidate manifest missing" | Stage step not run in this checkout | `pipeline.py stage` for the character |
| `verify-inputs` reports `MISMATCH` | The source changed, or it is a different download | Stop. Re-acquire the source and compare it with `INPUT_MANIFEST.json` |
| Derived clip hash differs from the workspace | Absolute and relative input paths produce different provenance | Run `adapt` from the workspace with relative paths (the driver does this) |
| Render metadata labelled `_m` looks 100× too large | Armature-local units, armature scale 0.01 | Convert with the armature scale, or use world space |
| Hips drift after render | Bone-level root correction is discarded at render | Use `--root-mode object` |
| Render fails with `Error: Please select a file` | `measure_render.py` cannot find its master (it was once derived from the script's own location) | Pass `--master`. The driver does this; the regression test guards the pattern |
| Rendered frames differ slightly from the originals | Renderer run-to-run variation (section 1) | Compare metadata exactly and pixels within the variation bound, not byte for byte |
| `operator_stage.py` wrote into the coordination checkout | Old hard-coded `REPO` path | Pass `--repo` the worktree root (the driver does this) |
| Smoke fails at `behit_flyup uses the 256x320 viewport` | Inspect clip not advanced before the check | Call `adapter.advance(0.0)` first |
| `ERROR: N resources still in use at exit` after a headless run | Scene not freed before `quit` | Harmless for a passing run. Free nodes to silence it |
| `add_child` on null in `combat_drone.gd:602` | Playground ally-drone fallback path | Not caused by the candidate. See section 9 |
| Windowed capture very slow | Software renderer plus per-frame PNG saves | Run in the background with `nohup`, and poll the output folder |

**`agree_gesture` crash (reported).** The report did not include a log, steps, or mode. In this revision the inspect path
was reproduced headlessly: `agree_gesture` was stepped through all eight directions and all 312 frames (2,496 texture
loads) with no error, and the texture cache held at its 48-texture limit. A windowed repeat of the same stepping was
started; its result is recorded in the workstream report, not here.

To investigate a recurrence, collect: the mode (inspect or gameplay), the exact key sequence, whether the enemy was
chasing, the Godot version, the full log, and whether it happens headlessly or only in a window. `agree_gesture` is
inspect-only, so gameplay should never load it. If a gameplay path does load it, that is the first thing to check.

---

## 14. Recommended next steps and best practices

**Next steps for reuse, in order.**

1. **Gate: reproduce the full chain for every action.** `running` passes end to end (section 1). Run the same
   comparison for the other ten Pursuit actions, then for the Operator, whose render and cleanup are still external.
2. Give the Operator a render and cleanup stage in the repository, so its chain stops depending on the external probe
   scripts (`compact_viewports.py`, `render_operator_scale.py`, `measure_render.py`, `alpha_cleanup.py`,
   `root_motion_audit.py` and `stage_godot_preview.py` in its probe workspace).
3. Decide the Operator's physical reference (section 5.3) and record it in its contract.
4. Move the proof manifests (not the GLBs) into the repository as data, so hashes can be reviewed.

**Source and data.** Hash every input before you touch it. Check the armature scale on every import, and assume
centimetres until you have measured. Validate a new checker on a known-good file first. Record each exclusion
with its reason.

**Blender (headless, 5.x).** Start with `-b --factory-startup`, and track the default objects you delete. Hide
importer helpers rather than deleting them. Read F-curves through layers, strips and channel bags. Set mode and
selection before operators, and update the view layer before reading matrices. Check render output, not only scene
state. Use `BLENDER_EEVEE` for transparent renders.

**Pose and math.** A rotation and its inverse share an angle, so angle-only checks miss sign flips. Compare full
matrices or positions too.

**Rendering and cleanup.** Never edit raw renders. Keep one root per fixed class, or one pivot per action where the
policy says so, and never recentre silently. Crop and pad; do not resample. Check alpha before and after each crop.
Keep labels outside cells.

**Game integration.** The adapter reads semantics and never writes them. Assert exactly one visible body on every
sample. Anchor to the existing shadow. State the scale in one place. Label every fallback on screen.

**Evidence.** Prove movement with telemetry, not with a stationary screenshot. Prove the regression set still passes.
Publish each piece of evidence with the question it answers.

**Repository hygiene.** Commit exact paths. Leave other workstreams' untracked files alone. Pull only the LFS files you
need. Keep candidate art out of Git. Stop processes by PID.

---

## 15. Known gaps and open decisions

- **Operator physical reference** (section 5.3): 50 px/m runtime versus the 80 px/m preview default. Open.
- **Operator render and cleanup chain** is external (section 14, item 2).
- **Full chain reproduction** is shown for the Pursuit `running` action only (section 14, item 1).
- **Renderer determinism:** EEVEE output varies by a few units in 255 between runs (section 1).
- **Positional ground truth** is unverified for both characters. Rotation and deformation checks pass.
- **Attacks, reactions and deaths** are not authored in the Pursuit candidate. The held locomotion pose shows instead.
- **Idle** is a labelled fallback for Pursuit. There is no authored 3D idle.
- **Direction naming** (`S` toward the camera, `E` screen-right) is verified by stills for Pursuit only. Re-check per character.
- **Blob shadow** draws as a flat box in captures. This matches the existing shadow, and its look is an art decision.
- **Feet extend about 10 px below the root** at 45° elevation, because the root is the foot centre on the ground plane.
- **Operator review flags** (`ROOT MOTION UNREVIEWED` on `dead` and `triple_combo_attack`; `SEMANTIC REVIEW PENDING` on
  `skill_01` and `skill_03`) are open.
- **Pursuit target density** (96 px family versus 256 px candidates) is an open decision.
- **Enemy E/W facing** in the enemy-presentation packet is still open. It needs verification on the legacy sprites.

---

## 16. External dependency register

Everything this pipeline cannot produce from the repository:

| # | Input | Needed by | Location | Checked by |
|---|---|---|---|---|
| 1 | Pursuit master and 11 motion GLBs | adapt, verify, render | `~/Downloads/PursuitFrame3D/` | `verify-inputs` |
| 2 | Pursuit workspace outputs (derived, measure, clean) | stage, sheets | proof workspace `pursuit_frame_3d_v1/` | Re-run with `pipeline.py` |
| 3 | Operator probe reports and clean frames | Operator stage | `operator_running_scale_probe_v1/` | Not verified by the repository |
| 4 | Operator batch `INPUT_MANIFEST.json` | Operator stage and contract | `operator_sprite_batch_v1/reports/` | Hashes recorded in the contract |
| 5 | Operator master GLB | Operator source identity | Git LFS, branch `operator-character-master-v1` | SHA-256 in the contract |
| 6 | Blender 5.2.3 LTS | verify, render, root audit | System | Version in render metadata |
| 7 | Godot 4.7 | previews and smokes | System | `project.godot` |
| 8 | LFS sprite content | previews | Git LFS cache | Pointer-size check |
| 9 | NumPy and Pillow | stagers, sheets, clean | System Python | Import at run time |

---

## 17. References

Repository (committed):

- `custodian/AGENTS.md`: repository rules, worktrees, asset ingest approval (around lines 132–134).
- `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md`: Asset V2 inbox convention and the expert backend path.
- `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`: workstream start, checkpoint and finish.
- `custodian/tools/agent/workstream.py`: `start`, `checkpoint`, `finish`.
- `custodian/tools/iteration/publish_review_artifacts.py`: review bundle flags.
- `custodian/tools/assets/asset.py`: `plan`, `status`, `doctor`, `needs --check`.
- `custodian/tools/validation/validation_manifest.json`: smoke registry.
- `custodian/tools/operator/animation_compiler/schemas/batch.v1.schema.json`: an earlier camera-contract schema.
- `custodian/tools/operator/model_to_sprite/render_static_blender.py`: static render reference.
- `custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py`: retargeting and render proof.
- `custodian/game/actors/operator/presentation/operator_body_presenter.gd`: presenter ownership model.
- `custodian/game/actors/enemies/presentation/enemy_animation_set.gd` and `enemy_presentation_controller.gd`: semantic presentation authority.
- `custodian/game/actors/enemies/components/enemy_behavior_profile.gd`: Pursuit detection values.
- `custodian/game/actors/enemies/pursuit_frame.tscn`: production actor.
- `custodian/docs/ai_context/PURSUIT_FRAME_3D_PLAYABLE_PREVIEW_V1.md`: Pursuit preview evidence and limits.
- `custodian/docs/ai_context/OPERATOR_3D_BLENDER_PIPELINE.md` (on branch `operator-character-master-v1`): Operator Blender notes.
- `design/02_features/enemies/PURSUIT_FRAME.md`: production design boundary for the Pursuit Frame.

External, not committed: see section 16.
