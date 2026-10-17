# CARROW INTERIOR LAYOUT AUTHORING V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `carrow-interior-layout-authoring-v1`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-carrow-interior-scale-calibration-v1`
- Locks: `carrow-yard-route`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-carrow-interior-layout-authoring-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new interactive Carrow authored-layout adapter must preserve physics/room/asset routing and deterministic export without inventing user-owned geometry`
- Reviewed main: `0d51fdba1da51b7cd3af4960b93e2dc6b4066b66`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0`
- Visual review: `conditional`
- Goal: Provide three 1:1, tile-snapped Carrow interior layout-authoring surfaces with explicit user control over floors, art anchors and collision, emitting stable machine-verifiable drafts without replacing production rooms.
- Completion boundary: Reuse the shipped `AuthoredLevelMapper` framework and accepted scale fixture/camera for three fixed layouts (West 24×18, East 30×22, Ops 36×26). User can view art, drag/position registered existing props, paint/erase floor-region state cells, draw/erase separately owned collision rectangles and edit doors/storage anchors; save/load versioned canonical JSON drafts. No autonomously chosen composition or runtime production resize.
- Current measured state: Independent scale review passed for all 3 debug-only scenes, user approves each size for a DIFFERENT Carrow building but rejects floor repetition, arbitrary machine placement, and bad collision. Current production `gothic_compound_map.gd` still has 14×10 East, 12×10 West, 20×14 Ops. It repeats floor states by `(x*3 + y*5) % floor_states.size()`. Fixture synthetic obstacle rectangles do not reflect real machine bases. Detailed authority: `design/05_levels/CARROW_YARD_INTERIOR_SCALE_AND_LAYOUT_V2.md`.
- Evidence: `custodian/scenes/debug/carrow_machine_house_scale_{24x18,30x22,36x26}.tscn`; `custodian/tools/level_authoring/carrow_machine_house_scale_fixture.gd`; `custodian/tools/level_authoring/mapper/{authored_level_mapper.gd,mapper_collision_model.gd}`; `custodian/scenes/debug/level_collision_poi_mapper.gd`; `custodian/game/world/gothic_compound/gothic_compound_map.gd`; `custodian/tools/validation/{carrow_machine_house_scale_calibration_smoke.gd,carrow_yard_interior_smoke.gd,carrow_operations_house_interior_smoke.gd,carrow_backdrop_isolation_smoke.gd}`.
- Task-specific authority: User owns layout judgement and collider/anchor authoring. Mapper model/tooling owns interactive editing. Carrow existing map owns runtime room/portal state, not this draft surface. Asset Pipeline V2 owns production textures; mapper references only already registered art. Separate Carrow route-migration packet owns world ingress and route systems.
- Work surface: New bounded `custodian/scenes/debug/carrow_interior_layout_mapper.tscn` and adjacent adapter script(s) under `custodian/tools/level_authoring/mapper/`; deterministic preview/export/load tooling under same tree; new focused smoke registered in `custodian/tools/validation/validation_manifest.json`. Read-only imports from live Carrow/fixture resources. **No production room rewrite**, no art normalization and no mutations to other owners' worktrees.
- Change:
  1. Exact selectors `west_draft_house` 24×18 (768×576), `east_machine_house` 30×22 (960×704), `operations_house` 36×26 (1152×832); never substitute current 12×10/14×10/20×14 geometry or invent intermediate sizes. Keep actual Operator capsule, CameraController base 0.84 and 150px/s speed as the debug previews' read-only resources.
  2. Extend existing AuthoredLevelMapper via Carrow-specific adapter instead of writing a new draggable-canvas engine. Expose collision and floor and prop modes and one true 32px tile grid. Author selects one of existing registered Machine House art IDs; transform fields use exact integer tile cell anchor and unchanged native scale/z unless explicitly edited via dedicated UI. No random defaults beyond an empty room shell/door and neutral registered base tile.
  3. Floors: default exact `slab_plain_01` registered state for every cell. An explicit user paint/del action creates region/cell overrides; do not generate modulo pattern, wear maps, noise or auto-placed grates. Display a provisional normalized hardstand only after Asset V2 has actually registered it, else omit it from palette.
  4. Distinguish visual alpha/image extents and authorized collision shapes. User can draw/edit/delete solid tile rects/polyline footprints; tool displays actual collider shapes and Operator capsule, preserves door cell openings (initially current 3-cell production portal in temporary plan), and reports asset alpha overhang on walkable cells as advisory geometry facts. Never infer collision from texture alpha or automatically 'fix' poorly aligned equipment.
  5. Drag/move/delete named prop anchors and existing resource markers independently while preserving existing resource IDs/contents: West 2, East 3, Ops 1. Tool prohibits duplicate resource IDs; re-bound storage must reference exactly one named registered art anchor and must not duplicate chest presentation.
  6. Save/load deterministic JSON **draft only** under ignored `reports/carrow_layout_authoring/<room_id>.draft.json`, with schema `custodian.carrow_layout_draft.v1`, `room_id`, `grid_wh`, `tile_size:32`, original source ref hashes/IDs, sorted `floor_regions`, `art_placements`, `collision_shapes`, `portal_cells`, `storage_anchors`, and `content_sha256` over canonical JSON excluding the digest itself. No timestamps in digest; no script string replacement and no direct production artifact writes.
  7. Provide explicit `validate` and `export` controls and machine-checkable report with exact actual Operator shape clearance for door and named user-supplied waypoints; duplicate/overlap/invalid bounding-box detection; texture/resource existence; no overlapping camera regions in proposed off-map allocation; stable round-trip JSON. Report blocked facts; never assert room 'feels playable' or automatically choose layouts.
