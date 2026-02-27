# Procgen Phase 0: Instrumentation Baseline

## Status

- Lifecycle: `planned`
- Parent roadmap: `design/20_features/planned/PROCGEN_FORWARD_PROTOTYPE_ROADMAP.md`
- Implementation start condition: explicit approval to move this doc to `in_progress`

## Purpose

Establish a deterministic instrumentation layer that makes procedural variance measurable before deeper gameplay procgen changes land.

Phase 0 does not change world mechanics. It adds observability and measurement primitives only.

## Problem This Phase Solves

Current perception of "runs feel the same" is valid, but there is no canonical numeric baseline to prove:

- how similar runs are across seeds
- which systems are contributing variance
- whether future procgen phases improve strategic divergence

Without these metrics, later changes risk increasing noise instead of meaningful run diversity.

## Scope

1. Add deterministic run fingerprint fields to snapshot output.
2. Add dev-mode procgen report surface for quick operator inspection.
3. Add repeatable variability-analysis harness for seed suites.
4. Add tests proving same-seed stability and cross-seed differentiation in instrumentation output.

## Out of Scope

- No new topology generation logic.
- No threat-behavior logic changes.
- No objective generation changes.
- No player-facing command contract changes.
- No nondeterministic analytics tooling.

## Design Constraints

1. Deterministic replay must remain unchanged.
2. Snapshot compatibility must be preserved.
3. Instrumentation must be additive and read-only.
4. Runtime overhead must remain low in normal mode.
5. Dev reporting must be available only in dev mode.

## Affected Code Areas

- `game/simulations/world_state/core/state.py`
- `game/simulations/world_state/core/simulation.py`
- `game/simulations/world_state/core/factions.py`
- `game/simulations/world_state/core/events.py`
- `game/simulations/world_state/server.py`
- `custodian-terminal/server.py`
- `game/simulations/world_state/tests/test_snapshot.py`
- `game/simulations/world_state/tests/test_procgen_engine.py`
- `tests/test_simulation_step_world.py`

## Data Contract Additions

## Snapshot Additions

Add a top-level `run_fingerprint` object to `GameState.snapshot()`:

```json
{
  "run_fingerprint": {
    "schema_version": 1,
    "seed": 12345,
    "text_seed": 12345,
    "topology_profile_id": "BASELINE_STATIC",
    "doctrine_profile_id": "DCT_COUNTER_SIEGE_A",
    "economy_profile_id": "ECON_BALANCED_A",
    "event_catalog_hash": "d4bc3f0e1a5c92bf",
    "faction_profile_hash": "129ab1f48f5b0bc1",
    "fingerprint_hash": "f238cb4a6e1f6b20"
  }
}
```

### Field Rules

- `schema_version`: integer version for forward compatibility.
- `seed`: canonical simulation seed.
- `text_seed`: canonical text variant seed.
- `*_profile_id`: deterministic IDs for currently active generated profiles.
- `*_hash`: deterministic, stable, short hex strings (64-bit hash represented as 16 hex chars).
- `fingerprint_hash`: stable aggregate hash over all fingerprint components.

## Report Contract (Dev Mode)

Add dev-only procgen report payload (for debug command and/or debug snapshot projection):

```json
{
  "procgen_report": {
    "seed": 12345,
    "fingerprint_hash": "f238cb4a6e1f6b20",
    "components": [
      {"name": "topology_profile_id", "value": "BASELINE_STATIC"},
      {"name": "doctrine_profile_id", "value": "DCT_COUNTER_SIEGE_A"},
      {"name": "economy_profile_id", "value": "ECON_BALANCED_A"},
      {"name": "event_catalog_hash", "value": "d4bc3f0e1a5c92bf"},
      {"name": "faction_profile_hash", "value": "129ab1f48f5b0bc1"}
    ]
  }
}
```

## Implementation Plan

## Slice A: Fingerprint Builder

Implement a pure helper in `state.py` (or a narrow helper module) that builds a deterministic fingerprint object from current state.

Requirements:

- Use stable hash utility (`stable_hash64` or equivalent deterministic hash).
- Never include mutable per-tick values (`time`, `resources`, `damage`) in the stable profile fingerprint.
- Include only run-identity features.

## Slice B: Snapshot Wiring

Attach `run_fingerprint` to the snapshot payload with no mutation side effects.

Requirements:

- Existing snapshot keys remain unchanged.
- New key is additive.
- Backward readers that ignore unknown keys remain unaffected.

## Slice C: Dev Report Surface

Expose the procgen report in dev mode through existing debug pathways.

Requirements:

- No output in non-dev mode.
- Report format stable and machine-readable.
- Keep human-readable terminal formatting concise and operational.

## Slice D: Variability Harness

Add a script or test helper that runs a seed suite and emits baseline metrics:

- unique fingerprint count
- profile-ID distribution
- pairwise similarity on fingerprint components

The harness must be deterministic and runnable under pytest or a deterministic utility path.

## Variability Baseline Metrics

Phase 0 records baseline only. It does not enforce high diversity yet.

## Metric Definitions

1. `fingerprint_uniqueness_ratio`: unique fingerprints / total seeds.
2. `profile_switch_rate`: fraction of adjacent seeds where at least one profile ID differs.
3. `component_entropy`: per-component distribution entropy over seed suite.
4. `same_seed_stability`: repeated run of same seed yields identical fingerprint 100% of the time.

## Seed Suite

- Canonical baseline suite: seeds `1000..1099` (100 seeds).
- Stability suite: repeat seed `424242` for 20 runs.

## Test Plan

## Unit Tests

1. Fingerprint helper returns required keys and deterministic hash lengths.
2. Fingerprint aggregate hash changes when a profile ID changes.
3. Fingerprint aggregate hash does not change when mutable runtime counters change.

## Integration Tests

1. Snapshot includes `run_fingerprint` and preserves existing keys.
2. Same seed + same command sequence => identical `run_fingerprint`.
3. Different seeds produce at least one differing fingerprint component over baseline suite.

## Regression Tests

1. Existing snapshot and terminal contract tests remain passing.
2. Dev mode report is gated and absent in normal mode.

## Acceptance Criteria

Phase 0 is complete when all are true:

1. `run_fingerprint` exists in snapshot with `schema_version=1`.
2. Fingerprint is stable under same-seed replay.
3. Dev mode procgen report is available and deterministic.
4. Baseline variability metrics can be produced from a fixed seed suite.
5. No gameplay behavior changes are introduced.
6. Existing world-state tests pass.

## Risks and Mitigations

- Risk: fingerprint accidentally includes mutable fields and becomes unstable.
  - Mitigation: explicit allowlist of fingerprint components + dedicated unit tests.
- Risk: instrumentation payload drift breaks downstream readers.
  - Mitigation: schema versioning and additive-only snapshot updates.
- Risk: dev report leaks into operator-facing non-dev output.
  - Mitigation: strict dev-mode gate tests.

## Migration and Compatibility Notes

- Snapshot format change is additive.
- No state migration required for save compatibility beyond optional snapshot schema annotation.
- If snapshot version increments, include migration adapter and test coverage in the same change.

## Review Checklist

- Are all fingerprint fields deterministic and run-identity scoped?
- Is there zero mechanic mutation in this phase?
- Is dev output fully gated?
- Are baseline metrics reproducible from command-line test runs?
- Are docs and changelog updated when implementation starts and completes?
