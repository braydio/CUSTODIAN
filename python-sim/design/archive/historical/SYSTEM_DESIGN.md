# System Design

This document describes the implemented simulation architecture and near-term design intent.

## Design Priority

- Simulation authority first.
- Terminal transport and read-only UI projection second.
- Avoid UI-side state mutation.

## Implemented Structure

- Single mutable `GameState` per running server process.
- Command parsing/dispatch in terminal processor.
- Explicit world stepping through `step_world` under time-bearing commands.
- Shared command transport helpers (`server_contracts.py`) used by both servers.

## Time and Pressure Model

- No autonomous background ticking in terminal command mode.
- Pressure, assaults, repairs, fabrication, and fidelity all progress through world ticks.
- Wait units are variable by context:
  - default wait unit = 5 ticks
  - active assault wait unit = 1 tick

## Information Model

- Comms fidelity controls operator certainty.
- STATUS is filtered truth.
- WAIT is filtered operational signaling over stepped ticks.

## Presence and Authority

- Command authority depends on location mode (`COMMAND` vs `FIELD`).
- Strategic commands are denied in field mode.
- Movement/transit commands define where authority is available.

## Current Subsystems

- Spatial assault approaches + tactical assault resolution.
- Repairs with power/output dependencies and regression on damage.
- Fabrication queue and stock production.
- Defense policy, doctrine, and allocation controls.
- Snapshot projection for terminal side-panel UI.

## Deferred Scope

- Campaign/hub persistence beyond current scaffolding.
- Additional world-generation and long-arc campaign systems.
- Non-terminal presentation layers that alter simulation contract.
