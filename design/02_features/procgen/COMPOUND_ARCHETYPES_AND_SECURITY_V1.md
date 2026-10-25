# Compound Archetypes and Security V1

**Status (2026-10-17):** Profile contract accepted; Type A and Type B physical blockouts landed. Type A independent review remains active. Type B review concluded `findings` (R0-01, R0-02); the bounded R1 correction implementation is complete and awaits its fresh independent review before Type B is accepted as playable. Interior traversal, powered security and assault/recovery remain unshipped.
**Workstream:** compound-archetypes-v1 + compound-recovery-v1
**Reviewed main:** 512226d488d3b5db63335b2357b4b566e44ccb03
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488

## Architecture decision

Two explicit initial archetypes share existing game mechanics but differ in physical topology. Profile and seed select generated geometry, NEVER new simulation authority.

**Type A: walled_yard.** Tightly grouped independent buildings; one continuous collision-real perimeter; primary yard gate plus a secondary controlled personnel/service entry; yard circulation and reserved construction/repair pads. Room interiors can use independent reversible transfers initially. Assault pressure targets perimeter and exposed infrastructure.

**Type B: connected_bunker.** Slightly spaced fortified surface access housings linked by reversible entries to ONE continuously navigable subsurface corridor/room network. Underground room-to-room travel is physical and never teleportation. Fortified compartment doors and alternate emergency egress make access-control decisions meaningful. Subsurface floor/wall authority must not overlap surface collider space.

## Verified seams and ownership

- Planner: custodian/game/world/compound/rooms/persistent_compound_layout_planner.gd, load_default_graph(), generate_layout(), _place_rooms_attempt(), _connect_rooms(). One graph at graphs/persistent_compound_layout_v1.json. Existing room counts 10-13, 64x52 to 76x60 tile compound. Preserve default seven-seed behavior.
- Spatial: custodian/game/world/procgen/proc_gen_tilemap.gd owns physical floor, wall, region, collision/nav, level_data. world_placement_context.gd and minimap_view.gd read room/sector topology.
- Carrow: custodian/game/world/gothic_compound/gothic_compound_map.gd has East Machine 14x10, West Draft 12x10, Operations 20x14 independent interior transfers. It is a donor, not a route manager to duplicate. Carrow Yard has separate route migration and independent human scale calibration.
- Structural: design/04_architecture/COMPOUND_TILE_SYSTEM.md; damage via custodian/game/infrastructure/infrastructure_structure.gd take_damage()/heal()/get_integrity_modifier(); separate existing Damageable adapter needed where legacy sector damage meets new infrastructure.
- Economy: existing ResourceLedger, FabPipeline, BuildInventory, ConstructionPlacementController, InfrastructureRegistry, Power components; initial extra permanent build is existing Capacitor Bank.
- Combat: existing EnemyDirector / WaveManager, seeded attack lanes and objective selection. No independent base assault manager.
- Security: stealth acoustic foundations exist but no production camera/alarm network. Fixture observations must be local, provenance-bearing and power-aware.

## Proposed additive data contract

Profile enum walled_yard | connected_bunker; deterministic seed; stable room IDs and sector_id; versioned layer_id (surface | subsurface), room/yard/tunnel zones, stable connection IDs and typed edges (yard, gate, door, tunnel, vertical_entry); paired entry/return anchors and per-fixture IDs. Generated topology is immutable data; mutable doors/integrity/power/resources are held by existing runtime owners. Keep old level_data keys and legacy default behavior.

The shipped profile-selection contract is intentionally narrower: the optional
`legacy`, `walled_yard`, or `connected_bunker` ID is validated from
`custodian/game/world/compound/rooms/profiles/compound_archetype_profiles_v1.json`.
That **initial profile-contract-only release** retained the same surface geometry
for all IDs while adding versioned room/connector/level-data identity. Later
review-gated code has since implemented distinct `walled_yard_close_packed_v1`
and `connected_bunker_subsurface_v1` geometry. Omitted selection still preserves
the legacy planner output. Do not use the original profile-contract behavior as
current evidence that the archetypes share geometry.

### Shipped: `walled_yard` close-packed blockout

`walled_yard` selects geometry `walled_yard_close_packed_v1` on the single surface layer. The
planner runs the semantic room planner on a progressively tighter placement area (the tightest
inset that still places every mandatory building and reserves at least 22 percent open yard),
then adds:

- exactly two perimeter gates (`gate_primary`, `gate_secondary`) on different edges, each a
  corridor crossing the full perimeter thickness; `ingress` is exactly these two cells;
- one yard-facing exterior doorway per building with a stable ID (`door_<room>_exterior`),
  whose doorway and two apron cells open onto free yard rather than another building;
- a `perimeter` record (`perimeter_main`, rect, thickness, gate IDs) and the yard contract
  (`diagnostics.yard_ratio`, `cluster_margin_extra`, `gate_count`, `doorway_count`).

The planner fails closed (`walled_yard_gates_unplaceable`, `walled_yard_yard_too_small`,
`walled_yard_room_unreachable` and similar) if any gate, doorway, building or anchor is not
reachable from the gates over modelled floor. `ProcGenTilemap` stamps the perimeter in the
existing floor/wall layer and seals every ring wall cell that is not a gate, so roads, routes and
terrain cannot breach the boundary. Level data adds `compound_perimeter`, `compound_gates` and
`compound_building_doorways`. Opening or closing a gate is a physical crossing question only; no
gate state machine ships here.

