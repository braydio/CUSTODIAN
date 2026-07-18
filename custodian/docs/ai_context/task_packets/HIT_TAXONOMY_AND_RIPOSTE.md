# HIT_TAXONOMY_AND_RIPOSTE

## Packet Status

- Status: in_progress
- Owner: agent
- Agent/session: current
- Created: 2026-07-17
- Last updated: 2026-07-17

## Task

Implement Milestone C of the Combat Resource and Readability System: hit-strength
metadata at the damage boundary, differentiated Operator and enemy reactions,
explicit guard-break presentation, and a unique riposte action after successful
parry.

## Authority

- Primary design: `design/02_features/combat_feel/HIT_TAXONOMY_AND_RIPOSTE.md`
- Umbrella: `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md`
- Parry critical: `design/02_features/combat_feel/PARRY_CRITICAL_BRANCHING_AND_VFX.md`
- Combat feel: `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`

## Work Surface

### Files to change

| File | Phase | What changes |
|------|-------|-------------|
| **New:** `custodian/game/systems/combat/combat_constants.gd` | 1 | HitStrength/DamageType enums |
| `custodian/game/actors/operator/operator.gd` | 1-4 | Accept hit metadata, differentiated reactions, guard break, riposte |
| `custodian/game/actors/enemies/enemy.gd` | 1-2 | Accept hit metadata, differentiated reactions, armor deflect |
| `custodian/game/actors/enemies/enemy_savage.tscn` | 2 | Wire `resists_light_flinch` if applicable |
| `custodian/game/actors/enemies/enemy_marine.tscn` | 2 | Wire `resists_light_flinch = true` |
| `custodian/game/actors/projectiles/bullet.gd` | 1 | Pass hit metadata through projectile damage |
| **New:** `custodian/tools/validation/hit_taxonomy_smoke.gd` | 1-2 | Validate metadata flows and reactions |
| **New:** `custodian/tools/validation/operator_guard_break_smoke.gd` | 3 | Validate guard break presentation |
| **New:** `custodian/tools/validation/riposte_smoke.gd` | 4 | Validate riposte flow |

### Files to read but not change

- `custodian/game/actors/operator/operator_weapon_definition.gd`
- `custodian/game/actors/operator/unarmed_definition.tres`
- `custodian/game/systems/combat/melee_attack_profile.gd`
- `custodian/docs/ai_context/CURRENT_STATE.md` (update after)
- `custodian/docs/ai_context/FILE_INDEX.md` (update after)

### Out of scope

- Armor system (Milestone D)
- Enemy guard/parry (only explicitly authored elites)
- Production guard-break audio (placeholder V1)
- Riposte directional animation suite (E/W minimum)

## Plan

### Phase 1: Hit Metadata Foundation

1. Create `combat_constants.gd` with `HitStrength` and `DamageType` enums
2. Extend `receive_enemy_hit()` signature to accept `hit_strength` parameter with default
3. Extend enemy `take_damage()` signature to accept `hit_strength` parameter with default
4. Wire Operator melee attacks to pass `HitStrength.LIGHT` (fast) or `HitStrength.HEAVY` (heavy)
5. Wire enemy melee attacks to pass appropriate hit strength
6. Wire bullet.gd to pass metadata through `receive_projectile_hit()`
7. **No behavioral change** — metadata flows but `_apply_reaction()` ignores it

### Phase 2: Differentiated Enemy Reactions

8. Add `resists_light_flinch: bool` export to `Enemy`
9. Set `resists_light_flinch = true` on `enemy_marine.tscn`
10. Modify `_apply_reaction()` to accept `HitStrength` and branch on it
11. Add interrupt reaction (brief freeze + cancel)
12. Add armor-deflect presentation (metallic ping + no flinch)
13. Add observability counters for reaction types
14. Create `hit_taxonomy_smoke.gd` validation

### Phase 3: Differentiated Operator Reactions + Guard Break

