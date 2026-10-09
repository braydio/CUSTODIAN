# REVIEW: WB25-2 Guided Ingress Resume and Collision Corrections

- Packet schema: custodian.task_packet.v2
- Workstream: review-operator-2-5d-workbench-ingress-review-corrections-1
- Kind: review
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: operator-2-5d-workbench-ingress-review-corrections-1
- Locks: operator-workbench-ui, operator-workbench-publish, operator-source-normalization, operator-art-generation-schema
- Review: none
- Review target workstream: operator-2-5d-workbench-ingress-review-corrections-1
- Review target packet: custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_WORKBENCH_INGRESS_REVIEW_CORRECTIONS_1.md
- Reviewed main: 0d4612f52e064b48c2cf5a157a6c95aec4a553a8
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, asset-pipeline, workflow
- Review cycle: 1
- Max automatic review cycles: 2
- Goal: Independently verify the landed bounded correction against R0-01 through R0-04 and its archived acceptance.
- Reviewed implementation acceptance: The archived correction Acceptance section is the exact contract; retain original WB25-2 publication/legacy/target invariants.
- Review evidence: Reuse correction regressions and durable receipts; independently falsify the READY persistence boundary, terminal proof staleness/document existence, mixed-state service progression, and OPUI default-root alternate-frame collision.
- Correction threshold: Confirmed correctness/authority defects or material acceptance-proof gaps require a bounded correction plus re-review; optional polish belongs to WB25-3.
- Focused validation: Rerun the correction's focused smokes and independently exercise all four original reproductions with negative controls, legacy-96 behavior and 2.5D publish refusal; git diff --check. Reuse green broader evidence unless stale or insufficient.
- Review focus: Source Session remains proof authority; package terminal hints cannot skip proof; valid artist edits survive restart; no destructive conversion/handoff repeat; every eligible direction can progress despite a blocked sibling; source scan agrees across actual default/root shapes.
- Acceptance: Findings-first receipt; record R0-01, R0-02, R0-03, R0-04 individually as fixed/unresolved/regressed with concrete evidence. Pass requires zero blocking defects/material proof gaps. Do not patch reviewed implementation.
- Non-goals: No implementation fixes, successor implementation, production art mutation, redesign or aesthetic approval.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

Follow custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md from fresh context. Retain original finding IDs; new findings use R1 IDs.

## Handoff

- Next workstream: operator-2-5d-workbench-polish-automation
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: WB25-3 must consume the accepted actual landed Source Session/Workbench package handoff and exact Art Agent seams after correction re-review.
- Next action: Return durable implementation/correction/re-review evidence to the authoring chat and refresh WB25-3 before claim.
- Blockers or open questions: WB25-3 intentionally draft until refresh; unresolved correction findings take precedence.

