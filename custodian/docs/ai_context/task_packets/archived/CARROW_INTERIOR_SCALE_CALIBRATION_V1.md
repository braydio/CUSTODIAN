# CARROW INTERIOR SCALE CALIBRATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `carrow-interior-scale-calibration-v1`
- Authoring handoff: `auto`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-carrow-operations-house-interior-v1`
- Locks: `carrow-yard-route`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-carrow-interior-scale-calibration-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new debug-only Operator/camera/collision fixture and room builder must not mutate shipped three-room authority`
- Reviewed main: `9e0912dff173a65f808da14df698923aea426c8d`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0`
- Visual review: `conditional`
- Goal: Produce three EXACT, individually launchable East Machine House size test scenes with identical gameplay settings, deterministic wall/machinery geometry and named debug entrypoints so **the user** can compare physical scale.
- Completion boundary: Implement fixed 24×18, 30×22 and 36×26 debug fixtures, real Operator and camera, source-art/static-geometry reuse, input overlays/waypoint controls, reproducible 1:1 evidence and geometry JSON, with green objective tests and unchanged production East/West/Operations. No agent scale recommendation, no production room dimension modification.
- Current measured state: Current `gothic_compound_map.gd` has a 14×10 East layout, 12×10 West and 20×14 Ops in `INTERIOR_ROOM_DEFINITIONS`, 32px tiles, per-cell floor Sprite2Ds, 13 East art placements and 3 East storage bindings. The Operations House landed at `fea61dc39c34e7a2d5bc50c8f5fd1a34e29713d1` and independent review completed PASS at `8edc7252b`, verifying 41/41 changed-file checks and correct collision/exit. The user expressly says small rooms feel like a Pokémon house and wants **human-owned size choice** after deterministic debug scene trials. Existing three-room proof is not human size approval.
- Evidence: `design/05_levels/CARROW_YARD_POST_INTERIORS_PLANNING_V1.md`; `custodian/game/world/gothic_compound/{gothic_compound_map.gd,carrow_machine_house_door.gd}`; `custodian/game/actors/operator/operator.tscn`; `custodian/tools/validation/{carrow_yard_interior_smoke.gd,carrow_backdrop_isolation_smoke.gd,carrow_operations_house_interior_smoke.gd}`; `REVIEW_CARROW_OPERATIONS_HOUSE_INTERIOR_V1_CLAUDE_SUMMARY.md`.
- Task-specific authority: Original Carrow named-room system owns production room metadata, collision, storage, light, and indoor camera/environment, and must remain unchanged. Debug harness may reuse read-only registered Carrow assets and existing Operator/camera components but not create a second production world/route. User owns experience/size selection.
- Work surface: New debug scene fixtures under `custodian/scenes/debug/`, bounded builder/controller under `custodian/tools/level_authoring/` or a narrower existing Carrow debug module, a new deterministic smoke under `custodian/tools/validation/`, and exact validation-manifest registration for new scripts. No edits to production `INTERIOR_ROOM_DEFINITIONS` or the gate/route implementation.
- Change:
  1. Create exactly these launchable Godot scenes with no aliases and exactly one immutable size each:
     `res://scenes/debug/carrow_machine_house_scale_24x18.tscn` = 24×18 cells = 768×576px = 432 floor cells;
     `res://scenes/debug/carrow_machine_house_scale_30x22.tscn` = 30×22 = 960×704px = 660 cells;
     `res://scenes/debug/carrow_machine_house_scale_36x26.tscn` = 36×26 = 1152×832px = 936 cells.
     All cells are exactly 32px, never resized. Do not add random layout variants, new art, procedural prop placement or production serialization.
  2. Use local integer tile coordinates `(0,0)` upper left. For `(W,H)`, floor covers every cell `0<=x<W, 0<=y<H`. Single-cell-thick collision perimeter occupies `x=0, x=W-1, y=0, y=H-1` EXCEPT for 4 open south doorway cells `x=W/2-2, W/2-1, W/2, W/2+1` on `y=H-1`. Reserve exactly 4 center aisle columns `W/2-2..W/2+1` across `y=1..H-2`. The only interior solid equipment rectangles are NW relay `Rect2i(3,3,6,4)`, NE switchgear `Rect2i(W-9,3,6,4)`, SW service `Rect2i(3,H-8,5,3)`, SE power `Rect2i(W-8,H-8,5,3)`. Do not infer collision from texture alpha. Tag each collider with tile coords and owner label, and reject an overlap with room bounds, aisle, other equipment or doorway.
  3. Place exactly the existing **13 art sources** at fixed, variant-derived room-local *anchor cells*, with current source filenames/Z values and native texture sizes, never stretch. Names and anchors:
     `NorthWallPanelled=(W/2-5,2)`, `NorthWallConduit=(W/2+3,2)`,
     `WestWall=(1,H/2)`, `EastWall=(W-1,H/2)`,
     `SouthDoorway=(W/2-1,H)`,
     `RelayBank=(4,4)`, `Switchgear=(W-7,4)`,
     `PartsLocker=(3,H-7)`, `Workbench=(6,H-7)`,
     `ServiceCabinet=(4,H-5)`, `ReplacementModules=(7,H-6)`,
     `ConduitJunction=(W-5,H/2)`, `PowerCabinet=(W-5,H-6)`.
     Keep exactly three East resource bindings, anchored to `PartsLocker`, `ReplacementModules`, `PowerCabinet`, with current IDs/contents and no visible generic chest. Identify any presentation-versus-defined-solid mismatch in geometry evidence; do not autonomously redesign dimensions or art based on that observation.
  4. Expose three deterministic waypoint teleports in tile coordinates `ENTRY=(W/2,H-3)`, `CENTER=(W/2,H/2)`, `NORTH=(W/2,7)` (snap actor to center of named tile). 1, 2, 3 select respective waypoint; R resets fixture; F1 toggles *actual physics collider overlay*, F2 the 32px grid, F3 readonly values. Expose variant ID, grid and px extent, room-local Operator tile, camera zoom, fixed floor/solid/collider/art counts. Do not call a waypoint a 'good' position, merely assert it has clearance for actual Operator shape.
  5. Load the real Operator movement/collision source and gameplay camera defaults in debug-only scene, without duplicate persistent Operator or separate global route manager. Use identical viewport size, camera zoom, Operator scale/move speed, lighting, asset state and 13-art/3-storage counts across scenes. If the actual boot/Operator architecture prevents direct scene instantiation, use one documented debug-only adapter feeding the same components, not an invented proxy physics model.
  6. Implement one reusable debug fixture builder with fixed config table, not three copies of map logic. Floor rendering is allowed to use existing batch/TileMapLayer where the art remains unchanged; do not rewrite production rendering or optimize purely by intuition. Identical reset and no persistence across different fixture scenes. The default existing rooms, route, caches, and map data remain untouched.
  7. Generate fixed-viewport 768×576 1:1 captures per scene at ENTRY/CENTER/NORTH and a machine-readable per-variant `geometry.json` under ignored `reports/carrow_scale_calibration/<size>/`. Include occupied cells, exact tile/pixel rectangles, camera zoom, Operator shape, waypoint coords, floor/art/collision counts, and assertion results. Aggregate the 3 JSONs into `comparison.json` with numeric facts only. Do not include qualitative grades, aesthetic critique or a 'winner'.
