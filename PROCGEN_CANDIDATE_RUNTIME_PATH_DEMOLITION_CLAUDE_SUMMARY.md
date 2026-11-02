# Procgen Candidate Runtime Path Demolition (G5) — Closing Summary

Removed the in-place candidate-promotion path that G4's fresh-materialization
architecture had already superseded in production. `ProcGenTilemap` no longer
has a `promote_evaluated_candidate_to_final()`/`_finalize_accepted_candidate_to_final()`
seam at all; `materialize_accepted_candidate()` (G4) is the only
accepted-candidate realization entry point. Migrated its last two callers
(a dev review tool and a source-order smoke) to the canonical pipeline.
Accepted-world fingerprints are unchanged, verified byte-for-byte against
G4's own documented baseline.

## What landed

- `custodian/game/world/procgen/proc_gen_tilemap.gd`: deleted
  `promote_evaluated_candidate_to_final()` and `_finalize_accepted_candidate_to_final()`
  in full (~105 lines). `CustodianContractMap.generate_contract()` already
  routed exclusively through `materialize_accepted_candidate()` before this
  packet (confirmed by grep: zero production callers of the deleted
  functions), so this is a pure deletion with no production call-site change.
  Fixed three stale comments/docstrings that still referenced the deleted
  function name. Left `get_last_promotion_timing_snapshot()` in place as a
  one-line alias to G4's `get_last_materialization_timing_snapshot()`: it
  backs the `"promotion"` field in the `custodian.procgen_performance_baseline.v1`
  benchmark schema, and this packet's own Preserve clause explicitly covers
  benchmark schema, so removing that field was out of scope even though the
  function body was legitimately dead weight.
- `custodian/tools/validation/procgen_dressing_cluster_review.gd`: the
  `clusters_on` capture pass used to eval-generate on its `map` instance
  then call `promote_evaluated_candidate_to_final()` on that same instance.
  It now builds a `candidate_semantic_adapter` snapshot from the eval-mode
  candidate and materializes onto a fresh, never-generated second
  `ProcGenTilemap` via `ProcgenCandidateMaterializer`, mirroring
  `CustodianContractMap`'s own production flow exactly (a fresh instance is
  required — `materialize_accepted_candidate()` rejects any instance with a
  nonzero `_debug_generation_id`).
- `custodian/tools/validation/procgen_macro_presentation_smoke.gd`:
  `_validate_pipeline_order()` used to prove the macro-presentation ->
  dressing-clusters -> foliage phase ordering twice — once by scanning
  `_fill_tilemaps()`'s source, once by scanning the now-deleted promotion
  function's source. Since materialization now runs through one fresh,
  non-eval-mode `_fill_tilemaps()` pass with no separate promotion step, the
  same invariant only needs proving once; the check now verifies
  `_rebuild_macro_presentation()` -> `_build_dressing_cluster_plan()` ->
  `_generate_foliage()` ordering directly within `_fill_tilemaps()`'s
  final-mode branches.
- Updated `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` (G5 complete, S4
  Completion Evidence, Current Program Position advanced to M2) and mirrored
  S4 to `complete` in `design/00_meta/MASTER_ROADMAP.md`.

## What went wrong on the way

- G4 landed a genuinely large architecture shift (fresh-materialization
  instead of in-place promotion) between my prior session (G2/G3) and this
  one; the packet's own "Current measured state" line undersold how much had
  already changed. Reading G4's closing summary and the current
  `custodian_contract_map.gd`/`proc_gen_tilemap.gd` state before touching
  anything avoided building on a stale mental model.
- `procgen_dressing_cluster_review.gd`'s baseline (`clusters_off`) capture
  fails under plain `--headless` with `Parameter "t" is null` at
  `viewport.get_texture().get_image()` — no rendering device available. This
  reproduces on the *original* baseline pass, before any of this packet's
  migrated code runs, and the tool is not a `validation_manifest.json` entry
  (only referenced as an owner-trigger for `procgen_dressing_clusters_smoke.gd`),
  so it is a pre-existing headless-mode limitation of a manual review tool,
  not a regression from this change. The script parsed and ran correctly up
  to that point, which is the confidence available without a rendering
  backend.
- LFS materialization was needed again (all objects locally cached; pure
  local `git lfs checkout` before the first `--import --quit` pass;
  confirmed clean with only the same ~20 unrelated pre-existing
  `valid=false` sidecars afterward, none touching procgen).

## Validation

- `procgen_candidate_promotion_smoke.gd`: PASS.
- `procgen_candidate_semantic_model_smoke.gd` (G2): PASS, unchanged.
- `procgen_candidate_evaluator_smoke.gd` (G1): PASS, unchanged.
- `procgen_macro_presentation_smoke.gd` (edited): PASS.
- `procgen_contract_rescue_diagnostic_smoke.gd`: PASS, 36/36 seeds.
- `procgen_terrain_required_cells_smoke.gd`: PASS, unchanged.
- S1 quick benchmark: PASS, `determinism_ok: true`; contract fingerprint
  `2884730602` — exact match to G4's documented seed-420777 result.
- S1 full benchmark: PASS, `determinism_ok: true`; all 3 contract fingerprints
  (`2884730602`, `392435093`, `1672459047`) exact matches to G4's documented
  baseline for the same three seeds — proves the deletion changed zero
  accepted-world output.
- `procgen_dressing_cluster_review.gd` (edited, not manifest-gated): baseline
  capture fails under `--headless` for the pre-existing reason above; the
  migrated `clusters_on` materialization code was never reached in this
  environment. Documented, not treated as blocking.
- `python3 custodian/tools/validation/run_validation.py --changed --json`:
  17/17 selected tests passed.
- `git diff --check`: clean.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: nothing structurally surprising; the main cost was re-establishing an accurate mental model of `custodian_contract_map.gd`/`proc_gen_tilemap.gd` after G4's architecture shift before making any edits, plus a pre-existing (unrelated) headless-mode limitation in a non-gating review tool.
- Root cause / contributing factors: this packet's own "Current measured state" description ("Migration temporarily retains legacy evaluation/promotion seams for parity while S3/S4 land") undersold that G4 had already fully replaced the promotion call site in production; the dead code really was dead by the time this packet started, which made the deletion itself low-risk once confirmed.
- Prevention / pipeline improvement: for demolition/cleanup packets that depend on a just-landed architecture-shifting predecessor, read that predecessor's closing summary and re-derive the current call graph (grep for the function(s) being retired) before planning the diff, rather than trusting the packet's authored-time description of "current state."
- Tooling / docs drift discovered: `procgen_dressing_cluster_review.gd` cannot run its baseline capture under plain `--headless`; worth a note in its own header or in `VALIDATION_RECIPES.md` if anyone expects to run it unattended, since it is a rendering-dependent review tool, not a `--headless`-safe smoke.
- Follow-up: manual-follow-up (document `procgen_dressing_cluster_review.gd`'s rendering-backend requirement; not blocking for this series). The pre-existing candidate-promotion streaming-reveal assertion tracked since S1 appears resolved by G4's rewrite of that smoke test — no longer observed as a failure in this task's validation.
- What worked: grepping for all callers of the functions being deleted before deleting anything, and validating fingerprint equality against G4's own documented numbers rather than just "determinism_ok: true" in isolation, gave strong, specific confidence that the deletion was behavior-neutral rather than just "the tests still pass."
