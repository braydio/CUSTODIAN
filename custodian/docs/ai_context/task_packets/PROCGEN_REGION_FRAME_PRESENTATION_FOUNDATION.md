# PROCGEN REGION FRAME PRESENTATION FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-region-frame-presentation-foundation`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-procgen-distant-chunk-unload`
- Locks: `procgen-runtime, procgen-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-procgen-region-frame-presentation-foundation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `fdead30223afa44748e134fe0727772e5b5cfb31`
- Goal: Add the data-driven Region Frame presentation seam that separates local biome, permanent map-edge/depth presentation, and Archive Resolve, with `ALPINE_PLATEAU` as the first production frame and no change to gameplay surface/collision/navigation authority.
- Completion boundary: Done when one small region-frame profile resource selects permanent underlay/border presentation; final nonwalkable classification exposes a deterministic true-map-exterior CHASM mask distinct from internal chasms without adding a new gameplay surface kind; the live depth backdrop is driven by the selected frame and exterior mask instead of the hard-coded production `ENDLESS_FOREST` choice; `ALPINE_PLATEAU` is the current default frame; Drowned Basilica remains an explicit development/special override; local biome classification and Archive Resolve remain independent; and missing Alpine art falls back explicitly/observably rather than being silently treated as final art.
- Current measured state: `NonwalkableSurfaceClassifier.classify()` currently returns complete CHASM/OCEAN sets only. `ProcgenVoidCliffFace._classify_fascia_chasm_cells()` determines component “exterior” relative to the bounding box of all chasm cells and also admits sufficiently large enclosed components, so it is not a true map-exterior mask. `ProcGenTilemap._refresh_depth_backdrop()` hard-codes `ENDLESS_FOREST_UNDERLAY` with a `DROWNED_BASILICA` enum override; `ProcgenDepthBackdrop.configure_from_chasm_cells()` receives complete CHASM semantics and uses them only to establish visibility/bounds for one global FAR/MIDDLE/NEAR camera-following stack. `ProcgenUnderlayProfile` already provides the correct FAR/MIDDLE/NEAR data contract. The first starting-region design now locks `ALPINE_PLATEAU`, but its six production underlay images do not yet exist, so code must expose an explicit compatibility fallback until the Asset V2 family lands.
- Evidence: `design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md`; `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; `NONWALKABLE_SURFACE_REGIONS.md`; `ELEVATED_WORLD_PRESENTATION.md`; `terrain/nonwalkable_surface_classifier.gd`; `presentation/procgen_underlay_profile.gd`; `procgen_depth_backdrop.gd`; `procgen_void_cliff_face.gd`; `proc_gen_tilemap.gd::_refresh_depth_backdrop`; current `endless_forest_underlay.tres` / `drowned_basilica_underlay.tres`; `drowned_basilica_underlay_smoke.gd`; nonwalkable/cliff-face smokes.
- Task-specific authority: `PROCGEN_REGION_FRAME_PROFILES.md`; `ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; `NONWALKABLE_SURFACE_REGIONS.md`; existing nonwalkable surface classifier semantics; Archive Resolve remains separately governed by `STREAMING_REVEAL_PRESENTATION_V1.md`.
- Work surface: Prefer one focused resource owner at `custodian/game/world/procgen/presentation/procgen_region_frame_profile.gd` and profile resources under `presentation/region_frames/`; extend `terrain/nonwalkable_surface_classifier.gd` only with derived exterior/internal CHASM presentation masks; narrow integration in `proc_gen_tilemap.gd` for profile selection, mask storage/debug/level-data export and depth-backdrop configuration; reuse `procgen_depth_backdrop.gd` and current `ProcgenUnderlayProfile`; keep `procgen_void_cliff_face.gd` local-cliff behavior unless a tiny adapter is needed to expose/consume the exterior mask. Add one focused region-frame smoke after its path exists and register it in the manifest.
- Change: Introduce a `ProcgenRegionFrameProfile` Resource with at minimum stable `profile_id`, selected `ProcgenUnderlayProfile`, and enough presentation metadata to identify the frame without owning gameplay. Create `alpine_plateau.tres` as the default frame. Until the Alpine underlay Asset V2 family exists, bind the current compatible underlay only as an explicit `visual_fallback`/debug-reported fallback state; do not rename Endless Forest art as Alpine.
- Change: In `NonwalkableSurfaceClassifier`, after CHASM/OCEAN classification, derive `exterior_chasm_cells` by flood-filling **CHASM cells only** from the rectangular map boundary. Derive `internal_chasm_cells = chasm_cells - exterior_chasm_cells`. Return both as deterministic presentation metadata. Do not change `kind_by_cell`, CHASM/OCEAN counts, collision, navigation, floor precedence, or ocean claim semantics.
- Change: Route production frame selection through world/profile data. `ProcGenTilemap.apply_planet_world_profile()` should consume a stable `region_frame_profile_id` when present and default current generated worlds to `alpine_plateau`. Keep a narrow development override for explicit underlay/frame A/B testing; preserve the existing Drowned Basilica development path without letting it remain the production authority.
- Change: Configure the global `ProcgenDepthBackdrop` from the **exterior CHASM mask**, not complete CHASM semantics. Internal ravines/pits must no longer be what turns on or bounds the permanent lower-world underlay. Keep the backdrop presentation-only and camera-following. Local/internal cliff fascia may remain driven by existing complete chasm/local-component presentation in this foundation; a later art pass may differentiate exterior versus ravine fascia styling.
- Change: Export/debug the selected frame ID, whether fallback art is active, exterior-chasm count, internal-chasm count, and underlay profile ID through existing procgen observability/level-data seams. No frame/state logs per tick.
- Preserve: Exact generated floor/wall/chasm/ocean semantics; Sundered Keep ocean claim behavior; `RuntimeWalkableBoundary`; navigation/collision; M3-M6 streaming lifecycle/residency; local `BiomeField` output; weather; current macro/depth-chunk placement semantics; Archive Resolve ownership; deterministic fingerprints except for newly added presentation/debug metadata.
- Non-goals: No new underlay PNG creation or ingestion; no Archive Resolve implementation; no new gameplay biome; no universal cliff-border rule for future frames; no ocean/coastal frame implementation; no GenerationGrid/decomplexification; no redesign of VoidCliffFace art; no minimap/compass work.
- Acceptance: (1) `ALPINE_PLATEAU` is the default region frame for current generated worlds while local biome output remains byte/fingerprint-equivalent. (2) A fixture containing one map-edge-connected CHASM and one enclosed CHASM proves only the former enters `exterior_chasm_cells`; both remain structurally CHASM. (3) Ocean cells never leak into the Alpine exterior-CHASM mask. (4) DepthBackdrop visibility/profile is driven by frame + exterior mask, and an internal-only chasm fixture does not activate/bound the global lower-world underlay. (5) Existing Drowned Basilica explicit override still works and does not mutate surface semantics. (6) Missing Alpine production art is reported as fallback state, not silently claimed final. (7) Archive Resolve and M6 counters/fingerprints are unchanged. (8) S1 quick remains deterministic with the established fingerprint unless an independently justified baseline change landed first.
- Validation: Add the implementation-created focused region-frame smoke first: boundary flood vs internal chasm, ocean exclusion, frame selection, explicit fallback telemetry, Drowned override parity and underlay activation from exterior only. Then run `procgen_nonwalkable_surface`, `procgen_void_cliff_face`, `procgen_void_cliff_wall_integration`, `drowned_basilica_underlay_smoke.gd`, `elevated_world_asset_contract_smoke.gd`, M6 residency smoke, runtime-health smoke, candidate materializer parity and S1 quick. Use structured counts/profile IDs before any visual capture. One minimal gameplay-scale capture is permitted only to verify the permanent underlay is spatially distinct from internal ravines; aesthetic Alpine approval is deferred to the asset packet/human review.
- Task overrides: `none`
- Deferred: Production Alpine FAR/MIDDLE/NEAR art and final visual sign-off live in `procgen-alpine-plateau-underlay-assets`. Other frame profiles remain design catalogue only.

## Refresh Gate

This packet is intentionally blocked until MR6 finishes.

After a clean/non-blocking-only MR6:

1. fetch current `origin/main`;
2. update `Reviewed main`;
3. confirm M6 request/unload/reload seams did not move the nonwalkable/depth owners named above;
4. remove this section;
5. set `Status: ready`, `Dispatch: auto`.

If MR6 creates a correction cycle, keep this packet blocked until the re-review passes.

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

- Next action: Refresh immediately after clean MR6, then claim this foundation independently of D1-D3.
- Best starting files: `nonwalkable_surface_classifier.gd`, `procgen_underlay_profile.gd`, `procgen_depth_backdrop.gd`, `proc_gen_tilemap.gd::_refresh_depth_backdrop`.
- Blockers or open questions: MR6 review gate only. Alpine production underlay art is intentionally deferred.
