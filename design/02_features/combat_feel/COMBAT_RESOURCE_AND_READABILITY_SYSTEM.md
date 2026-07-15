# CUSTODIAN — Combat Resource and Readability System

**Roadmap:** Cross-cutting Combat Resource and Readability
**Status:** in_progress
**Owner:** gameplay/combat + logistics + enemy behavior
**Runtime target:** Godot 4.x (`custodian/`)
**Last updated:** 2026-07-14

## Purpose

CUSTODIAN combat should make every choice affect immediate survival or future
route safety. Ranged attacks spend ammunition, create heat and noise, and force
reload or recovery windows. Melee conserves supplies but requires commitment.
Defense is timing- and stamina-driven. Storage, deployables, and allied drones
make the battlefield part of the resource problem.

This is the active integration and remaining-work authority. Completed V1
slices keep their detailed contracts in the permanent feature specs listed
below; this document does not duplicate their runtime ownership.

## Current Runtime State

| System | State | Runtime result | Durable authority |
|---|---|---|---|
| Typed ammunition, magazines, reload, range/falloff | complete-v1 | Capped typed reserves and persistent per-weapon magazines; projectile range and falloff are live; normal-play HUD keeps magazine/reserve counts visible while a separate pressure row shows reload progress | `RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md` |
| Weapon heat and overheat | complete-v1 | Per-weapon heat, delayed decay, spread/recoil scaling, overheat lockout, threshold-aware status, discrete feedback events, compact HUD pressure state, weapon-local audio, and procedural barrel vent VFX are live | `RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md` |
| Positional gunshot noise | complete-v1 | `NoiseEventBus` drives local enemy investigation, LOS-loss search, and leash return | `RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md` |
| Global attention/escalation | pending | No shared attention meter, alarm network, reinforcement pressure, or ritual acceleration from noise | This document |
| Sidearm loadout tradeoff | complete-v1 | Recovered P-9 must occupy the Equipment-page sidearm slot; equipped P-9 replaces guard/parry with sidearm-ready | `COMBAT_FEEL_SYSTEM.md`, `SIDEARM_UNLOCK.md` |
| Health | complete-v1 | Operator health, damage, death, hit recoil, and HUD/status display are live | `COMBAT_FEEL_SYSTEM.md` |
| Field Patch healing/restock | complete-v1 | Operator carries limited Field Patches, uses a timed commit heal, slows during use, restores 35% max health at commit, and interrupts before commit on damage or conflicting actions. Restock v1 is terminal/crafting based through `lattice_field_patch`, with emergency cache pickup fallback materials when full. | This document |
| Stamina, dodge, guard, parry | complete-v1 | Dodge/heavy/parry costs, guard chip and stamina damage, timed parry, enemy stagger, and counter window are live | `COMBAT_FEEL_SYSTEM.md` |
| Dedicated riposte/opened state | partial | Parry grants a counter damage window, but there is no unique riposte action or persistent enemy-opened state | This document |
| Hit readability | partial | Operator hit recoil and enemy recoil/stagger thresholds are live; strength taxonomy, armor deflect, guard-break presentation, and complete animation coverage are not | This document |
| Durability | pending | No weapon, armor, tool, drone, turret, or deployable durability economy | This document |
| Physical storage and theft | complete-v1 | Typed vault storage, enemy theft/sabotage/escape, permanent loss, dropped recovery bundles, and state textures are live | `ENEMY_OBJECTIVE_SYSTEM.md` |
| Portable turrets | complete-v1 | Fabrication build tokens, placement preview/validation, placement, pickup/redeployment, health, targeting, and power hooks are live | `turret/implementation.md`, `RESOURCE_FABRICATION_SYSTEM.md` |
| Traps | pending | No player trap inventory, placement, trigger, or recovery contract | This document |
| Allied combat drones | complete-v1 | Two fragile local drones support FOLLOW/HOLD/INTERCEPT/RECALL with deterministic targeting and burst fire | `AUTONOMOUS_COMBAT_DRONES.md` |
| Drone logistics | pending | No battery, repair/reboot, fabrication reserve, production animation, or redeployment loop | This document |

## Permanent Completed-Slice Authorities

Completed slices are maintained in their feature homes:

- Ranged pressure and stealth:
  `design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md`
- Core combat, parry/guard, stamina, and sidearm controls:
  `design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`
- Sidearm acquisition and equipment gate:
  `design/02_features/operator/SIDEARM_UNLOCK.md`
- Physical enemy objectives, vault storage, and theft:
  `design/02_features/enemy_objective/ENEMY_OBJECTIVE_SYSTEM.md`
- Turret behavior and placement:
  `design/02_features/turret/implementation.md`
- Fabrication/build-token bridge:
  `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`
- Allied drone V1:
  `design/02_features/vehicles/AUTONOMOUS_COMBAT_DRONES.md`

Their live Godot ownership remains under `custodian/game/`, `custodian/content/`,
and `custodian/autoload/`. A completed slice should be changed in its durable
authority first and summarized here only when integration state changes.

## Active Design Rules

### Ranged pressure

- Ranged weapons remain strong in deliberate bursts.
- Ammunition is strategic scarcity; heat is immediate pressure; noise is a
  positional consequence.
- High heat may worsen spread/recoil before overheat. Production feedback must
  make hot, critical, overheated, dry-fire, reload, and recovery causes clear.
- Ammo caches and supply drops remain bounded. Contextual enemy ammunition
  drops and ammunition/fabrication competition are not yet authoritative.

### Sidearm and defense controls

The equipped offhand slot decides the action. Do not reintroduce the obsolete
"aim plus secondary shot" proposal.

