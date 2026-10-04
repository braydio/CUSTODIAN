# PROCGEN_REGION_FRAME_PRESENTATION_FOUNDATION summary

Workstream `procgen-region-frame-presentation-foundation` (RF1).

**Part 0, M6 proof hardening (N1-01..N1-05)** in `procgen_distant_chunk_unload_smoke.gd`: counted multi-frame flush coalescing (new debug counter `debug_get_streaming_visual_flush_count()`), real A* path plus a genuinely UNSEEN chunk exclusion, guaranteed road-decal removal, hermetic portal protection with in-test mutation, tree/trunk-blocker/cluster foliage parity. No M6 production defect surfaced; reinstating the direct flush fails the new counter assertions.

**Part 1, Region Frame**:
- `ProcgenRegionFrameProfile` + `alpine_plateau.tres` (explicit `visual_fallback`; Endless Forest underlay is a reported stand-in).
- Classifier derives `exterior_chasm_cells` / `internal_chasm_cells` (CHASM-only boundary flood; OCEAN never enters; surface kinds and counts unchanged).
- `CustodianContractMap.region_frame_profile_id`: set to `alpine_plateau` only in the production scene, copied into `world_profile`; `PLANET_WORLD_PROFILES` untouched, nothing inferred from `planet_key`.
- Depth backdrop follows the exterior mask only; internal-only chasms hide it; Drowned Basilica override still wins and never mutates semantics.
- Telemetry: `get_region_frame_debug_snapshot()` and level-data `region_frame`.

**Validation**: new `procgen_region_frame` smoke (mutation-checked) plus the full packet regression list green; macro/dressing fingerprints unchanged; S1 quick `determinism_ok=true` (`1773840677`). No renderer capture. `procgen_candidate_materializer_parity` does not exist; candidate promotion smoke ran instead.

**Not done / notes**: no Alpine art (separate asset packet). `VoidCliffFace` fascia is untouched and still uses complete-chasm/local presentation. The paired `review-procgen-region-frame-presentation-foundation` is now claimable.

## Reminder

Ran on `agent/procgen-region-frame-presentation-foundation` in a separate worktree. Switch back to `main` (or your previous branch) in the main checkout; note that checkout was behind origin and ahead by one local commit (`cleanup archive`) when I started.
