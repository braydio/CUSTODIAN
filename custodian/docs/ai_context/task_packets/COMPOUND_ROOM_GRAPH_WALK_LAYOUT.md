# COMPOUND ROOM GRAPH WALK LAYOUT

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-14
- Created: 2026-05-14
- Last updated: 2026-05-14

## Task

Implement the next `custodian/game/world/compound/rooms/CODEX_INSTRUCT.md` slice after the room graph/loader/assembler contract hardening: move `LayoutAssembler` beyond plain fixed-grid adjacency toward graph-walk, door-aligned room placement.

## Outcome

`LayoutAssembler.generate_layout(seed)` now tries a graph-walk placement pass first:

- Required/start-like room assignment is placed at origin.
- Remaining room assignments are walked outward from already placed rooms.
- Candidate placements must satisfy `RoomGraph.allows_connection()`.
- Candidate placements must have compatible opposing doors through `RoomLoader.can_connect()`.
- Candidate room world origins are aligned from door tile to door tile instead of using only fixed cell spacing.
- Rooms that cannot be graph-placed are still appended through fixed-grid fallback so missing templates or incomplete door metadata do not hard-fail generation.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `custodian/game/world/compound/rooms/CODEX_INSTRUCT.md`
- Active runtime/docs files: `custodian/game/world/compound/rooms/layout_assembler.gd`, `custodian/docs/ai_context/*`
- Historical reference only: `python-sim/`

## Work Surface

- Files changed:
  - `custodian/game/world/compound/rooms/layout_assembler.gd`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/task_packets/README.md`
- Files read but not changed:
  - `custodian/game/world/compound/rooms/CODEX_INSTRUCT.md`
  - `custodian/game/world/compound/rooms/room_graph.gd`
  - `custodian/game/world/compound/rooms/room_loader.gd`
  - `custodian/game/world/compound/rooms/templates/command_post.tmj`
- Out-of-scope areas:
  - Authoring missing `.tmj` templates.
  - Carving corridor tiles between imperfect door alignments.
  - Replacing the fallback grid path entirely.

## Constraints

- Determinism concerns: graph walk uses existing deterministic assignments, sorted room types, and seeded random door-pair selection.
- Simulation/UI boundary concerns: layout assembly remains data-only.
- Asset requirements: graph-walk coverage is limited until the missing compound `.tmj` templates exist.
- Compatibility or migration concerns: fixed-grid fallback remains available to avoid breaking current incomplete room content.
- Clarifying questions or assumptions: no question required; section 4 explicitly calls for graph walking after contract hardening.

## Implementation Plan

1. Extract room-instance construction from the old grid loop.
2. Add graph-walk placement rooted at a required/start assignment.
3. Place child rooms only when graph rules and opposing door compatibility pass.
4. Align child room origins using resolved parent door tile plus direction vector minus child door local tile.
5. Keep fallback grid placement for unresolved assignments.
6. Validate with Godot script checks.

## Acceptance

- Runtime behavior: room assembly attempts graph-walk, door-aligned placement before fallback grid placement.
- Documentation: current state, file index, and task packet index updated.
- Path/reference validation: touched docs reference existing files.
- Manual validation: not run in editor.
- Automated/headless validation: `layout_assembler.gd` script check and whitespace check.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes, updated.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes, updated.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No; `CODEX_INSTRUCT.md` remains the active task instruction.

## Completion Notes

- Implemented: graph-walk first-pass placement, door-aligned child origins, overlap avoidance, and fixed-grid fallback for unresolved rooms.
- Validated: `godot --headless --path custodian --check-only --script res://game/world/compound/rooms/layout_assembler.gd`; `git diff --check`.
- Deferred: end-to-end generation smoke test with multiple real templates, because only `command_post.tmj` exists today.

## Next Steps

- Next action: author the missing `.tmj` compound room templates so graph-walk placement can be tested with real hangar, corridor, storage, and landing-pad content.
- Best starting files: `custodian/game/world/compound/rooms/templates/`, `custodian/game/world/compound/rooms/graphs/default_compound.json`, `custodian/game/world/compound/rooms/README.md`.
- Required context: `custodian/game/world/compound/rooms/CODEX_INSTRUCT.md` section 4 and `REQUIRED_ASSETS.md` compound room template entries.
- Validation to run: a deterministic layout smoke script that loads all templates and compares two same-seed layouts after the missing templates exist.
- Blockers or open questions: graph-walk behavior is structurally implemented, but meaningful multi-room proof depends on missing `.tmj` room assets.
