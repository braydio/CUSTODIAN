# Procgen Phase 0: Instrumentation Baseline

## Status

- Lifecycle: `planned`
- Parent roadmap: `design/20_features/planned/PROCGEN_FORWARD_PROTOTYPE_ROADMAP.md`
- Implementation start condition: explicit approval to move this doc to `in_progress`

## Purpose

Create deterministic instrumentation for run identity and cross-seed variance measurement before deeper procgen gameplay phases.

Phase 0 is additive only. It must not alter gameplay mechanics.

## Current Audit

- `dev_mode` exists in `GameState`.
- `faction_profile` exists and is seed-driven.
- Snapshot currently lacks `run_fingerprint` contract fields.
- No dedicated procgen report endpoint exists.
- No baseline variability harness exists.

## Scope

1. Add deterministic `run_fingerprint` to snapshot output.
2. Add dev-gated `/procgen_report` endpoint.
3. Add baseline variability test harness and metrics.
4. Add determinism tests for same-seed stability and runtime-counter invariance.

## Out of Scope

- Topology generation changes (Phase 1).
- Doctrine behavior rewrites (Phase 2).
- Economy profile generation (Phase 3).
- Command contract shape changes.
- Nondeterministic analytics.

## Design Constraints

1. Same seed and text seed must produce stable fingerprint values.
2. Fingerprint fields must be run-identity scoped only.
3. Mutable counters (`time`, `materials`, threat, damage) must not affect fingerprint.
4. Dev report must be unavailable when `dev_mode` is false.
5. Snapshot changes must be additive and migration-safe.

## Data Contract

## Snapshot Additions

Add top-level `run_fingerprint` and bump snapshot schema version to `5`.

```json
{
  "snapshot_version": 5,
  "run_fingerprint": {
    "schema_version": 1,
    "seed": 12345,
    "text_seed": 987654321,
    "topology_profile_id": "BASELINE_STATIC",
    "doctrine_profile_id": "PRECISION",
    "economy_profile_id": "BASELINE_STATIC",
    "event_catalog_hash": "d4bc3f0e1a5c92bf",
    "faction_profile_hash": "129ab1f48f5b0bc1",
    "fingerprint_hash": "f238cb4a6e1f6b20"
  }
}
```

## Dev Report Contract

`GET /procgen_report` (dev mode only):

```json
{
  "ok": true,
  "procgen_report": {
    "seed": 12345,
    "fingerprint_hash": "f238cb4a6e1f6b20",
    "components": [
      {"name": "topology_profile_id", "value": "BASELINE_STATIC"},
      {"name": "doctrine_profile_id", "value": "PRECISION"},
      {"name": "economy_profile_id", "value": "BASELINE_STATIC"},
      {"name": "event_catalog_hash", "value": "d4bc3f0e1a5c92bf"},
      {"name": "faction_profile_hash", "value": "129ab1f48f5b0bc1"}
    ]
  }
}
```

When `dev_mode` is false:

```json
{"ok": false, "error": "DEV MODE REQUIRED"}
```

with HTTP `403`.

## Implementation Plan

## Slice A: Fingerprint Builder

- Add `_build_run_fingerprint()` to `GameState`.
- Use deterministic hashing over a strict allowlist of fields.
- Use placeholders until later phases generate live profiles:
  - `topology_profile_id = BASELINE_STATIC`
  - `economy_profile_id = BASELINE_STATIC`

## Slice B: Snapshot Wiring and Migration

- Add `run_fingerprint` to `snapshot()`.
- Set `snapshot_version = 5`.
- Update `snapshot_migration.py` to migrate versions `<5`.

## Slice C: Dev Procgen Report Surface

- Add `/procgen_report` endpoint to world-state and terminal servers.
- Gate response on `state.dev_mode`.
- Return deterministic report derived from `GameState.procgen_report()`.

## Slice D: Variability Harness

- Add deterministic test helper to compute:
  - `fingerprint_uniqueness_ratio`
  - `profile_switch_rate`
- Baseline seed suite: `1000..1099`.
- Stability suite: repeated `424242`.

## Test Plan

1. Snapshot includes `run_fingerprint` with required keys.
2. Fingerprint hash length and schema fields are valid.
3. Same seed replay yields identical fingerprint.
4. Runtime counters do not alter fingerprint.
5. `/procgen_report` returns `403` when dev mode is off.
6. `/procgen_report` returns deterministic payload when dev mode is on.
7. Baseline variability harness executes and emits stable metrics.

## Acceptance Criteria

1. `run_fingerprint` exists in snapshot with schema version `1`.
2. Snapshot migration supports version `5`.
3. Dev report endpoint is available and correctly gated.
4. Variability harness exists and passes.
5. Existing world-state regression tests remain passing.
6. No gameplay mechanics changed.

## Risks and Mitigations

- Risk: hash instability from unordered structures.
  - Mitigation: canonical JSON serialization with sorted keys.
- Risk: accidental dependency on mutable runtime fields.
  - Mitigation: strict allowlist in fingerprint builder and dedicated test.
- Risk: exposing debug data outside dev mode.
  - Mitigation: explicit dev gate with endpoint tests.
