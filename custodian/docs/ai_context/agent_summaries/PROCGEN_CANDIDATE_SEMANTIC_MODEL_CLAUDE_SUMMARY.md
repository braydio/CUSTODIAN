# Procgen Candidate Semantic Model (G2) — Closing Summary

Introduced the deterministic, data-only candidate representation
(`custodian.procgen_candidate_semantic_model.v1`) and an adapter that
projects an already-generated candidate into it. `CandidateEvaluator`
gained snapshot-based `evaluate_snapshot()`/`measure_snapshot()` functions
with identical acceptance/score/terrain-failure policy to the existing
live-Node path, and `CustodianContractMap`'s candidate loop now calls
`evaluate_snapshot()` — no evaluator call in production requires a
Node/TileMap reference. Live candidate construction is unchanged; this is
purely a measure-from-data seam, not a materializer (that is G3/G4's job).

## What landed

- `custodian/game/world/procgen/generation/candidate_semantic_adapter.gd` —
  `build_snapshot(map_instance, level_data, seed_identity)` walks the live
  candidate exactly once to capture: full-map walkable-cell topology,
  elevation-blocked-edge exceptions (captured by calling the candidate's own
  `can_traverse_elevation()` once per adjacent walkable pair, never
  reimplementing its logic), the already-computed required-ingress
  validation result, `level_data` pass-through (already data-only), map
  size, and caller-supplied seed identity. `fingerprint_snapshot()` proves
  stable serialization ordering.
- `candidate_evaluator.gd`: added `evaluate_snapshot()`/`measure_snapshot()`
  and their internal mirrors (`_get_map_layout_metrics_from_snapshot()`,
  `_flood_fill_walkable_snapshot()`, `_is_layout_walkable_tile_snapshot()`,
  `_find_nearest_walkable_layout_tile_snapshot()`) that read only
  `snapshot.walkable_cells`/`elevation_blocked_edges`/`level_data`. The
  legacy live-Node `evaluate_candidate()`/`measure_candidate()` and their
  internals are untouched, kept as the parity baseline.
- `custodian_contract_map.gd`'s candidate loop: builds a snapshot per
  attempt via the adapter, then calls `evaluate_snapshot()` instead of
  `evaluate_candidate()`. `_last_generation_attempts`/`_last_contract_generation_report`
  (S1) are unaffected — they read the same `evaluation` dict shape as
  before.
- `tools/validation/procgen_candidate_semantic_model_smoke.gd` — generates
  real candidates at S1's fixed seeds (420777/420779/771923), proves
  snapshot fingerprint stability across two independent builds of the same
  candidate, and asserts `evaluate_snapshot()` results (accepted, score,
  terrain_failed, and every relevant metrics key) exactly match
  `evaluate_candidate()`. Registered in `validation_manifest.json`
  (`procgen_candidate_semantic_model`, tier actor, needs_import).
- Updated `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` (G2 complete, evidence
  under S3, Current Program Position) and mirrored S3 to `in_progress` in
  `design/00_meta/MASTER_ROADMAP.md` (S3 covers G2+G3; only G2 has landed).

## What went wrong on the way

- Two real GDScript bugs in the first draft of the adapter, both caught by
  the first smoke run: a typed `var ingress_validator: RefCounted = ...`
  where `WorldIngressSpawner` actually `extends Node` (wrong static type),
  and a `var procgen := _get_procgen_node(...)` where the callee returns
  `Variant`, tripping this project's warnings-as-errors on inferred-Variant
  typing. Both are one-line fixes; caught immediately by attempting the
  real generation path rather than trusting the design on paper.
- A genuine parity bug, also caught by the smoke: `evaluate_snapshot()`
  initially lacked the same early-return guard `evaluate_candidate()` has
  for a null/missing map (`if map_instance == null or ...: return
  _evaluation_result(metrics, policy, false)` *before* touching ingress
  state). Without it, the missing-map case fell through into the "append
  `required_world_ingress` to rejection_reasons" branch, producing
  `["missing_map_instance", "required_world_ingress"]` instead of the
  legacy path's `["missing_map_instance"]`. Fixed by adding the identical
  guard to `evaluate_snapshot()`. This is exactly the kind of drift the
  parity smoke exists to catch — worth noting since a superficially
  reasonable "mirror the other function" implementation missed a real edge
  case without it.
- LFS materialization was needed again in this fresh worktree (all 12,773
  objects already locally cached, so `git lfs checkout` was a pure local
  operation per the degraded-mode note); done *before* the first
  `--import --quit` pass this time, per the S1 closing summary's own
  documented lesson, and confirmed clean (only 23 unrelated pre-existing
  `valid=false` sidecars afterward, none touching procgen).
- `procgen_contract_rescue_diagnostic_smoke.gd` legitimately takes ~10-12
  minutes (36 candidate generations across up to 224x224 maps); not a hang,
  just slow — worth remembering for future slices in this lane so it isn't
  mistaken for a stall.

## Validation

- `procgen_candidate_semantic_model_smoke.gd` (new): PASS, all 3 S1 fixed
  seeds, snapshot/live parity exact, fingerprint stable.
- `procgen_candidate_evaluator_smoke.gd` (G1): PASS, unchanged.
- `procgen_contract_rescue_diagnostic_smoke.gd` (G1): PASS, 36/36 seeds,
  forced-failure abort path intact.
- `procgen_terrain_required_cells_smoke.gd` (G1): PASS, unchanged.
- `procgen_performance_baseline_quick` (S1): PASS, `determinism_ok: true`.
- `procgen_candidate_promotion_smoke.gd`: FAIL — the same pre-existing,
  unrelated streamed-floor-cell assertion documented in S1 and G1. Not
  caused by this diff.
- `python3 custodian/tools/validation/run_validation.py --changed --json`:
  4/4 selected tests passed (diff scoped correctly after discarding local
  `.import` cache churn before the sweep).
- `git diff --check`: clean.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: two static-typing bugs and one real parity bug (missing null-map guard) in the first draft of the new snapshot code; all caught by the required parity smoke on the first real run.
- Root cause / contributing factors: mirroring an existing function's structure by eye missed one conditional early-return branch; GDScript's strict typed-var inference (warnings as errors) rejected a `Variant`-returning helper assigned via `:=`.
- Prevention / pipeline improvement: when mirroring a function for a new data source, diff the two implementations structurally (branch-by-branch) rather than re-deriving from the docstring/spec, and run the parity proof before anything else once both paths exist.
- Tooling / docs drift discovered: none new; `procgen_candidate_promotion_smoke.gd`'s pre-existing streaming-reveal assertion remains open, same as reported in S1 and G1.
- Follow-up: manual-follow-up (same pre-existing candidate-promotion streaming assertion tracked in S1/G1; still not owned by any packet in this series' scope).
- What worked: keeping the legacy live-Node evaluator functions completely untouched and adding pure-mirror snapshot functions alongside them made the parity smoke a strong, cheap safety net, and let the diff stay small and structurally easy to review.
