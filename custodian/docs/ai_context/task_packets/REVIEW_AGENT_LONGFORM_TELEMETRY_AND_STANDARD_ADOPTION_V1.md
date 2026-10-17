# REVIEW AGENT LONGFORM TELEMETRY AND STANDARD ADOPTION V1

- Packet schema: custodian.task_packet.v2
- Workstream: review-agent-longform-telemetry-and-standard-adoption-v1
- Status: draft
- Dispatch: manual
- Authoring handoff: auto
- Priority: P1
- Depends on: agent-longform-telemetry-and-standard-adoption-v1
- Locks: agent-workflow
- Kind: review
- Review: none
- Review stage: post-land
- Review modes: code, workflow
- Paired review workstream: none
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independent review of fail-closed supervisor changes
- Review target workstream: agent-longform-telemetry-and-standard-adoption-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/AGENT_LONGFORM_TELEMETRY_AND_STANDARD_ADOPTION_V1.md
- Reviewed main: <fill at claim>
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Goal: Independently falsify Truthful usage and standard execution reuse from landed code and immutable evidence, not an implementation summary.
- Completion boundary: Zero blocking defects/material evidence gaps with witnessed positive and negative tests and exact source/commit receipt; otherwise findings/correction lineage, never false pass.
- Current measured state: Draft, implementation not landed.
- Evidence: source spec, landed implementation, focused regressions, synthetic race and failure evidence, canonical changed-file report.
- Task-specific authority: current longform spec, dispatcher/RunTrace/review-runner/validation owner source.
- Work surface: review receipt and scoped correction packet authoring only; do not edit implementation code.
- Change: Independently attack every named test: cumulative-event duplicate, missing cache/token=unknown, interrupted JSONL, 9 landed of 12 attempted, scrub secret content, context compaction, review replay, standard task single-pair regression, manifest/index/changed validation. Re-run exact acceptance and verify preserved ownership. Confirm separate maintenance authorization vs actual tool permission, redacted and truthful exception audit, reviewer context provenance, and single-pair workflow staying free of bypass authority. Reject missing/zero selected and stale/forged reports.
- Preserve: fresh reviewer context and complete implementation behavioral contract.
- Non-goals: code feature changes or acceptance waivers.
- Acceptance: exact reviewed commit main reachability, focused and changed green, all negative controls, no material evidence gaps; findings remain unresolved.
- Validation: cumulative-event duplicate, missing cache/token=unknown, interrupted JSONL, 9 landed of 12 attempted, scrub secret content, context compaction, review replay, standard task single-pair regression, manifest/index/changed validation. and checked review receipt scope.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Review Receipt

- Status: pending
- Review target workstream: agent-longform-telemetry-and-standard-adoption-v1
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
- Detailed review summary: REVIEW_AGENT_LONGFORM_TELEMETRY_AND_STANDARD_ADOPTION_V1_CLAUDE_SUMMARY.md
- Follow-up workstream: <fill>

## Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Next action: Only open dependent LF work after passed review; correction otherwise.
- Blockers or open questions: implementation not landed yet.
