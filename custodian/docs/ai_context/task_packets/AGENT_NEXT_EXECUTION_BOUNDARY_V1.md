# AGENT NEXT EXECUTION BOUNDARY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-next-execution-boundary-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-agent-paired-review-coordinator-boundary-v1`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-next-execution-boundary-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Independent fresh-context review required for high-impact pipeline safety and resource-use changes`
- Reviewed main: `2ffbbec13d55a939096750d059602ea56047cae3`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Goal: Make a routine request to implement the next CUSTODIAN packet execute exactly one implementation plus its paired independent review, then stop; expose explicit bounded continuous-chain mode for users who actually request it.
- Completion boundary: Change CUSTODIAN Next skill and the narrow existing orchestration/receipt seams to provide deterministic, testable invocation-scoped execution limits and compact milestones without changing dispatcher claim or successor authority.
- Current measured state: Current `.agents/skills/custodian-next/SKILL.md` instructs repeated same-series successor execution and suppresses routine user-facing handoffs. The 2026-10-11 Codex export starts with 'Please claim and implement the next custodian task packet' and chains many independent implementation/review pairs until interrupted. `dispatch.py claim-next` owns only one atomic claim, not user intent or execution budget. Normal named dependency chains and review gates already exist.
- Evidence: 2026-10-11 complete Codex chat log, `.agents/skills/custodian-next/SKILL.md`, root AGENTS.md CUSTODIAN Next Shortcut, `custodian/tools/agent/dispatch.py` and its claim/last-claim receipt, `paired_review_runner.py`, `workstream.py`, existing ULTRA_CODEX_PACKET_WORKER packet (separate host policy).
- Task-specific authority: Existing dispatcher for claim selection, original packet/Next Handoff for named successors, paired_review_runner for fresh review. The Codex Next skill owns user-facing routing; a small pure execution-boundary helper may enforce an invocation limit but must not implement a second dispatcher.
- Work surface: Edit `.agents/skills/custodian-next/SKILL.md`, minimum corresponding root `AGENTS.md` text, and add a small focused `custodian/tools/agent/next_execution_boundary.py` helper with temporary-repo/pure-fixture tests only if needed to make the budget deterministically enforceable.
- Change: Default mode `single-pair` for 'next task' and unqualified `$custodian-next`: at most one newly claimed implementation/correction plus its required paired review/re-review chain; stop with a compact final status after accepted review or a real gate. Existing claimed branch means resume that packet, not second claim; continue its paired review if in scope. An expressly requested `continuous-chain` mode may advance only along authorized Next Handoff DAG successors, with explicit positive `max_pairs` and optional user-designated scope; never treat absence of `Next workstream` or an unrelated global-ready item as a free continuation. If explicit general-next, may select exactly one new eligible implementation, then honor mode budget. Emit a compact structured per-workstream boundary receipt (workstream, phase, landed SHA, review status, elapsed/validation summary, next eligibility) under existing durable log ownership; print stage updates at pair boundaries and do not dump entire queue. Never infer active ownership solely from stale `last-claim`; reconcile branch/worktree/ref/status. Respect manual/refresh/human/validation gates.
- Preserve: No change to actual packet acceptance, independent review or correction-cycle limits; existing same-series dependency traversal for explicitly named goals, no skipped human gate; dispatcher locks and permission boundaries; Ultra remote worker behavior left alone.
- Non-goals: No second dispatcher, generic remote daemon, perpetual agent, first-party telemetry service, model selection changes or global token-accounting instrumentation.
- Acceptance: 1) A single 'please claim and implement next packet' invocation terminates after one completed implementation+paired review even if its Next Handoff points to another ready packet; 2) explicit continuous-chain honors max_pairs and scope, stops at human/manual gates and never selects unrelated successors; 3) review correction cycles remain inside the first pair; 4) stale last-claim, claimed active worktree and global lock contention do not create duplicate claims; 5) structured summary for each completed pair and final stop shows exact SHA and status; 6) targeted tests cover single/continuous, pause/resume, no successor, blocked review, ambiguous handoff and automatic fallback; 7) dispatcher behavior itself unchanged.
- Validation: Implement rule table and fixtures for 1/2/3-pair scenarios, active-workstream resume and stale last-claim; test changed `.agents/skills/custodian-next` routing against the pure boundary helper, plus existing dispatch/paired-review/workstream tests; check_ai_context.py --json, validate_review_pairing.py, task_packet_index.py, run_validation.py --changed --base origin/main --json; git diff --check.
- Task overrides: `none`
- Deferred: Automated policy-based job scheduler, global prioritization, fee/token budgets and webhook progress notifications.

## Handoff

- Next workstream: `review-agent-next-execution-boundary-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: `After completed implementation landing/archival, initiate this exact independent fresh-context paired review.`
- Blockers or open questions: `none`
