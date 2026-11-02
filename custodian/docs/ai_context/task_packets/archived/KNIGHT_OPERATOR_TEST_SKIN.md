# KNIGHT OPERATOR TEST SKIN TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-07
- Created: 2026-05-07
- Last updated: 2026-05-07

## Task

Add a toggleable Knight sprite test skin for the operator using `custodian/dev/test_sprites/Knight/*.png`.

## Outcome

The operator can be switched to a visual-only Knight SpriteFrames set without replacing production operator art or depending on custom weapon/FX overlay alignment.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: active operator/combat runtime in `design/`
- Active runtime/docs files: `custodian/game/actors/operator/operator.gd`, `custodian/game/ui/hud/ui.gd`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: operator runtime script, HUD DevConsole command registration, AI context docs
- Files or folders expected to be read but not changed: Knight test PNGs, operator scene/resource files
- Out-of-scope areas: production sprite pipeline replacement, authored weapon socket data, collision resizing

## Constraints

- Determinism concerns: visual-only test toggle must not alter movement, collision, combat damage, or simulation state.
- Simulation/UI boundary concerns: DevConsole only toggles a visual debug mode; operator remains gameplay authority.
- Asset requirements: use existing Knight test sheets; no new drawn assets required.
- Compatibility or migration concerns: production `operator_runtime_frames.tres` remains the default.
- Clarifying questions or assumptions: Knight sheets are treated as 128x128 frames, 15 columns, 8 directional rows.

## Implementation Plan

1. Build Knight `SpriteFrames` at runtime from test sheets when enabled.
2. Hide custom operator weapon/FX overlays while the Knight test skin is active.
3. Add a DevConsole command to activate/deactivate the test skin.
4. Validate headless and update docs.

## Acceptance

- Runtime behavior: operator can toggle Knight test skin on/off without changing collision or gameplay stats.
- Runtime behavior: custom operator weapon/FX overlays are hidden while the Knight visual override is active.
- Documentation: current state records the debug skin toggle.
- Automated/headless validation: `cd custodian && godot --headless --quit`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: added operator-side Knight test `SpriteFrames` construction from `res://dev/test_sprites/Knight/*.png`, DevConsole `knight_skin` toggle/status command, and overlay hiding while the test skin is active.
- Validated: `godot --headless --check-only --script res://game/actors/operator/operator.gd`; `godot --headless --check-only --script res://game/ui/hud/ui.gd`.
- Deferred: full `godot --headless --quit` boot validation currently floods `tile_set.is_null()` errors from procgen/shadow rendering because the active world TileSet is missing referenced placeholder atlas textures; this is outside the Knight skin change. Knight directional row mapping may still need visual tuning during an in-game pass.

## Next Steps

- Next action: test the Knight skin visually in a live run and adjust exported `knight_test_row_*`, position, offset, or scale fields if the sheet row order differs from the current assumption.
- Best starting files: `custodian/game/actors/operator/operator.gd`, `custodian/game/ui/hud/ui.gd`
- Required context: operator visual update and DevConsole command registration.
- Validation to run: `cd custodian && godot --headless --quit` after the missing TileSet texture references are restored or remapped.
- Blockers or open questions: live visual QA is still needed because the Knight sheet row order was inferred from the PNG layout.
