# Operator 3D Neutral Idle Retarget Fix V1

- Packet schema: custodian.task_packet.v2
- Workstream: operator-3d-neutral-idle-retarget-fix-v1
- Status: `complete`
- Dispatch: `auto`
- Priority: P1
- Depends on: operator-3d-neutral-idle-blender-proof-v1
- Locks: operator-3d-animation-pipeline
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, asset-pipeline, workflow
- Paired review workstream: review-operator-3d-neutral-idle-retarget-fix-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: The current source-to-target rest-axis transfer produced materially incorrect arm posture, excessive stance width and changed joint flex. The correction changes reusable motion math and deterministic image QA, so a fresh technical review is required; no production or artistic approval follows.
- Reviewed main: f566cdf302afbab2dd386f80a5605b5c2e76859a
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Visual review: required
- Authoring handoff: auto
- Goal: Correct the reusable Mixamo-to-Operator retargeting math that caused the rejected Neutral Idle pose, apply the same calibrated method to Neutral Idle and the exact new Idle.fbx, and produce compact candidate-only evidence.
- Completion boundary: One shared retargeting correction, one candidate-only generation and focused validation cycle for both clips, deterministic RGBA comparison repair with regression tests, source-versus-target measurements, compact directional previews and short full-duration comparison videos. Stop at READY_FOR_HUMAN_VISUAL_REVIEW. Do not approve or publish either animation.
- Current measured state: Task 002 is complete and its Neutral Idle candidate remains visually rejected and unapproved. The prior world-space transfer computes source pose delta on the left of the target rest rotation, despite large source/target rest-axis discrepancies. Existing external diagnostics show that a first-frame reference candidate fixes the horizontal-arm failure but leaves target ankle spacing at 0.505 leg-length units versus 0.341 for the normalized source (old retarget: 0.592); this candidate is diagnostic evidence only. The original source and master hashes match the pinned values. New Idle.fbx is present at /home/braydenchaffee/Downloads/Idle.fbx with SHA-256 dbab063735fb0510df0fe9b713a1052613224e9f2e83d3992ec340915c3b7895; Blender 5.2.3 confirms a 65-bone Mixamo armature, 30 FPS, frames 1–251, and identical endpoint pose transforms. The original Neutral Idle is frames 1–264 at 30 FPS with matching endpoint pose transforms.
- Evidence: Archived Task 002 packet and root summary; compiler adapter, contracts and focused tests; proof-area baseline diagnostic, current candidate receipt, calibrated diagnostic report and candidate artifacts; exact FBX and master hashes stated above.
- Task-specific authority: This packet and the exact authoring chat; archived Task 002 packet custodian/docs/ai_context/task_packets/archived/OPERATOR_3D_NEUTRAL_IDLE_BLENDER_PROOF_V1.md; custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py; neutral_idle_proof_contract.py; finalize_neutral_idle_candidate.py; test_operator_neutral_idle_proof.py; Task 001 compiler contracts; design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md for camera and candidate/runtime boundary.
- Work surface: Shared retargeting adapter/policy and focused tests under custodian/tools/operator/animation_compiler/ and custodian/tools/validation/. New source copies, policy records, motion candidates, renders, diagnostics, contact sheets, videos and QA remain under /home/braydenchaffee/Projects/.operator-3d-animation-proof/neutral-idle/ and user-download preview copies under /home/braydenchaffee/Downloads/.
- Publication inputs: custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py, custodian/tools/operator/animation_compiler/neutral_idle_proof_contract.py, custodian/tools/operator/animation_compiler/finalize_neutral_idle_candidate.py, custodian/tools/validation/test_operator_neutral_idle_proof.py, custodian/tools/operator/animation_compiler/prepare_neutral_idle_contracts.py, custodian/docs/ai_context/task_packets/archived/OPERATOR_3D_NEUTRAL_IDLE_BLENDER_PROOF_V1.md, design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md. Host-local inputs are the explicitly hash-pinned source FBXs and ITER005 master; fail closed on any mismatch.
- Change:
  1. Reproduce the archived Task 002 Neutral Idle candidate as the baseline, preserving its files and receipt.
  2. Replace the world-delta transfer with one deterministic rest-frame calibrated anatomical mapping that transforms source bone motion into target bone axes using each validated source/target rest frame. Record formula, coordinate spaces, per-bone calibration data and chain compatibility. Keep it reusable across clips sharing the validated Mixamo skeleton and unchanged Operator target rig.
  3. Calibrate shoulder, upper-arm, forearm, hip, thigh, shin and foot chains. Preserve source local motion, elbow/knee bend and temporal variation. Use source and target chain lengths plus each side's measured source joint positions to constrain stance correction; retain source asymmetry. Apply no animation-specific hand poses, direction offsets, arbitrary symmetric stance, bone scaling or animation retiming.
  4. Keep source root trajectory separate from in-place target pose. Verify foot contact and sliding from stable source/target landmarks, loop continuity, source-to-target joint-direction errors, and unchanged target rest transforms, geometry, weights and materials.
  5. Apply the same policy and code to original Neutral Idle and new Idle.fbx. Inspect both actual actions and their endpoint poses; preserve authored FPS and frame range, omitting a terminal duplicate only when measured.
  6. Replace ImageChops difference getbbox equality with exact decoded RGBA buffer equality. Add regression tests where RGB differs while alpha is identical, plus an equal-pixel control.
