# Alpine Plateau Presentation Asset Manifest

**Status:** locked continuation manifest  
**Date:** 2026-10-06  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d  
**Reviewed base:** `braydio/CUSTODIAN` `main@b086e552de00cea8551d62884c996558d33f12e6`  
**Scope:** believable production presentation for the first generated `ALPINE_PLATEAU` Region Frame  
**Asset authority:** Asset Pipeline V2 family contracts remain canonical for runtime routing and naming.

## Purpose

This manifest continues the existing Alpine Plateau Region Frame and underlay work. The first six-state underlay pass proved the Region Frame seam, presentation-only FAR/MIDDLE/NEAR ownership, deterministic A/B selection, Asset Pipeline V2 publication path, exterior-only depth presentation, and Moment Forge review workflow. The continuation keeps those authorities and closes the remaining visual integration gap.

The production target is one coherent elevated alpine world:

1. the permanent underlay is compatible with the existing top-down gameplay camera in every exterior direction;
2. the exterior cliff reads as geological terrain rather than a repeated tile fascia;
3. the playable upper plane reads as large authored terrain rather than exposed 32 px cell structure;
4. hardened infrastructure visibly interlocks with the mountain rather than floating on it;
5. local depth, weather, lighting and foliage motion share one environmental composition.

Gameplay floor, collision, navigation, biome, elevation, road and streaming authority remain unchanged.

## Projection Contract

The normal gameplay camera remains the existing `Camera2D`. No dynamic camera pitch or 3D conversion is required here.

All Alpine presentation art must imply an elevated aerial-oblique projection compatible with unrestricted top-down traversal:

- no conventional horizon line tied to screen-bottom;
- no composition that only works when the exterior edge lies south of the player;
- distant terrain reads as geographically below the playable plateau;
- north, east, south and west exterior edges remain believable;
- perspective remains compatible with current Operator, prop and gameplay-tile presentation;
- FAR terrain is visibly non-navigable;
- gameplay plane remains the strongest readability authority.

Directional cinematic/vista camera treatment is deferred to a separate future feature.

## Required Production Inventory

**Total required new or revised image states: 48.**

| Family | Action | Required states |
| --- | --- | ---: |
| `procgen_underlay_alpine_plateau` | revise existing | 6 |
| `procgen_alpine_cliff_fascia` | new | 12 |
| `procgen_alpine_cliff_contact` | new | 10 |
| `procgen_depth_chunks` | extend existing | 4 |
| `procgen_surface_rocky_upland` | extend existing | 10 |
| `procgen_surface_meridian_hardstand` | extend existing | 6 |

No additional snow-particle, fog-particle or foliage-wind sprite family is required. Existing `WorldAtmosphere2D`, deterministic weather, `WorldLightingDirector`, and shared foliage wind materials remain authority.

---

## Family A — `procgen_underlay_alpine_plateau`

**Action:** retain and revise the existing family. Do not create a replacement Alpine underlay family.

- metadata: `custodian/content/metadata/assets/families/procgen_underlay_alpine_plateau.asset.json`
- runtime: `custodian/content/backgrounds/procgen/alpine_plateau/`
- source-work: `custodian/asset_drop/source_work/procgen/procgen_underlay_alpine_plateau/`
- inbox: `custodian/asset_drop/inbox/procgen_underlay_alpine_plateau/`
- canvas: `1536×1024`
- format: RGBA PNG, true alpha, one static frame per state
- direction policy: `omni`

### Required states

| State | Size | Role |
| --- | ---: | --- |
| `far_world_a` | 1536×1024 | aerial-oblique lower mountain world A |
| `far_world_b` | 1536×1024 | aerial-oblique lower mountain world B |
| `depth_fog_a` | 1536×1024 | irregular cloud/fog shelf A |
| `depth_fog_b` | 1536×1024 | irregular cloud/fog shelf B |
| `near_cliff_mist_a` | 1536×1024 | cliff-root mist / descending terrain A |
| `near_cliff_mist_b` | 1536×1024 | cliff-root mist / descending terrain B |

Exact source-work names:

```text
far_world_a_source.png
far_world_b_source.png
depth_fog_a_source.png
depth_fog_b_source.png
near_cliff_mist_a_source.png
near_cliff_mist_b_source.png
```

