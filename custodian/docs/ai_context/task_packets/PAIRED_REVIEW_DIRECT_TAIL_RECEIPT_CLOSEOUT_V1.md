# Paired Review Direct-Tail Provenance and Receipt Closeout V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-direct-tail-receipt-closeout-v1`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-failed-host-validation-import-recovery-v1, review-agent-paired-review-failed-host-validation-import-recovery-v1`
- Locks: `paired-review-source-span-provenance, paired-review-host-import-recovery`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-direct-tail-receipt-closeout-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `source-span provenance and coordinator-authored review receipts define protected review trust boundaries`
- Reviewed main: `d3476a38ca457d4186c11cec718592fef7e9ffbc`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Make the exact scoped-snapshot archive-to-source-tail history verifiable and prevent canonical review receipt formatting from stranding an otherwise valid independent review.
- Completion boundary: Correct only the authenticated direct-tail `main_sync` base relationship and the paired-review receipt formatting/closeout path. Preserve strict source and reviewer identity checks, add historical and adversarial real-Git coverage, and land through the ordinary workstream lifecycle. The quarantined historical witness review remains immutable and unresolved.
- Current measured state: At `origin/main@d3476a38`, `_verify_archive_sync_followup()` requires a no-op direct-tail witness `main_sha` to equal the later `reviewed_main`, while the scoped-snapshot run records `main_sync(changed=false, head=926415c5..., main_sha=1e24241a...)`; its authenticated claim/source base is `1e24241a...`, canonical archived packet is `ce56db82...`, and final trace landing is `926415c5...`. The runner prompt requests a receipt append without specifying its byte separator. `verify_review_receipt_delta()` consequently rejects the missing separator. Ordinary closeout cannot handle a reviewer-archived active packet, and existing `recover-closeout` accepts only nonpassing outcomes. The witness review itself is `legacy_quarantined` and is not eligible for mutation or continuation.
- Evidence: `custodian/tools/agent/paired_review_host_validation.py::_verify_archive_sync_followup`; `custodian/tools/agent/paired_review_runner.py` reviewer prompt, post-exit verification, and closeout recovery; `custodian/tools/agent/review_receipt_delta.py::verify_review_receipt_delta`; `custodian/tools/agent/test_paired_review_runner.py`; archived packet `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_POST_MERGE_SOURCE_SPAN_WITNESS_V1.md`; preserved scoped-snapshot run `20261021T022404Z-69d171614730`; quarantined witness run `20261021T060528Z-2985d230b33b` and quarantine record on `origin/main`.
- Task-specific authority: Archived source-span witness packet acceptance and preservation rules; immutable claim/lifecycle trace and Git ancestry; `review_receipt_delta.py` exact target baseline contract; canonical reviewer outcome parser; dispatcher quarantine and lock semantics; `AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; root summary `AGENT_PAIRED_REVIEW_DIRECT_TAIL_RECEIPT_CLOSEOUT_V1_CLAUDE_SUMMARY.md`.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/test_workstream.py`; `custodian/tools/agent/review_outcome.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_POST_MERGE_SOURCE_SPAN_WITNESS_V1.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md`.
- Change:
  1. Bind the direct archive-to-source-tail no-op `main_sync` to the exact authenticated source/claim base recorded by the unique claim trace, not to a later reviewed-main pin. Verify that base is the exact full commit, is an ancestor of the canonical archive and final trace landing, and matches the unique `changed=false`, final-head event ordered before landing. Keep claim/workstream/packet/run identity, exact archive identity, source surface, regular-file modes, event uniqueness, and complete changed-file coverage mandatory.
  2. Add an exact historical regression for the scoped-snapshot topology `1e24241a -> ce56db82 -> 926415c5` and its immutable `main_sync(changed=false, head=926415c5, main_sha=1e24241a)` event. Add real-Git negatives for a reviewed-main substitution, unrelated or reversed ancestry, wrong/duplicate/reordered/forged events, changed archive identity, unauthorized paths, changed source, and non-regular files.
  3. Add a coordinator-owned canonical receipt renderer in `review_receipt_delta.py`. It must construct the exact byte separator, section and ordered fields accepted by `verify_review_receipt_delta()`. The reviewer authors the canonical disposition/judgment; the coordinator derives receipt identity from the parsed outcome and pinned target, and writes a receipt only when the target remains byte-identical to the pinned baseline with no preexisting receipt. Findings and human-required outcomes never produce a PASS receipt.
  4. Update the reviewer prompt and coordinator closeout so reviewers do not hand-format or edit the target receipt. Reject extra fields, target edits, duplicate receipts, mismatched identities, nonpassing outcomes, and stale baselines. Preserve the ordinary reviewer fresh-context and independent-outcome requirements.
  5. Add a narrowly scoped, read-only-plan/checksum-guarded PASS closeout recovery for an exited, non-quarantined run whose authentic canonical PASS disposition and original evidence manifest are intact but whose claimed worktree has already archived the active review packet. Reconstruct the exact original review-packet identity from the pinned baseline and claim evidence; preserve the original branch/worktree/run files; apply only coordinator-generated canonical receipt/archive formatting through the existing race-safe landing authority. Recovery must refuse quarantined identities, changed evidence hashes, changed ancestry, ambiguous claim ownership, stale target identity, consumed/uncertain reviewer launches, or any outcome other than a uniquely parsed PASS. It must not relaunch a reviewer.
  6. Keep the quarantined historical witness run `20261021T060528Z-2985d230b33b`, its branch at `0f6681e4`, its evidence, and its unresolved verdict unchanged. Prove in tests that every PASS-closeout recovery entrypoint refuses a `legacy_quarantined` identity; do not use this tool to resume or modify that run.
