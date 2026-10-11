# Awakening — Dust Lung Cistern V2 Spatial + Presentation Design

Status: **active design lock / pre-production**  
Area: **Awakening Section 05 — Dust Lung Cistern**  
Phase: **ASCENT**  
Runtime cutover: **not yet landed; current Zone 05 remains production fallback until V2 is implemented and reviewed**  
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d

## 1. Purpose

The current Dust Lung is too small, too self-contained, and too room-like for its
narrative and gameplay role. V2 supersedes the old "single room with a central
hole" presentation target with a **region-scale ruptured cistern complex**.

The player should understand, before any explanatory text, that they are moving
through one surviving fragment of a much larger failed piece of civic-industrial
infrastructure.

The core fantasy is:

> **A damaged route through an enormous dry cistern system. The obvious route is
> broken. One stubborn service lift still provides ascent through the ruins.**

This is the Awakening's first shocking reveal of institutional scale and
collapse. It is not an arena and not a decorative pit.

## 2. Authority and migration boundary

Until the V2 runtime cutover lands:

- `custodian/game/world/awakening/awakening_layout.gd` remains the live gameplay
  authority for Zone 05 traversal, collision, void, markers, lift stations,
  connectors, and progression.
- `awakening_dust_lung_environment` remains the current production visual
  fallback.
- The accepted 04→05 Locker/Dust registration remains live production truth.
- V2 design may reauthor Zone 05 geometry, markers, camera reveal, and Dust-side
  connector presentation, but it **must preserve the semantic route** from Locker
  Reliquary through Dust Lung to Undergate and must not mutate Locker or Undergate
  geometry merely to make art fit.
- Asset art is presentation. It never owns collision, navigation, progression,
  interaction activation, or fall/void authority.

When V2 is implemented, `awakening_layout.gd` must be updated from this spec in
one bounded spatial-authority cutover rather than letting art sprites become
implicit collision truth.

## 3. Reference composition

The accepted planning composition in the Authoring chat is a **1536×2048**
north-up collage assembled from the generated Dust Lung plates. It is the visual
geography reference for DL0 planning, not a runtime texture.

Measured source reuse in that composition is internally consistent at roughly
**0.512× source scale with zero rotation**, which is strong evidence that the
final modular environment can be registered without stretching.

Reference coordinate convention for this document:

- origin: top-left of the 1536×2048 planning composite;
- +X: east;
- +Y: south;
- north/Undergate: top;
- Locker ingress: lower/southeastern side;
- numbers below are planning-reference pixels, not yet world coordinates.

The primary recovered plate placements are approximately:

| V2 role | Planning reference bounds | Source role |
|---|---:|---|
| `north_upper_works` | x -19..889, y 100..554 | upper routeworks / Undergate approach |
| `central_broken_service_spine` | x 346..902, y 736..1478 | main damaged horizontal route |
| `deep_cistern_field` | x 814..1455, y 934..1576 | scenic depth / distant shaft |
| `cistern_core` | x 791..1433, y 1129..1771 | major lower rupture / vista |
| `south_ingress_transition` | x 611..1520, y 1471..1926 | Locker-side surviving platform |

The earlier concept of placing a full `east_lift_works` plate in the large
northeast gap is **superseded**. The lift belongs in the **western/central vertical
service stack** identified in the accepted red/green route markup.

## 4. Spatial identity

Dust Lung V2 is an irregular chain of connected cistern volumes and broken
service structures. It should read as infrastructure that continues beyond the
camera in multiple directions.

Required visual roles:

1. **North upper works**
   - compressed, more institutional upper route;
   - surviving service deck toward Undergate;
   - visual transition toward Zone 06 routeworks.

2. **Western lift/service stack**
   - the critical vertical traversal machine;
   - clearly readable lower station, shaft machinery, cables/counterweights, and
     upper landing;
   - not a clean elevator lobby; it is a maintenance mechanism that has somehow
     continued functioning.

3. **Central broken service spine**
   - the primary horizontal traversal after the first vista;
   - broad enough for ordinary Operator movement and combat readability;
   - visibly damaged and surrounded by inaccessible collapse.

4. **Major cistern rupture**
   - enormous dry shaft/reservoir depth;
   - multiple lower maintenance rings, pipes, tiny service lights, haze, mineral
     residue;
   - visually dominant but not itself traversable.

5. **South ingress platform**
   - the comparatively intact handoff from Locker Reliquary;
   - retains some ordered Locker-compatible proportions and brass/grate language,
     then degrades quickly into Dust Lung rupture language.

6. **Distant infrastructure**
   - secondary shafts, broken catwalks, pipe galleries, lower decks and tiny
     service lights;
   - mostly inaccessible;
   - lower contrast than active traversal.

## 5. Locked gameplay route

The accepted main route follows the user's red-line markup and the western lift
shown in green.

### 5.1 Route topology

