# Ash-Bell — Bridged Falls / Lower Quarter Approach

**Status:** locked design  
**Date:** 2026-10-07  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c  
**Scope:** Ritualant north egress -> generated Alpine Highlands -> generated Bridged Falls -> Lower Quarter edge / Station IX vista  
**Implementation roadmap:** `design/05_levels/ASH_BELL_BRIDGED_FALLS_IMPLEMENTATION_ROADMAP.md`

## Design Lock

Bridged Falls is the physical transition between the Ash-Bell highlands and the
Lower Quarter lowlands.

The required world read is:

> cold alpine highlands descend toward a vast river-and-waterfall basin where
> colossal, partly ruined Meridian civic bridges span mist-filled drops; the
> Lower Quarter occupies the civic lowlands at and beyond the waterfall edge,
> while Station IX remains a distant skyline attractor.

The emotional target is a sunset waterfall ruin-city with very large broken
bridges looming through mist. Niagara-scale falls and civic infrastructure
supply the vertical spectacle; the Meridian ruin language supplies the setting.
The player must feel that the bridge system was once ordinary public-scale
infrastructure for a much larger civilization, not a bespoke fantasy dungeon.

The user-approved visual composition is recorded in the 2026-10-07 authoring
chat. If a durable image copy is added later, place it at:

`design/05_levels/reference/bridged_falls/bridged_falls_design_lock_v1.png`

That image is composition/art-direction authority only. Runtime topology remains
generated and must not hard-code the illustrated route.

## Geographic Topology

```text
CURRENT CAMPAIGN PROCGEN
        |
        v
ASH-BELL SURFACE LIFT
        |
        v
FORLORN RITUALANT UNDERGROUND
        |
        | post-resolution north egress
        v
ASH-BELL ALPINE HIGHLANDS
generated route region
        |
        v
CLIFF DESCENT / FIRST BASIN REVEAL
        |
        v
BRIDGED FALLS
generated bridge-and-waterfall subregion
        |
        v
LOWER QUARTER EDGE
        |
        v
LOWER QUARTER -> WEST GATE WORKS / STATION IX
```

The Ritualant chamber is therefore a through-route, not an isolated special
room. Its south side remains the lift/return relationship; its north side is
withheld until the encounter is resolved.

## Procgen Lock

Both the **Alpine Highlands destination** and **Bridged Falls** are generated.

Bridged Falls is not a fixed authored bridge corridor with randomized dressing.
Every accepted seed must produce a new traversable bridge network while
preserving the same macro narrative beats.

Required generated beats:

1. Highlands entry from the Ritualant seam.
2. Ordinary highland traversal before the destination dominates the frame.
3. Cliff descent/compression.
4. First basin reveal.
5. Bridge-head commitment.
6. A convoluted multi-span Bridged Falls traversal.
7. One or more optional overlooks/branches that improve scale and route variety.
8. Lower Quarter threshold / onward route terminal.

The generator may vary bridge count, bend order, branch placement, overlook
location, broken-span composition, civic ruin pockets, and shortcut structure.
It may not remove the entry-to-terminal critical path or reorder the first-basin
reveal after the bridge commitment.

### Bridge-network target

The first production target is:

- 5–9 major traversable bridge spans on the accepted critical route;
- 2–4 civic ruin/terrace nodes between or beside spans;
- 1–3 optional branch loops or overlook spurs;
- 0–2 seeded shortcuts when topology can support them without bypassing the
  required reveal/commit beats;
- at least one long visual span that reads materially larger than ordinary road
  or causeway content;
- deterministic output for one seed and meaningful route variation across seeds.

These are authoring/tuning targets, not a requirement to encode arbitrary quota
checks into generic procgen.

## Top-Down Translation

The visual reference is deliberately grander and more side-on than the game
camera. Runtime must translate that feeling instead of imitating the camera.

Use:

- long bridge silhouettes running laterally/diagonally through the top-down view;
- large CHASM/exterior-negative spaces around bridges;
- playable bridge decks on the actual gameplay plane;
- world-positioned falls that visibly leave the gameplay plane and disappear
  into mist;
- mist/cloud layers that obscure the impossible river depth;
- near / middle / far separation;
- overlook pockets with deliberately protected sightlines;
- Lower Quarter and Station IX as low-contrast far presentation until the final
  approach;
- cliff edges and bridge heads as composition frames.

Do not use:

- side-view platforming;
- fake collision from painted waterfalls;
- giant foreground art that hides immediate combat/traversal;
- a flat panorama pretending to be navigable lower terrain;
- authored bridge art as walkability/navigation authority.

## Spatial Composition

### Near field

Gameplay-readable alpine/highland terrain:

