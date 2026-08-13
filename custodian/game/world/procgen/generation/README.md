# Procgen Generation

- Belongs here: generation contexts, level-data builders, candidate metrics, construction summaries.
- Does not belong here: live actor behavior, HUD pages, persistent campaign mutation.
- Current migration status: scaffold only; candidate metrics and level-data export still live in coordinator files.
- Current source of truth: `game/world/procgen/proc_gen_tilemap.gd`, `game/world/procgen/custodian_contract_map.gd`.

Runtime topology mutation remains in `ProcGenTilemap`. Its connector dry-run is
also the placement precondition for isolated Ash-Bell pockets, so generation
acceptance and later White Thread commit use one definition of valid geometry.
Cached runtime-health counters are updated only at wall, boundary, navigation,
and terrain mutation sites; Observatory sampling is read-only.
