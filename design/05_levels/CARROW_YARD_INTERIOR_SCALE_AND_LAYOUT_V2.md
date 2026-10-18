# CARROW YARD — INTERIOR SCALE, SPATIAL AUTHORING AND ART COMPLETION V2

**Status:** Scale-class **human decision accepted** on 2026-10-17; layout, collisions, floors and presentation **not yet approved**
**Baseline audited:** `braydio/CUSTODIAN main@0d51fdba1da51b7cd3af4960b93e2dc6b4066b66`
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0
**History:** `design/05_levels/CARROW_YARD_POST_INTERIORS_PLANNING_V1.md` and independently PASSed `review-carrow-interior-scale-calibration-v1`.
**Owners:** Carrow site canon/room semantics in `design/03_world/locations/CARROW_YARD.md`; live room registry in `custodian/game/world/gothic_compound/gothic_compound_map.gd`; edited collision/POIs through the existing Authored Level Mapper family; Asset Pipeline V2 for art; distinct `carrow-yard-route-authority-migration` owns world ingress.

## 1. Human scale decision: three approved classes

The user tried all three **actual debug scenes** and finds every one more suitable than the tiny production rooms. All three are APPROVED **as dimensions/classes only**. Do not force a single winner or request another size-selection signoff.

| Class | First Carrow assignment | Columns × rows | Native 32px footprint | Floor cell count |
| --- | --- | --- | --- | --- |
| Small full interior | `west_draft_house` | **24×18** | **768×576** | **432** |
| Medium production interior | `east_machine_house` | **30×22** | **960×704** | **660** |
| Large civic/administrative interior | `operations_house` | **36×26** | **1152×832** | **936** |

A dedicated stand-alone **off-map** Carrow interior must be at least **24×18 cells**. This is a current art/gameplay minimum for Carrow, not a requirement that tiny rooms vanish: smaller booths/closets/control annexes should be built **on-site or nested inside larger rooms** unless separately authorized. 36×26 is not a ceiling. A large building can exceed it after its own specific authored plan.

Retain original three production rooms until separately reviewed layout authoring is complete. Current production is East 14×10, West 12×10, Ops 20×14. Calibration scenes are **not** final room layouts.

## 2. User-observed defects; do not silently classify as acceptable

1. The debug floor is conspicuously repeated. The production floor's exact `_build_interior_floor()` state selector uses `floor_states[(x * 3 + y * 5) % floor_states.size()]`; repeated slab/grate/crack symbols make a tiled-house effect. The calibration fixture also repeats a small tile set. Green floor-cell-count tests don't certify art direction.
2. Existing fixture prop placements don't represent real work zones: 13 art nodes reuse fixed anchor offsets regardless of room's role and new scale. Native image rectangles overlap nominally free cells; that's currently evidence, not proof of correct physical footprints.
3. Solid collision is generated from symbolic `X/R/S/F/H/... ` cells or fixture rectangles, not authored from each installed machine's actual base. Disagreement between visual equipment and collision is an unresolved user-visible defect.
4. The independent calibration test intentionally proves 4-column clear aisle, exact colliders and Operator capsule waypoint clearance, **not** that room-layout composition, density or working-machine placement is believable.
5. New larger 24×18 / 30×22 / 36×26 rectangles invalidate original off-map `origin_offset` and camera spacing assumptions. Recompute each region with deterministic nonoverlap and margin; don't add 200 lines of duplicate per-room geometry code or another room router.

**Correct division of labor:** user authors/approves visual composition, working zones and collision footings. Codex writes the mapper, imports explicit layout records, binds the real art/colliders, proves deterministic rules and reports facts without subjective 'playability' grades.

## 3. Spatial plan per size: purpose labels, not Codex placement permission

- **West 24×18:** intake/filter bank; north draft mechanism; east auxiliary power; west repair/filter access; central operator movement and a defined southern return. Equipment positions and collider footprints are **UNDECIDED until visual mapper authoring**.
- **East 30×22:** receiving and parts desk; conversion/switchgear bays; a coherent maintenance aisle; rear equipment zone; control/inspection niche. Equipment positions and collider footprints **UNDECIDED**.
- **Operations 36×26:** entry/receiving; public-service records; dispatch/communications; logistics storage; rear status/coordination galleries. Not a shrine or faction command seat. Equipment positions and collider footprints **UNDECIDED**.

Don't copy the fixture's four black rectangle islands or arbitrary repeated 13 prop coordinates into production. Reuse the IDs/resources of existing storage with user-chosen anchors; do not duplicate/summon extra loot.

## 4. Floor presentation: separate from floor collisions

**Temporary preview:** one declared subdued registered slab state for the base, plus individually authored feature zones, with existing 32px art at native scale. Remove modulo-based `(x*3+y*5)%N` assignment in the later production slice; no algorithmically patterned oil patches, grates or repeated high-contrast wear. No creation of runtime assets during mapper work.

**Future production art:** source package already published in Dropbox, `custodian_carrow_yard_exterior_source_set_asset_handoff_v1.zip`; the newly generated `hardstand_plain_01` is a **source candidate**, not a passed seam-tested runtime tile. Derive a genuinely repeatable low-contrast slab/base family through Asset Pipeline V2. Grates, road stripes and access hatches are sparse authored overlays/regions, not every tile. Seam and alpha tests objectively verify published outputs, and the user judges look/variation at 1:1 gameplay scale.

The floor's collision stays independent from visual variation. No prop physics inferred by color/alpha.

## 5. Physical continuity vs off-map interior staging

