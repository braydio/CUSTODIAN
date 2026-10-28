# Review: Operator 3D Neutral Idle Retarget Fix V1

- Packet schema: custodian.task_packet.v2
- Workstream: review-operator-3d-neutral-idle-retarget-fix-v1
- Status: draft
- Dispatch: manual
- Priority: P1
- Depends on: operator-3d-neutral-idle-retarget-fix-v1
- Locks: operator-3d-animation-pipeline
- Kind: review
- Review: none
- Review target workstream: operator-3d-neutral-idle-retarget-fix-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/OPERATOR_3D_NEUTRAL_IDLE_RETARGET_FIX_V1.md
- Reviewed main: f566cdf302afbab2dd386f80a5605b5c2e76859a
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, asset-pipeline, workflow
- Review cycle: 0
- Max automatic review cycles: 2
- Authoring handoff: auto
- Goal: Independently verify the landed retarget calibration, deterministic RGBA QA and candidate-only evidence against all correction acceptance claims without judging artistic approval.
- Reviewed implementation acceptance: Verify rest-frame calibration math and coordinate spaces; preserved chain lengths and source bend/asymmetry; exact action timing/root-motion separation for both clips; exact RGBA equality regression; source/master preservation; repeatable metrics, candidate checks and review artifacts; no runtime or production changes.
- Review evidence: Landed diff and summary, pinned source/policy/calibration hashes, focused test logs, Blender inspection/render manifests, per-frame comparison report, repeated decoded-pixel checks, input before/after hashes and exact candidate receipt status.
- Correction threshold: A wrong transform order/space, source/target calibration inconsistency, lost motion/asymmetry, altered rest pose/geometry/weights, fabricated timing/loop claims, false pixel equality, stale/mismatched input hash, missing required evidence or production/runtime side effect is material. Subjective idle quality remains human-owned.
- Focused validation: Rerun the pure unit tests and QA RGB-same-alpha negative fixture; independently inspect retarget matrix math, policy/calibration hashes, source actions, endpoint checks, input preservation and candidate-only receipt. Compare objective joint/stance metrics and verify no full frame library or runtime publication entered the patch.
- Review focus: Confirm the target mapping uses the validated source and target rest frames rather than animation-specific posing; the same policy is applied to both clips; asymmetric source stance and knee/elbow behavior are preserved within target proportions; loop/root-motion contracts remain honest; and the prior rejected candidate remains intact.
- Acceptance: Record a genuine PASS or stable R0-NN findings with class, domain, affected acceptance, evidence, disposition and rationale. Blocking defects or material evidence gaps create a bounded correction/re-review packet. Do not approve either animation or decide which should be the default.
- Non-goals: No implementation edits, no aesthetic judgment, no further animation/model changes, no additional clips, no full directional library, no production/runtime promotion.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the implementation dependency is complete and archived on origin/main.
2. Start from a fresh reviewer context; inspect the exact landed implementation, summary, tests, calibration report and immutable inputs.
3. Verify objective technical acceptance independently and record findings before any disposition.
4. Stop after technical review. The user/ChatGPT retains visual approval and default-idle selection.

## Handoff
- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Refresh reason: Human visual assessment and default-idle selection remain required after technical review.
- Next action: Return the technical verdict and exact artifact/report paths for user and ChatGPT visual review.
- Blockers or open questions: none
