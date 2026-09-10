# CUSTODIAN Procgen Depth Chunks

## Production Art and Runtime Integration Specification

**Status:** active production specification; baseline library is integrated, follow-on Wetland/Rocky batch is ingested and awaiting presentation binding

**Last updated:** 2026-09-10

**Runtime:** `custodian/`

**Primary presentation authority:** `design/02_features/procgen/PROCGEN_MACRO_PRESENTATION_SYSTEM.md`

---

## Current Truth

Procgen depth chunks are large world-positioned scenic underlays beneath and outside playable generated terrain. They are **not terrain tiles, not playable ground, and not a replacement for near cliff/retaining-edge presentation**.

The live repository now contains two generations of source work and four Asset Pipeline V2 families:

```text
BASELINE / INTEGRATED
procgen_depth_universal   4 states
procgen_depth_scrubland   3 states
procgen_depth_woodland    2 states
                         ----------
                          9 runtime assets

FOLLOW-ON / INGESTED, NOT YET PRESENTATION-BOUND
procgen_depth_chunks      7 states
                          1 woodland overgrown-works
                          3 wetland
                          3 rocky-upland
                         ----------
                          7 runtime assets

TOTAL                     16 runtime depth-chunk assets
```

The old statement that Wetland and Rocky Upland should not be generated yet is obsolete. Those six biome assets plus the new Woodland overgrown-works asset have already been normalized and successfully ingested through Asset Pipeline V2.

The remaining gap is **runtime presentation integration**, not art ingest.

---

# 1. Runtime Stack

The presentation stack is:

```text
FAR ATMOSPHERE
        ↓
AUTHORED DEPTH CHUNKS
        ↓
NEAR CLIFF / RETAINING EDGE
        ↓
PLAYABLE PROCGEN TERRAIN
        ↓
PROPS / FOLIAGE / STRUCTURES
```

Depth chunks belong to the world-positioned scenic underlay band. They do **not** replace macro terrain stamps, cliff faces, or playable TileMap semantics. The 32×32 semantic grid remains authoritative for walkability, collision, and navigation.

Connected-map presentation must suppress procgen depth presentation where another map owns the scene.

---

# 2. Asset Pipeline V2 Ownership

All live depth families use:

```text
schema: custodian.asset_family.v2
kind: backdrop
direction_policy: omni
auto_mirror: false
```

## Baseline families

```text
custodian/content/metadata/assets/families/
├── procgen_depth_universal.asset.json
├── procgen_depth_scrubland.asset.json
└── procgen_depth_woodland.asset.json
```

Runtime roots:

```text
res://content/backgrounds/procgen/depth_chunks/universal/
res://content/backgrounds/procgen/depth_chunks/scrubland/
res://content/backgrounds/procgen/depth_chunks/woodland/
```

These nine assets also have `TerrainStampProfile` resources under:

```text
custodian/content/procgen/presentation/depth_chunks/
```

and are part of the procgen macro-presentation selection system.

Current biome-family behavior is effectively:

```text
scrubland
  procgen_depth_universal
  procgen_depth_scrubland

woodland
  procgen_depth_universal
  procgen_depth_woodland

wetland
  procgen_depth_universal

rocky_upland
  procgen_depth_universal
```

That last pair is why the follow-on batch still needs integration.

## Follow-on family

```text
custodian/content/metadata/assets/families/
└── procgen_depth_chunks.asset.json
```

Runtime root:

```text
res://content/backgrounds/procgen/depth_chunks/
```

States:

```text
woodland_overgrown_works

wetland_flooded_basin
wetland_reed_channels
wetland_drowned_service_platform

rocky_upland_cliff_bowl
rocky_upland_talus_ravine
rocky_upland_exposed_ledge
```

All seven are present in the generated V2 catalog and runtime directory. The family currently has no declared V2 consumers, but that field alone is not the integration test for this subsystem: the older depth families also have empty contract consumer arrays while being consumed through separate `TerrainStampProfile` resources.

For the follow-on family, the actionable missing layer is the absence of corresponding presentation profiles/selection registration.

---

# 3. Source Work and Provenance

Source masters remain under `asset_drop/source_work`; they are not runtime dependencies.

## Baseline archive/master set

```text
custodian/asset_drop/source_work/procgen_depth_chunks_v1/
```