Exact inbox names:

```text
far_world_a.png
far_world_b.png
depth_fog_a.png
depth_fog_b.png
near_cliff_mist_a.png
near_cliff_mist_b.png
```

### FAR requirements

Use lower ridges, forested valleys, snow-banded slopes, large rock masses, extremely subordinate ruined infrastructure, and atmospheric occlusion. Do not include a conventional landscape horizon, bottom-screen-only vista, readable second combat map, or high-frequency microdetail competing with actors.

### MIDDLE requirements

Use broad valley cloud/fog with large irregular transparent openings, variable density and scale, and enough opacity to hide lower cliff termination. Fog must occupy the composition rather than forming a simple bottom strip.

### NEAR requirements

Bridge world-space cliff art into depth with low mist, partial rock ledges, descending conifer silhouettes, occasional retaining/ruin fragments and fog occlusion. No hard lower boundary may be visible.

---

## Alpine Cliff Source-Master Pipeline

AP1 is now complete/landed. AP2 uses a reviewed high-resolution source-master family rather than requiring image generation to emit final runtime canvases directly.

Canonical active Dropbox batch:

```text
batch_id: alpine-cliff-source-family-v1
CUSTODIAN/asset_batches/procgen-alpine-presentation/alpine-cliff-source-family-v1/
custodian_alpine_cliff_source_family_v1.zip
SHA-256 e804c5d9d55f0610cafde5f4169a6b36438b0e08469b212ac3fff84618b127f3
```

Discovery/registry authority:

```text
CUSTODIAN/asset_batches/_registry/
custodian/docs/ai_context/DROPBOX_ASSET_BATCH_REGISTRY.md
```

The source package contains 12 approved high-resolution masters:

### Fascia source masters

```text
body_strata_01_source.png
body_strata_02_source.png
body_cracked_01_source.png
body_snow_streak_01_source.png
body_rooted_01_source.png
body_retaining_01_source.png
bottom_mist_01_source.png
bottom_mist_broken_01_source.png
```

These are source authority for the eight body/bottom fascia states. The four `top_*` runtime fascia states are derived from appropriate crown regions of the approved large contact masters so the crown/fascia/contact art remains one geological family.

### Large contact/source masters

```text
contact_natural_plateau_master_source.png
contact_industrial_master_source.png
contact_vegetated_broken_master_source.png
contact_clean_granite_master_source.png
```

These are high-detail 2.5D gray-granite authority for crown, directional contact and depth-chunk derivation. They are not final contact canvases and must not be nonuniformly squashed into target aspect ratios.

### Locked source-master style

- high-detail CUSTODIAN 2.5D realistic presentation;
- cold neutral gray columnar granite;
- restrained warm mineral weathering only;
- dirty sparse snow, scree, alpine scrub/conifers;
- weathered Custodian retaining infrastructure embedded in geology and kept rare/subordinate;
- no purple/lavender fallback cliff language;
- final fascia must look like selected/cropped fragments of the same large geological plates.

### Derivation rule

High-resolution source masters may exceed runtime dimensions. Runtime dimensions in Families B/C/D remain exact output contracts.

For fascia:

```text
source master
  -> crop/select one semantic geological fragment
  -> project pixel-art resizer/normalizer
  -> explicit alpha cleanup
  -> exact runtime state
  -> assembled 4–8 tile repetition test
  -> Asset V2 publication
```

For contact/depth assets:

```text
source master
  -> crop/recompose for required direction/role
  -> preserve projection and lighting
  -> exact target canvas
  -> explicit alpha cleanup
  -> deterministic placement review
  -> Asset V2 publication
```

Do not use generic smooth interpolation, nonuniform stretching, or PNG alpha as gameplay authority. Solid geology/structure should normalize to alpha 255; exterior/background to alpha 0; partial alpha is reserved for intentional mist/fog transitions.

The source package is sufficient to begin AP2 derivation. The final 26-state Gate B handoff is an AP2 **output/closeout receipt**, not a prerequisite that must already exist before Codex can claim AP2.

---

## Family B — `procgen_alpine_cliff_fascia`

**Action:** new frame-specific Asset Pipeline V2 family. It supplements rather than replaces the generic `void_cliff_face` fallback.

