# AGENT LONGFORM REVIEW AND GATE HARDENING V1

- Packet schema: custodian.task_packet.v2
- Workstream: agent-longform-review-and-gate-hardening-v1
- Status: draft
- Dispatch: manual
- Priority: P1
- Depends on: review-agent-longform-session-core-v1
- Locks: agent-workflow, review-runner
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: workflow, code, runtime
- Paired review workstream: review-agent-longform-review-and-gate-hardening-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: longform execution safety demands independent falsification
- Reviewed main: 029c31b0396842bc566a5616c46ab03c0696ad80
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Visual review: none
- Goal: Review and human gate truth through the existing CUSTODIAN workflow authorities.
- Completion boundary: Implement the precise contract below with covered negative tests, final changed-file green and fresh independent post-land review. No false claim or acceptance.
- Current measured state: Design only; no longform command exists on main. next_execution_boundary is pure routing, not runner; source design/04_architecture/AGENT_LONGFORM_SESSION_FRAMEWORK_V1.md.
- Evidence: Oct 12 transcript-reconciled audit; live agent/workstream/review/validation tools and associated tests.
- Task-specific authority: longform design spec, current AGENTS, dispatch/workstream/RunTrace/paired_review_runner/validation owners; reviewed upstream OR1/OR2 and evidence-freshness work when actually landed.
- Work surface: scoped custodian/tools/agent/ scripts/tests; matching skill and wrapper for LF1; validation selector and tests for LF3 only; directly stale docs.
- Change: Extend LF supervisor exact paired-review preflight/recovery using existing runner, not an alternate runner. Before claim probe reviewer writable Git metadata, Godot import/cache and selected tests; preserve exact claim on infra failure. Zero selected or red/timeout/skipped/uncovered cannot pass. Exact review findings keep correction lineage. For Review:manual demand explicit verdict; for human/visual require explicit authoring chat/Dropbox disposition AND technical green. Packet-specified real-scene integration is mandatory despite passing intermediate aggregate.
- Preserve: strict dispatch authority, no force Git, no user file loss, independent reviews, human design gates, Asset Pipeline V2, exact original packet acceptance and full final changed-file coverage.
- Non-goals: no new gameplay logic, parallel dispatch/review authority, blanket timeout increase, legacy summary rename, auto-bypass of any safety gate.
- Acceptance: All noted failure cases are provably blocked; a real run can execute bounded attempts and independently verify each outcome; no unauthorized main mutation and no requirement silently dropped.
- Validation: read-only FETCH_HEAD/cache, reviewer zero-selection, stale receipt and duplicate claim, findings R0-01, post-exit recovery, manual no verdict, human pass plus 1 timeout/1 skip, sidearm scenario fail with 51 green; normal paired-review and changed-file suite. Final check_ai_context, validate_review_pairing, task_packet_index and changed-file sweep.
- Task overrides: none
- Deferred: Other LF slices and standard path changes until their verified dependencies land.

## Handoff

- Next workstream: review-agent-longform-review-and-gate-hardening-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Next action: Await explicit draft-pair promotion after targeted authoring preflight, then implement from latest main, land and fresh review.
- Blockers or open questions: draft/manual authoring publication, targeted authoring preflight, and formal promotion to main.
