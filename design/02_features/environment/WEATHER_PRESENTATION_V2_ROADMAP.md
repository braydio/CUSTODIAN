# CUSTODIAN | Weather V2: Atmospheric Presentation Expansion | Full Buildout Roadmap V1

**Status:** approved program design and authored task-packet sequence; no production implementation or art approval implied.  
**Audit baseline:** braydio/CUSTODIAN main@ebfe3810eec146d7202a4378324b0f32c9e12fee (2026-11-08).  
**Authoring chat:** not-recorded (replace only with the exact user-supplied current conversation URL).  
**Implementation scope:** A comprehensive presentation expansion of the current deterministic weather ecosystem. Preserve the schedule, biome, gameplay and lighting authorities while vastly improving weather depth, motion, local responses and configurability.

## Verified starting condition

WorldEnvironmentDirector owns 1440-second day, seeded 8-state weather schedule (90–240s holds, 8–15s transitions) and weather/indoor exposure. WorldLightingDirector composes base profiles and weather. WorldAtmosphere2D owns one fullscreen world pass; shader uses TIME for visual motion and currently gives precipitation mostly one procedural layer. WorldEnvironment V1 excludes puddles, lightning and accumulation. Existing static world-atmosphere and environment smokes protect this.

## Intended gameplay/presentation payoff and operating mechanics

1. Add a versioned weather-presentation profile/config layer: climate/region/zone biases, far/mid/near density, opacity, streak scale, snow drift, dust streak, fog altitude and weather quality tier. The existing eight weather IDs and their deterministic transition ownership stay unchanged.
2. Make visual phase, seed and wind vectors explicit read-only projections of the environment contract/clock with world-space stability. Presentation noise is independently hashed by spatial coordinates, does not consume the gameplay RNG or decide weather events, and is testable at fixed as-of samples.
3. Within the existing one fullscreen WorldAtmosphere2D world pass, render three depth behaviors or a measured equivalent: far veils, middle falling particles and near contact streaks. Screen/wind/camera motion preserve world anchoring and actor/hazard readability; UI remains above all weather.
4. Art-direct all eight states: clear (sparse airborne dust/high contrast), overcast (moving soft cloud shadow), light_rain (gentle fine streaks), heavy_rain (angular multi-depth rain and gusts), mist (low moving banks/depth fade), dust_wind (horizontal gritty sheets), snow (slow drift with gust variability), ashfall (dark floating particulate). All tune with the existing lighting profile.
5. Add bounded world-local cosmetic responses as a separately owned consumer: rain splash/ripple on valid exposed ground, windblown snow/ash eddies at obstacles, occasional directional lightning plus thunder where design allows. Do not mutate TileMap terrain, material gameplay modifiers, water levels or collision. Use existing audio and lighting commands, never create a second music/weather state owner.
6. Add a Weather Lab for fixed weather/time/seed camera-position test scenes, A/B current vs V2, lighting/haze/precipitation isolation toggles, performance/quality metrics and reproducible review captures. Enable legacy off / quality-low fallback and preserve the core shader path when effects are disabled.

## Core boundaries

**Preserve:** Eight IDs, existing world profile weights, schedule/timing, fixed-step simulation, authored zone lighting, weather neutrality for gameplay, indoor visibility/weather exposure, shared foliage wind/material variants, existing layer ordering and atmosphere singleton, generated procgen map acceptance and weather director ownership.

**Explicit non-goals:** No climate sim reboot, no second weather director, no global weather damage, no physically accumulated snow/surface wetness state, no replacing lighting profiles, no breakage of Alpine profile or other existing locked art integration.

**Measure success:** At equal contract seed and fixed game time, weather schedule and lighting modifiers remain unchanged from V1. In 1280x720 test scenes, the new weather is visibly multi-depth and spatially stable in camera pan, with indoor mask response and UI preserved. Establish current p50/p95 GPU + CPU baseline before choosing quality thresholds. Low quality should stay close to V1 cost; full quality must have measured and accepted budget. Final artistic signoff is required on clear/rain/snow/mist/ash/dust samples.

**Art / Asset Pipeline V2:** No new PNGs required for the first four weather slices: use procedural shader, reusable node-generated ripples and existing lighting/audio assets. A future bespoke precipitation texture/particle sprite enters a separately reviewed Asset V2 family after source and size contracts are locked; do not fabricate a family or leave source only in chat.

**Human-owned review:** Final A/B must approve cinematic improvement without losing target visibility, native pixel integrity, or region identity; subjective visual approval must not be inferred from a shader compiling or headless smokes.

