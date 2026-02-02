# AGENTS.md

This repository contains lightweight prototypes for a defense-oriented simulation of a static command post in a collapsed interstellar civilization. Keep changes simple, readable, and consistent with the tone in the simulations (operational, perimeter-defense language; terse, grounded output). Emphasize reconstruction and knowledge preservation over extermination.

## Repo Structure

- `game/simulations/`
  - `world-state/` world simulation prototypes.
  - `assault/` assault simulation modules and JSON data.
- `docs/` root design docs and campaign logic.
- `frameworks/` instruction packs (if present).
- `scripts/` helper scripts.
- `skills/`, `rules/`, `sessions/` are managed by Codex; avoid manual edits unless directed.
- `log/`, `history.jsonl`, `shell_snapshots/` are diagnostics; keep out of version control.

## World-State Simulation

- Entry point: `game/simulations/world-state/simulate-world.py`.
- Modular code lives in `game/simulations/world-state/world_state/`.
- Docs live in `game/simulations/world-state/docs/`.
- Tuning knobs are centralized in `game/simulations/world-state/world_state/config.py` (preferred place for pacing tweaks).

## Coding Style

- Keep Python code straightforward; avoid unnecessary abstraction.
- Favor small functions and clear naming.
- Use ASCII text in code and output.
- Add only minimal comments where logic is not self-explanatory.

## Documentation

- When adding docs for a simulation, place them in a `docs/` subdir next to the Python entry point.
- Keep docs concise with bullets and short paragraphs.

## Main Docs Summary

- `simulations/world-state/docs/world-state-simulation.md`: Describes the world-state simulation layout, core state, flow, event system, assault logic, and tuning guidance. It emphasizes a terse, operational tone and points to `world_state/config.py` for pacing tweaks.

## Testing & Validation

- No formal automated tests yet.
- When documenting validation, state the manual action (e.g., “ran `python simulate-world.py` and reviewed output”).

## Safety & Secrets

- Do not commit or edit: `auth.json`, `internal_storage.json`, `history.jsonl`, `olddauth.json`.
- Keep credentials out of the repo; store locally.

## Contribution Notes

- Preserve existing tone and theme in event text.
- If refactoring, keep entry points stable.
- Keep sector naming aligned with root docs (Command Center + Goal Sector, plus the eight tutorial peripheral sectors).
- Prefer `rg` for searches in this repo.