- schema: `custodian.asset_family.v2`
- kind: `tile`
- metadata target: `custodian/content/metadata/assets/families/procgen_alpine_cliff_fascia.asset.json`
- runtime domain: `custodian/content/tiles/mountain_cliffs/alpine_fascia/`
- owner: `alpine_plateau`
- source-work: `custodian/asset_drop/source_work/procgen/procgen_alpine_cliff_fascia/`
- inbox: `custodian/asset_drop/inbox/procgen_alpine_cliff_fascia/`
- **runtime canvas:** `32×32`
- approved source masters may be higher resolution and are normalized/derived through the source-master pipeline above
- one frame per runtime state, RGBA, true alpha
- direction policy: `omni`
- auto mirror: `false`

### Required states

```text
top_clean_01
top_broken_01
top_snow_01
top_retained_01
body_strata_01
body_strata_02
body_cracked_01
body_snow_streak_01
body_rooted_01
body_retaining_01
bottom_mist_01
bottom_mist_broken_01
```

Final source-work/runtime derivations use `<state>_source.png` / `<state>.png` naming as appropriate. The active Dropbox source-master package uses the canonical source filenames listed in the Source-Master Pipeline section; Codex maps those masters to final semantic states before Asset V2 intake.

### Material lock

Use charcoal/blue-gray granite, cold shadow, muted earth fractures, dirty off-white snow, restrained lichen and occasional infrastructure staining. Avoid saturated purple, bright fantasy stone and uniform tile-edge outlines.

`top_*` anchors the upper playable plane and varies crown fracture/snow/retaining integration. `body_*` provides clustered vertical variation without conspicuous horizontal seams. `bottom_*` dissolves into cloud/mist and must not terminate on a hard visible line.

---

## Family C — `procgen_alpine_cliff_contact`

**Action:** new large world-space edge/contact Asset Pipeline V2 family. These compositions break visible 32 px fascia rhythm and visually attach the upper plane to the cliff.

- schema: `custodian.asset_family.v2`
- kind: `backdrop`
- metadata target: `custodian/content/metadata/assets/families/procgen_alpine_cliff_contact.asset.json`
- runtime domain: `custodian/content/tiles/procgen_macro/runtime/alpine_cliff_contact/`
- owner: `alpine_plateau`
- source-work: `custodian/asset_drop/source_work/procgen/procgen_alpine_cliff_contact/`
- inbox: `custodian/asset_drop/inbox/procgen_alpine_cliff_contact/`
- all states static, one frame, RGBA, true alpha

### Required states

| State | Size |
| --- | ---: |
| `south_broad_01` | 1024×512 |
| `south_broken_01` | 1024×512 |
| `south_rooted_01` | 1024×512 |
| `east_broad_01` | 512×1024 |
| `west_broad_01` | 512×1024 |
| `north_broad_01` | 1024×320 |
| `corner_se_01` | 768×768 |
| `corner_sw_01` | 768×768 |
| `corner_ne_01` | 768×768 |
| `corner_nw_01` | 768×768 |

Source-work filenames use `<state>_source.png`; inbox filenames use `<state>.png`.

Allowed content: contact shadow, fractured crown stone, scree, snow overhang/streaking, exposed roots, sparse cliff vegetation, broken retaining masonry, and ledges disappearing into fog. Directional compositions intentionally differ: south may expose the deepest face, east/west intermediate depth, north the shallowest/crown-dominant read.

PNG alpha is presentation only and must never be used to infer gameplay collision or traversal masks.

---

## Family D — `procgen_depth_chunks`

**Action:** extend the existing family.

- metadata: `custodian/content/metadata/assets/families/procgen_depth_chunks.asset.json`
- runtime: `custodian/content/backgrounds/procgen/depth_chunks/`
- source-work: `custodian/asset_drop/source_work/procgen/procgen_depth_chunks/`
- inbox: `custodian/asset_drop/inbox/procgen_depth_chunks/`

### Required new states

| State | Size |
| --- | ---: |
| `rocky_upland_descending_conifer_ledge` | 896×576 |
| `rocky_upland_broken_retaining_drop` | 896×576 |
| `rocky_upland_lower_ledge_mist` | 640×448 |
| `rocky_upland_service_ruin_drop` | 640×448 |

