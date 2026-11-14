# PROCGEN ELEVATION CONNECTOR TOPOLOGY V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-elevation-connector-topology-v1`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-operator-elevation-traversal-enforcement-v1`
- Locks: `procgen-terrain, elevation-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, architecture`
- Paired review workstream: `review-procgen-elevation-connector-topology-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `changes generated topology and height/traversal reservations after Operator enforcement lands`
- Reviewed main: `350ee94e4b3b80010c0970903f3418966df3b851`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Visual review: `none`
- Goal: Generate a deterministic multi-cell lower-to-upper Alpine traversal module using existing ramp/stair semantics, with a shelf/shoulder wrap and safe upper overlook.
- Completion boundary: After required planning refresh, one bounded connector planner reserves lower landing, shelf turn, ascent, upper landing/overlook and exclusion footprint; TerrainBuilder/ElevationMap realize exactly one logical height transition; claims/connectivity remain valid; level data exports exact geometry for A3.
- Current measured state: REFRESH REQUIRED. TerrainBuilder/ElevationMap have height 0/1 + ramp/stair/ledge/drop semantics and rollback. ASCENT_FIELD generates terraces/pockets but no explicit multi-cell production connector module. Broad reserved-region elevation is not a traversal-module grammar.
- Evidence: TerrainBuilder, ElevationMap, ASCENT_FIELD/intent owners, plus landed A1 implementation/review to be added at refresh.
- Task-specific authority: ASCENT_FIELD remains upstream shape authority; TerrainBuilder/ElevationMap own height/traversal; procgen claim/reservation APIs own footprints; presentation is downstream.
- Work surface: new focused connector planner under procgen terrain/intent plus narrow ProcGen orchestration/export and deterministic topology validation.
- Change:
  1. REFRESH FIRST from archived A1 implementation/review and latest main. Replace API/test/schema placeholders and re-run packet-authoring preflight before promotion.
  2. Plan deterministic `shelf_wrap` candidates with one logical height step, target >=5x4 lower/upper landings, >=3-cell ascent width, >=4-cell ascent run, one shoulder/shelf turn and total target footprint <=14x14 cells.
  3. Realize the transition only through existing ramp/stair semantics. No new hand-over-hand traversal type in V1.
  4. Reserve all route/landing/ascent/shelf cells against props, foliage, ordinary cliff presentation and incompatible authored/story/faction/compound claims.
  5. Fail closed if no valid placement exists; never disable TerrainBuilder connectivity rollback or carve through claims to force a route.
  6. Export a stable connector record: id/archetype/orientation/bounds, lower+upper landing cells, ascent/shelf cells, logical heights, presentation footprint/anchors and reservation cells. Lock exact schema during refresh.
  7. Keep standard NavigationSystem traversal through the ramp/stair edges so existing navigation-driven enemies can use the route.
- Preserve: accepted-seed determinism, route/claims, TerrainBuilder rollback/rescue, ordinary cliff semantics outside reservations, streaming and spawn validity.
- Non-goals: no production art, renderer rewrite, true Z physics, mantle state, vehicle support or mandatory connector on every seed.
- Acceptance:
  1. Valid synthetic terrace pair deterministically produces one complete shelf-wrap plan; claim/space/height invalid fixtures produce none.
  2. Every ascent edge is legal under ElevationMap; both landings are runtime-walkable and route-connected.
  3. Connector reservation remains clear of conflicting walls/props/foliage/ordinary cliff stamps; dropping reservation enforcement fails coverage.
  4. Fixed-seed export is deterministic and contains all geometry/anchors needed for A3 sizing without reading pixels.
  5. A navigation-driven grunt fixture can path through the standard ramp/stair connector while neighboring ordinary cliff edges remain impassable.
- Validation: At refresh name exact landed A1 coverage. Add connector planner/realization smoke; rerun terrain/elevation/intent/ascent/navigation/reservation/determinism checks, changed-file validation and `git diff --check`.
- Task overrides: `none`
- Deferred: A3 owns production art; A4 owns cliff/presentation integration.

## Handoff
- Next workstream: `review-procgen-elevation-connector-topology-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Refresh reason: `A1 changes the exact Operator/provider proof surface and current terrain/intent owners may move; re-lock APIs, tests and connector export schema from landed main.`
- Next action: `After A1 review PASS, return to this planning chat, refresh this implementation/review pair, then promote.`
- Blockers or open questions: `none`
