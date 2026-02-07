# Documentation Index

This folder contains design, campaign, and system references for the CUSTODIAN prototypes. Use this index to navigate the current design intent and implementation priorities.

## Start Here

- `docs/Broad_Overview_Design_Rules.md`: core fantasy, progression tracks, enemy generation rules, campaign arc, and scope boundaries.
- `docs/SystemDesign.md`: system boundaries, time/pressure model, and implementation order for the simulation layer.
- `docs/PROJECT_MAP.md`: tutorial campaign structure, base topology, and first assault spec (locked for now).
- `docs/CommandCenter.md`: command center capabilities, power routing, and awareness asymmetry.
- `docs/Tutorial_Details.md`: first assault teaching goals and pacing refinements.
- `docs/ROADMAP.md`: next steps and staged development plan.

## Simulation Docs

- `game/simulations/world_state/docs/world-state-simulation.md`: world-state simulation layout, core state model, event flow, command-driven stepping, and terminal failure behavior.
- `game/simulations/world_state/docs/terminal-repl.md`: Phase 1 terminal loop, live `/command` transport contract, command reference (`STATUS`, `WAIT`, `HELP`), and failure recovery flow (`RESET`/`REBOOT`).
- `docs/Custodian_Terminal.md`: terminal UI prototype notes for the custodian interface.

## AI Context Snapshot

- `docs/_ai_context/CURRENT_STATE.md`: current implementation snapshot and locked/flexible decisions.
- `docs/_ai_context/COMMAND_CONTRACT.md`: current `/command` request/response contract across both Flask server surfaces and command semantics.
- `docs/_ai_context/DEVLOG.md`: architecture and behavior change log.

## Conventions

- Tone: operational, perimeter-defense language; terse, grounded output.
- Scope: build systems first in text simulations; visuals and 3D presentation are deferred until the simulation loop is stable.
- Design north star: reconstruction and knowledge preservation over extermination.

## Testing

- World-state terminal tests: `python -m pytest game/simulations/world_state/tests`
