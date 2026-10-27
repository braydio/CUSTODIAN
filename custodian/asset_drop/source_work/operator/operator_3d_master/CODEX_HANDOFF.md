# Codex implementation handoff: Operator genuine 3D master (modeling proof)

## Goal
Iterate toward one **artist-approved volumetric 3D master** of CUSTODIAN's existing Operator that can produce convincing eight-direction 2.5D renderings and an animated 15-frame NE walk. Start from this bundle's named, editable blockout GLB, not from 2D pixel fragments. This is art source-work only.

## Required sources
Read and obey repository `AGENTS.md` and the real locked sources:
- `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`
- `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`
- `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`
- `custodian/content/data/operator/authoring/operator_art_profile.json`
- `custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/operator_2_5d_design_lock_v1_source.png` (Git LFS: get real bytes)
- `custodian/asset_drop/source_work/operator/operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_source.png` (Git LFS: get real bytes)

Source contracts: design image SHA256 `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`; idle image SHA256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`. Authoritative Dropbox originals are under `/CUSTODIAN/implementation_inputs/` with these same respective names:
`operator_2_5d_design_lock_v1_8dir_1f_256.png`; `operator_2_5d_unarmed_posture_idle_relaxed_01_full_body_v1_8dir_15f_128.png`.

## Explicit state of this handoff
- Includes a genuine triangulated 3D mesh: 72 independent colorized volumetric and cloth components in `assets/operator_volumetric_v001.glb`, edited via deterministic `scripts/generate_mesh.py` and `config/shape_v001.json`.
- Includes Blender builder and animation script `scripts/create_blend.py` (14-bone named character armature, two IK target empties, NE walk preview, eight fixed cameras, transparent output). **Blender runtime execution is not independently verified** in this container because Blender is not installed. Diagnose actual Blender API/runtime errors rather than asserting animation acceptance.
- Includes eight VTK/EGL geometric preview views and a montage, **not** Blender animation proof or comparison against the source masters.
- The design has not been visually matched to canonical reference imagery. It is a structural blockout, not the final Operator. Avoid making ungrounded claims of canonical equivalence.

## Do first (one bounded PR/branch; not main)
1. Work on a scoped new branch rooted at current `main`; obey coordination/worktree rules, never overwrite other people's working state. Place this bundle under a single authoritative source-work path of the repo as appropriate, without creating competing art-registration, renderer, or runtime publication owners.
2. Verify the two exact LFS source reference hashes from actual bytes. If LFS unavailable, fail visibly rather than substituting Git's 131-byte pointer.
3. Install/use locally available Blender 4.3+ or 5.x, then run the provided Blender builder command from README. Fix Blender API compatibility and any rig-parenting/pose/IK bugs in a new experiment. Save a real `.blend` and real render proof; do not accept a file just because scripting exited zero.
4. Render eight neutral views and actual fifteen NE frames. Build compact side-by-side comparisons of native source canonical idle silhouette vs 3D at 128 px, plus a looping walk video/GIF. Evaluate silhouette, proportion, hood, pauldron, cloak, feet, visor position, near/far projection, ambient value/material language, and foot skating. Correct model shapes and IK as needed.
5. Create `exp-002` rather than rewriting `exp-001`. Every candidate includes parameter snapshot, GLB, `.blend`, QA, SHA256, comparison sheet, NE loop. Keep rejected and successful outputs; don't recast prior failures as successes.
6. Show me at most 2-3 well-contrasted candidates in an honest visual review. Favor high-impact geometric changes over dozens of micro-iterations. Do not proceed to 69 animation families.

## Production boundaries
- No `operator.gd` changes, sprite selector/runtime manifest/SpriteFrames changes, source-work promotion, or live gameplay cutover.
- No approval of FPS: 15 frames and the Blender preview cadence are provisional. Never treat 8 FPS preview as canonical timing.
- Preserve asset generation identity `operator_2_5d_128` and 128x128 frame, center x64, projected root (64,106), ground y107, apparent height ~84-88 px.
- Full-body-first. Only use modular pieces where gameplay independently owns facing/aim/movement. No mirroring for directions.
- Do not resume the rejected 2D cutout / warped-sprite retargeting iteration011; its branch and evidence remain untouched.
- Green numeric QA or unchanged source hashes never substitute for human recognition and motion acceptance.

## Definition of done for this *first* slice
- Reopenable Blender file with genuine dimensional geometry and stable named rig.
- Eight usable static camera previews; source-aligned perspective and silhouette from canonical 8-direction design.
- 15-frame NE animated preview with alternating steps and continuous readable boots/robe; real Blender-rendered loop, no pose-generation per-frame inconsistencies.
- Clear review evidence showing what is correct, still visually wrong, and how to revise in a bounded next iteration.
- A durable candidate ID/hash and rollback-selection journal; no mutation of existing accepted idle, no runtime art publication.

Stop after preparing the next comparison for human review. Do not claim subjective art approval or launch indefinite autonomous redesign.

After successful Blender execution, call `scripts/freeze_proof.py --experiment exp-001 --notes '...'` and preserve both the original mesh snapshot and rendered proofs. This capture refuses partial missing animations and refuses overwriting the prior receipt. New experiments must get new names, not replace an accepted file.
