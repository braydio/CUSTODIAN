# SUNDERED KEEP PHASE 1

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-30
- Created: 2026-05-30
- Last updated: 2026-05-30

## Task

Implement the first playable Sundered Keep slice from `design/SUNDERED_KEEP_PHASE_1.md`: Main Gate, Courtyard, Great Hall, rampart/cliff boundary, and upper/lower traversal stubs. Follow-up asset correction: wire the slice to the existing game32 metadata/catalog assets and do not generate or render placeholder art.

## Outcome

The Godot runtime has a reachable connected Sundered Keep map with game32-backed Sundered Keep runtime assets, blocking props/walls/cliffs, live traversal assets, a return gate, asset smoke validation, and updated active documentation.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/SUNDERED_KEEP_PHASE_1.md`, `design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVEL_SET.md`
- Active runtime/docs files: `custodian/game/world/gothic_compound/gothic_compound_map.gd`, `custodian/game/world/gothic_compound/gothic_compound_travel_gate.gd`, `custodian/game/systems/core/systems/contract_world_loader.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: legacy Python runtime under `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/world/sundered_keep/`, `custodian/tools/validation/`, active Sundered Keep design docs, and active AI context docs.
- Files or folders expected to be read but not changed: existing gothic compound map/gate and procgen handoff code.
- Out-of-scope areas: full multi-floor keep, chapel/library/observatory/dungeon destination maps, new/generated placeholder art, and unrelated asset pipeline churn already present in the worktree.

## Constraints

- Determinism concerns: authored map generation must be deterministic from fixed placements and must not add random runtime layout variance.
- Simulation/UI boundary concerns: map collision and traversal belong to world nodes; HUD/terminal logic should not own slice behavior.
- Asset requirements: use existing Sundered Keep game32 metadata/catalog assets only; do not generate placeholder art or render synthetic placeholder markers for missing assets.
- Compatibility or migration concerns: preserve the existing gothic compound connection while adding the Sundered Keep entry as a separate connected map.
- Clarifying questions or assumptions: proceeding under the user's instruction to implement to the full extent possible without waiting for asset confirmation.

## Implementation Plan

1. Review `custodian/content/sundered_keep_manifest.game32.json` and the generated domain manifests/catalog for live candidate assets.
2. Update `SunderedKeepMap` to resolve terrain/traversal/props through `sundered_keep_game32_assets.gd`, resolve floors/walls from the metadata-backed Sundered Keep folders, and skip missing textures instead of drawing placeholder sprites.
3. Wire the contract-world loader to place an entry gate to the Sundered Keep near the generated map's compound ingress.
4. Update design/context docs and validate with Godot import/headless checks.

## Acceptance

- Runtime behavior: a contract world exposes an interactable `ENTER SUNDERED KEEP` gate, moving the operator into the authored keep slice and allowing return to the main map.
- Documentation: active context and broad design status reflect the new phase-1 runtime slice.
- Path/reference validation: Sundered Keep map instantiation creates only Sprite2D nodes with live textures.
- Manual validation: playtest entry/readability remains recommended after headless validation.
- Automated/headless validation: run Godot import, headless boot, and `tools/validation/sundered_keep_asset_smoke.gd` where feasible.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No unless workflow rules change.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, level-set status and phase-1 implementation notes.

## Completion Notes

- Implemented: `SunderedKeepMap` now uses the game32 catalog for runtime terrain/traversal/prop paths, routes wall/floor selections to existing metadata-backed assets, uses Great Hall wall candidates in the Great Hall, removes non-asset overlay polygons and traversal marker polygons, skips missing textures instead of drawing red fallback sprites, and adds direct asset smoke validation.
- Validated: `cd custodian && godot --headless --import --quit`; `cd custodian && godot --headless --quit`; `cd custodian && godot --headless --script tools/validation/sundered_keep_asset_smoke.gd`. The asset smoke check reported `2910` Sprite2D nodes with live textures.
- Deferred: Manual visual pass, dedicated TileSet/TileMapLayer authoring, enemy encounter composition inside the connected map, save/load persistence for visited connected maps, minimap specialization, and full multi-floor expansion remain beyond phase 1.

## Next Steps

- Next action: Manual Godot playtest of gate placement, collision readability, and traversal-stub readability.
- Best starting files: `custodian/game/world/sundered_keep/sundered_keep_map.gd`, `custodian/game/systems/core/systems/contract_world_loader.gd`
- Required context: `design/SUNDERED_KEEP_PHASE_1.md`
- Validation to run: `cd custodian && godot` for visual/manual traversal; rerun `cd custodian && godot --headless --quit` after follow-up edits.
- Blockers or open questions: None for phase-1 runtime insertion; final art quality remains a polish decision.
