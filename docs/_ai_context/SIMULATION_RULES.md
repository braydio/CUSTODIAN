# SIMULATION RULES — CUSTODIAN

## Time
- The world simulation advances by explicit ticks.
- No hidden background ticking outside the world simulation loop.
- Terminal command loop advances time only via `wait`.

## State
- `GameState` is the authoritative container for world-state data.
- Assaults are stateful objects tracked in the world state.

## Assaults
- Assault lifecycle is managed by the world-state layer.
- Assault resolution is delegated to the assault prototype module.

## Autopilot
- Reactive only; it should not introduce hidden time progression.

## Output
- Simulation output remains operational, terse, and grounded.
- Avoid verbose narration or speculative text.
