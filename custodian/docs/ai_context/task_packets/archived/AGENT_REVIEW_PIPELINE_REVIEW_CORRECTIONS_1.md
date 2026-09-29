# AGENT REVIEW PIPELINE REVIEW CORRECTIONS 1

- Workstream: `agent-review-pipeline-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-agent-review-pipeline`
- Locks: `agent-workflow`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-review-pipeline-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Goal: Make the paired review consistency guard fail closed when an auto-reviewed implementation points at the wrong packet or its review packet cannot be auto-dispatched.
- Task-specific authority: `custodian/tools/agent/dispatch.py`, `custodian/tools/agent/validate_review_pairing.py`, `custodian/tools/agent/test_dispatch.py`, `custodian/docs/ai_context/task_packets/README.md`, and the archived `AGENT_REVIEW_PIPELINE.md` review contract.
- Change:
  - For an active `Review: auto` implementation packet, require the paired review packet to declare `Status: ready` and `Dispatch: auto`; a manual or non-ready pair must block implementation eligibility with a specific consistency error.
  - Require `Review target packet` and validate that it names the canonical archived path for the paired implementation packet. Missing, unrelated, or traversal paths must fail closed before implementation claim.
  - Keep the same validation authority shared by dispatcher status/claim and the standalone pairing validator.
  - Update the paired-review documentation and regression tests to cover these metadata mismatches and preserve historical packets with default `Review: none` behavior.
- Preserve: Existing generic dependency/lock scheduling, post-land review, historical packet compatibility, review receipt format, correction-cycle policy, and no-pre-land-review architecture.
- Non-goals: Do not change runtime/gameplay code, add a second scheduler, alter review-cycle semantics, or introduce a mandatory pre-land gate.
- Acceptance:
  - Correct auto-review pairs remain valid and become eligible after their implementation is archived complete.
  - A wrong/missing `Review target packet` blocks the declaring implementation and produces a clear guard diagnostic.
  - A paired review packet with `Dispatch: manual` or a non-`ready` status blocks the declaring implementation and cannot silently disable automatic review.
  - Temporary-repository tests exercise each negative case through both consistency validation and dispatcher eligibility; correct-pair and historical-default controls stay green.
  - `review_pairing_contract`, `test_dispatch.py`, `agent_workflow_smoke.py`, and changed-file validation pass.
- Task overrides: `none`
- Deferred: Mode-set equality between implementation and review packets is not changed by this correction.

## Ownership And Timing

- Owner: agent workflow / review orchestration
- Agent/session: Codex 2026-09-28
- Created: 2026-09-28
- Last updated: 2026-09-29

## Work Surface

- Files/systems to change: dispatcher pairing validator and parser tests; standalone validator expectations; task packet lifecycle documentation and focused validation ownership if needed.
- Related consumers or tests: `dispatch.py status`, `dispatch.py claim-next`, `dispatch.py claim`, `validate_review_pairing.py`, `test_dispatch.py`, and real active paired packets.

## Handoff

- Completion: The shared pairing guard now requires a ready, auto-dispatchable reviewer and the exact canonical archived target-packet path. Added dispatcher and validator regression coverage; docs updated.
- Validation: `test_dispatch.py` (56 tests), `validate_review_pairing.py` (6 live auto-review pairs), `agent_workflow_smoke.py`, `review_pairing_contract`, changed-file validation, Python compilation, and `git diff --check` passed.
- Next action: paired independent review on main.
- Blockers or open questions: none.
