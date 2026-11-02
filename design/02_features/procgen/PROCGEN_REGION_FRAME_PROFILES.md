# Procgen Region Frame Profiles

**Status:** locked design; RF1 foundation implemented (frame profile resource, exterior/internal CHASM masks, explicit starting-region selector, frame-driven depth backdrop); Alpine production underlay art pending\
**Date:** 2026-10-02  
**Scope:** generated-region macro frame, playable-border presentation, depth/underlay selection  
**Archive Resolve:** separate authority at `STREAMING_REVEAL_PRESENTATION_V1.md`

## Decision

Procgen has three independent presentation axes:

1. **Local biome field** — ecological variation *inside* playable floor.
2. **Region frame profile** — the macro physical/presentation envelope around the playable region.
3. **Archive Resolve** — the moving streaming-resolution treatment over generated playable cells.

These must not be collapsed into one concept.

`alpine` is **not** a fifth local biome. The first starting region uses a fixed
`ALPINE_PLATEAU` **region frame**, while its local ecological biome field remains deterministic/generative.

Future generated regions may select different frame profiles without changing Archive Resolve and without pretending every biome sits on a cliff island.

## Current Local Biome Authority

Existing local biome IDs remain:

- `rocky_upland`
- `woodland`
- `scrubland`
- `wetland`

`BiomeField` continues deriving them from terrain, elevation, seeded moisture/exposure, and world-profile bias.

A region frame may bias which local biomes are common through the existing world/climate profile, but the frame does not directly paint biome cells.

## Region Frame Responsibility

A region frame profile answers:

- What is the macro setting/envelope of this generated operation?
- What does the **exterior playable boundary** look like?
- What permanent nonplayable presentation exists beyond that boundary?
- Which depth/underlay profile is used?
- Which near-edge presentation family is compatible?
- Which climate/world-profile defaults are appropriate?
- Which local biome combinations are visually compatible?

A region frame does **not** own:

- walkability;
- floor membership;
- navigation;
- collision;
- streaming lifecycle;
- Archive Resolve;
- local biome classification;
- weather schedule;
- route generation;
- save authority.

## Exterior Boundary Versus Internal Chasm

Current V1 classifies every in-map non-floor cell as `CHASM` unless replaced by an explicit nonwalkable claim such as `OCEAN`.

That structural surface contract remains valid, but presentation needs one additional **derived distinction**:

- **exterior void**: non-floor/chasm cells connected to the map exterior;
- **interior chasm**: enclosed ravines, pits, gaps, or holes inside the generated region.

This is presentation metadata only.

Derive exterior void deterministically by flood-filling non-floor cells from the map bounds after final floor/nonwalkable claims are stable. Do not create a second collision or traversal authority.

The **playable region border** is the irregular frontier between final authoritative floor and exterior void.

Internal chasms may use local ravine/pit presentation and must not automatically inherit the region's full exterior-world underlay treatment.

## Archive Resolve Separation

Archive Resolve operates over cells that belong to the generated playable/structural region and are unresolved or resolving.

It may show the already-locked **evidence echo** of the actual future resolved terrain under its graphite veil.

That echo is not the underlay.

At the permanent world edge:

- Archive Resolve ends when there are no more region cells to resolve;
- the region-frame edge/fog/underlay remains visible even after the entire playable region is settled;
- no underlay pixel becomes playable or implies streaming authority.

This distinction is mandatory.

## First Starting Region: ALPINE_PLATEAU

The first generated campaign starting region is locked to the `ALPINE_PLATEAU` frame.

Its detailed art lock is:
`design/02_features/procgen/ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`.

### Macro shape

- broad irregular upper plateau / highland shelf;
- multiple local height changes and ravines on the playable plane;
- exterior perimeter falls away through cliffs/escarpments;
- not a tiny floating island and not a square arena;
- hardstand compounds/terraces are embedded into terrain rather than defining the whole map.

### Starting-region scale

Use the existing production contract-map scale rather than inventing a new giant-world system.

- existing contract canvases: roughly `144–240` cells per side depending on world profile;
- native semantic cell: `32×32 px`;
- current general configured contract range: `160–224` cells;
- Alpine starting-region target: **192–208 cells per side**;
- acceptable lower bound for authored/tuning variants: **176 cells** without separate review.

