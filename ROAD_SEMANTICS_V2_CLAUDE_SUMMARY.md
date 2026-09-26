# Road Semantics V2 — implementation summary

- Starting HEAD: `1fa207d6cd04181543dcd5c97ed4bc0f45a591db` (`main`).
- Production now deterministically classifies intermittent ruined-road fragments and an optional service apron from existing route/floor authority; it does not carve, repair, or mutate gameplay geometry. The archived wide-road path remains disabled.
- Fixed seed `824790` (128×104): 4 road fragments / 115 ruined-road cells; no service apron or parking cells qualified. Resolver fixtures also cover a valid apron and reject one below 30 cells.
- Same-seed fingerprint is stable. The production smoke confirms floor, wall, route playability, and elevation remain unchanged; soft paths resolve to biome-natural material unless independently classified as road.
- Focused road-semantics, surface-material, and macro-presentation smokes passed. Shared `--changed --json` passed 66/66, including all three focused cases.
- Archived `procgen_road_surface_roles_smoke.gd` failed because its production-default scene generated zero `_main_road_tiles` while the old assertion requires a substantial carved network. It was left unchanged; production remains correctly disabled.
- Fixed-seed overview and detail captures are at `reports/procgen_road_semantics_v2/seed_824790_overview.png` and `reports/procgen_road_semantics_v2/seed_824790_road_fragment_detail.png`. Direct review confirms playability/terrain composition, but the fragment detail is a diagnostic highlight, not production road artwork; visible road-art acceptance is not demonstrated. No dedicated Road Semantics Moment Forge scenario is registered.
- Full procgen suite had two failures: `sundered_keep_procgen_frontage_smoke` (depth-backdrop assertions) and `terrain_gameplay_packs_smoke` (atlas source/manifest path mismatches). Other suite cases passed; slow contract-rescue diagnostic was skipped by the suite recipe.
- No road art, topology, navigation, collision, or movement tuning was added. The remaining visible-material presentation and stale archived-smoke setup require follow-up; neither was masked by enabling old roads.
