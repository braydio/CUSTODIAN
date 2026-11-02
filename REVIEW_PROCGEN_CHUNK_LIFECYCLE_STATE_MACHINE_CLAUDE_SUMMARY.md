# Review: Procgen Chunk Lifecycle State Machine (MR4) — Closing Summary

Workstream: `review-procgen-chunk-lifecycle-state-machine`
Reviewed implementation: `custodian/docs/ai_context/task_packets/archived/PROCGEN_CHUNK_LIFECYCLE_STATE_MACHINE.md` (M4)
Reviewed on main: `5ee2018ce`

## Verdict

Passed, non-blocking-only. 0 blocking defects, 0 material evidence gaps, 1
non-blocking documentation-drift finding (`R0-01`, routed to next-slice). No
correction packet scaffolded. Full receipt is the `## Independent Review`
section appended to the archived M4 packet.

## Verification performed (not just re-reading prior claims)

- **Live-reference audit**: grepped the entire `.gd` tree for
  `_revealed_chunks`/`_queued_chunks`; confirmed zero remaining field
  references (only two historical doc-comment mentions, both inside
  `ProcGenChunkLifecycle`'s own "replaces the old X" documentation).
- **Side-effect-free enumeration**: read `_get_chunk_tiles()` directly;
  confirmed it only reads `_generated_floor_cells`/`_generated_wall_cells`
  and never touches `_chunk_lifecycle` or any Node/TileMap state.
- **Truthful visibility during partial commit**: read `_is_tile_currently_visible()`
  directly; confirmed it queries `floor_tilemap.get_cell_source_id()`/
  `walls_tilemap.get_cell_source_id()` (canonical painted-cell state), not
  chunk membership.
- **State-machine contract**: read `procgen_chunk_lifecycle.gd` in full and
  traced every legal/illegal transition against the M4 packet's Change
  clauses (UNSEEN->QUEUED/VISIBLE, QUEUED->PREPARED, QUEUED/PREPARED->REVEALING,
  REVEALING->VISIBLE, VISIBLE<->DORMANT, VISIBLE/DORMANT->UNLOADED) and
  against the acceptance contract's zero-content/immediate-radius/DORMANT/
  idempotency requirements.
- **M3 integration, no duplicate queue**: read `procgen_pause_aware_streaming.gd`
  in full and the `_ready()` wiring that passes `_streaming_reveal_queue` to
  `ProcGenPauseAwareStreaming.configure()` by reference, plus the two narrow
  `on_tile_prepared`/`on_tile_committed` callbacks. Confirmed
  `ProcGenChunkLifecycle` stores only per-chunk integer counters, never a
  second tile list.
- **M5/M6 boundary**: confirmed `streaming_unload_distant_chunks` still
  defaults `false`; confirmed `force_unload()`/`debug_force_unload_chunk()`
  have no production call site (only the disabled-by-default unload path in
  `_update_streaming_chunks()` and the validation scripts); grepped for any
  payload-cache-shaped structure under `custodian/game/world/procgen/` and
  found none.
- **Fresh runtime re-execution** (Godot 4.7.2.stable.arch_linux, headless; not
  reused from the implementation's own prior claims): `procgen_chunk_lifecycle_smoke.gd`,
  `procgen_pause_aware_streaming_smoke.gd`, `procgen_candidate_promotion_smoke.gd`
  (registered as `procgen_candidate_materializer_parity`), `procgen_runtime_health_smoke.gd`,
  `procgen_macro_presentation_smoke.gd`, and `procgen_road_semantics_v2_smoke.gd`
  all PASS via `run_validation.py --test <id> --json`.
  `procgen_walkable_boundary_smoke.gd` and `runtime_wall_collision_compaction_smoke.gd`
  (not in `validation_manifest.json`) PASS via direct
  `godot --headless --path . --script res://tools/validation/<name>.gd`
  invocation per `VALIDATION_RECIPES.md`; the wall-collision smoke reproduced
  the exact documented baseline (`bodies=19 shapes=443`). `procgen_performance_baseline_quick`
  re-run fresh: `determinism_ok=true`, 48x48 seed-420777 fingerprint
  `1773840677` matches the M1-M4 documented baseline exactly. All runs
  genuinely executed in this environment; no environment gap, nothing
  fabricated.

## Finding

One non-blocking finding, `R0-01` (see the archived M4 packet's
`## Independent Review` receipt for the full record): `ProcGenChunkLifecycle.force_unload()`'s
docstring and `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md` both
describe `UNLOADED` as sticky/non-reloadable, which contradicts the actually
shipped behavior three lines above in the same file (`is_requested()`
excludes `UNLOADED`, so `request()` legitimately restarts the lifecycle) and
the already-passing `procgen_road_semantics_v2_smoke.gd` regression that
exercises exactly that reload mechanism. The M4 packet's own Execution
Feedback already documents this as an intentional, correct fix; only the
prose is stale. Routed to next-slice rather than a correction packet: the
mechanism is correct and tested, and this review's task override does not
authorize editing `design/` docs or runtime comments directly.

No other findings. All twelve M4 acceptance items were independently
reconfirmed true; item (11) (documentation reconciliation) is true except for
the one `STREAMING_PROCGEN_REVEAL.md` sentence covered by `R0-01`.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `none`
- What went wrong: Nothing blocking. Two of the named focused-validation
  scripts (`procgen_walkable_boundary_smoke.gd`,
  `runtime_wall_collision_compaction_smoke.gd`) are not registered in
  `validation_manifest.json`, so `run_validation.py --test <id>` cannot
  select them; they had to be run via direct `godot --headless --script`
  invocation per `VALIDATION_RECIPES.md` instead. This is a pre-existing
  manifest-coverage gap, not something introduced by this review.
- Root cause / contributing factors: these two smokes predate the
  manifest/`run_validation.py` convention and were apparently never
  backfilled into `validation_manifest.json`.
- Prevention / pipeline improvement: no fix attempted here (out of this
  review's bounded task-override scope, which does not authorize editing
  `validation_manifest.json`); named as a follow-up below.
- Tooling / docs drift discovered: `R0-01` above (design doc/comment claims
  `UNLOADED` is non-reloadable; code and a passing regression prove
  otherwise).
- Follow-up: `manual-follow-up` to register `procgen_walkable_boundary_smoke.gd`
  and `runtime_wall_collision_compaction_smoke.gd` in `validation_manifest.json`
  so future `--test`/`--changed` selection covers them without needing the
  direct-invocation fallback; and `manual-follow-up`/next-slice to correct
  the `R0-01` stale UNLOADED-reload prose the next time `procgen_chunk_lifecycle.gd`
  or `STREAMING_PROCGEN_REVEAL.md` is touched (e.g. during M5/M6 authoring).
- What worked: Tracing every `_chunk_lifecycle` call site directly in
  `proc_gen_tilemap.gd` (rather than trusting the packet's prose summary)
  is what surfaced `R0-01` — the docstring contradiction was adjacent to,
  not inside, the functions the M4 packet's own prose described, and would
  have been missed by a review that only reused the implementation's
  reported evidence.
