# PROJECT CONTEXT PRIMER — CUSTODIAN

Last updated: 2026-02-23

## Purpose

This is the single consolidated handoff document for AI sessions.
Use it to understand current implementation state, constraints, active gaps, and high-value next steps.

If this primer conflicts with legacy planning docs, trust `docs/_ai_context/*` and current code.

## One-Paragraph Project Summary

CUSTODIAN is a deterministic, terminal-first defense simulation where the player preserves a failing command post under pressure.
Gameplay centers on command-vs-field authority, infrastructure survival, degraded information fidelity, and reconstruction loops (repair, fabrication, relay recovery), with backend-authoritative world simulation and UI as read-only projection.

## Canonical Runtime Facts

- Backend authority: all game mutations happen server-side in `GameState`.
- Time progression: only explicit time-bearing commands advance state (`WAIT`, `WAIT NX`, `WAIT UNTIL ...`).
- Determinism: seeded RNG (`GameState(seed=...)`) is active across world simulation behavior.
- Command transport contract:
  - Request: `POST /command` with `{ "command": "<string>" }` (`raw` fallback supported).
  - Response: `{ "ok": bool, "text": str, "lines": list[str] }`.
  - Optional idempotency: `command_id`.
- Snapshot contract: `GET /snapshot`, schema version `2`.

## Current Architecture

1. Command layer:
- Parser/processor and command handlers in `game/simulations/world_state/terminal/`.
- Authority policy split by player mode (`COMMAND` vs `FIELD`).

2. World-state layer:
- Tick orchestration: `game/simulations/world_state/core/simulation.py::step_world`.
- Major subsystems: assaults, events, repairs, power/fidelity, fabrication, policies, logistics, relays, presence.

3. UI layer:
- Browser terminal and map monitor in `custodian-terminal/`.
- Boot lock/unlock, command POST transport, snapshot-driven side panels/map.

## Implemented Systems (High Confidence)

- Presence and authority:
  - `DEPLOY`, `MOVE`, `RETURN`, field command gating, transit travel graph, local/remote repair constraints.
- Assault pipeline:
  - Spatial approaches, transit interception, multi-tick tactical resolution, after-action summaries.
- Policy/infrastructure layer:
  - `SET`, `SET FAB`, `FORTIFY`, `POLICY SHOW`, `POLICY PRESET`.
  - Power load, wear, logistics throughput multipliers.
- Fabrication:
  - Recipe queue, stock outputs, queue controls (`FAB ADD/QUEUE/CANCEL/PRIORITY`), throughput coupling.
- Power-performance + fidelity:
  - Effective output and COMMS-driven fidelity gates for status/wait visibility.
- Assault introspection/dev tooling:
  - Assault ledger + trace/report controls in dev mode.
- ARRN relay slice:
  - `SCAN RELAYS`, `STABILIZE RELAY`, `SYNC`, knowledge index progression, first relay benefit.
- Reliability hardening:
  - Idempotency cache, snapshot migration/versioning, centralized invariants.
- Terminal UI QoL:
  - map monitor mode (auto-WAIT cadence), command history, completion, offline banner, reduced-motion handling.

## Current Command Surface (Operator-Relevant)

- Core: `STATUS`, `STATUS FULL`, `STATUS <FAB|POSTURE|ASSAULT|POLICY|SYSTEMS|RELAY>`, `WAIT`, `WAIT NX`, `WAIT UNTIL <ASSAULT|APPROACH|REPAIR_DONE>`.
- Movement: `DEPLOY`, `MOVE`, `RETURN`.
- Repair/recovery: `REPAIR`, `REPAIR <ID> FULL`, `SCAVENGE`, `SCAVENGE NX`.
- Policy/defense: `SET`, `SET FAB`, `FORTIFY`, `CONFIG DOCTRINE`, `ALLOCATE DEFENSE`, `POLICY SHOW`, `POLICY PRESET`.
- Fabrication: `FAB ADD`, `FAB QUEUE`, `FAB CANCEL`, `FAB PRIORITY`.
- Assault ops: `REROUTE POWER`, `BOOST DEFENSE`, `DRONE DEPLOY`, `DEPLOY DRONE`, `LOCKDOWN`, `PRIORITIZE REPAIR`.
- Relay/knowledge: `SCAN RELAYS`, `STABILIZE RELAY <ID>`, `SYNC`.
- Help/recovery: `HELP`, `HELP <TOPIC>`, `RESET`, `REBOOT`.

## Known High-Value Gaps

1. Procedural narrative variation system is not fully implemented.
- Current messaging is fidelity-gated templates, not a separate deterministic narrative variation layer.

2. ARRN progression is early-stage.
- Relay commands and first benefit exist; deeper knowledge unlock ladder and decay/maintenance loops remain.

3. Assault-Resource-Link follow-on phases remain.
- Transit interception Phase A exists.
- Phase B explicit spend loop and Phase C salvage coupling are still partial/missing.

4. Downed-state architecture remains future-facing.
- Presence model has seams, but operational downed state is not fully active.

5. Balance/pacing is still an active task.
- Long-run stability and pacing need targeted tuning across threats, assaults, recovery, and economy pressure.

## Focus Areas for Next-Step Recommendations

Recommend in this order unless user asks otherwise:

1. Mechanics completion:
- Finish Assault-Resource-Link B/C.
- Expand ARRN reward ladder with bounded, deterministic effects.

2. Systems clarity:
- Add deterministic narrative variation layer without violating fidelity constraints.
- Improve operator-visible factual delta lines for high-pressure ticks.

3. Balance and test depth:
- Add long-run deterministic seed scenarios.
- Tune early-game pressure and post-defense recovery cadence.

4. Engine hardening:
- Separate RNG streams by domain (simulation vs description variation).
- Add dev-mode timing instrumentation and stricter contract schema tests.

## Guardrails for Any New Work

- Preserve backend-authoritative mutation model.
- Keep terminal outputs concise, operational, and fidelity-gated.
- Maintain deterministic replay behavior for identical seeds and command sequences.
- Keep UI read-only relative to simulation authority.
- Keep command contract stable unless explicitly versioned.

## Session Start Checklist (For ChatGPT)

1. Read `docs/_ai_context/CURRENT_STATE.md`.
2. Read this primer.
3. Verify requested feature against current code, not older planning drafts.
4. Prefer incremental slices with tests after each slice.
5. Update `docs/_ai_context/DEVLOG.md` and relevant context docs when behavior changes.

## Validation Baseline

Primary baseline command:

`./.venv/bin/pytest -q game/simulations/world_state/tests`

Current known result at primer update time:

- `102 passed` (2026-02-23).

