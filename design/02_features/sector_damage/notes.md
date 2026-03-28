# Sector Damage System Design Audit (2026-03-06)

## Scope

Audit target: `design/20_features/in_progress/SECTOR_DAMAGE_SYSTEM.md`

Runtime compared:

- `custodian/entities/sector/sector.gd`
- `custodian/entities/defense/turret.gd`
- `custodian/core/systems/power.gd`
- `custodian/entities/enemies/enemy.gd`

## Summary

Current runtime has partial sector damage behavior, with Slice A now landed. The highest-risk remaining gaps are command-post game-over integration and power-node semantics not wired to damage states.

Readiness: **Core implementation complete**. Recommended status: **Ready for gameplay balancing and polish**.

## Progress Update (2026-03-07)

Slice A/B/C core is now implemented:

- Added shared state machine: `custodian/core/systems/damageable.gd`
- Refactored `Sector` to extend `Damageable`
- Refactored `DefenseTurret` to extend `Damageable`
- Added command post specialization: `custodian/entities/sector/command_post.gd`
- Added power node specialization: `custodian/entities/sector/power_node.gd`
- Updated power coupling logic: `custodian/core/systems/power.gd`
- Wired scene integration for command and power sectors: `custodian/scenes/game.tscn`

Remaining work is non-blocking polish (UI feedback depth, balance tuning, persistence interactions).

## Findings

### High

1. No blocking high-severity gaps remain for the feature slice.

### Medium

2. Destruction/game-over UX is functional but minimal (no dedicated modal/state screen).
3. Power economy values require balance tuning against wave pressure.

## Spec-to-Runtime Mapping

### Implemented now

- Enemies can damage targets with `take_damage()`.
- Sector node tracks HP and updates visuals by health bands.
- Turrets support damage bands and wreck persistence.

### Missing vs spec

- Dedicated fail-state presentation layer (optional polish)
- Final balancing pass for power output/consumption ratios

## Recommended Implementation Order

1. Tune balance values for `power_output`, `power_cost`, and repair economy.
2. Add fail-state modal/restart flow if needed for playtest loop.
3. Extend telemetry/logging for structure state transitions.

## Build Slice (Suggested)

### Slice A: Architecture baseline

- [x] Add `Damageable` with signals and state transitions.
- [x] Convert sector/turret HP logic to shared state transitions.

### Slice B: Gameplay critical outcomes

- [x] Implement command-post destruction -> fail state.
- [x] Remove invulnerability on powerless sectors.

### Slice C: Power coupling

- [x] Add power-node output scaling by damage state.
- [x] Rework `power.gd` read model to use node outputs.

## Acceptance Checklist

- [x] Structures transition through all four states using one canonical model.
- [x] Command-post destruction reliably triggers game over.
- [x] Powerless structures can still take damage.
- [x] Power output scales with power-node damage state.
- [x] Turret effective output scales consistently with damage state and power.
- [x] Repair system can call `repair(amount)` uniformly on all structures.

## Decision Needed Before Build

Choose one architecture path and keep it consistent:

- Inheritance path: `Sector`, `DefenseTurret`, `PowerNode`, `CommandPost` extend `Damageable`.
- Composition path: each structure owns a `DamageableComponent` child and forwards events.

For current codebase, inheritance is the fastest path to delivery.
