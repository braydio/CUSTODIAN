# Sector Damage System Design Audit (2026-03-06)

## Scope

Audit target: `design/20_features/in_progress/SECTOR_DAMAGE_SYSTEM.md`

Runtime compared:

- `custodian/entities/sector/sector.gd`
- `custodian/entities/defense/turret.gd`
- `custodian/core/systems/power.gd`
- `custodian/entities/enemies/enemy.gd`

## Summary

Current runtime has partial sector damage behavior, but the feature is not implemented as designed. The highest-risk gaps are missing shared damage-state architecture, missing command-post game-over integration, and power-node semantics not wired to damage states.

Readiness: **Not implementation-complete**. Recommended status: **In progress (audit complete, ready to build)**.

## Findings

### High

1. No shared `Damageable` component exists, so structures do not share a canonical state model (`operational/damaged/critical/destroyed`) from the feature spec.
2. Command-post destruction does not trigger game-over flow; generic sector destruction currently frees the node.
3. Sector damage currently ignores hits when `has_power == false`; this creates invulnerable structures during outages and conflicts with intended persistent damage pressure.

### Medium

4. Power system does not consume damage-state output from power nodes (`get_power_output` model is not present); it uses flat sector `power_cost` distribution.
5. Naming and API shape differ from design (`heal()` in sector vs `repair()` in spec), which will increase integration friction with repair gameplay.
6. Turret damage behavior exists but is independent of a shared state component and uses local thresholds.

## Spec-to-Runtime Mapping

### Implemented now

- Enemies can damage targets with `take_damage()`.
- Sector node tracks HP and updates visuals by health bands.
- Turrets support damage bands and wreck persistence.

### Missing vs spec

- `res://core/systems/damageable.gd`
- `CommandPost` runtime class with `game_over` emission
- `PowerNode` runtime class with state-based output (`1.0 / 0.6 / 0.3 / 0.0`)
- Unified state-change signals for all structures

## Recommended Implementation Order

1. Create `core/systems/damageable.gd` as canonical structure state machine.
2. Refactor `Sector` and `DefenseTurret` to either extend or compose `Damageable` while preserving existing scene usage.
3. Introduce dedicated `CommandPost` behavior (or command-sector specialization) with game-over signal and scene-level handler.
4. Introduce `PowerNode` behavior and update `power.gd` to aggregate node output rather than fixed static assumptions.
5. Align repair contract to `repair(amount)` across all repairable structures.
6. Add UI hooks for state transitions and destruction events.

## Build Slice (Suggested)

### Slice A: Architecture baseline

- Add `Damageable` with signals and state transitions.
- Convert sector/turret HP logic to shared state transitions.

### Slice B: Gameplay critical outcomes

- Implement command-post destruction -> fail state.
- Remove invulnerability on powerless sectors.

### Slice C: Power coupling

- Add power-node output scaling by damage state.
- Rework `power.gd` read model to use node outputs.

## Acceptance Checklist

- [ ] Structures transition through all four states using one canonical model.
- [ ] Command-post destruction reliably triggers game over.
- [ ] Powerless structures can still take damage.
- [ ] Power output scales with power-node damage state.
- [ ] Turret effective output scales consistently with damage state and power.
- [ ] Repair system can call `repair(amount)` uniformly on all structures.

## Decision Needed Before Build

Choose one architecture path and keep it consistent:

- Inheritance path: `Sector`, `DefenseTurret`, `PowerNode`, `CommandPost` extend `Damageable`.
- Composition path: each structure owns a `DamageableComponent` child and forwards events.

For current codebase, inheritance is the fastest path to delivery.
