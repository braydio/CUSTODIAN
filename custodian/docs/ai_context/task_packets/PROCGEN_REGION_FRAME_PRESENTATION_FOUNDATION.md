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
- Reviewed main: `86920fd172d78c8f40cfa6da09acec19b8ed65b8`
- Goal: Add the data-driven Region Frame presentation seam that separates local biome, permanent map-edge/depth presentation, and Archive Resolve, with `ALPINE_PLATEAU` as the first production frame and no change to gameplay surface/collision/navigation authority.
- Completion boundary: Done when one small region-frame profile resource selects permanent underlay/border presentation; final nonwalkable classification exposes a deterministic true-map-exterior CHASM mask distinct from internal chasms without adding a gameplay surface kind; the live depth backdrop is driven by the selected frame and exterior mask instead of the hard-coded `ENDLESS_FOREST` choice; the **current production starting-region `CustodianContractMap` scene explicitly selects `alpine_plateau`**, while the reusable generator class and `PLANET_WORLD_PROFILES` do not globally force or infer Alpine for future regions; Drowned Basilica remains an explicit development/special override; local biome classification and Archive Resolve remain independent; and missing Alpine art falls back explicitly/observably rather than being silently treated as final art.
- Current measured state: `NonwalkableSurfaceClassifier.classify(map_size, floor_cells, surface_claims)` already receives the exact rectangular `map_size` needed for deterministic boundary flooding but currently returns only complete CHASM/OCEAN sets. `ProcgenVoidCliffFace` still uses its own local-component/bounds heuristic rather than a true exterior mask. `ProcGenTilemap._refresh_depth_backdrop()` hard-codes `ENDLESS_FOREST_UNDERLAY` plus the `DROWNED_BASILICA` development override and feeds complete `_chasm_cells`; `apply_planet_world_profile()` does not consume a frame ID. `CustodianContractMap._pick_planet_key()` randomly selects among multiple `PLANET_WORLD_PROFILES` (`terran_wet`, `terran_dry`, `islands`, `ice_world`, `lava_world`, `gas_giant`), and those profiles currently own climate/generation variation only. No live field identifies the **first starting region** as Alpine. Therefore RF1 must add an explicit scene/profile frame selector rather than mapping every planet key or generated contract to Alpine. M6 correction/re-review does not move these owners, so RF1 remains dependency-gated directly on the cycle-1 re-review.
- Evidence: `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md`; `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; `NONWALKABLE_SURFACE_REGIONS.md`; `ELEVATED_WORLD_PRESENTATION.md`; `custodian/game/world/procgen/custodian_contract_map.gd` (`_pick_planet_key`, `_build_planet_world_profile`, `_apply_map_generation_profile`); `custodian_contract_map.tscn`; `terrain/nonwalkable_surface_classifier.gd`; `presentation/procgen_underlay_profile.gd`; `procgen_depth_backdrop.gd`; `procgen_void_cliff_face.gd`; `proc_gen_tilemap.gd` (`apply_planet_world_profile`, `_refresh_depth_backdrop`); current `endless_forest_underlay.tres` / `drowned_basilica_underlay.tres`; `drowned_basilica_underlay_smoke.gd`; nonwalkable/cliff-face smokes.
- Task-specific authority: `PROCGEN_REGION_FRAME_PROFILES.md`; `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; `NONWALKABLE_SURFACE_REGIONS.md`; current `NonwalkableSurfaceClassifier` semantics; `ProcgenUnderlayProfile`; Archive Resolve remains separately governed by `STREAMING_REVEAL_PRESENTATION_V1.md`; reviewed M6 residency behavior is consumed only as a preserved neighboring contract.
- Work surface: Prefer one focused resource owner at `custodian/game/world/procgen/presentation/procgen_region_frame_profile.gd` and profile resources under `presentation/region_frames/`; extend `terrain/nonwalkable_surface_classifier.gd` only with derived exterior/internal CHASM presentation masks; add the explicit starting-region frame selector in `custodian_contract_map.gd` + `custodian_contract_map.tscn` and forward it through `_build_planet_world_profile()`; narrow integration in `proc_gen_tilemap.gd` for profile consumption, mask storage/debug/level-data export and depth-backdrop configuration; reuse `procgen_depth_backdrop.gd` and current `ProcgenUnderlayProfile`; keep `procgen_void_cliff_face.gd` local-cliff behavior unless a tiny adapter is needed to expose/consume the exterior mask. Add one focused region-frame smoke after its path exists and register it in the manifest.
- Change: Introduce a `ProcgenRegionFrameProfile` Resource with at minimum stable `profile_id`, selected `ProcgenUnderlayProfile`, and enough presentation metadata to identify the frame without owning gameplay. Create `alpine_plateau.tres` as the default frame. Until the Alpine underlay Asset V2 family exists, bind the current compatible underlay only as an explicit `visual_fallback`/debug-reported fallback state; do not rename Endless Forest art as Alpine.
- Change: In `NonwalkableSurfaceClassifier`, after CHASM/OCEAN classification, derive `exterior_chasm_cells` by flood-filling **CHASM cells only** from the rectangular map boundary. Derive `internal_chasm_cells = chasm_cells - exterior_chasm_cells`. Return both as deterministic presentation metadata. Do not change `kind_by_cell`, CHASM/OCEAN counts, collision, navigation, floor precedence, or ocean claim semantics.
- Change: Route frame selection through explicit world/profile data, **not planet/climate inference**. Add one exported selector on `CustodianContractMap` (recommended: `region_frame_profile_id: StringName`, empty/default-neutral in reusable code), set the current production `custodian_contract_map.tscn` starting-region instance to `alpine_plateau`, and have `_build_planet_world_profile()` copy that non-empty ID into the generated `world_profile`. `ProcGenTilemap.apply_planet_world_profile()` consumes the ID when present. Do not add `region_frame_profile_id` mappings to each existing `PLANET_WORLD_PROFILES` entry in RF1 and do not derive it from `planet_key`, biome mix, weather, tint, or elevation. Future region/scenario owners may explicitly supply another frame ID. Keep the narrow Drowned Basilica development override without letting it become production frame authority.
- Change: Configure the global `ProcgenDepthBackdrop` from the **exterior CHASM mask**, not complete CHASM semantics. Internal ravines/pits must no longer be what turns on or bounds the permanent lower-world underlay. Keep the backdrop presentation-only and camera-following. Local/internal cliff fascia may remain driven by existing complete chasm/local-component presentation in this foundation; a later art pass may differentiate exterior versus ravine fascia styling.
- Change: Export/debug the selected frame ID, whether fallback art is active, exterior-chasm count, internal-chasm count, and underlay profile ID through existing procgen observability/level-data seams. No frame/state logs per tick.
- Preserve: Exact generated floor/wall/chasm/ocean semantics; Sundered Keep ocean claim behavior; `RuntimeWalkableBoundary`; navigation/collision; M3-M6 streaming lifecycle/residency; local `BiomeField` output; weather; current macro/depth-chunk placement semantics; Archive Resolve ownership; deterministic fingerprints except for newly added presentation/debug metadata.
- Non-goals: No new underlay PNG creation or ingestion; no Archive Resolve implementation; no new gameplay biome; no universal cliff-border rule for future frames; no ocean/coastal frame implementation; no GenerationGrid/decomplexification; no redesign of VoidCliffFace art; no minimap/compass work.
- Acceptance: (1) The current production `custodian_contract_map.tscn` explicitly emits `region_frame_profile_id=alpine_plateau` for the starting region, while the reusable generator class can emit another explicit frame ID and `PLANET_WORLD_PROFILES` remain frame-agnostic; local biome/planet-profile output stays byte/fingerprint-equivalent. (2) A fixture containing one map-edge-connected CHASM and one enclosed CHASM proves only the former enters `exterior_chasm_cells`; both remain structurally CHASM. (3) Ocean cells never leak into the Alpine exterior-CHASM mask. (4) DepthBackdrop visibility/profile is driven by frame + exterior mask, and an internal-only chasm fixture does not activate/bound the global lower-world underlay. (5) Existing Drowned Basilica explicit override still works and does not mutate surface semantics. (6) Missing Alpine production art is reported as fallback state, not silently claimed final. (7) An explicit non-Alpine frame ID can pass through the world-profile seam without being overwritten by `planet_key` or the starting-region scene default, even if only Alpine has a production profile resource in RF1. (8) Archive Resolve and M6 counters/fingerprints are unchanged. (9) S1 quick remains deterministic with the established fingerprint unless an independently justified baseline change landed first.
- Validation: Create the focused RF1 smoke during implementation and register it after the path exists. Run it first: exact boundary-flood exterior vs enclosed CHASM, OCEAN exclusion, `custodian_contract_map.tscn` starting-region selection of `alpine_plateau`, explicit alternate-frame passthrough with no `planet_key` inference, explicit visual-fallback telemetry, Drowned override parity, and DepthBackdrop activation from exterior CHASM only. Then run `procgen_nonwalkable_surface`, `procgen_void_cliff_face`, `procgen_void_cliff_wall_integration`, `drowned_basilica_underlay_smoke.gd`, `elevated_world_asset_contract_smoke.gd`, `procgen_distant_chunk_unload`, `procgen_runtime_health`, candidate materializer parity, S1 quick, changed-file validation and `git diff --check`. Use structured counts/profile IDs before renderer evidence. Permit at most one gameplay-scale capture only if needed to falsify permanent-underlay vs internal-ravine spatial separation; Alpine aesthetic approval remains deferred to the asset packet/human review.
- Task overrides: `none`
- Deferred: Production Alpine FAR/MIDDLE/NEAR art and final visual sign-off live in `procgen-alpine-plateau-underlay-assets`. Other frame profiles remain design catalogue only.