- cold rock;
- conifers;
- scrub;
- sparse snow/frost;
- hard civic retaining work;
- bridge heads and traversable decks.

### Mid field

World-scale structure and atmosphere:

- immense ruined Meridian bridge piers;
- broken arches and public-infrastructure remnants;
- cliff faces;
- multiple waterfall tiers;
- spray clouds and river mist;
- civic terraces at inaccessible depth.

### Far field

Lowland world context:

- Lower Quarter basin;
- civic ruin silhouettes;
- Station IX vertical massing;
- pale river courses and terraces;
- warm sunset haze.

Station IX is a **silhouette cue and geographic attractor**, not a close hero
facade in the highlands.

## Region-Frame Relationship

The existing procgen presentation separation remains authoritative:

1. local biome field;
2. region frame;
3. Archive Resolve.

Bridged Falls must not become a biome.

The Alpine Highlands destination may begin with an Alpine-derived region frame.
The Bridged Falls portion uses a location-specific frame/underlay treatment that
introduces waterfall haze, the lowland basin, and Meridian skyline without
changing collision, navigation, local-biome classification, Archive Resolve, or
streaming authority.

## Gameplay Readability

Visual hierarchy at gameplay scale:

1. Operator / threat / immediate bridge edge;
2. traversable deck or highland floor;
3. next route connection or bridge head;
4. local cover / ruin mass;
5. waterfall and mist depth;
6. Lower Quarter / Station IX skyline.

Vista spectacle loses whenever it harms combat or traversal readability.

## Bridge Gameplay Grammar

Bridge walkability comes from generated semantic floor, never from sprite alpha.

Bridge generation may use:

- straight spans;
- slight bends and staggered heads;
- broken-but-rerouted spans;
- junction terraces;
- ruined civic platforms;
- side overlook spurs;
- large support piers and towers as presentation;
- occasional elevated-looking but gameplay-planar crossovers only when
  navigation/collision remains unambiguous.

Avoid a maze of tiny bridges. Convolution should come from **large-scale route
shape and intersecting civic infrastructure**, not noisy micro-pathing.

## Water And Falls

The river below is nonplayable depth presentation.

The Meridian civic falls should read as engineered public infrastructure that
water has reclaimed:

- spillways;
- retaining walls;
- enormous culverts or broken channels;
- civic bridge piers embedded in the fall edge;
- stepped falls;
- mist from several elevations.

Waterfall visuals may respond to generated CHASM/exterior geometry but never
create gameplay surface authority.

## Sunset / Atmosphere Lock

Preferred palette progression:

- near field: cool alpine stone, dark conifers, dirty snow;
- middle: blue-white spray, slate bridge stone, pale mist;
- far: warm lowland gold, pink-gray haze, desaturated civic silhouettes;
- lights: sparse amber institutional/work lamps.

The sunset treatment should feel epic and melancholy without turning traversal
into silhouette soup. Time-of-day systems may eventually vary lighting, but
this warm sunset state is the canonical art-direction review target.

## Lower Quarter Relationship

The existing `ash_bell_lower_quarter` authored route remains current runtime
truth until the final handoff slice.

The future Bridged Falls route must arrive at a named Lower Quarter approach
without cloning Lower Quarter state under a second route-state identity. The
final integration packet must re-derive the cleanest route-session handoff or
canonical route migration from landed lifecycle work before cutover.

The existing direct campaign ingress remains functional during construction and
is not deleted merely because the new geographic approach exists.

## Ritualant Presentation Integration

The existing distant-chapel presentation defect is part of the upstream route
closeout:

- actual arrival must activate `LANDING_VISTA`;
- the distant chapel remains visible through `UPPER_DESCENT`;
- it retires at `DEEP_CAVERN`;
- tests must exercise the real camera-zone/director path rather than directly
  calling the profile-change handler.

After encounter resolution, the northern Lower Quarter Seal stops being only a
visual tease and becomes the prelude to the Highlands egress.

## Anti-Drift

Reject implementation that primarily reads as:

- one authored bridge corridor with randomized props;
- generic fantasy aqueducts;
- tiny road bridges;
- a flat city backdrop;
- a second Alpine Plateau with a different wallpaper;
- a waterfall image that owns collision;
- a Lower Quarter teleport with no geographic approach;
- a route that duplicates Lower Quarter persistent/session state under another
  route ID;
- a fixed seed-independent bridge layout.

## Acceptance Vision

A player completing the Ritualant encounter should eventually be able to move
north, emerge into a generated alpine region, discover a fresh generated route
toward Bridged Falls, receive a first-basin reveal, traverse a large and
convoluted network of ruined Meridian bridges above immense mist-fed falls, and
arrive at the Lower Quarter with Station IX having remained a distant visual
anchor throughout the approach.
