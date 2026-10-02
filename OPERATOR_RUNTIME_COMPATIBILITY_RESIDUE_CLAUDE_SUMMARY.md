# Operator Runtime Compatibility Residue — Claude Summary

C2b.3 retired all eleven actor-local Operator compatibility SpriteFrames and the updater, moved the final consumers to the canonical generated SpriteFrames or weapon-owned art, migrated DodgeChargeFeedback and paired execution to canonical identities, refreshed the reachability ledger, and added the generated consumer-disposition report. Thirteen superseded/orphan action families were removed from runtime publication; their 34 source sheets remain archived for provenance. No production art was modified.

## Evidence

- Runtime publication: 596 outputs before; 562 after. Retired source sheets: 34 across 13 families.
- Consumer disposition: 538 active canonical identities plus 34 archived retired identities; all eleven compatibility resources accounted for.
- Reachability audit: 237 runtime actions checked, 117 classifications.
- `operator_runtime_animation_authority_smoke.py`: compatibility gates clear; one separate TODO remains for 188 legacy runtime files. Its `--final` mode therefore remains red for that pre-existing migration debt.
- `run_validation.py --changed --max-tier unit --json`: 24 selected, 24 passed, 0 failed, complete ownership.
- Focused compatibility, timing, Workbench mirror/UI/art-worktree, runtime-path, reachability, melee point-blank and modular-layer checks passed. The Textual UI pilot was skipped because its optional dependency is not installed.
- `git diff --check`: pass.

A Godot smoke exposed a stale paired-execution sheet-map reference and shared presentation declarations that had been removed with compatibility code. Those were corrected, and the canonical execution smoke now passes. The validation manifest now owns each retired family and the specific affected fixture/smoke files. The smoke still emits a small resource-leak warning on exit, though it reports success and exits zero.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: removed declarations and a stale identifier survived the broad compatibility cutover until runtime smoke validation; changed-file validation initially lacked ownership for several retired families and fixtures.
- Root cause / contributing factors: a large shared actor script mixed compatibility lookup code with still-live presentation declarations, and validation ownership did not track the full deletion surface.
- Prevention / pipeline improvement: keep shared declarations outside compatibility deletions; validate canonical runtime identities for critical execution; assign exact runtime-family ownership to the compatibility test.
- Tooling / docs drift discovered: repaired within this slice; 188 legacy runtime files remain tracked by the separate authority gate.
- Follow-up: fixed-in-scope
- What worked: the generated disposition report and focused SpriteFrames identity checks made retirement decisions easy to audit.
