# Carrow Yard: Structures and Interior Expansion V1

**Status:** Proposed implementation design, not new settled world canon
**Audited repository:** `braydio/CUSTODIAN main@d4e5dd6e06cf664b6503b9bd4ffca4a591f11f9d` (2026-10-14)
**Canonical world identity:** [Carrow Yard](../03_world/locations/CARROW_YARD.md)
**Existing production layout:** `custodian/game/world/procgen/gothic_compound/{gothic_compound_generator,gothic_compound_asset_defs}.gd` and `custodian/game/world/gothic_compound/gothic_compound_map.gd`
**Separate travel authority:** `custodian/docs/ai_context/task_packets/CARROW_YARD_ROUTE_AUTHORITY_MIGRATION.md`
**Scope:** More architectural, navigable, functionally distinct structures; preserve canon, controlled transitions and current gameplay

> **2026-10-15 status correction:** West Draft House 12×10 and Operations House 20×14 have now landed and independently passed review, alongside the existing East Machine House 14×10. The implementation columns, 'no interior' statements, and W1/O1 future-tense prose below are **historical pre-implementation design**, not current runtime truth. None of the three small footprints has received human game-feel/scale approval. For current status, exact scale-calibration entrypoints and gated Gatehouse/Alarm decisions, see [Carrow Yard Post-Interiors Planning V1](CARROW_YARD_POST_INTERIORS_PLANNING_V1.md). The separately queued route migration still owns world-level transfer authority.

## Design thesis

Carrow is a fortified **municipal utility yard**, not an army compound or shrine. Every visible structure should answer a practical question: which system did the facility maintain, where did technicians work, what needed protecting, where did materials pass, and how did an emergency signal travel? The yard must stay legible from its South Gate to its north Operations House. Retain empty Service Court circulation; do not pack it into a maze of crates and monuments.

Three interlocking layers:
1. **Exterior operational geometry:** South Gate → Service Court spine → Operations House; lateral west ventilation and east electrical service pads; the Alarm Gantry on the court edge.
2. **Authored interior rooms:** differentiated floor patterns, work bays, real collision, coherent lighting, diegetic storage and reversible, camera-safe traversal. East Machine House is the pattern, not the floor plan to copy.
3. **Narrative residue:** labels, maintenance logs, inactive instruments, damage and procedural traces that show past municipal use. Current faction ownership remains **unassigned**. Keep the `gothic_compound` technical namespace until its authorized migration.

## Verified existing implementation vs proposal

| Element | Verified shipped state | Proposed expansion |
| --- | --- | --- |
| East Machine House | Working 14×10 (448×320px) off-map interior, 140 floor cells, 13 art sprites, 3 storage interactions; both doors, camera/lighting/weather exposure | Preserve byte/behavior contracts; extract reusable interior orchestration only where necessary |
| West Draft House (`utility_fan`) | Exterior 7×8 tile / 224×256px footprint, generator site ID `west_draft_house`; no accessible interior | New 12×10 tile / 384×320px ventilation plant |
| Operations House (`command_keep`) | Exterior 11×10 tile / 352×320px footprint, generator site ID `operations_house`; no accessible interior | New 20×14 tile / 640×448px dispatch/control building |
| South Gate / gatehouse | Generator-owned south opening; 5-tile nominal gate (160px); approach road/required walkability | Adjacent 10×8 tile / 320×256px side-gate control annex; do not cover the required gate gap |
| Alarm Gantry (`bell_frame`) | Exterior 4×6 / 128×192px blocker and named `alarm_gantry` placement; no shared gameplay alarm network | Inspectable signal station and visual state only, no invented alarm escalation |
| Service Court | Road spine, open floor, terminal, staging/scatter and resources | Reserve vehicle route and loading apron; add select repair/stock clusters only after overlap tests |

Existing Asset Pipeline V2 families: `carrow_machine_house_floor` **64 × 32×32 tile states**, `carrow_machine_house_walls` **49 wall/structure states**, `carrow_machine_house_props` **11 prop states**. Reuse compatible registered runtime art by reference (no duplicate ingestion), recognizing that their original family IDs remain intact. Runtime floor art and wall alpha never own physics/navigation.

### Exact present runtime seam

