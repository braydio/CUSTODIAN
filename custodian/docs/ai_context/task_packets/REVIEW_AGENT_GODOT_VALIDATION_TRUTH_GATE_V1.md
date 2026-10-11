# REVIEW: AGENT GODOT VALIDATION TRUTH GATE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-godot-validation-truth-gate-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `agent-godot-validation-truth-gate-v1`
- Locks: `validation-infrastructure, asset-pipeline`
- Review: `none`
- Review target workstream: `agent-godot-validation-truth-gate-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_GODOT_VALIDATION_TRUTH_GATE_V1.md`
- Reviewed main: `4b5ba4c4f88f25cbde281ca6f148da58cd5648b2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Summary backlink: Repeat exact Authoring chat URL in durable review/recovery/closeout summary and Next Handoff.
- Goal: Independently falsify the new import/truth gate using resource failures masked by PASS markers and expected-rollback near misses.
- Reviewed implementation acceptance: All six acceptance items in archived PF3 packet, with actual Godot loader and Python-runner negative evidence.
- Review evidence: Archived implementation packet and summary, changed preflight/runner patterns, real source sidecars, isolated import/resource smoke and negative fixtures.
- Correction threshold: Fatal parse or resource error accepted as passed, broadened rollback regex, hidden invalid remap state, automatic network access or dirty coordination checkout triggers correction.
- Focused validation: Re-run invalid-sidecar, missing extension, PASS-plus-fatal, exact-rollback and near-miss fixture matrix; registered resource smoke; changed-file sweep.
- Review focus: Fail-closed diagnostics, anti-vacuity, Godot startup/import isolation, scoped metadata authority and no masking.
- Acceptance: Fresh independent findings-first R0-NN receipt and bounded correction/re-review for confirmed material defects; never edit reviewed implementation.
- Non-goals: No new importer, no art changes, no relaxed error thresholds and no reviewer runtime patch.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `agent-workstream-closeout-preflight-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: `After accepted review, continue PF4 under its own claim if eligible.`
- Blockers or open questions: `none`
