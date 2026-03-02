# Unified TODO

Generated from design and archived planning document audit against current implementation.

## Legend
- `OPEN`: Not implemented.
- `PARTIAL`: Implemented in part; remaining requirements listed.
- `DECISION`: Conflicting or superseded spec; needs product decision before coding.

## Unified Outstanding Backlog

## Recommended Next Focus

1. `NEXT` Complete mechanics follow-ons before new feature surface area.
- Expand ARRN progression depth (`design/20_features/planned/ARRN_FEATURE_RECOMMENDATIONS.md`):
  - add relay reward ladder beyond initial remote-repair discount
  - add relay decay/dormancy pressure loop
- Why this is next: Assault-resource coupling is complete and ARRN remains the primary open progression loop.

1. `OPEN` Intra-sector tactical depth expansion.
- Current 12x12 grid insufficient for meaningful defensive geometry.
- Expand to configurable per-sector grids (target 30-40x per sector).
- Add player-authored wall placement beyond auto-perimeter.
- Source: `design/00_foundations/GAME_IDENTITY_LOCK.md` (design review 2026-02)

1. `OPEN` ARRN Expansion: Reward Ladder + Decay Loop.
- New spec in `design/20_features/planned/ARRN_FEATURE_RECOMMENDATIONS.md`
- Implement reward ladder (tier table: knowledge_index 1-7)
- Implement decay loop (0.5 stability/tick + assault pressure modifier)
- Implement dormancy pressure (affects assault freq, fidelity, knowledge drift)
- Files to modify:
  - core/relays.py (stability, decay, dormancy)
  - core/state.py (dormancy_pressure field)
  - core/assaults.py (assault_interval modifier)
  - corefidelity suppression)
/fidelity.py (  - terminal/commands/status.py (STATUS KNOWLEDGE)

2. `COMPLETE` Assault-resource coupling follow-ons.
- Implemented:
  - transit fortification lane prep and interception coupling
  - deterministic bounded Phase C salvage coupling
  - after-action salvage breakdown surfacing
- Source: `design/10_systems/assault/ASSAULT_DESIGN.md`

3. `PARTIAL` Finish embodied-presence future compatibility items.
- Implement `DOWNED` state pathways (currently only constant/scaffold exists).
- Add downed-compatible handling for movement/repair interruption and recovery flow.
- Source: `design/20_features/planned/ASSAULT_INSTANCES_WORLD_TRAVEL.md`

4. `PARTIAL` Finish infrastructure next-step systems not yet wired.
- Implemented: logistics throughput cap model (`core/logistics.py`) integrated with simulation/status, policy QoL commands, and initial logistics penalty tests.
- Remaining: balance/tuning pass for logistics pressure curve and additional long-run edge-case tests.
- Source: `design/20_features/planned/INFRASTRUCTURE_POLICY_LAYER_NEXT_STEPS.md`

5. `PARTIAL` Complete power-performance exact mechanics that are still missing.
- Wire defense output to full per-structure operational-output equations where specified.
- Implement explicit misfire/low-output behavior where required by spec.
- Add any missing blast-door-style threshold behavior if retained in design scope.
- Ensure fabrication/repair throughput math is fully consistent with final chosen power model.
- Source: `design/10_systems/infrastructure/POWER_SYSTEMS.md`

6. `PARTIAL` Expand deterministic procedural narrative/event-description architecture.
- Implemented:
  - canonical event instance records (`tick_events`) and mechanics-to-text signal projection
  - deterministic seeded grammar/variant engine (`game/procgen/`)
  - fidelity-gated procedural `WAIT` messaging via world-state grammar bank
  - semantic signal-key suppression to prevent repeated message spam under variant phrasing
- Remaining:
  - extend procedural messaging beyond current `WAIT` surface where appropriate
  - add stronger deterministic integration tests for long `WAIT` sequences and fidelity redaction guarantees
  - decide whether to fully isolate simulation RNG and text RNG streams at config/interface level
- Source: `design/10_systems/procgen/PROCEDURAL_GENERATION_RESEARCH.md`

7. `DECISION` Resolve repair-spec conflicts before additional repair refactor.
- Earlier spec (`REPAIR_MECHANICS.md`) enforces local-only repairs; live code and newer planning support remote damaged repair + local escalation.
- Decide canonical model, then either close this doc as superseded or open a targeted change set.
- Source: `design/10_systems/infrastructure/REPAIR_MECHANICS.md`


## Completed/Satisfied Planning Areas (No Current TODO)

- Dev mode/debug tooling core (`design/20_features/in_progress/DEV_MODE.md`)
- Assault ledger/trace + spatial assault routing core (`design/20_features/in_progress/ASSAULT_MISC_CLARIFICATIONS.md`, `design/20_features/in_progress/ASSAULT_MISC_DESIGN.md`)
- STATUS/UI rework requirements (archived in `design/archive/deprecated/UI_RECOMMENDS_INSTRUCT.md`)
- Robustness/modularity/accessibility recommendations from review docs where applicable (`design/archive/deprecated/RECOMMENDED_IMPROVEMENTS_LEGACY.md`, `design/20_features/completed/RECOMMENDED_IMPROVEMENTS.md`)
- Completed-folder implementation documents under `design/20_features/completed/`
