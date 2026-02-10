# DEVLOG — CUSTODIAN

## 2026-02-10
- Added structure damage scaffolding with timed repairs, plus the `REPAIR` command and repair progression tests.
- Shifted assault outcomes to degrade structures at resolution and tightened status report degradation to match COMMS fidelity rules.
- Cleaned and aligned `docs/SystemDesign.md` and AI context docs with the current structure/repair implementation.
- Reworked WAIT/WAIT 10X output to follow the revised information degradation spec with fidelity-gated event and summary lines.
- Consolidated STATUS/WAIT information degradation rules into `docs/INFORMATION_DEGRADATION.md`.
- Added Phase 1 materials economy: materials in state/snapshot, STATUS resources block, SCAVENGE command, and repair material gating.

## 2026-02-09 # {NOTE FOR CODEX}
- CODEX OVER HERE! READ THIS!
- Hi it's Brayden. I want you to put move the contents of docs/INFORMATION_FIDELITY.md to somewhere persistent so that the style of (in-game) information degradation is a persistent design theme. Also thanks for all your hard work. Brayden out.

## 2026-02-09
- Implemented hub/campaign schemas with offer generation, recon refinement, hub mutation rules, and snapshot/load seams.

## 2026-02-07
- Implemented HARDEN posture and updated FOCUS to bias assault target selection only.
- Added ARCHIVE loss counter/threshold and STATUS posture/loss reporting.
- Added system panel + terminal feed formatting and comms-based UI degradation.

## 2026-02-08
- Reconciled campaign contract language: contracts are interface commitments, scenarios are hub-surfaced proposals, rewards are hub mutations justified by context.
- Current focus: finalize the Hub ↔ Campaign scaffolding by defining campaign offer generation, recon-based information refinement, and a strict outcome-to-hub mutation contract before expanding gameplay systems.
- Added `WAIT 10X` support to advance ten ticks with summarized output.
- Removed obsolete `NEXT_FEATURES.md` now that Phase 1 plan is realized.
- Added `GameState.snapshot()` and `/snapshot` endpoints for read-only UI projection.
- Implemented sector map UI that updates only after state-changing commands.
- Added `RESET`/`REBOOT` handling in the terminal processor and slowed/enhanced boot audio cadence.
- Updated Phase 1 sector layout to the canonical 8-sector set with IDs and map positioning.
- Removed `docs/PHASE_I_FINALIZATION.md` after implementing its Phase 1 requirements.
- Implemented Phase 1.5 asymmetry and `FOCUS` command, plus associated map layout updates.
- Removed `docs/PHASE_1.5_BUILD.md` after implementing Phase 1.5 requirements.

## 2026-02-05
- Added terminal webserver `custodian-terminal/server.py` with SSE boot stream.
- Renamed `simulate_*` entrypoints to `sandbox_*` and updated references.
- Hardened `game/run.py` to add repo root to `sys.path` for any CWD.
- Added world-state terminal command stack (parser, processor, command registry, REPL) with read/write authority gating.
- Added `step_world` helper and pytest coverage for world-state stepping and terminal commands.
- Added git hooks for docs/secret hygiene: `pre-commit` (block forbidden files, warn on untracked logs), `commit-msg` (docs check with [no-docs] override), `post-commit` (DEVLOG nudge).
- Archived the Phase 1 terminal design lock from the former `NEXT_FEATURES.md` into `docs/_ai_context/ARCHITECTURE.md` with divergence notes.
- Updated terminal boot flow: `boot.js` appends a system log and unlocks command mode; terminal input submits to `/command` and renders lines or failure messages.
- Implemented `/command` in `custodian-terminal/server.py` using a persistent `GameState` and the terminal command processor.
- Added unified entrypoint `python -m game` with `--ui`/`--sim`/`--repl` modes and updated README entrypoints.
- Fixed `custodian-terminal/server.py` to add the repo root to `sys.path` so `python -m game --ui` can import `game`.
- Renamed boot and server files to canonical `boot.js` and `server.py`.
- Aligned `/command` contract to `{raw}` request and `{ok, lines}` response across UI and servers.
- Removed reset/reboot command mutations to keep state changes inside `step_world`.
- Implemented Phase 2 assault outcomes (clean defense, damage, breach, strategic loss, command center breach) with outcome messaging.
- Tightened terminal cursor cadence and suppressed cursor during active typing.
- Added power-cycle boot audio hook (power_cycle.mp3) and wired it into boot start.
- Expanded terminal boot audio base (hum + relay + beep + alert) with policy-safe unlock and one-shot helpers.

## 2026-02-06
- Updated terminal boot flow integration so UI command submit/render path uses backend `CommandResult` payloads (`ok`, `text`, optional `lines`/`warnings`).
- Standardized world-state `/command` request handling on canonical `{command}` with temporary `{raw}` fallback.
- Added world-state failure latch (`is_failed`, `failure_reason`) on COMMAND breach threshold.
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
