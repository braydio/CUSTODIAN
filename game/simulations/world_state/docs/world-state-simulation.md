# World State Simulation

This simulation models a fortified command post under escalating pressure. It focuses on ambient tension, sector damage, and periodic major assaults. Output text stays grounded in operational, perimeter-defense language consistent with the theme of the game and the reconstruction-first campaign logic.

## Layout

- `game/simulations/world_state/sandbox_world.py` is the entry point.
- `game/simulations/world_state/core/` contains the modular simulation logic.

## Core State

- `GameState`
  - `time`: abstract ticks.
  - `ambient_threat`: slow, always-rising pressure.
  - `assault_timer`: hidden countdown to a major assault.
  - `in_major_assault`: whether a large assault is active.
  - `player_location`: current sector name for the operator.
  - `in_command_center`: derived flag for Command Center authority checks.
  - `faction_profile`: ideology + form + tech expression for procedural events.
  - `is_failed`: terminal failure latch after Command Center breach.
  - `failure_reason`: locked operator-facing reason for failure mode.
  - `sectors`: dictionary of `SectorState` by name.
- `SectorState`
  - `damage`: persistent wear on a sector.
  - `alertness`: volatility that rises with damage and decays slowly.
  - `power`: availability in that sector.
  - `occupied`: whether hostiles were present this tick.
  - `effects`: lingering sector conditions applied by events.
  - `global_effects`: campaign-level conditions applied by events.

## Sectors (Tutorial Set)

- Critical
  - Command Center
  - Goal Sector
- Peripheral
  - Main Terminal
  - Security Gate / Checkpoint
  - Hangar A
  - Hangar B
  - Fuel Depot
  - Radar / Control Tower
  - Service Tunnels
  - Maintenance Yard

## Simulation Flow

1. Accept one operator command.
2. Validate authority and parse intent.
3. Execute command action.
4. Advance world by one step when command semantics require time (`wait`, movement, and other time-bearing commands).
5. Return a `CommandResult` payload for terminal rendering.

## Command-Driven Stepping

The world-state loop is command-driven in terminal mode.

- No hidden background stepping while input is idle.
- Each accepted time-bearing command advances exactly one simulation step.
- Read-only commands may return state without advancing time.
- Major assault timers and ambient events resolve during the step, not during idle UI time.

This keeps pacing deterministic, debuggable, and aligned with explicit operator intent.

## Events (Procedural)

Ambient events are generated from an event catalog derived from a hostile profile:

- Ideology (why they attack)
- Form (what they are)
- Technology expression (how they fight)

Each event has:

- `min_threat`: the global threat needed to trigger.
- `cooldown`: per-sector cooldown (in ticks).
- `sector_filter`: tag-driven eligibility for specific sectors.
- `weight`: relative chance once eligible.
- Optional `chains` to print secondary consequences.
- Optional persistent effects that decay over time but remain across ticks.

This keeps events consistent with the theme while still procedural and lightweight.

## Failure Conditions

The world enters a terminal failure state when the Command Center is breached.

- Breach threshold is configured in `core/config.py` as `COMMAND_CENTER_BREACH_DAMAGE`.
- Once failed, normal world progression stops.
- Terminal mode accepts only reset/reboot recovery commands until a session reset occurs.

## Assaults

Major assaults occur after a countdown influenced by damage in weak sectors. While active, the assault:

- Increases ambient threat.
- Adds damage and alertness to targeted sectors.
- Ends after a short randomized duration.

## Tuning Notes

- Tuning values live in `game/simulations/world_state/core/config.py` so designers can adjust pacing without editing logic.
- Increase `AMBIENT_THREAT_GROWTH` to tighten the loop.
- Adjust event `cooldown` and `weight` in `events.py` to shift pacing.
- Alter `ASSAULT_TIMER_*` and `ASSAULT_DURATION_*` values to make assaults rarer or more frequent.
- Keep event text terse and operational to preserve the tone.

## Run It

From this directory:

```bash
python sandbox_world.py
```

### Phase 1 Terminal

Phase 1 uses a deterministic terminal loop with manual time advancement.

```bash
WORLD_STATE_MODE=repl python sandbox_world.py
```

Use `WORLD_STATE_MODE=sim` to run the autonomous loop.
