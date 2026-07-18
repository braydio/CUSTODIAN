# HIT TAXONOMY AND RIPOSTE — MILESTONE C

Status: in_progress (Phases 1-2 complete; Phase 3 heavy-hit presentation partial)
Owner: gameplay/combat feel
Runtime target: Godot 4.x (`custodian/`)
Created: 2026-07-17
Last updated: 2026-07-17

## Completed Phases

### Phase 1: Hit Metadata Foundation — COMPLETE
- `CombatConstants.HitStrength` and `CombatConstants.DamageType` enums defined in `combat_constants.gd`
- All damage sources pass `hit_strength` through `attack_context` or direct `take_damage()` params
- Observability counters track light/heavy/interrupt player hits taken
- Full backward compatibility via default parameters

### Phase 2: Differentiated Enemy Reactions — COMPLETE
- `@export var resists_light_flinch: bool = false` on Enemy base, enabled on `enemy_marine.tscn`
- `_apply_reaction()` branches on `hit_strength`:
  - INTERRUPT always causes flinch
  - Heavy hits always flinch (if damage is above minimum)
  - Light hits on `resists_light_flinch` enemies show armor-deflect flash
  - Light hits on normal enemies cause standard flinch
- `_play_armor_deflect_fx()` provides visual-only bright flash feedback
- Observability counters track flinch/stagger/crit/interrupt/armor-deflect enemy reactions

### Phase 3: Differentiated Operator Reactions — PARTIAL
- Unblocked HEAVY hits resolve the authored E/W 12-frame `bodyslam_knockdown_01` full-body strip from incoming hit direction.
- The paired combat-FX strip plays on the existing melee FX layer and is cleaned up with the reaction state.
- LIGHT hits retain the existing 0.22-second recoil; guard-break presentation/cooldown work remains open.
- `operator_knockdown_animation_smoke.gd` covers both directional body/FX resources and live selection.

## Purpose

Make every combat hit visually and audibly distinguishable. Players should never
wonder "did that do damage?" or "why didn't I flinch?" This milestone adds
hit-strength metadata at the damage boundary, differentiated reactions for both
Operator and enemies, explicit guard-break presentation, and a unique riposte
action after successful parry.

## Design Rules

- Simulation authority stays in `operator.gd` and `enemy.gd`. Presentation is
  read-only from hit metadata.
- Hit metadata travels WITH the damage event, never stored as persistent state.
- Heavy enemies may ignore light flinch. This does not change their damage or
  stagger thresholds — it changes their ANIMATION response only.
- Guard break is a stamina-state event, not a damage type. The guard break
  presentation happens when stamina crosses the threshold, not when a
  particular hit lands.
- Riposte is a contextual melee action available during the parry-critical
  window. It is NOT a replacement for the existing critical execution — it is
  a lighter, faster alternative that costs no stamina and deals bonus damage.

## 1. Hit Metadata System

### HitStrength Enum

```gdscript
enum HitStrength {
    LIGHT,      # Standard chip — small recoil, no stagger
    HEAVY,      # Committing strike — guaranteed stagger on light targets
    INTERRUPT,  # Special cancel — interrupts enemy windups without damage-based stagger
}
```

### DamageType Enum

```gdscript
enum DamageType {
    PHYSICAL,   # Default melee/ranged
    EXPLOSIVE,  # Future: grenades, traps
    ENERGY,     # Future: lasers, special attacks
}
```

### HitContext Dictionary

Every damage event should carry a `hit_context` dictionary:

```gdscript
var hit_context := {
    "hit_strength": HitStrength.HEAVY,     # enum value
    "damage_type": DamageType.PHYSICAL,    # enum value
    "source_attack_id": &"melee_heavy",    # for observability
    "knockback_force": 56.0,              # presentation hint
    "can_guard_break": true,              # whether this hit can break guard
}
```

The existing `attack_context` parameter in `receive_enemy_hit()` already
carries dictionaries. We extend it with these standardized fields.

### Where Metadata Is Created

