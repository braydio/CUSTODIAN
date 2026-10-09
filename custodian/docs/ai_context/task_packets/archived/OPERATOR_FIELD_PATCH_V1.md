# OPERATOR FIELD PATCH V1

- Status: `complete`
- Authority: `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md`, `custodian/game/actors/operator/operator.gd`
- Goal: Implement the first limited, timed, interruptible Operator Field Patch heal without passive regeneration or inventory rewrite.
- Files: `custodian/project.godot`, `custodian/game/actors/operator/operator.gd`, `custodian/game/ui/hud/ui.gd`, `custodian/tools/validation/field_patch_smoke.gd`, `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Constraints: Baseline max carried 2, start count 1, 1.25s use, 35% max health restore, heal only at commit, interrupt before commit on damage/dodge/reload/attack/death/UI, HUD read-only, no passive health regeneration.
- Acceptance: Input action exists; Operator can start patch only when damaged and eligible; health does not change before commit; commit restores and consumes one patch; pre-commit interruption prevents heal and preserves count; movement is slowed during use; focused smoke and ranged combat smoke pass.
- Completed: Added `use_field_patch` input on keyboard `P`; added Operator Field Patch tuning, carried count, timed commit, health restore, movement slow, status API, restock helper, damage/action/inventory-UI interruption, death/reset cleanup, and read-only compact HUD/debug status. `B` remains reserved for Build, and the focused smoke checks that Field Patch no longer shares that binding.
- Validation: `godot --headless --path . --script res://tools/validation/field_patch_smoke.gd` passed. `godot --headless --path . --script res://tools/validation/ranged_combat_balance_smoke.gd` passed. `godot --headless --path . --script res://tools/validation/operator_ranged_ready_input_smoke.gd` passed.
- Deferred: Production Field Patch animation/audio/pickup/restock source. Controller binding is intentionally deferred because Xbox face-up is already inventory and D-pad up is already quick-item.