## Dependency DAG and staged production

| Slice | Workstream ID | Deliverable | Depends on review | Visual decision |
|---|---|---|---|---|
| 1 | weather-v2-presentation-contract-v1 | Profiles, deterministic sample time and baseline | none | conditional |
| 2 | weather-v2-layered-precipitation-v1 | Deep weather rendering and wind coherence | review-weather-v2-presentation-contract-v1 | conditional |
| 3 | weather-v2-surface-events-v1 | Local contact, gust and lightning presentation | review-weather-v2-layered-precipitation-v1 | conditional |
| 4 | weather-v2-polish-tooling-v1 | Weather Lab, quality tiers and final style approval | review-weather-v2-surface-events-v1 | required |

### 1. Profiles, deterministic sample time and baseline

**Implementation:** weather-v2-presentation-contract-v1  
**Independent review:** review-weather-v2-presentation-contract-v1  
**Dependency:** none  
**Primary locks:** weather-profile, world-environment  
**Priority:** P1

**Change:** Build a data/config-driven visual profile with explicit quality fallback, climate/zone overrides and stable visual time/seed/wind. Extend only the presentation state contract where needed, with no weather schedule or biome changes. Add deterministic state fixtures and profile compatibility/legacy-off tests; measure p50/p95 baseline on one representative scene.

**Acceptance:** At equal contract seed/step sequence, V1 weather IDs, transition sequence, director lighting modifiers and indoor exposure remain byte/semantically identical; absent profile invokes exact current V1 rendering; visual sampling stable across camera paths/pause policy; baseline cost documented.

**Validation:** custodian/tools/validation/world_environment_smoke.gd; custodian/tools/validation/world_atmosphere_smoke.gd; custodian/tools/validation/lighting_system_smoke.gd; new weather V2 profile/sampling/baseline fixture; changed-file validation.

**Next deferred:** New precipitation layers, surface contact and artistic tuning.

### 2. Deep weather rendering and wind coherence

**Implementation:** weather-v2-layered-precipitation-v1  
**Independent review:** review-weather-v2-layered-precipitation-v1  
**Dependency:** review-weather-v2-presentation-contract-v1  
**Primary locks:** world-atmosphere, weather-presentation  
**Priority:** P1

**Change:** Implement opt-in far/mid/near weather patterns per state, spatially stable world-space rain/snow/ash/dust, depth-aware fog and gust direction consistent with foliage. Honor exposure/weather influence, source camera zoom, pixel snapping and quality tiers. Preserve no-effects shader fallback and avoid noisy shader loops.

**Acceptance:** At a fixed seed/time/camera, V2 render is reproducible with distinct far/mid/near signatures; moving camera does not drag the weather screen grid; near combat zone remains readable, UI ungraded, indoor suppression preserved, no extra fullscreen pass or per-tile weather materials.

**Validation:** custodian/tools/validation/world_environment_smoke.gd; custodian/tools/validation/world_atmosphere_smoke.gd; new layered shader uniform/region/camera regression and frame-cost measurements; changed-file validation.

**Next deferred:** Contact splashes, lightning/thunder and Weather Lab full UI.

### 3. Local contact, gust and lightning presentation

**Implementation:** weather-v2-surface-events-v1  
**Independent review:** review-weather-v2-surface-events-v1  
**Dependency:** review-weather-v2-layered-precipitation-v1  
**Primary locks:** weather-surface-presentation, world-lighting-presentation  
**Priority:** P1

**Change:** Add bounded exposed-ground rain contact splashes, transient ripples without water gameplay, snow/ash/dust eddies at authored static occluders and weather-dependent ambience routed through existing audio ownership. Lightning in an eligible existing rain state is seeded cosmetic event timing and uses existing temporary-flash API, with optional thunder delayed by authored distance and quality/accessibility gates. Respect indoor clipping, fade/cleanup, offscreen interest and pause behavior.

**Acceptance:** No TileMap semantics, nav, water/temperature or damage changes; event positions are valid exposed locations and deterministic for fixed input; scene transitions cleanup, indoor zero exposure suppresses local rain; lightning does not interrupt combat lighting authority or overlay UI; mute/reduced-flash option works.

**Validation:** custodian/tools/validation/world_environment_smoke.gd; custodian/tools/validation/world_atmosphere_smoke.gd; custodian/tools/validation/lighting_system_smoke.gd; new weather event lifecycle/accessibility/seed smoke; changed-file validation.

