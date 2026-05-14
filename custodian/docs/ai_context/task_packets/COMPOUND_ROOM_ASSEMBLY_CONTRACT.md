# COMPOUND ROOM ASSEMBLY CONTRACT

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-13
- Created: 2026-05-13
- Last updated: 2026-05-13

## Task

Implement `custodian/game/world/compound/rooms/CODEX_INSTRUCT.md` for the compound room assembly stack.

## Outcome

The compound room assembler should have a tighter deterministic contract between graph rules, Tiled room-template loading, and layout output:

- `RoomGraph` validates input JSON, exposes deterministic seeding, returns stable room-type order, clamps room counts, warns on missing templates, and can answer directional connection-rule checks.
- `RoomLoader` loads `.tmj` templates in deterministic order, validates JSON roots, normalizes door metadata, returns template duplicates, and checks compatible door pairs using size, kind, elevation, and key metadata.
- `LayoutAssembler` seeds all cooperating systems, guards null dependencies, uses fixed layout-cell spacing, creates stable room IDs, estimates room intensity, keeps entry-like rooms early, enforces graph connection rules, selects any compatible door pair, returns resolved door endpoint tiles, records actual tile bounds, and populates `_placed_rooms`.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `custodian/game/world/compound/rooms/CODEX_INSTRUCT.md`
- Active runtime/docs files: `custodian/game/world/compound/rooms/*.gd`, `custodian/docs/ai_context/*`, `REQUIRED_ASSETS.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files changed:
  - `custodian/game/world/compound/rooms/room_graph.gd`
  - `custodian/game/world/compound/rooms/room_loader.gd`
  - `custodian/game/world/compound/rooms/layout_assembler.gd`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - `REQUIRED_ASSETS.md`
- Files read but not changed:
  - `custodian/game/world/compound/rooms/CODEX_INSTRUCT.md`
  - `custodian/game/world/compound/rooms/README.md`
  - `custodian/game/world/compound/rooms/graphs/default_compound.json`
- Out-of-scope areas:
  - Full EDGAR-style door-aligned graph walking.
  - Authoring missing `.tmj` templates.
  - Integrating compound room layouts into the live procgen map beyond the current room stack contract.

## Constraints

- Determinism concerns: graph, loader, and assembler RNGs must share the layout seed; room type ordering and template directory traversal must be stable.
- Simulation/UI boundary concerns: room assembly remains data-only; no UI behavior changes.
- Asset requirements: default graph still references missing `.tmj` templates for hangars, corridors, storage, and landing pad.
- Compatibility or migration concerns: existing room template fields are preserved; returned template data is now duplicated to prevent caller mutation of loader state.
- Clarifying questions or assumptions: none required. The instruction file explicitly scoped this as contract hardening before deeper graph placement.

## Implementation Plan

1. Harden `RoomGraph` loading, validation, deterministic ordering, and directional connection-rule API.
2. Harden `RoomLoader` deterministic directory loading, door parsing/normalization, template getter safety, and door compatibility.
3. Upgrade `LayoutAssembler` seed propagation, fixed layout cells, stable IDs/intensity, graph-rule checks, compatible door-pair selection, endpoint tiles, bounds, and placed-room state.
4. Update AI context docs and required-asset tracking for missing compound room templates.
5. Run Godot script checks and diff whitespace validation.

## Acceptance

- Runtime behavior: compound room assembly emits deterministic, stable room metadata and only creates connections allowed by graph rules and compatible doors.
- Documentation: current state, file index, task packet index, and required assets updated.
- Path/reference validation: touched docs reference existing runtime paths.
- Manual validation: not run in editor; changes are data-assembly code only.
- Automated/headless validation: Godot script checks for `room_graph.gd`, `room_loader.gd`, and `layout_assembler.gd`; `git diff --check`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes, updated.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No, no routing or doctrine changed.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes, updated.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No, the instruction file is the active task spec.

## Completion Notes

- Implemented: all concrete changes requested in `CODEX_INSTRUCT.md` sections 1-3.
- Validated: headless script checks and whitespace check passed.
- Deferred: full graph-walk / door-aligned EDGAR-style assembly is intentionally deferred until the contract layer is reliable.

## Next Steps

- Next action: implement the next upgrade described in `custodian/game/world/compound/rooms/CODEX_INSTRUCT.md` section 4: required rooms first, start/entry at origin, graph connections walked outward, compatible templates chosen per required direction, rooms placed by door alignment, and fixed-grid placement only as fallback.
- Best starting files: `custodian/game/world/compound/rooms/layout_assembler.gd`, `custodian/game/world/compound/rooms/room_graph.gd`, `custodian/game/world/compound/rooms/room_loader.gd`, `custodian/game/world/compound/rooms/graphs/default_compound.json`.
- Required context: `custodian/game/world/compound/rooms/CODEX_INSTRUCT.md` sections 3-4 and `custodian/game/world/compound/rooms/README.md` template/door conventions.
- Validation to run: Godot script checks for all three room scripts plus a small deterministic generation smoke script once enough `.tmj` templates exist.
- Blockers or open questions: default graph references `hangar_large`, `hangar_small`, `corridor_h`, `corridor_v`, `storage`, and `landing_pad`, but only `command_post.tmj` exists today; these are now tracked in `REQUIRED_ASSETS.md`.