`GothicCompoundMap` still owns exactly one `_machine_house_root`, one `_machine_house_interior_rect`, one `_operator_inside_machine_house` flag and one interior camera rectangle. Room created at off-map `map_size_tiles + Vector2i(8 - map_size_tiles.x, 8)` effectively `(map_size_tiles.x + 8, 8)`, with exclusive camera region and interior-weather query. Do not duplicate these fields for each building. A bounded **named-room registry** should give each interior a stable ID, layout/presentation anchor, interior Rect2, camera bounds, entrance/return position and environment profile. The map remains the only current room-transfer authority until the separate canonical route migration; do not build a second LevelRegistry/RouteTraversalManager inside these rooms.

Exterior site bindings must come from `result.structure_sites` and per-site footprint, not absolute world-pixel guesses. Missing/blocked exterior placement must fail closed (no floating entrance/phantom portal). Reference layout coordinates are room-local 32px tiles, not global world positions. Off-map allocations should be derived deterministically from map size + room dimensions + margin with no overlap and no camera bleeding. Preserve the East Machine House room origin and debug/API observations to avoid breaking the passing smoke.

## 1. West Draft House: first expansion (W1)

**Player impression:** Compact but physically legible municipal air-handling equipment. Restrained noise, heavy vent surfaces, heat-stained grates, filtered airflow and a visibly separate technician aisle. Not a giant magical fan chamber.

**Room:** 12 columns × 10 rows, 384×320px. Southern 3-cell entrance; the exterior anchor is the actual `west_draft_house` 7×8 site. Functional bands: north dual fan/exchanger bays; west filter trench; east pressure controls and auxiliary power; clear maintenance/return aisle. Prefer side-on shallow wall treatment and 2D equipment silhouettes; art/collision co-registration is independent of opaque image extent.

**Proposed room-local symbol grid** (`X` shell, `D` passable exit, `F` fan banks, `H` heat-exchanger banks, `V` ventilation/filter stacks, `C` control, `P` reserve power, `.` walkable). This is an initial validated-size blockout, subject to playtest spacing, not already shipped:

```text
XXXXXXXXXXXX
X..........X
XFFFF..HHHHX
XFFFF..HHHHX
X..........X
XVV.......CX
XVV......PPX
X..........X
X..........X
XXXXXDDDXXXX
```

The west and east equipment are collision-bearing only at approved lower mechanical footprints. Continuous 2-cell circulation at the north banks plus an accessible southern aisle are mandatory. `D` is passable, not automatically a travel trigger. Verify actual Operator navigation geometry, not grid-only connectivity. Proposed environmental profile: weather exposure 0 indoors, subdued world influence (~0.10), weak uneven amber service lighting plus cold dead-vent pockets, no constant full-room bloom.

**Interactions:** Service Filter Cradle (one optional resource pocket); Draft Controller (read-only/diagnostic presentation initially); Emergency Parts Rack (one optional source of mechanical salvage). Do not create a new crafting/alarm/heat mechanic. A unique visible equipment source should be the same anchor used by its interaction, as the East Machine House storage presentation already proves.

**Visual acceptance:** unmistakably west-side airflow plant, readable ingress at 100% zoom, no walking through heavy impellers, no impenetrable duplicate art+collision, no visual rain indoors, exit returns outside the exact west structure. A player can identify the route to the exit even with the HUD suppressed.

## 2. Operations House: civic nerve center (O1, after W1 review)

**Player impression:** Human decisions translated into service work. Municipal duty rather than throne room. The room should be wider, more layered, and less visually dense than the Machine House: public-facing vestibule, dispatch record wall, inventory/stock ledger, emergency coordination desk and power-status reporting.

**Room:** 20×14, 640×448px. Exterior north building footprint remains the existing 11×10 site. `command_keep` stays the technical exterior art ID. Southern three-cell entrance. Interior subspaces:
- **South 3 rows:** entry, inspection/storage point, hardstand traffic markings; no sudden bottleneck.
- **West/middle:** dispatch tables, status/route assignment and radio/dispatch terminals, low blockers with interaction clearance.
- **North:** civic power and route status panels, paper/metal inventory banks and dry relay displays, high wall band.
- **East:** spares registry and emergency supply cage; no locked story progression gate until canon and behavior exist.

**Proposed room-local symbol grid** (`X` shell; `D` exit; `C` control wall; `R` records; `K` dispatch consoles; `S` stock; `W` workshop/logistics; dots open):

```text
XXXXXXXXXXXXXXXXXXXX
X..................X
XCCCCCCC.....RRRRRRX
XCCCCCCC.....RRRRRRX
X..................X
XKKK.......SSS.....X
XKKK.......SSS.....X
X..................X
X..................X
XWWWW..............X
XWWWW..............X
X..................X
X..................X
XXXXXXXXXDDDXXXXXXXX
```

