# SIMULATION RULES — CUSTODIAN

Status: Active
Last updated: 2026-03-04

## Tick and Time

- Active runtime simulation is fixed-step (default target 60Hz).
- Simulation systems execute on fixed ticks only.
- Render frames may interpolate but must not mutate authoritative gameplay state.

## Determinism

- Use deterministic RNG streams for simulation-affecting outcomes.
- Avoid frame-rate-dependent mutation.
- Equivalent seed + input sequence must produce equivalent outcomes.

## Pause and Scaling

- Hard pause freezes simulation mutation.
- Input/command planning can continue while paused.
- Time scaling is allowed only if deterministic tick-order remains stable.

## State Authority

- `GameState` (autoload singleton in Godot) is authoritative for the active runtime.
- Visual scenes and UI consume state; they do not define rules.

## Assault, Repair, and Infrastructure

- Assaults, damage propagation, repair progression, fabrication, and relay state mutate on simulation ticks.
- Power and logistics remain cross-system modifiers.

## Legacy Python Rules

Legacy terminal command-time progression rules (`WAIT`, `WAIT NX`, `WAIT UNTIL`) are preserved in `python-sim/game/` as historical reference only and are not the primary live runtime model.
