# AGENT LONGFORM VALIDATION ECONOMY V1

- Packet schema: custodian.task_packet.v2
- Workstream: agent-longform-validation-economy-v1
- Status: draft
- Dispatch: manual
- Authoring handoff: auto
- Priority: P1
- Depends on: review-agent-longform-review-and-gate-hardening-v1
- Locks: agent-validation, agent-workflow
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, workflow
- Paired review workstream: review-agent-longform-validation-economy-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: longform execution safety demands independent falsification
- Reviewed main: 029c31b0396842bc566a5616c46ab03c0696ad80
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Visual review: none
- Goal: Explainable validation planner through the existing CUSTODIAN workflow authorities.
- Completion boundary: Implement the precise contract below with covered negative tests, final changed-file green and fresh independent post-land review. No false claim or acceptance.
- Current measured state: Design only; no longform command exists on main. next_execution_boundary is pure routing, not runner; source design/04_architecture/AGENT_LONGFORM_SESSION_FRAMEWORK_V1.md.
- Evidence: Oct 12 transcript-reconciled audit; live agent/workstream/review/validation tools and associated tests.
- Task-specific authority: longform design spec, current AGENTS, dispatch/workstream/RunTrace/paired_review_runner/validation owners; reviewed upstream OR1/OR2 and evidence-freshness work when actually landed.
- Work surface: scoped custodian/tools/agent/ scripts/tests; matching skill and wrapper for LF1; validation selector and tests for LF3 only; directly stale docs.
- Change: Add deterministic owner-aware --plan/report explanations to current manifest-driven validation selection, exposing direct/indirect owning changes, expected resource cost and exact manifest SHA. Separate focused and broad plan phases for scheduling, not final acceptance. Reuse validation_failure_triage and evidence freshness authority; no baseline waiver, skip, exclusion or timeout-based green. Bound Godot jobs via existing resource mutex. Report provenance-reusable tests separately from fresh runs, with exact schema, source SHA, manifest SHA, selection, coverage and accepted freshness authority; an eight-report green coordinator set is NEVER an independent PASS. Prove relevant runtime-change and manifest-change selections remain covered.
- Preserve: strict dispatch authority, no force Git, no user file loss, independent reviews, human design gates, Asset Pipeline V2, exact original packet acceptance and full final changed-file coverage.
- Non-goals: no new gameplay logic, parallel dispatch/review authority, blanket timeout increase, legacy summary rename, auto-bypass of any safety gate.
- Acceptance: All noted failure cases are provably blocked; a real run can execute bounded attempts and independently verify each outcome; no unauthorized main mutation and no requirement silently dropped.
- Validation: synthetic shared manifest 38 passes/3 timeout/1 skip; changed owner mutation, bogus test exclusion, missing coverage, stale hashes, same-test baseline red, zero selected, Godot concurrency, one-per-test source ownership, report reuse with identical input SHA/selection, stale SHA forcing rerun; final canonical --changed. Final check_ai_context, validate_review_pairing, task_packet_index and changed-file sweep.
- Task overrides: none
- Deferred: Other LF slices and standard path changes until their verified dependencies land.

## Handoff

- Next workstream: review-agent-longform-validation-economy-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Next action: After opt-in targeted authoring promotion, claim only after independently accepted LF2 review and eligible dispatcher lock.
- Blockers or open questions: Pending promotion, accepted LF2 review and live lock availability.
