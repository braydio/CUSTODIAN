# Paired Review Resumed-Worktree Provenance V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-resumed-worktree-provenance-v1`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-conflict-resolution-merge-provenance-v1`
- Locks: `paired-review-resumed-worktree-provenance-v1`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-resumed-worktree-provenance-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `split claim-to-landing provenance is a protected independent-review trust boundary`
- Reviewed main: `7a8be70c366fd00b00d488b5385eccb6dff47e6e`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Allow independently verified source-span validation when a claimed worktree was recovered after a failed initial creation, without inventing a worktree publication event.
- Completion boundary: Add an exact, fail-closed resumed-worktree claim proof to `_split_landing_source_span()`; prove it against the immutable run `20261022T172255Z-7f774d406013` and landing `7a8be70c`; exercise source-span resolution and coordinator validation end to end; correct the prior implementation packet/summary's overstated acceptance record; publish and obtain a fresh independent review of this correction; then confirm the existing blocked review's read-only recovery plan succeeds. Do not apply that plan or mutate/relaunch its held claim.
- Current measured state: The correction review `review-agent-paired-review-conflict-resolution-merge-provenance-v1` run `20261022T175242Z-eb006ee7c5e9` is preserved but blocked before reviewer launch. Its plan fails with `split landing has missing or ambiguous exact workstream trace provenance`. Original implementation run `20261022T172255Z-7f774d406013` has one claim at base `9254dc8465820279723e35a3ec232557a9cf4cae`, one `worktree_create_begin`, two ordered `run_blocked` creation-failure records, then one `worktree_resumed` at the same base/path/branch; it has no `worktree_published`. Later main sync, landing at `7a8be70c`, and teardown are recorded. The immutable published trace ref is `refs/remotes/origin/agent-diagnostics/agent-paired-review-conflict-resolution-merge-provenance-v1/20261022T172255Z-7f774d406013`, SHA-256 `c540e3a42945c76db7e8c19ec9d33fd5a04d450294da09d3cbd466da97c0e870`.
- Evidence: `custodian/tools/agent/paired_review_host_validation.py::_split_landing_source_span`; `custodian/tools/agent/test_paired_review_runner.py`; original diagnostic trace ref above; archived implementation packet `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_CONFLICT_RESOLUTION_MERGE_PROVENANCE_V1.md`; blocked review run evidence under `.git/custodian-review-runs/review-agent-paired-review-conflict-resolution-merge-provenance-v1/20261022T175242Z-eb006ee7c5e9`; original held host-import review remains separate and unchanged.
- Task-specific authority: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; the two paired-review packets and exact immutable trace; `paired_review_host_validation.py` source-span and coordinator-validation contracts.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_CONFLICT_RESOLUTION_MERGE_PROVENANCE_V1.md`; `AGENT_PAIRED_REVIEW_CONFLICT_RESOLUTION_MERGE_PROVENANCE_V1_CLAUDE_SUMMARY.md`; `AGENT_PAIRED_REVIEW_RESUMED_WORKTREE_PROVENANCE_V1_CLAUDE_SUMMARY.md`.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_CONFLICT_RESOLUTION_MERGE_PROVENANCE_V1.md`; `AGENT_PAIRED_REVIEW_CONFLICT_RESOLUTION_MERGE_PROVENANCE_V1_CLAUDE_SUMMARY.md`.
- Change:
  1. Preserve the existing successful `worktree_published` claim-proof path unchanged.
  2. Add a second proof path only for exactly one `remote_claim_acquired`, one matching `worktree_create_begin`, at least one recorded failed-creation `run_blocked`, and exactly one later `worktree_resumed`; require unique ordered records in the same exact workstream/run/packet diagnostic trace.
  3. Bind claim OID and remote/local refs, workstream, run ID, agent, canonical branch, absolute worktree path, execution generation, and source-base SHA. Require `worktree_resumed.head == remote_claim_acquired.main_sha == worktree_create_begin.main_sha`; verify the claim object and its exact pinned ancestry. Require resumed evidence before source-changing work, sync, landing, and teardown.
  4. Independently verify archive identity, source paths/modes/blobs, final implementation ancestry, and the existing successful landing/teardown records. Preserve unique claim-to-landing pairing and all current source-span gates.
  5. Reject duplicate/ambiguous/foreign claims, changed base/branch/path/claim OID, absent failure, duplicate resume, wrong ordering, fabricated publication, unrelated landing, and any trace/ref identity mutation. Do not synthesize lifecycle events or make arbitrary `worktree_resumed` events publication substitutes.
  6. Add historical real-Git coverage for the exact run/landing; exercise `resolve_validation_source_span()`, `run_coordinator_validation()`, and `verify_coordinator_validation()`; include an end-to-end prelaunch test that proves this implementation's review trace remains launchable for both ordinary publication and authenticated failed-create/resume shape.
  7. Correct the archived prior implementation packet and its summary to say implementation tests passed but its historical recovery plan and independent acceptance were pending at that time; append a dated clarification for the newly verified host-validation blocker. Preserve the earlier account verbatim.
- Preserve: The blocked correction review claim/worktree/run and reviewer-not-launched disposition; prior implementation commit `44b1ce5b44ff9e40cb017cfef1cea9abba8826ab`, landing `7a8be70c366fd00b00d488b5385eccb6dff47e6e`, and original diagnostic trace; original host-import run `20261022T052405Z-1ce687862e23`; source-bearing merge witness logic from the prior correction.
- Non-goals: No claim deletion/parking/release; no replacement claim or reviewer relaunch for `review-agent-paired-review-conflict-resolution-merge-provenance-v1`; no mutation of either held review's checkout/evidence/verdict; no host-validation plan apply; no changes to the earlier host-import recovery run; no weakening of ordinary publication or merge provenance.
- Acceptance:
  - A1: The actual run's exact failed-create → resume chain resolves one unique claim/landing source span with base `9254dc84...` and final landing `7a8be70c...`.
  - A2: Existing successful-publication histories remain accepted and all adversarial mutations fail closed.
  - A3: Full `resolve_validation_source_span()`, coordinator validation, and coordinator verification succeed for the exact historical case and fail for altered evidence.
  - A4: End-to-end prelaunch simulation proves the correction's own review source-span can be authenticated for both publication and resumed-worktree lifecycle shapes.
  - A5: The prior completion truth/summary distinguishes focused tests and changed-file checks from unrun host-recovery plan and independent acceptance.
  - A6: After the correction's fresh paired review genuinely passes, the original blocked correction review's read-only recovery plan succeeds; do not apply it or launch the preserved reviewer without separate authorization.
- Validation: Focused exact historical tests; full `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; `run_coordinator_validation()` and `verify_coordinator_validation()` integration coverage; changed-file validation with complete coverage and zero skips; `py_compile`, packet-index validation, `git diff --check`; end-to-end review prelaunch simulation; after fresh review acceptance, exact same-run `--recover-host-validation --plan` only.
- Task overrides: `none`
- Deferred: Applying any same-run plan and launching/recovering the existing held reviewer require separate authorization after A6's plan passes.

## Context Pack

- Repomix: `none`

## Next Handoff
- Next workstream: `review-agent-paired-review-resumed-worktree-provenance-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: After implementation landing, independently review the exact resume proof and end-to-end prelaunch tests, then verify the existing correction review's read-only recovery plan. Do not alter or relaunch its held claim.
- Blockers or open questions: The existing correction review claim remains preserved in prelaunch recovery; its plan cannot pass until this correction lands and receives fresh independent approval.