These are BACK-band CHASM presentation only. They never create traversable floor, collision or a second combat map.

Create matching `TerrainStampProfile` resources under:

`custodian/content/procgen/presentation/depth_chunks/`

and register them in:

`custodian/content/procgen/presentation/terrain_stamp_catalog_v1.tres`.

---

## Family E — `procgen_surface_rocky_upland`

**Action:** extend the existing family and preserve all current states.

- metadata: `custodian/content/metadata/assets/families/procgen_surface_rocky_upland.asset.json`
- runtime: `custodian/content/tiles/procgen_macro/runtime/rocky_upland/`
- source-work: `custodian/asset_drop/source_work/procgen/procgen_surface_rocky_upland/`
- inbox: `custodian/asset_drop/inbox/procgen_surface_rocky_upland/`

### Required new states

| State | Size |
| --- | ---: |
| `granite_plateau_broad_01` | 1024×1024 |
| `granite_plateau_fractured_01` | 1024×1024 |
| `granite_shelf_windscoured_01` | 1024×768 |
| `granite_shelf_snow_seam_01` | 1024×768 |
| `scree_apron_large_01` | 1024×512 |
| `scree_fan_01` | 768×768 |
| `snow_patch_broad_01` | 1024×768 |
| `snow_patch_windscoured_01` | 1024×512 |
| `melt_edge_rock_01` | 512×512 |
| `cold_scrub_rock_01` | 768×512 |

These are large presentation surfaces over existing semantic floor and exist to break the visible 32 px tile cadence. They may not change floor membership, walkability, collision, biome classification or elevation semantics.

Create corresponding `TerrainStampProfile` resources under:

`custodian/content/procgen/presentation/surface/rocky_upland/`.

Masks remain authored Resource data; PNG alpha is never gameplay authority.

---

## Family F — `procgen_surface_meridian_hardstand`

**Action:** extend the existing family and preserve all current states.

- metadata: `custodian/content/metadata/assets/families/procgen_surface_meridian_hardstand.asset.json`
- runtime: `custodian/content/tiles/procgen_macro/runtime/meridian_hardstand/`
- source-work: `custodian/asset_drop/source_work/procgen/procgen_surface_meridian_hardstand/`
- inbox: `custodian/asset_drop/inbox/procgen_surface_meridian_hardstand/`

### Required new states

| State | Size |
| --- | ---: |
| `meridian_hardstand_alpine_terrace_01` | 1024×1024 |
| `meridian_hardstand_rock_transition_01` | 1024×768 |
| `meridian_hardstand_snow_transition_01` | 1024×768 |
| `meridian_hardstand_retaining_edge_01` | 1024×512 |
| `meridian_hardstand_service_apron_alpine_01` | 1024×1024 |
| `meridian_ruined_roadway_alpine_01` | 1024×768 |

These do not replace hardened-floor gameplay tiles. They provide irregular slab grouping, rock intrusion, snow/melt accumulation, retaining integration, worn ochre marking and natural transitions.

Create corresponding `TerrainStampProfile` resources under:

`custodian/content/procgen/presentation/surface/meridian_hardstand/`

and register them through the existing terrain stamp catalog.

---

## Motion And Animation Requirements

No required Alpine sprite-sheet animation is introduced by this continuation.

Motion is owned by existing runtime systems:

- **underlay:** optional extremely subtle per-layer camera parallax, data-driven in the underlay profile;
- **fog/weather:** existing `WorldAtmosphere2D`;
- **snow:** existing procedural `snow` weather state;
- **foliage:** existing shared `foliage_life.gdshader` wind/gust path;
- **lighting:** existing `WorldLightingDirector` and lighting profiles.

Do not create animated mountain panoramas, duplicate snow particle nodes, an Alpine-only fullscreen fog shader, or an Alpine-only foliage shader.

## Lighting Requirement

Required new data resource:

`custodian/content/lighting/profiles/alpine_plateau_exterior.tres`

It should provide a cold diffuse daylight baseline, subdued atmospheric contrast, compatible climate fog, restrained saturation, and strong contrast for warm practical infrastructure lights. Day/night and weather continue to modulate it through existing authorities.

