# EFFECTIVE IMPROVEMENTS IMPLEMENTATION PLAN

This document lists high-impact, implementation-ready improvements for the current CUSTODIAN codebase.
Order is intentional and should be followed in sequence:
code efficiency -> gameplay -> mechanics -> systems -> engine -> development planning.

## 1. Code Efficiency Improvements

1. Reduce repeated sector/structure scans in command handlers.
- Change: add cached lookup helpers for common sector and structure queries used by `STATUS`, `WAIT`, and assault summary generation.
- Files: `game/simulations/world_state/terminal/commands/status.py`, `game/simulations/world_state/terminal/commands/wait.py`, `game/simulations/world_state/core/assaults.py`.
- Acceptance: no behavior changes, lower per-command allocations, all tests remain green.

2. Remove duplicate fidelity recomputation in single command flows.
- Change: compute fidelity once per command execution path and pass it through formatter helpers.
- Files: `game/simulations/world_state/terminal/commands/status.py`, `game/simulations/world_state/terminal/commands/wait.py`, `game/simulations/world_state/core/power.py`.
- Acceptance: output text remains identical for same seed and command sequence.

3. Normalize command parsing branches to reduce processor branching cost and maintenance risk.
- Change: convert major subcommand trees to compact dispatch maps where possible (`FAB`, `POLICY`, `DEBUG`).
- Files: `game/simulations/world_state/terminal/processor.py`.
- Acceptance: command contract unchanged; unknown/error messages unchanged.

4. Limit terminal-side DOM churn for high-frequency updates in map mode.
- Change: batch append operations and minimize full re-render calls on no-op updates.
- Files: `custodian-terminal/terminal.js`, `custodian-terminal/sector-map.js`.
- Acceptance: map mode keeps 2s cadence and feels more responsive on long sessions.

## 2. Gameplay Improvements

1. Add clearer mid-pressure decision visibility without strategy hints.
- Change: after major `WAIT` windows, surface one factual operational delta line: threat trend, top damaged sector, or logistics pressure.
- Files: `game/simulations/world_state/terminal/commands/wait.py`, `game/simulations/world_state/terminal/commands/status.py`.
- Acceptance: concise output, no prescriptive language, fidelity rules preserved.

2. Improve early-game pacing for field deployment.
- Change: reduce dead time by tuning initial assault spawn probability and ambient threat ramp for first 30-50 ticks.
- Files: `game/simulations/world_state/core/assaults.py`, `game/simulations/world_state/core/state.py`, `game/simulations/world_state/core/config.py`.
- Acceptance: first meaningful decision appears earlier without increasing unavoidable losses.

3. Strengthen recovery rhythm after successful defense.
- Change: tune maintenance recovery and recovery windows so successful defense creates visible stabilization momentum.
- Files: `game/simulations/world_state/core/state.py`, `game/simulations/world_state/core/repairs.py`.
- Acceptance: successful actions create measurable but bounded relief.

## 3. Mechanics Improvements

1. Complete Assault-Resource-Link Phase B.
- Change: add explicit material spend command for transit lane preparation and wire to interception strength.
- Files: `game/simulations/world_state/terminal/processor.py`, `game/simulations/world_state/terminal/commands/policy.py` or new command module, `game/simulations/world_state/core/assaults.py`.
- Acceptance: command is deterministic, bounded, and reflected in assault outcomes.

2. Complete Assault-Resource-Link Phase C.
- Change: couple salvage payout to interception spend/effectiveness with strict caps.
- Files: `game/simulations/world_state/core/assaults.py`.
- Acceptance: no runaway resource loop; deterministic across identical seeds.

3. Expand ARRN relay reward ladder beyond first unlock.
- Change: add additional bounded knowledge benefits tied to `RELAY_RECOVERY` levels.
- Files: `game/simulations/world_state/core/relays.py`, `game/simulations/world_state/core/repairs.py`, `game/simulations/world_state/terminal/commands/status.py`.
- Acceptance: each unlock has clear mechanical effect and no combat-system rewrite required.

