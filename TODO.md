# Unified TODO

Generated from `feature_planning/` document audit against current implementation.

## Legend
- `OPEN`: Not implemented.
- `PARTIAL`: Implemented in part; remaining requirements listed.
- `DECISION`: Conflicting or superseded spec; needs product decision before coding.

## Unified Outstanding Backlog

1. `OPEN` Add ARRN relay network feature set.
- Add state: `relay_nodes`, `relay_packets_pending`, `knowledge_index`, `last_sync_time`.
- Add commands: `SCAN RELAYS`, `STABILIZE RELAY <ID>`, `SYNC`.
- Add authority/fidelity behavior for relay reporting.
- Add tests for command authority, locality, timed stabilization, and fidelity output.
- Source: `feature_planning/CODEX-FEATURE-RECOMMEND.md`

2. `PARTIAL` Complete assault-resource coupling follow-ons after transit interception.
- Phase B: add explicit operator material-spend command for lane prep / interception modification.
- Phase C: couple salvage payout to interception/ammo expenditure in bounded deterministic way.
- Source: `feature_planning/ASSAULT-RESOURCE-LINK.md`

3. `PARTIAL` Finish embodied-presence future compatibility items.
- Implement `DOWNED` state pathways (currently only constant/scaffold exists).
- Add downed-compatible handling for movement/repair interruption and recovery flow.
- Source: `feature_planning/ASSAULT_INSTANCES_WORLD_TRAVEL.md`

4. `PARTIAL` Finish infrastructure next-step systems not yet wired.
- Add logistics throughput cap system (`core/logistics.py`) and integrate with simulation/status.
- Add policy QoL commands: `POLICY PRESET <...>` and `POLICY SHOW`.
- Add tests for logistics penalties and preset invariants.
- Source: `feature_planning/INFRASTRUCTURE_POLICY_LAYER_NEXT_STEPS.md`

5. `PARTIAL` Complete power-performance exact mechanics that are still missing.
- Wire defense output to full per-structure operational-output equations where specified.
- Implement explicit misfire/low-output behavior where required by spec.
- Add any missing blast-door-style threshold behavior if retained in design scope.
- Ensure fabrication/repair throughput math is fully consistent with final chosen power model.
- Source: `feature_planning/POWER_SYSTEMS.md`

6. `OPEN` Implement deterministic narrative/event-description architecture.
- Add canonical event instance records and observability projection layer.
- Add fidelity-gated narrative surface model and constrained template generation.
- Separate simulation RNG from text-variation RNG for reproducible state with varied phrasing.
- Add tests for non-contradiction and fidelity redaction guarantees.
- Source: `feature_planning/PROCEDURAL_GENERATION_RESEARCH.md`

7. `DECISION` Resolve repair-spec conflicts before additional repair refactor.
- Earlier spec (`REPAIR_MECHANICS.md`) enforces local-only repairs; live code and newer planning support remote damaged repair + local escalation.
- Decide canonical model, then either close this doc as superseded or open a targeted change set.
- Source: `feature_planning/REPAIR_MECHANICS.md`


## Completed/Satisfied Planning Areas (No Current TODO)

- Dev mode/debug tooling core (`feature_planning/DEV-MODE.md`)
- Assault ledger/trace + spatial assault routing core (`feature_planning/CLARIFY_ASSAULT_MISC.md`, `feature_planning/ASSAULT_MISC_DESIGN.md`)
- STATUS/UI rework requirements (`feature_planning/UI_RECOMMENDS_INSTRUCT.md`)
- Robustness/modularity/accessibility recommendations from review docs where applicable (`feature_planning/RECOMMENDED_IMROVEMENTS.md`, `feature_planning/completed/RECOMMENDED_IMPROVEMENTS.md`)
- Completed-folder implementation documents under `feature_planning/completed/`