This is the broad older source set. It contains the original Universal, Scrubland, and Woodland baseline masters and also retained copies/revisions from later depth work.

## Follow-on seven-asset source set

```text
custodian/asset_drop/source_work/procgen_depth_chunks/
```

Current files:

```text
depth_rocky_upland_cliff_bowl_v1.png
depth_rocky_upland_exposed_ledge_v1.png
depth_rocky_upland_talus_ravine_v1.png

depth_wetland_drowned_service_platform_v1.png
depth_wetland_flooded_basin_v1.png
depth_wetland_reed_channels_v1.png

depth_woodland_overgrown_works_v1.png
```

Six Wetland/Rocky files are byte-identical to same-named copies retained in `procgen_depth_chunks_v1/`.

`depth_woodland_overgrown_works_v1.png` is **not** byte-identical between the two source roots. The source used to normalize the current `procgen_depth_chunks` runtime state is the copy under:

```text
custodian/asset_drop/source_work/procgen_depth_chunks/
```

Do not collapse these two source roots by deleting the differing Woodland master. A future provenance cleanup must update the preparation scripts and documentation in the same change.

---

# 4. Production Prep and Inbox State

The completed prep artifacts from the Carrow/depth work were moved during housekeeping to:

```text
custodian/asset_drop/archive/
manual_housekeeping_20260909-224003/
production_prep/
```

The active `custodian/asset_drop/production_prep/` lane is currently empty.

The official V2 inbox has no pending depth-chunk art. Depth assets should only re-enter the inbox when a new or replacement source has passed review and normalization.

Do not treat `source_work` or archived `production_prep` as pending ingest queues.

---

# 5. Production Size Classes

The generated artwork should remain untouched as source masters. Runtime derivatives are normalized through Asset Pipeline V2.

| Class | Runtime canvas | Approximate logical footprint |
|---|---:|---:|
| **LARGE** | `896×576` | ~28×18 cells |
| **MEDIUM** | `640×448` | ~20×14 cells |

The logical footprint is a placement envelope, not a rectangular visible shape. Alpha silhouettes should remain irregular and the visible artwork does not need to fill the full canvas.

---

# 6. Core Visual Contract

## Perspective

Top-down / 2.5D. Match the world camera rather than side-scrolling perspective or full 45° isometric architecture.

Vertical relief is welcome for ravines, retaining walls, cliff faces, and foundation cavities, but the composition should still read primarily from above.

## Detail hierarchy

Depth chunks are most detailed near the terrain-contact edge and progressively quieter into deeper background space.

Target:

```text
terrain-contact ~25%
HIGH detail

middle ~45%
MEDIUM detail

deep / outer ~30%
LOWER detail + deeper shadow
```

Playable terrain must remain visually dominant.

## Base palette

Universal language:

```text
charcoal
graphite
weathered concrete gray
dirty warm gray
deep earth brown
oxidized iron
muted olive
restrained moss / vegetation
```

Scrubland adds:

```text
dusty tan
pale compacted earth
gray-green brush
dead straw
muted ochre
```

Woodland adds:

```text
deep olive
desaturated forest green
moss green
wet graphite rock
dark brown wood
```

Wetland should extend the same grounded industrial/natural language with dark water, flooded infrastructure, reeds, mud, oxidized structures, and restrained green-brown vegetation.

Rocky Upland should emphasize exposed stone, talus, broken ledges, dry structural scars, muted mineral tones, and vertical depth without becoming a bright fantasy mountain palette.

No high-saturation scenery.

---

# 7. Alpha Contract

Every master must provide:

```text
RGBA
true transparent exterior
irregular silhouette
no rectangular matte
```

During normalization, near-zero accidental alpha may be cleaned to true zero. Preserve intentional partial alpha around foliage edges, fine roots, mist, water spray, and atmospheric edges.

Do not binary-alpha the family globally.

---

# 8. Lighting Contract

Assume soft overcast/diffuse top lighting. Avoid strongly baked directional sunlight so chunks remain usable under dawn, midday, dusk, night, overcast, rain, and mist presentation.

Depth chunks should generally read darker and quieter than adjacent playable terrain before environment treatment. Bright flat surfaces that imply reachable ground are undesirable.

---

