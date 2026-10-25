# Pre-validation Checkout Recovery — Review Corrections 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-prevalidation-checkout-recovery-v1-review-corrections-1`
- Authoring handoff: `auto`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-prevalidation-checkout-recovery-v1`
- Locks: `paired-review-source-span-provenance`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-prevalidation-checkout-recovery-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Review rationale: `canonical host validation must authenticate source-span merge history before an independent reviewer can launch`
- Reviewed main: `936e58f3211d5af0d35093bf67d1c70ee1aff5b1`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: `Allow the existing pre-validation recovery review to pass canonical host validation when its implementation history contains the exact recorded in-place main-sync merge, while retaining strict source-span provenance.`
- Completion boundary: `Teach the split source-span resolver to recognize one uniquely witnessed main_sync merge inside a source-bearing implementation history. Keep the merge out of the authored source span, reject every ambiguous or forged variant, and unblock the already claimed paired review without replacing its run or claim.`
- Current measured state: `The implementation landed at 936e58f3211d5af0d35093bf67d1c70ee1aff5b1. Its paired review run 20261025T032358Z-3b242f79acdc is preserved in host_validation_recovery before reviewer launch. Canonical validation fails with “checkpoint-resume merge lacks a unique matching lifecycle pair.” The source-span merge is 2981a122c2983fb946494e2ad821b5059c20fe98, authenticated by the original workstream trace's main_sync(changed=true, head=2981a122, main_sha=a6b419e23758ba789f1c197a5c76045515b122f5), preceded by checkpoint_completed at 4c206444 and followed by the exact no-op main_sync at implementation landing 936e58f.`
- Evidence: `.git/custodian-review-runs/review-agent-paired-review-prevalidation-checkout-recovery-v1/20261025T032358Z-3b242f79acdc/`; `.git/custodian-workflow/traces/agent-paired-review-prevalidation-checkout-recovery-v1/20261024T055251Z-7abc1a2bf558.jsonl`; the pinned implementation and current `paired_review_host_validation.py` source-span resolver.
- Task-specific authority: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; archived `PAIRED_REVIEW_PREVALIDATION_CHECKOUT_RECOVERY_V1.md`; source-span main-sync and checkpoint-resume provenance contracts in `paired_review_host_validation.py` and its real-Git tests.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; root summary `AGENT_PAIRED_REVIEW_PREVALIDATION_CHECKOUT_RECOVERY_V1_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/run_trace.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Change:
  1. Accept an interior source-span merge only when it has exactly two ordered parents, its first parent is the preceding first-parent implementation commit, and a unique same-run `main_sync(changed=true)` event binds the merge SHA and second parent.
  2. Require the exact preceding checkpoint event for the claimed branch and first parent, no conflicting resume event, a deterministic `git merge-tree --write-tree` match, an exact later no-op main-sync witness at the completed landing, and ancestry of the second parent under reviewed main.
  3. Derive authored source paths only from first-parent non-merge commits. Record the merge and event identities in source-span provenance without broadening generic merge acceptance or admitting inherited source as implementation-owned.
  4. Add real temporary-Git positive and hostile tests for this exact history, including missing/duplicate/mismatched sync events, wrong parent order, forged checkpoint ownership, changed merge tree, multiple merges, and source-loss cases. Preserve existing checkpoint-resume and direct main-sync landing behavior.
- Preserve: `The held review claim, branch, worktree, and failed host-validation evidence; source-span archive identity; existing checkpoint-resume and main-sync landing checks; all implementation and runtime content.`
- Non-goals: `No mutation of the held review run during correction implementation or its paired review; no general merge acceptance; no history rewriting, new recovery subsystem, claim release, or mapper implementation.`
- Acceptance:
  - A1: The exact 936e58f implementation source span resolves using merge 2981a122 only as synchronization provenance and returns the code/test paths authored on the first-parent line.
  - A2: The sync merge is admitted only with the unique exact same-run trace witness, ordered parents, deterministic tree, exact checkpoint and later no-op sync witnesses, and required ancestry.
  - A3: Forged, missing, duplicate, stale, reordered, repeated, or source-losing merge histories fail closed; existing checkpoint-resume and canonical landing regressions remain green.
  - A4: Canonical paired-review host validation for the correction is green with complete changed-file coverage, and its independent review passes before the held review is resumed.
- Validation: `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; `python3 custodian/tools/validation/run_validation.py --test paired_review_runner_unit --json`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `python3 custodian/tools/agent/check_ai_context.py --json`; `python3 custodian/tools/agent/task_packet_index.py`; `python3 custodian/tools/agent/validate_review_pairing.py`; Python compile checks and `git diff --check`.
- Task overrides: `none`
- Deferred: `After this correction and its independent review are accepted, resume original review run 20261025T032358Z-3b242f79acdc through the supported --recover-host-validation plan/apply path. Do not create another primary implementation or review claim.`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: `The exact primary source span resolves with merge 2981a122c2983fb946494e2ad821b5059c20fe98 recorded as source_main_sync_merge. Authored paths are derived from first-parent commits. The new positive and hostile real-Git tests pass; the full paired-review runner suite passes 186/186; canonical paired_review_runner_unit passes; changed-file validation passes 2/2 with complete coverage; AI-context, packet index, review-pairing, packet authoring, compile, and diff checks pass.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The first hostile fixture unexpectedly represented a matching resume and in-place sync together; tightening the fixture exposed and closed the conflicting-witness acceptance gap.`
- Root cause / contributing factors: `Source-span validation recognized checkpoint/resume merges and landing-time main-sync merges, but not an interior merge authenticated by the exact lifecycle main_sync event.`
- Prevention / pipeline improvement: `The resolver now distinguishes the exact in-place sync transition from checkpoint/resume and rejects conflicting, missing, duplicate, or mismatched witnesses.`
- Tooling / docs drift discovered: `none`
- Follow-up: `review-agent-paired-review-prevalidation-checkout-recovery-v1-review-corrections-1`
- What worked: `Real temporary-Git histories verify both authored-path ownership and hostile event/parent/tree mutations.`

## Next Handoff
- Next workstream: `review-agent-paired-review-prevalidation-checkout-recovery-v1-review-corrections-1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Run the fresh-context paired review against the landed source-span correction. After accepted review, resume the held primary review's preserved host-validation run.
- Blockers or open questions: `none`
