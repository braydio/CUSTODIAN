# Tile Value Clusters

## Status

- Type: Procgen visual presentation
- Runtime: `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Authority boundary: visual floor selection only
- Last updated: 2026-07-09

## Goal

Break up large procgen floors into deterministic, uneven islands of related value and material without changing
the generated world graph. Clusters should read as accumulated wear, damp, moss, soot, cracking, or local stone
variation rather than per-cell checkerboard noise.

## Runtime Contract

The pass runs after final road and terrain visual placement and before streaming reveal, props, and foliage. It may
replace only the `source_id`, atlas coordinate, and alternative tile used to draw an already-walkable exterior
floor cell.

It must not write to:

- height, traversal, ramp direction, terrain type, edge profile, or ballistics data
- required-cell, intent-graph, road-connectivity, or candidate-acceptance data
- wall, chasm, collision, navigation, or runtime gameplay authority

The set of floor cells and wall cells must be identical before and after the pass.

## Cluster Model

- deterministic from the procgen map seed
- 12–35 cluster centers, scaled by map area
- radius 3–9 cells
- strength 0.15–0.45, multiplied by the exported global strength
- radial falloff plus deterministic low-amplitude flecks
- dominant local family selects the replacement floor source
- irregular threshold modulation prevents circular stamps and checkerboard noise

## Safe Cell Policy

Eligible cells must:

- already exist in floor visual authority
- have no wall authority
- use one of the configured ordinary exterior floor sources
- remain ordinary walkable ground

Skip ramps, stairs, ledges, drops, blocked cells, elevated feature art, roads/paths/parking, connector corridors,
spawn clearings, portals, authored claims, interiors, thresholds, gates, objective/reservation regions, and any
known required route or ingress marker.

## Variant Registry

The current procgen scene configures two registered full-grid exterior floor sources:

- source 9: grass/moss value family
- source 10: stone/worn value family

These provide a safe initial clustered contrast without inventing TileSet source IDs. Dedicated production sources
remain required for:

- `sundered_floor_dark_01`
- `sundered_floor_light_01`
- `sundered_floor_cracked_01`
- `sundered_floor_damp_01`
- `sundered_floor_moss_01`
- `sundered_floor_ash_01`
- `sundered_floor_worn_01`

If fewer than two configured sources resolve to valid atlas tiles, the pass performs no writes and reports:

```text
[ProcGen] floor_value_clusters SKIP no registered floor value variants
```

## Debugging

Exports:

- `floor_value_clusters_enabled`
- `floor_value_cluster_debug`
- `floor_value_cluster_strength`
- `floor_value_cluster_variant_source_ids`

Debug output:

```text
[ProcGen] floor_value_clusters: clusters=X cells_changed=Y skipped=Z
```

## Acceptance

- identical seed and input produce identical changed cells and visuals
- different seeds can produce different cluster signatures
- at least one cell changes when two valid sources and eligible floor cells exist
- no floor/wall membership or gameplay metadata changes
- existing procgen default and slow validation suites remain green

## Next Agent Slice

- Goal: register dedicated Sundered floor value families and replace the current two-family proxy registry.
- Files: `procgen_world_tileset.tres`, terrain ingest/registration tools, `proc_gen_map.tscn`.
- Constraints: preserve source-ID stability and keep all variants floor-only.
- Acceptance: seven named production families resolve, cluster smoke covers each family, and visual review shows no
  hard seams or checkerboard distribution.
