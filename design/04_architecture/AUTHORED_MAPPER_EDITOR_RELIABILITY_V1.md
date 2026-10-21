# Authored Mapper Editor Reliability V1

- Status: **design / static audit only**; implementation NOT landed.
- Reviewed repo: `braydio/CUSTODIAN main@0bcd4c2455ff1ba7993b6891b98e0101ea23aab8` (2026-10-21).
- Workstream: `mapper-editor-usability-overhaul-v1`
- Authoring chat: `not-recorded` (fill in exact current chat URL when supplied).
- Scope: Mapper editor usability, input/data integrity and draft-versus-source safety. No runtime map or asset authoring in this phase.

## Current mapper inventory

| Mapper surface | Live owner | Contract |
| --- | --- | --- |
| Generic collision/POI | `custodian/scenes/debug/level_collision_poi_mapper.gd` | Polyline/marker editor, semantic overlays and direct source apply |
| Shared authored mapper | `custodian/tools/level_authoring/mapper/authored_level_mapper.gd` | Adapter, mode, history, collision operations |
| Awakening First Return | `custodian/tools/level_authoring/mapper/awakening_first_return_collision_mapper.gd` | Actual collision/provenance, protected routes, ignored collision draft only |
| Carrow Interiors | `custodian/tools/level_authoring/mapper/carrow_interior_layout_mapper.gd` | West 24x18, East 30x22, Operations 36x26, registered art and ignored room drafts |
| Home / Beginning | `custodian/scenes/debug/home_custodian_begin_mapper.tscn` | Shared authored mapper and source-writing base |
| Forlorn Ritualant Underground | `custodian/scenes/debug/forlorn_ritualant_underground_mapper.tscn` | Shared authored mapper and special overlay |
| Sundered Keep Approach | `custodian/scenes/debug/sundered_keep_approach_mapper.gd` | Base collision/POI plus feature zone rectangles |
| Sundered Keep standalone | `custodian/scenes/debug/sundered_keep_mapper.gd` | Independent tile, underlay stamps, rails, markers, feature authoring |

## Grounded high-return audit findings

- **P0 action safety:** generic Enter/U invokes source-script/scene write functions, while Awakening Enter/U only finishes a draft line and Carrow Save writes ignored JSON. A mode-independent meaning for a keystroke is currently absent.
- **P0 edit history:** Carrow's six modes have no undo/redo and drag paths use different digest/cache update routines from ordinary commit paths. `_on_room_selected` *does* cache the departing live draft, so room-switch data loss is not proven; test it rather than assuming it.
- **P0 camera/navigation:** Carrow disables inherited camera, uses real fixture `_game_camera` at 0.84, and overrides inherited process/input handling; inherited pan/wheel flow therefore does not control active Carrow view. Awakening long level starts at 0.18 without a cohesive fit/focus authoring UI.
- **P1 Awakening selection:** source-collider cycle comma/period + B import, Alt-drag, I insert, Delete; per-proposal inspector and visible selection distinction are missing.
- **P1 Carrow discoverability:** six modes in a compact 310x590 panel, text-only registered art picker, no-op picker callbacks, validation as plain status text. Existing features are real, but hard to discover.
- **P1 Keep shortcut collision:** Approach catches Z even with Ctrl, so Ctrl+Z toggles zone mode; standalone Keep is architecturally separate and must not be blindly rewritten to inherit generic mapper.
- **P1 state/validation feedback:** shared authored mapper DIRTY flag only checks active polyline; Carrow status errors and Awakening comma-joined findings are not object-targeted.

These are observations from static live repository inspection, not results of a hands-on GUI test or local Godot run.

## Execution order and review gates

| Slice | Implementation ID | Priority | Dependency |
| --- | --- | --- | --- |
| M1 | `mapper-source-write-safety-v1` | P0 | `review-awakening-collision-mapper-authoring-bridge-v1`, `review-carrow-interior-layout-authoring-v1` |
| M2 | `carrow-mapper-transactional-editing-v1` | P0 | `review-carrow-interior-layout-authoring-v1` |
| M3 | `mapper-canvas-navigation-v1` | P0 | `review-mapper-source-write-safety-v1`, `review-carrow-mapper-transactional-editing-v1` |
| M4 | `awakening-mapper-proposal-workflow-v1` | P1 | `review-mapper-canvas-navigation-v1` |
| M5 | `carrow-mapper-authoring-workspace-v1` | P1 | `review-mapper-canvas-navigation-v1` |
| M6 | `sundered-keep-mapper-input-reliability-v1` | P1 | `review-mapper-canvas-navigation-v1` |
| M7 | `mapper-validation-feedback-v1` | P1 | `review-awakening-mapper-proposal-workflow-v1`, `review-carrow-mapper-authoring-workspace-v1`, `review-sundered-keep-mapper-input-reliability-v1` |

Every slice has a fresh-context paired post-land review. Parallel work is limited by declared locks; M1 and M2 are independent but both must be reviewed before shared M3 navigation. M4/M5/M6 branch after M3 review; M7 converges.

## Safety and acceptance philosophy

1. One pointer action = one undoable edit transaction. No per-frame edits in history.
2. The active view camera must be the only input coordinate/camera authority; UI controls win pointer/keyboard focus.
3. Drafts, exports, and source apply have visibly separate capabilities. Never turn draft-only work into production writes by convenience.
4. Preserve Awakening route/clearance/provenance gates, Carrow 32px/room/storage/registered-asset contracts, and Keep production JSON/palette mappings.
5. When validation finding has grounded object/position, focus it; never fake localization for global errors.
6. No art assets required, no new Asset V2 families or `custodian/asset_drop/inbox/` inputs. Only existing source files and focused tests are required inputs.
7. Deterministic geometry/state/event tests before optional cropped UI evidence. Final subjective UI polish needs user judgment, never agent self-approval.

## Documentation-drift note

`design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md` still documents the generic source-apply mapper but does not distinguish newer Awakening collision draft and Carrow layout draft as separate authoring contracts. Do not overwrite generic truth prematurely; after M1 and M7 reconcile the pipeline's authoring section, `custodian/docs/ai_context/CURRENT_STATE.md`, `FILE_INDEX.md`, and validation recipes **only to what live implementation verifies**. Archived task packets and root closing summaries remain historical receipts.

## Publication contract

M1-M7 implementation/review pairs are published together with this specification as draft/manual with `Authoring handoff: auto`. The repository's targeted CI authoring handoff, not this audit, must validate/promote/index them and confirm claimability. Existing dependency reviews must pass before affected work can claim. No user layout/art approval is implied by authoring the packets.
