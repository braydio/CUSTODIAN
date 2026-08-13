# Persistent Compound Layout System

Status: implemented and validated

## Purpose

The persistent contract-world compound is a deterministic semantic campus, not
an anonymous list of building rectangles. Standard generation produces 10–13
rooms selected from a bounded catalog, places them across core, operational,
and perimeter zones, connects every room to the Command Post, and exports the
same semantic topology to physical procgen geometry, static Sector placement,
and the shared minimap.

`ProcGenTilemap` remains generated-world authority. The
`PersistentCompoundLayoutPlanner` is a seeded generation helper. It owns no
simulation state, creates no Sector nodes, and does not change the production
`PROCGEN_ONLY` world-generation mode.

## Runtime Flow

```text
persistent_compound_layout_v1.json
        -> RoomGraph
        -> PersistentCompoundLayoutPlanner
        -> ProcGenTilemap floors/walls/regions
        -> semantic level_data
        -> ContractWorldLoader + MinimapView
```

`RoomGraph` supplies stable room ordering, count bounds, connection rules, and
layout metadata. Missing authored `.tmj` templates never block V1 procedural
shell generation. `RoomLoader` and `LayoutAssembler` remain the future curated
interior layer.

## Catalog

Mandatory rooms are Command Post, Power, Archive, Defense, Storage, North
Transit, South Transit, and Maintenance. Optional rooms are Fabrication,
Comms, Barracks, Hangar, Vault, Service Annex, Observation, and a second
Maintenance room within graph limits.

Canonical live Sector mappings are semantic and optional:

- `power` -> `POWER`
- `archive` -> `ARCHIVE`
- `defense` -> `DEFENSE`
- `storage` -> `STORAGE`
- `north_transit` -> `NORTH_TRANSIT`
- `south_transit` -> `SOUTH_TRANSIT`

Rooms with no matching live Sector use an empty `sector_id`. Room and Sector
are not synonyms.

## Layout Contract

Standard compounds contain 10–13 rooms inside a bounded 64x52–76x60 tile
footprint, clamped to usable map bounds. Layout uses one seeded RNG. Required
rooms are placed first, optional weighted selection fills the target, room
footprints vary within graph bounds, and candidate placement scores zone fit,
edge preference, preferred-neighbor distance, asymmetry, and congestion.

Command Post is near the center. Archive is protected/core-biased. North and
South Transit approach their named edges. Defense, Hangar, and Observation are
perimeter-biased. At least 22% of usable interior remains non-room circulation,
courtyard, or service space.

Every accepted room is connected to Command Post. Connections expose room-edge
doors and deterministic 3-tile-wide orthogonal corridor paths that do not cross
unrelated room interiors. Required placement failure returns `valid = false`;
the retired four-square grid is never a production fallback.

Planner output includes semantic `rooms`, `connections`, `corridor_cells`,
`courtyard_cells`, anchors, diagnostics, and a compatibility-only `buildings`
rect projection. Array position carries no semantic meaning.

## Physical Geometry

The compound yard remains walkable. Each semantic room has a walkable interior
and perimeter walls opened only at generated door cells. Connection corridors
are walkable and use the same floor/wall authority as navigation and collision.
Region metadata distinguishes `compound_room` with room subtype,
`compound_corridor`, and `compound_courtyard`.

The Command Post provides deterministic `primary_anchor` and
`terminal_anchor` interior cells. Existing gameplay authority for the terminal
is unchanged.

## Minimap

`MinimapView` consumes semantic rooms and actual connection paths. It draws the
outer perimeter, corridors, variable room footprints/outlines, optional labels
in Overview/terminal mode, ingress, then dynamic markers. Compact HUD maps may
suppress labels. Old level data containing only `compound_buildings` remains a
safe presentation fallback.

## Compatibility and Deferred Work

- `compound_buildings` remains a rect mirror for legacy consumers.
- `ContractWorldLoader` may use its renamed legacy index map only when semantic
  room data is absent.
- `default_compound.json` remains a dormant EDGAR sample.
- Authored `.tmj` stamping, furniture/art, NPC staffing, new Sectors,
  multi-floor compounds, save migration, EDGAR/HYBRID world migration, and
  unrestricted construction are deferred.

## Acceptance

- Seven fixed planner seeds are deterministic, yield 10–13 rooms, and produce
  at least three topology signatures.
- Mandatory rooms, zone placement, clearance, negative space, connectivity,
  physical doors/corridors, semantic Sector placement, and minimap compatibility
  are covered by focused smokes.
- Production generation no longer uses fixed two-column or building-index
  semantics.

## Next Agent Slice

Replace individual procedural room shells with authored `template_family`
variants through the existing `.tmj` pipeline while preserving this semantic
reservation, topology, level-data, Sector, and minimap contract.
