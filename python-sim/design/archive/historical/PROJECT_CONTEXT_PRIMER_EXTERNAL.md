# PROJECT CONTEXT PRIMER (EXTERNAL REVIEWER) — CUSTODIAN

Last updated: 2026-02-23

## What This Project Is

CUSTODIAN is a deterministic, terminal-first defense simulation set in a collapsed interstellar civilization.
The player defends and reconstructs a static command post under resource and information pressure.
The design theme is reconstruction and knowledge preservation, not extermination.

## Runtime Model (Critical)

- Backend-authoritative simulation state (`GameState`).
- Frontend is transport/projection only (no gameplay authority).
- Time advances only on explicit time-bearing commands.
- Deterministic seed support is active for reproducible runs.

## Contracts

- `POST /command` request:
  - Canonical: `{ "command": "<string>" }`
  - Compatibility: `{ "raw": "<string>" }`
  - Optional: `command_id` (idempotency), `seed` (first-tick only)
- Response shape:
  - `{ "ok": bool, "text": str, "lines": list[str] }`
- `GET /snapshot`:
  - Read-only projection, schema version `2`

## Current Feature State (Summary)

Implemented:
- Command/field presence split (`DEPLOY`, `MOVE`, `RETURN`) and authority gating.
- Spatial assaults with ingress routing, transit interception, and multi-tick tactical resolution.
- Infrastructure policy layer (`SET`, `SET FAB`, `FORTIFY`, `POLICY SHOW`, `POLICY PRESET`).
- Fabrication recipe queue and stock outputs (`FAB ADD/QUEUE/CANCEL/PRIORITY`).
- Power-performance coupling and fidelity-gated operator visibility (`FULL` -> `LOST`).
- Assault introspection (ledger + dev trace/report commands).
- ARRN relay slice (`SCAN RELAYS`, `STABILIZE RELAY`, `SYNC`) with first knowledge benefit.
- Logistics throughput caps and deterministic slowdown under overload.

Still in progress / partial:
- Deeper ARRN progression (additional unlock ladder, longer campaign coupling).
- Assault-Resource-Link Phase B/C (explicit operator spend + salvage coupling).
- Procedural narrative variation layer (currently fidelity-gated templates, not full variation system).
- Full downed-state activation and associated field-risk mechanics.
- Balance/pacing pass for longer campaign stability.

## Risk / Drift Notes

- Some legacy planning docs are aspirational or stale relative to implementation.
- `docs/_ai_context/*` is the canonical source for current behavior.

## Recommended Immediate Focus

1. Finish mechanics gap:
- Assault-Resource-Link Phase B/C
- Expanded ARRN unlock ladder

2. Improve operational readability:
- Deterministic narrative variation without leaking hidden state
- Better factual delta lines under pressure

3. Harden long-run stability:
- Deterministic multi-seed integration tests
- Pacing and economy tuning

## Validation Baseline

Primary command:

`./.venv/bin/pytest -q game/simulations/world_state/tests`

Known result at update time:

- `102 passed` (2026-02-23)

