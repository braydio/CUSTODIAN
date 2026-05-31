# Sundered Keep Large Front Gate

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-30
- Created: 2026-05-30
- Last updated: 2026-05-30

## Task

Implement `design/SUNDERED_KEEP_WORK.md` by converting the current Sundered Keep front-gate slice into a larger data-driven layout while preserving the existing Return Mooring, key-gated Main Gate, Great Hall door, connected-map return, and debug state behavior.

## Outcome

Sundered Keep now builds from `custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json` at `112x80` tiles. The route starts on a broken southern causeway tip, reaches Return Mooring/key alcoves before the gate, blocks courtyard access until `sundered_gate_key` opens the portcullis, and keeps the Great Hall door interaction.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/SUNDERED_KEEP_WORK.md`, `design/20_levels/in_progress/SUNDERED_KEEP_LARGE_FRONT_GATE.md`
- Active runtime/docs files: `custodian/game/world/sundered_keep/`, `custodian/content/levels/sundered_keep/`, `custodian/docs/ai_context/`
- Historical reference only: `python-sim/`

## Work Surface

- Files changed: Sundered Keep map runtime, new JSON level data, new JSON loader, layout smoke scripts, active docs, design note.
- Files read: Sundered Keep asset catalog, entrance/gatehouse/return mooring assets, existing layout smoke, active AI context docs.
- Out-of-scope areas: legacy Python runtime, new art generation, save/load persistence.

## Constraints

- Determinism concerns: tile selection uses coordinate-derived deterministic weighted selection.
- Simulation/UI boundary concerns: interaction state remains in `sundered_keep_map.gd`; JSON controls layout and marker data.
- Asset requirements: no placeholder assets were generated; missing asset count is validated as zero.
- Compatibility or migration concerns: old hard-coded builders remain fallback if JSON loading fails.
- Clarifying questions or assumptions: the east rampart is deliberately post-gate/courtyard-side so it does not bypass the locked Main Gate.

## Implementation Plan

1. Add a Sundered Keep JSON tilemap loader and a large front-gate JSON layout source.
2. Refactor `sundered_keep_map.gd` to build the active layout from JSON while preserving gate/key/mooring/door logic.
3. Update layout validation to cover large-map markers, reachability, blockers, and missing assets.
4. Update active docs and design note.

## Acceptance

- Runtime behavior: large JSON layout builds, Return Mooring/key are reachable pre-gate, courtyard is blocked until the gate opens, Great Hall door opens.
- Documentation: active AI context and design note updated.
- Path/reference validation: Sundered Keep manifest missing-ref scan reports zero missing file refs.
- Manual validation: not performed in editor during this pass.
- Automated/headless validation: asset smoke, layout smoke, and large-layout smoke pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Updated.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Updated.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Updated.
- Does `custodian/AGENTS.md` need an update? No routing change.
- Do any design docs need an update? Added `design/20_levels/in_progress/SUNDERED_KEEP_LARGE_FRONT_GATE.md`.

## Completion Notes

- Implemented: JSON level source, loader, map data-build path, stateful gate/door integration, large reachability smoke.
- Validated: `sundered_keep_asset_smoke.gd`, `sundered_keep_layout_smoke.gd`, `sundered_keep_large_layout_smoke.gd`, and manifest missing-ref scan.
- Deferred: persistence, encounter composition, editor-friendly TileSet/TileMapLayer authoring, final visual polish.

## Next Steps

- Next action: visually review the large front gate in-game and tune the JSON composition cells/props if needed.
- Best starting files: `custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json`, `custodian/game/world/sundered_keep/sundered_keep_map.gd`.
- Required context: `design/SUNDERED_KEEP_WORK.md`, this packet, active Sundered Keep smoke scripts.
- Validation to run: the three Sundered Keep Godot smoke scripts.
- Blockers or open questions: none for this implementation pass.