That yields roughly:

- `192 × 32 = 6144 px`
- `208 × 32 = 6656 px`

across the semantic canvas.

The playable footprint is intentionally irregular and smaller than the rectangular canvas.

This is large enough for the cliff perimeter to be a geographic condition rather than a constantly visible arena wall.

### Local biome mix

The local biome field remains generative.

Desired starting-region tendency:

1. `rocky_upland` dominant;
2. `woodland` substantial secondary;
3. `scrubland` connective/exposed pockets;
4. `wetland` sparse, bounded drainage/bog pockets.

Do not hard-code exact percentage quotas into biome classification merely to satisfy the art lock. Use climate/exposure bias and content profiles, then validate fixed seeds visually.

## Alpine Exterior Presentation Stack

The permanent nonplayable edge is a three-depth composition independent of Archive Resolve:

```text
PLAYABLE ALPINE FLOOR
        ↓
WORLD-POSITIONED CLIFF LIP / FASCIA
        ↓
DEPTH FOG / CLOUD SHELF
        ↓
FAINT DISTANT LOWER WORLD
```

### 1. Near edge: cliff lip/fascia

Use actual world-positioned edge geometry derived from the exterior floor frontier.

Current `ProcgenVoidCliffFace` is the correct ownership model: presentation only, no collision/navigation authority.

For Alpine Plateau:

- stone lip clearly anchors the playable surface;
- vertical fascia descends out of the playable plane;
- roots, broken retaining structures, snow streaks and sparse descending conifers may be used as presentation;
- the face should disappear into depth fog rather than end on a visible hard bottom.

### 2. Middle depth: obscuring fog shelf

This is **permanent region depth atmosphere**, not Archive Resolve.

It should:

- obscure the lower cliff terminus;
- prevent the far world from reading as a flat pasted backdrop;
- move slowly/subtly with camera/parallax if the implementation supports it;
- remain present after every playable cell is fully resolved;
- never hide immediate playable hazards or terrain.

### 3. Far depth: distant world below

The player should faintly perceive that the plateau belongs to a larger world.

Allowed reads:

- distant lower ridges;
- forested valleys;
- snow-banded slopes;
- scattered ruined/industrial silhouettes;
- faint roads/terraces;
- extremely subdued lights in rare infrastructure.

It is nonplayable presentation only.

Do not show a second readable combat map below. It should suggest scale, not invite pathfinding.

## V1 Underlay Mapping

The existing `ProcgenUnderlayProfile` FAR/MIDDLE/NEAR structure is sufficient for the first implementation and should be data-driven by the region frame.

For `ALPINE_PLATEAU`:

- **FAR** = distant lower-world panorama;
- **MIDDLE** = valley fog / cloud shelf;
- **NEAR** = cliff-root mist / descending conifer silhouette.

The current hard-coded `ENDLESS_FOREST` production default is an implementation placeholder/legacy profile, not the target Alpine starting-region underlay.

`DROWNED_BASILICA` remains an explicit special/development profile and is not the Alpine default.

## Future Frame Catalogue

Only `ALPINE_PLATEAU` is locked as the first production starting frame.

Future examples, not implementation commitments:

| Frame | Typical playable border | Permanent nonplayable depth |
| --- | --- | --- |
| `ALPINE_PLATEAU` | cliff/escarpment | fog shelf + lower valleys |
| `COASTAL_SHELF` | sea cliff / shoreline | ocean + marine haze |
| `LOWLAND_BASIN` | ridge, dense ruin/forest obstruction, floodplain limit | distant basin/treeline |
| `FLOODED_MARSH` | deep water / reed mass | flooded expanse + mist |
| `RUINED_URBAN` | collapsed city canyon / impassable structural mass | skyline/ruin depth |
| `SUBTERRANEAN` | rock/structure enclosure | darkness/shafts/void |
| `AEROSTAT_PLATFORM` | platform edge | cloud/sky/depth |

The border is chosen by the **region frame**, never inferred from a single local biome cell.

## World/Climate Profile Integration Target

Current `CustodianContractMap.PLANET_WORLD_PROFILES` already owns macro generation/climate inputs such as map-size range, moisture/exposure bias, foliage density and weather weights.

