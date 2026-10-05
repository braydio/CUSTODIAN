# REVIEW: OPERATOR WORKBENCH BACKGROUND BASE SYNC

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-background-base-sync`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `operator-workbench-background-base-sync`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-background-base-sync`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_BACKGROUND_BASE_SYNC.md`
- Reviewed main: `0d2d39e3928cad86d3088aafaab8717eafa1f438`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Independently verify that OPUI launch automatically clears routine repository lag and safely resumes only a **previously user-authorized, transaction-proven publication**, without turning startup into an arbitrary dirty-file publisher or weakening existing Workbench rollback/landing guarantees.
- Reviewed implementation acceptance: Verify every acceptance item in archived `OPERATOR_WORKBENCH_BACKGROUND_BASE_SYNC.md`, especially clean automatic FF, exact pending-publication finalization proof, crash-window recovery, one-time Fast 01 recovery evidence, same-path conflict refusal, sparse retention, unknown/staged/ahead/unresolved fail-closed behavior, automatic valid LAND PENDING retry, and Publish's independent revalidation.
- Review evidence: Reuse durable implementation receipts, fixture-local Git/sparse/transaction evidence, exact hashes and closing summary. Gather fresh focused evidence only where durable artifacts cannot prove acceptance.
- Correction threshold: Any path by which OPUI startup can publish unproven dirt, lose local bytes, stage beyond the recorded allowlist, bypass Workbench validation, auto-land a transaction that was not previously user-authorized, overwrite an upstream same-path change, rewrite local history, or hide a recovery failure is blocking. Cosmetic wording remains UX1/UX3/UX5 unless it misstates safety.
- Focused validation:
  - `python3 custodian/tools/validation/operator_art_worktree_smoke.py`
  - `python3 custodian/tools/validation/operator_workbench_mirror_publish_smoke.py`
  - `python3 custodian/tools/validation/operator_workbench_ui_smoke.py`
  - `python3 custodian/tools/validation/run_validation.py --changed --json`
  - `python3 custodian/tools/agent/check_ai_context.py`
  - current review-pairing validation
  - `git diff --check`
- Review focus:
  - prove an outer finalization receipt exists before canonical mutation and cannot be created just by opening/reviewing Publish;
  - prove Workbench COMMITTED carries or atomically exposes exact validated Git postimages sufficient for finalization;
  - prove crash/restart between every receipt/transaction/commit/landing boundary is deterministic and fail-closed;
  - prove current Fast 01 residue was not guessed from path/dimensions and was only changed if prior user authorization + COMMITTED transaction + exact postimages + no upstream overlap were all established;
  - prove unrelated main history does not materialize unrelated sparse assets and raw `behind N` is never treated as animation count;
  - prove staged, unknown, ahead/diverged, unresolved transaction and same-path upstream cases remain untouched;
  - prove a valid LAND PENDING can resume automatically but invalid receipt identity cannot;
  - prove launch reconciliation and normal Publish readiness/preflight remain distinct safety boundaries.
- Acceptance: Produce a findings-first independent review of live `main`. Record a `passed` receipt or concrete findings with stable cycle-scoped IDs and dispositions. Do not patch reviewed implementation code.
- Non-goals: Do not redesign UX1/UX3/UX5, alter animation pixels, perform a new real publication unrelated to the stranded Fast 01 proof case, or broaden this into generic Git/worktree healing.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the implementation is complete and archived on `origin/main`.
2. Start from a fresh reviewer context and reconstruct the target from durable repository evidence.
3. Read root/local AGENTS, this packet, the archived implementation packet, closing summary, active Workbench design, transaction/publish code and focused tests.
4. Review the landed behavior against the original packet acceptance, not merely code style.
5. Report findings first with file/line references where practical.
6. If no correction-worthy defect remains, append the independent-review receipt to the archived implementation packet and finish this review normally.
7. If correction-worthy findings exist, create the bounded correction/re-review pair using the current repository template.
8. Do not implement UX wording or other feature work in this review.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `pending`
- Friction severity: `none`
- What went wrong: `pending execution`
- Root cause / contributing factors: `pending execution`
- Prevention / pipeline improvement: `pending execution`
- Tooling / docs drift discovered: `pending execution`
- Follow-up: `pending execution`
- What worked: `pending execution`

## Handoff

- Next workstream: `operator-workbench-browser-preview-refresh-hardening`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Refresh reason: `none`
- Next action: `Proceed to browser/PREVIEW hardening only after this review passes.`
- Blockers or open questions: `none`
