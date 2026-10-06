# PROCGEN ALPINE ENVIRONMENT COHESION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-alpine-environment-cohesion-v1`
- Status: `blocked`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `procgen-alpine-plateau-underlay-assets, procgen-alpine-cliff-presentation-v1, procgen-alpine-surface-plates-v1`
- Locks: `procgen-presentation, world-environment, world-lighting`
- Kind: `implementation`
- Review: `manual`
- Review stage: `post-land`
- Review modes: `runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `final environmental hierarchy, weather balance and art cohesion are human-owned subjective decisions after objective runtime checks`
- Reviewed main: `1ef9201f31f108afdfed5065ee736bc101008c23`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Goal: Make the completed Alpine underlay, cliff and playable-surface presentation feel like one environment by tuning and binding the existing deterministic world-environment, world-atmosphere, lighting and foliage-wind authorities rather than creating Alpine-specific duplicate effect systems.
- Completion boundary: Done when AP1/AP2/AP3 are complete; an `alpine_plateau_exterior.tres` lighting/profile baseline is wired through existing profile selection for the starting Region Frame/context; existing procedural snow/mist/fog and shared foliage wind respond coherently to the same environment state; combat/hazard readability remains intact across representative clear/overcast/snow-or-mist conditions; no duplicate atmosphere/wind/precipitation authority is introduced; active docs/required-asset truth is reconciled; and the complete Alpine presentation receives final human visual approval.
- Current measured state: World Environment V1 already owns deterministic `clear`, `overcast`, `light_rain`, `heavy_rain`, `mist`, `dust_wind`, `snow`, and `ashfall` schedules and weather exposure. `WorldAtmosphere2D` is the sole fullscreen environment pass and renders rain/snow/ash/dust below UI. `WorldLightingDirector` composes lighting profiles with day/weather influence. Generated foliage already shares `foliage_life.gdshader`, world-position spatial phase and bounded shrub/tree wind/gust tuning. The live default exterior profile is currently Sundered Keep-oriented until a contract planet or authored zone overrides it. Therefore this Alpine slice requires data/profile integration and tuning, not a second renderer. No additional image assets are required by the manifest; the packet is blocked only because final tuning must occur against AP1/AP2/AP3 production art.
- Evidence: `design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md`; `design/02_features/environment/WORLD_ENVIRONMENT_BIOME_DAYNIGHT_WEATHER.md`; `design/02_features/visuals/WORLD_ATMOSPHERE_SHADER_SYSTEM.md`; `design/02_features/lighting/CUSTODIAN_LIGHTING_SYSTEM.md`; `custodian/game/world/environment/world_environment_director.gd`; `custodian/game/world/lighting/{world_lighting_director.gd,world_atmosphere_2d.gd,world_atmosphere_2d.tscn,shaders/world_atmosphere.gdshader}`; `custodian/game/world/procgen/foliage_life.gdshader`; existing lighting/environment smokes.
- Task-specific authority: World Environment V1; World Atmosphere shader system; CUSTODIAN Lighting System; Region Frame/Alpine visual lock; Alpine presentation manifest; existing foliage wind materials. No new external art authority is introduced.
- Work surface: `custodian/content/lighting/profiles/alpine_plateau_exterior.tres` (new data resource); existing world lighting/environment profile plumbing; minimal Region Frame/world-profile selection seam needed to choose the Alpine exterior baseline; existing atmosphere/foliage material tuning only where data already supports profile/weather influence; focused validation and final visual review.
- Change: Create `custodian/content/lighting/profiles/alpine_plateau_exterior.tres` using the existing `LightingProfile` contract. Target cold diffuse daylight, restrained saturation/contrast, subordinate fog, and strong warm-practical contrast for Custodian infrastructure. Bind that profile through the existing contract/Region Frame/environment selection seam rather than hard-coding Alpine into `WorldLightingDirector`. Preserve day/night and weather modulation. Ensure snow/mist remain rendered through existing `WorldAtmosphere2D`; do not add particle-node precipitation or a second fullscreen pass. Keep foliage on shared `foliage_life.gdshader` and ensure the same environment wind/gust state produces visually compatible foliage and precipitation direction/intensity. Tune fog/snow/mist only enough to support depth without hiding immediate hazards. Optional broad cloud-shadow modulation may be added only if it fits cheaply inside existing lighting/environment authority and requires no new image asset; it is not required for packet closure.
- Preserve: deterministic weather schedule; weather gameplay neutrality; indoor/exposure suppression; UI ungraded; existing authored lighting zones/profiles; Sundered Keep presentation; shared foliage material count; current combat/hazard readability; Region Frame/local-biome separation; Archive Resolve; no per-instance/per-tile environment materials.
- Non-goals: No dynamic snow accumulation, wetness, weather damage, temperature, gameplay penalties, second atmosphere pass, new foliage shader, new required art, dynamic camera pitch, new local biome or broad lighting-system redesign.
- Acceptance: (1) AP1/AP2/AP3 complete with their human art gates; (2) `alpine_plateau_exterior.tres` validates and is selected only for the intended Alpine starting Region Frame/context through existing data plumbing; (3) equal seed/time/environment inputs remain deterministic; (4) snow and mist render only through existing atmosphere authority; (5) foliage remains shared-material based and wind/gust state remains bounded; (6) UI is not graded and indoor exposure behavior remains intact; (7) representative clear/overcast/snow-or-mist captures keep Operator, threats, cliff edge, routes and hazards readable; (8) FAR/MIDDLE/NEAR remain subordinate to gameplay; (9) environment does not create an obvious disagreement between precipitation, foliage and fog motion; (10) no required new art is discovered silently; if a new texture becomes materially required, stop and return to the authoring chat rather than fabricating it; (11) active docs/required-assets state matches runtime; (12) final compact review bundle receives explicit human acceptance of the complete Alpine presentation.
- Validation: Run existing world-environment focused validation, `world_atmosphere_smoke.gd`, `lighting_system_smoke.gd`, affected procgen combat-readability coverage, Region Frame regression, changed-file validation and `git diff --check`. Reuse deterministic state/metrics before renderer evidence. Then publish the smallest final Alpine review set showing interior plateau, multiple exterior directions, hardstand/natural transition and one active weather state. Ask whether the plateau reads as one geographic body, all exterior directions belong to the same world, cliff/ground/underlay integrate, tile cadence is sufficiently suppressed, infrastructure feels embedded in hostile terrain, and environment motion/grade supports rather than competes with gameplay.
- Task overrides: `none`
- Deferred: Dynamic camera projection/vista modes; dynamic accumulation/wetness; additional Region Frames; additional local-biome production vocabulary beyond the approved Alpine closeout.

## Asset Gate

This packet requires **no additional image assets**. It remains blocked until AP1/AP2/AP3 complete because environment tuning must use the final production art. If implementation discovers a genuinely required new texture or animation, stop and return to this authoring chat so the manifest and immutable Dropbox gate can be extended explicitly. Do not create or substitute art inside this packet.

## Documentation Closeout

Reconcile only active truth made stale by the landed continuation. At minimum inspect:

```text
design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md
design/02_features/procgen/ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md
design/02_features/procgen/PROCGEN_REGION_FRAME_PROFILES.md
design/02_features/procgen/ELEVATED_WORLD_PRESENTATION.md
design/02_features/procgen/PROCGEN_MACRO_PRESENTATION_SYSTEM.md
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
design/00_meta/MASTER_ROADMAP.md
custodian/content/metadata/assets/required_assets.registry.json
REQUIRED_ASSETS.md
```

Do not rewrite historical summaries as if the earlier state had never been true.

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
- Follow-up: `none | fixed-in-scope | manual-follow-up`

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh instruction: At claim time, reconcile exact landed AP1/AP2/AP3 profile/resource paths and current environment selection plumbing. The visual/environment contract is already bounded. Escalate to the recorded chat only if a new human-owned art/camera decision or newly required asset is discovered.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: Final human Alpine presentation disposition after the compact visual handoff.
- Blockers or open questions: AP1/AP2/AP3 must complete first; no new image-asset blocker is declared for AP4.