```text
LOCKER RELIQUARY
      ↓
South / southeast ingress platform
      ↓
First cistern vista and route-failure read
      ↓
Main lower service route travels WEST across the broken spine
      ↓
Lower western lift station + lever
      ↓
VERTICAL ASCENT through the western service stack
      ↓
Upper western lift landing
      ↓
Upper route travels EAST / NORTH through north_upper_works
      ↓
UNDERGATE EXIT
```

The large northeast black region in the planning collage is **not required main
route space**. It may remain atmospheric void, distant inaccessible structure, or
receive later scenic support only if camera coverage needs it.

### 5.2 Planning-reference route bands

The accepted red/green markup maps into the 1536×2048 reference approximately as:

- **lower main route:** x ≈ 313..863, y ≈ 825..950;
- **lower lift approach / station pocket:** x ≈ 366..507, y ≈ 796..895;
- **vertical lift stack:** x ≈ 271..358, y ≈ 529..805;
- **upper lift landing / western connection:** x ≈ 216..358, y ≈ 461..563;
- **upper route to Undergate:** x ≈ 326..457, y ≈ 174..497;
- **Undergate exit center:** approximately x ≈ 430..450, y ≈ 150..190.

These bands lock **geography and topology**, not final collision contours.
Implementation DL0 must derive final world-space polygons from the actual
registered V2 plates and maintain safe Operator clearance.

## 6. Gameplay mechanics

### 6.1 Main traversal

Dust Lung should be a short authored traversal sequence, not a giant open room:

1. emerge from comparatively controlled Locker architecture;
2. receive a scale reveal over the failed cistern complex;
3. discover the obvious/direct route is broken;
4. travel west along the surviving damaged service spine;
5. discover and operate the western maintenance lift;
6. ascend through the open cistern machinery;
7. cross the upper landing/routeworks;
8. enter Undergate.

### 6.2 Void / fall readability

The cistern shafts are hard non-traversal space.

- Walkable surfaces must be broad, continuous, and visually distinct.
- Inaccessible scenic galleries must be narrower, visibly broken, disconnected,
  or separated by obvious depth.
- Do not create visually inviting intact platforms that collision arbitrarily
  forbids.
- V2 implementation may choose the existing fail-safe boundary behavior rather
  than literal player death if current Awakening rules do not support lethal
  falling; the art language is still "hard void / no traversal."

### 6.3 Transit lift

The existing `AwakeningTransitLift` gameplay owner remains the intended
interaction authority.

Required presentation around it:

- a readable lower station pad;
- one obvious lever/control location;
- vertical rails/cable/counterweight machinery visible before interaction;
- a coherent upper receiving landing;
- enough safe standing room at both stations for the Operator;
- no need for a giant separate east-side lift hall.

The actual lift body/lever should remain separate interactive presentation where
possible instead of being irreversibly baked into an underlay.

### 6.4 Camera / vista

The old single-room reveal is not sufficient for V2.

The first Dust Lung reveal should frame **scale and route failure**, not the whole
zone at once. Preferred behavior:

1. entering from Locker opens the camera enough to show the major rupture and
   distant rings;
2. the player can still read the lower main route;
3. the lift is discovered through traversal rather than centered immediately;
4. upper Dust Lung compresses visually toward Undergate.

Do not require one camera shot to expose every V2 plate.

### 6.5 Encounter space

The existing `scavenger_nest` remains a **future/deferred encounter marker**
unless a separate gameplay packet enables it.

If retained in V2, place it off the critical lower route near a readable side
pocket so it can become a threat/optional encounter later without blocking the
lift path.

## 7. Points of interest and interactibles

V2 should retain or replace these semantic POIs:

| POI | Role | Required |
|---|---|---:|
| `dust_lung_ingress` | Locker → Dust handoff | yes |
| `cistern_reveal` | first scale/vista moment | yes |
| `broken_primary_route` | communicates route failure | yes |
| `lift_lower` | lower lift station | yes |
| `lift_lever` | critical interactible / affordance | yes |
| `lift_upper` | upper lift station | yes |
| `daylight_split` | cold failing daylight landmark | yes |
| `undergate_exit` | Zone 05 → Zone 06 transition | yes |
| `scavenger_nest` | future encounter pocket | deferred |
| `central_shaft` | scenic/telemetry marker only | optional |

The old `lift_mechanism` orphan marker should not survive as a second ambiguous
interactable. Either fold its presentation identity into the real lift/lever
contract or delete it during the spatial cutover.

## 8. Material and lighting identity

Dust Lung V2 material language:

- cold charcoal stone and blackened industrial masonry;
- rusted / oil-dark pipe iron;
- chalky mineral deposits and dried reservoir staining;
- ashen sediment;
- broken / interrupted brass institutional inlays;
- sparse cyan/teal service lights used as scale markers;
- diluted pale-blue daylight entering through one or more structural ruptures.

Progression contrast:

```text
Locker Reliquary
sealed / ordered / designation-controlled
        ↓
Dust ingress
same institutional ancestry, visibly stressed
        ↓
Dust Lung
breached / enormous / vertical / dry / failing
        ↓
Undergate
compressed oil-dark route machinery
```

