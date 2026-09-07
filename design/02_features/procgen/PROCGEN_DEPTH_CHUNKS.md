# CUSTODIAN Procgen Depth Chunks

## Full Production Art Specification, V1

Status: new production contract

Last updated: 2026-09-07

Runtime: `custodian/`

This is the production contract for the nine authored depth chunks.

The key distinction: these are **not terrain tiles, not playable ground, and not
a replacement for cliffs**. They are large world-positioned scenic plates
underneath/outside generated terrain, designed to make the generated landmass
feel embedded in a much larger physical environment.

## Runtime Stack

The runtime stack should eventually read:

```text
FAR ATMOSPHERE
        ↓
AUTHORED DEPTH CHUNKS         ← these nine assets
        ↓
NEAR CLIFF / RETAINING EDGE
        ↓
PLAYABLE PROCGEN TERRAIN
        ↓
PROPS / FOLIAGE / STRUCTURES
```

## Authority Relationship

This family is presentation-only and belongs to the procgen exterior
presentation stack defined in
`design/02_features/procgen/PROCGEN_MACRO_PRESENTATION_SYSTEM.md`. Depth chunks
are the world-positioned scenic underlay band; they do **not** replace the macro
terrain stamps, cliff faces, or playable TileMap semantics. The 32×32 semantic
grid remains authoritative for walkability, collision, and navigation.

---

# 1. Family identity

**Family ID**

```text
procgen_depth_chunks_v1
```

**Source-work family**

```text
custodian/asset_drop/source_work/procgen_depth_chunks_v1/
```

**V2 family recommendation**

```text
procgen_depth_chunks
```

**Runtime ownership**

```text
res://content/sprites/environment/procgen_depth/
```

These assets are:

* presentation-only
* non-colliding
* non-navigable
* world-positioned
* biome-aware
* seeded/deterministically selected
* allowed to overlap generated terrain beneath the terrain edge
* never allowed to imply reachable ground

---

# 2. Production size classes

The generated artwork should remain untouched as **source masters**.

Do not manually squash the generated masters directly into runtime.

Use Asset Pipeline V2 normalization to create derivatives.

| Class      | Runtime canvas | Logical footprint |
| ---------- | -------------: | ----------------: |
| **LARGE**  |      `896×576` |      ~28×18 cells |
| **MEDIUM** |      `640×448` |      ~20×14 cells |

The logical footprint is only a placement envelope.

The alpha silhouette should remain irregular.

The visible artwork does **not** need to fill the entire canvas.

---

# 3. Core visual contract

All nine assets must obey the same production language.

## Perspective

Top-down / 2.5D.

They should match the world camera, not side-scrolling perspective and not full
isometric 45° architecture.

Vertical relief is welcome, especially for:

* ravines
* retaining walls
* cliff faces
* foundation cavities

but the player should still perceive the composition primarily from above.

## Detail hierarchy

The chunks should be:

**most detailed near the terrain-facing edge**

then progressively quieter toward deeper background space.

Target:

```text
upper / terrain-contact 25%
HIGH detail

middle 45%
MEDIUM detail

deep / outer 30%
LOWER detail + deeper shadow
```

That lets playable terrain visually overlap the chunk without the underlay
fighting the player.

## Color

Universal base palette:

