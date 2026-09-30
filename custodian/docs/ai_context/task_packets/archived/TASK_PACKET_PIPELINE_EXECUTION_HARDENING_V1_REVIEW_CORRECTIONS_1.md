# CORRECTION: Task Packet Pipeline Execution Hardening V1 — Review Corrections 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `task-packet-pipeline-execution-hardening-v1-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-task-packet-pipeline-execution-hardening-v1`
- Locks: `agent-workflow`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture`
- Paired review workstream: `review-task-packet-pipeline-execution-hardening-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `7287fd62a`
- Parent implementation: `task-packet-pipeline-execution-hardening-v1` — `custodian/docs/ai_context/task_packets/archived/TASK_PACKET_PIPELINE_EXECUTION_HARDENING_V1.md`
- Parent review: `review-task-packet-pipeline-execution-hardening-v1` — `custodian/docs/ai_context/task_packets/archived/REVIEW_TASK_PACKET_PIPELINE_EXECUTION_HARDENING_V1.md`
- Findings addressed: `R0-01`
- Affected acceptance: The parent packet's own Acceptance claim "One shared parser/contract authority is used by dispatch plus new validator/index/finish checks" and Required Architecture item 1 ("there must be one parser/validation authority rather than dispatcher, validator, indexer, and finish each inventing their own front-matter grammar").
- Current defect/evidence: `custodian/tools/agent/task_packet_index.py`'s `_normalize_goal()` reimplements `task_packet_contract.py`'s `_header_field_with_continuations()` Goal-field-folding algorithm (including the same unindented-only break-condition logic) instead of reusing it, so the shared parser is not the single authority for every field derivation `task_packet_index.py` needs. Currently behaviorally correct (both implementations agree today), but a latent authority-duplication risk: a future change to the shared folding algorithm will not propagate here.
- Goal: Make `task_packet_index.py`'s Goal-text rendering reuse `task_packet_contract.py`'s field-folding logic instead of maintaining its own copy, so there is exactly one field-folding implementation for every consumer.
- Completion boundary: Done when `task_packet_index.py` no longer contains its own copy of the unindented-only continuation-folding loop; it must call a shared function from `task_packet_contract.py` to obtain the folded Goal text. `task_packet_index.py`'s existing Goal-specific behaviors (the `"(no Goal recorded)"` fallback and the 160-character truncation with `...`) are local rendering concerns for the README index, not parsing concerns, and may remain in `task_packet_index.py` as thin wrapping around the shared folded value.
- Current measured state: Re-derived directly from live `custodian/tools/agent/task_packet_index.py` and `custodian/tools/agent/task_packet_contract.py` at the `Reviewed main` SHA above (not carried over from the parent packet): `task_packet_contract.py` exposes `_header_field_with_continuations(text, field)` as a module-private helper (leading underscore) and the public `v2_required_field_values(text, fields=...)`, which calls it per-field but returns a dict keyed by the full `V2_REQUIRED_FIELDS`/`V2_CORRECTION_REQUIRED_FIELDS` sets, not a single ad hoc field name like `"Goal"` alone outside that fixed set — so `task_packet_index.py` cannot call `v2_required_field_values` directly for a one-off "Goal" lookup without importing the private helper or requesting a new small public wrapper.
- Evidence: `custodian/tools/agent/task_packet_index.py:_normalize_goal` (lines ~47-61); `custodian/tools/agent/task_packet_contract.py:_header_field_with_continuations`; `REVIEW_TASK_PACKET_PIPELINE_EXECUTION_HARDENING_V1.md`'s `## Independent Review` receipt, finding `R0-01`.
- Task-specific authority: `custodian/tools/agent/task_packet_contract.py` (the shared parser authority this correction must actually route through); `custodian/tools/agent/task_packet_index.py`; the parent packet's Required Architecture item 1.
- Work surface: `custodian/tools/agent/task_packet_contract.py` (add one small public function, e.g. `field_value(text, field)` or `header_field(text, field)`, that is simply the existing `_header_field_with_continuations` made public — do not change its folding behavior); `custodian/tools/agent/task_packet_index.py` (`_normalize_goal` calls the new public function instead of its own loop); `custodian/tools/agent/test_task_packet_index.py` and/or `custodian/tools/agent/test_task_packet_contract.py` (add a focused test proving `task_packet_index.py` no longer contains a parallel folding loop and that Goal rendering still matches existing `test_task_packet_index.py` expectations).
- Required correction: Expose the shared continuation-folding function as a small public name in `task_packet_contract.py` without changing its behavior, and change `task_packet_index.py._normalize_goal` to call it for the raw Goal value, keeping only the README-rendering-specific fallback text and truncation local to `task_packet_index.py`.
- Preserve: All 10 existing `test_task_packet_index.py` assertions (missing/stale/duplicate entries, manual exclusion, deterministic ordering, malformed-metadata exclusion, idempotence, byte preservation) must continue to pass unmodified; the rendered Goal text for every existing fixture must be byte-identical before and after this correction (this is a pure internal refactor, not a behavior change).
- Non-goals: Do not change `_header_field_with_continuations`'s folding algorithm itself (already fixed in the parent packet); do not touch `dispatch.py`, `workstream.py`, `check_ai_context.py`, or any procgen content; do not migrate the live README's `Ready / Auto Dispatch` section (still deferred, unrelated to this correction).
- Acceptance: `task_packet_index.py` contains no regex-based field-continuation-folding loop of its own; `_normalize_goal` (or its replacement) calls a shared `task_packet_contract.py` function for the folded Goal value; all existing `test_task_packet_index.py` tests pass unmodified with identical rendered output; a new focused test demonstrates that changing the shared folding function's behavior (e.g. via monkeypatching in a test) changes `task_packet_index.py`'s rendered Goal output too, proving it is not an independent copy.
- Validation: `python3 custodian/tools/agent/test_task_packet_index.py`; `python3 custodian/tools/agent/test_task_packet_contract.py`; `python3 -m py_compile` on both changed files; `python3 custodian/tools/agent/check_ai_context.py`; `git diff --check`. No broader sweep needed; this is a narrow internal refactor.
- Task overrides: `none`
- Deferred: Nothing further deferred by this correction; it fully closes finding R0-01.