- Preserve: Original source FBXs, original ITER005 master, the rejected original Neutral Idle motion/candidate/receipt, existing diagnostic/calibration artifacts, Running, all mesh geometry/topology, 42-bone hierarchy and rest pose, materials, textures, skin weights, production Godot assets and existing renderer/camera contract.
- Non-goals: No model/rig redesign, mesh or weight edit, shoulder work, other animation clips, full eight-direction frame library, full batch compiler, runtime timing changes, Asset V2 intake, candidate approval, production promotion, Godot integration, main merge outside the normal workstream closeout, deployment or additional speculative correction iteration.
- Acceptance:
  1. The original Neutral Idle failure is reproducible from the preserved prior candidate; the corrected retargeter uses explicit source/target rest-frame calibration and deterministic per-chain data with no per-animation magic offsets.
  2. Neutral Idle and Idle.fbx retain their actual FPS, action ranges, source motion variation and measured loop policy; both source trajectories remain separate from in-place motion.
  3. At frames 1, 33, 66, 99, 132, 165, 198, 231 and the actual final unique frame, report source, old-retarget and corrected measurements for ankle spacing normalized by leg length and pelvis width; wrist/shoulder positions; shoulder-to-wrist and hip-to-ankle direction errors; knee/elbow angles; pelvis alignment; foot heights/landmarks; and loop continuity. Corrections must improve the demonstrated pose defects without collapsing asymmetric source stance or introducing flips, scale changes or discontinuities.
  4. Generate source/current/corrected synchronized front and side comparisons for Neutral Idle. Generate source/corrected comparisons for new Idle. Generate each corrected clip's front, right-side and rear 512px preview, sampled eight-direction native 128px sheets, and short full-duration comparison MP4. Keep identical camera, registration and frame timing. Check all directions for clipping, including SW.
  5. Deterministic QA compares decoded RGBA bytes exactly. Regression tests prove same-alpha RGB changes are detected; rerun and accurately report each repeated image's byte and decoded-pixel equality.
  6. Original master, source FBXs, previous Neutral Idle candidate/receipt, Running, mesh, weights, materials and rest pose remain byte/semantic identical. New outputs remain candidate_unapproved in the ignored proof root; preview MP4 copies are available under Downloads.
  7. Focused compiler and proof suites, Blender source inspections/retarget/render checks, candidate checks, reproducibility checks, Python compile checks and git diff --check pass. No broad Godot validation.
  8. The durable summary records exact changed code/tests, formula and coordinate spaces, metrics, source hashes, actual test results, artifact paths, recommendation and exact Authoring chat URL. Stop at READY_FOR_HUMAN_VISUAL_REVIEW; subjective gait/idle approval remains human-owned.
- Validation: python3 -m unittest custodian.tools.validation.test_operator_3d_animation_compiler -v; python3 -m unittest custodian.tools.validation.test_operator_neutral_idle_proof -v; py_compile changed Python files; Blender 5.2.3 inspection and candidate-only retarget/render of both exact sources; candidate receipt checks where applicable; deterministic motion and sampled-render repeats; exact RGBA regression tests; source/master hashes before and after; git diff --check; python3 custodian/tools/agent/check_ai_context.py and task_packet_index validation. Do not run broad Godot sweeps or the full eight-direction frame library.
- Task overrides: TASK OVERRIDE: This user-authorized continuation supersedes Task 002's prior “follow-up changes require explicit authorization” stop condition only for the exact retargeting/Idle.fbx/QA/evidence scope above. It does not approve either clip or authorize production/runtime changes.
- Deferred: Human visual selection of the default idle; any animation-specific follow-up correction; full directional libraries; production model freeze, candidate promotion and runtime integration.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `OPERATOR_3D_NEUTRAL_IDLE_RETARGET_FIX_V1_CLAUDE_SUMMARY.md`; 32 focused unit tests pass; both hash-pinned clips processed and measured through all unique frames; source and corrected loops remain within declared seams; corrected mesh has no below-ground frames; exact RGBA QA reports 22/24 equal and two single-RGB-pixel differences without misclassifying them; fixed-camera evidence and two full-duration videos published in the Dropbox review bundle; source/master hashes unchanged; no production outputs or approvals.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: exact repeated render comparison exposed two one-pixel RGB variations previously hidden by the alpha-only bounding-box comparison.
- Root cause / contributing factors: the old equality predicate ignored RGB-only differences; the render engine also produces a one-pixel RGB variation in two of 24 repeated samples.
- Prevention / pipeline improvement: compare decoded RGBA bytes exactly and preserve same-alpha RGB regression coverage; record exact equality counts.
- Tooling / docs drift discovered: none
- Follow-up: review-operator-3d-neutral-idle-retarget-fix-v1
- What worked: one hash-pinned calibration and contact-phase IK policy applied to both validated Mixamo clips; the source contact landmarks identify stable phases without per-animation correction constants.

## Handoff
- Next workstream: review-operator-3d-neutral-idle-retarget-fix-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Refresh reason: none
- Next action: Complete one retarget correction and candidate evidence package, then perform the fresh paired technical review and stop for human visual assessment.
- Blockers or open questions: none
