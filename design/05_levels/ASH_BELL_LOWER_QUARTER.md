# Ash-Bell Lower Quarter / Station IX

**Status:** active implementation spec
**Route ID:** `ash_bell_lower_quarter`
**Runtime target:** Godot 4.x (`custodian/`)
**Canon authority:** `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md`

## Route Purpose

This route is the first playable reconstruction of the Ash-Bell Lower Quarter,
the optional West Gate Works branch, and Station IX. It is a route-complete,
traversal-complete, stateful first-pass blockout. `RouteTraversalManager` owns
destinations, transitions, session state, caching, and world-origin restoration;
the authored levels own only local geometry, interaction state, and generic exit
requests.

```text
@world_origin -> lower_quarter -> station_ix
                     |              |
                     v              v
               west_gate_works   lower_quarter
                     |
                     v
               lower_quarter -> @world_origin
```

West Gate Works and Station IX intentionally have no direct exfil. Both return
physically through the Lower Quarter.

## Canon Lock

The Meridian Office operated Stations I through IX under the Ash-Bell Protocol.
Precentor Orra was ordered directly to Station IX, diverted into the Lower
Quarter after a civilian evacuation route failed, and arrived after Stations
I–VIII had answered and IX had been classified `UNARRIVAL`. Her late Ninth
Answer terminated regional coupling after the Open Interval and local
catastrophe, arresting wider propagation.

The implementation preserves all competing moral readings: Orra abandoned her
post, saved civilians, enabled and ended the Open Interval, prevented a larger
catastrophe, and was placed in an impossible choice by her superiors. Penitent
interpretations remain faction theology, not authorial cosmology. Provenance is
forensic origin/evidence lineage. Retired terms including “Unnarrival” and
“Bellfall” are forbidden.

## Authored-Cell And Camera Contract

This region uses a local `32.0` world-unit authored cell. This does not migrate
the global Sector/procgen logical scale, which remains 24 world units where
runtime explicitly uses it.

| Level | Authored cells | World extent |
|---|---:|---:|
| Lower Quarter | 128×96 | 4096×3072 |
| West Gate Works | 64×48 | 2048×1536 |
| Station IX | 64×56 | 2048×1792 |

Essential compositions must remain readable within roughly 40×22 authored
cells. Lower Quarter progression is predominantly north/up-screen. Ordinary
traversal must not depend on cinematic camera ownership.

## Lower Quarter Geometry

Origin: `(-2048, -1536)`. Camera bounds: `Rect2(-2048, -1536, 4096, 3072)`.

Walkable regions:

- Arrival Platform `Rect2i(52,82,24,12)`
- Direct Personnel Line `Rect2i(58,70,12,14)`
- West Detour `Rect2i(38,74,22,8)`
- Evacuation Arcade `Rect2i(32,48,14,32)`
- Lower Market `Rect2i(16,34,46,20)`
- Civic Basin Link `Rect2i(56,36,24,14)`
- Wrong Street `Rect2i(74,30,34,24)`
- North Ramp `Rect2i(84,18,12,14)`
- Eight Answers Court `Rect2i(55,8,34,22)`
- Upper East Traverse `Rect2i(84,16,24,10)`
- East Switchback `Rect2i(98,22,10,44)`
- Station East Approach `Rect2i(72,58,30,10)`
- West Gate Branch `Rect2i(4,39,14,8)`

Station IX exterior mass is `Rect2i(54,58,18,14)` and is not walkable Lower
Quarter floor. Its facade sits roughly fifteen authored cells north of the
arrival spawn and shares the opening composition with the direct-route signage.
The collapsed direct line at `Rect2i(55,71,18,4)` is visibly and physically
impassable. The required signs are `MERIDIAN PERSONNEL / STATION IX → DIRECT`
and `CIVIL EVACUATION / LOWER QUARTER ↓`.

Markers:

- `Spawn_FromWorld` `(64,87)`
- `Spawn_FromWestGate` `(14,43)`
- `Spawn_FromStationIX` `(80,65)`
- `Exit_ReturnWorld` `(64,91)`, exit `return_world`
- `Exit_WestGateWorks` `(6,43)`, exit `west_gate`, locally gated
- `Exit_StationIX` `(74,65)`, exit `station_ix`, locally gated

Relays:

- `evac_annunciator` `(39,58)` opens the Evacuation Arcade shutter.
- `gate_pressure_relay` `(22,42)` opens the West Gate local exit.
- `station_ix_transit_interlock` `(89,21)` opens the east-switchback blocker
  and Station IX local exit.

