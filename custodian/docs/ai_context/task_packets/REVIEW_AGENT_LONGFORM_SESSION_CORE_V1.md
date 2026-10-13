# REVIEW AGENT LONGFORM SESSION CORE V1

- Packet schema: custodian.task_packet.v2
- Workstream: review-agent-longform-session-core-v1
- Status: draft
- Dispatch: manual
- Priority: P1
- Depends on: agent-longform-session-core-v1
- Locks: agent-workflow
- Kind: review
- Review: none
- Review stage: post-land
- Review modes: workflow, code, architecture
- Paired review workstream: none
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independent review of fail-closed supervisor changes
- Review target workstream: agent-longform-session-core-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_LONGFORM_SESSION_CORE_V1.md
- Reviewed main: <fill at claim>
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Goal: Independently falsify Real CLI and durable accounting from landed code and immutable evidence, not an implementation summary.
- Completion boundary: Zero blocking defects/material evidence gaps with witnessed positive and negative tests and exact source/commit receipt; otherwise findings/correction lineage, never false pass.
- Current measured state: Draft, implementation not landed.
- Evidence: source spec, landed implementation, focused regressions, synthetic race and failure evidence, canonical changed-file report.
- Task-specific authority: current longform spec, dispatcher/RunTrace/review-runner/validation owner source.
- Work surface: review receipt and scoped correction packet authoring only; do not edit implementation code.
- Change: Independently attack every named test: temporary two-clone bare Git remote; fake Codex process; crash between claim/event, torn append, concurrent supervisors, duplicate resume, bad commit/validation, busy claim lock, parked attempt count, dirty root preservation, stop during child; existing test_next_execution_boundary, test_dispatch, test_workstream, paired_review runner, context/index/changed checks. Re-run exact acceptance and verify preserved ownership. Reject missing/zero selected and stale/forged reports.
- Preserve: fresh reviewer context and complete implementation behavioral contract.
- Non-goals: code feature changes or acceptance waivers.
- Acceptance: exact reviewed commit main reachability, focused and changed green, all negative controls, no material evidence gaps; findings remain unresolved.
- Validation: temporary two-clone bare Git remote; fake Codex process; crash between claim/event, torn append, concurrent supervisors, duplicate resume, bad commit/validation, busy claim lock, parked attempt count, dirty root preservation, stop during child; existing test_next_execution_boundary, test_dispatch, test_workstream, paired_review runner, context/index/changed checks. and checked review receipt scope.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Review Receipt

- Status: pending
- Review target workstream: agent-longform-session-core-v1
- Reviewed main: <fill>
- Reviewer context: fresh
- Reviewer provenance: <fill>
- Blocking defects: <fill>
- Material evidence gaps: <fill>
- Non-blocking issues: <fill>
- Optional improvements: <fill>
- Correction finding IDs: <fill>
- Next-slice finding IDs: <fill>
- Human-decision finding IDs: <fill>
- Detailed review summary: REVIEW_AGENT_LONGFORM_SESSION_CORE_V1_CLAUDE_SUMMARY.md
- Follow-up workstream: <fill>

## Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Next action: Only open dependent LF work after passed review; correction otherwise.
- Blockers or open questions: implementation not landed yet.