## Completion Truth

- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance evidence: `task_packet_index.py::_normalize_goal` calls the public `task_packet_contract.py::header_field` helper; its own continuation-folding loop is removed. The focused monkeypatch test proves rendered Goal text follows the shared helper. Existing index output assertions pass unchanged.
- Superseded/legacy production path disposition: `n/a`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The tasking-instructions request added a timed expiry requirement beyond the correction packet's parser scope.
- Root cause / contributing factors: The repository already had a self-removing temporary-instruction workflow, so the request could be implemented by extending its target list and schedule.
- Prevention / pipeline improvement: Added a smoke assertion for expiry time, skip policy, Claude exemption, and cleanup markers.
- Tooling / docs drift discovered: The existing cleanup schedule was 17 minutes after midnight; changed it to midnight UTC, matching midnight in America/New_York on the stated date.
- Follow-up: `fixed-in-scope`
- What worked: Reused the existing timed cleanup workflow and its marked-block convention.

## Completion Notes

- Exposed the existing field-folding behavior through `header_field` without changing parsing semantics and removed the indexer's duplicate fold loop.
- Added the expiring procgen task routing note requested by the user; Claude is explicitly allowed to claim and work those packets until 2026-10-01 00:00 America/New_York.
- Focused packet validation and workflow smoke are recorded in the closing summary.

## Handoff

- Next action: Claim `task-packet-pipeline-execution-hardening-v1-review-corrections-1` once `review-task-packet-pipeline-execution-hardening-v1` is complete and archived (this correction is itself part of that same review cycle's required follow-through, dependency-gated on the review packet's own completion per the ordinary paired-review lifecycle).
- Best starting files: `custodian/tools/agent/task_packet_contract.py`, `custodian/tools/agent/task_packet_index.py`, `custodian/tools/agent/test_task_packet_index.py`.
- Blockers or open questions: None. This is a small, mechanical, low-risk refactor.
