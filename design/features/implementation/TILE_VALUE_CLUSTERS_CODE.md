# Tile Value Clusters — Implementation Packet

- Status: `complete`
- Authority: `design/features/implementation/TILE_VALUE_CLUSTERS.md`
- Goal: Add deterministic visual-only exterior floor clustering to `ProcGenTilemap`.
- Files:
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/game/world/procgen/proc_gen_map.tscn`
  - `custodian/tools/validation/floor_value_clusters_smoke.gd`
  - `custodian/tools/validation/run_procgen_validation_suite.sh`
  - active AI context docs
- Constraints:
  - no topology, traversal, collision, navigation, rescue, candidate, or ballistics changes
  - only registered/configured ordinary exterior floor sources
  - skip special semantic and elevation cells
  - deterministic ordering and hashing
- Acceptance:
  - same seed produces the same cluster signature
  - paint changes only source/atlas/alternative values for existing safe floor cells
  - floor/wall keys and gameplay metadata remain unchanged
  - missing variant registry safely skips
  - focused, default, and slow procgen validation pass
- Completed:
  - Added final-visual-only deterministic 12–35 center clustering with radius, strength, falloff, island noise,
    sparse flecks, and registered-source validation.
  - Added exported enable/debug/strength/source-registry controls and missing-variant warning.
  - Added conservative semantic/elevation/required-cell skip policy.
  - Preserved floor/wall membership and all gameplay metadata; evaluation candidates bypass the pass.
  - Added `floor_value_clusters_smoke.gd` to the default suite.
  - Default and slow procgen suites passed on 2026-07-09:
    `logs/procgen-validation-20260709-053534.log` and
    `logs/procgen-validation-20260709-053551.log`.
- Deferred:
  - dedicated dark/light/cracked/damp/ash production atlas sources