**Verified current behavior:** All three 'interiors' live in the same `GothicCompoundMap` Node2D, allocated beyond `map_size_tiles.x + 8` to the east, with per-room camera bounds, environment and teleport/return doors. This is **off-site placement in the same scene**, not a loaded standalone second scene. It preserves one Operator and state, but loses physical continuity, sightlines through doors/windows, the sensation of seamless entry, and a plausible relationship between the 7×8-tile exterior shell and a 30×22-tile interior.

**Adopt a conditional hybrid design, NOT an immediate rewrite:**
- Under 24×18 (small control booths, short halls): author on-site within actual exterior site and show the interior through roof-hiding/cutaway/occlusion, using the existing world collision authority.
- Three large approved interiors: keep current **off-map staging temporarily** to avoid disturbing the procgen/route architecture. Before declaring production game-feel complete, inspect a human-viewable A/B scene showing (A) current door/teleport/camera presentation and (B) a contained in-world shell/roof-removal prototype, with exact Operator/camera/door tests. User, not Codex, chooses presentation.
- If large interiors require physical continuity, the exterior silhouette/site footprint must be reconciled with real grid size; do not fabricate an impossible interior behind the current small 7×8 building. A loading/door transition may be intentionally stylized, but user must approve that abstraction.
- Preserve main Carrow world-route workstream ownership and existing state persistence; do not spawn a second Operator, reset world time, or add parallel world level registration.

## 6. Narrow next implementation: authoring mapper, then human layout

Build a Carrow adapter to the already shipped `AuthoredLevelMapper` / `LevelCollisionPoiMapper` and reuse 24×18, 30×22, 36×26 fixture art/Operator/camera resources. Provide three selectable previews with exact room coordinate bounds, grid toggle, candidate floor layer, click-to-place/move/delete named existing art and storage markers, and separate collision footprint editing. Exact planned output: one deterministic JSON **draft per room** with `schema,room_id,grid_wh,tile_size,source_refs,art_placements,solid_rects,portals,storage_anchors,floor_regions`. No pixel analysis, script string surgery or direct production overwrite. Authoring can track placeholder layouts but cannot 'approve' them. One explicit user confirmation of per-room draft unlocks later production sizing/integration; no further size vote needed.

**Code-level gates:** output schema version and hash, integer 32px tile coordinate bounds, unique names and IDs, exact source ref/hash, no undesired clipping in room rect, collision overlap and doorway guard, Operator-shape clearance for every author-declared route/portal, every storage anchor matching a named prop, room/camera AABBs nonoverlapping, replay equal JSON bytes, existing Carrow tests unchanged. Detect unsupported art/collision disagreements as facts, not aesthetic auto-corrections.

## 7. Artwork workstream remains ACTIVE until six missing wall states are complete

Existing **7 individual RGBA perimeter wall sources** are already exported and included in the Dropbox batch; do not re-generate or re-ingest them. The floor source package includes specialized ground variants and `hardstand_plain_01` as candidate. The **six pending pieces** in the same `carrow_yard_perimeter_walls_v1` family, all 1 frame, true-alpha source and **provisional** normalized dimensions:

| Source state | Normalized target | Visual requirement |
| --- | --- | --- |
| `wall_inner_corner_nw` | 96×128 | concave upper-left junction |
| `wall_inner_corner_ne` | 96×128 | concave upper-right junction |
| `wall_inner_corner_sw` | 96×128 | concave lower-left junction |
| `wall_inner_corner_se` | 96×128 | concave lower-right junction |
| `wall_straight_ns_01` | 256×128 | genuine north-south connector run, **not** a second E–W section |
| `wall_pillar_unlit_01` | 64×160 | unlit repeating support, no beacon |

**Source-work convention:** `custodian/asset_drop/source_work/carrow_yard/carrow_yard_perimeter_walls_v1/<state>_source.png`
**Inbox after visual approval + normalize QA:** `custodian/asset_drop/inbox/carrow_yard_perimeter_walls_v1/<state>.png`
**Manifest when family accepted:** `custodian/content/metadata/assets/families/carrow_yard_perimeter_walls_v1.asset.json`

The six source canvases may be generated large and then normalized without resizing until exact connectors/footprints are authored. The 96×128 / 256×128 / 64×160 dimensions are **provisional only** and must NOT be treated as a settled 32px collision/AABB authority. Perspective/real 3D visual depth, identical materials and lights to existing Carrow walls, matching caps and thickness are the human art targets. Codex can test named seam/anchor coordinates but cannot declare these visually good. Do not drop this art workstream after discussing scale.

## 8. Workstream order and drift closure

**Completed:** calibration implementation and independent review. **Now decided:** sizes, class allocation and under-24×18 on-site default. **Next claimable engineering work:** Carrow interior layout-authoring mapper implementation + independent review. **Human slice:** draw/approve floor zones, prop anchors and collision within each of the three approved grids. **Then:** one production conversion packet per building or bounded combined slice with exact approved JSON, preserving accepted review/route semantics. **Separately:** finish four concave corners, N–S straight, unlit pillar, repackage source bundle revision and upload to Dropbox before Asset V2 normalization.

**Drift corrected by this V2:** Previous post-interiors planning still called the size choice human-required and invited a single chosen size even though three calibrations passed and the user now approved all three. The older 'working room' checks treated green collision as if it supported art/readability; these are independent acceptance dimensions. The old 'Gatehouse 10×8' planning remains historical, not a new contradiction with current minimum. Production code remains unchanged and must not be described as resized yet.
