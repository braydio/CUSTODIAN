# REVIEW: AWAKENING 04→05 REGISTERED COMPOSITION CORRECTION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-awakening-04-05-registered-composition-correction-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `awakening-04-05-registered-composition-correction-v1`
- Locks: `awakening-runtime, awakening-art-registration, awakening-04-05-connector-presentation`
- Review: `none`
- Review target workstream: `awakening-04-05-registered-composition-correction-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_04_05_REGISTERED_COMPOSITION_CORRECTION_V1.md`
- Reviewed main: `60c258e88478b7e8b6b8bf7c08e59332763a5cbe`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Goal: Independently prove the runtime now preserves the user's exact axis-aligned 1502×2048 Dust→connector→Locker composition rather than the previously reviewed anchor-fit/rotated connector solution.
- Reviewed implementation acceptance: Reuse every Acceptance clause from archived `AWAKENING_04_05_REGISTERED_COMPOSITION_CORRECTION_V1.md`.
- Review evidence: `custodian/docs/ai_context/reports/assets/awakening_04_05_registered_composition_v1.json`;  exact runtime art rectangles; effective transforms; layer z-order; overlap pixel/rect metrics; renderer capture spanning all three pieces; bidirectional traversal; Asset V2/source receipts; Designation Locker regression proof.
- Correction threshold: Any nonzero per-piece rotation, independent rescale/recenter, >1px registered-bound drift, wrong overlap/order, connector missing chunk, raw overlap leakage, Designation Locker regression, or route falling off visible floor is blocking.
- Focused validation: re-run the dedicated registration smoke, three-layer capture, Asset V2 status/doctor where touched, Designation Locker smoke, Awakening geometry/progression, and bidirectional traversal.
- Review focus: Do not re-approve the old `-11.391598°` connector simply because its source contacts hit gameplay anchors. The user's registered composition is now placement authority.
- Acceptance: Findings-first fresh review. Pass only if the complete three-layer composition is preserved as one coordinate system and the old independent-fit solution is absent from live runtime.
- Non-goals: No new art, 05→06 work, HUD/console work, Hub work, or broad convergence.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `awakening-lower-upper-spine-connection`
- Next packet state: `ready after this review passes and interaction-feedback review is already complete`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Refresh reason: `none`
- Next action: Release lower→upper spine only after this exact-composition re-review passes.
- Blockers or open questions: `none`
