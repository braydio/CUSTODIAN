# Terrain Gameplay Art Runtime Visuals

- Status: `complete`
- Authority: `design/04_architecture/REGION_GENERATION_SYSTEM.md`
- Goal: Wire registered terrain gameplay art into existing procgen visual selection without changing topology, traversal, rescue, candidate acceptance, or ballistics.
- Files: `proc_gen_tilemap.gd`, `terrain_builder.gd`, terrain gameplay smokes, procgen suite, AI context docs.
- Constraints: Visual substitutions only; preserve source IDs 32–59; no new chasm or bridge generation; deterministic connector/chasm variants; directional stairs remain on the stable fallback when direction is unknown.
- Acceptance: All 62 gameplay-pack IDs resolve and paint; safe ascent/connector/existing-chasm paths use new art; default and slow procgen suites pass.
- Completed: Source-map entries 60–123 and opt-in runtime usage debugging added. TerrainBuilder/compound industrial ramps select Ascent Pack wide ramps; surviving compound-connector floor and authority-repair/rescue floor select deterministic Connector Pack visuals; existing chasm-drop visuals resolve to deterministic Chasm Pack void/gap art. Registration/runtime-map and focused paint-path smokes cover all 62 IDs and stable legacy IDs. Default and slow procgen suites passed on 2026-07-09 (`procgen-validation-20260709-034801.log`, `procgen-validation-20260709-034815.log`).
- Deferred: Directional stair art until stair direction metadata is authoritative; bridge placement until explicit crossing generation exists.
