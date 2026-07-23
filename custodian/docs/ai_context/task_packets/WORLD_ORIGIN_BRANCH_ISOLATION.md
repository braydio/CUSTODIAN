# WORLD ORIGIN BRANCH ISOLATION

- Status: `complete`
- Authority: `design/04_architecture/ROUTE_TRAVERSAL_SYSTEM.md`; `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`
- Goal: Replace two-path authored-route isolation with an explicit top-level `world_origin_branch` contract that remains isolated for the full route session and restores exact entry state only on exfil.
- Files: `world_ingress_site.gd`, `contract_world_loader.gd`, `game.tscn`, Sundered Vista presentation, lifecycle/route/scene smokes, level-pipeline CI, and affected design/context docs.
- Constraints: Preserve Operator, Camera2D, shared lighting, LevelLoader, RouteTraversalManager, route coordinates, and camera bounds; keep `ConnectedMaps` compatibility lookup; do not make Vista own origin-world mutation.
- Acceptance: Static and dynamic origin branches hide and disable on entry, remain isolated across Vista/Causeway/Front Gate transitions, restore exact state only at `@world_origin`, persistent services remain active, and focused plus adjacent route/lifecycle suites pass.
- Completed: Shared grouped-branch snapshot/isolation/restoration; static and dynamic branch classification; Vista authority cleanup; leaking-sector visual/collision regression; full-route persistence assertions; static scene contract; CI/docs updates; ingress physics re-entry overlap repair.
- Deferred: Removal of the `ConnectedMaps` compatibility path remains tied to retiring that container.
