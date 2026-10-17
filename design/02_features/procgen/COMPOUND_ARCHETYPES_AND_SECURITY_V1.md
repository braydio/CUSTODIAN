# Compound Archetypes and Security V1

**Status:** Approved planning; profile-selection contract and the Type B (`connected_bunker`) layered blockout shipped. Type A geometry, interior traversal integration and security/gameplay remain deferred.
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
All three currently select the existing surface topology. Explicit selection
adds versioned archetype/layer metadata to planner rooms, connectors, and
exported level data; omitted selection preserves the legacy planner output.
No subsurface layer, yard gate, or archetype-specific geometry is implied by
this metadata for `legacy` and `walled_yard`.

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

Validated by `compound_connected_bunker_smoke.gd` (planner contract plus the real generator).

## Security and traversal V1

Powered actual gates and compartment doors, explicit authorized physical entry/exit, local access panel, emergency egress, powered status lighting, optional existing turret mounts; closed/locked/breached must alter real nav/collision through canonical tile authority. No softlock if power fails. Source-specific sensor observations only, not global enemy clairvoyance. Camera feeds, radar, overhead drones, surveillance UI and seamless surface-to-underground movement are later independent choices; B's underground room-to-room continuity is required immediately.

## Assault/recovery dependent gameplay

Prepare or fabricate resources -> establish defenses and build infrastructure -> director sends bounded objective-based pressure -> real structural damage reduces power/defense/fabrication service -> local resource-consuming Operator repair OR a valid new Capacitor Bank build -> restore service, preserve state and prepare next attack. The critical choice is finite supply between repair and expansion. No free repair of destroyed structures, duplicate HP or double resource debits.

## Dependency-gated implementation order

profile-contract -> (walled-yard-blockout + connected-bunker-blockout) -> interior-traversal-integration -> secure-access-fixtures -> archetype-playable-proof -> recovery-damage-coupling -> (recovery-assault-objectives + recovery-field-repair + recovery-build-restoration) -> recovery-end-to-end-proof.

Every arrow means predecessor PAIRED REVIEW passes; no downstream runtime work should start based only on implementation claim. No new art is necessary for mechanical blockouts.

## Technical acceptance

Both archetypes: deterministic seeds 1,2,3,10,42,99,1337; room/connectivity/sector/ingress/minimap/fixture identity; no dead ends, invalid collision, spurious room transfer, camera bleed or duplicate Operator. A has continuous wall except enumerated legitimate gates and safe yard route. B has genuinely walkable underground graph and safe surface↔subsurface links. Security changes real pathability, damage real capability, repair/build finite resources, and revisits preserve exact state. Human visual/gameplay acceptability remains an independent review gate.

## Art demand

See COMPOUND_ARCHETYPES_REQUIRED_ASSETS_V1.md and canonical required_assets.registry.json. Registry rows are needed, not fulfilled. Reuse existing approved tiles/props and diagnostic render geometry until art human approval.
