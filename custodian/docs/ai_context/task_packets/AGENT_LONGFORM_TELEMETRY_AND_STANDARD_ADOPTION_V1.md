# AGENT LONGFORM TELEMETRY AND STANDARD ADOPTION V1

- Packet schema: custodian.task_packet.v2
- Workstream: agent-longform-telemetry-and-standard-adoption-v1
- Status: draft
- Dispatch: manual
- Authoring handoff: auto
- Priority: P1
- Depends on: review-agent-longform-validation-economy-v1
- Locks: agent-workflow
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, workflow
- Paired review workstream: review-agent-longform-telemetry-and-standard-adoption-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: longform execution safety demands independent falsification
- Reviewed main: 029c31b0396842bc566a5616c46ab03c0696ad80
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Visual review: none
- Goal: Truthful usage and standard execution reuse through the existing CUSTODIAN workflow authorities.
- Completion boundary: Implement the precise contract below with covered negative tests, final changed-file green and fresh independent post-land review. No false claim or acceptance.
- Current measured state: Design only; no longform command exists on main. next_execution_boundary is pure routing, not runner; source design/04_architecture/AGENT_LONGFORM_SESSION_FRAMEWORK_V1.md.
- Evidence: Oct 12 transcript-reconciled audit; live agent/workstream/review/validation tools and associated tests.
- Task-specific authority: longform design spec, current AGENTS, dispatch/workstream/RunTrace/paired_review_runner/validation owners; reviewed upstream OR1/OR2 and evidence-freshness work when actually landed.
- Work surface: scoped custodian/tools/agent/ scripts/tests; matching skill and wrapper for LF1; validation selector and tests for LF3 only; directly stale docs.
- Change: Collect Codex native structured model/token/cached/uncached/reasoning/compaction data when available, safely reconcile cumulative vs delta events and return unknown/null otherwise. Record attempt/land/review/accepted denominators, errors, retries, wall/tool time and tokens per accepted pair in redacted JSON/CSV/Markdown exports. Keep legacy *_CLAUDE_SUMMARY files without inferring executor. Reuse narrow proven receipt/status adapters in standard single-pair custodian-next without changing its default one-pair semantics or gates. Export original owner/run/exception authorization, exact shell permission refusal, root sync blockers, administrative findings versus verified accepted PASS, new reviewer continuation cost and provenance-reused report cost. Unknown values remain null; permission denial never implies an alternate permitted path.
- Preserve: strict dispatch authority, no force Git, no user file loss, independent reviews, human design gates, Asset Pipeline V2, exact original packet acceptance and full final changed-file coverage.
- Non-goals: no new gameplay logic, parallel dispatch/review authority, blanket timeout increase, legacy summary rename, auto-bypass of any safety gate.
- Acceptance: All noted failure cases are provably blocked; a real run can execute bounded attempts and independently verify each outcome; no unauthorized main mutation and no requirement silently dropped.
- Validation: cumulative-event duplicate, missing cache/token=unknown, interrupted JSONL, 9 landed of 12 attempted, scrub secret content, context compaction, review replay, standard task single-pair regression, denied maintenance command with no fallback, archived findings not accepted, original protected claim still retained, redacted exception authorization, manifest/index/changed validation. Final check_ai_context, validate_review_pairing, task_packet_index and changed-file sweep.
- Task overrides: none
- Deferred: Other LF slices and standard path changes until their verified dependencies land.

## Handoff

- Next workstream: review-agent-longform-telemetry-and-standard-adoption-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Next action: After opt-in targeted authoring promotion, claim only after independently accepted LF3 review and eligible dispatcher lock.
- Blockers or open questions: Pending promotion, accepted LF3 review and live lock availability.
