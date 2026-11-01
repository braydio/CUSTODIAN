# Canonical summary rename lifecycle recovery

- Packet schema: `custodian.task_packet.v2`
- Authoring handoff: auto
- Workstream: agent-workstream-canonical-summary-rename-recovery-v1
- Category: agent-ops
- Status: `draft`
- Dispatch: `manual`
- Priority: P0
- Depends on: none
- Locks: workstream-canonical-summary-rename-recovery
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, workflow
- Paired review workstream: review-agent-workstream-canonical-summary-rename-recovery-v1
- Review cycle: 0
- Max automatic review cycles: 0
- Review rationale: Canonical finish can archive a valid implementation and summary, then fail to recognize one byte-identical rename needed to correct the summary filename to the canonical workstream-derived name. Producer and independent consumer must authenticate this narrow administrative transition without relaxing source-span, synchronization, review or teardown gates.
- Reviewed main: f38d7f405014960072e10feeb93f339e1ba7067e
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Visual review: none
- Goal: Support at most one authenticated, byte-identical legacy-to-canonical closing-summary filename correction immediately after a canonical task-packet archive transition, then preserve ordinary authenticated sync and landing requirements.
- Current measured state: On origin/main `f38d7f405014960072e10feeb93f339e1ba7067e`, the timeout recovery archive transition is `073b8ffe64e0fb04ae21f9186fa00b1a051f71fb` and its immediate child is `a5603fe9ddbe497cc1d18dce68ea3f48960fcf62`. Normal preflight blocks because the child is not an authenticated archive/sync first-parent continuation.
- Completion boundary: Update the canonical workstream producer and independent paired-review host-validation consumer to admit only an exact direct-child administrative summary rename after the archive transition. Require canonical destination derived from the workstream ID, regular non-executable file modes, identical source/destination blob and bytes, one old path plus one new path and no other change, at most one rename, unchanged archived packet, and the authenticated lifecycle sync chain. Add real-Git positive/adversarial regressions and lifecycle documentation. Run focused suites and canonical changed-file validation with complete coverage and zero failures, timeouts, skips or infrastructure errors; produce truthful closeout artifacts for canonical finish. The subsequent fresh-context independent paired review is a separate mandatory acceptance gate after landing and teardown.
- Evidence: Preserved private diagnostic report and exact Git-object inspection establish the direct-child summary rename, identical blob/bytes, unchanged archived packet and absence of other changes.
- Incident evidence: Archive transition `073b8ffe64e0fb04ae21f9186fa00b1a051f71fb` was followed by direct child `a5603fe9ddbe497cc1d18dce68ea3f48960fcf62`, whose only changes are deletion of `VALIDATION_PAIRED_REVIEW_RUNNER_TIME_BUDGET_CLAUDE_SUMMARY.md` and addition of `VALIDATION_PAIRED_REVIEW_RUNNER_TIME_BUDGET_V1_CLAUDE_SUMMARY.md`. Both paths have mode `100644`, identical blob `5761116b5e84dd1e5b6b66159254428243545d1b`, identical SHA-256 `7fd464c45adeb40046a61433f28780a298bb48f879deb4d760aafa1806767608`; archived implementation packet blob is unchanged. No code or other path changed in that follow-up.
- Task-specific authority: `custodian/tools/agent/workstream.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_workstream.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: The producer's canonical archive-transition lineage gate; the independent consumer's source-span/archive lineage verifier; tests for those gates; and the lifecycle documentation describing the bounded administrative rename.
- Publication inputs: `custodian/tools/agent/workstream.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_workstream.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/tools/agent/validate_task_packet_authoring.py`; `custodian/tools/agent/validate_review_pairing.py`; `custodian/tools/agent/task_packet_index.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/iteration/changed_file_router.py`.
- Change:
  1. Define one explicit administrative rename shape: a canonical archive-transition commit, followed immediately by at most one direct single-parent commit whose only changes under `--no-renames` are deletion of one legacy `*_CLAUDE_SUMMARY.md` and addition of the exact canonical `_expected_summary_filename(workstream_id)`.
  2. Verify the old summary exists before and is absent after; the canonical destination is absent before and present after; both entries are regular mode `100644`; bytes and blob OIDs match; the archived packet blob is unchanged; no summary copy, extra path, executable mode, symlink or second rename exists.
  3. Allow normal finish to authenticate this exact pre-sync state, then require the existing checkpoint, main-sync, after-sync validation witness, final source-span and teardown contracts unchanged.
  4. Independently authenticate the same administrative commit in `paired_review_host_validation.py`; do not infer provenance from producer output or a claimed summary SHA alone.
  5. Add real-Git fixtures covering the exact two-commit topology and positive/negative controls, then document the rule and its preservation boundary.
- Preserve: Existing RC-119 and historical recovery exceptions byte-for-byte in behavior; archived packet content; all existing source-span, checkpoint/resume, main-sync, after-sync, review acceptance and teardown gates; the timeout implementation branch and its paired review; P0, Operator, Ritualant and all protected evidence.
- Non-goals: Do not modify or rewrite commits `073b8ffe64e0fb04ae21f9186fa00b1a051f71fb` or `a5603fe9ddbe497cc1d18dce68ea3f48960fcf62`; do not force-push, amend, reset, rebase, stash, release claims, launch the timeout reviewer, or finish the timeout workstream in this recovery implementation; do not allow arbitrary post-archive edits, summary creation, changed summary contents, multiple renames, source edits, unauthenticated merges, missing after-sync validation or review bypasses.
- Acceptance:
  - Real-Git tests prove the exact archive -> byte-identical canonical rename -> authenticated sync/landing sequence is accepted by both producer and independent consumer.
  - Negative tests reject altered summary bytes, wrong/noncanonical path, wrong mode, extra or missing path, duplicate rename, changed archive packet, modified source, wrong parent, unauthenticated merge, missing/reused/forged lifecycle witness and missing after-sync report.
  - Existing RC-119 and historical recovery tests remain green; no existing protection is weakened.
  - Focused suites and canonical changed-file validation pass with complete applicable coverage and zero failures, timeouts, skips or infrastructure errors; report includes exact source identity and SHA-256.
  - Canonical finish lands and safely tears down this recovery workstream. A fresh independent paired reviewer records an authentic outcome afterward; implementation completion is not described as independent acceptance.
- Validation:
  - Run targeted real-Git producer/consumer regression tests, including `python3 -m unittest custodian.tools.agent.test_workstream` and the relevant `test_paired_review_runner` cases.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` and inspect every selected test, complete coverage, report digest and exact commit/tree/status identity.
  - Run `python3 custodian/tools/agent/check_ai_context.py --json`, targeted authoring and pairing checks, `python3 custodian/tools/agent/task_packet_index.py`, and `git diff --check`.
- Task overrides: none
- Deferred: The blocked timeout workstream remains at `a5603fe9ddbe497cc1d18dce68ea3f48960fcf62`; resume it only after this recovery lands and receives independent review, then use its original claim and a fresh canonical source-bound validation. The P0 implementation and its own review remain later gates.

## Handoff

- Next workstream: `validation-paired-review-runner-time-budget-v1`
- Next packet state: `dependency-gated until this recovery lands and its independent review accepts`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae73140-7bb8-83e8-8a42-705d683aa2fb
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation summary and final Next Handoff.
- Refresh reason: `none`
- Next action: After this recovery's canonical finish and independent review, reconcile the timeout implementation's existing claim and canonical summary rename through the new authenticated lifecycle gate.
- Blockers or open questions: `none`
