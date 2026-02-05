# ARCHITECTURE — CUSTODIAN (Canonical)

## High-Level Loop
- Recon / Expedition → Return with knowledge + materials → Build / reinforce base → Assault → Repair → Repeat.

## Simulation Structure
- World-state simulation is the ambient loop that drives events and assault timing.
- Assault simulation is a focused resolution prototype; it can be invoked by the world-state layer.

## Interface
- Terminal-first interface; UI is a thin view of the simulation state and command results.
- Operational, perimeter-defense language with terse output.

## Authority Model
- Authority is location-based (Command Center presence) rather than flags.

## Time Model
- Time advances by explicit ticks; avoid hidden background time in the world simulation.

## Canonical Entrypoints
- World sim: `game/run.py` (imports `game.simulations.world_state.core.simulation.sandbox_world`).
- World sim standalone: `game/simulations/world_state/sandbox_world.py`.
- Assault sim standalone: `game/simulations/assault/sandbox_assault.py`.
- Terminal UI server: `custodian-terminal/server.py`.

## Notes
- This file should only change when architectural decisions are locked or revised.
