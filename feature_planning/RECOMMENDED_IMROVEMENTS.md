# RECOMMENDED_IMROVEMENTS

## Scope Reviewed
This document recommends hardening changes for the features implemented from `docs/feature_planning` and now moved into `feature_planing/completed/`.

Implemented scope includes:
- Materials economy + SCAVENGE loop
- Material-aware repair progression and reporting
- FABRICATION sector scaffolding
- Stage 1.5 UI hierarchy and map/status refinements
- Embodied Presence Phase A (field mode, travel, authority split, local/remote repair split)

## Priority 1: Robustness
1. Add deterministic simulation seeds to command/session bootstrap.
- Why: reproducible bug reports and test replay.
- Change: support optional `seed` in state init and server startup; emit active seed in STATUS FULL fidelity.

2. Add command idempotency guards for transient network retries.
- Why: duplicate POSTs can issue duplicate commands in high-latency links.
- Change: optional `command_id` in `/command` payload; keep short-lived replay cache in server process.

3. Add repair/task invariant validator in one central function.
- Why: field state, active task, and active repair interactions are now interdependent.
- Change: on each tick/command, assert:
  - at most one active task
  - at most one active repair in Phase A
  - `field_action` reflects task/repair reality
  - command mode implies location `COMMAND`

4. Add save/load schema versioning.
- Why: new fields (`player_mode`, `field_action`, `active_task`) will evolve.
- Change: introduce `snapshot_version`; add migration function from previous snapshots.

5. Strengthen endpoint parity.
- Why: UI server and simulation server diverged historically on `/command` payload shape.
- Change: enforce shared serializer + parser module consumed by both servers.

## Priority 2: Modularity
1. Extract command authority policy into a dedicated module.
- Current risk: command gating logic is split across processor and handlers.
- Change: `terminal/authority.py` with policy table by `player_mode`.

2. Extract presence system into `core/presence.py`.
- Current risk: wait tick helper owns movement progression implicitly.
- Change: expose `tick_presence(state)` and `start_move_task(...)` to remove hidden coupling.

3. Introduce typed task dataclasses.
- Current risk: loose dict tasks are easy to drift.
- Change: `MoveTask`, `RepairTask` dataclasses with explicit fields.

4. Consolidate location normalization and travel graph semantics.
- Current risk: aliases and canonical names can diverge from sector IDs.
- Change: central location registry object that maps id/name/alias/display label.

5. Move terminal message strings into a message catalog.
- Why: easier consistency, easier future localization, easier contract testing.

## Priority 3: Accessibility
1. Add reduced-motion mode for map and terminal effects.
- Change: CSS media query `prefers-reduced-motion`; disable border flashes/flicker.

2. Improve screen reader output for terminal updates.
- Change: add ARIA live region with concise summary line per command while preserving visual feed.

3. Increase contrast variance for warning/assault lines.
- Change: keep palette style but move warning/assault classes to WCAG-friendly contrast thresholds.

4. Add keyboard focus visibility and command history navigation.
- Change: visible input focus ring and `ArrowUp/ArrowDown` history buffer in terminal input.

5. Add explicit offline/network-failed banner state.
- Change: non-modal, high-contrast status strip when `/command` fetch fails repeatedly.

## Priority 4: Engagement
1. Add consequence-rich but non-prescriptive post-action telemetry.
- Change: after WAIT/SCAVENGE/REPAIR, append one factual delta line (damage delta, repaired structures, threat drift bucket).
- Constraint: no strategy hint text.

2. Expand transit identity with localized signal flavor.
- Change: transit nodes report ambient condition tags (`NOISE`, `THERMAL`, `POWER HUM`) tied to COMMS fidelity.

3. Add soft operational milestones.
- Change: non-intrusive milestones such as `FIRST FIELD REPAIR COMPLETE`, `FIRST ASSAULT AWAY FROM COMMAND` in logs.

4. Add persistent operator logbook feed.
- Change: append important events into a compact timeline panel derived from command results and snapshots.

5. Strengthen sector role readability.
- Change: keep map read-only but add subtle static role glyphs (ASCII-safe initials) without interactive hints.

## Testing Expansion Recommendations
1. Add dedicated presence-flow tests:
- deploy while assault active
- move invalid route from transit
- return while action in progress
- local repair only in local sector
- remote repair denied for offline/destroyed

2. Add snapshot contract tests for field mode branches.
- Verify STATUS in field mode never includes global threat/timers.

3. Add browser integration test for snapshot refresh triggers.
- Ensure DEPLOY/MOVE/RETURN/REPAIR/SCAVENGE all refresh right panel and map.

4. Add endpoint contract tests for both servers.
- Enforce `{ok, text, lines}` and support for `command` + `raw` fallback.

5. Add property-based tests for travel graph validity.
- Symmetric edges where expected
- no unreachable canonical nodes
- no invalid alias resolution

## Architecture Drift Risks To Watch
- Dual meaning of `COMMAND` (mode + location string) can cause subtle bugs.
- Mixed sector IDs and sector names across UI/backend can create invalid route checks.
- Future downed-state work will break if `field_action` becomes optional or inconsistent.
- Additional async tasks (future fabrication queues) can conflict with single-task assumptions.

## Suggested Next Refactor Sequence
1. Presence/task extraction (`core/presence.py`) and authority policy extraction.
2. Snapshot/version migration layer.
3. Accessibility pass (reduced motion + ARIA + focus/history).
4. Integration tests across terminal UI refresh behavior.
5. Message catalog and contract locking.
