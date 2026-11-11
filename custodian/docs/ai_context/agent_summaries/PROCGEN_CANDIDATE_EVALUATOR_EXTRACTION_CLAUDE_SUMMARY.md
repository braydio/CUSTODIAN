# Procgen Candidate Evaluator Extraction — Closing Summary

Moved candidate measurement and selection policy out of `CustodianContractMap`
into `custodian/game/world/procgen/generation/candidate_evaluator.gd`. The
coordinator still owns seeded profile setup, attempt ordering, candidate
lifecycle, and final promotion. Evaluation returns a data-only dictionary with
the existing metrics dictionary plus score, terrain-failure classification,
and acceptance; existing metric keys and rejection reasons remain intact.

## Evidence

- Implementation commit: `41fde2780` (`procgen candidate evaluator, G1 extraction`); included in the workstream landing on `origin/main`.
- `procgen_candidate_evaluator` focused smoke: PASS. Covers acceptance,
  score/rejection thresholds, terrain-failure classification, degraded fallback
  eligibility, fallback tie ordering, missing-map rejection, and data-only
  result shape.
- `procgen_contract_rescue_diagnostic_smoke.gd`: PASS, 36/36 fixed-seed
  candidate metrics valid across seeds 731101, 731211, and 731333; forced
  contract failure still aborts world activation. Godot emitted shutdown leak
  warnings after the fixture completed.
- `procgen_terrain_required_cells_smoke.gd`: PASS for seeds 420777, 420778,
  and 420779, including large baseline-rescue rejection and contract abort.
- S1 `procgen_performance_baseline_quick`: PASS; same-seed determinism held.
- `run_validation.py --changed --json`: PASS, 7/7 selected tests.
- `procgen_candidate_promotion_smoke.gd`: FAIL at the previously documented
  `Promotion exposed additional streamed floor cells` assertion. This is the
  pre-existing streaming-reveal assertion recorded in the S1 summary; this
  task does not change `proc_gen_tilemap.gd` or streaming behavior. The process
  was stopped after the assertion because the failed SceneTree did not quit.
- `git diff --check` and validation manifest JSON parse: clean.

## What Went Wrong

The workstream checkout skipped Git LFS smudging during the repository's
temporary degraded-mode window. Godot initially saw pointer stubs and missing
class-cache entries. The required objects were available in the local cache;
`git lfs checkout` materialized them, a fresh editor scan/import completed, and
generated `.import` sidecar churn was restored before commit. No LFS assets or
generated import state are included in the task diff.

The first focused smoke runs also caught a floating-point equality assertion
and an invalid attempt to `free()` a `RefCounted`; both were corrected before
the passing run.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: LFS skip-smudge prevented initial Godot validation; the first smoke revision had two harness errors.
- Root cause / contributing factors: workstream checkouts honor degraded LFS mode; Godot requires materialized assets and a fresh class scan for this project.
- Prevention / pipeline improvement: check local LFS object availability and materialize cached objects before any Godot import; the primer already documents this order.
- Tooling / docs drift discovered: none; the candidate-promotion assertion is an already documented, independent follow-up.
- Follow-up: manual-follow-up
- What worked: cached LFS checkout followed by one fresh editor import restored validation.
