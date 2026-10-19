# Paired Review Claim Base Ancestry Provenance V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-claim-base-ancestry-provenance-v1`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-source-bearing-archive-gate-v1`
- Locks: `paired-review-claim-base-ancestry-provenance`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-claim-base-ancestry-provenance-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Substantial provenance and review-host safety repair; independent review is required.`
- Reviewed main: `9cbbfef899957f2e3fff3306b74accf28cd846dc`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Visual review: `none`
- Goal: `Allow the source-span resolver to recognize a documented earlier failed claim as provenance for the same published checkout, without changing the authoritative source base or relaxing claim identity checks.`
- Completion boundary: `Implement and independently review ancestry-aware validation for the specific earlier-claim continuation. Preserve all existing held review runs. After review PASS, generate only a read-only recovery plan for the existing source-bearing review run and stop.`
- Current measured state: `At origin/main 9cbbfef899957f2e3fff3306b74accf28cd846dc, the source-bearing resolver rejects the landing trace because its earlier remote_claim_acquired event has main_sha 83bdbd1e53fdcb06b18a5a5645f70a050c3cba01 while the selected published claim base is 8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8. Git proves the former is an ancestor of the latter. The validation source base must remain 8fa7c190. Three held review claims and their run evidence remain preserved.`
- Evidence: `custodian/tools/agent/paired_review_host_validation.py::_split_landing_source_span; custodian/tools/agent/test_paired_review_runner.py; archived packet custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_SOURCE_BEARING_ARCHIVE_GATE_V1.md; claim trace refs refs/remotes/origin/agent-diagnostics/agent-paired-review-source-bearing-archive-gate-v1/20261019T022243Z-fbd7e4e2f3d7 and refs/remotes/origin/agent-diagnostics/agent-paired-review-source-bearing-archive-gate-v1/20261018T073442Z-9f32a80a4938; canonical landing 9cbbfef899957f2e3fff3306b74accf28cd846dc; protected review run IDs 20261019T024516Z-fcfcefa2d521, 20261018T065436Z-f77aa52cf7a1, and 20261018T014101Z-f4fd619029aa.`
- Task-specific authority: `custodian/AGENTS.md; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; archived source-bearing archive-gate packet and its paired-review provenance contract.`
- Work surface: `custodian/tools/agent/paired_review_host_validation.py::_split_landing_source_span and custodian/tools/agent/test_paired_review_runner.py. No held review artifacts, existing claims/worktrees, queue analyzer, runtime files, or other source-span policy.`
- Publication inputs: `none`
- Change: `For earlier remote_claim_acquired events in the verified landing trace, accept zero events or exactly one identity-verified earlier failed claim. Verify the run ID agrees with the trace ref and event, local_ref and remote_ref are canonical for this workstream/run, claim_oid is a full resolvable commit, its subject binds the workstream and run ID, and it has exactly one parent equal to the event main_sha. Accept that earlier base only when Git proves it is an ancestor of the selected published claim base. Keep source_base exactly equal to the selected published claim record base (8fa7c190 in the historical case); never widen the source span to the earlier failed-claim base or include intervening commits. Reject duplicate/ambiguous claims, identity mismatch, unrelated claims, and reversed ancestry. Preserve equality behavior for valid existing traces.`
- Preserve: `Exact trace-role binding, unique claim/landing pairing, canonical landing and archive checks, archive-only restrictions, main-sync restrictions, changed-file coverage and source/test ownership. Preserve the original three held review claims, their traces, worktrees, and evidence byte-for-byte.`
- Non-goals: `Do not launch, resume, release, replace, or accept any held review; do not continue W1; do not alter source-bearing archive policy beyond the earlier failed-claim ancestry case; do not sync/reset/rebase the project root; do not modify the untracked custodian_grunt_runtime_ab_v1.zip.`
- Acceptance: `A1: Historical source-bearing case resolves successfully with base exactly 8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8 and canonical head 5b5de5717ae10aa5bbacbd53433571aae016c555 (or the exact current packet-defined source head), with no paths from the intervening 83bdbd1e..8fa7c190 range. A2: Positive temporary-Git fixture accepts one run-identity-verified earlier claim whose base is ancestor of selected claim base and returns selected base unchanged. A3: Negative fixtures reject invalid/mismatched run and claim identity, duplicate or ambiguous traces/claims, unrelated claims, and reversed ancestry. A4: Existing equality, queue, archive-only, main-sync, 6519, and W1 cases remain passing. A5: Source and tests land in one validated implementation commit; packet archive, summary, and generated index land in a separate closeout commit with no source/test changes. A6: New paired independent review passes while all three protected runs remain unchanged. A7: After A6 only, create the read-only recovery plan for preserved source-bearing review run 20261019T024516Z-fcfcefa2d521 and stop without applying it.`
- Validation: `From custodian/tools/agent, run python3 -m unittest test_paired_review_runner -v. Also run python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py; python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json; git diff --check. Add focused real-historical resolver proof and verify exact source base/head and changed paths. Re-hash manifests and key files for all three protected review runs before and after. Use normal workstream finish, with source/tests and archive closeout in separate commits.`
- Task overrides: `none`
- Deferred: `Read-only recovery plan for existing source-bearing review run after independent PASS; no reviewer launch or plan application is authorized.`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `A1: exact historical resolution at reviewed main 9cbbfef899957f2e3fff3306b74accf28cd846dc returns selected source base 8fa7c190936ce98ca5a9bb93f28fcb4862c9acb8, source head 5b5de5717ae10aa5bbacbd53433571aae016c555, and only that implementation commit with the expected validator/test paths. A2/A3: synthetic real-Git cases pass for valid earlier ancestry, wrong local ref, mismatched subject/event run, duplicate claims, unrelated ancestry and reversed ancestry. A4: all 82 paired-review runner tests pass, including queue-frontier, archive-only, main-sync, 6519 and W1 historical cases; changed-file validation selects both owning suites with complete coverage. A5: source/test commit 4a89ce3c61b773619edf0206ae8905fb231e60b5 precedes this archive/summary/index-only closeout commit. All three held review-run file manifests match their pre-change SHA-256 values; their existing claims and worktrees remain preserved.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The first automatic packet handoff stopped on the review override wording, and the first focused unittest invocation used a module path that did not match the test file's import layout. Initial negative fixture combinations also shared trace refs, so they were split into independently isolated cases.`
- Root cause / contributing factors: `The handoff tool requires the exact bounded override from its template; this test module imports sibling runner modules directly and is intended to run from custodian/tools/agent.`
- Prevention / pipeline improvement: `Copy the exact paired-review override and run the suite from custodian/tools/agent (or through the changed-file validation harness). Keep negative provenance fixtures independently isolated.`
- Tooling / docs drift discovered: `The original packet validation command's package-qualified unittest path did not import in this environment; the validated command is python3 -m unittest test_paired_review_runner -v from custodian/tools/agent.`
- Follow-up: `none`
- What worked: `Real historical resolution and synthetic claim-identity/ancestry controls confirmed the selected source base remains 8fa7c190 while all protected review runs stayed byte-identical.`

## Next Handoff

- Next workstream: `review-agent-paired-review-claim-base-ancestry-provenance-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Refresh reason: `none`
- Next action: `Run the fresh-context independent review. Only after PASS, produce the read-only recovery plan for preserved source-bearing review run 20261019T024516Z-fcfcefa2d521 and stop without applying it or launching its reviewer.`
- Blockers or open questions: `All three original review claims and their traces, worktrees and evidence remain held and unchanged; no held reviewer has been launched.`

## Next Handoff

- Next workstream: `review-agent-paired-review-claim-base-ancestry-provenance-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Refresh reason: `none`
- Next action: `Run a fresh-context independent review of the landed ancestry correction. If it passes, produce the specifically authorized read-only recovery plan for preserved run 20261019T024516Z-fcfcefa2d521 and stop.`
- Blockers or open questions: `Three existing review claims remain held and immutable; do not launch them or continue W1.`
