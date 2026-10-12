# REVIEW AGENT LONGFORM VALIDATION ECONOMY V1

- Packet schema: custodian.task_packet.v2
- Workstream: review-agent-longform-validation-economy-v1
- Status: draft
- Dispatch: manual
- Priority: P1
- Depends on: agent-longform-validation-economy-v1
- Locks: agent-validation, agent-workflow
- Kind: review
- Review: none
- Review stage: post-land
- Review modes: code, workflow
- Paired review workstream: none
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independent review of fail-closed supervisor changes
- Review target workstream: agent-longform-validation-economy-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_LONGFORM_VALIDATION_ECONOMY_V1.md
- Reviewed main: <fill at claim>
- Authoring chat: not-recorded
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Goal: Independently falsify Explainable validation planner from landed code and immutable evidence, not an implementation summary.
- Completion boundary: Zero blocking defects/material evidence gaps with witnessed positive and negative tests and exact source/commit receipt; otherwise findings/correction lineage, never false pass.
- Current measured state: Draft, implementation not landed.
- Evidence: source spec, landed implementation, focused regressions, synthetic race and failure evidence, canonical changed-file report.
- Task-specific authority: current longform spec, dispatcher/RunTrace/review-runner/validation owner source.
- Work surface: review receipt and scoped correction packet authoring only; do not edit implementation code.
- Change: Independently attack every named test: synthetic shared manifest 38 passes/3 timeout/1 skip; changed owner mutation, bogus test exclusion, missing coverage, stale hashes, same-test baseline red, zero selected, Godot concurrency, one-per-test source ownership; final canonical --changed. Re-run exact acceptance and verify preserved ownership. Reject missing/zero selected and stale/forged reports.
- Preserve: fresh reviewer context and complete implementation behavioral contract.
- Non-goals: code feature changes or acceptance waivers.
- Acceptance: exact reviewed commit main reachability, focused and changed green, all negative controls, no material evidence gaps; findings remain unresolved.
- Validation: synthetic shared manifest 38 passes/3 timeout/1 skip; changed owner mutation, bogus test exclusion, missing coverage, stale hashes, same-test baseline red, zero selected, Godot concurrency, one-per-test source ownership; final canonical --changed. and checked review receipt scope.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Review Receipt

- Status: pending
- Review target workstream: agent-longform-validation-economy-v1
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
- Detailed review summary: REVIEW_AGENT_LONGFORM_VALIDATION_ECONOMY_V1_CLAUDE_SUMMARY.md
- Follow-up workstream: <fill>

## Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Next action: Only open dependent LF work after passed review; correction otherwise.
- Blockers or open questions: implementation not landed yet.
