# Paired Review Source-Span Main-Sync Recovery V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-source-span-main-sync-recovery-v1`
- Kind: `implementation`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-host-validation-recovery-v1-review-corrections-1`
- Locks: `paired-review-source-span-provenance`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-source-span-main-sync-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `security-sensitive source-span provenance must have an independent negative-control review`
- Reviewed main: `d26d8d535ddfa63240a29ad655e27bfa9ddb8802`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Visual review: `none`
- Goal: `Allow exact, legitimate main-sync merge landing provenance to validate a pinned archive-only implementation without accepting unrelated source or forged lifecycle traces.`
- Completion boundary: `Correct the two confirmed resolver gates (landing trace merge identity, legitimate archive closeout paths); add exact historical and adversarial regression tests. Land normally, then independently review before attempting the preserved review run.`
- Current measured state: `Implemented and validated the bounded archive/main-sync split. Exact historical resolution retains canonical archive 1fa679c33f49bf3ee7d08072c82f747809b00b35 while recovering source range 06cbe9521dfa8efe82fb5820709646ca6d1486e7..48a0bfc4836fbc88cd4406cc814959dcfc6e453b. Trace merge f12717e61213d7d30ae6b3e670d45e71507cd784 is independently tied to its exact main_sync(changed=true) second parent 623dd45ddf35f9c88460386ac047db3e9c1f8d52 and remains an ancestor of the pinned reviewed main.`
- Evidence: `custodian/tools/agent/paired_review_host_validation.py::_split_landing_source_span and resolve_validation_source_span; custodian/tools/agent/test_paired_review_runner.py::PairedReviewHostValidationTests; exact remote diagnostic trace agent-diagnostics/agent-paired-review-host-validation-recovery-v1-review-corrections-1/20261018T005240Z-25f5254d4395:trace.jsonl; archived target AGENT_PAIRED_REVIEW_HOST_VALIDATION_RECOVERY_V1_REVIEW_CORRECTIONS_1.md; preserved review run 20261018T014101Z-f4fd619029aa under .git/custodian-review-runs/review-agent-paired-review-host-validation-recovery-v1-review-corrections-1/.`
- Task-specific authority: `The existing fail-closed source-span resolver and lifecycle trace contract; current paired review validation and post-land archive/receipt semantics.`
- Work surface: `custodian/tools/agent/paired_review_host_validation.py; custodian/tools/agent/test_paired_review_runner.py; narrowly update lifecycle docs only if their active contract is inconsistent.`
- Change: `Retain canonical archive identity at 1fa679c3. Permit landing_started.start_sha and landing_completed.head to equal either canonical archive SHA (existing case) OR one verified two-parent main-sync merge whose first parent equals the archive SHA and second parent equals the uniquely matching prior-main SHA from main_sync(changed=true, head=merge, main_sha=second parent), with exactly matching workstream/packet/run identity. The trace landing must be an ancestor of pinned reviewed main. Check the merge leaves the archived target packet and every source/test path in the recovered source span byte-identical to the archive-first-parent version, and reject a merge carrying altered target or source. Continue deriving source_base/source_head and the linear, no-merge implementation span from the archive commit's first-parent ancestry, NOT from the main-sync merge. Preserve an explicit trace merge identity in provenance for the merge case. Permit archive-only closeout paths consisting exclusively of that workstream's active packet deletion, canonical archived packet creation, its exact root CLAUDE_SUMMARY.md, and generated task_packets/README.md; continue rejecting any other path or executable change. Do not rewrite original trace or original run evidence.`
- Preserve: `Existing normal direct-archive trace case and strict unique trace matching; source-bearing linear-history, packet Reviewed main ancestry, documented implementation path, coverage, hash, immutable evidence and single-claim rules; original W1 run, original correction review run, root checkout .gitignore, and all operator preservation refs unchanged.`
- Non-goals: `No generic merge acceptance or merge-tree laundering; no unpinned fallbacks; no claim rewriting, reviewer launch, run apply, W2/W5 release, unrelated lifecycle refactor, or edits to the archived correction's source.`
- Acceptance: `1) Exact historical resolve_validation_source_span against reviewed f12717e6, canonical archive 1fa679c3 and archived correction packet returns source range 06cbe952..48a0bfc4 and the expected two changed Python files, without using the merge as source head. 2) Existing W1 b5b85ca4 source-span case remains unchanged. 3) Forged/missing/ambiguous trace, incorrect main_sync, wrong parent order or count, modified source/test or archived target in merge, unrelated archive-closeout file, merged source span and undocumented code fail closed. 4) Successful validation writes exclusive evidence and post-run verification re-resolves the same provenance; no protected original run evidence changed. 5) This correction lands and passes fresh independent review before resuming the existing blocked review run.`
- Validation: `Run python3 custodian/tools/agent/test_paired_review_runner.py with real temporary Git merge fixtures plus the exact historical Git refs and negative controls; run python3 custodian/tools/agent/test_dispatch.py, python3 custodian/tools/agent/test_workstream.py, python3 custodian/tools/agent/test_review_outcome.py, python3 custodian/tools/agent/test_task_packet_contract.py; then python3 custodian/tools/validation/run_validation.py --changed --json with complete changed-file coverage, py_compile and git diff --check. Run only read-only source-span/recovery plans, not apply.`
- Task overrides: `none`
- Deferred: `Recovery/independent disposition of existing review run 20261018T014101Z-f4fd619029aa, regeneration/application of original W1 plan, and W2/W5 dependency release until this implementation's paired review passes.`

## Next Handoff

- Next workstream: `review-agent-paired-review-source-span-main-sync-recovery-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Refresh reason: `none`
- Next action: `Independent fresh-context review of the bounded resolver and regression coverage; only after it passes attempt exact same-run recovery of review-agent-paired-review-host-validation-recovery-v1-review-corrections-1 run 20261018T014101Z-f4fd619029aa.`
- Blockers or open questions: `Existing correction review has no verdict and its original run remains protected; W2/W5 remain blocked.`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: `The historical f12717e6/1fa679c3 case resolves source 06cbe952..48a0bfc4 and preserves the canonical archive identity. Temporary Git merge fixtures pass for direct and legitimate main-sync landings, and reject invalid/missing sync provenance, wrong parent order/count, source/target mutation, unrelated archive-closeout files, missing/ambiguous traces and undocumented source code. The W1 b5b85ca4 source-span regression remains unchanged. The paired-review runner, dispatcher, workstream, review-outcome, packet-contract and changed-file validation suites passed; py_compile and git diff --check passed. No original review run or W1 plan was modified or applied.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `Initial adversarial tests showed that a code file added to an archive-closeout commit could be classified as a normal source-bearing implementation before archive checks ran. Archive-transition detection now takes precedence, so the closeout allowlist rejects that path. A historical W1 archive commit also proved that summary/index files may already be present or unchanged before archive closeout; the resolver requires the active deletion and canonical archive creation while only allowing the exact root summary and generated index.`
- Root cause / contributing factors: `The canonical archived implementation commit, the trace's final main-sync merge, and the source-bearing range are separate Git identities. Rename detection also obscured the active packet deletion unless the archive diff is enumerated with --no-renames.`
- Prevention / pipeline improvement: `Keep archive identity, trace landing identity and source range as separate provenance fields; derive source paths only from the archive commit's first-parent ancestry and compare protected source/target trees against any accepted trace merge.`
- Tooling / docs drift discovered: `none`
- Follow-up: `review-agent-paired-review-source-span-main-sync-recovery-v1`
- What worked: `Historical Git refs plus real temporary two-parent merge fixtures exercised positive provenance and fail-closed negative controls.`
