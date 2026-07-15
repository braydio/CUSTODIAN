# PARRY CRITICAL BRANCHING AND VFX

- Status: `complete`
- Authority: `design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md`; supporting umbrella `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Goal: Replace frozen-stagger critical-open presentation with explicit enter/hold/recover phases and migrate the follow-up into a reserved, synchronized paired execution.
- Files: `custodian/game/actors/operator/operator.gd`; `custodian/game/actors/enemies/enemy.gd`; focused validation under `custodian/tools/validation/`; AI/design docs.
- Constraints: Every guard entry goes through `block_enter`; enemy owns opportunity/reservation/damage authority; Operator owns the shared eight-frame timeline; damage occurs once at frame 3; the authored south pair is not mirrored; grunt asset filenames use `melee__`.
- Acceptance: Enter advances to looping hold; expiry advances through recover; reservation is atomic; semantic Operator body/FX and enemy victim clips share an 8-frame 12-FPS clock; frame-3 damage is exactly once; lethal/nonlethal/cancel cleanup is safe; focused Godot smokes pass.
- Completed: Added authored grunt enter/hold/recover registrations and phases; tokenized reservation plus begin/damage/finish/cancel callbacks; scene-owned execution anchor; fixed south alignment; semantic Operator body/FX and enemy victim playback; shared fixed-step frame clock with frame-3 one-shot damage; lethal, nonlethal, and interruption cleanup; required-asset failures; focused smoke coverage; root-spec redirect and context drift cleanup.
- Deferred: Directional paired executions remain unauthored. The requested combined 128px Aseprite master is not present at its canonical source-only path and is not used by runtime playback.

## Drift Review

- Primary authority: Added `design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md`.
- `CURRENT_STATE.md`: Updated for explicit open phases and paired ownership.
- `FILE_INDEX.md`: Updated for the active runtime/API/test contract.
- Local routing/readmes: No routing change required.

## Validation

```bash
cd custodian
godot --headless --path . --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
godot --headless --path . --script res://tools/validation/operator_modular_defense_ranged_smoke.gd
```