**Next deferred:** Long-lived physical snow, wetness affecting traction, puddle navigation or storm damage.

### 4. Weather Lab, quality tiers and final style approval

**Implementation:** weather-v2-polish-tooling-v1  
**Independent review:** review-weather-v2-polish-tooling-v1  
**Dependency:** review-weather-v2-surface-events-v1  
**Primary locks:** weather-workbench, world-atmosphere  
**Priority:** P1

**Change:** Provide weather/time/seed/zone presets, before/after toggle, ROI capture metadata, adaptive low/medium/high quality controls, stable default settings, performance counters and inspectable effect budget. Prove clear, overcast, rain, mist, snow, dust and ash; test indoor, cinematics and combat. Coordinate rope-cloth winds only if that library independently landed; no hard dependency. Update authoritative docs and clear stale V1-as-current wording without rewriting history.

**Acceptance:** One reproducible dev gallery covers eight states and transitions; baseline CPU/GPU and quality tier tradeoffs documented; no normal gameplay change; low/off matches legacy policy, no per-frame telemetry flood; user accepts final style on representative keyframes/short motion loops.

**Validation:** custodian/tools/validation/world_environment_smoke.gd; custodian/tools/validation/world_atmosphere_smoke.gd; custodian/tools/validation/lighting_system_smoke.gd; new Weather Lab scene/state/quality regression and representative measured profile; changed-file validation.

**Next deferred:** Future gameplay wetness/accumulation/damage and biome-specific simulation remain separate proposals.

## Eight-state weather visual vocabulary

| Existing weather ID | V2 presentation target |
|---|---|
| clear | Restrained particle motes and broad sunlight variation; no false precipitation |
| overcast | Moving diffuse cloud shadow and deep gray aerial perspective |
| light_rain | Fine distant slant, little near clutter and occasional ground contact |
| heavy_rain | Far curtain + mid streak + near bursts, gust direction, lightning only when allowed |
| mist | Ground-hugging drifting veils that preserve short-range threats |
| dust_wind | Horizontal sheets and occasional bounded eddies, no global sand physics |
| snow | Near/far flakes at distinct speeds, gentle swirl, no accumulation gameplay |
| ashfall | Slow dark ash, sparse warm flecks, muted layering |

## Integration and file ownership

- New library code and tests are **planned outputs**, not already published runtime features. Workstream packets name the recommended repository-relative owners and exact focused baselines.
- Required inputs for each packet are this document plus the current-main source owners named in its Evidence section; no chat-only schemas, reference ZIPs or art are needed to claim the first slice.
- Every implementation stage gets a separate post-land fresh-context review. The implementation workstream does not self-approve its review. Only the first implementation/review pair opts in to automatic authoring preflight; successors remain draft/manual pending predecessor review and a refreshed repository/claim audit.
- Before any new production texture, family or runtime art route, inspect design/04_architecture/ASSET_PIPELINE_V2.md, the registered family schema and the actual consumer. New art requires source/alpha/dimension/animation contracts, human review, and explicit source_work/inbox routing.
- Deterministic tests and source/geometry/contracts precede visual inspection. Material aesthetic decisions require a minimal ROI/short-motion handoff. The default is no new full-screen recording or unnecessary LFS generation.

## Documentation drift and change hygiene

V1 world-environment spec intentionally excludes lightning, puddles and gameplay wetness. Keep that factual as a V1 scope statement; when V2 local cosmetic events land, explicitly document they are presentation-only, not a contradiction or new gameplay authority. COMBAT_FEEL_UPGRADE and older art docs must not be reused as current weather authority.

This document is a forward plan, not a claim that every planned stage is implemented. On each stage closeout, reconcile impacted live design, CURRENT_STATE.md, FILE_INDEX.md, actual code, test ownership and asset registry truth. Do not rewrite unrelated historical state or bypass independent reviews.

## Release / stop conditions

1. Never assume a partial implementation is ready/auto without the current packet authoring preflight and remote publication receipts.
2. The review of every stage must archive PASS before the dependent stage becomes claimable. A review finding keeps the original workstream identity and enters its bounded correction/re-review lifecycle.
3. A human/ChatGPT visual decision is mandatory for final subjective polish; technical PASS does not imply aesthetic approval.
4. If a new runtime gameplay authority, unapproved art family, or incompatible schema is necessary, stop and return the smallest explicit decision/proof to the authoring chat instead of silently inventing ownership.
