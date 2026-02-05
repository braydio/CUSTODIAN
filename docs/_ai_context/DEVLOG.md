# DEVLOG — CUSTODIAN

## 2026-02-05
- Added terminal webserver `custodian-terminal/server.py` with SSE boot stream.
- Updated terminal UI to stream boot lines from server when available.
- Renamed `simulate_*` entrypoints to `sandbox_*` and updated references.
- Hardened `game/run.py` to add repo root to `sys.path` for any CWD.

Not done:
- No command endpoint wired yet.
- No backend command handling implemented.