## Recommended Implementation Order

1. Add `procgen_region_frame_profile.gd` and the `alpine_plateau` profile resource using the existing `ProcgenUnderlayProfile` reference, with an explicit fallback flag/ID because Alpine production art is not present.
2. Extend `NonwalkableSurfaceClassifier.classify()` with CHASM-only boundary flood output `exterior_chasm_cells` and `internal_chasm_cells`; prove this in the focused smoke before integrating presentation.
3. Add the explicit `CustodianContractMap` frame selector, set only the current production starting-region scene to `alpine_plateau`, and thread that ID through `_build_planet_world_profile()` -> `ProcGenTilemap.apply_planet_world_profile()`; prove an explicit alternate ID is preserved and never inferred from `planet_key`; retain the narrow Drowned development override.
4. Change `_refresh_depth_backdrop()` to configure the global backdrop from exterior CHASM only and export selected-frame/fallback/exterior/internal/profile telemetry through existing debug/level-data seams.
5. Run focused nonwalkable/underlay/M6 regressions, then docs/index/current-state closeout. Do not touch Archive Resolve or create Alpine art in this workstream.

## Agent Search Budget

Start only from: `custodian_contract_map.gd` (`_pick_planet_key`, `_build_planet_world_profile`, `_apply_map_generation_profile`), `custodian_contract_map.tscn`, `terrain/nonwalkable_surface_classifier.gd`, `presentation/procgen_underlay_profile.gd`, `presentation/procgen_depth_backdrop.gd`, `proc_gen_tilemap.gd` (`apply_planet_world_profile`, `_refresh_depth_backdrop`), and the named focused tests. Do not inspect general biome generation, campaign lore, renderer batching, or Archive Resolve implementation. Expand only from a focused compile/test failure.

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