- Preserve: Production Carrow room sizes and door/return names until layout approval, existing storage values/persistence, Operator/camera/time/weather, map generation/required walkable, current asset registrations, world route migration ownership. Respect unrelated modified root files or existing agent worktrees.
- Non-goals: Choose where props go, alter production room sizes, automatically add new floors/props, generate art, paint visual proof of quality, register off-map as a second Godot scene/router, implement roof cutaway/in-world interior in this slice, or fix all future Carrow floor/door geometry without approved draft inputs.
- Acceptance:
  - A1. Three exact selectors and real 32px extents, same asset scale and actual Operator/CameraController input resources; each starts with a clean empty authored plan, not the four synthetic obstacle rects.
  - A2. User can paint floor regions, move/delete a prop anchor, create/edit/remove collision rectangle, edit portal and real storage anchor, save draft, reopen it with identical geometry and scene presentation.
  - A3. Every saved plan passes version/hash/source pin, exact size/tile checks, snap/bounds, unique IDs, safe 3-cell preliminary portal and actual Operator-shape clearance checks. Wrong/hash-stale/overlap/blocked-portals fail clearly without overwriting valid drafts.
  - A4. No production `gothic_compound_map.gd` mutation or Asset V2 ingest; fresh empty draft does not claim human approval. Existing three Carrow interiors and registered assets remain unchanged.
  - A5. Focused mapper smoke, existing Carrow calibration/interior/Ops/backdrop smokes, changed-file suite and `git diff --check` all pass. No gameplay-feel or random visual goodness assertion.
- Validation: New Carrow mapper smoke verifying all 3 configs, input operations, canonical repeatable serialization, malformed/stale/bad collision negative fixtures, output path confinement, and no production write; existing `custodian/tools/validation/carrow_machine_house_scale_calibration_smoke.gd`, `carrow_yard_interior_smoke.gd`, `carrow_operations_house_interior_smoke.gd`, `carrow_backdrop_isolation_smoke.gd`, authored level mapper framework smoke, then changed-file validation and packet/index checks.
- Task overrides: `none`
- Deferred: A separate production-layout adoption implementation after human-authored layouts are approved, and a separate same-building off-map/in-world presentation A/B test. Six perimeter art states and updated Dropbox source package remain active in the art workstream, not this tool slice.

## Next Handoff

- Next workstream: `review-carrow-interior-layout-authoring-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0`
- Refresh reason: `none`
- Next action: Fresh independent technical review of editor controls, serialized layout records and production nonmutation. After PASS give user three editor entrypoints and await authored floor/prop/collision layouts, not a second vote on sizes.
- Blockers or open questions: `Production conversion still requires human geometry signoff, but mapper tooling has enough exact values to implement now.`
