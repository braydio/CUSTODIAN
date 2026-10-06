# REVIEW: PERSISTENT CHECKOUT SYNC HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-persistent-checkout-sync-hardening`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `persistent-checkout-sync-hardening`
- Locks: `agent-workflow, operator-workbench-publish`
- Review: `none`
- Review target workstream: `persistent-checkout-sync-hardening`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PERSISTENT_CHECKOUT_SYNC_HARDENING.md`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `a7fabe3c9bf4de09b1d1e573d9c85247e5c90a32`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Independently verify that the shared persistent-checkout sync implementation keeps the coordination root and OPUI art checkout current only when synchronization is provably non-destructive, while preserving dirty/diverged/recovery/editor-open state and avoiding a second Git policy.
- Review focus:
  - one shared inspect/apply authority owns root/art ahead-behind and mutation policy;
  - `workstream.py`, Operator tooling, and shell aliases delegate instead of duplicating Git logic;
  - coordination-main sync remains clean-main + FF-only and never rewrites local work;
  - Operator-art sync preserves `workbench/operator-art`, sparse-profile, ignored Workbench bytes, `LAND PENDING`, transaction recovery, and source-freshness boundaries;
  - OPUI safe startup sync reduces avoidable behind-state without making blocked synchronization a UI-start failure;
  - active Aseprite state prevents automatic art baseline movement;
  - common-directory locking and revalidation close concurrent/race windows without deadlock;
  - no network LFS acquisition, project-wide import, art republish, reset, stash, rebase, force, branch switch, or cleanup was introduced;
  - user-facing `csync` / `opui-sync` are thin wrappers over the same backend.
- Acceptance: Findings-first fresh-context review on live `main` records a clean/non-blocking pass or creates the bounded correction/re-review sequence. The reviewer must independently exercise safe positive sync and destructive-safety negative controls; implementation-summary claims alone are insufficient.
- Non-goals: Do not recover arbitrary divergent history, clean the user's current root, redesign workstream dispatch, change Operator publication semantics, or alter Operator art/gameplay.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Required Review Checks

1. Read the archived implementation packet/summary, current root AGENTS sync rule, live shared sync authority, `workstream.py`, `operator_art_worktree.py`, and `tools/custodian_aliases.sh`.
2. Run the focused persistent-checkout sync smoke and inspect that its fixtures use real temporary Git repositories/worktrees rather than mocks for the core FF-only behavior.
3. Independently verify root clean-behind sync and at least dirty + diverged preservation cases, checking HEAD, index, tracked bytes, and untracked bytes before/after.
4. Independently verify Operator-art clean-behind sync plus ignored `.ai` byte preservation and sparse-profile health.
5. Independently verify at least three art blockers spanning local commits/divergence, `LAND PENDING` or recovery state, and Aseprite-open state; no blocker may move HEAD or rewrite Workbench files.
6. Verify normal `opui` startup reaches current main when safe but still mounts when synchronization is blocked.
7. Verify `workstream.py finish` and post-Operator-publication coordination sync delegate the shared helper and preserve previous behavior.
8. Verify shell commands route through the Python authority rather than implementing Git classification in Bash.
9. Exercise lock contention and an inspect/apply race or equivalent adversarial fixture proving no non-FF merge/rebase/reset can occur.
10. Search the changed production paths for forbidden destructive commands/flags and unexpected LFS network calls.
11. Record findings first with stable IDs and dispositions.
12. If blocking findings exist, queue only the narrow correction + paired re-review required by the live review pipeline.

## Handoff

- Next action: Auto-dispatch after `persistent-checkout-sync-hardening` lands and archives.
- Blockers or open questions: Dependency only.
