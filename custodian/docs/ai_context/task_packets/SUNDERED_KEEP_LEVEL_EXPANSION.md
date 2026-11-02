# Sundered Keep Level Expansion Task Packet

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-30
- Created: 2026-05-30
- Last updated: 2026-05-30

## Task

Implement the next Sundered Keep pass: Return Mooring, expanded cliff-island castle layout, item-gated Main Gate, docs, and validation.

## Outcome

Sundered Keep no longer reads as a rectangular test arena. The player enters from the storm causeway, can reach a Return Mooring before the locked Main Gate, can acquire `sundered_gate_key`, can open the portcullis, can open the Great Hall door, and can continue to the courtyard, Great Hall, rampart, service path, and traversal stubs.

## Authority

- Root routing: `/home/braydenchaffee/Projects/CUSTODIAN/AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/SUNDERED_KEEP_PHASE_1.md`, `design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVELSET.md`, `design/20_levels/in_progress/SUNDERED_KEEP_LEVEL_EXPANSION.md`
- Active runtime/docs files: `custodian/game/world/sundered_keep/`, `custodian/content/runtime/sundered_keep/`, `custodian/content/tiles/sundered_keep/`, `custodian/docs/ai_context/`
- Historical reference only: legacy Python runtime

## Work Surface

- Changed runtime: `custodian/game/world/sundered_keep/sundered_keep_map.gd`, `custodian/game/world/sundered_keep/sundered_keep_interactable.gd`
- Changed validation: `custodian/tools/validation/sundered_keep_layout_smoke.gd`
- Changed docs: active AI context files and Sundered Keep level expansion note
- Read but not changed: Sundered Keep game32 manifests, Return Mooring manifests, inventory manager
- Out of scope: legacy Python runtime, generated placeholder assets

## Constraints

- Determinism concerns: layout placement is static and deterministic.
- Simulation/UI boundary concerns: gate/key state stays in map logic; sprite placement remains visual-only except blockers and interactables.
- Asset requirements: only existing game32/runtime Return Mooring and Sundered Keep assets were used.
- Compatibility or migration concerns: local key fallback remains isolated for later full inventory/save migration.
- Clarifying questions or assumptions: no new assets were generated because Return Mooring assets already existed.

## Implementation Plan

1. Verify existing Return Mooring assets/manifests and Sundered Keep catalog paths.
2. Rebuild the authored map into the expanded cliff-island route.
3. Add Return Mooring, local interactable bridge, key pickup, gate state, collision blockers, and debug summary.
4. Add layout smoke validation.
5. Update AI context and design docs.

## Acceptance

- Runtime behavior: Return Mooring exists, gate starts closed, key pickup grants `sundered_gate_key`, key opens gate, blocker is removed after opening.
- Documentation: `CURRENT_STATE.md`, `CONTEXT.md`, `FILE_INDEX.md`, and design note updated.
- Path/reference validation: Sundered Keep and Return Mooring manifests report zero missing refs.
- Manual validation: not run in an interactive Godot session.
- Automated/headless validation: asset smoke and layout smoke pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Done.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Done.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Done.
- Does `custodian/AGENTS.md` need an update? No routing change.
- Do any design docs need an update? `design/20_levels/in_progress/SUNDERED_KEEP_LEVEL_EXPANSION.md` added.

## Completion Notes

- Implemented: Return Mooring module, expanded layout, item-gated Main Gate, Great Hall door interaction, local interactable bridge, prop blockers, sparse ocean composition, vertical parapet slices, and layout smoke.
- Validated: return mooring asset paths, manifest refs, texture smoke, layout/gate/door smoke.
- Deferred: save/load persistence, enemy composition, TileSet migration, final art polish.

## Next Steps

- Next action: interactive playtest for route readability and collision feel.
- Best starting files: `custodian/game/world/sundered_keep/sundered_keep_map.gd`
- Required context: Sundered Keep manifests and `InventoryManager`
- Validation to run: `godot --headless --script res://tools/validation/sundered_keep_layout_smoke.gd`
- Blockers or open questions: none for this pass.