Validated by `compound_walled_yard_smoke.gd` (planner contract plus the real generator).

### Shipped: `connected_bunker` layered blockout

`connected_bunker` now selects geometry `connected_bunker_subsurface_v1`. The compound
reservation is split into two disjoint layers inside one tile authority (`ProcGenTilemap`):

- **surface**: the north band holds the yard and two stable access housings (`surface_housing_NN`).
  Only this band opens to the outside; ingress cells outside it are dropped.
- **separator**: a solid band at least two tiles thick.
- **subsurface**: a wall-filled region below the separator. One continuous underground network
  holds all mandatory rooms along a 3-wide corridor spine; every room has a compartment threshold
  cell on the spine. Room-to-room travel is physical, never a transfer.

Each housing is paired with an underground spine anchor through a reversible `vertical_entry`
edge (`surface_anchor` and `subsurface_anchor`). Level data adds `compound_layers`,
`compound_surface_housings`, `compound_vertical_entries`, `compound_compartment_thresholds`
and `compound_spine_cells`; room and connector entries carry their owning `layer_id`
(`subsurface` for the network, `surface` for housings) while the top-level `layer_id` stays the
`surface` entry layer. The minimap projects both layers.

Layer ownership is enforced, not assumed. Every compound cell outside the surface band that is
not planned underground floor is sealed in `ProcGenTilemap`; the floor writers (roads, routes,
terrain, intent floors) refuse sealed cells. Underground cells are not terrain-required cells,
because they are reached through vertical entries rather than by walking from the surface spawn,
so reachability repair cannot carve a tunnel through the separator. The generic constructed
interior region is skipped for a layered compound, which owns all of its interior space.

The initial `compound_connected_bunker_smoke.gd` verifies planner topology and generator geometry, **not** an accepted physical entry/exit or collision/navigation/camera proof. Fresh independent review `REVIEW_COMPOUND_CONNECTED_BUNKER_BLOCKOUT.md` closed with `findings`: R0-01 (surface/subsurface anchors have no usable runtime transfer consumer) and R0-02 (the smoke disables real wall collision and navigation checks and never checks camera bounds).

The bounded R1 correction implementation adds `CompoundVerticalEntryController`, attached by
`ProcGenTilemap`, to move the Operator between each housing threshold and its paired underground
anchor. It derives the active layer from Operator position, locks out an immediate return until the
arrival tile is left, changes no layer while walking between underground rooms, and sets/restores
the authored camera bounds through the existing `CameraController`. The extended
`compound_connected_bunker_smoke.gd` exercises both entry pairs in both directions and checks real
wall collision, the project's `NavigationSystem`/`AStar2D` graph, camera isolation, and restoration.
The correction is not accepted until its fresh cycle-1 independent review passes; do not describe B
as playable/accepted before that gate.

## Security and traversal V1

Powered actual gates and compartment doors, explicit authorized physical entry/exit, local access panel, emergency egress, powered status lighting, optional existing turret mounts; closed/locked/breached must alter real nav/collision through canonical tile authority. No softlock if power fails. Source-specific sensor observations only, not global enemy clairvoyance. Camera feeds, radar, overhead drones, surveillance UI and seamless surface-to-underground movement are later independent choices; B's underground room-to-room continuity is required immediately.

## Assault/recovery dependent gameplay

Prepare or fabricate resources -> establish defenses and build infrastructure -> director sends bounded objective-based pressure -> real structural damage reduces power/defense/fabrication service -> local resource-consuming Operator repair OR a valid new Capacitor Bank build -> restore service, preserve state and prepare next attack. The critical choice is finite supply between repair and expansion. No free repair of destroyed structures, duplicate HP or double resource debits.

## Dependency-gated implementation order (reconciled 2026-10-17)

```
profile-contract + passed review [complete]
  ├─ walled-yard-blockout [landed] -> walled-yard paired review [active]
  └─ connected-bunker-blockout [landed] -> review [findings R0-01/R0-02]
       -> bunker-review-corrections-1 [implemented, review pending]
       -> correction paired review [required]
  BOTH accepted reviews -> interior-traversal-integration -> secure-access-fixtures
       -> archetype-playable-proof -> recovery-damage-coupling
       -> (recovery-assault-objectives | recovery-field-repair | recovery-build-restoration)
       -> recovery-end-to-end-proof
```

The `interior-traversal-integration` packet must **reuse** the B correction's accepted paired-anchor transfer and camera ownership. It owns Type A independent room transitions and layer-aware world/Operator/environment integration, not another B transfer controller. Every ordinary successor waits for an accepted `passed` independent review; the parent B `findings` result gates only its bounded correction, not downstream gameplay. Runtime and asset intake remain separable: no unapproved PNG blocks mechanical geometry/repair tests.

## Technical acceptance

Both archetypes: deterministic seeds 1,2,3,10,42,99,1337; room/connectivity/sector/ingress/minimap/fixture identity; no dead ends, invalid collision, spurious room transfer, camera bleed or duplicate Operator. A has continuous wall except enumerated legitimate gates and safe yard route. B has genuinely walkable underground graph and safe surface↔subsurface links. Security changes real pathability, damage real capability, repair/build finite resources, and revisits preserve exact state. Human visual/gameplay acceptability remains an independent review gate.

## Art demand

See COMPOUND_ARCHETYPES_REQUIRED_ASSETS_V1.md and canonical required_assets.registry.json. Registry rows are needed, not fulfilled. Reuse existing approved tiles/props and diagnostic render geometry until art human approval.
