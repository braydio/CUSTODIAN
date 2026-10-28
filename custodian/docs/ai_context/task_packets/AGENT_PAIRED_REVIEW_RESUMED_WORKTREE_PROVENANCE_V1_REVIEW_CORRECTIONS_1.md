# Correction: Paired Review Resumed-Worktree Provenance V1

- Packet schema: `custodian.task_packet.v2`
- Authoring handoff: `auto`
- Workstream: `agent-paired-review-resumed-worktree-provenance-v1-review-corrections-1`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P0`
- Depends on: `review-agent-paired-review-resumed-worktree-provenance-v1`
- Locks: `paired-review-resumed-worktree-provenance-v1`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-resumed-worktree-provenance-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `e637d68e9b34a6f653431e8a69054ac4cfcdd838`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad556b3-998c-83ea-8620-22173524205f`
- Parent implementation: `agent-paired-review-resumed-worktree-provenance-v1`; `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md`
- Parent review: `review-agent-paired-review-resumed-worktree-provenance-v1`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md`
- Findings addressed: `R0-01`
- Affected acceptance: Original A1–A3; the exact claim-to-create/resume/landing/teardown proof must authenticate only chronologically possible, identity-consistent lifecycle evidence.
- Current defect/evidence: Fresh real-Git review found `resolve_validation_source_span()` accepts swapped `landing_started`/`landing_completed` and `teardown_started`/`teardown_completed` records. A second exact positive is required for trace `agent-diagnostics/operator-3d-animation-batch-pipeline-v1/20261028T093229Z-201dfe64e1e5`: claim base `9988e8f6c42e39150d82f4e931f1af8f36e4bb76`, create base `b319ead51168a122224ddc5673c6d854e9fdddb9`, resumed HEAD `48081acad473894e39823aa87cf5ab5fe8c47896`, landing `a26f987a550778f0c4afaeeb7468a94a54de609b`.
- Goal: Authenticate the exact interrupted-fetch-and-resume lifecycle while rejecting impossible ordering or mismatched identities.
- Completion boundary: Correct the existing source-span verifier and focused real-Git tests only; do not change review outcomes, claims, or unrelated provenance paths.
- Current measured state: The historical resumed-worktree proof omits ordering checks; the exact Operator trace has a failed worktree creation at a later create base than the original claim base, then a same-run resume at the fetched main SHA and a landed archive.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; both archived parent packets; exact local diagnostic trace (host-private, verified by SHA and worktree evidence at execution).
- Evidence: Parent review summary finding `R0-01`; exact immutable Operator trace at `.git/custodian-workflow/traces/operator-3d-animation-batch-pipeline-v1/20261028T093229Z-201dfe64e1e5.jsonl`; source `custodian/tools/agent/paired_review_host_validation.py`; tests `custodian/tools/agent/test_paired_review_runner.py`.
- Task-specific authority: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; both archived parent packets; `paired_review_host_validation.py`.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; root closing summary.
- Required correction:
  1. Require ordered lifecycle event records and reject timestamp contradictions for create, failure, resume, landing start/completion, and teardown start/completion.
  2. Model claim base and worktree-creation base as distinct values. Accept the Operator trace only when the same exact run proves the fetch failure, branch/path/claim identity remain exact, the resumed HEAD is a verified first-parent fast-forward descendant, and archive landing ancestry and teardown match.
  3. Keep all established claim identity, exact run/ref, original worktree, SHA ancestry, immutable trace and archive landing checks. No generic recovery/provenance bypass.
- Preserve: Existing successful publication flow, historical same-base resume proof, all current claim locks, original review/claim/run evidence, source-span boundaries, and downstream Task 001 review gate.
- Non-goals: Do not alter ITER005 or animation inputs; do not implement rendering; do not edit review verdicts; do not weaken source-span validation or add a general trace exception.
- Acceptance:
  - A1 (`R0-01`): Real-Git negative fixtures reject swapped landing and teardown event pairs, timestamp/order contradictions, duplicate/forged lifecycle records, and divergent histories.
  - A2 (`R0-01`): The exact Operator trace resolves with claim base, creation base, resumed SHA, original worktree, exact run ID and landing each independently verified; no inferred or invented provenance is introduced.
  - A3 (`R0-01`): Negative controls reject inconsistent SHAs, unrelated worktrees, forged fetch failure/resume events, altered claim identity, and non-first-parent/divergent histories.
  - A4: Existing normal publication and same-base recovered-creation tests continue to pass; focused tests and registered changed-file validation pass with complete coverage and zero skips.
- Validation: Focused real-Git tests in `test_paired_review_runner.py`; full `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; exact source-span resolution of the Operator trace; `py_compile`; changed-file validation; packet index and `git diff --check`.
- Task overrides: `none`
- Deferred: The Task 001 review and Neutral Idle execution remain downstream of this correction's independent review and dispatcher eligibility.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: low
- What went wrong: none
- Root cause / contributing factors: The prior positive coverage omitted a fetch race in which worktree creation began after the claim base had advanced.
- Prevention / pipeline improvement: Exercise exact production traces as real-Git positives and mutate chronological event order as a negative control.
- Tooling / docs drift discovered: none
- Follow-up: review-agent-paired-review-resumed-worktree-provenance-v1-review-corrections-1
- What worked: Exact immutable trace evidence identifies distinct claim, create, and resumed SHAs.

## Next Handoff
- Next workstream: `review-agent-paired-review-resumed-worktree-provenance-v1-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad556b3-998c-83ea-8620-22173524205f`
- Refresh reason: `none`
- Next action: `dispatcher claim after this review and correction pair are published`
- Blockers or open questions: `none`