- Preserve: East 14×10 and legacy short-bottom-row production exception; West 12×10, Ops 20×14; three live production room IDs, their door names, real resource depletion, weather/camera/rain state, 32px art, 13 East art sprites, three caches, the main Transfer Frame, route migration ownership, existing user dirty root files and any unrelated worktrees.
- Non-goals: Production rescale of ANY interior, new equipment/tiles, GameRoot routing, new Gatehouse/Gantry code, region aesthetic judgment, invented 'playable' score, choosing preferred variant, post-hoc camera adjustment, adjusting Operator speed, repacking Asset V2 masters, or entering production asset_drop/inbox.
- Acceptance:
  - A1. Three exact scene paths resolve and launch with 24×18/30×22/36×26 true pixel dimensions; floor counts 432/660/936; each has one actual Operator and only the expected camera authority.
  - A2. Colliders exist on every declared solid wall/equipment cell and on no open doorway/aisle cell; 4-cell exit; equipment/aisle nonoverlap; tests use real Operator physics shape for route-clearance checks with *named deterministic waypoints*, not AI-rated gameplay.
  - A3. All 13 named native-scale East registered art assets and three art-bound storage nodes exist in every variant; source resources and exact native scale stay unchanged; no duplicate chest art.
  - A4. F1/F2/F3/1/2/3/R controls work; reset reproducible; camera/viewport/Operator config equal between sizes.
  - A5. Nine 768×576 captures plus three `geometry.json` and `comparison.json` are generated from exact launched scenes with no ratings or aesthetic recommendations.
  - A6. Unmodified production files match base tree and the existing East/West/Ops/backdrop-focused regressions remain green; missing art, malformed configuration, doorway obstruction and overlapping equipment reject invalid fixtures; `git diff --check` and changed-file validation pass.