This is a presentation blockout, not an NPC cast or faction claim. Plan for generous 2–3-cell center circulation and an unobstructed entrance-to-controls sightline. Separate floor decoration and above-head occlusion. The northern control wall should feel commanding because of function, not cathedral motifs.

**Interactions:** Service Dispatch Board (read-only work-order residue), Municipal Stores Ledger (lightweight inspectable lore, or noninteractive until shared inspection affordance exists), Emergency Spares Cache (one small bounded reward), Yard Status Array (passive display initially, no authority over alarms/doors/route unlocks). Persist consumed stores across revisits through the current owner/state policy, not a new parallel data store.

**Environmental contract:** In-door weather 0, softer ambient world influence, localized stale console glows and one practical desk light. Camera bounds are the Ops room only. Do not reset East Machine House storage on Ops transition; continuous same-runtime revisit must be proven.

## 3. South Gatehouse service annex (G1, after structural proof)

**Room:** tentative 10×8 / 320×256px, built as a **side annex** to the gate rather than a structure spanning the 160px south gate passage. Proposed north sight slit/vehicle observation console, compact western watch/entry records nook, central service aisle, and south-facing mechanical gate actuator housing. No two-story gameplay, ladder or walkable wall-top until authored.

**Important boundary:** The current generator exposes `gate_cell` and gate clusters, not a named `gatehouse` structure site equivalent to `operations_house`. G1 must first prove a stable physical annex/entrance anchor, walkable yard approach and gate-route separation across fixed seeds. Do not bolt a door to a guessed `gatehouse` texture pixel or mark the existing open gate as solid. Retain transfer route, spawn and return route guard.

**Interactions:** mechanical latch inspectable; control journal; optional observation/perimeter cue. No autonomous sentry/turret/alarm gameplay in this slice.

## 4. Alarm Gantry and Service Court (A1, after gatehouse; optional later)

`alarm_gantry` already has a named generator site and a 4×6 blocker. Make this an **industrial warning mast** with maintenance footings, sightline, a static/inert status display, and a plainly nonreligious structure. Its signal states can be a visual authoring target but **do not** add alarm propagation until `STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md` provides the adopted shared network contract. Avoid implying that a disabled signal device commands every enemy.

Keep the Service Court's central logistics identity. Potential approved placement grammar:
- West-side pallet/replacement-module staging, at most one large cluster.
- East-side electrical-conduit inspection apron, mostly painted ground and shallow equipment.
- South gate approach and central northbound movement lanes remain free; no scatter directly on any `required_walkable` route or within mandatory approach clearances.
- One small dead drainage trench and nonblocking stencil lane marks, rather than a decorative pond, fountain, or religious monument.

All proposed physical props require generator zone/footprint metadata, collision authored from their **ground contact** and route checks. Maintain the gate-to-Operations sightline and walkable machine-house entry paths.

## Reuse and proposed new art

**Reuse now:** 32×32 `carrow_machine_house_floor` slabs/vents/grates/conduits, existing wall bays `fan_bay_01` (160×96), `vent_pipe_bay_01` (160×96), `control_bay_01` (128×96), `machine_bay_01` (192×96), existing shallow pillars/doorframes, and compatible relay/workbench/locker props. This is reference-only reuse of existing family outputs; don't duplicate source or re-register them under an invented owner.

**Candidate NEW Asset V2 art** only after the first playable graybox reveals actual deficits. All static 1-frame RGBA with true alpha, 32px-aligned native scale; no art requested/generated in this design pass:

| Proposed family | State ID | Normalized size | Purpose |
| --- | --- | --- | --- |
| `carrow_west_draft_house_props_v1` | `impeller_guard` | 192×128 | Guarded fan face/front occlusion |
| same | `filter_cradle` | 96×96 | Service-filter interactable face |
| same | `thermal_manifold` | 128×96 | Hot/cold exchange bank |
| same | `draft_controller` | 96×96 | Local status/controls |
| `carrow_operations_house_props_v1` | `dispatch_board` | 192×96 | Route/status duty board |
| same | `records_shelves` | 128×96 | Municipal ledgers and route logs |
| same | `dispatch_console` | 128×96 | Service crew station |
| same | `inventory_cage` | 160×128 | Warehouse stock, guarded |
| same | `emergency_status_array` | 192×96 | Yard system state wall |
| `carrow_gatehouse_props_v1` | `gate_actuator` | 128×96 | Mechanical gate linkage |
| same | `observation_slit` | 160×96 | Yard observation wall module |
| same | `entry_records_desk` | 96×96 | Shift/watch notes |

