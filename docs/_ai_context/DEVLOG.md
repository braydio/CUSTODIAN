# DEVLOG — CUSTODIAN

## 2026-02-05
- Added terminal webserver `custodian-terminal/server.py` with SSE boot stream.
- Updated terminal UI to stream boot lines from server when available.
- Renamed `simulate_*` entrypoints to `sandbox_*` and updated references.
- Hardened `game/run.py` to add repo root to `sys.path` for any CWD.

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
