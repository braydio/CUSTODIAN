# CUSTODIAN · Operator NE walk · 15-frame reference-guided batch-retarget

Workstream ID: `operator-2-5d-ne-walk-retargeting`
Suggested branch: `agent/operator-2-5d-ne-walk-retargeting` (only if a repository code change is actually needed).

## Goal

Advance local Aseprite Knight→CUSTODIAN retarget prototype V5.5 into a 15-frame *reference-guided* NE walk proof. The enclosed reference strip and frame PNGs are reference pose inputs only. Preserve the existing CUSTODIAN rig master's source pixels, layer ownership, editable pivot authority, body proportions, palette, sole-contact geometry, and 128x128 registration.

## Inputs

- `reference/knight_ne_walk_reference_15f_128.png` exact uploaded 1920x128 RGBA source; see SHA-256 in MANIFEST.json.
- `reference/frames/knight_ne_walk_f01.png` ... `f15.png`: exact 128x128 crops, no rescale.
- Existing local Aseprite `operator_ne_pose_builder_v0_5_5_swing_stride_control.lua` and validated NE rig master; these are **not embedded** in this package.
- Current `braydio/CUSTODIAN` main and AGENTS.md. Use specialized Operator source/Workbench authority, not generic family paths invented in chat.

## Slice contracts

1. **Reference truth**: The new strip's first frame is DIFFERENT from the earlier embedded Frame 1; never reuse `KNIGHT_F1_JOINTS` or embedded pixels. Produce and validate separate nine-landmark annotations for each of 15 frames; each joint must refer to visible anatomy (allow documented occlusion inference where anatomy is hidden), never shadow. Do not infer support side solely from darkest/bottommost alpha pixels. Prefer machine-readable per-frame annotations with provenance and editable overrides. Do not silently invent hidden-joint confidence.
2. **Temporal gait**: Track near/far limb identities consistently through crossings; explicitly describe the near→far→near provisional support transitions. Validate reference continuity, foot contact intervals, knee branch stability, pelvis bob, and swing-foot clearance. Do not assume every frame can ground the same sole at an identical screen coordinate: maintain canonical world registration while representing in-place treadmill animation.
3. **Retarget**: Retain canonical Operator segment lengths, editable pivots, semantic ownership, sole-aware IK and the rasterized boot correction. Bound pelvis reach and swing span without silently crushing the donor's gait. Preserve all rig art and never copy the Knight's weapon or shadow to the Operator. Flag large fit errors, clamps, discontinuities, pixel holes and cross-frame jumps. Model the upper-body counter-motion and robe relationship as separate controlled additions rather than letting legs drag unrelated sprites.
4. **Output**: Generate separate 15-frame RGBA Operator animation preview and QA evidence. Target exact 128x128 cells, 15x1 1920x128, transparent background, stable center x=64 and projected root (64,106), ground/shadow y=107. No ambient shadow, reference pixels, guides, or QA in the clean output. Authoritative timing is UNKNOWN until selected explicitly; do not silently choose 8 FPS.
5. **Isolation**: Use a duplicate/local disposable Aseprite rig file. Never overwrite its immutable source layers; do not publish the result to canonical runtime or update game animation selectors. First validate all 15 in preview; reserve specialized Operator source promotion for a separate acceptance slice.

## Acceptance

- 15 exact source-frame hashes match the manifest when reassembled.
- Every marker record has provenance, unique identity and no shadow-based foot anchors.
- The 15 preview frames form a coherent loop, have a stable root and preserve source identity/materials.
- Each support frame reports actual rendered boot contact; unreachable / unusable reference frames fail individually and transparently, rather than forcing a fake pass.
- Frame 15→1 interpolation/contact continuity is inspected visually and quantified.
- An editable QA artifact/report marks frame-by-frame target deviations and deficiencies.
- No art/publish/ingest action occurs without acceptance. Reports name exact validation commands and observed outcomes, including any runtime tests unavailable outside Aseprite.

## Non-goals

No generic skeletal detector, no full 3D game runtime conversion, no simultaneous eight-direction generation, no combat-animation migration, no old-rig rebuild, no automatic publish.

## Documentation drift check

Compare the current `design/01_systems/ISOMETRIC_2_5D_REALIZATION_ROADMAP.md`, canonical Operator profile, `custodian/tools/operator/README.md`, and current active Operator production packet. Report any stale status, profile/registration mismatch, or contradictory intake requirements. Update active docs only after reality changes.

## Completion report

List changed files, frame validations and contact residuals, loop result, runtime/provenance limitations, exact outputs/paths, doc drift, and smallest next correction. Inherit repository-wide packet/landing rules from live AGENTS.md instead of duplicating them here.
