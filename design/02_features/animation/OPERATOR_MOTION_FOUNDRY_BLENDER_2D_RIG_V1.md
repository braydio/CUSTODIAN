# Operator Motion Foundry: Blender 2D Cutout Authoring V1

- Status: approved tool-authoring slice; **no Blender Operator rig implemented yet**
- Reviewed main: `82892c37eaec466f59b58e8df52cb36e3a75a1e5`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Nature: **2D image-plane / cutout authoring**, **not** 3D character modeling, 3D gameplay, a replacement Operator art design, or runtime animation.
- Input authority: `custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/` after `operator-motion-foundry-south-rig-sourcework-v1` lands. Source-work is not human-approved 2.5D animation art.
- Existing Blender technical precedent: `custodian/tools/art/broken_warrant_3d/{build_materials,render_pixel_proof,assemble_pixel_proof}.py` and README; reuse version-compatible background scripting, PNG metadata normalization, input pinning and reports but **not the 3D model or its shaders/rig**.
- Existing animation authority: `design/02_features/animation/CUSTODIAN_MOTION_FOUNDRY_V1.md`, `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`, and `custodian/tools/operator/motion_foundry/rig.py`.

## Goal and input contract

Transform the already-extracted **south-view Operator**, not the AI illustration, into one **editable, usable 2D puppet** in Blender. This is an offline working-artifact proof independent from MF1's publication/review gate. It should open in Blender with understandable named controls and a safe 15-frame idle blocking test.

Inputs after predecessor:
- `extracted/rig.json` carrying `custodian.motion_foundry.rig.v1`, an ordered list of `parts` with `id`, `source`, `sha256`, `pivot`, `parent`, `draw_order`, `movable`.
- `extracted/hierarchy_and_overlap.json` with distinct semantic/draw/occlusion annotations, authoritative for reviewing *how to rig*, not approval to synthesize hidden art.
- `extracted/parts/*.png`, **23 full 128×128 RGBA cells**, 18 visible original-pixel cutouts plus 5 transparent placeholders. All original pixels are in absolute source-frame coordinates, not cropped around pivots.
- Original south frame = index 4 zero-based from `source/CUSTODIAN_OPERATOR_RUNTIME_REFERENCE_128.aseprite` (8 directional reference frames, **not** an 8f animation).
- Root (64,106), floor (64,107), exact 2,440 visible pixels, zero-loss neutral 23-layer reassembly.
- Authored FPS: **null**. Preview rates are noncanonical and labeled preview-only.

## Blender representation

- Place **one** image-plane object per nonempty part, textured from the original source PNG with nearest-neighbor filtering, emission/unlit material and alpha; camera is orthographic, front-on, fixed, with transparent RGBA 128×128 output. No lights, shadows, perspective camera, pixel interpolation, color modification, face artwork, global flips or false 3D geometry.
- Build a **named 2D armature** from the explicit part IDs, with correct root-space hierarchy, per-part pivots and configurable inter-part draw depth; do not infer a new anatomy hierarchy from names when the source JSON already declares parents. Verify acyclic graph; do not parent missing parts silently.
- Preserve absolute source-pixel placement with explicit pivot-to-object origin calculation. Maintain world transforms when binding each plane to its bone and verify the rest-pose **Blender-rendered** 128×128 RGBA frame against the authoritative south source via real image/pixel comparison. Do not infer success solely from the unchanged input PNGs. If Blender shading/color-management/alpha behavior prevents exact agreement, diagnose/fix rather than relax the neutral-image gate.
- Deliberately empty parts may have documented/disabled nondeforming guide controls but **may not** acquire invented geometry, floating scraps, fake underpaint or hidden pixel art.
- Provide clear viewport organization: names, near/far controls, collection visibility, front-ortho camera, rig root, zero/reset pose. The user should be able to select a bone/control, pose visible parts and save the Blend; the renderer should export from that **same saved** editable source.
- Initial motion = bounded **15-frame south-facing idle proof**, no authored FPS or combat logic. Root and both visible planted feet remain fixed; torso/head/arms/tabard are allowed at most subtle keyed changes only when their separated surfaces can maintain credible seams. Use few pose keys and interpolation; do not force unseen rear cape, pelvis or upper thigh parts to move. If a convincing motion cannot avoid holes, preserve working rig and report specific seam/underpaint blockers rather than fabricated acceptance.
- Joint rotations and translations are Blender *authoring-only* pose controls, explicitly **not** MF1's integer-only translation model. Never silently write Blender-pose data into `custodian.motion_foundry.motion.v1` without a documented, reviewed conversion.

## Paths and artifacts

Tracked scripts created by task:
- `custodian/tools/operator/motion_foundry/blender/build_operator_2d_rig.py`
- `custodian/tools/operator/motion_foundry/blender/render_operator_2d_rig.py`
- `custodian/tools/operator/motion_foundry/blender/README.md`
- `custodian/tools/validation/operator_motion_foundry_blender_2d_smoke.py`
- Update `custodian/tools/validation/validation_manifest.json` for focused ownership.

Source-work outputs (working art only):
- `custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/blender/operator_south_cutout_rig_v1.blend` (editable packed 2D plane scene, sources hashed).
- `custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/blender/rig_build_receipt.json` (source/part hashes, Blender version, rig hierarchy/pivots, source-vs-render pixel diff, preview-only state).
- `.ai/operator_motion_foundry/blender/south_idle_v1/` ignored renders: `frame_000.png` through `frame_014.png` (15 x 128×128 transparent RGBA), `idle_preview_15f_128.png` (1920×128), `proof.json` and compact review closeups. No pretense that this strip is approved for runtime.

Asset V2: these are `operator_2_5d`-context **source-work candidates**, not a new family schema. No writes to `custodian/asset_drop/inbox/operator_2_5d/`, `custodian/content/`, Workbench-approved sources or runtime during this slice. Any later promotion must go through specialized Operator V2 ingress after human review.

## Objective and subjective gates

Before any pose: reverify source hashes, all part PNGs and pivots, exactly 23 expected controls/parts, correct parent graph, correct binary alpha and transparent background, registration/alpha bbox and **zero pixel diffs at the rendered neutral frame**. Test 1px cross-part displacements, an arm rotation, reset-to-neutral, bad/missing input hash, wrong camera, and wrong output dimensions; ensure every failed operation refuses to claim an accepted proof. Confirm the **same Blender source** renders the chosen pose frames in background, not a duplicated pure-Python image approximation. Repeat neutral build/render and compare normalized PNG content fingerprints for determinism; no nondeterministic timestamps in receipts.

After objective tests, publish the *smallest* useful review evidence (neutral and a few key frames, plus seam crops and metric report) only if subjective seam plausibility remains important. The full 15-frame strip is the explicit requested animation deliverable (not gratuitous evidence); do not spam full-resolution captures. Artistic seam approval and missing hidden-surface underpaint are user-owned. A passed engineering rig smoke is **not** approval of the animation.

## Drift and constraints

The main Motion Foundry V1 spec still says "not implemented" despite MF1 landing. Report the discrepancy; do not rewrite original MF1's archived packet or infer independent review passed. Current Broken Warrant 3D Blender tooling is technical precedent only and remains independent. Keep 96×96 enemy runtime rig untouched. The South Rig source-work predecessor remains prerequisite; the preserved MF1/MF2 reviews do not need to be bypassed to build a nonproduction 2D tool.

