# AGENTS.md

This repository contains lightweight prototypes for a defense-oriented simulation of a static command post in a collapsed interstellar civilization. Keep changes simple, readable, and consistent with the simulation tone (operational, perimeter-defense language; terse, grounded output). Emphasize reconstruction and knowledge preservation over extermination.

## Repo Structure

- `game/`: simulation engine code.
- `game/simulations/world_state/`: primary world-state simulation and terminal command stack.
- `game/simulations/assault/`: assault simulation modules and JSON data packs.
- `custodian-terminal/`: Flask UI server, terminal frontend, boot stream scripts, and static assets.
- `design/`: canonical design and architecture docs (see `design/AGENTS.md` for design-layer governance).
- `ai/`: AI context projection docs (`CURRENT_STATE.md`, `FILE_INDEX.md`, `CONTEXT.md`).
- `docs/`: lightweight operational docs (for example deployment notes).
- `tests/`: top-level regression tests.

## Entrypoints

- Unified launcher: `python -m game`
- Terminal UI server (default from unified launcher): `python -m game --ui`
- World-state autonomous sim: `python -m game --sim`
- World-state REPL: `python -m game --repl`
- World-state standalone script: `python game/simulations/world_state/sandbox_world.py`
- Assault standalone script: `python game/simulations/assault/sandbox_assault.py`

## Runtime Servers

- Primary terminal web service: `custodian-terminal/server.py` (boot stream at `/stream/boot`, command endpoint at `/command`, snapshot endpoint at `/snapshot`).
- Secondary world-state server prototype: `game/simulations/world_state/server.py` (stream/history/pause/resume prototype plus `/command` and `/snapshot`).
- Render deployment is configured in `render.yaml` and currently starts Gunicorn with `--chdir custodian-terminal server:app`.

## Terminal Contract Guidance

- Command transport is `POST /command` with JSON containing `command` or `raw`; `command_id` is supported for idempotent replay.
- Backend handler contract is `CommandResult(ok, text, lines=None, warnings=None)` from `game/simulations/world_state/terminal/result.py`.
- Serialized response currently returns `ok`, `text`, and merged `lines` (warnings are folded into `lines` by serializer).
- `text` is the single primary operator-facing line; `lines` are ordered detail lines.
- Keep output concise, operational, and ASCII-safe.

## UI Naming Policy (No Shorthand In User-Facing Text)

- Never use shorthand/acronyms/internal tokens in user-facing UI copy, terminal output, map labels, help text, or tutorials.
- Use full readable names such as `Fabrication`, `North Transit`, `South Transit`, `Command Center`.
- Do not surface abbreviations such as `FAB`, `FB`, `T_NORTH`, `TN`, `T_SOUTH`, `TS`, `CC`, `DF`, `HG`, `GS` to users.
- Internal tokens are allowed in code, data models, and parser aliases only; display surfaces must map to full names via display-name utilities.

## Terminal Module Guidance

- Keep web transport and HTTP routes in `custodian-terminal/server.py`.
- Keep boot stream sequencing in `custodian-terminal/boot.js`.
- Keep terminal I/O rendering and submit wiring in `custodian-terminal/terminal.js`.
- Keep map rendering/overlay logic in `custodian-terminal/sector-map.js`.
- Keep authority and command dispatch logic backend-side in `game/simulations/world_state/terminal/processor.py`.

## World-State Module Guidance

- Keep simulation tick progression in `game/simulations/world_state/core/simulation.py`.
- Keep balancing/tuning knobs in `game/simulations/world_state/core/config.py`.
- Keep parser/token normalization in `game/simulations/world_state/terminal/parser.py` and `terminal/location.py`.
- Keep command specs and handlers under `game/simulations/world_state/terminal/commands/`.
- Handlers must return `CommandResult` and should not print directly.

## Documentation Guidance

- Read `ai/CURRENT_STATE.md` at the start of each session; treat it as current runtime status context.
- Keep `ai/` files concise and synchronized with actual implemented behavior.
- Keep canonical architecture/design changes in `design/` and append material design/architecture changes to `design/DEVLOG.md` once per session.
- If code structure, entrypoints, naming, or behavior drift from docs, update docs in the same change.
- Do not add speculative plans or TODO lists to state-tracking docs.

## Testing & Validation

- Automated tests exist at both top-level `tests/` and `game/simulations/world_state/tests/`.
- Run `python -m pytest` for full regression coverage.
- Prefer targeted runs while iterating (for example `python -m pytest game/simulations/world_state/tests/test_terminal_parser.py`).
- When documenting validation, include exact commands you ran and what you checked manually.

## Coding Style

- Keep Python/JS straightforward; avoid unnecessary abstraction.
- Favor small functions and clear naming.
- Use ASCII in code and output unless a file already requires otherwise.
- Add minimal comments only where logic is not self-evident.
- For multi-phase work, ship stable slices with tests before moving to the next slice.

## Safety & Secrets

- Do not commit credentials or runtime-local artifacts.
- Treat files like `auth.json`, `internal_storage.json`, `history.jsonl`, `olddauth.json`, and similar local auth/state files as sensitive.
- Keep secrets out of repository docs and code.

## Contribution Notes

- Preserve scenario tone and thematic consistency in event text.
- Keep entrypoints stable unless a deliberate migration is documented.
- Keep sector naming aligned with the current world model and user-facing full-name policy.
- Prefer `rg` for repository searches.