Cloud-shadow modulation is recommended later if it can remain a low-cost extension of existing lighting/environment authority; it is not an Asset V2 blocker for the first believable closeout.

---

## Runtime Integration Requirements

### Underlay

Existing owners:

```text
custodian/game/world/procgen/presentation/procgen_underlay_profile.gd
custodian/game/world/procgen/presentation/procgen_depth_backdrop.gd
custodian/game/world/procgen/presentation/underlays/alpine_plateau_underlay.tres
custodian/game/world/procgen/presentation/region_frames/alpine_plateau.tres
```

Recommended continuation:

- retain deterministic A/B selection;
- add data-driven per-layer parallax strength only if needed;
- preserve zero/default behavior for existing non-Alpine profiles;
- apply bounded displacement inside `ProcgenDepthBackdrop`;
- guarantee supported viewport/camera motion cannot expose an unpainted canvas;
- keep opacity in `ProcgenUnderlayProfile`;
- never introduce gameplay authority.

### Cliff fascia

Current owner:

`custodian/game/world/procgen/presentation/procgen_void_cliff_face.gd`

Generic source IDs `149–154` remain fallback.

Recommended continuation:

- add a small data-driven cliff-fascia profile rather than a second hard-coded Alpine table;
- let `ProcgenRegionFrameProfile` optionally select that profile;
- bind `ALPINE_PLATEAU` to the Alpine fascia profile;
- retain generic `void_cliff_face` when no frame-specific profile exists;
- support deterministic weighted crown/body/bottom variants;
- support presentation-only depth bias by outward direction;
- never paint non-CHASM cells or mutate collision/navigation.

Likely files:

```text
custodian/game/world/procgen/presentation/procgen_region_frame_profile.gd
custodian/game/world/procgen/presentation/procgen_void_cliff_face.gd
custodian/game/world/procgen/presentation/region_frames/alpine_plateau.tres
custodian/content/tiles/tilesets/procgen_world_tileset.tres
```

A focused profile Resource may live under:

`custodian/game/world/procgen/presentation/cliff_fascia/`.

### Cliff-contact compositions

Placement derives from the same authoritative exterior frontier/outward direction already used by the fascia. A focused helper may be used, but must not create competing edge semantics.

Required behavior:

- deterministic by accepted map seed;
- qualifying frontier runs only;
- no collision/navigation;
- no incompatible wall/claim overlap;
- streaming visibility compatibility;
- Archive Resolve independence.

### Macro plates

Existing owners:

```text
custodian/game/world/procgen/presentation/procgen_macro_presentation_composer.gd
custodian/game/world/procgen/presentation/terrain_region_extractor.gd
custodian/game/world/procgen/presentation/terrain_stamp_placer.gd
custodian/game/world/procgen/presentation/terrain_stamp_profile.gd
custodian/content/procgen/presentation/terrain_stamp_catalog_v1.tres
```

Extend the existing system. Do not add another Alpine plate compositor.

### Environment

Reuse:

```text
custodian/game/world/environment/world_environment_director.gd
custodian/game/world/lighting/world_lighting_director.gd
custodian/game/world/lighting/world_atmosphere_2d.gd
custodian/game/world/lighting/world_atmosphere_2d.tscn
custodian/game/world/lighting/shaders/world_atmosphere.gdshader
custodian/game/world/procgen/foliage_life.gdshader
```

Do not introduce a second fullscreen pass, per-tile weather materials, or duplicate precipitation authority.

---

## Immutable Dropbox Implementation Gates

A source file merely existing somewhere in Dropbox does not satisfy an implementation gate. Every required art batch must be committed through the canonical immutable input lane with a `custodian.implementation_handoff.v1` manifest containing exact sizes, hashes, paths and this authoring chat URL.

### Gate A — omnidirectional underlay

```text
CUSTODIAN/implementation_inputs/
  procgen-alpine-plateau-underlay-assets/
    alpine-underlay-omnidirectional-v2/
      HANDOFF_MANIFEST.json
      payload/
        procgen_underlay_alpine_plateau/
          far_world_a.png
          far_world_b.png
          depth_fog_a.png
          depth_fog_b.png
          near_cliff_mist_a.png
          near_cliff_mist_b.png
```

Exactly 6 PNGs.

### AP2 source-master input and Gate B closeout