**Exact intake paths** for each proposed family/state:
```text
custodian/asset_drop/source_work/carrow_yard/<family_id>/<state_id>_source.png
custodian/asset_drop/inbox/<family_id>/<state_id>.png
custodian/content/metadata/assets/families/<family_id>.asset.json
```
Each image has **1 frame**, source master dimensions are measured when authored, normalized/runtime dimensions are locked by the table, and the runtime domain follows the live `sprites/environment/structure/carrow_*` convention under the new family contract. No direct runtime image writes; no stretching; no invented visual review. The original East Machine House art remains unchanged. If these assets are later requested as illustrations, generate and review them in a discrete art slice before actual V2 ingest.

## Runtime design, test authority and conflict guards

**W1 implementation** should use a thin reusable site/room definition and current GothicCompoundMap as a delegation owner, not copy its 480-line script's floor/collision/camera/door implementations wholesale. Production room metadata should own room ID, grid, lighting profile, door schema, site ID and resource bindings; one component should build/present each room and one map-side selection state should choose the active region/camera. The map remains a staging owner until `carrow-yard-route-authority-migration` moves **world** entry/exit to canonical routes. Interior-to-yard transfer must not become a second global route owner.

**Proposed build order:**
1. **W1:** small shared interior-room seam + West Draft House first playable interior; independent review.
2. **O1:** Operations House interior + independent review, only after W1 is accepted.
3. **G1:** South Gatehouse site/adjacent annex proof + small room; geometry/gate-route review required before detailed art.
4. **A1:** Alarm Gantry non-networked presentation and Service Court placement polish; later shared stealth/alarm integration separate.

**Focused tests per slice:** default and alternate seeds with real `structure_sites` bindings, each exterior↔interior door pair, Operator collision passage width, no overlapping world-space room AABBs/camera bounds, outside↔inside weather and camera restoration, same-runtime revisits and resource depletion, floor count equals width×height, distinct art bindings, no doubling of shadows/rain, no service route closure, main transfer-gate state unchanged. Run the existing `carrow_yard_interior_smoke.gd`, `carrow_backdrop_isolation_smoke.gd`, generator validator, and route-specific focused smokes before changed-file sweep.

**Route-migration protection:** Existing `CARROW_YARD_ROUTE_AUTHORITY_MIGRATION.md` is `ready/auto` but depends on `contract-world-loader-contraction`, itself refresh/dependency gated. It owns future transfer frame/LevelRegistry/LevelExit changes, not new interior content. Serialize edits to the same Carrow map through shared `carrow-yard-route` ownership and verify current branch/locks at claim. Avoid committing speculative `levels.json` registrations or deleting `GothicCompoundTravelGate` in W1/O1.

## Documentation drift actions

- `design/03_world/locations/CARROW_YARD.md` formerly held only one-line building role descriptions. Link this design as **proposed**, retain original historical identity and explicitly unassigned present-day faction.
- `design/02_features/procgen/GOTHIC_COMPOUND_PROCGEN.md` is 1,699 lines and contains the live first-slice truth followed by its old prototype implementation specification. Treat only the opening **Current Implementation** summary as a description of shipped Carrow; do not follow legacy generator examples to replace the live code.
- `design/02_features/procgen/GOTHIC_COMPOUND_ARCHITECTURE_HARDENING.md` carries a May-2026 draft audit with snippets; not an authoritative current issue list. Re-audit actual generator before acting on specific old offsets.
- `custodian/docs/ai_context/task_packets/CARROW_YARD_ROUTE_AUTHORITY_MIGRATION.md` still describes the bespoke map as current production truth, which remains correct at this baseline. Its long-term authority dependency is distinct from authored-room expansion.
- `CURRENT_STATE.md` should only be updated after runtime work lands. No claim is made here that West/Ops interiors already exist.

## Design approval gate

Room dimensions and placements above are **proposed design targets**, suitable for one bounded graybox implementation. Do not convert lore residue into a new quest, faction, unlock, alarm effect or enemy placement without separate approval. After W1/O1 real screenshots and geometry evidence, a human visual pass may change prop sizes/lighting without invalidating site canon. Only then publish new art requirements as truly required states.