# 9. Terrain-Contact Edge

Each asset needs an intentional terrain-overlap zone, normally the upper portion of the image.

Typical target:

```text
20–25% of chunk height
```

Suitable overlap material:

- broken slabs
- rock ledges
- roots
- retaining structures
- soil/earth
- rubble
- vegetation

Avoid placing the primary focal object directly on the overlap seam.

---

# 10. Baseline Universal Family

## `depth_civic_foundation_breach_v1.png`

**Class:** LARGE  
**Runtime:** `896×576`

Universal structural hero chunk. A partially buried civic foundation should expose fractured retaining slabs, structural reinforcement, broken decks, conduits, pipe runs, drainage openings, collapsed retaining walls, rubble, and inaccessible service cavities.

The upper overlap zone should provide a convincing built foundation beneath playable terrain. The deeper edge should dissolve into rubble, earth, and dark infrastructure.

Avoid intact inviting doors, brightly lit corridors, obvious usable stairs, giant signage, faction branding, overt religious architecture, or magical technology.

Primary tags:

```text
universal
constructed_edge
foundation
civic
large_void
compound_adjacent
```

## `depth_fractured_ravine_v1.png`

**Class:** LARGE  
**Runtime:** `896×576`

Universal natural/structural depth separator. Use an uneven diagonal ravine with fractured ledges, dark depth channel, rubble, roots, modest vegetation, structural fragments, and optional subtle water trace.

The central channel must remain visibly unwalkable. Horizontal flip is acceptable when lighting remains coherent.

Primary tags:

```text
universal
ravine
natural
structural_decay
large_gap
```

## `depth_service_infrastructure_field_v1.png`

**Class:** MEDIUM  
**Runtime:** `640×448`

Universal industrial background chunk representing buried utility infrastructure: dead cable trenches, armored pipe runs, conduit banks, broken vaults, service pads, collapsed grating, retaining structures, muddy depressions, and ruined utility hardware.

It should not read as a building or possess a clear architectural center.

Primary tags:

```text
universal
infrastructure
utility
constructed
service
carrow_compatible
```

## `depth_talus_and_rubble_shelf_v1.png`

**Class:** MEDIUM  
**Runtime:** `640×448`

Universal neutral glue/fallback chunk: angular rock, talus, gravel, fragmented concrete, fallen slabs, dust, sparse vegetation, and occasional reinforcement.

No hero structure or dominant landmark.

Primary tags:

```text
universal
neutral
rubble
talus
fallback
```

---

# 11. Baseline Scrubland Family

Scrubland should read as wind-beaten, dry, eroded, sparse, and abandoned, not as stylized desert, dunes, cowboy scenery, or dramatic mesa country.

## `depth_scrubland_dry_basin_v1.png`

**Class:** LARGE  
**Runtime:** `896×576`

Broad lower-elevation basin with compacted earth, dark bedrock, erosion channels, gravel, sparse brush, dead grasses, small concrete fragments, utility remnants, and drainage traces.

The subdued center must still read as lower/inaccessible rather than convenient alternate walking ground.

## `depth_scrubland_wash_channel_v1.png`

**Class:** MEDIUM  
**Runtime:** `640×448`

Diagonal old runoff corridor with gravel, sediment, erosion grooves, fractured culvert pieces, sparse brush, drainage remnants, and broken retaining structures.

It must not read as a road. Avoid lane symmetry, constant width, clean shoulders, and an obvious driveable surface.

## `depth_scrubland_service_scar_v1.png`

**Class:** MEDIUM  
**Runtime:** `640×448`

Former service route reclaimed by collapse and vegetation: disturbed-ground scars, fractured hardstand, abandoned cable trench, shrubs, smashed utility hardware, drainage, concrete debris, and buried conduit.

Visual continuity should be broken enough that it no longer reads as an intact road.

---

# 12. Baseline Woodland Family

Woodland should feel dense, low, shadowed, reclaimed, and structurally layered without becoming lush fantasy wilderness. Old infrastructure should remain faintly legible.

## `depth_woodland_canopy_basin_v1.png`

**Class:** LARGE  
**Runtime:** `896×576`

Dense lower canopy with irregular tree crowns, dark understory, exposed rock, moss, fallen trunks, roots, openings, and one restrained buried-service cue.

