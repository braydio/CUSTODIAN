# DEVLOG — CUSTODIAN

## 2026-02-05
- Added terminal webserver `custodian-terminal/streaming-server.py` with SSE boot stream.
- Renamed `simulate_*` entrypoints to `sandbox_*` and updated references.
- Hardened `game/run.py` to add repo root to `sys.path` for any CWD.
- Added world-state terminal command stack (parser, processor, command registry, REPL) with read/write authority gating.
- Added `step_world` helper and pytest coverage for world-state stepping and terminal commands.
- Added git hooks for docs/secret hygiene: `pre-commit` (block forbidden files, warn on untracked logs), `commit-msg` (docs check with [no-docs] override), `post-commit` (DEVLOG nudge).
- Archived the Phase 1 terminal design lock from `NEXT_FEATURES.md` into `docs/_ai_context/ARCHITECTURE.md` with divergence notes.
- Added alternate boot script `custodian-terminal/server-streaming-boot.js` for SSE boot streaming.
- Added unified entrypoint `python -m game` with `--ui`/`--sim`/`--repl` modes and updated README entrypoints.

## 2026-02-06
- Implemented `/command` in `custodian-terminal/streaming-server.py` using a persistent `GameState` and terminal command processor dispatch.
- Updated terminal boot flow integration so UI command submit/render path now uses backend `CommandResult` payloads (`ok`, `text`, optional `lines`/`warnings`).
- Standardized world-state `/command` request handling on canonical `{command}` with temporary `{raw}` fallback.
- Added world-state failure latch (`is_failed`, `failure_reason`) on Command Center breach threshold.
- Updated `step_world` and terminal `WAIT` behavior to emit final failure lines and halt normal progression after breach.
- Updated terminal processor lockout so only `RESET`/`REBOOT` are accepted while failed.
- Extended world-state terminal tests to cover failure trigger, failure finality, and reboot-required behavior.
- Reconciled AI context docs to current implementation state: removed stale unwired `/command` assumptions, documented live endpoint contract/command set, and aligned cross-references in docs.
- Verified no `AGENTS_ADDENDUM.md` remains in repo scope, so no addendum carryover items remain to prune.

## 2026-02-07
- Refined `WAIT` quiet-tick fallback output to include a compact secondary threat signal alongside assault-pressure state, keeping `TIME ADVANCED.` as the primary line.
- Expanded terminal processor tests to lock quiet-tick fallback behavior for non-empty, concise, contract-compliant detail lines.
- Revalidated AI context docs against current implementation of both `/command` Flask handlers and terminal processor behavior.
- Updated contract documentation to reflect active endpoint behavior, current command set semantics, and authoritative backend dispatch model.
- Updated cross-references in docs index and world-state docs so `/command` behavior descriptions match live code paths.
- Confirmed no `AGENTS_ADDENDUM.md` exists in repository scope, so no completed addendum items remain to prune or archive.
