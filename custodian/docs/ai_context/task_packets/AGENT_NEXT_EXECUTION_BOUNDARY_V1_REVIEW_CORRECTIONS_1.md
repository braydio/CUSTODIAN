# CORRECTION: NEXT EXECUTION BOUNDARY SCOPED GENERAL FALLBACK (R0-01)

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-next-execution-boundary-v1-review-corrections-1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-agent-next-execution-boundary-v1`
- Locks: `agent-workflow`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-next-execution-boundary-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Review rationale: `Correct the blocking R0-01 scope bypass without weakening dispatcher claim authority or the finite pair budget`
- Reviewed main: `3384cb990547452f1e0cd7dbe5689bd983a7282d`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Parent implementation: `agent-next-execution-boundary-v1`; `custodian/docs/ai_context/task_packets/archived/AGENT_NEXT_EXECUTION_BOUNDARY_V1.md`
- Parent review: `review-agent-next-execution-boundary-v1`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_NEXT_EXECUTION_BOUNDARY_V1.md`
- Findings addressed: `R0-01`
- Affected acceptance: Acceptance 2 of the parent: explicit `continuous-chain` execution honors the user-designated scope and never selects unrelated successors.
- Current defect/evidence: The parent review (run `20261011T233501Z-61ac2d68e601`, recovered as `findings` with `R0-01` retained) reproduced `scope: ["allowed-task"]`, `explicit_general_next: true`, no named successor and an eligible general candidate `outside-scope-task` returning `claim_general_next`. The fallback checks only `general_candidate_eligible` and `general_candidate_kind`, never `general_candidate_workstream` against scope, and `dispatch.py claim-next` accepts no scope.
- Goal: Make scoped general fallback fail closed unless the dispatcher supplies a candidate identity that can be checked against the requested scope.
- Completion boundary: `next_execution_boundary.py` returns `claim_general_next` for a scoped request only when `general_candidate_workstream` is present and inside scope; otherwise it stops with an explicit reason. Unscoped behavior is unchanged.
- Current measured state: `next_execution_boundary.py` general fallback (around `explicit_general_next` handling) and `test_next_execution_boundary.py`, which has no scoped general-fallback case; its explicit fallback fixture omits scope.
- Evidence: R0-01 in the archived parent review; `custodian/tools/agent/next_execution_boundary.py`; `custodian/tools/agent/test_next_execution_boundary.py`.
- Task-specific authority: `dispatch.py` keeps claim authority. The boundary helper only decides; it must not claim, rank or invent a candidate.
- Work surface: `custodian/tools/agent/next_execution_boundary.py`; `custodian/tools/agent/test_next_execution_boundary.py`; the `custodian-next` skill text only if it states the fallback rule; the packet's own lifecycle metadata.
- Required correction: 1) Reproduce R0-01 first with a failing regression. 2) For a request with a non-empty scope, `claim_general_next` requires `general_candidate_workstream` to be a string that is in scope; a missing identity or an out-of-scope identity stops with a distinct reason and never returns a claim action. 3) Add in-scope, out-of-scope and missing-identity regressions, plus an unscoped regression proving unchanged behavior. 4) Preserve the explicit finite pair budget and every existing stop reason.
- Preserve: Dispatcher claim authority, the single-pair default, the `max_pairs` budget, review-cycle containment, human/manual gates and the pinned parent implementation packet bytes.
- Non-goals: No change to `dispatch.py`, no scope parameter for `claim-next`, no redesign of the boundary rule table, no edit to the archived parent or its review.
- Acceptance: A) A scoped request with an out-of-scope general candidate stops and never claims; B) a scoped request with no candidate identity stops; C) a scoped request with an in-scope candidate still claims; D) an unscoped request behaves exactly as before; E) the full existing boundary suite stays green; F) the first new regression fails against the unfixed code.
- Validation: `python3 -m unittest -q` for `test_next_execution_boundary`; the existing dispatch/paired-review/workstream tests; `check_ai_context.py --json`; `validate_review_pairing.py`; `task_packet_index.py`; `run_validation.py --changed --base origin/main --json`; `git diff --check`.
- Task overrides: `none`
- Deferred: Teaching `dispatch.py claim-next` to accept a scope, which would be a separate dispatcher change.

## Handoff

- Next workstream: `review-agent-next-execution-boundary-v1-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: Implement the bounded R0-01 correction, finish and land normally, then run the exact fresh-context cycle-1 re-review.
- Blockers or open questions: `none`
