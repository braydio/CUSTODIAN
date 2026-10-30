# Operator 3D Running Contact Follow-Up V1

- Packet schema: custodian.task_packet.v2
- Workstream: operator-3d-running-contact-followup-v1
- Status: draft
- Dispatch: manual
- Priority: P2
- Depends on: none
- Locks: operator-3d-running-contact-followup
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, asset-pipeline, workflow
- Paired review workstream: review-operator-3d-running-contact-followup-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: An experimental contact correction must preserve pinned source, weights and motion while independently validating evaluated sole clearance between frames.
- Reviewed main: 3dbbdc450d62c052c954ec8e999e8988a9e266ff
- Authoring chat: not-recorded
- Visual review: required
- Goal: Produce a bounded reversible candidate that improves the measured ITER005 Running foot-contact issue, or a justified failed experiment, without redoing the model or disturbing idle pipeline work.
- Completion boundary: After resolving ownership and a human-approved gait reference, inspect the immutable ITER005 baseline; make at most one authorized phase-contact correction, exact subframe QA and minimal visual handoff, then stop for visual decision. No production approval.
- Current measured state: Branch agent/operator-3d-master-modeling-proof-v1-iter005 at Task 015 evidence commit 6b89c4d503bb2d73d2783443d4280f313c681bfa retains RUN_MOTION_NEEDS_REPAIR. It contains 21 frames at 30 FPS, 0.70s, 42 bones, 10,367 triangles and experimental 4096px textures. ITER005 eliminated integer-frame below-ground observations (164 to 0), but quarter-frame samples include right -8.82mm at 1.50 and left -6.09mm at 12.50. The Task 015 branch/worktree is not proven completed or retired, so a new concurrent claim is forbidden.
- Evidence: Branch-only custodian/asset_drop/source_work/operator/operator_3d_master/TASK_015_CLAUDE_SUMMARY.md and rig_diagnostics/meshy-004_rigged/run_iter005/REPORT_task015_iter005.md; Dropbox /CUSTODIAN/visual_review/operator-3d-master-modeling-proof-v1/task015-iter005-foot-contact-review-20261028/REVIEW_MANIFEST.json; main archived OPERATOR_3D_NEUTRAL_IDLE_BLENDER_PROOF_V1.md documents the master as preserved source.
- Task-specific authority: Preserved Task 015 source/action/model hashes and actual host-local rig data, source Mixamo action timing, canonical eight-direction 128px view and root contract. No branch-only binary is claimed available on main.
- Work surface: Task-specific isolated derivative and report under the authorized model source_work/rig_diagnostics area, external ignored proof outputs, focused 3D contact tests; do not modify the original ITER005 branch/worktree.
- Publication inputs: custodian/tools/operator/animation_compiler/blender_neutral_idle_proof.py, custodian/tools/operator/animation_compiler/retarget_calibration.py, design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md, design/02_features/animation/OPERATOR_3D_TO_2_5D_PRODUCTION_ROADMAP_V1.md
- Change: (1) At claim, audit original Task 015 branch/worktree, remote refs and writers; if original owner retains this exact effort, resume it instead and cancel this successor. (2) Confirm authorized source/master hashes, preserve originals and record the user's visual disposition of ITER005 before further correction. (3) If authorized, create a new named experimental derivative with one local phase-aware contact/IK adjustment, never a global lift, pelvis rewrite or arbitrary gait change. (4) Preserve 21 authored samples/30 FPS and other geometry/action properties unless separately authorized. (5) Measure right/left actual evaluated sole vertices at integer and quarter/half/three-quarter frames, toe/heel landmarks, contact windows, gait translation assumptions, stretch, loop seam and drift. (6) Compare before/after whole 21-frame x eight-view 128px silhouettes, sparse 512px contact crops and GLB clean reimport. (7) Publish minimal compact evidence to /CUSTODIAN/visual_review/operator-3d-running-contact-followup-v1/ via publish_review_artifacts.py --important --reason, ask specifically about stance, foot contact, skating and residual cloth fragments, and STOP for the human decision.
- Preserve: Original ITER001–ITER005 blends/exports and source FBX, rest pose, rig weights/topology/mesh, arm swing, materials, authored root trajectory, idle candidates, active executor and runtime selectors.
- Non-goals: No new Running source identity, no Running Slide substitution, no model redesign, no contact-based automatic art approval, no runtime FPS or Asset V2 promotion, no overwritten original worktree.
- Acceptance: (A) Exact pinned originals match before/after hashes. (B) Whole-cycle integer and quarter/half/three-quarter subframes have reproducible numerical left/right foot and mesh-ground reports. (C) Corrected result either demonstrably improves the contact issue without material visual/geometry regressions, or clearly reports remaining defects; never change status to clean without evidence. (D) Timing/action/skeleton material identity and GLB replay remain bound and verified. (E) Human visual review occurs before any candidate promotion.
- Validation: Read-only original SHA proof; targeted contact-phase Blender measurements across frames/subframes, repeat pose and GLB clean reimport, focused 128px per-direction mask/bounds metrics, minimal actual motion visual handoff, git diff --check; preserve experimental statuses.
- Task overrides: TASK OVERRIDE: Do not claim while the prior Task 015 owner remains active or without the user's recorded gait decision; do not modify or replace preserved modeling source files, any runtime art, timings or approved Asset V2 family.
- Deferred: More global animation/sculpt/weight revisions require separate scope and human authorization; production is governed by existing Operator Workbench/runtime gates.

## Refresh Planning Authority

- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Refresh planning chat: not-recorded
- Refresh instruction: Reconcile exact Task 015 host claim/branch and visual ITER005 assessment. If Task 015 still owns the repair, resume its existing workstream rather than promoting this packet. If it has concluded and user authorizes a separate derivative, refresh source hash/path and approval scope before preflight.
- Claim state: draft/manual; not executable on publication.

## Next Handoff

- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Summary backlink: n/a
- Refresh reason: Accept/reject the candidate Running gait only after viewing its true movement and technical contact evidence.
- Next action: Report exact updated subframe metrics and Dropbox REVIEW_MANIFEST.json for human judgment.
- Blockers or open questions: Existing Task 015 ownership and human reference-gait approval unresolved.
