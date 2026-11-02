# PROCGEN WALL COLLISION SYNC TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-07
- Created: 2026-05-07
- Last updated: 2026-05-07

## Task

Fix procgen wall collision drift where visible wall tiles can exist without matching runtime wall bodies, especially after streaming reveal resets.

## Outcome

Visible wall TileMap cells and `RuntimeWallCollision` bodies stay synchronized after generation, streaming prep, chunk reveal, chunk unload, and wall damage.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/procgen/DESTRUCTIBLE_PROCGEN_WALLS.md`, `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/world/procgen/runtime_wall_segment.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: procgen tilemap runtime collision code, AI context docs
- Files or folders expected to be read but not changed: procgen scene and TileSet resources
- Out-of-scope areas: TileSet atlas authoring, compound tile system redesign

## Constraints

- Determinism concerns: collision sync must derive only from current visible/generated wall tile state.
- Simulation/UI boundary concerns: minimap and rendering remain consumers; wall collision stays runtime gameplay authority.
- Asset requirements: none.
- Compatibility or migration concerns: keep destructible wall segment behavior and public procgen API intact.
- Clarifying questions or assumptions: use runtime wall bodies as the canonical collision path for procgen walls; do not add TileSet physics shapes in this slice.

## Implementation Plan

1. Fix streaming collision reset so old collision nodes are detached before queue-free.
2. Add a sync pass that creates missing bodies for visible wall cells and removes stale bodies without matching wall cells.
3. Run headless validation and update docs.

## Acceptance

- Runtime behavior: visible procgen wall cells have matching `RuntimeWallCollision/Wall_x_y` bodies.
- Runtime behavior: stale runtime wall bodies are removed when cells are cleared/unloaded/destroyed.
- Documentation: current state records the wall collision sync behavior.
- Path/reference validation: packet is listed in task packet README.
- Automated/headless validation: `cd custodian && godot --headless --quit`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: Streaming reveal now detaches stale runtime wall bodies before queue-free, visible wall cells are synced against `RuntimeWallCollision/Wall_x_y` bodies after initial reveal, incremental reveal, and chunk unload, and bulk rebuilds avoid repeated debug rebuild churn.
- Validated: `cd custodian && godot --headless --quit` completed without parse/load errors. Existing shutdown resource leak warnings still appear.
- Deferred: Longer-term TileSet physics cleanup remains out of scope; procgen walls continue to use runtime bodies as gameplay collision authority.

## Next Steps

- Next action: Manually test a generated map with `show_runtime_wall_collision_debug = true` if wall collision still feels inconsistent in play.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Required context: runtime wall collision and streaming reveal paths.
- Validation to run: `cd custodian && godot --headless --quit`
- Blockers or open questions: none.
