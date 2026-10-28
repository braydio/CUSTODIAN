# Operator 3D Neutral Idle Blender Proof V1 — Closeout

Workstream: `operator-3d-neutral-idle-blender-proof-v1`

## Result

Produced one experimental, `candidate_unapproved` Neutral Idle proof using Blender 5.2.3, the verified Mixamo FBX, and the preserved experimental ITER005 model. This proof did not edit or save the original `.blend` or FBX and did not publish runtime sprites.

- FBX: `/home/braydenchaffee/Downloads/Neutral Idle.fbx` — SHA-256 `40fda03b9e87092978f31c0721a3de2ad686a35983d73386769a17029684e1a3`.
- Master: `operator_run_mixamo_iter005_contact_ik.blend` — SHA-256 `a0bdf6c1143d23386721299c42d2e76178c0dff841a7e54bd9d9df1bf17dd969`.
- Imported source action: `Armature|mixamo.com|Layer0`, 65 bones, 30 FPS, inclusive frames 1–264 (8.8 authored seconds).
- Target rig: `SmartRigArmature`, 42 bones. The explicit hashed mapping policy transfers 25 same-name bones, leaves 17 declared target-only bones in local rest pose so they inherit their parent motion, and ignores only 40 explicitly allowlisted source finger bones. Any mapping difference fails closed.
- Source endpoint maximum rotation delta: 0 degrees. All 264 authored source samples remain in motion metadata; playback samples 1–263.

## Delivered proof artifacts

All proof files are under `/home/braydenchaffee/Projects/.operator-3d-animation-proof/neutral-idle/` and are excluded from Git.

- Reusable model-independent pose data: `motion/neutral_idle_motion.v1.json`; file SHA-256 `eadba16e3516d320b92a85945e561b45a12df8685de2ae21f44bfa597224e7d5`. It contains target-rig local transforms and source/policy/target-rig bindings, with no model mesh, material, texture, camera, or master-file hash. A repeated retarget pass produced the same file SHA.
- Separate source root trajectory: `motion/neutral_idle_root_trajectory.v1.json`; trajectory is preserved as metadata and excluded from in-place sprite root poses and any Godot application.
- Independent direction outputs: `candidate/neutral_idle/unarmed/posture/neutral_idle/full_body/{N,NE,E,SE,S,SW,W,NW}/####.png`; 263 128×128 RGBA frames per direction (2,104 total). One experimental-master-derived scale is fixed across all views and frames; render metadata records the 45° camera, 50 px/m, no mirroring, and root projection within 0.0001 px of `(64,106)`.
- Candidate receipt: `candidate/neutral_idle_candidate_receipt.v1.json`; SHA-256 `1fd0b407d4ac1267b687cea024647ff7be7bf6bc8fe95b08dcc1b300aa13aee6`. Compiler `check --candidate-only` reports it current with zero changes. The default production validation still fails on missing runtime timing authority, as required.
- Technical QA: `qa/neutral_idle_technical_qa.v1.json`; all eight directions and frame dimensions/alpha checks pass. The root trajectory's maximum displacement from its first sample is approximately 0.02054 m.
- Compact contact sheet: `review/neutral_idle_eight_direction_contact_sheet.png`; eight directional 30 FPS GIF loops are in `review/loops/`.

The repeated retarget pass produced a byte-identical motion artifact. Repeated sample rendering matched decoded RGBA pixels for all 24 sampled direction/frame pairs; PNG byte streams differed for all 24 pairs, so the QA records bounded PNG encoding variation with pixel identity preserved.

## Validation

- `python3 -m unittest custodian.tools.validation.test_operator_3d_animation_compiler custodian.tools.validation.test_operator_neutral_idle_proof -q` — 28 tests passed.
- `python3 -m py_compile custodian/tools/operator/animation_compiler/*.py` — passed.
- Blender headless inventory, retarget, full eight-direction render, and repeated sample render — passed.
- Candidate-only manifest validation and candidate receipt `check` — passed; default production validation correctly reports `RUNTIME_TIMING_AUTHORITY_MISSING`.
- `python3 custodian/tools/agent/check_ai_context.py` — PASS.
- `git diff --check` — passed.
- Before/after source hashes match both pinned inputs.

## Preservation and review

The Task 001 `R0-01` verifier finding remains unresolved. The user waived that review only as a prerequisite to this experimental proof; no global dispatch policy, review claim, or production approval was changed. The Task 002 paired independent review remains required after landing. No shoulder geometry, Task 017 worktree, ITER005 Running source, Workbench/runtime asset, canonical source asset, Godot policy, or original modeling worktree was modified.

The required human animation-quality review is the next gate. The final Dropbox publication path will be recorded here after the implementation commit is pushed; review only the latest manifest.

## Process Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: Previewing exposed a quaternion component-order mistake; receipt checking exposed a trajectory hash that did not match the exact sidecar file bytes.
- Root cause / contributing factors: Blender stores quaternions as WXYZ while the portable motion artifact serializes XYZW; the initial trajectory digest excluded its stored digest field.
- Prevention / pipeline improvement: Explicit quaternion conversion and normalized-motion checks; exact sidecar byte hashing; explicit allowlisted mapping policy; candidate-only validation remains separate from production timing authority.
- Tooling / docs drift discovered: Candidate receipt schema lacked explicit retargeted-motion, skeleton-mapping, Blender-inventory, and render-metadata dependency types; those were added.
- Follow-up: fixed-in-scope
- What worked: Rest-pose scale fitting, sample pixel comparison, hash-bound dependency check, and preserving the full 264-frame authored source record.

## Next Handoff
- Next workstream: review-operator-3d-neutral-idle-blender-proof-v1
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: The human animation-quality decision is required for this candidate; the Task 002 paired post-land review also remains a required workflow gate.
- Next action: Review the latest Dropbox manifest and its compact contact sheet/eight loops, then record the human animation decision before further processing.
- Blockers or open questions: Candidate remains unapproved; Task 001 `R0-01` remains unresolved but is not a prerequisite for this experimental proof.
