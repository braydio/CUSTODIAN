# OPERATOR MOTION FOUNDRY BLENDER 2D CUTOUT RIG V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-motion-foundry-blender-2d-rig-v1`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `operator-motion-foundry-south-rig-sourcework-v1`
- Locks: `operator-blender-2d-authoring`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, asset-pipeline, workflow`
- Paired review workstream: `review-operator-motion-foundry-blender-2d-rig-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Blender pose ownership, exact source-pixel fidelity, and candidate-only export need independently falsifiable proof`
- Reviewed main: `82892c37eaec466f59b58e8df52cb36e3a75a1e5`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Visual review: `conditional`
- Goal: Build a **real, editable south-facing 2D cutout rig** for the Operator in Blender, scripted and repeatable from the source-work parts, with a transparent registered idle preview. No user script-pasting or 3D modeling.
- Completion boundary: New Blender background build/render scripts, a packed/editable .blend, validated 23-part rig and neutral pixel-exact Blender render, bounded 15-frame pose test, reproducible proof/manifest and narrow smoke. Entire result remains unapproved source-work.
- Current measured state: CUSTODIAN has headless Blender automation under `custodian/tools/art/broken_warrant_3d/` for a **different** 3D actor, and MF1's CPU part renderer under `custodian/tools/operator/motion_foundry/`; neither builds a Blender 2D Operator puppet. The south source-work precursor packet is currently `ready/auto` but not archived complete, and its extracted rig/parts are absent from reviewed main. MF1 review remains separately unresolved. The user's Blender is running, but command-line executable/version on the Codex execution host has **not** been verified.
- Evidence: `design/02_features/animation/OPERATOR_MOTION_FOUNDRY_BLENDER_2D_RIG_V1.md`; existing `custodian/tools/art/broken_warrant_3d/{README.md,build_materials.py,render_pixel_proof.py}`; `custodian/tools/operator/motion_foundry/rig.py`; `custodian/docs/ai_context/asset_audits/OPERATOR_MOTION_FOUNDRY_SOUTH_RIG_ADDENDUM_20261019.md`; `OPERATOR_MOTION_FOUNDRY_SOUTH_RIG_SOURCEWORK_V1.md`.
- Task-specific authority: New Blender 2D spec for authoring, exact landed south-source rig/ownership manifest, Operator 2.5D root and 128px direction/palette contracts, existing Asset Pipeline V2 source-work versus runtime distinction.
- Work surface: New `custodian/tools/operator/motion_foundry/blender/build_operator_2d_rig.py`; new `custodian/tools/operator/motion_foundry/blender/render_operator_2d_rig.py`; new `custodian/tools/operator/motion_foundry/blender/README.md`; new `custodian/tools/validation/operator_motion_foundry_blender_2d_smoke.py`; `custodian/tools/validation/validation_manifest.json` owner entry; source-work **only** `custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/blender/` and ignored `.ai/operator_motion_foundry/blender/` proofs. Other MF1 core and existing Blender 3D code read-only.
- Publication inputs: `design/02_features/animation/OPERATOR_MOTION_FOUNDRY_BLENDER_2D_RIG_V1.md`, `custodian/docs/ai_context/asset_audits/OPERATOR_MOTION_FOUNDRY_SOUTH_RIG_ADDENDUM_20261019.md`; authoritative south-rig files arrive from the completed predecessor, **not from this chat or a duplicate Dropbox fetch**.
- Change:
  1. On eligible claim confirm predecessor source-work is complete with hydrated `extracted/rig.json`, 23 original-source PNGs, hierarchy/overlap JSON, pinned source hash and pixel-exact neutral reassembly. Stop if unavailable or mismatched. Do not modify the claimed predecessor worktree. Locate the local Blender binary (running UI does not prove CLI availability); check `blender --background --factory-startup --python-expr`, report version. Use live API-compatible scripts rather than the earlier untested chat script (which must not become implementation input). Reuse relevant background CLI/PNG comparison patterns from existing Broken Warrant 3D tooling, never its GLB/armature.
  2. Create a **pure 2D** front-facing cutout armature from exact part IDs/parents/pivots/draw order; image-plane material uses unlit emission, nearest sampling, binary alpha, preserved source colors, exact no-resize frame registration and fixed orthographic 128x128 RGBA camera. Parent matrices must preserve neutral positions; hierarchy must be controllable in Blender pose mode. Mark 5 empty occluded parts as disabled/guide-only; never generate their art.
  3. Save packed editable `operator_south_cutout_rig_v1.blend`; renderer opens this **same saved file** in background and outputs rest frame, 15 numbered 128x128 preview frames, 1920x128 strip and hashes. Expose a clean `reset neutral` pose, stable root and named layer controls. Author a restrained idle test (breath/head/cape-tabard/arms only when no visible holes); keep planted feet fixed and `fps=null` in all canonical-provenance records. Any preview playback speed stays separate.
  4. Validate Blender-rendered **neutral** RGBA matches exact source south frame (not merely parts sum) including 2440 visible pixels and alpha outside silhouette. Validate 23 unique part controls, correct parent graph/depth, intended motion in nonneutral frames, no hidden geometry or new palette, no cropping, stable root/foot contacts, and restoration of neutral pose. Include negative controls for malformed/missing rig, hash, source part, incorrect projection, wrong direction and nondeterministic second render. Document unavoidable seam gaps as explicit human-review blockers without claiming an approved idle.
  5. Add narrow Blender test into validation manifest with skip/fail policy explicit: **missing Blender executable cannot count as passed acceptance**. Run smoke twice and changed validation with normal host resource budget. If subjective seam quality is still material after objective checks, produce one compact Dropbox visual-review handoff through the existing publisher; record human-required findings separately. Nothing can promote to runtime.
- Preserve: Original south source and 23 part PNG bytes, approved master idle/design lock, Operator 2.5D 128px root/ground/directions, MF1/its held review, MF2 gate, SourceArtService/Workbench/Asset V2 paths, and Broken Warrant 3D authoring tools. Don't mutate existing sourcework or branch/claim artifacts.
- Non-goals: No 3D mesh/character modeling, 3D gameplay/camera, retexturing/redrawing, inferred hidden body parts, runtime rig, palette edits, Asset V2 ingest or pixel-perfect claims from unrendered source alone. No claim/recovery workflow changes.
- Acceptance: (A) A clean worktree with installed Blender can build the packed 2D rig from **only the tracked landed source-work** without any user UI paste. (B) Exactly 23 source-identified controls, 18 populated textured planes, 5 empty guide-only; correct root, draw order, pivots, editable parent/pose navigation. (C) Neutral Blender render 128x128 RGBA matches original south source pixel-by-pixel; 0 mismatched pixels including alpha. (D) 15 preview frames 128x128, 1920x128 horizontal strip, two renders deterministic; visible but modest controlled motion and planted feet with a clean neutral reset. (E) Fail closed on hash/path/camera/alpha/regression faults; no runtime/canonical write. (F) Source-work receipt states **candidate / not art approved** and any open seams/human art decisions.
- Validation: New `operator_motion_foundry_blender_2d_smoke.py` run in execution host with actual `blender`; existing `operator_south_rig_extract_smoke.py` once predecessor has landed; `python3 custodian/tools/validation/run_validation.py --changed --json`, `git diff --check`, `git lfs ls-files` if binary source-work uses LFS. Test binary output/readback after fresh reload and one negative source modification in temporary fixture.
- Task overrides: `none`
- Deferred: Human redraw/underpaint of seams and five hidden parts, advanced rotations/IK and polished attack/walk states; separately reviewed MF1/MF2 candidate pipeline and eventual Operator V2 art approval.

## Next Handoff

- Next workstream: `review-operator-motion-foundry-blender-2d-rig-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `none`
- Next action: `Fresh independent readback of saved Blender rig, actual neutral render, and candidate-only export boundaries.`
- Blockers or open questions: `Source-work predecessor must land first; Blender CLI must be executable in the Codex host. Human art quality remains a postengineering review gate.`
