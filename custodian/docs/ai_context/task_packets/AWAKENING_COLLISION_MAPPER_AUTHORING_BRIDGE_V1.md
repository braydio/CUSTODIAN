# AWAKENING COLLISION MAPPER AUTHORING BRIDGE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-collision-mapper-authoring-bridge-v1`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `awakening-runtime, authored-level`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `review-awakening-collision-mapper-authoring-bridge-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `editor writes and collision-authority safety require independent proof`
- Reviewed main: `17fd54aa9bf78887ff162f51af19176095284d8f`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Let the user visually trace actual Awakening collision against the real composite artwork, edit collision outlines at exact world pixels and save a durable unambiguous collision-authoring draft, without Codex inventing coordinates or silently changing protected routes.
- Completion boundary: Repair only the existing Awakening mapper authoring/preview/export seam, with an exact coordinate+provenance draft format, readback and regression checks. Do not apply new collisions to production until the user has drawn/reviewed them; no gameplay collision redesign in this slice.
- Current measured state: `scenes/debug/awakening_first_return_mapper.tscn` exists and loads the actual production scene with `AuthoredLevelMapper`, 4px snap, a zone overlay and the Awakening adapter. But `LevelCollisionPoiMapper._apply_draft_segments_to_runtime_collision_map` writes a `BOUNDARY_SEGMENTS` constant to `awakening_first_return.gd`, which has no such authoring constant or `AUTHORING_MARKERS`; its guarded write cannot apply authored geometry. `_load_existing_collision_polylines` loads the four edges of `WORLD_BOUNDS` from `get_boundary_segments()`, not actual blockers. The generic existing-collision overlay scans a nonexistent root `Collision/PathBoundaryCollision`; Awakening collision is instead dynamically assembled in per-zone `Collision` nodes from `awakening_layout.gd` occupancy walls, void polygons and set-piece rectangles, plus Road/prop-owned blockers. The Awakening zone overlay's `show_collision` defaults false and shows Layout geometry, not the instantiated collision bodies. Generic snapshot exports semantic bounds but not draft polyline points. Adapter advertises COLLISION/MARKER/REGION yet the mode switch tests `MARKERS` and REGION has no real drafting operations. Zones 04–05 have hidden individual underlays and use a live registered composite, so rendered pixel alignment must come from the actual production presentation. Existing QA identifies gate pylon footprints, 04→05 visual gaps and central gate art-vs-collision mismatch.
- Evidence: `custodian/scenes/debug/{awakening_first_return_mapper.tscn,awakening_first_return_overlay.gd,level_collision_poi_mapper.gd,level_collision_poi_mapper_overlay.gd}`; `custodian/tools/level_authoring/mapper/{authored_level_mapper.gd,mapper_collision_model.gd,mapper_validation.gd,adapters/awakening_first_return_mapper_adapter.gd}`; `custodian/game/world/awakening/{awakening_first_return.gd,awakening_layout.gd}`; `custodian/scenes/awakening_first_return.tscn`; `reports/awakening_gate_collision/QA.md`; `reports/awakening_visual_walkthrough/QA.md`; `design/04_architecture/{AWAKENING_FIRST_RETURN.md,AWAKENING_DUST_LUNG_V2.md}`; `custodian/docs/ai_context/reports/awakening/AWAKENING_COLLISION_MAPPER_AUDIT_20261013.md`.
- Task-specific authority: AwakeningLayout remains canonical spatial gameplay authority, including `is_point_walkable`, floors/voids, blockers, connectors/thresholds and Road offset; existing authored mapper owns editor interaction only. Production rendered plate transforms and actual instantiated collision shapes are measured truth for preview. Do not make raw alpha masks or scene-only nodes into implicit collision authority.
- Work surface: `custodian/scenes/debug/awakening_first_return_mapper.tscn`, mapper adapter, bounded generic mapper extension only if required, Awakening-specific preview/export helper under `custodian/tools/level_authoring/mapper/`, focused Godot smokes, `custodian/tools/validation/validation_manifest.json`; only thin read-only presentation hooks in the Awakening controller if necessary. Update design docs to reflect verified mapper limitations after implementation, not to preclaim collision reauthoring.
- Change:
  1. Display **the real runtime scene art**, including registered 04→05 composition, at native world coordinates. Provide zone jump, zoom, 4px/1px snap controls, overlay toggles for: art only, Layout walkable floor/void, instantiated colliders, connector/threshold protected paths, proposed geometry, and composite registration. Do not require dragging across all 7680 world pixels to reach a zone. Disable input/gameplay processing in the preview without hiding the art; do not create another Operator or scene owner.
  2. Present every actual collision contributor with deterministic zone/owner/type/shape identifiers: 32px occupancy walls, `CollisionPolygon2D` voids, blocking `CollisionShape2D` set pieces, scene prop colliders, and Road-prototype/temporary South Reach blockers. Render corresponding world-space boundaries on top of art. Distinguish **actual instantiated collision** from design Layout regions and intentionally nonblocking art. Do not relabel world bounds rails as real blockers.
  3. Author **named, zone-scoped collision proposals** interactively: polygon/segment/rect footprint with edit/move/insert/delete/undo/redo, snapping, explicit type (floor/void/blocker/decoration or per-owner footprint), exact world-space vertices and optional source-art pixel coordinates derived from the actual transform. Existing draft geometry may be used as reference but must not be mistaken for an existing runtime blocker. Selecting existing named blockers for adjustment must preserve their owner identity; don't silently create additive duplicate colliders.
  4. Replace **only Awakening's** broken Apply/Save operation with an atomic, parse/readback-verified authoring draft plus provenance, under `reports/level_maps/awakening_first_return/collision_draft.json` (or a more appropriate ignored, task-scoped staging path). Include schema, base Layout and scene Git SHAs, zone/owner/purpose, point/rect coordinates in world pixels, source plate/resource and transform when relevant, snap, revision and stable IDs. On reopen, restore all geometry/metadata losslessly. Provide clipboard exact-vertex export and annotated PNG/JSON capture. Never overwrite `awakening_first_return.gd` with generic `BOUNDARY_SEGMENTS` or silently change runtime collision.
  5. Implement **dry-run candidate compilation** against the same spatial semantics the runtime uses: report if a proposed blocker/void intersects a mandatory connector, threshold, the 05→06 passage, spawn/locker/lift positions, the 128px route-width expectation or the Operator's 11px collision radius. Preserve source art and collision origin alignment. Fail closed if draft/layout/art transforms are stale or unverified. Existing `awakening_first_return_geometry_smoke.gd` remains the production route oracle; preview alone is not an acceptance gate.
  6. Leave locked 04→05, Gate opening, Road and Dust Lung V2 architectural decisions intact. Visual-only open/blocked conflicts must be tagged `art_mismatch` rather than guessed away with a solid collider. Future production integration takes user-approved draft vertices and updates **one** canonical Layout authority in a separately authorized follow-up (or compatible data-backed Layout contract), with actual-route tests before landing. Do not duplicate coordinate sources.