| Source | HitStrength | DamageType | Notes |
|--------|------------|------------|-------|
| Operator melee light/fast | LIGHT | PHYSICAL | Default |
| Operator melee heavy | HEAVY | PHYSICAL | Stagger threshold bypass |
| Operator ranged (Carbine) | LIGHT | PHYSICAL | Unless headshot (future) |
| Operator unarmed light | LIGHT | PHYSICAL | |
| Operator unarmed heavy | HEAVY | PHYSICAL | |
| Enemy normal melee | LIGHT | PHYSICAL | Grunt, savage normal hits |
| Enemy Falcon Punch | HEAVY | PHYSICAL | Guaranteed stagger on Operator |
| Enemy savage chain hit 2 | HEAVY | PHYSICAL | Second hit in chain |
| Enemy marine dash | HEAVY | PHYSICAL | Dash impact |
| Parry critical execution | HEAVY | PHYSICAL | Source-frame-5 contact damage |

## 2. Differentiated Enemy Reactions

### Current System (threshold-only)

```
amount >= crit_damage_threshold    → _start_crit_reaction()
amount >= stagger_damage_threshold → _start_stagger_reaction()
else                               → _start_hit_recoil_reaction()
```

### New System (threshold + strength)

```
if _parry_critical_phase != NONE:
    return  # (unchanged)

if hit_strength == INTERRUPT:
    _start_interrupt_reaction()
elif amount >= crit_damage_threshold or hit_strength == HEAVY:
    _start_stagger_reaction()  # HEAVY bypasses threshold for light enemies
elif amount >= stagger_damage_threshold:
    _start_stagger_reaction()
else:
    _start_hit_recoil_reaction()  # LIGHT flinch
```

### Heavy-Enemy Resistance

Some enemies (marine, future elites) may resist LIGHT flinch:

```gdscript
@export var resists_light_flinch: bool = false

func _apply_reaction(amount: float, hit_strength: int = HitStrength.LIGHT) -> void:
    if _parry_critical_phase != ParryCriticalPhase.NONE:
        return
    if hit_strength == HitStrength.INTERRUPT:
        _start_interrupt_reaction()
        return
    if amount >= crit_damage_threshold or hit_strength == HitStrength.HEAVY:
        _start_stagger_reaction()
    elif amount >= stagger_damage_threshold:
        _start_stagger_reaction()
    elif not resists_light_flinch or hit_strength == HitStrength.HEAVY:
        _start_hit_recoil_reaction()
    # else: no reaction (armor deflect — presentation only)
```

### Enemy Reaction Types