4. Add downed-state seam activation (minimal Phase 0).
- Change: introduce non-lethal downed transition contract and command lock behavior without full combat avatar system.
- Files: `game/simulations/world_state/core/config.py`, `game/simulations/world_state/core/state.py`, `game/simulations/world_state/core/invariants.py`, `game/simulations/world_state/terminal/processor.py`.
- Acceptance: state remains coherent under forced downed test conditions.

## 4. Systems Improvements

1. Add bounded narrative variation layer for event text.
- Change: template families per signal channel with deterministic text seed; keep simulation truth separate from text rendering.
- Files: `game/simulations/world_state/terminal/commands/wait.py`, new module `game/simulations/world_state/terminal/messages.py` expansion or new narrative module.
- Acceptance: variation increases, no contradictory facts, fidelity redaction unchanged.

2. Improve snapshot/UI parity for high-signal state.
- Change: expose structured inbound approach summary, tactical effect durations, and compact relay progression fields in snapshot.
- Files: `game/simulations/world_state/core/state.py`, `custodian-terminal/sector-map.js`.
- Acceptance: UI remains read-only and reflects backend state without local inference.

3. Strengthen failure and recovery observability.
- Change: add compact standardized reason codes in state and status output (operator-safe).
- Files: `game/simulations/world_state/core/state.py`, `game/simulations/world_state/terminal/commands/status.py`.
- Acceptance: clearer failure/recovery diagnostics without leaking internal formulas.

## 5. Engine Improvements

1. Isolate deterministic RNG streams by domain.
- Change: separate simulation RNG from text-variation RNG and optional UI cosmetic randomness.
- Files: `game/simulations/world_state/core/state.py`, `game/simulations/world_state/terminal/commands/wait.py`.
- Acceptance: simulation outcomes remain identical regardless of text variation settings.

2. Add lightweight performance instrumentation in dev mode.
- Change: record per-tick timings for event, assault, repair, fabrication, and render formatting phases.
- Files: `game/simulations/world_state/core/simulation.py`, `game/simulations/world_state/terminal/processor.py`.
- Acceptance: instrumentation available only in dev mode, no gameplay mutation.

3. Harden command and snapshot contracts with schema checks.
- Change: add strict test assertions for response and snapshot field types and required keys.
- Files: `game/simulations/world_state/tests/test_server_command_endpoint.py`, `game/simulations/world_state/tests/test_snapshot.py`, `game/simulations/world_state/tests/test_terminal_contracts.py`.
- Acceptance: contract regressions fail fast in tests.

## 6. Development Planning Improvements

1. Execute implementation in fixed slices with lockstep validation.
- Slice order:
`efficiency -> gameplay pacing -> mechanics phase B/C -> systems narrative -> engine hardening`.
- Validation gate for each slice:
`./.venv/bin/pytest -q game/simulations/world_state/tests`.
- Acceptance: no slice merges without green tests and doc updates.

2. Keep canonical status docs synchronized each implementation session.
- Change: update `docs/_ai_context/CURRENT_STATE.md`, `docs/_ai_context/ROADMAP.md`, and append dated entry in `docs/_ai_context/DEVLOG.md` when behavior changes.
- Acceptance: planning docs do not drift from implementation.

3. Define release checkpoints.
- Checkpoint A: mechanics completion (Assault-Resource-Link B/C + ARRN reward ladder).
- Checkpoint B: systems polish (narrative variation + snapshot parity).
- Checkpoint C: engine hardening (RNG isolation + instrumentation + contract tests).
- Acceptance: each checkpoint has deterministic replay verification using fixed seeds.

4. Add a standing balancing pass protocol.
- Change: maintain a small seed set for repeatable long-run evaluations and capture outcome metrics per seed.
- Files: `game/simulations/world_state/tests/` (new integration seed tests).
- Acceptance: balancing changes are compared against baseline metrics before merge.