```text
charcoal
graphite
weathered concrete gray
dirty warm gray
deep earth brown
oxidized iron
muted olive
restrained moss/vegetation
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

No high-saturation scenery.

The playable surface must retain stronger gameplay contrast than the depth
chunks.

---

# 4. Alpha contract

Every master must have:

```text
RGBA
true transparent exterior
irregular silhouette
no rectangular matte
```

Before V2 ingest:

```text
alpha <= ~16
→ clean to 0
```

But preserve intentional partial alpha where it exists naturally around:

* foliage edges
* fine roots
* mist
* water spray
* deep atmospheric edges

Do **not** binary-alpha the whole family automatically.

These assets contain much finer natural edges than Operator sprites.

---

# 5. Lighting contract

All nine should assume:

```text
soft overcast / diffuse top lighting
```

Avoid strongly baked directional sunlight.

Why?

Because these chunks need to survive:

* dawn
* midday
* dusk
* night
* overcast
* rain
* mist

under the environment compositor.

Baked lighting can establish form, but not a strong fixed sun direction.

## Relative brightness

Depth chunks should generally render approximately:

```text
10–25% darker
```

than neighboring playable terrain before runtime atmospheric treatment.

Especially avoid bright open dirt patches that look walkable.

---

# 6. Terrain-contact edge

Each asset needs one intentional **terrain overlap zone**.

For most of these, that is the upper portion of the image.

Target:

```text
20–25% of chunk height
```

The playable terrain and cliff system may overlap this region.

Artwork there should include things that naturally disappear underneath another
layer:

* broken slabs
* rock ledges
* roots
* retaining structures
* earth
* scattered debris
* vegetation

Do not place a hero focal object immediately on the overlap edge.

---

# 7. Asset 01

## `depth_civic_foundation_breach_v1.png`

**Class:** LARGE
**Runtime:** `896×576`

## Role

Universal structural hero chunk.

This should be one of the most reusable depth assets in the entire system.

## Environmental read

> The playable land above was built, reinforced, or repeatedly repaired. Older
> infrastructure exists underneath it.

## Required composition

A massive partially buried civic foundation with:

* fractured composite retaining slabs
* exposed structural reinforcement
* broken concrete/composite decks
* rebar/reinforcement ribs
* dark support cavities
* buried conduits
* large pipe runs
* service channels
* drainage openings
* collapsed retaining walls
* rubble descending into the lower level
* inaccessible maintenance openings

## Upper overlap zone

Strong civic structure:

```text
broken plateau slab
retaining wall
reinforcement
conduit
rock/earth
```

The playable level can visually sit directly on top of it.

## Middle

The structure opens up.

Show:

* collapsed cavities
* fallen beams
* service recesses
* exposed pipe banks
* ruined access tunnels

## Deep edge

Should dissolve visually into:

* rubble
* darkness
* earth
* shadowed infrastructure

## Avoid

* intact door inviting exploration
* brightly illuminated corridors
* obvious usable staircase
* faction insignia
* religious architecture
* magical technology
* giant readable signage

## Placement tags

```text
universal
constructed_edge
foundation
civic
large_void
compound_adjacent
```

## Preferred topology

```text
EDGE_LONG
EDGE_LARGE_VOID
EDGE_CONCAVE
```

---

# 8. Asset 02

## `depth_fractured_ravine_v1.png`

**Class:** LARGE
**Runtime:** `896×576`

## Role

Universal natural/structural depth separator.

## Read

> This is genuinely below the playable level.

It should produce one of the clearest vertical-depth reads.

## Composition

A strong diagonal ravine.

Include:

* uneven rock walls
* fractured ledges
* narrow dark depth channel
* collapsed retaining structures
* rubble caught on ledges
* exposed roots
* modest vegetation
* old concrete fragments
* possibly a subtle water trace

The central channel should remain **visually unwalkable**.

## Direction

Primary authored orientation:

```text
NW → SE
```

Runtime may allow:

```text
horizontal flip
```

to achieve:

```text
NE → SW
```

provided the lighting still works.

## Deepest zone

Use:

* near-black rock
* deep water/shadow
* vertical surfaces
* debris

No clean flat valley floor.

## Placement tags

```text
universal
ravine
natural
structural_decay
large_gap
```

## Preferred topology

```text
EDGE_GAP
EDGE_LONG
EDGE_LARGE_VOID
```

---

# 9. Asset 03

## `depth_service_infrastructure_field_v1.png`

**Class:** MEDIUM
**Runtime:** `640×448`

## Role

Universal industrial background chunk.

## Read

> The player is seeing the utility layer that normal functioning districts
> tried not to think about.

This should feel ugly, functional, buried and redundant.

## Composition

Include:

* dead cable trenches
* armored pipe runs
* buried conduit banks
* half-submerged junction boxes
* broken utility vaults
* composite service pads
* collapsed maintenance grating
* low retaining structures
* muddy depressions
* one broken pole/gantry base

Not a building.

There should be **no obvious architectural center**.

## Detail distribution

Perimeter:

* pipes
* concrete
* cable trench
* supports

Center:

* darker disturbed ground
* gravel
* mud
* scattered structural debris

## Placement tags

```text
universal
infrastructure
utility
constructed
service
carrow_compatible
```

## Preferred topology

```text
EDGE_LONG
EDGE_CONCAVE
constructed_region
compound_region
```

---

# 10. Asset 04

## `depth_talus_and_rubble_shelf_v1.png`

**Class:** MEDIUM
**Runtime:** `640×448`

## Role

Universal neutral glue chunk.

This one should appear frequently.

## Composition

A broad broken slope containing:

* angular rock
* talus
* gravel
* fragmented concrete
* fallen slab pieces
* dust
* small soil pockets
* extremely sparse vegetation
* occasional exposed reinforcement

No major landmark.

No huge pipe.

No hero structure.

## Read

> There is damaged lower terrain beneath this ledge.

It should disappear into the scene rather than demand attention.

## Placement tags

```text
universal
neutral
rubble
talus
fallback
```

## Preferred topology

Essentially everything:

```text
EDGE_LONG
EDGE_CORNER
EDGE_CONCAVE
EDGE_SMALL_VOID
EDGE_LARGE_VOID
```

This should be the **fallback chunk** if the placement system cannot find a
stronger semantic match.

---

# SCRUBLAND FAMILY

Scrubland should mean:

```text
wind-beaten
dry
eroded
sparse
abandoned
```

not:

```text
desert
sand
cowboy
mesa
dunes
```

---

# 11. Asset 05

## `depth_scrubland_dry_basin_v1.png`

**Class:** LARGE
**Runtime:** `896×576`

## Role

Primary scrubland large-void chunk.

## Composition

A broad lower-elevation basin with:

* pale compacted ground
* exposed dark bedrock
* low erosion channels
* gravel
* sparse brush
* dead grasses
* small concrete fragments
* abandoned utility stakes
* occasional drainage remnants

## Center

The center must be intentionally subdued.

Broad:

```text
dust / gravel / eroded earth
```

with minimal focal content.

The perimeter can be busier.

## Important readability rule

Do not allow the broad center to look like a convenient alternate walking area.

Use:

* elevation cues
* darker edge rock
* irregular surface
* surrounding cliffs
* broken terrain

to make the lower elevation clear.

## Placement tags

```text
scrubland
basin
large_void
dry
```

## Preferred topology

```text
EDGE_LARGE_VOID
EDGE_CONCAVE
```

---

# 12. Asset 06

## `depth_scrubland_wash_channel_v1.png`

**Class:** MEDIUM
**Runtime:** `640×448`

## Role

Scrubland linear depth feature.

## Composition

A diagonal old runoff corridor.

Include:

* dry channel
* gravel bed
* darker sediment
* erosion grooves
* fractured culvert
* pipe remnants
* sparse brush
* gravel bars
* broken retaining pieces

## Direction

Author one strong diagonal.

Runtime flip allowed if visually acceptable.

The feature should meander slightly rather than form a straight line.

## Important rule

The channel should **not read as a road**.

Avoid:

* symmetrical lanes
* consistent width
* clean shoulders
* obvious drivable surface

## Placement tags

```text
scrubland
wash
drainage
erosion
linear
```

## Preferred topology

```text
EDGE_LONG
EDGE_GAP
```

---

# 13. Asset 07

## `depth_scrubland_service_scar_v1.png`

**Class:** MEDIUM
**Runtime:** `640×448`

## Role

Scrubland infrastructure/reclamation chunk.

## Read

> This used to be a service route. It is not one anymore.

## Composition

Include:

* two parallel disturbed-ground scars
* fractured hardstand
* broken service paving
* abandoned cable trench
* shrubs through cracks
* one smashed utility cabinet
* drainage edge
* concrete debris
* buried conduit

The scars should be incomplete and disrupted.

## Critical readability

Do not create an intact road.

Break the visual continuity with:

* vegetation
* collapse
* missing surface
* rubble
* displaced slab fragments

## Placement tags

```text
scrubland
infrastructure
service_scar
reclaimed
constructed_decay
```

## Preferred topology

```text
EDGE_LONG
constructed_region
former_route
```

---

# WOODLAND FAMILY

Woodland should feel:

```text
dense
low
shadowed
reclaimed
structurally layered
```

but not lush fantasy wilderness.

There should remain occasional evidence of old infrastructure.

---

# 14. Asset 08

## `depth_woodland_canopy_basin_v1.png`

**Class:** LARGE
**Runtime:** `896×576`

## Role

Primary woodland large-void chunk.

## Composition

Dense lower canopy viewed from above:

* clustered tree crowns
* irregular canopy density
* dark understory
* exposed rocks
* moss
* fallen trunks
* root systems
* canopy openings
* one faint buried service line
* small old utility fragment

## Upper contact zone

Needs exposed:

* cliff
* soil
* roots
* stone

before dropping into foliage.

This is important because the playable terrain needs to appear physically above
the canopy.

## Canopy variation

Avoid a repeated "tree-ball texture."

Use:

```text
large crowns
small crowns
dark gaps
fallen tree
rock interruption
root interruption
understory opening
```

The player should be able to recognize the authored composition.

## Placement tags

```text
woodland
canopy
basin
large_void
vegetation
```

## Preferred topology

```text
EDGE_LARGE_VOID
EDGE_CONCAVE
```

---

# 15. Asset 09

## `depth_woodland_ravine_v1.png`

**Class:** LARGE
**Runtime:** `896×576`

## Role

Woodland hero depth chunk.

This should be one of the strongest scenic pieces in the family.

## Composition

Deep wooded ravine with:

* fractured stone walls
* heavy root systems
* trees at multiple apparent elevations
* fallen logs spanning inaccessible gaps
* dark central water/shadow
* moss
* broken retaining slabs
* collapsed culvert
* pipe crossing
* small waterfalls/runoff if present
* vegetation hanging over structural ruin

## Visual hierarchy

The central ravine must remain clearly deeper than the woodland canopy around
it.

Use:

```text
dark water
vertical rock
root descent
fallen logs
deep shadow
```

## Infrastructure

One collapsed piece only needs to carry the CUSTODIAN language:

* culvert
* retaining wall
* pipe
* broken service crossing

Do not overload it with machinery.

## Placement tags

```text
woodland
ravine
hero_depth
water
structural_decay
```

## Preferred topology

```text
EDGE_GAP
EDGE_LONG
EDGE_LARGE_VOID
```

---

# 16. Production filenames

Use exactly:

```text
depth_civic_foundation_breach_v1.png
depth_fractured_ravine_v1.png
depth_service_infrastructure_field_v1.png
depth_talus_and_rubble_shelf_v1.png