15. Add heavy-stagger animation state to Operator
16. Modify `_request_damage_reaction()` to use hit metadata
17. Add guard-break VFX (shield-shatter particle)
18. Add guard-break camera shake (0.25s, moderate)
19. Add guard-break stun window (0.40s cannot guard/parry)
20. Add guard-break cooldown (1.5s before guard re-raise)
21. Wire HUD guard-break feedback (stamina flash + text)
22. Create `operator_guard_break_smoke.gd` validation

### Phase 4: Riposte Action

23. Add riposte timing constants to operator.gd
24. Wire riposte to parry success → primary input → no critical-open enemy path
25. Implement riposte damage (1.5x normal melee)
26. Add riposte animation state (reuse fast attack timing initially)
27. Add riposte VFX (counter-strike trail)
28. Add riposte observability counter
29. Create `riposte_smoke.gd` validation

### Phase 5: VFX/Audio Polish (deferred)

30. Source/create production guard-break VFX
31. Source/create production armor-deflect VFX
32. Source/create production riposte trail VFX
33. Wire audio for all new VFX
34. Tune camera shake values

## Constraints

- **Determinism:** Hit metadata is static per-attack, not random. Reactions are deterministic from metadata.
- **Backward compatibility:** All new parameters have defaults. Existing callers unchanged.
- **Simulation boundary:** VFX/audio are presentation only. Hit metadata affects reaction selection, not damage calculation.
- **Riposte:** Additive to existing parry-critical system. Does not replace or modify critical execution.
- **Guard break:** Cooldown is simulation state, not presentation. Must persist across frames.

## Acceptance Criteria

1. `godot --headless --check-only --script res://game/actors/operator/operator.gd` passes
2. `godot --headless --check-only --script res://game/actors/enemies/enemy.gd` passes
3. `godot --headless --quit --scene res://scenes/game.tscn` exits 0
4. Light melee hit on grunt → flinch reaction (not stagger)
5. Heavy melee hit on grunt → stagger reaction
6. Light melee hit on marine → no flinch (armor deflect)
7. Heavy melee hit on marine → stagger reaction
8. Guard break → visible VFX + camera shake + stun window
9. Successful parry → primary input → riposte (if no critical-open enemy)
10. Riposte deals 1.5x damage and has unique animation
11. All existing parry-critical and guard systems work unchanged
12. Observatory reports new hit-type counters

## Drift Review

- `custodian/docs/ai_context/CURRENT_STATE.md` — Needs update after Phase 2 and Phase 4
- `custodian/docs/ai_context/CONTEXT.md` — Check combat architecture section
- `custodian/docs/ai_context/FILE_INDEX.md` — Add new files after each phase
- `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md` — Update Milestone C status

## Completion Notes

- 2026-07-17: Ingested and wired the Operator E/W `bodyslam_knockdown_01` full-body and combat-FX pairs for unblocked HEAVY hits. Incoming direction now reaches presentation through per-hit context; the one-second reaction hides modular/weapon layers and preserves LIGHT recoil behavior. Added `operator_knockdown_animation_smoke.gd`. Guard-break presentation and riposte remain open.

## Next Steps

- Start Phase 1: create `combat_constants.gd` and extend damage function signatures
- Best starting files:
  - `custodian/game/actors/operator/operator.gd` (lines 7710-7810 for receive_enemy_hit)
  - `custodian/game/actors/enemies/enemy.gd` (lines 1732-1750 for take_damage, 2483-2491 for _apply_reaction)
  - `custodian/game/actors/projectiles/bullet.gd` (lines 170-180 for damage delivery)
- Validation to run after each phase:
  - `godot --headless --check-only --script res://game/actors/operator/operator.gd`
  - `godot --headless --check-only --script res://game/actors/enemies/enemy.gd`
  - `godot --headless --quit --scene res://scenes/game.tscn`
