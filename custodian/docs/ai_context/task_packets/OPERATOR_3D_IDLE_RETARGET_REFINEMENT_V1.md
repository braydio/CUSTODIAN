# Final Operator Idle Retarget Refinement

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-3d-neutral-idle-retarget-refinement-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: `review-operator-3d-neutral-idle-retarget-fix-v1`
- Locks: `operator-3d-animation-pipeline`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, asset-pipeline, workflow`
- Paired review workstream: `review-operator-3d-neutral-idle-retarget-refinement-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Reusable anatomical coordinate mapping changes motion math and contact validation; independent technical review is warranted. Subjective idle selection remains human-owned.`
- Reviewed main: `fc307761111317c218bf39fd7e2c65d53ff118c5`
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Visual review: `required`
- Authoring handoff: `auto`
- Goal: Refine the landed Mixamo-to-Operator idle retarget so both clips retain their improved arms and knee flex while their stance width, grounding, contact, and canonical sprite framing better match their source movement.
- Completion boundary: One bounded shared leg target-mapping correction and one validation/render cycle for the hash-pinned Neutral Idle and Idle FBXs. Preserve source timing and motion, existing shoulder/arm calibration, source-derived contact phases, target rig/rest pose and the fixed camera contract. Generate compact before/after proof under the existing ignored proof root in a new `idle_refinement/` directory. Stop for human visual review; do not approve or publish candidates.
- Current measured state: The landed Task 015 retarget uses `goal = target_hip + (source_ankle - source_hip) * ((target_upper + target_lower)/(source_upper + source_lower))`, uniformly scaling lateral, forward and vertical displacement by leg-chain ratio. Baseline normalized ankle spacing is Neutral Idle `0.3945` source versus `0.4962` corrected target and new Idle `0.3141` source versus `0.4508` target. Pelvis-width-normalized lateral spacing is Neutral `1.3769` source versus `1.2132` target and new Idle `1.5598` source versus `1.3111` target. The Neutral Idle SW sample touches the native 128px bottom boundary. Mean right shoulder-to-wrist direction error is approximately 17 degrees. New Idle is the preferred candidate direction; Neutral Idle is the alert alternative. Both remain unapproved.
- Evidence: `custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py`; `retarget_calibration.py`; `contracts/mixamo_rest_frame_retarget_policy_v2.json`; `custodian/tools/validation/test_operator_neutral_idle_proof.py`; original Task 015 summary and archived packet; exact source and master hashes below; external Task 015 validation report and review bundle.
- Task-specific authority: This packet and exact authoring chat; archived Task 015 packet and summary; `custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py`; `retarget_calibration.py`; the Task 015 policy JSON; `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md` for camera, scale, registration, timing, and candidate-only boundaries.
- Work surface: `custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py`, `custodian/tools/operator/animation_compiler/retarget_calibration.py`, `custodian/tools/operator/animation_compiler/contracts/mixamo_rest_frame_retarget_policy_v2.json`, `custodian/tools/operator/animation_compiler/finalize_neutral_idle_candidate.py`, `custodian/tools/validation/test_operator_neutral_idle_proof.py`, and a new ignored external proof subdirectory `/home/braydenchaffee/Projects/.operator-3d-animation-proof/neutral-idle/idle_refinement/`.
- Publication inputs: `custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py`, `custodian/tools/operator/animation_compiler/retarget_calibration.py`, `custodian/tools/operator/animation_compiler/contracts/mixamo_rest_frame_retarget_policy_v2.json`, `custodian/tools/operator/animation_compiler/neutral_idle_proof_contract.py`, `custodian/tools/operator/animation_compiler/finalize_neutral_idle_candidate.py`, `custodian/tools/validation/test_operator_neutral_idle_proof.py`, `custodian/tools/validation/test_operator_3d_animation_compiler.py`, `custodian/tools/operator/animation_compiler/prepare_neutral_idle_contracts.py`, `custodian/docs/ai_context/task_packets/archived/OPERATOR_3D_NEUTRAL_IDLE_RETARGET_FIX_V1.md`, `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`. Host-local immutable inputs: ITER005 master SHA-256 `a0bdf6c1143d23386721299c42d2e76178c0dff841a7e54bd9d9df1bf17dd969`; Neutral Idle SHA-256 `40fda03b9e87092978f31c0721a3de2ad686a35983d73386769a17029684e1a3`; Idle SHA-256 `dbab063735fb0510df0fe9b713a1052613224e9f2e83d3992ec340915c3b7895`.
- Change: First measure source and target anatomical pelvis axes and hip-socket widths from validated rig rest data; do not assume a world axis is lateral/forward. Express each source hip-to-ankle offset in the source pelvis-relative basis. Map lateral components by source/target pelvis or hip-socket width ratio; map forward and vertical components with explicitly documented leg-chain proportions; convert the result through the target pelvis basis into target armature/world space. Feed ankle goals to the existing two-bone solver. Preserve side-specific source offsets/asymmetry, source-derived knee-plane hints, contact phases, and source-relative motion. Investigate the right arm's approximately 17-degree direction error only for a demonstrated chain-space calibration defect; do not apply a visual offset. Keep the existing shoulder, arm and rest-frame calibration intact.
- Preserve: Exact source timing: Idle 251 authored frames/250 unique at 30 FPS; Neutral Idle 264 authored/263 unique at 30 FPS. Existing contact detector; analytic two-bone IK; source root-motion separation; unchanged 42-bone hierarchy, rest pose, mesh topology, materials and weights; exact decoded RGBA comparison and regression; ITER005 Running action; original candidate receipts and all prior renders. Do not alter source FBXs or master blend. No runtime/production changes.
- Non-goals: Character redesign, arbitrary stance symmetry, animation amplification, arbitrary shoulder or foot offsets, bone scaling, bone/rest edits, mesh/weight edits, changing the canonical camera/registration, full eight-direction animation libraries, Godot integration, production promotion, default-idle approval, or changing global retarget policy for unrelated source skeletons.
- Acceptance:
  1. Document validated source/target pelvis basis axes and proportions. Show whether uniform leg-length scaling caused residual stance error.
  2. Add focused regressions for pelvis-coordinate conversion, lateral scaling, asymmetric ankle placement, IK reachability/no hidden clamping, and loop continuity.
  3. Across all authored frames, report source/current/refined normalized ankle spacing by leg length and pelvis width for both clips. Improve both normalizations where anatomically feasible; target <15% source-relative spacing error when achievable. Explain target-proportion limits rather than forcing them.
  4. Preserve arms/shoulders and knee bending. Report wrist/shoulder positions, direction error including right arm, knee angles/flips, foot orientations, source motion preservation and torso/shoulder hashes. No unintended torso/shoulder movement caused by leg correction.
  5. Across all frames, report planted-foot drift using source-aligned intervals, ground penetration, non-contact foot motion, IK reach/clamping, and seam continuity. Do not force both feet to ground.
  6. At native 128px, inspect all eight directions for both clips. Determine whether SW bottom contact is alpha clipping; require two transparent pixels of margin where compatible with fixed registration/scale. If impossible, report the exact conflict and keep the camera contract.
  7. Produce per-animation 512px source/current/refined front/side/rear sheets; 128px eight-direction sample sheets; 30 FPS full-duration current-versus-refined MP4s; source-frame-aligned measures; and pixel bounds. Full-duration proof is required because sparse stills cannot establish contact continuity and subtle idle motion across the loop; do not render full directional frame libraries.
  8. Measure root-relative hand, shoulder, chest and head motion amplitudes in 128px pixels. Report whether new Idle motion is readable without amplification.
  9. Repeat exact decoded-RGBA checks and report unequal one-pixel variation accurately. Preserve the pinned source/master hashes and all protected originals.
  10. Provide an objective provisional recommendation: Idle as preferred default candidate and Neutral Idle as alert alternate, subject to user/ChatGPT visual review. No artistic approval or production promotion.
- Validation: Focused `test_operator_neutral_idle_proof` and `test_operator_3d_animation_compiler` suites; new mathematical and loop tests; Blender hash/timing/source inspection; full unique-frame measurements for both clips; contact/ground/IK and seam checks; canonical 128px all-direction bounds; independent 512px sheets and two full-duration candidate comparison MP4s; exact RGBA repeat test; unchanged source/master hashes; candidate-only receipt checks; `py_compile`; `git diff --check`; packet/index validation; standard workstream finish and independent paired review. No broad Godot sweep.
- Task overrides: `TASK OVERRIDE: Execute this refinement only after the dependency review is archived complete. The task may generate candidate-only animation artifacts and human-review evidence; it does not approve either animation, choose a production default, or authorize runtime integration.`
- Deferred: Human visual approval and default-idle selection; any subsequent animation polish or breathing overlay; full directional libraries; production promotion.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `no`
- Completion boundary satisfied: `no`
- Acceptance satisfied: `no`
- Evidence: `pending`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `low`
- What went wrong: `none`
- Root cause / contributing factors: `none`
- Prevention / pipeline improvement: `none`
- Tooling / docs drift discovered: `none`
- Follow-up: `none`

## Handoff
- Next action: Wait for the preserved Task 015 technical review to complete, then claim this exact workstream only when its dependency and animation-pipeline lock are released.
- Blockers or open questions: The named review is currently blocked before reviewer launch by a historical source-scope declaration mismatch; resolve it through its exact attestation recovery first.

## Next Handoff
- Next workstream: `none`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Refresh reason: none
- Next action: After technical review completion and lock release, dispatch the refinement packet; stop after technical proof for human visual assessment.
- Blockers or open questions: `none`