The upper contact zone needs exposed cliff/soil/root/stone before dropping into foliage so the playable level reads physically above the canopy.

Avoid a repeated tree-ball texture.

## `depth_woodland_ravine_v1.png`

**Class:** LARGE  
**Runtime:** `896×576`

Woodland hero chunk with fractured stone walls, heavy roots, vegetation at several apparent elevations, fallen logs across inaccessible gaps, dark central water/shadow, retaining ruin, and one restrained piece of collapsed infrastructure.

The center must clearly read deeper than the surrounding canopy.

---

# 13. Follow-On Woodland Asset

## `depth_woodland_overgrown_works_v1.png`

**Class:** MEDIUM  
**Runtime:** `640×448`

This is the current follow-on Woodland state in `procgen_depth_chunks`.

It should **augment**, not silently replace, the existing `procgen_depth_woodland` canopy-basin/ravine pair unless a later design decision explicitly supersedes one of those baseline states.

Presentation intent: reclaimed civic/industrial works heavily overtaken by woodland growth, with enough structural geometry to distinguish it from pure canopy/ravine scenery.

---

# 14. Follow-On Wetland Assets

## `depth_wetland_flooded_basin_v1.png`

**Class:** LARGE  
**Runtime:** `896×576`

Primary Wetland large-void scenic plate. Flooded low ground, irregular dark water, mud/silt, emergent vegetation, drowned structural fragments, and strong elevation cues should prevent the basin from reading as traversable water terrain.

## `depth_wetland_reed_channels_v1.png`

**Class:** MEDIUM  
**Runtime:** `640×448`

Linear Wetland depth feature using reeds, dark channels, water/mud breaks, partially submerged structural remnants, and irregular banks. It should not read as a designed canal or playable path.

## `depth_wetland_drowned_service_platform_v1.png`

**Class:** MEDIUM  
**Runtime:** `640×448`

Constructed Wetland decay: a former service platform or utility structure partially submerged/reclaimed, with broken hard surfaces, water, vegetation, oxidized hardware, and inaccessible lower-space cues.

---

# 15. Follow-On Rocky Upland Assets

## `depth_rocky_upland_cliff_bowl_v1.png`

**Class:** LARGE  
**Runtime:** `896×576`

Primary Rocky Upland large-void plate. Use a strong bowl/cliff formation with exposed vertical stone, irregular ledges, rubble/talus, shadow depth, and restrained remnants of old constructed edge work.

## `depth_rocky_upland_talus_ravine_v1.png`

**Class:** LARGE  
**Runtime:** `896×576`

Hero Rocky Upland ravine with broken stone, talus descent, dark depth seams, fractured ledges, and selective structural debris. Avoid a clean valley floor or readable traversable channel.

## `depth_rocky_upland_exposed_ledge_v1.png`

**Class:** MEDIUM  
**Runtime:** `640×448`

Reusable rocky ledge/shelf plate with exposed bedrock, broken cliff lip, talus, cracks, sparse upland vegetation, and muted structural scars. It should function as a medium-size biome glue asset rather than a landmark every time it appears.

---

# 16. Canonical Runtime Files

Baseline runtime files are generated by their family templates, for example:

```text
custodian/content/backgrounds/procgen/depth_chunks/universal/
  procgen_depth_universal_civic_foundation_breach_v1_896x576.png
  procgen_depth_universal_fractured_ravine_v1_896x576.png
  procgen_depth_universal_service_infrastructure_field_v1_640x448.png
  procgen_depth_universal_talus_and_rubble_shelf_v1_640x448.png

custodian/content/backgrounds/procgen/depth_chunks/scrubland/
  procgen_depth_scrubland_dry_basin_v1_896x576.png
  procgen_depth_scrubland_wash_channel_v1_640x448.png
  procgen_depth_scrubland_service_scar_v1_640x448.png

custodian/content/backgrounds/procgen/depth_chunks/woodland/
  procgen_depth_woodland_canopy_basin_v1_896x576.png
  procgen_depth_woodland_ravine_v1_896x576.png
```

The follow-on family currently owns:

