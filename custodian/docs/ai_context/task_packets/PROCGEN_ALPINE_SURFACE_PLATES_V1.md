# PROCGEN ALPINE SURFACE PLATES V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-alpine-surface-plates-v1`
- Status: `blocked`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-alpine-cliff-presentation-v1`
- Locks: `procgen-presentation, asset-pipeline`
- Kind: `implementation`
- Review: `manual`
- Review stage: `post-land`
- Review modes: `asset-pipeline, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `large authored presentation plates require objective semantic checks plus final human gameplay-scale composition approval`
- Reviewed base: `78bb7b865948a2a342017993f5b98c4b795d1f6e`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Goal: Use the existing Macro Presentation system to suppress the exposed 32 px “chessboard” read with large authored Rocky Upland and Meridian Hardstand compositions while leaving gameplay tiles, semantic masks, collision/navigation, biome, roads and elevation as the sole gameplay authorities.
- Completion boundary: Done when the two registered approved source-master batches (`rocky-upland-10-source-family-v1` and `meridian-hardstand-6-source-family-v1`) are fetched and verified; the existing `procgen_surface_rocky_upland` family gains the 10 manifest states and `procgen_surface_meridian_hardstand` gains the six manifest states through Asset Pipeline V2; each state has a validated `TerrainStampProfile` with explicit semantic masks/eligibility; the existing catalog/composer deterministically places the new vocabulary without semantic mutation; streaming/materializer parity remains green; representative natural/hardstand gameplay views no longer read primarily as exposed tiled cells or rectangular presentation patches; and compact human review accepts the integration.
- Current measured state: Production already has 10 Rocky Upland macro states and 10 Meridian Hardstand macro states. `ProcgenMacroPresentationComposer`, `TerrainRegionExtractor`, `TerrainStampPlacer`, `TerrainStampProfile` and `terrain_stamp_catalog_v1.tres` own deterministic presentation-only macro placement. `TerrainStampProfile` already supports explicit solid/walkable masks, placement domain, allowed region kinds, required biome, surface-material filters, depth band, weights, reveal probes and per-map caps. Therefore this continuation should extend those existing families/catalogs rather than invent an Alpine compositor. The AP3 image-art requirement is now complete in Dropbox as two approved source-master batches: Rocky Upland 10 and Meridian Hardstand 6. AP3 remains dependency-gated behind AP2 on live main. The final Gate C runtime handoff is intentionally not present yet because AP3 produces it after normalization, profile wiring and validation.
- Evidence: `design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md`; `PROCGEN_MACRO_PRESENTATION_SYSTEM.md`; `SURFACE_MATERIALS_V1.md`; `custodian/content/metadata/assets/families/{procgen_surface_rocky_upland,procgen_surface_meridian_hardstand}.asset.json`; `custodian/game/world/procgen/presentation/{procgen_macro_presentation_composer,terrain_region_extractor,terrain_stamp_placer,terrain_stamp_profile,terrain_stamp_catalog}.gd`; `custodian/content/procgen/presentation/terrain_stamp_catalog_v1.tres`; existing macro/surface smokes.
- Task-specific authority: Alpine presentation manifest; Macro Presentation; Surface Materials; existing Rocky Upland and Meridian hardstand Asset V2 families; Asset Pipeline V2; `IMPLEMENTATION_HANDOFF.md`; `VISUAL_REVIEW_HANDOFF.md`.
- Work surface: Existing family metadata; runtime domains `content/tiles/procgen_macro/runtime/{rocky_upland,meridian_hardstand}/`; new matching profiles under `content/procgen/presentation/surface/{rocky_upland,meridian_hardstand}/`; `terrain_stamp_catalog_v1.tres`; existing extractor/placer/composer only where the approved assets prove a narrow integration gap; focused validation and representative Moment Forge/gameplay evidence.
- Change: Extend `procgen_surface_rocky_upland` with exactly the 10 manifest states and `procgen_surface_meridian_hardstand` with exactly the six manifest states; preserve every existing state. Create matching `TerrainStampProfile` resources with exact `canvas_px`, pivot, footprint, semantic masks, reveal probes, region/biome/material eligibility, weight and `max_instances_per_map`. Use `required_biome`, `allowed_surface_materials`, `walkable_overlay_cells`, `solid_mask_cells` and current placement domains instead of alpha-derived assumptions. PNG alpha remains presentation only. Rocky plates should create broad quiet natural compositions, snow/scree/fracture continuity and irregular boundaries over already-authoritative floor. Meridian Alpine plates should visibly interlock slabs/roads/aprons with rock, snow, retaining work and drainage while consuming the existing hardstand material seam. If the approved plate geometry cannot be expressed by existing region extraction/placement contracts, make the smallest extension to those authorities; do not add another composer.
- Preserve: Native 32 px semantic authority; accepted-seed determinism; current 20 production macro states; Floor TileMap authority; Surface Materials V1; Meridian hardstand classification; Road Semantics V2; route/combat/ingress clearances; biome field; terrain/elevation; collision/navigation; dressing/foliage policy; streaming reveal; missing-art fallback behavior for unrelated families.
- Non-goals: No gameplay-tile replacement; no topology or route redesign; no road-generation rewrite; no biome-distribution rewrite; no cliff/underlay work; no weather-system changes; no alpha-derived collision; no general procgen renderer redesign.
- Acceptance: (1) exact Gate C handoff verifies 16 expected PNGs, hashes, sizes, dimensions and authoring chat; (2) both existing Asset V2 families are extended without renaming/removing prior states; (3) all new states are ingested/bound/verified and every production texture has a valid corresponding `TerrainStampProfile`; (4) profile masks/eligibility are explicit data and no presentation planner mutates semantic input; (5) same semantic input/seed gives a stable plan fingerprint; (6) direct-final and accepted-candidate materialization agree; (7) streaming unload/reveal reproduces the same composition; (8) route/playability/surface-material audits remain green; (9) representative Rocky Upland and Alpine hardstand captures suppress dominant grid repetition at normal gameplay scale; (10) transitions do not read as obvious rectangles; (11) Operator/threat/hazard readability remains above surface detail; (12) final compact human review accepts plate density, scale and integration.
- Validation: Fetch and verify both registered source-master ZIPs before mutation; stage/extract outside the checkout and verify package/internal checksums. Normalize through current Asset Pipeline V2 tooling, author/verify profiles, then at AP3 closeout publish/fetch the exact 16-state Gate C handoff with `implementation_handoff.py`. Run live Asset V2 family plan/status/doctor. Run `procgen_macro_presentation_smoke.gd`, `procgen_surface_material_smoke.gd`, directly affected road/route-clearance checks, candidate-materializer parity, streaming/reveal parity, changed-file validation and `git diff --check`. Add profile-contract tests for every new resource and focused fixed-seed assertions that new plate placement remains bounded. Only after objective checks pass, publish the smallest representative natural/hardstand gameplay evidence set through `publish_review_artifacts.py --important` and ask whether tile cadence is sufficiently suppressed without obscuring gameplay or making the world over-authored.
- Task overrides: `none`
- Deferred: Environment/weather/lighting cohesion is `procgen-alpine-environment-cohesion-v1`; additional local-biome production vocabularies beyond this Alpine closeout remain governed by Macro Presentation roadmap; dynamic camera treatment remains separate.

