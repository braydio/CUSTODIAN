# AGENTS.md

This repository contains lightweight prototypes for a defense-oriented simulation of a static command post in a collapsed interstellar civilization. Keep changes simple, readable, and consistent with the tone in the simulations (operational, perimeter-defense language; terse, grounded output). Emphasize reconstruction and knowledge preservation over extermination.

## Repo Structure

- `game/simulations/`
  - `world_state/` world simulation prototypes.
  - `assault/` assault simulation modules and JSON data.
- `docs/` root design docs and campaign logic.
- `frameworks/` instruction packs (if present).
- `scripts/` helper scripts.
- `skills/`, `rules/`, `sessions/` are managed by Codex; avoid manual edits unless directed.
- `log/`, `history.jsonl`, `shell_snapshots/` are diagnostics; keep out of version control.

## World-State Simulation

- Entry point: `game/simulations/world_state/sandbox_world.py`.
- Modular code lives in `game/simulations/world_state/core/`.
- Docs live in `game/simulations/world_state/docs/`.
- Tuning knobs are centralized in `game/simulations/world_state/core/config.py` (preferred place for pacing tweaks).

## Coding Style

- Keep Python code straightforward; avoid unnecessary abstraction.
- Favor small functions and clear naming.
- Use ASCII text in code and output.
- Add only minimal comments where logic is not self-explanatory.

## Documentation

- When adding docs for a simulation, place them in a `docs/` subdir next to the Python entry point.
- Keep docs concise with bullets and short paragraphs.
- The canonical AI context bundle lives in `docs/_ai_context/` and must be reviewed every session.
  - Update `CURRENT_STATE.md` every session.
  - Keep all files relevant, timely, and accurate within their scope; do not omit important context.
  - Treat this folder as the authoritative snapshot exported for external review.
- Update this `AGENTS.md` periodically as needed to keep its guidance current.

## Recent Entrypoints

- World sim runner: `game/run.py` (adds repo root to `sys.path` for any CWD).
- World sim standalone: `game/simulations/world_state/sandbox_world.py` (`sandbox_*` replaces `simulate_*`).
- Assault sim standalone: `game/simulations/assault/sandbox_assault.py`.
- Terminal UI server: `custodian-terminal/server.py` (SSE boot stream for remote viewing).

## Main Docs Summary

- `game/simulations/world_state/docs/world-state-simulation.md`: Describes the world_state simulation layout, core state, flow, event system, assault logic, and tuning guidance. It emphasizes a terse, operational tone and points to `core/config.py` for pacing tweaks.

## Testing & Validation

- No formal automated tests yet.
- When documenting validation, state the manual action (e.g., “ran `python sandbox_world.py` and reviewed output”).

## Safety & Secrets

- Do not commit or edit: `auth.json`, `internal_storage.json`, `history.jsonl`, `olddauth.json`.
- Keep credentials out of the repo; store locally.

## Contribution Notes

- Preserve existing tone and theme in event text.
- If refactoring, keep entry points stable.
- Keep sector naming aligned with root docs (Command Center + Goal Sector, plus the eight tutorial peripheral sectors).
- Prefer `rg` for searches in this repo.