The civic basin at `(66,43)` is mundane Meridian public emergency
wash/decontamination infrastructure. Wrong Street is a fixed cross-continuity
overlap: the local half uses Meridian civic geometry, while the Ash-Bell
Continuity half visibly misaligns its street, structures, and utility line.
Inspect-ready diagnostics distinguish `PROVENANCE: LOCAL / SOURCE INTEGRITY:
HIGH` from `CONTINUITY ORIGIN: ASH-BELL / LOCAL MANUFACTURE RECORD: ABSENT`.

Eight Answers Court is `Rect2i(55,8,34,22)`. Positions I–VIII retain weak-white
receiver markers; IX is visibly absent/damaged. Original technical presentation
reads `ASH-BELL REGIONAL SYNCHRONIZATION`, Answers I–VIII, and `IX UNARRIVAL`.
Later Penitent white thread, black banners, and ash remain visibly distinct from
the Meridian machinery.

Opening sight progression is: Station IX visible at arrival; increasingly
occluded through evacuation descent; mostly absent in Lower Market; partially
reacquired at the civic basin; disrupted through Wrong Street; obviously near
at Eight Answers Court; sustained through the east switchback; then threshold.

## West Gate Works Geometry

Origin: `(-1024,-768)`. Camera bounds: `Rect2(-1024,-768,2048,1536)`.

- Entry `Rect2i(48,18,12,12)`
- Control Gallery `Rect2i(34,16,16,16)`
- Pressure Pit `Rect2i(20,12,16,24)`
- Gate Motor `Rect2i(8,16,14,16)`
- Archive Alcove `Rect2i(14,4,16,8)`
- Closure Chamber `Rect2i(20,32,28,10)`

`Spawn_FromLowerQuarter` is `(55,24)` and `Exit_Backtrack` is `(58,24)`. The
closure motor near `(12,24)` moves a visible collision-owning slab roughly five
authored cells over about 2.4 seconds. Completion changes accessible geometry
and exposes archive maintenance access. Restored completion places the slab in
its final state without replaying animation. The archive preserves the fact
that West Gate closure was ordered before the Lower Quarter was fully cleared,
without an authorial moral verdict.

## Station IX Geometry

Origin: `(-1024,-896)`. Camera bounds: `Rect2(-1024,-896,2048,1792)`.

- Ground Intake `Rect2i(24,44,16,10)`
- West Duty / Records `Rect2i(8,32,20,12)`
- Sync Plant `Rect2i(22,24,20,16)`
- East Records `Rect2i(40,30,16,12)`
- Answer Chamber `Rect2i(15,2,34,28)`

`Spawn_FromLowerQuarter` is `(32,50)` and `Exit_Backtrack` is `(32,53)`.
Station IX begins as a workplace—lockers, duty board, emergency coats, transit
clock, and service fixtures—not a cathedral. Original Meridian records identify
`PRECENTOR ORRA`, never Saint Orra.

Isolation proceeds strictly A→B→C:

1. `RESTORE PRIMARY SYNCHRONIZATION BUS`
2. `ISOLATE RECIPROCAL RETURN CHANNEL`
3. `SEVER STATION IX RECEIVER COUPLING`

Only A begins actionable. Completion of C sets `station_isolated`. Before
completion, technical evidence may state `RETURN-PATH CONTACT: UNRESOLVED`,
`RECIPROCAL ADDRESS: UNRESOLVED`, and `DO NOT COMPLETE HANDSHAKE`; it does not
confirm NON-RECIPIENT. Final status is:

```text
STATION IX
RESPONSE WINDOW: MISSED
STATUS: UNARRIVAL
LATE RESPONSE:
ACCEPTED
REGIONAL COUPLING:
TERMINATED
```

## Session-State Keys

Lower Quarter:

- `evac_annunciator_repaired`
- `gate_pressure_relay_repaired`
- `station_ix_transit_interlock_repaired`

West Gate Works:

- `gate_motor_repaired`
- `closure_complete`
- `closure_archive_read`

Station IX:

- `assembly_a_repaired`
- `assembly_b_repaired`
- `assembly_c_repaired`
- `station_isolated`
- `answer_archive_recovered`

Restore is idempotent, suppresses one-shot effects/rewards, and restores visual
and collision state together.

## Historical First-Pass Limitations

- The first pass used procedural/blockout geometry and labels only; that presentation was superseded by the production-art integration below.
- Pressure markers are authored, but production Pale Bell Penitent population
  is deferred unless existing production-ready actors prove suitable.
- Dialogue, evidence-reader UX, cinematics, weather polish, and final encounter
  tuning are deferred.
- No global 24→32 scale migration and no new traversal or world-map framework.

## Validation Requirements

