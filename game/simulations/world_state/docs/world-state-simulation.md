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
  - `faction_profile`: ideology + form + tech expression for procedural events.
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

1. Advance time and escalate ambient threat.
2. Run ambient events based on sector state and global threat.
3. Tick or start a major assault timer.
4. If assault starts, resolve it against the weakest sectors.
5. Periodically print snapshots for visibility.

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
