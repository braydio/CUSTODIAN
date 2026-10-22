# Review Paired Review Resumed-Worktree Provenance V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-resumed-worktree-provenance-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-resumed-worktree-provenance-v1`
- Locks: `paired-review-resumed-worktree-provenance-v1`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Review target workstream: `agent-paired-review-resumed-worktree-provenance-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md`
- Reviewed main: `7a8be70c366fd00b00d488b5385eccb6dff47e6e`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently establish that resumed-worktree lifecycle evidence authenticates only the exact failed-create/resume claim and does not weaken source-span provenance.
- Completion boundary: Reconstruct the actual immutable trace and Git history; review all implementation, negative tests, coordinator validation, prelaunch simulation, and acceptance-evidence correction; produce authentic findings-first review and canonical closeout. Do not apply the existing blocked review's plan, mutate its worktree/evidence, or launch its reviewer.
- Current measured state: The current blocked review run fails before launch with missing/ambiguous exact claim provenance because the source-span resolver has no claim record for the trace's failed `worktree_create_begin` followed by `worktree_resumed`.
- Evidence: Archived implementation packet and exact source/tests; immutable diagnostic ref `refs/remotes/origin/agent-diagnostics/agent-paired-review-conflict-resolution-merge-provenance-v1/20261022T172255Z-7f774d406013`, SHA-256 `c540e3a42945c76db7e8c19ec9d33fd5a04d450294da09d3cbd466da97c0e870`; original claim OID `840af1b9a74e97f25ec806ecc78ba9eea2cf0f06`; blocked review run evidence under `.git/custodian-review-runs/review-agent-paired-review-conflict-resolution-merge-provenance-v1/20261022T175242Z-eb006ee7c5e9`.
- Task-specific authority: Archived implementation packet `PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1.md`; `AGENT_WORKSTREAM_LIFECYCLE.md`; source-span and coordinator validation contracts.
- Work surface: Read-only review of `paired_review_host_validation.py`, `test_paired_review_runner.py`, `paired_review_runner.py`, lifecycle docs, archived prior packet and implementation summary, and the exact diagnostic trace.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_CONFLICT_RESOLUTION_MERGE_PROVENANCE_V1.md`.
- Review focus:
  1. Independently verify exact trace identity and unique ordered claim/create-failure/resume evidence, including claim OID, source base, branch and absolute path.
  2. Recompute the claim Git object, source ancestry, archive identity, file path/mode/blob coverage, and final landing/teardown.
  3. Confirm the old successful publication path is unchanged and arbitrary resumes, fabricated publications, duplicates, foreign claims, ordering changes, mismatched bases/paths/branches/OIDs, and unrelated landings fail closed.
  4. Run full source-span, coordinator validation/verifier, and prelaunch simulation coverage; confirm no skips.
  5. Verify the prior summary's historical text is preserved and its new clarification truthfully distinguishes implementation validation, host-plan result, and independent acceptance.
- Acceptance: PASS only with no blocking defects or material evidence gaps, exact historical provenance reproduced, all adversarial controls failing closed, end-to-end prelaunch simulation green, and both protected reviews preserved. Never infer review acceptance from implementation tests alone.
- Validation: Run the exact focused and full paired-review runner tests; inspect the immutable trace and Git objects; run `run_coordinator_validation()` / `verify_coordinator_validation()` cases and changed-file validation with complete coverage; check canonical review outcome parser, receipt delta, and coordinator closeout. Do not run plan apply or launch the held reviewer.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Start from a fresh reviewer context and reconstruct the target from `origin/main`.
2. Verify the original local diagnostic trace identity without modifying it.
3. Produce findings with stable IDs or a genuine PASS based on all acceptance criteria.
4. Preserve both held review claims/runs and do not apply either recovery plan.

## Handoff

- Next workstream: `review-agent-paired-review-conflict-resolution-merge-provenance-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: After this review genuinely passes, re-run the blocked correction review's read-only host-validation recovery plan and report its hash and result; stop for separate apply authorization.
- Blockers or open questions: The earlier host-import recovery run remains held and unchanged.
