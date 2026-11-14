# Procgen Semantic Candidate Generation (G3) — Closing Summary

Rejected candidate attempts no longer pay for final-presentation or
collision realization work. Three purely presentation/collision phases in
`ProcGenTilemap._fill_tilemaps()` now skip during `generation_evaluation_mode`
(every candidate attempt runs in this mode), while the accepted winner still
gets them via `promote_evaluated_candidate_to_final()`. No candidate
acceptance, scoring, or winner-selection logic changed; this is purely about
what work a rejected attempt does before being discarded.

## What landed

- `custodian/game/world/procgen/proc_gen_tilemap.gd`, three gates added to
  `_fill_tilemaps()`:
  - `_rebuild_runtime_wall_collision(map_size)` — was reachable for every
    candidate attempt via the `elif build_runtime_wall_collision:` branch
    (candidates never override that export's `true` default). Now requires
    `not generation_evaluation_mode` too.
  - `_rebuild_nonwalkable_surface_visuals()` — ocean/shoreline decal
    painting plus coastline-presentation node instantiation. Now inside an
    `if not generation_evaluation_mode:` block alongside the boundary call
    below.
  - `_rebuild_runtime_walkable_boundary()` — physics boundary body
    creation. Same gate.
  - `promote_evaluated_candidate_to_final()` gained calls to the latter two
    (`_rebuild_nonwalkable_surface_visuals()`, `_rebuild_runtime_walkable_boundary()`)
    so the accepted winner still receives them. It does not need a new call
    to `_rebuild_runtime_wall_collision()`: the accepted winner always has
    `enable_streaming_reveal = true` (candidates never override it), so
    promotion's existing `_prepare_streaming_reveal()` call already
    established wall collision via `_sync_runtime_wall_collision_with_visible_walls()`
    — the eval-mode `_rebuild_runtime_wall_collision()` call this change
    removes was redundant with that path, not load-bearing for it.
- `_apply_sundered_keep_frontage_floor_visuals()` (floor-cell tile-variant
  repainting) was investigated as a fourth gate candidate and **not**
  changed — see What Went Wrong.
- Updated `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` (G3 complete, evidence
  under S3, Current Program Position advanced to G4) and mirrored S3 to
  `complete` in `design/00_meta/MASTER_ROADMAP.md` (G2+G3 both now landed).

## What went wrong on the way

- **A real regression, caught immediately by the existing promotion smoke.**
  My first draft also gated `_apply_sundered_keep_frontage_floor_visuals()`
  behind `generation_evaluation_mode` and added it to
  `promote_evaluated_candidate_to_final()`, on the assumption that "cosmetic
  tile repainting" was as safe to defer as the other three. It is not:
  `procgen_candidate_promotion_smoke.gd` asserts the accepted candidate's
  floor-cell fingerprint (source/atlas/alternative per cell) is byte-for-byte
  identical before and after promotion, and this function changes exactly
  that data for existing floor cells. Deferring it to promotion made the
  fingerprint diverge, failing with `Promotion changed accepted floor
  authority` — a *different*, new assertion than the one pre-existing
  failure this series has documented since S1, which made it easy to
  recognize as a genuine regression rather than the known issue. Fixed by
  reverting that one function to unconditional (it must run in the same pass
  that establishes floor authority) and removing the now-unneeded call from
  promotion. Reran the smoke and confirmed it was back to exactly the one
  pre-existing, documented failure.
- This is a strong argument for why the packet's parity/promotion smokes
  exist: a plausible-sounding uniform treatment of four similarly-named
  "_rebuild_*_visuals"-style functions was wrong for one of the four in a
  way that would have silently shipped a determinism bug in the accepted
  world's floor tile texturing.
- LFS materialization was needed again (all 12,773 objects locally cached;
  pure local `git lfs checkout`, done before the first `--import --quit`
  pass, confirmed clean with only the same 23 unrelated pre-existing
  `valid=false` sidecars afterward).
- The fixed-seed test corpus (S1's cases, the rescue diagnostic's 36 seeds)
  turned out to almost never exercise genuine multi-attempt rejection —
  nearly every seed accepts on attempt 1/12 — which limited how strong a
  timing delta this closeout could measure directly; see the roadmap's G3
  Completion Evidence for the one real data point available and why the
  architectural guarantee is the stronger claim here.

## Validation

- `procgen_candidate_promotion_smoke.gd`: FAIL — same pre-existing,
  documented streamed-floor-cell assertion (confirmed identical to
  S1/G1/G2, not the new one caught and fixed during this task).
- `procgen_candidate_semantic_model_smoke.gd` (G2): PASS, unchanged.
- `procgen_candidate_evaluator_smoke.gd` (G1): PASS, unchanged.
- `procgen_contract_rescue_diagnostic_smoke.gd` (G1): PASS, 36/36 seeds,
  identical `ok` summary to G2's run.
- `procgen_terrain_required_cells_smoke.gd` (G1): PASS, unchanged.
- S1 quick benchmark: PASS, `determinism_ok: true`.
- S1 full benchmark: PASS, `determinism_ok: true`; all 3 contract cases
  accept on attempt 1/12 with timings within normal host variance of the S1
  baseline.
- `python3 custodian/tools/validation/run_validation.py --changed --json`:
  14/14 selected tests passed.
- `git diff --check`: clean.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: one of four superficially-similar "skip during eval mode" gates was actually load-bearing for the accepted candidate's floor-tile fingerprint contract; applying uniform treatment to all four introduced a real regression, caught by the existing promotion smoke on the first validation run.
- Root cause / contributing factors: `_apply_sundered_keep_frontage_floor_visuals()`'s naming and location alongside three genuinely-safe presentation/collision functions made it look like a peer of theirs; it actually mutates floor-cell tile identity data that a downstream correctness smoke fingerprints, while the other three only touch separate presentation layers or physics bodies never read by `level_data`/the evaluator.
- Prevention / pipeline improvement: before gating a function behind a new mode check, trace what it actually writes (which TileMap layer, which `_last_*`/member field) rather than grouping by name or by physical proximity in the source; then run the most correctness-sensitive existing smoke (here, candidate promotion) before the broader suite.
- Tooling / docs drift discovered: none new. The fixed-seed test corpus rarely exercises genuine multi-attempt candidate rejection, which is a real gap for measuring this class of optimization's actual savings; worth a note for whoever authors S11's soak corpus.
- Follow-up: manual-follow-up (same pre-existing candidate-promotion streaming assertion tracked since S1; still not owned by any packet in this series' scope). Consider whether S11's soak corpus should include at least one fixed seed that genuinely rejects several candidates before accepting, so future generation-lane slices have a real timing signal to measure against.
- What worked: running the highest-risk correctness smoke (`procgen_candidate_promotion_smoke.gd`) immediately after the first draft, before the longer rescue/terrain/benchmark suite, caught the regression in under two minutes instead of after a ~15-minute validation pass.
