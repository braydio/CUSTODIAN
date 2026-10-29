# Review: Final Operator Idle Retarget Refinement

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-3d-neutral-idle-retarget-refinement-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: `operator-3d-neutral-idle-retarget-refinement-v1`
- Locks: `operator-3d-animation-pipeline`
- Kind: `review`
- Review: `none`
- Review target workstream: `operator-3d-neutral-idle-retarget-refinement-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_3D_IDLE_RETARGET_REFINEMENT_V1.md`
- Reviewed main: `fc307761111317c218bf39fd7e2c65d53ff118c5`
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Authoring handoff: `auto`
- Goal: Independently verify the bounded shared leg-space correction, preserved shoulder/arm calibration, full-frame contact/loop measurements, candidate-only artifact boundaries, and accurate deterministic pixel reporting.
- Completion boundary: Technical correctness and evidence only. Subjective appearance, default-idle selection, and artistic acceptance remain with the user and ChatGPT.
- Reviewed implementation acceptance: Verify actual anatomical axes and conversion math, lateral mapping, source asymmetry, IK reachability, ground/contact behavior, motion timing, loop endpoints, unchanged master/source inputs, canonical camera/bounds, and exact decoded-RGBA comparisons. Confirm the task did not alter production/runtime assets or claim visual approval.
- Review evidence: Landed diff and summary; exact source/master hashes; per-frame geometry/contact report; unit tests; current/refined/sources comparison sheets and videos; pixel-bound report; candidate receipts and file manifests.
- Correction threshold: Wrong coordinate space or axes, worsened paired spacing metrics without documented anatomical limit, hidden IK clamp/flip/penetration, altered timing or protected inputs, noncanonical camera changes, false RGBA equality, missing required evidence, or any production side effect is blocking.
- Focused validation: Rerun focused compiler/proof tests; independently inspect pelvis basis derivation and source-target mapping; verify all-frame metric calculations and contact intervals; verify media dimensions/timing, canonical sprite bounds and SHA manifests; confirm all candidate artifacts remain external and unapproved.
- Acceptance: Record a genuine technical PASS or structured findings. Do not judge idle naturalness, approve the default, or promote either clip. Stop after the technical verdict and human-review handoff.
- Non-goals: No implementation changes, no animation regeneration, no aesthetic approval, no default-idle selection, no runtime or production integration.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff
- Next action: Provide the technical verdict and artifact paths to the user/ChatGPT for visual assessment.
- Blockers or open questions: none

## Next Handoff
- Next workstream: `none`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6add1d40fb9c81918972e72d33e8d286-custodian-assets/c/6ae05096-99b0-83ea-bcbd-3720e795052f
- Refresh reason: Human visual approval and default-idle selection remain pending.
- Next action: Review candidate evidence before any further iteration or promotion.
- Blockers or open questions: none