depth_scrubland_dry_basin_v1.png
depth_scrubland_wash_channel_v1.png
depth_scrubland_service_scar_v1.png

depth_woodland_canopy_basin_v1.png
depth_woodland_ravine_v1.png
```

Do not append the generated source dimensions to canonical asset identity.

Source-master dimensions belong in provenance metadata, not filenames.

---

# 17. Runtime normalization

The source masters just generated should remain at maximum generation
resolution.

Pipeline:

```text
generated source master
        ↓
asset_drop/source_work/procgen_depth_chunks_v1
        ↓
V2 preparation
        ↓
trim only meaningless transparent border
        ↓
resize ONCE
        ↓
LARGE  → 896×576
MEDIUM → 640×448
        ↓
preserve alpha
        ↓
Asset Pipeline V2 ingest
```

Use **Lanczos** for the major source reduction, since these source masters are
high-resolution rendered artwork rather than already-native pixel art.

After downsampling, do a restrained pixel-art compatibility pass if the rest of
the world requires it.

Do not:

```text
downsample
→ upscale
→ downsample again
```

One normalization pass only.

---

# 18. Important pixel-art note

These generated chunks are deliberately much more detailed than the runtime
world assets.

Do **not** force them into crude pixelization immediately.

At actual gameplay scale, downsampling from ~1500 px to 896 or 640 will already
condense detail substantially.

Evaluate them in runtime first.

If they still look too photographic relative to the rest of CUSTODIAN, apply a
**family-wide normalization pass**, not individual hand edits:

```text
shared color quantization
subtle edge cleanup
minor local contrast reduction
```

Do not individually paint over all nine unless runtime proves it necessary.

---

# 19. Runtime contrast treatment

The raw files should preserve their detail.

Runtime presentation should control their hierarchy.

Recommended starting presentation:

```text
modulate brightness ≈ 0.78–0.88
saturation ≈ 0.80–0.90
contrast slightly reduced
```

Then biome/environment/day/weather can modify them further.

This is much better than permanently crushing the source art.

---

# 20. Placement density

Do not carpet the void with these.

A normal camera view should probably show:

```text
0–2 major chunks
```

rather than five overlapping scenic plates.

Suggested approximate selection:

```text
60% neutral/universal
40% biome-specific
```

Within universal:

```text
talus/rubble shelf
most common

