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
- Reviewed main: `7cfa2c12f5a99a90bfe087117856d16c92f8772a`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent | same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Independently verify that OPUI launch can advance a behind, ahead-zero dedicated art checkout while preserving provably Workbench-owned unpublished binary changes exactly, without turning background synchronization into automatic publication or a broad destructive Git-recovery mechanism.
- Reviewed implementation acceptance: Verify every acceptance item in archived `OPERATOR_WORKBENCH_BACKGROUND_BASE_SYNC.md`, especially exact-byte dirty preservation, no-overlap FF-only advancement, sparse-profile retention, unknown/staged/ahead/pending/conflict fail-closed behavior, recovery evidence, and Publish's independent recheck.
- Review evidence: Reuse the implementation's fixture-local Git/sparse/recovery receipts, exact before/after hashes, changed-file validation, and closing summary. Gather fresh focused evidence only where those durable artifacts cannot prove acceptance.
- Correction threshold: Any data-loss possibility, silent auto-publication, broad reset/clean/stash/rebase, same-path overwrite, staged/index mutation, loss of ignored Workbench/Aseprite bytes, or failure to recheck Publish readiness is blocking and creates a correction packet. Cosmetic wording belongs to UX1/UX3 unless it misstates safety.
- Focused validation:
  - `python3 custodian/tools/validation/operator_art_worktree_smoke.py`
  - `python3 custodian/tools/validation/operator_workbench_ui_smoke.py`
  - existing Operator Workbench publish/recovery regression selected by changed-file ownership
  - `python3 custodian/tools/validation/run_validation.py --changed --json`
  - `python3 custodian/tools/agent/check_ai_context.py`
  - `git diff --check`
- Review focus:
  - prove the 96px -> 128px-equivalent binary fixture survives byte-exactly across base advancement;
  - prove unrelated main commits do not materialize unrelated sparse assets;
  - prove dirty ownership derives from saved Workbench/publication contracts, not a permissive directory prefix;
  - prove staged, unknown, pending, transaction, ahead/diverged and same-path upstream cases remain untouched;
  - prove recovery snapshot/receipt paths are ignored and cannot become canonical source;
  - prove launch reconciliation and Publish preparation are distinct safety boundaries;
  - prove raw `behind N` remains diagnostic repository-history distance rather than an artist workload metric.
- Acceptance: Produce a findings-first independent review of live `main`. Record a `passed` receipt or concrete findings with stable cycle-scoped IDs and dispositions. Do not patch reviewed implementation code.
- Non-goals: Do not redesign UX1/UX3, change animation art, publish a real user Workbench, or broaden this into general Git worktree healing.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the implementation is complete and archived on `origin/main`.
2. Start from a fresh reviewer context and reconstruct the target from durable repository evidence.
3. Read root/local AGENTS, this packet, the archived implementation packet, closing summary, active Workbench design, and live implementation/tests.
4. Review the landed behavior against the original packet acceptance, not merely code style.
5. Report findings first with file/line references where practical.
6. If no correction-worthy defect remains, append the independent-review receipt to the archived implementation packet and finish this review normally.
7. If correction-worthy findings exist, create the bounded correction/re-review pair using the current repository template.
8. Do not make the human-facing UX redesign in this review; route non-safety wording improvements to UX1/UX3.

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