- Validation: Create and run one new deterministic fixture smoke for exact config/equipment/doorway/waypoints/Operator shape/camera/asset/negative checks, then run EXISTING `custodian/tools/validation/carrow_yard_interior_smoke.gd`, `custodian/tools/validation/carrow_operations_house_interior_smoke.gd`, and `custodian/tools/validation/carrow_backdrop_isolation_smoke.gd` (plus the existing West test by live discovery). Run changed-file validation and AI-context/packet-pair checks. The new fixture file is not a pre-existing validation dependency and MUST be authored before execution. Do not run headless aesthetic evaluation.
- Task overrides: `none`
- Deferred: User picks actual production size (or requests further fixed variants) after playtesting. Only a later approved task changes production East/West/Ops and refreshes Gatehouse dimensions.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: `Three separately launchable scenes use 24x18, 30x22 and 36x26 native 32px geometry. The shared controller reuses the actual Operator, CameraController, Carrow production floor/art resources and East storage scene without instantiating GothicCompoundMap or changing production room data. Fixture smoke verifies exact floor/collider/art/storage counts, actual capsule clearance, controls, negative geometry/art inputs and all three camera profiles. Nine native 768x576 renderer captures plus three geometry.json files and comparison.json are present under ignored reports/carrow_scale_calibration/; local retained evidence is under .git/custodian-review-runs/carrow-interior-scale-calibration-v1/20261016T012240Z-44c5ccfe48e1/. Validation was green: changed-file coverage 34/34, new fixture, East/West/Ops and backdrop regressions.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The packet specified an ignored reports/carrow_scale_calibration output path, but the repository had no matching ignore rule. A narrowly scoped root .gitignore rule was added. The first fresh Godot editor scan also had to import the project asset cache.`
- Root cause / contributing factors: `The packet's local-artifact assumption was not represented in the repository ignore policy.`
- Prevention / pipeline improvement: `Keep task-specific generated-evidence paths and their ignore rules authored together.`
- Tooling / docs drift discovered: `reports/carrow_scale_calibration/ was not ignored despite the packet calling it an ignored output path.`
- Follow-up: `review-carrow-interior-scale-calibration-v1`
- What worked: `The fixture smoke queries the real Operator capsule against the actual PhysicsServer2D space, while deterministic cell ownership checks prove the exact layout without inferring collision from art.`

## Next Handoff

- Next workstream: `review-carrow-interior-scale-calibration-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0`
- Refresh reason: `none`
- Next action: Independent deterministic review validates debug fixtures, counts, actual collider/Operator, and production nonmutation, then publishes scene entrypoints for human playtesting. Do not request game-feel approval to complete the debug harness itself.
- Blockers or open questions: `No missing visual decision blocks building fixed debug fixtures; production resizing deliberately human-gated.`

## Independent Review

### Review Receipt: review-carrow-interior-scale-calibration-v1
- Schema: `custodian.paired_review.v1`
- Review workstream: `review-carrow-interior-scale-calibration-v1`
- Review target workstream: `carrow-interior-scale-calibration-v1`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Reviewed main: `200fb5ba35c41526e339198c156d0afc7c4455f1`
- Reviewed implementation commit: `200fb5ba35c41526e339198c156d0afc7c4455f1`