- Preserve: All existing source-span and multi-merge acceptance; exact reset/Blender pins; source/test allowlists and file modes; original scoped-snapshot claim, worktree, trace and run evidence; quarantined witness claim, branch, worktree, reviewer output, run evidence and unresolved verdict; other held reviews; reviewer outcome authority; race-safe landing and ownership checks.
- Non-goals: No historical claim unquarantine or continuation; no reviewer relaunch; no synthesized reviewer judgment from prose, exit codes, tests, or quarantine; no target receipt for the quarantined witness run; no broad parser relaxation, arbitrary receipt normalization, source path expansion, lock bypass, or application of scoped-snapshot/reset/Blender recovery plans.
- Acceptance:
  - A1: The exact scoped-snapshot Git history resolves with `source_base=1e24241a...`, canonical archive `ce56db82...`, landing `926415c5...`, and the unique immutable no-op trace event. The source span excludes unrelated commits and retains complete path/mode coverage.
  - A2: Every stated negative direct-tail control fails closed, while existing reset, Blender, direct-tail, and adversarial multi-merge cases remain unchanged and green.
  - A3: The canonical receipt renderer emits bytes that pass `verify_review_receipt_delta()` for the pinned PASS identity, including the required separator; target baseline bytes are an exact prefix, and duplicate/malformed/extra-field/nonpass/mismatched-target inputs fail.
  - A4: A non-quarantined synthetic same-run recovery fixture succeeds only with exact original evidence hashes, canonical PASS outcome, original claim/worktree/ancestry, pinned target identity, no prior receipt, and coordinator-generated formatting. A quarantined run, missing archived packet, altered manifest, changed SHA, stale ownership, consumed/uncertain launch, contradictory outcome, or target edit is rejected without mutation.
  - A5: The original quarantined witness run and source-span claims remain untouched; no review is marked passed except through a canonical, independently authored, coordinator-verified outcome.
- Validation: Add failing tests first. Run `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; `python3 -m unittest custodian.tools.agent.test_workstream -v`; `python3 -m unittest custodian.tools.agent.test_legacy_claim_quarantine -v`; exact historical resolver regression and hostile real-Git fixtures; targeted authoring validation for this pair; `python3 custodian/tools/validation/run_validation.py --changed --json` with complete coverage; `python3 -m py_compile` on all changed Python files; `python3 custodian/tools/agent/task_packet_index.py`; and `git diff --check`. Do not apply any historical recovery plan.
- Task overrides: `none`
- Deferred: Any use of receipt closeout recovery for non-quarantined historical runs requires a fresh exact plan and separately authorized apply. The quarantined witness verdict remains unresolved. Scoped-snapshot, reset, and Blender plans remain prohibited until this correction receives a genuine independent accepted PASS.

## Context Pack

- Repomix: `none`

## Next Handoff

- Next workstream: `review-agent-paired-review-direct-tail-receipt-closeout-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: `After the implementation pair owning paired_review_runner.py completes and releases its declared lock, dispatch this exact correction normally. Obtain its fresh independent review before creating or applying any historical recovery plan.`
- Blockers or open questions: `The currently claimed host-import recovery pair owns the shared runner and test surface; the dispatcher lock and explicit dependencies serialize this correction behind it.`