## Required External Input — Approved Surface Source Masters

AP3's image-art input is complete as two registered Dropbox source-master batches.

### Rocky Upland 10

```text
CUSTODIAN/asset_batches/procgen-alpine-presentation/
  rocky-upland-10-source-family-v1/
    custodian_rocky_upland_10_asset_handoff_v1.zip
```

ZIP SHA-256:

```text
c47718b7f1e94eb67cbb647fdc3c38f81b20fa5a0b44e33de89137b9d62bbfdf
```

### Meridian Hardstand 6

```text
CUSTODIAN/asset_batches/procgen-alpine-presentation/
  meridian-hardstand-6-source-family-v1/
    custodian_meridian_hardstand_6_asset_handoff_v1.zip
```

ZIP SHA-256:

```text
ac3af79bb216d6abf678482149301410071a3d583b2917938ebf5885b6212e2d
```

Dropbox discovery authority:

```text
CUSTODIAN/asset_batches/_registry/
custodian/docs/ai_context/DROPBOX_ASSET_BATCH_REGISTRY.md
```

Together these two batches contain the approved high-resolution source masters for all 16 AP3 states. They are source authority, not final runtime canvases. Codex must preserve them into the declared Asset V2 source-work roots, normalize exact target canvases through current project tooling, author explicit `TerrainStampProfile` resources/masks, extend the two existing families, register the profiles in the existing catalog, and validate deterministic placement.

AP3 is still dependency-gated behind `procgen-alpine-cliff-presentation-v1`. The art is no longer a blocker.

### AP3 closeout Gate C

After AP2 clears and AP3 completes normalization/wiring/objective validation, AP3 publishes/verifies:

```text
CUSTODIAN/implementation_inputs/
  procgen-alpine-surface-plates-v1/
    alpine-surface-plates-v1/
      HANDOFF_MANIFEST.json
      payload/
        procgen_surface_rocky_upland/         # 10 final PNGs
        procgen_surface_meridian_hardstand/   # 6 final PNGs
```

Exactly 16 final PNGs. The handoff manifest must use `custodian.implementation_handoff.v1` and record the exact authoring chat URL. Gate C is the AP3 closeout/downstream receipt, not a prerequisite source-art handoff.

Do not substitute visual-review media, arbitrary local files, older generations, or generated placeholders.

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
- Follow-up: `none | fixed-in-scope | procgen-alpine-environment-cohesion-v1 | manual-follow-up`

## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh instruction: No design refresh is required if AP2 lands within contract and both registered source-master batches/checksums match this packet. Re-derive exact live catalog/profile APIs before mutation. Escalate only if landed macro ownership or the supplied approved art introduces a new material placement/semantic decision.

## Handoff

- Next workstream: `procgen-alpine-environment-cohesion-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: After AP3 completes, run the environment-cohesion slice against settled production art.
- Blockers or open questions: AP2 must complete first. The AP3 image-art requirement is complete and registered; Gate C is produced at AP3 closeout.