# PERSISTENT COMPOUND LAYOUT V1

- Status: `complete`
- Authority: `design/02_features/procgen/PERSISTENT_COMPOUND_LAYOUT_SYSTEM.md`
- Goal: retire the fixed four-building procgen compound and make a deterministic 10–13-room semantic campus live in physical geometry, level data, Sector placement, and the shared minimap.
- Files: RoomGraph metadata, new planner/graph, ProcGenTilemap, ContractWorldLoader, MinimapView, focused validation, active docs, and root `REQUIRED_ASSETS.md`.
- Constraints: preserve `PROCGEN_ONLY`, ProcGenTilemap authority, existing Sector nodes, seeded determinism, old level-data fallback, and future `.tmj` compatibility; do not create art or simulation authority.
- Acceptance: mandatory catalog; variable asymmetric zones/footprints/topology; connected walkable doors/corridors; 22–55% negative space; semantic level data and Sector mapping; minimap topology; multi-seed deterministic/runtime/minimap smokes and relevant regressions.
- Deferred: authored `.tmj` stamping/interiors, new Sectors, furniture/art, NPC staffing, save overhaul, EDGAR/HYBRID migration, multi-floor compounds, and unrestricted construction.

## Completion notes

- Live generation now selects 10–13 rooms from the semantic catalog, stamps physical shells/doors/corridors, reserves those walkable regions against TerrainBuilder, and exports versioned semantic level data plus compatibility rectangles.
- Existing POWER, ARCHIVE, DEFENSE, STORAGE, NORTH_TRANSIT, and SOUTH_TRANSIT nodes resolve by `sector_id`; legacy index mapping is used only for old level data. Command terminal placement prefers the Command Post interior anchor.
- Shared MinimapView renders generated connection paths, unequal room footprints, overview labels, ingress, and legacy fallback.
- Deterministic seeds `1, 2, 3, 10, 42, 99, 1337` passed planner comparison with multiple topology signatures. Runtime seed `424242` and existing compound/terrain regression seeds passed focused validation.
- Moment Forge changed-file routing suggested no stable scenario. Curated `.tmj` interiors remain the explicit next content slice.
