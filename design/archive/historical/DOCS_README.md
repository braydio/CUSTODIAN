# Documentation Index

This folder contains both implementation references and broader design docs.

## Implementation-Accurate References

Use these first for current behavior:

- `docs/_ai_context/CURRENT_STATE.md`
- `docs/_ai_context/COMMAND_CONTRACT.md`
- `docs/_ai_context/ARCHITECTURE.md`
- `docs/_ai_context/SIMULATION_RULES.md`
- `game/simulations/world_state/docs/world-state-simulation.md`
- `game/simulations/world_state/docs/terminal-repl.md`
- `docs/Custodian_Terminal.md`

## Design / Narrative References

These are concept and planning docs. They may describe target direction beyond current implementation:

- `docs/Broad_Overview_Design_Rules.md`
- `docs/PROJECT_MAP.md`
- `docs/CommandCenter.md`
- `docs/Tutorial_Details.md`
- `docs/GLOBAL_CONTEXT.md`
- `docs/SystemDesign.md`
- `docs/ROADMAP.md`

## Conventions

- Tone: operational, perimeter-defense language; terse and grounded output.
- Simulation authority: backend world-state (`GameState`) is the source of truth.
- UI role: read-only projection + command transport.

## Validation

- World-state tests: `.venv/bin/python -m pytest -q game/simulations/world_state/tests`
