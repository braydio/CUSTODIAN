# Procgen Performance Baseline V1 (S1) — Closing Summary

Landed the first reproducible, structured, threshold-free procgen generation
+ runtime-streaming performance baseline (`custodian.procgen_performance_baseline.v1`),
establishing the fixed-seed contract that every later slice in
`PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` compares against. No generation,
candidate-acceptance, promotion, or streaming-reveal behavior was changed.

## What landed

- `custodian/tools/validation/procgen_performance_baseline_bench.gd` — headless
  `SceneTree` benchmark with `quick` (default) and opt-in `--full` profiles.
  Quick runs the same fixed seed/size twice and asserts matching fingerprints;
  full runs the fixed 3x3 size/seed direct-generation matrix
  (160x160/192x192/224x224 x seeds 420777/420779/771923) plus 3 fixed-seed
  full-candidate-loop contract cases and one scripted runtime-streaming case.
  Writes JSON to `user://performance/procgen_performance_baseline_v1.json`
  and prints a compact summary. `--sha=<git-sha>` attaches optional
  CLI-provided commit metadata since exact Git SHA is not safely discoverable
  from headless runtime code.
- `custodian/game/world/procgen/diagnostics/procgen_performance_snapshot.gd` —
  narrow normalizer. Never re-runs generation/mutation/streaming; only
  reshapes facts already owned by `ProcGenTilemap`/`CustodianContractMap`.
- `ProcGenTilemap` (`proc_gen_tilemap.gd`): added `_last_generation_timing_snapshot`,
  `_last_promotion_timing_snapshot` (plus the intermediate `_last_fill_tilemaps_marks`/
  `_last_fill_tilemaps_total_ms` fields feeding them) and their getters
  `get_last_generation_timing_snapshot()` / `get_last_promotion_timing_snapshot()`.
  Purely additive: populated at the tail of `_on_procgen_finished()`/`_fill_tilemaps()`
  and `promote_evaluated_candidate_to_final()`, no control flow touched.
- `CustodianContractMap` (`custodian_contract_map.gd`): added a per-attempt
  accumulator (`_last_generation_attempts`) appended inside the existing
  candidate loop, and `_last_contract_generation_report` (contract seed,
  attempt limit/run count, accepted attempt, total candidate-loop duration,
  degraded-fallback state, final-promotion duration, full per-attempt array)
  populated before both failure-return paths and refined on success/fallback,
  exposed via `get_last_contract_generation_report()`.
- Registered the quick profile as `procgen_performance_baseline_quick` in
  `validation_manifest.json` (only the cheap proof; full profile stays
  manual/opt-in). Documented both invocations in `VALIDATION_RECIPES.md`
  under a new "Procgen Performance Baseline (S1)" section. Indexed both new
  files in `FILE_INDEX.md`. Updated `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`
  (S1 complete, Completion Evidence, Current Program Position) and mirrored
  S1 to `complete` in `design/00_meta/MASTER_ROADMAP.md`.

## Measurements (first baseline, not a pass/fail budget)

Host: Godot 4.7.2-stable (arch_linux), debug build, headless.

- Quick (48x48, seed 420777): two same-seed runs produced identical
  fingerprints; generation `total_ms` ~2.6s; one contract case accepted on
  attempt 1/12 (`total_candidate_loop_duration_ms` 24086,
  `final_promotion_duration_ms` 14933); runtime case (64x64) averaged
  ~6.8 ms/frame over 60 frames.
- Full (fixed 3x3 matrix): all 9 generation cases and 3 contract cases
  produced valid schema-stable output with `determinism_ok: true`.
  Generation `total_ms` scaled ~25-46s across 160x160 to 224x224. All 3
  contract cases accepted on attempt 1/12
  (`total_candidate_loop_duration_ms` 12637-32399,
  `final_promotion_duration_ms` 8676-18536). Runtime case (192x192) averaged
  ~7.0 ms/frame over 60 frames, streaming-reveal queue peak 362.

Full detail is in `PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`'s S1 Completion
Evidence section; the runtime JSON itself is ephemeral and was not committed.

## What went wrong on the way