Focused validation covers route registry/profile/connectivity/spawns, all scene
instantiation, Lower Quarter scale/geometry/gates/relay restoration, Wrong
Street and Nine-position Court semantics, Station IX ordered repair and
idempotent restoration, and existing ingress behavior. The existing route
pipeline, changed-file workflow, historical archive boundary check, and Moment
Forge selection remain required.

## Second Pass Implemented

The second pass adds a generic authored-grid navigation provider and a shared
`NavigationSystem` provider seam. Authored route activation binds the provider;
deactivation restores the previous campaign source. Lower Quarter relay gates,
the direct collapse, and the moving West Gate slab update collision and
navigation together.

West Gate closure now persists `closure_phase` (`OPEN`, `CLOSING`, `CLOSED`)
and normalized `closure_progress`; a midpoint snapshot resumes only the
remaining travel. Ten semantic route beats, placeholder Meridian civic masses,
three physical Wrong Street bands, nine inspectable Court positions, and ten
player-readable evidence records replace the most diagram-like first-pass
presentation. `closure_archive_read` and `answer_archive_recovered` are now
driven by their corresponding records and survive reconstruction.

Production Penitent population is still withheld because no approved runtime
actor exists. Real-camera Moment Forge capture remains a required visual review,
not something inferred from headless geometry tests.

## Production Art Integration

Lower Quarter, West Gate Works, and Station IX use exact 512×512, 16×16
atlases with unscaled 32×32 source cells for Meridian civic floor/wall and the
fixed Ash-Bell overlap. The former civic props atlas is retained only for true
tile-scale or legacy detail; physical props resolve through the 224-entry
`meridian_civic_props_native` semantic manifest and render at their preserved
native dimensions. `lower_quarter_native_prop_placements.json` is exact visual
placement authority for 112 Lower Quarter, 64 West Gate Works, and 82 Station
IX instances. Its 258 records use 180 reviewed source variants across 77
semantic families; review-required source IDs 177, 201, and 212 remain absent.
Explicit semantic selection drives both paths; presentation
art never owns collision, walkability, navigation, exits, or route state.
`AuthoredBlockoutGrid2D` remains geometry and navigation authority with
production drawing suppressed.

The Meridian civic floor atlas uses quiet opaque ground pools rather than the
full 256-cell sheet: clean civic slabs dominate normal paving, worn slabs remain
low-frequency, and market/road materials are restricted to authored districts.
Transit markings, row-seven civic ornaments, drains, machine details, and amber
technical cells are authored overlays only. The reproducible source-work prep
removes border-connected near-black negative space and one adjacent halo layer
from non-ground cells while preserving all approved ground cells opaque.

The Meridian wall atlas uses the reviewed alpha-clean source. Native civic prop
extracts preserve those already-correct thin silhouettes without normalizing
them into 32×32 destinations. Wall cells are facade and perimeter
modules rather than solid-building voxels. `MeridianCivicArtPresenter` draws a
dark continuous civic structural mass first, then a quiet top edge, a semantic
bottom facade, and sparse interior machinery. `LowerQuarterNativePropLayer2D`
separately mounts manifest-backed native prop children at exact authored world
anchors using semantic anchor metadata. All collision footprints are disabled
for this visual pass; collision is never inferred from pixels and authored
navigation remains unchanged. The presenter must not refill
authored wall rectangles with repeated 32×32 wall sprites or derive collision
from prop alpha.

The Lower Quarter integrates the 768×768 Station IX landmark, eight 96×96
Answer pedestals with a physically missing/damaged IX, and 96×96 civic relays.
Wrong Street uses fixed local, seam, and imported bands with mismatched curb and
service-channel alignment. West Gate reuses the civic set with industrial
dressing and atlas-presented moving-slab art while its `AnimatableBody2D`
retains collision and closure authority.

Station IX uses the civic set as a workplace, the 384×320 synchronization core,
and the canonical 768×96 receiver as eight 96×96 frames at 9 FPS. Isolation
stops the receiver on a cold inert frame without replay on restore. The world
ingress uses the 288×224 Meridian transit descent. The reviewed
`traversal/ash_bell_lower_quarter_opening` fixture uses the real Operator and
gameplay `CameraController`; baselines remain a manual developer decision.

West Gate Works session state is now:

- `gate_motor_repaired`
- `closure_phase`
- `closure_progress`
- `closure_complete` (read-compatibility projection)
- `closure_archive_read`

## Next Agent Slice

**Goal:** populate deterministic authored pressure encounters only after a
canonically honest production actor identity is available.

**Constraints:** preserve authored geometry, local 32-unit scale, route state
keys, camera-safe compositions, and authorial ambiguity. Do not promote faction
theology into cosmological fact.

**Acceptance:** subsequent combat work retains the approved production-art
sightlines and all focused route/layout/state validation.
