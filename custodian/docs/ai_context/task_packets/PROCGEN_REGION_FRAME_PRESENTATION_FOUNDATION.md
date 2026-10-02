# PROCGEN REGION FRAME PRESENTATION FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-region-frame-presentation-foundation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-procgen-distant-chunk-unload-review-corrections-1`
- Locks: `procgen-runtime, procgen-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-procgen-region-frame-presentation-foundation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `1c12e0900f031c09032e9cb673ab6a53f93c60df`
- Goal: Add the data-driven Region Frame presentation seam that separates local biome, permanent map-edge/depth presentation, and Archive Resolve, with `ALPINE_PLATEAU` as the first production frame and no change to gameplay surface/collision/navigation authority.
- Completion boundary: Done when one small region-frame profile resource selects permanent underlay/border presentation; final nonwalkable classification exposes a deterministic true-map-exterior CHASM mask distinct from internal chasms without adding a new gameplay surface kind; the live depth backdrop is driven by the selected frame and exterior mask instead of the hard-coded production `ENDLESS_FOREST` choice; `ALPINE_PLATEAU` is the current default frame; Drowned Basilica remains an explicit development/special override; local biome classification and Archive Resolve remain independent; and missing Alpine art falls back explicitly/observably rather than being silently treated as final art.
- Current measured state: Live main still has exactly the RF1 seam audited before MR6: `NonwalkableSurfaceClassifier.classify()` returns complete CHASM/OCEAN sets only; `ProcgenVoidCliffFace._classify_fascia_chasm_cells()` uses its own local-component/bounds heuristic rather than a true map-exterior mask; `ProcGenTilemap._refresh_depth_backdrop()` still hard-codes `ENDLESS_FOREST_UNDERLAY` with the `DROWNED_BASILICA` development override and passes complete `_chasm_cells` into `ProcgenDepthBackdrop.configure_from_chasm_cells()`; `ProcgenUnderlayProfile` remains the reusable FAR/MIDDLE/NEAR resource contract; and `apply_planet_world_profile()` does not consume a region-frame ID. M6 landed default-on residency. Cycle-0 MR6 then found one eviction-flush batching defect plus four missing proof assertions and created `procgen-distant-chunk-unload-review-corrections-1`; that correction is contractually limited to `_drain_residency_eviction()` coalescing and focused M6 proof, so it does not move any RF1 nonwalkable/underlay/profile owner. RF1 therefore has no remaining design uncertainty and is dependency-gated directly on the cycle-1 re-review rather than requiring another refresh.
- Evidence: `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md`; `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; `NONWALKABLE_SURFACE_REGIONS.md`; `ELEVATED_WORLD_PRESENTATION.md`; `terrain/nonwalkable_surface_classifier.gd`; `presentation/procgen_underlay_profile.gd`; `procgen_depth_backdrop.gd`; `procgen_void_cliff_face.gd`; `proc_gen_tilemap.gd::_refresh_depth_backdrop`; current `endless_forest_underlay.tres` / `drowned_basilica_underlay.tres`; `drowned_basilica_underlay_smoke.gd`; nonwalkable/cliff-face smokes.
- Task-specific authority: `PROCGEN_REGION_FRAME_PROFILES.md`; `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; `NONWALKABLE_SURFACE_REGIONS.md`; current `NonwalkableSurfaceClassifier` semantics; `ProcgenUnderlayProfile`; Archive Resolve remains separately governed by `STREAMING_REVEAL_PRESENTATION_V1.md`; reviewed M6 residency behavior is consumed only as a preserved neighboring contract.
- Work surface: Prefer one focused resource owner at `custodian/game/world/procgen/presentation/procgen_region_frame_profile.gd` and profile resources under `presentation/region_frames/`; extend `terrain/nonwalkable_surface_classifier.gd` only with derived exterior/internal CHASM presentation masks; narrow integration in `proc_gen_tilemap.gd` for profile selection, mask storage/debug/level-data export and depth-backdrop configuration; reuse `procgen_depth_backdrop.gd` and current `ProcgenUnderlayProfile`; keep `procgen_void_cliff_face.gd` local-cliff behavior unless a tiny adapter is needed to expose/consume the exterior mask. Add one focused region-frame smoke after its path exists and register it in the manifest.
- Change: Introduce a `ProcgenRegionFrameProfile` Resource with at minimum stable `profile_id`, selected `ProcgenUnderlayProfile`, and enough presentation metadata to identify the frame without owning gameplay. Create `alpine_plateau.tres` as the default frame. Until the Alpine underlay Asset V2 family exists, bind the current compatible underlay only as an explicit `visual_fallback`/debug-reported fallback state; do not rename Endless Forest art as Alpine.
- Change: In `NonwalkableSurfaceClassifier`, after CHASM/OCEAN classification, derive `exterior_chasm_cells` by flood-filling **CHASM cells only** from the rectangular map boundary. Derive `internal_chasm_cells = chasm_cells - exterior_chasm_cells`. Return both as deterministic presentation metadata. Do not change `kind_by_cell`, CHASM/OCEAN counts, collision, navigation, floor precedence, or ocean claim semantics.
- Change: Route production frame selection through world/profile data. `ProcGenTilemap.apply_planet_world_profile()` should consume a stable `region_frame_profile_id` when present and default current generated worlds to `alpine_plateau`. Keep a narrow development override for explicit underlay/frame A/B testing; preserve the existing Drowned Basilica development path without letting it remain the production authority.
- Change: Configure the global `ProcgenDepthBackdrop` from the **exterior CHASM mask**, not complete CHASM semantics. Internal ravines/pits must no longer be what turns on or bounds the permanent lower-world underlay. Keep the backdrop presentation-only and camera-following. Local/internal cliff fascia may remain driven by existing complete chasm/local-component presentation in this foundation; a later art pass may differentiate exterior versus ravine fascia styling.
- Change: Export/debug the selected frame ID, whether fallback art is active, exterior-chasm count, internal-chasm count, and underlay profile ID through existing procgen observability/level-data seams. No frame/state logs per tick.
- Preserve: Exact generated floor/wall/chasm/ocean semantics; Sundered Keep ocean claim behavior; `RuntimeWalkableBoundary`; navigation/collision; M3-M6 streaming lifecycle/residency; local `BiomeField` output; weather; current macro/depth-chunk placement semantics; Archive Resolve ownership; deterministic fingerprints except for newly added presentation/debug metadata.
- Non-goals: No new underlay PNG creation or ingestion; no Archive Resolve implementation; no new gameplay biome; no universal cliff-border rule for future frames; no ocean/coastal frame implementation; no GenerationGrid/decomplexification; no redesign of VoidCliffFace art; no minimap/compass work.
- Acceptance: (1) `ALPINE_PLATEAU` is the default region frame for current generated worlds while local biome output remains byte/fingerprint-equivalent. (2) A fixture containing one map-edge-connected CHASM and one enclosed CHASM proves only the former enters `exterior_chasm_cells`; both remain structurally CHASM. (3) Ocean cells never leak into the Alpine exterior-CHASM mask. (4) DepthBackdrop visibility/profile is driven by frame + exterior mask, and an internal-only chasm fixture does not activate/bound the global lower-world underlay. (5) Existing Drowned Basilica explicit override still works and does not mutate surface semantics. (6) Missing Alpine production art is reported as fallback state, not silently claimed final. (7) Archive Resolve and M6 counters/fingerprints are unchanged. (8) S1 quick remains deterministic with the established fingerprint unless an independently justified baseline change landed first.
- Validation: Create the focused RF1 smoke during implementation and register it after the path exists. Run it first: exact boundary-flood exterior vs enclosed CHASM, OCEAN exclusion, default `alpine_plateau` selection, explicit visual-fallback telemetry, Drowned override parity, and DepthBackdrop activation from exterior CHASM only. Then run `procgen_nonwalkable_surface`, `procgen_void_cliff_face`, `procgen_void_cliff_wall_integration`, `drowned_basilica_underlay_smoke.gd`, `elevated_world_asset_contract_smoke.gd`, `procgen_distant_chunk_unload`, `procgen_runtime_health`, candidate materializer parity, S1 quick, changed-file validation and `git diff --check`. Use structured counts/profile IDs before renderer evidence. Permit at most one gameplay-scale capture only if needed to falsify permanent-underlay vs internal-ravine spatial separation; Alpine aesthetic approval remains deferred to the asset packet/human review.
- Task overrides: `none`
- Deferred: Production Alpine FAR/MIDDLE/NEAR art and final visual sign-off live in `procgen-alpine-plateau-underlay-assets`. Other frame profiles remain design catalogue only.

## Recommended Implementation Order

1. Add `procgen_region_frame_profile.gd` and the `alpine_plateau` profile resource using the existing `ProcgenUnderlayProfile` reference, with an explicit fallback flag/ID because Alpine production art is not present.
2. Extend `NonwalkableSurfaceClassifier.classify()` with CHASM-only boundary flood output `exterior_chasm_cells` and `internal_chasm_cells`; prove this in the focused smoke before integrating presentation.
3. Thread `region_frame_profile_id` through the existing planet-world-profile seam and make current generated worlds default to `alpine_plateau`; retain the narrow Drowned development override.
4. Change `_refresh_depth_backdrop()` to configure the global backdrop from exterior CHASM only and export selected-frame/fallback/exterior/internal/profile telemetry through existing debug/level-data seams.
5. Run focused nonwalkable/underlay/M6 regressions, then docs/index/current-state closeout. Do not touch Archive Resolve or create Alpine art in this workstream.

## Agent Search Budget

Start only from the files named in Evidence/Work surface. Do not inspect general biome generation, campaign lore, renderer batching, or Archive Resolve implementation. Expand only from a focused compile/test failure.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none`
- Root cause / contributing factors: `none`
- Prevention / pipeline improvement: `none`
- Tooling / docs drift discovered: `none`
- Follow-up: `none | fixed-in-scope | <workstream-id> | manual-follow-up`

## Handoff

- Next action: Auto-claim immediately after `review-procgen-distant-chunk-unload-review-corrections-1` completes cleanly; no additional planning refresh is required.
- Best starting files: `nonwalkable_surface_classifier.gd`, `procgen_underlay_profile.gd`, `procgen_depth_backdrop.gd`, `proc_gen_tilemap.gd::_refresh_depth_backdrop`.
- Blockers or open questions: Dependency gate only: cycle-1 M6 correction re-review must pass. Alpine production underlay art is intentionally deferred and is not an RF1 blocker because fallback state is part of RF1 acceptance.
