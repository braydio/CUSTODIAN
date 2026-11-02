# REVIEW: OPERATOR WORKBENCH SPARSE ART CHECKOUT

- Workstream: `review-operator-workbench-sparse-art-checkout`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-workbench-sparse-art-checkout`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-sparse-art-checkout`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT.md`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the persistent Operator art checkout is materially narrowed without weakening publication safety, validation, or local authoring-state preservation.
- Review focus: sparse checkout is per-worktree rather than repository-global; unrelated tracked files stay tracked but unmaterialized; clean idle FF-only sync; no reset/rebase/stash of dirty/ahead/pending state; ignored Workbench bytes survive; mandatory publish/build/import/smokes work from the final sparse profile; publication staging remains exact allowlist-only; no user Git step is introduced.
- Acceptance: Findings-first review of landed `main`. Prove a fresh and migrated fixture, inspect the final sparse path profile for unnecessary bulk and missing authority, run the focused Operator worktree/UI/publish tests, and verify one real sparse Workbench validation path. Blocking findings create the bounded correction pair. Do not patch the reviewed implementation in this review workstream.
- Non-goals: Do not change Operator art, broaden sparse checkout to other worktrees, redesign Asset V2, or optimize unrelated Git workflows.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Required Checks

1. Prove `.gitignore` was not misused to hide tracked repository content.
2. Prove sparse configuration/patterns apply only to `workbench/operator-art` and do not alter coordination/agent worktrees.
3. In a fixture, verify an unrelated tracked heavy-path file exists in `HEAD` but is absent from the sparse filesystem before and after upstream FF sync.
4. Verify relevant Operator source/runtime/tool paths remain materialized and update from upstream.
5. Verify ignored `.ai/operator_animation_workbench` bytes survive sparse initialization, reapply, and safe sync.
6. Verify dirty/ahead/diverged/LAND-PENDING state is preserved and never automatically rebased/reset/stashed.
7. Run the existing scoped publication flow and prove unexpected output still blocks while allowed outputs stage/commit/land normally.
8. Run the mandatory Workbench validation set from the final sparse profile; missing-resource failures are blocking, not permission to weaken validation.
9. Confirm the UI/status surface no longer implies unrelated repository files are version candidates.
10. Confirm normal Codex workstreams and coordination main remain unchanged.

## Handoff

- Completion: Sparse isolation, state preservation, UI and scoped publication safety passed review. Finding `R0-01` blocks the required current-main Godot modular-layer validation; the bounded correction and paired review are ready and dependency-gated.
- Next action: Auto-dispatch `operator-workbench-sparse-art-checkout-review-corrections-1` after this review lands.
- Blockers or open questions: The two `block_hold_01` FX `.import` records must be repaired before the parent acceptance can be verified.