service infrastructure
moderate

fractured ravine
less common

civic foundation breach
rare/hero
```

Within woodland:

```text
canopy basin
common

woodland ravine
rare
```

Within scrubland:

```text
dry basin
common

wash channel
moderate

service scar
less common
```

---

# 21. Chunk overlap

Allow chunks to overlap each other.

Recommended:

```text
32–96 px
1–3 world cells
```

But overlap should occur primarily at:

* rock
* earth
* rubble
* vegetation

Avoid overlapping focal infrastructure over focal infrastructure.

Bad:

```text
utility cabinet
on top of
broken culvert
on top of
foundation door
```

Good:

```text
talus edge
over
ravine rock edge
```

---

# 22. Deterministic transformation

Runtime can safely use:

```text
horizontal flip
```

on most natural chunks.

Potentially allow limited rotation only for near-top-down chunks:

```text
0°
180°
```

Do **not** freely rotate every chunk by 90°.

Some of these have strong perspective and terrain-facing orientation.

For V1:

```text
rotation = 0
flip_x = allowed selectively
```

is safer.

---

# 23. Suggested semantic metadata

Each chunk should eventually carry something equivalent to:

```json
{
  "id": "depth_woodland_ravine_v1",
  "biomes": ["woodland"],
  "size_class": "large",
  "topologies": [
    "edge_gap",
    "edge_long",
    "edge_large_void"
  ],
  "weight": 0.35,
  "allow_flip_x": true,
  "terrain_contact_edge": "north",
  "collision": false,
  "navigation": false,
  "presentation_only": true
}
```

Universal assets:

```json
"biomes": ["*"]
```

This metadata should control selection.

Do not infer semantic purpose from filename parsing at runtime.

---

# 24. Placement clearance

Depth chunks must never create a visual contradiction underneath:

* major building interiors
* authored connected maps
* transfer sequences
* explicit black/void presentation regions
* special hero connectors that own their own backdrop

So chunk placement should respect presentation exclusion regions.

Carrow itself is a perfect example.

The Machine House interior should **not** inherit these chunks merely because
the camera happens to move over their world coordinates.

---

# 25. Connected-map isolation

This family belongs to the **procgen exterior presentation stack**.

When transitioning:

```text
procgen world
→ Carrow Yard connected map
```

the procgen depth-chunk root should be hidden.

When transitioning back:

```text
Carrow Yard
→ procgen
```

restore it.

Same for:

```text
East Machine House interior
```

No woodland basin behind the electrical room ever again.

---

# 26. Far backdrop after this change

The current camera-following forest should no longer be the dominant
environment.

Once these chunks ship, the surviving FAR layer should become extremely
restrained.

Something closer to:

```text
haze
distant relief
very dark canopy suggestion
distant rock mass
atmospheric gradient
```

at perhaps:

```text
0.15–0.30 alpha
```

depending on profile.

The authored chunks provide the tangible world.

The FAR layer provides atmosphere.

---

# 27. Near-depth relationship

These chunks do **not** replace cliff faces.

Near edges should still be rendered with:

* `ProcgenVoidCliffFace`
* terrain-derived rock edges
* retaining structures
* edge transitions

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

The chunk starts visually underneath the cliff.

That's what makes the landmass stop looking pasted onto a scenic background.

---

# 28. V2 asset family split

Use **three V2 families**, rather than one giant family:

```text
procgen_depth_universal
procgen_depth_scrubland
procgen_depth_woodland
```

## Universal

```text
civic_foundation_breach
fractured_ravine
service_infrastructure_field
talus_and_rubble_shelf
```

## Scrubland

```text
dry_basin
wash_channel
service_scar
```

## Woodland

```text
canopy_basin
ravine
```

That makes later expansion clean:

```text
procgen_depth_wetland
procgen_depth_rocky_upland
```

without rewriting an enormous family contract.

---

# 29. Source directory

Save the nine generated masters exactly here:

```text
custodian/asset_drop/source_work/
procgen_depth_chunks_v1/
```

with the nine canonical filenames.

Do not put them straight into `content/`.

Then do the same process established with Carrow:

```text
SOURCE MASTER
        ↓