- Preserve: Production geometry, Z01–Z10 route/zone indices, actual render/lighting/occlusion transforms, interaction/spawn/progression, the Road prototype, existing generic/Sundered Keep mapper behavior, artist file bytes, temporary/ignored artwork, project main startup, all unrelated worktrees and locks. No unreviewed change to collision activation.
- Non-goals: Hand-specifying every art collider, auto-tracing alpha into gameplay geometry, automatically promoting drafts, rebuilding the mapper in another UI, moving the Dust Lung lift per unimplemented V2 spec, touching procgen, changing art registration, or implementing new Awakening content.
- Acceptance:
  - A1. Launching Awakening mapper shows real art and actual colliders for the same scene; a sampled gate pylon collider matches center `(-256,-4768)`, size `(240,496)`, companion east `(256,-4768)`, and the protected 272px central gap.
  - A2. Existing generated wall/void/set-piece/prop/Road colliders are classified honestly, with world-space boundaries matching real nodes; existing world bounds rails are not presented as blocker geometry.
  - A3. User-authored Z01 and Z07 fixtures save/reopen with unchanged world-pixel vertices, stable IDs and source-art transforms, and no runtime scene/script/layout modification; existing mapper controls do not accidentally write on Enter/U.
  - A4. Snap, zone focus, draft editing/undo/redo, protected-route overlay and collision source selection function without losing drawing data. Marker/region mode either works or is explicitly disabled with truthful UI, not an inert advertised mode.
  - A5. Negative probes fail on connector-spanning blocker, 05→06 passage closure, 128px route narrowing, spawn/locker/lift overlap, missing owner, stale scene SHA and malformed draft. Root layout/geometry smokes remain unchanged and green.
  - A6. Imported preview runs without competing live gameplay input, authoring draft cannot silently become runtime authority, and Sundered Keep mapper smoke does not regress.
- Validation: Existing focused `custodian/tools/validation/{awakening_first_return_smoke.gd,awakening_first_return_geometry_smoke.gd,authored_level_mapper_framework_smoke.gd,level_collision_poi_mapper_smoke.gd,sundered_keep_mapper_smoke.gd}`; new bounded Awakening mapper exact-geometry fixture and draft round-trip/collision-negative fixtures (create under `custodian/tools/validation/`, then register exact paths). For art, inspect smallest registered 04→05 and gate pylon crops overlaid with true collider bounds; don't generate extra full-scene render sweeps. Then changed-file route validation, AI-context, pairing/index and `git diff --check`.
- Task overrides: `none`
- Deferred: User-authored production collision promotion and any V2 Dust Lung spatial cutover require a separate post-drawing authorizing action.

## Next Handoff

- Next workstream: `review-awakening-collision-mapper-authoring-bridge-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Independent fresh-context review of real-collider overlay, pixel-coordinate draft round trip and guard tests before inviting user to draw collision.
- Blockers or open questions: `Actual LFS artwork pixels must be checked in a rendered Godot environment; manual authored geometry and V2 cutover remain later steps.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: `The required standalone Sundered Keep mapper smoke failed five assertions after the shared mapper overlay was restored unchanged; changed-file validation passed 40/40.`
- Root cause / contributing factors: `The current Sundered level JSON already contains saved mapper placements while the smoke requires zero; the same smoke also expects outdated placement previews, 127 collision segments, and matching spawn coordinates. This mismatch is outside the Awakening work surface.`
- Prevention / pipeline improvement: `Reconcile the Sundered smoke against its current production data in its own scoped task, then rerun it before declaring this preserve gate green.`
- Tooling / docs drift discovered: `The task's shared Sundered regression is not green at the claimed main baseline; the failure is not selected by changed-file validation because no Sundered owner files changed.`
- Follow-up: `manual-follow-up`
- What worked: `Awakening-specific overlay and draft bridge remained isolated; all 40 changed-file checks passed.`
