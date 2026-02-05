# DEVLOG — CUSTODIAN

## 2026-02-05
- Added terminal webserver `custodian-terminal/server.py` with SSE boot stream.
- Updated terminal UI to stream boot lines from server when available.
- Renamed `simulate_*` entrypoints to `sandbox_*` and updated references.
- Hardened `game/run.py` to add repo root to `sys.path` for any CWD.
- Added world-state terminal command stack (parser, processor, command registry, REPL) with read/write authority gating.
- Added `step_world` helper and pytest coverage for world-state stepping and terminal commands.
- Added git hooks for docs/secret hygiene: `pre-commit` (block forbidden files, warn on untracked logs), `commit-msg` (docs check with [no-docs] override), `post-commit` (DEVLOG nudge).
- Archived the Phase 1 terminal design lock from `NEXT_FEATURES.md` into `docs/_ai_context/ARCHITECTURE.md` with divergence notes.

Not done:
- No command endpoint wired yet.
- No backend command handling implemented.

## 2026-02-05
- Locked and implemented Phase 1 terminal command loop contract.
- Switched command API to `POST /command` with request `{raw}` and response `{ok, lines}`.
- Reworked terminal command processing to STATUS/WAIT/HELP only.
- Added locked STATUS format and one-tick WAIT behavior with minimal meaningful output.
- Wired terminal UI submit path to backend command endpoint and transcript rendering.
- Updated world-state terminal tests and command contract documentation to match locked behavior.