The eventual data seam should add one field such as:

```text
region_frame_profile_id
```

The starting region explicitly selects `alpine_plateau`.

Future scenario/world profiles may provide a default frame choice.

Do not infer the frame by asking which biome happens to be most common after generation.

## Asset Pipeline V2: Alpine Underlay Family

When producing the Alpine underlay art, use Asset Pipeline V2.

### Family

```text
family_id: procgen_underlay_alpine_plateau
schema: custodian.asset_family.v2
kind: backdrop
direction_policy: omni
auto_mirror: false
frame_count: 1 per state
canvas: 1536×1024 RGBA PNG
```

### Source-work paths

```text
custodian/asset_drop/source_work/procgen/procgen_underlay_alpine_plateau/
  far_world_a_source.png
  far_world_b_source.png
  depth_fog_a_source.png
  depth_fog_b_source.png
  near_cliff_mist_a_source.png
  near_cliff_mist_b_source.png
```

### Inbox staging

```text
custodian/asset_drop/inbox/procgen_underlay_alpine_plateau/
  far_world_a.png
  far_world_b.png
  depth_fog_a.png
  depth_fog_b.png
  near_cliff_mist_a.png
  near_cliff_mist_b.png
```

### Runtime target

```text
custodian/content/backgrounds/procgen/alpine_plateau/
  alpine_plateau_far_world_a_1536x1024.png
  alpine_plateau_far_world_b_1536x1024.png
  alpine_plateau_depth_fog_a_1536x1024.png
  alpine_plateau_depth_fog_b_1536x1024.png
  alpine_plateau_near_cliff_mist_a_1536x1024.png
  alpine_plateau_near_cliff_mist_b_1536x1024.png
```

Family metadata target:

```text
custodian/content/metadata/assets/families/procgen_underlay_alpine_plateau.asset.json
```

Profile target:

```text
custodian/game/world/procgen/presentation/underlays/alpine_plateau_underlay.tres
```

No generated or staged asset is a runtime dependency until Asset Pipeline V2 publishes it.

## Implementation Boundary

This document is a design lock, not authorization to edit the active streaming/refactor workstream.

Implementation should:

1. preserve M3/M4/M5/M6 streaming ownership;
2. derive exterior-void presentation metadata from final semantics;
3. replace hard-coded underlay selection with a region-frame-driven profile seam;
4. introduce `ALPINE_PLATEAU` as the first production frame;
5. keep Archive Resolve entirely separate;
6. preserve `RuntimeWalkableBoundary` as physical perimeter authority.

Do not implement this by making biome classification own border geometry.

## RF1 Implementation Notes

- `ProcgenRegionFrameProfile` (`presentation/procgen_region_frame_profile.gd`) holds `profile_id`, the selected `ProcgenUnderlayProfile`, and explicit `visual_fallback`/`fallback_reason` telemetry. AP1 is complete/landed: `region_frames/alpine_plateau.tres` now binds the real `procgen_underlay_alpine_plateau` family and reports `visual_fallback=false`; Endless Forest remains only historical fallback context.
- `NonwalkableSurfaceClassifier.classify()` additionally returns `exterior_chasm_cells` (boundary flood over CHASM cells only; OCEAN, floor and other surfaces block it) and `internal_chasm_cells`. `kind_by_cell`, chasm/ocean sets and counts are unchanged.
- Frame selection is explicit data: `CustodianContractMap.region_frame_profile_id` (empty = neutral) is copied into the generated `world_profile`; only the production `custodian_contract_map.tscn` sets `alpine_plateau`. `PLANET_WORLD_PROFILES` stay frame-agnostic and nothing infers a frame from `planet_key`.
- `ProcGenTilemap._refresh_depth_backdrop()` configures the global backdrop from the exterior mask only. A map with chasm cells but no exterior chasm hides the backdrop (`no_exterior_chasm`); a map with no chasm keeps the legacy world-bounds fallback. The Drowned Basilica override still wins and never mutates surface semantics.
- Telemetry: `get_region_frame_debug_snapshot()` and the `region_frame` level-data key report frame id, resolution, fallback state/reason, underlay source/profile id, exterior/internal counts and backdrop mode.
