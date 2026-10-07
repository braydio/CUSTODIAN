# REVIEW: OPERATOR 2.5D WORKBENCH REVIEW AUTOMATION + RUNTIME SANDBOX

- Packet schema: custodian.task_packet.v2
- Workstream: review-operator-2-5d-workbench-review-automation
- Kind: review
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: operator-2-5d-workbench-review-automation
- Locks: operator-workbench-ui, operator-art-agent, operator-review-automation, operator-runtime-preview
- Review: none
- Review target workstream: operator-2-5d-workbench-review-automation
- Review target packet: custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION.md
- Reviewed main: e56a75cfb76cdb5a3a430b21be267b1b4e20ed6e
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac60342-02a4-83e9-b402-577faeed63ff
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, workflow, visual, runtime
- Review cycle: 0
- Max automatic review cycles: 2
- Goal: Independently verify the landed implementation against its archived packet and live behavior.
- Reviewed implementation acceptance: The archived implementation packet Acceptance section is the exact contract.
- Review evidence: Reuse implementation receipts/fixtures first; gather fresh evidence only where acceptance is not established.
- Correction threshold: Correct confirmed correctness/authority defects or material proof gaps through bounded correction + re-review; route polish to the next slice.
- Focused validation: Rerun the smallest tests named by the archived packet plus git diff --check.
- Review focus: Consume canonical/polish QA rather than duplicate it; family/sequence truth comes from targets/timing; stale reference fails closed; sandbox shows selected pixels on real Operator context while production selector/catalog/runtime resources remain unchanged and teardown restores normal presentation.
- Acceptance: Findings-first receipt with stable IDs; zero blocking defects/material proof gaps for pass; do not patch reviewed implementation.
- Non-goals: No redesign, implementation fixes, production art mutation, or successor implementation.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Procedure

Follow custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md from fresh context.

## Handoff

- Next workstream: operator-2-5d-workbench-production-queue
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac60342-02a4-83e9-b402-577faeed63ff
- Summary backlink: include exact Authoring chat URL
- Refresh reason: WB25-5 must consume landed target/review receipt fields and actual verified-state counts.
- Next action: Return implementation/review evidence to the authoring chat and refresh the successor before claim.
- Blockers or open questions: successor intentionally draft until refresh
