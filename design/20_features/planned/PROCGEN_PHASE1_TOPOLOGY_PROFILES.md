# Procgen Phase 1: Seeded Topology Profiles

## Status

- Lifecycle: `planned`
- Parent roadmap: `design/20_features/planned/PROCGEN_FORWARD_PROTOTYPE_ROADMAP.md`
- Prerequisite: `PROCGEN_PHASE0_INSTRUMENTATION.md` accepted and implemented
- Implementation start condition: explicit approval to move this doc to `in_progress`

## Purpose

Introduce deterministic, seed-driven topology profiles that change route pressure and sector access characteristics per run while preserving canonical sector identity and deterministic replay.

Phase 1 is the first gameplay-affecting procgen phase.

## Problem This Phase Solves

The simulation currently has stable strategic geometry across seeds, so operator playbooks converge quickly. Even when threats vary, traversal and chokepoint assumptions are mostly fixed.

Phase 1 adds controlled topology variability so runs diverge in:

- ingress pressure distribution
- transit interception value
- defense allocation priorities
- early command sequencing

## Scope

1. Generate a deterministic topology profile at run initialization.
2. Apply profile to transit/approach lane behavior (not sector identity).
3. Surface profile in snapshot and status-visible diagnostics.
4. Keep user-facing naming full-form (no shorthand tokens in display output).
5. Add deterministic tests for same-seed stability and cross-seed divergence.

## Out of Scope

- No new sectors added.
- No continuous/pathfinding movement system.
- No objective generation changes (Phase 5).
- No economy profile generation (Phase 3).
- No nondeterministic runtime topology mutation.

## Design Constraints

1. Canonical sectors remain intact (`COMMAND`, `COMMS`, `DEFENSE GRID`, `POWER`, `FABRICATION`, `ARCHIVE`, `STORAGE`, `HANGAR`, `GATEWAY`).
2. Topology profile is fixed for the life of a run.
3. Same seed and command stream always produce identical topology behavior.
4. Topology affects simulation rules, not just UI presentation.
5. Any internal shorthand (`T_NORTH`) must map to full user-facing names (`North Transit`).

## Data Contract Additions

## Profile Schema

Add a deterministic topology profile object in state:

```json
{
  "topology_profile": {
    "schema_version": 1,
    "profile_id": "TP_SPLIT_INGRESS_A",
    "transit_bias": {
      "North Transit": 1.2,
      "South Transit": 0.8
    },
    "ingress_bias": {
      "North Ingress": 1.15,
      "South Ingress": 0.85
    },
    "intercept_modifier": {
      "North Transit": 0.9,
      "South Transit": 1.1
    },
    "fortify_effectiveness_modifier": {
      "North Transit": 1.1,
      "South Transit": 0.95
    }
  }
}
```

## Snapshot Additions

Add top-level snapshot section:

```json
{
  "topology_profile": {
    "profile_id": "TP_SPLIT_INGRESS_A",
    "summary": "North ingress pressure elevated; South transit interception favorable."
  }
}
```

`summary` must use full names only.

## Integration Points

- `run_fingerprint.topology_profile_id` from Phase 0 must reference this profile.
- `status` and map projection can consume profile summary data without mutating state.

## Topology Profile Families

Define a bounded set of deterministic profile families:

1. `TP_BALANCED_BASELINE`
2. `TP_NORTH_PRESSURE`
3. `TP_SOUTH_PRESSURE`
4. `TP_SPLIT_INGRESS`
5. `TP_TRANSIT_CONTESTED`
6. `TP_ARCHIVE_EXPOSED`

Each family may have variants (`_A`, `_B`) but must preserve invariant ranges.

## Numeric Bounds

All profile modifiers must remain within safe deterministic bounds:

- ingress/transit bias: `0.75..1.25`
- intercept modifier: `0.85..1.15`
- fortify effectiveness modifier: `0.85..1.15`

Goal: meaningful variance without creating unwinnable extremes.

## Implementation Plan

## Slice A: Topology Profile Model

Add typed profile model and deterministic selector:

- input: `seed`
- output: immutable `topology_profile`
- selection: stable hash or seeded RNG mapping to family + variant

Target files:

- `game/simulations/world_state/core/state.py`
- `game/simulations/world_state/core/location_registry.py`

## Slice B: Simulation Rule Wiring

Apply profile modifiers where transit and approach pressure are resolved.

Target files:

- `game/simulations/world_state/core/tactical_bridge.py`
- `game/simulations/world_state/core/assaults.py`
- `game/simulations/world_state/core/grid_assault.py`

Rules:

- modify pressure/entry weighting by profile bias
- do not bypass existing deterministic fortification logic
- preserve current command semantics

## Slice C: Display Mapping and Snapshot Surface

Expose profile ID and concise summary:

- full-name labels only
- no internal token leakage

Target files:

- `game/simulations/world_state/core/display_names.py`
- `game/simulations/world_state/core/state.py`
- `game/simulations/world_state/terminal/commands/status.py`
- `custodian-terminal/sector-map.js`

## Slice D: Dev Diagnostics

Add profile component lines to Phase 0 procgen report in dev mode.

Target files:

- `game/simulations/world_state/core/state.py`
- `game/simulations/world_state/terminal/commands/status.py`

## Test Plan

## Unit Tests

1. Same seed returns same topology profile object.
2. Different seed distribution hits multiple profile families over seed suite.
3. All modifiers stay within bounded ranges.
4. Profile summary rendering uses full names only.

## Integration Tests

1. Snapshot includes `topology_profile.profile_id` and deterministic `summary`.
2. Transit-related simulation outcomes differ across selected profile families for same command script.
3. Same seed + same command script reproduces identical transit/approach outcomes.

## Regression Tests

1. Existing transit fortification tests still pass with profile-aware expectations.
2. Existing command contract tests remain unchanged.
3. Existing snapshot compatibility tests pass.

Suggested test files:

- `game/simulations/world_state/tests/test_transit_fortification.py`
- `game/simulations/world_state/tests/test_assault_trace.py`
- `game/simulations/world_state/tests/test_snapshot.py`

## Acceptance Criteria

Phase 1 is complete when all are true:

1. Every run has exactly one deterministic topology profile selected at init.
2. Topology profile materially influences route pressure/interception behavior.
3. Same-seed replay is stable and test-verified.
4. Cross-seed runs produce measurable topology divergence.
5. User-facing outputs show full names only (`North Transit`, not `T_NORTH`).
6. Existing world-state regression suite remains green.

## Risks and Mitigations

- Risk: hidden token leakage in UI/status strings.
  - Mitigation: explicit display-name mapping tests and snapshot string assertions.
- Risk: profile effects overlap too much and feel cosmetic.
  - Mitigation: baseline metric checks comparing route pressure and interception outcomes across seed suite.
- Risk: profile effects too strong and destabilizing.
  - Mitigation: bounded modifiers with simulation stability regression tests.

## Migration and Compatibility Notes

- Topology profile is additive state metadata with deterministic defaults.
- Existing saves/snapshots should load with fallback to `TP_BALANCED_BASELINE` when missing.
- If snapshot schema changes, include migration adapter and tests in same change.

## Review Checklist

- Does this phase change strategic route decisions in first 20 commands?
- Are all profile effects deterministic and bounded?
- Are full-name user-facing labels enforced?
- Does `run_fingerprint.topology_profile_id` stay stable and meaningful?
- Are tests covering both stability and divergence?
