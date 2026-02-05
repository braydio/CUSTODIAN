# DEVLOG — CUSTODIAN

## 2026-02-05
- Added terminal webserver `custodian-terminal/streaming-server.py` with SSE boot stream.
- Renamed `simulate_*` entrypoints to `sandbox_*` and updated references.
- Hardened `game/run.py` to add repo root to `sys.path` for any CWD.
- Added world-state terminal command stack (parser, processor, command registry, REPL) with read/write authority gating.
- Added `step_world` helper and pytest coverage for world-state stepping and terminal commands.
- Added git hooks for docs/secret hygiene: `pre-commit` (block forbidden files, warn on untracked logs), `commit-msg` (docs check with [no-docs] override), `post-commit` (DEVLOG nudge).
- Archived the Phase 1 terminal design lock from `NEXT_FEATURES.md` into `docs/_ai_context/ARCHITECTURE.md` with divergence notes.
- Updated terminal boot flow: `boot.js` now appends a system log and unlocks command mode; terminal input submits to `/command` and renders lines or failure messages (UI only; backend endpoint not implemented yet).
- Added alternate boot script `custodian-terminal/server-streaming-boot.js` for SSE boot streaming.

Not done:
- No backend `/command` endpoint wired yet.
- No server-side command handling integrated with the terminal UI.
