# AI CONTEXT — CUSTODIAN

This folder is the canonical project snapshot for external review and AI sessions.
Read files in this order:

1. `CURRENT_STATE.md`
2. `COMMAND_CONTRACT.md`
3. `ARCHITECTURE.md`
4. `SIMULATION_RULES.md`
5. `FILE_INDEX.md`
6. `ROADMAP.md`
7. `DEVLOG.md`

## Scope

- This context tracks implemented behavior in the current codebase.
- Design ideation docs under `docs/` may be aspirational unless explicitly mirrored here.
- If behavior changes, update this folder in the same session.

## Entrypoints

- Unified CLI: `python -m game`
- UI server: `python -m game --ui`
- REPL: `python -m game --repl`
- Autonomous sim: `python -m game --sim`

## Validation Baseline

- World-state tests: `.venv/bin/python -m pytest -q game/simulations/world_state/tests`
