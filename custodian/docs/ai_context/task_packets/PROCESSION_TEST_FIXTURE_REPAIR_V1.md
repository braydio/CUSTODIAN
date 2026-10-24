# Procession Review Provenance Test Fixture Repair

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-procession-test-fixture-repair-v1`
- Authoring handoff: `auto`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `paired-review-runner-tests`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, workflow`
- Paired review workstream: `review-agent-paired-review-procession-test-fixture-repair-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `canonical paired-review validation is blocked by stale historical fixture assumptions`
- Reviewed main: `edaae65a308ef4a96916afb3b3cf653ff4969ae9`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Repair the three pre-existing Procession failures in the canonical paired-review runner suite without changing production provenance rules or real review evidence.
- Completion boundary: The three identified Procession tests pass on an isolated correction branch, the complete paired-review runner unit suite and changed-file validation pass, and a fresh independent post-land review accepts the test-only change.
- Current measured state: At `origin/main@edaae65a308ef4a96916afb3b3cf653ff4969ae9`, `paired_review_runner_unit` fails two approval-history fixtures because they start at current main after the correction packet is archived, and one actual-source-span assertion because pinned merge `f01a4982f1f1ddd05e4eb68740a2b1bddcaeefe3` changes source files after the archive first parent.
- Evidence: Clean-main runner validation; disposable checkout probe from `49a93aa726e26bd40220d3bdb658079ea9da3440`; failure trace for `test_procession_recovery_actual_source_span_is_bounded`; exact merge path diff from `c0f9d325e75cdb121489898f9f34a5f5c47f3196` to `f01a4982f1f1ddd05e4eb68740a2b1bddcaeefe3`.
- Task-specific authority: `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; archived `AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1.md` and paired review packet.
- Work surface: `custodian/tools/agent/test_paired_review_runner.py`; root summary `AGENT_PAIRED_REVIEW_PROCESSION_TEST_FIXTURE_REPAIR_V1_CLAUDE_SUMMARY.md`.
- Publication inputs: `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1.md`.
- Change:
  1. Pin `_build_procession_scope_approval_history()` to verified historical pre-archive base `49a93aa726e26bd40220d3bdb658079ea9da3440`, and assert that this starting tree contains the active correction/review pair but no post-hoc source attestation.
  2. Keep the fixture’s synthetic archive transition, attestation creation, synthetic independent PASS, and hostile/missing/nonpassing approval checks intact; all records stay inside disposable Git repositories.
  3. Update `test_procession_recovery_actual_source_span_is_bounded` only to reflect the observed exact history: require the production source-span guard to reject merge `f01a4982...` because its changes after the archive first parent alter `paired_review_host_validation.py`, `test_paired_review_runner.py`, and `validation_manifest.json`. Assert all three paths in the rejection. Do not relax or modify production validation.
  4. Preserve test ownership and canonical validation selection; do not skip, xfail, delete, or weaken hostile cases.
- Preserve: Exact Procession review and archive identities; source-span and independent-PASS requirements; existing failure behavior for forged, missing, altered, or nonpassing approvals; the primary pre-validation recovery worktree and all its dirty files.
- Non-goals: No production validator changes, Procession gameplay/runtime edits, edits to real review receipts or reports, changes to any claim/lock/worktree outside this new workstream, or mapper implementation.
- Acceptance:
  - A1: Fixture base is the exact verified commit and explicitly proves the active packet/review and no-attestation preconditions.
  - A2: Both approval-history tests pass while retaining negative approval cases and requiring synthetic independent PASS before acceptance.
  - A3: The actual-source-span test rejects the exact source-changing main-sync merge and checks the complete three-path witness; no expected source provenance is broadened.
  - A4: All three original failing tests pass, then `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v` passes completely.
  - A5: `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`, AI-context, packet index, review-pairing, compile, and diff checks pass.
- Validation: Run the three named Procession tests first; then the full paired-review runner suite, canonical `paired_review_runner_unit`, and changed-file validation with full coverage. Also run `check_ai_context.py --json`, `task_packet_index.py`, `validate_review_pairing.py`, Python compile checks, and `git diff --check`.
- Task overrides: `none`
- Deferred: After this pair lands, resume the already-claimed `agent-paired-review-prevalidation-checkout-recovery-v1` without discarding or overwriting its changes.

## Next Handoff
- Next workstream: `review-agent-paired-review-procession-test-fixture-repair-v1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: After the fixture repair lands, run its fresh-context paired review, then resume the preserved pre-validation recovery claim.
- Blockers or open questions: The exact three-test failure traces must be reproduced before editing; no production source-span rule may be relaxed.