The WorldLightingDirector remains lighting authority. Underlays must not bake a
global vignette that fights runtime lighting.

## 9. Plate / seam strategy

The environment is modular. Do not replace it with one 4096×4096 monolith.

### 9.1 Required major plate roles

- `north_upper_works`
- `central_broken_service_spine`
- `cistern_core`
- `deep_cistern_field`
- `south_ingress_transition`
- `western_lift_spine` — new bespoke V2 plate built around the accepted green
  lift location rather than the superseded east-side concept.

### 9.2 Critical seams

**S1 — Lower route join**  
Where the south/cistern presentation meets the central broken service spine.
This is on the critical route and must become continuous broad floor with a
truthful broken edge.

**S2 — Western lift bridge**  
The vertical gap between the lower broken service spine and north upper works.
This is no longer a generic black gap. It is the lift mechanic and must be
resolved with the dedicated western lift plate plus bounded splice overlays.

**S3 — Depth overlap**  
Where `central_broken_service_spine`, `cistern_core`, and
`deep_cistern_field` overlap. Use one depth owner and alpha/z-order; do not
double-render incompatible rings/pipes.

**S4 — Locker-side material handoff**  
The south ingress should intentionally move from controlled Locker proportions
to Dust Lung degradation. This should be a designed transition, not a perfectly
invisible clone of Locker and not an abrupt tileset swap.

### 9.3 Do not fill every black region

Black planning gaps fall into three classes:

1. critical-route gaps → require real connective presentation;
2. scenic gaps → deep cistern wall / haze / distant structures;
3. off-camera or true abyss → may remain unfilled.

Filling every gap with playable-looking architecture would make Dust Lung feel
smaller.

## 10. Presentation hierarchy

Front-to-back target:

1. deep atmospheric cistern field;
2. distant pipe/ring infrastructure;
3. major underlay plates;
4. walkable-route splice overlays;
5. runtime props / interactibles / lift;
6. Operator;
7. bounded local foreground occluders.

The exact runtime z values are implementation-owned. The hierarchy, however, is
locked.

Distant/scenic structures must be lower contrast than canonical traversal and
interactible presentation.

## 11. V2 footprint

The 1536×2048 planning composition represents a much larger native environment.
Because the current plates were composed at roughly 0.512 source scale, a
straight native-scale projection is approximately:

- **visual footprint:** ~3072×4096 world/pixel units before any optional scenic
  extension;
- **playable footprint:** intentionally much smaller than the visual footprint;
- **main-route width:** implementation must support real Operator clearance,
  combat readability, and safe lift staging rather than blindly scaling old
  128px corridors.

The visual environment should be at least ~4× the perceived scale of the old
single-room Dust Lung without turning all visible infrastructure into traversable
floor.

## 12. Existing assets and reuse

Continue to reuse the canonical specialized Dust Lung gameplay presentation where
it remains appropriate:

- `awakening_dust_lung_lift`;
- `awakening_dust_lung_structures/lift_lever`;
- `awakening_dust_lung_structures/broken_bridge_a`;
- `awakening_dust_lung_structures/broken_bridge_b`;
- `awakening_dust_lung_structures/giant_duct`.

Published fixture art that is currently `BAKED_ONLY` / `NOT_READY` is not
automatically authorized for duplicate standalone placement. The V2
implementation must resolve consumption status explicitly.

## 13. Supersession

This document supersedes the **Zone 05 assumption** in
`AWAKENING_PERIMETER_SUPPORT_V1.md` that Dust Lung will keep its existing room
plate and receive only the generic three-state perimeter-support treatment.

Specifically:

- do **not** generate `awakening_dust_lung_perimeter_support` from the old
  generic 512×512 / 1024×512 / 256×256 plan;
- Dust Lung now receives a full modular V2 environment reauthor;
- the generic perimeter-support strategy remains valid for other Awakening zones
  unless separately superseded.

The existing live V1 environment is not deleted until V2 runtime validation and
human review pass.

## 14. Implementation acceptance

Before V2 can replace the live Dust Lung:

1. the final world-space V2 layout preserves continuous Locker → Dust →
   Undergate traversal;
2. the accepted red-line lower route and western lift topology are represented;
3. lift lower/upper stations have safe Operator staging;
4. canonical walkable floor, inaccessible structure, and hard void are
   unambiguous in both art and Layout;
5. no visual platform strongly promises traversal where Layout denies it;
6. the major plates register without nonuniform stretching;
7. critical-route seams are objectively covered with no black holes or doubled
   floor;
8. depth overlaps have one clear z/alpha owner;
9. existing progression and lift behavior remain deterministic;
10. a compact gameplay-scale human review approves scale, route readability,
    Locker→Dust transition, lift discoverability, and Dust→Undergate handoff.

## 15. Next production step

Use `AWAKENING_DUST_LUNG_V2_ASSET_MANIFEST.md` to generate and review the new
V2 underlay set. Do not implement final Zone 05 collision from unreviewed source
art. After the required source plates are approved, author the bounded DL0
world-coordinate/layout implementation packet.
