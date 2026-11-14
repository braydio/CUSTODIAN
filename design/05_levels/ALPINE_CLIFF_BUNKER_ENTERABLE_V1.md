# Alpine Cliff Bunker — Enterable Location V1

**Status:** LOCKED DESIGN DIRECTION, planning-only (2026-11-03). **Inspected main:** `50fd76fdb6e85d6bf11d01bce7c5e9ee26f5df62`. No production assets, level scene, reviewed transfer, or gameplay implementation are implied.

**Companions:** [Production and validation](ALPINE_CLIFF_BUNKER_PRODUCTION_PLAN_V1.md) · [Planning manifest](ALPINE_CLIFF_BUNKER_ASSET_MANIFEST_V1.json).

## Locked experience

The Operator approaches a snowbound bunker built into a sheer Alpine cliff, opens an actual blast-door threshold, enters a spatially real industrial antechamber, walks inside, and returns to the **same surface world**. An inaccessible painted doorway or an ornamental cutaway does not satisfy this design. The two 1254×1254 transparent concept PNGs are the reference for material language and composition, **not placeable runtime art**. They mix cliff, floor, walls, doors, props, lighting and shadows in one oblique illustration; this is not direct Godot floor, occlusion, navigation or collision authority.

**Art identity:** jagged layered basalt with patchy snow, severe exposure, embedded concrete and vents, worn ochre hazard chevrons, warm functional lights, plated/grated interior floors, utilitarian shelves, physically robust doors. Preserve the existing Alpine Plateau visual lock and 32px semantic construction rhythm, but resolve the actual camera/world-to-pixel mapping before production art. Do not warp square diorama crops into a walkable room.

## Locked topology, pending exact coordinates

```text
ALPINE SURFACE / WALKABLE CLIFF APPROACH
    ↕ exterior heavy blast door and safe apron
INTERIOR ANTECHAMBER / STAGING (V1a)
    ↕ inner secure bulkhead (closed until V1b)
SERVICE BAY / ENGINEERING (V1b)
    ↕ physical room-to-room connection
CONTROL ROOM / LOCAL OPERATIONS (V1b)
    ↳ optional EQUIPMENT BRANCH (future)
```

**V1a:** one fully playable exterior ↔ antechamber ↔ originating exterior vertical slice. The main entrance must have synchronized closed/open art and real crossing/collision. Keep the inner bulkhead genuinely closed, not a false path, until V1b exists.

**V1b:** service bay and control room become physically connected playable rooms, not disconnected illustrations or unnecessary teleports; the optional equipment branch is a genuine side route, never a mandatory extraction gate. Equipment and operations must have tangible **local** function, not a duplicate lost-route tribunal.

**Blockout prerequisites:** explicit surface reservation and floor masks, approved walkable approaches, door/apron and paired return anchors, Operator collision clearance, room dimensions and transforms, camera bounds, actual input/interaction owner, asset origins and z-order. Exact pixel canvases, world coordinates, and 32px cell extents are **undetermined** until a running-game blockout. Art cannot silently change clearance or define collision.

## World/architecture invariants

1. Valid seed and surface access: the optional site cannot obstruct mandatory route, current Contract objectives, extraction, procgen reservations or weather/region-frame authorities. Invalid placement **skips** the site without carving safe terrain or breaking the world.
2. Doors are gameplay: open graphics correspond to walkable door apertures; closed graphics correspond to blocked apertures. No invisible barriers, ghost gates, unintended shortcut, or duplicate trigger.
3. Crossing is **reversible and stateful**: exactly one Operator, valid arrival and return, no bounce, correct camera and originating session restoration, no loss of retained player/Contract state, no duplicate completed encounter.
4. Floors, solids, props, scenic cliff depth and foreground occlusion are independently owned. Opaque ground is drawn below the Operator; relevant wall caps/near cliff faces occlude it correctly without hiding the usable path.
5. The interior is big enough to be *walked in* at actual character scale, with storage and machinery outside the main clearance. All actual doors, grates and cover align with registered geometry; a single illustration cannot be the authoritative collision mask.
6. Persistence reuses existing state owner; no new global CampaignOutcome, Port, route physics or separate world transition manager is created simply by depicting a bunker.

## Distinct canon role and existing owners

This is a proposed independent **optional authored cliff site**, NOT an automatic replacement for the existing `campaign-abandoned-station-{site,stability,containment}-v1` three-service encounter; wiring the two together is a later explicit owner/behavior decision. Preserve that encounter's North Relay, East Conduit, Core Feed, timer, and Maintain Containment / Shutdown Coupling outcomes until approved work says otherwise.

This is NOT the `connected_bunker` compound archetype, although it should reuse an appropriately **reviewed** surface/interior transfer and camera pattern. It is NOT Station IX or the Forlorn Ritualant station. Twin Solaria retains Crown-class lost-route acquisition/reciprocity adjudication. The cliff bunker is a **local engineering and supply installation**, with practical stakes and material consequences. Author an actual crew choice, cost, physical evidence and useful player discovery before writing lore logs. Contradictory records, impossible occupancy and vague containment riddles are not default content.

## Visual decomposition lock

- **Walkable ground:** exterior approach and interior floor **separate opaque underlays**, based on G1-approved floor masks, with no baked raised structures or false paths.
- **Exterior nonwalkable cliff and facade:** distinct scenic-depth and true-alpha architectural layers, registered to the surface mask. Existing AP2 cliff assets take precedence where appropriate; do not overwrite their renderer/contacts.
- **Interior wall shell and foreground:** true-alpha registered layers with valid occlusion; do not allow wall imagery to create an obstruction outside approved geometry.
- **Doors:** exterior and matching interior-face open/closed states with shared physically verified pivots; deeper bulkhead closed for V1a, separately opened for V1b.
- **Dressing/lighting:** independently placeable shelf, utilities, lights; visual cues follow actual access/power state and do not grant gameplay authority.

The per-state inventory is in the JSON planning manifest; it is NOT a `custodian.asset_family.v2` contract or an edit to `required_assets.registry.json`. All concept image references still need delivery, individual source review and hash-pinned production approval.

## Binding authorities

`design/00_meta/MASTER_DESIGN_DOCTRINE.md`; `design/02_features/procgen/ALPINE_PLATEAU_STARTING_REGION_VISUAL_LOCK.md`; `design/02_features/procgen/ALPINE_PLATEAU_PRESENTATION_ASSET_MANIFEST.md`; `design/04_architecture/AI_ART_GENERATION_REVIEW_PROTOCOL_V1.md`; `design/04_architecture/ASSET_PIPELINE_V2.md`; `design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md`; `design/02_features/events/AUTHORED_HUB_CAMPAIGN_MICROEVENTS_V1.md`; live Godot/procgen/route/Operator owners. Design lock never claims integration, independent review or deployment.
