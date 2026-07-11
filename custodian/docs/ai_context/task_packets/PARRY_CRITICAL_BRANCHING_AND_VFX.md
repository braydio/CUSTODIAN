# PARRY CRITICAL BRANCHING AND VFX

- Status: `complete`
- Authority: `design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md`; supporting umbrella `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Goal: Harden failed/successful parry branching, explicit enemy-owned critical validation/consumption, independent success VFX, and the fast parry-critical attack animation.
- Files: `custodian/game/actors/operator/operator.gd`; `custodian/game/actors/enemies/enemy.gd`; focused validation under `custodian/tools/validation/`; AI/design docs.
- Constraints: Every guard entry goes through `block_enter`; successful parry requires block release/repress; enemy owns the critical-open timer; `critical_attack_01` only starts after a valid vulnerable target is found.
- Acceptance: Failed parry finishes the original `parry_01` read with no miss VFX; held-block failure re-enters `block_enter`; released-block failure returns neutral; enemy validates and consumes parry critical through explicit methods; BREACH/ring cleanup is preserved; critical branch plays the repurposed 8-frame fast critical body sheet; focused Godot smokes pass.
- Completed: Added design authority doc; removed the parry-miss VFX branch; added enemy `can_receive_parry_critical_from()` / `receive_parry_critical()`; added Operator contextual critical target search and explicit critical branch; mapped the previously misnamed 8-frame `parry_miss` body sheets as `operator_critical_1h_right/left`; refreshed focused smokes.
- Deferred: Rename the misnamed `operator__body__unarmed__parry_miss_01__{e,w}__8f__96.png` files through the asset pipeline when it is safe to update import metadata and references.

## Drift Review

- Primary authority: Added `design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md`.
- `CURRENT_STATE.md`: Must mention the explicit parry branching and enemy-owned critical consumption.
- `FILE_INDEX.md`: Must index this packet and the new design doc.
- Local routing/readmes: No routing change required.

## Validation

```bash
cd custodian
godot --headless --path . --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
godot --headless --path . --script res://tools/validation/operator_modular_defense_ranged_smoke.gd
```