```text
custodian/content/backgrounds/procgen/depth_chunks/
  depth_woodland_overgrown_works_v1.png

  depth_wetland_flooded_basin_v1.png
  depth_wetland_reed_channels_v1.png
  depth_wetland_drowned_service_platform_v1.png

  depth_rocky_upland_cliff_bowl_v1.png
  depth_rocky_upland_talus_ravine_v1.png
  depth_rocky_upland_exposed_ledge_v1.png
```

Gameplay/runtime code must reference canonical runtime resources, never source masters, prep files, archived handoffs, or inbox files.

---

# 17. Normalization Contract

Pipeline:

```text
generated source master
        ↓
asset_drop/source_work/...
        ↓
review / preparation
        ↓
trim only meaningless transparent border when required
        ↓
resize ONCE
        ↓
LARGE  → 896×576
MEDIUM → 640×448
        ↓
preserve alpha
        ↓
asset_drop/inbox/<family>/
        ↓
Asset Pipeline V2 plan / ingest
        ↓
canonical runtime + catalog + receipt/archive
```

Use a high-quality single reduction pass for high-resolution rendered source artwork. Do not downsample, upscale, and downsample again.

The completed follow-on normalization used Pillow LANCZOS exactly once from source master to final target size and preserved partial alpha.

---

# 18. Runtime Contrast Treatment

Raw files should preserve source detail. Runtime presentation owns hierarchy.

Useful starting treatment remains approximately:

```text
brightness/modulate ≈ 0.78–0.88
saturation          ≈ 0.80–0.90
contrast            slightly reduced
```

Environment, biome, day/night, and weather may modify this further.

Do not permanently crush source masters merely to achieve one runtime lighting condition.

---

# 19. Placement Density

Do not carpet the void with scenic plates.

A normal camera view should usually contain approximately:

```text
0–2 major chunks
```

Use universal assets as broad fallback/glue and biome-specific assets for identity.

Avoid multiple competing hero assets in one view.

---

# 20. Overlap

Chunks may overlap each other where their silhouettes support it.

Typical overlap:

```text
32–96 px
~1–3 world cells
```

Prefer overlap through rock, earth, rubble, vegetation, water-edge noise, and similarly forgiving material transitions.

Avoid stacking focal infrastructure over focal infrastructure.

---

# 21. Determinism and Transformations

Selection must remain seeded/deterministic.

Horizontal flips can be allowed selectively when the source lighting and terrain-contact edge remain valid.

Do not freely rotate every chunk by 90°. Several assets have strong terrain-facing orientation and 2.5D relief.

For the current generation, `rotation = 0` plus carefully approved horizontal flip is safer than arbitrary rotation.

---

# 22. Semantic Selection

Selection should be owned by explicit presentation metadata/resources rather than filename inference at runtime.

Depth profiles need enough data to express:

```text
family identity
biome eligibility
size class
weight
minimum region size
placement domain
allowed region/topology kinds
terrain-contact edge
overlap rows
pivot
footprint
chasm/core exclusion geometry
flip policy
tags
```

The existing `TerrainStampProfile` resource path is the live authority for baseline depth placement.

The follow-on batch should join that authority instead of creating a parallel selector.

---

# 23. Placement Clearance

Depth chunks must never create visual contradictions underneath:

- major building interiors
- authored connected maps
- transfer sequences
- explicit black/void presentation regions
- hero connectors that own their own backdrop
- ingress/route areas whose readability would be damaged by a scenic plate

Placement must respect presentation exclusion and clearance regions.

---

# 24. Connected-Map Isolation

This family belongs to the **procgen exterior presentation stack**.

When transitioning away from procgen into an authored connected map such as Carrow Yard or the East Machine House interior, the procgen depth presentation root must be suppressed. It should be restored on return to the procgen world.

No procgen woodland basin or other exterior depth plate should appear behind an interior merely because world coordinates overlap.

---

# 25. Far Backdrop Relationship

The far layer should remain restrained:

```text
haze
distant relief
very dark canopy/rock suggestion
atmospheric gradient
```

The authored depth chunks provide tangible world mass. The FAR layer provides atmosphere.

The old camera-following scenic wallpaper should not dominate the environment.

---

# 26. Near-Depth Relationship

Depth chunks do not replace cliff faces.

Near edges remain the responsibility of terrain-derived cliff/retaining-edge presentation such as `ProcgenVoidCliffFace` and related terrain/structure systems.