AP2 begins from the active durable source-master batch:

```text
CUSTODIAN/asset_batches/procgen-alpine-presentation/alpine-cliff-source-family-v1/
  custodian_alpine_cliff_source_family_v1.zip
```

Verify SHA-256:

```text
e804c5d9d55f0610cafde5f4169a6b36438b0e08469b212ac3fff84618b127f3
```

Codex derives, normalizes and validates the final semantic states from those approved masters. At closeout, AP2 publishes/verifies the final immutable runtime-output handoff:

```text
CUSTODIAN/implementation_inputs/
  procgen-alpine-cliff-presentation-v1/
    alpine-cliff-presentation-v1/
      HANDOFF_MANIFEST.json
      payload/
        procgen_alpine_cliff_fascia/     # 12 final PNGs
        procgen_alpine_cliff_contact/    # 10 final PNGs
        procgen_depth_chunks/            # 4 final PNGs
```

Exactly 26 final PNGs. This Gate B handoff is the verified AP2 closeout artifact and downstream contract, not the source-master input.

### Gate C — playable surface plates

```text
CUSTODIAN/implementation_inputs/
  procgen-alpine-surface-plates-v1/
    alpine-surface-plates-v1/
      HANDOFF_MANIFEST.json
      payload/
        procgen_surface_rocky_upland/         # 10 PNGs
        procgen_surface_meridian_hardstand/   # 6 PNGs
```

Exactly 16 PNGs.

### Gate policy

Gate A and Gate C remain traditional immutable-input gates. AP2 is the explicit exception documented above: its reviewed source-master batch under `asset_batches/` is sufficient to begin derivation, and its final Gate B is produced/verified at closeout.

For every lane:

- execution may not substitute visual-review artifacts;
- execution may not use arbitrary `~/Downloads` files;
- execution may not generate placeholder art;
- execution may not silently use another family;
- exact package/batch identity and hashes must be verified before mutation.

Dropbox is transport only. After fetch, the owning packet and Asset Pipeline V2 authorize any promotion into `source_work`, inbox and runtime.

---

## Validation And Human Acceptance

Objective validation precedes subjective review. It must prove:

- exact Asset V2 state completeness and dimensions;
- alpha/channel contract;
- deterministic selection and placement;
- semantic terrain immutability;
- collision/navigation immutability;
- exterior/internal CHASM separation;
- Archive Resolve independence;
- no exposed backdrop canvas;
- streaming/reload stability;
- Resource-authored masks remain authority;
- environment effects continue through existing atmosphere/wind owners.

Final visual review should include the minimum evidence needed to inspect:

1. normal interior plateau;
2. south exterior edge;
3. north exterior edge;
4. east or west exterior edge;
5. hardstand-to-natural transition;
6. weather-active view.

Human review questions:

- Does the plateau read as one geographic body rather than a tile board?
- Does every exterior direction imply the same larger alpine world?
- Does the cliff visually belong to the playable terrain?
- Are FAR/MIDDLE/NEAR layers subordinate to gameplay?
- Does infrastructure feel inserted into hostile mountain terrain?
- Are weather, wind, foliage and depth cues coherent?
- Is grid repetition conspicuous at normal gameplay scale?

Human visual approval remains final aesthetic authority.

## Packet Sequence

1. `procgen-alpine-plateau-underlay-assets` — revised omnidirectional underlay, **complete/landed**.
2. `procgen-alpine-cliff-presentation-v1` — derive fascia/contact/depth runtime states from the approved source-master batch, then publish/verify Gate B at closeout.
3. `procgen-alpine-surface-plates-v1` — large Rocky/Hardstand plate vocabulary, Gate C.
4. `procgen-alpine-environment-cohesion-v1` — existing atmosphere/wind/lighting tuning and final cohesive review.

## Documentation Reconciliation

Update active truth only when implementation makes it stale:

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

Historical review and closing summaries remain historical and are not rewritten.

## Non-goals

This continuation does not require 3D terrain, dynamic camera pitch, camera rotation, new topology, new navigation, new collision authority, dynamic snow accumulation, weather gameplay penalties, a second atmosphere shader, Archive Resolve replacement, a new local biome, giant map-sized baked textures, or moving presentation authority into gameplay tiles.