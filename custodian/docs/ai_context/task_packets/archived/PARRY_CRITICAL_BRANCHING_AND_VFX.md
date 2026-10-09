# PARRY CRITICAL BRANCHING AND VFX

- Status: `complete`
- Authority: `design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md`; supporting umbrella `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Goal: Replace frozen-stagger critical-open presentation with explicit enter/hold/recover phases and migrate the follow-up into a reserved, synchronized paired execution.
- Files: `custodian/game/actors/operator/operator.gd`; `custodian/game/actors/enemies/enemy.gd`; focused validation under `custodian/tools/validation/`; AI/design docs.
- Constraints: Every guard entry goes through `block_enter`; critical-open phases keep independent actor roots after one parry knockback step; enemy owns opportunity/reservation/damage authority; Operator owns the shared nonuniform eight-frame timeline after reservation; damage occurs once on source frame 5 (runtime index 4); matched directional layers are not independently mirrored; their full-cell layers share a zero-offset root; grunt asset filenames use `melee__`.
- Acceptance: Enter advances to looping hold; expiry advances through recover; reservation is atomic; Operator and victim share the zero-offset execution root; semantic Operator body/FX and enemy victim clips share the authored duration table; source-frame-5 damage is exactly once; contact freezes both paired actors for 110ms; control remains locked through the final settle; lethal/nonlethal/cancel cleanup is safe; focused Godot smokes pass.
- Completed: Added authored grunt enter/hold/recover registrations and phases; preserved the post-knockback enemy root and suppressed ordinary targeting through standalone recovery; realigned hold artwork 16 pixels right inside its uncropped cells for enter/hold/recover continuity; tokenized reservation plus begin/damage/finish/cancel callbacks; scene-owned zero-local execution anchor; fixed shared-root alignment with no Operator separation offset; wired matched S/E/W semantic playback; replaced uniform playback with 90/130/160/220/50/150/150/250ms holds, source-frame-5 one-shot damage, a 110ms paired contact freeze, a dedicated 3px directional camera impulse, and final-settle control locking; retained lethal, nonlethal, and interruption cleanup; DevConsole critical/execution grunt spawn presets; required-asset failures; focused smoke coverage; root-spec redirect and context drift cleanup.
- Deferred: North-facing paired execution art remains unauthored, so vertical approaches deliberately use the south composition.

## Drift Review

- Primary authority: Added `design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md`.
- `CURRENT_STATE.md`: Updated for explicit open phases and paired ownership.
- `FILE_INDEX.md`: Updated for the active runtime/API/test contract.
- Local routing/readmes: No routing change required.

## Validation

```bash
cd custodian
godot --headless --path . --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
godot --headless --path . --script res://tools/validation/debug_grunt_spawn_modes_smoke.gd
godot --headless --path . --script res://tools/validation/operator_modular_defense_ranged_smoke.gd
```