Conceptually:

```text
PLAYABLE FLOOR
█████████████████
      cliff
      █████
        ↓
   authored chunk
 ~~~~~~~~~~~~~~~~~
        ↓
    far atmosphere
```

The chunk begins visually beneath the near terrain edge.

---

# 27. Baseline Runtime Integration

The original nine assets are no longer merely a future art proposal.

They are represented as three live V2 families:

```text
procgen_depth_universal
procgen_depth_scrubland
procgen_depth_woodland
```

Their runtime textures are referenced by production `TerrainStampProfile` resources under:

```text
custodian/content/procgen/presentation/depth_chunks/
```

The macro presentation validation exercises universal, scrubland, and woodland family eligibility.

This is the current integration path to extend.

---

# 28. Follow-On Runtime Integration Required

The follow-on `procgen_depth_chunks` family is successfully ingested but is **not yet part of the live biome presentation selection**.

The next implementation slice should:

1. Add presentation profiles for the three Wetland assets.
2. Add presentation profiles for the three Rocky Upland assets.
3. Add a Woodland presentation profile for `woodland_overgrown_works`.
4. Extend biome family/eligibility selection so Wetland can choose universal + Wetland follow-on depth art.
5. Extend biome family/eligibility selection so Rocky Upland can choose universal + Rocky follow-on depth art.
6. Extend Woodland so `woodland_overgrown_works` augments the existing Woodland pair unless an explicit supersession decision is made.
7. Preserve seeded deterministic selection, clearance rules, connected-map isolation, collision/navigation authority, and the existing baseline profiles.
8. Add focused validation proving the new families/states are selectable only in the intended biomes and that deterministic selection remains stable.

Do **not** re-ingest the seven PNGs as part of this task. They are already runtime/catalog assets.

Do **not** create a second depth-chunk selection system.

---

# 29. Review Scene / Visual Validation

The existing depth-chunk review tooling should remain useful for checking:

```text
playable plateau / terrain edge
one selected depth chunk
far backdrop
Operator or equivalent scale reference
biome cycling
horizontal-flip review where permitted
day/night preview
weather preview
```

Visual review should answer:

- Does the chunk clearly sit below playable terrain?
- Does the alpha edge disappear naturally under the terrain contact zone?
- Does it look consistent with the world camera and pixel/detail density?
- Does it remain subordinate under day/night/weather presentation?
- Does it ever imply reachable ground?
- Does it overlap neighboring chunks without obvious rectangular seams?

---

# 30. Definition of Done

The **baseline nine** are considered production-integrated when:

- source masters remain preserved
- V2 runtime/catalog outputs exist
- `TerrainStampProfile` resources point to canonical runtime textures
- deterministic selection uses those profiles
- Scrubland and Woodland biome eligibility works
- universal fallback works
- collision/navigation remain unaffected
- connected maps suppress procgen depth presentation

The **follow-on seven** are considered production-integrated when:

- current source masters remain preserved
- all seven V2 runtime/catalog outputs remain intact
- Wetland/Rocky/Overgrown presentation profiles exist
- Wetland selects universal + appropriate Wetland depth profiles
- Rocky Upland selects universal + appropriate Rocky profiles
- Woodland can select the new overgrown-works profile alongside its existing baseline pair unless explicitly superseded
- selection remains deterministic for a given seed/context
- clearance/exclusion rules are preserved
- no runtime consumer points into `asset_drop`
- focused procgen macro-presentation validation passes
- nighttime/weather preserve scene readability
- normal gameplay does not mistake underlay scenery for reachable space

---

# Current State Summary

```text
SOURCE MASTERS
  retained

ACTIVE PRODUCTION_PREP
  empty after housekeeping

DEPTH INBOX
  empty

BASELINE 9
  V2 ingested
  runtime present
  TerrainStampProfile presentation resources present
  universal/scrubland/woodland selection integrated

FOLLOW-ON 7
  V2 ingested successfully
  runtime present
  generated catalog present
  not yet registered into macro presentation selection
```

**Current next step:** integrate the already-ingested `procgen_depth_chunks` Wetland, Rocky Upland, and Woodland-overgrown states into the existing `TerrainStampProfile` / macro-presentation authority. No new art generation or Asset V2 ingest is required for that slice.