| Reaction | Trigger | Animation | Duration | VFX |
|----------|---------|-----------|----------|-----|
| **Light flinch** | LIGHT hit below stagger threshold | `flinch_s` (existing) | 0.12s | None |
| **Heavy stagger** | HEAVY hit or above stagger threshold | `stagger_s` (existing) | 0.35s | Impact spark |
| **Interrupt** | INTERRUPT hit (cancel windup) | Brief freeze + recoil | 0.15s | Cancel flash |
| **Armor deflect** | LIGHT hit on `resists_light_flinch` enemy | Metallic ping + no flinch | — | Deflect spark |
| **Guard break** | (N/A — enemies don't guard in V1) | — | — | — |

## 3. Differentiated Operator Reactions

### Current System

```
receive_enemy_hit() → try_guard_incoming_attack() → take_damage() → _request_damage_reaction()
_request_damage_reaction() always plays hit_recoil
```

### New System

```
receive_enemy_hit() → try_guard_incoming_attack() → take_damage() → _request_damage_reaction(hit_strength)
```

### Operator Reaction Types

| Reaction | Trigger | Animation | Duration | VFX/Audio |
|----------|---------|-----------|----------|-----------|
| **Light hit** | LIGHT damage, unblocked | `hit_recoil` (existing) | 0.12s | Small spark |
| **Heavy stagger** | HEAVY damage, unblocked | `stagger` (new/extended) | 0.30s | Large spark + camera shake |
| **Guard impact** | Blocked hit (any strength) | `block_hitreact` (existing) | 0.15s | Block spark (existing) |
| **Guard break** | Stamina crosses threshold | `block_break` (new) | 0.40s | Break flash + camera shake + stamina drain VFX |
| **Failed parry hit** | Hit during failed parry | `block_hitreact` (existing) | 0.15s | Red flash |

### Guard Break Presentation

The current guard break is too subtle. New behavior:

1. When `stamina <= guard_break_stamina_threshold`:
   - Play `block_break` animation (new, or reuse `block_hitreact` with longer duration)
   - Spawn guard-break VFX at Operator position (shield-shatter particle)
   - Camera shake (moderate, 0.25s)
   - Brief stun window (0.40s) where Operator cannot guard/parry
   - Stamina drains to 0
   - HUD stamina bar flashes red + "GUARD BROKEN" text

2. Guard break cooldown: 1.5s before guard can be re-raised

## 4. Riposte Action

### Concept

After a successful parry, the Operator can perform a **riposte** — a quick,
powerful counter-attack that deals bonus damage and has a unique animation.
This is distinct from the existing parry-critical execution (which requires
enemy to be in critical-open state and uses the 8-frame paired execution).

### Riposte vs Critical Execution

| Property | Riposte | Critical Execution |
|----------|---------|-------------------|
| **Trigger** | Successful parry + primary input | Parry-critical open window + primary input |
| **Timing** | Immediate (within 0.5s of parry) | During enemy open window (0.8-1.5s) |
| **Target** | Any parried enemy | Only enemies in critical-open state |
| **Animation** | Quick counter-strike (4-6 frames) | Full 8-frame paired execution |
| **Damage** | 1.5x normal melee damage | Lethal (source-frame-5 contact damage) |
| **Stamina cost** | None (refund from parry) | None |
| **VFX** | Parry spark + counter-strike trail | Full execution FX stack |

### Riposte Flow

```
Successful parry
  → _counter_window_timer starts (0.5s)
  → Player presses primary
  → Check: is parried enemy in critical-open state?
    → YES: start critical execution (existing)
    → NO: start riposte (new)
  → Riposte plays quick counter-strike animation
  → Deals 1.5x damage to parried enemy
  → No stamina cost
  → Enemy gets brief stagger from riposte hit
```

### Riposte Animation Requirements

- 4-6 frames at 12 FPS
- Quick forward strike with impact trail
- Should feel snappier than normal melee
- Directional: at minimum E/W, with N/S fallback

### Riposte Timing

- Available: 0.0s to 0.5s after successful parry
- Animation: 0.33-0.50s (4-6 frames at 12 FPS)
- Recovery: 0.15s (shorter than normal melee)
- During riposte: Operator is briefly locked (cannot dodge/parry/guard)

## 5. VFX and Audio Additions

### New VFX Needed

| VFX | Purpose | Frames | Notes |
|-----|---------|--------|-------|
| `guard_break_flash` | Shield-shatter on guard break | 4 | Spawned at Operator position |
| `guard_break_stamina_drain` | Red stamina drain particles | 6 | Optional, HUD-integrated |
| `armor_deflect_spark` | Metallic ping on armor deflect | 3 | For heavy enemies resisting light flinch |
| `riposte_trail` | Counter-strike motion trail | 4 | During riposte animation |
| `heavy_hit_impact` | Large spark for heavy hits | 4 | Larger than existing `hit_spark` |

### New Audio Needed

| Audio | Purpose | Notes |
|-------|---------|-------|
| `guard_break_sfx` | Shield-shatter sound | Heavy, satisfying break |
| `armor_deflect_sfx` | Metallic ping | For armor deflect |
| `riposte_sfx` | Quick counter-strike | Snappier than normal melee |

### Existing VFX Reused

- `hit_spark` — light hits
- `block_spark` — guard impacts
- `parry_contact_spark` — parry success
- `parry_success_fx` — parry success burst

## 6. Observatory Integration

New observability counters:

```gdscript
"hits_light"           # Total light hits dealt
"hits_heavy"           # Total heavy hits dealt
"hits_interrupt"       # Total interrupt hits dealt
"enemy_reactions_flinch"    # Enemy light flinch reactions
"enemy_reactions_stagger"   # Enemy stagger reactions
"enemy_reactions_deflect"   # Enemy armor deflects
"operator_guard_breaks"     # Times guard was broken
"operator_ripostes"         # Successful riposte attacks
"operator_heavy_staggers"   # Times Operator was heavy-staggered
```

## Implementation Phases

### Phase 1: Hit Metadata Foundation

1. Add `HitStrength` and `DamageType` enums to a shared combat constants file
2. Extend `receive_enemy_hit()` to accept and propagate hit metadata
3. Extend enemy `take_damage()` to accept hit metadata
4. Wire Operator melee attacks to pass `HitStrength.LIGHT`/`HEAVY`
5. Wire enemy attacks to pass appropriate hit strength
6. **No behavioral change yet** — metadata flows but doesn't affect reactions

### Phase 2: Differentiated Enemy Reactions

7. Add `resists_light_flinch` export to `Enemy`
8. Modify `_apply_reaction()` to accept and use `HitStrength`
9. Add interrupt reaction for `HitStrength.INTERRUPT`
10. Add armor-deflect presentation for resisted light hits
11. Add observability counters for reaction types
12. **Verify** grunts flinch on light, stagger on heavy; marines resist light flinch

### Phase 3: Differentiated Operator Reactions

13. Add heavy-stagger animation state for Operator
14. Modify `_request_damage_reaction()` to use hit metadata
15. Add guard-break presentation (VFX + camera shake + stun window)
16. Add guard-break cooldown before guard can be re-raised
17. Wire HUD guard-break feedback
18. **Verify** light hits cause small recoil, heavy hits cause stagger, guard break is visible

### Phase 4: Riposte Action

19. Add riposte animation (or reuse fast attack with timing override)
20. Wire riposte to parry success → primary input path
21. Add 1.5x damage multiplier for riposte
22. Add riposte VFX (counter-strike trail)
23. Add riposte observability counter
24. **Verify** riposte triggers after parry, deals bonus damage, has unique feel

### Phase 5: VFX/Audio Polish

25. Create/source guard-break VFX
26. Create/source armor-deflect VFX
27. Create/source riposte trail VFX
28. Wire audio for all new VFX
29. Tune camera shake values for guard break and heavy hits

## Validation

```bash
cd custodian
# Phase 1-2: Hit metadata and enemy reactions
godot --headless --script tools/validation/hit_taxonomy_smoke.gd

# Phase 3: Operator reactions and guard break
godot --headless --script tools/validation/operator_guard_break_smoke.gd

# Phase 4: Riposte
godot --headless --script tools/validation/riposte_smoke.gd

# Existing regression
godot --headless --script tools/validation/grunt_parry_crit_reaction_smoke.gd
godot --headless --script tools/validation/combat_resource_feedback_smoke.gd
```

## Acceptance Criteria

1. Players can distinguish light hit, heavy hit, guard impact, and guard break
   by animation + VFX + audio alone
2. Heavy enemies (marine) resist light flinch but still stagger on heavy hits
3. Guard break has dedicated presentation (not just block hitreact)
4. Riposte is available after successful parry and deals 1.5x damage
5. Riposte has unique animation/VFX distinct from normal melee
6. All existing parry-critical and guard/parry systems still work
7. Simulation remains deterministic
8. Observatory reports new hit-type counters

## Constraints

- Keep all simulation in `operator.gd` and `enemy.gd`
- Hit metadata is per-event, never persistent state
- Guard break cooldown is simulation, not presentation
- Riposte animation can reuse existing assets initially (fast attack timing override)
- Do not change parry-critical execution flow — riposte is additive
- Preserve existing `receive_enemy_hit()` return dictionary shape (extend, don't replace)

## Out of Scope

- Armor system (future Milestone D)
- Elemental damage types (future)
- Enemy guard/parry (only for explicitly authored elite profiles)
- Riposte VFX polish beyond initial wire
- Production guard-break audio (placeholder acceptable for V1)

## Next Agent Slice

Goal: implement Phase 1 (hit metadata foundation) — add enums, extend damage
functions, wire metadata through existing attack paths without behavioral change.

Files:
- `custodian/game/systems/combat/combat_constants.gd` (new)
- `custodian/game/actors/operator/operator.gd`
- `custodian/game/actors/enemies/enemy.gd`
- `custodian/game/actors/enemies/enemy_savage.tscn`
- `custodian/game/actors/enemies/enemy_marine.tscn`

Constraints:
- No behavioral change in Phase 1 — metadata flows but reactions stay the same
- Preserve all existing `receive_enemy_hit()` and `take_damage()` signatures
- Add backward-compatible defaults for new parameters

Acceptance:
- `godot --headless --check-only --script res://game/actors/operator/operator.gd`
- `godot --headless --check-only --script res://game/actors/enemies/enemy.gd`
- `godot --headless --quit --scene res://scenes/game.tscn`