V2 prep
        ↓
review contact sheet
        ↓
asset_drop/inbox/<family>
        ↓
asset plan
        ↓
asset ingest
        ↓
canonical runtime
```

---

# 30. Minimum runtime test scene

Before wiring this into full procgen, build one test scene:

```text
DepthChunkReview.tscn
```

It should show:

```text
generated-looking playable plateau
cliff edge
one depth chunk
far background
operator for scale
```

with hotkeys to cycle:

```text
1 universal
2 scrubland
3 woodland

F flip
N next
B previous
```

and maybe:

```text
day/night preview
weather preview
```

This will tell us very quickly whether the assets need further normalization.

---

# 31. Definition of Done

The nine-chunk family is production-ready when:

* every master exists under `source_work`
* true alpha is verified
* no rectangular matte survives
* LARGE outputs are exactly `896×576`
* MEDIUM outputs are exactly `640×448`
* no runtime code references source masters
* V2 catalog owns all runtime outputs
* chunks are placed in world space
* chunks never follow the camera
* chunks do not affect navigation
* chunks do not affect collision
* chunks are selected deterministically
* biome eligibility is respected
* geometry topology influences chunk choice
* connected maps suppress procgen depth presentation
* playable terrain visually overlaps the chunk contact zone
* FAR backdrop is subordinate
* nighttime/weather still preserve scene readability
* normal gameplay does not mistake underlay terrain for reachable space

---

# Current State

The nine generated masters give a surprisingly good first library:

```text
UNIVERSAL
├── civic foundation breach
├── fractured ravine
├── service infrastructure field
└── talus/rubble shelf

SCRUBLAND
├── dry basin
├── wash channel
└── reclaimed service scar

WOODLAND
├── canopy basin
└── wooded ravine
```

That is already enough variety to completely replace the current "forest
wallpaper under everything" look for the first implementation.

Do **not** generate wetland and rocky upland yet. First get these nine
normalized and placed. If a procedural world using just these already looks
dramatically better, then the architecture works and the next art batch can
cover the remaining biome families rather than guessing.

**Track:** initial environment work = biomes + day/night + weather.
**Problem discovered:** current camera-following procgen underlay is
aesthetically weak and leaks into connected interiors.
**Decided replacement:** terrain-derived near edges + world-positioned
authored depth chunks + restrained far atmosphere.
**Current:** nine production source chunks covering universal, scrubland, and
woodland are generated and now have a complete production contract.
**Next:** Asset Pipeline V2 normalization/ingest → depth-chunk review scene →
topology-based procgen placement → then wetland/rocky-upland expansion if the
runtime proof succeeds.
