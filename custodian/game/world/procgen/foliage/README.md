# Procgen Foliage

- Belongs here: final-visual procgen foliage generation, deterministic foliage spawn policy, fruit child sprite placement, foliage clear/remove helpers.
- Does not belong here: terrain connectivity, road authority, elevation traversal, contract candidate scoring, authored-scene claims, campaign state.
- Current migration status: generation/clear/remove are extracted to `procgen_foliage_spawner.gd`; occlusion runtime updates remain in `ProcGenTilemap`.
- Current source of truth: `procgen_foliage_spawner.gd` for foliage generation policy; `game/world/procgen/proc_gen_tilemap.gd` remains the facade and query host.

Streaming reveal foliage behavior must remain compatible with reveal-time spawning. Foliage may mark `foliage_cover` region metadata exactly as previous behavior did, but must not mutate terrain, road, elevation, or contract validation authority.
