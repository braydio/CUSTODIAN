# SUNDERED KEEP PHASE 1

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-30
- Created: 2026-05-30
- Last updated: 2026-05-30

## Task

Implement the first playable Sundered Keep slice from `design/SUNDERED_KEEP_PHASE_1.md`: Main Gate, Courtyard, Great Hall, rampart/cliff boundary, and upper/lower traversal stubs.

## Outcome

The Godot runtime has a reachable connected Sundered Keep map with generated phase-1 runtime assets, blocking props/walls/cliffs, visual traversal markers, a return gate, an asset manifest, and updated active documentation.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/SUNDERED_KEEP_PHASE_1.md`, `design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVEL_SET.md`
- Active runtime/docs files: `custodian/game/world/gothic_compound/gothic_compound_map.gd`, `custodian/game/world/gothic_compound/gothic_compound_travel_gate.gd`, `custodian/game/systems/core/systems/contract_world_loader.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: legacy Python runtime under `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/content/tiles/sundered_keep/`, `custodian/content/props/sundered_keep/`, `custodian/content/levels/sundered_keep/`, `custodian/game/world/sundered_keep/`, `custodian/game/systems/core/systems/contract_world_loader.gd`, active AI context docs.
- Files or folders expected to be read but not changed: existing gothic compound map/gate and procgen handoff code.
- Out-of-scope areas: full multi-floor keep, chapel/library/observatory/dungeon destination maps, bespoke production art pass beyond generated readable runtime tiles.

## Constraints

- Determinism concerns: authored map generation must be deterministic from fixed placements and must not add random runtime layout variance.
- Simulation/UI boundary concerns: map collision and traversal belong to world nodes; HUD/terminal logic should not own slice behavior.
- Asset requirements: phase 1 can ship with generated first-pass runtime PNGs; production art polish may still be desirable after playtest.
- Compatibility or migration concerns: preserve the existing gothic compound connection while adding the Sundered Keep entry as a separate connected map.
- Clarifying questions or assumptions: proceeding under the user's instruction to implement to the full extent possible without waiting for asset confirmation.

## Implementation Plan

1. Generate the phase-1 folder structure, first-batch PNG assets, and `sundered_keep_assets.json`.
2. Add an authored `SunderedKeepMap` connected map that builds the first slice with layer groups, sprites, blocking collision, traversal stubs, camera bounds, and return travel.
3. Wire the contract-world loader to place an entry gate to the Sundered Keep near the generated map's compound ingress.
4. Update design/context docs and validate with Godot import/headless checks.

## Acceptance

- Runtime behavior: a contract world exposes an interactable `ENTER SUNDERED KEEP` gate, moving the operator into the authored keep slice and allowing return to the main map.
- Documentation: active context and broad design status reflect the new phase-1 runtime slice.
- Path/reference validation: new `res://` script and asset paths load.
- Manual validation: playtest entry/readability remains recommended after headless validation.
- Automated/headless validation: run Godot import and headless boot where feasible.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No unless workflow rules change.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, level-set status and phase-1 implementation notes.

## Completion Notes

- Implemented: Generated the Sundered Keep phase-1 runtime asset pack and manifest, added `SunderedKeepMap`, wired `ContractWorldLoader` to place an `ENTER SUNDERED KEEP` gate, and updated active design/context docs.
- Validated: `cd custodian && godot --headless --import --quit`; `cd custodian && godot --headless --quit`. The runtime boot instantiated the Sundered Keep without missing Sundered Keep resources after a path fix.
- Deferred: Production art polish, dedicated TileSet/TileMapLayer authoring, enemy encounter composition inside the connected map, save/load persistence for visited connected maps, minimap specialization, and full multi-floor expansion remain beyond phase 1.

## Next Steps

- Next action: Manual Godot playtest of gate placement, collision readability, and traversal-stub readability.
- Best starting files: `custodian/game/world/sundered_keep/sundered_keep_map.gd`, `custodian/game/systems/core/systems/contract_world_loader.gd`
- Required context: `design/SUNDERED_KEEP_PHASE_1.md`
- Validation to run: `cd custodian && godot` for visual/manual traversal; rerun `cd custodian && godot --headless --quit` after follow-up edits.
- Blockers or open questions: None for phase-1 runtime insertion; final art quality remains a polish decision.