```text
selected ranged primary + hold offhand secondary -> primary ranged-ready
melee/unarmed + equipped P-9 + hold offhand secondary -> sidearm-ready
sidearm-ready + primary -> fire P-9
melee/unarmed + empty/defensive offhand + hold secondary -> guard
guard + primary -> parry
```

### Healing

The first healing slice uses a limited physical Field Patch:

- maximum carried baseline: 2
- starting count baseline: 1
- tunable use time target: 1.25 seconds
- tunable restore target: 35% maximum health
- apply healing only at a timed commit point
- damage, dodge, reload, attack, death, terminal/runtime locks, and field-work input interrupt before commit
- no free combat regeneration
- primary restock is fabrication at the Custodian Field Terminal under
  Fabrication / Consumables: `lattice_field_patch` costs `resin_clot` x2,
  `signal_filament` x1, and `capacitor_dust` x1, consumes resources only when
  the Operator can accept the patch, completes as an `operator_consumable`
  output through `Operator.add_field_patches(...)`, and cannot exceed the carry cap
- secondary restock is rare sealed emergency caches: below cap they grant +1
  Field Patch; at cap they grant fallback materials instead
- no enemy health-potion drops, passive wave refill, or free combat regeneration

### Hit readability and riposte

- Damage events should distinguish at least light, heavy, interrupt, armor
  deflect, stagger, guard impact, and guard break.
- Heavy enemies may ignore light flinch; presentation must not silently change
  damage or stagger authority.
- Parry already owns startup/active/recovery/success timing. The next extension
  adds a visible enemy-opened state and unique melee riposte without duplicating
  the existing parry receiver.
- Enemy parry remains restricted to explicitly authored elite profiles.

### Durability

Durability follows healing and readability. It must be predictable, repairable,
and infrequent enough to create strategic tension rather than maintenance spam.
Runtime durability belongs to item/deployable state, never shared resource data.

### Battlefield logistics

- Storage and stolen resources remain physical and recoverable before escape.
- Portable turrets remain resource-backed deployables, not free abilities.
- Traps must consume an item/build token and use the existing placement-validity
  boundary where possible.
- Drones remain fragile local support. Battery, repair, and redeployment must not
  give them objective-solving or global command authority.

## Remaining Milestones

### Milestone A — Production combat-pressure feedback

- Complete-v1: normal-play heat/overheat/reload/dry-fire feedback consumes
  authoritative Operator snapshots and discrete transition events without moving
  weapon state into UI.
- Complete-v1: active weapon magazine/reserve count remains continuously visible;
  a polymorphic pressure row displays heat, critical, reload, dry, and vent state.
- Complete-v1: held-fire failure feedback and observability are debounced while
  the underlying request remains live, so firing resumes automatically after reload/cooling.
- Remaining tuning: review rifle burst cadence, cache supply, sidearm distinction,
  movement handling, and cue mix in play.
- Decide whether explicit vent input adds value beyond current lockout cooling.
- Extend noise sources only through `NoiseEventBus`.

Acceptance: ranged constraints are readable without F12; the player cannot fire
the rifle indefinitely; current ranged-balance smoke remains green.

### Milestone B — Field Patch survival pressure

- Carried Field Patch count and quick-use action are complete-v1.
- Timed, interruptible heal commit and partial restore are complete-v1.
- Cache/fabrication restock using existing resource IDs is complete-v1.
- Add production start/apply/recovery presentation assets beyond the current placeholder warning.

Acceptance: healing is finite, cannot be animation-cancelled for free, and does
not regenerate health passively. Runtime v1 acceptance is covered by
`custodian/tools/validation/field_patch_smoke.gd`.

### Milestone C — Hit taxonomy and full riposte

- Normalize hit-strength metadata at the existing damage boundary.
- Add differentiated enemy and Operator reactions with heavy-enemy resistance.
- Add explicit guard-break presentation.
- Add enemy-opened state and unique riposte action after successful parry.

Acceptance: players can distinguish hurt, deflect, stagger, parry-opened, guard
impact, and guard break; simulation remains deterministic.

### Milestone D — Durability and field repair

- Define item/deployable durability data and save ownership.
- Apply wear from configured actions only.
- Add field repair costs and readable degraded-state thresholds.

Acceptance: wear is predictable and recoverable, never stored in shared `.tres`
resources, and does not create per-encounter repair spam.

### Milestone E — Traps and drone logistics

- Add one minimal trap through the existing build-token/placement bridge.
- Add drone battery plus disabled/repair/redeploy states.
- Add production presentation hooks without expanding autonomous authority.

Acceptance: both systems spend physical resources, expose valid state, and
remain local tactical aids.

## Validation Baseline

```bash
cd custodian
godot --headless --script tools/validation/ranged_combat_balance_smoke.gd
godot --headless --script tools/validation/combat_resource_feedback_smoke.gd
godot --headless --script tools/validation/field_patch_smoke.gd
godot --headless --script tools/validation/enemy_behavior_vault_smoke.gd
godot --headless --script tools/validation/debug_collector_combat_drone_smoke.gd
```

Add focused validation per milestone. Manual combat-feel review remains required
for cadence, readability, animation interruption, and control regressions.

## Next Agent Slice

Goal: perform the manual feel/mix review for completed Milestone A, replace shared
P-9 cues when weapon-specific audio arrives, then begin Milestone C hit taxonomy.

Files: combat resource feedback presenter/HUD, ranged weapon JSON/audio, and the
combat hit/reaction boundaries named by Milestone C.

Constraints: UI is read-only; retain typed ammo adapters; use `NoiseEventBus`;
preserve the equipment-gated sidearm and guard/parry control contract.

Acceptance: cue cadence and mix remain readable without chatter; weapon-specific
replacement assets preserve the existing event contract; the next hit-readability
slice keeps presentation out of damage/stagger authority.
