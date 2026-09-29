# REVIEW: OPERATOR WORKBENCH SPARSE ART CHECKOUT IMPORT CORRECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-sparse-art-checkout-review-corrections-1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-workbench-sparse-art-checkout-review-corrections-1`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-sparse-art-checkout-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT_REVIEW_CORRECTIONS_1.md`
- Reviewed main: `dfaf9e269`
- Review modes: `code, workflow`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Goal: Independently verify that the targeted Godot FX import repair resolves finding `R0-01` without widening sparse checkout or weakening Workbench validation.
- Reviewed implementation acceptance: The east and west `block_hold_01` FX imports resolve correctly from a fresh sparse profile, and the mandatory modular-layer smoke passes without missing-resource or Operator parse errors.
- Review evidence: Parent review finding `R0-01`; correction commit and closing summary; fresh sparse-worktree import and validation output.
- Correction threshold: Reopen only if `R0-01` remains unresolved/regressed or the correction changes unrelated tracked files or weakens validation.
- Focused validation: Inspect both corrected `.import` files; run `operator_art_worktree_smoke.py`, UI/workbench/mirror smokes, compatibility check, contract report, Godot import, and modular-layer smoke from a fresh sparse checkout.
- Review focus: Exact FX remap integrity, source/runtime path availability, narrow diff, and preservation of sparse and publish boundaries.
- Acceptance: Produce a findings-first review of live main. Retain finding ID `R0-01` and report it as `fixed`, `unresolved`, or `regressed`; assign any new finding the next cycle-scoped ID. Do not patch reviewed correction code.
- Non-goals: Do not redesign the sparse profile, modify art, or reopen other Operator pipeline behavior.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Review the correction packet and parent review receipt before inspecting the narrow diff.
2. Validate the repaired import metadata and reproduce the required smoke from a fresh sparse worktree.
3. Record a durable receipt in the archived correction packet and write the required root closing summary.
4. Complete and archive this review packet through the normal workstream lifecycle.

## Handoff

- Next action: Auto-dispatch after the correction lands.
- Blockers or open questions: none.