- **Environment was broken before any of this could run.** The worktree's
  procgen dependency chain (`custodian_contract_map.gd` -> `world_ingress_spawner.gd`
  -> Ash Bell ingress site) failed to compile because a batch of Git-LFS-tracked
  binary assets were left as unmaterialized pointer stubs (real content
  present in the local LFS object cache but not smudged into this worktree's
  working tree — the repo is currently in the documented temporary LFS
  bandwidth-degraded mode). This broke every procgen validation path in the
  environment, not just this task's new bench. Confirmed via `git lfs
  ls-files -l` + a local object-store existence check that all 12,772 unique
  LFS objects referenced anywhere in the repo were already cached locally, so
  materializing them (`git lfs checkout`) was a pure local disk operation
  (0 B/s network) explicitly permitted by `custodian/AGENTS.md`'s degraded-mode
  note ("Existing locally cached LFS objects may be used normally").
- **A genuine bug in the new bench script, found and fixed.** `level_data_ready`
  is emitted *synchronously* inside `ProcGenTilemap.generate()`, before that
  call returns. An `await map.level_data_ready` placed on the line *after*
  `generate()` therefore missed the already-fired emission and hung forever —
  reproduced twice with identical symptoms (process alive at ~1-3% CPU,
  stalled forever after the last synchronous print). Fixed by dropping the
  post-hoc await entirely; `generate()` is confirmed synchronous end-to-end
  in this headless context, so the bench now just calls it and proceeds.
  A first attempted fix (connect-then-check-a-flag) also failed, because
  GDScript lambdas capture outer local variables *by value*, not by
  reference — a second real GDScript-specific gotcha worth remembering.
- **Discovered a pre-existing, unrelated smoke-test defect, not caused by
  this task.** `procgen_candidate_promotion_smoke.gd` fails deterministically
  on `Assertion failed: Promotion exposed additional streamed floor cells.`
  Root cause: `promote_evaluated_candidate_to_final()` calls
  `_prepare_streaming_reveal()` when `enable_streaming_reveal` is true, which
  clears `floor_tilemap` and re-primes only the immediate-radius chunk window
  around spawn — a different (and here, larger, via
  `_reveal_chunk_immediately -> _reveal_road_piece_decal ->
  _spawn_road_piece_decal`) painted-cell count than the smoke test's
  `painted_before` baseline from eval-mode painting. Verified this is not
  caused by this task: `git log 6a11a14e..HEAD -- .../proc_gen_tilemap.gd`
  shows zero commits touched the file since the packet's reviewed SHA, and
  the 2-file diff added here is purely additive dict/getter insertions with
  no touchpoints in the streaming-reveal code path (confirmed by temporarily
  reverting the diff via `Edit`, not `git checkout`, and reproducing the
  identical failure). `procgen_runtime_health_smoke.gd` and
  `procgen_spatial_normalization_smoke.gd` both pass cleanly. Not fixed here:
  streaming-reveal chunk-lifecycle behavior is explicitly out of S1's scope
  (`Non-goals: ... do not change chunk lifecycle/unload defaults`).
- Two unrelated interior-prop textures
  (`props_steel_locker_01_44x64.png`, `props_terminal_console_01_74x56.png`)
  still fail to load even after full LFS materialization and two re-import
  passes, despite being real non-pointer files on disk. Non-fatal (both
  required smokes that touch this path still pass); left uninvestigated as
  out of scope.

## Validation

- `procgen_performance_baseline_bench.gd` (quick): PASS, `determinism_ok: true`.
- `procgen_performance_baseline_bench.gd` (`--full`): PASS, `determinism_ok: true`, all 9 generation + 3 contract cases valid.
- `procgen_runtime_health_smoke.gd`: PASS.
- `procgen_spatial_normalization_smoke.gd`: PASS.
- `procgen_candidate_promotion_smoke.gd`: FAIL — pre-existing, unrelated to this task (see above). Not green at closeout; documented rather than silently skipped.
- `python3 custodian/tools/validation/run_validation.py --changed --json`: see command output at closeout.
- `git diff --check`: see command output at closeout.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: high
- What went wrong: the worktree environment was non-functional for any procgen validation before this task began (LFS pointer stubs breaking compilation of `custodian_contract_map.gd`'s dependency chain); a real signal-race bug in the new bench script caused it to hang indefinitely; a pre-existing, unrelated smoke-test assertion (`procgen_candidate_promotion_smoke.gd`) remains red and could not be fixed within S1's scope.
- Root cause / contributing factors: (1) the repo's active temporary Git-LFS bandwidth-degraded mode left binary assets unmaterialized in this specific worktree though fully cached locally; (2) `Signal.emit()` inside a synchronous GDScript call chain fires before the caller's next line runs, so `await signal` placed after the call that emits it is a classic missed-emission race; GDScript lambda closures also capture by value, not reference, defeating a first attempted fix; (3) `_prepare_streaming_reveal()`'s clear-and-reprime behavior does not preserve `procgen_candidate_promotion_smoke.gd`'s `painted_before == painted_after` invariant, and this predates S1 (verified via `git log` and diff-revert reproduction).
- Prevention / pipeline improvement: when a headless Godot script needs to know a synchronous call has finished, do not `await` a signal it may have already emitted — either avoid the await entirely once synchronicity is confirmed, or connect a listener *before* calling and check a mutable-by-reference container (Array/Dictionary), never a plain local `var`, since GDScript lambdas snapshot locals by value.
- Tooling / docs drift discovered: `procgen_candidate_promotion_smoke.gd`'s streamed-floor-cell equality assertion appears to be a latent defect independent of any recent landed work; needs its own investigation/fix packet. Two interior-prop PNGs fail to load despite real materialized content on disk; root cause not identified.
- Follow-up: `procgen-candidate-promotion-smoke-streaming-assertion` (manual-follow-up; no such packet exists yet, this is a discovered gap, not an authored one — see governance note on this program's packet-authoring restriction).
- What worked: reusing existing timing boundaries (`_marks`, candidate-loop locals, `get_runtime_health_snapshot()`) via purely additive getters kept the diff small and provably non-overlapping with the pre-existing smoke-test failure, which made isolating that failure's cause tractable without a second full-worktree environment.
